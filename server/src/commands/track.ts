import { Vector3 } from "../math";
import { Server } from "../server";

export default function track(server: Server, args: string[]) {
    if (args.length < 3) {
        console.log("Usage: track [x y z]")
        return
    }
    const pos = new Vector3(
        parseInt(args[0]),
        parseInt(args[1]),
        parseInt(args[2]),
    )
    server.world.tracking.add(pos.toString())
    console.log(`Tracking changes to ${pos.toString()}`)
}
