# Backend Source Placeholder

The NestJS backend source code lives in a separate repository:
**[CIRCA-RL-GHANA/NestJS-Ready](https://github.com/CIRCA-RL-GHANA/NestJS-Ready)**

CI workflows in this Root repo check out `NestJS-Ready` into this directory at
build/test time before running `docker build` or `npm run lint/test`.

Do **not** add source files here — this directory is overwritten by CI.
