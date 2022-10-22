//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

// Contract developed by 0Kage (https://github.com/0kage-eth/Staking-Rewards)

/**
 * @notice Staking Rewards contract - for logic and details, refer to https://www.youtube.com/watch?v=32n3Vu0BK4g
 * @notice this contract allows users to stake 0Kage and win r0Kage - rewards 0Kage whose emission rate is pre-decided
 * @dev multiple people can stake into this contract, contract will issue r0Kage proportional to each individual's contribution
 */

contract StakingRewards is Ownable, ReentrancyGuard {
    //************ Variables **************/
    IERC20 private immutable i_0Kage;
    IERC20 private immutable i_rKage;

    uint256 private s_totalRewards; // total reward allocated for distribution
    uint256 private s_duration; // duration is calculated in seconds
    uint256 private s_lastUpdate; // last timestamp when staking rewards were calculated

    mapping(address => uint256) private s_rewards; // rewards for a given user
    mapping(address => uint256) private s_balance; // staked balances per user
    mapping(address => uint256) private s_rewardsPaidPerUser; // rewards paid per user

    uint256 private s_totalSupply; // total supply of staked tokens
    uint256 private s_rewardsPerToken; // total rewards per token

    /**
     * ************ FORMULAS **********
     * rewardsPerToken (r) += rewardPerSecond * (current time - prev time) / totalSupply
     * rewards[user] += balance[user]*(r-rewardsPaidPerUser[user])
     * rewardsPaidPerUser[user]= rewardsPerToken
     * totalSupply += stakedAmount (-= unStakedAmount)
     * balance[user] += stakedAmount (-= unStakedAmount)
     * prevTime = currentTime
     */

    //*************** Modifiers ************/

    //*************** Events ***************/
    event Stake(address staker, uint256 amount);
    event Unstake(address staker, uint256 amount);
    event RewardDistributed(address staker, uint256 reward);

    //*************** Constructor **********/

    /**
     * @param zeroKage zero Kage token address
     * @param rKage reward Kage token address
     * @param duration total duration in seconds for which rewards will be paid
     * @param totalReward total reward amount to be paid over duration
     */
    constructor(
        address zeroKage,
        address rKage,
        uint256 duration,
        uint256 totalReward
    ) {
        // initializing 0Kage and rKage Interfaces
        i_0Kage = IERC20(zeroKage);
        i_rKage = IERC20(rKage);
        s_duration = duration;
        s_totalRewards = totalReward;
        s_lastUpdate = block.timestamp;
    }

    //*************** MUTATIVE FUNCTIONS **********/

    /**
     * @notice function that helps users stake 0Kage & keeps track of rKage rewards
     * @param stakeAmount amount of 0Kage tokens that will be staked into the contract
     * @dev every time there is a stake, user balances and rewards are recalculated
     */
    function stake(uint256 stakeAmount) public payable {
        require(stakeAmount > 0, "Stake Amount must be >0");
        require(stakeAmount <= userStakedTokenBalance(), "Cannot stake more than your balance");

        // first calculate rewards from prev time to current time
        calculateStakes();

        // withdraw balance from staker
        bool success = i_0Kage.transferFrom(msg.sender, address(this), stakeAmount);
        require(success, "Failed to transfer tokens to staking contract");

        // next, update total supply and balance for user
        s_totalSupply += stakeAmount;
        s_balance[msg.sender] += stakeAmount;

        // at the end update time
        updateTime();

        // emit Stake event
        emit Stake(msg.sender, stakeAmount);
    }

    /**
     * @notice function manages unstaking of balance -> freezes rewards on amount unstaked
     * @param unStakeAmount amount of 0Kage that will be unstaked from contract
     */
    function unstake(uint256 unStakeAmount) public {
        require(unStakeAmount > 0, "Stake Amount withdrawal must be >0");
        require(
            unStakeAmount <= s_balance[msg.sender],
            "Amount to unstake exceeds your staked balance"
        );

        // first calculate rewards from prev time snapshot to current time snapshot
        // snapshot is taken at every significant event - either staking or unstaking is considered significant
        calculateStakes();

        // transfer balance back to staker
        bool success = i_0Kage.transfer(msg.sender, unStakeAmount);
        require(success, "Failed to seend tokens back to staker");

        // next, update total supply and balance for user
        // total supply reduces by total amount -> same applies for balance of current user
        s_totalSupply -= unStakeAmount;
        s_balance[msg.sender] -= unStakeAmount;

        // at the end update last timestamp (snapshot at previous significant event)
        updateTime();

        // emit Unstake event
        emit Unstake(msg.sender, unStakeAmount);
    }

    /**
     * @notice main function that calculates rewards for a given user
     * @notice gets executed every time user stakes or unstakes
     */
    function calculateStakes() private {
        // first update rewards per token
        // rewardsPerToken (r) += rewardPerSecond * (current time - prev time) / totalSupply
        updateRewardsPerToken();

        // then we update rewards from last time stamp to current
        // for the given user who staked
        // rewards[user] += balance[user]*(r-rewardsPaidPerUser[user])
        updateReward();

        // update rewards paid per user with rewards per token
        s_rewardsPaidPerUser[msg.sender] = s_rewardsPerToken;
    }

    // Helper function that internally updates reward for a staker
    function updateReward() private {
        s_rewards[msg.sender] +=
            (s_balance[msg.sender] * (s_rewardsPerToken - s_rewardsPaidPerUser[msg.sender])) /
            s_duration;
    }

    // Helper function that updates rewards per token -> kind of reward emission rate
    function updateRewardsPerToken() private {
        s_rewardsPerToken += s_totalSupply == 0
            ? 0
            : (s_totalRewards * (block.timestamp - s_lastUpdate)) / s_totalSupply;
    }

    // helper function that recents update time of last significant event
    function updateTime() private {
        s_lastUpdate = block.timestamp;
    }

    /**
     * @notice function distributes accrued rewards back to staker wallets
     * @notice protecting againt re-entrancy attacks
     */
    function distributeReward() public nonReentrant {
        uint256 userReward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        // console.log("staker reward sol", userReward);
        // console.log("rewards before transfer sol", i_rKage.balanceOf(address(this)));
        bool success = i_rKage.transfer(msg.sender, userReward);
        // console.log("rewards after transfer sol", i_rKage.balanceOf(address(this)));
        require(success, "Reward token transfer failed");

        // emit reward distributed event
        emit RewardDistributed(msg.sender, userReward);
    }

    // changes duration of staking
    function setDuration(uint256 duration) public onlyOwner {
        s_duration = duration;
    }

    //*************** GET (View) functions **********/

    /**
     * @notice get 0Kage balance in staker wallet
     */
    function userStakedTokenBalance() private view returns (uint256) {
        return i_0Kage.balanceOf(msg.sender);
    }

    /**
     * @notice get r0Kage balance in staker wallet (reward tokens already distributed)
     */
    function userRewardTokenBalance() private view returns (uint256) {
        return i_rKage.balanceOf(msg.sender);
    }

    /**
     * @notice get time of last significant update
     */
    function getLastUpdate() public view returns (uint256) {
        return s_lastUpdate;
    }

    /**
     * @notice get staking duration
     */
    function getDuration() public view returns (uint256) {
        return s_duration;
    }

    function getRewardAmount() public view returns (uint256) {
        return s_totalRewards;
    }

    /**
     * @notice get total reward accrued to user
     */
    function getStakerReward(address staker) public view returns (uint256) {
        return s_rewards[staker];
    }

    /**
     * @notice this function returns accrued rewards assuming user unstakes right now
     * @notice until a staker unstakes, user will not be able to redeem rewards
     * @notice this function calculates only accrued rewards that will become redeemable
     * @notice once user unstakes
     */
    function getStakerAccruedRewards() public view returns (uint256 accruedRewards) {
        uint256 rewardsPerToken = s_rewardsPerToken +
            (
                s_totalSupply == 0
                    ? 0
                    : (s_totalRewards * (block.timestamp - s_lastUpdate)) / s_totalSupply
            );

        accruedRewards =
            s_rewards[msg.sender] +
            (s_balance[msg.sender] * (rewardsPerToken - s_rewardsPaidPerUser[msg.sender])) /
            s_duration;
    }

    // get total amount staked by staker
    function getStakingBalance(address staker) public view returns (uint256) {
        return s_balance[staker];
    }

    // get total supply of staked tokens across all stakers
    function getTotalStakingSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    // get zKage address used by current contract
    function getZeroKageAddress() public view returns (address) {
        return address(i_0Kage);
    }

    // get r0Kage address used by current contract
    function getrKageAddress() public view returns (address) {
        return address(i_rKage);
    }

    // ******************* FALLBACK FUNCTIONS *********************//

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
     * by making the `nonReentrant` function external, and making it call a
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