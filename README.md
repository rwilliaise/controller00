# controller00
mine chunks with cc from webserver (1.12, CC: Tweaked), attempt #01.

## building
```bash
# to build server:
cd server && npx tsc

# to build clients:
cd client/cc-turtle/1.89.2 && ./build.sh
```

## using
In the `cc-turtle` subfolders, a minified `dist.lua` is generated. This can be directly uploaded to the turtle and ran.

```
dist
```

For the server, a `ctrl00` bin is defined for the package.
```bash
npx ctrl00
```

### commands
Starting the server opens a command-line interface.

```bash
$ npx ctrl00
> kick 0
Turtle not found
>
```

The available commands are listed below in a table. 

`[turtle]` shall be interpreted as the id of the turtle when it logs in. This is the same id displayed in `turtles` (the number in `Turtle 0` or `Turtle 1`).

`[x y z]` shall be interpreted as a position of a block. For example, `track 220 50 100`.

`[chunk.x chunk.z]` shall be interpreted as a position of a chunk. For example, `scan 0 12 -4` will tell the turtle with the id `0` to scan chunk `12 -4`.

| name | usage | description |
| - | - | - |
| `save` | `save` | Saves world to file. |
| `kick` | `kick [turtle]` | Cuts connection to a turtle. |
| `exit` | `exit` | Saves world and stops server. |
| `cancel` | `cancel [turtle]` | Makes turtle drop its current state. |
| `move` | `move [turtle] [x y z]` | Makes turtle try to path to given location. |
| `track` | `track [x y z]` | Tracks changes to block position in world. |
| `turtles` | `turtles` | Shows information about connected turtles. |
| `what` | `what [x y z]` | Shows known information about the block at position. |
| `netstat` | `netstat [turtle]` | Shows statistics about incoming and outgoing packets from a turtle. |
| `rethink` | `rethink [turtle]` | Re-calibrates the turtle. Requires an open space in front of the turtle and running GPS servers. |
| `scan` | `scan [turtle] [chunk.x chunk.z]` | Makes turtle with block scanner try to scan the terrain of a chunk. Not the entire chunk, however. |