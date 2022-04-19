// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArtScript {
    string public constant PROJECT_NAME = "Minimal Line";
    string public constant ARTIST_NAME = "Tibout Shaik";
    string public constant EXTERNAL_LIBRARY = "";
    string public constant TWOFIVESIX_LIBRARY = "";
    string public constant LICENSE = "NFT License";
    string public constant ARTSCRIPT =
        "class Random{constructor(){this.useA=!1;let t=function(t){let n=parseInt(t.substr(0,8),16),e=parseInt(t.substr(8,8),16),a=parseInt(t.substr(16,8),16),r=parseInt(t.substr(24,8),16);return function(){n|=0,e|=0,a|=0,r|=0;let t=(n+e|0)+r|0;return r=r+1|0,n=e^e>>>9,e=a+(a<<3)|0,a=a<<21|a>>>11,a=a+t|0,(t>>>0)/4294967296}};this.prngA=new t(inputData.hash.substr(2,32)),this.prngB=new t(inputData.hash.substr(34,32));for(let t=0;t<1e6;t+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}random_num(t,n){return t+(n-t)*this.random_dec()}random_int(t,n){return Math.floor(this.random_num(t,n+1))}random_bool(t){return this.random_dec()<t}random_choice(t){return t[this.random_int(0,t.length-1)]}}function setup(){let t=Math.min(window.innerWidth,window.innerHeight);canvas.width=t,canvas.height=1.35*t,document.body.appendChild(canvas)}function draw(){let t=canvas.getContext('2d'),n=new Random,e='#'+Math.floor(16777215*n.random_dec()).toString(16).toString(),a=canvas.width*n.random_dec(),r=canvas.height*n.random_dec(),s=canvas.width*n.random_dec(),i=canvas.height*n.random_dec(),o=.05*canvas.width;t.fillStyle='#fff',t.fillRect(0,0,canvas.width,canvas.height),t.strokeStyle=e,t.lineWidth=o,t.moveTo(a,r),t.lineTo(s,i),t.stroke(),t.rect(0,0,canvas.width,canvas.height),t.stroke()}let canvas=document.createElement('canvas');setup(),draw();";
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