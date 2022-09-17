/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LockAndWithdrawHalf {

    address payable public owner; 
    uint public unlockTimestamp;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTimestamp) payable {
        require(_unlockTimestamp > block.timestamp, "Unlock timestamp has to be in the future");
        owner = payable(msg.sender);
        unlockTimestamp = _unlockTimestamp;
    }

    function withdrawHalf() public {
        require(block.timestamp > unlockTimestamp, "Funds are not available to unlock, please come back in the future");
        require(owner == msg.sender, "Only owner can claim ETH from this contract");

        emit Withdrawal(address(this).balance / 2, block.timestamp);
        owner.transfer(address(this).balance / 2);
    }
}