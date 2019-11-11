;This will be an attempt to do the EHX Bass Micro Synth or somehting similar that i can use with Owen Lake. 
; Written by Jair-Rohm Parker Wells 2019




<Cabbage>
form caption("BassSynth") size(400, 300), colour(58, 110, 182), pluginid("def1")

vslider bounds(26, 12, 50, 150), channel("sfreq"), range(40.00, 800.00, 60, 1, 1.0) text("StartFreq")
vslider bounds(86, 12, 50, 150), channel("efreq"), range(40.00, 10000.00, 40, 1, 1.0) text("EndFreq")
vslider bounds(146, 12, 50, 150), channel("res"), range(0, 1, 0, 1, 0.001) text("Res")
vslider bounds(266, 12, 50, 150), channel("dist"), range(0, 1, 0, 1, 0.001) text("Dist")
vslider bounds(206, 12, 50, 150), channel("rate"), range(0, 1, 0, 1, 0.001) text("Rate")
vslider bounds(322, 10, 50, 150), channel("oct"), range(0, 1, 0, 1, 0.001) text("Oct")
rslider bounds(144, 208, 60, 60), channel("gain"), range(0, 5.0, 0, 1, 1.0) text("Volume")
rslider bounds(20, 208, 60, 60), channel("gGain"), range(0, 5.0, 0, 1, 1.0) text("Clean Volume")

</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 -m0d 
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
ksmps = 32
nchnls = 2
0dbfs = 1

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
kRes chnget "res"
kRate chnget "rate"
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



;a1 inch 1
;a2 inch 2

a1 diskin2 "OLBass.wav", 1,0,1

;aFilter moogladder2 a1, kFreq, 0.7

;aFilter2 moogladder2 a1, kEfreq, 0.7

aDist distort a1, kDist, gifn

kLine linseg 0.0, 0.02, 1.0

aFilter moogladder2 a1, kFreq, kRate
;kEnv adsr 0.4, 0.6, 0.5, 0.3

aout EnvelopeFollower a1,ksens,katt,krel,kEfreq,kres*0.95

;aFilter = (aFilter*aout)

asig = (aout+aFilter+aDist*0.3+kVol2)



outs asig*kVol, asig*kVol

endin

</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
f0 z
;starts instrument 1 and runs it for a week
i1 0 [60*60*24*7] 
</CsScore>
</CsoundSynthesizer>
