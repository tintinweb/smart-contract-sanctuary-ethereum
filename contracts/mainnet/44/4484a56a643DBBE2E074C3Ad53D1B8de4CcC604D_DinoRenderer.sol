// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*************************************************************
**           _               -x-++--+-x                     **
**     _____|_|_ __   ___   __  __ ___  _  ___  __   ___    **
**    / __  | | '_ \ / _ \ /  \/ / _ \| |__|  | '_ \/ __|   **
**   / /_/ /|_|_| |_| (_) /_/\__/ (_) |\__,_|_| | | \__ \   **
**  /_____/          \___/       \___/        |_| |_|___/   **
**                                                          **
*************************************************************/  

// Project  : DinoNouns
// Buidler  : Nero One
// Note     : Interactive on-chain DinoNouns - Dino Renderer -

import "@openzeppelin/contracts/utils/Base64.sol";

error NotOwner();

contract DinoRenderer {
    address public dinoUtility;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function getDinoHTML(string calldata _name, uint256 _id)
        external
        view
        returns (string memory)
    {
        string memory nounName = _name;
        string memory nounImage = IDinoUtility(dinoUtility).getNounsSVG(
            _name,
            _id
        );
        string memory dinoCSS = IDinoUtility(dinoUtility).getCSS(_id);
        string memory extraJS = IDinoUtility(dinoUtility).getExtraJS();

        bytes memory html;

        html = abi.encodePacked(
            '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>DinoNouns</title><link rel="icon" id="dynFav" type="image/svg+xml"></head><body> <div class="wrapper"> <img id="dinoImage" class="dino"> <svg width="500" height="500" fill="none"><rect x="10" y="10" width="480" height="480" rx=".65em" id="primStroke" stroke-width="6"/><g filter="url(#filter0_d_0_1)"><rect x="44" y="60" width="412" height="234" rx="12" id="primStroke" stroke-width="6" shape-rendering="crispEdges"/></g><g filter="url(#filter1_i_0_1)"><rect width="148" height="60" rx="15" id="accFill" transform="matrix(1 0 0 -1 176 87)"/></g><g filter="url(#filter2_d_0_1)"><rect x="44" y="356" width="194" height="36" id="accStroke" rx="12" stroke-width="6" shape-rendering="crispEdges"/></g><g filter="url(#filter3_d_0_1)"><rect x="42" y="409" width="414" height="42" rx="15" id="primFill"/></g><defs><filter id="filter0_d_0_1" x="37" y="57" width="426" height="248" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="4"/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_0_1"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_0_1" result="shape"/></filter><filter id="filter1_i_0_1" x="176" y="25" width="148" height="62" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="-4"/><feGaussianBlur stdDeviation="1"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="shape" result="effect1_innerShadow_0_1"/></filter><filter id="filter2_d_0_1" x="37" y="353" width="208" height="50" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="4"/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_0_1"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_0_1" result="shape"/></filter><filter id="filter3_d_0_1" x="38" y="409" width="422" height="50" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="4"/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_0_1"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_0_1" result="shape"/></filter></defs></svg> <svg width="85" height="26" id="dinoTitle" fill="none"><g filter="url(#filter0_i_34_1025)" fill="#fff"><path d="M17.212 0v25.822H0V8.602h8.603V0h8.61ZM22.593 8.603V0h8.61v8.603h-8.61Zm0 17.22v-8.604h8.61v8.61l-8.61-.007ZM53.797 0v8.603h-8.61v17.22h-8.603V0h17.213Zm0 25.822V8.602h8.61v17.22h-8.61ZM67.788 25.822V8.602H85v17.22H67.788Z"/></g><defs><filter id="filter0_i_34_1025" x="0" y="0" width="85" height="25.829" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="2"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="shape" result="effect1_innerShadow_34_1025"/></filter></defs></svg> <h1 id="dinoName">dino</h1> <input type="text" placeholder="type here" id="inputText" autofocus> <span id="log"></span> <span id="reaction"></span> <div class="btns" id="btnA">A</div> <div class="btns" id="btnB">B</div> <div class="btns" id="btnX">X</div> <div class="btns" id="btnY">Y</div> <div id="btnLvl"></div> <span id="lvlTxt"></span> </div> </body>',
            dinoCSS,
            '<script>const onchainSVG="',
            nounImage,
            '",onchainName="',
            nounName,
            '",prefix="/",el=I=>document.getElementById(I);let inputText=el("inputText"),dinoImage=el("dinoImage"),dinoName=el("dinoName"),outputLog=el("log"),reaction=el("reaction"),lvlTxt=el("lvlTxt");function Dino(){this.name="dino",this.image="",this.stats={}}const ding=new Dino,setTitleFavicon=()=>{let I=ding.image;el("dynFav").href=I,document.title=ding.name},setInit=(I,i)=>{const a={str:1,agi:1,lvl:1,age:1};ding.stats=a,ding.name=i,ding.image=I,dinoName.innerHTML=ding.name,dinoImage.src=ding.image,lvlTxt.innerHTML=`LV${a.lvl}`,setTitleFavicon()},getDino=async I=>{setInit(onchainSVG,I)};getDino(onchainName);const statError=()=>console.error("No such stat"),addStat=(I,i)=>{ding.stats.hasOwnProperty(I)?ding.stats[I]+=i:statError()},subStat=(I,i)=>{ding.stats.hasOwnProperty(I)?ding.stats[I]-=i:statError()},setStat=(I,i)=>{ding.stats.hasOwnProperty(I)?ding.stats[I]=i:statError()},sleep=I=>new Promise((i=>setTimeout(i,I))),resetAnimation=()=>dinoImage.style.animationName="",clearLog=()=>log(""),clearReact=()=>react(""),log=I=>outputLog.innerHTML=I,react=I=>reaction.innerHTML=I,reactAnim=async()=>{react("."),await sleep(200),react(".."),await sleep(200),react("..."),await sleep(200)};ding.image&&ding.name&&ding.stats&&(setTitleFavicon(),dinoImage.src=ding.image,dinoName.innerHTML=ding.name),setInterval((()=>{addStat("lvl",.1),lvlTxt.innerHTML=`LV${ding.stats.lvl.toFixed(1)}`}),6e4);const run={name:"run",args:!1,help:"run! agi+ energy-",usage:"/run",async exec(I){dinoImage.style.animationName="run",log("running.."),await sleep(500),log("running..."),await sleep(500),log("running...."),await sleep(500),log("running....."),await sleep(500),clearLog(),clearReact();const i=parseFloat(ding.stats.agi);addStat("agi",.01*i),resetAnimation()}},jump={name:"jump",aliases:["j","lompat"],args:!1,help:"jump! str+ energy-",usage:"/jump",async exec(I){dinoImage.style.animationName="jump",log("jumping.."),await sleep(500),log("jumping..."),await sleep(500),log("jumping...."),await sleep(500),log("jumping....."),await sleep(500),clearLog(),clearReact();let i=parseFloat(ding.stats.str);addStat("str",.01*i),resetAnimation()}},dino={name:"dino",args:!0,help:"give temporary nickname",usage:"/dino [name]",async exec(I){let i=I.slice(0).join(" ");log("running through the letters.."),await sleep(1e3),log("changing dino name.."),await sleep(1e3),i.length>0?await getDino(i):log("no name specified"),clearLog(),clearReact()}},clear={name:"clear",args:!1,aliases:["cls","clr"],help:"clear log",usage:"/clear",async exec(I){log("clearing log"),await sleep(500),clearLog(),clearReact()}},help={name:"help",args:!0,bypass:!0,usage:"/help [command]",async exec(I){if(!I.length)return log("Get the help file for commands. eg: /help [command]");const i=I[0].toLowerCase(),a=cmds.find((I=>I.name===i))||cmds.find((I=>I.aliases&&I.aliases.includes(i)));if(!a)return log("Unknown command");a.help?(log(a.help),await sleep(2000),log("usage: "+a.usage),await sleep(3e3),clearLog(),clearReact()):(log("no help file. contact admin"),await sleep(1e3),clearLog(),clearReact())}},reset={name:"reset",args:!1,help:"reset dino",usage:"/reset",async exec(I){log("initiate comlink.."),await sleep(1e3),log("fetching default dino.."),await sleep(1e3),getDino(onchainName),clearLog(),clearReact()}},teach={name:"teach",args:!0,help:"teach dino words",usage:"/teach [word] [reply]",async exec(I){const i=I[0],a=I.slice(1).join(" ");if(""===a)return log("give me the reply pls");repl.push({[i]:a}),log("teaching dino.."),await sleep(1e3),log(`u can use [${i}] now`),await sleep(1e3),clearLog(),clearReact()}};let mapping={a:"",b:"",x:"",y:""};const map={name:"map",args:!0,bypass:!0,help:"map cmd to button",usage:"/map [a/b/x/y] [command]",async exec(I){let i=I[0],a=I[1];if(!a)return log("please specify a command");return cmds.find((I=>I.name===a))||cmds.find((I=>I.aliases&&I.aliases.includes(a)))?"a"!==i&&"b"!==i&&"x"!==i&&"y"!==i?log("use a/b/x/y only"):(log("mapping buttons.."),await sleep(1e3),mapping[i]=a,log("done!"),await sleep(1e3),clearLog(),void clearReact()):log("no such command exist")}};let cmds=[run,jump,dino,help,clear,reset,map,teach];const runCMD=async()=>{if(!inputText.value.startsWith("/"))return runConv();const I=inputText.value.slice("/".length).trim().split(/ +/),i=I.shift().toLowerCase(),a=cmds.find((I=>I.name===i))||cmds.find((I=>I.aliases&&I.aliases.includes(i)));if(!a)return log("Unknown command. use /help");if(a.args&&!I.length)return a.usage?log(a.usage):log("No parameter provided");try{if(!a.bypass){if(Math.floor(10*Math.random())<2)return react(`${ding.name} does not feel like it`)}await a.exec(I)}catch(I){log(I)}},repl=[{hi:"hello human"},{hello:"rawr"},{haha:"hahaha"},{hungry:"plis go eat"},{help:"use /help"},{wait:"wat?"},{yes:"yes?"},{no:"no?"},{nouns:`<a href="https://nouns.wtf" target="_blank">nouns.wtf</a>`},{center:`<a href="https://nouns.center" target="_blank">nouns.center</a>`}],runConv=async()=>{const I=inputText.value;let i=repl.filter((i=>null!=i[I]));const a=cmds.find((i=>i.name===I));return a&&I.includes(a.name)?(react(I),log(`use /${a.name}`),await sleep(2e3),clearLog(),clearReact()):i.length>0?(await reactAnim(),react(i[0][I])):(await reactAnim(),react(I))};let btnA=el("btnA"),btnB=el("btnB"),btnX=el("btnX"),btnY=el("btnY");btnA.onclick=()=>{if(""==mapping.a)return log("/map a [cmd] | eg: /map a run");inputText.value=`/${mapping.a}`,runCMD()},btnB.onclick=()=>{if(""==mapping.b)return log("/map b [cmd] | eg: /map b run");inputText.value=`/${mapping.b}`,runCMD()},btnX.onclick=()=>{if(""==mapping.x)return log("/map x [cmd] | eg: /map x run");inputText.value=`/${mapping.x}`,runCMD()},btnY.onclick=()=>{if(""==mapping.y)return log("/map y [cmd] | eg: /map y run");inputText.value=`/${mapping.y}`,runCMD()},document.addEventListener("keypress",(I=>{if("Enter"===I.key&&(I.preventDefault(),runCMD()),inputText!=document.activeElement)switch(I.key){case"Enter":I.preventDefault(),runCMD();break;case"a":btnA.click();break;case"b":btnB.click();break;case"x":btnX.click();break;case"y":btnY.click()}}),!1);',
            extraJS,
            "</script></html>"
        );

        html = abi.encodePacked("data:text/html;base64,", Base64.encode(html));
        string memory output = string(html);

        return output;
    }

    function setDinoUtilityAddress(address _address) external onlyOwner {
        dinoUtility = _address;
    }
}

interface IDinoUtility {
    function getNounsSVG(string calldata _name, uint256 _id)
        external
        view
        returns (string memory);

    function getCSS(uint256 _id) external view returns (string memory);

    function getExtraJS() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}