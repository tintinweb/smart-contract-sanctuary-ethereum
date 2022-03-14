/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

// TitanLocker contract

// Made by Lizard Man
//      https://t.me/lizardev
//      https://twitter.com/reallizardev

// Links:
// Website: https://titanlocker.xyz/
// Project: https://www.shibgeki.com/

interface IERC20Locker {

    function deposit(
        address token,
        uint256 amount,
        address recipient,
        uint256 unlockTimestamp
    ) external payable returns(bool);

    function withdraw(uint256 lockId) external returns(bool);

    function extendLock(uint256 lockId, uint256 additionalTime) external returns(bool);

}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract TitanLocker is IERC20Locker, Context {

//  DATA STRUCTURES
//  ____________________________________________________________________________________________________________________

    struct Lock {
        uint256 lockId;
        address token;
        uint256 amount;
        address recipient;
        uint256 unlockTimestamp;
        bool claimed;
    }

    Lock[] private _locks;

    mapping (address => uint256[]) private _ownerIndex;
    mapping (address => uint256[]) private _tokenIndex;

    modifier _requireLockExists(uint256 lockId) {
        require (lockId < _locks.length, "No such lock");
        _;
    }

    modifier _requireFee() {
        require (msg.value >= 0.05 ether, "Insufficient fee");
        _;
    }

//  Interface implementation
//  ____________________________________________________________________________________________________________________

    address private _feeReceiver = 0x8DF98F8B61D2F37DaCBF571eF261C31D808Ad055;

    function deposit(
        address token,
        uint256 amount,
        address recipient,
        uint256 unlockTimestamp
    ) _requireFee payable override external returns(bool) {

        IERC20 tokenContract = IERC20(token);

        uint256 ownedAmountBefore = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(_msgSender(), address(this), amount);
        uint256 ownedAmountAfter = tokenContract.balanceOf(address(this));
        uint256 transactedAmount = ownedAmountAfter - ownedAmountBefore;

        Lock memory lock = Lock(_locks.length, token, transactedAmount, recipient, unlockTimestamp, false);
        _locks.push(lock);

        uint256 index = _locks.length - 1;
        _ownerIndex[recipient].push(index);
        _tokenIndex[token].push(index);

        (bool success, ) = payable(_feeReceiver).call{value: msg.value}("");
        require (success, "Failed to deposit");

        return true;
    }

    function withdraw(uint256 lockId)
    _requireLockExists(lockId)
    override external returns(bool) {

        Lock storage lock = _locks[lockId];

        require (_msgSender() == lock.recipient, "Only lock recipient can withdraw");
        require (!lock.claimed, "Already withdrawn");
        require (lock.unlockTimestamp < block.timestamp, "Lock still active");

        lock.claimed = true;
        IERC20(lock.token).transfer(lock.recipient, lock.amount);

        return true;
    }

    function extendLock(uint256 lockId, uint256 additionalTime)
    _requireLockExists(lockId)
    override external returns(bool) {

        Lock storage lock = _locks[lockId];

        require (lock.recipient == _msgSender(), "Only lock owner can extend it");
        lock.unlockTimestamp += additionalTime;

        return true;
    }

//  Viewer functions
//  ____________________________________________________________________________________________________________________

    function getLockById(uint256 id)
    _requireLockExists(id)
    external view returns(Lock memory) {
        return _locks[id];
    }

    function getNumberOfLocks() external view returns(uint256) {
        return _locks.length;
    }

    // Returns all locks owned by the caller
    function getOwnedLocks() external view returns(Lock[] memory) {
        return _getLocksViaIndex(_ownerIndex[_msgSender()]);
    }

    // Returns all locks which contain the given token address
    function getTokenLocks(address token) external view returns(Lock[] memory) {
        return _getLocksViaIndex(_tokenIndex[token]);
    }

    function _getLocksViaIndex(uint256[] storage index) private view returns(Lock[] memory) {
        require (index.length > 0, "No locks found");

        Lock[] memory foundLocks = new Lock[](index.length);

        for (uint256 i = 0; i < index.length; i++) {
            foundLocks[i] = _locks[index[i]];
        }

        return foundLocks;
    }

}