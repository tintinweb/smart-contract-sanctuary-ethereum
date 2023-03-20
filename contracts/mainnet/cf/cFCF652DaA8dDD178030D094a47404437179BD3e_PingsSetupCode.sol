// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ICode.sol";

contract PingsSetupCode is ICode {

    string public code = 'let pings=Pings();urlParams=parseUrlParams();if(urlParams !== null) {pings.setParams(urlParams);}let q=new Q5();let canvas=q.canvas;pings.sketch(q);q.resize(q.windowWidth,q.windowHeight);window.onresize=()=>{let mainElement=document.body;recalcSketchSize(mainElement,canvas,q);pings.windowResized();};';

    function getCode(string calldata) external view override returns(string memory) {
        return code;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
}