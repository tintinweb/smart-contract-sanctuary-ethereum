/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.7.2;

contract pigbank{
    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable{}

     
    function showBalance() public view returns(uint){
        return address(this).balance;
    }

    function withdraw() public {
        if (showBalance() > goal){
            selfdestruct(msg.sender);
        }
    }

}