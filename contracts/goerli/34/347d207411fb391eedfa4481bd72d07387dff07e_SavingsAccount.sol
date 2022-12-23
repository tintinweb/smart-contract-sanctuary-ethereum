/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SavingsAccount {
    address payable public  owner;

    constructor() payable {
        owner = payable(msg.sender);
    }
    function deposit() public  payable returns (string memory) {
        return "deposited";
    }


    function withdraw() public {
        require(msg.sender == owner,"Only Owner Can Withdraw funds");
        (bool success,) = msg.sender.call{value:address(this).balance}("");
        require(success,"transfer failed");   
    }
   
}