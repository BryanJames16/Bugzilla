<div align="center">
  <img src="./assets/images/Buggie.svg" title="Bugzilla" alt="Bugzilla" width="95" height="125" style="filter: url(#glow);" align="center" />

<svg xmlns="http://www.w3.org/2000/svg" version="1.1" height="0">
  <defs>
    <filter id="glow">
      <feGaussianBlur stdDeviation="15" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
</svg>

<link href="https://fonts.googleapis.com/css?family=Onest&display=swap" rel="stylesheet">

<h1 style="font-family: Onest, monospace; color: orange; ">Bugzilla Containerized</h1>
<h6>An experimental repository for deploying Bugzilla on a containerized environment</h6>

</div>

---

This project aims to create a more seamless deployment for Bugzilla as containerized and cloud native application. As of the moment, there are lots of dependencies and set up needed in order for Bugzilla to properly run. We want this experience to improve and create a more cross-platform appraoch in running and deploying Bugzilla. Furthermore, we want our deployments to be secure and easy to configure.

## 🏁 Goals
- [ ] Improve ease of deployment of Bugzila and its dependencies through containerization.
- [ ] Improve backend configuration of Bugzilla by introducing declarative set up through Kubernetes and Helm Charts.
- [ ] Secure Bugzilla container deployments through secure container image base.
- [ ] GItOps approach in deployment and managing Bugzilla.

## 🤝 Contributing
To be added

## 🪪 License
[Mozilla Public License v2.0](./LICENSE)
