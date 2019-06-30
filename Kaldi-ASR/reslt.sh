#!/bin/bash
. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

#local/kws_data_prep.sh data/lang data/test data/KWS 
#steps/make_index.sh data/KWS data/lang exp/mono/decode_test data/test/kws
steps/search_index.sh data/test/kws data/test/kws
