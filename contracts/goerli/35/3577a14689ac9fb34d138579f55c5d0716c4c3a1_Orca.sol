/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// File: contracts/interfaces/IUniswapV2Factory.sol



pragma solidity ^0.8.6;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// File: contracts/interfaces/IUniswapV2Router.sol



pragma solidity ^0.8.6;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: contracts/libs/ERC20.sol


pragma solidity ^0.8.6;





contract ERC20 is Context, IERC20, IERC20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
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
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    return _decimals;
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
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
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

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
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

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
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

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
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
   * will be to transferred to `to`.
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
}

// File: contracts/interfaces/DividendPayingTokenInterface.sol



pragma solidity ^0.8.6;

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns (uint256);

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(address indexed from, uint256 weiAmount);

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// File: contracts/interfaces/DividendPayingTokenOptionalInterface.sol



pragma solidity ^0.8.6;

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns (uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns (uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns (uint256);
}

// File: contracts/libs/SafeMathUint.sol



pragma solidity ^0.8.6;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// File: contracts/libs/SafeMathInt.sol



/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.6;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  /**
   * @dev Multiplies two int256 variables and fails on overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;

    // Detect overflow when multiplying MIN_INT256 with -1
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  /**
   * @dev Division of two int256 variables and fails on overflow.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing MIN_INT256 by -1
    require(b != -1 || a != MIN_INT256);

    // Solidity already throws when dividing by 0.
    return a / b;
  }

  /**
   * @dev Subtracts two int256 variables and fails on overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  /**
   * @dev Adds two int256 variables and fails on overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  /**
   * @dev Converts to absolute value, and fails on overflow.
   */
  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

// File: contracts/libs/DividendPayingToken.sol


pragma solidity ^0.8.6;









/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is
  ERC20,
  Ownable,
  DividendPayingTokenInterface,
  DividendPayingTokenOptionalInterface
{
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public immutable CAKE = 0x430171391E3B027c6f73134974e30B4879f256Fa;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 internal constant magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol, _decimals) {}

  function distributeCAKEDividends(uint256 amount) public onlyOwner {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(_msgSender()));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(CAKE).transfer(user, _withdrawableDividend);

      if (!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns (uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns (uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns (uint256) {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns (uint256) {
    return
      magnifiedDividendPerShare
        .mul(balanceOf(_owner))
        .toInt256Safe()
        .add(magnifiedDividendCorrections[_owner])
        .toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub(
      (magnifiedDividendPerShare.mul(value)).toInt256Safe()
    );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add(
      (magnifiedDividendPerShare.mul(value)).toInt256Safe()
    );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if (newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if (newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// File: contracts/libs/IterableMapping.sol


pragma solidity ^0.8.6;

library IterableMapping {
  // Iterable mapping from address to uint;
  struct Map {
    address[] keys;
    mapping(address => uint256) values;
    mapping(address => uint256) indexOf;
    mapping(address => bool) inserted;
  }

  function get(Map storage map, address key) public view returns (uint256) {
    return map.values[key];
  }

  function getIndexOfKey(Map storage map, address key) public view returns (int256) {
    if (!map.inserted[key]) {
      return -1;
    }
    return int256(map.indexOf[key]);
  }

  function getKeyAtIndex(Map storage map, uint256 index) public view returns (address) {
    return map.keys[index];
  }

  function size(Map storage map) public view returns (uint256) {
    return map.keys.length;
  }

  function set(
    Map storage map,
    address key,
    uint256 val
  ) public {
    if (map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(Map storage map, address key) public {
    if (!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint256 index = map.indexOf[key];
    uint256 lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}

// File: contracts/Orca.sol


pragma solidity ^0.8.6;










contract Orca is ERC20, Ownable {
  using SafeMath for uint256;

  using EnumerableSet for EnumerableSet.AddressSet;

  struct FeeSet {
    uint256 BNBRewardsFee;
    uint256 liquidityFee;
    uint256 marketingFee;
    uint256 burnFee;
    bool inviterFee;
  }

  IUniswapV2Router02 public uniswapV2Router;
  address public immutable uniswapV2Pair;

  OrcaDividendTracker public dividendTracker;

  mapping(address => bool) public _isIgnoredAddress;

  address public marketingWallet;
  address public liquidityCollector;
  address public deadWallet = address(0x000000000000000000000000000000000000dEaD);

  // Swap and liquify active status
  bool public isSwapAndLiquifyEnabled = true;
  bool private swapping;
  uint256 public swapTokensAtAmount;

  uint256 public maxWalletAmount;

  bool public launched;

  // fees
  FeeSet public buyFees =
    FeeSet({BNBRewardsFee: 3, liquidityFee: 2, burnFee: 3, marketingFee: 4, inviterFee: true});

  FeeSet public sellFees =
    FeeSet({BNBRewardsFee: 3, liquidityFee: 2, burnFee: 3, marketingFee: 4, inviterFee: true});

  // use by default 300,000 gas to process auto-claiming dividends
  uint256 public gasForProcessing = 300000;

  // exlcude from fees and max transaction amount
  mapping(address => bool) private _isExcludedFromFees;

  // exclude from invite system
  mapping(address => bool) public _excludedFromInvite;
  mapping(address => address) public _inviter;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

  event ExcludeFromFees(address indexed account, bool isExcluded);
  event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

  event SendDividends(uint256 tokensSwapped, uint256 amount);

  event SendInviterFee(address indexed from, address indexed to, uint256 indexed amount);
  event SetInviter(address indexed invitee, address indexed inviter);

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  constructor() ERC20("Orca", "Orca", 9) {
    address deployTarget = _msgSender();
    marketingWallet = address(0x4d5149B4024e6dE73b491aed63a096FD8ccC6EF8);
    liquidityCollector = deployTarget;
    dividendTracker = new OrcaDividendTracker();

    swapTokensAtAmount = 5000000 * (10**9);
    maxWalletAmount = 100000000000 * (10**9);

//    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
//      0x323013460fbe7F66e8Ec9C8858Ed4bFfa8dc03fb
//    ); // Mainnet
      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
      ); // Testnet

    // Create a uniswap pair for this new token
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // exclude from receiving dividends
    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(address(deadWallet)); // don't want dead address to take BNB!!!
    dividendTracker.excludeFromDividends(address(_uniswapV2Router));

    // exclude from paying fees or having max transaction amount
    excludeFromFees(marketingWallet, true);
    excludeFromFees(deployTarget, true);
    excludeFromFees(address(this), true);
    excludeFromFees(address(dividendTracker), true);
    excludeFromFees(address(_uniswapV2Router), true);

    _excludedFromInvite[address(_uniswapV2Router)] = true;
    _excludedFromInvite[_uniswapV2Pair] = true;
    _excludedFromInvite[address(this)] = true;
    _excludedFromInvite[address(deadWallet)] = true;

    /*
      _mint is an internal function in ERC20.sol that is only called here,
      and CANNOT be called ever again
    */
    _mint(deployTarget, 100000000000 * (10**9));
  }

  receive() external payable {}

  function getTotalFees(FeeSet memory fees) private pure returns (uint256) {
    return fees.BNBRewardsFee.add(fees.liquidityFee);
  }

  // @dev Owner functions start -------------------------------------

  function setMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
    maxWalletAmount = newMaxWalletAmount;
  }

  function changeInviter(address account, address newInviter) external onlyOwner {
    _inviter[account] = newInviter;

    emit SetInviter(account, newInviter);
  }

  function updateLiquidityCollector(address newLiquidityCollector) external onlyOwner {
    liquidityCollector = newLiquidityCollector;
  }

  // change the minimum amount of tokens to sell from fees
  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
    require(newAmount < totalSupply(), "Swap amount cannot be higher than total supply.");
    swapTokensAtAmount = newAmount;
    return true;
  }

  // migration feature (DO NOT CHANGE WITHOUT CONSULTATION)
  function updateDividendTracker(address newAddress) public onlyOwner {
    require(
      newAddress != address(dividendTracker),
      "Orca: The dividend tracker already has that address"
    );

    OrcaDividendTracker newDividendTracker = OrcaDividendTracker(payable(newAddress));

    require(
      newDividendTracker.owner() == address(this),
      "Orca: The new dividend tracker must be owned by the Orca token contract"
    );

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    newDividendTracker.excludeFromDividends(address(uniswapV2Router));

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  // updates the default router for selling tokens
  function updateUniswapV2Router(address newAddress) external onlyOwner {
    require(newAddress != address(uniswapV2Router), "Orca: The router already has that address");
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }

  // excludes wallets from max txn and fees.
  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  // allows multiple exclusions at once
  function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      _isExcludedFromFees[accounts[i]] = excluded;
    }

    emit ExcludeMultipleAccountsFromFees(accounts, excluded);
  }

  function setIsBot(address wallet, bool status) external onlyOwner {
    _isIgnoredAddress[wallet] = status;
  }

  function setSwapAndLiquifyEnabled(bool value) external onlyOwner {
    isSwapAndLiquifyEnabled = value;
  }

  // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
  function excludeFromDividends(address account) external onlyOwner {
    dividendTracker.excludeFromDividends(account);
  }

  // allow adding additional AMM pairs to the list
  function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
    require(
      pair != uniswapV2Pair,
      "Orca: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
    );

    _setAutomatedMarketMakerPair(pair, value);
  }

  function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
    require(
      newMarketingWallet != marketingWallet,
      "Orca: The marketing wallet is already this address"
    );
    excludeFromFees(newMarketingWallet, true);
    marketingWallet = newMarketingWallet;
  }

  // rebalance fees as needed
  function updateFees(
    uint256 bnbRewardPerc,
    uint256 liquidityPerc,
    uint256 marketingPerc,
    uint256 burnPerc,
    bool inviterFee
  ) external onlyOwner {
    buyFees.BNBRewardsFee = bnbRewardPerc;
    sellFees.BNBRewardsFee = bnbRewardPerc;

    buyFees.liquidityFee = liquidityPerc;
    sellFees.liquidityFee = liquidityPerc;

    buyFees.marketingFee = marketingPerc;
    sellFees.marketingFee = marketingPerc;

    buyFees.burnFee = burnPerc;
    sellFees.burnFee = burnPerc;

    buyFees.inviterFee = inviterFee;
    sellFees.inviterFee = inviterFee;
  }

  // changes the gas reserve for processing dividend distribution
  function updateGasForProcessing(uint256 newValue) external onlyOwner {
    require(
      newValue >= 200000 && newValue <= 500000,
      "Orca: gasForProcessing must be between 200,000 and 500,000"
    );
    require(newValue != gasForProcessing, "Orca: Cannot update gasForProcessing to same value");
    emit GasForProcessingUpdated(newValue, gasForProcessing);
    gasForProcessing = newValue;
  }

  // changes the amount of time to wait for claims (1-24 hours, expressed in seconds)
  function updateClaimWait(uint256 claimWait) external onlyOwner returns (bool) {
    dividendTracker.updateClaimWait(claimWait);
    return true;
  }

  // @dev Views start here ------------------------------------

  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return dividendTracker.getLastProcessedIndex();
  }

  function getNumberOfDividendTokenHolders() external view returns (uint256) {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function getDividendTokensMinimum() external view returns (uint256) {
    return dividendTracker.minimumTokenBalanceForDividends();
  }

  function getClaimWait() external view returns (uint256) {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed() external view returns (uint256) {
    return dividendTracker.totalDividendsDistributed();
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function withdrawableDividendOf(address account) public view returns (uint256) {
    return dividendTracker.withdrawableDividendOf(account);
  }

  function dividendTokenBalanceOf(address account) public view returns (uint256) {
    return dividendTracker.balanceOf(account);
  }

  function getAccountDividendsInfo(address account)
    external
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccount(account);
  }

  function getAccountDividendsInfoAtIndex(uint256 index)
    external
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccountAtIndex(index);
  }

  function getDividends(address holder) public view returns (uint256) {
    return dividendTracker.dividendOf(holder);
  }

  function currentBuyFee() public view returns (uint256) {
    return buyFees.BNBRewardsFee.add(buyFees.liquidityFee).add(buyFees.marketingFee);
  }

  function currentSellFee() public view returns (uint256) {
    return sellFees.BNBRewardsFee.add(sellFees.liquidityFee).add(sellFees.marketingFee);
  }

  // @dev User Callable Functions start here! ---------------------------------------------

  // allows a user to manually claim their tokens.
  function claim() external {
    dividendTracker.processAccount(payable(msg.sender), false);
  }

  // allow a user to manuall process dividends.
  function processDividendTracker(uint256 gas) external {
    (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
    emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
  }

  // @dev Token functions

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(
      automatedMarketMakerPairs[pair] != value,
      "Orca: Automated market maker pair is already set to that value"
    );
    automatedMarketMakerPairs[pair] = value;

    if (value) {
      dividendTracker.excludeFromDividends(pair);
    }
    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(!_isIgnoredAddress[from], "Orca: you are banned");

    // early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    bool shouldSetInviter = balanceOf(to) == 0 &&
      !_excludedFromInvite[from] &&
      !_excludedFromInvite[to] &&
      _inviter[to] == address(0);

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      launched &&
      !swapping &&
      isSwapAndLiquifyEnabled &&
      !automatedMarketMakerPairs[from] &&
      !_isExcludedFromFees[to] &&
      !_isExcludedFromFees[from]
    ) {
      swapping = true;

      uint256 liquifyTokens = contractTokenBalance.mul(buyFees.liquidityFee).div(
        buyFees.BNBRewardsFee.add(buyFees.liquidityFee).add(buyFees.marketingFee)
      );
      uint256 otherTokens = contractTokenBalance.sub(liquifyTokens);

      swapAndLiquify(liquifyTokens);
      swapAndOthers(otherTokens);

      swapping = false;
    }

    bool takeFee = !swapping;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (
      _isExcludedFromFees[from] || _isExcludedFromFees[to] || from == address(this) || !launched
    ) {
      takeFee = false;
    }

    if (takeFee) {
      uint256 fees = amount
        .mul(automatedMarketMakerPairs[to] ? currentSellFee() : currentBuyFee())
        .div(100);

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }

      uint256 burnFee = amount
        .mul(automatedMarketMakerPairs[to] ? sellFees.burnFee : buyFees.burnFee)
        .div(100);

      if (burnFee > 0) {
        super._transfer(from, address(0x000000000000000000000000000000000000dEaD), burnFee);
      }

      uint256 inviteFee = _takeInvite(from, to, amount);

      amount = amount.sub(fees).sub(burnFee).sub(inviteFee);
    }

    if (!launched && to == uniswapV2Pair) {
      launched = true;
    }

    super._transfer(from, to, amount);
    if (to != uniswapV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
      require(balanceOf(to) <= maxWalletAmount, "Orca: you are owning too many tokens.");
    }

    if (shouldSetInviter) {
      _inviter[to] = from;

      emit SetInviter(to, from);
    }

    try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

    if (!swapping) {
      uint256 gas = gasForProcessing;

      try dividendTracker.process(gas) returns (
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
      ) {
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
      } catch {}
    }
  }

  function _takeInvite(
    address sender,
    address recipient,
    uint256 amount
  ) private returns (uint256) {
    if (!buyFees.inviterFee) return 0;

    address inviter;
    uint256 totalInviteFee;
    if (sender == uniswapV2Pair) {
      inviter = recipient;
    } else if (recipient == uniswapV2Pair) {
      inviter = sender;
    }
    if (inviter == address(0)) {
      return 0;
    }

    for (int256 i = 0; i < 2; i++) {
      uint256 fee = 1;
      inviter = _inviter[inviter];
      if (inviter == address(0)) {
        break;
      }

      uint256 inviteFee = amount.mul(fee).div(100);
      super._transfer(sender, inviter, inviteFee);
      emit SendInviterFee(sender, inviter, inviteFee);

      totalInviteFee = totalInviteFee.add(inviteFee);
    }

    return totalInviteFee;
  }

  function swapAndLiquify(uint256 tokens) private {
    // split the contract balance into halves
    uint256 half = tokens.div(2);
    uint256 otherHalf = tokens.sub(half);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      liquidityCollector,
      block.timestamp
    );
  }

  function swapAndOthers(uint256 tokens) private {
    uint256 totalPerc = buyFees.BNBRewardsFee.add(buyFees.marketingFee);
    swapTokensForEth(tokens);

    uint256 etherForDividends = address(this).balance.mul(buyFees.BNBRewardsFee).div(totalPerc);
    uint256 etherForMarketing = address(this).balance.sub(etherForDividends);
    uint256 dividends = address(this).balance;

    bool success;
    (success, ) = address(dividendTracker).call{value: etherForDividends}("");

    if (success) {
      emit SendDividends(tokens, dividends);
    }

    (success, ) = address(marketingWallet).call{value: etherForMarketing}("");
    require(success, "Orca: unable to do marketing.");
  }

  function recoverContractBNB(uint256 recoverRate) public onlyOwner {
    uint256 bnbAmount = address(this).balance;
    if (bnbAmount > 0) {
      (bool success, ) = owner().call{value: bnbAmount.mul(recoverRate).div(100)}("");
      require(success, "Orca: unable to recover BNB.");
    }
  }
}

contract OrcaDividendTracker is Ownable, DividendPayingToken {
  using SafeMath for uint256;
  using SafeMathInt for int256;
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;
  uint256 public lastProcessedIndex;

  mapping(address => bool) public excludedFromDividends;

  mapping(address => uint256) public lastClaimTimes;

  uint256 public claimWait = 3600;
  uint256 public immutable minimumTokenBalanceForDividends = 1000 * (10**9);

  event ExcludeFromDividends(address indexed account);
  event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

  event Claim(address indexed account, uint256 amount, bool indexed automatic);

  constructor() DividendPayingToken("Orca_Dividend_Tracker", "Orca_Dividend_Tracker", 9) {}

  function _transfer(
    address,
    address,
    uint256
  ) internal pure override {
    require(false, "Orca_Dividend_Tracker: No transfers allowed");
  }

  function withdrawDividend() public pure override {
    require(
      false,
      "Orca_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Orca contract."
    );
  }

  function excludeFromDividends(address account) external onlyOwner {
    require(!excludedFromDividends[account]);
    excludedFromDividends[account] = true;

    _setBalance(account, 0);
    tokenHoldersMap.remove(account);

    emit ExcludeFromDividends(account);
  }

  function updateClaimWait(uint256 newClaimWait) external onlyOwner {
    require(
      newClaimWait >= 3600 && newClaimWait <= 86400,
      "Orca_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
    );
    require(
      newClaimWait != claimWait,
      "Orca_Dividend_Tracker: Cannot update claimWait to same value"
    );
    emit ClaimWaitUpdated(newClaimWait, claimWait);
    claimWait = newClaimWait;
  }

  function getLastProcessedIndex() external view returns (uint256) {
    return lastProcessedIndex;
  }

  function getNumberOfTokenHolders() external view returns (uint256) {
    return tokenHoldersMap.keys.length;
  }

  function getAccount(address _account)
    public
    view
    returns (
      address account,
      int256 index,
      int256 iterationsUntilProcessed,
      uint256 withdrawableDividends,
      uint256 totalDividends,
      uint256 lastClaimTime,
      uint256 nextClaimTime,
      uint256 secondsUntilAutoClaimAvailable
    )
  {
    account = _account;

    index = tokenHoldersMap.getIndexOfKey(account);

    iterationsUntilProcessed = -1;

    if (index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex
          ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
          : 0;
        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);

    lastClaimTime = lastClaimTimes[account];

    nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
      ? nextClaimTime.sub(block.timestamp)
      : 0;
  }

  function getAccountAtIndex(uint256 index)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if (index >= tokenHoldersMap.size()) {
      return (address(0), -1, -1, 0, 0, 0, 0, 0);
    }

    return getAccount(tokenHoldersMap.getKeyAtIndex(index));
  }

  function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) {
      return false;
    }

    return block.timestamp.sub(lastClaimTime) >= claimWait;
  }

  function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    if (excludedFromDividends[account]) {
      return;
    }

    if (newBalance >= minimumTokenBalanceForDividends) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(account, true);
  }

  function process(uint256 gas)
    public
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if (numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;

    uint256 gasUsed = 0;

    uint256 gasLeft = gasleft();

    uint256 iterations = 0;
    uint256 claims = 0;

    while (gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;

      if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if (canAutoClaim(lastClaimTimes[account])) {
        if (processAccount(payable(account), true)) {
          claims++;
        }
      }

      iterations++;

      uint256 newGasLeft = gasleft();

      if (gasLeft > newGasLeft) {
        gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
    uint256 amount = _withdrawDividendOfUser(account);

    if (amount > 0) {
      lastClaimTimes[account] = block.timestamp;
      emit Claim(account, amount, automatic);
      return true;
    }

    return false;
  }
}