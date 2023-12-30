import { IncomingMessage } from "http"
import { WebSocketServer, WebSocket } from "ws"
import { Args } from "./bin"
import { World } from "./world"
import { Turtle } from "./world/turtle"
import { Commands } from "./commands"

export class Server {
    socket = new WebSocketServer({
        port: this.argv.port ?? 8080
    })
    world = new World(this, "localhost")
    commands = new Commands(this)
    turtles = new Set<Turtle>()
    currentUid = 0

    saveLocation = this.argv.save ?? "save"

    constructor(public argv: Args) {
        this.socket.on("connection", (socket, request) => this.connected(socket, request))
    }

    async connected(socket: WebSocket, request: IncomingMessage) {
        const response = await this.commands.interface.question(`Turtle ${this.currentUid} (${request.socket.remoteAddress}) requesting to join. Approve? [y/N] `)
        this.commands.interface.prompt()
        if (response.trim().toLowerCase() !== "y") {
            socket.close()
            return
        }
        this.world.add(socket)
    }
}

