# !/bin/bash

set -x
set -e

MIX_ENV=test mix local.rebar --force
MIX_ENV=test mix local.hex --force
MIX_ENV=test mix deps.get
MIX_ENV=test mix compile

MIX_ENV=test mix format --check-formatted
MIX_ENV=test mix credo
MIX_ENV=test mix deps.audit
MIX_ENV=test mix dialyzer