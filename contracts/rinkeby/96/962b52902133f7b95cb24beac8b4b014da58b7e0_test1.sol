/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
// File: polkaTest/test1.sol


pragma solidity ^0.8.0;

contract test1 {

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}    

    function purchase() public payable {
        // address payable me = payable(this);
        // me.transfer(msg.value);
    }

    function withdraw() public {
        address payable dest = payable(msg.sender);
        dest.transfer(address(this).balance);
    }

    function getBalance() public view returns(uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}