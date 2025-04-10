const esbuild = require("esbuild")
const path = require("path")

const args = process.argv.slice(2)
const watch = args.includes("--watch")
const deploy = args.includes("--deploy")

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
}

const plugins = [
  // Add and configure plugins here
]

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  logLevel: "info",
  target: "es2017",
  outdir: "../priv/static/assets",
  external: ["*.css", "fonts/*", "images/*"],
  loader: loader,
  plugins: plugins
}

if (deploy) {
  opts = {
    ...opts,
    minify: true
  }
}

if (watch) {
  opts = {
    ...opts,
    watch: {
      onRebuild(error) {
        if (error) console.error("Esbuild: Failed to rebuild")
        else console.log("Esbuild: Rebuilt")
      }
    }
  }
}

// Build
esbuild.build(opts)
