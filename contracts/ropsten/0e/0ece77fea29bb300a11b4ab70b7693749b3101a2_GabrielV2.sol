/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 < 0.9.0;
pragma abicoder v2;
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Gabby.sol

/// @title Archangel Reward Staking Pool V2 (GabrielV2)
/// @notice Stake tokens to Earn Rewards.
/// @dev All function calls are currently implemented without side effects
contract GabrielV2 is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public devaddr;
    address public growthFundAddr;

    uint devPercent;
    uint gfPercent;
    
    struct PoolInfo {
        IERC20 lpToken;
        uint totalStaked;
        uint totalValLocked;
        uint emergencyUnstaked;
        uint openTime;
        uint waitPeriod;
        uint lockTime;
        uint lockDuration;
        uint unlockTime;
        bool canStake;
        bool inWaitPeriod;
        bool canUnstake;
        uint NORT;
        address[] rewardToken;
        uint[] totalRewards;
        uint[] rewardsInPool;
    }
    PoolInfo[] public poolInfo;

    struct UserInfo {
        uint amount;
        bool harvested;
    }
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    struct ExtraArgs {
        IERC20 lpToken;
        uint openTime;
        uint waitPeriod;
        uint lockDuration;
    }

    struct ConstructorArgs {
        address devaddr;
        address growthFundAddr;
        uint devPercent;
        uint gfPercent;
    }

    event Stake(uint indexed pid, address indexed user, uint amount);
    event Unstake(uint indexed pid, address indexed user, uint amount);
    event Harvest(uint indexed pid, address indexed user,  uint amount);
    event EmergencyWithdraw(
        uint indexed pid,
        address indexed user,
        uint amount
    );
    event PercentsUpdated(uint indexed dev, uint indexed growthFund);
    event ReflectionsClaimed(
        uint indexed pid,
        address indexed token,
        uint indexed amount
    );
    event ForfeitedRewardsClaimed(
        uint indexed pid,
        address indexed token,
        uint indexed amount
    );

    constructor(
        ConstructorArgs memory constructorArgs,
        ExtraArgs memory extraArgs,
        uint _NORT,
        address[] memory _rewardTokens,
        uint[] memory _totalRewards
    ) {
        devaddr = constructorArgs.devaddr;
        growthFundAddr = constructorArgs.growthFundAddr;
        devPercent = constructorArgs.devPercent;
        gfPercent = constructorArgs.gfPercent;
        createPool(extraArgs, _NORT, _rewardTokens, _totalRewards);
    }

    /**
     * @notice Total number of pools that have been created
     * @return TotalPools 
     */
    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    /**
     * @notice Create a new pool
     * @dev struct extraArgs was used to prevent error "stack too deep"
     * @param extraArgs ["lpToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _totalRewards an array of token balances for each unique reward token in the pool
     */
    function createPool(ExtraArgs memory extraArgs, uint _NORT, address[] memory _rewardTokens, uint[] memory _totalRewards) public onlyOwner {
        require(_rewardTokens.length == _NORT && _rewardTokens.length == _totalRewards.length, "CP: array length mismatch");
        address[] memory rewardToken = new address[](_NORT);
        uint[] memory totalRewards = new uint[](_NORT);
        uint[] memory rewardsInPool = new uint[](_NORT);
        require(
            extraArgs.openTime > block.timestamp,
            "open time must be a future time"
        );

        require(extraArgs.waitPeriod > 0);

        uint _lockTime = extraArgs.openTime.add(extraArgs.waitPeriod);

        require(extraArgs.lockDuration > 0);

        require(
            _lockTime > block.timestamp && _lockTime + extraArgs.lockDuration > _lockTime,
            "unlock time must be greater than lock time"
        );
        uint _unlockTime = _lockTime.add(extraArgs.lockDuration);
        
        poolInfo.push(
            PoolInfo({
                lpToken: extraArgs.lpToken,
                totalStaked: 0,
                totalValLocked: 0,
                emergencyUnstaked: 0,
                openTime: extraArgs.openTime,
                waitPeriod: extraArgs.waitPeriod,
                lockTime: _lockTime,
                lockDuration: extraArgs.lockDuration,
                unlockTime: _unlockTime,
                canStake: false,
                inWaitPeriod: false,
                canUnstake: false,
                NORT: _NORT,
                rewardToken: rewardToken,
                totalRewards: totalRewards,
                rewardsInPool: rewardsInPool
            })
        );
        uint _pid = poolInfo.length - 1;
        PoolInfo storage pool = poolInfo[_pid];
        for (uint i = 0; i < _NORT; i++) {
            pool.rewardToken[i] = _rewardTokens[i];
            pool.totalRewards[i] = _totalRewards[i];
            pool.rewardsInPool[i] = _totalRewards[i];
        }
    }

    function _setTimeValues(
        uint _pid,
        uint _openTime,
        uint _waitPeriod,
        uint _lockDuration
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            _openTime > block.timestamp,
            "open time must be a future time"
        );
        pool.openTime = _openTime;

        require(_waitPeriod > 0);
        pool.waitPeriod = _waitPeriod;

        pool.lockTime = _openTime.add(_waitPeriod);

        require(_lockDuration > 0);
        pool.lockDuration = _lockDuration;

        require(
            pool.lockTime > block.timestamp &&
            pool.lockTime + _lockDuration > pool.lockTime,
            "unlock time must be greater than lock time"
        );
        pool.unlockTime = pool.lockTime.add(_lockDuration);
    }

    /**
     * @notice Set or modify the openTime, waitPeriod and lockDuration of a particular pool
     * @param _pid select the particular pool
     * @param _openTime unix timestamp
     * @param _waitPeriod exact number of seconds that pool will remain open
     * @param _lockDuration exact number of seconds that pool will remain locked.
     */
    function setTimeValues(
        uint _pid,
        uint _openTime,
        uint _waitPeriod,
        uint _lockDuration
    ) external onlyOwner {
        _setTimeValues(_pid, _openTime, _waitPeriod, _lockDuration);
        updatePool(_pid);
    }

    function updatePool(uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.openTime) {
            return;
        }
        if (
            block.timestamp > pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = false;
            pool.inWaitPeriod = false;
            pool.canUnstake = false;
        }
        if (
            block.timestamp > pool.openTime &&
            block.timestamp < pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = true;
            pool.inWaitPeriod = true;
            pool.canUnstake = false;
        }
        if (
            block.timestamp > pool.unlockTime &&
            pool.unlockTime > 0
        ) {
            pool.canUnstake = true;
            pool.canStake = false;
            pool.inWaitPeriod = false;
        }
    }

    function _changeNORT(uint _pid, uint _NORT) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory rewardToken = new address[](_NORT);
        uint[] memory totalRewards = new uint[](_NORT);
        uint[] memory rewardsInPool = new uint[](_NORT);
        pool.NORT = _NORT;
        pool.rewardToken = rewardToken;
        pool.totalRewards = totalRewards;
        pool.rewardsInPool = rewardsInPool;
    }

    /**
     * @notice Set or modify the number of reward tokens of a particular pool
     * @param _pid select the particular pool
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     */
    function changeNORT(uint _pid, uint _NORT) external onlyOwner {
        _changeNORT(_pid, _NORT);
    }

    /**
     * @notice Set or modify the address of the different reward tokens of a particular pool
     * @param _pid select the particular pool
     * @param _rewardTokens array of reward token addresses
     */
    function changeRewardTokens(uint _pid, address[] memory _rewardTokens) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint NORT = pool.NORT;
        for (uint i = 0; i < NORT; i++) {
            pool.rewardToken[i] = _rewardTokens[i];
        }
    }

    function tokensInPool(uint _pid) external view returns (address[] memory rewardTokens) {
        PoolInfo storage pool = poolInfo[_pid];
        rewardTokens = pool.rewardToken;
    }

    /**
     * @notice Set or modify the token balances of a particular pool
     * @param _pid select the particular pool
     * @param rewards array of token balances for each reward token in the pool
     */
    function setTotalRewards(uint _pid, uint[] memory rewards) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint len = pool.NORT;
        require(rewards.length == len, "STR: array length mismatch");
        for (uint i = 0; i < len; i++) {
            pool.totalRewards[i] = rewards[i];
            pool.rewardsInPool[i] = rewards[i];
        }
    }

    function totalReward(uint _pid) external view returns (uint[] memory totalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        totalRewards = pool.totalRewards;
    }

    function rewardInPool(uint _pid) external view returns (uint[] memory rewardsInPool) {
        PoolInfo storage pool = poolInfo[_pid];
        rewardsInPool = pool.rewardsInPool;
    }

    /**
     * @notice Reset all the values of a particular pool
     * @dev struct extraArgs was used to prevent error "stack too deep"
     * @param extraArgs ["lpToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _totalRewards an array containing the amount of rewards for each unique reward token.
     */
    function reusePool(uint _pid, ExtraArgs memory extraArgs, uint _NORT, address[] memory _rewardTokens, uint[] memory _totalRewards) external onlyOwner {
        require(
            _rewardTokens.length == _NORT &&
            _rewardTokens.length == _totalRewards.length,
            "RP: array length mismatch"
        );
        PoolInfo storage pool = poolInfo[_pid];
        pool.lpToken = extraArgs.lpToken;
        pool.totalStaked = 0;
        pool.totalValLocked = 0;
        pool.emergencyUnstaked = 0;
        // Set Time Values.
        _setTimeValues( _pid, extraArgs.openTime, extraArgs.waitPeriod, extraArgs.lockDuration);
        // Update Pool to set bool canStake, inWaitPeriod, canUnstake.
        updatePool(_pid);
        _changeNORT(_pid, _NORT);
        for (uint i = 0; i < _NORT; i++) {
            pool.rewardToken[i] = _rewardTokens[i];
            pool.totalRewards[i] = _totalRewards[i];
            pool.rewardsInPool[i] = _totalRewards[i];
        }
    }

    function unclaimedRewards(uint _pid, address _user)
        external
        view
        returns (uint[] memory unclaimedReward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint NORT = pool.NORT;
        if (block.timestamp > pool.lockTime && block.timestamp < pool.unlockTime) {
            if (block.timestamp > pool.lockTime && pool.totalStaked != 0) {
                uint[] memory array = new uint[](NORT);
                for (uint i = 0; i < NORT; i++) {
                    uint blocks = block.timestamp.sub(pool.lockTime);
                    uint reward = blocks * user.amount * pool.totalRewards[i];
                    uint lpSupply = pool.totalStaked * pool.lockDuration;
                    uint pending = reward.div(lpSupply);
                    array[i] = pending;
                }
                return array;
                
            }
        } else if (block.timestamp > pool.unlockTime) {
            uint[] memory array = new uint[](NORT);
            for (uint i = 0; i < NORT; i++) {                
                uint reward = pool.lockDuration * user.amount * pool.totalRewards[i];
                uint lpSupply = pool.totalStaked * pool.lockDuration;
                uint pending = reward.div(lpSupply);
                array[i] = pending;
            }
            return array;
        } else {
            uint[] memory array = new uint[](NORT);
            return array;
        }        
    }

    /**
     * @notice Stake ERC20 tokens to earn rewards
     * @param _pid select the particular pool
     * @param _amount amount of tokens to be deposited by user
     */
    function stake(uint _pid, uint _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.lockTime && pool.canStake == true) {
            pool.canStake = false;
        }
        if (block.timestamp < pool.lockTime && pool.canStake == false) {
            pool.canStake = true;
        }
        require(
            pool.canStake == true,
            "Waiting Period has ended, pool is now locked"
        );
        updatePool(_pid);
        if (_amount <= 0) {
            return;
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        pool.totalStaked = pool.totalStaked.add(_amount);
        pool.totalValLocked = pool.totalValLocked.add(_amount);
        emit Stake(_pid, msg.sender, _amount);
    }

    /**
     * @notice Harvest your earnings
     * @dev Expected Behaviour: Sends out rewards, leaves stake, user.amount remains the same
     * @param _pid select the particular pool
     */
    function harvest(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.unlockTime && pool.canUnstake == false) {
            pool.canUnstake = true;
        }
        require(pool.canUnstake == true, "Pool is still locked");
        // should only allow people that staked to unstake
        require(user.amount > 0 && user.harvested == false, "forbid withdraw");
        updatePool(_pid);
        uint NORT = pool.NORT;
        for (uint i = 0; i < NORT; i++) {
            uint reward = pool.lockDuration * user.amount * pool.totalRewards[i];
            uint lpSupply = pool.totalStaked * pool.lockDuration;
            uint pending = reward.div(lpSupply);
            if (pending > 0) {
                uint forfeitedRwds = (pool.emergencyUnstaked *
                    pool.lockDuration *
                    pool.totalRewards[i]) / (pool.totalStaked * pool.lockDuration);
                /** Should send only yet-to-claim rewards
                 *  yetToClaimRwds = pool.rewardsInPool - forfeitedRwds
                 */
                uint tokenBal = pool.rewardsInPool[i].sub(forfeitedRwds);
                if (pending > tokenBal) {
                    IERC20(pool.rewardToken[i]).safeTransfer(msg.sender, tokenBal);
                } else {
                    IERC20(pool.rewardToken[i]).safeTransfer(msg.sender, pending);
                }
                // To Know the actual amount of reward remaining in the pool
                pool.rewardsInPool[i] = pool.rewardsInPool[i].sub(pending);
                emit Harvest(_pid, msg.sender, pending);
            }
        }
        // totalValLocked will reduce but user.amount remains same.
        pool.totalValLocked = pool.totalValLocked.sub(user.amount);
        // register that the user has already harvested, so he cannot harvest again
        user.harvested = true;
    }

    /// @notice Exit without caring about rewards. EMERGENCY ONLY.
    /// @param _pid select the particular pool
    function emergencyWithdraw(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        // will be used to calculate total forfeited rewards
        pool.emergencyUnstaked = pool.emergencyUnstaked.add(user.amount);
        // Decrease TVL so it will reflect in UI
        pool.totalValLocked = pool.totalValLocked.sub(user.amount);
        emit EmergencyWithdraw(_pid, msg.sender, user.amount);
        user.amount = 0;
    }

    /// @notice Update dev address by the previous dev.
    function dev(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    /// @notice Update Growth Fund Address.
    function growthFund(address _growthFundAddr) external onlyOwner {
        growthFundAddr = _growthFundAddr;
    }

    /**
     * @notice function to recover tokens that were mistakenly sent to this contract
     * @param tokenAddress address of the ERC20 to to be released
     * @param amount amount of tokens to be recovered
     */
    function release(address tokenAddress, uint amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);
    }

    function changePercents(uint _devPercent, uint _gfPercent) external onlyOwner {
        require(_devPercent.add(_gfPercent) == 100, "must sum up to 100%");
        devPercent = _devPercent;
        gfPercent = _gfPercent;
        emit PercentsUpdated(_devPercent, _gfPercent);
    }

    /// @notice function to claim reflections
    /// @dev reflections can only be claimed after all users have harvested their rewards
    function withdraw(uint _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            block.timestamp > pool.unlockTime && pool.totalValLocked == 0,
            "all users need to unstake"
        );
        uint NORT = pool.NORT;
        for (uint i = 0; i < NORT; i++) {
            uint tStaked = pool.totalValLocked;
            /** After the last user unstakes, we check if any user forfeited their rewards.
             *  uint forfeitedRwds = pool.rewardsInPool;
             */
            uint forfeitedRwds = (pool.emergencyUnstaked *
                pool.lockDuration *
                pool.totalRewards[i]) / (pool.totalStaked * pool.lockDuration);
            // tStaked will be eqaul to zero when the last person unstakes.
            if (tStaked == 0) {
                // Calculate the LOR.
                uint poolBal = IERC20(pool.rewardToken[i]).balanceOf(address(this));
                // remember that tStaked = 0
                uint min = tStaked.add(forfeitedRwds);
                if (poolBal > min) {
                    /** LOR is the reflections that will enter this contract address due to the fact that the contract holds ARCHA tokens
                     *  The Important amounts that are in the pool are:
                     *  totalStaked --> The total amount of lpTokens deposited by users to the pool
                     *  forfeitedRewards --> After all users have unstaked, rewardsInPool should be equal to forfeitedRewards.
                     *  Note: After adding all these amounts together, and subtracting from poolBal, any tokens left should be LOR.
                     */
                    uint LOR = poolBal.sub(min);
                    if (LOR > 0) {
                        // Split LOR
                        uint onePercent = LOR.div(100);
                        uint devShare = devPercent.mul(onePercent);
                        uint gfShare = LOR.sub(devShare);
                        // Transfer devShare to devaddr, for code maintenance
                        IERC20(pool.rewardToken[i]).safeTransfer(devaddr, devShare);
                        // Transfer gfShare to growthFundAddr, to store funds for future growth of this project
                        IERC20(pool.rewardToken[i]).safeTransfer(growthFundAddr, gfShare);
                        emit ReflectionsClaimed(_pid, pool.rewardToken[i], LOR);
                    }
                }
                // If any user forfeited their rewards, it will remain in the pool after LOR is sent to devaddr & growthFundAddr
                // if there is any forfieted reward, send it to grwothFundAddr.
                if (forfeitedRwds > 0) {
                    poolBal = IERC20(pool.rewardToken[i]).balanceOf(address(this));
                    if (forfeitedRwds > poolBal) {
                        IERC20(pool.rewardToken[i]).safeTransfer(growthFundAddr, poolBal);
                        emit ForfeitedRewardsClaimed(_pid, pool.rewardToken[i], poolBal);
                    } else {
                        IERC20(pool.rewardToken[i]).safeTransfer(growthFundAddr, forfeitedRwds);
                        emit ForfeitedRewardsClaimed(_pid, pool.rewardToken[i], forfeitedRwds);
                    }
                }
                pool.totalStaked = 0;
                pool.emergencyUnstaked = 0;
                pool.rewardsInPool[i] = 0;
            }
        }
    }
}