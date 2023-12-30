import WebSocket from "ws"
import { Vector2, Vector3 } from "../math"
import { BlockState } from "./block"
import { Chunk, CHUNK_HEIGHT, CHUNK_WIDTH } from "./chunk"
import { Turtle } from "./turtle"
import { Server } from "../server"

import * as fs from "node:fs/promises"
import path from "node:path"
import * as zlib from "node:zlib"
import { promisify } from "node:util"

type Vector3s = string

export class World {
    address?: string
    turtles = new Set<Turtle>()
    chunks = new Map<string, Chunk>()
    tracking = new Set<string>()
    wid = 0

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
        this.save()
    }

    getFolderPath() {
        return path.join(this.server.saveLocation, String(this.wid))
    }

    /**
     * Get the height of the world at block pos `position` (x, z).
     */
    async getHeight(position: Vector2): Promise<number | undefined> {
        for (let i = 255; i >= 0; i--) {
            const state = await this.getBlock(new Vector3(
                position.x,
                i,
                position.y
            ))
            if (state !== undefined) {
                return i
            }
        }
        return undefined
    }

    async getChunk(pos: Vector2): Promise<Chunk | undefined> {
        let out = this.chunks.get(pos.toString())
        if (out === undefined) {
            const chunkPath = path.join(this.getFolderPath(), pos.toString())
            try {
                const chunk = await fs.readFile(chunkPath)
                    .then(b => promisify(zlib.inflate)(b))
                    .then(b => b.toString())
                    .then(s => JSON.parse(s))
                if (this.chunks.has(pos.toString())) return this.chunks.get(pos.toString())
                out = new Chunk()
                out.blocks = chunk.blocks
                out.palette = new Map(chunk.palette)
                console.log(`Loading chunk at ${pos.toString()}`)
                this.chunks.set(pos.toString(), out)
            } catch {
                return undefined
            }
        }
        return out
    }

    async getOrCreateChunk(pos: Vector2): Promise<Chunk> {
        let out = await this.getChunk(pos)
        if (out === undefined) {
            out = new Chunk()
            // bro...
            if (!this.chunks.has(pos.toString())) {
                console.log(`Creating new chunk at ${pos.toString()}`)
                this.chunks.set(pos.toString(), out)
            } else {
                out = this.chunks.get(pos.toString()) as Chunk
            }
        }
        return out
    }

    async getBlock(pos: Vector3): Promise<BlockState | undefined> {
        const chunkPos = new Vector2(pos.x >> 4, pos.z >> 4)
        const chunk = await this.getChunk(chunkPos)
        if (chunk === undefined) return undefined
        return chunk.getBlock(new Vector3(
            pos.x & 0xF,
            pos.y,
            pos.z & 0xF,
        ))
    }

    async setBlock(pos: Vector3, state?: BlockState) {
        const chunkPos = new Vector2(Math.floor(pos.x / 16), Math.floor(pos.z / 16))
        const chunk = await this.getOrCreateChunk(chunkPos)
        if (this.tracking.has(pos.toString())) {
            const old = await this.getBlock(pos)
            if (old?.name !== state?.name || old?.meta !== state?.meta) {
                console.log(`Tracked (${pos.toString()}) -> ${state?.name}`)
            }
        }
        chunk.setBlock(new Vector3(
            pos.x & 0xF,
            pos.y,
            pos.z & 0xF,
        ), state)
    }

    load() {
    }

    async save() {
        const folder = await fs.mkdir(this.getFolderPath(), { recursive: true })
        const promises = []
        for (const [pos, chunk] of this.chunks.entries()) {
            const chunkPath = path.join(this.getFolderPath(), pos)

            promises.push(
                promisify(zlib.deflate)(
                    JSON.stringify({
                        blocks: chunk.blocks,
                        palette: Array.from(chunk.palette.entries())
                    })
                ).then(b => fs.writeFile(chunkPath, b))
            )
        }
        await Promise.all(promises)
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

    private async forNeighbors(pos: Vector3, cb: ((neighbor: Vector3) => Promise<void>)) {
        const ifAllowed = async (n: Vector3) => {
            // TODO: mining blocks to get to location

            const state = (await this.getBlock(n))
            if (state === undefined) {
                await cb(n)
            }
        }
        
        await Promise.all([
            ifAllowed(pos.add( 1,  0,  0)),
            ifAllowed(pos.add(-1,  0,  0)),
            ifAllowed(pos.add( 0,  1,  0)),
            ifAllowed(pos.add( 0, -1,  0)),
            ifAllowed(pos.add( 0,  0,  1)),
            ifAllowed(pos.add( 0,  0, -1)),
        ])
    }

    async searchPath(start: Vector3, end: Vector3) {
        // this function is a plight on man
        // this function does and continues to drag humanity down
        if (start.equals(end)) return

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

           await this.forNeighbors(Vector3.fromString(current), async (n) => {
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

