// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lock {
    uint256 public immutable i_unlockTime;
    address payable public immutable i_owner;

    event LockWithdrawn(uint256 amount, uint256 when);

    constructor(uint256 unlockTime) payable {
        require(unlockTime > block.timestamp, "Unlock time must be greater");
        i_unlockTime = unlockTime;
        i_owner = payable(msg.sender);
    }

    function withdraw() external {
        require(msg.sender == i_owner, "Wow, this is for owner!");
        require(block.timestamp >= i_unlockTime, "Wow, this is to yearly!");

        emit LockWithdrawn(address(this).balance, block.timestamp);
        (bool isSuccessed, ) = i_owner.call{value: address(this).balance}("");
        require(isSuccessed, "Call was non-successfull!");
    }
}