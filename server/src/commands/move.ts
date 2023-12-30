import {Vector3} from "../math"
import { Server } from "../server"

export default function move(server: Server, args: string[]) {
    if (args.length < 4) {
        console.log("Usage: move [turtle] [x y z]")
        return
    }
    const uid = parseInt(args[0])
    const pos = new Vector3(
        parseInt(args[1]),
        parseInt(args[2]),
        parseInt(args[3]),
    )

    
    for (const turtle of server.turtles) {
        if (turtle.uid === uid) {
            turtle.world.setBlock(pos, undefined) // ensure it works
            turtle.sendData("start_pathing", pos)
            return
        }
    }
    console.log("No turtle found.")
}
