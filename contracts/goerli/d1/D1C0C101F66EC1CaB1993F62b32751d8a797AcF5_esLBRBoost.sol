// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "Ownable.sol";

contract esLBRBoost is Ownable {
    esLBRLockSetting[] public esLBRLockSettings;
    mapping(address => LockStatus) public userLockStatus;

    struct esLBRLockSetting {
        uint256 duration;
        uint256 miningBoost;
    }

    struct LockStatus {
        uint256 unlockTime;
        uint256 duration;
        uint256 miningBoost;
    }

    constructor(
    ) {
        esLBRLockSettings.push(esLBRLockSetting(30 days, 20 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(90 days, 30 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(180 days, 50 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(365 days, 100 * 1e18));
    }

    // Function to add a new lock setting
    function addLockSetting(esLBRLockSetting memory setting) external onlyOwner {
        esLBRLockSettings.push(setting);
    }

    // Function to set the user's lock status
    function setLockStatus(uint256 id) external {
        esLBRLockSetting memory _setting = esLBRLockSettings[id];
        LockStatus memory userStatus = userLockStatus[msg.sender];
        if(userStatus.unlockTime > block.timestamp) {
            require(userStatus.duration <= _setting.duration, "Your lock-in period has not ended, and the term can only be extended, not reduced.");
        }
        userLockStatus[msg.sender] = LockStatus(block.timestamp + _setting.duration, _setting.duration, _setting.miningBoost);
    }

    // Function to get the user's unlock time
    function getUnlockTime(address user) external view returns(uint256 unlockTime) {
        unlockTime = userLockStatus[user].unlockTime;
    }

    /**
     * @notice calculate the user's mining boost based on their lock status
     * @dev Based on the user's userUpdatedAt time, finishAt time, and the current time,
     * there are several scenarios that could occur, including no acceleration, full acceleration, and partial acceleration.
     */
    function getUserBoost(address user, uint256 userUpdatedAt, uint256 finishAt) external view returns(uint256) {
        uint256 boostEndTime = userLockStatus[user].unlockTime;
        uint256 maxBoost = userLockStatus[user].miningBoost;
        if(userUpdatedAt >= boostEndTime || userUpdatedAt >= finishAt) {
            return 0;
        }
        if (finishAt <= boostEndTime || block.timestamp <= boostEndTime) {
            return maxBoost;
        } else {
            uint256 time = block.timestamp > finishAt ? finishAt : block.timestamp;
            return
                ((boostEndTime - userUpdatedAt) *
                    maxBoost) /
                (time - userUpdatedAt);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}