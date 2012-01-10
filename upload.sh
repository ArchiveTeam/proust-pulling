#!/bin/sh

set -x

MODULE=$1

rsync --exclude fetch -avzcP data batcave.textfiles.com::$MODULE/proust-stories
