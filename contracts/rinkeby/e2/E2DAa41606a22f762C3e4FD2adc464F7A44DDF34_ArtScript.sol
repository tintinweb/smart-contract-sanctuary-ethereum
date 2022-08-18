// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtScript is Ownable {
    string public constant PROJECT_NAME = "It was always the eyes";
    string public constant ARTIST_NAME = "Tibout Shaik";
    string public externalLibraryUsed = "None";
    string public twofivesixLibraryUsed = "None";
    string public constant LICENSE = "NFT License 2.0";
    string public constant ARTSCRIPT =
        "class Random{constructor(){this.useA=!1;let a=function(a){let e=parseInt(a.substr(0,8),16),t=parseInt(a.substr(8,8),16),n=parseInt(a.substr(16,8),16),h=parseInt(a.substr(24,8),16);return function(){e|=0,t|=0,n|=0,h|=0;let a=(e+t|0)+h|0;return h=h+1|0,e=t^t>>>9,t=n+(n<<3)|0,n=n<<21|n>>>11,n=n+a|0,(a>>>0)/4294967296}};this.prngA=new a(inputData.hash.substr(2,32)),this.prngB=new a(inputData.hash.substr(34,32));for(let a=0;a<1e6;a+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}function setup(){let a=Math.min(window.innerWidth,window.innerHeight);canvas.width=a,canvas.height=1*a,document.body.appendChild(canvas)}let useMemberShipId,artOnly,paused,buffers=[],memberBuffers=[],changingPalette=!1;async function draw(){let a=canvas.getContext('2d');a.resetTransform(),a.fillStyle='#000000',a.fillRect(0,0,canvas.width,canvas.height),a.fillStyle='#ffffff',a.textAlign='center',a.font=Math.round(canvas.width/60).toString()+'px Arial',a.fillText('Preparing art with '+(useMemberShipId?'member':'default')+' color palette, this can take up to 20 minutes.',canvas.width/2,canvas.height/2),await new Promise((a=>setTimeout(a,100))),a.clearRect(0,0,canvas.width,canvas.height);let e=new Random;function t(a,e){a=a.substr(1);var t=parseInt(a,16),n=Math.round(2.55*e),h=(t>>16)+n,c=(t>>8&255)+n,i=(255&t)+n;return'#'+(16777216+65536*(h<255?h<1?0:h:255)+256*(c<255?c<1?0:c:255)+(i<255?i<1?0:i:255)).toString(16).slice(1)}async function n(n,h,c,i,s,d,r,l,o){let v=c-n,g=i-h;a.beginPath(),a.moveTo(n,h);for(let c=0;c<d;c++){a.lineWidth=e.random_dec()*(canvas.width/4e3)*l;let c=h+g*e.random_dec(),i=n+v*e.random_dec();a.lineTo(i,c),a.strokeStyle=t(s,e.random_dec()*(-1*o)+o),a.globalAlpha=r,a.stroke(),a.closePath(),a.beginPath(),a.moveTo(i,c)}a.globalAlpha=1,a.closePath()}let h,c,i,s,d=inputData.membershipId;d=Math.floor(4096*e.random_dec());let r,l=e.random_dec();l<=.14?r=10:l<=.28?r=9:l<=.42?r=8:l<=.56?r=7:l<=.65?r=6:l<=.74?r=5:l<=.83?r=4:l<=.89?r=3:l<=.95?r=2:l<=.98?r=1:l<=1&&(r=0);let o=[['#7739D1','#7739D1','#7EC292','#7EC292','#22133D','#7739D1','#7739D1','#7EC292','#7EC292','#22133D','#E14D9C'],['#959d71','#9aa276','#959d71','#9aa276','#414033','#959d71','#9aa276','#959d71','#9aa276','#414033','#acc4cf','#b8d1db','#acc4cf','#b8d1db','#91b2cd','#acc4cf','#b8d1db','#acc4cf','#a85a50','#a85a50','#da9087','#6e6861','#f1e7b6'],['#07090b','#07090b','#07090b','#07090b','#07090b','#07090b','#07090b','#07090b','#34171b','#9f0a25','#631420','#9f5342','#651521'],['#241f1c','#241f1c','#393739','#86786a','#dad3c1','#5b5e60','#9f9488','#362d2b','#241f1c','#241f1c','#393739','#86786a','#dad3c1','#5b5e60','#9f9488','#362d2b'],['#ceccc9','#0e8dc4','#0e8dc4','#1e1f21','#1e1f21','#5d8383','#b02c21','#c89d1e','#753a30','#81b8cc','#265a7a'],['#dbd07d','#dbd07d','#232b29','#6b6e52','#739f79','#487b63','#739f79','#487b63','#4f3325','#a85d24','#39595d','#648b96'],['#f50e0e','#f50e0e','#0c7ebe','#0c7ebe','#fbe316','#fbe316'],['#ce9d72','#171510','#397144','#c02b32','#734917','#734917','#627c95','#493629','#000001','#472b6e'],['#f15630','#345a7d','#e1b83a','#000000','#000000','#000000','#000000','#000000','#000000','#d8c4a6','#c6b08e','#d8c4a6','#d8c4a6','#c6b08e'],['#BDA22A','#b6b994','#b6b994','#4b638a','#1d201f','#96afac','#192455','#7590c1','#879691','#3b4548','#1a366d','#4b638a','#1d201f','#96afac','#192455','#7590c1','#879691','#3b4548','#1a366d'],['#EBC644','#EBC644','#EBC644','#EBC644','#EBC644','#080806','#73A54E','#B98C31','#FFDF4E','#c33f18','#c33f18','#3d4970','#538c3b']][r],v=o[Math.floor(e.random_dec()*o.length)],g=o[Math.floor(e.random_dec()*o.length)];do{g=o[Math.floor(e.random_dec()*o.length)]}while(v===g);0!==d&&useMemberShipId?(h=!0,c=await TwoFiveSix.getBlockColorsForId(d),i=await TwoFiveSix.getBackgroundColorForId(d),s=await TwoFiveSix.getBorderColorForId(d)):(h=!1,i=v,s=g);let f=1.1*e.random_dec()+.2,w=e.random_dec(),m=Math.round(16/f+256/f*w),u=10*e.random_dec(),b=.75+.25*e.random_dec(),p=.5*e.random_dec()-.25,M=e.random_dec(),_=Math.round(512*M)+10,S=e.random_dec()<=.92?1:2,I=e.random_dec()<=.8,y=e.random_dec()>=.5;if(y&&(a.translate(canvas.width,0),a.scale(-1,1),a.translate(0,0)),artOnly){a.fillStyle='#000000',a.fillRect(0,0,canvas.width,canvas.height);for(let A=0;A<64*m;A++){let x=(.04*canvas.width*e.random_dec()+.02*canvas.width)*f,E=canvas.width*e.random_dec()-x/2,P=canvas.height*e.random_dec()-x/2,B=h?c[Math.floor(e.random_dec()*c.length)]:o[Math.floor(e.random_dec()*o.length)],R=Math.round(P/canvas.height*-50)+(p<0?Math.round(-40*(1-E/canvas.width)):Math.round(E/canvas.width*-40));I||(a.fillStyle=t('#000000',10),a.fillRect(E,P,x,x)),await n(E,P,E+x,P+x,t(B,h?R-u:R+20),_*f,b,2,20)}}else{a.fillStyle='#000000',a.fillRect(0,0,canvas.width,canvas.height),await n(0-.5*canvas.width,0-.5*canvas.height,canvas.width+canvas.width,canvas.height+canvas.height,t(i,-10),1e5,.1,5,10),a.globalAlpha=.4;let T=a.createLinearGradient(0,0,canvas.width,0);T.addColorStop(p<0?0:1,t('#ffffff'===i?i:t(i,-50),'#ffffff'===i?-62:2)),T.addColorStop(p<0?1:0,t('#ffffff'===i?i:t(i,-50),'#ffffff'===i?-2:62)),a.fillStyle=T,a.fillRect(0,0,canvas.width,canvas.height),a.globalAlpha=1;let D=document.createElement('canvas');if(D.width=canvas.width,D.height=canvas.height,D.ctx=D.getContext('2d'),await D.ctx.drawImage(canvas,0,0),a.clearRect(0,0,canvas.width,canvas.height),a.beginPath(),a.moveTo(0,canvas.height),a.lineTo(0,.9*canvas.height),a.quadraticCurveTo(.4*canvas.width,canvas.height*(1-.18),.3*canvas.width,.55*canvas.height),a.lineTo(.7*canvas.width,.55*canvas.height),a.quadraticCurveTo(.6*canvas.width,canvas.height*(1-.18),canvas.width,.9*canvas.height),a.lineTo(canvas.width,canvas.height),a.closePath(),a.save(),a.clip(),a.strokeStyle='#000000',a.lineWidth=.03*canvas.width,a.stroke(),a.globalAlpha=1,a.fillStyle=t('#000000',10),a.fillRect(0,0,canvas.width,canvas.height),1==S)for(let ta=0;ta<64*m;ta++){let na=(.04*canvas.width*e.random_dec()+.02*canvas.width)*f,ha=canvas.width*e.random_dec()-na/2,ca=canvas.height*e.random_dec()-na/2,ia=h?c[Math.floor(e.random_dec()*c.length)]:o[Math.floor(e.random_dec()*o.length)],sa=Math.round(ca/canvas.height*-50)+(p<0?Math.round(-40*(1-ha/canvas.width)):Math.round(ha/canvas.width*-40));I||(a.fillStyle=t('#000000',10),a.fillRect(ha,ca,na,na)),await n(ha,ca,ha+na,ca+na,t(ia,h?sa-u-5:sa+10),_*f,b,2,20)}else if(2==S){let da=.04*canvas.width*f;for(let ra=0;ra<canvas.width/da;ra++)for(let la=0;la<canvas.height/da;la++){let oa=da*ra,va=da*la,ga=h?c[Math.floor(e.random_dec()*c.length)]:o[Math.floor(e.random_dec()*o.length)],fa=Math.round(va/canvas.height*-50)+(p<0?Math.round(-40*(1-oa/canvas.width)):Math.round(oa/canvas.width*-40));await n(oa,va,oa+da,va+da,t(ga,h?fa-u-5:fa+10),_*f,b,2,20)}}let F=document.createElement('canvas');F.width=canvas.width,F.height=canvas.height,F.ctx=F.getContext('2d'),await F.ctx.drawImage(canvas,0,0),a.clearRect(0,0,canvas.width,canvas.height);let k=e.random_dec(),O=5;if(k>=.9?O=1:k>=.75?O=2:k>=.55?O=3:k>=.275&&(O=4),2==O||3==O){let wa=e.random_dec();(2==O&&wa<=.5||3==O)&&(a.save(),a.translate(.5*canvas.width,.5*canvas.height),a.rotate(-30*Math.PI/180),a.translate(.5*-canvas.width,.5*-canvas.height),await n(.2*-canvas.width,.5*canvas.height,.2*canvas.width,1.2*canvas.height,t(s,-20),2e4,2,5,8),a.restore()),(2==O&&wa>.5||3==O)&&(a.save(),a.translate(.5*canvas.width,.5*canvas.height),a.rotate(30*Math.PI/180),a.translate(.5*-canvas.width,.5*-canvas.height),await n(.8*canvas.width,.5*canvas.height,1.2*canvas.width,1.2*canvas.height,t(s,-20),2e4,2,5,8),a.restore())}else 4==O?(a.fillStyle=t(s,-20),a.fillRect(.1*canvas.width,.5*canvas.height,.15*canvas.width,.5*canvas.height),a.fillRect(.75*canvas.width,.5*canvas.height,.15*canvas.width,.5*canvas.height),await n(.1*canvas.width,.5*canvas.height,.25*canvas.width,1.2*canvas.height,t(s,-20),9e3,2,5,8),await n(.75*canvas.width,.5*canvas.height,.9*canvas.width,1.2*canvas.height,t(s,-20),9e3,2,5,8)):5==O&&(a.fillStyle=t(s,-20),a.fillRect(0,0,.25*canvas.width,canvas.height),a.fillRect(.75*canvas.width,0,canvas.width,canvas.height),await n(.2*-canvas.width,.5*canvas.height,.25*canvas.width,1.2*canvas.height,t(s,-20),12e3,2,5,8),await n(.75*canvas.width,.5*canvas.height,1.2*canvas.width,1.2*canvas.height,t(s,-20),12e3,2,5,8));if(a.restore(),4==O||5==O){a.save(),a.beginPath(),a.moveTo(.1*canvas.width,canvas.height),a.lineTo(.25*canvas.width,.797*canvas.height);let ma=canvas.height*e.random_dec()*.1;a.bezierCurveTo(.3*canvas.width,.9*canvas.height+ma,.7*canvas.width,.9*canvas.height+ma,.75*canvas.width,.797*canvas.height),a.lineTo(.9*canvas.width,canvas.height),a.closePath(),a.clip(),await n(.1*canvas.width,.5*canvas.height,.9*canvas.width,1.2*canvas.height,t(s,-20),12e3,2,5,8),a.restore()}let q=document.createElement('canvas');q.width=canvas.width,q.height=canvas.height,q.ctx=q.getContext('2d'),await q.ctx.drawImage(canvas,0,0),a.restore(),a.clearRect(0,0,canvas.width,canvas.height),a.save();let L=e.random_dec()>=.35,W=e.random_dec(),z=e.random_dec();if(a.beginPath(),L)a.save(),a.translate(.5*canvas.width,.375*canvas.height),a.rotate(p),a.translate(.5*-canvas.width,.375*-canvas.height),a.ellipse(canvas.width/2,canvas.height/2.4,canvas.width/3.65+(canvas.width/15*W-canvas.width/30),canvas.height/2.75+(canvas.height/15*z-canvas.height/30),0,0,2*Math.PI,!0),a.restore();else{let ua=canvas.width/30*W,ba=canvas.height/30*z;a.save(),a.translate(.5*canvas.width,.375*canvas.height),a.rotate(p),a.translate(.5*-canvas.width,.375*-canvas.height),a.rect(.25*canvas.width-ua,.1*canvas.height-ba,.5*canvas.width+ua,.65*canvas.height+ba),a.restore()}if(a.save(),a.globalAlpha=.6,a.shadowColor='#000000',a.shadowBlur=.2*canvas.width,a.shadowOffsetX=(p<0?y?1:-1:y?-1:1)*canvas.width*.075,a.shadowOffsetY=.02*canvas.height,a.fill(),a.globalAlpha=1,a.restore(),a.closePath(),a.clip(),a.fillStyle=t('#000000',10),a.fillRect(0,0,canvas.width,canvas.height),a.rotate(p),1==S)for(let pa=0;pa<64*m;pa++){let Ma=(.04*canvas.width*e.random_dec()+.02*canvas.width)*f,_a=canvas.width*e.random_dec()-Ma/2,Sa=1.1*canvas.height*e.random_dec()-.1*canvas.height-Ma/2,Ia=h?c[Math.floor(e.random_dec()*c.length)]:o[Math.floor(e.random_dec()*o.length)],ya=Math.round(Sa/canvas.height*-35)+(p<0?Math.round(-85*(1-_a/canvas.width)):Math.round(_a/canvas.width*-85));I||(a.fillStyle=t('#000000',10),a.fillRect(_a,Sa,Ma,Ma)),await n(_a,Sa,_a+Ma,Sa+Ma,t(Ia,h?ya+35-u:ya+45),_*f,b,2,20)}else if(2==S){let Ca=.04*canvas.width*f;for(let Aa=0;Aa<canvas.width/Ca;Aa++)for(let xa=0;xa<canvas.height/Ca;xa++){let Ea=Ca*Aa,Pa=.1*-canvas.height+Ca*xa,Ba=h?c[Math.floor(e.random_dec()*c.length)]:o[Math.floor(e.random_dec()*o.length)],Ra=Math.round(Pa/canvas.height*-35)+(p<0?Math.round(-85*(1-Ea/canvas.width)):Math.round(Ea/canvas.width*-85));await n(Ea,Pa,Ea+Ca,Pa+Ca,t(Ba,h?Ra+35-u:Ra+45),_*f,b,2,20)}}let G=document.createElement('canvas');G.width=canvas.width,G.height=canvas.height,G.ctx=G.getContext('2d'),await G.ctx.drawImage(canvas,0,0),a.restore(),a.clearRect(0,0,canvas.width,canvas.height);let H,X=.12*canvas.width,Y=.04*canvas.height*e.random_dec()+.04*canvas.height,j=.04*canvas.height*e.random_dec()+.04*canvas.height,J=.39*canvas.width-X/2,K=.36*canvas.height-Y/2,N=.61*canvas.width-X/2,Q=.36*canvas.height-j/2,U=.12*e.random_dec()-.06,V=!0,Z=0,$=70,aa=Date.now(),ea=0;async function C(){if(Z<=8){let t;a.globalAlpha=1,t=V?108:100,V=!V,a.drawImage(D,0,0),a.filter='brightness('+t.toString()+'%)',a.drawImage(F,0,0),a.filter='brightness(100%)',a.drawImage(q,0,0),a.filter='brightness('+t.toString()+'%)',a.drawImage(G,0,0),a.filter='brightness(100%)',a.save(),L?a.rotate(y?-p/1.5:p/1.5):a.rotate(y?-p:p),a.save();let h=U+.06*e.random_dec()-.03;a.translate(J+X/2,K+Y/2),a.rotate(h),a.translate(-1*(J+X/2),-1*(K+Y/2)),await n(J,K,J+X,K+Y,'#ffffff',1e3,1,3,-5),a.restore(),a.translate(N+X/2,Q+j/2),a.rotate(2*-h),a.translate(-1*(N+X/2),-1*(Q+j/2)),await n(N,Q,N+X,Q+j,'#ffffff',1e3,1,3,-5),a.restore();let c=document.createElement('canvas');c.width=canvas.width,c.height=canvas.height,c.ctx=c.getContext('2d'),await c.ctx.drawImage(canvas,0,0),useMemberShipId?memberBuffers.push(c):buffers.push(c),8==Z&&y&&(a.translate(canvas.width,0),a.scale(-1,1),a.translate(0,0)),changingPalette||(requestAnimationFrame(C),Z++)}else H=Date.now(),ea=H-aa,(ea>$||0==ea)&&!paused?(aa=H-ea%$,(useMemberShipId&&9==memberBuffers.length||!useMemberShipId&&9==buffers.length)&&a.drawImage(useMemberShipId?memberBuffers[Z%8]:buffers[Z%8],0,0),changingPalette||(requestAnimationFrame(C),Z++)):changingPalette||requestAnimationFrame(C)}h&&9==memberBuffers.length&&(Z=8),h||9!=buffers.length||(Z=8),paused=!1,changingPalette=!1,C(),document.addEventListener('keydown',(function a(e){const t=e.key;'m'==t&&(paused=!0,useMemberShipId=!useMemberShipId,9!=memberBuffers.length?(document.removeEventListener('keydown',a),changingPalette=!0,draw()):paused=!1),'a'==t&&(artOnly=!artOnly,document.removeEventListener('keydown',a),draw()),'p'==t&&(paused=!paused,C())}))}}let canvas=document.createElement('canvas');setup(),useMemberShipId=inputData.useMemberShipId,artOnly=!1,paused=!1,draw();";
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