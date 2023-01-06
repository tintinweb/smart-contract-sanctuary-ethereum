// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract AcuityAtomicSwapERC20 {

    /**
     * @dev Mapping of lockId to value stored in the lock.
     */
    mapping (bytes32 => uint) lockIdValue;

    /**
     * @dev Value has been locked to buy from a sell order.
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which creator can retrieve the value.
     * @param value Value being locked.
     * @param sellAssetId Asset the buyer is buying
     * @param sellPrice Unit price the buyer is paying for asset.
     */
    event LockBuy(ERC20 indexed token, address indexed creator, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 sellAssetId, uint sellPrice);

    /**
     * @dev Value has been locked in response to a buy lock.
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param hashedSecret Hash of the secret required to unlock the value.
     * @param timeout Time after which creator can retrieve the value.
     * @param value Value being locked.
     * @param buyAssetId Asset of the buy lock this lock is responding to.
     * @param buyLockId Buy lock this lock is responding to.
     */
    event LockSell(ERC20 indexed token, address indexed creator, address indexed recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 buyAssetId, bytes32 buyLockId);

    /**
     * @dev Lock has been declined by the recipient.
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Lock declined.
     */
    event Decline(ERC20 indexed token, address indexed creator, address indexed recipient, bytes32 lockId);

    /**
     * @dev Value has been unlocked by the recipient.
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param recipient Account that received the value.
     * @param lockId Lock unlocked.
     * @param secret The secret used to unlock the lock.
     */
    event Unlock(ERC20 indexed token, address indexed creator, address indexed recipient, bytes32 lockId, bytes32 secret);

    /**
     * @dev Value has been retrieved from a timed-out lock.
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param recipient Account to receive the value.
     * @param lockId Lock retrieved.
     */
    event Retrieve(ERC20 indexed token, address indexed creator, address indexed recipient, bytes32 lockId);

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
     * @dev Token transfer in has failed.
     * @param token Transfer token.
     * @param from Transfer source.
     * @param value Tramsfer value.
     */
    error TransferInFailed(ERC20 token, address from, uint value);

    /**
     * @dev Token transfer out has failed.
     * @param token Transfer token.
     * @param to Transfer recipient.
     * @param value Tramsfer value.
     */
    error TransferOutFailed(ERC20 token, address to, uint value);

    /**
     * @dev Lock value to buy from a sell order.
     * @param token Token to lock.
     * @param recipient Account that can unlock the lock.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will expire.
     * @param value Value of token to lock.
     * @param sellAssetId Asset the buyer is buying
     * @param sellPrice Unit price the buyer is paying for asset.
     */
    function lockBuy(ERC20 token, address recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 sellAssetId, uint sellPrice)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Lock value.
        lockIdValue[lockId] = value;
        // Transfer value.
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transferFrom.selector, msg.sender, address(this), value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferInFailed(token, msg.sender, value);
        // Log info.
        emit LockBuy(token, msg.sender, recipient, hashedSecret, timeout, value, sellAssetId, sellPrice);
    }

    /**
     * @dev Lock value to sell in response to a buy lock.
     * @param token Token to lock.
     * @param recipient Account that can unlock the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timestamp when the lock will expire.
     * @param value Value of token to lock.
     * @param buyAssetId Asset of the buy lock this lock is responding to.
     * @param buyLockId Buy lock this lock is responding to.
     */
    function lockSell(ERC20 token, address recipient, bytes32 hashedSecret, uint timeout, uint value, bytes32 buyAssetId, bytes32 buyLockId)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Ensure lockId is not already in use.
        if (lockIdValue[lockId] != 0) revert LockAlreadyExists(lockId);
        // Lock value.
        lockIdValue[lockId] = value;
        // Transfer value.
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transferFrom.selector, msg.sender, address(this), value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferInFailed(token, msg.sender, value);
        // Log info.
        emit LockSell(token, msg.sender, recipient, hashedSecret, timeout, value, buyAssetId, buyLockId);
    }

    /**
     * @dev Transfer value back to creator (called by recipient).
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param hashedSecret Hash of the secret.
     * @param timeout Timeout of the lock.
     */
    function decline(ERC20 token, address creator, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(token, creator, msg.sender, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transfer.selector, creator, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferOutFailed(token, creator, value);
        // Log info.
        emit Decline(token, creator, msg.sender, lockId);
    }

    /**
     * @dev Transfer value from lock to recipient (called by recipient).
     * @param token Token locked.
     * @param creator Account that locked the value.
     * @param secret Secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function unlock(ERC20 token, address creator, bytes32 secret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(token, creator, msg.sender, keccak256(abi.encode(secret)), timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has not timed out.
        if (block.timestamp >= timeout) revert LockTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transfer.selector, msg.sender, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferOutFailed(token, msg.sender, value);
        // Log info.
        emit Unlock(token, creator, msg.sender, lockId, secret);
    }

    /**
     * @dev Transfer value from expired lock back to creator (called by creator).
     * @param token Token locked.
     * @param recipient Recipient of the value.
     * @param hashedSecret Hash of secret to unlock the value.
     * @param timeout Timeout of the lock.
     */
    function retrieve(ERC20 token, address recipient, bytes32 hashedSecret, uint timeout)
        external
    {
        // Calculate intrinsic lockId.
        bytes32 lockId = keccak256(abi.encode(token, msg.sender, recipient, hashedSecret, timeout));
        // Get lock value.
        uint value = lockIdValue[lockId];
        // Check if the lock exists.
        if (value == 0) revert LockNotFound(lockId);
        // Check lock has timed out.
        if (block.timestamp < timeout) revert LockNotTimedOut(lockId);
        // Delete lock.
        delete lockIdValue[lockId];
        // Transfer value.
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(ERC20.transfer.selector, msg.sender, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferOutFailed(token, msg.sender, value);
        // Log info.
        emit Retrieve(token, msg.sender, recipient, lockId);
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