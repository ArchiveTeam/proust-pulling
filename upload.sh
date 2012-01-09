#!/bin/sh

set -x

MODULE=$1

mkdir -p www.proust.com
rsync --exclude fetch -cavP data batcave.textfiles.com::$MODULE/proust-stories
