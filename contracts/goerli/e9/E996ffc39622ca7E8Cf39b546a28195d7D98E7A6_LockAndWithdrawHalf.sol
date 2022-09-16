/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LockAndWithdrawHalf{

    address payable public owner;
    uint public unlockTime;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = payable(msg.sender);
        unlockTime = _unlockTime;
    }

    function withdrawHalf() public {
        require(block.timestamp >= unlockTime, "Unlock time is still in the future, cannot withdraw just yet");
        require(msg.sender == owner, "Only owner of the contract can withdraw ETH");

        emit Withdrawal(address(this).balance / 2, block.timestamp);
        owner.transfer(address(this).balance / 2);
    }
}