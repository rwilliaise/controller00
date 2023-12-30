import { Server } from "../server"

export default function cancel(server: Server, args: string[]) {
    const id = parseInt(args[0] ?? "-1")
    if (id === -1) {
        console.log("Supply a turtle id.")
        return
    }

    for (const t of server.turtles) {
        if (t.uid === id) {
            t.send({ id: "start_idling" })
            return
        }
    }
    console.log("Turtle not found.")
}
