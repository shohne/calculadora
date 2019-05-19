# python -m pip install watchdog

# python hotdeploy.py c:\projeto\calculadora\liberty c:\projeto\wlp\usr\servers\calculadora\apps\expanded\calculadora.war\WEB-INF\classes\

import os
import time
import glob
from shutil import copyfile
import hashlib
import pathlib
import subprocess
import argparse
import sys
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

parser = argparse.ArgumentParser(description = 'Hot Deploy de aplicacoes JavaEE em servidor Liberty')
parser.add_argument('pomdirectory', type=str, help='diretorio que contem o arquvo pom.xml do projeto')
parser.add_argument('libertyappfolder', type=str, help='caminho para diretorio liberty com a aplicacao [ja expandida]')
args = parser.parse_args()



def dict_md5_files_in_directory(base_directory, file_mask, recursive = True):
    files = [f for f in glob.glob(base_directory + '**' + os.sep + '*.' + file_mask, recursive = recursive)]
    dict_md5_files = {}
    for f in files:
        filename_from_project_base_directory = f.replace(base_directory, '')
        dict_md5_files[filename_from_project_base_directory] = [hashlib.md5(pathlib.Path(f).read_bytes()).hexdigest(), f]

    return dict_md5_files


def compileAndDeploy():

    mavenProcess = subprocess.Popen(['mvn', '-f', args.pomdirectory + os.sep + 'pom.xml', 'compile'], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE, shell=True)

    dict_md5_files_in_source = dict_md5_files_in_directory(args.pomdirectory + os.sep + 'target' + os.sep + 'classes' + os.sep, 'class')
    dict_md5_files_in_dest = dict_md5_files_in_directory(args.libertyappfolder, 'class')

#    print ('source', dict_md5_files_in_source)
#    print ('dest', dict_md5_files_in_dest)

#    if True:
#        return

    for file_source in dict_md5_files_in_source.keys():
        if  file_source not in dict_md5_files_in_dest or dict_md5_files_in_source[file_source][0] != dict_md5_files_in_dest[file_source][0]:
            print ('File ', file_source, ' has changed/created ', dict_md5_files_in_source[file_source][0])
            copyfile(dict_md5_files_in_source[file_source][1], args.libertyappfolder + file_source)




class SourceChangeEventHandler(FileSystemEventHandler):
    """Logs all the events captured."""

    def on_moved(self, event):
        super(SourceChangeEventHandler, self).on_moved(event)
#        what = 'directory' if event.is_directory else 'file'
#        logging.info("Moved %s: from %s to %s", what, event.src_path, event.dest_path)

    def on_created(self, event):
        super(SourceChangeEventHandler, self).on_created(event)
#        what = 'directory' if event.is_directory else 'file'
#        logging.info("Created %s: %s", what, event.src_path)

    def on_deleted(self, event):
        super(SourceChangeEventHandler, self).on_deleted(event)
#        what = 'directory' if event.is_directory else 'file'
#        logging.info("Deleted %s: %s", what, event.src_path)

    def on_modified(self, event):
        super(SourceChangeEventHandler, self).on_modified(event)
#        what = 'directory' if event.is_directory else 'file'
#        logging.info("Modified %s: %s", what, event.src_path)
        compileAndDeploy()


if __name__ == "__main__":

    print ('args.pomdirectory:', args.pomdirectory)
    print ('src:', args.pomdirectory + os.sep + 'src')
    print ('target/classes/', args.pomdirectory + os.sep + 'target' + os.sep + 'classes' + os.sep)
    print ('libertyappfolder', args.libertyappfolder)

    event_handler = SourceChangeEventHandler()
    observer = Observer()
    observer.schedule(event_handler, args.pomdirectory + os.sep + 'src', recursive = True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()