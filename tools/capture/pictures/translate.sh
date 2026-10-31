#!/usr/bin/env bash
# makes: translate
# A paragraph of a PDF in the other language selected and translated with Super+T.
. "$(dirname "$0")/../lib.sh"
pdfs
fresh
if [[ $lang == ru ]]; then papers Cloudberry.pdf; else papers Морошка.pdf; fi
sleep 7
c click 700 750
film "translate-$lang" translate 0.1 9.6
c key esc
