// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// @author: mr unbekannt boys
contract Locken {
    uint256 public unlockTime;
    address payable public owner;
    uint256 public favoriteNumber = 8;

    event Withdrawal(uint amount, uint when);

    constructor() payable {
        unlockTime = block.timestamp + 1 days;
        owner = payable(msg.sender);
    }

    function changeFaveNumber(uint256 _newNumber) public {
        favoriteNumber = _newNumber;
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}