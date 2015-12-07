//Building a Sample Player, the sausage factory version

//STARTING THE GUI - VISUALIZE THE INDEX AND WAVEFORM DISPLAY
//You may have noticed last time that we created a control version of our phasor/index.
//We took the phasor signal, normalized it to a number between 0.0 and 1.0 and sent it out a control bus
//But we never used it
SynthDef(\indexer, {
	arg buf, spd=1, start=0, end=1, abus, kbus;
	var index, indexnorm;
	index = Phasor.ar(0, BufRateScale.kr(buf)*spd, start*BufFrames.kr(buf), end*BufFrames.kr(buf));
	--->>> indexnorm = index.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
	Out.ar(abus, index);
	--->>> Out.kr(kbus, indexnorm);
}).add;

~ixkbus = Bus.control(s, 1);
~ixsynth = Synth(\indexer, [\buf, ~sbuf, \abus, ~ixabus, --->>> \kbus, ~ixkbus], ~g0);

//This is because we'll use it today for our GUI.
//The plan is to create an on-demand data service.
//We'll create an OSCdef, remember this is a responder/listener that is waiting for a certian tag/address
//and will respond to that tag/address with an action, much like a virtual instrument plugin will wait for a midi command and respond with sound
//By on-demand, I mean the index information, current location, will be available by request, only when asked for, and won't continually push this data out.
//This is useful because other applications operate at different clocks and it will be good for our GUI
//to get the index information at the speed and pace that is most apporpriate for our GUI environment(Processing)

//First, lets look at how to query data from a control bus
//Remember, the normalized version of our index/phasor location is going out to a control bus
//We can get it's current location by querying the bus
//Before we do anything, let's grab the code from last session and run it to have a live signal to work with


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

//You don't need to run the play synth just yet, but I'll include it here for later
//start a playback synth, add it to the ~g1 group, and get the index signal from the appropriate bus
~playsynth = Synth(\sampplay2, [\buf, ~sbuf, \idxbus, ~ixabus], ~g1);

//to get the current value of a control bus we'll use the .get instance method from the Bus class of supercollider
// bus.get( {some function to run using bus data which will be the first argument} );
~ixkbus.get({|val| val.postln});
//if you keep evaluating the above line, you should see a number between 0.0 and 1.0, the normalized location of our phasor

//Now let's create our OSCdef, that will send out the information from the control bus
//First we'll create a NetAddr, a destination for the index information
~proc = NetAddr("127.0.0.1", 12321);
//the hostname is just my localhost ip because I'll be using it with a gui running on this same machine
//the port will be the one I use when I initialize OSC in my processing sketch
//In our OSCdef well run the above '.get' method but instead of posting the busses value, we'll send it to processing, (we can post it to, for verification)
OSCdef(\getix, {
	~ixkbus.get({ |val|
		val.postln;
		~proc.sendMsg("/ix", val.asFloat);
	});
}, "/getix");

//You see the ~ixkbus.get code is similar to the line above: ~ixkbus.get({|val| val.postln});
//we've just expanded it into several lines and in addition to posting, 'val.postln'
//there is this line:
~proc.sendMsg("/ix", val.asFloat);
//This code sends the index value from the control bus ~ixkbus as an OSC message with the tag "/ix", so we'll need to create a receiver in Processing that will look for "/ix"

//So lets turn to Processing and grab this data
//But before we do this, I'll compile the supercollider code so far, below and you can recompile and run the code below


// 1) Boot the server
s.boot;
(
// 2) Run this code:
//Make a net address for sending messages to our Processing GUI sketch
~proc = NetAddr("127.0.0.1", 12321);
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
//OSCdef for sending out index data on demand
OSCdef(\getix, {
	~ixkbus.get({ |val|
		val.postln;
		~proc.sendMsg("/ix", val.asFloat);
	});
}, "/getix");
)

// 3)
//start a phasor/index synth, add it to the ~g0 group, and send out the signal to the appropriate busses
~ixsynth = Synth(\indexer, [\buf, ~sbuf, \abus, ~ixabus, \kbus, ~ixkbus], ~g0);

//You don't need to run the play synth just yet, but I'll include it here for later
//start a playback synth, add it to the ~g1 group, and get the index signal from the appropriate bus
~playsynth = Synth(\sampplay2, [\buf, ~sbuf, \idxbus, ~ixabus], ~g1);







