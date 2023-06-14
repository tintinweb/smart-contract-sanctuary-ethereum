// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract ETHPool is Ownable2Step {

    error DirectTransferNotAllowed();
    error FailedToSendEther();
    error NoOneToReward();
    error NothingToWithdraw();
    error ZeroEtherDeposit();

    event RewardDeposit(address indexed teamMember, uint256 amount);
    event UserDeposit(address indexed user, uint256 currentDepositAmount, uint256 totalDeposited);
    event UserWithdrawal(address indexed user, uint256 returnedDeposit, uint256 rewardAmount);

    // Most important elements of deposits: the full amount a user has, and what reward period it
    // corresponds to. User can deposit N times before team deposits rewards; only final balance matters
    struct UserBalance {
        uint256 cumulativeBalance;
        uint256 rewardPeriodIndex;
    }

    // Most important elements of rewards: the amount, and the total deposits at that time in order
    // to calculate the percentage owed to each person in the pool.
    struct TeamReward {
        uint256 rewardAmount;
        uint256 totalUserDeposits;
    }

    // Track deposits: by user and total amount
    uint256 public _totalDepositBalance;
    mapping(address => UserBalance[]) _balancesByRewardIndex;

    // Track each reward distribution
    TeamReward[] public _rewards;

    /**
     * @dev Allows a user to deposit ETH into the pool.
     * @notice Users can deposit ETH to participate in the pool and earn rewards.
     * @dev Users must send a non-zero value transaction for the deposit to be accepted.
     */
    function deposit() external payable {

        // Refuse 0-value transactions
        if (!(msg.value > 0)) {
            revert ZeroEtherDeposit();
        }
        // Build a UserBalance struct to store for later. Copy most recent value if it exists.
        UserBalance memory newUserBalance;
        uint256 length = _balancesByRewardIndex[msg.sender].length;
        if (length > 0) {
            newUserBalance = _balancesByRewardIndex[msg.sender][length - 1];
        }

        // Add current value to both user balance and total deposits
        newUserBalance.cumulativeBalance += msg.value;
        _totalDepositBalance += msg.value;

        // Cache reward index to save on storage read. Any deposits made now will be eligible
        // for the *next* rewards distribution; therefore, use length of rewards array.
        uint256 rewardIndex = _rewards.length;

        // Add deposit entry to the user's array
        //      - add new element if it's a new reward index or first deposit
        //      - update last element if no new rewards have been deposited since last user deposit
        if (newUserBalance.rewardPeriodIndex != rewardIndex || length == 0) {
            newUserBalance.rewardPeriodIndex = rewardIndex;
            _balancesByRewardIndex[msg.sender].push(newUserBalance);
        } else {
            _balancesByRewardIndex[msg.sender][length - 1] = newUserBalance;
        }

        // Log the new deposit
        emit UserDeposit(msg.sender, msg.value, newUserBalance.cumulativeBalance);
    }

    /**
     * @dev Allows a user to withdraw their deposits along with their share of rewards across each eligible reward period.
     * @return The total amount withdrawn by the user, including the deposits and rewards.
     * @dev All user balances are cleared after the payout calculation to prevent double withdrawals.
     */
    function withdraw() external returns (uint256) {

        UserBalance[] memory userBalances = _balancesByRewardIndex[msg.sender];
        if (userBalances.length == 0) {
            revert NothingToWithdraw();
        }

        // Start out with payout being all the deposits
        uint256 payout = userBalances[userBalances.length - 1].cumulativeBalance;

        // Decrease the total deposit balance
        _totalDepositBalance -= payout;

        // Add all calculated rewards to payout
        TeamReward memory currReward;
        for (uint256 i = 0; i < userBalances.length; i++) {
            // Directly accessing each reward period for which a user has pending rewards avoids doing
            // a storage read on all rewards periods, as we would have done if we cached it to local memory
            currReward = _rewards[userBalances[i].rewardPeriodIndex];

            // Default Solidity math rounds down, so calculating each payout like this favors the pool.
            // Multiplication followed by division; decimal scaling from these operations cancels out.
            // Div by zero should not be possible since totalUserDeposits >= a single user's cumulative balance
            payout += currReward.rewardAmount * userBalances[i].cumulativeBalance / currReward.totalUserDeposits;
        }

        // Clear balances for user now that we've determined their payout.
        // Iterate through all elements of array, then delete the mapping. Free up previous storage space.
        UserBalance[] storage arrayToDelete = _balancesByRewardIndex[msg.sender];
        for (uint256 i = 0; i < arrayToDelete.length; i++) {
            delete arrayToDelete[i];
        }
        delete _balancesByRewardIndex[msg.sender];

        // Send native asset with `call`
        (bool sent,) = payable(msg.sender).call{value: payout}("");
        if (!sent) {
            revert FailedToSendEther();
        }
        return payout;
    }

    /**
     * @notice Allows team to deposit rewards into the pool.
     * @dev Reward amount and total balance in pool must be non-zero.
     */
    function depositRewards() external payable onlyOwner {
        if (msg.value == 0) {
            revert ZeroEtherDeposit();
        }
        // Prevent Eth getting stuck, potential div by zero
        if (_totalDepositBalance == 0) {
            revert NoOneToReward();
        }

        TeamReward memory newReward = TeamReward({rewardAmount:msg.value, totalUserDeposits:_totalDepositBalance});
        _rewards.push(newReward);
        emit RewardDeposit(msg.sender, msg.value);
    }

    function getUserBalances(address user) public view returns (UserBalance[] memory) {
        return _balancesByRewardIndex[user];
    }

    receive() external payable {
        revert DirectTransferNotAllowed();
    }
    
    fallback() external payable {
        revert DirectTransferNotAllowed();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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