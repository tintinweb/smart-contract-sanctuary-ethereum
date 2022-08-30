/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LockWithdrawHalf {
    uint public unlockTime;
    address payable owner;

    event Withdrawal(uint balance, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );
        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdrawHalf() public {
        require(block.timestamp > unlockTime, "You cannot withdraw your funds yet, unlock time is still in the future");
        require(msg.sender == owner, "Only contract owner can withdraw funds");

        owner.transfer(address(this).balance / 2);
        emit Withdrawal(address(this).balance / 2, block.timestamp);
    }
}