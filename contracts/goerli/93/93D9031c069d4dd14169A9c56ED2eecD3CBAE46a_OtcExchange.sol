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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

import "./OrderEscrow.sol";

/**
 * @dev Interface of the Escrow order
 *
 */
interface IOrderEscrow {
  
  event OrderEscrowBuyCreated(
    uint64 orderID,
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote
  );
  event OrderEscrowSellCreated(
    uint64 orderID,
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote
  );
  event OrderEscrowPartialFilled(
    uint64  orderID,
    uint256 amountLastBase,
    uint256 amountLastQuote
  );
  event OrderEscrowFulFilled(
    uint64 orderID,
    address tokenBase,
    address tokenQuote
  );

  event OrderEscrowCancelled(
    uint64 orderID,
    address tokenBase,
    address tokenQuote
  );

  event OrderEscrowUpdated(
    uint64 orderID,
    uint256 price
    );

  /**
   *   @dev create an Escrew Order
   *
   *   @param tokenBase : address of the main token in the pair
   *   @param tokenQuote : address of the token being exchanged for the main token
   *   @param amountBase : amount of base tokens
   *   @param amountQuote : amount of tokens exchanged for the main token
   *   @param orderType : type of the order (true: buy, false: sell)
   *   @param enableTwap : enable twap discount
   *   @param twapDiscount : twap discount in basis points
   *   @return success : true if the order has been successfully created
   *
   *   Emits a {OrderEscrowBuyCreated} event
   *   Emits a {OrderEscrowSellCreated} event
   */
  function createOrderEscrow(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType,
    bool enableTwap,
    uint16 twapDiscount
  ) external returns (bool success);

  /**
    *   @dev Take an escrow Order (only total order filling is allowed)
    *
    *   @param orderID : unique id of the order being canceled
    *   @param amountToken  : amount of tokens being either purchased or sold
    *                         if the order is a buy order amountToken is the token base 
    *                         else amountToken is the token quote
    *   @return success : true if the order has been successfully taken
    *   Emits a {OrderEscrowPartialFilled} event if the order has been partially filled
    *   Emits a {OrderEscrowFulFilled} event if the order has been fulfilled

    */
  function takeOrderEscrow(uint64 orderID, uint256 amountToken)
    external
    returns (bool success);


  /**
   *   @dev Update a selected fixed order
   *
   *   @param orderID : unique id of the order being created
   *   @param amountBase : amount of base tokens
   *   @param amountQuote : amount of quote tokens
   *   @param enableTwap : enable time weighted average price for the order
   *   @param twapDiscount : discount applied to the price when the TWAP is enabled
   *   @return success : true if the order has been successfully created
   *   Emits a {OrderFixedUpdated} event
   */
  function updateOrderEscrow(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote,
    bool enableTwap,
    uint16 twapDiscount
  ) external returns (bool success);

  /**
   *   @dev Return a selected escrow order
   *   @param orderID ID of the examined order
   */
  function getOrderEscrow(uint64 orderID)
    external
    view
    returns (OrderEscrow memory orderSelected);


  /**
    *   @dev Take a TWAP order from the TWAP Oracle
    *   @param orderID ID of the selected order
    *   @param amountToken : amount of base tokens if the order is a buy order
    *   else amount of quote tokens
    *   @return success : true if the order has been successfully created
    */
  function takeTWAPOfferEscrow(
    uint64 orderID,
    uint256 amountToken
  ) external returns (bool success);
  
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

import "./OrderFixed.sol";

interface IOrderFixed {


    event OrderFixedBuyCreated(
        uint64 orderID,
        address tokenBase,
        address tokenQuote,
        uint256 amountBase,
        uint256 amountQuote,
        uint128 expirationTime
    );
    event OrderFixedSellCreated(
        uint64 orderID,
        address tokenBase,
        address tokenQuote,
        uint256 amountBase,
        uint256 amountQuote
    );
    event OrderFixedFulFilled(
        uint64 orderID,
        address tokenBase,
        address tokenQuote
    );

    event OrderFixedCancelled(
        uint64 orderID,
        address tokenBase,
        address tokenQuote
    );

    event OrderFixedUpdated(
        uint64 orderID,
        uint256 price,
        uint128 expirationTime
    );

    /**
    *   @dev create an Escrew Order
    *
    *   @param tokenBase : address of the main token in the pair
    *   @param tokenQuote : address of the token being exchanged for the main token
    *   @param amountBase : amount of base tokens 
    *   @param amountQuote : amount of tokens exchanged for the main token
    *   @param orderType : type of the order (true: buy, false: sell)
    *   @param expirationTime : expiration timestamp of the order 
    *   @param enableTwap : enable twap discount
    *   @param twapDiscount : twap discount in basis points
    *
    *   Emits a {OrderEscrowBuyCreated} event
    *   Emits a {OrderEscrowSellCreated} event
    */
    function createOrderFixed(
        address tokenBase,
        address tokenQuote,
        uint256 amountBase,
        uint256 amountQuote,
        bool orderType,
        uint64 expirationTime,
        bool enableTwap,
        uint16 twapDiscount
    ) external returns (bool success);


    /**
    *   @dev Take an fixed Order (only total order filling is allowed)
    *
    *   @param orderID : unique id of the order being canceled
    *
    *   Emits a {OrderFixedFulFilled} event
    */
    function takeOrderFixed(
        uint64 orderID
    ) external returns (bool success);
    


    /**
    *   @dev Update a selected fixed order ct state or just a specific subset of the state?
Can you split storage and functionality?
    * 
    *   @param orderID : unique id of the order being created
    *   @param amountBase : amount of base tokens 
    *   @param amountQuote : amount of the quote token
    *   @param expirationTime : expiration time of the fixed order 
    *   @param enableTwap : enable twap discount
    *   @param twapDiscount : twap discount in basis points
    *   @return success : true if the order has been successfully created
    *   Emits a {OrderFixedUpdated} event
    */
    function updateOrderFixed(
        uint64 orderID, 
        uint256 amountBase, 
        uint256 amountQuote,
        uint64 expirationTime,
        bool enableTwap,
        uint16 twapDiscount
    ) external returns (bool success);


    /**
    *   @dev Return a selected fixed order
    *   @param orderID : ID of the examined order
    *   @return orderSelected : the order being selected
    */
    function getOrderFixed(
        uint64 orderID
    ) external view returns (OrderFixed memory orderSelected);




    /**
    *   @dev Take a TWAP order from the TWAP Oracle
    *   @param orderID : ID of the selected order 
    *   @return success : true if the order has been successfully created
    */
    function takeTWAPOfferFixed(
       uint64 orderID
    ) external returns (bool success);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import "./FullMath.sol";
import "./BitMath.sol";
import "./Babylonian.sol";


// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= type(uint112).max, 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (type(uint256).max - d + 1);
        d /= pow2;
        l /= pow2;
        l += h * ( (type(uint256).max - pow2 + 1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;


/**
 * @dev structure definining an Escrow order 
 * An escrow order requires the maker to send his funds to the contract.
 * It can be partially filled by one or more takers 
 * Attributes:
 * - enableTwap : enable time weighted average price for the order
 * - orderType: type of the order, true if it is either a buy order , otherwise false.
 * - twapDiscont: discount applied to the price when the TWAP is enabled
 * - orderID : unique ID of the order
 * - tokenBase : address of the main token in the pair 
 * - tokenQuote : address of the quate token in the pair 
 * - createdAt: timestamp of the order's creation date
 * - maker: address of the order maker 
 * - price: price of the base token, with 18 decimals
 * - amountBase : amount of the base token 
 * - amountQuote : amount of the quote token
 */
struct OrderEscrow{
    bool enableTwap; // 1 bit
    bool orderType; // 1 bit
    uint16 twapDiscount; // 16 bits
    uint64 orderID; // 64 bits
    address tokenBase; // 160 bits
    address tokenQuote; // 160 bits
    uint64 createdAt; // 64 bits
    address maker; // 160 bits
    uint256 price; // 256 bits
    uint256 amountBase; // 256 bits
    uint256 amountQuote; // 256 bits
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;



/**
 * @dev structure definining a Fixed order 
 * A fixed order DOES NOT requires the maker to send his funds to the contract.
 * It has an expiration time, after that the order will be marked as inactive.
 * It can only be fulfilled by one taker that must fill the whole amount. 
 * Attributes:
 * - enableTwap: enable time weighted average price for the order
 * - orderType: type of the order, true if it is either a buy order , otherwise false. 
 * - twapDiscount: discount applied to the price when the TWAP is enabled
 * - orderID : unique ID of the order
 * - tokenBase : address of the main token in the pair 
 * - createdAt: timestamp of the order's creation date
 * - tokenQuote : address of the quate token in the pair 
 * - expirationTime: expiration time of the order
 * - maker: address of the order maker
 * - price: price of the base token, with 18 decimals
 * - amountBase : amount of the base token 
 * - amountQuote : amount of the quote token
 */
struct OrderFixed {
    bool enableTwap; // 1 bit
    bool orderType; // 1 bit
    uint16 twapDiscount; // 16 bits
    uint64 orderID; // 64 bits
    address tokenBase; // 160 bits
    uint64 createdAt; // 64 bits
    address tokenQuote; // 160 bits
    uint64 expirationTime; // 64 bits
    address maker; // 160 bits
    uint256 price; // 256 bits
    uint256 amountBase; // 256 bits
    uint256 amountQuote; // 256 bits
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;
    

error BaseTokenNotAllowed();
error QuoteTokenNotAllowed();
error OrderIDDoesNotExists(
    uint64 orderID
    );
error InsufficientFunds(
    address tokenAddress, 
    uint256 tokenAmount
    );
error OrderNotActive(
    uint64 orderID, 
    bool orderClass
    );
error InvalidOwner(
    uint64 orderID, 
    bool orderClass
    );
error InvalidAmount(
    uint64 orderID, 
    bool orderClass
    );
/* error InsufficientFundsOnTakeOrderFixed(
    address tokenBase, 
    address tokenQuote, 
    uint256 senderBalance, 
    uint256 makerBalance, 
     bool orderType
    ); */
error InsufficientAllowance();
error InvalidTaker(
    uint64 orderID, 
    bool orderClass
    );
error InvalidTakeOrderTwap(
    uint64 orderID, 
    uint256 amountTwap,
    uint256 amountOrder 
    );
error InvalidDiscount(uint256 orderID, uint16 discount);
error FeesTooHigh(uint256 platformFees);
error OrderNotOwned(uint64 orderID);
error TradingDisabled();

// SPDX-License-Identifier: UNLIGENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IOrderEscrow.sol";
import "./IOrderFixed.sol";
import "./OtcErrors.sol";
import "./twap/TwapOracle.sol";

contract OtcExchange is IOrderEscrow, IOrderFixed, Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.UintSet;

  // uint
  uint256 public _platformFee;
  uint256 public _platformFeeDivider;
  uint64 private _totalTrades;
  uint64 private _totalOrders;
  uint64 public lastOrderID;

  // bool
  bool public tradingEnabled;

  // address
  address private _feeReceiver;

  // mappingsmodifier
  mapping(address => bool) public availableBaseTokens;
  mapping(address => bool) public availableQuoteTokens;
  mapping(address => EnumerableSet.UintSet) private availableOrdersIDsForUser;
  //  mapping(uint256 => Order) public orders;

  mapping(uint64 => OrderEscrow) private marketsEscrow;
  mapping(uint64 => OrderFixed) private marketsFixed;

  // return wether an order is available or not
  EnumerableSet.UintSet availableOrdersIDs;
  TwapOracle public twapOracle;


  struct UpdateStruct{
    uint64 orderID;
    bool enableTwap;
    bool orderClass;
    uint16 twapDiscount;
    uint256 amountBase;
    uint256 amountQuote;   
  }

  // events
  event UpdatedAvailableTokenBase(address indexed tokenBase);
  event UpdatedAvailableTokenQuote(address indexed tokenQuote);
  event UpdatedFeeReceiver(address indexed feeReceiver);
  event UpdatedPlatformFee(uint256 indexed platformFee);
  event TwapOracleUpdated(address indexed twapOracle);

  // order checks

  function canCreateOrder(address tokenBase, address tokenQuote) private view {
    if (!availableBaseTokens[tokenBase]) 
      revert BaseTokenNotAllowed();
    if (!availableQuoteTokens[tokenQuote])
      revert QuoteTokenNotAllowed();
    if(!tradingEnabled)
      revert();
  }

  function canTakeOrder(uint64 orderID, bool orderClass) private view {
    if (!isActive(orderID, orderClass))
      revert OrderNotActive(orderID, orderClass);

    if (msg.sender == getMaker(orderID, orderClass))
      revert InvalidTaker(orderID, orderClass);

    if (!tradingEnabled)
      revert();
  }

  function canCancelOrder(uint64 orderID, bool orderClass) private view {
    if (msg.sender != getMaker(orderID, orderClass))
      revert InvalidOwner(orderID, orderClass);
  }

  function canUpdateOrder(
    UpdateStruct memory update
  ) private view {
    if (!isActive(update.orderID, update.orderClass))
      revert OrderNotActive(update.orderID, update.orderClass);
    if (msg.sender != getMaker(update.orderID, update.orderClass))
      revert InvalidOwner(update.orderID, update.orderClass);
    if (update.amountBase <= 0) 
      revert InvalidAmount(update.orderID, update.orderClass);
    if (update.twapDiscount > 90 && update.enableTwap ) 
      revert InvalidDiscount(update.orderID, update.twapDiscount);
    
    if (update.orderClass) {
      // updating a fixed order

      OrderFixed memory _order = marketsFixed[update.orderID];
      ERC20 tokenBase = ERC20(_order.tokenBase);
      ERC20 tokenQuote = ERC20(_order.tokenQuote);
      if (
        _order.orderType &&
        update.amountQuote > tokenQuote.balanceOf(msg.sender)
      ) 
        // buy order, check if maker has enough tokenQuote
        revert InsufficientFunds(
          _order.tokenQuote,
          update.amountQuote
        );
        
      if (
        !_order.orderType &&
        update.amountBase > tokenBase.balanceOf(msg.sender)
      ) 
        // sell order, check amountBase
        revert InsufficientFunds(
          _order.tokenBase,
          update.amountBase
        );

      if (
        _order.orderType &&
        update.amountQuote > tokenQuote.allowance(msg.sender, address(this))
      ) 
        revert InsufficientAllowance();
      if (
        !_order.orderType &&
        update.amountBase > tokenBase.allowance(msg.sender, address(this))
      )
        revert InsufficientAllowance();
    
    }
  }

  constructor(address twapOracleAddress) {
    // to be changed
    _platformFee = 10;
    _platformFeeDivider = 1000;
    twapOracle = TwapOracle(twapOracleAddress);
  }

  function createOrderFixed(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType,
    uint64 expirationTime,
    bool enableTwap,
    uint16 twapDiscount
  )
    external
    nonReentrant
    returns (bool success)
  {
    canCreateOrder(tokenBase, tokenQuote);
    lastOrderID += 1;

    // take into account the possibility of trading tokens with different decimals than 18
    uint256 price = ((amountQuote * 10 ** (18 - ERC20(tokenQuote).decimals())) *
      1e18) / (amountBase * 10 ** (18 - ERC20(tokenBase).decimals()));

    if (orderType) {
      // buy order
      
      IERC20 tokenQuoteERC = IERC20(tokenQuote);
      uint256 userBalance = tokenQuoteERC.balanceOf(msg.sender);

      if (userBalance < amountQuote) {
        revert(); 
      }

      if (tokenQuoteERC.allowance(msg.sender, address(this)) < amountQuote)
        revert(); 
   
      emit OrderFixedBuyCreated(
        lastOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote,
        expirationTime
      );
      
    } else {
      //sell order
      IERC20 tokenBaseERC = IERC20(tokenBase);
      uint256 userBalance = tokenBaseERC.balanceOf(address(msg.sender));
      if (userBalance < amountBase) {
        revert();
      }

      if (tokenBaseERC.allowance(msg.sender, address(this)) < amountBase)
        revert(); /*InsufficientAllowance(
          tokenBase,
          amountBase,
          tokenBaseERC.allowance(msg.sender, address(this))
        );
      */
      emit OrderFixedSellCreated(
        lastOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
      
    }

    marketsFixed[lastOrderID] = OrderFixed(
      enableTwap,
      orderType,
      twapDiscount,
      lastOrderID,
      tokenBase,
      uint64(block.timestamp),
      tokenQuote,
      expirationTime,
      msg.sender,
      price,
      amountBase,
      amountQuote
    );

    // add a new order to the list of available orders for the user
    availableOrdersIDsForUser[msg.sender].add(uint256(lastOrderID));
    availableOrdersIDs.add(uint256(lastOrderID));
    _totalOrders = _totalOrders + 1;

    return true;
  }

  function takeOrderFixed(
    uint64 orderID
  ) external  nonReentrant returns (bool success) {
    OrderFixed memory orderSelected = marketsFixed[orderID];
    canTakeOrder(orderID, true);
    ERC20 tokenQuoteERC = ERC20(orderSelected.tokenQuote);
    ERC20 tokenBaseERC = ERC20(orderSelected.tokenBase);


    // this function is not available for twap orders
    if( orderSelected.enableTwap ) {
      revert();
    }

    
    if (orderSelected.orderType) {
      // buy order
      if (
        tokenQuoteERC.balanceOf(orderSelected.maker) < orderSelected.amountQuote ||
        tokenBaseERC.balanceOf(msg.sender) < orderSelected.amountBase 
      )
        revert(); 

      _transferTokensFixed(
        orderSelected.maker, 
        tokenBaseERC, 
        tokenQuoteERC,
        orderSelected.amountBase,
        orderSelected.amountQuote
      );


    } else {
      // sell order
      if (
        tokenBaseERC.balanceOf(orderSelected.maker) <  orderSelected.amountBase ||
        tokenQuoteERC.balanceOf(msg.sender) < orderSelected.amountQuote
      )
        revert(); 


      _transferTokensFixed(
        orderSelected.maker, 
        tokenQuoteERC, 
        tokenBaseERC,
        orderSelected.amountQuote,
        orderSelected.amountBase
      );

    }
        
    // order fulfilled, delete from the market orders
    delete marketsFixed[orderID];
    availableOrdersIDs.remove(uint256(orderID));

    _totalOrders = _totalOrders - 1;
    availableOrdersIDsForUser[msg.sender].add(uint256(lastOrderID));

    emit OrderFixedFulFilled(
      orderID,
      orderSelected.tokenBase,
      orderSelected.tokenQuote
    );

    return true;
  }

  /**
    * @dev Cancel an order
    * @param orderID The order ID
    * @param orderClass The order class (true: fixed or false: escrow)
    */
  function cancelOrder(
    uint64 orderID,
    bool orderClass
  ) external nonReentrant returns (bool success) {

    canCancelOrder(orderID, orderClass);

    _cancelOrder(orderID, msg.sender, orderClass);

    return true;
  }


  function updateOrderFixed(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote,
    uint64 expirationTime,
    bool enableTwap,
    uint16 twapDiscount
  )
    external
    nonReentrant
    returns (bool success)
  {
      canUpdateOrder( UpdateStruct(orderID, enableTwap, true, twapDiscount, amountBase, amountQuote ));
    
      OrderFixed memory order = marketsFixed[orderID];
    
  /*  uint256 price = ((amountQuote *
        10 ** (18 - ERC20(order.tokenQuote).decimals())) * 1e18) /
        (amountBase * 10 ** (18 - ERC20(order.tokenBase).decimals()));
    */
    
      order.amountBase = amountBase;
      order.amountQuote = amountQuote;
      order.expirationTime = expirationTime;
      order.enableTwap = enableTwap;
      order.price = ((amountQuote *
        10 ** (18 - ERC20(order.tokenQuote).decimals())) * 1e18) /
        (amountBase * 10 ** (18 - ERC20(order.tokenBase).decimals()));
        
      order.twapDiscount = twapDiscount;

      marketsFixed[orderID] = order;
    
      emit OrderFixedUpdated(
        order.orderID,
        order.price,
        expirationTime
      );

    
    return true;
  }

  function createOrderEscrow(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType,
    bool enableTwap,
    uint16 twapDiscount
  ) external nonReentrant returns (bool success) {
    if (!availableBaseTokens[tokenBase]) 
      revert BaseTokenNotAllowed();
    if (!availableQuoteTokens[tokenQuote])
      revert QuoteTokenNotAllowed();

    lastOrderID += 1;

    uint256 price = ((amountQuote * 10 ** (18 - ERC20(tokenQuote).decimals())) *
      1e18) / (amountBase * 10 ** (18 - ERC20(tokenBase).decimals()));

    if (orderType) {
      IERC20 tokenQuoteERC = IERC20(tokenQuote);
      uint256 userBalance = tokenQuoteERC.balanceOf(address(msg.sender));
      if (userBalance < amountQuote) {
        revert InsufficientFunds(tokenQuote, amountQuote);
      }

      // transfer funds
      tokenQuoteERC.transferFrom(msg.sender, address(this), amountQuote);

      emit OrderEscrowBuyCreated(
        lastOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
    } else {
      IERC20 tokenBaseERC = IERC20(tokenBase);
      uint256 userBalance = tokenBaseERC.balanceOf(address(msg.sender));
      if (userBalance < amountBase) {
        revert InsufficientFunds(tokenBase, amountBase );
      }

      tokenBaseERC.transferFrom(msg.sender, address(this), amountBase);

      emit OrderEscrowSellCreated(
        lastOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
    }

    marketsEscrow[lastOrderID] = OrderEscrow(
      enableTwap,
      orderType,
      twapDiscount,
      lastOrderID,
      tokenBase,
      tokenQuote,
      uint64(block.timestamp),
      msg.sender,
      price,
      amountBase,
      amountQuote
    );

    availableOrdersIDsForUser[msg.sender].add(uint256(lastOrderID));
    availableOrdersIDs.add(uint256(lastOrderID));

    _totalOrders = _totalOrders + 1;

    return true;
  }


  function _transferTokensEscrow( 
    address orderMaker,
    ERC20 tokenA,
    ERC20 tokenB,
    uint256 amountTokenA,
    uint256 amountTokenB
  ) internal returns (bool success) {

      // transfer the tokens from the taker to the maker
      tokenA.transferFrom(
        msg.sender,
        orderMaker,
        amountTokenA - ((amountTokenA * _platformFee) / _platformFeeDivider)
      );

      // transfer token from the contract to the taker
      tokenB.transfer(
        msg.sender,
        amountTokenB - ((amountTokenB * _platformFee) / _platformFeeDivider)
      );

      // take fees from the order maker and taker
      tokenA.transferFrom(
        msg.sender,
        _feeReceiver,
        ((amountTokenA * _platformFee) / _platformFeeDivider)
      );

      tokenB.transfer(
        _feeReceiver,
        (amountTokenB * _platformFee) / _platformFeeDivider
      );
      


    return true;
  }


  function _transferTokensFixed( 
    address orderMaker,
    ERC20 tokenA,
    ERC20 tokenB,
    uint256 amountTokenA,
    uint256 amountTokenB
  ) internal returns (bool success) {

    // transfer the tokens from the taker to the maker
    tokenA.transferFrom(
        msg.sender,
        orderMaker,
        amountTokenA -
          ((amountTokenA * _platformFee) / _platformFeeDivider)
    );
    // transfer token from the contract to the taker
    tokenB.transferFrom(
        orderMaker,
        msg.sender,
        amountTokenB -
          ((amountTokenB * _platformFee) / _platformFeeDivider)
      );

    // take fees from the order  maker and taker
    tokenA.transferFrom(
        msg.sender,
        _feeReceiver,
        ((amountTokenA * _platformFee) / _platformFeeDivider)
    );

    tokenB.transferFrom(
        orderMaker,
        _feeReceiver,
        ((amountTokenB * _platformFee) / _platformFeeDivider)
    );

    return true;
  }



  function takeOrderEscrow(
    uint64 orderID,
    uint256 amountToken
  ) external  nonReentrant returns (bool success) {
    canTakeOrder(orderID, false);
    OrderEscrow memory orderSelected = marketsEscrow[orderID];
    ERC20 tokenQuoteERC = ERC20(orderSelected.tokenQuote);
    ERC20 tokenBaseERC = ERC20(orderSelected.tokenBase);

    uint256 quoteDecimals = tokenQuoteERC.decimals();
    uint256 baseDecimals = tokenBaseERC.decimals();


    // this function is not available for twap orders
    if( orderSelected.enableTwap ) {
      revert();
    }


    if (orderSelected.orderType) {
      /// buy order
      if (amountToken < 0 || amountToken > orderSelected.amountBase)
        revert InvalidAmount(orderID, orderSelected.orderType);

      // amountToken is the amount of tokenBase I want to buy
      uint256 amountQuote = amountToken * orderSelected.price;

      // adapt to any type of decimal's combination
      if (quoteDecimals > baseDecimals) {
        amountQuote = amountQuote / 10 ** (18 - (quoteDecimals - baseDecimals));
      } else if (quoteDecimals < baseDecimals) {
        amountQuote = amountQuote / 10 ** (18 - (baseDecimals - quoteDecimals));
      }
      else amountQuote = (amountToken * orderSelected.price) / 10 ** 18;


      if (amountToken > tokenBaseERC.balanceOf(msg.sender))
        revert(); /*/InsufficientFunds(
          orderSelected.tokenBase,
          amountToken,
          tokenBaseERC.balanceOf(msg.sender)
        );
        */
      _transferTokensEscrow(
        orderSelected.maker,
        tokenBaseERC,
        tokenQuoteERC,
        amountToken,
        amountQuote
      );

      // check if order is fully filled

      marketsEscrow[orderID].amountBase -= amountToken;

      marketsEscrow[orderID].amountQuote -= amountQuote;

    } else {
      // sell order

      if (amountToken < 0 || amountToken > orderSelected.amountQuote)
        revert InvalidAmount(orderID, orderSelected.orderType);

      //  amountToken is the amount of tokenQuote I want to get by selling
      uint256 amountBase = (amountToken * 1e18) / orderSelected.price;

      if (quoteDecimals > baseDecimals) {
        amountBase = amountBase / 10 ** (18 - (quoteDecimals - baseDecimals));
      } else if (baseDecimals > quoteDecimals) {
        amountBase = amountBase / 10 ** (18 - (baseDecimals - quoteDecimals));
      }


      if (amountToken > tokenQuoteERC.balanceOf(msg.sender))
        revert(); /*/InsufficientFunds(
          orderSelected.tokenQuote,
          amountToken,
          tokenQuoteERC.balanceOf(msg.sender)
        );
        */


      _transferTokensEscrow(
        orderSelected.maker,
        tokenQuoteERC,
        tokenBaseERC,
        amountToken,
        amountBase
      );


      marketsEscrow[orderID].amountBase -= amountBase;

      marketsEscrow[orderID].amountQuote -= amountToken;
    }

    if (marketsEscrow[orderID].amountBase == 0 || marketsEscrow[orderID].amountQuote == 0) {
      delete marketsEscrow[orderID];
      availableOrdersIDs.remove(uint256(orderID));
      availableOrdersIDsForUser[msg.sender].remove(uint256(orderID));
     // removeOrderForUser(msg.sender, orderID);
      _totalOrders = _totalOrders - 1;
      _totalTrades = _totalTrades + 1;
      
      emit OrderEscrowFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );



      return true;
    }

    emit OrderEscrowPartialFilled(
      orderID,
      marketsEscrow[orderID].amountBase,
      marketsEscrow[orderID].amountQuote
    );

    _totalTrades = _totalTrades + 1;
    return true;
  
  }


  function _cancelOrder(
    uint64 orderID,
    address orderMaker,
    bool orderClass
    ) internal {

      if(orderClass) {
      
        OrderFixed memory _orderToBeDeleted = marketsFixed[orderID];
        delete marketsFixed[orderID];

        emit OrderFixedCancelled(
        orderID,
        _orderToBeDeleted.tokenBase,
        _orderToBeDeleted.tokenQuote
        ); 

      } else {

        OrderEscrow memory _orderToBeDeleted = marketsEscrow[orderID];

        if (_orderToBeDeleted.orderType) {
        // buy order

          IERC20 tokenQuoteERC = IERC20(_orderToBeDeleted.tokenQuote);
          tokenQuoteERC.transfer(orderMaker, _orderToBeDeleted.amountQuote);
        } else {
          // sell order

          IERC20 tokenBaseERC = IERC20(_orderToBeDeleted.tokenBase);
          tokenBaseERC.transfer(orderMaker, _orderToBeDeleted.amountBase);
        }

        delete marketsEscrow[orderID];

        emit OrderEscrowCancelled(
          orderID,
          _orderToBeDeleted.tokenBase,
          _orderToBeDeleted.tokenQuote
        );


      }
      availableOrdersIDsForUser[orderMaker].remove(uint256(orderID));
      //removeOrderForUser(orderMaker, orderID);
      availableOrdersIDs.remove(uint256(orderID));
      _totalOrders = _totalOrders - 1;  
              
    }


  function updateOrderEscrow(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote,
    bool enableTwap,
    uint16 twapDiscount
  )
    external
    nonReentrant
    returns (bool success)
  {
    if (!availableOrdersIDs.contains(uint256(orderID))) {
      revert OrderIDDoesNotExists({orderID: orderID});
    }
    canUpdateOrder(UpdateStruct(orderID, enableTwap, false, twapDiscount, amountBase, amountQuote ));

    OrderEscrow memory order = marketsEscrow[orderID];

    uint256 price = ((amountQuote *
      10 ** (18 - ERC20(order.tokenQuote).decimals())) * 1e18) /
      (amountBase * 10 ** (18 - ERC20(order.tokenBase).decimals()));

    if (order.orderType) {
      // buy order

      if (amountQuote > order.amountQuote) {
        IERC20(order.tokenQuote).transferFrom(
          msg.sender,
          address(this),
          (amountQuote - order.amountQuote)
        );
      } else if (amountQuote < order.amountQuote) {
        IERC20(order.tokenQuote).transfer(
          msg.sender,
          (order.amountQuote - amountQuote)
        );
      }
    } else {
      // sell order
      if (amountBase > order.amountBase) {
        IERC20(order.tokenBase).transferFrom(
          msg.sender,
          address(this),
          (amountBase - order.amountBase)
        );
      } else if (amountBase < order.amountQuote) {
        IERC20(order.tokenBase).transfer(
          msg.sender,
          (order.amountBase - amountBase)
        );
      }
    }

    marketsEscrow[orderID] = OrderEscrow(
      enableTwap,
      order.orderType,
      twapDiscount,
      orderID,
      order.tokenBase,
      order.tokenQuote,
      uint64(block.timestamp),
      order.maker,
      price,
      amountBase,
      amountQuote
    );

    emit OrderEscrowUpdated(
      orderID,
      price
    );

    return true;
  }



  /**
    * @dev Take a fixed order at TWAP price
    * @param orderID The order ID
    * @return success True if the order was taken
    */
  function takeTWAPOfferFixed(
    uint64 orderID
  )
    external
    nonReentrant
    returns (bool success)
  {
    canTakeOrder(orderID, true);

    OrderFixed memory orderSelected = marketsFixed[orderID];

    require(orderSelected.enableTwap, "Twap not enabled");

    ERC20 tokenQuoteERC = ERC20(orderSelected.tokenQuote);
    ERC20 tokenBaseERC = ERC20(orderSelected.tokenBase);
    
    twapOracle.updateByAddr(orderSelected.tokenBase, orderSelected.tokenQuote);


    if( orderSelected.orderType){
      // buy order
      
      uint256 amountBase = twapOracle.consult(
        orderSelected.tokenBase,
        orderSelected.tokenQuote,
        true,
        orderSelected.amountQuote
      ); 
      
      // apply discount
      amountBase = amountBase - (amountBase * orderSelected.twapDiscount) / 100;

      if(amountBase > orderSelected.amountBase){
        revert(); /*/InvalidTakeOrderTwap(
          orderID, 
          amountBase,
          orderSelected.amountBase  
        );
        */
      }


      _transferTokensFixed(
        orderSelected.maker,
        tokenBaseERC,
        tokenQuoteERC,
        amountBase,
        orderSelected.amountQuote
      );

      emit OrderFixedFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );


    } else{
      // sell order

      uint256 amountQuote = twapOracle.consult(
        orderSelected.tokenBase,
        orderSelected.tokenQuote,
        true,
        orderSelected.amountBase
      );
      
      amountQuote = amountQuote - (amountQuote * orderSelected.twapDiscount) / 100;
      
      if(amountQuote > orderSelected.amountQuote){
        revert(); /*/InvalidTakeOrderTwap(
          orderID, 
          amountQuote,
          orderSelected.amountQuote
        );
        */
      }

      _transferTokensFixed(
        orderSelected.maker,
        tokenQuoteERC, 
        tokenBaseERC,
        amountQuote,
        orderSelected.amountBase
      );

      emit OrderFixedFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );
    }

    // order fulfilled, delete from the market orders
    delete marketsFixed[orderID];
    availableOrdersIDs.remove(uint256(orderID));

    _totalOrders = _totalOrders - 1;

    return true;
   
  }

  /**
    * @dev Take a TWAP order at TWAP price
    * @param orderID The order ID
    * @param amountToken The amount of token to take ( inverse of take order escrow )
    * @return success True if the order was taken
    */
  function takeTWAPOfferEscrow(
    uint64 orderID,
    uint256 amountToken
  )
    external
    nonReentrant
    returns (bool success)
  {
    canTakeOrder(orderID, false);

    OrderEscrow memory orderSelected = marketsEscrow[orderID];

    require( orderSelected.enableTwap, "Twap not enabled"); 

    ERC20 tokenQuoteERC = ERC20(orderSelected.tokenQuote);
    ERC20 tokenBaseERC = ERC20(orderSelected.tokenBase);

   twapOracle.updateByAddr(orderSelected.tokenBase, orderSelected.tokenQuote);

    if( orderSelected.orderType){

      uint256 amountBase = twapOracle.consult(
        orderSelected.tokenQuote,
        orderSelected.tokenBase,
        false,
        amountToken
      );
      
      // apply discount
      amountBase = amountBase - (amountBase * orderSelected.twapDiscount) / 100;
      

      if(amountBase > orderSelected.amountBase){
        revert(); /*/InvalidTakeOrderTwap(
          orderID, 
          amountBase, 
          orderSelected.amountBase
        );
        */
      }

      _transferTokensEscrow(
        orderSelected.maker,
        tokenBaseERC,
        tokenQuoteERC,
        amountBase,
        amountToken
      );

      marketsEscrow[orderID].amountBase -= amountBase;

      marketsEscrow[orderID].amountQuote -= amountToken;

      marketsEscrow[orderID].price = ((amountToken * 
        10 ** (18 - tokenQuoteERC.decimals())) * 1e18) /
        (amountBase * 10 ** (18 - tokenBaseERC.decimals()));

    } else{

      uint256 amountQuote = twapOracle.consult(
        orderSelected.tokenBase,
        orderSelected.tokenQuote,
        true,
        amountToken
      );
       
      // apply discount
      amountQuote = amountQuote - (amountQuote * orderSelected.twapDiscount) / 100;

      if(amountQuote > orderSelected.amountQuote){
        revert(); /*/InvalidTakeOrderTwap(
          orderID, 
          amountQuote,
          orderSelected.amountQuote  
        );
        */
      }

      _transferTokensEscrow(
        orderSelected.maker,
        tokenQuoteERC,
        tokenBaseERC,
        amountQuote,
        amountToken
      );

      marketsEscrow[orderID].amountBase -= amountToken;

      marketsEscrow[orderID].amountQuote -= amountQuote;

      marketsEscrow[orderID].price = ((amountQuote * 
        10 ** (18 - tokenQuoteERC.decimals())) * 1e18) /
        (amountToken * 10 ** (18 - tokenBaseERC.decimals()));
    }

    if (marketsEscrow[orderID].amountBase == 0 || marketsEscrow[orderID].amountQuote == 0) {
      delete marketsEscrow[orderID];
      availableOrdersIDs.remove(uint256(orderID));
      emit OrderEscrowFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );

      _totalOrders = _totalOrders - 1;
      _totalTrades = _totalTrades + 1;

      return true;
    }

    emit OrderEscrowPartialFilled(
      orderID,
      marketsEscrow[orderID].amountBase,
      marketsEscrow[orderID].amountQuote
    );

    _totalTrades = _totalTrades + 1;

    return true;
  }
  /*
  function removeOrderForUser(
    address maker,
    uint64 orderID
  )
    internal
  {
    uint64[] memory ids = availableOrdersIDsForUser[maker];

    uint index = ids.length;
    for (uint i = 0; i < ids.length; i++) {
        if (ids[i] == orderID) {
            index = i;
            break;
        }
    }
    if (index < ids.length) {
        delete availableOrdersIDsForUser[maker][index];
    }

    }
    */
  

  /**
   *   @dev Cancel a list of active orders for a user
   *   @param orderIDList list of order IDs to cancel
   *   @return success true if the orders were cancelled
   */
  function emergencyCancelOrders(
    address user,
    uint64[] calldata orderIDList
  )
    external
    onlyOwner
    returns (bool success)
  {
    for (uint i = 0; i < orderIDList.length; i++) {
      uint64 orderID = orderIDList[i];

      if (marketsFixed[orderID].maker == user) {
        _cancelOrder(orderID, user, true);
      } else if (marketsEscrow[orderID].maker == user) {
        _cancelOrder(orderID, user, false);
      } else {
        revert OrderNotOwned(orderID);
      }
    }
    return true;
  }


  // setter functions

  /**
   *   @dev Set the reciever of the escrow platform fees
   *   @param feeReceiver address of the wallet recieving the platform fees
   */
  function setfeeReceiver(address feeReceiver) external onlyOwner {
    
    if ( 
        feeReceiver == address(0x0000000000000000000000000000000000000000) ||
        feeReceiver ==  address(0x000000000000000000000000000000000000dEaD) 
      )
      revert ();

    _feeReceiver = feeReceiver;
    emit UpdatedFeeReceiver(feeReceiver);
  }

  /**
   *   @dev Set the amount of fees taken by the escrow platform
   *   @param platformFee quantity of fees for going to the platform
   */
  function setPlatformFee(uint256 platformFee) external onlyOwner {
    if (platformFee > 20) revert(); //FeesTooHigh(platformFee);

    _platformFee = platformFee;
    emit UpdatedPlatformFee(platformFee);
  }

  /**
   *   @dev Add a Token to the list of available traded tokens
   *   @param newTokenBase The address of the new token available for trading
   *   @param state true if the token is available, else false
   *   Emits a {AddedTokenBase} event
   */
  function setAvailableTokenBase(
    address newTokenBase,
    bool state
  ) external onlyOwner {
    availableBaseTokens[newTokenBase] = state;

    emit UpdatedAvailableTokenBase(newTokenBase);
  }

  /**
   *   @dev Add a Token to the list of available quote tokens (that can be paired with each base token)
   *   @param newTokenQuote The address of the new token available for trading
   *   @param state true if the token is available, else false
   *   Emits a {AddedTokenQuote} event
   */
  function setAvailableTokenQuote(
    address newTokenQuote,
    bool state
  ) external onlyOwner {
    availableQuoteTokens[newTokenQuote] = state;

    emit UpdatedAvailableTokenQuote(newTokenQuote);
  }

  /**
   *   @dev Set the trading status of the platform
   *   @param _tradingEnabled true if the platform is open for trading, else false
   */
  function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
    tradingEnabled = _tradingEnabled;
  }

  // getter functions

  /**
   *   @dev Return the address of the platform's fees reciever
   */
  function getfeeReceiver() external view returns (address feeReceiver) {
    return _feeReceiver;
  }

  /**
   *   @dev Function that returns the total amount of orders divided by type and the
   *   total amount of trades.
   */
  function getPlatformStatistics()
    external
    view
    returns (uint64 totalOrders, uint64 totalTrades)
  {
    return (_totalOrders, _totalTrades);
  }

  /**
   *   @dev Check wether a certain fixed order is active or wether a certain escrow order exists
   *   @param orderID ID of the examined order
   *   @param orderClass type of order (true = fixed , false = escrow)
   *   @return true if the fixed order with "orderID" is active or the escrow order exists
   */
  function isActive(
    uint64 orderID,
    bool orderClass
  ) internal view returns (bool) {
    if (orderClass) {
      // fixed order
      return (marketsFixed[orderID].expirationTime > block.timestamp);
    } else {
      return (availableOrdersIDs.contains(uint256(orderID)));
    }
  }

  /**
   *   @dev Return the maker of a selected order
   *   @param orderID ID of the examined order
   *   @param orderClass type of order (true = fixed , false = escrow)
   *   @return maker the order maker address
   *
   */
  function getMaker(
    uint64 orderID,
    bool orderClass
  ) internal view returns (address maker) {
    if (orderClass) {
      // fixed order
      return (marketsFixed[orderID].maker);
    } else {
      // escrow order
      return (marketsEscrow[orderID].maker);
    }
  }


  /**
   *   @dev Return the list of all the active orders
   */
  function getActiveOrderIds() external view returns (uint256[] memory) {
    return availableOrdersIDs.values();
  }

  /**
   *   @dev Return the list of all the active orders for a given user
   *   @param user address of the user
   */
   function getAvailableOrderIdsForUser(address user) 
    external 
    view 
    returns (uint256[] memory) {
      return availableOrdersIDsForUser[user].values();
    }


  /**
   *   @dev Update TWAPOracle contract address
   *   @param newOracleAddress address of new TWAPOracle contract
   *
   */
  function updateTwapOracle(address newOracleAddress) external onlyOwner {
    twapOracle = TwapOracle(newOracleAddress);
    emit TwapOracleUpdated(newOracleAddress);
  }


  function getOrderFixed(
    uint64 orderID
  ) external view returns (OrderFixed memory orderSelected) {
    return marketsFixed[orderID];
  }

  function getOrderEscrow(
    uint64 orderID
  ) external view returns (OrderEscrow memory orderSelected) {
    return marketsEscrow[orderID];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

import "../libraries/FixedPoint.sol";
/**
 * 
 * Interface of the TwapOracle, a fixed window oracle that recomputes the average price 
 * for the entire period once every period.
 * NOTE: the price average is only guaranteed to be over at least 1 period, but may be over a longer period
 * 
 */
interface ITwapOracle {


  struct PairInfo {
    address token0;
    address token1;
    uint32 blockTimestampLast;
    address pair;
    FixedPoint.uq112x112 price0Average;
    FixedPoint.uq112x112 price1Average;
    uint256 price0CumulativeLast;
    uint256 price1CumulativeLast;
  }

  /**
   * @dev update the price for a given pair
   * @param pair: address of the pair to be updated
   * @return price0Average : average price of token0
   * @return price1Average : average price of token1
   */
 function update(address pair)
    external
    returns (
      FixedPoint.uq112x112 memory price0Average,
      FixedPoint.uq112x112 memory price1Average
    );

  /**
   * @dev add a new pair to the list of available pairs
   * @param token0 : address of the first token of the pair
   * @param token1 : address of the second token of the pair
   * @return newPair : the pair info of the new pair
   */
  function addPair(address token0, address token1)
    external
    returns (PairInfo memory);


  /**
   * @dev remove a pair from the list of available pairs
   * @param pairAddress : address of the first token of the pair
   */
  function removePair(address pairAddress)
    external
    returns (bool success);
 

  /** 
   * NOTE: this will always return 0 before update has been called successfully for the first time.
   * @dev returns the average price of the pair
   * @param token0 : address of the first token of the pair
   * @param token1 : address of the second token of the pair
   * @param isSell : true if the price is for a sell, false if it's for a buy
   * @param amountIn : amount of token0 or token1 depending on isSell
   */
  function consult(
    address token0,
    address token1,
    bool isSell,
    uint256 amountIn
  ) external 
    view 
    returns (uint256 amountOut); 

  /**
   * Returns the pair info for the given pair of tokens
   * @param token0 : address of the first token of the pair
   * @param token1 : address of the second token of the pair
   * @return pairInfo : the price info of the pair
   */ 
  function getPairInfoForTokens(
    address token0,
    address token1
  ) external
    view
    returns (PairInfo memory pairInfo);   

  /**
   * Returns the pair info of the pair
   * @param pairAddress : address of the pair
   * @return pairInfo : the price info of the pair
   */
  function getPairInfo(address pairAddress)
    external
    view
    returns (PairInfo memory pairInfo);


  /**
   * Update the TWAP period 
   * @param _period : new period in hours
   */
  function updateTWAPPeriod(uint32 _period) external;

}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;

//import 'hardhat/console.sol';
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libraries/UniswapV2OracleLibrary.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniswapV2Library.sol";
import "../libraries/FixedPoint.sol";
import "./ITwapOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period

contract TwapOracle is ITwapOracle {
  using FixedPoint for *;

  uint32 public PERIOD = 4 hours;
  address public immutable owner;
  address public immutable factory;
  address public constant ZERO =
    address(0x0000000000000000000000000000000000000000);


  mapping(address => PairInfo) availablePairs;


  event PairAdded(PairInfo newPair);
  event PairRemoved(address pairAddress);
  event PriceUpdated(PairInfo updatedPair);
  event PeriodUpdated(uint32 newPeriod);
  
  //error PairNotFound(string error);
  //error NoReserves(string error);

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  constructor(
    address _factory,
    address token0,
    address token1
  ) {
    factory = _factory;
    IUniswapV2Pair _pair = IUniswapV2Pair(
      UniswapV2Library.pairFor(_factory, token0, token1)
    );
 
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = _pair.getReserves();
    if(reserve0 == 0 || reserve1 == 0){ 
      // ensure that there's liquidity in the pair
      revert('TWAPOracle: NO_RESERVES');
    }
    owner = address(msg.sender);
    blockTimestampLast = uint32(block.timestamp % 2**32);

    /*
        price0Average = FixedPoint.uq112x112(
      uint224((price0Cumulative - availablePairs[pair].price0CumulativeLast) / timeElapsed)
    );
    price1Average = FixedPoint.uq112x112(
      uint224((price1Cumulative - availablePairs[pair].price1CumulativeLast) / timeElapsed)
    );
    */

    PairInfo memory newPair = PairInfo(
      _pair.token0(),
      _pair.token1(),
      blockTimestampLast,
      address(_pair),
      FixedPoint.uq112x112(uint224(1)),
      FixedPoint.uq112x112(uint224(1)),
      _pair.price0CumulativeLast(),
      _pair.price1CumulativeLast()
    );

    availablePairs[address(_pair)] = newPair;
  }


  function updateByAddr(address token0, address token1)
    external 
    returns (
      FixedPoint.uq112x112 memory price0Average,
      FixedPoint.uq112x112 memory price1Average
    )
  {
  
    address pair = address(IUniswapV2Pair(
      UniswapV2Library.pairFor(factory, token0, token1))
    );
 
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    uint32 timeElapsed = blockTimestamp - availablePairs[pair].blockTimestampLast; 

    // ensure that at least one full period has passed since the last update
    if(timeElapsed >= PERIOD){ 

    PairInfo storage pairInfo = availablePairs[pair];

    if(pairInfo.pair != pair)
      revert ('TWAPOracle: Pair not present');


    // overflow is desired, casting never truncates
    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    price0Average = FixedPoint.uq112x112(
      uint224((price0Cumulative - availablePairs[pair].price0CumulativeLast) / timeElapsed)
    );
    price1Average = FixedPoint.uq112x112(
      uint224((price1Cumulative - availablePairs[pair].price1CumulativeLast) / timeElapsed)
    );

    pairInfo.price0CumulativeLast = price0Cumulative;
    pairInfo.price1CumulativeLast = price1Cumulative;
    pairInfo.blockTimestampLast = blockTimestamp;
    pairInfo.price0Average = price0Average;
    pairInfo.price1Average = price1Average;

    emit PriceUpdated(availablePairs[pair]);
    } 
    
  }



  function update(address pair)
    external override
    returns (
      FixedPoint.uq112x112 memory price0Average,
      FixedPoint.uq112x112 memory price1Average
    )
  {
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    uint32 timeElapsed = blockTimestamp - availablePairs[pair].blockTimestampLast; 

    // ensure that at least one full period has passed since the last update
    require(timeElapsed >= PERIOD, 'TWAPOracle: PERIOD_NOT_ELAPSED');

    PairInfo storage pairInfo = availablePairs[pair];

    if(pairInfo.pair != pair)
      revert ('TWAPOracle: Pair not present');


    // overflow is desired, casting never truncates
    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
    price0Average = FixedPoint.uq112x112(
      uint224((price0Cumulative - availablePairs[pair].price0CumulativeLast) / timeElapsed)
    );
    price1Average = FixedPoint.uq112x112(
      uint224((price1Cumulative - availablePairs[pair].price1CumulativeLast) / timeElapsed)
    );

    pairInfo.price0CumulativeLast = price0Cumulative;
    pairInfo.price1CumulativeLast = price1Cumulative;
    pairInfo.blockTimestampLast = blockTimestamp;
    pairInfo.price0Average = price0Average;
    pairInfo.price1Average = price1Average;

    emit PriceUpdated(availablePairs[pair]);
  }


  function addPair(address token0, address token1)
    external override
    onlyOwner
    returns (PairInfo memory)
  {
    IUniswapV2Pair _pair = IUniswapV2Pair(
      UniswapV2Library.pairFor(factory, token0, token1)
    );

    uint112 reserve0;
    uint112 reserve1;
    uint32 blockTimestampLast;
    (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
    if(reserve0 == 0 || reserve1 == 0){
      // ensure that there's liquidity in the pair
      revert('TWAPOracle: NO_RESERVES');
    }
    
    require(
      availablePairs[address(_pair)].pair == ZERO,
      'TWAPOracle: Pair already present'
    );

    PairInfo memory newPair = PairInfo(
      _pair.token0(),
      _pair.token1(),
      blockTimestampLast,
      address(_pair),
      FixedPoint.uq112x112(uint224(1)),
      FixedPoint.uq112x112(uint224(1)),
      _pair.price0CumulativeLast(),
      _pair.price1CumulativeLast()
    );

    availablePairs[address(_pair)] = newPair;
    emit PairAdded(newPair);
    return newPair;
  }

  function removePair(address pairAddress)
    external override
    onlyOwner
    returns (bool success)
  {
    if( availablePairs[pairAddress].pair != pairAddress )
        revert( 'TWAPOracle: Pair not present');

    delete availablePairs[pairAddress];
    emit PairRemoved(pairAddress);

    return true;
  }

  function consult(
    address token0,
    address token1,
    bool isSell,
    uint256 amountIn
  ) external view override returns (uint256 amountOut) {
    IUniswapV2Pair _pair = IUniswapV2Pair(
      UniswapV2Library.pairFor(factory, token0, token1)
    );

    address pairAddress = address(_pair);

    if( availablePairs[pairAddress].pair != pairAddress)
      revert (
        'TWAPOracle: Pair not present'
      );
  
    PairInfo memory pairInfo = availablePairs[pairAddress];

    if (isSell) {
      // NOTE: mul returns uq144x112
      amountOut = pairInfo.price0Average.mul(amountIn).decode144(); // decode144() divides by 2**112
    } else {
      amountOut = pairInfo.price1Average.mul(amountIn).decode144();
    }
  }

  function getPairInfoForTokens(address token0, address token1)
    external
    view override
    returns (PairInfo memory pairInfo)
  {
    IUniswapV2Pair _pair = IUniswapV2Pair(
      UniswapV2Library.pairFor(factory, token0, token1)
    );
    address pairAddress = address(_pair);

    if( availablePairs[pairAddress].pair != pairAddress)
      revert (
        'TWAPOracle: Pair not present'
      );
  
    pairInfo = availablePairs[pairAddress];
  }
  
  function getPairInfo(address pairAddress)
    external
    view override
    returns (PairInfo memory pairInfo)
  {
    pairInfo = availablePairs[pairAddress];
  }

  function updateTWAPPeriod(uint32 _period) 
    external 
    override 
    onlyOwner {
    PERIOD = _period;
    emit PeriodUpdated(_period);
  }

}