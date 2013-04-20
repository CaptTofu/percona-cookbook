#!/usr/bin/env python

import os
import time
import subprocess
import hashlib
import logging
import struct
from Crypto.Cipher import AES
from swiftclient import Connection, ClientException

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger(__name__)

# Settings
container = 'db_backup'
restore_dir = '/var/lib/mysql-backup/restore'
restore_name = "%s_backup" % time.strftime("%A").lower()
restore_file = restore_name + ".tar.gz"
restore_file_enc = restore_file + ".enc"
backup_key = "backup.key"

try:
    # establish connection
    conn = Connection(os.environ['OS_AUTH_URL'],
                      os.environ['OS_USERNAME'],
                      os.environ['OS_PASSWORD'],
                      tenant_name=os.environ['OS_TENANT_NAME'],
                      auth_version="2.0")
except ClientException, err:
    LOG.critical("No Swift Connection: %s", str(err))


def restore_task(command):
    try:
        subprocess.check_call("%s" % command, shell=True)
    except subprocess.CalledProcessError:
        LOG.error("%s failed" % command)
    else:
        LOG.debug("%s succeeded" % command)


def get_backup_key():
    with open(backup_key, "r") as fh:
        key = fh.readline()

    return key.rstrip()


def download_file_from_swift(container, filename):
    LOG.info("Downloading file %s" % filename)

    try:
        headers, body = conn.get_object(container,
                                        filename,
                                        resp_chunk_size=65536)
    except ClientException, err:
        LOG.critical('Download failed: %s', str(err))
    else:
        LOG.info('Download succeeded')

    s_etag = headers.get('etag')
    md5 = hashlib.md5()
    fh = open(filename, 'wb')
    read_length = 0
    for chunk in body:
        fh.write(chunk)
        read_length += len(chunk)
        LOG.debug("read_length: %d" % read_length)
        if md5:
            md5.update(chunk)
    fh.close()
    f_etag = md5.hexdigest()
    # need to figure out how to handle this
    if (s_etag != f_etag):
        LOG.error("MD5 for file from swift doesn't match that which was "
                  "downloaded!")
        LOG.error("%s != %s" % (s_etag, f_etag))


def run_restoration():
    # get AES key
    backup_key = get_backup_key()

    if not os.path.exists(restore_dir):
        os.mkdir(restore_dir)

    os.chdir(restore_dir)

    download_file_from_swift(container, restore_file_enc)

    # AES encrypt the file before uploading
    decrypt_file(backup_key, restore_file_enc, restore_file)

    restore_task("tar xvzf %s" % restore_file)

    LOG.info("Backup is ready. From here you need to start mysql with "
             "restored data")


def decrypt_file(key, in_filename, out_filename=None, chunksize=24 * 1024):
    """ Decrypts a file using AES (CBC mode) with the
        given key. Parameters are similar to encrypt_file,
        with one difference: out_filename, if not supplied
        will be in_filename without its last extension
        (i.e. if in_filename is 'aaa.zip.enc' then
        out_filename will be 'aaa.zip')
    """
    if not out_filename:
        out_filename = os.path.splitext(in_filename)[0]

    with open(in_filename, 'rb') as infile:
        origsize = struct.unpack('<Q', infile.read(struct.calcsize('Q')))[0]
        iv = infile.read(16)
        decryptor = AES.new(key, AES.MODE_CBC, iv)

        with open(out_filename, 'wb') as outfile:
            while True:
                chunk = infile.read(chunksize)
                if len(chunk) == 0:
                    break
                outfile.write(decryptor.decrypt(chunk))

            outfile.truncate(origsize)


if __name__ == '__main__':
    run_restoration()
