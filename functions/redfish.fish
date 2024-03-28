# redfish: Use Redis/Valkey/KeyDB/etc. from the fish shell.
# Copyright (c) 2023-2024 D. Bohdan. License: MIT.
#
# Requirements:
# - fish 3.4 or later (older versions do not work);
# - redis-cli(1), valkey-cli(1), keydb-cli(1), or another compatible client.
# A Redis, Valkey, KeyDB, or another server compatible with the client
# (the default local server by default).

function redfish --no-scope-shadowing
    if not set --query __redfish_client_command
        set --global __redfish_client_command redis-cli
    end

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
            '^(command|del|exists|incr|keys|get|get-list|set|set-list)$' \
            $argv[1]
        printf 'redfish: %s: invalid subcommand\n' $argv[1] >/dev/stderr
        return 1
    end

    set --global __redfish_cmd __redfish_(string replace --all - _ $argv[1])
    $__redfish_cmd $argv[2..]
end

function __redfish_usage
    printf 'usage: redfish command [ARG ...]\n'
    printf '       redfish del [-v|--verbose] KEY [KEY ...]\n'
    printf '       redfish exists KEY\n'
    printf '       redfish get [-r|--raw] KEY\n'
    printf '       redfish get-list VAR KEY\n'
    printf '       redfish incr KEY [INCREMENT]\n'
    printf '       redfish keys PATTERN\n'
    printf '       redfish set KEY VALUE\n'
    printf '       redfish set-list KEY [VALUE ...]\n'
end

function __redfish_command
    command $__redfish_client_command $argv
end

function __redfish_del --argument-names key
    argparse --min-args 1 v/verbose -- $argv
    or return

    set --local output "$(__redfish_command del $argv)"
    if set --query _flag_verbose
        echo $output
    end

    test $output -eq (count $argv)
    # The following `or return` statement does nothing. While currently
    # useless, it will become necessary for corrent error handling if we add
    # commands below it. Our stylistic choice is to have these returns from
    # the start rather than risk forgetting to add them later.
    or return
end

function __redfish_exists --argument-names key
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    test "$(__redfish_command exists $key)" -eq 1
    or return
end

function __redfish_keys --argument-names pattern
    argparse --min-args 1 --max-args 1 -- $argv
    or return

    __redfish_command keys $pattern
end

function __redfish_incr --argument-names key inc
    set --local count (count $argv)
    if test $count -lt 1 -o $count -gt 2
        return 1
    end

    set --local cmd incrby
    if test -z $inc
        set inc 1
    end
    if test $inc -lt 0
        set cmd decrby
        set inc (math - $inc)
    end

    __redfish_command $cmd $key $inc >/dev/null
end

function __redfish_get --argument-names key
    argparse --min-args 1 --max-args 1 r/raw -- $argv
    or return

    set --local value "$(__redfish_command get $key)"
    or return

    if not set --query _flag_raw
        set value (string unescape $value)
        or return
    end

    echo -n $value
end

function __redfish_get_list --no-scope-shadowing --argument-names __redfish_dst_var __redfish_src_key
    argparse --min-args 2 --max-args 2 -- $argv
    or return

    set $__redfish_dst_var

    test "$(__redfish_command llen $__redfish_src_key)" -eq 0
    and return

    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    set --local __redfish_list (__redfish_command lrange $__redfish_src_key 0 -1)
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

    __redfish_command set $key $value >/dev/null
    or return
end

function __redfish_set_list --argument-names key
    argparse --min-args 1 -- $argv
    or return

    __redfish_command del $key >/dev/null
    or return

    test (count $argv) -eq 1
    and return

    set --local rpushed "$(__redfish_command rpush $key (string escape $argv[2..]))"
    or return

    test $rpushed -eq (count $argv[2..])
    or return
end
