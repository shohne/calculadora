
import os
import time
import glob
from shutil import copyfile
import hashlib
import pathlib
import subprocess
import argparse

parser = argparse.ArgumentParser(description = 'Hot Deploy de aplicacoes JavaEE em servidor Liberty')
parser.add_argument('pomdirectory', type=str, help='diretorio que contem o arquvo pom.xml do projeto')
parser.add_argument('libertyappfolder', type=str, help='caminho para diretorio liberty com a aplicacao [ja expandida]')
args = parser.parse_args()

def dict_md5_files_in_directory(directory, file_mask, recursive = True):
    files = [f for f in glob.glob(directory + "**/*." + file_mask, recursive = recursive)]
    dict_md5_files = {}
    for f in files:
        dict_md5_files[os.path.basename(f)] = [hashlib.md5(pathlib.Path(f).read_bytes()).hexdigest(), f]

    return dict_md5_files


i = 0
while True:
    if i > 1000:
        break

    mavenProcess = subprocess.Popen(['mvn', '-f', args.pomdirectory + '/pom.xml', 'compile'], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)

    dict_md5_files_in_source = dict_md5_files_in_directory(args.pomdirectory + '/target/', 'class')
    dict_md5_files_in_dest = dict_md5_files_in_directory(args.libertyappfolder, 'class')

    for file_source in dict_md5_files_in_source.keys():
        if dict_md5_files_in_source[file_source][0] != dict_md5_files_in_dest[file_source][0]:
            print ('File ', file_source, ' has changed ', dict_md5_files_in_source[file_source][0], dict_md5_files_in_dest[file_source][0])
            copyfile(dict_md5_files_in_source[file_source][1], dict_md5_files_in_dest[file_source][1])


    i = i + 1
    time.sleep(1.000)
