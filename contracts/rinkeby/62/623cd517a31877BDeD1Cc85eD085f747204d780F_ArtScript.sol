// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArtScript {
    string public constant PROJECT_NAME = "It's (a)live";
    string public constant ARTIST_NAME = "Tibout Shaik";
    string public constant EXTERNAL_LIBRARY = "None";
    string public constant TWOFIVESIX_LIBRARY = "None";
    string public constant LICENSE = "NFT License";
    string public constant ARTSCRIPT = "class Random{constructor(){this.useA=!1;let a=function(a){let t=parseInt(a.substr(0,8),16),e=parseInt(a.substr(8,8),16),n=parseInt(a.substr(16,8),16),c=parseInt(a.substr(24,8),16);return function(){t|=0,e|=0,n|=0,c|=0;let a=(t+e|0)+c|0;return c=c+1|0,t=e^e>>>9,e=n+(n<<3)|0,n=n<<21|n>>>11,n=n+a|0,(a>>>0)/4294967296}};this.prngA=new a(inputData.hash.substr(2,32)),this.prngB=new a(inputData.hash.substr(34,32));for(let a=0;a<1e6;a+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}function setup(){let a=Math.min(window.innerWidth,window.innerHeight);canvas.width=a,canvas.height=1.35*a,document.body.appendChild(canvas)}async function draw(){let a=canvas.getContext('2d',{alpha:!1}),t=new Random;async function e(e,c,r,i,h,d,s,o,l){let v=r-e,f=i-c;a.beginPath(),a.moveTo(e,c);for(let r=0;r<d;r++){a.lineWidth=t.random_dec()*(canvas.width/1500)*o;let r=c+f*t.random_dec(),i=e+v*t.random_dec();a.lineTo(i,r),a.strokeStyle=n(h,t.random_dec()*(-1*l)+l),a.globalAlpha=t.random_dec()*s,a.stroke(),a.beginPath(),a.moveTo(i,r)}a.globalAlpha=1}function n(a,t){a=a.substr(1);var e=parseInt(a,16),n=Math.round(2.55*t),c=(e>>16)+n,r=(e>>8&255)+n,i=(255&e)+n;return'#'+(16777216+65536*(c<255?c<1?0:c:255)+256*(r<255?r<1?0:r:255)+(i<255?i<1?0:i:255)).toString(16).slice(1)}function c(a,t,e){t=100+t,a=a.substr(1);let n,c,r,i=parseInt(a,16);return e?(n=Math.round(255-255*t/150+(i>>16)),c=Math.round(255-255*t/150+(i>>8&255)),r=Math.round(255-255*t/150+(255&i))):(n=Math.round((i>>16)*t/150),c=Math.round((i>>8&255)*t/150),r=Math.round((255&i)*t/150)),'#'+(16777216+65536*(n<255?n<1?0:n:255)+256*(c<255?c<1?0:c:255)+(r<255?r<1?0:r:255)).toString(16).slice(1)}let r=c('#'+Math.floor(16777215*Math.random()).toString(16),-52),i=c('#'+Math.floor(16777215*Math.random()).toString(16),-52),h=t.random_dec()>=.55,d=t.random_dec()>=.2;a.fillStyle=h?'#0c0c0c':'#efefef',a.fillRect(0,0,canvas.width,canvas.height);let s=.02*canvas.width,o=h?n('#ffffff',-15):'#000000';await e(.15*-canvas.width,.15*-canvas.height,1.3*canvas.width,1.3*canvas.height,h?'#000000':n('#ffffff',-15),5e4,1,2,15),await e(0,0,canvas.width,s,o,2e3,1,2,15),await e(0,canvas.height-s,canvas.width,canvas.height,o,2e3,1,2,15),await e(0,0,s,canvas.height,o,2700,1,2,15),await e(canvas.width-s,0,canvas.width,canvas.height,o,2700,1,2,15);let l=document.createElement('canvas');l.width=canvas.width,l.height=canvas.height,l.ctx=l.getContext('2d'),l.ctx.drawImage(canvas,0,0),await e(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,d?h?n('#ffffff',-15):'#000000':h?'#000000':n('#ffffff',-15),67500,1,2,15);let v=document.createElement('canvas');v.width=canvas.width,v.height=canvas.height,v.ctx=v.getContext('2d'),v.ctx.drawImage(canvas,0,0),a.drawImage(l,0,0),await e(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,d?h?n('#ffffff',-15):'#000000':h?'#000000':n('#ffffff',-15),67500,1,2,15);let f=document.createElement('canvas');f.width=canvas.width,f.height=canvas.height,f.ctx=f.getContext('2d'),f.ctx.drawImage(canvas,0,0),a.drawImage(l,0,0);let g=[],m=t.random_dec()>=.24,w=t.random_dec()>=.24,u=t.random_dec()/1.5+1,_=Math.floor(22*t.random_dec())+10,y=t.random_dec()>=.84,p=t.random_dec()>=.24,x=h?'#efefef':'#0c0c0c',I=.005*canvas.width*u,M=h?'#0c0c0c':'#efefef',b=h?'#efefef':'#0c0c0c',P=Math.round(10*t.random_dec()),C=360*t.random_dec()*(Math.PI/180),k=Math.round(10+246*t.random_dec()),S=1-t.random_dec();function D(){let e,n,c,r;a.strokeStyle=x,a.beginPath();for(let t=0;t<g.length;t++)e=g[t].x,n=g[t].y,0==t&&a.moveTo(e,n),t==g.length-1?(c=g[0].x,r=g[0].y):(c=g[t+1].x,r=g[t+1].y),a.lineWidth=I,a.lineTo(c,r),a.stroke(),e=c,n=r;a.closePath(),a.save(),a.clip(),a.drawImage(t.random_dec()>=.5?f:v,0,0,canvas.width,canvas.height),a.translate(canvas.width/2,canvas.height/2),a.rotate(C),a.drawImage(t.random_dec()>=.5?f:v,-canvas.width/2,-canvas.height/2,canvas.width,canvas.height),a.rotate(-C),a.translate(-canvas.width/2,-canvas.height/2),a.fillStyle=M,a.strokeStyle=b,a.lineWidth=.002*canvas.width*u;for(let t=0;t<g.length;t++)if(g[t].isCircle){a.beginPath(),a.arc(g[t].x,g[t].y,.03*canvas.width*g[t].enlarger,0,2*Math.PI),a.closePath(),a.fillStyle=g[t].circleFill,a.fill(),a.stroke();for(let e=0;e<g[t].innerCircles;e++)a.beginPath(),a.arc(g[t].x,g[t].y,.02*canvas.width/e*g[t].enlarger,0,2*Math.PI),a.closePath(),a.stroke()}else{let e=.03*canvas.width*g[t].enlarger*1.25;a.fillStyle=g[t].circleFill,C=Math.PI/180*45,a.translate(g[t].x,g[t].y),a.rotate(C),a.beginPath(),a.rect(-e/2,-e/2,e,e),a.closePath(),a.fill(),a.stroke();for(let e=0;e<g[t].innerCircles;e++){let n=.02*canvas.width/e*g[t].enlarger*1.25;a.beginPath(),a.rect(-n/2,-n/2,n,n),a.closePath(),a.stroke()}a.rotate(-C),a.translate(-g[t].x,-g[t].y)}a.restore()}for(let a=0;a<_;a++){let a=u;m||(a=t.random_dec()/1.5+1);let e=P;w||(e=Math.round(10*t.random_dec()));let n=p;y&&(n=t.random_dec()>=.5),g.push({x:.8*canvas.width*t.random_dec()+.1*canvas.width,y:.8*canvas.height*t.random_dec()+.1*canvas.height,circleFill:t.random_dec()>=S?t.random_dec()>=.5?r:i:M,xDirection:t.random_dec()>=.5?1:-1,yDirection:t.random_dec()>=.5?1:-1,enlarger:a,innerCircles:e,isCircle:n})}D();let A=!1,E=20;function F(e,n){if(!A){let c=[];e&&(P=Math.round(10*t.random_dec()));for(let a=0;a<g.length;a++){let h=g[a].x+canvas.width/750*t.random_dec()*g[a].xDirection;h>.9*canvas.width&&(h=.9*canvas.width),h<.1*canvas.width&&(h=.1*canvas.width);let d=g[a].y+canvas.height/750*t.random_dec()*g[a].yDirection;d>.9*canvas.height&&(d=.9*canvas.height),d<.1*canvas.height&&(d=.1*canvas.height);let s=g[a].circleFill;e&&(s=t.random_dec()>=S?t.random_dec()>=.5?r:i:M,w||(P=Math.round(10*t.random_dec())));let o=g[a].xDirection,l=g[a].yDirection;n&&(o=t.random_dec()>=.5?1:-1,l=t.random_dec()>=.5?1:-1),c.push({x:h,y:d,circleFill:s,xDirection:o,yDirection:l,enlarger:g[a].enlarger,innerCircles:e?P:g[a].innerCircles,isCircle:g[a].isCircle})}g=c,a.drawImage(l,0,0),D()}}async function T(){W++,C=360*t.random_dec()*(Math.PI/180),W%k==0?F(!0,!0):F(!1,!1)}let W=0,B=setInterval(T,E);document.addEventListener('keydown',(function(a){const t=a.key;'p'==t&&(A=!A),'f'==t&&E>1&&(E/=1.5,clearInterval(B),B=setInterval(T,E)),'s'==t&&(E*=1.5,clearInterval(B),B=setInterval(T,E))}))}let canvas=document.createElement('canvas');setup(),draw();";
    string public constant HEAD =
        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'> <style type='text/css'> html{height: 100%; width: 100%;}body{height: 100%; width: 100%; margin: 0; padding: 0; background-color: rgb(40, 40, 40);}canvas{display: block; max-width: 100%; max-height: 100%; padding: 0; margin: auto; display: block; position: absolute; top: 0; bottom: 0; left: 0; right: 0; object-fit: contain;}</style>";

    function projectName() external pure returns (string memory) {
        return PROJECT_NAME;
    }

    function artistName() external pure returns (string memory) {
        return ARTIST_NAME;
    }

    function externalLibrary() external pure returns (string memory) {
        return EXTERNAL_LIBRARY;
    }

    function twoFiveSixLibrary() external pure returns (string memory) {
        return TWOFIVESIX_LIBRARY;
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
}