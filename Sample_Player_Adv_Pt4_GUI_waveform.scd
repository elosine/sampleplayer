//Building a Sample Player, the sausage factory version

//GUI PART II - WAVEFORM DISPLAY
//Run the code below to use with the updates in the processing sketch for waveform display

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
//function for converting and resampling buffer data for waveform display
~wff = { //the whole loadToFloatArray, wrapped into a function for ease of use
	arg buf, numpx;
	buf.loadToFloatArray(action:{
		arg array;
		var bufarray = array.copyRange(0, array.size-1);
		var newsampsize = numpx;
		var newsamplerate = (bufarray.size/newsampsize).round;
		var resampedArray = Array.newClear(newsampsize+1);
		var ct = 0;
		bufarray.do{ arg it, ix;
			if( ix%newsamplerate == 0, {
				resampedArray[ct] = it.asFloat;
				ct = ct+1;
			}); //end if statement: if( ix%newsamplerate == 0
		}; //end for loop bufarray.do{
		//Insert the osc address "/wavfrm" into the first (zeroith) slot of the resampled array resampedArray
		resampedArray = resampedArray.insert(0, "/wavfrm");
		//send to processing as a bundle
		~proc.sendBundle(0.0, resampedArray);  //the first argument, 0.0, is a time stamp, 0.0 will be asap
	}); //end b.loadToFloatArray(action:{
}; //end ~wff function
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
//OSCdef for requesting waveform data
OSCdef(\getwf, { |msg|
	var bufnum = msg[1].asInteger;
	var numpx = msg[2].asInteger;
	~wff.value(bufnum, numpx);
}, "/getwf");
)

// 3)
(
//start a phasor/index synth, add it to the ~g0 group, and send out the signal to the appropriate busses
~ixsynth = Synth(\indexer, [\buf, ~sbuf, \abus, ~ixabus, \kbus, ~ixkbus], ~g0);

//start a playback synth, add it to the ~g1 group, and get the index signal from the appropriate bus
~playsynth = Synth(\sampplay2, [\buf, ~sbuf, \idxbus, ~ixabus], ~g1);
)







