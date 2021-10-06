# CIS 566 Project 1: Noisy Planets
Name : Samantha Lee
PennKey : smlee18

Inspiration: https://www.youtube.com/watch?t=596&fbclid=IwAR3E0nGlTbzzqL5nk320UExC5RfclXHhQVIL6G6-w6qT0cBbhPhyh8OwttQ&v=zlZR8nePEOY&feature=youtu.be&ab_channel=PratulDesigns

I saw this clip on a compilation of satisfying 3D renders and thought it would be cool to do something like it!

Live Demo: https://18smlee.github.io/hw00-webgl-intro/

## Cylinders
I first started by appling the opRepLim to a block of cylinders and smooth subtracted it from the floor plane. Then I added the same block of cylinders with a slightly smaller radius to make it appear as though they were coming out of holes in the floor. Next, I added a "dynamic height" to each cylinder position's y component. I calculated the dynamic height with a transformed cosine function on the x and z directions to give it the angled wave look. 

## Pendulum
The pendulum is created with a sphere and a cylinder smooth blended together. Currently the animation is bit hacky - I applied a power curve to the pendulum's y position and a corresponding cosine function to the pendulum's z position to mimick a swinging motion. Later I hope to implement the motion of a pendulum based on the actual physics of the pendulum. 
