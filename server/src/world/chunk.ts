import { Vector3 } from "../math";
import { BlockState } from "./block";

export const CHUNK_HEIGHT = 256
export const CHUNK_WIDTH = 16

export class Chunk {
    palette = new Map<number, BlockState>()
    blocks: number[] = []

    getBlock(pos: Vector3): BlockState | undefined {
        const pid = this.blocks[pos.z * CHUNK_WIDTH * CHUNK_HEIGHT + pos.y * CHUNK_WIDTH + pos.x]
        if (pid === undefined) return undefined
        return this.palette.get(pid)
    }

    findOpenPid() {
        let out = 0
        while (true) {
            if (!this.palette.has(out)) {
                return out
            }
            out++
        }
    }

    setBlock(pos: Vector3, state?: BlockState) {
        if (pos.x < 0 || pos.x >= CHUNK_WIDTH) return // just check
        if (pos.y < 0 || pos.y >= CHUNK_HEIGHT) return
        if (pos.z < 0 || pos.z >= CHUNK_WIDTH) return
        if (state === undefined) {
            delete this.blocks[pos.z * CHUNK_WIDTH * CHUNK_HEIGHT + pos.y * CHUNK_WIDTH + pos.x]
            return
        }
        let outPid = -1
        for (const [pid, pstate] of this.palette.entries()) {
            if (state.name === pstate.name && state.meta === pstate.meta) {
                outPid = pid
                break
            }
        }
        if (outPid === -1) {
            outPid = this.findOpenPid()
            this.palette.set(outPid, state)
        }
        this.blocks[pos.z * CHUNK_WIDTH * CHUNK_HEIGHT + pos.y * CHUNK_WIDTH + pos.x] = outPid
    }

    
}

