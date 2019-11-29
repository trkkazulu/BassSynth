;This will be an attempt to do the EHX Bass Micro Synth or somehting similar that i can use with Owen Lake. 
; Written by Jair-Rohm Parker Wells 2019
; The dilemma here is whether to go with the single fader Envelope Follwer here or do on that works more like the EHX pedal with two
; faders.
; This is making sense now. I'll probably start working on the GUI. 




<Cabbage>
form caption("BassSynth") size(600, 300), colour(58, 110, 182), pluginid("bsnt")

vslider bounds(26, 12, 50, 150), channel("sfreq"), range(40.00, 800.00, 0.0, 1, 1.0) text("StartFreq") ; Frequency selector
;vslider bounds(86, 12, 50, 150), channel("efreq"), range(40.00, 10000.00, 40, 1, 1.0) text("EndFreq")
vslider bounds(146, 12, 50, 150), channel("res"), range(0, 1, 0, 1, 0.001) text("Res")
vslider bounds(266, 12, 50, 150), channel("dist"), range(0, 1, 0, 1, 0.001) text("Dist")
vslider bounds(206, 12, 50, 150), channel("rate"), range(0, 1, 0, 1, 0.001) text("Rate")
vslider bounds(322, 10, 50, 150), channel("oct"), range(0, 15, 0, 1, 0.001) text("Oct")
vslider bounds(446, 10, 50, 150), channel("gain"), range(0, 1, 0, 1, 0.001) text("Synth") ; Fader for the synth processed sound
vslider bounds(526, 10, 50, 150), channel("gGain"), range(0, 1, 0, 1, 0.001) text("Guitar") ; Fader for the clean sound.


</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d 
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
;ksmps = 4
nchnls = 2
0dbfs = 1

;- Region: UDOs

opcode	OctaveDivider,a,akkk
	ain,kdivider,kInputFilt,kToneFilt	xin
	krms	rms		ain
		setksmps	1		;SET kr=sr, ksmps=1 (sample)
	kcount	init		0		;COUNTER USED TO COUNT ZERO CROSSINGS
	kout	init		-1		;INITIAL DISPOSITION OF OUTPUT SIGNAL
	ain	butlp		ain,kInputFilt	;LOWPASS FILTER THE INPUT SIGNAL (TO REMOVE SOME HF OVERTONE MATERIAL)
	ain	butlp		ain,kInputFilt	;LOWPASS FILTER THE INPUT SIGNAL (TO REMOVE SOME HF OVERTONE MATERIAL)
	ain	butlp		ain,kInputFilt	;LOWPASS FILTER THE INPUT SIGNAL (TO REMOVE SOME HF OVERTONE MATERIAL)
	ksig	downsamp	ain		;CREATE A K-RATE VERSION OF THE INPUT AUDIO SIGNAL
	ktrig	trigger		ksig,0,2	;IF THE INPUT AUDIO SIGNAL (K-RATE VERSION) CROSSES ZERO IN EITHER DIRECTION, GENERATE A TRIGGER
	if ktrig==1 then			;IF A TRIGGER HAS BEEN GENERATED...
	 kcount	wrap	kcount+1,0,kdivider	;INCREMENT COUNTER BUT WRAPAROUND ACCORDING TO THE NUMBER OF FREQUENCY DIVISIONS REQUIRED
	 if kcount=0 then			;IF WE HAVE COMPLETED A DIVISION BLOCK (I.E. COUNTER HAS JUST WRAPPED AROUND)...
	  kout =	(kout=-1?1:-1)		;FLIP THE OUTPUT SIGNAL BETWEEN -1 AND 1 (THIS WILL CREATE A SQUARE WAVE)
	 endif
	endif
	aout	upsamp		kout		;CREATE A-RATE SIGNAL FROM K-RATE SIGNAL
	aout	butlp		aout,kToneFilt	;FILTER THE OUTPUT TONE
		xout		aout*krms	;SEND AUDIO BACK TO CALLER INSTRUMENT, SCALE ACCORDING TO THE ENVELOPE FOLLOW OF THE INPUT SIGNAL
endop

opcode	EnvelopeFollower,a,akkkkk
	ain,ksens,katt,krel,kfreq,kres	xin	
	setksmps	4

	aFollow		follow2		ain, katt, krel			; AMPLITUDE FOLLOWING AUDIO SIGNAL
	kFollow		downsamp	aFollow				; DOWNSAMPLE TO K-RATE
	kFollow		expcurve	kFollow/0dbfs,0.5		; ADJUSTMENT OF THE RESPONSE OF DYNAMICS TO FILTER FREQUENCY MODULATION
	kFrq = kfreq + (kFollow*ksens*10000)	; CREATE A LEFT CHANNEL MODULATING FREQUENCY BASE ON THE STATIC VALUE CREATED BY kfreq AND THE AMOUNT OF DYNAMIC ENVELOPE FOLLOWING GOVERNED BY ksens
	kFrq		limit		kFrq, 20,sr/2			; LIMIT FREQUENCY RANGE TO PREVENT OUT OF RANGE FREQUENCIES  

 aout		moogladder	ain, kFrq, kres			; REDEFINE AUDIO SIGNAL AS FILTERED VERSION OF ITSELF
	
			xout		aout				; SEND AUDIO BACK TO CALLER INSTRUMENT
endop


instr 1
kFreq chnget "sfreq"
kEfreq chnget "efreq"
kRes chnget "rate"
kRate chnget "res"
kOct chnget "oct"
kDist chnget "dist"
kVol chnget "gain"
kVol2 chnget "gGain"
ksens = 0.5
katt = kRate
krel = 0.3
kfreq = kFreq
kres = kRes
gifn	ftgen	0,0, 257, 9, .5,1,270	



;- Region: Input Section 
;+++++++++++++++++++++++++++++++++++++++
a1 inch 1
;a2 inch 2

;a1 diskin2 "OLBass.wav", 1,0,1
;++++++++++++++++++++++++++++++++++++++++

;aFilter moogladder2 a1, kFreq, 0.7

;aFilter2 moogladder2 a1, kEfreq, 0.7

aDist distort a1, kDist, gifn

aDist lpf18 aDist, 800, .5, .2

kLine linseg 0.0, 0.02, 1.0

aFilter moogladder2 a1, kFreq, kRes

aFilter = aFilter*kVol

aDist = aDist*kDist

aClean = a1*kVol2

aout EnvelopeFollower a1,ksens,katt,krel,kFreq,kres

aout = aout*kVol

aOct OctaveDivider a1, 2, 220.00, 80.00

aOct compress aOct, aOct, -12, 48, 48, 2, .01, .5, .02

aOct = aOct*kOct

asig = (aOct+aFilter+aout+aDist+aClean)

;- Region: Output Section

outs asig, asig

endin

</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
f0 z
;starts instrument 1 and runs it for a week
i1 0 [60*60*24*7] 
</CsScore>
</CsoundSynthesizer>
