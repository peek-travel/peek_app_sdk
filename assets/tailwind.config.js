// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

let colors = {
  gray: {
    100: "#fafaff",
    200: "#dadce7",
    300: "#dee2e6",
    400: "#ced4da",
    500: "#adb5bd",
    600: "#868e96",
    700: "#455460",
    800: "#414159",
    900: "#212529"
  }
}

module.exports = function(options = {}) {
  const heroiconsPath = options.heroiconsPath || path.join(__dirname, "../deps/heroicons/optimized")

  return {
    content: [
      "./assets/**/*.js",
      "../lib/peek_app_sdk/**/*.*ex"
    ],
    theme: {
      extend: {
        colors: {
          brand: "#3957EA",
          warning: "#F9AA00",
          danger: "#E5243C",
          info: "#048AF7",
          success: "#41B658",
          'brand-secondary': "#1F37AD",
          'background-primary': "#F2F3FA",
          'background-secondary': "#FAFAFF",
          'focus-shadow': "#E9EDFD",
          'gray-primary': "#656A81",
          'pale-green': "#EFFFF5",
          'pale-blue': "#E7FFFE",
          'brand-teal': "#007494",
          'brand-green': "#8FE98F",
          ...colors
        },
      },
    },
    plugins: [
      require("@tailwindcss/forms"),
      // Allows prefixing tailwind classes with LiveView classes to add rules
      // only when LiveView classes are applied, for example:
      //
      //     <div class="phx-click-loading:animate-ping">
      //
      plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
      plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
      plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

      // Embeds Heroicons (https://heroicons.com) into your app.css bundle
      // See your `CoreComponents.icon/1` for more information.
      //
      plugin(function({matchComponents, theme}) {
        if (!fs.existsSync(heroiconsPath)) {
          console.warn("Heroicons directory not found at:", heroiconsPath)
          return
        }

        let values = {}
        let icons = [
          ["", "/24/outline"],
          ["-solid", "/24/solid"],
          ["-mini", "/20/solid"],
          ["-micro", "/16/solid"]
        ]

        icons.forEach(([suffix, dir]) => {
          const fullDir = path.join(heroiconsPath, dir)
          if (fs.existsSync(fullDir)) {
            fs.readdirSync(fullDir).forEach(file => {
              let name = path.basename(file, ".svg") + suffix
              values[name] = {name, fullPath: path.join(fullDir, file)}
            })
          }
        })

        if (Object.keys(values).length > 0) {
          matchComponents({
            "hero": ({name, fullPath}) => {
              let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
              let size = theme("spacing.6")
              if (name.endsWith("-mini")) {
                size = theme("spacing.5")
              } else if (name.endsWith("-micro")) {
                size = theme("spacing.4")
              }
              return {
                [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
                "-webkit-mask": `var(--hero-${name})`,
                "mask": `var(--hero-${name})`,
                "mask-repeat": "no-repeat",
                "background-color": "currentColor",
                "vertical-align": "middle",
                "display": "inline-block",
                "width": size,
                "height": size
              }
            }
          }, {values})
        }
      })
    ]
  }
}
