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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface ISabreSwapOffer {

    event NewBuyOffer(address indexed buyer, address token, uint256 amount, uint256 pricePerToken, uint256 _buyOfferCount);
    event CancelBuyOffer(uint256 buyOfferPosition);
    event BuyOfferFulfilled(address indexed seller, uint256 offerPosition, uint256 price);

    event NewSellOffer(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 pricePerToken,
        uint256 _sellOfferCount
    );
    event CancelSellOffer(uint256 offerPosition);
    event SellOfferFulfilled(address indexed buyer, uint256 offerPosition, uint256 price);

    error WrongAmount();
    error WrongPrice();
    error WrongValue();
    error NotOfferOwnerNorFound();
    error OfferNotFound();
    error FailedToFulfillOffer();
    error WrongAllowance();
    error WrongBalance();
    error OfferWrongValue();
    error FailedToCancelOffer();

    struct BuyOffer {
        address token;
        address buyer;
        uint256 amount;
        uint256 ethPricePerToken;
    }

    struct SellOffer {
        address token;
        address seller;
        uint256 amount;
        uint256 ethPricePerToken;
    }
}

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './SabreSwapSellOffer.sol';
import './SabreSwapBuyOffer.sol';

/** @title SabreSwap */
contract SabreSwap is Ownable, SabreSwapSellOffer, SabreSwapBuyOffer {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event SetTransferFee(uint256 transferFee);

    error TokenAlreadyAdded();
    error TokenNotYetAdded();
    error TokenAddressIsZero();
    error WrongTransferFee();
    error FailedToRetrieveFees();

    uint256 public transferFee;
    uint256 public balanceFees;

    EnumerableSet.AddressSet private _tokens;

    /** @param _transferFee must be between 1 and 10000 which represents 100% */
    constructor(uint256 _transferFee) {
        setTransferFee(_transferFee);
    }

    /** @notice sets a Sell Offer, should have allowance and balance in order call the function
     *  @param token address of whitelisted token
     *  @param amount amount of erc20 token to sell
     *  @param pricePerToken price in ETH for each token
     */
    function setSellOffer(
        address token,
        uint256 amount,
        uint256 pricePerToken
    ) external {
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _setSellOffer(token, amount, pricePerToken);
    }

    /** @notice fulfills a Sell Offer, must be a payable function with the exact value
     * @param sellOfferPosition position of the Sell Offer stored in _sellOfferByPosition
     */
    function fulfillSellOffer(uint256 sellOfferPosition) external payable {
        uint256 takenFee = _fulfillSellOffer(sellOfferPosition, transferFee);
        balanceFees += takenFee;
    }

    /** @notice sets Buy Offer, must be a payable function with the exact value
     *  @param token address of whitelisted token
     *  @param amount amount of erc20 token to sell
     *  @param pricePerToken price in ETH for each token
     */
    function setBuyOffer(
        address token,
        uint256 amount,
        uint256 pricePerToken
    ) external payable {
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _setBuyOffer(token, amount, pricePerToken);
    }

    /** @notice fulfills a Buy Offer, must have ERC20 token approval set
     *  @param buyOfferPosition position of the Buy Offer stored in _buyOfferByPosition
     */
    function fulfillBuyOffer(uint256 buyOfferPosition) external {
        uint256 takenFee = _fulfillBuyOffer(buyOfferPosition, transferFee);
        balanceFees += takenFee;
    }

    /** @notice Sets new transfer fee
     * @param _transferFee must be between 1 and 10000 which represents 100% 
     */
    function setTransferFee(uint256 _transferFee) public onlyOwner {
        if (_transferFee == 0 || _transferFee > 10000) revert WrongTransferFee();
        transferFee = _transferFee;
        emit SetTransferFee(_transferFee);
    }

    function withdrawFees(address receiver) external onlyOwner nonReentrant {
        (bool sent, ) = receiver.call{value: balanceFees}('');
        balanceFees = 0;
        if (!sent) revert FailedToRetrieveFees();
    }

    function addToken(address token) external onlyOwner {
        if (token == address(0)) revert TokenAddressIsZero();
        if (_tokens.contains(token)) revert TokenAlreadyAdded();
        _tokens.add(token);
        emit TokenAdded(token);
    }

    function removeToken(address token) external onlyOwner {
        if (token == address(0)) revert TokenAddressIsZero();
        if (!_tokens.contains(token)) revert TokenNotYetAdded();
        _tokens.remove(token);
        emit TokenRemoved(token);
    }

    function getTokens() external view returns (address[] memory) {
        return _tokens.values();
    }

    function isTokenAdded(address token) external view returns (bool) {
        return _tokens.contains(token);
    }
}

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/ISabreSwapOffer.sol';

contract SabreSwapBuyOffer is ISabreSwapOffer, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint256) public buyerBalance;

    uint256 _buyOfferCount;

    EnumerableSet.UintSet private _activeBuyOffers;

    mapping(uint256 => BuyOffer) private _buyOfferByPosition;
    mapping(uint256 => BuyOffer) private _fulfilledBuyOfferByPosition;

    mapping(address => EnumerableSet.UintSet) private _buyOffersByBuyer;

    mapping(address => uint256[]) private _fulfilledBuyOffersByBuyer;
    mapping(address => uint256[]) private _fulfilledBuyOffersBySeller;

    uint256[] private _fulfilledBuyOffers;


    function _setBuyOffer(address token, uint256 amount, uint256 pricePerToken) internal {
        if (amount == 0) revert WrongAmount();
        if (pricePerToken == 0) revert WrongPrice();

        ERC20 _token = ERC20(token);
        uint256 total = (amount * pricePerToken)/10**_token.decimals();

        if(total != msg.value) revert WrongValue();

        BuyOffer memory buy = BuyOffer(token, msg.sender, amount, pricePerToken);
        _buyOfferCount += 1;
        _activeBuyOffers.add(_buyOfferCount);
        _buyOfferByPosition[_buyOfferCount] = buy;
        _buyOffersByBuyer[msg.sender].add(_buyOfferCount);

        buyerBalance[msg.sender] += total;

        emit NewBuyOffer(msg.sender, token, amount, pricePerToken, _buyOfferCount);
    }

    function _fulfillBuyOffer(uint256 buyOfferPosition, uint256 transferFee) internal nonReentrant returns(uint256 takenFee) {
        BuyOffer memory buy = _buyOfferByPosition[buyOfferPosition];
        if(buy.buyer == address(0)) revert OfferNotFound();

        ERC20 token = ERC20(buy.token);
        uint256 total = (buy.amount * buy.ethPricePerToken)/10**token.decimals();

        buyerBalance[buy.buyer] -= total;

        takenFee = total*transferFee/(10000);
        
        token.transferFrom(msg.sender, buy.buyer, buy.amount);
        (bool sent, ) = msg.sender.call{value: total - takenFee}('');
        if (!sent) revert FailedToFulfillOffer();

        _activeBuyOffers.remove(buyOfferPosition);
        delete _buyOfferByPosition[buyOfferPosition];
        _buyOffersByBuyer[buy.buyer].remove(buyOfferPosition);
        _fulfilledBuyOffers.push(buyOfferPosition);
        _fulfilledBuyOffersByBuyer[buy.buyer].push(buyOfferPosition);
        _fulfilledBuyOffersBySeller[msg.sender].push(buyOfferPosition);
        _fulfilledBuyOfferByPosition[buyOfferPosition] = buy;

        emit BuyOfferFulfilled(msg.sender, buyOfferPosition, total - takenFee);
    }

    function cancelBuyOffer(uint256 buyOfferPosition) external nonReentrant {
        if(!_buyOffersByBuyer[msg.sender].contains(buyOfferPosition)) revert NotOfferOwnerNorFound();

        BuyOffer memory buy = _buyOfferByPosition[buyOfferPosition];
        ERC20 token = ERC20(buy.token);
        uint256 total = (buy.amount * buy.ethPricePerToken)/10**token.decimals();

        buyerBalance[msg.sender] -= total;
        (bool sent, ) = msg.sender.call{value: total}('');
        if (!sent) revert FailedToCancelOffer();

        _activeBuyOffers.remove(buyOfferPosition);
        delete _buyOfferByPosition[buyOfferPosition];
        _buyOffersByBuyer[msg.sender].remove(buyOfferPosition);

        emit CancelBuyOffer(buyOfferPosition);
    }

    function getBuyOffers(bool fulfilled) external view returns(uint256[] memory) {
        if(!fulfilled) return _activeBuyOffers.values();
        else return _fulfilledBuyOffers;
    }

    function getBuyOfferByBuyer(address buyer, bool fulfilled) external view returns(uint256[] memory) {
        if(!fulfilled) return _buyOffersByBuyer[buyer].values();
        else return _fulfilledBuyOffersByBuyer[buyer];
    }

    function getFulfilledBuyOffersBySeller(address seller) external view returns(uint256[] memory) {
        return _fulfilledBuyOffersBySeller[seller];
    }

    function getActiveBuyOffer(uint256 buyOfferPosition) external view returns(BuyOffer memory) {
        return _buyOfferByPosition[buyOfferPosition];
    }

    function getFullfilledBuyOffer(uint256 buyOfferPosition) external view returns(BuyOffer memory) {
        return _fulfilledBuyOfferByPosition[buyOfferPosition];
    }
}

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './interfaces/ISabreSwapOffer.sol';

contract SabreSwapSellOffer is ISabreSwapOffer, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 private _sellOfferCount;

    EnumerableSet.UintSet private _activeSellOffers;

    mapping(uint256 => SellOffer) private _sellOfferByPosition;
    mapping(uint256 => SellOffer) private _fulfilledSellOfferByPosition;

    mapping(address => EnumerableSet.UintSet) private _sellOffersBySeller;

    uint256[] private _fulfilledSellOffers;

    mapping(address => uint256[]) private _fulfilledSellOffersBySeller;
    mapping(address => uint256[]) private _fulfilledSellOffersByBuyer;

    function _setSellOffer(
        address token,
        uint256 amount,
        uint256 ethPricePerToken
    ) internal {
        if (amount == 0) revert WrongAmount();
        if (ethPricePerToken == 0) revert WrongPrice();

        IERC20 t = IERC20(token);
        if (t.allowance(msg.sender, address(this)) < amount) revert WrongAllowance();
        if (t.balanceOf(msg.sender) < amount) revert WrongBalance();

        _sellOfferCount += 1;

        SellOffer memory sell = SellOffer(token, msg.sender, amount, ethPricePerToken);
        _sellOfferByPosition[_sellOfferCount] = sell;

        _activeSellOffers.add(_sellOfferCount);
        _sellOffersBySeller[msg.sender].add(_sellOfferCount);

        emit NewSellOffer(msg.sender, token, amount, ethPricePerToken, _sellOfferCount);
    }

    function _fulfillSellOffer(uint256 sellOfferPosition, uint256 transferFee) internal nonReentrant returns(uint256 takenFee) {
        SellOffer memory sell = _sellOfferByPosition[sellOfferPosition];
        if (sell.seller == address(0)) revert OfferNotFound();

        ERC20 token = ERC20(sell.token);

        uint256 total = (sell.amount * sell.ethPricePerToken)/10**token.decimals();
        if (total != msg.value) revert OfferWrongValue();

        takenFee = total*transferFee/(10000);

        _removeSellOffer(sellOfferPosition, sell.seller);

        _fulfilledSellOffers.push(sellOfferPosition);
        _fulfilledSellOffersBySeller[sell.seller].push(sellOfferPosition);
        _fulfilledSellOffersByBuyer[msg.sender].push(sellOfferPosition);
        _fulfilledSellOfferByPosition[sellOfferPosition] = sell;

        token.transferFrom(sell.seller, msg.sender, sell.amount);
        (bool sent, ) = sell.seller.call{value: total - takenFee}('');
        if (!sent) revert FailedToFulfillOffer();

        emit SellOfferFulfilled(msg.sender, sellOfferPosition, total - takenFee);
    }

    function cancelSellOffer(uint256 sellOfferPosition) external {
        if (!_sellOffersBySeller[msg.sender].contains(sellOfferPosition)) revert NotOfferOwnerNorFound();

        _removeSellOffer(sellOfferPosition, msg.sender);

        emit CancelSellOffer(sellOfferPosition);
    }

    function _removeSellOffer(uint256 sellOfferPosition, address seller) private {
        _activeSellOffers.remove(sellOfferPosition);
        delete _sellOfferByPosition[sellOfferPosition];
        _sellOffersBySeller[seller].remove(sellOfferPosition);
    }

    function getSellOffers(bool fulfilled) external view returns (uint256[] memory) {
        if (!fulfilled) return _activeSellOffers.values();
        else return _fulfilledSellOffers;
    }

    function getSellOfferBySeller(address seller, bool fulfilled) external view returns (uint256[] memory) {
        if (!fulfilled) return _sellOffersBySeller[seller].values();
        else return _fulfilledSellOffersBySeller[seller];
    }

    function getFulfilledSellOffersByBuyer(address buyer) external view returns (uint256[] memory) {
        return _fulfilledSellOffersByBuyer[buyer];
    }

    function getActiveSellOffer(uint256 sellOfferPosition) external view returns (SellOffer memory) {
        return _sellOfferByPosition[sellOfferPosition];
    }

    function getFullfilledSellOffer(uint256 sellOfferPosition) external view returns (SellOffer memory) {
        return _fulfilledSellOfferByPosition[sellOfferPosition];
    }
}