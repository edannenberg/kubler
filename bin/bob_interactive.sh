#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "starting interactive build container..\n"

docker run -it --rm \
--volumes-from portage-data \
-v $(realpath -s $SCRIPT_DIR/../tmp/distfiles):/distfiles \
-v $(realpath -s $SCRIPT_DIR/../tmp/packages):/packages \
"gentoobb/bob:latest"
