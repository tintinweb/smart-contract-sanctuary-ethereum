// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract InterversePay {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function buy() external payable {
        require(msg.value == 200000000000000000, "Please pay 0.2ETH!");
    }

    function withdraw(uint _amt) external {
        require(msg.sender == owner, "You are not the owner!");
        payable(msg.sender).transfer(_amt);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}