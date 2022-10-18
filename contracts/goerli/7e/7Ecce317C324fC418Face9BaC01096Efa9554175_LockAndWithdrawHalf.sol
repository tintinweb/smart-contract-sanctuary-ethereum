/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LockAndWithdrawHalf {
    address payable public owner;
    uint public unlockTime;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            _unlockTime > block.timestamp,
            "Unlock time has to be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdrawHalf() public {
        require(
            msg.sender == owner,
            "Only the smart contract owner can withdraw funds"
        );
        require(
            block.timestamp >= unlockTime,
            "Funds are not available yet, please wait longer"
        );

        emit Withdrawal(address(this).balance / 2, block.timestamp);
        
        owner.transfer(address(this).balance / 2);
    }
}