/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Timed Locker Contract
contract TimedLocker {

    struct AccountLockMetadata {
        uint amountLocked; 
        uint lockedUntil; 
    }
    event Deposited(address depositBy, address depositFor, uint amount, uint lockedUntil);
    event Withdrawn(address withdrawnBy, uint amount);

    mapping(address => AccountLockMetadata) accountLocks;
    
    // Returns lock info for the given address
    function getLockInfo(address lockAddress) external view returns (uint amountLocked, uint lockedUntil) {
        AccountLockMetadata storage accountLockInfo = accountLocks[lockAddress];
        amountLocked = accountLockInfo.amountLocked;
        lockedUntil = accountLockInfo.lockedUntil;
    }

    // deposit passed wei amount and lock it until given unix epoch time
    function deposit(uint lockedUntil, address lockedFor) external payable {
        require(msg.value > 0, "Nothing to deposit.");
        require(lockedFor != address(0), "LockedFor Address is not passed coreectly.");
        AccountLockMetadata storage accountLockInfo = accountLocks[lockedFor];
        accountLockInfo.amountLocked += msg.value;
        accountLockInfo.lockedUntil = lockedUntil;
        emit Deposited(msg.sender, lockedFor, msg.value, lockedUntil);
    }

    // withdraw given wei amount if the locking period has elapsed. If the amount is more than max available
    // then it returns the total remaining amount
    function withdraw(uint amountToWithdraw) external {
        require(amountToWithdraw > 0, "No amount specified to withdraw.");
        AccountLockMetadata storage accountLockInfo = accountLocks[msg.sender];
        require(accountLockInfo.lockedUntil <= block.timestamp, "You can't withdraw yet.");
        require(accountLockInfo.amountLocked > 0, "You don't have any balance to withdraw.");

        if(amountToWithdraw > accountLockInfo.amountLocked){
            amountToWithdraw = accountLockInfo.amountLocked;
        }
        
        (payable(msg.sender)).transfer(amountToWithdraw);
        accountLockInfo.amountLocked -= amountToWithdraw;

        emit Withdrawn(msg.sender, amountToWithdraw);
    }
}