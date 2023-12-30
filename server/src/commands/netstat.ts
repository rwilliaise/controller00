import {Server} from "../server"

export default function netstat(server: Server, args: string[]) {
    const id = parseInt(args[0] ?? "-1")
    for (const t of server.turtles) {
        if (t.uid === id) {
            console.log("Packets received:")
            console.table(t.netstat.received)

            console.log("Packets sent:")
            console.table(t.netstat.sent)
            return
        }
    }
    console.log("Turtle not found.")
}
