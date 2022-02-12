/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract PiggyBank{
    uint public goal;

    constructor(uint _goal){
        goal = _goal;
    }

    receive() external payable{
        
    }

    function get_my_balance() public view returns (uint){
        return address(this).balance;
    }
    function withdraw() public{
        if(get_my_balance() > goal){
            selfdestruct(msg.sender);
        }
    }
}