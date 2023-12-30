#!/usr/bin/node

import yargs from "yargs";
import { Server } from "./server";

const options = yargs(process.argv.slice(2))
    .scriptName("ctrl00")
    .usage("opens webserver for controller00")
    .option("save", {
        type: "string",
        alias: "S",
        desc: "save location"
    })
    .option("server", {
        type: "string",
        alias: "s",
        desc: "limit connections to ip",
    })
    .option("port", {
        type: "number",
        alias: "p",
        desc: "bind server to port",
    })
    .help()
    .parseSync()

export type Args = typeof options
new Server(options)
