//Building a Sample Player, the sausage factory version

//SAMPLE PLAYER AND PHASOR BASED INDEXER

//We are going to use BufRd.ar as the ugen to play our samples
//However, we will make an independant 'sample-indexer' that will give us
//lots of freedom and capability later on as our project grows more complex
//Let's take a look at the basic sample player, BufRd.ar in Supercollider
BufRd.ar(numChannels, bufnum, phase);
//we'll concider arguments 2 and 3, bufnum and phase
//bufnum is the number of a buffer from which BufRd will read audio
//The phase argument is where in that buffer
//we are currently reading from in this frame/sample
//If I say 'cassette tape' or real-to-real, does this conjure any images for you?
//Well a motor pulls a magnetic tape across a fixed play head and the data on the tape is converted to an electric signal which eventually drives some speakers to make sound
//"/Users/jyang/GitHub/sampleplayer/casettetape.jpg"
//Now imagine unfurling the tape and fixing each end, and instead of the tape being dragged across the play head, you pick up the play head and drag it across the fixed tape.
"/Users/jyang/GitHub/sampleplayer/playhead.png"
//This is essentially what the 'phase' argument of BufRd does.  It drags the playhead/readposition across the tape/buffer.
//If we look at one of the examples from the BufRd help file:
{ BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b), 0, BufFrames.kr(b))) }.play;
//The Phasor.ar ugen is the machine that drags the playhead/read-position across the tape/buffer
//Phasor.ar is basically an audio rate ugen that cycles from 0.0 - 1.0 (or a range of your choice)
Phasor.ar(trig, rate, start, end, resetPos);
//Let's look at the rate agrument
//The way the phasor is set up in supercollider is by increment of change
//In other words, if the supercollider server is operating at a sample rate, (i.e., it performs operations 44100 times a second or once every 1/44100 seconds), the phasor will advance x amount each sample/frame.  It starts at 0.0 for example, advances amount x each sample, until it gets to 1.0, where it starts over at 0.0 again, in a cycle.
//This is the rate argument.
//So if we have a buffer that is y seconds long, and we are moving at at a rate of 1/44100, we'll have to move our playhead the amount of y/44100 each frame to get to 1 in y seconds.

//Now if we translate this to the digital domain with discrete samples, a 2 second buffer at a sample rate of 44100 has 88200 samples in it
//To playback the whole buffer, BufRd has to read from sample 0 to sample 88200 in 2 seconds.  If our server is running at 44100 frames a second we need to read 1 sample per frame to read the buffer through in 2 seconds. So the rate of our Phasor is 1.
//This seems like much ado about nothing but it will be good to have an understanding of what each of these arguments are and how they work for later when we use a single phasor to sync many different processes.
//Supercollider has a number of functions to help with this process and this is what you see in the BufRd example:
{ BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b), 0, BufFrames.kr(b))) }.play;
//This example will be reading from buffer b, in the second argument, and the rate is BufRateScale.kr(b).  BufRateScale(b) basically does the math for you, it figures out how many samples your buffer has, what sample rate the scServer is running at and gives an amount to move each frame.  If you add .poll to this ugen and run it, it should be '1';
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
{ BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b).poll, 0, BufFrames.kr(b))) }.play;
//Since we are playing the entire buffer from the beginning to the end, the start argument of Phasor is 0, and the end argument should be the total number of samples in the buffer.  Here again we can use a supercollider helper - BufFrames.kr(b).  This will give the total number of samples/frames in buffer b.
//So to tie up our analogy of the long tape loop with a moving playhead, if we have a very precise robot moving our playhead, it will move it x amount every 1/44100 seconds.  x is the rate, 1/44100 seconds is the frame or sample rate. And the length of the loop would, let's say it is 100meters long, would be BufFrames.
"/Users/jyang/GitHub/sampleplayer/tapeloop_phasor.png"

//So Phasor is our index or cursor into the buffer
//Typically you might make a synthDef to play back a buffer like this with the Phasor/index built in
SynthDef(\sampplay1, {
	arg buf, start, end;
	var samp, index;
	index = Phasor.ar(0, BufRateScale.kr(buf), start*BufFrames.kr(buf), end*BufFrames.kr(buf));
	samp = BufRd.ar(1, buf, index);
	Out.ar(0, samp);
}).add;
//In this example, the start and end arguments would be a number from 0-1.  If it was a 2 second sample, but you wanted to start half way through the sample, and play to 3/4 through the sample. You would start at frame 44100, and play until frame 66150, or 88200(BufFrames)*0.5 for start and 88200(BufFrames)*0.75 for end.

//Now in our project, we will make the indexer or phasor independant, in a separate SynthDef, and this will be very useful for syncing, making an animated GUI, and many other things we haven't thought of yet.  We'll use supercollider's convienent structure of control and audio busses as well as groups to manage this activity and make our project robust and expandable.

//Let's break out the indexer/phasor:
SynthDef(\indexer, {
	arg buf, spd=1, start=0, end=1, abus, kbus;
	var index, indexnorm;
	index = Phasor.ar(0, BufRateScale.kr(buf)*spd, start*BufFrames.kr(buf), end*BufFrames.kr(buf));
	indexnorm = index.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
	Out.ar(abus, index);
	Out.kr(kbus, indexnorm);
}).add;

//The first thing to notice from the two Out ugens is we are sending the phasor signal to private busses of our choice
//The sc bus system is analogous (no put intended) to an audio patch bay system
//You send audio out to a patch bay, and then you can patch it from there to any number of outputs
//SC has both audio and control busses, like modular synths where you can send an LFO out to a patch bay and then patch it in somewhere
//We are sending the index/Phasor straight out as an audio signal to a bus determined by the 'abus' argument
//This signal will be used by other synthdefs to playback or record or process buffers
//Now we are sending a modified phasor signal to a control bus.  This is a normalized version (the phasor output mapped to a value between 0.0 and 1.0), which will be useful for a wide variety of applications.  So the index/phasor is converted to a number between 0.0 and 1.0 and 'converted' to a control signal by sending it to a control bus.
//I also took this opportunity to add a 'spd' argument so you can play back at different speeds

//Now we have to modify our sample player SynthDef to use an external audio signal as its buffer indexer

SynthDef(\sampplay2, {
	arg idxbus, obs=0, buf, gate=1;
	var index, samp, env;
	env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
	index = In.ar(idxbus);
	samp = BufRd.ar(1, buf, index);
	Out.ar(obs, samp*env);
}).add;

//You see that the phasor based index has been replaced with a simple In.ar, which will read an audio signal from a bus.
//I've also taken the opportunity to add an envelope, more to start, stop, kill our synths (more on this later) and have made the outbus in Out.ar variable so we don't always have to send our sample playback to the left speaker.

//So to use our sample player it might look something like this:

//Boot the server
s.boot;
//load a soundfile into a buffer
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
//add our synthdefs to the server
SynthDef(\indexer, {
	arg buf, spd=1, start=0, end=1, abus, kbus;
	var index, indexnorm;
	index = Phasor.ar(0, BufRateScale.kr(buf)*spd, start*BufFrames.kr(buf), end*BufFrames.kr(buf));
	indexnorm = index.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
	Out.ar(abus, index);
	Out.kr(kbus, indexnorm);
}).add;
SynthDef(\sampplay2, {
	arg idxbus, obs=0, buf, gate=1;
	var index, samp, env;
	env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
	index = In.ar(idxbus);
	samp = BufRd.ar(1, buf, index);
	Out.ar(obs, samp*env);
}).add;
//start a phasor/index synth
a = Synth(\indexer, [\buf, b]);
//start a playback synth
c = Synth(\sampplay2, [\buf, b]);

//This won't work yet because there are a few missing pieces.
//So let's put it all together.

//First Groups
//The idea of groups can sometimes be a bit confusing.
//Groups have to do with the computing side of things and for our purposes can be thought of separate from audio
//Computers can only do one thing at a time (at least for the most part up until recently), but can do them very, very fast
//Digital audio at its root is just a lot of very fast math, but we have to specify what order to do calculations in
//If making a audio-rate index/phasor is a calculation and playing back audio from a buffer is a calculation
//To use the index in playing back a buffer, we have to tell the computer to calculate the index first then calculate the buffer reading/playback
//Groups help us with this
//By using groups, we can assure that certian calculations happen in a certian order that neatly (but easy to confuse) correspond with our audio processes.
//So we'll create 2 groups, one for the index synth to run in and one for the playback synth to run in,
//this way the index calculations will always be done before the playback calculations


~g0 = Group.new(s);
~g1 = Group.after(~g0);
s.queryAllNodes;

// ~g0 will be our index group and we use the syntax '.after' to add ~g1 after ~g0
//if you run s.queryAllNodes, you will see a post of the computing order

//The second loose end we need to tie up is our busses.  We didn't create any busses for our patch bay like system, so lets do this.

~ixabus = Bus.audio(s, 1);
~ixkbus = Bus.control(s, 1);

//we've created an audio bus to hold the audio signal from our index synth's phasor and a control bus for the normalized control signal the same synth is sending out

//Now can put it all together.  I've updated the variables to ~ versions.

//Boot the server
s.boot;
//Create groups for running our synths in the proper order
~g0 = Group.new(s);
~g1 = Group.after(~g0);
//Create busses to hold our phasor/index information
~ixabus = Bus.audio(s, 1);
~ixkbus = Bus.control(s, 1);
//load a soundfile into a buffer
~sbuf = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
//add our synthdefs to the server
SynthDef(\indexer, {
	arg buf, spd=1, start=0, end=1, abus, kbus;
	var index, indexnorm;
	index = Phasor.ar(0, BufRateScale.kr(buf)*spd, start*BufFrames.kr(buf), end*BufFrames.kr(buf));
	indexnorm = index.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
	Out.ar(abus, index);
	Out.kr(kbus, indexnorm);
}).add;
SynthDef(\sampplay2, {
	arg idxbus, obs=0, buf, gate=1;
	var index, samp, env;
	env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
	index = In.ar(idxbus);
	samp = BufRd.ar(1, buf, index);
	Out.ar(obs, samp*env);
}).add;
//start a phasor/index synth, add it to the ~g0 group, and send out the signal to the appropriate busses
~ixsynth = Synth(\indexer, [\buf, ~sbuf, \abus, ~ixabus, \kbus, ~ixkbus], ~g0);
//you notice Synth's 3rd argument is target, in our case the group ~g0
//start a playback synth, add it to the ~g1 group, and get the index signal from the appropriate bus
~playsynth = Synth(\sampplay2, [\buf, ~sbuf, \idxbus, ~ixabus], ~g1);

//Phew, seems like a lot of work for something we had going 9 hours ago!
//But these are important steps to give us a robust and expandable sample player/processor

//Next time - We'll start our GUI, by visualizing the index, and eventually have a waveform display of the sample.






