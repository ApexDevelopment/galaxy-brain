# About
This is an interpreter and interface for running [Brainf-ck code](https://en.wikipedia.org/wiki/Brainfuck). It is written in Lua.

## galaxy
`galaxy` is the interpreter itself. It can be found under `/src/galaxy`. It can be `require()`'d and used in your own code if you like. I have stress tested it and it seems to work fine. The general specifications for the machine are as follows:

- 8-bit unsigned integer cells
- 30,000-cells long memory tape
- No error on cell underflow or overflow
- No error on memory tape wraparound

## galaxy-brain
`galaxy-brain` is what I call the combination of the interpreter and the interface. The interface code can be found in `/src/main.lua` and is written using Love2D version 11.3. Just change into the src directory and run `love .` in your command line to launch it. Once running, drag and drop a `.b` or `.bf` (Brainf-ck) file onto the interface, and it will automatically create a new machine. Use the following controls:

| Key         | Command                 |
| ----------- | ----------------------- |
| Space       | Pause/unpause execution |
| Right Arrow | Run 1 instruction       |
| Up Arrow    | Speed up execution      |
| Down Arrow  | Slow down execution     |
| Ctrl+Z      | Input a null byte       |

Note that the Ctrl+Z command is the same on both Windows and Mac. If there is nothing in the input buffer and the interpreter hits an input command (`,`) it will stop execution until a byte is placed in the input buffer. In `galaxy-brain`, this is handled by waiting for keyboard input from the user. This is where the Ctrl+Z command comes in handy, since some BF programs use a null byte to signify an EOF.

## Important Note!
The interface is **designed for my experimentation** and **is not a typical BF interpreter interface**. For example, right now, there is no way to directly view the raw values being written to the output buffer. This is because I'm using this project as a way to experiment with getting the BF language to interact with "devices" using its I/O commands. As of writing this README, for example, the interface draws a green 256x256 square. This is a virtual "screen" that the BF program can draw to by outputting the number 2, followed by two bytes signifying XY coordinates, followed by three bytes representing RGB values for the color of the pixel to draw. For an example of this working, run `/src/code/mouse.b` in the interpreter to see BF code reading the position of the mouse in the 256x256 "screen" and then drawing a pixel at that position.

<sub>(Brain icon by Arjun Adamson from the Noun Project)</sub>