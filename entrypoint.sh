#!/bin/sh
exec node --trace_gc /app/bin/verdaccio --config /app/config.yaml
