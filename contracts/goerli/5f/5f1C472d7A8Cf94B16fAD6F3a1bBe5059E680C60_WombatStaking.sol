// SPDX-License-Identifier: UNLICENSED
import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
pragma solidity 0.8.5;

/**
 * @dev Smart contract that allows staking a token. Staking means a user transfers an amount of a
 *  token to the smart contract. The smart contract keeps track of the stakes. Tokens can be
 *  unstaked and reclaimed after a cooldown period.
 *
 *  While the token is staked the user might get some benefit in applications. That benefit gets
 *  lost as soon as the tokens are unstaked.
 */
contract WombatStaking is Ownable {

    /**
     * @dev A struct to describe how much and when someone unstaked tokens
     */
    struct Unstake {
        /**
         * @dev The amount of tokens unstaked
         */
        uint256 amount;

        /**
         * @dev The timestamp at which the last unstake happened. 0 if no unstake exists.
         */
        uint256 unstakedAt;
    }

    /**
     * @dev Event that is emitted when someone stakes tokens
     */
    event TokensStaked(address indexed from, uint256 value);

    /**
     * @dev Event that is emitted when someone unstakes tokens
     */
    event TokensUnstaked(address indexed from, uint256 value);

    /**
     * @dev Event that is emitted when someone claims unstaked tokens
     */
    event TokensClaimed(address indexed from, uint256 value);

    /**
     * @dev Flag determining if staking is paused. When this is true, no one can stake anymore.
     */
    bool public stakingPaused;

    /**
     * @dev The token that can be staked.
     */
    IERC20 public immutable token;

    /**
     * @dev The time in seconds a user has to wait to reclaim their tokens after unstaking. Can be
     *  updated.
     */
    uint public unstakeTimeSeconds;

    /**
     * @dev Mapping of who staked how much
     */
    mapping(address => uint256) private _stakes;

    /**
     * @dev Mapping of who unstaked how much and when
     */
    mapping(address => Unstake) private _unstakes;

    /**
     * @param _token The address of the token that can be staked
     * @param _unstakeTimeSeconds The amount of seconds that has to be waited to claim tokens after
     *  unstaking
     * @param _newOwner An address that will be set as the owner of the smart contract.
     */
    constructor(address _token, uint _unstakeTimeSeconds, address _newOwner) Ownable() {
        require(_token != address(0), "Token address must not be 0");
        token = IERC20(_token);
        unstakeTimeSeconds = _unstakeTimeSeconds;
        stakingPaused = false;
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Owner function to update the unstake cooldown period
     * @param _seconds The new value to set
     */
    function setUnstakeTime(uint _seconds) external onlyOwner() {
        unstakeTimeSeconds = _seconds;
    }

    /**
     * @dev Owner function to pause staking. After this is called, no one can stake anymore unless
     *  resumeStaking is called.
     */
    function pauseStaking() external onlyOwner() {
        stakingPaused = true;
    }

    /**
     * @dev Owner function to resume staking after pauseStaking has been called.
     */
    function resumeStaking() external onlyOwner() {
        stakingPaused = false;
    }

    /**
     * @dev Stake an amount of tokens to the smart contract. Before this is called, the "approve"
     *  function of the token has to be called with at least the amount that should be staked.
     *  (Usually a user would be asked to approve a very high amount to this smart contract so it
     *  only has to be done once).
     *
     *  Staked tokens are locked in this smart contract. A release process can be initiated with
     *  unstake and then claim.
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Must stake more than 0");
        require(stakingPaused == false, "Staking is paused");
        token.transferFrom(msg.sender, address(this), amount);
        _stakes[msg.sender] += amount;
        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @dev Unstake an amount of tokens. This "moves" them internally so they don't appear as staked
     *  anymore. The unstaked tokens can be claimed after unstakeTimeSeconds has passed. Afterwards
     *  they can be claimed via the claim function.
     *
     *  Unstaking multiple times resets the unstakedAt timestamp.
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "Must unstake more than 0");
        uint256 currentStake = _stakes[msg.sender];
        require(currentStake >= amount, "Not enough staked");
        _stakes[msg.sender] -= amount;

        // "Transfer" the tokens from staked to the unstake.
        Unstake storage _unstake = _unstakes[msg.sender];
        _unstake.amount += amount;
        // Also reset the unstaked at timestamp to the block time
        _unstake.unstakedAt = block.timestamp;

        emit TokensUnstaked(msg.sender, amount);
    }

    /**
     * @dev Claim unstaked tokens. This transfers the tokens back to their original owner. Can only
     *  be called when the user has unstaked tokens and unstakeTimeSeconds has passed since they
     *  last unstaked.
     */
    function claim() external {
        Unstake storage _unstake = _unstakes[msg.sender];
        uint256 amount = _unstake.amount;
        require(amount > 0, "No tokens claimable found");
        require(
            block.timestamp - _unstake.unstakedAt >= unstakeTimeSeconds,
            "Unstake too early"
        );
        token.transfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);

        _unstake.amount = 0;
        _unstake.unstakedAt = 0;
    }

    /**
     * @dev Get the amount of tokens staked by a user.
     * @param _address The address to get the stake for.
     */
    function getStake(address _address) external view returns (uint256) {
        return _stakes[_address];
    }

    /**
     * @dev Get the unstake for a user
     * @param _address The address to get the unstake for.
     */
    function getUnstake(address _address) external view returns (Unstake memory) {
        return _unstakes[_address];
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