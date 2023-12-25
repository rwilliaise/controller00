import {Server} from "../server"

export default function kick(server: Server, args: string[]) {
    const id = parseInt(args[0] ?? "-1")
    if (id === -1) {
        console.log("Supply an id.")
        return
    }

    for (const t of server.turtles) {
        if (t.uid === id) {
            t.ws.close()
            break
        }
    }
}
