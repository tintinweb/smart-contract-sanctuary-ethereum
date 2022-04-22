/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT

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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20Custom {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenVesting is Ownable, ReentrancyGuard {
    IERC20Custom public tokenContract;
    address public stakingContract;
    
    uint256 public lockedPeriod;
    uint256 public totalLocked;
    
    mapping(address => uint256) private _userBalances;
    mapping(address => uint256[2][]) private _userLocks;

    modifier onlyStakingContract() {
        require(stakingContract == _msgSender(), "TokenVesting: caller is not allowed");
        _;
    }


    // constructor
    constructor(address token, address staking, uint256 period) {
        require(token != address(0) && staking != address(0), "TokenVesting: not valid address");
        _setLockPeriod(period);
        tokenContract = IERC20Custom(token);
        stakingContract = staking;
    }


    // ownable public functions
    function setTokenContract(address tokenContract_) public onlyOwner {
        require(tokenContract_ != address(0), "TokenVesting: null address for Token contract");
        tokenContract = IERC20Custom(tokenContract_);
    }

    function setStakingContract(address stakingContract_) public onlyOwner {
        require(stakingContract_ != address(0), "TokenVesting: null address for Token contract");
        stakingContract = stakingContract_;
    }

    function setLockPeriod(uint256 period) public onlyOwner {
        _setLockPeriod(period);
    }

    function addVestingData(address user, uint256 amount) public onlyOwner {
        _addVestingData(user, amount);
    }

    function batchAddVestingData(address[] calldata users, uint256[] calldata amounts) public onlyOwner {
        require(users.length == amounts.length,"TokenVesting: wrong length");

        for (uint256 i = 0; i < amounts.length; i++) {
            _addVestingData(users[i], amounts[i]);
        }
    }


    // restricted public functions
    function addLock(address user, uint256 amount) public onlyStakingContract {
        _addVestingData(user, amount);
    }
    
    
    // public functions
    function getLockedBalance(address user) public view returns (uint256 balance) {
        return _userBalances[user];
    }
    
    function getLocksCount(address user) public view returns (uint256 count) {
        return _userLocks[user].length;
    }
    
    function getLockByIndex(address user, uint256 index) public view returns (uint256, uint256) {
        require(index < _userLocks[user].length, "TokenVesting: index out of range");
        uint256 amount = _userLocks[user][index][0];
        uint256 releaseTime = _userLocks[user][index][1];
        return (amount, releaseTime);
    }
    
    function release() public nonReentrant {
        require(_userBalances[_msgSender()] > 0, "TokenVesting: empty balance");
        uint256 count;
        
        for (uint256 i = 0; i < _userLocks[_msgSender()].length; i++) {
            if (block.timestamp >= _userLocks[_msgSender()][i][1]) {
                uint256 amount = _userLocks[_msgSender()][i][0];
                require(tokenContract.balanceOf(address(this)) >= amount, "TokenVesting: insufficient tokens");
                _userBalances[_msgSender()] = _userBalances[_msgSender()] - amount;
                totalLocked = totalLocked - amount;
                tokenContract.transfer(_msgSender(), amount);
                count++;            
            }
        }

        while (count != 0) {
            _userLocks[_msgSender()].pop();
            count--;
        } 
    }

    function getUnlockedBalance(address user) public view returns (uint256) {
        uint256 balance = 0;
        if (_userBalances[user] == 0) {
            return balance;
        }
        
        for (uint256 i = 0; i < _userLocks[user].length; i++) {
            if (block.timestamp >= _userLocks[user][i][1]) {
                balance = balance + _userLocks[user][i][0];          
            }
        }
        return balance;
    }

    // private functions
    function _setLockPeriod(uint256 period) private {
        require(period > lockedPeriod, "TokenVesting: not valid locked period");
        lockedPeriod = period;
    }

    function _addVestingData(address user, uint256 amount) private {
        uint256 releaseTime = block.timestamp + lockedPeriod;
        uint256 len = _userLocks[user].length + 1;
        uint256[2][] memory newLocks = new uint256[2][](len);
        newLocks[0][0] = amount;
        newLocks[0][1] = releaseTime;

        for (uint256 i = 0; i < _userLocks[user].length; i++) {
            newLocks[i + 1] = _userLocks[user][i];
        }
        _userLocks[user] = newLocks;
        _userBalances[user] = _userBalances[user] + amount;
        totalLocked = totalLocked + amount;       
    }
}