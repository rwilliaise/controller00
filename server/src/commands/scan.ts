import { Vector2 } from "../math";
import { Server } from "../server";

export default function scan(server: Server, args: string[]) {
    if (args.length < 3) {
        console.log("Usage: scan [turtle] [chunk.x chunk.z]")
        return
    }
    const uid = parseInt(args[0])
    const pos = new Vector2(
        parseInt(args[1]),
        parseInt(args[2]),
    )

    for (const turtle of server.turtles) {
        if (turtle.uid === uid) {
            turtle.sendData(
                "start_scanning",
                {
                    x: pos.x,
                    z: pos.y
                }
            )
            return
        }
    }
    console.log("No turtle found.")
}
