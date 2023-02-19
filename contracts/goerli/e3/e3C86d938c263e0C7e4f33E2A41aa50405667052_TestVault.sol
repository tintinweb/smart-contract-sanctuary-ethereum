// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TestVault {
    event Deposit(address sender, uint amount, uint when);
    event Withdrawal(uint amount, uint when);

    address payable public owner;

    constructor(address _owner) {
        owner = payable(_owner);
    }

    function deposit() payable public {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() public {
        require(msg.sender == owner, "Not Owner");
        owner.transfer(address(this).balance);
        emit Withdrawal(address(this).balance, block.timestamp);
    }
}