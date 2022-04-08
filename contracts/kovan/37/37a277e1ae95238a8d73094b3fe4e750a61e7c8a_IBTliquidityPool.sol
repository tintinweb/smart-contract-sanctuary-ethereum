/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeCast.sol


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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol


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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Counters.sol


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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Context.sol


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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/access/Ownable.sol


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

// File: IBTliquidityPool.sol

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.8.7 <0.9.0;






contract IBTliquidityPool is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Address for address;
    Counters.Counter private _totalNumberOfTokens;
    Counters.Counter private _optimumCompositionTotal0dp;
    Counters.Counter private _quotes;
   
    struct Token {
        address contractAddress;
        uint8 decimalPlaces;
        string tokenTicker;
        string tokenName;
        uint40 exchangeRateFP6DP; //Token:USD Fixed point 6 decimal places. Range is 0 < x < 2^40 ~ 1,099,511.627776: TODO: Increase this
        uint16 compositionPercentageFP2DP;
        uint8 optimumCompositionPercentage0DP;
        uint8 rewardPercentage;
        bool active;  // if false, trading suspended
        bool hasValue;
    }

    struct quoteObject {
        address _requestor;
        address _tokenIn;
        address _tokenOut;
        address _recipient;
        uint256 _amountInFP6DP;
        uint256 _exchangeRateFP6DP;
        uint256 _amountOutFP12DP;
        uint256 _feeFP6DP;
        uint256 _totalDueFP6DP;
        uint256 _validity;
        bool hasValue;
    }
    
    address[] _tokenAddresses;
    bool private _isAMMActive;
    uint16 private _swapFeeFP2DP = 50; //0.5% //TODO: Getter & Setter
    mapping(address => Token) private tokens;
    mapping(uint256 => quoteObject) private quotes;

    event quoteSent(address _tokenIn,address _tokenOut,address _recipient,uint256 _amountInFP6DP, uint256 _exchangeRateFP6DP, uint256 _amountOutFP12DP,uint256 _feeFP6DP,uint256 _totalDueFP6DP,uint256 _validity);

    function addTokenToLiquidityPool(address contractAddress, uint8 decimalPlaces, string memory tokenTicker, string memory tokenName, uint40 exchangeRateFP6DP, uint8 optimumCompositionPercentage0dp, bool active) public onlyOwner () //TODO: Add roles so multiple addresses can access contract
    {   
        require(
            tokens[contractAddress].hasValue == false,
            "Token contract exists"
        );
        /*
        //TODO: Enable for production
        if(contractAddress != 0x0000000000000000000000000000000000000000) {
            require(
                _isContract(contractAddress) == true,
                "Address is not contract"
            );
        }
        */
        require(
            decimalPlaces >= 0 && decimalPlaces <= 18,
            "Decimal places must be 0 <= x <= 18"
        );
        
        require(
            _getStringLength(tokenTicker) > 0,
            "Token ticker is empty"
        );
        require(
            _getStringLength(tokenName) > 0,
            "Token name is empty"
        );
        require(
            exchangeRateFP6DP > 0 && exchangeRateFP6DP < 1099511627776, //2^40
            "Exchange rate must be in range 0 < x < 1099511627776"
        );
        
        require(
            optimumCompositionPercentage0dp > 0 && optimumCompositionPercentage0dp <= 100,
            "Optimum composition must be 0 < x < 100"
        );

        require(
            _optimumCompositionTotal0dp.current() + optimumCompositionPercentage0dp <= 100,
            "Total Optimum condition must be <= 100%"
        );
        
        tokens[contractAddress].contractAddress = contractAddress;
        tokens[contractAddress].decimalPlaces = decimalPlaces;
        
        tokens[contractAddress].tokenTicker = _getString(tokenTicker);
        tokens[contractAddress].tokenName = _getString(tokenName);
        tokens[contractAddress].exchangeRateFP6DP = exchangeRateFP6DP;
        tokens[contractAddress].compositionPercentageFP2DP = _transformToFixedPoint2DP(optimumCompositionPercentage0dp);
        tokens[contractAddress].optimumCompositionPercentage0DP = optimumCompositionPercentage0dp;
        tokens[contractAddress].rewardPercentage = 0;
        tokens[contractAddress].active = active;    
        tokens[contractAddress].hasValue = true;
        if(active == true) {   
            _increaseOptimumComposition(optimumCompositionPercentage0dp);
        }
        _tokenAddresses.push(contractAddress);
        _totalNumberOfTokens.increment();
    }

    function getTokenByContractAddress(address contractAddress) public view returns (Token memory) {
        require(
            tokens[contractAddress].hasValue == true,
            "Token not in liquidity pool"
        );
        return tokens[contractAddress];
    }

    function updateExchangeRate(address contractAddress,uint40 exchangeRateFP6DP) public onlyOwner (){ //TODO: Use roles to multiple oracles can update
        require(
            tokens[contractAddress].hasValue == true,
            "Token not in liquidity pool"
        );
        require(
            exchangeRateFP6DP > 0 && exchangeRateFP6DP < 1099511627776, //2^40
            "Exchange rate must be in range 0 < x < 1099511627776"
        );
        tokens[contractAddress].exchangeRateFP6DP = exchangeRateFP6DP;
    }

    function disableToken(address contractAddress) public onlyOwner (){
        require(
            tokens[contractAddress].hasValue == true,
            "Token not in liquidity pool"
        );
        require(
            tokens[contractAddress].active == true,
            "Token is not active"
        );
        setAMMActiveStatus(false);
        _decreaseOptimumComposition(tokens[contractAddress].optimumCompositionPercentage0DP);
        tokens[contractAddress].active = false;
    }

    function enableToken(address contractAddress) public onlyOwner (){
        require(
            tokens[contractAddress].hasValue == true,
            "Token not in liquidity pool"
        );
        require(
            tokens[contractAddress].active == false,
            "Token is active"
        );
        setAMMActiveStatus(false);
        _increaseOptimumComposition(tokens[contractAddress].optimumCompositionPercentage0DP);
        tokens[contractAddress].active = true;
    }

    function adjustOptimumComposition(address contractAddress, uint8 optimumCompositionPercentage0dp) public onlyOwner (){
        require(
            tokens[contractAddress].hasValue == true,
            "Token not in liquidity pool"
        );
        require(
            optimumCompositionPercentage0dp > 0 && optimumCompositionPercentage0dp <= 100,
            "Optimum composition must be 0 < x < 100"
        );
        setAMMActiveStatus(false);
        _decreaseOptimumComposition(tokens[contractAddress].optimumCompositionPercentage0DP);
        _increaseOptimumComposition(optimumCompositionPercentage0dp);
        tokens[contractAddress].optimumCompositionPercentage0DP = optimumCompositionPercentage0dp;
    }

    function _getStringLength(string memory _string) private pure returns(uint256) { //Input must be ASCII. No UTF-8
        bytes memory bytesString = bytes(_string);
        return bytesString.length;
    }

    function _getString(string memory _string) private pure returns(string memory) { //Input must be ASCII. No UTF-8
        bytes memory bytesString = bytes(_string);
        return string(bytesString);
    }

    function getTotalNumberOfTokens() public view returns(uint256) {
        return _totalNumberOfTokens.current();
    }

    function renounceOwnership() public override(Ownable) view onlyOwner ()
    {   
        revert("The contract must have an owner");
    }

    function _increaseOptimumComposition(uint256 _optimumComposition) private {
        for(uint8 i = 0; i < _optimumComposition; i++) {
            _optimumCompositionTotal0dp.increment();
        }
    }
    function _decreaseOptimumComposition(uint256 _optimumComposition) private {
        require( //Check underflow
            _optimumComposition < _optimumCompositionTotal0dp.current(),
            "Optimum storage underflow"
        );
        for(uint8 i = 0; i < _optimumComposition; i++) {
            _optimumCompositionTotal0dp.decrement();
        }
    }

    function getContractAddressesByIndex(uint256 index) public view returns(address)
    {
        return _tokenAddresses[index];
    }

    function getTotalOptimumComposition() public view returns(uint256) {
        return _optimumCompositionTotal0dp.current();
    }

    function _transformToFixedPoint2DP(uint8 optimumCompositionPercentage0dp) private pure returns (uint16) {
        uint256 optimumCompositionPercentage0dpUint256 = uint256(optimumCompositionPercentage0dp);
        uint256 optimumCompositionPercentage2dpUint256 = optimumCompositionPercentage0dpUint256.mul(100);
        return optimumCompositionPercentage2dpUint256.toUint16();
    }

    function seedData() public onlyOwner ()
    {   
        addTokenToLiquidityPool(0x3acF975Bd92f4c297dbC36Fa7b96F388dD5A12e2,12,'USDC','USD Coin',1000000, 5, true);
        addTokenToLiquidityPool(0xFa4D13a5499FEdbBfA63bd887683E91b0EcE8E36,8,'USDT','Tether', 1000000, 15, true);
        addTokenToLiquidityPool(0xfbC32B919354ac273E7eecF5B3b77182D6730258,18,'tUSD','Trusted USD', 1000000, 10, true);
        addTokenToLiquidityPool(0x0000000000000000000000000000000000000000,18,'ETH','Ethereum', 3372020000, 17, true);
        addTokenToLiquidityPool(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,0,'BMT','BitMinutes', 3439, 12, true);
        addTokenToLiquidityPool(0x617F2E2fD72FD9D5503197092aC168c91465E7f2,6,'EXV','Everex', 27130, 8, true);
        addTokenToLiquidityPool(0xdD870fA1b7C4700F2BD7f44238821C26f7392148,10,'tUAH','Trusted Ukrainian Hryvnia', 34000, 19, true);
        addTokenToLiquidityPool(0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,12,'wBTC','Wrapped BTC', 46606600000, 1, true);
        addTokenToLiquidityPool(0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,18,'tKRW','Trusted South Korean Won', 820, 3, true);
        addTokenToLiquidityPool(0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC,10,'DAI','Maker DAO', 1000000, 10, true);
        setAMMActiveStatus(true);
    }

    function getAMMActiveStatus() public view onlyOwner returns(bool)
    {
        return _isAMMActive;
    }
    
    function setAMMActiveStatus(bool status) public onlyOwner ()
    {
        if(status == false) {
            _isAMMActive = status;
        } else {
            require(
                _optimumCompositionTotal0dp.current() == 100,
                "Optimum Composition not at 100%"
            );
            _isAMMActive = status;
        }
        
    }

    //function getAMMPairQuote(address tokenIn, address tokenOut,address recipient,uint40 amountInFP6DP) public returns(uint256){
    function getAMMPairQuote() public returns(uint256) {
        address tokenIn = 0x0000000000000000000000000000000000000000; //ETH
        address tokenOut = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678; //wBTC
        address recipient = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        uint40 amountInFP6DP = 2500000;

        Token memory tokenInStruct = tokens[tokenIn];
        Token memory tokenOutStruct = tokens[tokenOut];
        require(
            _isAMMActive == true,
            "Automated Market Maker not active"
        );
        require(
            tokenInStruct.hasValue == true,
            "tokenIn not in liquidity pool"
        );
        require(
            tokenInStruct.active == true,
            "tokenIn not active"
        );
        require(
            tokenOutStruct.hasValue == true,
            "tokenOut not in liquidity pool"
        );
        require(
            tokenOutStruct.active == true,
            "tokenOut not active"
        );
        
        uint256 tokenInExchangeRateUint256 = uint256(tokenInStruct.exchangeRateFP6DP);
        tokenInExchangeRateUint256 = tokenInExchangeRateUint256.mul(1000000);
        uint256 tokenOutExchangeRateUint256 = uint256(tokenOutStruct.exchangeRateFP6DP);
        uint256 exchangeRateFP6DP = tokenInExchangeRateUint256.div(tokenOutExchangeRateUint256);
        uint256 amountOutFP12DP = exchangeRateFP6DP.mul(uint256(amountInFP6DP));
        uint256 swapFeeFP6DP = _calculateFee(amountInFP6DP,_swapFeeFP2DP);
        uint256 amountInFP6DPUint256 = uint256(amountInFP6DP);
        uint256 totalDueFP6DP = amountInFP6DPUint256.add(swapFeeFP6DP);
        uint256 validity = block.timestamp + 5 minutes;

        uint256 quoteIndex = _quotes.current();

        quotes[quoteIndex]._requestor = msg.sender;
        quotes[quoteIndex]._tokenIn = tokenIn;
        quotes[quoteIndex]._tokenOut = tokenOut;
        quotes[quoteIndex]._recipient = recipient;
        quotes[quoteIndex]._amountInFP6DP = amountInFP6DPUint256;
        quotes[quoteIndex]._exchangeRateFP6DP = exchangeRateFP6DP;
        quotes[quoteIndex]._amountOutFP12DP = amountOutFP12DP;
        quotes[quoteIndex]._feeFP6DP = swapFeeFP6DP;
        quotes[quoteIndex]._totalDueFP6DP = totalDueFP6DP;
        quotes[quoteIndex]._validity = validity;
        quotes[quoteIndex].hasValue = true;

        _quotes.increment();

        emit quoteSent(tokenIn,tokenOut,recipient,amountInFP6DPUint256,exchangeRateFP6DP,amountOutFP12DP,swapFeeFP6DP,totalDueFP6DP,validity);

        return quoteIndex;
    }

    
    function getQuoteByQuoteIndexRequestor(uint256 quoteIndex, address requestor) public view returns (quoteObject memory) {
        require(
            quotes[quoteIndex].hasValue == true,
            "Qoute not available"
        );
        require(
            quotes[quoteIndex]._requestor == requestor,
            "Invalid requestor address"
        );
        return quotes[quoteIndex];
    }

    function confirmAMMQuote(uint256 quoteIndex) public view {
        require(
            _isAMMActive == true,
            "Automated Market Maker not active"
        );
        quoteObject memory quoteStruct = quotes[quoteIndex];
        Token memory tokenInStruct = tokens[quoteStruct._tokenIn];
        Token memory tokenOutStruct = tokens[quoteStruct._tokenOut];
        require (
            quoteStruct.hasValue = true,
            "Quote not available"
        );
        require (
            msg.sender == quoteStruct._requestor,
            "Invalid requestor address"
        );
        require(
            tokenInStruct.active == true,
            "tokenIn not active"
        );
        require(
            tokenOutStruct.active == true,
            "tokenOut not active"
        );
        require(
            block.timestamp > quoteStruct._validity,
            "Quote has expired"
        );
        /*
        //TODO: In Swap Interface. Disable AMM and tokens that have run out
        Check amount in vs supply, amount out vs supply, hold supply
        Check balance of tokenOut
        Place balance of tokenOut on hold
        */
    }
    
    function _calculateFee(uint256 amountInFP6DP, uint256 swapFeeFP2DP) private  pure  returns(uint256) {
        uint256 swapFeeFP2DPUint256 = uint256(swapFeeFP2DP);
        uint256 swapFee = swapFeeFP2DPUint256.mul(amountInFP6DP);
        swapFee = swapFee.div(10000);
        return swapFee;
    }

    function _isContract(address contractAddress) private view returns (bool) {
        return contractAddress.isContract();
    } 
}