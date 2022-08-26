
let Hooks = {};

Hooks.LocalTime = {
  mounted() {
    this.updated();
  },
  updated() {
    const el = this.el;
    var seconds = parseInt(el.innerText)
    var dt = new Date(Date.UTC(1970, 0, 1));
    dt.setSeconds(seconds);
    el.innerText = dt.toLocaleString()
  },
};

export default Hooks;
