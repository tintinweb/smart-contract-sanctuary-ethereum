/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SendnReceive {
    address payable public owner;

    constructor(){
        owner = payable (msg.sender);
    }

    receive() external payable{}

    function withdraw(uint _amount ) external {
        require(msg.sender == owner, "you are not the owner");
        payable(msg.sender).transfer(_amount);
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }
}