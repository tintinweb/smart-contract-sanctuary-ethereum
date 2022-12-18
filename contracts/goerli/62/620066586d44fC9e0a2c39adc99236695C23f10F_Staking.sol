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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {
    IERC20 private rewardsToken;
    IERC20 private stakingToken;

    uint256 private constant REWARD_RATE = 100;
    uint256 private lastUpdateTime;
    uint256 private rewardPerTokenStored;

    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    uint256 private totalSupply;
    mapping(address => uint256) private balances;

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    /**
     * @notice How much reward a token gets
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return rewardPerTokenStored;

        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) /
                totalSupply);
    }

    /**
     * @notice How much reward a user has earned
     */
    function earned(address account) public view returns (uint256) {
        return
            ((balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    /**
     * @notice Deposit tokens into this contract
     * @param amount to stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        totalSupply += amount;
        balances[msg.sender] += amount;

        emit Staked(msg.sender, amount);

        bool success = stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (!success) revert Staking__TransferFailed();
    }

    /**
     * @notice Withdraw tokens from this contract
     * @param amount to withdraw
     */
    function withdraw(uint256 amount) external updateReward(msg.sender) {
        totalSupply -= amount;
        balances[msg.sender] -= amount;

        emit WithdrewStake(msg.sender, amount);

        bool success = stakingToken.transfer(msg.sender, amount);

        if (!success) revert Staking__TransferFailed();
    }

    /**
     * @notice User claims their tokens
     */
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        emit RewardsClaimed(msg.sender, reward);

        bool success = rewardsToken.transfer(msg.sender, reward);

        if (!success) revert Staking__TransferFailed();
    }

    function getStaked(address account) external view returns (uint256) {
        return balances[account];
    }

    function getStakingToken() external view returns (IERC20) {
        return stakingToken;
    }

    function getRewardsToken() external view returns (IERC20) {
        return rewardsToken;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert Staking__NeedsMoreThanZero();
        _;
    }
}