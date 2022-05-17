// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArtScript {
    string public constant PROJECT_NAME = "It's (a)live";
    string public constant ARTIST_NAME = "Tibout Shaik";
    string public constant EXTERNAL_LIBRARY = "None";
    string public constant TWOFIVESIX_LIBRARY = "None";
    string public constant LICENSE = "NFT License";
    string public constant ARTSCRIPT = "class Random{constructor(){this.useA=!1;let a=function(a){let e=parseInt(a.substr(0,8),16),t=parseInt(a.substr(8,8),16),n=parseInt(a.substr(16,8),16),c=parseInt(a.substr(24,8),16);return function(){e|=0,t|=0,n|=0,c|=0;let a=(e+t|0)+c|0;return c=c+1|0,e=t^t>>>9,t=n+(n<<3)|0,n=n<<21|n>>>11,n=n+a|0,(a>>>0)/4294967296}};this.prngA=new a(inputData.hash.substr(2,32)),this.prngB=new a(inputData.hash.substr(34,32));for(let a=0;a<1e6;a+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}function setup(){let a=Math.min(window.innerWidth,window.innerHeight);canvas.width=a,canvas.height=1.35*a,document.body.appendChild(canvas)}async function draw(){let a=canvas.getContext('2d',{alpha:!1}),e=new Random;async function t(t,c,i,r,d,h,s,l,o){let f=i-t,v=r-c;a.beginPath(),a.moveTo(t,c);for(let i=0;i<h;i++){a.lineWidth=e.random_dec()*(canvas.width/1500)*l;let i=c+v*e.random_dec(),r=t+f*e.random_dec();a.lineTo(r,i),a.strokeStyle=n(d,e.random_dec()*(-1*o)+o),a.globalAlpha=e.random_dec()*s,a.stroke(),a.beginPath(),a.moveTo(r,i)}a.globalAlpha=1}function n(a,e){a=a.substr(1);var t=parseInt(a,16),n=Math.round(2.55*e),c=(t>>16)+n,i=(t>>8&255)+n,r=(255&t)+n;return'#'+(16777216+65536*(c<255?c<1?0:c:255)+256*(i<255?i<1?0:i:255)+(r<255?r<1?0:r:255)).toString(16).slice(1)}let c=['#ffb100','#d9865f','#a5182e','#1c97bf','#000000','#ffffff','#e4dfd1','#262a27','#568164','#a1583a','#35585d'],i=c[Math.floor(c.length*e.random_dec())],r=c[Math.floor(c.length*e.random_dec())],d=e.random_dec()>=.55,h=e.random_dec()>=.2;a.fillStyle=d?'#0c0c0c':'#efefef',a.fillRect(0,0,canvas.width,canvas.height);let s=.02*canvas.width,l=d?n('#ffffff',-15):'#000000';await t(.15*-canvas.width,.15*-canvas.height,1.3*canvas.width,1.3*canvas.height,d?'#000000':n('#ffffff',-10),5e4,1,2,d?15:10),await t(0,0,canvas.width,s,l,2e3,1,2,15),await t(0,canvas.height-s,canvas.width,canvas.height,l,2e3,1,2,15),await t(0,0,s,canvas.height,l,2700,1,2,15),await t(canvas.width-s,0,canvas.width,canvas.height,l,2700,1,2,15);let o=document.createElement('canvas');o.width=canvas.width,o.height=canvas.height,o.ctx=o.getContext('2d'),o.ctx.drawImage(canvas,0,0),await t(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,h?d?n('#ffffff',-10):'#000000':d?'#000000':n('#ffffff',-10),67500,1,2,h?d?10:15:d?15:10);let f=document.createElement('canvas');f.width=canvas.width,f.height=canvas.height,f.ctx=f.getContext('2d'),f.ctx.drawImage(canvas,0,0),a.drawImage(o,0,0),await t(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,h?d?n('#ffffff',-10):'#000000':d?'#000000':n('#ffffff',-10),67500,1,2,h?d?10:15:d?15:10);let v=document.createElement('canvas');v.width=canvas.width,v.height=canvas.height,v.ctx=v.getContext('2d'),v.ctx.drawImage(canvas,0,0),a.drawImage(o,0,0);let g=[],m=e.random_dec()>=.24,w=e.random_dec()>=.24,u=e.random_dec()/1.5+1,_=Math.floor(14*e.random_dec())+10,y=e.random_dec()>=.84,p=e.random_dec()>=.24,x=d?'#efefef':'#0c0c0c',I=.005*canvas.width*u,b=d?'#0c0c0c':'#efefef',P=d?'#efefef':'#0c0c0c',M=Math.round(10*e.random_dec()),C=360*e.random_dec()*(Math.PI/180),k=Math.round(16+240*e.random_dec()),D=e.random_dec()<=.96,A=.5*e.random_dec()+.15;function S(){let t,n,c,i;a.strokeStyle=x,a.beginPath();for(let e=0;e<g.length;e++)t=g[e].x,n=g[e].y,0==e&&a.moveTo(t,n),e==g.length-1?(c=g[0].x,i=g[0].y):(c=g[e+1].x,i=g[e+1].y),a.lineWidth=I,a.lineTo(c,i),a.stroke(),t=c,n=i;a.closePath(),a.save(),a.clip(),a.drawImage(e.random_dec()>=.5?v:f,0,0,canvas.width,canvas.height),a.translate(canvas.width/2,canvas.height/2),a.rotate(C),a.drawImage(e.random_dec()>=.5?v:f,-canvas.width/2,-canvas.height/2,canvas.width,canvas.height),a.rotate(-C),a.translate(-canvas.width/2,-canvas.height/2),a.fillStyle=b,a.strokeStyle=P,a.lineWidth=.002*canvas.width*u;for(let e=0;e<g.length;e++)if(g[e].isCircle){a.beginPath(),a.arc(g[e].x,g[e].y,.03*canvas.width*g[e].enlarger,0,2*Math.PI),a.closePath(),a.fillStyle=D?g[e].circleFill:b,a.fill(),a.stroke();for(let t=0;t<g[e].innerCircles;t++)a.beginPath(),a.arc(g[e].x,g[e].y,.02*canvas.width/t*g[e].enlarger,0,2*Math.PI),a.closePath(),a.stroke()}else{let t=.03*canvas.width*g[e].enlarger*1.25;a.fillStyle=D?g[e].circleFill:b,C=Math.PI/180*45,a.translate(g[e].x,g[e].y),a.rotate(C),a.beginPath(),a.rect(-t/2,-t/2,t,t),a.closePath(),a.fill(),a.stroke();for(let t=0;t<g[e].innerCircles;t++){let n=.02*canvas.width/t*g[e].enlarger*1.25;a.beginPath(),a.rect(-n/2,-n/2,n,n),a.closePath(),a.stroke()}a.rotate(-C),a.translate(-g[e].x,-g[e].y)}a.restore()}for(let a=0;a<_;a++){let a=u;m||(a=e.random_dec()/1.5+1);let t=M;w||(t=Math.round(10*e.random_dec()));let n=p;y&&(n=e.random_dec()>=.5),g.push({x:.8*canvas.width*e.random_dec()+.1*canvas.width,y:.8*canvas.height*e.random_dec()+.1*canvas.height,circleFill:e.random_dec()<=A?e.random_dec()>=.5?i:r:b,xDirection:e.random_dec()>=.5?1:-1,yDirection:e.random_dec()>=.5?1:-1,enlarger:a,innerCircles:t,isCircle:n})}S();let E=!1,F=15;function T(t,n){if(!E){let c=[];t&&(M=Math.round(10*e.random_dec()));for(let a=0;a<g.length;a++){let d=g[a].x+canvas.width/1500*e.random_dec()*g[a].xDirection;d>.9*canvas.width&&(d=.9*canvas.width),d<.1*canvas.width&&(d=.1*canvas.width);let h=g[a].y+canvas.height/1500*e.random_dec()*g[a].yDirection;h>.9*canvas.height&&(h=.9*canvas.height),h<.1*canvas.height&&(h=.1*canvas.height);let s=g[a].circleFill;t&&(s=e.random_dec()<=A?e.random_dec()>=.5?i:r:b,w||(M=Math.round(10*e.random_dec())));let l=g[a].xDirection,o=g[a].yDirection;if(n){e.random_dec()>=.5?l=e.random_dec()>=.5?1:-1:o=e.random_dec()>=.5?1:-1}c.push({x:d,y:h,circleFill:s,xDirection:l,yDirection:o,enlarger:g[a].enlarger,innerCircles:t?M:g[a].innerCircles,isCircle:g[a].isCircle})}g=c,a.drawImage(o,0,0),S()}}async function W(){B++,C=360*e.random_dec()*(Math.PI/180),B%k==0?T(!0,!0):T(!1,!1)}let B=0,R=setInterval(W,F);document.addEventListener('keydown',(function(a){const e=a.key;'p'==e&&(E=!E),'f'==e&&F>1&&(F/=1.5,clearInterval(R),R=setInterval(W,F)),'s'==e&&(F*=1.5,clearInterval(R),R=setInterval(W,F))}))}let canvas=document.createElement('canvas');setup(),draw();";
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