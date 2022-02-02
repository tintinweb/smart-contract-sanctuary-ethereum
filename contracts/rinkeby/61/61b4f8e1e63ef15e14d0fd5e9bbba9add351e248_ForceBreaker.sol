/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Self destruct gives remaining either to designated contract

contract ForceBreaker {
    constructor() public payable {}
    
    function selfDestruct() public {
        address payable addr = payable(address(0xEa72F49487F31C23e603B029bf839a84dE7808C9));
        selfdestruct(addr);
    }
}