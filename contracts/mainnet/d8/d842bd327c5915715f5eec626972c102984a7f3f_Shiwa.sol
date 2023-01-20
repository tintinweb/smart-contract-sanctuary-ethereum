/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: @utils/math/SafeMathUint.sol



pragma solidity ^0.8.1;

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

// File: @utils/math/SafeMathInt.sol



pragma solidity ^0.8.1;

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

// File: @uniswap/interfaces/IUniswapV2Pair.sol

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
// File: @uniswap/interfaces/IUniswapV2Factory.sol

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
// File: @uniswap/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;



interface IUniswapV2Router01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);



    function addLiquidity(

        address tokenA,

        address tokenB,

        uint amountADesired,

        uint amountBDesired,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(

        address token,

        uint amountTokenDesired,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(

        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(

        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(

        uint amountOut,

        uint amountInMax,

        address[] calldata path,

        address to,

        uint deadline

    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        external

        payable

        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)

        external

        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)

        external

        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)

        external

        payable

        returns (uint[] memory amounts);



    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}
// File: @uniswap/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;




interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,

        uint liquidity,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline,

        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountETH);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

}
// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol



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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: Shiwa.sol

/*

     _______. __    __   __  ____    __    ____  ___  V2    

    /       ||  |  |  | |  | \   \  /  \  /   / /   \     

   |   (----`|  |__|  | |  |  \   \/    \/   / /  ^  \    

    \   \    |   __   | |  |   \            / /  /_\  \   

.----)   |   |  |  |  | |  |    \    /\    / /  _____  \  

|_______/    |__|  |__| |__|     \__/  \__/ /__/     \__\ 

                   The King is Back 



-Website: https://shiwa.finance

-Telegram: https://t.me/shiwaportal

-Telegram announcements: https://t.me/shiwaAnnouncements

-Twitter: https://twitter.com/shiwa_finance

-Facebook: https://www.facebook.com/OFFICIALSHIWA/

-Github: https://github.com/Shiwa-Finance

-OpenSea: https://opensea.io/ShiwaOfficial



SHIWA is a true decentralized utility meme token. Our mission is to empower the community via the Dao Governance,

We are a constantly evolving decentralised ecosystem that puts its destiny in the hands of its holders. 

SHIWA is a token that combines the power of a Wolf meme with real utility in the blockchain, including NFT Collections,

Web3 Marketplace & DAO Governance utility. Our goal is a honourable one, we want to improve transparency, honour,

trust & success in the cryptocurrency industry thus making SHIWA a safe haven for all our investors!



Shiwa Version II go live at 20/01/22 18:00 UTC

Visit our website to migrate from Shiwa version 1 to Shiwa version 2.



The King of the both Ethereums is back, renewed and more KING than ever!

Shiwa V2 is the first contract on the entire blockchain to deliver dynamic rewards to all holders that

will be voted in our DAO. The token of the moment will be in your wallet just for holding Shiwa!

*/


pragma solidity ^0.8.9;











contract Shiwa is ERC20, Ownable {

    using SafeMathUint for uint256;

    using SafeMathInt for int256;

    using EnumerableSet for EnumerableSet.AddressSet;



    mapping(address => bool) public isExcludedFromFees;

    mapping(address => bool) public isExemptedFromHeld;

    mapping(address => bool) public isExcludedFromReward;

    address[] public ExclusionRewardList;

    uint256 constant private MAGNITUDE = 2**165;

    mapping(address => uint256) private magnifiedDividendPerShareMap; //token=>amount

    mapping(address => mapping(address => int256)) private magnifiedDividendCorrectionsMap; //token=>user=>amount

    mapping(address => mapping(address => uint256)) private withdrawnDividendsMap; //token=>user=>amount

    mapping(address => bool) public pairMap;

    EnumerableSet.AddressSet private _dividendTokenSet; //div-addressSet



    uint256 public currentTXCount;

    uint256 public SWAP_MIN_TOKEN = 1000000000000000000000;

    uint256 public SWAP_MIN_TX = 20;

    bool public SHOULD_SWAP = true;

    bool public TAKE_FEE = true;

    uint256 public MAX_RATIO = 500; //5% of total supply() at the time of tx

    uint256 public BUY_TX_FEE = 700; //7% Max fee allowed

    uint256 public SELL_TX_FEE = 700; //7% Max fee allowed

    uint256 public USUAL_TX_FEE = 700; //7% Max fee allowed

    uint256 public MARK_FEE = 9000;

    uint256 public DEV_FEE = 100;

    uint256 public LPR_FEE = 1000;

    uint256 public swapTokensAmount; //total tokens to be swapped

    address public currentRewardToken;

    uint256 private constant maxTokenLen = 5; //max dividend tokens

    //Fee in basis points (BP) 1%=100 points, min 0.1% = 10bp

    //amount.mul(fee).div(10000::10k) := fee

    //amount.sub(fee) = rest

    uint256 private constant BASE_DIVIDER = 10000; // constant 100%

    uint256 private constant MIN_DIVIDER = 100; // constant min 1%

    address payable private constant BURN_WALLET = payable(0x000000000000000000000000000000000000dEaD);

    address payable public MARK_WALLET = payable(0x9D38F6581Cb7635CD5bf031Af1E1635b42db74fe);

    address payable public DEV_WALLET = payable(0x9D38F6581Cb7635CD5bf031Af1E1635b42db74fe);



    IUniswapV2Router02 public UniswapV2Router;

    address public uniswapV2Pair;



    event DividendsDistributed(

        address token,

        uint256 weiAmount

    );

    event DividendWithdrawn(

        address to,

        address token,

        uint256 weiAmount

    );



    receive() external payable {}



    constructor(address router) ERC20("Shiwa", "SHIWA") {

        uint256 amount = (1000000000000000 * 10 ** decimals());

        _mint(_msgSender(), amount);

        UniswapV2Router = IUniswapV2Router02(router);

        _initPairCreationHook();

        isExcludedFromFees[_msgSender()] = true;

        isExcludedFromFees[MARK_WALLET] = true;

        isExcludedFromFees[DEV_WALLET] = true;

        isExcludedFromFees[BURN_WALLET] = true;

        isExcludedFromFees[address(0)] = true;

        isExcludedFromFees[address(this)] = true;

        isExemptedFromHeld[router] = true;

        isExcludedFromReward[_msgSender()] = true;

        ExclusionRewardList.push(_msgSender());

        pairMap[router] = true;

        _dividendTokenSet.add(address(this));

        currentRewardToken = address(this);

    }



    /**

     * liquid guard for potential <SWC-107>.

     */

    bool public isNowLiquid;



    /**

     * @dev get total token supply - excluded

     * @notice extension of the following implementations for Dividends:

     * https://github.com/ethereum/EIPs/issues/1726

     * https://github.com/Roger-Wu/erc1726-dividend-paying-token/blob/master/contracts

     * https://github.com/Alexander-Herranz/ERC20DividendPayingToken

     * deduct the supply from excluded reward since those will be distributed.

     */

    function getReducedSupply() public view returns(uint256) {

        uint256 deductSupply = 0;

        uint256 eLen = ExclusionRewardList.length;

        if (eLen > 0) {

            for (uint256 i = 0; i < eLen; i++) {

                deductSupply += balanceOf(ExclusionRewardList[i]);

            }

        }

        deductSupply += balanceOf(BURN_WALLET) + 

                        balanceOf(address(0)) + 

                        balanceOf(address(this)) + 

                        balanceOf(address(UniswapV2Router));

        uint256 supply = totalSupply();

        uint256 netSupply = (supply - deductSupply) == 0 ? (1000 * 10 ** decimals()) : (supply - deductSupply);

        return netSupply;

    }



    /**

     * @dev See {IERC20-transfer}.

     *

     * Requirements:

     *

     * - `to` cannot be the zero address.

     * - the caller must have a balance of at least `amount`.

     */

    function transfer(address to, uint256 amount) public override(ERC20) returns (bool) {

        address owner = _msgSender();

        _preTransferHook(owner, to, amount);

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

    ) public override(ERC20) returns (bool) {

        address spender = _msgSender();

        _spendAllowance(from, spender, amount);

        _preTransferHook(from, to, amount);

        return true;

    }



    /**

     * @dev handles token liquidity and distributions

     * - swap fees to ETH

     * - provide liquidity

     * - distribute tokens

     * - doesn't revert on failure <SWC-113>.

     */

    function liquidSwapProvider(uint256 tokens) private returns (bool) {

        if (isNowLiquid == false) {

            isNowLiquid = true;

            uint256 prevTokens = balanceOf(address(this));

            uint256 lprTokens = (tokens * LPR_FEE) / BASE_DIVIDER;

            uint256 tokensToSwap = tokens - lprTokens;



            if (currentRewardToken == address(this)) { //this_token

                //distribute rewards

                uint256 splitTokens = tokensToSwap / 2;

                _selfDistributeDividends(currentRewardToken, splitTokens);

                tokensToSwap -= splitTokens;

            }



            uint256 prevRewardBal = IERC20(currentRewardToken).balanceOf(address(this));

            _SwapDefinitionHook(tokensToSwap,currentRewardToken);



            if (currentRewardToken != address(this)) { //different_token

                uint256 currentRewardBal = IERC20(currentRewardToken).balanceOf(address(this));

                uint256 rewardBal = currentRewardBal != 0 && prevRewardBal != 0 ? currentRewardBal - prevRewardBal : 0;



                if (rewardBal > 0) {

                    //distribute rewards

                    _selfDistributeDividends(currentRewardToken, rewardBal);

                }

            }



            uint256 contractETHBalance = address(this).balance;

            if (contractETHBalance > 0) {

                uint256 splitMarkTokens = (contractETHBalance * MARK_FEE) / BASE_DIVIDER;

                uint256 splitDevTokens = (contractETHBalance * DEV_FEE) / BASE_DIVIDER;

                uint256 splitLprTokens = (contractETHBalance * LPR_FEE) / BASE_DIVIDER;



                if (lprTokens > 0 && splitLprTokens > 0) {

                    addLiquidity(lprTokens, splitLprTokens);

                }



                _sendValueHook(MARK_WALLET, splitMarkTokens);

                _sendValueHook(DEV_WALLET, splitDevTokens);

            }



            uint256 currentTokens = balanceOf(address(this));

            if (currentTokens < prevTokens) {

                swapTokensAmount = 0;

            }



            isNowLiquid = false;

            return true;

        } else {

            return false;

        }

    }



    /**

     * @dev swap fee tokens to ETH

     * doesn't revert on failure <SWC-113>.

     */

    function _ethSwapHook(uint256 tokenAmount) private returns (bool) {

        bool isSuccess = false;

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = UniswapV2Router.WETH();

        _approve(address(this), address(UniswapV2Router), tokenAmount);



        try UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(

            tokenAmount,

            0,

            path,

            address(this),

            block.timestamp

        ) {

            isSuccess = true;

        } catch Error(string memory /*reason*/) {

            isSuccess = false;

        } catch (bytes memory /*lowLevelData*/) {

            isSuccess = false;

        }

        return isSuccess;

    }



    /**

     * @dev swap ETH fee to tokens

     * doesn't revert on failure <SWC-113>.

     */

    function _tokenSwapHook(uint256 ethAmount, address token) private returns (bool) {

        bool isSuccess = false;

        address[] memory path = new address[](2);

        path[0] = UniswapV2Router.WETH();

        path[1] = token;



        try UniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(

            0, 

            path, 

            address(this), 

            block.timestamp

        ) {

            isSuccess = true;

        } catch Error(string memory /*reason*/) {

            isSuccess = false;

        } catch (bytes memory /*lowLevelData*/) {

            isSuccess = false;

        }

        return isSuccess;

    }



    /**

     * @dev _SwapDefinitionHook handle token swaps

     */

    function _SwapDefinitionHook(uint256 tokenAmount, address token) private {

        if (tokenAmount > 0) {

            if (token == address(this)) {

                _ethSwapHook(tokenAmount);

            } else {

                _ethSwapHook(tokenAmount);

                uint256 contractETHBalance = address(this).balance;

                uint256 splitTokens = contractETHBalance / 2;

                if (splitTokens > 0) {

                    _tokenSwapHook(splitTokens, token);

                }

            }

        }

    }



    /**

     * @dev add liquidity to pair

     * doesn't revert on failure <SWC-113>.

     */

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private returns (bool) {

        if (tokenAmount > 0 && ETHAmount > 0) {

            bool isSuccess = false;

            _approve(address(this), address(UniswapV2Router), tokenAmount);



            try UniswapV2Router.addLiquidityETH{value: ETHAmount}(

                address(this),

                tokenAmount,

                0,

                0,

                BURN_WALLET,

                block.timestamp

            ) {

                isSuccess = true;

            } catch Error(string memory /*reason*/) {

                isSuccess = false;

            } catch (bytes memory /*lowLevelData*/) {

                isSuccess = false;

            }

            return isSuccess;

        } else {

            return false;

        }

    }



    /**

     * @dev set minimum amount of tokens before the `liquidSwapProvider` is called.

     */

    function setSwapMinToken(uint256 amount) public onlyOwner {

        require(amount > 0,"ERC20: amount is zero");

        SWAP_MIN_TOKEN = amount;

    }



    /**

     * @dev set whether there should be fees on transactions.

     */

    function setFeeStatus(bool state) public onlyOwner {

        TAKE_FEE = state;

    }



    /**

     * @dev set isNowLiquid for liquidSwapProvider.

     */

    function setIsNowLiquid(bool state) public onlyOwner {

        isNowLiquid = state;

    }



    /**

     * @dev set minimum tx count for liquidSwapProvider.

     */

    function setMinTX(uint256 count) public onlyOwner {

        SWAP_MIN_TX = count;

    }



    /**

     * @dev set current tx count for liquidSwapProvider.

     */

    function setTXCount(uint256 count) public onlyOwner {

        currentTXCount = count;

    }



    /**

     * @dev set whether `liquidSwapProvider` should be called if the requirements are met.

     */

    function setSwapStatus(bool state) public onlyOwner {

        SHOULD_SWAP = state;

    }



    /**

     * @dev set maximum percentage of tokens one wallet can have.

     */

    function setMaxRatio(uint256 ratio) public onlyOwner {

        require((ratio >= MIN_DIVIDER) && (ratio <= BASE_DIVIDER), "ERC20: ratio is zero");

        MAX_RATIO = ratio;

    }



    /**

     * @dev exempt wallet from maximum held limit such is UniswapV2Pair.

     */

    function setExemptHeldList(address[] memory wallets, bool state) public onlyOwner {

        uint256 len = wallets.length;



        for (uint256 i = 0; i < len; i++) {

            isExemptedFromHeld[wallets[i]] = state;

        }

    }



    /**

     * @dev set transaction fee.

     */

    function setTXFee(

        uint256 buyFee,

        uint256 sellFee,

        uint256 usualFee

    ) public onlyOwner {

        require(buyFee <= 700 && sellFee <= 700 && usualFee <= 700, "ERC20: amount exceeds maximum allowed");

        BUY_TX_FEE = buyFee;

        SELL_TX_FEE = sellFee;

        USUAL_TX_FEE = usualFee;

    }



    /**

     * @dev set provider fees.

     */

    function setProviderFee(

        uint256[] memory fees

    ) public onlyOwner {

        uint256 totalFees;

        uint256 len = 4;



        for (uint256 i = 0; i < len; i++) {

            totalFees += fees[i];

        }

        require(totalFees == BASE_DIVIDER, "ERC20: fee is out of scope");



        MARK_FEE = fees[0];

        DEV_FEE = fees[1];

        LPR_FEE = fees[2];

    }



    /**

     * @dev set pair maps for uniswap router or pair.

     */

    function setPairMapList(address[] memory pairs, bool state) public onlyOwner {

        uint256 len = pairs.length;



        for (uint256 i = 0; i < len; i++) {

            address pair = pairs[i];

            if (pair != uniswapV2Pair && pair != address(UniswapV2Router)) {

                pairMap[pair] = state;

            }

        }

    }



    /**

     * @dev set fee wallet for inclusion or exclusion of fees.

     */

    function setFeeWalletList(address[] memory wallets, bool state) public onlyOwner {

        _feeWalletHook(wallets, state);

    }



    /**

     * @dev set provider wallets.

     */

    function setProviderWallets(address payable markWallet, address payable devWallet) public onlyOwner {

        require(_walletVerifyHook(MARK_WALLET) && _walletVerifyHook(DEV_WALLET), "ERC20: wallet not allowed");

        MARK_WALLET = markWallet;

        DEV_WALLET = devWallet;

        address[] memory wallets = new address[](2);

        wallets[0] = markWallet;

        wallets[1] = devWallet;

        _feeWalletHook(wallets, true);

    }



    /**

     * @dev _feeWalletHook to include or exclude wallets for fees.

     */

    function _feeWalletHook(address[] memory wallets, bool state) private {

        uint256 len = wallets.length;



        for (uint256 i = 0; i < len; i++) {

            address wallet = wallets[i];

            isExcludedFromFees[wallet] = state;

        }

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public override(Ownable) onlyOwner {

        require(_walletVerifyHook(newOwner), "Ownable: new owner is the zero address");

        _transferOwnership(newOwner);

    }



    /**

     * @dev overrides the `renounceOwnership`.

     */

    function renounceOwnership() public override(Ownable) onlyOwner {

        _transferOwnership(owner());

    }



    /// @notice Distributes ether to token holders as dividends.

    /// @dev It reverts if the total supply of tokens is 0.

    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.

    /// About undistributed ether:

    ///   In each distribution, there is a small amount of ether not distributed,

    ///     the magnified amount of which is

    ///     `(msg.value * magnitude) % totalSupply()`. or

    ///     `(token * magnitude) % totalSupply()`

    ///   With a well-chosen `magnitude`, the amount of undistributed ether

    ///     (de-magnified) in a distribution can be less than 1 wei.

    ///   We can actually keep track of the undistributed ether in a distribution

    ///     and try to distribute it in the next distribution,

    ///     but keeping track of such data on-chain costs much more than

    ///     the saved ether, so we don't do that.

    function distributeDividends(address token, uint256 dividendTokenAmount) public onlyOwner {

        require(_dividendTokenSet.contains(token), "ERC20: invalid token");

        require(getReducedSupply() > 0 && dividendTokenAmount > 0, "ERC20: zero value transfer");

        if (token == address(this)) {

            _transfer(_msgSender(), address(this), dividendTokenAmount);

        } else {

            IERC20(token).transferFrom(_msgSender(), address(this), dividendTokenAmount);

        }

        _selfDistributeDividends(token, dividendTokenAmount);

    }



    /**

     * @dev set current reward token for dividends.

     */

    function setCurrentRewardToken(address token) public onlyOwner {

        require(_dividendTokenSet.contains(token) || _dividendTokenSet.length() <= maxTokenLen, "ERC20: token not found reached maxLen");

        if (!_dividendTokenSet.contains(token)) {

            _dividendTokenSet.add(token);

        }

        currentRewardToken = token;

    }



    /**

     * @dev recover ERC20 tokens.

     */

    function recoverERC20(address token, uint256 amount) public onlyOwner {

        IERC20(token).transfer(_msgSender(), amount);

    }



    /**

     * @dev _preTransferHook: used for pre_transfer actions.

     */

    function _preTransferHook(

        address from, 

        address to, 

        uint256 amount

    ) private returns (bool) {

        require(amount > 0, "ERC20: transfer amount is zero");

        require(from != address(0) && to != address(0), "ERC20: transfer address is zero");

        uint256 actualAmount = amount;

        //anyone who's excludedFromFees = no held limit

        //anyone who's exemptedFromHeld = no held limit

        //no exclusion on router as I see

        //no exclusion on pair (should be exempted) && router?

        if (!isExcludedFromFees[to] && !isExemptedFromHeld[to]) {

            //not excluded or exempted

            require((balanceOf(to) + amount) <= ((totalSupply() * MAX_RATIO) / BASE_DIVIDER), "ERC20: exceeds max holding");

        }



        if (!pairMap[from]) {

            //not a uniswap pair

            _swapProviderHook(); //performs swap and dist if needed

        }



        if (TAKE_FEE && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {

            //take fee

            uint256 feeAmount;

            if (pairMap[from]) {

                //@isBuy=true

                feeAmount = (amount * BUY_TX_FEE) / BASE_DIVIDER;

            } else if (pairMap[to]) {

                //@isSell=true

                feeAmount = (amount * SELL_TX_FEE) / BASE_DIVIDER;

            }

            else {

                //@isUsual=true

                feeAmount = (amount * USUAL_TX_FEE) / BASE_DIVIDER;

            }

            amount = amount - feeAmount;

            _transfer(from, address(this), feeAmount);

            swapTokensAmount += feeAmount;

        }

        _transfer(from, to, amount); //ordinary transfer

        _postTransferHook(from, to, actualAmount);

        currentTXCount++;

        return true;

    }



    /**

     * @dev _postTransferHook for handling dividends.

     */

    function _postTransferHook(address from, address to, uint256 value) private {

        if (!isExcludedFromReward[from]) {

            _multiTransferHook(from, to, value); //usual correction

        }

    }



    /**

     * @dev _multiTransferHook for handling postTransfer dividends.

     */

    function _multiTransferHook(address from, address to, uint256 value) private {

        address[] memory tokenArray = getDividendTokenList();

        uint256 len = tokenArray.length;



        for (uint256 i = 0; i < len; i++) {

            address token = tokenArray[i];

            int256 _magCorrection = (magnifiedDividendPerShareMap[token] * value).toInt256Safe();

            magnifiedDividendCorrectionsMap[token][from] = magnifiedDividendCorrectionsMap[token][from].add(_magCorrection);

            magnifiedDividendCorrectionsMap[token][to] = magnifiedDividendCorrectionsMap[token][to].sub(_magCorrection);

        }

    }



    /**

     * @dev _initPairCreationHook: create UniswapV2Pair for <Native>:<WETH>.

     */

    function _initPairCreationHook() private returns (bool) {

        uniswapV2Pair = IUniswapV2Factory(UniswapV2Router.factory()).createPair(

            address(this), 

            UniswapV2Router.WETH()

        );

        isExemptedFromHeld[uniswapV2Pair] = true;

        pairMap[uniswapV2Pair] = true;

        return true;

    }



    /**

     * @dev _sendValueHook: doesn't revert on failed ether transfer <SWC-113>.

     */

    function _sendValueHook(address payable recipient, uint256 amount) private returns (bool) {

        bool success = false;

        if (_walletVerifyHook(recipient) && amount > 0) {

            (success, ) = recipient.call{value: amount, gas: 5000}("");

        }

        return success;

    }



    /**

     * @dev _walletVerifyHook: check for potential invalid address.

     */

    function _walletVerifyHook(address wallet) private view returns (bool) {

        return wallet != address(0) &&

               wallet != address(BURN_WALLET) &&

               wallet != address(this) &&

               wallet != address(UniswapV2Router);

    }



    /**

     * @dev _swapProviderHook: check for swap requirements.

     */

    function _swapProviderHook() private returns (bool) {

        if (SHOULD_SWAP && currentTXCount >= SWAP_MIN_TX && swapTokensAmount >= SWAP_MIN_TOKEN) {

            liquidSwapProvider(swapTokensAmount);

        }

        return true;

    }



    /**

     * @dev exclude wallets such as initial from acquiring fees.

     */

    function excludeRewardWallet(address wallet) public onlyOwner {

        if (!isExcludedFromReward[wallet]) {

            isExcludedFromReward[wallet] = true;

            ExclusionRewardList.push(wallet);

        }

    }



    /// @dev internal distributeDividend tokens.

    function _selfDistributeDividends(address token, uint256 dividendTokenAmount) private {

        magnifiedDividendPerShareMap[token] = magnifiedDividendPerShareMap[token] + (

            (dividendTokenAmount) * (MAGNITUDE) / getReducedSupply()        

        );

        emit DividendsDistributed(token, dividendTokenAmount);

    }



    /// @notice Withdraws the ether distributed to the sender.

    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.

    function withdrawDividend(address token) public {

        require(!isExcludedFromReward[_msgSender()], "ERC20: excluded from reward");

        require(_dividendTokenSet.contains(token), "ERC20: invalid token");

        uint256 _withdrawableDividend = withdrawableDividendOf(_msgSender(), token);



        if (_withdrawableDividend > 0) {

            withdrawnDividendsMap[token][_msgSender()] = withdrawnDividendsMap[token][_msgSender()] + (_withdrawableDividend);

            emit DividendWithdrawn(_msgSender(), token, _withdrawableDividend);

            if (token == address(this)) {

                _transfer(address(this), _msgSender(), _withdrawableDividend);

            } else {

                IERC20(token).transfer(_msgSender(), _withdrawableDividend);

            }

        }

    }



    /// @dev get dividend token list

    function getDividendTokenList() public view returns (address[] memory) {

        uint256 len = _dividendTokenSet.length();

        address[] memory tokenArray = new address[](len);



        for (uint256 i = 0; i < len; i++) {

            tokenArray[i] = _dividendTokenSet.at(i);

        }



        return tokenArray;

    }



    /// @dev withdrawDividend for all tokens

    function multiWithdrawDividend() public {

        require(!isExcludedFromReward[_msgSender()], "ERC20: excluded from reward");

        address[] memory tokenArray = getDividendTokenList();

        uint256 len = tokenArray.length;



        for (uint256 i = 0; i < len; i++) {

            withdrawDividend(tokenArray[i]);

        }

    }



    /// @notice View the amount of dividend in wei that an address can withdraw.

    /// @param _owner The address of a token holder.

    /// @return The amount of dividend in wei that `_owner` can withdraw.

    function dividendOf(address _owner, address _token) public view returns(uint256) {

        return !isExcludedFromReward[_owner] ? withdrawableDividendOf(_owner, _token) : 0;

    }



    /// @dev dividendOf for all tokens

    function dividendOfAll(address _owner) public view returns(uint256[] memory) {

        address[] memory tokenArray = getDividendTokenList();

        uint256 len = tokenArray.length;

        uint256[] memory variableArray = new uint256[](len);



        for (uint256 i = 0; i < len; i++) {

            address _token = tokenArray[i];

            variableArray[i] = dividendOf(_owner, _token);

        }



        return variableArray;

    }



    /// @notice View the amount of dividend in wei that an address can withdraw.

    /// @param _owner The address of a token holder.

    /// @return The amount of dividend in wei that `_owner` can withdraw.

    function withdrawableDividendOf(address _owner, address _token) public view returns(uint256) {

        return !isExcludedFromReward[_owner] ? accumulativeDividendOf(_owner, _token) - (withdrawnDividendsMap[_token][_owner]) : 0;

    }



    /// @notice View the amount of dividend in wei that an address has withdrawn.

    /// @param _owner The address of a token holder.

    /// @return The amount of dividend in wei that `_owner` has withdrawn.

    function withdrawnDividendOf(address _owner, address _token) public view returns(uint256) {

        return withdrawnDividendsMap[_token][_owner];

    }



    /// @dev withdrawnDividendOf for all tokens

    function withdrawnDividendOfAll(address _owner) public view returns(uint256[] memory) {

        address[] memory tokenArray = getDividendTokenList();

        uint256 len = tokenArray.length;

        uint256[] memory variableArray = new uint256[](len);



        for (uint256 i = 0; i < len; i++) {

            address _token = tokenArray[i];

            variableArray[i] = withdrawnDividendOf(_owner, _token);

        }



        return variableArray;

    }



    /// @notice View the amount of dividend in wei that an address has earned in total.

    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)

    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude

    /// @param _owner The address of a token holder.

    /// @return The amount of dividend in wei that `_owner` has earned in total.

    function accumulativeDividendOf(address _owner, address _token) public view returns(uint256) {    

        return !isExcludedFromReward[_owner] ? magnifiedDividendPerShareMap[_token] * (balanceOf(_owner)).toInt256Safe()

                .add(magnifiedDividendCorrectionsMap[_token][_owner]).toUint256Safe() / MAGNITUDE : 0;

    }



}