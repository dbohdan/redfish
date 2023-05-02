#! /usr/bin/env fish

cd "$(path dirname "$(status filename)")"

set --local src redfish.fish
set --local dst $__fish_config_dir/conf.d/redfish.fish

if not cp $src $dst
    return 1
end
printf 'copied "%s" to "%s"\n' $src $dst

if not source $dst
    return 1
end
printf 'sourced "%s"\n' $dst
