// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ICode.sol";

contract ResizeCode is ICode {

    string public code = 'function recalcSketchSize(htmlElement,canvasToAttach,q){let styles=getComputedStyle(htmlElement);let w=parseInt(styles.getPropertyValue("width"),10);let h=parseInt(styles.getPropertyValue("height"),10);canvasToAttach.width=w;canvasToAttach.height=h;console.log(w,",",h);q.resizeCanvas(w,h);}';

    function getCode(string calldata) external view override returns(string memory) {
        return code;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
}