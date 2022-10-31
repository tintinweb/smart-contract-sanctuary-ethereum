/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Game {
    
    uint public balance;

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function receiveMoney() public payable {
        balance += msg.value;
    }

    function payWinner(address payable winner) payable public {
        winner.transfer(address(this).balance);
        balance = 0;
    }

}