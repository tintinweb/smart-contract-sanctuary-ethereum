/**
 *Submitted for verification at Etherscan.io on 2022-08-27
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

// File: ETHPool.sol




pragma solidity 0.8.16;

contract ETHPool is Ownable {
    mapping (address => UserDeposit[]) public usersDeposits;
    TeamDeposit[] public teamDeposits;
    uint256 public userDepositsBalance;
    uint256 public teamDepositsBalance;

    // struct for both deposits
    struct UserDeposit {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardsDepositsLength;
    }
    struct TeamDeposit {
        uint256 amount;
        uint256 timestamp;
        uint256 userDepositsBalance;
    }

    // Events
    event Deposited(uint256 amount, uint256 timestamp, address user);
    event Withdrawn(uint256 amount, uint256 timestamp, address user);
    event DepositedReward(uint256 amount, uint256 timestamp);

    // PUBLIC METHODS

    // Deposit method allow users to deposit ETH keeping track of who, how much and when he deposited in order to
    function deposit() public payable {
        require(msg.value > 0, "You cannot send empty value.");
        usersDeposits[msg.sender].push(
            UserDeposit(
                msg.value,
                block.timestamp,
                teamDeposits.length
            )
        );

        userDepositsBalance = userDepositsBalance + msg.value;

        emit Deposited(msg.value, block.timestamp, msg.sender);
    }

    function withdraw() public {
        uint256 balance = getUserBalance(msg.sender);
        uint256 rewards = getUserRewardsAmount(msg.sender);

        uint256 amount = balance + rewards; // balance + rewards
        payable(msg.sender).transfer(amount); // sending amount to user
        userDepositsBalance = userDepositsBalance - balance;
        teamDepositsBalance = teamDepositsBalance - rewards; // decreasing teamDepositsBalance

        delete usersDeposits[msg.sender]; // deleting userDeposits

        emit Withdrawn(amount, block.timestamp, msg.sender);
    }

    function getUserRewardsAmount(address user) public view returns (uint256) {
        uint256 rewards = 0;

        for (uint256 i = 0; i < usersDeposits[user].length; i++) {
            // starting from next rewardsDeposit respect when deposited
            for (uint256 t = usersDeposits[user][i].rewardsDepositsLength; t < teamDeposits.length; t++) {
                uint256 poolShareInBasisPoints = (usersDeposits[user][i].amount * 10000) / teamDeposits[t].userDepositsBalance;
                uint256 currentRewardsAmount = (teamDeposits[t].amount * poolShareInBasisPoints) / 10000;
                rewards = rewards + currentRewardsAmount;
            }
        }

        return rewards;
    }

    // GETTERS

    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address user) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < usersDeposits[user].length; i++) {
            balance = balance + usersDeposits[user][i].amount;
        }
        return balance;
    }

    // OWNER

    function depositRewards() public payable onlyOwner {
        teamDepositsBalance = teamDepositsBalance + msg.value; // incrementing teamDepositsBalance variable

        teamDeposits.push(
            TeamDeposit(
                msg.value,
                block.timestamp,
                userDepositsBalance
            )
        );

        emit DepositedReward(msg.value, block.timestamp);
    }
}