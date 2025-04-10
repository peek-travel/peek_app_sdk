// Import CSS

// Import Phoenix dependencies
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

// Define hooks
let Hooks = {}

// Initialize LiveSocket
let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket

// Add event listener for modal demo
document.addEventListener("DOMContentLoaded", () => {
  console.log("PeekAppSDK Demo initialized")
})
