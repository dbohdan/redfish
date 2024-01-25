# redfish

**redfish** lets you use
[Redis](https://redis.io/)
from the
[fish shell](https://fishshell.com/).

redfish is a wrapper around [redis-cli(1)](https://redis.io/docs/connect/cli/).
It acts as a partial general-purpose Redis client library.
The use of redis-cli imposes limitations on what data it can store.
Line feeds are not allowed in values.
It can load and store simple values
and also fish lists as Redis lists.

## Usage

```none
usage: redfish exists KEY
       redfish del [-v|--verbose] KEY [KEY ...]
       redfish get [-r|--raw] KEY
       redfish get-list VAR KEY
       redfish incr KEY [INCREMENT]
       redfish keys PATTERN
       redfish redis [ARG ...]
       redfish set KEY VALUE
       redfish set-list KEY [VALUE ...]
```

## License

MIT.
