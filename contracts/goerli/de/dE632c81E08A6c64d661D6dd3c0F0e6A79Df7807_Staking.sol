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

// ------------Core Functions-------------
// stake: users lock tokens into our smart contracts
// withdraw: users can unlock tokens and pull out of the contract
// claimReward: users get their reward tokens
//      What's a good reward mechanism ?
//      What's some good reward Math?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {
    IERC20 private s_stakingToken;
    IERC20 private s_rewardToken;

    // address => how much they stake
    mapping(address => uint256) private s_balances;
    // how much each address have been paid already
    mapping(address => uint256) private s_userRewardPerTokenPaid;
    // how much reward each address has to claim
    mapping(address => uint256) private s_rewards;

    uint256 private constant REWARD_RATE = 1000000000000000;
    // how many tokens have been sent to the contract
    uint256 private s_totalSupply;
    uint256 private s_rewardPerTokenStaked;
    uint256 private s_lastUpdateTime;

    // MODIFIERS
    modifier updateReward(address account) {
        // How much reward per token?
        // last timestamp?
        // 4-5, user earned X tokens

        s_rewardPerTokenStaked = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStaked;

        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }

        _;
    }

    // keeping track of staking token right away when it is deployed
    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        // How much they have been paid already
        uint256 rewardPerTokenPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 _earned = ((currentBalance *
            (currentRewardPerToken - rewardPerTokenPaid)) / 1e18) + pastRewards;

        return _earned;
    }

    // reward / token based on how long it's been during this most recent snapshot
    function rewardPerToken() public view returns (uint256) {
        // Nothing staked in this contract
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStaked;
        }

        return
            s_rewardPerTokenStaked +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    // do we allow any tokens?❌ =>
    //      can be done using Chainlink to convert between prices of tokens
    // or just a specific tokens?✅
    function stake(
        uint256 amount
    ) public moreThanZero(amount) updateReward(msg.sender) {
        // keep track how much user has staked
        s_balances[msg.sender] += amount;
        // keep track how much token we have in total
        s_totalSupply += amount;
        // transfer the tokens to this contract
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert Staking__TransferFailed();
        }

        // emit event
        // emit TokenStaked
    }

    function withdraw(
        uint256 amount
    ) public moreThanZero(amount) updateReward(msg.sender) {
        // keep track how much user has staked
        s_balances[msg.sender] -= amount;
        // keep track how much token we have in total
        s_totalSupply -= amount;
        // transfer the tokens to the user
        bool success = s_stakingToken.transfer(msg.sender, amount);

        if (!success) {
            revert Staking__TransferFailed();
        }

        // emit event
    }

    function claimReward() public updateReward(msg.sender) {
        // How much reward the users get?
        // The contract is going to emit X tokens per second
        // And disperse them to all token stakers
        //
        // 100 reward tokens / second
        //      1 token / staked token => in 1 second 100 reward tokens
        // staked: 50 staked tokens, 20 staked tokens, 30 staked tokens
        // rewards: 50 reward tokens, 20 reward tokens, 30 reward tokens
        //
        // 5 seconds, 1 person had 100 tokens staked = reward = 500 tokens
        //      0.5 tokens / staked token => in 1 second 100 reward tokens
        //      for Person 1: cumulative rewadTokens / second => 100 + 100 + 100 + 100 + 100 + 50 => 550 reward tokens / second
        // 6 seconds, 2 person have 100 tokens staked each:
        //      Person 1: 550 reward tokens
        //      Person 2: 50 reward tokens
        //
        // Have a data structure that says:
        //      between seconds 1-5: Person 1 => 100 reward tokens per second || 500 reward tokens
        //      from secon 6: Person 1 => 50 reward tokens per second || 50 reward tokens
        uint256 reward = s_rewards[msg.sender];

        // reward token is different from staking token
        bool success = s_rewardToken.transfer(msg.sender, reward);

        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function getTotalStakedTokens() external view returns (uint256) {
        return s_totalSupply;
    }

    function getStakedAmount(
        address userAddress
    ) external view returns (uint256) {
        return s_balances[userAddress];
    }

    function getReward(address userAddress) external view returns (uint256) {
        return s_rewards[userAddress];
    }

    function getRewardRate() external pure returns (uint256) {
        return REWARD_RATE;
    }
}