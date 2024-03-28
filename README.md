# redfish

**redfish** lets you use
[Redis](https://redis.io/),
[Valkey](https://valkey.io/)
(an open-source fork of Redis),
[KeyDB](https://github.com/Snapchat/KeyDB),
and other compatible databases
from the
[fish shell](https://fishshell.com/).

redfish is a wrapper around `redis-cli` and compatible clients.
It acts as a partial general-purpose Redis/Valkey/KeyDB/etc. client library.
The use of a `*-cli` binary imposes limitations
on what data redfish can store.
Line feeds are not allowed in values.
It can load and store simple values
and also fish lists as database lists.

## Contents

- [Requirements](#requirements)
- [Usage](#usage)
- [Installation](#installation)
- [Motivation](#motivation)
- [Problems with complex scripting in fish](#problems-with-complex-scripting-in-fish)
- [License](#license)

## Requirements

- fish 3.4 or later.
  Earlier versions will not work.
- redis-cli(1), valkey-cli(1), keydb-cli(1), or another compatible client.
- A Redis, Valkey, KeyDB, or another server compatible with the client
  (the default local server by default).

## Usage

```none
usage: redfish command [ARG ...]
       redfish del [-v|--verbose] KEY [KEY ...]
       redfish exists KEY
       redfish get [-r|--raw] KEY
       redfish get-list VAR KEY
       redfish incr KEY [INCREMENT]
       redfish keys PATTERN
       redfish set KEY VALUE
       redfish set-list KEY [VALUE ...]
```

See
[`example.fish`](example.fish)
for an example of how you can use redfish.

Optionally,
set the variable `__redfish_client_command` in your shell
to use a different client than `redis-cli`
or to pass arguments to the client.

## Installation

### Using Fisher

To install redfish with [Fisher](https://github.com/jorgebucaran/fisher),
run the command:

```fish
fisher install dbohdan/redfish
```

### Manual

1. Clone the repository
   or download and extract a source archive.
2. Run `install.fish`.

## Motivation

I wrote redfish as another way to have
[associative arrays](https://github.com/fish-shell/fish-shell/issues/390)
or dictionaries in fish.
Using redfish requires you to keep its limitations in mind.
Shelling out to `*-cli` makes data access slow.
A fun aspect of using a networked data store is that
it essentially gives you universal variables,
only available over the network and not just to fish.
If you don't need this aspect,
another dictionary implementation is probably better.

## Problems with complex scripting in fish

When writing redfish and [`example.fish`](example.fish),
I discovered that several aspects of the language design
invited bugs and made development distinctly less fun for me.
My experience has lead me to believe that you shouldn't write complex scripts in fish.
Make no mistake:
I still very much like fish as an interactive shell.
I have written about
[my problems with the language](https://dbohdan.com/fish-scripting).

## License

MIT.
