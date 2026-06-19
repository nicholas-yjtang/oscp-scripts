#!/bin/bash
SCRIPTDIR=$(dirname "${BASH_SOURCE[0]}")
NEWDIR=$1
if [ -z "$NEWDIR" ]; then
  echo "Usage: $0 <directory_name>"
  exit 1
fi

if [ -d "$NEWDIR" ]; then
    echo "Directory $1 already exists."
    exit 1
fi

SCRIPTDIR_NAME=$(basename $SCRIPTDIR)
mkdir -p $NEWDIR
if [ ! -f $NEWDIR/setup.sh ]; then
    default_setup=$(find $SCRIPTDIR -name "setup.sh" | grep "default")
    cp "$default_setup" $NEWDIR
    echo "NEWDIR: $NEWDIR"
    readarray -td "/" directories <<< "$NEWDIR"    
    number_of_directories=${#directories[@]}
    subdir=""
    echo "number_of_directories: $number_of_directories"
    for i in $(seq 1 $number_of_directories); do
        subdir+='\.\.\/'
    done
    sed -i "s/scripts\/common/$subdir""$SCRIPTDIR_NAME\/common/g" $NEWDIR/setup.sh
fi

if [ ! -f $NEWDIR/walk.sh ]; then
    default_walk=$(find $SCRIPTDIR -name "walk.sh" | grep "default")
    cp "$default_walk"  $NEWDIR
fi

if [ ! -f $NEWDIR/mkproject.sh ]; then
    default_project_setup=$(find $SCRIPTDIR -name "mkproject.sh" | grep "default")
    cp "$default_project_setup" $NEWDIR
fi

if [ ! -f $NEWDIR/setup_network.sh ]; then
	default_setup_network=$(find $SCRIPTDIR -name "setup_network.sh" | grep "default")
	cp $default_setup_network $NEWDIR
fi

if [ ! -f $NEWDIR/mkpart.sh ]; then
	default_setup_network=$(find $SCRIPTDIR -name "mkpart.sh" | grep "default")
	cp $default_setup_network $NEWDIR
fi

if [ ! -f $NEWDIR/part_template.sh ]; then
	default_setup_network=$(find $SCRIPTDIR -name "part_template.sh" | grep "default")
	cp $default_setup_network $NEWDIR
fi

