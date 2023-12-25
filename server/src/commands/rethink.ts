import {Server} from "../server"

export default function rethink(server: Server, args: string[]) {
    const id = parseInt(args[0] ?? "-1")
    if (id === -1) {
        console.log("Supply a turtle id.")
        return
    }

    for (const t of server.turtles) {
        if (t.uid === id) {
            t.sendData("rethink", undefined)
            return
        }
    }
    console.log("Turtle not found.")
}
