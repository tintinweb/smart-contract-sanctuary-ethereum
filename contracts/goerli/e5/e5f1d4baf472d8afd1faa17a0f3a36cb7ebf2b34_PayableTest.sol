/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PayableTest {

    event Deposit(address _from, uint _value);

    constructor() {}

    function payAnything() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function paySingleEth() external payable {
        require(msg.value == 1000000000000000000, "You must pay 1 Eth");
        emit Deposit(msg.sender, msg.value);
    }

    function withDraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}