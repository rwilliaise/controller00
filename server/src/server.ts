import { IncomingMessage } from "http"
import { WebSocketServer, WebSocket } from "ws"
import { Args } from "./bin"
import {World} from "./world"
import { Turtle } from "./world/turtle"

export class Server {
    socket = new WebSocketServer({
        port: this.argv.port ?? 8080
    })

    world = new World("localhost")

    constructor(public argv: Args) {
        this.socket.on("connection", (socket, request) => this.connected(socket, request))
    }

    async connected(socket: WebSocket, request: IncomingMessage) {
        console.log(`Incoming connection from ${request.socket.remoteAddress}`)
        this.world.add(socket)
    }
}

