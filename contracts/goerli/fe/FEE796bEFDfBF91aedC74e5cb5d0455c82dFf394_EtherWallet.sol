/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract EtherWallet{

    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "The caller is not the owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }


}