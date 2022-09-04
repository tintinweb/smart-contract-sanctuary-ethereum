/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData()
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

// File: newContracts/DEXTokenPrice.sol


pragma solidity ^0.8.8;


contract DEXTokenPrice {
  mapping(address => address) internal s_tokenUsdPricesV3contracts;

  constructor(
    address[] memory validTokenAddr,
    address[] memory chainlinkAggregatorV3Addr
  ) {
    for (uint8 i = 0; i < validTokenAddr.length; i++) {
      s_tokenUsdPricesV3contracts[
        validTokenAddr[i]
      ] = chainlinkAggregatorV3Addr[i];
    }
  }

  function _getPrice(AggregatorV3Interface tokenPriceFeed)
    internal
    view
    returns (int256)
  {
    int256 price = _getLatestPrice(tokenPriceFeed);
    return price;
  }

  function _getLatestPrice(AggregatorV3Interface tokenPriceFeed)
    internal
    view
    returns (int256)
  {
    (
      ,
      /*uint80 roundID*/
      int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
      ,
      ,

    ) = tokenPriceFeed.latestRoundData();
    return price;
  }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: newContracts/DEXValidTokens.sol



pragma solidity ^0.8.8;


contract DEXValidTokens is Ownable {
  address[] public s_validTokenAddresses;
  address internal immutable i_wethContractAddress;

  event TokenAddressesSet(address[], address);
  event TokensAdded(address[], address);
  event TokensRemvod(address[], address);

  constructor(address[] memory tokenAddresses, address wethContract) {
    for (uint8 i = 0; i < tokenAddresses.length; i++) {
      s_validTokenAddresses.push(tokenAddresses[i]);
    }
    i_wethContractAddress = wethContract;
    emit TokenAddressesSet(tokenAddresses, _msgSender());
  }

  function addTokens(address[] memory tokenAddresses) external onlyOwner {
    for (uint8 i = 0; i < tokenAddresses.length; i++) {
      s_validTokenAddresses.push(tokenAddresses[i]);
    }
    emit TokensAdded(tokenAddresses, _msgSender());
  }

  function renewAddresses(address[] memory tokenAddresses) external onlyOwner {
    for (uint8 i = 0; i < tokenAddresses.length; i++) {
      s_validTokenAddresses.push(tokenAddresses[i]);
    }
    emit TokenAddressesSet(tokenAddresses, _msgSender());
  }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: newContracts/WETH.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;



error WETH_AnErrorOccured();

contract WETH is ERC20, ReentrancyGuard {
  event Deposit(address, uint256);
  event Withdraw(address, uint256);

  constructor(uint256 initialSupply) ERC20("Wrapped Ether", "WETH") {}

  function deposit() public payable {
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) external nonReentrant {
    _burn(msg.sender, amount);
    (bool success, ) = payable(msg.sender).call{ value: amount }("");

    if (!success) {
      revert WETH_AnErrorOccured();
    }
    emit Withdraw(msg.sender, amount);
  }

  function ethBalance() public view returns (uint256) {
    return address(this).balance;
  }

  fallback() external payable {
    deposit();
  }

  receive() external payable {
    deposit();
  }
}

// File: newContracts/DEX.sol

pragma solidity ^0.8.8;









error DEX_notEnoughTokenProvided(address provider, uint256 amount);
error DEX_notEnoughAmountProvided(address provider, uint256 amount);
error DEX_notValidToken(address token);
error DEX_insufficientBalance(address owner, address token);
error DEX_tokenNotSupported(address token);
error DEX_invalidId();
error DEX_swapForTokensNotSupported(address from, address to);
error DEX_sameTokensProvidedForSwap(address from, address to);
error DEX_insufficientLiquidityInPool(int256 amount);
error DEX_anErrorOccured();
error DEX_WrongFunctionCall();
error DEX_poolNotActive();
error DEX_notPoolOwner(address owner);
error DEX_poolInTimeLock(uint256 minLockPeriod);

/// @title A Decenteralized exchange for swapping tokens
/// @author Aamir usmani. github username: Aamirusmani1552
/// @notice This contract is just a for learning purpose. Please don't use it to deploy on mainnet. it might lead to loss of funds.
/// @dev since solidity doesn't support fractional value, the contract formula's has been modified accordingly.

contract DEX is Ownable, DEXValidTokens, DEXTokenPrice, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeMath for int128;
  using Counters for Counters.Counter;
  Counters.Counter private s_counter;

  uint256 private constant RATE_0F_INTEREST_PER_ANNUM = 10;

  struct pool {
    address token;
    uint256 amount;
    uint256 timestamp;
    uint256 minLockPeriod;
    address owner;
    bool active;
  }

  mapping(uint256 => pool) private s_liquidityPool;
  mapping(address => uint256[]) private s_poolContributions;

  event poolCreated(
    uint256 indexed poolId,
    address indexed token,
    uint256 amount,
    address owner,
    uint256 indexed timeStamp,
    uint256 minLockPeriod,
    bool active
  );

  event EthToTokenSwapSuccessfull(
    uint256 ethSwapped,
    int256 tokenReceived,
    int256 transactionFee,
    address user
  );

  event TokenToEthSwapSuccessfull(
    uint256 tokenSwapped,
    int256 tokenReceived,
    int256 transactionFee,
    address user
  );

  event tokenSwappedSuccessfully(
    uint256 tokenSwapped,
    int256 tokenReceived,
    int256 transactionFee,
    address user
  );

  event LiquidityWithdrawSuccessfull(
    uint256 poolId,
    uint256 tokenToRecieve,
    uint256 tokenToReceiveWithInterest,
    uint256 totalInterestEarned,
    address user,
    address token
  );

  constructor(
    address[] memory tokenAddresses,
    address[] memory chainlinkAggregatorV3Addr,
    address wethContract
  )
    DEXValidTokens(tokenAddresses, wethContract)
    DEXTokenPrice(tokenAddresses, chainlinkAggregatorV3Addr)
  {}

  function provideLiquidity(address token, uint256 amount)
    public
    payable
    nonReentrant
  {
    if (token == address(0)) {
      revert DEX_notValidToken(token);
    }
    if (amount <= 0) {
      revert DEX_notEnoughTokenProvided(msg.sender, amount);
    }
    if (!_tokenPresent(token)) {
      revert DEX_tokenNotSupported(token);
    }

    if (IERC20(token).balanceOf(msg.sender) < amount && msg.value <= 0) {
      revert DEX_insufficientBalance(msg.sender, token);
    }

    pool memory newPool = pool(
      token,
      amount,
      block.timestamp,
      block.timestamp + uint256(1 weeks),
      msg.sender,
      true
    );
    s_liquidityPool[s_counter.current()] = newPool;
    uint256 poolId = s_counter.current();
    s_poolContributions[msg.sender].push(poolId);
    s_counter.increment();

    if (msg.value > 0 && token == i_wethContractAddress) {
      WETH wethContract = WETH(payable(i_wethContractAddress));
      wethContract.deposit{ value: msg.value }();
    } else {
      IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
    emit poolCreated(
      poolId,
      token,
      amount,
      msg.sender,
      block.timestamp,
      (block.timestamp + uint256(1 weeks)),
      true
    );
  }

  function swap(
    address from,
    address to,
    uint256 amount
  ) public nonReentrant {
    if (from == i_wethContractAddress || to == i_wethContractAddress) {
      revert DEX_WrongFunctionCall();
    }
    if (from == to) {
      revert DEX_sameTokensProvidedForSwap(from, to);
    }

    if (from == address(0) || to == address(0)) {
      revert DEX_notValidToken(address(0));
    }
    if (amount <= 0) {
      revert DEX_notEnoughAmountProvided(msg.sender, amount);
    }
    if (!_tokenPresent(from) || !_tokenPresent(to)) {
      revert DEX_swapForTokensNotSupported(from, to);
    }

    if (IERC20(from).balanceOf(msg.sender) < amount) {
      revert DEX_insufficientBalance(msg.sender, from);
    }

    int256 totalToToken = calculateExchangeToken(from, to, amount);
    if (IERC20(to).balanceOf(address(this)) < uint256(totalToToken)) {
      revert DEX_insufficientLiquidityInPool(totalToToken);
    }

    int256 fee = _calculateExchangeFee(totalToToken);
    uint256 amountToSend = (uint256(totalToToken).sub(uint256(fee))).mul(
      10**10
    );

    IERC20(from).transferFrom(msg.sender, address(this), amount.mul(10**18));
    IERC20(to).transfer(msg.sender, amountToSend);

    emit tokenSwappedSuccessfully(
      (amount).mul(10**18),
      int256(amountToSend),
      fee,
      msg.sender
    );
  }

  function swapWETH(
    address from,
    address to,
    uint256 amount
  ) public payable nonReentrant {
    if (from == address(0) || to == address(0)) {
      revert DEX_notValidToken(address(0));
    } else if (amount <= 0) {
      revert DEX_notEnoughAmountProvided(msg.sender, amount);
    } else if (
      msg.value > 0 && from == i_wethContractAddress && _tokenPresent(to)
    ) {
      int256 totalToToken = calculateExchangeToken(
        i_wethContractAddress,
        to,
        amount
      );

      if (
        IERC20(to).balanceOf(address(this)) < uint256(totalToToken).mul(10**10)
      ) {
        revert DEX_insufficientLiquidityInPool(
          int256(uint256(totalToToken).mul(10**10))
        );
      }

      WETH wethContract = WETH(payable(i_wethContractAddress));
      wethContract.deposit{ value: msg.value }();
      int256 fee = _calculateExchangeFee(totalToToken);
      IERC20(to).transfer(
        msg.sender,
        (uint256(totalToToken).sub(uint256(fee))).mul(10**10)
      );

      emit EthToTokenSwapSuccessfull(
        msg.value,
        int256((uint256(totalToToken).sub(uint256(fee))).mul(10**10)),
        int256(uint256(fee).mul(10**10)),
        msg.sender
      );
    } else if (
      msg.value <= 0 && _tokenPresent(from) && to == i_wethContractAddress
    ) {
      int256 totalToToken = calculateExchangeToken(
        from,
        i_wethContractAddress,
        amount
      );

      if (
        IERC20(i_wethContractAddress).balanceOf(address(this)) <
        uint256(totalToToken).mul(10**10)
      ) {
        revert DEX_insufficientLiquidityInPool(
          int256(uint256(totalToToken).mul(10**10))
        );
      }

      WETH wethContract = WETH(payable(i_wethContractAddress));
      int256 fee = _calculateExchangeFee(totalToToken);
      uint256 amountToSend = (uint256(totalToToken).sub(uint256(fee))).mul(
        10**10
      );

      IERC20(from).transferFrom(msg.sender, address(this), amount.mul(10**18));

      wethContract.withdraw(amountToSend);

      (bool success, ) = payable(msg.sender).call{ value: amountToSend }("");

      if (!success) {
        revert DEX_anErrorOccured();
      }

      emit TokenToEthSwapSuccessfull(
        amount * 10**18,
        int256(amountToSend),
        int256(uint256(fee).mul(10**10)),
        msg.sender
      );
    }
  }

  function calculateExchangeToken(
    address from,
    address to,
    uint256 amount
  ) public view returns (int256) {
    if (from == address(0) || to == address(0)) {
      revert DEX_notValidToken(address(0));
    }
    if (amount <= 0) {
      revert DEX_notEnoughAmountProvided(msg.sender, amount);
    }
    if (!_tokenPresent(from) || !_tokenPresent(to)) {
      revert DEX_swapForTokensNotSupported(from, to);
    }
    AggregatorV3Interface fromChainlinkContract = AggregatorV3Interface(
      s_tokenUsdPricesV3contracts[from]
    );
    AggregatorV3Interface toChainlinkContract = AggregatorV3Interface(
      s_tokenUsdPricesV3contracts[to]
    );

    int256 fromPrice = _getPrice(fromChainlinkContract);
    int256 toTokenPrice = _getPrice(toChainlinkContract);
    uint256 roundFigure = 10**8;
    int256 fromPerToToken = int256(
      (uint256(fromPrice).mul(roundFigure)).div(uint256(toTokenPrice))
    );
    int256 totalToToken = fromPerToToken * int256(amount);
    return totalToToken;
  }

  function _calculateExchangeFee(int256 totalToToken)
    internal
    pure
    returns (int256)
  {
    int256 fee = int256((uint256(totalToToken).mul(30)).div(10000));
    return fee;
  }

  function calculateExchangeTokenAfterFee(
    address from,
    address to,
    uint256 amount
  ) public view returns (int256) {
    if (from == address(0) || to == address(0)) {
      revert DEX_notValidToken(address(0));
    }
    if (amount <= 0) {
      revert DEX_notEnoughAmountProvided(msg.sender, amount);
    }
    if (!_tokenPresent(from) || !_tokenPresent(to)) {
      revert DEX_swapForTokensNotSupported(from, to);
    }
    int256 totalToToken = calculateExchangeToken(from, to, amount);
    int256 fee = _calculateExchangeFee(totalToToken);
    return int256(uint256(totalToToken).sub(uint256(fee)).mul(10**10));
  }

  function _tokenPresent(address token) internal view returns (bool) {
    address[] memory tokenAddresses = s_validTokenAddresses;
    for (uint8 i = 0; i < tokenAddresses.length; i++) {
      if (token == tokenAddresses[i]) {
        return true;
      }
    }
    return false;
  }

  function removeLiquidity(uint256 poolId, address token)
    external
    nonReentrant
  {
    if (!_tokenPresent(token)) {
      revert DEX_tokenNotSupported(token);
    }

    if (poolId >= s_counter.current()) {
      revert DEX_invalidId();
    }

    pool storage _pool = s_liquidityPool[poolId];

    if (_pool.active == false) {
      revert DEX_poolNotActive();
    }

    if (_pool.owner != msg.sender) {
      revert DEX_notPoolOwner(msg.sender);
    }

    if (_pool.minLockPeriod > block.timestamp) {
      revert DEX_poolInTimeLock(_pool.minLockPeriod);
    }

    uint256 amount = _pool.amount;

    int256 tokenToRecieve = calculateExchangeToken(
      _pool.token,
      token,
      amount.div(10**18)
    );

    if (
      IERC20(token).balanceOf(address(this)) <
      uint256(tokenToRecieve).mul(10**10)
    ) {
      revert DEX_insufficientLiquidityInPool(int256(amount));
    }

    uint256 totalInterestEarned = _calculateInterest(
      tokenToRecieve,
      _pool.timestamp
    );

    uint256 tokenToReceiveWithInterest = uint256(tokenToRecieve)
      .add(totalInterestEarned)
      .mul(10**10);

    _pool.active = false;

    if (token == i_wethContractAddress) {
      WETH wethContract = WETH(payable(i_wethContractAddress));
      wethContract.withdraw(tokenToReceiveWithInterest);
      (bool success, ) = payable(msg.sender).call{
        value: tokenToReceiveWithInterest
      }("");
      if (!success) {
        revert DEX_anErrorOccured();
      }
    } else {
      IERC20(token).transfer(msg.sender, tokenToReceiveWithInterest);
    }

    emit LiquidityWithdrawSuccessfull(
      poolId,
      uint256(tokenToRecieve),
      tokenToReceiveWithInterest,
      totalInterestEarned,
      msg.sender,
      token
    );
  }

  function _calculateInterest(int256 tokens, uint256 initialTimeStamp)
    internal
    view
    returns (uint256)
  {
    uint256 secondsInYear = 31536000;
    uint256 investPeriod = block.timestamp.sub(initialTimeStamp);
    uint256 interestInOneYear = uint256(tokens).mul(RATE_0F_INTEREST_PER_ANNUM);
    uint256 totalInterestEarned = investPeriod
      .mul(interestInOneYear)
      .div(secondsInYear)
      .div(100);
    return totalInterestEarned;
  }

  //getter functions
  function checkPoolBalanceForToken(address token)
    public
    view
    returns (uint256)
  {
    if (token == address(0)) {
      revert DEX_notValidToken(token);
    }
    if (!_tokenPresent(token)) {
      revert DEX_tokenNotSupported(token);
    }
    return IERC20(token).balanceOf(address(this));
  }

  function supportedTokens() public view returns (address[] memory) {
    return s_validTokenAddresses;
  }

  function checkPoolWithId(uint256 id) public view returns (pool memory) {
    if (id >= s_counter.current()) {
      revert DEX_invalidId();
    }

    return s_liquidityPool[id];
  }

  function checkContributionIds(address contributer)
    public
    view
    returns (uint256[] memory)
  {
    return s_poolContributions[contributer];
  }

  // fallback and recieve functions
  fallback() external payable {}

  receive() external payable {}
}