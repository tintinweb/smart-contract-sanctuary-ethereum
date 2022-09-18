// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtScript is Ownable {
    string public constant PROJECT_NAME = "Entangled";
    string public constant ARTIST_NAME = "Tezumie";
    string public externalLibraryUsed =
        "https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.4.1/p5.min.js";
    string public twofivesixLibraryUsed = "None";
    string public constant LICENSE = "NFT License 2.0";
    string public constant ARTSCRIPT =
        "let l=0,CF,MS,CF2,MS2,t,A,ld,S,wv,f,c,h,C,C2,lv,fc,N,tr,fu,ts,dc,vc,gc,lr,lg,lb,pt,R,DS,WI,hs,HE,DIM,M,ll,lw,r,x,y,hc,ht,sc,hz,aspectRatio,p,H,HF,HH,GD,s,fcc,fl,LV,sv,z,fs;function setup(){let a=123456789*(R=new Random).random_dec();randomSeed(a),noiseSeed(a),DS=100*int(random(12,14.99)),HE=random(hs=[WI=2*window.innerWidth,WI/.75,.75*WI]),DIM=Math.min(WI,HE),M=DIM/DS,aspectRatio=WI/HE,createCanvas(WI,HE),strokeWeight(1*M),pt=int(random(1,25.99)),z=random(-25,25),c=new Colors,c.choose(),background(C),gr=drawingContext.createLinearGradient(width/2,0,width/2,height),gr.addColorStop(0,C),gr.addColorStop(1,C2),drawingContext.fillStyle=gr,rect(0,0,width,height),noLoop(),angleMode(DEGREES),ll=random(20,55),lw=random(25,40),r=random(.2*width,.8*width),x=random(width),y=random(height),hc=random(1),ht=random(1),HF=random(1),GD=0,s=random(1),pixelDensity(1)}function draw(){SF(),MS.rect(0,0,width,height),image(MS,0,0),SF2();let b=width/random(9.5,10.5)*1.2,d=width/random(13.5,16.5)*1.2;hz=random(-100*M,300*M);for(let e=0;e<=8;e++)push(),translate(random(width),height/2+hz),(t=new T2(0)).draw(),c.choose(),pop(),push(),translate(random(width),height/2+hz),(t=new T2(0)).draw(),c.choose(),pop(),push(),new L(height/2+hz,s),pop(),hz+=200*M,l=0;if(image(MS2,0,0),1==(fs=int(random(1,4.15)))&&(noFill(),(gr=drawingContext.createLinearGradient(width/2,0,width/2,height)).addColorStop(0,lv),gr.addColorStop(1,C2),drawingContext.strokeStyle=gr,strokeWeight(b),rect(0,0,width,height),stroke(C),strokeWeight(d),rect(0,0,width,height),stroke(N),strokeWeight(1*M),rect(b/2,b/2,width-b,height-b),rect(d/2,d/2,width-d,height-d)),2==fs){noStroke();let a=random(75*M,125*M);rect(0,0,a,height),rect(0,0,width,a),rect(width-a,0,a,height),rect(0,height-a,width,a),SF2(),MS2.noStroke(),MS2.rect(0,0,a,height),MS2.rect(0,0,width,a),MS2.rect(width-a,0,a,height),MS2.rect(0,height-a,width,a),image(MS2,0,0),noFill(),stroke(C),strokeWeight(random(75*M,100*M)),rect(0,0,width,height)}3==fs&&(noFill(),stroke(C),strokeWeight(random(75*M,100*M)),rect(0,0,width,height))}class Random{constructor(){this.useA=!1;let a=function(a){let b=parseInt(a.substr(0,8),16),d=parseInt(a.substr(8,8),16),e=parseInt(a.substr(16,8),16),g=parseInt(a.substr(24,8),16);return function(){e|=0;let a=((b|=0)+(d|=0)|0)+(g|=0)|0;return g=g+1|0,b=d^d>>>9,d=e+(e<<3)|0,e=e<<21|e>>>11,e=e+a|0,(a>>>0)/4294967296}};this.prngA=new a(inputData.hash.substr(2,32)),this.prngB=new a(inputData.hash.substr(34,32));for(let b=0;b<1e6;b+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}function L(a,b){for(this.n=a-350*M,this.N=a,this.yo=0,this.s=b,this.sc=18*M,this.i=0;this.i<=30;this.i++){for(this.xo=0,this.x=0;this.x<=width;this.x+=this.sc)this.y=map(noise(this.xo,this.yo),0,1,this.n,this.N),stroke(N),fill(dc),this.s>.5?ellipse(this.x,this.y-this.sc,this.sc):rect(this.x,this.y-this.sc,this.sc),this.cg=random(1),fill(gc),stroke(S),strokeWeight(1*M),this.cg>.75&&(this.sx=random(-30*M,30*M),this.sy=random(-5*M,38*M),this.sx2=random(-85*M,85*M),this.length=random(75*M,160*M),this.length2=random(100*M,160*M),this.width1=10*M,fill(gc),beginShape(),vertex(this.x,this.y),bezierVertex(this.x,this.y,this.x-1.2*this.width1+this.sx,this.y-this.length2,this.x+this.width1/2+this.sx2,this.y-this.length-this.sy),bezierVertex(this.x+this.width1/2+this.sx2,this.y-this.length-this.sy,this.x+1.2*this.width1+this.sx,this.y-this.length2,this.x,this.y),endShape(CLOSE)),this.cw=random(1e3),(this.cw>999.93&&GD<4||0==GD)&&((wv=new W(this.x,this.y)).draw(),GD+=1),this.cf=random(10),this.cf>9.945&&(sv=new ST(this.x,this.y)).draw(),this.xo+=.05;this.n+=this.sc,this.N+=this.sc,this.yo+=.01}}class W{constructor(a,b){this.x=a,this.y=b,this.s=2200*M,this.ss=this.s/3,this.xt=this.x+random(-1e3*M,1e3*M),this.xo=this.x+random(-700*M,700*M),this.xo2=this.x+random(-855*M,855*M),this.yt=this.y-this.s,this.yt=-5*M}draw(){for(noFill(),strokeWeight(10*M),stroke(S),bezier(this.x,this.y,this.xo,this.y-this.ss,this.xo2,this.y-2*this.ss,this.xt,this.yt),stroke(vc),strokeWeight(8*M),bezier(this.x,this.y,this.xo,this.y-this.ss,this.xo2,this.y-2*this.ss,this.xt,this.yt),stroke(S),this.i=0;this.i<=20;this.i++)this.t=this.i/20,this.x2=bezierPoint(this.x,this.xo,this.xo2,this.xt,this.t),this.y2=bezierPoint(this.y,this.y-this.ss,this.y-2*this.ss,this.yt,this.t),this.h=random(1),this.bd=random(1),this.bl=random(500*M,1200*M),this.bd<.5?(this.bs=-this.bl/3,this.yo=this.y2-random(-90*M,90*M),this.yo2=this.y2-random(-199*M,550*M),this.xe=this.x2-this.bl,this.ye=this.y2-random(80*M,1505*M),this.ye=-5*M):(this.bs=this.bl/3,this.yo=this.y2-random(-90*M,90*M),this.yo2=this.y2-random(-199*M,550*M),this.xe=this.x2+this.bl,this.ye=this.y2-random(80*M,1505*M),this.ye=-5*M),this.h>.3&&(strokeWeight(8*M),stroke(S),bezier(this.x2,this.y2,this.x2+this.bs,this.yo,this.x2+2*this.bs,this.yo2,this.xe,this.ye),strokeWeight(6*M),stroke(vc),bezier(this.x2,this.y2,this.x2+this.bs,this.yo,this.x2+2*this.bs,this.yo2,this.xe,this.ye),stroke(S));strokeWeight(1*M),noFill()}}class ST{constructor(a,b){this.x=a,this.x1=this.x,this.y=b,this.y1=this.y}draw(){for(this.lf=.75,this.r=4,this.lg=random(150*M,250*M),this.xo=40,this.y2=this.y-this.lg/3,this.y3=this.y-this.lg/3*2,this.y4=this.y-this.lg,this.x2=this.x+random(-this.xo*M,this.xo*M),this.x3=this.x+random(-(2*this.xo)*M,2*this.xo*M),this.x4=this.x+random(-(2.25*this.xo)*M,2.25*this.xo*M),noFill(),strokeWeight(8*M),bezier(this.x,this.y,this.x2,this.y2,this.x3,this.y3,this.x4,this.y4),stroke(vc),strokeWeight(6*M),bezier(this.x,this.y,this.x2,this.y2,this.x3,this.y3,this.x4,this.y4),fill(C),stroke(S),strokeWeight(1*M),this.i=0;this.i<=this.r;this.i++)this.t=this.i/this.r,this.xa=bezierPoint(this.x1,this.x2,this.x3,this.x4,this.t),this.ya=bezierPoint(this.y1,this.y2,this.y3,this.y4,this.t),this.hl=random(1),this.ya>this.y4&&this.hl>.15&&(LV=new LF(this.xa,this.ya,this.lf)).draw();(f=new F(this.x4,this.y4)).draw()}}class LF{constructor(a,b,d){this.xo=a,this.yo=b,this.x=0,this.y=0,this.s1=random(33*M,40*M)*d,this.s2=this.s1/2,this.s3=.9*this.s1,this.s4=this.s3/3,this.as=[random(-45,-20),random(20,45)],this.an=random(this.as),this.pa=3,this.rt=random(35,40)/this.pa}draw(){fill(fl),stroke(ts),push(),translate(this.xo,this.yo),rotate(this.an),beginShape(),vertex(this.x,this.y),bezierVertex(this.x,this.y,this.x-this.s1/1.5,this.y-this.s1,this.x,this.y-1.85*this.s1),bezierVertex(this.x,this.y-1.85*this.s1,this.x+this.s1/1.5,this.y-this.s1,this.x,this.y),endShape(CLOSE),bezier(this.x,this.y,this.x,this.y-this.s1,this.x,this.y-this.s1,this.x,this.y-this.s1*random(1.15,1.65)),pop(),this.double=random(1),this.double>.4&&(push(),translate(this.xo,this.yo),this.an=this.an*random(1.2),rotate(-1*this.an),beginShape(),vertex(this.x,this.y),bezierVertex(this.x,this.y,this.x-this.s1/2,this.y-this.s1,this.x,this.y-1.85*this.s1),bezierVertex(this.x,this.y-1.85*this.s1,this.x+this.s1/2,this.y-this.s1,this.x,this.y),endShape(CLOSE),bezier(this.x,this.y,this.x,this.y-this.s1,this.x,this.y-this.s1,this.x,this.y-this.s1*random(1.15,1.65)),pop())}}class F{constructor(a,b){this.xo=a,this.yo=b,this.x=0,this.y=0,this.s1=random(75*M,90*M)/3.3,this.s2=this.s1/2,this.s3=.7*this.s1,this.s4=this.s3/3,this.lo=random(-this.s1/8,this.s1/8),this.an=random(180),this.pa=int(random(4,6.99)),this.rt=360/this.pa}draw(){for(fill(fc),stroke(ts),push(),translate(this.xo,this.yo),rotate(this.an),this.i=0;this.i<this.pa;this.i++)beginShape(),vertex(this.x,this.y),bezierVertex(this.x,this.y,this.x-this.s2,this.y-this.s4,this.x-this.s3,this.y-this.s3+this.lo),bezierVertex(this.x-this.s3,this.y-this.s3+this.lo,this.x+this.s2,this.y-this.s4,this.x,this.y),this.lo=random(-this.s1/5,this.s1/5),endShape(CLOSE),rotate(this.rt);for(pop(),push(),translate(this.xo,this.yo),rotate(this.an),this.i=0;this.i<this.pa;this.i++)this.lo=random(-this.s1/5,this.s1/5),beginShape(),vertex(this.x,this.y),bezierVertex(this.x,this.y,this.x-.8*this.s1+this.lo,this.y-this.s1,this.x,this.y-1.2*this.s1),bezierVertex(this.x,this.y-1.2*this.s1,this.x+.8*this.s1,this.y-this.s1,this.x,this.y),endShape(CLOSE),bezier(this.x,this.y,this.x-.8*this.s1/4,this.y-this.s1/3,this.x-.8*this.s1/4,this.y-this.s1/2,this.x-this.s1/6,this.y-this.s1/random(1.1,1.7)),bezier(this.x,this.y,this.x+.8*this.s1/4,this.y-this.s1/3,this.x+.8*this.s1/4,this.y-this.s1/2,this.x+this.s1/6,this.y-this.s1/random(1.1,1.7)),rotate(this.rt+random(-7,7));fill(fcc),ellipse(this.x,this.y,this.s1/random(2.7,5)),pop()}}class T2{constructor(a){this.l=a,this.xo=0}draw(){if(this.xo=0,0==l&&(this.l=225*M,l+=1,this.xo=0),this.l>80*M?this.tw=1.8*this.l/10:this.tw=1.5*this.l/10,this.l>16*M)for(noStroke(),fill(tr),quad(0-this.tw/2,-this.l-5*M,0-this.tw/2-1*M,0,0+this.tw/2+1*M,0,0+this.tw/2,-this.l-5*M),stroke(ts),strokeWeight(1*M),line(0-this.tw/2,-this.l-5*M,0-this.tw/2-1*M,0),line(0+this.tw/2,-this.l-5*M,0+this.tw/2+1*M,0),this.i=0;this.i<=10;this.i++)this.t=this.i/10,this.xa=bezierPoint(0-this.tw/2,0-this.tw/2-.5*M,0-this.tw/2-1*M,0-this.tw/2-1*M,this.t),this.ya=bezierPoint(-this.l-5*M,-this.l-5*M,0,0,this.t),line(this.xa,this.ya,this.xa+random(this.tw/3),this.ya);else line(0-this.tw/2,-this.l,0-this.tw/2,0);this.l<35*M&&(c.l(),this.cl=random(1),this.cl>.7&&(this.ly=random(-30*M,30*M),fill(lv),stroke(S),line(0-this.tw/2,-this.l,0-this.tw/2,0),beginShape(),vertex(0,-this.l),bezierVertex(0,-this.l,-lw*M,-this.l-10*M,0+this.ly,-this.l-ll*M),bezierVertex(0+this.ly,-this.l-ll*M,lw*M,-this.l-10*M,0,-this.l),endShape(CLOSE),bezier(0,-this.l,-lw/3*M,-this.l-10*M,lw/3*M,-this.l-10*M,0+this.ly,-this.l-ll*M)),this.c=random(10),this.c>9.97&&HF>.5&&(fill(fu),ellipse(0+this.tw/2+30*M,-this.l-10*M,30*M),noFill())),translate(this.xo,-this.l),this.l>16*M&&(this.d=random(1),this.b=random(1),ld=random(.7,.955),(this.d>.5||this.b>.3)&&(push(),rotate((A=this.l>175*M?random(50):random(80))/2),(t=new T2(this.l*ld)).draw(),pop()),(this.d<=.5||this.b>.3)&&(push(),rotate(-(A=this.l>175*M?random(50):random(80))/2),(t=new T2(this.l*ld)).draw(),pop()))}}function SF(){for((CF=createGraphics(width,height)).stroke(S),CF.fill(C),(gr=drawingContext.createLinearGradient(width/2,0,width/2,height)).addColorStop(0,C2),gr.addColorStop(.65,C),gr.addColorStop(1,C),CF.drawingContext.fillStyle=gr,CF.rect(0,0,width,height),CF.strokeWeight(1*M),CF.stroke(N),this.yo=0,this.ro=0,this.i=0;this.i<HE;this.i++){for(this.xo=0,this.x=0;this.x<=WI;this.x+=9*M)this.y=map(noise(this.xo,this.yo),0,1,0+this.ro,0),CF.line(this.x,this.y,this.x-10*M,this.y+20*M),this.xo+=.001;this.ro+=45*M,this.yo+=61e-5}(MS=createGraphics(width,height))._renderer._setFill(MS.drawingContext.createPattern(CF.canvas,"
        "))}function SF2(){for((CF2=createGraphics(width,height)).stroke(N),CF2.fill(C),(gr=drawingContext.createLinearGradient(width/2,0,width/2,height)).addColorStop(0,C),gr.addColorStop(1,C2),CF2.drawingContext.fillStyle=gr,CF2.rect(0,0,width,height),CF2.strokeWeight(1*M),this.yo=0,this.ro=0,this.i=0;this.i<HE;this.i++){for(this.xo=0,this.x=0;this.x<=WI;this.x+=10*M)this.y=map(noise(this.xo,this.yo),0,1,0+this.ro,0),CF2.line(this.x,this.y,this.x+10*M,this.y+20*M),this.xo+=.01;this.ro+=45*M,this.yo+=5101e-8}(MS2=createGraphics(width,height))._renderer._setFill(MS2.drawingContext.createPattern(CF2.canvas,"
        "))}class Colors{l(){3!=pt&&4!=pt&&12!=pt&&14!=pt&&15!=pt&&16!=pt&&17!=pt&&7!=pt&&24!=pt&&25!=pt&&(lr+=.0035,lg+=.0035,lb+=.0035,lv=color(lr,lg,lb))}choose(){1==pt&&(z=random(-25,25),S=color(0),N=color(0),C=color(238+z,194+z,167+z),C2=color(160+z,195+z,195+z),fc=color(245+z,244+z,143+z),fcc=C2,fl=color(161+z,141+z,129+z),tr=color(196+z,171+z,147+z),lr=184+z,lg=101+z,lb=73+z,lv=color(lr,lg,lb),fu=C2,ts=color(0),dc=C2,vc=tr,gc=lv),2==pt&&(z=random(-30,30),S=color(0),N=color(0),C=color(219+z,203+z,193+z),C2=color(249+z,238+z,231+z),fc=color(255+z,217+z,194+z),fcc=color(255),fl=color(161+z,141+z,129+z),tr=color(241+z,229+z,222+z),lr=192+z,lg=165+z,lb=148+z,lv=color(lr,lg,lb),fu=fcc,ts=color(0),dc=tr,vc=C2,gc=color(213+z,198+z,188+z)),3==pt&&(N=S=color(255),C=color(0),C2=C,fc=C,fcc=S,fl=C,tr=C,lr=0,lg=0,lb=0,lv=color(lr,lg,lb),fu=S,ts=S,dc=C,vc=C,gc=C),4==pt&&(N=S=color(0,31,133),C=color(237,238,221),C2=color(199,57,57),fc=color(151,207,220),fcc=C,fl=C,tr=C,lr=237,lg=238,lb=221,lv=color(lr,lg,lb),fu=C2,ts=S,dc=C2,vc=C,gc=C),5==pt&&(N=S=color(0),C=color(255),C2=C,fc=C,fcc=S,fl=C,tr=C,lr=255,lg=255,lb=255,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),6==pt&&(z=random(-20,20),S=color(0),N=color(0),C2=color(233+z,242+z,249+z),C=color(119+z,157+z,187+z),fc=color(186+z,216+z,240+z),fcc=C,fl=color(255),tr=C2,lr=119+z,lg=157+z,lb=187+z,lv=color(lr,lg,lb),fu=C2,ts=color(0),dc=C2,vc=C,gc=C),7==pt&&(z=random(-20,20),S=color(0),N=color(0),C=color(255+z,232+z,201+z),C2=color(206+z,128+z,93+z),fc=color(255+z,252+z,221+z),fcc=C2,fl=color(245+z,212+z,184+z),tr=color(255+z,252+z,221+z),lr=245+z,lg=222+z,lb=191+z,lv=color(lr,lg,lb),fu=C2,ts=color(0),dc=C2,vc=C,gc=color(245+z,222+z,191+z)),8==pt&&(N=S=color(45+(z=random(-20,20)),39+z,0+z),C=color(197+z,192+z,160+z),C2=color(234+z,226+z,175+z),fc=C2,fcc=C,fl=C,tr=C2,lr=197+z,lg=192+z,lb=160+z,lv=color(lr,lg,lb),fu=C2,ts=S,dc=C,vc=C2,gc=C2),9==pt&&(S=color(134,160,106),N=color(255),C=color(154,180,126),C2=color(214,236,189),fc=S,fcc=N,fl=C,tr=fc,lr=255,lg=255,lb=255,lv=color(lr,lg,lb),fu=S,ts=N,dc=C,vc=N,gc=N),10==pt&&(S=color(118,139,184),N=color(255),C=color(138,159,204),C2=color(226,230,239),fc=S,fcc=N,fl=C,tr=S,lr=255,lg=255,lb=255,lv=color(lr,lg,lb),fu=color(108,129,174),ts=N,dc=C,vc=N,gc=N),11==pt&&(S=color(194,50,50),N=color(255),C=color(214,70,70),C2=color(255,173,173),fc=color(100,177,226),fcc=S,fl=S,tr=S,lr=255,lg=255,lb=255,lv=color(lr,lg,lb),fu=fc,ts=N,dc=C,vc=N,gc=N),12==pt&&(S=color(243,239,220),N=color(0),C=S,C2=color(203,196,165),fc=color(201,58,58),fcc=N,fl=N,tr=N,lr=0,lg=0,lb=0,lv=color(lr,lg,lb),fu=fc,ts=S,dc=S,vc=N,gc=N),13==pt&&(z=random(-20,20),N=S=color(0),C=color(239+z,208+z,176+z),C2=color(160+z,195+z,195+z),fc=color(217+z,112+z,112+z),fcc=C2,fl=color(135+z,176+z,155+z),tr=color(196+z,171+z,147+z),lr=108+z,lg=136+z,lb=114+z,lv=color(lr,lg,lb),fu=color(255+z,165+z,109+z),ts=S,dc=C2,vc=tr,gc=color(109+z,146+z,132+z)),14==pt&&(N=S=color(0),C=color(150+z,188+z,211+z),C2=C,fc=C,fcc=C,fl=C,tr=C,lr=150+z,lg=188+z,lb=211+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),15==pt&&(N=S=color(0),C=color(251+z,122+z,122+z),C2=C,fc=C,fcc=C,fl=C,tr=C,lr=251+z,lg=122+z,lb=122+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),16==pt&&(N=S=color(0),C=color(150+z,189+z,151+z),C2=C,fc=C,fcc=C,fl=C,tr=C,lr=150+z,lg=189+z,lb=151+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),17==pt&&(N=S=color(53+z,54+z,24+z),C=color(247+z,248+z,219+z),C2=C,fc=C,fcc=C,fl=C,tr=C,lr=247+z,lg=248+z,lb=219+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),18==pt&&(z=random(-20,20),N=S=color(0),C2=color(249+z,242+z,233+z),C=color(222+z,75+z,75+z),fc=color(255+z,153+z,153+z),fcc=C2,fl=C2,tr=C2,lr=222+z,lg=75+z,lb=75+z,lv=color(lr,lg,lb),fu=C2,ts=S,dc=C2,vc=C,gc=C),19==pt&&(z=random(-20,20),N=S=color(0),C2=color(249+z,242+z,233+z),C=color(228+z,184+z,81+z),fc=color(255+z,243+z,84+z),fcc=C2,fl=C2,tr=C2,lr=228+z,lg=184+z,lb=81+z,lv=color(lr,lg,lb),fu=C2,ts=S,dc=C2,vc=C,gc=C),20==pt&&(N=S=color(random(90),random(90),random(90)),C2=color(random(190),random(190),random(190)),C=color(random(150,255),random(150,255),random(150,255)),fc=color(random(100,255),random(100,255),random(100,255)),fcc=color(random(100),random(100),random(100)),fl=color(random(150,255),random(150,255),random(150,255)),tr=color(random(190,255),random(190,255),random(190,255)),lr=random(150,255),lg=random(150,255),lb=random(150,255),lv=color(lr,lg,lb),fu=color(random(100,255),random(100,255),random(100,255)),ts=S,dc=C,vc=C,gc=lv,pt=20.1),21==pt&&(z=random(-30,30),S=color(0),N=color(0),C2=color(222+z,225+z,192+z),C=color(232+z,119+z,119+z),fc=color(135+z,175+z,208+z),fcc=C2,fl=C,tr=C2,lr=242+z,lg=152+z,lb=152+z,lv=color(lr,lg,lb),fu=color(135+z,175+z,208+z),ts=color(0),dc=color(222,225,192),vc=C2,gc=C2),22==pt&&(z=random(-30,30),S=color(0),N=color(0),C2=color(222+z,225+z,192+z),C=color(135+z,175+z,208+z),fc=color(255+z,153+z,153+z),fcc=color(174+z,239+z,232+z),fl=C,tr=C2,lr=135+z,lg=175+z,lb=208+z,lv=color(lr,lg,lb),fu=color(247+z,255+z,111+z),ts=color(0),dc=color(222,225,192),vc=C2,gc=C2),23==pt&&(z=random(-30,30),S=color(0),N=color(0),C2=color(222+z,225+z,192+z),C=color(107+z,134+z,102+z),fc=color(255+z,153+z,153+z),fcc=color(107+z,134+z,102+z),fl=color(222+z,225+z,192+z),tr=color(222+z,225+z,192+z),lr=107+z,lg=134+z,lb=102+z,lv=color(lr,lg,lb),fu=color(255+z,173+z,173+z),ts=color(0),dc=color(222+z,225+z,192+z),vc=color(222+z,225+z,192+z),gc=color(147+z,174+z,142+z)),24==pt&&(N=S=color(5,5,39),C=color(200+z,199+z,234+z),C2=C,fc=C,fcc=S,fl=C,tr=C,lr=200+z,lg=199+z,lb=234+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C),25==pt&&(N=S=color(0),C=color(255+z,246+z,125+z),C2=C,fc=C,fcc=S,fl=C,tr=C,lr=255+z,lg=246+z,lb=125+z,lv=color(lr,lg,lb),fu=C,ts=S,dc=C,vc=C,gc=C)}}";
    string public constant HEAD =
        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'> <style type='text/css'> html{height: 100%; width: 100%;}body{height: 100%; width: 100%; margin: 0; padding: 0; background-color: rgb(40, 40, 40);}canvas{display: block; max-width: 100%; max-height: 100%; padding: 0; margin: auto; display: block; position: absolute; top: 0; bottom: 0; left: 0; right: 0; object-fit: contain;}</style>";

    function projectName() external pure returns (string memory) {
        return PROJECT_NAME;
    }

    function artistName() external pure returns (string memory) {
        return ARTIST_NAME;
    }

    function externalLibrary() external view returns (string memory) {
        return externalLibraryUsed;
    }

    function twoFiveSixLibrary() external view returns (string memory) {
        return twofivesixLibraryUsed;
    }

    function license() external pure returns (string memory) {
        return LICENSE;
    }

    function artScript() external pure returns (string memory) {
        return ARTSCRIPT;
    }

    function head() external pure returns (string memory) {
        return HEAD;
    }

    function setExternalLibrary(string calldata _externalLibraryUsed)
        external
        onlyOwner
    {
        externalLibraryUsed = _externalLibraryUsed;
    }

    function setTwoFiveSixLibrary(string calldata _twoFiveSixLibraryUsed)
        external
        onlyOwner
    {
        twofivesixLibraryUsed = _twoFiveSixLibraryUsed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}