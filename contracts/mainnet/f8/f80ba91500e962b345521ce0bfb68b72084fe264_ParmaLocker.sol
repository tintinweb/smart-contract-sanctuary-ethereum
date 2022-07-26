// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

/*
    Parma Locker v1
    - Expect to release a more detailed version with our upcoming UI.
*/

contract ParmaLocker {
    using SafeMath for uint256;

    // dead address for burning
    address burnAddr = 0x000000000000000000000000000000000000dEaD;

    // store the lock
    struct Lock {
        address owner;
        uint256 amount;
        uint256 unlockDate;
        IERC20 token;
    }

    /**
     * @dev Store specific to address
    */
    mapping(address => Lock[]) public locks;

    /**
     * @dev Simple lock owner check
    */
    modifier isOwner(uint256 id) {
        require(locks[msg.sender][id].owner == msg.sender, "You are not the owner of this lock");
        _;
    }

    function _deleteLock(Lock[] storage lock, uint index) private {
        require(index < lock.length, "Index out of bounds");

        for (uint i = index; i < lock.length - 1; i++) {
            lock[i] = lock[i + 1];
        }

        lock.pop();
    }

    function lockTokens(uint256 amount, uint256 length, IERC20 token) external {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Funds in wallet");

        uint256 lengthDays = length.mul(1 days);
        uint256 date = block.timestamp.add(lengthDays);

        locks[msg.sender].push(Lock({
            owner: msg.sender,
            amount: amount,
            unlockDate: date,
            token: token
        }));

        token.transferFrom(msg.sender, address(this), amount);
    }

    function unlockTokens(uint256 id) external isOwner(id) {
        require(block.timestamp >= locks[msg.sender][id].unlockDate, "You cannot unlock your tokens yet");

        locks[msg.sender][id].token.transfer(msg.sender, locks[msg.sender][id].amount);

        _deleteLock(locks[msg.sender], id);
    }

    function extendLock(uint256 id, uint256 addedLength) external isOwner(id) {
        uint256 unlockDate = locks[msg.sender][id].unlockDate;

        uint256 newUnlockDate = unlockDate + addedLength.mul(1 days); 
        if (block.timestamp >= unlockDate) {
            newUnlockDate = block.timestamp + addedLength.mul(1 days);
        }

        require(newUnlockDate > unlockDate, "New date must be bigger then the current set unlock date");

        locks[msg.sender][id].unlockDate = newUnlockDate;
    }

    function transferLock(uint256 id, address newOwner) external isOwner(id) {
        require(newOwner != locks[msg.sender][id].owner, "This lock is already owned by this address");

        locks[msg.sender][id].owner = newOwner;
        locks[newOwner].push(locks[msg.sender][id]);

        _deleteLock(locks[msg.sender], id);
    }

    function burnLock(uint256 id) external isOwner(id) {        
        locks[msg.sender][id].token.transfer(burnAddr, locks[msg.sender][id].amount);

        _deleteLock(locks[msg.sender], id);
    }

    function partialBurnLock(uint256 id, uint256 amount) external isOwner(id) {        
        require(locks[msg.sender][id].amount > amount, "Lock does not have that many tokens in it!");

        locks[msg.sender][id].token.transfer(burnAddr, amount);

        locks[msg.sender][id].amount -= amount;
    }
}