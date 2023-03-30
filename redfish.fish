#! /usr/bin/env fish

function redfish-write
    redis-cli del $argv[1]
    redis-cli rpush $argv[1] (string escape $argv[2..])
end

function redfish-read --no-scope-shadowing -a __redfish_var __redfish_key
    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    for __redfish_value in (redis-cli lrange $__redfish_key 0 -1)
        set -a $__redfish_var "$(string unescape $__redfish_value)"
    end

    set -e __redfish_key __redfish_value __redfish_var
end

function test-me
    set --local a foo1\nfoo2 bar βαζ
    set --local key fish-redfish-test
    redfish-write $key $a
    set -l got
    redfish-read got $key
    set -s got
end

test-me
