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

    constructor(public argv: Args) {
        this.socket.on("connection", (socket, request) => this.connected(socket, request))
    }

    async connected(socket: WebSocket, request: IncomingMessage) {
        this.world.add(socket)
    }
}

