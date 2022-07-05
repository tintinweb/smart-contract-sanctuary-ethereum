// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amt) external {
        require(msg.sender == owner, " You are not the owner!");
        payable(msg.sender).transfer(_amt);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}