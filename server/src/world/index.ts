import WebSocket from "ws"
import { Vector2, Vector3 } from "../math"
import { BlockState } from "./block"
import { Chunk, CHUNK_WIDTH } from "./chunk"
import { Turtle } from "./turtle"
import { Server } from "../server"

type Vector3s = string

export class World {
    address?: string
    turtles = new Set<Turtle>()
    chunks = new Map<string, Chunk>()

    constructor(public server: Server, private location: string) {}

    add(socket: WebSocket) {
        const turtle = new Turtle(this, socket)
        this.turtles.add(turtle)
        this.server.turtles.add(turtle)
        return turtle
    }

    remove(turtle: Turtle) {
        this.turtles.delete(turtle)
        this.server.turtles.delete(turtle)
    }

    getChunk(pos: Vector2): Chunk | undefined {
        return this.chunks.get(pos.toString())
    }

    getBlock(pos: Vector3): BlockState | undefined {
        const chunkPos = new Vector2(Math.floor(pos.x / 16), Math.floor(pos.z / 16))
        const chunk = this.getChunk(chunkPos)
        if (chunk === undefined) return
        return chunk.getBlock(new Vector3(
            pos.x % CHUNK_WIDTH,
            pos.y,
            pos.z % CHUNK_WIDTH,
        ))
    }

    load() {

    }

    save() {

    }

    private heuristic(start: Vector3, end: Vector3) {
        return Math.abs(start.x - end.x) + Math.abs(start.y - end.y) + Math.abs(start.z - end.z)
    }

    private reconstructPath(from: Map<Vector3s, Vector3s>, end: Vector3s) {
        const totalPath: Vector3[] = [Vector3.fromString(end)]
        let current: Vector3s | undefined = end
        while (current !== undefined && from.has(current)) {
            current = from.get(current)
            if (current === undefined) continue
            totalPath.unshift(Vector3.fromString(current))
        }
        return totalPath
    }

    private forNeighbors(pos: Vector3, cb: (neighbor: Vector3) => void) {
        const ifAllowed = (n: Vector3) => {
            // TODO: mining blocks to get to location
            if (this.getBlock(n) === undefined) {
                cb(n)
            }
        }
        
        ifAllowed(pos.add( 1,  0,  0))
        ifAllowed(pos.add(-1,  0,  0))
        ifAllowed(pos.add( 0,  1,  0))
        ifAllowed(pos.add( 0, -1,  0))
        ifAllowed(pos.add( 0,  0,  1))
        ifAllowed(pos.add( 0,  0, -1))
    }

    searchPath(start: Vector3, end: Vector3) {
        // this function is a plight on man
        // this function does and continues to drag humanity down
        const open = new Set<Vector3s>()
        const from = new Map<Vector3s, Vector3s>()
        open.add(start.toString())

        const f = new Map<Vector3s, number>()
        const g = new Map<Vector3s, number>()

        f.set(start.toString(), this.heuristic(start, end))
        g.set(start.toString(), 0)

        while (open.size > 0) {
            let current!: Vector3s
            open.forEach((node) => {
                if (current === undefined)
                    current = node
                else if ((f.get(node) ?? Infinity) < (f.get(current) ?? Infinity))
                    current = node
            })

            if (Vector3.fromString(current).equals(end))
               return this.reconstructPath(from, current) 

           open.delete(current)

           this.forNeighbors(Vector3.fromString(current), (n) => {
                const newGScore = (g.get(current) ?? Infinity) + 1 // TODO: replace with d
                if (newGScore < (g.get(n.toString()) ?? Infinity)) {
                    from.set(n.toString(), current)
                    g.set(n.toString(), newGScore)
                    f.set(n.toString(), newGScore + this.heuristic(n, end))
                    if (!open.has(n.toString())) {
                        open.add(n.toString())
                    }
                }
           })
        }
        return undefined
    }
}

