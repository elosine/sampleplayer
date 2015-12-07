//Building a Sample Player, the sausage factory version
//GUI PART II - WAVEFORM DISPLAY
//You'll recognize the code below from our last session
//If we run it and have our supercollider code running we should see an animated cursor
//Now we need to create a visual waveform display
//We'll do 3 things:
////Send a message to supercollider requesting the waveform data
////Create an OSC receiver to recive the waveform data
////Visualize the waveform data in our sample window

//The workflow goes like this:
////Our processing sketch, let's call it proc, sends a  message like this: "/getwf", 0, 1000
////Supercollider, sc for short, receives this message and the OSCdef: \getwf responds to it by
////running the function ~wff with the arguments sent along '0, 1000': ~wff.value(0, 1000)
////Our ~wff function grabs the designated buffer, converts it to a float array, and resamples it to 1000 samples (as designated in the argument
////It then sends this array back to proc with the "/wavfrm" OSC address, something like this: "/wavfrm", 0.0004, 0.00041, 0.00042... + 997 more


//PART 1 - SEND A MESSAGE TO SUPERCOLLIDER REQUESTING THE WAVEFORM DATA
//let's first have a look at our supercollider code, the oscdef
/*

 //OSCdef for requesting waveform data
 OSCdef(\getwf, { |msg|
 var bufnum = msg[1].asInteger;
 var numpx = msg[2].asInteger;
 ~wff.value(bufnum, numpx);
 }, "/getwf");
 */

//We are expecting a message with the OSC address "/getwf"
//It needs a few arguments:
////the buffer number, which is a place holder for now but will be useful when we expand to multiple buffers
////and the number pixels width in our sample display area

//We also need to decide when/how we send the message
//For now, let's use mousepressed as a triger, any time our mouse is pressed on our sketch we'll request waveform data
//We add a mousePressed() function to our code

/*
import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

//variable for cursor animation
float cx = 50.0;

//sample display variables
float sw = 1000.0; //sample width

void setup() {
  size(1100, 250);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "ix", "/ix");
}

void draw() {
  background(100);
  OscMessage msg1 = new OscMessage("/getix"); 
  osc.send(msg1, sc); 

  //Sample Display Background
  noStroke();
  fill(0);
  rect(50, 50, sw, 150);

  //Cursor
  strokeWeight(3);
  stroke(153, 255, 0);
  //cursor with x variable
  line(cx, 50, cx, 200);
}

void ix(float val) {
  float ixtmp = map(val, 0.0, 1.0, 50.0, 1050.0);
  cx = ixtmp;
}

void mousePressed(){
  //When we press the mouse on our sketch
  //We send a request for waveform data from supercollider
  OscMessage msg2 = new OscMessage("/getwf"); //the OSCaddress our OSCdef in sc expects
  msg2.add(0); //the buffer number (useful later)
  //Let's make the width of our sample window a variable and add it here as an argument
  msg2.add(sw);
  //send it to supercollider
  osc.send(msg2, sc);
}
*/

//PART 2 - CREATE AN OSC RECEIVER TO RECEIVE THE WAVEFORM DATA
////Once we have sent sc a request for waveform data, it sends it right back to us
////Let's create a receiver function to collect the data
////We'll first have to modify our OSC set-up so it can handle larger chunks of data
////Then we'll create a receiving function
////Finally we'll create an oscplug to forward the waveform data to the function

import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

//variable for cursor animation
float cx = 50.0;

//sample display variables
float sw = 1000.0; //sample width

void setup() {
  size(1100, 250);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "ix", "/ix");
}

void draw() {
  background(100);
  OscMessage msg1 = new OscMessage("/getix"); 
  osc.send(msg1, sc); 

  //Sample Display Background
  noStroke();
  fill(0);
  rect(50, 50, sw, 150);

  //Cursor
  strokeWeight(3);
  stroke(153, 255, 0);
  //cursor with x variable
  line(cx, 50, cx, 200);
}

void ix(float val) {
  float ixtmp = map(val, 0.0, 1.0, 50.0, 1050.0);
  cx = ixtmp;
}

void mousePressed(){
  //When we press the mouse on our sketch
  //We send a request for waveform data from supercollider
  OscMessage msg2 = new OscMessage("/getwf"); //the OSCaddress our OSCdef in sc expects
  msg2.add(0); //the buffer number (useful later)
  //Let's make the width of our sample window a variable and add it here as an argument
  msg2.add(sw);
  //send it to supercollider
  osc.send(msg2, sc);
}