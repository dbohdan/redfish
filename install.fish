#! /usr/bin/env fish

cd "$(path dirname "$(status filename)")"

set --local src functions/redfish.fish
set --local dst $__fish_config_dir/functions/

printf 'copying "%s" to "%s"\n' $src $dst

cp $src $dst
