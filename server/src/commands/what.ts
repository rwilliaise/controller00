import {Vector3} from "../math"
import { Server } from "../server"

export default function what(server: Server, args: string[]) {
    if (args.length < 4) {
        console.log("Usage: what [x y z]")
        return
    }
    // const wid = parseInt(args[0])
    const pos = new Vector3(
        parseInt(args[0]),
        parseInt(args[1]),
        parseInt(args[2]),
    )

    server.world.getBlock(pos)
        .then((block) => {
            let out
            if (block === undefined) {
                out = {
                    name: 'minecraft:air'
                }
            } else {
                out = {
                    name: block.name,
                    meta: block.meta,
                }
            }
            console.table(out)
        })
    
}
