( // PLACE THE MOUSE ANYWHERE BELOW HERE.
~aa = {
// reset
//~port.close;
s.freeAll;
Server.killAll;
SerialPort.closeAll;
Tdef.clear; Tdef.removeAll;
Pdef.clear; Pdef.removeAll;
i.free;     j.free;
Window.closeAll;
// INITIALIZE ARDUINO READING & POSTING
s.latency = 0.2;
s.options.memSize = 8192 * 32; // increase this if you get "alloc failed" messages

//s.boot; // boot server
};




~cc = {
// initialize calendar synth
~calendar = Synth(\calendar, [\atk, 3, \vol, 0]);
//format calendar variables
~mode = [Scale.lydian,Scale.mixolydian, Scale.aeolian, Scale.locrian, Scale.major];
~week = ~mode[4];
~rootAr = [0, 6, 5, 11, 10, 4, 3, 9, 8, 2, 1, 7];
~chord = [0, 2, 4];
~freqScaleKnob.action_({arg v; ~freqScale = v.value.linlin(0,1,1,3)}); // ~freqScale calibrates frequencies
~freqScale = 1;
~pos = 0;

Tdef(\eventStream,
	{var index = 0,

		 source = ~source_arr[index].asInteger,
		 lat, long, depth, mag, time, time1, time0, hour1;

		// prepare background map
		 i.scalesWhenResized_(true);
		{i.setSize(200, (200 / (i.width / i.height)).asInteger); // rescale
		 w.onClose_({ i.free }); // free the image when the window is closed
	     w.drawFunc_({ // draw image in main window
		 i.drawInRect(Rect(10,10,545,545), Rect(10,10,545,545), 2, 1.0);
		 });
		 }.defer;

		~aftermath = 0; // touch knows to do nothing additional (updated at the end)

		 ~source_arr.size.do{ // looped section

			var string, year, month, day, hour, hour1;
			~event_duration; ~year; ~month; ~day; ~hour; ~hour1;

			time = ~time_arr[index];
			time1 = ~time_arr[index+1];
			time0 = ~time_arr[index-1];
			lat = ~lat_arr[index];
			long = ~long_arr[index];
			depth = ~depth_arr[index];
			mag = ~mag_arr[index];

			if(time0.notNil, { // if value previous to the current is not Nil,

			 if(time1.notNil, // at the same time, next value is not Nil
				{string = time;
				 year = string[0..3].asInteger;  ~year  = year;
				 month = string[5..6].asInteger; ~month = month;
				 day = string[8..9].asInteger;   ~day   = day;
				 hour = string[11..18].asString; ~hour  = hour;
				 hour1 = string[11..12].asInteger;
				 ~root = (~rootAr[~month-1]);

				 if(~hour1 != hour1, {
					 case
					 {~day <= 7} // LYDIAN - WEEK 1
					 {~mtranspose = 3;// 4th degree major scale
					  ~chord = [[0, 2, 4, 6], [0, 2, 4, 6, 10]].choose;} //maj7, maj7#11

					 {~day > 7 && ~day <= 14} // MIXOLYDIAN - WEEK 2
					 {~mtranspose = 4;// 5th degree of major scale (mixo)
					  ~chord = [0, 2, 4, 6]} //dominant 7

					 {~day > 14 && ~day <= 21} // AEOLIAN - WEEK 3
					 {~mtranspose = 5;// 6th degree (aeolian)
					  ~chord = [[0, 2, 4, 6], [0, 2, 4, 5]].choose} //min7, b6

					 {~day > 21} // LOCRIAN - WEEK 4
					 {~mtranspose = 6;// 7th degree (locrian)
					  ~chord = [0, 2, 4, 6]}; // Ø7

					 if(hour1 <= 12,{~octave = 4;},{~octave = 3;});

					 ~calendar.release(3);
					 ~calendar = Synth(\calendar, [
						 \atk, 3,
					     \cut, 2000,
					 ]);
				   });


				 ~hour1 = hour1;
// calculate duration of each event (next event time - current event time)
				~event_duration = (~source_arr[index+1].asInteger - source);

				~magEv = mag;
				~depthEv = depth;
				~latEv = lat;
				~longEv = long;
			//debug only
		/*		~magEv.post;"mag \t".post;
				~longEv.post; "long \t".post;
				~latEv.post;"lat \t".post;
				~depthEv.post; "depth \t".postln;   */

// gui update
				{
				~current_string1.string =
					"magnitude "++~magEv.linlin(0,1,0,5.47).round(0.001).asString;
				~current_string2.string =
					"depth -"++~depthEv.linlin(0,1,0,25).round(0.001).asString ++"\n"++
					"long "++~longEv.linlin(0,1,-24.804,-14.334).round(0.001).asString ++"\n"++
					"lat "++~latEv.linlin(0,1,63.168,67.311).round(0.001).asString;
				~current_string3.string =
						~year.asString++" -\r"++~month.asString++" -\r"++
						~day.asString++" •\r"++~hour.asString;
				 }.defer;

				~currentPitch = ~depthEv.linlin(0,1,150,40);

		 // the actual sonification synth
				if(~createSynth == true,{
						~synth = Synth(\victor, [\gate, 1, \g, 1,
							\freq, (~currentPitch/2)*~freqScale,
							\noisectrl, 300*(~magEv+~depthEv),
							\atk, 0.01, \dec, 0.3,
							\sus, 0.1+~magEv,
							\rel,((~event_duration/~timeRatio)*~stretchFactor)+(~magEv+~depthEv).linexp(0,2,1,3),
							\bus_out, 0
						]);
						~click = Synth(\click, [
								\freq, (~currentPitch+100) * ~freqScale,
								\pos, ~pos,
								\vol, 0
							]);
				}, { // with ~createSynth == false,
					 ~click = Synth(\click, [
						\freq, ~depthEv.clip(0,1).linexp(0,1,555,999),
						\vol, ~magEv.clip(0,1).linexp(0,1,0.1,1)
				     ]);
				});

				// default timeRatio = 3000
				((~event_duration/~timeRatio)*~stretchFactor).wait; // wait time for each event

				// conclusion main loop
				index = index + ~direction; //update index (counter) and next STD timestamp
				{~local_timeline.value = index.linlin(0, ~source_arr.size, 0,1)}.defer; //update timeline position
				source = ~source_arr[index].asInteger;
			   },
				// if next time value (time1) is nil,
			   {"Sequence completed".postln;
				~click = Synth(\click, [\freq, 999]); //signal the end of the sequence
				if(~loop==1,
						{if( ~source_arr.size < 3,
							{ Tdef(\eventStream).stop; "Start again".postln;
							  1.do{1.wait; Tdef(\eventStream).play}; },
							{ Tdef(\eventStream).stop; "Start again".postln;
							  Tdef(\eventStream).play }
						);
						},
					//if loop=0
				   {"Sequence stopped. Select another timespan".postln;
				    Tdef(\eventStream).stop; Tdef(\binauralRev).pause; ~calendar.release(3)}
				);
			   }
			); //time1
			}, // if PREVIOUS value is Nil, do one of the following
		    {
			  if(~direction == -1, // if going backwards,
				{ //do this reset
				 Tdef(\eventStream).stop;
				 Tdef(\binauralRev).stop;
				// this won't restart the task
				// tell touch sensor to do it when releasing it
				 ~aftermath = 1; //this variable tells touch wether to restart eventStream+bin or not
				 "can't go further back!".postln;
				 ~click = Synth(\click, [\freq, 555, \vol, 0.05]); //signal the end of the sequence
				}, // if anything else, use the normal conclusion
				{	index = index + ~direction;
					{~local_timeline.value = index.linlin(0, ~source_arr.size, 0,1)}.defer;
					source = ~source_arr[index].asInteger;
				}
			  );
			}); // time0
}});
}; //cc











~bb = {
s.options.memSize = 8192 * 32;
s.boot;
SynthDef(\victor, {
 arg noisectrl, freq=60, cut=200, hpf=30, vol=0.5,
	 phase=0, br=200, brq=1,
	 g=1, gate=1,
	 atk=0.1, sus=0.2, dec=0.3, rel=0.5,
	 ampL=0.5, ampR=0.5, haasL=0.1, haasR=0.1,
	 mix=0.5, room=065, damp=0.5,
     bus_out = 0;
 var noise, snd, snd2, dist, env, env_d,
	 compensation, delL, delR, rev, out;
 noise = WhiteNoise.ar;
 noise = RLPF.ar(noise, 50);
 compensation = AmpCompA.kr(freq, 20);
 snd = SinOsc.ar(freq+(noise*noisectrl) *compensation, phase.lag(0.1))*0.8;
 env = EnvGen.kr(
		Env([0,1,sus,0],[atk, dec, rel], 'lin'),
		gate, doneAction: Done.freeSelf);
 //snd = Clip.ar(snd, -0.3, 0.3);
 snd2 = snd;
 dist = InsideOut.ar(snd2);
 env_d = EnvGen.kr(
		Env.adsr(0.01, 0.3, 0, 0.5), g);
 dist = dist*env_d;
 snd = (snd + dist);
 snd = RLPF.ar(snd, cut.lag(0.1));
 snd = HPF.ar(snd, hpf.lag(0.3));
 snd = BRF.ar(snd, br.lag(0.1), brq.lag(0.1));
 delL = DelayC.ar((snd*ampL.lag(0.1)), 1, haasL.lag(1)+(SampleDur.ir * 4));
 delR = DelayC.ar((snd*ampR.lag(0.1)), 1, haasR.lag(1)+(SampleDur.ir * 4));
 rev = FreeVerb2.ar(delL, delR, mix.lag(0.1), room, damp.lag(0.1)) *env *vol;
 out = Out.ar(bus_out, rev);
}).add;

// calendar synth
SynthDef( \calendar, {
 arg freqs=#[100,200,350,500], vol=0, cut=500, res=0.5,
	 gate = 1, atk=0.01, dec=0.4, sus=1, rel=0.5;
 var sig, env, lpf, out;
 sig = SinOsc.ar([freqs, freqs+3].lag(0.1));
 env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate, doneAction: Done.freeSelf);
 sig = HPF.ar(sig, 400);
 lpf = RLPF.ar(sig, cut, res);
 sig = lpf *env.lag(1) *vol.lag(1);
 sig = FreeVerb.ar(sig, 0.5, 0.6, 0.5);
 out = Out.ar(0, sig!2);
}).add;


// inspection boundaries
SynthDef( \synthello, {
 arg freq=100, vol=0.5, atk=0.1, release=0.1, cut=500, res=0.5;
 var sig, env, lpf, out;
 sig = Saw.ar([freq, freq+1]);
 env = EnvGen.kr(Env([0, 0.8, 0], [atk, release+0.1]), doneAction: 2);
 sig = sig*env*vol;
 lpf = RLPF.ar(sig, cut, res);
 out = Out.ar(0, lpf);
}).add;
// inspection reference synth (maps start-end notes)
SynthDef( \slRef, {
 arg freq=300, vol=0.4;
 var sig, env, out;
 env = EnvGen.kr(Env([0,1,0], [0.03,0.2]), doneAction: 2);
 sig = SinOsc.ar(freq!2) *env *vol;
 out = Out.ar(0, sig);
}).add;
// buf to hold magnitude array to mini-sonification, as freq env
SynthDef( \msoniBuf, {
 arg buffreq = ~bufFreq, bufamp = ~bufAmp, gate=1, vol=0.5;
 var numSeg, sig, compensation, env, amp, out;
 numSeg = Index.kr(buffreq, 1);
 compensation = AmpCompA.kr(Dbufrd(buffreq, Dseries(0, 4, numSeg+1)), 20, 0.01);
 sig = SinOsc.ar(
		DemandEnvGen.ar(
		 Dbufrd(buffreq, Dseries(0, 4, numSeg+1)),
		 Dbufrd(buffreq, Dseries(5, 4, numSeg)),
		 //Dbufrd(bufnum, Dseries(6, 4, numSeg)),
		 //Dbufrd(bufnum, Dseries(7, 4, numSeg)),
			doneAction: 2), 0, 0.1
	);
 env = EnvGen.kr(Env.adsr(0.01, 1, 1, 0.1), gate, doneAction: 2);
 amp = DemandEnvGen.ar(
		Dbufrd(bufamp, Dseries(0,4,numSeg+1)),
		Dbufrd(bufamp, Dseries(5,4,numSeg)),
		//Dbufrd(bufamp, Dseries(6, 4, numSeg)),
		//Dbufrd(bufamp, Dseries(7, 4, numSeg)),
		doneAction: 0);
 sig = sig *vol*amp *env;
 sig = LPF.ar(sig,  2000);
 out = Out.ar(0, sig!2);
}).add;
// test synth
SynthDef(\click, {
 arg freq=50, vol=0.5, pos= 0;
 var snd, env, pan, out;
 env = Line.ar(vol, 0, 0.1, doneAction: 2);
 snd = Ringz.ar(Impulse.ar(0.1), [freq, freq+1], 0.1) * env;
 snd = snd*vol;
	snd = HPF.ar(snd, 500);
 pan = Splay.ar(snd, 0,1, pos);
 out = Out.ar(0, pan);
}).add;

/////////////////////////////////////
// initialize global variables used before and after sensor smoothing
~accelerometerX = 0; ~accelerometerY = 0; ~accelerometerZ = 0;
~flexSensor = 700; ~buttonSensor = 1; ~touchSensor = 1;
~buttonS = 1; ~accelX = 0; ~accelY = 0; ~accelZ = 0;
~flex = 700; ~touchS = 1;
~createSynth = true;


// it takes too long to convert the entire column. consider formatting the dataset iso+std from py
// this CSV contains ISO timestamps
~earthquakesCSV = CSVFileReader.read("/Users/Robin/Desktop/vi semester/Summer Internship - IIL/earthquakes/earthquakes_aug21-22.csv", true, true);
//this contains original unix timestamps
~timesourceCSV = CSVFileReader.read("/Users/Robin/Desktop/vi semester/Summer Internship - IIL/earthquakes/aug2021-aug2022_2.csv", true, true);
~earthquakesCSV.removeAt(0); // column names is in entry 0
~timesourceCSV.removeAt(0); // remove to keep same size
// put all in a dictionary and cut out first entry for each array (column's name)
~skjalda = Dictionary.new(6);
~skjalda
.put(\time,  Array.fill(~earthquakesCSV.size, {arg i; ~earthquakesCSV.wrapAt(i).[0]}))
.put(\depth, Array.fill(~earthquakesCSV.size, {arg i; ~earthquakesCSV.wrapAt(i).[1]})) // 0-25
.put(\mag,   Array.fill(~earthquakesCSV.size, {arg i; ~earthquakesCSV.wrapAt(i).[2]})) // 0-5.47
.put(\lat,   Array.fill(~earthquakesCSV.size, {arg i; ~earthquakesCSV.wrapAt(i).[3]})) // 63.168430 - 67.311250
.put(\long,  Array.fill(~earthquakesCSV.size, {arg i; ~earthquakesCSV.wrapAt(i).[4]})) // -24.803740 - -14.333800
// original timestamps (use for durations)
.put(\tSRC,  Array.fill( ~timesourceCSV.size, {arg i; ~timesourceCSV.wrapAt(i).[8]}))
;
// create arrays from dictionary keys
~dict = ~skjalda;
~timeD = ~dict[\time];
~depthD = ~dict[\depth].asFloat.normalize.round(0.001);
~magD = ~dict[\mag].asFloat.normalize.round(0.001);
~latD = ~dict[\lat].asFloat.normalize.round(0.001);
~longD = ~dict[\long].asFloat.normalize.round(0.001);
~sourceD = ~dict[\tSRC];
//store those array into named variables
~time = ~timeD;
~depth = ~depthD;
~mag = ~magD;
~lat = ~latD;
~long = ~longD;
~source = ~sourceD;
// create non-empty subarrays in each named array
~time_arr = ~time[20..26];
~depth_arr = ~depth[20..26];
~mag_arr = ~mag[20..26];
~lat_arr = ~lat[20..26];
~long_arr = ~long[20..26];
~source_arr = ~source[20..26];

// create GUI
Window.closeAll;
w = Window.new("gui_main", Rect(1440/3, 300, 500, 400), false).front;
w.background = Color.grey(0.5, 1);
//v = Window.new("map_gui", Rect((1440/3)*2, 300, 500,500));
~parent = w;
// h, a, k params settings
~knobs_rect = CompositeView(w, Rect(205, 50, 190, 120));
~knobs_rect.background = Color.grey(0.1, 0.1);

~num1 = NumberBox.new(~knobs_rect, Rect(5, 10, 35, 20));
~knob1 = Knob.new(~knobs_rect, Rect(45, 4, 32, 32));
~knob1.mode = \vert;
~knob1.step = 0.001;
~label1 = StaticText.new(~knobs_rect, Rect(85,10,70,20));
~label1.string="head size"; ~label1.stringColor = Color.white;

~num2 = NumberBox.new(~knobs_rect, Rect(5, 50, 35, 20));
~knob2 = Knob.new(~knobs_rect, Rect(45, 44, 32, 32));
~knob2.mode = \vert;
~label2 = StaticText.new(~knobs_rect, Rect(85,50,100,20));
~label2.string="speed of sound"; ~label2.stringColor = Color.white;

~num3 = NumberBox.new(~knobs_rect, Rect(5, 90, 35, 20));
~knob3 = Knob.new(~knobs_rect, Rect(45, 84, 32, 32));
~knob3.mode = \vert;
~label3 = StaticText.new(~knobs_rect, Rect(85,90,120,20));
~label3.string="coeff. amp slope"; ~label3.stringColor = Color.white;

//current events
~current_rect = CompositeView(w, Rect(205, 175, 140,90));
~current_rect.background = Color.grey(0.1, alpha: 0.1);
~current_string1 = StaticText(~current_rect, Rect(0, 0, 160, 30));
~current_string1.font = Font(size:14); ~current_string1.stringColor = Color.white;
~current_string2 = StaticText(~current_rect, Rect(0, 20, 160, 60));
~current_string2.font = Font(size:12); ~current_string2.stringColor = Color.white;
~current_string3 = StaticText(~current_rect, Rect(0, 50, 160, 60));
~current_string3.font = Font(size:12); ~current_string3.stringColor = Color.white;

// cursor long, lat, depth
~local_rect = CompositeView(w, Rect(10, 205, 190, 60));
~local_rect.background = Color.grey(0.1,alpha: 0.1);
~local_timeline = Slider.new(~local_rect, Rect(5, 5, 180, 10)); //this timeline is set by eventStream index
~local_timeline.value = 0;
~local_coordinates = StaticText(~local_rect, Rect(10, 20, 400, 40));
~local_coordinates.font = Font(size:14); ~local_coordinates.stringColor = Color.white;
///////////////////////////////////////////////////
~current_string1.string ="magnitude ____";
~current_string2.string =
"depth -"++0.5.linlin(0,1,0,25).round(0.001).asString ++"\n"++
"long "++0.5.linlin(0,1,-24.804,-14.334).round(0.001).asString ++"\n"++
"lat "++0.5.linlin(0,1,63.168,67.311).round(0.001).asString;
~current_string3.string =
~year.asString++"\r"++~month.asString++"\r"++~day.asString++"\r"++~hour.asString;

~local_coordinates.string =
//"Approx. listening location:\n"++
"long "++
0.5.linlin(0,1,-24.804, -14.334).round(0.001).asString ++
" °\f lat "++
0.5.linlin(0,1, 63.168, 67.311).round(0.001).asString ++
" °\ndepth -"++
0.5.linlin(600,830,0,25).round(0.001).asString ++" km"
;
//////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// set up text elements
~range_rect = CompositeView(w, Rect(10, 320, 350, 40));
~range_rect.background = Color.grey(0.1,0.1);
~daterange = StaticText.new(~range_rect, Rect(10, 0, 500, 20));
~daterange.font = Font(size: 12); ~daterange.stringColor = Color.white;
~daterange.string = "Date range:___________________________________________";
~boundaries = StaticText.new(~range_rect, Rect(10, 20, 400, 20));
~boundaries.font = Font(size: 12); ~boundaries.stringColor = Color.white;
~boundaries.string = "Boundaries: _______________________________________";
// force stop button
~forceStop = Button.new(w, Rect(10, 270, 40,40));
~forceStop.states_([["force\nstop", Color.black, Color.red]]);
~forceStop.action = ({
	"forced stop".postln;
	Tdef(\binauralRev).stop;
	Tdef(\eventStream).stop;
	~calendar.release(1);
});
//setup status button
~status = Button.new(w, Rect(60, 270, 150, 40));// status button
~status.states_([
	[ "Scanning", Color.black, Color.yellow], //0 default scanning color
	[ "Zooming", Color.black, ~zoomcolor], //1 keep for 2sec after pressing touch, then 2
	[ "Scanning", Color.black, ~zoomcolor],//2 come sopra
	[ "Listening", Color.black, Color.green], //3 for when release button
	[ "<<< Backwards <<<", Color.black, Color.gray], //4 when paused and listening backwards
	[ ">>> Forward >>>", Color.black, Color.gray], //5 when paused and listening forward
	[ "Pause", Color.black, Color.red],
]);

//loop switch & global variable used in eventStream
~loopButton = Button.new(w, Rect(220, 270, 40,40));
~loopButton.states_([
	["loop\noff", Color.black, Color.white],
	["loop\non", Color.white, Color.black],
]);
~loopButton.action = ({arg butt; case
	{butt.value==0}{"loop off".postln; ~loop = 0}
	{butt.value==1}{"loop on".postln; ~loop = 1}
});
~loopButton.valueAction=1; // default loop ON

// reset button (restarts the sequence)
~resetButton = Button.new(w, Rect(270, 270, 40,40));
~resetButton.states_([["reset", Color.black, Color.white]]);
~resetButton.action = ({
	Tdef(\eventStream).play; Tdef(\binauralRev).play;
	"reset sequence!".postln
});

// map rescale button
~mapButton = Button.new(w, Rect(320, 270, 40,40));
~mapButton.states_([
	["open\nmap", Color.white, Color.blue(alpha: 0.4)],
	["close\nmap", Color.white, Color.grey(alpha: 0.3)]
]);
~mapButton.action = ({ arg map; case
	{map.value==1}
	{v = Window.new("map_gui", Rect(120, 180, 545,545), false);
	 v.front;
	 ~parent = v;
	 "magnify map".postln;
	 ~mapScaleCoeff = 2.725;
	 ~adjustMap = 0;
	 ~mapView.close;
	 ~mapView = UserView.new(~parent, Rect(0,0, 545, 545));
	 ~mapView.drawFunc = {
		i.drawInRect(
			Rect(0,0,545,545),
			Rect(0,0,545,545),
			2,
			1.0);
	 };
	 ~mapView.refresh;
	 w.refresh;
	 v.refresh;
	}
	{map.value==0}
	{~parent = w;
	"reduce map".postln;
	~mapScaleCoeff = 1;
	~adjustMap = 10;
	//i.scalesWhenResized_(true);
	~mapView = UserView.new(~parent, Rect(0,0, 200, 200));
	~mapView.drawFunc = {
	i.drawInRect(
		Rect(10,10,200,200),
		Rect(10,10,545,545),
		2,
		1.0);
};
~mapView.refresh;
	 w.refresh;
	 v.close;
	 w.front;
	}
});

// vol reference elements (context); includes blip blops, synthello, and calendar synth
~volNum = NumberBox.new(w, Rect(370, 340, 40, 20));//number box
~volContext = Slider.new(w, Rect(370, 260, 40,80));
~volContext.action = ({
	arg vl;
	~vol_context = ~volContext.value.linexp(0,1,0.000001,1);
	~volNum.value = ~volContext.value;
});
~volContextText = StaticText.new(w, Rect(370, 225, 50, 30));
~volContextText.string = "vol\ncontext"; ~volContextText.stringColor = Color.white;
~vol_context = 0.5;

// timescale (slowest: x3000, fastest: x12000
//~timeNum = NumberBox.new(w, Rect(420, 340, 60, 20));//numb box
~timeRatio = 3000;

~timeScale = Slider.new(w, Rect(420, 260, 40,80));
~timeScale.action = ({
	arg vl;
	~timeRatio = ~timeScale.value.linlin(0,1,2000,12000); // timeRatio is used in eventStream
	~timeCapt.string = "1 day =\n"++~timeRatio.linlin(2000,12000,43,7.2).round(0.1).asString++" sec";
});
~timeCapt = StaticText.new(w, Rect(420, 342, 80, 20));
~timeCapt.string = "1 day =\n"++~timeRatio.linlin(2000,12000,43,7.2).round(0.1).asString++" sec";
~timeCapt.font = Font(size:10); ~timeCapt.stringColor = Color.white;

~timeScaletText = StaticText.new(w, Rect(425, 225, 50, 30));
~timeScaletText.string = "time\nscale"; ~timeScaletText.stringColor = Color.white;

// serial port selection pop up menu
~usb_rect = CompositeView(w, Rect(205, 10, 190, 35));
~usb_rect.background = Color.grey(0.1,0.1);
~select_usbPort = PopUpMenu(~usb_rect, Rect(55, 10, 100, 20));
~select_usbPort.items = SerialPort.devices;
~select_usbPort.font_(Font(size: 10));
~select_usbPort.action = {arg me;
	var portnum = me.value;
	var portname = ~select_usbPort.items[portnum];
	~port = SerialPort.new(portname.asString, 115200, crtscts: true);
	portname.asString.postln;
	if(~port.isOpen,
		{"USB port ready.".postln;
			1.do{

				if( (~port.isOpen==true)&&(~port.notNil==true),{
					// open reading port process
					Tdef(\readValues,{
						loop {
							var byte, str, res;
							if(~port.read==10,
								{str = "";
									while(
										{byte = ~port.read; byte !=13 },
										{str= str++byte.asAscii;}
									);
									res = str.split($ ); //strings
									~accelerometerX = res[2].asFloat;
									~accelerometerY = res[1].asFloat;
									~accelerometerZ = res[3].asFloat;
									~flexSensor = res[4].asFloat; // mappa 830-600 -> depth 0-max
									~buttonSensor = res[0].asInteger;
									~touchSensor = res[5].asInteger;
							}); // no need for .wait as there's some delay in arduino
						};

					});
					Tdef(\readValues).play;
					"loadin up..".postln;
				},{"ops, no port was found".postln}
				);

				if(
					Tdef(\readValues).isPlaying,
					{"port is reading...".postln;
						// smoothen sensor readings
						Tdef(\smoothSensors, {
							arg i = 1;
							var c = 0.3; // lag coeff.
							loop{
								// smooth = coeff*arduino reading + (1-coeff)*smooth(pre)
								~accelX = ((c*(~accelerometerX)) + ((1-c)*(~accelX)));
								~accelY = ((c*(~accelerometerY)) + ((1-c)*(~accelY)));
								~accelZ = ((c*(~accelerometerZ)) + ((1-c)*(~accelZ)));
								~flex = ((c*(~flexSensor)) + ((1-c)*(~flex)));
								// these don't need smoothing, update var name
								~buttonS = ~buttonSensor;
								~touchS = ~touchSensor;
								0.03.wait;
							}
						}).play;
						Tdef(\sliderMove,{
							loop
							{0.03.wait;
								{l.activeLo_(~accelX.round(10).linlin(-10000, 10000, 1, 0))}.defer;
								{l.activeRange_(~accelY.round(10).linlin(-10000, 10000, 1, 0))}.defer;
							};
						}).play;

						Tdef(\xyMove,
							{loop
								{
									{~xyPad.setXYActive(
										~accelX.linlin(-10000, 10000, 1, 0).lag(3),
										~accelY.linlin(-10000, 10000, 0, 1).lag(3)
									);}.defer;
									{~xyPad.action_({
										arg pad;
										~padX = pad.x.asFloat.round(0.01);
										~padY = pad.y.asFloat.round(0.01);
									})}.defer;
									0.03.wait;
								}
						}).play;
						// initialize some global variables
						~button = ~buttonS;
						~touch = ~touchS;
						~direction = 1;
						//~direction = -1;
						~stretchFactor = 1;
						// listener parameters
						h = 1; //size head (tweak!)
						a = 0.1; //a = 343 m/s, speed of sound. try slower than this. used only for haas effect
						k = 3; // try <1 as well
					},
					{"error: select a valid port".postln;
						~port.close;
					}
				);

			};
		},
		{"error. check usb connection".postln;}
	);
};
~select_usbPort_text = StaticText.new(~usb_rect, Rect(5, 5, 60, 25));
~select_usbPort_text.string = "Select\nUSB port"; ~select_usbPort_text.stringColor = Color.white;
~select_usbPort_text.font_(Font(size:10));

// initialization sequential switches
~switches_rect = CompositeView.new(w, Rect(400,10, 90,35));
~switches_rect.background = Color.grey(0.05, 0.1);
/*
~switch_1 = Button.new(~switches_rect, Rect(5, 10, 20, 20))
	.states_([ [], [] ]);

~switch_1.action = {arg sw;
		if(sw.value == 1, {
			fork{
				1.do{
					{~switch_1.states = [["", Color.yellow, Color.yellow]]}.defer;
					{~cc.()}.defer;
					1.wait;
					{~switch_1.states = [["", Color.green, Color.green]]; }.defer;
				}
			};
		});
	};

~switch_2 = Button.new(~switches_rect, Rect(30, 10, 20, 20));
~switch_3 = Button.new(~switches_rect, Rect(55, 10, 20, 20));
*/
// frequency scaling knob
~freqScaleRect = CompositeView(w, Rect(350, 175, 45, 50));
~freqScaleRect.background = Color.grey(0.1,0.1);
~freqScaleKnob = Knob(~freqScaleRect, Rect(5, 16, 32, 32));
~freqScaleKnob.mode = \vert;
~freqScaleText = StaticText.new(~freqScaleRect, Rect(2, 2, 45,10));
~freqScaleText.string = "f. scale"; ~freqScaleText.stringColor=Color.white;

// 2d slider (hidden)
~xyPad = Slider2D(w, Rect(1500, 10, 190,190))
		 .x_(0.5).y_(0.5);

//open map image and format it
i = Image.open(thisProcess.nowExecutingPath.dirname+/+"map.jpg");
i.scalesWhenResized_(true);

~mapView = UserView.new(~parent, Rect(0,0, 200, 200));
~mapView.drawFunc = {
	i.drawInRect(
		Rect(10,10,200,200),
		Rect(10,10,545,545),
		2,
		1.0);
};
~mapView.refresh;

// add gradient image
j = Image.color(200,200, Color.white);
j.scalesWhenResized_(true);

// set up range slider
l = RangeSlider.new(w,Rect(10, 370, 480, 20));
l.action_({
 arg sl;
 ~loindex = sl.lo.linlin(0, 1, 0, ~time.size-1;).asInteger;
 ~hiindex = sl.hi.linlin(0, 1, 0, ~time.size-1;).asInteger;
});

w.onClose_({
	s.freeAll;
	Server.killAll;
	~port.close;
	SerialPort.closeAll;
	Tdef.clear; Tdef.removeAll;
	Pdef.clear; Pdef.removeAll;
	v.close;
	i.free; j.free;
	Tdef(\eventStream).stop;Tdef(\binauralRev).stop;Tdef(\action).stop;
	s.latency = 0.20;
	s.reboot;
});

}; //bb


///////////////////////////////////////////////////////////////////////
~cc = {
// initialize calendar synth
~calendar = Synth(\calendar, [\atk, 3, \vol, 0]);
//format calendar variables
~mode = [Scale.lydian,Scale.mixolydian, Scale.aeolian, Scale.locrian, Scale.major];
~week = ~mode[4];
~rootAr = [0, 6, 5, 11, 10, 4, 3, 9, 8, 2, 1, 7];
~chord = [0, 2, 4];
~freqScaleKnob.action_({arg v; ~freqScale = v.value.linlin(0,1,1,3)}); // ~freqScale calibrates frequencies
~freqScale = 1;
~pos = 0;

Tdef(\eventStream,
	{var index = 0,

		 source = ~source_arr[index].asInteger,
		 lat, long, depth, mag, time, time1, time0, hour1;

		// prepare background map
		 i.scalesWhenResized_(true);
		{i.setSize(200, (200 / (i.width / i.height)).asInteger); // rescale
		 w.onClose_({ i.free }); // free the image when the window is closed
	     w.drawFunc_({ // draw image in main window
		 i.drawInRect(Rect(10,10,545,545), Rect(10,10,545,545), 2, 1.0);
		 });
		 }.defer;

		~aftermath = 0; // touch knows to do nothing additional (updated at the end)

		 ~source_arr.size.do{ // looped section

			var string, year, month, day, hour, hour1;
			~event_duration; ~year; ~month; ~day; ~hour; ~hour1;

			time = ~time_arr[index];
			time1 = ~time_arr[index+1];
			time0 = ~time_arr[index-1];
			lat = ~lat_arr[index];
			long = ~long_arr[index];
			depth = ~depth_arr[index];
			mag = ~mag_arr[index];

			if(time0.notNil, { // if value previous to the current is not Nil,

			 if(time1.notNil, // at the same time, next value is not Nil
				{string = time;
				 year = string[0..3].asInteger;  ~year  = year;
				 month = string[5..6].asInteger; ~month = month;
				 day = string[8..9].asInteger;   ~day   = day;
				 hour = string[11..18].asString; ~hour  = hour;
				 hour1 = string[11..12].asInteger;
				 ~root = (~rootAr[~month-1]);

				 if(~hour1 != hour1, {
					 case
					 {~day <= 7} // LYDIAN - WEEK 1
					 {~mtranspose = 3;// 4th degree major scale
					  ~chord = [[0, 2, 4, 6], [0, 2, 4, 6, 10]].choose;} //maj7, maj7#11

					 {~day > 7 && ~day <= 14} // MIXOLYDIAN - WEEK 2
					 {~mtranspose = 4;// 5th degree of major scale (mixo)
					  ~chord = [0, 2, 4, 6]} //dominant 7

					 {~day > 14 && ~day <= 21} // AEOLIAN - WEEK 3
					 {~mtranspose = 5;// 6th degree (aeolian)
					  ~chord = [[0, 2, 4, 6], [0, 2, 4, 5]].choose} //min7, b6

					 {~day > 21} // LOCRIAN - WEEK 4
					 {~mtranspose = 6;// 7th degree (locrian)
					  ~chord = [0, 2, 4, 6]}; // Ø7

					 if(hour1 <= 12,{~octave = 4;},{~octave = 3;});

					 ~calendar.release(3);
					 ~calendar = Synth(\calendar, [
						 \atk, 3,
					     \cut, 2000,
					 ]);
				   });


				 ~hour1 = hour1;
// calculate duration of each event (next event time - current event time)
				~event_duration = (~source_arr[index+1].asInteger - source);

				~magEv = mag;
				~depthEv = depth;
				~latEv = lat;
				~longEv = long;
			//debug only
		/*		~magEv.post;"mag \t".post;
				~longEv.post; "long \t".post;
				~latEv.post;"lat \t".post;
				~depthEv.post; "depth \t".postln;   */

// gui update
				{
				~current_string1.string =
					"magnitude "++~magEv.linlin(0,1,0,5.47).round(0.001).asString;
				~current_string2.string =
					"depth -"++~depthEv.linlin(0,1,0,25).round(0.001).asString ++"\n"++
					"long "++~longEv.linlin(0,1,-24.804,-14.334).round(0.001).asString ++"\n"++
					"lat "++~latEv.linlin(0,1,63.168,67.311).round(0.001).asString;
				~current_string3.string =
						~year.asString++" -\r"++~month.asString++" -\r"++
						~day.asString++" •\r"++~hour.asString;
				 }.defer;

				~currentPitch = ~depthEv.linlin(0,1,150,40);

		 // the actual sonification synth
				if(~createSynth == true,{
						~synth = Synth(\victor, [\gate, 1, \g, 1,
							\freq, (~currentPitch/2)*~freqScale,
							\noisectrl, 300*(~magEv+~depthEv),
							\atk, 0.01, \dec, 0.3,
							\sus, 0.1+~magEv,
							\rel,((~event_duration/~timeRatio)*~stretchFactor)+(~magEv+~depthEv).linexp(0,2,1,3),
							\bus_out, 0
						]);
						~click = Synth(\click, [
								\freq, (~currentPitch+100) * ~freqScale,
								\pos, ~pos,
								\vol, 0
							]);
				}, { // with ~createSynth == false,
					 ~click = Synth(\click, [
						\freq, ~depthEv.clip(0,1).linexp(0,1,555,999),
						\vol, ~magEv.clip(0,1).linexp(0,1,0.1,1)
				     ]);
				});

				// default timeRatio = 3000
				((~event_duration/~timeRatio)*~stretchFactor).wait; // wait time for each event

				// conclusion main loop
				index = index + ~direction; //update index (counter) and next STD timestamp
				{~local_timeline.value = index.linlin(0, ~source_arr.size, 0,1)}.defer; //update timeline position
				source = ~source_arr[index].asInteger;
			   },
				// if next time value (time1) is nil,
			   {"Sequence completed".postln;
				~click = Synth(\click, [\freq, 999]); //signal the end of the sequence
				if(~loop==1,
						{if( ~source_arr.size < 3,
							{ Tdef(\eventStream).stop; "Start again".postln;
							  1.do{1.wait; Tdef(\eventStream).play}; },
							{ Tdef(\eventStream).stop; "Start again".postln;
							  Tdef(\eventStream).play }
						);
						},
					//if loop=0
				   {"Sequence stopped. Select another timespan".postln;
				    Tdef(\eventStream).stop; Tdef(\binauralRev).pause; ~calendar.release(3)}
				);
			   }
			); //time1
			}, // if PREVIOUS value is Nil, do one of the following
		    {
			  if(~direction == -1, // if going backwards,
				{ //do this reset
				 Tdef(\eventStream).stop;
				 Tdef(\binauralRev).stop;
				// this won't restart the task
				// tell touch sensor to do it when releasing it
				 ~aftermath = 1; //this variable tells touch wether to restart eventStream+bin or not
				 "can't go further back!".postln;
				 ~click = Synth(\click, [\freq, 555, \vol, 0.05]); //signal the end of the sequence
				}, // if anything else, use the normal conclusion
				{	index = index + ~direction;
					{~local_timeline.value = index.linlin(0, ~source_arr.size, 0,1)}.defer;
					source = ~source_arr[index].asInteger;
				}
			  );
			}); // time0
}});
}; //cc


~dd = {
~knob1.action_({arg v; h = v.value; ~num1.value = h;});
~knob2.action_({arg v; a = v.value.linexp(0,1,0.01,0.5); ~num2.value = a});
~knob3.action_({arg v; k = v.value.linexp(0,1,0.01,10); ~num3.value = k});
~knob1.valueAction = 0.53;
~knob2.valueAction = 0.3;
~knob3.valueAction = 0.97;

Tdef(\binauralRev, {
	loop{
	~currentDepth = ~flex.linexp(580,780,1,0.001); //accessed depth
// ear pairs 3d location
	~xL = ~padX.asFloat - (h/2);
	~xR = ~padX.asFloat + (h/2);
	~yL = ~yR = ~padY.asFloat;
	~zL = ~zR = ~flex.linexp(580, 780, 1, 0.001);
// calculate distance for each ear from source
	~distance_source_left = sqrt((~xL - ~longEv ).squared
			+(~yL - ~latEv).squared +(~zL - ~depthEv).squared);
	~distance_source_right = sqrt((~xR - ~longEv ).squared
			+(~yR - ~latEv).squared +(~zR - ~depthEv).squared);
	~ampL = (2 ** (k.neg * ~distance_source_left));
	~ampR = (2 ** (k.neg * ~distance_source_right));
	~haasL = a * ~distance_source_left;
	~haasR = a * ~distance_source_right;
// emphasis on transient position
		if((~longEv < 0.5),
			{~pos = (-1) * ((~distance_source_left + ~distance_source_right)/2)},
			{~pos = 1 * ((~distance_source_left + ~distance_source_right)/2)}
		);
// calculate additional dynamic params
	~revMix = (~depthEv-~currentDepth).abs.clip(0,1);
	~farness = (~distance_source_left-~distance_source_right).abs.linexp(0,0.8,20,800);
	~darkness = (~distance_source_left-~distance_source_right).abs.linexp(0,0.8,600,~farness);
	~br = ~yL.linexp(0,1,970,1030);
	~brq = if(~yL<=0.5, {~brq=~yL.linexp(0,0.5,0.8,1)},{~brq=~yL.linexp(0.5,1,1,0.8)});
	//~phase = ~yL.linexp(0,1,-4*pi,4*pi);
// update these synth params at sensor rate
	if(~createSynth == true, {
			~synth.set(\hpf, ~farness, \cut, ~darkness, \br, ~br, \brq, ~brq,
				\vol, 1-(((~distance_source_left+~distance_source_right)/2).clip(0,0.85)+0.1),
				\ampL,~ampL, \ampR,~ampR, \haasL,~haasL, \haasR,~haasR,
				\mix, ~revMix);
// update calendar volume at sensor rate
			~calendar.set(\vol, 0.05*~vol_context, //~magEv.linlin(0,1,0.05,0.5),
				\freqs, ((((((~chord + ~mtranspose)
					.degreeToKey(~week, ~week.stepsPerOctave))
					.value + ~root) / ~week.stepsPerOctave + ~octave)
					* 12.0).value).midicps,
				\cut, 400);
	});
	0.03.wait; //updated at sensor rate
}});
// parallel task to control secondary audio streams volume
Tdef(\volContextUpdate, {
	loop{
		{~vol_context = ~volContext.value;}.defer;
		0.03.wait;
	}
}).play;
}; //dd

~ee = {
 //leave this on
Tdef(\action, {loop{
	~time_arr = ~time[~loindex .. ~hiindex];

	~mag_arr = ~mag[~loindex .. ~hiindex];
	~lat_arr = ~lat[~loindex .. ~hiindex];
	~long_arr = ~long[~loindex .. ~hiindex];
	~depth_arr = ~depth[~loindex .. ~hiindex];
	~source_arr = ~source[~loindex .. ~hiindex];

	if(~button != ~buttonS,{
		~button = ~buttonS;
		~button.post;" button".postln;

		if(~button==1,{

			{~status.valueAction = 0}.defer;
			{~daterange.string = "select a date range"}.defer;
			~time = ~timeD;
			~depth = ~depthD;
			~mag = ~magD;
			~lat = ~latD;
			~long = ~longD;
			~source = ~sourceD;

			// release calendar synth
			~calendar.release(1);

			Tdef(\gestureMapping).stop;
			Tdef(\binauralRev).stop;
			Tdef(\eventStream).stop;
			Tdef(\xyMove).stop;
			Tdef(\sliderMove).play;
			Tdef(\inspectSectRef, {
				loop{

					~selboundaries = //this is just for the GUI
					   ~time[~loindex].asString ++"\t" ++
					   ~time[~hiindex].asString;

					{~boundaries.string =
					 "current: "++~selboundaries.asString;}.defer;

					if(~touch != ~touchS,{
						~touch = ~touchS;
						~touch.post;" touch".postln;

						if(~touch==0,{
							~zoomcolor = [(Color.rand)].choose;
							{~status.valueAction = 2}.defer;
							~time = ~time_arr;
							~depth = ~depth_arr;
							~mag = ~mag_arr;
							~lat = ~lat_arr;
							~long = ~long_arr;
							~source = ~source_arr;
						},{
							{~status.valueAction = 1}.defer;
						});
					});

					~startnote = ~loindex.linlin(
						0, ~time.size-1, 60.midicps,(60.midicps*2)).asFloat;
					~endnote = ~hiindex.linlin(
						0, ~time.size-1;, 60.midicps,(60.midicps*2)).asFloat;

					~env_durations = [];
					// create an array to store distance in seconds between each events
					// (divide by 3000 when using as synth durations)
					~env_durations = Array.fill(~source_arr.size, {arg i;
						~source_arr.clipAt(i+1).asInteger - ~source_arr.clipAt(i).asInteger;}
					);

				// store mini-sonification parameters in dedicated array to rescale etc
					~envM = ~mag_arr.linexp(0,1,500,4000); // representation of magnitudes as amplitudes
					~envA = ~mag_arr.linexp(0,1,0.1, 1).expexp(0.001, 1, 0.01, 1);// mag as amplitudes
					~envD = ~env_durations; // (actual durations for Pbind)

					e = Env(~envM, ~envD.normalizeSum/2, -400); // freq envelope
					f = Env(~envA, ~envD.normalizeSum/2, -400); // amp envelope
					~bufFreq = Buffer.sendCollection(s, e.asArray, 1, -1,/*{"blip!".postln}*/);
					~bufAmp = Buffer.sendCollection(s, f.asArray, 1, -1,/*{"blip!".postln}*/);
					//c = Buffer.sendCollection(s, f.asArray, 1, -1);

					Pdef(\section, Ppar([
						Pbind(
							\instrument, \slRef,
							\freq, Pseq([~startnote, ~endnote, \rest, \rest], inf),
							\dur, 0.25,
							\vol, 0.15*~vol_context
						),
						Pbind(
							\instrument, \synthello,
							\freq, Pseq([[60.midicps/2,60.midicps*2], \rest], inf),
							\atk, 0.5,
							\release, 1,
							\dur, Pseq([2,2], inf),
							\cut, 400,
							\res, 0.5,
							\vol, 0.1*~vol_context
						),
						Pbind(
							\instrument, \msoniBuf,
							\buffreq, ~bufFreq,
							\bufamp, ~bufAmp,
							\vol, Pseq([0,0,1], inf),
							\dur, Pseq([0.25,0.25,0.5], inf)
					)], inf)
					);
					0.05.wait; //inspectSectRef

				}
			}).play;

			Pdef(\section).play;
		},{

			{~status.valueAction = 3;}.defer;
			{~boundaries.string = "executing"}.defer;

			Tdef(\inspectSectRef).stop;
			Pdef(\section).stop;
			Tdef(\sliderMove).stop;
			Tdef(\xyMove).play;
			Tdef(\eventStream).play;
			Tdef(\binauralRev).play;
			~datestring = "from "++~time[~loindex].asString++" to "++~time[~hiindex].asString;
			{~daterange.string = ~datestring.asString;}.defer;

			Tdef(\gestureMapping, {
				loop{
					if(~touch != ~touchS,{
						~touch = ~touchS;
						~touch.post;" touch".postln;
						if(~touch==0,{
							Tdef(\scrubbing).stop;
							Buffer.freeAll;
							~createSynth = true;
							//if task has been stopped after hitting the start edge
							if(~aftermath == 1, //reboot also the synths
								{Tdef(\eventStream).play;
								 Tdef(\binauralRev).play
								} //otherwise ignore
							);
							~direction = 1;
							{~timeRatio = ~timeScale.value.linexp(0,1,2000,12000)}.defer;
							~stretchFactor = 1;
							{~status.valueAction = 3}.defer;
							Tdef(\eventStream).resume;
							Tdef(\binauralRev).resume;
							~calendar.release(1);
							~calendar = Synth(\calendar,[\freqs,[100,200,350,500],\atk, 3,\vol, 0]);
						},{// if touch ==1,
						   ~createSynth = false;
						   Tdef(\scrubbing, {
						    loop{
							 if(~accelX >= 3000,{
								"backwards".postln;
								{~status.valueAction= 4}.defer;
								Tdef(\binauralRev).pause;
								Tdef(\eventStream).pause;
								~direction = -1;
								~timeRatio = 3000;
								~stretchFactor = 0.1;
								Tdef(\eventStream).resume;
								Tdef(\binauralRev).resume;
								~calendar.release(1);
							    },{// if accel anything different than >=1000
								   if(~accelX <= -3000,{
									  "forward".postln;
									  {~status.valueAction= 5}.defer;
									  Tdef(\binauralRev).pause;
									  Tdef(\eventStream).pause;
									  ~direction = 1;
									  ~timeRatio = 3000;
									  ~stretchFactor = 0.1;
									  Tdef(\eventStream).resume;
									  Tdef(\binauralRev).resume;
									  ~calendar.release(1);
								      },{
									     if((~accelX < 3000)&&(~accelX > -3000),
										    {"pause".postln;
										     {~status.valueAction= 6}.defer;
										     Tdef(\eventStream).pause;
										     Tdef(\binauralRev).pause;
										     ~calendar.release(1);
									     });
								   });
						   });
						   0.5.wait;
						   }
						  }).play;
						});
					});
					0.05.wait
				}
			}).play;
		});
	});

	{// update elements on GUI
	 ~mapView.drawFunc = {
	 if(~parent == v, {
	 i.drawInRect(
				Rect(0+~adjustMap,0+~adjustMap,200*~mapScaleCoeff,200*~mapScaleCoeff),
				Rect(0+~adjustMap,0+~adjustMap,545/~mapScaleCoeff,545/~mapScaleCoeff),
				2,
				1.0);
	 j.drawInRect( // over layer depth-rep (flex shading)
				Rect(0+~adjustMap,0+~adjustMap,200*~mapScaleCoeff,200*~mapScaleCoeff),
				Rect(0+~adjustMap,0+~adjustMap,545/~mapScaleCoeff,545/~mapScaleCoeff),
				2,
				~flex.linlin(580,780,1,0));

	 ~pointScaleFact = 3;
	 },
	 {
	 j.drawInRect( // over layer depth-rep (flex shading)
				Rect(0+~adjustMap,0+~adjustMap,545*~mapScaleCoeff,545*~mapScaleCoeff),
				Rect(0+~adjustMap,0+~adjustMap,545*~mapScaleCoeff,545*~mapScaleCoeff),
				2,
				~flex.linlin(580,780,1,0));

	 ~pointScaleFact = 1;
	 });

	 Pen.fillColor = Color.red; // draw seismic events
	 Pen.fillOval(Rect( //adjust a bit lat and long to fit map location
				7+~longEv.linlin(0,1,0,(200*~mapScaleCoeff)-10),
				7+~latEv.linlin(0,1,(200*~mapScaleCoeff)-10,0),
				~magEv.linexp(0,1,3*~pointScaleFact,7*~pointScaleFact),
				~magEv.linexp(0,1,3*~pointScaleFact,7*~pointScaleFact)
	 ));
	 Pen.draw(0); //fill
	 Pen.strokeColor = Color.cyan; // draw ripples
	 Pen.strokeOval(Rect(
				7+~longEv.linlin(0,1,0,(200*~mapScaleCoeff)-10)
				-(~magEv.linlin(0,1,8*~pointScaleFact,20*~pointScaleFact)/pi),
				7+~latEv.linlin(0,1,(200*~mapScaleCoeff)-10,0)
				-(~magEv.linlin(0,1,8*~pointScaleFact,20*~pointScaleFact)/pi),
				~magEv.linexp(0,1,8*~pointScaleFact,20*~pointScaleFact),
				~magEv.linexp(0,1,8*~pointScaleFact,20*~pointScaleFact)
	 ));
	 Pen.draw(2); //stroke


	 Pen.fillColor = Color.grey(0.3); // draw head
	 Pen.fillOval(Rect(
			10+~padX.linlin(0,1,0,(200*~mapScaleCoeff)-20)
				+ h.value.linlin(0,1,0*~pointScaleFact,5*~pointScaleFact),
			10+~padY.linlin(0,1,(200*~mapScaleCoeff)-20,0),
			10*~pointScaleFact,
			10*~pointScaleFact
	 ));
     Pen.strokeColor_(Color.black);
	 Pen.strokeOval(Rect(
			10+~padX.linlin(0,1,0,(200*~mapScaleCoeff)-20),
			10+~padY.linlin(0,1,(200*~mapScaleCoeff)-20,0),
			h.value.linlin(0,1,8*~pointScaleFact,20*~pointScaleFact),
			10*~pointScaleFact
	 ));
	 Pen.draw(0); // fill
	 Pen.draw(2); // stroke
	 };

	 ~mapView.refresh;
	 w.refresh;
	 if(v.isClosed.not, {v.refresh});

	 ~local_coordinates.string =
		"long "++
		~padX.linlin(0,1,-24.804, -14.334).round(0.001).asString ++
		" °\f lat "++
		~padY.linlin(0,1, 63.168, 67.311).round(0.001).asString ++
		" °\ndepth -"++
		~flex.linlin(580,780,25,0).round(0.001).asString ++" km";
// add knobs actions (h, a, k variables)
	}.defer;

	0.03.wait; // UPDATED EVERY 30ms
}}).play;
}; //ee

"- - - - - - environment is set up! - - - - - - -".postln;
)
//////////////////////////////////////////////////////////////////////
( // stop
Tdef(\binauralRev).stop;
Tdef(\eventStream).stop;
~calendar.release(1);
)
// audio test
Synth(\synthello, [\freq, 100]);
Synth(\click, [\freq, 999]);


Tdef(\action).play;



Tdef(\eventStream).pause;
Tdef(\eventStream).play;
Tdef(\eventStream).stop;

