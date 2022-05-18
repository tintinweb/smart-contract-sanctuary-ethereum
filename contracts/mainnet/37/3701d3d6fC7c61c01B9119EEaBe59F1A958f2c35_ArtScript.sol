// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArtScript {
    string public constant PROJECT_NAME = "It's (a)live";
    string public constant ARTIST_NAME = "Tibout Shaik";
    string public constant EXTERNAL_LIBRARY = "None";
    string public constant TWOFIVESIX_LIBRARY = "None";
    string public constant LICENSE = "NFT License";
    string public constant ARTSCRIPT =
        "class Random{constructor(){this.useA=!1;let a=function(a){let e=parseInt(a.substr(0,8),16),t=parseInt(a.substr(8,8),16),n=parseInt(a.substr(16,8),16),c=parseInt(a.substr(24,8),16);return function(){e|=0,t|=0,n|=0,c|=0;let a=(e+t|0)+c|0;return c=c+1|0,e=t^t>>>9,t=n+(n<<3)|0,n=n<<21|n>>>11,n=n+a|0,(a>>>0)/4294967296}};this.prngA=new a(inputData.hash.substr(2,32)),this.prngB=new a(inputData.hash.substr(34,32));for(let a=0;a<1e6;a+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}function setup(){let a=Math.min(window.innerWidth,window.innerHeight);canvas.width=a,canvas.height=1.35*a,document.body.appendChild(canvas)}async function draw(){let a=canvas.getContext('2d',{alpha:!1}),e=new Random;async function t(t,c,i,r,h,d,s,l,o){let f=i-t,v=r-c;a.beginPath(),a.moveTo(t,c);for(let i=0;i<d;i++){a.lineWidth=e.random_dec()*(canvas.width/1500)*l;let i=c+v*e.random_dec(),r=t+f*e.random_dec();a.lineTo(r,i),a.strokeStyle=n(h,e.random_dec()*(-1*o)+o),a.globalAlpha=e.random_dec()*s,a.stroke(),a.beginPath(),a.moveTo(r,i)}a.globalAlpha=1}function n(a,e){a=a.substr(1);var t=parseInt(a,16),n=Math.round(2.55*e),c=(t>>16)+n,i=(t>>8&255)+n,r=(255&t)+n;return'#'+(16777216+65536*(c<255?c<1?0:c:255)+256*(i<255?i<1?0:i:255)+(r<255?r<1?0:r:255)).toString(16).slice(1)}let c=['#ffb100','#d9865f','#a5182e','#1c97bf','#000000','#ffffff','#e4dfd1','#262a27','#568164','#a1583a','#35585d'],i=c[Math.floor(c.length*e.random_dec())],r=c[Math.floor(c.length*e.random_dec())],h=e.random_dec()>=.55,d=e.random_dec()>=.2;a.fillStyle=h?'#0c0c0c':'#efefef',a.fillRect(0,0,canvas.width,canvas.height);let s=.02*canvas.width,l=h?n('#ffffff',-15):'#000000';await t(.15*-canvas.width,.15*-canvas.height,1.3*canvas.width,1.3*canvas.height,h?'#000000':n('#ffffff',-10),5e4,1,2,h?15:10),await t(0,0,canvas.width,s,l,2e3,1,2,15),await t(0,canvas.height-s,canvas.width,canvas.height,l,2e3,1,2,15),await t(0,0,s,canvas.height,l,2700,1,2,15),await t(canvas.width-s,0,canvas.width,canvas.height,l,2700,1,2,15);let o=document.createElement('canvas');o.width=canvas.width,o.height=canvas.height,o.ctx=o.getContext('2d'),o.ctx.drawImage(canvas,0,0),await t(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,d?h?n('#ffffff',-10):'#000000':h?'#000000':n('#ffffff',-10),67500,1,2,d?h?10:15:h?15:10);let f=document.createElement('canvas');f.width=canvas.width,f.height=canvas.height,f.ctx=f.getContext('2d'),f.ctx.drawImage(canvas,0,0),a.drawImage(o,0,0),await t(-canvas.height/2+.35*canvas.width,.15*-canvas.height,canvas.height+.35*canvas.width,1.3*canvas.height,d?h?n('#ffffff',-10):'#000000':h?'#000000':n('#ffffff',-10),67500,1,2,d?h?10:15:h?15:10);let v=document.createElement('canvas');v.width=canvas.width,v.height=canvas.height,v.ctx=v.getContext('2d'),v.ctx.drawImage(canvas,0,0),a.drawImage(o,0,0);let g=[],m=e.random_dec()>=.24,w=e.random_dec()>=.24,u=e.random_dec()/1.5+1,_=Math.floor(54*e.random_dec())+10,y=e.random_dec()>=.84,p=e.random_dec()>=.24,x=h?'#efefef':'#0c0c0c',b=.005*canvas.width*u,I=h?'#0c0c0c':'#efefef',P=h?'#efefef':'#0c0c0c',C=Math.round(10*e.random_dec()),M=360*e.random_dec()*(Math.PI/180),k=e.random_dec()<=.96,D=.5*e.random_dec()+.15,A=f,S=!1,E=!1;function F(){let e,t,n,c;a.strokeStyle=x,a.beginPath();for(let i=0;i<g.length;i++)e=g[i].x,t=g[i].y,0==i&&a.moveTo(e,t),i==g.length-1?(n=g[0].x,c=g[0].y):(n=g[i+1].x,c=g[i+1].y),a.lineWidth=b,a.lineTo(n,c),e=n,t=c;a.stroke(),a.closePath(),a.save(),a.clip(),a.drawImage(f,0,0,canvas.width,canvas.height),S&&(a.translate(canvas.width/2,canvas.height/2),a.rotate(M),a.drawImage(A,-canvas.width/2,-canvas.height/2,canvas.width,canvas.height),a.rotate(-M),a.translate(-canvas.width/2,-canvas.height/2)),a.fillStyle=I,a.strokeStyle=P,a.lineWidth=.002*canvas.width*u;for(let e=0;e<g.length;e++)if(g[e].isCircle){a.beginPath(),a.arc(g[e].x,g[e].y,.03*canvas.width*g[e].enlarger,0,2*Math.PI),a.closePath(),a.fillStyle=k?g[e].circleFill:I,a.fill(),a.stroke();for(let t=0;t<g[e].innerCircles;t++)a.beginPath(),a.arc(g[e].x,g[e].y,.02*canvas.width/t*g[e].enlarger,0,2*Math.PI),a.closePath(),a.stroke()}else{let t=.03*canvas.width*g[e].enlarger*1.25;a.fillStyle=k?g[e].circleFill:I;let n=Math.PI/180*45;a.translate(g[e].x,g[e].y),a.rotate(n),a.beginPath(),a.rect(-t/2,-t/2,t,t),a.closePath(),a.fill(),a.stroke();for(let t=0;t<g[e].innerCircles;t++){let n=.02*canvas.width/t*g[e].enlarger*1.25;a.beginPath(),a.rect(-n/2,-n/2,n,n),a.closePath(),a.stroke()}a.rotate(-n),a.translate(-g[e].x,-g[e].y)}a.restore()}for(let a=0;a<_;a++){let a=u;m||(a=e.random_dec()/1.5+1);let t=C;w||(t=Math.round(10*e.random_dec()));let n=p;y&&(n=e.random_dec()>=.5),g.push({x:.8*canvas.width*e.random_dec()+.1*canvas.width,y:.8*canvas.height*e.random_dec()+.1*canvas.height,circleFill:e.random_dec()<=D?e.random_dec()>=.5?i:r:I,xDirection:e.random_dec()>=.5?1:-1,yDirection:e.random_dec()>=.5?1:-1,enlarger:a,innerCircles:t,isCircle:n})}F();let T=!1;function W(t){let n=[];E&&(C=Math.round(10*e.random_dec()));for(let a=0;a<g.length;a++){let c=g[a].x+canvas.width/4e4*e.random_dec()*g[a].xDirection;c>.9*canvas.width&&(c=.9*canvas.width),c<.1*canvas.width&&(c=.1*canvas.width);let h=g[a].y+canvas.height/4e4*e.random_dec()*g[a].yDirection;h>.9*canvas.height&&(h=.9*canvas.height),h<.1*canvas.height&&(h=.1*canvas.height);let d=g[a].circleFill;E&&(d=e.random_dec()<=D?e.random_dec()>=.5?i:r:I,w||(C=Math.round(10*e.random_dec())));let s=g[a].xDirection,l=g[a].yDirection;if(t){e.random_dec()>=.5?s=e.random_dec()>=.5?1:-1:l=e.random_dec()>=.5?1:-1}n.push({x:c,y:h,circleFill:d,xDirection:s,yDirection:l,enlarger:g[a].enlarger,innerCircles:E?C:g[a].innerCircles,isCircle:g[a].isCircle})}g=n,a.drawImage(o,0,0),F()}let B=0;setInterval((async function(){T||(E=!1,B++,B%4==0&&(A=A==f?v:f,M=360*e.random_dec()*(Math.PI/180)),W(B%256==0))}),10);document.addEventListener('keydown',(function(a){const e=a.key;'p'==e&&(T=!T),'m'==e&&(S=!S),'d'==e&&(E=!0,W(!1))}))}let canvas=document.createElement('canvas');setup(),draw();";
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