// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Payable {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function deposit() payable external {

    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}