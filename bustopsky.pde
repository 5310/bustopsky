Cloud c[] = new Cloud[10];
int d = 50;

color clight, cdark; 
float time = 0; // 0 ~ 2*PI (multiples)
int weather = 0; // 0 ~ 9

Sun sun = new Sun();
Moon moon = new Moon();
int starc = 500;
Star[] stars;

void setup() {

  size(512, 160);
  frameRate(8);
  smooth();

  // populate cloud array
  float distance = 0;
  for (int i = 0; i < c.length; i++) {
    distance += random(d*5);
    c[i] = new Cloud(distance, random(height*0.0+d, height*0.6), random(1, 3));
  }

  // stars are center
  stars = new Star[starc];
  for (int i = 0; i < stars.length; i++)
    stars[i] = new Star();
}

void draw() {

  //time-keeping
  cycle();

  //paint the sky
  sky();
  
  //change weather
  changeWeather();

  // draw and refresh clouds
  for (int i = 0; i < c.length; i++) {
    c[i].draw();
    //NOTE: maybe I should methodify the following?
    if (c[i].dead)
      c[i] = new Cloud(width, random(height*0.0+d, height*0.6), random(1, 3));
  }

  // give me RED
  redden();
  
}

void cycle() {
  time+=0.005;
  time%=24;
  clight = color(255 - abs(255*sin(time)));
  cdark = color(abs(255*sin(time)));
}

void redden() {
  loadPixels();
  for (int i = 0; i < width*height; i++)
    pixels[i] = color(red(pixels[i]), 0, 0);
  updatePixels();
}

class Cloud {

  float x, y, s;
  int r, n;
  float[] radii;
  float[] offset;
  float lt, rt;

  boolean dark, dead;

  Rain[] drops;
  float dropr;

  float rand;

  Cloud(float _x, float _y, float _s, int _r, int _n, int seed) {
    x = _x;
    y = _y;
    s = _s;
    r = _r;
    n = _n;
    randomSeed(seed);
    seed();
  }
  Cloud(float _x, float _y, float _s) {
    x = _x;
    y = _y;
    s = _s;
    r = 50;
    n = 5;
    seed();
  }

  void seed() {
    radii = new float[n];
    offset = new float[n];
    dark = false; 
    dead = false;

    drops = new Rain[0];
    dropr = 3;

    for (int i = 0; i < n; i++) {
      radii[i] = random(5, r);
      if (i==0)
        offset[i] = radii[i]/2;
      else
        offset[i] = random(5, radii[i]/2);
    }

    float[] totes = new float[n];
    float sum = offset[0];
    for (int i = 1; i < n; i++) {
      sum += offset[i];
      totes[i] = sum + radii[i]/2;
    } 
    rt = max(totes);

    sum = offset[0];
    for (int i = 1; i < n; i++) {
      sum += offset[i];
      totes[i] = sum - radii[i]/2;
    } 
    lt = min(totes);

    rand = random(0, 5);
  }

  void draw() {
    if (dead)
      return;

    pushStyle();
    float sum;

    // stroke
    sum = 0;
    strokeWeight(10);
    stroke(cdark);
    for (int i = 0; i < n; i++) {
      sum += offset[i];
      arc(x+sum, y, radii[i], radii[i], PI, 2*PI);
    }

    // baseline
    line(x+lt, y, x+rt, y);

    // fill
    sum = 0;
    noStroke();
    fill(clight);
    for (int i = 0; i < n; i++) {
      sum += offset[i];
      arc(x+sum, y, radii[i], radii[i], PI, 2*PI);
    }

    popStyle();

    // move
    x -= s;
    // weather
    rain();
    strike();

    // out of sight out of mind
    if (x < - n*r/2)
      dead = true;
  }

  void rain() {
    
    //spawn drops
    if (weather > 0 && (frameCount+(int)rand*10)%(10-weather) == 0)
      if (drops.length <= 20) {
        Rain tempdrop = new Rain(x+lt, x+rt, y, s, random(2, dropr));
        drops = (Rain[])append(drops, tempdrop);
      }

    //respawn drops
    if (drops.length > 0) {
      Rain[] tempdrops = new Rain[0];
      for (int i = 0; i < drops.length; i++) {
        drops[i].draw();
        if (!drops[i].dead)
          tempdrops = (Rain[])append(tempdrops, drops[i]);
      }
      drops = tempdrops;
    }
    
  }

  void strike() {
    if((int)random(1000-weather*100) == (int)rand*10)
      lightning(x+(rt+lt)/2, y, 0);
  }
}

void changeWeather() {
  if (weather == 0) {
    if ((int)random(0, 7) == 0)
      weather += (int)random(-1.1, 1.1);
  } else {
    if ((int)random(0, 1) == 0)
      weather += (int)random(0, 1.1);
    if ((int)random(0, 3) == 0)
      weather += (int)random(-1.1, 0);
  }
  if  (weather == 9)
    if ((int)random(0, 30) == 0)
      weather= 0;
      
  if (weather < 0)
    weather = 0;
  if (weather > 9)
    weather = 9;
}

void lightning(float _x, float _y, int _d) {
  float x = _x, y = _y;
  for (int i = _d ; i < 10 ; i++) {
    if (i > 2 && (int)random(10) == 0)
      lightning(x, y, i);
    pushStyle();
    stroke(255);
    strokeWeight(4-i/3);
    line(x, y, x+=random(-width/12, width/12), y+=random(height/10));
    popStyle();
  }
}

class Rain {

  float x, y;
  float d;
  float s, g = 10, v = 10;
  boolean tail = false;
  int r;
  boolean dead;

  Rain(float _x, float _y, float _s, int _r) {
    x = _x;
    y = _y;
    s = _s;
    r = _r;
    dead = false;
  }
  Rain(float _xlt, float _xrt, float _y, float _s, float _r) {
    x = random(_xlt, _xrt);
    y = _y;
    s = _s;
    r = (int)_r;
    dead = false;
  }

  void draw() {
    if (dead)
      return;

    pushStyle();
    pushMatrix();

    translate(x, y);
    rotate(atan2(s, v));

    // peak
    noStroke();
    fill(cdark);
    float t = 1.73205081;
    triangle(0, 0, r, t*r, -r, t*r);
    
    // bowl
    float u = 2*pow(pow(t*r/3, 2) + pow(r, 2), 0.5);
    ellipse(0, t*r/3*4, u, u);

    // line
    if (tail) {
      stroke(0);
      strokeWeight(2);
      line(0, 1, 0, -v*s);
    }

    popMatrix();
    popStyle();

    y += v;
    if (v<=g)
      v += 1;

    x -= s;

    if (y > height*1.5)
      dead = true;
  }
}
void sky() {
  pushStyle();
  background(clight);
  for (int i = 0; i < stars.length; i++)
    stars[i].draw();
  sun.draw();
  moon.draw();
  stroke(clight);
  for (int i = 0 ; i < 7; i++) {
    strokeWeight(10-i*1.5);
    line(0, height-i*10, width, height-i*10);
  }
  popStyle();
}

class Sun {
  float x, y;
  float r;

  Sun() {
    x = -100;
    y = -100;
    r = 75;
  }
  void draw() {
    pushStyle();
    drawBeam(0);
    drawBeam(2);
    drawBeam(4);
    strokeWeight(5);
    stroke(cdark);
    fill(255);
    ellipse(x, y, r, r);
    popStyle();
    x = map((time+PI/2)%(PI), 0, PI, -width/2-r, width*1.5+r)-r;
    y = map(abs(sin(time+PI/2)), 0, 1, height*3, 0)+r/2;
  }
  void drawBeam(int o) {
    float m = 10;
    pushStyle();
    noFill();
    strokeWeight(3);
    stroke(255, 255*(9-((frameCount+o)%10))/9);
    ellipse(x, y, r*(1+((frameCount+o)%10)/m), r*(1+((frameCount+o)%10)/m));
    popStyle();
  }
}

class Moon {
  float x, y;
  float r;
  int phase;

  Moon() {
    x = -100;
    y = -100;
    r = 75;
    phase = 7;
  }
  void draw() {
    pushStyle();
    strokeWeight(5);
    stroke(255);
    fill(255);
    ellipse(x, y, r, r);
    drawPhase();
    popStyle();
    x = map((time+PI)%(PI), 0, PI, -width/2-r, width*1.5+r)+r;
    y = map(abs(cos(time+PI/2)), 0, 1, height*3, 0)+r/2;
  }
  void drawPhase() {
    if (time%PI < 0.0052) {
      phase++;
      phase%=8;
    }
    strokeWeight(6);
    stroke(clight);
    fill(clight);
    switch(phase) {
    case 0:
      break;
    case 1:
      noStroke();
      arc(x, y, r+6, r+6, -PI/3, PI/3);
      arc(x+(r+6)/2, y, r+6, r+6, PI*2/3, PI*4/3);
      break;
    case 2:
      noStroke();
      arc(x, y, r+6, r+6, -PI/2, PI/2);
      break;
    case 3:
      ellipse(x+(r/10)/2, y, r*0.9, r*0.9);
      break;
    case 4:
      ellipse(x, y, r, r);
      break;
    case 5:
      ellipse(x-(r/10)/2, y, r*0.9, r*0.9);
      break;
    case 6:
      noStroke();
      arc(x, y, r+6, r+6, PI/2, PI*3/2);
      break;
    case 7:
      noStroke();
      arc(x, y, r+6, r+6, PI*2/3, PI*4/3);
      arc(x-(r+6)/2, y, r+6, r+6, -PI/3, PI/3);
      break;
    }
  }
}

class Star {
  float x, y;
  int type;

  Star() {
    x = random(width);
    y = random(height);

    seedType();
  }

  void seedType() {
    float rand = random(1, 10);
    if (rand <= 10)
      type = 3;
    if (rand <= 9)
      type = 2;
    if (rand <= 8)
      type = 1;
    if (rand <= 1)
      type = 0;
  }

  void draw() {
    pushStyle();
    stroke(255);
    strokeWeight(1);
    fill(255);
    int flick;
    if ((frameCount+(int)random(200))%200 == 0)
      flick = 1;
    else
      flick = 0;
    if ((int)random(50000) == 0)
      type = 0;
    switch(type+flick) {
    case 0:
      typeX();
      break;
    case 1:
      typeA();
      break;
    case 2:
      typeB();
      break;
    case 3:
      typeC();
      break;
    default:
      typeD();
      break;
    }
    popStyle();
  }
  void typeX() {
    line(x, y, x-height, y+height);
    seedType();
  }
  void typeA() {
    point(x, y);
  }
  void typeB() {
    point(x, y+1);
    point(x, y-1);
    point(x+1, y);
    point(x-1, y);
  }
  void typeC() {
    point(x, y);
    point(x+1, y+1);
    point(x-1, y-1);
    point(x+1, y-1);
    point(x-1, y+1);
  }
  void typeD() {
    point(x, y+1);
    point(x, y-1);
    point(x+1, y);
    point(x-1, y);
    point(x, y+2);
    point(x, y-2);
    point(x+2, y);
    point(x-2, y);
  }
}

