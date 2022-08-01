/** @type {import('tailwindcss').Config} */
const colors = require("tailwindcss/colors");
module.exports = {
  mode: "jit",
  purge: ["../lib/*_web/**/*.*ex", "./js/**/*.js", "../deps/petal_components/**/*.*ex"],
  darkMode: "class",
  content: [],
  theme: {
    extend: {
      colors: {
        primary: colors.blue,
        secondary: colors.pink,
      },
    },
  },
  plugins: [],
}
