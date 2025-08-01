# azem

a cool multiplatform maze simulator written in zig.

initial goals are micromouse simulation, expanding to other simulation options is planned.

here is how it looks currently

![azem running in macos](https://i.imgur.com/pypv09P.png)

## why

i'm a very openionated person, that's one of the reasons i love open-source. if something is itchy, then you can go break some stuff. when i'm trying the mms simulator (which is awesome and props to mack for providing executables for all platforms, god what a legend), i wanted to make some changes to make my experience a bit better and add some additional sim capabilities. then much to my disappointment, i found out it uses qt for the gui. hmm... (long pause and a deep sigh). i went through the internet to find ways to build the project easily on my mac and dear lord... i already knew about the qt/cpp build ecosystem problem because of some other things i tried to fiddle with before. combined with the licensing of qt i just couldn't.

another smoldering fire that was burning in me was to try the zig language which i was learning at the time of the project's inception, in a potentially usefull and cool application. and with many other motivations, azem was born.

> yeah if you haven't figured already, azem is just the letter `m` on the word "maze" cycled to the back.

initially i didn't have much time, i just had a rough idea about what i wanted to do. i just yoinked the gui layout idea from mms and tried to recreate it with dvui in zig. went well to be honest. and rendering the maze with raylib was very cool. now SDL3 backend is being used because of some limitations of raylib backend. much of app architectural decisions were also inspired from [pixi](https://github.com/foxnne/pixi/tree/dvui) (another awesome zig project by an awesome person currently being migrated to dvui). this is almost the 4th rewrite of this application. this will evolve with dvui and zig so don't expect a finished product anytime soon.

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
- [x] native and web compatibility
- [x] console logging

### next

- render mouse
- test wall following
- decide on theme structure
- decide on settings structure
- when project structure is somewhat ok
  - implement tests for existing functions
  - brainstorm the rest and come back
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

- ZSF : zig is godlike (for better or for worse i'm still living off my parents, if you can please go donate them)
- mackorone : for creating the awesome piece of software that is mms
- david-vanderson : dvui is awesome
- foxnne : pixi codebase rocks
