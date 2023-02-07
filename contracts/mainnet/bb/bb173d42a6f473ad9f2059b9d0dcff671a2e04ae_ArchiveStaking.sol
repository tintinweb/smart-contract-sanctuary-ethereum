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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ArchiveStaking is Ownable {
    struct Staking {
        uint256 lastReward;
        uint256 amount;
        uint256 rewarded;
        uint256 pendingReward;
        bool isUnstaked;
        bool isInitialized;
    }

    mapping(address => Staking) public stakers;

    uint256 public maxApr = 1000000;
    uint256 public minStaking = 1 * 10 ** 18;
    uint256 public totalStaked;
    uint256 public totalEth;

    uint256 public rewardPeriod = 300;
    uint256 private rewardPeriodsPerYear = 365 days / rewardPeriod;

    bool public stakingEnabled = true;
    bool public claimEnabled = true;

    IERC20 private token;

    event Stake(address indexed staker, uint256 amount, uint totalStaked);
    event Reward(address indexed staker, uint256 amount);
    event UnStake(address indexed staker, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
    * @notice Starts a new staking or adds tokens to the active staking.
    * @param amount Amount of Archive tokens to stake.
    */
    function stake(uint256 amount) external {
        require(stakingEnabled, "disabled");
        require(amount >= minStaking, "less than minimum");

        address staker = _msgSender();

        require(token.balanceOf(staker) >= amount, "insufficient token");
        require(token.allowance(staker, address(this)) >= amount, "not allowed");

        if (stakers[staker].isInitialized && !stakers[staker].isUnstaked) {
            stakers[staker].pendingReward = _getStakingReward(stakers[staker]);
            stakers[staker].amount += amount;
            stakers[staker].lastReward = block.timestamp;
        } else {
            stakers[staker] = Staking(block.timestamp, amount, 0, 0, false, true);
        }

        totalStaked += amount;
        token.transferFrom(staker, address(this), amount);

        emit Stake(staker, amount, stakers[staker].amount);
    }

    /**
    * @notice Claim rewards and withdraw the amount of tokens from staking.
    * @param amount Amount of tokens to unstake.
    */
    function unstake(uint256 amount) external {
        address staker = _msgSender();

        Staking storage staking = stakers[staker];
        require(amount <= staking.amount, "insufficient token");

        _claim(staker);

        if (staking.amount == amount) {
            staking.isUnstaked = true;
            staking.amount = 0;
        } else {
            staking.amount -= amount;
        }

        totalStaked -= amount;
        token.transfer(staker, amount);

        emit UnStake(staker, amount);
    }

    /**
    * @notice Claim rewards to staker account.
    */
    function claim() external {
        _claim(_msgSender());
    }

    /**
    * @notice Handle deposit of eth amount to smart contract account.
    */
    receive() external payable {
        if (msg.value > 0) {
            totalEth += msg.value;
        }
    }

    /**
    * @notice Handle deposit of eth amount to smart contract account.
    */
    fallback() external payable {
        if (msg.value > 0) {
            totalEth += msg.value;
        }
    }

    /**
    * @notice Withdraw ETH from smart contract account.
    * @param to Address to withdraw.
    * @param amount Amount of ETH to withdraw.
    */
    function withdrawEth(address to, uint256 amount) external onlyOwner {
        _withdrawEth(to, amount);
    }

    /**
    * @notice Set the rewards period in seconds for charge rewards.
    * @param _rewardPeriod Period each {_rewardPeriod} seconds charge rewards.
    */
    function setRewardPeriod(uint256 _rewardPeriod) external onlyOwner {
        require(_rewardPeriod > 0, "less than one");
        rewardPeriod = _rewardPeriod;
        rewardPeriodsPerYear = 365 days / _rewardPeriod;
    }

    /**
    * @notice Set the maximum of APR (Annual Percentage Rate).
    * @param _maxApr Maximum Annual Percentage Rate.
    */
    function setMaxApr(uint256 _maxApr) external onlyOwner {
        maxApr = _maxApr;
    }

    /**
    * @notice Turn on or off staking operation.
    * @param _stakingEnabled Flag to set true or false.
    */
    function setStakingEnabled(bool _stakingEnabled) external onlyOwner {
        stakingEnabled = _stakingEnabled;
    }

    /**
    * @notice Turn on or off claiming rewards operation.
    * @param _claimEnabled Flag to set true or false.
    */
    function setClaimEnabled(bool _claimEnabled) external onlyOwner {
        claimEnabled = _claimEnabled;
    }

    /**
    * @notice Get the rewards amount for the staker account.
    * @param staker Address of the staker account.
    */
    function getStakingReward(address staker) public view returns (uint256) {
        return _getStakingReward(stakers[staker]);
    }

    /**
    * @notice Returns APR for staker based on staked amount and total ETH on smart contract balance.
    */
    function getApr(address staker) public view returns (uint256) {
        return _getApr(stakers[staker]);
    }

    /**
    * @notice Withdraw ETH from smart contract account.
    * @param to Address to withdraw.
    * @param amount Amount of ETH to withdraw.
    */
    function _withdrawEth(address to, uint256 amount) private {
        require(totalEth >= amount, "insufficient eth");
        payable(to).transfer(amount);
        totalEth -= amount;
    }

    /**
    * @notice Rewards calculation and withdraw to staker account.
    * @param staker Staker account address.
    */
    function _claim(address staker) private {
        require(claimEnabled, "disabled");

        Staking storage staking = stakers[staker];
        uint256 reward = _getStakingReward(staking);

        staking.lastReward = block.timestamp;
        staking.rewarded += reward;
        staking.pendingReward = 0;

        _withdrawEth(staker, reward);

        emit Reward(staker, reward);
    }

    /**
    * @notice Rewards calculation for staking
    * @param staking Staking record
    */
    function _getStakingReward(Staking storage staking) private view returns (uint256) {
        require(staking.isInitialized && !staking.isUnstaked, "no staking");

        uint256 apr = _getApr(staking);
        uint256 rewardsTime = block.timestamp - staking.lastReward;

        uint256 periods = rewardsTime / rewardPeriod;
        uint256 reward = totalEth * apr * periods / 1000000 / rewardPeriodsPerYear;

        return staking.pendingReward + reward;
    }

    /**
    * @notice Returns APR for staker based on staked amount and total ETH on smart contract balance.
    */
    function _getApr(Staking storage staker) private view returns (uint256) {
        if (staker.amount == 0) {
            return 0;
        } else {
            uint256 apr = (staker.amount * 1000000) / totalStaked;
            if (apr > maxApr) {
                return maxApr;
            } else {
                return apr;
            }
        }
    }
}