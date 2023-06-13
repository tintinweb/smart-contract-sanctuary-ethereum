// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./IRigoLocker.sol";

contract RigoLocker is Ownable, IRigoLocker {
    
    mapping(address => unitLock[]) public lockInfo;
    address[] addressKey;
    
    uint256 public lockIndex;
    uint256 public totalLockAmount;

    constructor() Ownable(msg.sender){
    }

    event RigoLock(
        address destination,
        uint256 unlockTime,
        uint256 amount,
        string description
    );
    event RigoUnlock(
        address destination,
        uint256 amount
    );

    error IncorrectedAmount(uint256 totalAmount, uint256 depositAmount);
    
    function rigoLock(address _destination, uint256 _unlockTime, string calldata _description) external payable {
        require(_unlockTime > block.timestamp, "UnlockTime must be in future");
        require(_destination != address(0) && _destination != address(this), "destination should be correct");
        require(msg.value > 0 , "Lock Amount must be bigger than 0");
    
        lockIndex++;

        if(lockInfo[_destination].length == 0) {
            addressKey.push(_destination);
        }

        lockInfo[_destination].push(unitLock(_destination, lockIndex, block.timestamp, _unlockTime, msg.value, false, _description));
        totalLockAmount += msg.value;
        
        emit RigoLock(_destination, _unlockTime, msg.value, _description);
    }

    function rigoMultiLock(multiLockStruct[] calldata _multiLockArr) external payable {
        uint256 totalAmount;
        for(uint256 i = 0; i < _multiLockArr.length; i++) {
            require(_multiLockArr[i].unlockTime > block.timestamp, string(abi.encodePacked(i + 1, "th UnlockTime must be in future")));
            require(_multiLockArr[i].destination != address(0) && _multiLockArr[i].destination != address(this), string(abi.encodePacked(i + 1, "th destination should be correct")));
            
            totalAmount += _multiLockArr[i].amount;
            lockIndex++;

            if(lockInfo[_multiLockArr[i].destination].length == 0) {
                addressKey.push(_multiLockArr[i].destination);
            }

            lockInfo[_multiLockArr[i].destination].push(unitLock(_multiLockArr[i].destination, lockIndex, block.timestamp, _multiLockArr[i].unlockTime, _multiLockArr[i].amount, false, _multiLockArr[i].description));
            totalLockAmount += _multiLockArr[i].amount;
            emit RigoLock(_multiLockArr[i].destination, _multiLockArr[i].unlockTime, _multiLockArr[i].amount, _multiLockArr[i].description);
        }

        if(totalAmount != msg.value) {
            revert IncorrectedAmount(totalAmount, msg.value);
        }
        
    }

    function unlockUnit(address payable _destination, uint256 _lockId) external {
        uint256 _lockIndex = getUnitLockIndex(_destination, _lockId);
        unitLock memory unitLockInfo = lockInfo[_destination][_lockIndex];
        require(_destination == msg.sender, "Only the address owner can unlock");
        require(unitLockInfo.lockId != 0, "Unit lock does not exist");
        require(!unitLockInfo.claimed, "Aleady unlock token");
        require(unitLockInfo.unlockTime <= block.timestamp, "The period has not expired yet.");
        
        _destination.transfer(unitLockInfo.amount);
        lockInfo[_destination][_lockIndex].claimed = true;
        totalLockAmount -= unitLockInfo.amount;

        emit RigoUnlock(_destination, unitLockInfo.amount);
    }

    function unlockAllByAddress(address payable _destination) external {
        require(_destination == msg.sender, "Only the address owner can unlock");
        for(uint256 i = 0; i < lockInfo[_destination].length; i++) {
            if(!lockInfo[_destination][i].claimed && lockInfo[_destination][i].unlockTime <= block.timestamp){
                _destination.transfer(lockInfo[_destination][i].amount);
                lockInfo[_destination][i].claimed = true;
                totalLockAmount -= lockInfo[_destination][i].amount;

                emit RigoUnlock(_destination, lockInfo[_destination][i].amount);
            }
        }

    }

    function getUnitLockInfo(address _destination, uint256 _lockId) external view returns (unitLock memory) {
        unitLock memory unitLockInfo;
        for(uint256 i = 0; i< lockInfo[_destination].length; i++) {
            if(lockInfo[_destination][i].lockId == _lockId) {
                unitLockInfo = lockInfo[_destination][i];
                break;
            }
        }
        return unitLockInfo;
    }
    
    function getUnitLockIndex(address _destination, uint256 _lockId) public view returns (uint256) {
        uint256 unitLockIndex;
        for(uint256 i = 0; i < lockInfo[_destination].length; i++) {
            if(lockInfo[_destination][i].lockId == _lockId) {
                unitLockIndex = i;
                break;
            }
        }
        return unitLockIndex;
    }    

    function getRigoAmount() external view returns (uint256) {
        return address(this).balance;
    }

    function getAllLockInfo() external view returns (unitLock[] memory) {
        uint256 totalLocks;
        for(uint256 i = 0; i < addressKey.length; i++) {
            totalLocks += lockInfo[addressKey[i]].length;
        }

        unitLock[] memory _lockInfo = new unitLock[](totalLocks);
        uint256 index = 0;
        for(uint256 i = 0; i < addressKey.length; i++) {
            for(uint256 j = 0; j < lockInfo[addressKey[i]].length; j ++) {
                _lockInfo[index] = lockInfo[addressKey[i]][j];
                index++;
            }
        }
        return _lockInfo;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IRigoLocker {

    struct unitLock {
        address destination;
        uint256 lockId;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 amount;
        bool claimed;
        string description;
    }

    struct multiLockStruct {
        address destination;
        uint256 unlockTime;
        uint256 amount;
        string description;
    }

    function rigoLock (address destination, uint256 unlockTime, string calldata description) external payable;

    function rigoMultiLock(multiLockStruct[] calldata multiLockArr) external payable;
    
    function unlockUnit(address payable destination, uint256 lockId) external;

    function unlockAllByAddress(address payable destination) external;

    function getUnitLockInfo(address destination, uint256 lockId) external view returns (unitLock memory);

    function getRigoAmount() external view returns (uint256);

    function getAllLockInfo() external view returns (unitLock[] memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import "./Context.sol";

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
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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