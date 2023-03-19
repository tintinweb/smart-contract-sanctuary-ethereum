/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}


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

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}



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

interface IVesting {
    struct LockParams {
        address owner;
        uint256 amount;
        uint256 startEmission;
        uint256 cliffEndEmission;
        uint256 endEmission;
    }

    function getLock (uint256 _lockID) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address);
    function convertSharesToTokens (uint256 _shares) external view returns (uint256);
    function convertTokensToShares (uint256 _tokens) external view returns (uint256);
    function getTokenLocksLength () external view returns (uint256);
    function getTokenLockIDAtIndex (uint256 _index) external view returns (uint256);
    function getUserLocksLength (address _user) external view returns (uint256);
    function getUserLockIDAtIndex (address _user, uint256 _index) external view returns (uint256);
    function getWithdrawableTokens (uint256 _lockID) external view returns (uint256);
    function getWithdrawableShares (uint256 _lockID) external view returns (uint256);
    function transferLockOwnership (uint256 _lockID, address payable _newOwner) external;
    function lockCrowdsale (address owner, uint256 amount, uint256 startEmission, uint256 cliffEndEmission, uint256 endEmission) external;
    function withdraw (uint256 _lockID, uint256 _amount) external;

}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract CrowdSale is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    struct StableCoinLP {
        IUniswapV2Pair pair;
        uint256 tokenIndex;
        uint256 decimals;
    }

    struct PresaleInfo {
        uint256 tokenPrice;
        uint256 maxSpendPerBuyer;
        uint256 hardcap;
        uint256 softcap;
        uint256 startBlock;
        uint256 endBlock;
        IERC20 token;
        bool withETH;
    }

    struct PresaleStatus {
        bool whitelistOnly;
        bool forceFailed;
        bool paused;
        bool vested;
        uint256 lockID;
        uint256 totalETHCollected;
        uint256 totalETHValueCollected;
        uint256 totalETHWithdrawn;
        uint256 totalTokensSold;
        uint256 numBuyers;
        bool initialized;
    }

    struct BuyerInfo {
        mapping(address => uint256) baseDeposited;
        uint256 ethDeposited;
        uint256 depositedValue;
        uint256 tokensOwed;
        uint256 withdrawAmount;
    }

    PresaleInfo public INFO;
    PresaleStatus public STATUS;
    IVesting public VESTING;
    mapping(address => BuyerInfo) public BUYERS;
    EnumerableSet.AddressSet private WHITELIST;
    EnumerableSet.AddressSet private BASE_TOKENS;
    IERC20[] public baseToken;
    address[] public stableCoins;
    uint256 public PRICE_DECIMALS = 6;
    mapping(address => uint256) public totalBaseCollected;
    mapping(address => uint256) public totalBaseWithdrawn;
    mapping (address => StableCoinLP) public stableCoinsLPs;
    event Deposit(address indexed user, uint256 amount, address baseToken);

    constructor() public {
        // WETH-USDC LP
        stableCoins.push(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        IUniswapV2Pair USDC_WETH_Pair = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
        uint tokenIndex0 = USDC_WETH_Pair.token0() == stableCoins[0] ? 0 : 1;
        stableCoinsLPs[stableCoins[0]] = StableCoinLP(USDC_WETH_Pair, tokenIndex0, 6);
        // WETH-DAI LP
        stableCoins.push(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        IUniswapV2Pair WETH_DAI_Pair = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
        uint tokenIndex1 = WETH_DAI_Pair.token0() == stableCoins[1] ? 0 : 1;
        stableCoinsLPs[stableCoins[1]] = StableCoinLP(WETH_DAI_Pair, tokenIndex1, 18);
        // WETH-USDT LP
        stableCoins.push(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        IUniswapV2Pair WETH_USDT_Pair = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);
        uint tokenIndex2 = WETH_USDT_Pair.token0() == stableCoins[2] ? 0 : 1;
        stableCoinsLPs[stableCoins[2]] = StableCoinLP(WETH_USDT_Pair, tokenIndex2, 6);
    }

    function getETHPrice() public view returns (uint256 price) {
        for(uint i = 0; i < stableCoins.length; i++) {
            StableCoinLP memory lp = stableCoinsLPs[stableCoins[i]];
            (uint112 reserve0, uint112 reserve1,) = lp.pair.getReserves();
            uint256 _price;
            if(reserve0 == 0 || reserve1 == 0) {
                _price = 0;
            } else {
                uint256 decimalsDifferences = 18 - lp.decimals;
                if(lp.tokenIndex == 0) {
                    _price = uint256(reserve0).mul(10**(18 + decimalsDifferences)).div(uint256(reserve1));
                } else {
                    _price = uint256(reserve1).mul(10**(18 + decimalsDifferences)).div(uint256(reserve0));
                }
            }
            price += _price;
        }
        price = price / stableCoins.length;
    }

    function init(
        address _token,
        address[] memory _baseToken,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _price,
        uint256 _maxSpend,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _withETH
    ) external onlyOwner {
        require(!STATUS.initialized, "ALREADY INITIALIZED");
        require(_startBlock < _endBlock, "INVALID DURATION");
        require(_hardcap >= _softcap, "INVALID HARDCAP");
        for(uint256 i = 0; i < _baseToken.length; i++) {
            baseToken.push(IERC20(_baseToken[i]));
            BASE_TOKENS.add(_baseToken[i]);
        }
        INFO.token = IERC20(_token);
        INFO.softcap = _softcap;
        INFO.hardcap = _hardcap;
        INFO.tokenPrice = _price;
        INFO.maxSpendPerBuyer = _maxSpend;
        INFO.startBlock = _startBlock;
        INFO.endBlock = _endBlock;
        INFO.withETH = _withETH;
        STATUS.initialized = true;
    }

    function updateVestingAddress(address _vesting) external onlyOwner {
        require(!STATUS.vested, "VESTED ALREADY");
        VESTING = IVesting(_vesting);
    }

    function getTotalCollectedValue() public view returns (uint256) {
        uint256 totalCollected = STATUS.totalETHValueCollected;
        for(uint256 i = 0; i < baseToken.length; i++) {
            address _baseToken = address(baseToken[i]);
            totalCollected = totalCollected.add(totalBaseCollected[_baseToken]);
        }
        return totalCollected;
    }

    function _isValidBaseToken(address _baseToken) internal view returns (bool) {
        return BASE_TOKENS.contains(_baseToken);
    }

    function presaleStatus() public view returns (uint256) {
        if (STATUS.forceFailed) {
            return 3; // FAILED - force fail
        }
        if(STATUS.paused) {
            return 4; // PAUSED - Wait for admin resume
        }
        if(!STATUS.initialized) {
            return 0;
        }
        uint256 _totalCollected = getTotalCollectedValue();
        if ((block.number > INFO.endBlock) && (_totalCollected < INFO.softcap)) {
            return 3; // FAILED - softcap not met by end block
        }
        if (_totalCollected >= INFO.hardcap) {
            return 2; // SUCCESS - hardcap met
        }
        if ((block.number > INFO.endBlock) && (_totalCollected >= INFO.softcap)) {
            return 2; // SUCCESS - end block and soft cap reached
        }
        if ((block.number >= INFO.startBlock) && (block.number <= INFO.endBlock)) {
            return 1; // ACTIVE - deposits enabled
        }
        return 0; // NOT STARTED - awaiting start block
    }

    function userDeposit (uint256 _amount, address _baseToken) external payable nonReentrant {
        require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
        if (STATUS.whitelistOnly) {
            require(WHITELIST.contains(_msgSender()), 'NOT WHITELISTED');
        }
        bool isETH = _baseToken == address(0);
        if(isETH) {
            require(INFO.withETH, "NOT ALLOWED TO PARTICIPATE WITH ETH");
        } else {
            require(_isValidBaseToken(_baseToken), "INVALID BASE TOKEN");
        }
        uint256 ethPrice = getETHPrice();
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amount_in = isETH ? msg.value : _amount;
        uint256 amountInValue = isETH ? amount_in.mul(ethPrice).div(10 ** 30) : _amount;
        uint256 allowance = INFO.maxSpendPerBuyer.sub(buyer.depositedValue);
        uint256 _totalCollected = getTotalCollectedValue();
        uint256 remaining = INFO.hardcap.sub(_totalCollected);
        allowance = allowance > remaining ? remaining : allowance;
        if (amountInValue > allowance) {
            amountInValue = allowance;
            amount_in = isETH ? allowance.mul(10**30).div(ethPrice) : allowance;
        }
        uint256 tokensSold = amountInValue.mul(10 ** PRICE_DECIMALS).mul(10 ** 12).div(INFO.tokenPrice);
        require(tokensSold > 0, 'ZERO TOKENS');
        if (buyer.depositedValue == 0) {
            STATUS.numBuyers++;
        }
        if(isETH) {
            buyer.ethDeposited = buyer.ethDeposited.add(amount_in);
            buyer.depositedValue = buyer.depositedValue.add(amountInValue);
            STATUS.totalETHCollected = STATUS.totalETHCollected.add(amount_in);
            STATUS.totalETHValueCollected = STATUS.totalETHValueCollected.add(amountInValue);
        } else {
            buyer.baseDeposited[_baseToken] = buyer.baseDeposited[_baseToken].add(amount_in);
            buyer.depositedValue = buyer.depositedValue.add(amount_in);
            totalBaseCollected[_baseToken] = totalBaseCollected[_baseToken].add(amount_in);
        }
        buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
        STATUS.totalTokensSold = STATUS.totalTokensSold.add(tokensSold);
        // return unused ETH
        if (isETH && amount_in < msg.value) {
            msg.sender.transfer(msg.value.sub(amount_in));
        }
        // deduct non ETH token from user
        if (!isETH) {
            TransferHelper.safeTransferFrom(_baseToken, msg.sender, address(this), amount_in);
        }
        emit Deposit(msg.sender, amount_in, _baseToken);
    }

    function getUserWithdrawable(address _user) public view returns (uint256) {
        if(!STATUS.vested) {
            return 0;
        }
        (,,, uint256 tokensWithdrawn,,,,,,) = VESTING.getLock(STATUS.lockID);
        uint256 withdrawable = VESTING.getWithdrawableTokens(STATUS.lockID);
        if(withdrawable == 0) {
            return 0;
        }
        uint256 userWithdrawable = tokensWithdrawn
            .add(withdrawable)
            .mul(BUYERS[_user].tokensOwed)
            .div(STATUS.totalTokensSold)
            .sub(BUYERS[_user].withdrawAmount);
        return userWithdrawable;
    }

    function userWithdrawAMFI() external nonReentrant {
        require(presaleStatus() == 2, 'NOT SUCCESS');
        require(STATUS.vested, "NOT FINALIZED");
        uint256 withdrawableAmount = getUserWithdrawable(_msgSender());
        require(withdrawableAmount > 0, "ZERO TOKEN");
        BuyerInfo storage buyer = BUYERS[_msgSender()];
        uint256 beforeBalance = INFO.token.balanceOf(address(this));
        VESTING.withdraw(STATUS.lockID, withdrawableAmount);
        uint256 amount = INFO.token.balanceOf(address(this)) - beforeBalance;
        buyer.withdrawAmount = buyer.withdrawAmount.add(amount);
        TransferHelper.safeTransfer(address(INFO.token), _msgSender(), amount);
    }

    function userWithdrawOnFail() external nonReentrant {
        require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
        _withdrawBaseTokens();
        _withdrawETHTokens();
    }

    function userWithdrawBaseTokens () external nonReentrant {
        require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
        _withdrawBaseTokens();
    }

    function _withdrawBaseTokens() internal {
        BuyerInfo storage buyer = BUYERS[msg.sender];
        for(uint256 i = 0; i < baseToken.length; i++) {
            address _baseToken = address(baseToken[i]);
            uint256 baseRemainingDenominator = totalBaseCollected[_baseToken].sub(totalBaseWithdrawn[_baseToken]);
            if(baseRemainingDenominator == 0) continue;
            uint256 remainingBaseBalance = baseToken[i].balanceOf(address(this));
            uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited[_baseToken]).div(baseRemainingDenominator);
            if(tokensOwed > 0) {
                totalBaseWithdrawn[_baseToken] = totalBaseWithdrawn[_baseToken].add(buyer.baseDeposited[_baseToken]);
                buyer.baseDeposited[_baseToken] = 0;
                TransferHelper.safeTransferBaseToken(_baseToken, msg.sender, tokensOwed, true);
            }
        }
    }

    function userWithdrawETHTokens() external nonReentrant {
        require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
        _withdrawETHTokens();
    }

    function _withdrawETHTokens() internal {
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 baseRemainingDenominator = STATUS.totalETHCollected.sub(STATUS.totalETHWithdrawn);
        if(baseRemainingDenominator == 0) return;
        uint256 remainingBaseBalance = INFO.withETH ? address(this).balance : 0;
        uint256 tokensOwed = remainingBaseBalance.mul(buyer.ethDeposited).div(baseRemainingDenominator);
        if(tokensOwed > 0) {
            STATUS.totalETHWithdrawn = STATUS.totalETHWithdrawn.add(buyer.ethDeposited);
            buyer.ethDeposited = 0;
            TransferHelper.safeTransferBaseToken(address(0), msg.sender, tokensOwed, false);
        }
    }

    function ownerWithdrawTokens() external onlyOwner {
        require(presaleStatus() == 3, "NOT FAILED"); // FAILED
        TransferHelper.safeTransfer(address(INFO.token), owner(), INFO.token.balanceOf(address(this)));
    }

    function ownerWithdraw() external onlyOwner {
        require(getTotalCollectedValue() >= INFO.softcap, "SOFT CAP DOESNT MET");
        TransferHelper.safeTransferBaseToken(address(0), msg.sender, address(this).balance, false);
        for(uint256 i = 0; i < baseToken.length; i++) {
            uint256 _balance = baseToken[i].balanceOf(address(this));
            address _baseToken = address(baseToken[i]);
            TransferHelper.safeTransferBaseToken(_baseToken, msg.sender, _balance, true);
        }
    }

    function finalizedCrowdSale(uint256 cliffEndEmission, uint256 endEmission) external onlyOwner {
        require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
        require(STATUS.initialized, "NOT INITIALIZED");
        require(!STATUS.vested, "FINALIZED ALREADY");
        require(cliffEndEmission < endEmission, "INVALID LOCK END DATE");
        require(0 < cliffEndEmission, "INVALID CLIFF END DATE");

        TransferHelper.safeTransferFrom(address(INFO.token), _msgSender(), address(this), STATUS.totalTokensSold);
        TransferHelper.safeApprove(address(INFO.token), address(VESTING), STATUS.totalTokensSold);

        VESTING.lockCrowdsale(
            address(this),
            STATUS.totalTokensSold,
            block.timestamp,
            block.timestamp + cliffEndEmission,
            block.timestamp + endEmission
        );

        STATUS.lockID = VESTING.getUserLockIDAtIndex(address(this), 0);
        STATUS.vested = true;
    }
    function earlyFinishCrowdSale() external onlyOwner {
        require(!STATUS.forceFailed, "FAILED");
        require(presaleStatus() == 1, "NOT ACTIVE"); // ACTIVE
        uint256 _totalCollected = getTotalCollectedValue();
        require(_totalCollected >= INFO.softcap, "SOFT CAP NOT REACHED");
        INFO.endBlock = block.number;
    }
    function updateLockID(uint256 _id) external onlyOwner {
        require(presaleStatus() == 2, "NOT SUCCESS"); // SUCCESS
        require(STATUS.initialized, "NOT INITIALIZED");
        require(!STATUS.vested, "FINALIZED ALREADY");
        STATUS.lockID = _id;
        STATUS.vested = true;
    }
    function forceFail() external onlyOwner {
        STATUS.forceFailed = true;
    }
    function togglePause() external onlyOwner {
        STATUS.paused = !STATUS.paused;
    }
    function updateMaxSpendLimit(uint256 _maxSpend) external onlyOwner {
        INFO.maxSpendPerBuyer = _maxSpend;
    }
    function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(INFO.startBlock > block.number, "ALREADY STARTED");
        require(_endBlock.sub(_startBlock) > 0, "INVALID BLOCKS");
        INFO.startBlock = _startBlock;
        INFO.endBlock = _endBlock;
    }
    function setWhitelistFlag(bool _flag) external onlyOwner {
        STATUS.whitelistOnly = _flag;
    }
    function editWhitelist(address[] memory _users, bool _add) external onlyOwner {
        if (_add) {
            for (uint i = 0; i < _users.length; i++) {
                WHITELIST.add(_users[i]);
            }
        } else {
            for (uint i = 0; i < _users.length; i++) {
                WHITELIST.remove(_users[i]);
            }
        }
    }
    function getWhitelistedUsersLength () external view returns (uint256) {
        return WHITELIST.length();
    }
    function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
        return WHITELIST.at(_index);
    }
    function getUserWhitelistStatus (address _user) external view returns (bool) {
        return WHITELIST.contains(_user);
    }
    function sweepETH() public onlyOwner {
        require(getTotalCollectedValue() >= INFO.softcap, "NOT SUCCESS"); // SUCCESS
        payable(owner()).transfer(address(this).balance);
    }
    function sweepETHToAddress(address _user) public onlyOwner {
        require(getTotalCollectedValue() >= INFO.softcap, "NOT SUCCESS"); // SUCCESS
        payable(_user).transfer(address(this).balance);
    }
    function sweepAnyTokens(address _token) public onlyOwner {
        if(getTotalCollectedValue() < INFO.softcap) {
            require(!BASE_TOKENS.contains(_token), "WITHDRAW BASE TOKENS");
        }
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
    function sweepAnyTokensToAddress(address _token, address _user) public onlyOwner {
        if(getTotalCollectedValue() < INFO.softcap) {
            require(!BASE_TOKENS.contains(_token), "WITHDRAW BASE TOKENS");
        }
        IERC20(_token).transfer(_user, IERC20(_token).balanceOf(address(this)));
    }
}