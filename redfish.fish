# redfish: use Redis as a key-value store from fish.
# Copyright (c) 2023 D. Bohdan. License: MIT.
#
# Installation:
# Put this file in $__fish_config_dir/conf.d/.
#
# Requirements:
# * fish 3.4.1 or later (older versions may work but have not been tested);
# * redis-cli(1);
# * a Redis server (local by default).

if not set --query __redfish_key_prefix
    set --global __redfish_key_prefix __redfish:
end
if not set --query __redfish_redis_cli_args
    set --global __redfish_redis_cli_args
end

function redfish --no-scope-shadowing
    if test (count $argv) -eq 0
        printf 'redfish: missing subcommand\n' >/dev/stderr
        return 1
    end

    if string match --quiet --regex -- \
            '^(-\?|-h|-help|--help|help)$' \ 
            $argv[1]
        __redfish_usage
        return
    end

    if not string match --quiet --regex -- \
            '^(delete|exists|key|read|read-list|redis|write|write-list)$' \
            $argv[1]
        printf 'redfish: %s: invalid subcommand\n' $argv[1] >/dev/stderr
        return 1
    end

    set --global __redfish_cmd __redfish_(string replace --all - _ $argv[1])
    $__redfish_cmd $argv[2..]
end

function __redfish_usage
    printf 'usage: redfish (delete|exists|key|read) KEY\n' >/dev/stderr
    printf '       redfish read-list VAR KEY\n' >/dev/stderr
    printf '       redfish redis [ARG ...]\n' >/dev/stderr
    printf '       redfish write KEY VALUE\n' >/dev/stderr
    printf '       redfish write-list KEY [VALUE ...]\n' >/dev/stderr
end

function __redfish_key --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    echo -n $__redfish_key_prefix$key
end

function __redfish_redis
    redis-cli $__redfish_redis_cli_args $argv
end

function __redfish_delete --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (__redfish_key $key)

    test "$(__redfish_redis del $key)" -eq 1
    # The following `or return` statement does nothing. While currently
    # useless, it will become necessary for corrent error handling if we add
    # commands below it. Our stylistic choice is to have these returns from
    # the start rather than risk forgetting to add them later.
    or return
end

function __redfish_exists --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (__redfish_key $key)

    test "$(__redfish_redis exists $key)" -eq 1
    or return
end

function __redfish_read --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    set key (__redfish_key $key)

    string unescape "$(__redfish_redis get $key)"
    or return
end

function __redfish_read_list --no-scope-shadowing --argument-names __redfish_dst_var __redfish_src_key
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    set __redfish_src_key (__redfish_key $__redfish_src_key)
    set $__redfish_dst_var

    test "$(__redfish_redis llen $__redfish_src_key)" -eq 0
    and return

    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    set --local __redfish_list (__redfish_redis lrange $__redfish_src_key 0 -1)
    or return

    for __redfish_value in $__redfish_list
        set --append $__redfish_dst_var "$(string unescape $__redfish_value)"
        or return
    end

    set --erase \
        __redfish_dst_var \
        __redfish_list \
        __redfish_src_key \
        __redfish_value
end

function __redfish_write --argument-names key value
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    set key (__redfish_key $key)

    __redfish_redis set $key $value >/dev/null
    or return
end

function __redfish_write_list --argument-names key
    argparse --min-args 1 -- $argv
    or return

    set key (__redfish_key $key)

    __redfish_redis del $key >/dev/null
    or return

    test (count $argv) -eq 1
    and return

    set --local rpushed (__redfish_redis rpush $key (string escape $argv[2..]))
    or return

    test "$rpushed" -eq (count $argv[2..])
    or return
end
