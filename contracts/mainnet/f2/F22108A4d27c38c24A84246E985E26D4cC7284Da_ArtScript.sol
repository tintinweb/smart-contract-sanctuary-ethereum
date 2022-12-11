// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtScript is Ownable {
    string public constant PROJECT_NAME = "Take Aim";
    string public constant ARTIST_NAME = "P1x3lboy";
    string public externalLibraryUsed =
        "https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.4.1/p5.min.js";
    string public twofivesixLibraryUsed =
        "https://cdn.jsdelivr.net/npm/[email protected]";
    string public constant LICENSE = "NFT License 2.0";
    string public constant ARTSCRIPT =
        "let cl,cl2,cl3,gX,gY,useMembership=!1,membershipId=inputData.membershipId;class Random{constructor(){this.useA=!1;let e=function(e){let t=parseInt(e.substr(0,8),16),o=parseInt(e.substr(8,8),16),r=parseInt(e.substr(16,8),16),n=parseInt(e.substr(24,8),16);return function(){t|=0,o|=0,r|=0,n|=0;let e=(t+o|0)+n|0;return n=n+1|0,t=o^o>>>9,o=r+(r<<3)|0,r=r<<21|r>>>11,r=r+e|0,(e>>>0)/4294967296}};this.prngA=new e(inputData.hash.substr(2,32)),this.prngB=new e(inputData.hash.substr(34,32));for(let e=0;e<1e6;e+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}random_num(e,t){return e+(t-e)*this.random_dec()}random_int(e,t){return Math.floor(this.random_num(e,t+1))}}let aspectRatio,palettes=[];function setup(){let e=(new Random).random_num(0,3);e>2?(aspectRatio=.8,orientation='Landscape'):e>1?(aspectRatio=1.25,orientation='Portrait'):(aspectRatio=1,orientation='Square'),noSmooth();let t=window.innerHeight,o=window.innerWidth;t/o<aspectRatio?createCanvas(t/aspectRatio,t):createCanvas(o,o*aspectRatio),noLoop()}async function draw(){clear();let e=new Random,t=width,o=height,r=t/68,n=t-4*r,a=o-4*r;palettes[0]=['#793623','#a16d45','#c5ac5c','#335441','#465534','#394a54','#419eac','#609198'],palettes[1]=['#3c5a50','#7ab7a5','#c5dccc','#2c3749','#6c7481','#aaafb5','#f9f8c2','#9b3c5c'],palettes[2]=['#25649d','#7eb6d7','#a43d1c','#e76b3c','#639259','#f5c23c','#f7e4a2','#e5e6dc'],palettes[3]=['#e55934','#fa7921','#fde74c','#9bc53d','#5bc0eb','#9cd9f3','#777777','#FFFFFF'],palettes[4]=['#0b3954','#547487','#bfd7ea','#B24745','#ff6663','#e0ff4f','#f2ffb8','#293a43'],palettes[5]=['#8f2d56','#d81159','#0D3433','#218380','#73d2de','#fbb13c','#555555','#FFFFFF'],palettes[6]=['#4b4d42','#555767','#a7182a','#ef233c','#b2c2c9','#edf2f4','#420910','#999AA3'],palettes[7]=['#ae7025','#da8c2f','#d7bc8a','#d16a65','#51c8be','#8fdccd','#777777','#FFFFFF'],palettes[8]=['#2e294e','#8661c1','#be97c6','#efbcd5','#f4dfe5','#FFFFFF','#545454','#323232'],palettes[9]=['#582936','#8c2f39','#b23a48','#fcb9b2','#fed0bb','#fef0ea','#25516c','#419eac'],palettes[10]=['#073b3a','#0b6e4f','#08a045','#6bbf59','#ddb771','#EEDBB8','#666666','#e8f5e3'],palettes[11]=['#022b3a','#1f7a8c','#62a1ae','#bfdbf7','#e1e5f2','#eeeeee','#777777','#444444'],palettes[12]=['#93cb9a','#f0b7bd','#f4ff89','#99e3ec','#50b4c3','#E7FFAC','#D5AAFF','#414700'],palettes[13]=['#42f7fd','#ff40fe','#feff40','#eeeeee','#7af9fd','#ff79fe','#feff79','#111111'],palettes[14]=['#F72585','#7209B7','#480CA8','#3F37C9','#4361EE','#4895EF','#4CC9F0','#55EDF1'],palettes[15]=['#262626','#4c4c4c','#737373','#999999','#c0c0c0','#d2d2d2','#ececec','#131313'],palettes[16]=['#600011','#851a2d','#af2a23','#cf5852','#d8572a','#db7c26','#f7b538','#f9cb73'];let i,c,l=e.random_int(0,5),s=e.random_int(0,5),d=e.random_int(0,5),g=(e.random_num(0,1),e.random_num(0,1)),f=e.random_num(0,1),F=e.random_num(0,1),m=e.random_num(0,1),p=0,h=e.random_num(0,1),u=e.random_num(0,1),b=e.random_num(0,1),k=e.random_int(1,4),_=e.random_num(0,1);h>.5?(targetThickness=t/20,targetName='Thick'):(targetThickness=t/25,targetName='Thin'),arcMode=u>.5?'Circles':'Arcs',gX=s>4?16:s>3?32:s>2?40:s>1?48:24,gY=d>4?16:d>3?32:d>2?40:d>1?48:24,await async function(){let t=e.random_int(0,16),o=e.random_int(0,16),r=e.random_int(0,16);cl=useMembership?await TwoFiveSix.getBlockColorsForId(membershipId):palettes[t],cl2=useMembership?await TwoFiveSix.getBlockColorsForId(membershipId):palettes[o],cl3=useMembership?await TwoFiveSix.getBlockColorsForId(membershipId):palettes[r]}();let M=7,x=T(cl[0]),Y=(T(cl2[0]),T(cl3[0]));m>.8&&(cl=useMembership?await TwoFiveSix.getBlockColorsForId(membershipId):[['#FF0000'],['#FF2A00'],['#FF5500'],['#FF7F00'],['#FFAA00'],['#FFD400'],['#FFFF00'],['#DFFF1F'],['#BFFF3F'],['#9FFF5F'],['#7FFF7F'],['#5FFF9F'],['#3FFFBF'],['#1FFFDF'],['#00FFFF'],['#04D8EF'],['#08B2E0'],['#0C8CD1'],['#1065C2'],['#143FB3'],['#1919A4'],['#5212BA'],['#8C0CD1'],['#C506E8'],['#FF00FF'],['#FF00BF'],['#FF007F'],['#FF003F']],M=27),angleMode(DEGREES),strokeCap(SQUARE),F>.92?(background(95),blendMode(SOFT_LIGHT),bMode='SoftLight Mode'):(background(0),blendMode(BLEND),bMode='Standard'),strokeWeight(r);let C=color(cl2[e.random_int(0,7)]);function T(e){return'#793623'==e?'Rome':'#3c5a50'==e?'Barcelona':'#25649d'==e?'Maldives':'#e55934'==e?'Tokyo':'#0b3954'==e?'New York':'#8f2d56'==e?'Boston':'#4b4d42'==e?'Paris':'#ae7025'==e?'Grand Canyon':'#2e294e'==e?'Noctis':'#582936'==e?'Terracotta':'#073b3a'==e?'Machu Picchu':'#022b3a'==e?'Helsinki':'#93cb9a'==e?'Positano':'#42f7fd'==e?'CMYK':'#F72585'==e?'Neons':'#262626'==e?'Mono':'#600011'==e?'Flames':'Member Mode'}function X(){z=.8==aspectRatio?.9:1.25==aspectRatio?1.125:1}function D(o,i){strokeWeight(targetThickness/(3.5*o));let c=30*o;X();for(let l=5*o;l>0;l--){stroke(cl2[e.random_int(0,7)]);for(let e=.25;e<1;e+=.5)for(let o=.25;o<1;o+=.5)I(2*r+n*e,2*r+a*o,l*t/c*z,i)}}function S(r,n){X(),strokeWeight(targetThickness/(1.6*r));for(let a=5*r;a>0;a--)stroke(cl2[e.random_int(0,7)]),I(t/2,o/2,a*t/(16*r)*z,n)}function w(o,i){strokeWeight(targetThickness/(5*o));let c=55*o;X();for(let l=5*o;l>0;l--){stroke(cl2[e.random_int(0,7)]);for(let e=.125;e<1;e+=.25)for(let o=.125;o<1;o+=.25)I(2*r+n*e,2*r+a*o,l*t/c*z,i)}}function R(o,i){strokeWeight(targetThickness/(10.5*o));let c=110*o;X();for(let l=5*o;l>0;l--){stroke(cl2[e.random_int(0,7)]);for(let e=.0625;e<1;e+=.125)for(let o=.0625;o<1;o+=.125)I(2*r+n*e,2*r+a*o,l*t/c*z,i)}}function B(t,o,i,c){noStroke();for(let l=i;l<t;l++)for(let t=c;t<o;t++){let o=color(cl2[e.random_int(0,7)]);c2=color(cl2[e.random_int(0,7)]),c3=color(cl2[e.random_int(0,7)]),g>.5?E(2*r+l*n/gX,2*r+t*a/gY,n/gX,a/gY,o,c2):A(2*r+l*n/gX,2*r+t*a/gY,n/gX,a/gY,o,c2)}}function A(e,t,o,r,n,a){noStroke();for(let i=e;i<=e+o;i++){fill(lerpColor(n,a,(i-e)/o)),rect(i,t,.74,r)}}function E(e,t,o,r,n,a){noStroke();for(let i=t;i<=t+r;i++){fill(lerpColor(n,a,(i-t)/r)),rect(e,i,o,.74)}}function W(){let e=-1;for(;++e<cl2.length;)cl2[e]=cl3[e]}function I(e,t,o,r){let n=360/r;beginShape();for(let r=0;r<360;r+=n){let n=e+cos(r)*o,a=t+sin(r)*o;vertex(n,a)}endShape(CLOSE)}c2=color(cl2[e.random_int(0,7)]),c3=color(cl2[e.random_int(0,7)]),f>.5?fill(cl[e.random_int(0,M)]):f>.25?E(r,r,n+2*r,a+2*r,C,c2):A(r,r,n+2*r,a+2*r,C,c2),_>.5?(i=1,await async function(){let n=e.random_int(0,7),a=useMembership?await TwoFiveSix.getBorderColorForId(membershipId):cl2[n];noFill(),strokeWeight(r),stroke(a),rect(r,r,t-2*r,o-2*r)}()):i=0,noFill(),rectMode(CENTER),b>.824?(function(o){strokeWeight(targetThickness/(9.6*o));let i=56*o;X();for(let c=5*o;c>0;c--)if(stroke(cl2[e.random_int(0,7)]),u>.5)for(let e=.0625;e<1;e+=.125)for(let o=.0625;o<1;o+=.125)ellipse(2*r+n*e,2*r+a*o,c*t/i*z);else for(let o=.0625;o<1;o+=.125){let l=e.random_int(0,359);for(let s=.0625;s<1;s+=.125)arc(2*r+n*o,2*r+a*s,c*t/i*z,c*t/i*z,l,l-e.random_int(18,90))}}(k),gridMode='8 x 8',c=arcMode):b>.76?(function(o){strokeWeight(targetThickness/(10*o));let i=64*o;X();for(let c=5*o;c>0;c--){stroke(cl2[e.random_int(0,7)]);for(let e=.0625;e<1;e+=.125)for(let o=.0625;o<1;o+=.125)rect(2*r+n*e,2*r+a*o,c*t/i*z)}}(k),gridMode='8 x 8',c='Rectangles'):b>.696?(R(k,4),gridMode='8 x 8',c='Diamonds'):b>.648?(R(k,6),gridMode='8 x 8',c='Hexagons'):b>.616?(R(k,8),gridMode='8 x 8',c='Octagons'):b>.6?(R(k,10),gridMode='8 x 8',c='Decagons'):b>.468?(function(o){strokeWeight(targetThickness/(4.8*o));let i=32*o;X();for(let c=5*o;c>0;c--)if(stroke(cl2[e.random_int(0,7)]),u>.5)for(let e=.125;e<1;e+=.25)for(let o=.125;o<1;o+=.25)ellipse(2*r+n*e,2*r+a*o,c*t/i*z);else for(let o=.125;o<1;o+=.25){let l=e.random_int(0,359);for(let s=.125;s<1;s+=.25)arc(2*r+n*o,2*r+a*s,c*t/i*z,c*t/i*z,l,l-e.random_int(18,90))}}(k),gridMode='4 x 4',c=arcMode):b>.42?(function(o){strokeWeight(targetThickness/(5*o));let i=32*o;X();for(let c=5*o;c>0;c--){stroke(cl2[e.random_int(0,7)]);for(let e=.125;e<1;e+=.25)for(let o=.125;o<1;o+=.25)rect(2*r+n*e,2*r+a*o,c*t/i*z)}}(k),gridMode='4 x 4',c='Rectangles'):b>.372?(w(k,4),gridMode='4 x 4',c='Diamonds'):b>.336?(w(k,6),gridMode='4 x 4',c='Hexagons'):b>.312?(w(k,8),gridMode='4 x 4',c='Octagons'):b>.3?(w(k,10),gridMode='4 x 4',c='Decagons'):b>.212?(function(o){strokeWeight(targetThickness/(2.25*o)),X();let i=16*o;for(let c=5*o;c>0;c--)if(stroke(cl2[e.random_int(0,7)]),u>.5)for(let e=.25;e<1;e+=.5)for(let o=.25;o<1;o+=.5)ellipse(2*r+n*e,2*r+a*o,c*t/i*z);else for(let o=.25;o<1;o+=.5){let l=e.random_int(0,359);for(let s=.25;s<1;s+=.5)arc(2*r+n*o,2*r+a*s,c*t/i*z,c*t/i*z,l,l-e.random_int(18,90))}}(k),gridMode='2 x 2',c=arcMode):b>.18?(function(o){strokeWeight(targetThickness/(2.5*o));let i=16*o;X();for(let c=5*o;c>0;c--){stroke(cl2[e.random_int(0,7)]);for(let e=.25;e<1;e+=.5)for(let o=.25;o<1;o+=.5)rect(2*r+n*e,2*r+a*o,c*t/i*z)}}(k),gridMode='2 x 2',c='Rectangles'):b>.148?(D(k,4),gridMode='2 x 2',c='Diamonds'):b>.124?(D(k,6),gridMode='2 x 2',c='Hexagons'):b>.108?(D(k,8),gridMode='2 x 2',c='Octagons'):b>.1?(D(k,10),gridMode='2 x 2',c='Decagons'):b>.056?(function(r){X(),strokeWeight(targetThickness/r);for(let n=5*r;n>0;n--)if(stroke(cl2[e.random_int(0,7)]),u>.5)ellipse(t/2,o/2,n*t/(8*r)*z);else{let a=e.random_int(0,359);arc(t/2,o/2,n*t/(8*r),n*t/(8*r),a,a-e.random_int(18,90)*z)}}(k),gridMode='Single',c=arcMode):b>.04?(function(r){X(),strokeWeight(targetThickness/r);for(let n=5*r;n>0;n--)stroke(cl2[e.random_int(0,7)]),rect(t/2,o/2,n*t/(8*r)*z)}(k),gridMode='Single',c='Rectangles'):b>.024?(S(k,4),gridMode='Single',c='Diamonds'):b>.012?(S(k,6),gridMode='Single',c='Hexagons'):b>.004?(S(k,8),gridMode='Single',c='Octagons'):(S(k,10),gridMode='Single',c='Decagons'),rectMode(CORNER),strokeWeight(r),l>4?(strokeWeight(r),B(gX/2,gY,0,gY/2),B(gX,gY,gX/2,gY/2),W(),B(gX/2,gY/2,0,0),B(gX,gY/2,gX/2,0)):l>3?(strokeWeight(r),B(gX/2,gY,0,gY/2),B(gX/2,gY/2,0,0),W(),B(gX,gY,gX/2,gY/2),B(gX,gY/2,gX/2,0)):l>2?(strokeWeight(r),B(gX/2,gY,0,gY/2),B(gX,gY/2,gX/2,0),W(),B(gX,gY,gX/2,gY/2),B(gX/2,gY/2,0,0)):(Y=x,function(){noStroke();for(let t=0;t<gX;t++)for(let o=0;o<gY;o++){let i=color(cl[e.random_int(0,M)]);c2=color(cl[e.random_int(0,M)]),c3=color(cl[e.random_int(0,M)]),A(2*r+t*n/gX,2*r+o*a/gY/e.random_int(0,1),n/gX,a/gY/e.random_int(1,2),i,c2)}}()),l<=2&&m>.8&&(1,Y='Polychromatic'),function(r){loadPixels();let n=pixelDensity(),a=t*n*4*(o*n);for(let t=0;t<a;t+=4)gVal=e.random_num(-r,r),pixels[t]=pixels[t]+gVal,pixels[t+1]=pixels[t+1]+gVal,pixels[t+2]=pixels[t+2]+gVal;updatePixels()}(t/64)}function keyTyped(){'m'==key|'M'==key&&0!=inputData.membershipId&&(useMembership=!useMembership,redraw())}";
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