// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Selfdestruct {
    function deposit(uint256 amount) public payable {
        payable(address(this)).transfer(amount);
    }

    function kill(address a) public payable {
        selfdestruct(payable(a));
    }

    receive() external payable {}

    fallback() external payable {}
}