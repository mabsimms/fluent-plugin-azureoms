#!/bin/bash

fluentd -vv --config ./fluentd-test-config.conf \
    --plugin ./lib/fluent/plugin
