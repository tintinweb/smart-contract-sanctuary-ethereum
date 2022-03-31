/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Wallet {
    address payable public owner;


    constructor() public {
        owner = payable(msg.sender);
    }

    function withdraw(uint _amount) external {
        require(msg.sender == owner,"not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    receive() external payable{}
}