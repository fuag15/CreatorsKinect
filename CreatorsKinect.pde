import toxi.physics2d.constraints.*;
import toxi.physics.*;
import toxi.physics.constraints.*;
import toxi.physics2d.behaviors.*;
import toxi.physics2d.*;
import toxi.geom.*;

import SimpleOpenNI.*;

import codeanticode.glgraphics.*;
import javax.media.opengl.*;
import java.util.*;

KinectManager kinectManager;
HandTracker handTracker;

GLGraphics renderer;
static GLTexture dropshadowTexture;
static GLTexture defaultTexture;

PImage[] staticImages;
int staticImageIndex = 0;

PFont infoFont;
GLTexture creatorsTag;
int hashtagStep = 0;
static final int HASHTAG_FADE_TIME = 960;
static final int HASHTAG_SIZE = 10;
int hashtagPosition = 0;
boolean showHashtag = true;

PhotoArranger photoArranger;

boolean simulateFreeze = false;
boolean shuttingDown = false;
boolean restarting = false;
int shutdownTimer = 0;
static final int SHUTDOWN_TIME = 60;

String watchdogFile = "/tmp/watching-the-clock";
String settingsFile = "settings.conf";
HashMap<String, String> settings;

void setup() {
  size(screenWidth, screenHeight-1, GLConstants.GLGRAPHICS);
 
  // Populate default settings
  settings = new HashMap<String, String>();
  settings.put("feed-url", "http://localhost:8080/tag/creators");
  settings.put("feed-update-period", "1000");
  settings.put("default-logo", "default.png");
  settings.put("hashtag-image", "creators-tag.png");
  settings.put("kinect-near", "2400");
  settings.put("kinect-far", "3600"); 
  settings.put("kinect-min-force", "0.005");
  settings.put("kinect-max-force", "0.03");
  settings.put("physics-drag", "0.2");
  settings.put("watchdog-file", "/tmp/watching-the-clock");
  
  // Load settings from file
  String[] settingsLines = loadStrings(settingsFile);
  if(settingsLines != null && settingsLines.length > 0) {
    for(int i=0; i<settingsLines.length; i++) {
      String key, value;
      String[] split = split(": ", settingsLines[i]);
      if(split.length > 1) {
        key = split[0].trim();
        value = split[1].trim();
        settings.put(key, value);
      }  
    }
  }
  
  watchdogFile = settings.get("watchdog-file");
 
  kinectManager = new KinectManager(this);
  handTracker = new HandTracker(this);
 
  generateStatic();
 
  background(200,0,0);
  //size(kinect.depthWidth(), kinect.depthHeight());
  
  infoFont = createFont("Courier Bold", 12);
  textFont(infoFont);
  
  creatorsTag = new GLTexture(this, settings.get("hashtag-image"));

  photoArranger = new PhotoArranger(this);
  
  frameRate(45);

  // Stop tearing
  GLGraphics pgl = (GLGraphics) g; //processing graphics object
  GL gl = pgl.beginGL(); //begin opengl
  gl.setSwapInterval(1); //set vertical sync on
  pgl.endGL(); //end opengl
}

void draw(){
  //println(frameRate);
  keepAlive();
  background(0);
  if(frameCount % 3 == 0) staticImageIndex = (int)random(0,staticImages.length);
  image(staticImages[staticImageIndex], 0,0);
  
  /*
  if(second() < 30)          photoArranger.setMode(2);
  else if(minute() % 2 == 0) photoArranger.setMode(3);
  else                       photoArranger.setMode(4);
  */
  photoArranger.setMode(2);
  
  kinectManager.update();
  handTracker.update();
  
  /*
  ArrayList<Vec3D> handPositions = new ArrayList<Vec3D>();
  handPositions.add(new Vec3D(kinectManager.handPosition.x*2, kinectManager.handPosition.y*2, 0));
  photoArranger.updateHands(handPositions);
  */
 
  
  //pushMatrix();
  //scale(2);
  //stroke(255,0,128);
  kinectManager.draw();
  //popMatrix();
  
  handTracker.draw();
  
   renderer = (GLGraphics)g;
  renderer.beginGL();
    photoArranger.update();
    photoArranger.draw();
  renderer.endGL(); 
  
  if(showHashtag) drawHashtag();
  
  
  if(shuttingDown || restarting) {
    fill(0,0,0, shutdownTimer / (float)SHUTDOWN_TIME * 255);
    rect(0,0,width,height);
    shutdownTimer++;
    if(shutdownTimer > SHUTDOWN_TIME) {
      if(shuttingDown) safeShutdown();  
      else if(restarting) safeRestart();
    }
  }
  //text(frameRate, 20,20);
  
}

void keyPressed() {  
  if(key == ']') photoArranger.setGridDimensions(photoArranger.gridRows + 1, photoArranger.gridCols);
  if(key == '[') photoArranger.setGridDimensions(photoArranger.gridRows - 1, photoArranger.gridCols);
  if(key == '\'') photoArranger.setGridDimensions(photoArranger.gridRows, photoArranger.gridCols + 1);
  if(key == ';') photoArranger.setGridDimensions(photoArranger.gridRows, photoArranger.gridCols - 1);
  
  if(key == '.') kinectManager.depthThreshold += 20;
  if(key == ',') kinectManager.depthThreshold -= 20;
  
  switch(key) {
    case '1':
      photoArranger.setMode(1);
      break;
    case '2':
      photoArranger.setMode(2);
      break;
    case '3':
      photoArranger.setMode(3);
      break;
    case '4':
      photoArranger.setMode(4);
      break;
    case '5':
      photoArranger.setMode(5);
      break;
    case 'f':
      ArrayList<Photo> photosCopy = (ArrayList<Photo>)photoArranger.photos.clone();
      Collections.shuffle(photosCopy);
      for(int i=0; i<60; i++) {
        photosCopy.get(i).flipSoon = true;  
        photosCopy.get(i).bounceSoon = true;
      }
      break;
    case 's':
      simulateFreeze = !simulateFreeze;
      break;
    case 'q':
      shuttingDown = true;
      break;
    case 'r':
      restarting = true;
      break;    
  }
}

void generateStatic() {
  staticImages = new PImage[10];
  int gray = 0;
  for(int i=0; i<staticImages.length; i++) {
    staticImages[i] = createImage(width, height, RGB);
    staticImages[i].loadPixels();
    for(int p=0; p<staticImages[i].pixels.length; p++) {
      gray = (int)random(0,100);
      staticImages[i].pixels[p] = color(gray, gray, gray);
    }
    staticImages[i].updatePixels();
  }  
}

void drawHashtag() {
  hashtagStep++;
  if(hashtagStep > HASHTAG_FADE_TIME) {
    hashtagStep = 0;
    hashtagPosition = (int)random(0,4); 
  }
  
  if(hashtagStep < HASHTAG_FADE_TIME) {
    //float alpha = (sin(frameCount/50.)+2)*60;
    float alpha = 0;
    if(hashtagStep < 360)
      alpha = tweenEaseInOut(hashtagStep, 360, 0, 240);
    else if(hashtagStep < HASHTAG_FADE_TIME-360)  
      alpha = 240;
    else
      alpha = tweenEaseInOut(HASHTAG_FADE_TIME-hashtagStep, 360, 0, 240);
    
    float hashtagOffset = HASHTAG_SIZE/200. * 150;
    
    pushMatrix();
    switch(hashtagPosition) {
      case 0:
        translate(hashtagOffset, height);
        rotate(radians(-90));
        translate(-30,-30);
        break;
      case 1:
        translate(width-creatorsTag.height, height);
        rotate(radians(-90));      
        break;
      case 2:
        translate(0,hashtagOffset);
        translate(-30,-30);
        break;
      case 3:
      default:
        translate(width - creatorsTag.width, height - creatorsTag.height);
        break;
    }
    colorMode(RGB);
    tint(alpha,alpha,alpha, alpha);
    //image(creatorsTag,0,0);
    creatorsTag.render();
    tint(1,1,1,1);
    popMatrix();
  }
}

void keepAlive() {
  if(frameCount % 10 == 0 && !simulateFreeze) {
    String[] out = {"Alive", str((int)(System.currentTimeMillis() / 100L))}; 
    saveStrings(watchdogFile, out);
  }
}

void safeRestart() {
  String[] out = {"Restart", str((int)(System.currentTimeMillis() / 100L))};
  saveStrings(watchdogFile, out);
  exit();  
}
void safeShutdown() {
  String[] out = {"Shutdown", str((int)(System.currentTimeMillis() / 100L))};
  saveStrings(watchdogFile, out);
  exit();
}
