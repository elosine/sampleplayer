

//Welcome to Processing and the first part of our Sample Player GUI
//Step-by-step is not as easy to display in processing so I'll create a step, and then copy it and comment out previous steps

//First let's set up our basic sketch and OSC communication

//Import the OSC libraries

/*
import netP5.*;
import oscP5.*;

//Declare the main OSC machine and a NetAddress for sending to supercollider

OscP5 osc;
NetAddress sc;

void setup(){
  size(1000, 250);
  //Initialize the Osc machine and sc netaddress in setup
  osc = new OscP5(this, 12321);
  //OscP5 instance/constructor takes the context as first argument in this case 'this' or the root sketch
  //and our home port number which is an arbritary '12321' and consistant with the number I use in the ~proc netaddress in supercollider
  sc = new NetAddress("127.0.0.1", 57120);
  //NetAddress takes the arguments of destination ip address, 
  //in this case the default local host, and 57120 which is the default port number for the supercollider language side
}

void draw(){
  background(0);
  
}
*/

/*
//STEP 2

//Now let's request the index data from supercollider in draw

import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

void setup(){
  size(1000, 250);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
}

void draw(){
  background(0);
  //send an osc message in draw with the osc address "/getix" which will communicate with the OSCdef we made in supercollider
  OscMessage msg1 = new OscMessage("/getix"); //create a new OscMessage
  osc.send(msg1, sc); //send it to supercolllider, it will send once each draw frame
}

*/

/*
//STEP 3

//When the OSCdef \getix we set up in supercollider receives the "/getix" message from Processing
//it will immediately send back the index data from the bus to our Processing sketch with the address "/ix"
//We then need to create a receiver in this sketch, equivalent to a Processing version of OSCdef
//However OSC communication works differently in JAVA/Processing, or at least the syntax/structure is slightly different
//I will jump past a more standard way of receiving and responding to OSC messages and directly use the handy
//forwarding service OSC.plug
//You can learn more if you go to the oscP5 example, "oscP5plug"

//oscP5plug basically works a lot like OSCdef in Supercollider
//it listens for a particular OSC address and then forwards the message and its data to a specified function in your sketch
//so lets create the receiving function below at the bottom of the code

//next we'll set up the oscplug in setup

//Now if you have the code still running in supercollider and  run this sketch you should
//see the phasor value printed below in the Processing console

//Great job!

import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

void setup(){
  size(1000, 250);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
  //make the oscplugs to forward osc messages to appropriate functions
  //index location
  osc.plug(this, "ix", "/ix");
  //the first argument is the context, 2nd is the name of the function you are forwarding to, and 3rd the OSC address to listen for
}

void draw(){
  background(0);
  //send an osc message in draw with the osc address "/getix" which will communicate with the OSCdef we made in supercollider
  OscMessage msg1 = new OscMessage("/getix"); //create a new OscMessage
  osc.send(msg1, sc); //send it to supercolllider, it will send once each draw frame
}

//This is the function to receive index information from supercollider
//It is passed the single float argument 'val' which needs to be consistant with the message from supercollider
//It will look something like this - "/ix", 0.342344
void ix(float val){
  //Let's just print out the value for now
  println(val);
  
}
*/


//STEP 4
//Now, let's create a basic area for displaying our sample and a scrolling cursor
//we'll draw a simple rectangle for the sample background
//we'll animate a vertical line for the cursor
//we'll have to map the data from the 0.0 - 1.0 number to the length of the sample display for the cursor

//First, make the sample background, see in draw

//Next make a line for the cursor, see in draw below the background

//Next create a variable for the x portions of the cursor line

//Next modify the ix function that receives the index location from Supercollider
//to first map then change the cx variable to animate the cursor

import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

//variable for cursor animation
float cx = 50.0;

void setup(){
  size(1100, 250);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "ix", "/ix");
}

void draw(){
  background(100);
  OscMessage msg1 = new OscMessage("/getix"); 
  osc.send(msg1, sc); 
  
  //Sample Display Background
  noStroke();
  fill(0);
  rect(50, 50, 1000, 150);
  
  //Cursor
  strokeWeight(3);
  stroke(153,255,0);
  //basic cursor
  //line(50, 50, 50, 200);
  //cursor with x variable
  line(cx, 50, cx, 200);
}

void ix(float val){
//  println(val);
//Create a local float to map the incomming normalized index value
float ixtmp = map(val, 0.0, 1.0, 50.0, 1050.0);
//map takes the input to map, the input's low, the input's high, the lo of the range you wish to map to, the hi of the range you are mapping to
//in this case the beginning of the sample display, 50 and the end of the sample display 1050, or y(50) + width(1000)

//update cx to ixtmp
cx = ixtmp;

//et voila! your animated cursor synced to your buffer player
  
}

//We'll actually wrap up this segment here and tackle waveform display next time.