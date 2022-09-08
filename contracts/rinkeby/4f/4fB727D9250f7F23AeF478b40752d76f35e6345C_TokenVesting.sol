// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";

/**
 * @title Token Vesting
 * @author Breakthrough Labs Inc.
 * @notice Utility, Finance
 * @custom:version 1.0.0
 * @custom:address 24
 * @custom:default-precision 0
 * @custom:simple-description The Token Vesting contract allows the owner to lock away tokens, and have them vest for a user over time.
 * @dev ERC20 vesting contract with the following features:
 *
 *  - Set a vesting start date to delay when vesting begins.
 *  - On creation, the owner can mark vestings as cancellable.
 *  - Only the contract owner can create new vestings.
 *
 */
contract TokenVesting is Ownable {
    struct Vest {
        uint256 amount;
        uint256 claimed;
        uint256 start;
        uint256 end;
        bool cancellable;
    }

    IERC20 public token;
    mapping(address => Vest) public vests;

    /**
     * @param tokenAddress The token to be vested
     */
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    /**
     * @dev Allows the owner to create new vestings.
     * @param to The user that will receive vested tokens
     * @param amount The total number of tokens that will vest | precision:18
     * @param start When the vesting begins, in months. 0 means they being vesting immediately.
     * @param end When the vesting ends, in months. 1 means that `amount` will vest over one month.
     * @param cancellable Whether or not the owner can cancel a vesting.
     */
    function createVest(
        address to,
        uint256 amount,
        uint256 start,
        uint256 end,
        bool cancellable
    ) external onlyOwner {
        Vest storage vest = vests[to];
        require(vest.amount == 0, "Account is already vested.");
        vest.amount = amount;
        vest.claimed = 0;
        vest.start = block.timestamp + 2629746 * start;
        vest.end = block.timestamp + 2629746 * end;
        vest.cancellable = cancellable;
        token.transferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @dev Allows the owner to cancel `cancellable` vestings.
     * @param account The user whose vesting will be cancelled
     */
    function cancelVest(address account) external onlyOwner {
        Vest storage vest = vests[account];
        require(vest.cancellable, "Cannot cancel."); // will also fail on nonexistent vests
        uint256 totalReleased = _totalReleased(vest);
        uint256 claimable = totalReleased - vest.claimed;
        uint256 locked = vest.amount - totalReleased;
        vest.amount = 0;
        // Avoid re-entrancy attacks by doing all the transfers last
        token.transfer(_msgSender(), locked);
        token.transfer(account, claimable);
    }

    /**
     * @dev Allows a user to claim their vested tokens.
     */
    function claim() external {
        address account = _msgSender();
        Vest storage vest = vests[account];
        uint256 totalReleased = _totalReleased(vest);
        uint256 amount = totalReleased - vest.claimed;
        require(amount > 0, "Nothing to claim.");
        vest.claimed = totalReleased;
        // Avoid re-entrancy attacks by doing the transfer last
        token.transfer(account, amount);
    }

    /**
     * @dev Allows anybody to check the total amount of their vesting.
     * @param account The user whose vesting is checked.
     */
    function getTotalVested(address account) external view returns (uint256) {
        Vest storage vest = vests[account];
        require(vest.amount != 0, "Account is not vested.");
        return vest.amount;
    }

    /**
     * @dev Allows anybody to check their total amount claimable.
     * @param account The user whose vesting is checked.
     */
    function getClaimable(address account) external view returns (uint256) {
        Vest storage vest = vests[account];
        return _totalReleased(vest) - vest.claimed;
    }

    /**
     * @dev Allows anybody to check their total amount that has not yet vested.
     * @param account The user whose vesting is checked.
     */
    function getLocked(address account) external view returns (uint256) {
        Vest storage vest = vests[account];
        return vest.amount - _totalReleased(vest);
    }

    function _totalReleased(Vest storage vest) private view returns (uint256) {
        require(vest.amount != 0, "Account is not vested.");
        if (block.timestamp <= vest.start) return 0;
        if (block.timestamp >= vest.end) return vest.amount;
        return
            (vest.amount * (block.timestamp - vest.start)) /
            (vest.end - vest.start);
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

import "Context.sol";

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