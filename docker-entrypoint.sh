#!/bin/bash
set -e

DAYS_BACK=0
FORMAT="mp4"
RESOLUTION1=1920
RESOLUTION2=1080


while getopts ":p:d:f:r1:r2:" opt; do
  case $opt in
    p)
      PATTERN=$OPTARG
      ;;
    d)
      DAYS_BACK=$OPTARG
      ;;
    f)
      FORMAT=$OPTARG
      ;;
    r1)
      RESOLUTION1=$OPTARG
      ;;
    r2)
      RESOLUTION2=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z $PATTERN ]]; then
    echo "No file pattern supplied."
    exit 1
fi

DATE_FORMATTED=$(date +%Y%m%d --date '-'$DAYS_BACK' day')

if [ $FORMAT = "mp4" ]; then
    echo "Busy creating timelapse in mp4 format"
    ffmpeg -hide_banner -v 16 -r 24 -pattern_type glob -i "/input/$PATTERN-$DATE_FORMATTED-*.jpg" -vf scale=$RESOLUTION1:$RESOLUTION2 -vcodec libx264 -y /output/$PATTERN-$DATE_FORMATTED.$FORMAT
    echo "Done...."
elif [ $FORMAT = "gif" ]; then
    # create a mp4 first and palette based on this secondly, this results in significant improved output
    echo "Busy creating and optimizing timelapse in gif format"
    ffmpeg -hide_banner -v 16 -r 24 -pattern_type glob -i "/input/$PATTERN-$DATE_FORMATTED-*.jpg" -vf scale=$RESOLUTION1:$RESOLUTION2 -vcodec libx264 -y /tmp/$PATTERN-$DATE_FORMATTED.mp4
    ffmpeg -hide_banner -v 16 -i /tmp/$PATTERN-$DATE_FORMATTED.mp4 -vf "fps=10,scale=$RESOLUTION1:$RESOLUTION2:flags=lanczos,palettegen" -y /tmp/palette.png
    ffmpeg -hide_banner -v 16 -i /tmp/$PATTERN-$DATE_FORMATTED.mp4 -i /tmp/palette.png -lavfi "fps=10,scale=$RESOLUTION1:$RESOLUTION2:flags=lanczos [x]; [x][1:v] paletteuse" -y /output/$PATTERN-$DATE_FORMATTED.$FORMAT
    rm /tmp/$PATTERN-$DATE_FORMATTED.mp4 /tmp/palette.png
    echo "Done...."
else
    echo "Invalid output specified, only mp4 and gif are supported."
fi


