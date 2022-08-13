/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBubbles {
    function mint(address recipient, uint256 amount) external;
}

contract BubbleBank {
    IBubbles bubble;
    constructor (address _bubble) {
        bubble = IBubbles(_bubble);
    }
    function claim10Bubbles() external {
        bubble.mint(msg.sender, 10 ether);
    }
}