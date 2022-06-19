/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
// File: ILocker.sol



pragma solidity ^0.8.0;

interface ILocker {
    function isLocked(address _user, uint256 volume) external view returns (bool);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: PrimezLocker.sol



pragma solidity ^0.8.0;



struct LockItem {
    address user;
    uint256 start;
    uint256 end;
    uint256 amount;
}

contract PrimezLocker is Ownable , ILocker{

    mapping(address => LockItem) private lockedItems;
    mapping(address => bool) private whitelist;
    address private ERC20;

    event Lock(address addr, uint256 start, uint256 end, uint256 amount);

    constructor(address _erc20){
        ERC20 = _erc20;
    }

    /**
    * duration: (uint256): seconds
    **/
    function lock(address _user, uint256 duration, uint256 amountLock) external onlyOwner {
        whitelist[_user] = true;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        LockItem memory lockItem = LockItem({
            user: _user,
            start: startTime,
            end: endTime,
            amount: amountLock
        });

        lockedItems[_user] = lockItem;
        emit Lock(_user, startTime, endTime, amountLock);
    }

    function isLocked(address _user, uint256 newBalance) external view override returns (bool){
        require((msg.sender == ERC20)||(msg.sender == owner()), "You are not allowed");
        
        if (!whitelist[_user])
            return false;

        uint256 lockAmount = getLockedAmount(_user);

        if(lockAmount == 0)
            return false;

        return newBalance < lockAmount;
    }

    function getLockedAmount(address _user) public view returns (uint256){
        if (!whitelist[_user])
            return 0;

        LockItem memory lockItem = lockedItems[_user];
        if(block.timestamp >= lockItem.end){
            return 0;
        }

        return lockItem.amount;
    }
}