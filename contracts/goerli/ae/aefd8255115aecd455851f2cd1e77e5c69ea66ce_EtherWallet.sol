/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract EtherWallet{
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);  
    }

    receive() external payable{}

    function withdraw(uint _amount) external{
     require(msg.sender == owner, "only the owner can call this method." );
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }
}