// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICode.sol";

contract PingsCode is ICode, Ownable{
    string public code_start = 'const Pings=(inputParams)=>{';
    string public code_end = '};';

    mapping (uint => string) public subCode;
    uint[] public codeOrder;

    constructor() {
        subCode[9999] = ""; //padding
        initData();
    }

    function initData() internal {
        uint i = 0;
        //SECTION PARAMS
        setSubCode(i++, i, 'let p;let testMode=true;let tokenId=1234;let numX=1;let numY=1;let lineThickness=1;let emitRate=10;let wiggleSpeedIdx=0;let wiggleStrengthIdx=0;let shapeSizesDensity=4;let paletteIndex=0;let paintIdx=0;let paint2Idx=0;let lineColorIdx=0;let shapeColorIdx=0;let shadowColorIdx=0;let nShadColIdx=0;let emitColorIdx=0;let openShape=false;let hasTexture=false;let colorCallback;let setBackgroundCallback=function(callback){colorCallback=callback;};let onBackgroundChange=function(){if(colorCallback!==undefined){colorCallback([paint,paint2]);}};let getParams=function(){return [tokenId,numX,numY,paletteIndex,hasTexture,openShape,lineColorIdx,paintIdx,shapeColorIdx,emitColorIdx,shadowColorIdx,nShadColIdx,shapeSizesDensity,lineThickness,emitRate,wiggleSpeedIdx,wiggleStrengthIdx,paint2Idx];};let setParams=function(input){testMode=false;let i=0;tokenId=input[i++]+100000; numX=input[i++];numY=input[i++];paletteIndex=input[i++];hasTexture=input[i++];openShape=input[i++];lineColorIdx=input[i++];paintIdx=input[i++];shapeColorIdx=input[i++];emitColorIdx=input[i++];shadowColorIdx=input[i++];nShadColIdx=input[i++];shapeSizesDensity=input[i++];lineThickness=input[i++];emitRate=input[i++];wiggleSpeedIdx=input[i++];wiggleStrengthIdx=input[i++];paint2Idx=input[i++];};if(inputParams!==undefined){setParams(inputParams);}'
        );
        //SECTION 2 - P5 IMPL FUNCTIONS - SETUP KEYPRESSED ETC
        setSubCode(i++, i, 'let setup=()=>{_setup(p);};let draw=()=>{_draw(p);};let windowResized=()=>{_windowResized(p);};let keyPressed=()=>{_keyPressed(p);};let p5Sketch=(p5)=>{p=p5;p.setup=setup;p.draw=draw;p.windowResized=windowResized;p.keyPressed=keyPressed;};let regenerate=()=>{generateTestData(p);};let fullscreenCanvas=()=>{let sketchesElement=document.getElementById("sketchesFrame");launchFullscreen(sketchesElement);};let debLog;let colorUrls=["ff4b3e-36213e-c45baa-32936f-f7b801","264653-2a9d8f-e9c46a-f4a261-e76f51","ff0a54-ff477e-ff5c8a-ff7096-ff85a1-ff99ac-fbb1bd-f9bec7-f7cad0-fae0e4","d8e2dc-ffe5d9-ffcad4-f4acb7-9d8189","2ebed9-795ec1-26e3e3-e83de1-f5f84b","433158-8988a0-e8d9be-a87775-6ba2c9-e2dcde","6C4A35-6d1f09-a05d32-cfa57b-f6e9d6","8d2a00-b55219-be6731-76704c-545e46-1f2d16","f404cf-90f505-01f5bb-037df4-af31f5-F50561","2d00f7-6a00f4-8900f2-a100f2-b100e8-bc00dd-d100d1-db00b6-e500a4-f20089","e574bc-ea84c9-ef94d5-f9b4ed-eabaf6-dabfff-c4c7ff-adcfff-96d7ff-7fdeff","ff99c8-fcf6bd-d0f4de-a9def9-e4c1f9","001427-708d81-f4d58d-bf0603-8d0801","d6d6d6-ffee32-F5C800-202020-333533","000000-ffffff","03b5aa-037971-023436-00bfb3-049a8f","f9f0a1-d8d085-718f8d-5ecbdf-90e7f8-c8f2fe","c6a477-eed7a3-f7ead7-d3e7ee-abd1dc-7097a8","c8823c-1d181d-bb5f36-769ea0"];let palette;let restOfColors;let paint;let paint2;let lineColor;let shapeColor;let shadowColor;let nShadCol;let emitColor;const refreshRate=60;const maxShape=8;const chargeSpeed=0.05;let backgBuff;let speeds=[1,30];let speedIdx=0;let displaySpeed=speeds[speedIdx];let t=0;let t2=0;let zoom=1;let seeds=tokenId;let w;let h;let vigour;let nC=1000;let nodeSize=10;let bgCurvePoints=[];let pressurePoints=[];let nodeScale=1;let spots=new Set();let wiggleSpeeds=[0.1,0.05,0.01];let wiggleSpeed;let wiggleStrengths=[0,5,10,20];let wiggleStrength;function _setup(p){_lastFrameTime=window.performance.now();setWindowParams(p);p.createCanvas(w,h);p.frameRate(refreshRate);p.colorMode(p.RGB);p.ellipseMode(p.RADIUS);p.strokeJoin(p.BEVEL);p.strokeCap(p.ROUND);if(testMode){generateTestData(p);}palette=getColorsFromUrl(p,colorUrls[paletteIndex]);initiateData();recalcData(p);}function createBackground(p){backgBuff=p.createGraphics(w,h);drawBackground(backgBuff);if(hasTexture){drawNoise(backgBuff);}}function _keyPressed(p){if(p.keyCode===32||p.keyCode===83){if(testMode){generateTestData(p);}}else if(p.keyCode===70){let fs=fullscreen();fullscreen(!fs);}else if(p.keyCode===82){windowResized();}}'
        );
        //SECTION 3 - CLASSES
        setSubCode(i++, i, 'class PP{constructor(x,y,size,shape,phase){this.x=x;this.y=y;this.dx=x;this.dy=y;this.px=0.5;this.py=0.5;this.size=size;this.shape=shape;this.shape2=this.shape;   this.seed=seeds++;this.phase=phase;this.charge=0;}moveit(p){let step=this.seed+this.phase;let nx=(p.noise(this.seed,(t+this.phase)*wiggleSpeed+step*1,0)-0.45);let ny=(p.noise(this.seed,(t+this.phase)*wiggleSpeed+step*2,1)-0.45);this.dx=this.x+nx*vigour;this.dy=this.y+ny*vigour;this.shape+=(this.shape2-this.shape)*0.5;}shouldEmit(p){if(this.charge>0){this.chargeUp(p);return;}if(this.shape2>0&&p.random(1)<emitRate/10/refreshRate){this.chargeUp(p);}}chargeUp(p){this.charge+=0.1;if(this.charge>1){this.charge=0;this.emit(p);}}emit(p){let direction=int(p.random(4));let next;let nextNext;let previous;switch(direction){case 0:next=this.top;if(next!=null){nextNext=next.top;previous=this.bottom;break;}case 1:next=this.bottom;if(next!=null){nextNext=next.bottom;previous=this.top;break;}case 2:next=this.left;if(next!=null){nextNext=next.left;previous=this.right;break;}case 3:next=this.right;if(next!=null){nextNext=next.right;previous=this.left;break;}}if(next!=null){this.shape2--;spots.add(new Spot(previous,this,next,nextNext,this.size));}}receive(p){this.shape2++;if(this.shape2>maxShape){this.emit(p);}}drawit(p){p.push();p.translate(this.dx,this.dy);p.scale(this.size);this.drawShape(p);p.pop();}drawShape(p){p.scale(3+this.charge);p.strokeWeight(0.5);if(this.shape<0.01){}else if(this.shape<1.01){p.strokeWeight(0.5*(this.shape));p.stroke(shapeColor);p.line(0,0,0,0);}else if(this.shape<=2.01){   let l=(this.shape-1);p.stroke(shapeColor);p.line(-l/2,0,l/2,0);}else{if(openShape){p.noFill();p.stroke(shapeColor);p.fill(paint);}else{p.noStroke();p.fill(shapeColor);}p.beginShape();let a=0;p.vertex(Math.cos(a),Math.sin(a));for(let i=0; i<this.shape; i++){a=p.TWO_PI*i/this.shape;p.vertex(Math.cos(a),Math.sin(a));}p.endShape(p.CLOSE);}}}class Spot{constructor(pp0,pp1,pp2,pp3,size){this.pp0=(pp0!=null)?pp0:pp1;this.pp1=pp1;this.pp2=pp2;this.pp3=(pp3!=null)?pp3:pp2;this.t=0;this.size=size*1.3;}drawit(p){p.fill(emitColor);p.noStroke();if(this.t>1){spots.delete(this);this.pp2.receive(p);}else{let x=p.curvePoint(this.pp0.dx,this.pp1.dx,this.pp2.dx,this.pp3.dx,this.t);let y=p.curvePoint(this.pp0.dy,this.pp1.dy,this.pp2.dy,this.pp3.dy,this.t);p.circle(x,y,this.size);this.t+=0.01;}}}'
        );
        //SECTION - DRAWING
        setSubCode(i++, i, 'function _draw(p){setDelta();let delta=speeds[speedIdx]-displaySpeed;displaySpeed=displaySpeed+delta*0.05;t=(t+(deltaTime*displaySpeed)/refreshRate)%129600; t2=(t2+(deltaTime*displaySpeed)/refreshRate)%129600;for(const pressurePointsx of pressurePoints){for(const pp of pressurePointsx){pp.moveit(p);}}p.image(backgBuff,0,0,w,h);p.translate(w/numX/2,h/numY/2);p.drawingContext.shadowColor=shadowColor;p.drawingContext.shadowOffsetX=5;p.drawingContext.shadowOffsetY= -5;p.drawingContext.shadowBlur=10;for(let i=0; i<pressurePoints.length; i++){drawWaterLine(p,lineColorIdx,pressurePoints[i]);}for(let i=0; i<pressurePoints[0].length; i++){drawWaterLine(p,lineColorIdx,pressurePoints.map(line=>line[i]));}for(const spot of spots){spot.drawit(p);}for(const pressurePointsx of pressurePoints){for(const pp of pressurePointsx){pp.shouldEmit(p);pp.drawit(p);}}}function drawNoise(p){p.push();let dotScale=Math.min(w,h)/500;p.drawingContext.shadowColor=nShadCol;p.drawingContext.shadowOffsetX=dotScale*0.6;p.drawingContext.shadowOffsetY=-dotScale*0.6;p.fill(paint);p.noStroke();let r=w/h;let nx=nC*r;let ny=nC/r;for(let i=0; i<nx; i+=7){for(let j=0; j<ny; j+=7){let n=p.noise(i,j);if(n<0.3){p.circle(i/nx*w,j/ny*h,dotScale);}}}p.pop();}function drawBackground(p){p.push();let gradient=p.drawingContext.createLinearGradient(0,h,w,0);gradient.addColorStop(0,paint2);gradient.addColorStop(1,paint);p.drawingContext.fillStyle=gradient;p.beginShape();p.noStroke();p.vertex(0,0);p.vertex(w,0);p.vertex(w,h);p.vertex(0,h);p.endShape();let col=p.color(paint._r,paint._g,paint._b);gradient=p.drawingContext.createLinearGradient(0,h,w,0);gradient.addColorStop(0,col);gradient.addColorStop(1,paint2);p.drawingContext.fillStyle=gradient;p.noStroke();p.beginShape();for(const pp of bgCurvePoints){p.curveVertex(pp[0],pp[1]);}p.endShape();p.pop();}function drawWaterLine(p,index,pressurePoints){p.push();let colorIdx=(index+1)%restOfColors.length;theColor1=new p.color(restOfColors[colorIdx]);theColor=new p.color(restOfColors[(colorIdx+1)%restOfColors.length]);p.strokeWeight(lineThickness);p.stroke(restOfColors[colorIdx]);p.noFill();p.beginShape();let last=pressurePoints.length-1;p.curveVertex(pressurePoints[0].x,pressurePoints[0].y);for(const pp of pressurePoints){p.curveVertex(pp.dx,pp.dy);}p.curveVertex(pressurePoints[last].x,pressurePoints[last].y);p.endShape();p.pop();}'
        );
        //SECTION 4 - DATA RECALC
        setSubCode(i++, i, 'function initiateData(){if(debLog){logDetails();}let chosenPaint=paintIdx%palette.length;paint=palette[chosenPaint];restOfColors=[...palette];restOfColors.splice(chosenPaint,1);paint2=restOfColors[paint2Idx%restOfColors.length];lineColor=restOfColors[lineColorIdx%restOfColors.length];shapeColor=restOfColors[shapeColorIdx%restOfColors.length];shadowColor=restOfColors[shadowColorIdx%restOfColors.length];nShadCol=restOfColors[nShadColIdx%restOfColors.length];emitColor=restOfColors[emitColorIdx%restOfColors.length];wiggleStrength=wiggleStrengths[wiggleStrengthIdx%wiggleStrengths.length];vigour=wiggleStrength*10/Math.min(numX,numY);vigour=wiggleStrength*(11-Math.max(numX,numY));wiggleSpeed=wiggleSpeeds[wiggleSpeedIdx%wiggleSpeeds.length];onBackgroundChange(paint,paint2);}function recalcData(p){t=0;t2=0;seeds=tokenId;p.noiseSeed(tokenId);p.noiseDetail(1,0.5);p.randomSeed(tokenId);recalcBackgroundWave(p);createBackground(p);recalcPressurePoints(p);}function recalcBackgroundWave(p){bgCurvePoints=[];let rx;let ry;let v=0.1;bgCurvePoints.push([-w,-h]);bgCurvePoints.push([-w,h]);bgCurvePoints.push([w*(0+p.random(-v,v)),h*(1+p.random(-v,v))]);bgCurvePoints.push([w*(0.5+p.random(-v,v)),h*(0.5+p.random(-v,v))]);bgCurvePoints.push([w*(1+p.random(-v,v)),h*(0+p.random(-v,v))]);bgCurvePoints.push([w,-h]);bgCurvePoints.push([-w,-h]);}function recalcPressurePoints(p){let windowScale=Math.min(w,h);let nodeScale=nodeSize*windowScale*0.001;pressurePoints=[];spots=new Set();let edgeX=1/numX*0.5;let edgeY=1/numY*0.5;for(let i=0; i<numX; i++){pressurePoints[i]=[];for(let j=0; j<numY; j++){pp=new PP((edgeX+float(i)/numX*w),(edgeY+float(j)/numY*h),nodeScale,1+int(p.random(shapeSizesDensity)),p.random(1));pressurePoints[i][j]=pp;if(j===0){pp.left=null;}else{pp.left=pressurePoints[i][j-1];pressurePoints[i][j-1].right=pp;}if(j===numX){pp.right=null;}if(i===0){pp.top=null;}else{pp.top=pressurePoints[i-1][j];pressurePoints[i-1][j].bottom=pp;}if(i===numY){pp.bottom=null;}}}}function setWindowParams(p){w=p.width;h=p.height;}function _windowResized(p){p.resizeCanvas(p.width,p.height);setWindowParams(p);recalcData(p);p.strokeJoin(p.BEVEL);p.strokeCap(p.ROUND);}function getColorsFromUrl(p,url){let colStrs=url.split("-");let cols=[];for(colStr of colStrs){cols.push(p.color(parseInt(colStr.substring(0,2),16),parseInt(colStr.substring(2,4),16),parseInt(colStr.substring(4,6),16)));}return cols;}'
        );
//        //SECTION RANDOM GEN + LOG
//        'function randomGeneration(p){paletteIndex=int(p.random(colorUrls.length));palette=getColorsFromUrl(p,colorUrls[paletteIndex]);paintIdx=int(p.random(palette.length));paint2Idx=int(p.random(palette.length));lineColorIdx=int(p.random(palette.length));shapeColorIdx=int(p.random(palette.length));shadowColorIdx=int(p.random(palette.length));nShadColIdx=int(p.random(palette.length));emitColorIdx=int(p.random(palette.length));numX=1+int(p.random(7));numY=1+int(p.random(7));lineThickness=1+int(p.random(5));wiggleStrength=10+int(p.random(40));wiggleStrengthIdx=int(p.random(wiggleStrengths.length));wiggleSpeedIdx=int(p.random(wiggleSpeeds.length));shapeSizesDensity=1+int(p.random(7));emitRate=1+int(p.random(10));openShape=p.random(2)<1;hasTexture=p.random(2)<1;tokenId=int(p.random(2000));}'
//        'function logDetails(){console.log("=========================");console.log("tokenId",tokenId);console.log("numX",numX);console.log("numY",numY);console.log("paletteIndex",paletteIndex);console.log("hasTexture",hasTexture);console.log("openShape",openShape);console.log("lineColorIdx",lineColorIdx);console.log("paintIdx",paintIdx);console.log("shapeColorIdx",shapeColorIdx);console.log("emitColorIdx",emitColorIdx);console.log("shadowColorIdx",shadowColorIdx);console.log("nShadColIdx",nShadColIdx);console.log("shapeSizesDensity",shapeSizesDensity);console.log("lineThickness",lineThickness);console.log("emitRate",emitRate);console.log("wiggleSpeedIdx",wiggleSpeedIdx);console.log("wiggleStrengthIdx",wiggleStrengthIdx);console.log("paint2",paint2Idx);console.log("["+tokenId+","+numX+","+numY+","+paletteIndex+","+hasTexture+","+openShape+","+lineColorIdx+","+paintIdx+","+shapeColorIdx+","+emitColorIdx+","+shadowColorIdx+","+nShadColIdx+","+shapeSizesDensity+","+lineThickness+","+emitRate+","+wiggleSpeedIdx+","+wiggleStrengthIdx+","+paint2Idx+"]");}function generateTestData(p){randomGeneration(p);initiateData();recalcData(p);}'
        //SECTION HELPERS + EXPORT
        setSubCode(i++, i, 'function int(n){return n|0;}function float(s){return parseFloat(s);}let deltaTime=0;let _lastFrameTime=0;function setDelta(){var now=window.performance.now();deltaTime=now-_lastFrameTime;_lastFrameTime=now; }function parseInputString(tokenParamsStr){console.log("tokenParamsStr:",tokenParamsStr);return JSON.parse(tokenParamsStr);}function urlUnfriendly(str){str=(str+"===").slice(0,str.length+(4-(str.length%4))%4);return str.replace(/-/g,"+").replace(/_/g,"/");}return {sketch:p5Sketch,params:getParams,setParams:setParams,windowResized:windowResized,setBackgroundCallback:setBackgroundCallback,regenerate:regenerate,fullscreenCanvas:fullscreenCanvas,setup:setup};'
        );

        addPadding();
    }


    function getCode(string calldata) external view override returns(string memory) {
        return string.concat(
            code_start,
            getCodeBody(),
            code_end
        );
    }
    function getCodeBody() public view returns(string memory) {
        string memory s = "";

        for (uint8 i = 0; i < codeOrder.length;) {
            s = string.concat(s,
                subCode[codeOrder[i++]],
                subCode[codeOrder[i++]],
                subCode[codeOrder[i++]],
                subCode[codeOrder[i++]],
                subCode[codeOrder[i++]],
                subCode[codeOrder[i++]]
            );
        }

        return s;
    }

    function setOrder(uint[] calldata order) external virtual onlyOwner {
        codeOrder = order;
    }

    function getNumBlocks() external view returns(uint) {
        return codeOrder.length;
    }

    function setSubCode(uint idx, uint id, string memory codeStr) public virtual onlyOwner {
        subCode[id] = codeStr;
        if(idx < codeOrder.length) {
            codeOrder[idx]=id;
        }
        else {
            codeOrder.push(id);
        }
    }

    function addPadding() public onlyOwner {
        uint batchSize = 6;
        uint paddingCount = batchSize - (codeOrder.length % batchSize);
        if (paddingCount != batchSize) { // add padding only if needed
            for (uint i = 0; i < paddingCount; i++) {
                codeOrder.push(9999);
            }
        }
    }

    function setCodeStart(string calldata code) public virtual onlyOwner {
        code_start = code;
    }

    function setCodeEnd(string calldata code) public virtual onlyOwner {
        code_end = code;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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