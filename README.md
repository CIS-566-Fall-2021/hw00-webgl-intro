# HW 0: Noisy Planet Part 1 (Intro to Javascript and WebGL)

**Author: Ashley Alexander-Lee**

## Running the Code

1. [Install Node.js](https://nodejs.org/en/download/)

2. Using a command terminal, run `npm install` in the root directory of your project to download dependencies.

3. Run `npm start` and then go to `localhost:5660` in your web browser.

## Description
This introductory project for CIS566 (Procedural Graphics) involved experimentation with Typescript and WebGL to produce an animated cube decorated with procedural noise. 

![Cube Animation Preview](/images/cis566-hw0-screenshot-long.png)

## Implementation 
I averaged three 3D Perlin Noise functions together at different frequencies and used the resulting value to pick a color from a gradient. These colors are based on the user's input color, and vary in transparency. The further from the camera z-position the fragments are, the more faded the noise becomes. I also have a control to turn on or off animation, which will move each vertex along a sine wave in the direction of its normal.

Live Demo: https://asalexan.github.io/hw00-webgl-intro/

![Cube Animation Demo](/images/cis566-hw0-3.gif)
