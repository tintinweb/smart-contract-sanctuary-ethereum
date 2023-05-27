// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SimpleMoney{
    mapping (address => uint) public ledger;

    function deposit() external payable {
        ledger[msg.sender] += msg.value;
    }

    function withdraw(uint amt) external {
        require(amt != 0, "amount can't be 0");
        uint sendable = amt > ledger[msg.sender] ? ledger[msg.sender] : amt;
        payable (address(this)).transfer(sendable);
    }
}