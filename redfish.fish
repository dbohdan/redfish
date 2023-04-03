#! /usr/bin/env fish
# redfish: use Redis as a key-value store from fish.
# Copyright (c) 2023 D. Bohdan. License: MIT.
# Put this file in $__fish_config_dir/cond.f/
#
# Requirements:
# * fish 3.4.1 or later (older versions may work but have not been tested);
# * redis-cli(1);
# * a Redis server (local by default).

if not set --query _redfish_key_prefix
    set --global _redfish_key_prefix redfish:
end
if not set --query _redfish_redis_cli_args
    set --global _redfish_redis_cli_args
end
if not set --query _redfish_run_tests
    set --global _redfish_run_tests 0
end

function redfish-key --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    echo -n $_redfish_key_prefix$key
end

function redfish-redis
    redis-cli $_redfish_redis_cli_args $argv
end

function redfish-delete --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (redfish-key $key)

    test "$(redfish-redis del $key)" -eq 1
    # This return is currently useless but won't be if we add more commands
    # later. Our stylistic choice is to have these returns.
    or return
end

function redfish-exists --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (redfish-key $key)

    test "$(redfish-redis exists $key)" -eq 1
    or return
end

function redfish-read --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (redfish-key $key)

    string unescape "$(redfish-redis get $key)"
    or return
end

function redfish-read-list --no-scope-shadowing --argument-names _redfish_var _redfish_key
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    set _redfish_key (redfish-key $_redfish_key)
    set $_redfish_var

    test "$(redfish-redis llen $_redfish_key)" -eq 0
    and return

    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    set --local _redfish_list (redfish-redis lrange $_redfish_key 0 -1)
    or return

    for _redfish_value in $_redfish_list
        set --append $_redfish_var "$(string unescape $_redfish_value)"
        or return
    end

    set --erase _redfish_key _redfish_list _redfish_value _redfish_var
end

function redfish-write --argument-names key value
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    set key (redfish-key $key)

    redfish-redis set $key $value >/dev/null
    or return
end

function redfish-write-list --argument-names key
    argparse --min-args 1 -- $argv
    or return

    set key (redfish-key $key)

    redfish-redis del $key >/dev/null
    or return

    test (count $argv) -eq 1
    and return

    set --local rpushed (redfish-redis rpush $key (string escape $argv[2..]))
    or return

    test "$rpushed" -eq (count $argv[2..])
    or return
end
