/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.4.22 <0.8.0;


contract PiggyBank{
    uint public goal;

    constructor(uint _goal)public {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public {
        if(getMyBalance() > goal){
            selfdestruct(msg.sender);
        }
    }
}