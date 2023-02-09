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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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

// SPDX-License-Identifier: MIT
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libraries/DEXLibrary.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBasicDEX.sol";

contract BasicDEX is IBasicDEX {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;
    address public USDC;
    EnumerableSet.AddressSet internal acceptableAssets;
    /// @dev Status to accept all asset or only certain assets.
    /// @dev true/false : accept certain assets/accept all assets.
    bool public allowlistMode;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'DEX: EXPIRED');
        _;
    }

    modifier onlyAllowedAssets(address[] calldata _assets) {
        if (allowlistMode) {
            for (uint256 i = 0; i < _assets.length; i ++) {
                require (acceptableAssets.contains(_assets[i]), "not allowed asset");
            }
        }
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getPairAddress(address _tokenA, address _tokenB) external view returns (address) {
        return DEXLibrary.pairFor(factory, _tokenA, _tokenB);
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external virtual ensure(_deadline) onlyAllowedAssets(_path) returns (uint256[] memory amounts) {
        amounts = _getAmountsOutWithFee(_path, _amountIn, false);
        require(amounts[amounts.length - 1] >= _amountOutMin, 'DEX: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            _path[0], msg.sender, DEXLibrary.pairFor(factory, _path[0], _path[1]), amounts[0]
        );
        _swap(amounts, _path, _to);
    }
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) onlyAllowedAssets(path) returns (uint256[] memory amounts) {
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        amounts = _getAmountsOutWithFee(path, amounts[0], false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        onlyAllowedAssets(path)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = _getAmountsOutWithFee(path, msg.value, true);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        ensure(deadline)
        onlyAllowedAssets(path)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        amounts = _getAmountsOutWithFee(path, amounts[0], false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        ensure(deadline)
        onlyAllowedAssets(path)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = _getAmountsOutWithFee(path, amountIn, false);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        onlyAllowedAssets(path)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        amounts = _getAmountsOutWithFee(path, amounts[0], true);
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        uint256 amountIn = 0;
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(DEXLibrary.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            { // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = DEXLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            amountIn = amountInput;
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? DEXLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) {
        amountIn = _beforeSwap(path[0], amountIn, false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        // uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // require(
        //     IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
        //     'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        // );
        // _afterSwap(path[0], amountIn);
        _swapTokensSuppotingFeeOnTransferTokens(path, to, amountOutMin, amountIn);
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint256 amountIn = _beforeSwap(path[0], msg.value, true);
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(DEXLibrary.pairFor(factory, path[0], path[1]), amountIn));
        // uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // require(
        //     IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
        //     'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        // );
        // _afterSwap(path[0], amountIn);
        _swapTokensSuppotingFeeOnTransferTokens(path, to, amountOutMin, amountIn);
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amountIn = _beforeSwap(path[0], amountIn, false);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, DEXLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        // _swapSupportingFeeOnTransferTokens(path, address(this));
        // uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        // require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // IWETH(WETH).withdraw(amountOut);
        // TransferHelper.safeTransferETH(to, amountOut);
        // _afterSwap(path[0], amountIn);
        _swapTokensSuppotingFeeOnTransferTokens(path, to, amountOutMin, amountIn);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure virtual override returns (uint256 amountB) {
        return DEXLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return DEXLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return DEXLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return DEXLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return DEXLibrary.getAmountsIn(factory, amountOut, path);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? DEXLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(DEXLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
        _afterSwap(path[0], amounts[0]);
    }

    /// @notice Take fee amount and returns fee amount.
    /// @param _token The address of swap token.
    /// @param _amount The amount of token to swap(amountIn).
    /// @param _isETH Status if swap token is ETH or not.
    /// @return sendAmount The amount of without feeAmount (feeAmount = roundFeeAmount + platformFeeAmount)
    function _beforeSwap(
        address _token, 
        uint256 _amount, 
        bool _isETH
    ) internal virtual returns (uint256 sendAmount) {
        return _amount;
    }

    /// @notice Calculate volum amount as USDC and update user and team volume.
    /// @notice Transfer round fee to trading master and update roundRewards.
    /// @param _token The address of swap token.
    /// @param _amount The amount of swap token (amountIn)
    function _afterSwap(address _token, uint256 _amount) internal virtual { }

    /// @notice This is calculated as USDC.
    function _getVolumeAmount(address _token, uint256 _amount) internal view returns(uint256) {
        if (_token == USDC) {
            return _amount;
        }
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = USDC;
        uint256[] memory amounts = DEXLibrary.getAmountsOut(factory, _amount, path);
        return amounts[1];
    }

    function _addAllowAssets(address _asset, bool _accept) internal {
        require (
            (_accept && !acceptableAssets.contains(_asset)) ||
            (!_accept && acceptableAssets.contains(_asset))
            , "already set"
        );
        if (_accept) { acceptableAssets.add(_asset); }
        else { acceptableAssets.remove(_asset); }
    }

    function _getAmountsOutWithFee(
        address[] calldata _path,
        uint256 _amountIn,
        bool _isETH
    ) internal returns (uint256[] memory amounts) {
        _amountIn = _beforeSwap(_path[0], _amountIn, _isETH);
        amounts = DEXLibrary.getAmountsOut(factory, _amountIn, _path);
    }

    function _swapTokensSuppotingFeeOnTransferTokens(
        address[] memory path,
        address to,
        uint256 amountOutMin,
        uint256 amountIn
    ) internal {
        uint256 pathLength = path.length;
        uint256 amountOut = 0;
        uint256 balanceBefore = 0;
        if (path[0] == WETH) {  // swapExactETHForTokensSupportingFeeOnTransferTokens
            balanceBefore = IERC20(path[pathLength - 1]).balanceOf(to);
            _swapSupportingFeeOnTransferTokens(path, to);
            amountOut = IERC20(path[pathLength - 1]).balanceOf(to).sub(balanceBefore);
        } else if (path[pathLength - 1] == WETH) {  // swapExactTokensForETHSupportingFeeOnTransferTokens
            _swapSupportingFeeOnTransferTokens(path, address(this));
            amountOut = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amountOut);
            TransferHelper.safeTransferETH(to, amountOut);
        } else {    // swapExactTokensForTokensSupportingFeeOnTransferTokens
            balanceBefore = IERC20(path[pathLength - 1]).balanceOf(to);
            _swapSupportingFeeOnTransferTokens(path, to);
            amountOut = IERC20(path[pathLength - 1]).balanceOf(to).sub(balanceBefore);
        }

        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _afterSwap(path[0], amountIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBasicDEX {
    function factory() external view returns (address);
    function WETH() external view returns (address);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ITradingMaster.sol";

interface IPlatformMaster {
    /// @notice Set new platform fee.
    /// @dev Only owner can call this function.
    /// @param _newFee The new platform fee.
    function setPlatformFee(uint16 _newFee) external;
    
    /// @notice Turn on/off allowlist mode. toggle.
    /// @notice Only owner can call this function.
    function setAllowlistMode() external;

    /// @notice Add/remove assets to acceptable asset list.
    /// @dev Only owner can call this function.
    /// @param _assets The addresses of assets.
    /// @param _accept Status for accept or not. true/false.
    function setAcceptableAssets(address[] memory _assets, bool _accept) external;

    /// @notice Create new round.
    /// @dev Only platform owner can call this function.
    /// @param _createTimestamp Start timestamp for new round.
    /// @param _durationDays    The new round duration as day.
    /// @param _roundFee        Round fee percent. 
    /// @param _rewardsPercents Rewards percent for winners.
    function createRound(
        uint256 _createTimestamp, 
        uint16 _durationDays, 
        uint16 _roundFee,
        uint16[] memory _rewardsPercents
    ) external;

    /// @notice Finish round.
    /// @dev Only owner can call this function.
    /// @dev Divide rewards to winners.
    function finishRound() external;

    /// @notice Create team.
    /// @dev The user should be apart from any teams to create a team.
    /// @param _name The team name.
    function createTeam(string memory _name) external;

    /// @notice Disband the team with team id.
    /// @dev Only team creator can do this.
    /// @param _teamId The team id to disband.
    function disbandTeam(uint256 _teamId) external;

    /// @notice Send invitation to users.
    /// @dev Invitor should be team member.
    /// @param _recipients The addresses of recipients.
    function sendInvitation(address[] memory _recipients) external;

    /// @notice Accept invitation.
    /// @dev Acceptor should be apart from any team.
    /// @param _teamId The team id to accept.
    function acceptInvitation(uint256 _teamId) external;

    /// @notice Send request to join to a team.
    /// @dev Requester should be not belongs to any teams.
    /// @param _teamIds The list of team id to send reqest.
    function sendRequestToTeam(uint256[] memory _teamIds) external;

    /// @notice Accept request.
    /// @dev Caller should be owner of a team.
    /// @param _user The addres of user for accepting.
    function acceptRequest(address _user) external;

    /// @notice Leave team.
    function leaveTeam() external;

    /// @notice Get all invitations.
    /// @param _user The address of a user.
    /// @return _invitationIds The team ids that received invitation.
    function checkInvitation(address _user) external view returns (uint256[] memory _invitationIds);

    /// @notice Get all requests.
    /// @dev Caller should be owner of a team.
    /// @param _user The address of user.
    /// @return _requesters The list of requester addresses .
    function checkRequest(address _user) external view returns (address[] memory _requesters);

    /// @notice Get information of a team.
    /// @param _teamId The team id to get info.
    /// @return volume  Amount of trading volume.
    /// @return creator The address of team creator.
    /// @return members The addresses of team member.
    /// @return name    Team name
    function getTeamInfo(uint256 _teamId) external view returns (
        uint256 volume,
        address creator,
        address[] memory members,
        string memory name
    );

    /// @notice Get amount of trade volume for a team.
    /// @param _teamId Team id.
    /// @return Return trading volume amount.
    function getTeamVolume(uint256 _teamId) external view returns (uint256);

    /// @notice Get team info user belongs to.
    function getUserTeamInfo(address _user) external view returns (
        bool teamMember, 
        bool teamCreator, 
        uint256 teamId,
        uint256 userTeamVolume
    );

    /// @notice Get rewards amount of prize.
    /// @param _teamId Team id.
    /// @return Rewards amount of prize.
    function getPrizeAmount(uint256 _teamId) external view returns (uint256);

    /// @notice Withdraw token.
    /// @dev Only owner can call this function.
    /// @param _token The address of token to withdraw.
    /// @param _amount The amount of token to withdraw.
    function withdrawToken(address _token, uint256 _amount) external;

    /// @notice Get round information.
    function getRoundInfo() external view returns (ITradingMaster.Round memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITradingMaster {
    struct Team {
        uint256 id;
        /// @dev Team volume amount. If one of members leave the team, it will not be reduced.
        mapping(uint256 => uint256) volumeByRound;
        /// @dev Actual Team volume amount. If one of memebers leave the team, it will be reduced.
        mapping(uint256 => uint256) actualVolumeByRound;
        address creator;
        address[] requesters;
        string name;
        bool live;
    }

    struct User {
        mapping(uint256 => uint256) volumeByRound;
        uint256 teamId;
        uint256[] receivedInvIds;
    }

    struct Request {
        bool invited;
        bool requested;
    }

    struct Round {
        uint256 createdTimestamp;
        uint256 endTimestamp;
        uint256 rewardsAmount;
        uint256[] winTeams;
        uint16 roundFee;
        uint16[] rewardsPercents;
        bool finished;
    }

    /// @notice Token that used for rewards and stored as fee.
    function baseToken() external view returns (address baseToken);

    /// @notice Check now is round duration or not.
    function inRoundDuration() external view returns (bool);

    /// @notice Get round information.
    function getRoundInfo() external view returns (Round memory);

    /// @notice Get Round fee rate.
    /// @dev If it's not round duration or trader doesn't belong to a team, returns 0.
    /// @param _trader The address of trader.
    function getRoundFee(address _trader) external view returns (uint16);

    /// @notice Set platform master contract address.
    /// @dev Only owner can call this function.
    /// @param _platformMaster The address of platform master contract.
    function setPlatformMaster(address _platformMaster) external;

    /// @notice Update user&team volume with volumeAmount.
    /// @notice Update current round rewards.
    /// @dev This is applied when now is in round duration.
    /// @dev _roundFee should be deposited first before call updateVolumeAndRewards function.
    /// @dev Only platformMaster can call this function.
    /// @param _account The address of account.
    /// @param _volumeAmount The amount of volume to update(add).
    /// @param _roundFee Roundfee to add roundRewards.
    function updateVolumeAndRewards(address _account, uint256 _volumeAmount, uint256 _roundFee) external;

    /// @notice Create new round.
    /// @dev Only platform master can call this function.
    /// @param _createTimestamp Start timestamp for new round.
    /// @param _durationDays    The new round duration as day.
    /// @param _roundFee        Round fee percent. 
    /// @param _rewardsPercents Rewards percent for winners.
    function createRound(
        uint256 _createTimestamp, 
        uint16 _durationDays, 
        uint16 _roundFee,
        uint16[] memory _rewardsPercents
    ) external;

    /// @notice Finish round.
    /// @dev Only platform master can call this function.
    /// @dev Divide rewards to winners.
    function finishRound() external;

    /// @notice Create team.
    /// @dev The user should be apart from any teams to create a team.
    /// @dev Only platform master can call this function.
    /// @param _creator The address of `msg.sender` - creator
    /// @param _name The team name.
    function createTeam(address _creator, string memory _name) external;

    /// @notice Disband the team with team id.
    /// @dev Only team creator can do this.
    /// @dev Only platform master can call this function.
    /// @param _account The address of origin caller.
    /// @param _teamId The team id to disband.
    function disbandTeam(address _account, uint256 _teamId) external;

    /// @notice Send invitation to users.
    /// @dev Invitor should be team member.
    /// @dev Only platform master can call this function.
    /// @param _account The address of origin caller.
    /// @param _recipients The list of invitation recipients.
    function sendInvitation(address _account, address[] memory _recipients) external;

    /// @notice Accept invitation.
    /// @dev Acceptor should be apart from any team.
    /// @dev Only platform master can call this function.
    /// @param _account the address of acceptor.
    /// @param _teamId The team id to accept.
    function acceptInvitation(address _account, uint256 _teamId) external;

    /// @notice Send request to join to a team.
    /// @dev Requester should be not belongs to any teams.
    /// @dev Only platform master can call this function.
    /// @param _account The address of sender.
    /// @param _teamIds The list of team id to send reqest.
    function sendRequestToTeam(address _account, uint256[] memory _teamIds) external;

    /// @notice Accept request.
    /// @dev Caller should be owner of a team.
    /// @dev Only platform master can call this function.
    /// @param _acceptor The address of acceptor.
    /// @param _user The addres of user for accepting.
    function acceptRequest(address _acceptor, address _user) external;

    /// @notice Leave team.
    /// @dev Only platform master can call this function.
    /// @param _creator The address of team creator.
    function leaveTeam(address _creator) external;

    /// @notice Get all invitations.
    /// @param _user The address of a user.
    /// @return _invitationIds The team ids that received invitation.
    function checkInvitation(address _user) external view returns (uint256[] memory _invitationIds);

    /// @notice Get all requests.
    /// @dev Caller should be owner of a team.
    /// @param _account, The address of user who wanna check requeest.
    /// @return _requesters The list of requester addresses .
    function checkRequest(address _account) external view returns (address[] memory _requesters);

    /// @notice Get information of a team.
    /// @param _teamId The team id to get info.
    /// @return volume  Amount of trading volume.
    /// @return creator The address of team creator.
    /// @return members The addresses of team member.
    /// @return name    Team name
    function getTeamInfo(uint256 _teamId) external view returns (
        uint256 volume,
        address creator,
        address[] memory members,
        string memory name
    );

    /// @notice Get amount of trade volume for a team.
    /// @param _teamId Team id.
    /// @return Return trading volume amount.
    function getTeamVolume(uint256 _teamId) external view returns (uint256);

    /// @notice Get rewards amount of prize.
    /// @param _teamId Team id.
    /// @return Rewards amount of prize.
    function getPrizeAmount(uint256 _teamId) external view returns (uint256);

    /// @notice Get team info user belongs to.
    function getUserTeamInfo(address _user) external view returns (
        bool teamMember, 
        bool teamCreator, 
        uint256 teamId,
        uint256 userTeamVolume
    );

    event RoundCreated(uint256 roundId);

    event RoundFinished(uint256 roundId);

    event TeamCreated(address indexed creator, uint256 teamId);

    event TeamDisbanded(uint256 teamId);

    event UserTeamLeft(address indexed user, uint256 teamId);

    event PlatformFeeSet(uint16 newFee);

    event InvitationAcceped(uint256 teamId);

    event RequestAccepted(address indexed requester, uint256 teamId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library DEXLibrary {
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
        bytes32 data = keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        ));
        pair = _convertBytesToAddress(data);
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

    function _convertBytesToAddress(bytes32 data) internal pure returns (address) {
        return address(uint160(uint256(data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BasicDEX.sol";
import "./interfaces/IPlatformMaster.sol";

/// @title PlatformMaster - Team Trading Platform contract
/// @author 5thWeb
contract PlatformMaster is Ownable2Step, BasicDEX, IPlatformMaster {
    /// @notice The handle of trading master.
    ITradingMaster public tradingMaster;

    uint256 private totalFeeAmount;
    uint256 private roundFeeAmount;
    uint16 public BASE_POINT = 1000;
    uint16 constant public MAX_PLATFORM_FEE = 10;  // 1%
    uint16 public platformFee;
    
    constructor (
        address _factory,
        address _WETH,
        address _tradingMaster,
        uint16 _platformFee
    ) BasicDEX(_factory, _WETH) {
        require (_tradingMaster != address(0), "zero trading master contract address");
        tradingMaster = ITradingMaster(_tradingMaster);
        USDC = tradingMaster.baseToken();
        allowlistMode = true;
        platformFee = _platformFee;
    }

    /// @inheritdoc IPlatformMaster
    function setPlatformFee(uint16 _newFee) external override onlyOwner {
        require (_newFee <= MAX_PLATFORM_FEE, "over max fee");
        platformFee = _newFee;
    }

    /// @inheritdoc IPlatformMaster
    function setAllowlistMode() external override onlyOwner {
        allowlistMode = !allowlistMode;
    }

    /// @inheritdoc IPlatformMaster
    function setAcceptableAssets(address[] memory _assets, bool _accept) external onlyOwner override {
        uint256 length = _assets.length;
        require (length > 0, "invalid asset array");
        for (uint256 i = 0; i < length; i ++) { 
            _addAllowAssets(_assets[i], _accept);
        }
    }

    /// @inheritdoc IPlatformMaster
    function createRound(
        uint256 _createTimestamp, 
        uint16 _durationDays, 
        uint16 _roundFee,
        uint16[] memory _rewardsPercents
    ) external override onlyOwner {
        require (_rewardsPercents.length == 3, "invalid rewardsPercent array length");
        require (
            _rewardsPercents[0] + _rewardsPercents[1] + _rewardsPercents[2] == BASE_POINT,
            "invalid total rewards percent"
        );

        tradingMaster.createRound(_createTimestamp, _durationDays, _roundFee, _rewardsPercents);
    }

    /// @inheritdoc IPlatformMaster
    function finishRound() external override onlyOwner {
        tradingMaster.finishRound();
    }

    /// @inheritdoc IPlatformMaster
    function createTeam(string memory _name) external override {
        tradingMaster.createTeam(msg.sender, _name);
    }

    /// @inheritdoc IPlatformMaster
    function disbandTeam(uint256 _teamId) external override {
        tradingMaster.disbandTeam(msg.sender, _teamId);
    }

    /// @inheritdoc IPlatformMaster
    function sendInvitation(address[] memory _recipients) external override {
        tradingMaster.sendInvitation(msg.sender, _recipients);
    }

    /// @inheritdoc IPlatformMaster
    function acceptInvitation(uint256 _teamId) external override {
        tradingMaster.acceptInvitation(msg.sender, _teamId);
    }

    /// @inheritdoc IPlatformMaster
    function checkInvitation(address _user) external view override returns (uint256[] memory _invitationIds) {
        require (_user != address(0), "invalid user address");
        return tradingMaster.checkInvitation(_user);
    }

    /// @inheritdoc IPlatformMaster
    function sendRequestToTeam(uint256[] memory _teamIds) external override {
        tradingMaster.sendRequestToTeam(msg.sender, _teamIds);
    }

    /// @inheritdoc IPlatformMaster
    function acceptRequest(address _user) external override {
        tradingMaster.acceptRequest(msg.sender, _user);
    }

    /// @inheritdoc IPlatformMaster
    function checkRequest(address _user) external view override returns (address[] memory _requesters) {
        require (_user != address(0), "invalid user address");
        return tradingMaster.checkRequest(_user);
    }

    /// @inheritdoc IPlatformMaster
    function leaveTeam() external override {
        tradingMaster.leaveTeam(msg.sender);
    }

    /// @inheritdoc IPlatformMaster
    function getRoundInfo() external view returns (ITradingMaster.Round memory) {
        return tradingMaster.getRoundInfo();
    }

    /// @inheritdoc IPlatformMaster
    function getTeamInfo(uint256 _teamId) external view override returns (
        uint256 volume,
        address creator,
        address[] memory members,
        string memory name
    ) {
        return tradingMaster.getTeamInfo(_teamId);
    }

    /// @inheritdoc IPlatformMaster
    function getTeamVolume(uint256 _teamId) external view override returns (uint256) {
        return tradingMaster.getTeamVolume(_teamId);
    }

    /// @inheritdoc IPlatformMaster
    function getUserTeamInfo(address _user) external view override returns (
        bool teamMember, 
        bool teamCreator, 
        uint256 teamId,
        uint256 userTeamVolume
    ) {
        return tradingMaster.getUserTeamInfo(_user);
    }

    /// @inheritdoc IPlatformMaster
    function getPrizeAmount(uint256 _teamId) public view override returns (uint256) {
        return tradingMaster.getPrizeAmount(_teamId);
    }

    /// @inheritdoc IPlatformMaster
    function withdrawToken(address _token, uint256 _amount) external onlyOwner override {
        address sender = msg.sender;
        require (_token != address(0), "invalid token address");
        require (IERC20(_token).balanceOf(address(this)) >= _amount, "not enough balance for withdraw");
        TransferHelper.safeTransfer(_token, sender, _amount);
    }

    function _beforeSwap(
        address _token, 
        uint256 _amount, 
        bool _isETH
    ) internal virtual override returns (uint256 sendAmount) {
        uint256 platformFeeAmount = _amount * platformFee / BASE_POINT;
        roundFeeAmount = _amount * tradingMaster.getRoundFee(msg.sender) / BASE_POINT;
        totalFeeAmount = platformFeeAmount + roundFeeAmount;
        sendAmount = _amount - totalFeeAmount;
        if (totalFeeAmount > 0) {
            if (_isETH) {
                IWETH(WETH).deposit{value: totalFeeAmount}();
            } else {
                TransferHelper.safeTransferFrom(_token, msg.sender, address(this), totalFeeAmount);
            }
        }
    }

    function _afterSwap(address _token, uint256 _amount) internal virtual override {
        roundFeeAmount = _swapToBaseToken(_token);
        if (tradingMaster.inRoundDuration()) {
            uint256 volumeAmount = _getVolumeAmount(_token, _amount);
            if (roundFeeAmount > 0) {
                TransferHelper.safeTransfer(USDC, address(tradingMaster), roundFeeAmount);
            }
            tradingMaster.updateVolumeAndRewards(msg.sender, volumeAmount, roundFeeAmount);
        }
    }

    function _swapToBaseToken(address _token) internal returns (uint256 feeAmount) {
        if (totalFeeAmount > 0) {
            if (_token == USDC) {
                return roundFeeAmount;
            }
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = USDC;
            uint256 balanceBefore = IERC20(USDC).balanceOf(address(this));

            TransferHelper.safeTransfer(path[0], DEXLibrary.pairFor(factory, path[0], path[1]), totalFeeAmount);
            _swapSupportingFeeOnTransferTokens(path, address(this));

            uint256 balanceAfter = IERC20(USDC).balanceOf(address(this));
            feeAmount = balanceAfter - balanceBefore;
            feeAmount = feeAmount * roundFeeAmount / totalFeeAmount;
        } else {
            feeAmount = 0;
        }
        
    }
}