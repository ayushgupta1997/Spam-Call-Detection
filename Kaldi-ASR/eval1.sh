cmd=run.pl
[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

set -u
set -e
set -o pipefail 
KWSEval -e /home/karabi/Documents/KWS1_kaldi/data/test/kws/ecf.xml -r /home/karabi/Documents/KWS1_kaldi/data/test/kws/rttm -t /home/karabi/Documents/KWS1_kaldi/data/test/kws/kwlist.xml \
    -s /home/karabi/Documents/KWS1_kaldi/exp/tri3/decode_test_kws/kws_9/kwslist.xml -c -o -b -d -f /home/karabi/Documents/KWS1_kaldi/exp/tri3/decode_test_kws

