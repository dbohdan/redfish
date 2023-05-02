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
            '^(del|exists|incr|keys|get|get-list|redis|set|set-list)$' \
            $argv[1]
        printf 'redfish: %s: invalid subcommand\n' $argv[1] >/dev/stderr
        return 1
    end

    set --global __redfish_cmd __redfish_(string replace --all - _ $argv[1])
    $__redfish_cmd $argv[2..]
end

function __redfish_usage
    printf 'usage: redfish exists KEY\n' >/dev/stderr
    printf '       redfish del KEY [KEY ...]\n' >/dev/stderr
    printf '       redfish get KEY\n' >/dev/stderr
    printf '       redfish get-list VAR KEY\n' >/dev/stderr
    printf '       redfish incr KEY [INCREMENT]\n' >/dev/stderr
    printf '       redfish keys PATTERN\n' >/dev/stderr
    printf '       redfish redis [ARG ...]\n' >/dev/stderr
    printf '       redfish set KEY VALUE\n' >/dev/stderr
    printf '       redfish set-list KEY [VALUE ...]\n' >/dev/stderr
end

function __redfish_redis
    redis-cli $__redfish_redis_cli_args $argv
end

function __redfish_del --argument-names key
    argparse --min-args 1 v/verbose -- $argv
    or return

    set --local output "$(__redfish_redis del $argv)"
    if set --query _flag_verbose
        echo $output
    end

    test "$output" -eq (count $argv)
    # The following `or return` statement does nothing. While currently
    # useless, it will become necessary for corrent error handling if we add
    # commands below it. Our stylistic choice is to have these returns from
    # the start rather than risk forgetting to add them later.
    or return
end

function __redfish_exists --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    test "$(__redfish_redis exists $key)" -eq 1
    or return
end

function __redfish_keys --argument-names pattern
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    __redfish_redis keys $pattern
end

function __redfish_incr --argument-names key inc
    set --local count (count $argv)
    if test "$count" -lt 1 -o "$count" -gt 2
        return 1
    end

    set --local cmd incrby
    if test -z "$inc"
        set inc 1
    end
    if test "$inc" -lt 0
        set cmd decrby
        set inc (math - $inc)
    end

    __redfish_redis $cmd $key $inc >/dev/null
end

function __redfish_get --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    string unescape "$(__redfish_redis get $key)"
    or return
end

function __redfish_get_list --no-scope-shadowing --argument-names __redfish_dst_var __redfish_src_key
    argparse --min-args 2 --max-args 2 -- $argv
    or return

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

function __redfish_set --argument-names key value
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    __redfish_redis set $key $value >/dev/null
    or return
end

function __redfish_set_list --argument-names key
    argparse --min-args 1 -- $argv
    or return

    __redfish_redis del $key >/dev/null
    or return

    test (count $argv) -eq 1
    and return

    set --local rpushed (__redfish_redis rpush $key (string escape $argv[2..]))
    or return

    test "$rpushed" -eq (count $argv[2..])
    or return
end
