/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: Test.sol


pragma solidity >=0.4.22 <0.9.0;


contract EthPool is Ownable{
    mapping(address => bool) public admins; // Team members is true. Team members can add reward to the staking pool.
    uint256 public constant week_duration = 3600 * 24 * 7;
    mapping(address => uint256) public unlockDeposits; // Individual's deposit balance. Attended to calculate reward
    mapping(address => uint256) public pendingDeposits; // Individual's deposit balance. Not attended to calculate reward
    uint256 public totalDeposit;
    uint256 public totalRewards;
    mapping(address => uint256) public lastRewardDate;
    mapping(address => uint256) public lastDepositDate;
    uint256 public lastAddRewardDate;

    modifier onlyAdmins {
        require (admins[msg.sender] == true, '');
        _;
    }

    /**
     * @notice Deposit into staking pool
     */
    function deposit() public payable {
        pendingDeposits[msg.sender] += msg.value;
        totalDeposit += msg.value;
        lastDepositDate[msg.sender] = block.timestamp;
    }

    /**
     * @notice Ask reward to the staking pool. This request is enable only once in one week.
     */
    function receiveRewards() public {
        require(totalRewards > 0, '');
        // The duration from the last reward date to the current time.
        uint256 diff = block.timestamp - lastRewardDate[msg.sender];
        // If this duration is less or equal to one week, receive reward is not enable.
        require(diff >= week_duration, '');
        
        // Check if pending deposit can be unlocked.
        _updatePendingDeposit(msg.sender);
        // Calculate reward 
        uint256 reward = _getReward(msg.sender);
        if (reward > 0) { // If reward is zero, there is not any state change.
            payable(msg.sender).transfer(reward);

            lastRewardDate[msg.sender] = block.timestamp;
            totalRewards -= reward;
        }
    }

    function _updatePendingDeposit(address staker) internal {
        // If the last deposit date is previous to the last add reward date, the pending deposit is unlocked.
        // The pending deposit can not be added to the deposit for reward sharing.
        if ( lastDepositDate[staker] < lastAddRewardDate ) {
            unlockDeposits[staker] += pendingDeposits[staker];
            // After updating total deposit balance and individual unlocked deposit, the pending deposit is reset as ZERO.
            pendingDeposits[staker] = 0;
        }
    } 

    function _getReward(address staker) internal view returns(uint256 rewards_){
        return totalRewards / totalDeposit * unlockDeposits[staker];
    }

    /**
     * @notice Withdraw all deposit from staking pool
     */
    function withdraw() public {
        uint256 diff = block.timestamp - lastRewardDate[msg.sender];
        uint256 reward = 0;
        if(diff > week_duration && totalRewards >= 0) {
            _updatePendingDeposit(msg.sender);
            reward = _getReward(msg.sender);
        }
        // If a client has already received a reward in less than one week, there is not any reward at withdraw.
        payable(msg.sender).transfer(unlockDeposits[msg.sender] + pendingDeposits[msg.sender] + reward);
        totalDeposit = totalDeposit - unlockDeposits[msg.sender] - pendingDeposits[msg.sender];
        unlockDeposits[msg.sender] = 0;
        pendingDeposits[msg.sender] = 0;
        totalRewards -= reward;
    }

    /**
     * @notice Add rewards once per week. Only team members can add reward.
     */
    function addRewards() public payable onlyAdmins {
        uint256 diff = block.timestamp - lastAddRewardDate;
        require(diff >= week_duration, '');
        totalRewards += msg.value;
        lastAddRewardDate = block.timestamp;
    }

    /**
     * @notice Add special reward by only Admin.
     */
    function forceAddRewards() public payable onlyOwner {
        totalRewards += msg.value;
        lastAddRewardDate = block.timestamp;
    }

    /**
     * @notice Add `new_admin` as a team member
     */
    function addAdmins(address new_admin) public onlyOwner {
        require(new_admin != address(0), '');
        admins[new_admin] = true;
    }
    
    /**
     * @notice Delete `admin_` from the team member
     */
    function removeAdmin(address admin_) public onlyOwner {
        require(admin_ != address(0), '');
        admins[admin_] = false;
    }
}