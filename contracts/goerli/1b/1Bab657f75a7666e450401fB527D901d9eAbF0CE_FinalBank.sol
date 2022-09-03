// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FinalBank {

    struct StakeInfo {
        uint256 balance;
        uint256 unlockTime;
        uint256 rewardStartTime;
    }

    address stakingToken;
    address rewardsToken;
    uint256 minimumLockTime = 600;


    mapping(address => uint256) balances;
    mapping(address => StakeInfo) stakingBalances;


    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = _stakingToken;
        rewardsToken = _rewardsToken;
    }

    function deposit(uint256 _amount) external { 
        require(IERC20(stakingToken).balanceOf(msg.sender) >= _amount, "token not enough");
        IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "balance not enough");
        IERC20(stakingToken).transfer(msg.sender, _amount);
        balances[msg.sender] -= _amount;
    }

    function stake(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "balance not enough");
        StakeInfo storage stakeInfo = stakingBalances[msg.sender];
        stakeInfo.balance += _amount;
        stakeInfo.unlockTime = block.timestamp + minimumLockTime;
        stakeInfo.rewardStartTime = block.timestamp;
        balances[msg.sender] -= _amount;
    }

    function unstake(uint256 _amount) external {
        StakeInfo storage stakeInfo = stakingBalances[msg.sender];
        require(stakeInfo.unlockTime <= block.timestamp, "can not unstake");
        require(stakeInfo.balance >= _amount, "balance not enough");
        stakeInfo.balance -= _amount;
        balances[msg.sender] += _amount;
    }

    function claimReward() external {
        StakeInfo storage stakeInfo = stakingBalances[msg.sender];
        uint256 reward = (block.timestamp - stakeInfo.rewardStartTime) ** 2 * stakeInfo.balance / 10000;
        IERC20(rewardsToken).transfer(msg.sender, reward);
        stakeInfo.rewardStartTime = block.timestamp;
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