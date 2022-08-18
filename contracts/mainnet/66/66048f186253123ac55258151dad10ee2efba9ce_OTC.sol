/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address, address, uint) external returns (bool);
}

contract OTC {

    address public constant INV = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;
    address public constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address public immutable concave;
    address public immutable inverse;
    bool public swapped;

    constructor(address _concave, address _inverse) {
        concave = _concave;
        inverse = _inverse;
    }

    function swap() public {
        require(!swapped);
        IERC20(INV).transferFrom(inverse, concave, 2500 ether);
        IERC20(DOLA).transferFrom(concave, inverse, 283525 ether);
        swapped = true;
    }
}