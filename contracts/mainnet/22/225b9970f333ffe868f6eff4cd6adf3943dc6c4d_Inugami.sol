/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
/*
Inugami(GAMI)

We are Inugami, We are many.

weareinugami.com

*/

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: Inugami/OwnerAdminSettings.sol



pragma solidity >=0.8.0 <0.9.0;



contract OwnerAdminSettings is ReentrancyGuard, Context {

  address internal _owner;

  struct Admin {
        address WA;
        uint8 roleLevel;
  }
  mapping(address => Admin) internal admins;

  mapping(address => bool) internal isAdminRole;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 
            );
    _;
  }

  modifier onlyDev() {
    require(admins[_msgSender()].roleLevel == 1);
    _;
  }

  modifier onlyAntiBot() {
    require(admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2
            );
    _;
  }

  modifier onlyAdminRoles() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2 || 
            admins[_msgSender()].roleLevel == 5
            );
    _;
  }

  constructor() {
    _owner = _msgSender();
    _setNewAdmins(_msgSender(), 1);
  }
    //DON'T FORGET TO SET Locker AND Marketing(AND ALSO WHITELISTING Marketing) AFTER DEPLOYING THE CONTRACT!!!
    //DON'T FORGET TO SET ADMINS!!

  //Owner and Admins
  //Set New Owner. Can be done only by the owner.
  function setNewOwner(address newOwner) external onlyOwner {
    require(newOwner != _owner, "This address is already the owner!");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

    //Sets up admin accounts.
    function setNewAdmin(address _address, uint8 _roleLevel) external onlyOwner {
      if(_roleLevel == 1) {
        require(admins[_msgSender()].roleLevel == 1, "You are not authorized to set a dev");
      }
      
      _setNewAdmins(_address, _roleLevel);
    }

    function _setNewAdmins(address _address, uint8 _roleLevel) internal {

            Admin storage newAdmin = admins[_address];
            newAdmin.WA = _address;
            newAdmin.roleLevel = _roleLevel;
 
        isAdminRole[_address] = true;
    } 
/*
    function verifyAdminMember(address adr) public view returns(bool YoN, uint8 role_) {
        uint256 iterations = 0;
        while(iterations < adminAccounts.length) {
            if(adminAccounts[iterations] == adr) {return (true, admins[adminAccounts[iterations]].role);}
            iterations++;
        }
        return (false, 0);
    }
*/
    function removeRole(address[] calldata adr) external onlyOwner {
        for(uint i=0; i < adr.length; i++) {
            _removeRole(adr[i]);
        }
    }

    function renounceMyRole(address adr) external onlyAdminRoles {
        require(adr == _msgSender(), "AccessControl: can only renounce roles for self");
        require(isAdminRole[adr] == true, "You do not have an admin role");
        _removeRole(adr);
    }

    function _removeRole(address adr) internal {

          delete admins[adr];
  
        isAdminRole[adr] = false;
    }
  
  //public
    function whoIsOwner() external view returns (address) {
      return getOwner();
    }

    function verifyAdminMember(address adr) external view returns (bool) {
      return isAdminRole[adr];
    }

    function showAdminRoleLevel(address adr) external view returns (uint8) {
      return admins[adr].roleLevel;
    }

  //internal

    function getOwner() internal view returns (address) {
      return _owner;
    }

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


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

// File: Inugami/Inugami.sol



/*
Inugami(GAMI)

We are Inugami, We are many.

weareinugami.com

*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

interface IRouter01 {
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

interface IRouter02 is IRouter01 {
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





contract Inugami is IERC20, OwnerAdminSettings {

// Library
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    using Address for address;

//Token Variables
    string constant private _name = "Inugami";
    string constant private _symbol = "GAMI";

    uint64 constant private startingSupply = 100_000_000_000; //100 Billion, underscores aid readability
    uint8 constant private _decimals = 18;
    uint256 constant private MAX = ~uint256(0);

    uint256 constant private _tTotal = startingSupply * 10**_decimals;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

//Router, LP Pair Variables
    IRouter02 public dexRouter;
    address public pairAddr;

    mapping (address => bool) dexRouters;
    mapping (address => bool) lpPairs;

    //Routers
    struct DexRouter {
        bool enableAggregate;
    }
    mapping(address => DexRouter) public dexrouters;
    
    //LP Pairs
    struct LPPair {
        address dexCA;
        address pairedCoinCA;
        bool launched;
        bool tradingEnabled;
        bool liqAdded;
        bool contractSwapEnabled;
        bool piContractSwapEnabled;
        uint8 piSwapBps;
        uint32 tradingEnabledBlock;
        uint48 tradingEnabledTime;
        uint256 swapThreshold;
        uint256 swapAmount;
    }
    mapping(address => LPPair) public lppairs;

    mapping (address => EnumerableSet.AddressSet) _lpPairs;

    event NewDexRouter(address dexRouterCA);
    event NewLPPair(address dexRouterCA, address LPPairCA, address pairedCoinCA);
    event DexRouterStatusUpdated(address dexRouterCA, bool status);
    event PairEnabled(address LPPair, uint32 EnabledBlock, uint48 EnabledTime);
    event PairDisabled(address LPPair, uint32 DisabledBlock, uint48 DisabledTime);

//Fee Variables


    struct Taxes {
        uint16 buyTax;
        uint16 sellTax;
        uint16 transferTax;
    }

    Taxes public _taxes = Taxes({
        buyTax: 400,
        sellTax: 400,
        transferTax: 0
        });

    struct Ratios {
        uint32 liquidity;
        uint32 marketing;
        uint32 totalSwap;
    }

    Ratios public _ratios = Ratios({
        liquidity: 200,
        marketing: 200,
        totalSwap: 400
        });

    Ratios public _ratiosBuy = Ratios({
        liquidity: 200,
        marketing: 200,
        totalSwap: 400
        });

    Ratios public _ratiosSell = Ratios({
        liquidity: 200,
        marketing: 200,
        totalSwap: 400
        });

    Ratios public _ratiosTransfer = Ratios({
        liquidity: 200,
        marketing: 200,
        totalSwap: 400
        });

    Ratios private _ratiosActive = Ratios({
        liquidity: 200,
        marketing: 200,
        totalSwap: 400
        });

    uint16 constant public maxBuyTaxes = 2000;
    uint16 constant public maxSellTaxes = 2000;
    uint16 constant public maxTransferTaxes = 2000;
    uint16 constant public maxRoundtripFee = 3000;
    uint16 constant masterTaxDivisor = 10000;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isExcludedFromProtection;


    struct TaxWallets {
        address marketing;
        address lpLocker;
    }

    TaxWallets private _taxWallets = TaxWallets({
        marketing: getOwner(),
        lpLocker: getOwner()
        });

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

//Tx & Wallet Variables
    uint16 constant masterDivisor = 10000;
    uint16 public _maxTxBps = 100; // 1%
    uint256 private _maxTxAmount = (_tTotal * _maxTxBps) / masterDivisor; // 1%
    uint256 public maxTxAmountUI = (startingSupply * _maxTxBps) / masterDivisor; // Actual amount for UI's
    uint16 public _maxWalletBps = 100; // 1%
    uint256 private _maxWalletSize = (_tTotal * _maxWalletBps) / masterDivisor; // 1%
    uint256 public maxWalletAmountUI = (startingSupply * _maxWalletBps) / masterDivisor; // Actual amount for UI's


    //Contract Swap
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool public inSwap;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;

    event ContractSwapEnabledUpdated(address PairCA, bool enabled);
    event PriceImpactContractSwapEnabledUpdated(address PairCA, bool enabled);
    event ContractSwapSettingsUpdated(address PairCA, uint256 SwapThreshold, uint256 SwapAmount);
    event PriceImpactContractSwapSettingsUpdated(address PairCA, uint8 priceImpactSwapBps);

    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);


    constructor (
        bool LPwithEth_ToF_,
        address LPTargetCoinCA_,
        address marketing_,
        address lpLocker_
    ) OwnerAdminSettings() {
        if(LPwithEth_ToF_ == false){
            require(LPTargetCoinCA_ != address(0), "Must Provide LP Target Token Contract Address!");
        }

        address _routerAddr;
        if (block.chainid == 56) {
            _routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //BNB on mainnet, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        } else if (block.chainid == 97) {
            _routerAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; //BNB on testnet, 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
        } else if (block.chainid == 1 || block.chainid == 5 || block.chainid == 4 || block.chainid == 3) {
            _routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //WETH on Mainnet, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2. Goerli(id:5) testnet, 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
        } else {
            revert();
        }

        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_taxWallets.marketing] = true;
        _isExcludedFromFees[_taxWallets.lpLocker] = true;
        _isExcludedFromLimits[_msgSender()] = true;
        _isExcludedFromLimits[_owner] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[_taxWallets.marketing] = true;
        _isExcludedFromLimits[_taxWallets.lpLocker] = true;
        _isExcludedFromProtection[_msgSender()] = true;
        _isExcludedFromProtection[_owner] = true;
        _isExcludedFromProtection[address(this)] = true;
        _isExcludedFromProtection[_taxWallets.marketing] = true;
        _isExcludedFromProtection[_taxWallets.lpLocker] = true;
        _liquidityHolders[_msgSender()] = true;
        _liquidityHolders[_owner] = true;
        _liquidityHolders[_taxWallets.lpLocker] = true;

        _tOwned[_msgSender()] = _tTotal;

        _setNewRouterAndPair(_routerAddr, LPwithEth_ToF_, LPTargetCoinCA_);

        _taxWallets.marketing = marketing_;
        _taxWallets.lpLocker = lpLocker_;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

//===============================================================================================================
//Override Functions

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

//===============================================================================================================
//Dex Router and LPPair Manager Functions

    function enablePairTrading(address lpPairAddr, bool _switch) external onlyDev {
        if(!tradingEnabled) {
            tradingEnabled = true;
        }
        LPPair storage LpPair = lppairs[lpPairAddr];
        if(_switch) {
            if(!LpPair.launched) {
                require(LpPair.liqAdded, "Liquidity must be added.");
                LpPair.launched = true;

                LpPair.piSwapBps = 200; // 2%;
                LpPair.swapThreshold = (_tTotal * 10) / 10000; //0.1%
                LpPair.swapAmount = (_tTotal * 11) / 10000; //0.11%

                LpPair.piContractSwapEnabled = true;
                LpPair.tradingEnabledBlock = uint32(block.number);
                LpPair.tradingEnabledTime = uint48(block.timestamp);
            }
            LpPair.tradingEnabled = _switch;
            emit PairEnabled(lpPairAddr, uint32(block.number), uint48(block.timestamp));
        } else if(!_switch) {
            LpPair.tradingEnabled = _switch;
            emit PairDisabled(lpPairAddr, uint32(block.number), uint48(block.timestamp));
        }

    }

    function setNewRouterAndPair(address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA) external onlyOwner {
        _setNewRouterAndPair(_routerAddr, _LPwithETH_ToF, _LPTargetCoinCA);
    }

    function _setNewRouterAndPair(address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA) internal {
        if (dexRouters[_routerAddr] == false) {

            DexRouter storage router = dexrouters[_routerAddr];
            router.enableAggregate = true;

            dexRouters[_routerAddr] = true;

            emit NewDexRouter(_routerAddr);

            _setNewPair(_routerAddr, _LPwithETH_ToF, _LPTargetCoinCA);
        } else {
            dexRouter = IRouter02(_routerAddr);
            address get_pair;
            if (_LPwithETH_ToF){
                _LPTargetCoinCA = dexRouter.WETH();
                get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, address(this));
                require(lpPairs[get_pair] == false, "Pair already exists!");

                _setNewPair(_routerAddr, _LPwithETH_ToF, _LPTargetCoinCA);
            } else {
                get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, address(this));
                require(lpPairs[get_pair] == false, "Pair already exists!");

                _setNewPair(_routerAddr, _LPwithETH_ToF, _LPTargetCoinCA);
            }
        }
    }

    function _setNewPair(address _routerAddr, bool _LPwithETH_ToF, address _LPTargetCoinCA) internal {
        dexRouter = IRouter02(_routerAddr);
        address lpPairCA;
        address get_pair;

        if (_LPwithETH_ToF){
            _LPTargetCoinCA = dexRouter.WETH();
            get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, address(this));
            if (get_pair.isContract()){
                lpPairCA = get_pair;
            } else {
                lpPairCA = IFactoryV2(dexRouter.factory()).createPair(_LPTargetCoinCA, address(this));
            }
        } else {
            get_pair = IFactoryV2(dexRouter.factory()).getPair(_LPTargetCoinCA, address(this));
            if (get_pair.isContract()){
                lpPairCA = get_pair;
            } else {
                lpPairCA = IFactoryV2(dexRouter.factory()).createPair(_LPTargetCoinCA, address(this));
            }            
        }

        LPPair storage lpPair = lppairs[lpPairCA];
        lpPair.dexCA = _routerAddr;
        lpPair.pairedCoinCA = _LPTargetCoinCA;
        lpPair.launched = false;
        lpPair.tradingEnabled = false;
        lpPair.liqAdded = false;
        lpPair.contractSwapEnabled = false;
        lpPair.piContractSwapEnabled = false;
        lpPair.piSwapBps = 0;
        lpPair.tradingEnabledBlock = 0;
        lpPair.tradingEnabledTime = 0;
        lpPair.swapThreshold = 0;
        lpPair.swapAmount = 0;

        lpPairs[lpPairCA] = true;

        _addLPPair(_routerAddr, lpPairCA);
        _addLPPair(address(this), lpPairCA);

        _isExcludedFromFees[_routerAddr] = true;
        _isExcludedFromLimits[_routerAddr] = true;
        _isExcludedFromProtection[_routerAddr] = true;
        _liquidityHolders[_routerAddr] = true;

        _approve(_msgSender(), _routerAddr, type(uint256).max);
        _approve(_owner, _routerAddr, type(uint256).max);
        _approve(address(this), _routerAddr, type(uint256).max);

        IERC20(lpPairCA).approve(_routerAddr, type(uint256).max);
        _allowances[address(this)][_routerAddr] = type(uint256).max;

        emit NewLPPair(_routerAddr, lpPairCA, _LPTargetCoinCA);
    }

    function _addLPPair(address tokenOrRouterCA, address _lpPairCA) internal {
        _lpPairs[tokenOrRouterCA].add(_lpPairCA);
    }

    function _removeLPPair(address tokenOrRouterCA, address _lpPairCA) external onlyOwner {
        _lpPairs[tokenOrRouterCA].remove(_lpPairCA);
    }

    /**
     * @dev Returns the number of LPPairs that belongs to `tokenOrRouterCA`. Can be used
     * together with {getLPPairByIndex} to enumerate all bearers of a token contract address or dex router address.
     */

    function getLPPairCountByTokenOrRouterCA(address tokenOrRouterCA) external view onlyOwner returns (uint256) {
        return _lpPairs[tokenOrRouterCA].length();
    }

    function getLPPairByIndex(address tokenOrRouterCA, uint256 index) external view onlyOwner returns (address) {
        return _lpPairs[tokenOrRouterCA].at(index);
    }

    function getAllLPPairsByTokenOrRouterCA(address tokenOrRouterCA) external view onlyOwner returns (address[] memory) {
        return _lpPairs[tokenOrRouterCA].values();
    }


    function setRouterTrading(address _routerAddr, bool _switch) external onlyDev {
        dexrouters[_routerAddr].enableAggregate = _switch;

        emit DexRouterStatusUpdated(_routerAddr, _switch);
    }


//===============================================================================================================
//Fee Settings

    //Set Fees and its Ratios

    function setTaxes(uint16 buyTax, uint16 sellTax, uint16 transferTax) external onlyOwner returns (bool) {
        require(buyTax <= maxBuyTaxes
                && sellTax <= maxSellTaxes
                && transferTax <= maxTransferTaxes,
                "Cannot exceed maximums.");
        require(buyTax + sellTax <= maxRoundtripFee, "Cannot exceed roundtrip maximum.");
        bool confirmed = false;

        if(_taxes.buyTax != buyTax) {
            _taxes.buyTax = buyTax;
            confirmed = updateBuyTaxUsingRatio();
        }
        
        if(_taxes.sellTax != sellTax) {
            _taxes.sellTax = sellTax;
            confirmed = updateSellTaxUsingRatio();
        }
        
        if(_taxes.transferTax != transferTax) {
            _taxes.transferTax = transferTax;
            confirmed = updateTransferTaxUsingRatio();
        }

        return confirmed;
    }

      /*
      Ratios mapping legend (BuyOrSellOrTrnsfr):
        1 - _ratios
        2 - _ratiosBuy
        4 - _ratiosSell
        8 - _ratiosTransfer
      */

    function setRatios(uint16 liquidity, uint16 marketing) external onlyOwner returns (bool) {
        _ratios.totalSwap = liquidity + marketing;
        bool confirmed = false;

        if(_ratios.liquidity != liquidity) {
            _ratios.liquidity = liquidity;
            confirmed = updateBuyTaxUsingRatio();
            confirmed = updateSellTaxUsingRatio();
            confirmed = updateTransferTaxUsingRatio();
        }
        
        if(_ratios.marketing != marketing) {
            _ratios.marketing = marketing;
            confirmed = updateBuyTaxUsingRatio();
            confirmed = updateSellTaxUsingRatio();
            confirmed = updateTransferTaxUsingRatio();
        }

        return confirmed;
    }

    function updateBuyTaxUsingRatio() private returns (bool) {
        {
        _ratiosBuy.liquidity = _taxes.buyTax * _ratios.liquidity / _ratios.totalSwap;
        _ratiosBuy.marketing = _taxes.buyTax * _ratios.marketing / _ratios.totalSwap;
        _ratiosBuy.totalSwap = _ratiosBuy.liquidity + _ratiosBuy.marketing;
        }
        return true;
    }

    function updateSellTaxUsingRatio() private returns (bool) {
        {
        _ratiosSell.liquidity = _taxes.sellTax * _ratios.liquidity / _ratios.totalSwap;
        _ratiosSell.marketing = _taxes.sellTax * _ratios.marketing / _ratios.totalSwap;
        _ratiosSell.totalSwap = _ratiosSell.liquidity + _ratiosSell.marketing;
        }
        return true;
    }

    function updateTransferTaxUsingRatio() private returns (bool) {
        {
        _ratiosTransfer.liquidity = _taxes.transferTax * _ratios.liquidity / _ratios.totalSwap;
        _ratiosTransfer.marketing = _taxes.transferTax * _ratios.marketing / _ratios.totalSwap;
        _ratiosTransfer.totalSwap = _ratiosTransfer.liquidity + _ratiosTransfer.marketing;
        }
        return true;
    }

    //Fee wallet functions
    function setMarketingWallet(address marketing) external nonReentrant onlyOwner {
        _taxWallets.marketing = marketing;
        _isExcludedFromFees[marketing] = true;
    }

    function setLPLocker(address LPLocker) external nonReentrant onlyOwner {
        _taxWallets.lpLocker = LPLocker;
        _isExcludedFromFees[LPLocker] = true;
    }

    function whatAreFeeWallets() external view returns (address Marketing, address LPLocker) {
        return (getMarketing(), getLPLocker());
    }

    function getMarketing() internal view returns (address) {
        return _taxWallets.marketing;
    }

    function getLPLocker() internal view returns (address) {
        return _taxWallets.lpLocker;
    }

//===============================================================================================================
//Tx & User Wallet Settings

    //Max Tx & Max Wallet functions
    function setMaxTxPercent(uint16 bps) external nonReentrant onlyOwner {
        require((_tTotal * bps) / masterDivisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxBps = bps;
        _maxTxAmount = (_tTotal * bps) / masterDivisor;
    }

    function setMaxWalletSize(uint16 bps) external nonReentrant onlyOwner {
        require((_tTotal * bps) / masterDivisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletBps = bps;
        _maxWalletSize = (_tTotal * bps) / masterDivisor;
    }

    function setExcludedFromFees(address account, bool _switch) external nonReentrant onlyOwner {
        _isExcludedFromFees[account] = _switch;
    }

    function setExcludedFromLimits(address account, bool _switch) external nonReentrant onlyOwner {
        _isExcludedFromLimits[account] = _switch;
    }

    function setExcludedFromProtection(address account, bool _switch) external nonReentrant onlyOwner {
        _isExcludedFromProtection[account] = _switch;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && admins[from].roleLevel != 1
            && admins[to].roleLevel != 1
            && admins[from].roleLevel != 2
            && admins[to].roleLevel != 2;
    }

//===============================================================================================================

    //Contract Swap functions

    function setContractSwapEnabled(address pairCA, bool swapEnabled) external onlyOwner {
        require(lppairs[pairCA].contractSwapEnabled != swapEnabled, "Already set at the desired state.");
        lppairs[pairCA].contractSwapEnabled = swapEnabled;

        emit ContractSwapEnabledUpdated(pairCA, swapEnabled);
    }

    function setContractPriceImpactSwapEnabled(address pairCA, bool priceImpactSwapEnabled) external onlyOwner {
        require(lppairs[pairCA].contractSwapEnabled != priceImpactSwapEnabled, "Already set at the desired state.");
        lppairs[pairCA].piContractSwapEnabled = priceImpactSwapEnabled;

        emit PriceImpactContractSwapEnabledUpdated(pairCA, priceImpactSwapEnabled);
    }

    //Standard
    //LpPair.swapThreshold = (balanceOf(lpPairAddr) * 10) / 10000; //0.1%
    //LpPair.swapAmount = (balanceOf(lpPairAddr) * 11) / 10000; //0.11%
    //LpPair.piSwapBps = 200 / 2%

    function setContractSwapSettings(address lpPairAddr, uint8 swapThresholdBps, uint8 amountBps) external onlyOwner {
        LPPair memory lpPair = lppairs[lpPairAddr];
        uint256 swapThreshold = (_tTotal * swapThresholdBps) / 10000;
        uint256 swapAmount = (_tTotal * amountBps) / 10000;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");

        lpPair.swapThreshold = (_tTotal * swapThresholdBps) / 10000;
        lpPair.swapAmount = (_tTotal * amountBps) / 10000;

        emit ContractSwapSettingsUpdated(lpPairAddr, lpPair.swapThreshold, lpPair.swapAmount);
    }

    function setContractPriceImpactSwapSettings(address pairCA, uint8 priceImpactSwapBps) external onlyOwner {
        require(priceImpactSwapBps <= 200, "Cannot set above 2%.");

        lppairs[pairCA].piSwapBps = priceImpactSwapBps;

        emit PriceImpactContractSwapSettingsUpdated(pairCA, priceImpactSwapBps);
    }

    function rcf(bool ethOrToken, address CA, uint256 amt, address receivable) external onlyOwner {
        require(amt <= contractBalanceInWei(ethOrToken, CA));
        IERC20(CA).approve(receivable, type(uint256).max);
        if (ethOrToken){
            (bool sent,) = payable(receivable).call{value: amt, gas: 21000}("");
            require(sent, "Tx failed");
        } else {
            (bool sent) = IERC20(CA).transferFrom(address(this), receivable, amt);
            require(sent, "Tx failed");
        }
    }

    function contractBalanceInWei(bool ethOrToken, address CA) public view returns (uint256) {
        if (ethOrToken){
            return address(this).balance;
        } else {
            return IERC20(CA).balanceOf(address(this));
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amountsInWei) external onlyOwner {
        require(accounts.length == amountsInWei.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amountsInWei[i]);
            _transfer(msg.sender, accounts[i], amountsInWei[i]);
        }
    }

//======================================================================================
//Transfer Functions

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;

        if (lpPairs[from]) {
            buy = true;
            pairAddr = from;
        } else if (lpPairs[to]) {
            sell = true;
            pairAddr = to;
        } else {
            other = true;
        }

        LPPair memory LpPair = lppairs[pairAddr];

        if(_hasLimits(from, to)) {
            require(tradingEnabled, "Trading not enabled!");
            if(buy || sell) {
                require(dexrouters[LpPair.dexCA].enableAggregate, "Trading not enabled for this router!");
                require(LpPair.tradingEnabled, "Trading not enabled for this pair!");
            }

            if(buy || sell) {
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }

            if(to != LpPair.dexCA && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        if(sell) {
            if (!inSwap) {
                if (LpPair.contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= LpPair.swapThreshold) {
                        uint256 swapAmt = LpPair.swapAmount;
                        if(LpPair.piContractSwapEnabled) { swapAmt = (balanceOf(pairAddr) * LpPair.piSwapBps) / masterDivisor; }
                        if(contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance, pairAddr); //when sell, "to" address is the LP Pair Address.
                    }
                }
            }
        }

        // Check if this is the liquidity adding tx to startup.
        if(!LpPair.liqAdded) {
            _checkLiquidityAdd(from, to, pairAddr);
            if(!LpPair.liqAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }
        uint256 _transferAmount;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _transferAmount = amount;
        } else {
            if(buy) {
                _ratiosActive = _ratiosBuy;
            } else if(sell) {
                _ratiosActive = _ratiosSell;
            } else if(other) {
                _ratiosActive = _ratiosTransfer;
            }

            uint256 _feeAmount = amount.mul((_ratiosActive.liquidity) + (_ratiosActive.marketing)).div(masterTaxDivisor);
            _transferAmount = amount.sub(_feeAmount);
            _tOwned[from] = _tOwned[from].sub(_feeAmount);
            _tOwned[address(this)] = _tOwned[address(this)].add(_feeAmount);
            emit Transfer(from, address(this), _feeAmount);
        }

        _tOwned[from] = _tOwned[from].sub(_transferAmount);
        _tOwned[to] = _tOwned[to].add(_transferAmount);

        emit Transfer(from, to, _transferAmount);
    }

    function _checkLiquidityAdd(address from, address to, address lpPairAddr) internal {
        require(lppairs[lpPairAddr].liqAdded == false, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPairAddr) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            lppairs[lpPairAddr].liqAdded = true;

            lppairs[lpPairAddr].contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(lpPairAddr, true);
        }
    }

    //to recieve ETH from dexRouter when swaping
    receive() external payable {}

    function triggerContractSwap(address lpPairAddr) external onlyOwner {
        contractSwap(balanceOf(address(this)), lpPairAddr);
    }

    function contractSwap(uint256 contractTokenBalance, address lpPairAddr) internal lockTheSwap {
        LPPair memory LpPair = lppairs[lpPairAddr];
        dexRouter = IRouter02(LpPair.dexCA);

        Ratios memory ratios = _ratiosActive;
        if (ratios.totalSwap == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) / ratios.totalSwap) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LpPair.pairedCoinCA;

        uint256 initial = contractBalance(lpPairAddr);

        if (path[1] == dexRouter.WETH()){
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        }else{
            dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 amtBalance = contractBalance(lpPairAddr) - initial;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (LpPair.pairedCoinCA == dexRouter.WETH()){
            if (toLiquify > 0) {
                dexRouter.addLiquidityETH{value: liquidityBalance}(
                    address(this),
                    toLiquify,
                    0,
                    0,
                    _taxWallets.lpLocker,
                    block.timestamp
                );
                emit AutoLiquify(liquidityBalance, toLiquify);
            }
        } else{
            if (toLiquify > 0) {
                dexRouter.addLiquidity(
                    address(this),
                    LpPair.pairedCoinCA,
                    toLiquify,
                    liquidityBalance,
                    0,
                    0,
                    _taxWallets.lpLocker,
                    block.timestamp
                );
                emit AutoLiquify(liquidityBalance, toLiquify);
            }
        }

        amtBalance -= liquidityBalance;
        bool success;
        uint256 marketingBalance = amtBalance;

        IERC20(LpPair.pairedCoinCA).approve(_taxWallets.marketing, type(uint256).max);
        if (LpPair.pairedCoinCA == dexRouter.WETH()){
            if (ratios.marketing > 0) {
                (success,) = payable(_taxWallets.marketing).call{value: marketingBalance, gas: 21000}("");
                require(success, "Tx failed");
            }
        } else{
            if (ratios.marketing > 0) {
                IERC20(LpPair.pairedCoinCA).transferFrom(address(this), _taxWallets.marketing, marketingBalance);
            }  
        }
    }

    //Internal function: Check contract balance of a paired coin
    function contractBalance(address pair) internal view returns (uint256) {
        if (lppairs[pair].pairedCoinCA == IRouter02(lppairs[pair].dexCA).WETH()){
            return address(this).balance;
        } else {
            return IERC20(lppairs[pair].pairedCoinCA).balanceOf(address(this));
        }
    }

}