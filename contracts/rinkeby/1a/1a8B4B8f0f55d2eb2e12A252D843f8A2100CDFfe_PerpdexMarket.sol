// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.0 <0.8.0;


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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IPerpdexMarket } from "./interface/IPerpdexMarket.sol";
import { MarketStructs } from "./lib/MarketStructs.sol";
import { FundingLibrary } from "./lib/FundingLibrary.sol";
import { PoolLibrary } from "./lib/PoolLibrary.sol";
import { PriceLimitLibrary } from "./lib/PriceLimitLibrary.sol";

contract PerpdexMarket is IPerpdexMarket, ReentrancyGuard, Ownable {
    using Address for address;
    using SafeMath for uint256;

    event PoolFeeRatioChanged(uint24 value);
    event FundingMaxPremiumRatioChanged(uint24 value);
    event FundingMaxElapsedSecChanged(uint32 value);
    event FundingRolloverSecChanged(uint32 value);
    event PriceLimitConfigChanged(
        uint24 normalOrderRatio,
        uint24 liquidationRatio,
        uint24 emaNormalOrderRatio,
        uint24 emaLiquidationRatio,
        uint32 emaSec
    );

    string public override symbol;
    address public immutable override exchange;
    address public immutable priceFeedBase;
    address public immutable priceFeedQuote;

    MarketStructs.PoolInfo public poolInfo;
    MarketStructs.FundingInfo public fundingInfo;
    MarketStructs.PriceLimitInfo public priceLimitInfo;

    uint24 public poolFeeRatio = 3e3;
    uint24 public fundingMaxPremiumRatio = 1e4;
    uint32 public fundingMaxElapsedSec = 1 days;
    uint32 public fundingRolloverSec = 1 days;
    MarketStructs.PriceLimitConfig public priceLimitConfig =
        MarketStructs.PriceLimitConfig({
            normalOrderRatio: 5e4,
            liquidationRatio: 10e4,
            emaNormalOrderRatio: 20e4,
            emaLiquidationRatio: 25e4,
            emaSec: 5 minutes
        });

    modifier onlyExchange() {
        require(exchange == msg.sender, "PM_OE: caller is not exchange");
        _;
    }

    constructor(
        string memory symbolArg,
        address exchangeArg,
        address priceFeedBaseArg,
        address priceFeedQuoteArg
    ) {
        require(priceFeedBaseArg == address(0) || priceFeedBaseArg.isContract(), "PM_C: base price feed invalid");
        require(priceFeedQuoteArg == address(0) || priceFeedQuoteArg.isContract(), "PM_C: quote price feed invalid");

        symbol = symbolArg;
        exchange = exchangeArg;
        priceFeedBase = priceFeedBaseArg;
        priceFeedQuote = priceFeedQuoteArg;

        FundingLibrary.initializeFunding(fundingInfo);
        PoolLibrary.initializePool(poolInfo);
    }

    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external override onlyExchange nonReentrant returns (uint256 oppositeAmount) {
        (uint256 maxAmount, MarketStructs.PriceLimitInfo memory updated) =
            _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation);
        require(amount <= maxAmount, "PM_S: too large amount");

        oppositeAmount = PoolLibrary.swap(
            poolInfo,
            PoolLibrary.SwapParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isExactInput,
                amount: amount,
                feeRatio: poolFeeRatio
            })
        );

        PriceLimitLibrary.update(priceLimitInfo, updated);

        emit Swapped(isBaseToQuote, isExactInput, amount, oppositeAmount);

        _processFunding();
    }

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        override
        onlyExchange
        nonReentrant
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        if (poolInfo.totalLiquidity == 0) {
            FundingLibrary.validateInitialLiquidityPrice(priceFeedBase, priceFeedQuote, baseShare, quoteBalance);
        }

        (base, quote, liquidity) = PoolLibrary.addLiquidity(
            poolInfo,
            PoolLibrary.AddLiquidityParams({ base: baseShare, quote: quoteBalance })
        );
        emit LiquidityAdded(base, quote, liquidity);

        _processFunding();
    }

    function removeLiquidity(uint256 liquidity)
        external
        override
        onlyExchange
        nonReentrant
        returns (uint256 base, uint256 quote)
    {
        (base, quote) = PoolLibrary.removeLiquidity(
            poolInfo,
            PoolLibrary.RemoveLiquidityParams({ liquidity: liquidity })
        );
        emit LiquidityRemoved(base, quote, liquidity);

        _processFunding();
    }

    function setPoolFeeRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 5e4, "PM_SPFR: too large");
        poolFeeRatio = value;
        emit PoolFeeRatioChanged(value);
    }

    function setFundingMaxPremiumRatio(uint24 value) external onlyOwner nonReentrant {
        require(value <= 1e5, "PM_SFMPR: too large");
        fundingMaxPremiumRatio = value;
        emit FundingMaxPremiumRatioChanged(value);
    }

    function setFundingMaxElapsedSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFMES: too large");
        fundingMaxElapsedSec = value;
        emit FundingMaxElapsedSecChanged(value);
    }

    function setFundingRolloverSec(uint32 value) external onlyOwner nonReentrant {
        require(value <= 7 days, "PM_SFRS: too large");
        require(value >= 1 hours, "PM_SFRS: too small");
        fundingRolloverSec = value;
        emit FundingRolloverSecChanged(value);
    }

    function setPriceLimitConfig(MarketStructs.PriceLimitConfig calldata value) external onlyOwner nonReentrant {
        require(value.liquidationRatio <= 5e5, "PE_SPLC: too large liquidation");
        require(value.normalOrderRatio <= value.liquidationRatio, "PE_SPLC: invalid");
        require(value.emaLiquidationRatio < 1e6, "PE_SPLC: ema too large liq");
        require(value.emaNormalOrderRatio <= value.emaLiquidationRatio, "PE_SPLC: ema invalid");
        priceLimitConfig = value;
        emit PriceLimitConfigChanged(
            value.normalOrderRatio,
            value.liquidationRatio,
            value.emaNormalOrderRatio,
            value.emaLiquidationRatio,
            value.emaSec
        );
    }

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view override returns (uint256 oppositeAmount) {
        (uint256 maxAmount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation);
        require(amount <= maxAmount, "PM_PS: too large amount");

        oppositeAmount = PoolLibrary.previewSwap(
            poolInfo.base,
            poolInfo.quote,
            PoolLibrary.SwapParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isExactInput,
                amount: amount,
                feeRatio: poolFeeRatio
            }),
            false
        );
    }

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view override returns (uint256 amount) {
        (amount, ) = _doMaxSwap(isBaseToQuote, isExactInput, isLiquidation);
    }

    function getShareMarkPriceX96() public view override returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getShareMarkPriceX96(poolInfo.base, poolInfo.quote);
    }

    function getLiquidityValue(uint256 liquidity) external view override returns (uint256, uint256) {
        return PoolLibrary.getLiquidityValue(poolInfo, liquidity);
    }

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view override returns (int256, int256) {
        return
            PoolLibrary.getLiquidityDeleveraged(
                poolInfo.cumBasePerLiquidityX96,
                poolInfo.cumQuotePerLiquidityX96,
                liquidity,
                cumBasePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
    }

    function getCumDeleveragedPerLiquidityX96() external view override returns (uint256, uint256) {
        return (poolInfo.cumBasePerLiquidityX96, poolInfo.cumQuotePerLiquidityX96);
    }

    function baseBalancePerShareX96() external view override returns (uint256) {
        return poolInfo.baseBalancePerShareX96;
    }

    function getMarkPriceX96() public view override returns (uint256) {
        if (poolInfo.base == 0) return 0;
        return PoolLibrary.getMarkPriceX96(poolInfo.base, poolInfo.quote, poolInfo.baseBalancePerShareX96);
    }

    function _processFunding() internal {
        uint256 markPriceX96 = getMarkPriceX96();
        (int256 fundingRateX96, uint32 elapsedSec, int256 premiumX96) =
            FundingLibrary.processFunding(
                fundingInfo,
                FundingLibrary.ProcessFundingParams({
                    priceFeedBase: priceFeedBase,
                    priceFeedQuote: priceFeedQuote,
                    markPriceX96: markPriceX96,
                    maxPremiumRatio: fundingMaxPremiumRatio,
                    maxElapsedSec: fundingMaxElapsedSec,
                    rolloverSec: fundingRolloverSec
                })
            );
        if (fundingRateX96 == 0) return;

        PoolLibrary.applyFunding(poolInfo, fundingRateX96);
        emit FundingPaid(
            fundingRateX96,
            elapsedSec,
            premiumX96,
            markPriceX96,
            poolInfo.cumBasePerLiquidityX96,
            poolInfo.cumQuotePerLiquidityX96
        );
    }

    function _doMaxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) private view returns (uint256 amount, MarketStructs.PriceLimitInfo memory updated) {
        if (poolInfo.totalLiquidity == 0) return (0, updated);

        uint256 sharePriceBeforeX96 = getShareMarkPriceX96();
        updated = PriceLimitLibrary.updateDry(priceLimitInfo, priceLimitConfig, sharePriceBeforeX96);

        uint256 sharePriceBound =
            PriceLimitLibrary.priceBound(
                updated.referencePrice,
                updated.emaPrice,
                priceLimitConfig,
                isLiquidation,
                !isBaseToQuote
            );
        amount = PoolLibrary.maxSwap(
            poolInfo.base,
            poolInfo.quote,
            isBaseToQuote,
            isExactInput,
            poolFeeRatio,
            sharePriceBound
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { IPerpdexMarketMinimum } from "./IPerpdexMarketMinimum.sol";

interface IPerpdexMarket is IPerpdexMarketMinimum {
    event FundingPaid(
        int256 fundingRateX96,
        uint32 elapsedSec,
        int256 premiumX96,
        uint256 markPriceX96,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    );
    event LiquidityAdded(uint256 base, uint256 quote, uint256 liquidity);
    event LiquidityRemoved(uint256 base, uint256 quote, uint256 liquidity);
    event Swapped(bool isBaseToQuote, bool isExactInput, uint256 amount, uint256 oppositeAmount);

    // getters

    function symbol() external view returns (string memory);

    function exchange() external view returns (address);

    function getMarkPriceX96() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPerpdexMarketMinimum {
    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external returns (uint256);

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(uint256 liquidity) external returns (uint256 baseShare, uint256 quoteBalance);

    // getters

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256);

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount);

    function getShareMarkPriceX96() external view returns (uint256);

    function getLiquidityValue(uint256 liquidity) external view returns (uint256 baseShare, uint256 quoteBalance);

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256);

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256);

    function baseBalancePerShareX96() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IPerpdexPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Math } from "../amm/uniswap_v2/libraries/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { IPerpdexPriceFeed } from "../interface/IPerpdexPriceFeed.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library FundingLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct ProcessFundingParams {
        address priceFeedBase;
        address priceFeedQuote;
        uint256 markPriceX96;
        uint24 maxPremiumRatio;
        uint32 maxElapsedSec;
        uint32 rolloverSec;
    }

    uint8 public constant MAX_DECIMALS = 77; // 10^MAX_DECIMALS < 2^256

    function initializeFunding(MarketStructs.FundingInfo storage fundingInfo) internal {
        fundingInfo.prevIndexPriceTimestamp = block.timestamp;
    }

    // must not revert even if priceFeed is malicious
    function processFunding(MarketStructs.FundingInfo storage fundingInfo, ProcessFundingParams memory params)
        internal
        returns (
            int256 fundingRateX96,
            uint32 elapsedSec,
            int256 premiumX96
        )
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 elapsedSec256 = currentTimestamp.sub(fundingInfo.prevIndexPriceTimestamp);
        if (elapsedSec256 == 0) return (0, 0, 0);

        uint256 indexPriceBase = _getIndexPriceSafe(params.priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(params.priceFeedQuote);
        uint8 decimalsBase = _getDecimalsSafe(params.priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(params.priceFeedQuote);
        if (
            (fundingInfo.prevIndexPriceBase == indexPriceBase && fundingInfo.prevIndexPriceQuote == indexPriceQuote) ||
            indexPriceBase == 0 ||
            indexPriceQuote == 0 ||
            decimalsBase > MAX_DECIMALS ||
            decimalsQuote > MAX_DECIMALS
        ) {
            return (0, 0, 0);
        }

        elapsedSec256 = Math.min(elapsedSec256, params.maxElapsedSec);
        elapsedSec = elapsedSec256.toUint32();

        premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, params.markPriceX96);

        int256 maxPremiumX96 = FixedPoint96.Q96.mulRatio(params.maxPremiumRatio).toInt256();
        premiumX96 = (-maxPremiumX96).max(maxPremiumX96.min(premiumX96));
        fundingRateX96 = premiumX96.mulDiv(elapsedSec256.toInt256(), params.rolloverSec);

        fundingInfo.prevIndexPriceBase = indexPriceBase;
        fundingInfo.prevIndexPriceQuote = indexPriceQuote;
        fundingInfo.prevIndexPriceTimestamp = currentTimestamp;
    }

    function validateInitialLiquidityPrice(
        address priceFeedBase,
        address priceFeedQuote,
        uint256 base,
        uint256 quote
    ) internal view {
        uint256 indexPriceBase = _getIndexPriceSafe(priceFeedBase);
        uint256 indexPriceQuote = _getIndexPriceSafe(priceFeedQuote);
        require(indexPriceBase > 0, "FL_VILP: invalid base price");
        require(indexPriceQuote > 0, "FL_VILP: invalid quote price");
        uint8 decimalsBase = _getDecimalsSafe(priceFeedBase);
        uint8 decimalsQuote = _getDecimalsSafe(priceFeedQuote);
        require(decimalsBase <= MAX_DECIMALS, "FL_VILP: invalid base decimals");
        require(decimalsQuote <= MAX_DECIMALS, "FL_VILP: invalid quote decimals");

        uint256 markPriceX96 = FullMath.mulDiv(quote, FixedPoint96.Q96, base);
        int256 premiumX96 = _calcPremiumX96(decimalsBase, decimalsQuote, indexPriceBase, indexPriceQuote, markPriceX96);

        require(premiumX96.abs() <= FixedPoint96.Q96.mulRatio(1e5), "FL_VILP: too far from index");
    }

    function _getIndexPriceSafe(address priceFeed) private view returns (uint256) {
        if (priceFeed == address(0)) return 1; // indicate valid

        bytes memory payload = abi.encodeWithSignature("getPrice()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 0; // invalid

        return abi.decode(data, (uint256));
    }

    function _getDecimalsSafe(address priceFeed) private view returns (uint8) {
        if (priceFeed == address(0)) return 0; // indicate valid

        bytes memory payload = abi.encodeWithSignature("decimals()");
        (bool success, bytes memory data) = address(priceFeed).staticcall(payload);
        if (!success) return 255; // invalid

        return abi.decode(data, (uint8));
    }

    // TODO: must not revert
    function _calcPremiumX96(
        uint8 decimalsBase,
        uint8 decimalsQuote,
        uint256 indexPriceBase,
        uint256 indexPriceQuote,
        uint256 markPriceX96
    ) private pure returns (int256 premiumX96) {
        uint256 priceRatioX96 = markPriceX96;

        if (decimalsBase != 0 || indexPriceBase != 1) {
            priceRatioX96 = FullMath.mulDiv(priceRatioX96, 10**decimalsBase, indexPriceBase);
        }
        if (decimalsQuote != 0 || indexPriceQuote != 1) {
            priceRatioX96 = FullMath.mulDiv(priceRatioX96, indexPriceQuote, 10**decimalsQuote);
        }

        premiumX96 = priceRatioX96.toInt256().sub(FixedPoint96.Q96.toInt256());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

library MarketStructs {
    struct FundingInfo {
        uint256 prevIndexPriceBase;
        uint256 prevIndexPriceQuote;
        uint256 prevIndexPriceTimestamp;
    }

    struct PoolInfo {
        uint256 base;
        uint256 quote;
        uint256 totalLiquidity;
        uint256 cumBasePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
        uint256 baseBalancePerShareX96;
    }

    struct PriceLimitInfo {
        uint256 referencePrice;
        uint256 referenceTimestamp;
        uint256 emaPrice;
    }

    struct PriceLimitConfig {
        uint24 normalOrderRatio;
        uint24 liquidationRatio;
        uint24 emaNormalOrderRatio;
        uint24 emaLiquidationRatio;
        uint32 emaSec;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

library PerpMath {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -SafeCast.toInt256(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, 1e6, ratio);
    }

    function divRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDivRoundingUp(value, 1e6, ratio);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : SafeCast.toInt256(unsignedResult);

        return result;
    }

    function sign(int256 value) internal pure returns (int256) {
        return value > 0 ? 1 : (value < 0 ? -1 : int256(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Math } from "../amm/uniswap_v2/libraries/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { MarketStructs } from "./MarketStructs.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

library PoolLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct SwapParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint24 feeRatio;
        uint256 amount;
    }

    struct AddLiquidityParams {
        uint256 base;
        uint256 quote;
    }

    struct RemoveLiquidityParams {
        uint256 liquidity;
    }

    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    function initializePool(MarketStructs.PoolInfo storage poolInfo) internal {
        poolInfo.baseBalancePerShareX96 = FixedPoint96.Q96;
    }

    // underestimate deleveraged tokens
    function applyFunding(MarketStructs.PoolInfo storage poolInfo, int256 fundingRateX96) internal {
        if (fundingRateX96 == 0) return;

        uint256 frAbs = fundingRateX96.abs();

        if (fundingRateX96 > 0) {
            uint256 poolQuote = poolInfo.quote;
            uint256 deleveratedQuote = FullMath.mulDiv(poolQuote, frAbs, FixedPoint96.Q96);
            poolInfo.quote = poolQuote.sub(deleveratedQuote);
            poolInfo.cumQuotePerLiquidityX96 = poolInfo.cumQuotePerLiquidityX96.add(
                FullMath.mulDiv(deleveratedQuote, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        } else {
            uint256 poolBase = poolInfo.base;
            uint256 deleveratedBase = FullMath.mulDiv(poolBase, frAbs, FixedPoint96.Q96.add(frAbs));
            poolInfo.base = poolBase.sub(deleveratedBase);
            poolInfo.cumBasePerLiquidityX96 = poolInfo.cumBasePerLiquidityX96.add(
                FullMath.mulDiv(deleveratedBase, FixedPoint96.Q96, poolInfo.totalLiquidity)
            );
        }

        poolInfo.baseBalancePerShareX96 = FullMath.mulDiv(
            poolInfo.baseBalancePerShareX96,
            FixedPoint96.Q96.toInt256().sub(fundingRateX96).toUint256(),
            FixedPoint96.Q96
        );
    }

    function swap(MarketStructs.PoolInfo storage poolInfo, SwapParams memory params)
        internal
        returns (uint256 oppositeAmount)
    {
        oppositeAmount = previewSwap(poolInfo.base, poolInfo.quote, params, false);
        (poolInfo.base, poolInfo.quote) = calcPoolAfter(
            params.isBaseToQuote,
            params.isExactInput,
            poolInfo.base,
            poolInfo.quote,
            params.amount,
            oppositeAmount
        );
    }

    function calcPoolAfter(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 base,
        uint256 quote,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (uint256 baseAfter, uint256 quoteAfter) {
        if (isExactInput) {
            if (isBaseToQuote) {
                baseAfter = base.add(amount);
                quoteAfter = quote.sub(oppositeAmount);
            } else {
                baseAfter = base.sub(oppositeAmount);
                quoteAfter = quote.add(amount);
            }
        } else {
            if (isBaseToQuote) {
                baseAfter = base.add(oppositeAmount);
                quoteAfter = quote.sub(amount);
            } else {
                baseAfter = base.sub(amount);
                quoteAfter = quote.add(oppositeAmount);
            }
        }
    }

    function addLiquidity(MarketStructs.PoolInfo storage poolInfo, AddLiquidityParams memory params)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 liquidity;

        if (poolTotalLiquidity == 0) {
            uint256 totalLiquidity = Math.sqrt(params.base.mul(params.quote));
            liquidity = totalLiquidity.sub(MINIMUM_LIQUIDITY);
            require(params.base > 0 && params.quote > 0 && liquidity > 0, "PL_AL: initial liquidity zero");

            poolInfo.base = params.base;
            poolInfo.quote = params.quote;
            poolInfo.totalLiquidity = totalLiquidity;
            return (params.base, params.quote, liquidity);
        }

        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;

        uint256 base = Math.min(params.base, FullMath.mulDiv(params.quote, poolBase, poolQuote));
        uint256 quote = Math.min(params.quote, FullMath.mulDiv(params.base, poolQuote, poolBase));
        liquidity = Math.min(
            FullMath.mulDiv(base, poolTotalLiquidity, poolBase),
            FullMath.mulDiv(quote, poolTotalLiquidity, poolQuote)
        );
        require(base > 0 && quote > 0 && liquidity > 0, "PL_AL: liquidity zero");

        poolInfo.base = poolBase.add(base);
        poolInfo.quote = poolQuote.add(quote);
        poolInfo.totalLiquidity = poolTotalLiquidity.add(liquidity);

        return (base, quote, liquidity);
    }

    function removeLiquidity(MarketStructs.PoolInfo storage poolInfo, RemoveLiquidityParams memory params)
        internal
        returns (uint256, uint256)
    {
        uint256 poolBase = poolInfo.base;
        uint256 poolQuote = poolInfo.quote;
        uint256 poolTotalLiquidity = poolInfo.totalLiquidity;
        uint256 base = FullMath.mulDiv(params.liquidity, poolBase, poolTotalLiquidity);
        uint256 quote = FullMath.mulDiv(params.liquidity, poolQuote, poolTotalLiquidity);
        require(base > 0 && quote > 0, "PL_RL: output is zero");
        poolInfo.base = poolBase.sub(base);
        poolInfo.quote = poolQuote.sub(quote);
        uint256 totalLiquidity = poolTotalLiquidity.sub(params.liquidity);
        require(totalLiquidity >= MINIMUM_LIQUIDITY, "PL_RL: min liquidity");
        poolInfo.totalLiquidity = totalLiquidity;
        return (base, quote);
    }

    function getLiquidityValue(MarketStructs.PoolInfo storage poolInfo, uint256 liquidity)
        internal
        view
        returns (uint256, uint256)
    {
        return (
            FullMath.mulDiv(liquidity, poolInfo.base, poolInfo.totalLiquidity),
            FullMath.mulDiv(liquidity, poolInfo.quote, poolInfo.totalLiquidity)
        );
    }

    function previewSwap(
        uint256 base,
        uint256 quote,
        SwapParams memory params,
        bool noRevert
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, params.feeRatio);

        if (params.isExactInput) {
            uint256 amountSubFee = params.amount.mulRatio(oneSubFeeRatio);
            if (params.isBaseToQuote) {
                // output = quote.sub(FullMath.mulDivRoundingUp(base, quote, base.add(amountSubFee)));
                output = FullMath.mulDiv(quote, amountSubFee, base.add(amountSubFee));
            } else {
                // output = base.sub(FullMath.mulDivRoundingUp(base, quote, quote.add(amountSubFee)));
                output = FullMath.mulDiv(base, amountSubFee, quote.add(amountSubFee));
            }
        } else {
            if (params.isBaseToQuote) {
                // output = FullMath.mulDivRoundingUp(base, quote, quote.sub(params.amount)).sub(base);
                output = FullMath.mulDivRoundingUp(base, params.amount, quote.sub(params.amount));
            } else {
                // output = FullMath.mulDivRoundingUp(base, quote, base.sub(params.amount)).sub(quote);
                output = FullMath.mulDivRoundingUp(quote, params.amount, base.sub(params.amount));
            }
            output = output.divRatioRoundingUp(oneSubFeeRatio);
        }
        if (!noRevert) {
            require(output > 0, "PL_SD: output is zero");
        }
    }

    function _solveQuadratic(uint256 b, uint256 cNeg) private pure returns (uint256) {
        return Math.sqrt(b.mul(b).add(cNeg.mul(4))).sub(b).div(2);
    }

    // must not revert
    function maxSwap(
        uint256 base,
        uint256 quote,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 feeRatio,
        uint256 priceBoundX96
    ) internal pure returns (uint256 output) {
        uint24 oneSubFeeRatio = PerpMath.subRatio(1e6, feeRatio);
        uint256 k = base.mul(quote);

        if (isBaseToQuote) {
            uint256 kDivP = FullMath.mulDiv(k, FixedPoint96.Q96, priceBoundX96);
            uint256 baseSqr = base.mul(base);
            if (kDivP <= baseSqr) return 0;
            uint256 cNeg = kDivP.sub(baseSqr);
            uint256 b = base.add(base.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        } else {
            // https://www.wolframalpha.com/input?i=%28x+%2B+a%29+*+%28x+%2B+a+*+%281+-+f%29%29+%3D+kp+solve+a
            uint256 kp = FullMath.mulDiv(k, priceBoundX96, FixedPoint96.Q96);
            uint256 quoteSqr = quote.mul(quote);
            if (kp <= quoteSqr) return 0;
            uint256 cNeg = kp.sub(quoteSqr);
            uint256 b = quote.add(quote.mulRatio(oneSubFeeRatio));
            output = _solveQuadratic(b.divRatio(oneSubFeeRatio), cNeg.divRatio(oneSubFeeRatio));
        }
        if (!isExactInput) {
            output = previewSwap(
                base,
                quote,
                SwapParams({ isBaseToQuote: isBaseToQuote, isExactInput: true, feeRatio: feeRatio, amount: output }),
                true
            );
        }
    }

    function getMarkPriceX96(
        uint256 base,
        uint256 quote,
        uint256 baseBalancePerShareX96
    ) internal pure returns (uint256) {
        return FullMath.mulDiv(getShareMarkPriceX96(base, quote), FixedPoint96.Q96, baseBalancePerShareX96);
    }

    function getShareMarkPriceX96(uint256 base, uint256 quote) internal pure returns (uint256) {
        return FullMath.mulDiv(quote, FixedPoint96.Q96, base);
    }

    function getLiquidityDeleveraged(
        uint256 poolCumBasePerLiquidityX96,
        uint256 poolCumQuotePerLiquidityX96,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) internal pure returns (int256, int256) {
        int256 basePerLiquidityX96 = poolCumBasePerLiquidityX96.toInt256().sub(cumBasePerLiquidityX96.toInt256());
        int256 quotePerLiquidityX96 = poolCumQuotePerLiquidityX96.toInt256().sub(cumQuotePerLiquidityX96.toInt256());

        return (
            liquidity.toInt256().mulDiv(basePerLiquidityX96, FixedPoint96.Q96),
            liquidity.toInt256().mulDiv(quotePerLiquidityX96, FixedPoint96.Q96)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { MarketStructs } from "./MarketStructs.sol";

library PriceLimitLibrary {
    using PerpMath for uint256;
    using SafeMath for uint256;

    function update(MarketStructs.PriceLimitInfo storage priceLimitInfo, MarketStructs.PriceLimitInfo memory value)
        internal
    {
        if (value.referenceTimestamp == 0) return;
        priceLimitInfo.referencePrice = value.referencePrice;
        priceLimitInfo.referenceTimestamp = value.referenceTimestamp;
        priceLimitInfo.emaPrice = value.emaPrice;
    }

    // referenceTimestamp == 0 indicates not updated
    function updateDry(
        MarketStructs.PriceLimitInfo storage priceLimitInfo,
        MarketStructs.PriceLimitConfig storage config,
        uint256 price
    ) internal view returns (MarketStructs.PriceLimitInfo memory updated) {
        uint256 currentTimestamp = block.timestamp;
        uint256 refTimestamp = priceLimitInfo.referenceTimestamp;
        if (currentTimestamp <= refTimestamp) {
            updated.referencePrice = priceLimitInfo.referencePrice;
            updated.emaPrice = priceLimitInfo.emaPrice;
            return updated;
        }

        uint256 elapsed = currentTimestamp.sub(refTimestamp);

        if (priceLimitInfo.referencePrice == 0) {
            updated.emaPrice = price;
        } else {
            uint32 emaSec = config.emaSec;
            uint256 denominator = elapsed.add(emaSec);
            updated.emaPrice = FullMath.mulDiv(priceLimitInfo.emaPrice, emaSec, denominator).add(
                FullMath.mulDiv(price, elapsed, denominator)
            );
        }

        updated.referencePrice = price;
        updated.referenceTimestamp = currentTimestamp;
    }

    function priceBound(
        uint256 referencePrice,
        uint256 emaPrice,
        MarketStructs.PriceLimitConfig storage config,
        bool isLiquidation,
        bool isUpperBound
    ) internal view returns (uint256 price) {
        uint256 referenceRange =
            referencePrice.mulRatio(isLiquidation ? config.liquidationRatio : config.normalOrderRatio);
        uint256 emaRange = emaPrice.mulRatio(isLiquidation ? config.emaLiquidationRatio : config.emaNormalOrderRatio);

        if (isUpperBound) {
            return Math.min(referencePrice.add(referenceRange), emaPrice.add(emaRange));
        } else {
            return Math.max(referencePrice.sub(referenceRange), emaPrice.sub(emaRange));
        }
    }
}