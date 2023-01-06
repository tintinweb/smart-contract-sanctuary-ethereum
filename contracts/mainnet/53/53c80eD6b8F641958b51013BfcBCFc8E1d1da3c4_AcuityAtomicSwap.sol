/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

contract AcuityAtomicSwap {

    /**
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint) lockIdValue;

    /**
     * @dev Value has been locked to buy from a sell order.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which creator can retrieve the value.
     * @param value Value being locked.
     * @param sellAssetId Asset the buyer is buying
     * @param sellPrice Unit price the buyer is paying for asset.
     */
    event LockBuy(address indexed creator, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 sellAssetId, uint sellPrice);

    /**
     * @dev Value has been locked in response to a buy lock.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which creator can retrieve the value.
     * @param value Value being locked.
     * @param buyAssetId Asset of the buy lock this lock is responding to.
     * @param buyLockId Buy lock this lock is responding to.
     */
    event LockSell(address indexed creator, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 buyAssetId, bytes32 buyLockId);

    /**
     * @dev Lock has been declined by the recipient.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Lock declined.
     */
    event Decline(address indexed creator, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has been unlocked by the recipient.
     * @param creator Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Lock unlocked.
     * @param secret The secret used to unlock the lock.
     */
    event Unlock(address indexed creator, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been retrieved from a timed-out lock.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Lock retrieved.
     */
    event Retrieve(address indexed creator, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has already been locked with this lockId.
     * @param lockId Lock already locked.
     */
    error LockAlreadyExists(bytes32 lockId);

    /**
     * @dev Value is not locked with this lockId.
     * @param lockId Lock that does not exist.
     */
    error LockNotFound(bytes32 lockId);

    /**
     * @dev Lock has timed out.
     * @param lockId Lock timed out.
     */
    error LockTimedOut(bytes32 lockId);

    /**
     * @dev Lock has not timed out.
     * @param lockId Lock not timed out.
     */
    error LockNotTimedOut(bytes32 lockId);

    /**
     * @dev Lock value to buy from a sell order.
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will expire.
     * @param sellAssetId Asset the buyer is buying
     * @param sellPrice Unit price the buyer is paying for asset.
     */
    function lockBuy(address recipient, bytes32 hashedSecret, uint timeout, bytes32 sellAssetId, uint sellPrice)
        external
        payable
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Lock value.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit LockBuy(msg.sender, recipient, hashedSecret, timeout, msg.value, sellAssetId, sellPrice);
    }

    /**
     * @dev Lock value to sell in response to a buy lock.
     * @param recipient Account that can unlock the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will expire.
     * @param buyAssetId Asset of the buy lock this lock is responding to.
     * @param buyLockId Buy lock this lock is responding to.
     */
    function lockSell(address recipient, bytes32 hashedSecret, uint timeout, bytes32 buyAssetId, bytes32 buyLockId)
        external
        payable
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Lock value.
        lockIdValue[lockId] = msg.value;
        // Log info.
        emit LockSell(msg.sender, recipient, hashedSecret, timeout, msg.value, buyAssetId, buyLockId);
    }

    /**
     * @dev Transfer value back to creator (called by recipient).
     * @param creator Account that locked the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timeout of the lock.
     */
    function decline(address creator, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(creator, msg.sender, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        payable(creator).transfer(value);
        // Log info.
        emit Decline(creator, msg.sender, lockId);
    }

    /**
     * @dev Transfer value from lock to recipient (called by recipient).
     * @param creator Account that locked the value.
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlock(address creator, bytes32 secret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(creator, msg.sender, keccak256(abi.encode(secret)), timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has not timed out.
        if (block.timestamp >= timeout) revert LockTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Unlock(creator, msg.sender, lockId, secret);
    }

    /**
     * @dev Transfer value from expired lock back to creator (called by creator).
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function retrieve(address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(msg.sender, recipient, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has timed out.
        if (block.timestamp < timeout) revert LockNotTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        payable(msg.sender).transfer(value);
        // Log info.
        emit Retrieve(msg.sender, recipient, lockId);
    }

    /**
     * @dev Get value locked.
     * @param lockId Lock to examine.
     * @return value Value held in the lock.
     */
    function getLockValue(bytes32 lockId)
        external
        view
        returns (uint value)
    {
        value = lockIdValue[lockId];
    }

}