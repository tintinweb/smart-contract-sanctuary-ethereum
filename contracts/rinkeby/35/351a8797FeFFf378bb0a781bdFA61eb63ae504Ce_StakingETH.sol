// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingETH is ReentrancyGuard{

    IERC20 public devUSDC;

    uint256 private lastUpdateTime; // last time the contract was call
    uint256 private rewardPerTokenStored; // reward rate / total stake supply at each given time
    uint256 private _totalSupply; // total staken in this contract
    uint256 private constant REWARD_RATE = 100; //  0.00100% or 10% APR

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);


    //first we need to update the reward/token stored
    // second we update the last update tima
    //store on the rewards mapping the amount of token earned until now
    // then update user reward/token paid with the reward/token stored
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    mapping(address => uint256) public userRewardPerTokenPaid; // store the reward per token stored when users interact with the contract
    mapping(address => uint256) public rewards; // update the reward if user withdraw or staking more tokens
    mapping(address => uint256) private _balances; // n tokens staked per user

    constructor(address _devUSDC) {
        devUSDC = IERC20(_devUSDC);
    }

    /* External Functions */


    // first update the reward
    //second update the total supply of the contract
    // third update the balance of msg.sender
    // finally emit staked event
    function stakeETH()
        external
        payable
        nonReentrant
        updateReward (msg.sender)
    {
        require(msg.value >= 5 ether, "need at least 5ETH to stake");
        _totalSupply += msg.value;
        _balances[msg.sender] += msg.value;
        
        emit Staked(msg.sender, msg.value);
    }

    // first line requires a condition of the balance to be equal or more the _amount parameter
    //second update the total supply of the contract
    // third update the balance of msg.sender
    // finally emit staked event
    function withdrawETH(uint256 _amount)
        external
        nonReentrant
        updateReward (msg.sender)
    {
        require(_balances[msg.sender] >= _amount, "insuficient amount");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "error");

        emit WithdrewStake(msg.sender, _amount);
    }

    // first line requires a condition of the msg.sender rewards balance to be greater than zero
    //second we put the value of rewards of the msg.sender in a stable variable 
    // third we reset msg.sender rewards
    // finally emit staked event
    function claimdevUSDC()
        external
        nonReentrant
        updateReward (msg.sender)
    {
        require(rewards[msg.sender] > 0, "no rewards to claim");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        devUSDC.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    /* Getter Functions */

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdateTime;
    }

    function getRewardPerTokenStored() public view returns (uint256) {
        return rewardPerTokenStored;
    }

    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getRewardRate() public pure returns (uint256) {
        return REWARD_RATE;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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