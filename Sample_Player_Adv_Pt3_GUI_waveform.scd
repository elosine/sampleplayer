//Building a Sample Player, the sausage factory version

//GUI PART II - WAVEFORM DISPLAY
//Let's begin by thinking about an audio buffer and how the computer sees it and stores it
//In the digital domain, a sound is basically a very large table of amplitude values, one for each sample
//So if we wanted to create a visual display, a waveform display, of our buffer,
//We could just plot a version of this table
//However, most digital audio programs, including supercollider, organize this large table
//into its own particular format and organization
//Buffers are essentially a data type not unlike int and float etc. and require a certian way of storing and handling
//So to create a visual display of a buffer we need to do a few things.
//We need to copy and convert the buffer into a more familiar format, that of a float array.
//Then we need to resample the large array into a size more suited to our Processing sketch. (last I checked, there isn't a monitor with a 44100 pixel resolution)
//Supercollider provides some helpers to convert a buffer to a float array. We'll use the function 'loadToFloatArray'
//Let's do this offline in an isolated example and then incorporate this into our overall code
//First boot the server and load a soundfile into a buffer:
s.boot;
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
//b = Buffer.read(s, if you want to load your own sound file, put the path to a soundfile from your drive here);
//you can drag and drop your sound file onto this ide and it will print out the path
//Then we'll run loadToFloatArray on this buffer.
//the method loadToFloatArray will perform an action upon making the float array
//we'll be performing all of our tasks in this action which takes the form of a function:
b.loadToFloatArray( action:{ do everything here } );
//the action has as its first argument the converted buffer, we'll convert and print out the size of the array
b.loadToFloatArray(action:{arg array; array.size.postln});
//my buffer contains 188893 samples or about 4 and 1/4 seconds worth of audio
//now that we've converted the buffer to a float array lets copy it and prepare it for resampling
//we'll resample the 188893 samples into 1000 or the length of our sample display area of our processing gui
b.loadToFloatArray(action:{
	arg array;
	//make a copy of the array for resampling, call it bufarray
	var bufarray = array.copyRange(0, array.size-1);
	//we have to calculate a new sample rate
	//so if we are going to only take 1000 samples, well need to take one sample
	//every 189 samples or the total number of samples in the buffer(188893)/the new sample size (1000)
	var newsampsize = 1000; //the new sample size for waveform display or number of pixels in the sample display area of our Processing sketch
	var newsamplerate = (buffarray.size/newsampsize).round;
	//the new sample rate will be the buffarray.size, which is the total number of samples in the original buffer divided by the new sample size.  We are rounding off into an integer because we will run a modulo on this which will be cleaner with an integer
	//create a new empty array to store the resampled array into
	var resampedArray = Array.newClear(newsampsize+1); //we add one slot to the array because we'll need to include the OSCaddress in the array, which I'll explain later
});

//Next we'll run a for loop on the larger buffer array and grab a sample at the new sample rate by using modulo
//Let me review how for loops work in supercollider, if this is old hat for you just skip ahead
//A for loop is executed in supercollider by the .do method
10.do{"ten".postln};
//Each do function has some built in arguments
//If your source is just an amount as the 10 in my example,
//the first argument will be the index number that you are on in the loop:
10.do{arg ix; ix.postln};
//For loops can also accept arrays as sources, in this case there are two built in arguments,
//the first is the current actual item from the array, the second is then the index number:
a = ["a", "b", "c", "d", "e", "f", "g"];
a.do{arg it, ix; it.postln; ix.postln};

//So getting back to our buffer conversion and resample function
//We'll run a for loop on the large float array from the converted buffer called bufarray
//We'll populate the new, smaller resampled array resampedArray with one value from the large buffer array every 'newsamplerate' samples, in other words
//We'll only grab one sample every 'newsamplerate' samples and store it into the new resampedArray
//In my particular case, I'll take one sample every 189 samples and stick it into the reaampedArray for a total of 1000 samples + 1 which we'll get to later
//to accomplish this we'll use modulo
//we'll modulo the ix of our for loop, which will count through every sample of our original buffer
//we'll modulo the ix by the 'newsamplerate' and only take a sample when ix%newsamplerate = 0,
//giving us one sample every 'newsamplerate' samples
//I'm guessing there are better ways to do this, but this seems to work ok
//I'll copy and consolodate the above code and add below:
b.loadToFloatArray(action:{
	arg array;
	var bufarray = array.copyRange(0, array.size-1);
	var newsampsize = 1000;
	var newsamplerate = (buffarray.size/newsampsize).round;
	var resampedArray = Array.newClear(newsampsize+1);
	//we need an extra counter as an index number for our final resampled array
	var ct = 0;
	//run a for loop on the converted large buffer float array
	bufarray.do{ arg it, ix;
		//Do resampling and other stuff here
		//if the ix modulo the newsamplerate = 0 then newsamplerate samples has passed by and we can take a single sample and store it into the new resampled array
		if( ix%newsamplerate == 0, {
			resampedArray[ct] = it.asFloat;
			//ct is just a counter to advance the slots of the new resampled array
			//each time we store a value in the new resampled array,
			//we need to move to the next slot to store the next value so we advance ct by 1: ct = ct+1
			//remember the argument 'it' is the actual item in the source array: 'bufarray' which is the converted buffer to float array
			//the .asFloat is just a redundant precaution, to assure that there is no data confusion, curruption
			ct = ct+1; //advance the resampled array slot by 1
		}); //end if statement: if( ix%newsamplerate == 0
	}; //end for loop bufarray.do{
}); //end b.loadToFloatArray(action:{

//Finally, we'll tack onto our resampled array the osc address which will be "/wavfrm"
//This is because we are sending it as a single bundled array and the first item of the array needs to be the osc address
//We'll then send it to processing as a bundle
//Also, I wrap the entire thing into a function so I can call it easily from an OSCdef
//I add arguments into the wrapper function:
////buf, so we can grab the waveform of any buffer
////numpx, so we can have different size areas in our processing sketch for waveform display
//////I update newsampsize to equal numpx & b to buf

//Again the code copied and consolidated and added to below:

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

//You call the function like this:
~wff.value(b, 1000);

//Our last step for this session will be to create an OSCdef so that our Processing sketch
//can request the waveform data and we'll run the function and send out the bundle of waveform data


OSCdef(\getwf, { |msg|
	var bufnum = msg[1].asInteger;
	var numpx = msg[2].asInteger;
	~wff.value(bufnum, numpx); //run the buffer conversion and resampling function which also sends array to processing
}, "/getwf");
//we are anticipating a message from processing that will include the buffer number (we are dealing with one now,
//but will expand to many so this will be useful to include)
//it will also include the number of pixels to resample to, the width in pixels of our display area

//Below is all of the sc code so far with the code from this session added
//Next we'll move to the processing side and create a mechanism for receiving and displaying the buffer waveform


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







