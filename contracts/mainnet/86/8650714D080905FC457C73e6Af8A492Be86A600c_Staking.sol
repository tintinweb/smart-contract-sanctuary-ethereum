// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Staking is Ownable {
    // maximum upper limit of the cooldown period
    uint256 public constant COOLDOWN_UPPER_LIMIT = 365 days;

    // token used for staking
    IERC20Upgradeable public immutable token;

    // amounts staked, address to value staked mapping
    mapping(address => uint256) public staked;

    // timestamps timers until which the penalty is applied, 0 means it is cleared
    mapping(address => uint256) public timers;

    // amounts set for the cooldown period
    mapping(address => uint256) public amounts;

    // snapshotted penalties, address to penalty mapping
    mapping(address => uint16) public penalties;

    // cooldown period
    uint256 public cooldown = 14 days;

    // penalty for unstaking, divided by 100 to get the total percentages
    uint16 public penalty = 1000;

    // wallet to which the tokens go for penalties
    address public treasury;

    error CooldownOverflow();
    error NotEnoughBalance();
    error NotEnoughStakedBalance();
    error PenaltyOverflow();
    error UnstakingDifferentAmount();
    error ZeroAmount();
    error ZeroAddress();

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event CooldownChanged(uint256 newCooldown);
    event PenaltyChanged(uint16 newPenalty);
    event SetCooldownTimer(address indexed account, uint256 amount);
    event TreasuryChanged(address newTreasury);

    /**
     * @param token_ staking token address
     * @param treasury_ address for the treasury wallet
     */
    constructor(IERC20Upgradeable token_, address treasury_) {
        if (address(token_) == address(0) || address(treasury_) == address(0)) {
            revert ZeroAddress();
        }
        token = token_;
        treasury = treasury_;
    }

    /**
     * @notice Allows any wallet to stake available tokens.
     *         The penalty for unstaking is updated to the current global one when a wallet stakes more tokens.
     * @param amount amount of tokens to stake
     */
    function stake(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (amount > token.balanceOf(msg.sender)) {
            revert NotEnoughBalance();
        }
        staked[msg.sender] += amount;
        penalties[msg.sender] = penalty;
        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Allows any wallet to unstake staked tokens.
     *         There is a penalty for unstaking the tokens during or without the cooldown period.
     *         The cooldown period is set via setCooldownTimer(amount) method.
     * @param amount amount of tokens to unstake
     */
    function unstake(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (amount > staked[msg.sender]) {
            revert NotEnoughStakedBalance();
        }
        if (amount != amounts[msg.sender] && amounts[msg.sender] != 0) {
            revert UnstakingDifferentAmount();
        }
        uint256 penaltyAmount = calculatePenalty(amount);
        staked[msg.sender] -= amount;
        setCooldownTimer(0);
        if (penaltyAmount > 0) {
            require(token.transfer(treasury, penaltyAmount), "penalty transfer failed");
        }
        if (amount != penaltyAmount) {
            require(token.transfer(msg.sender, amount - penaltyAmount), "transfer failed");
        }
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice Sets the cooldown timer for passed amount.
     * @param amount amount of set for the cooldown period
     */
    function setCooldownTimer(uint256 amount) public {
        if (amount > staked[msg.sender]) {
            revert NotEnoughStakedBalance();
        }
        timers[msg.sender] = amount == 0 ? 0 : block.timestamp + cooldown;
        amounts[msg.sender] = amount;
        penalties[msg.sender] = amount == 0 ? 0 : penalty;
        emit SetCooldownTimer(msg.sender, amount);
    }

    /**
     * @notice Allows the owner to set the cooldown period (maximum of 365 days).
     * @param newCooldown new cooldown period
     */
    function setCooldown(uint256 newCooldown) external onlyOwner {
        if (newCooldown > COOLDOWN_UPPER_LIMIT) {
            revert CooldownOverflow();
        }
        cooldown = newCooldown;
        emit CooldownChanged(newCooldown);
    }

    /**
     * @notice Allows the owner to set the penalty (maximum of 10000 = 100%).
     * @param newPenalty new penalty
     */
    function setPenalty(uint16 newPenalty) external onlyOwner {
        if (newPenalty > 10000) {
            revert PenaltyOverflow();
        }
        penalty = newPenalty;
        emit PenaltyChanged(newPenalty);
    }

    /**
     * @notice Allows the owner to set the treasury address.
     * @param newTreasury new treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            revert ZeroAddress();
        }
        treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    /**
     * @notice Calculates a penalty based on the given sender and amount.
     *         Can be used to return the penalty amount without actually unstaking.
     * @param amount amount on which the penalty is calculated
     * @return amount amount of penalty
     */
    function calculatePenalty(uint256 amount) public view returns (uint256) {
        if (amounts[msg.sender] == 0) {
            return (amount * penalty / 100) / 100;
        } else if (timers[msg.sender] > block.timestamp) {
            return (amount * penalties[msg.sender] / 100) / 100;
        } else {
            return 0;
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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