//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LpTokenFarming is Ownable {
    IERC20 immutable public lpToken;
    IERC20 immutable public rewardToken;

    /**
     * Amount of the blocks in one farming epoch. Suppose that one block is generated every 15 seconds
     */
    uint public farmingEpoch;
    /**
     * Amount of percent from user's stake wich they get for every farmingEpoch time 
     */
    uint public rewardPerFarmingEpoch;
    /**
     * The time in the blocks for wich staked tokens will be locked. Suppose that one block is generated every 15
     * seconds
     */
    uint public lockEpoch;

    struct Staking {
        uint stakingTokensAmount;
        uint lastGetRewardTime;
        uint stakingTime;
    }

    mapping (address => Staking) public stakers;

    constructor(address lpTokenAddress,
                address rewardTokenAddress,
                uint _farmingEpoch,
                uint _rewardPerFarmingEpoch,
                uint _lockEpoch) {
        require(lpTokenAddress != address(0x0), "LpTokenFarming: address of lpToken is equal to zero");
        require(rewardTokenAddress != address(0x0), "LpTokenFarming: address of rewardToken is equal to zero");
        lpToken = IERC20(lpTokenAddress);
        rewardToken = IERC20(rewardTokenAddress);

        farmingEpoch = _farmingEpoch;
        rewardPerFarmingEpoch = _rewardPerFarmingEpoch;
        lockEpoch = _lockEpoch;
    }

    /**
     * MODIFIERS
     */

    /**
     * @dev emitted from {stake} function
     */
    event Staked(address indexed user, uint amount);
    /**
     * @dev emitted from {claim} function
     */
    event Claimed(address indexed user, uint amount);
    /**
     * @dev emitted from {unstake} function
     */
    event Unstaked(address indexed user, uint amount);

    /**
     * FUNCTIONS
     */

    /**
     * @dev Allows to change epoch of farming. This function can call only Owner of contract.
     *
     * @param newFarmingEpoch new value for `farmingEpoch` 
     */
    function setFarmingEpoch(uint newFarmingEpoch) external onlyOwner {
        farmingEpoch = newFarmingEpoch;
    }

    /**
     * @dev Allows to change epoch of locking of stake. This function can call only Owner of contract.
     *
     * @param newLockEpoch new value for `lockEpoch` 
     */
    function setLockEpoch(uint newLockEpoch) external onlyOwner {
        lockEpoch = newLockEpoch;
    }

    /**
     * @dev Allows to change reward for stake per farming epoch. This function can call only Owner of contract.
     *
     * @param newRewardPerFarmingEpoch new value for `rewardPerFarmingEpoch` 
     */
    function setRewardPerFarmingEpoch(uint newRewardPerFarmingEpoch) external onlyOwner {
        rewardPerFarmingEpoch = newRewardPerFarmingEpoch;
    }

    /**
     * @dev Allows to stake `amount` of tokens. Before calling this function user must to call approve function from
     * `lpToken` address. This function resets `lastGetRewardTime` and `statingTime` of staker.
     *
     * @param amount amount of staking tokens
     *
     * emit {Staked} event
     */
    function stake(uint amount) external {
        require(amount > 0, "LpTokenFarming: amount must be greater than zero");
        require(lpToken.allowance(msg.sender, address(this)) >= amount,
                                                                "LpTokenFarming: caller didn't allow amount of tokens");
        require(lpToken.balanceOf(msg.sender) >= amount, "LpTokenFarming: caller doesn't have such amount of tokens");
        lpToken.transferFrom(msg.sender, address(this), amount);

        Staking storage staking = stakers[msg.sender];

        staking.stakingTokensAmount += amount;
        staking.lastGetRewardTime = block.number;
        staking.stakingTime = block.number;

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Allows to claim reward for farming of lpTokens. Function will throw an exception if contract doesn't have
     * enough liquidity for reward payment. If everything is okay, contract will transfer user's reward to the user.
     *
     * emit {Claimed} event
     */
    function claim() external {
        Staking storage staking = stakers[msg.sender];

        require(staking.stakingTokensAmount > 0, "LpTokenFarming: caller doesn't have staking");
        uint stakingTime = block.number - staking.lastGetRewardTime;
        require(stakingTime > farmingEpoch, "LpTokenFarming: caller can't claim reward yet");
        uint amountOfFarmingEpoch = stakingTime / farmingEpoch;

        uint claimPerEpoch = (rewardPerFarmingEpoch * staking.stakingTokensAmount) / 100;
        uint totalClaim = claimPerEpoch * amountOfFarmingEpoch;

        require(rewardToken.balanceOf(address(this)) >= totalClaim,
                                                            "LpTokenFarming: not enough liquidity for reward payment");

        staking.lastGetRewardTime = block.number;
        rewardToken.transfer(msg.sender, totalClaim);

        emit Claimed(msg.sender, totalClaim);
    }

    /**
     * @dev Allows to unstake all {lpToken} amount from the LpTokenFarming contract. Be careful, unstake function
     * doesn't call {claim} function! This means that you need to call {claim} before {unstake} yourself.
     *
     * emit {Unstaked} event
     */
    function unstake() external {
        Staking storage staking = stakers[msg.sender];

        require(staking.stakingTokensAmount > 0, "LpTokenFarming: caller doesn't have staking");
        require(block.number - staking.stakingTime > lockEpoch, "LpTokenFarming: caller can't unstake tokens yet");

        uint stakingTokensAmount = staking.stakingTokensAmount;
        delete stakers[msg.sender];
        lpToken.transfer(msg.sender, stakingTokensAmount);

        emit Unstaked(msg.sender, stakingTokensAmount);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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