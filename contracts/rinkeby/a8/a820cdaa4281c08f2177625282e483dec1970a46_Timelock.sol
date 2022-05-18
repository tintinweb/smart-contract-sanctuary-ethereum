/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title Timelock
/// @author Yaleni
/// Note: @dev can lock ETH
contract Timelock {
    struct Locked {
        uint256 amount;
        uint256 lockedTill;
    }

    /// Ex: User --> Deposit Id --> Locked
    mapping(address => mapping(uint256 => Locked)) public locked;
    mapping(address => uint256) public deposits;

    /// @dev allows user to lock funds
    /// @param timestamp represents the end time in unix
    function lock(uint256 timestamp) external payable {
        uint256 amount = msg.value;

        deposits[msg.sender] ++;
        uint256 depositId = deposits[msg.sender];

        locked[msg.sender][depositId] = Locked(amount, timestamp);
    }

    /// @dev allows user to claim their locked funds
    function claim(uint256 depositId) external {
        Locked memory _locked = locked[msg.sender][depositId];
        require(_locked.amount > 0, "Error: Invalid Deposit Id");
        require(block.timestamp > _locked.lockedTill, "Error: Unlock time not yet reached");

        uint256 amount = _locked.amount;
        locked[msg.sender][depositId] = Locked(0, 0);

        payable(msg.sender).transfer(amount);
    }
}