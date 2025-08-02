# azem

> [!WARNING]
> this project is currently WIP.
> expect memory leaks, inconsistencies, and missing features.
>
> initial goals revolve around micromouse simulation, enabling other simulation options via extensions and enhanced api is planned.

> [!TIP]
> you can try azem in your web browser now!
>
> go to [thuvasooriya.me/azem](https://thuvasooriya.me/azem)

<img src="https://i.imgur.com/pypv09P.png" alt="azem running in macos native build" width="500">

## getting started

it's zig so you know the drill.

```bash
git clone https://github.com/thuvasooriya/azem.git
cd azem
zig build # will build for your platform and run the exe

zig build web # to run on web browser! yeah i know awesome right
```

## why

i'm a **very** openionated person, that's one of the reasons i love open-source. if something is itchy, then you can go break some stuff. when i was trying out [mms simulator](https://github.com/mackorone/mms) (which is awesome and props to mack for providing executables for all platforms, god what a legend), i wanted to make some changes. then i found out it uses qt for the gui. hmm... (long pause and a deep sigh). cpp i can bite down but qt... i just couldn't.

aktually... i wanted to try doing something cool in zig language. so here we are.

much of the initial app architectural decisions were also inspired from [pixi](https://github.com/foxnne/pixi/tree/dvui) (another awesome zig project by an awesome person).
the architecture is constantly evolving. this is almost the 4th rewrite of this application. this will evolve with dvui and zig so don't expect a finish line anytime soon.

> [!TIP]
> yeah if you haven't figured already, azem is just the letter `m` on the word "maze" cycled to the back.

## plan

### next

- [ ] render mouse
- [ ] render detailed maze: numbering, detected, goal
- [ ] stats : time, speed
- [ ] test wall following
- [ ] reorganize azem theme to be modular and extensible
- [ ] implement settings struct
- [ ] keyboard navigation
- [ ] build wasm with github actions instead of having it in the repo
- [ ] loading indication in index.html when wasm is being pulled
- [ ] introduce better algorithms
- [ ] brainstorm
  - [ ] input and output files
    - [ ] maze text files
    - [ ] compressed representations?
  - [ ] file management dependency
  - [ ] mms compatibile api
  - [ ] better debugging during mouse run
  - [ ] accurate simulation params
    - [ ] turn rate
    - [ ] slip
    - [ ] disturbances
    - [ ] sensor errors
  - [ ] simulate sensor inputs
  - [ ] remote debugging with actual mc and sensors
- [ ] optimizations
  - [ ] embedded jetbrains fonts are taking up almost all of the executable size.
  - [ ] optimize in memory representations
- [ ] app packaging for mac
- [ ] windows packaging?
- [ ] incremental, hot reloading with algorithms
- [ ] set up donations

### done

- [x] basic theme
- [x] basic maze loading and rendering
- [x] native builds (tested in mac)
- [x] web wasm builds
- [x] console logging

## big thanks to

- [ZSF : zig is super awesome](https://ziglang.org/zsf/) (for better or for worse i'm still living off my parents, if you can please go [donate them](https://ziglang.org/zsf/))
- mackorone : for creating the awesome piece of software that is [mms](https://github.com/mackorone/mms)
- david-vanderson : [dvui is awesome](https://github.com/david-vanderson/dvui) and david can get you out of any tough spot
- [foxnne : pixi codebase rocks](https://github.com/foxnne/pixi/tree/dvui)
