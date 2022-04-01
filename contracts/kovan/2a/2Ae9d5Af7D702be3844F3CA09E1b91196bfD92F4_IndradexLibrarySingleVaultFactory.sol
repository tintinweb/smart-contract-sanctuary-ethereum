// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PreciseUnitMath} from "./libs/PreciseUnitMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract IndradexBaseVault is Ownable, ERC20 {
  using PreciseUnitMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using EnumerableSet for EnumerableSet.AddressSet;

  address internal constant DUMMY_AGGREGATOR = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

  struct TokenInfo{
    uint256 externalBalance;
    uint256 pendingWithdrawal;
    AggregatorV3Interface aggregator;
    uint8 tokenDecimals;
    uint8 aggregatorDecimals;
  }
  struct PendingUsersWithdrawal{
    uint256 endingTime;
    uint256[] tokenAmounts;
  }
  struct Balances{
    uint256 internalBalance;
    uint256 externalBalance;
    uint256 pendingBalance;
    int256 totalBalance;
  }
  struct TokenBalances{
    address token;
    Balances balances;
  }

  struct TokenTotalBalance{
    address token;
    uint256 balance;
  }

  uint256 internal _apr;
  uint256 internal _withdrawalTime;
  uint256 internal _maxCapDeposit;

  ERC20 internal immutable inputToken;
  EnumerableSet.AddressSet internal tokens;
  mapping(address=>TokenInfo) internal tokenInfo;
  mapping(address=>PendingUsersWithdrawal[]) internal pendingUsersWithdrawal;

  event APRUpdated(uint256 previousApr, uint256 newApr);
  event withdrawalTimeUpdated(uint256 previousWithdrawalTime, uint256 newWithdrawalTime);
  event maxCapDepositUpdated(uint256 previousMaxCapDeposit, uint256 newMaxCapDeposit);
  // TODO: eventi per deposit e withdraw

    /**
   * @dev Throws if the specified token is not in tokens list.
   */
  modifier onlyPresentToken(address token) {
      require(tokens.contains(token), "Vault: token is not in the list");
      _;
  }

  /**
    * @dev Initializes the contract setting the owner, name, symbol, inputToken and outputTokens with aggregators.
    */
  constructor(address newOwner, string memory name_, string memory symbol_, address payable inputToken_,
                address[] memory outputTokens_, address[] memory aggregators_, uint256 maxCapDeposit) ERC20(name_, symbol_) {
    require(inputToken_ != address(0), "Vault: inputToken is the zero address");
    require(outputTokens_.length == aggregators_.length, "Vault: outputTokens and aggregators lists have different length");
    uint8 current_token_decimals = ERC20(inputToken_).decimals();
    require(current_token_decimals<=18, "Vault: inputToken has unsupported number of decimals");
    inputToken = ERC20(inputToken_);
    tokens.add(inputToken_);
    tokenInfo[inputToken_] = TokenInfo(0, 0, AggregatorV3Interface(DUMMY_AGGREGATOR), current_token_decimals, 0);
    uint8 current_aggregator_decimals;
    for (uint i=0; i<outputTokens_.length; i++) {
      require(outputTokens_[i] != address(0), "Vault: one among the outputTokens is the zero address");
      require(aggregators_[i] != address(0), "Vault: one among the aggregators is the zero address");
      current_token_decimals = ERC20(outputTokens_[i]).decimals();
      require(current_token_decimals<=18, "Vault: one among the outputTokens has unsupported number of decimals");
      current_aggregator_decimals = AggregatorV3Interface(aggregators_[i]).decimals();
      require(current_aggregator_decimals<=18, "Vault: one among the aggregators has unsupported number of decimals");
      require(tokens.add(outputTokens_[i]), "Vault: duplicated token");
      tokenInfo[outputTokens_[i]] = TokenInfo(0, 0,AggregatorV3Interface(aggregators_[i]), current_token_decimals, current_aggregator_decimals);
    }
    if(block.chainid == 80001){
      _setWithdrawalTime(10 minutes);
    }
    else{
      _setWithdrawalTime(1 weeks);
    }
    _setMaxCapDeposit(maxCapDeposit);
    _transferOwnership(newOwner);
  }

  /**
   * @dev Returns the current APR.
   */
  function getApr() external view returns (uint256) {
    return _apr;
  }

  /**
   * @dev Set APR to 'newApr'. Can only be called by the current owner.
   */
  function setApr(uint256 newApr) external onlyOwner {
    _setApr(newApr);
  }

  /**
   * @dev Set APR to 'newApr'.
   * Internal function without access restriction.
   */
  function _setApr(uint256 newApr) internal {
    uint256 previousApr = _apr;
    _apr = newApr;
    emit APRUpdated(previousApr, newApr);
  }

  /**
   * @dev Returns the current withdrawalTime.
   */
  function getWithdrawalTime() external view returns (uint256) {
    return _withdrawalTime;
  }

  /**
   * @dev Set withdrawalTime to 'newWithdrawalTime'. Can only be called by the current owner.
   */
  function setWithdrawalTime(uint256 newWithdrawalTime) external onlyOwner {
    _setWithdrawalTime(newWithdrawalTime);
  }

  /**
   * @dev Set withdrawalTime to 'newWithdrawalTime'.
   * Internal function without access restriction.
   */
  function _setWithdrawalTime(uint256 newWithdrawalTime) internal {
    require(newWithdrawalTime>0, "Vault: withdrawal time must be greater than 0");
    uint256 previousWithdrawalTime = _withdrawalTime;
    _withdrawalTime = newWithdrawalTime;
    emit withdrawalTimeUpdated(previousWithdrawalTime, newWithdrawalTime);
  }

  /**
   * @dev Returns the current maxCapDeposit.
   */
  function getMaxCapDeposit() external view returns (uint256) {
    return _maxCapDeposit;
  }

  /**
   * @dev Set maxCapDeposit to 'newMaxCapDeposit'. Can only be called by the current owner.
   */
  function setMaxCapDeposit(uint256 newMaxCapDeposit) external onlyOwner {
    _setMaxCapDeposit(newMaxCapDeposit);
  }

  /**
   * @dev Set maxCapDeposit to 'newMaxCapDeposit'.
   * Internal function without access restriction.
   */
  function _setMaxCapDeposit(uint256 newMaxCapDeposit) internal {
    uint256 previousMaxCapDeposit = _maxCapDeposit;
    _maxCapDeposit = newMaxCapDeposit;
    emit maxCapDepositUpdated(previousMaxCapDeposit, newMaxCapDeposit);
  }


  /**
   * @dev Returns an array of internal, external and total balances of every token.
   */
  function tokensBalances() external view returns(TokenBalances[] memory){
    TokenBalances[] memory tokenBalances = new TokenBalances[](tokens.length());
    address currentToken;
    uint256 _internalBalance;
    uint256 _externalBalance;
    uint256 _pendingBalance;
    int256 _totalBalance;
    for (uint i=0; i<tokens.length(); i++) {
      currentToken = tokens.at(i);
      _internalBalance = tokenInternalBalance(currentToken);
      _externalBalance = tokenExternalBalance(currentToken);
      _pendingBalance = tokenPendingBalance(currentToken);
      _totalBalance = _internalBalance.toInt256() + _externalBalance.toInt256() - _pendingBalance.toInt256();
      tokenBalances[i] = (TokenBalances({
                              token: currentToken,
                              balances: Balances({
                                              internalBalance: _internalBalance,
                                              externalBalance: _externalBalance,
                                              pendingBalance: _pendingBalance,
                                              totalBalance: _totalBalance
                                              })
                              }));
    }
    return tokenBalances;
  }

  /**
    * @dev Returns the total balance for a token i.e. the sum of the internal and external balance for that token.
    */
  function tokenTotalBalance(address token) internal view returns(uint256){
    return tokenInternalBalance(token) + tokenExternalBalance(token) - tokenPendingBalance(token);
  }

  /**
    * @dev Returns the internal balance for a token i.e. the balance of the contract for that token.
    */
  function tokenInternalBalance(address token) internal view returns(uint256){
    return ERC20(token).balanceOf(address(this));
  }

  /**
    * @dev Returns the external balance for a token.
    */
  function tokenExternalBalance(address token) virtual internal view returns(uint256);

  /**
    * @dev Returns the pending balance for a token.
    */
  function tokenPendingBalance(address token) internal view returns(uint256){
    return tokenInfo[token].pendingWithdrawal;
  }


  /**
    * @dev Returns the price from Chainlink data feed with 18 decimals.
    */
  function scaledChainlinkPrice(AggregatorV3Interface aggregator, uint8 aggregatorDecimals) internal view returns(uint256){
    uint256 price;
    if(address(aggregator) == DUMMY_AGGREGATOR){
      price = PreciseUnitMath.preciseUnit();
    }
    else{
      ( , int256 priceInt, , , ) = aggregator.latestRoundData();
      price = priceInt.toUint256() * 10 ** (18 - aggregatorDecimals);
    }
    return price;
  }

  /**
    * @dev Calculate vault total value (sum of all tokens multiplied by their price) with 18 decimals.
    */
  function vaultTotalScaledValue() public view returns(uint256){
    uint256 scaledTotalTokensPrice;
    uint256 scaledTotalBalance;
    address currentToken;
    for(uint i=0; i<tokens.length(); i++){
      currentToken = tokens.at(i);
      TokenInfo memory currentTokenInfo = tokenInfo[currentToken];
      scaledTotalBalance = tokenTotalBalance(currentToken) * 10 ** (18 - currentTokenInfo.tokenDecimals);
      scaledTotalTokensPrice += scaledTotalBalance.mul(scaledChainlinkPrice(currentTokenInfo.aggregator, currentTokenInfo.aggregatorDecimals));
    }
    return scaledTotalTokensPrice;
  }
  /**
  * @dev returns the scaled vault total value (sum of all tokens multiplied by their price) with 18 decimals
  */
    function vaultScaledValue(uint256 amount) external view returns(uint256){
      return amount.mul(vaultTotalScaledValue()).div(totalSupply());
  }

  /**
  * @dev Get 'amount' LP token and returns the 
  * @param amount    Returns the scaled tot balance for every tokens
  */
  function lpBalances(uint256 amount) external view returns(TokenTotalBalance[] memory){
    uint256 tokensLength = tokens.length();
    uint256 totalSupply = totalSupply();
    address currentToken;
    TokenTotalBalance[] memory tokenTotalBalances = new TokenTotalBalance[] (tokensLength);
    for(uint j=0; j<tokensLength; j++){
      currentToken = tokens.at(j);
      tokenTotalBalances[j].token = currentToken;
      tokenTotalBalances[j].balance = amount.mul(tokenTotalBalance(currentToken)).div(totalSupply);
    }
    return tokenTotalBalances;
  }

  function lpTokens(uint256 amount) external view returns(uint256){
    return calculateMintAmount(amount * 10 ** (18 - tokenInfo[address(inputToken)].tokenDecimals), 
                                totalSupply(),
                                 vaultTotalScaledValue());
  }

  /**
    * @dev Calculate amount to mint relative to the share of a given amount of tokens with 18 decimals.
    */
  function calculateMintAmount(uint256 amount, uint256 totalSupply, uint256 vaultTotalValue_) internal pure returns(uint256){
    return totalSupply.mul(amount).div(vaultTotalValue_);  
  }

  /**
    * @dev Deposit tokens adding them to contract balance.
    */
  function deposit(uint256 amount) external {
    require(amount > 0, "Vault: deposit amount must be greater than 0");
    address sender = msg.sender;
    uint256 mintAmount;
    uint256 inputTokenDecimals = tokenInfo[address(inputToken)].tokenDecimals;
    uint256 scaledAmount = amount * 10 ** (18 - inputTokenDecimals);
    uint256 totalSupply = totalSupply();
    uint256 vaultTotalValue_ = vaultTotalScaledValue();
    if(_maxCapDeposit > 0){
      require(vaultTotalValue_ + scaledAmount <= _maxCapDeposit * 10 ** (18 - inputTokenDecimals), "Vault: deposit exceed vault maximum capacity");
    }
    if(totalSupply==0){
      mintAmount = scaledAmount;
    }
    else{
      mintAmount = calculateMintAmount(scaledAmount, totalSupply, vaultTotalValue_);
    }
    inputToken.transferFrom(sender, address(this), amount);
    _mint(sender, mintAmount);
  }

  /**
    * @dev Send quantity 'amount' of token 'token' to owner's address. Can only be called by the current owner.
    */
  function adminWithdraw(address token, uint256 amount) external onlyOwner onlyPresentToken(token){
    require(amount <= tokenTotalBalance(token), "Vault: withdraw amount cannot be greater than token total balance");
    ERC20(token).transfer(msg.sender, amount);
  }

  /**
  * @dev Burn tokens and create or update user's withdrawal request.
  */
  function requestWithdrawal(uint256 amount) external{
    require(amount > 0, "Vault: withdrawal amount must be greater than 0");
    address sender = msg.sender;
    uint256 tokensLength = tokens.length();
    uint256 totalSupply_ = totalSupply();
    _burn(sender, amount);
    PendingUsersWithdrawal memory newPendingUsersWithdrawal =  PendingUsersWithdrawal(block.timestamp + _withdrawalTime, new uint256[](tokensLength));
    address currentToken;
    uint256 tokenAmount;
    for(uint i=0; i<tokensLength; i++){
      currentToken = tokens.at(i);
      tokenAmount = amount.mul(tokenTotalBalance(currentToken)).div(totalSupply_);
      tokenInfo[currentToken].pendingWithdrawal += tokenAmount;
      newPendingUsersWithdrawal.tokenAmounts[i] = tokenAmount;
    }
    pendingUsersWithdrawal[sender].push(newPendingUsersWithdrawal);
  }

  /**
  * @dev Get one user's withdrawal requests.
  */
  function getUserWithdrawals(address user) external view returns(PendingUsersWithdrawal[] memory){
    return pendingUsersWithdrawal[user];
  }

  /**
  * @dev Release user's withdrawal request. Can only be called by the current owner.
  */
  function releaseAdmin(address userAddress, uint256[] calldata withdrawals) external onlyOwner {
    _release(userAddress, withdrawals, false);
  }

  /**
  * @dev Release user's withdrawal request if '_withdrawalTime' time has passed.
  */
  function releaseUser(uint256[] calldata withdrawals) external {
    _release(msg.sender, withdrawals, true);
  }

  /**
   * @dev Release user's withdrawal request.
   * Internal function without access restriction.
   */
  function _release(address userAddress, uint256[] calldata withdrawals, bool timeCheck) internal {
    PendingUsersWithdrawal storage withdrawal;
    address currentToken;
    uint256 currentTokenAmount;
    uint256 tokensLength = tokens.length();
    uint256[] memory tokensAmounts = new uint256[](tokensLength);
    for(uint i=0; i<withdrawals.length; i++){
      withdrawal = pendingUsersWithdrawal[userAddress][withdrawals[i]];
      if(timeCheck){
        require(withdrawal.endingTime <= block.timestamp, "Vault: withdrawal time has not passed since withdrawal request");
      }
      require(withdrawal.endingTime != 0, "Vault: no pending user's withdrawal");
      for(uint j=0; j<tokensLength; j++){
        tokensAmounts[j] += withdrawal.tokenAmounts[j];
      }
      withdrawal.endingTime = 0;
    }

    for(uint j=0; j<tokensLength; j++){
        currentToken = tokens.at(j);
        currentTokenAmount = tokensAmounts[j];
        if(currentTokenAmount > 0){
          ERC20(currentToken).transfer(userAddress, currentTokenAmount);
          tokenInfo[currentToken].pendingWithdrawal -= currentTokenAmount;
        }
      }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import {IndradexSingleExternalVault} from "./IndradexSingleExternalVault.sol";

library IndradexLibrarySingleVaultFactory{
    /**
    * @dev Creates new vault
    */
    function createVault(address newOwner, string memory name_, string memory symbol_, address payable inputToken_,
                address[] memory outputTokens_, address[] memory aggregators_, uint256 maxCapDeposit) external returns(IndradexSingleExternalVault){
        return new IndradexSingleExternalVault(newOwner, name_, symbol_, inputToken_, outputTokens_, aggregators_, maxCapDeposit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import {IndradexBaseVault} from "./IndradexBaseVault.sol";

contract IndradexSingleExternalVault is IndradexBaseVault {

  /**
    * @dev Initializes the contract setting the owner, name, symbol, inputToken and outputTokens with aggregators.
    */
  constructor(address newOwner, string memory name_, string memory symbol_, address payable inputToken_,
                address[] memory outputTokens_, address[] memory aggregators_, uint256 maxCapDeposit) 
      IndradexBaseVault(newOwner, name_, symbol_, inputToken_, outputTokens_, aggregators_, maxCapDeposit) {}

  /**
    * @dev Returns the external balance for a token.
    */
  function tokenExternalBalance(address token) internal override view returns(uint256){
    if(token == address(inputToken)){
      return tokenInfo[token].externalBalance;
    }
    else{
      return 0;
    }
  }

  /**
    * @dev Set the external balance only for the specified token.
    */
  function setInputTokenExternalBalance(uint256 newExternalBalance) external onlyOwner {
    tokenInfo[address(inputToken)].externalBalance = newExternalBalance;
  }
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";


/**
 * @title PreciseUnitMath
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 */
library PreciseUnitMath {
    using SafeCast for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (a * b - 1) / PRECISE_UNIT + 1;
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * PRECISE_UNIT / b;
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a * PRECISE_UNIT_INT / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? (a * PRECISE_UNIT - 1) / b + 1 : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function divCeil(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        
        a = a * PRECISE_UNIT_INT;
        int256 c = a / b;

        if (a % b != 0) {
            // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
            (a ^ b > 0) ? ++c : --c;
        }

        return c;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a / b;
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativeMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a * b, PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativeDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a * PRECISE_UNIT_INT, b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            result = previousResult * a;
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b + range && a >= b - range;
    }

    /**
     * Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 a) internal pure returns (uint) {
        return a >= 0 ? a.toUint256() : (a * -1).toUint256();
    }

    /**
     * Returns the negation of a
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a > MIN_INT_256, "Inversion overflow");
        return -a;
    }
}