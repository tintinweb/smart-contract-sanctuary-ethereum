/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract PiggyBank {
    uint public goal;
    
    constructor(uint _goal) {
        goal = _goal;
    }
    
    receive() external payable {}
    
    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdraw() public {
        if (getMyBalance() > goal) {
            selfdestruct(payable(msg.sender));
        }
    }
}