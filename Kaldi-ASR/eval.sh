cmd=run.pl
[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

set -u
set -e
set -o pipefail 
KWSEval -e /home/karabi/Documents/Children_Model/KWS_CM/data/test/kws/ecf.xml -r /home/karabi/Documents/Children_Model/KWS_CM/data/test/kws/rttm -t /home/karabi/Documents/Children_Model/KWS_CM/data/test/kws/kwlist.xml \
    -s /home/karabi/Documents/Children_Model/KWS_CM/exp/mono/decode_test/kws_9/kwslist.xml -c -o -b -d -f /home/karabi/Documents/Children_Model/KWS_CM/exp/mono/decode_test/kws_9

