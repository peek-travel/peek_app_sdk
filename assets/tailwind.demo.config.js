// Demo tailwind configuration that extends the main tailwind config
const path = require("path")
const mainConfig = require("./tailwind.config.js")

// Get the main config with heroicons path
const sdkConfig = mainConfig({
  heroiconsPath: path.join(__dirname, "../deps/heroicons/optimized")
})

module.exports = {
  content: [
    "./assets/**/*.js",
    "../lib/peek_app_sdk/**/*.*ex",
    "../lib/peek_app_sdk/demo/**/*.*ex",
  ],
  theme: {
    extend: {
      ...sdkConfig.theme.extend
    }
  },
  plugins: [...sdkConfig.plugins]
}
