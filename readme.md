# azem

a cool multiplatform maze simulator written in zig.

initial goals are micromouse simulation, expanding to other simulation options is planned.

here is how it looks currently

![azem running in macos](https://i.imgur.com/Si1ueth.png)

## why

first of all i'm a very openionated person, that's one of the reasons i love open-source. if something is itching, then you can go break some stuff. when i'm trying the mms simulator (which is awesome and props to make for providing executables for all platforms, god what a legend), i wanted to make some changes to make the user experience a bit better and adding additional sim capabilities. then i found out he used qt for the gui. so... (long pause and a deep sigh). i went through the internet to find ways to build the project easily on my mac and dear lord. i already knew about the qt/cpp build ecosystem problem because of some other things i tried to fiddle with before.

another smoldering fire that was burning in me was to try the zig language which i was learning at the time of the project's inception, in a potentially usefull and cool application. and with many other motimations, this was born.

initially i didn't have much time, i just had a rough idea about what i wanted to do. i just yoinked the gui layout idea from mms and tried to recreate it with dvui in zig. went well to be honest. and rendering the maze with raylib was very cool.

## getting started

it's zig so you know the drill.

```bash
git clone https://github.com/thuvasooriya/azem.git
cd azem
zig build # will build for your platform and run the exe

zig build web # to run on web browser! yeah i know awesome right
```

## plan

### done

- [x] basic theme
- [x] basic maze loading and rendering
- [x] native and web compatibility (credits to zig and dvui)

### next

- render mouse
- test wall following
- decide on theme structure
- decide on settings structure
- when project structure is somewhat ok
  - implement tests for existing functions
  - brainstorm the rest and come back
- logging
- stats
  - [ ] time
  - [ ] speed
  - [ ] explored
- simulate solving algorithms
- file management dependency
- mms compatibility mode

### brainstorm

- [x] text representation of maze : + and . taken as corner
- [ ] understand project structure of pixi and mms
- first release functionality decide
- maze design
- mouse design
- input and output files
  - [ ] maze text files
  - [ ] compressed representations?
- api
- better debugging during mouse run
- proper docs - zig docs and zine

### long time goals

- dod
  - [ ] optimize in memory representation of maze
  - [ ] remove heap allocation wherever possible
- app packaging for mac
- windows packaging?
- incremental, hot reloading with algorithms
- donation
- github workflows
- accurate simulation params
  - [ ] turn rate
  - [ ] slip
  - [ ] disturbances
  - [ ] sensor errors
- simulate sensor inputs
- remote debugging with actual mc and sensors

## inspirations

- mms simulator
- maze solver raylib
- pixi project structure
- dvui examples

### big thanks to

- ZSF : zig is godlike (i'm living off my parents, if you can go donate them)
- mackorone : for creating the awesome piece of software that is mms
- david-vanderson : dvui is awesome
