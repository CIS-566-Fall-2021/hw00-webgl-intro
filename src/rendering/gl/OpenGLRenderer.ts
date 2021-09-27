import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, progs: Array<ShaderProgram>, drawables: Array<Drawable>, color: Array<number>, 
    time: number, sea: number, mtn: number, frag: number, display: boolean) {
    let model = mat4.create();
    let viewProj = mat4.create();
    //let color = vec4.fromValues(1, 0, 0, 1);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    for (let i = 0; i < progs.length; ++i) {
      let prog = progs[i];
      prog.setModelMatrix(model);
      prog.setViewProjMatrix(viewProj);
      // prog.setGeometryColor(vec4.fromValues(color[0]/255, color[1]/255, color[2]/255, 1));
      prog.setTime(time);
      prog.setCamPos(vec4.fromValues(camera.position[0], camera.position[1], camera.position[2], 1.));
      prog.setSea(sea);
      prog.setMountains(mtn);
      prog.setFragments(frag);
      prog.draw(drawables[i]);
      if (display)
        prog.setPlanetAndMoon(1.);
      else 
        prog.setPlanetAndMoon(0.);
    }
  }
};

export default OpenGLRenderer;
