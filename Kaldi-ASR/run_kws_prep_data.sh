#!/bin/bash

#$duration is the length of the search collection, in seconds
duration=`feat-to-len scp:data/test/feats.scp  ark,t:- | awk '{x+=$2} END{print x/100;}'`
#local/generate_example_kws.sh data/test/ data/kws/
local/kws_data_prep_timit.sh data/lang_test_bg data/test data/kws
#lang
steps/make_index.sh --cmd "run.pl" --acwt 0.1 \
 data/kws/ data/lang/ \
  exp/tri3/decode_test/ \
  exp/tri3/decode_test/kws

steps/search_index.sh --cmd "run.pl" \
  data/kws \
  exp/tri3/decode_test/kws
#
# If you want to provide the start time for each utterance, you can use the --segments
# option. In WSJ each file is an utterance, so we don't have to set the start time.
cat exp/tri3/decode_test/kws/result.* | \
  utils/write_kwslist.pl --flen=0.01 --duration=$duration \
  --normalize=true --map-utter=data/kws/utter_map \
  - exp/tri3/decode_test/kws/kwslist.xml


