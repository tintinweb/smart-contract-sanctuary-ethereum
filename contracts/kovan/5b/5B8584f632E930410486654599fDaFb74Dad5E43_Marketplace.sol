/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// File: @openzeppelin\contracts\utils\Context.sol
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

// File: @openzeppelin\contracts\access\Ownable.sol


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

// File: @openzeppelin\contracts\utils\math\SafeMath.sol


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin\contracts\utils\structs\EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// File: @openzeppelin\contracts\utils\Counters.sol


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

// File: contracts\interfaces\IAdmin.sol


pragma solidity ^0.8.0;
/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    modifier isAdmin() {
        require(admins.contains(msg.sender), "You do not have rights");
        _;
    }

    event AdminAdded(address);
    event AdminRemoved(address);

    function addAdmin(address _admin) external virtual;

    function removeAdmin(address _admin) external virtual;

    function _addAdmin(address _admin) internal {
        require(_admin != address(0), "Address should not be empty");
        require(!admins.contains(_admin), "Already added");
        if (!admins.contains(_admin)) {
            admins.add(_admin);
            emit AdminAdded(_admin);
        }
    }

    function _removeAdmin(address _admin) internal {
        require(admins.contains(_admin), "Not exist");
        if (admins.contains(_admin)) {
            admins.remove(_admin);
            emit AdminRemoved(_admin);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}

// File: contracts\libs\Enhancer.sol


pragma solidity ^0.8.0;

/**
 * @title Representation of enhancer options
 */
library CellEnhancer {
    /**
     * @dev Enhancer
     * @param id - enhancer id
     * @param typeId - enhancer type id
     * @param probability - chance of successful enhancement
     * @param basePrice - default price
     * @param baseCurrency - default currency
     * @param enhancersAmount - amount of existing enhancers
     */
    struct Enhancer {
        uint256 id;
        uint8 typeId;
        uint16 probability;
        uint256 basePrice;
        string name;
        address tokenAddress;
        //todo uint256 amount; add
    }

    enum EnhancerType {
        UNKNOWN_ENHANCER,
        STAGE_ENHANCER,
        SPLIT_ENHANCER
    }

    function convertEnhancer(uint8 enhancerType)
        internal
        pure
        returns (EnhancerType)
    {
        if (enhancerType == 1) {
            return EnhancerType.STAGE_ENHANCER;
        } else if (enhancerType == 2) {
            return EnhancerType.SPLIT_ENHANCER;
        }

        return EnhancerType.UNKNOWN_ENHANCER;
    }
}

// File: contracts\interfaces\IEnhancer.sol


pragma solidity ^0.8.0;
/**
 * @title Interface to interact with our Cell nft proxy(CellFactory), to be able to push enhancers to marketplace
 */
interface IEnhancer {
    /**
     * @dev Creates enhancer with options
     */
    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external;

    /**
     * @dev Modifies enhancer's info
     * can be changed everything except enhancer's type
     */
    function modifyEnhancer(CellEnhancer.Enhancer memory, uint256) external;

    /**
     * @dev Increases enhancer amount by it's id
     */
    function addEnhancersAmount(uint256 _id, uint256 _amount) external;

    /**
     * @dev Removes enhancer from marketPlace
     */
    function removeEnhancerFromSale(uint256 id) external;

    event EnhancerCreated(uint256);
    event EnhancersAmountIncreased(uint256, uint256);
    event EnhancerModified(uint256, uint8);
    event EnhancersRemoved(uint256);

    /**
     * @dev Event emits when user successful bought enhancer
     */
    event EnhancerBought(uint256 _enhancerId);
}

// File: contracts\interfaces\IEnhancerRepository.sol


pragma solidity ^0.8.0;
/**
 * @title Interface for interaction with particular cell
 */
abstract contract IEnhancerRepository {
    using SafeMath for uint256;
    /**
     * @dev emits enhancer amount
     */
    event EnhancerAmountChanged(uint256, uint256);
    /**
     * @dev emits when enhancer is added
     */
    event EnhancerAdded(uint256);

    CellEnhancer.Enhancer[] private availableEnhancers;

    struct enhancer {
        uint256 id;
        uint256 amount;
    }
    mapping(address => enhancer[]) internal ownedEnhancers;

    /**
     * @dev Adds available enhancers to storage
     */
    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        virtual;

    function _addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        internal
    {
        uint256 _index = findEnhancerById(_enhancer.id);
        if (_index == type(uint256).max) {
            availableEnhancers.push(_enhancer);
        } else {
            availableEnhancers[_index] = _enhancer;
        }
    }

    /**
     * @dev Returns enhancer info by it's id
     */
    function getEnhancerInfo(uint256 _id)
        public
        view
        returns (CellEnhancer.Enhancer memory)
    {
        uint256 _index = findEnhancerById(_id);
        if (_index == type(uint256).max) {
            CellEnhancer.Enhancer memory _enhancer;
            _enhancer.id = type(uint256).max;
            return _enhancer;
        }
        return availableEnhancers[_index];
    }

    /**
     * @dev Increases amount of enhancers of particular user
     */
    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 i = 0; i < len; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .add(_amount);
                return;
            }
        }

        enhancer memory _enhancer = enhancer(_id, _amount);
        ownedEnhancers[_owner].push(_enhancer);
    }

    /**
     * @dev Decreases available user enhancers
     */
    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < ownedEnhancers[_owner].length; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .sub(_amount);
                index = i;
                break;
            }
        }

        if (
            index != type(uint256).max &&
            ownedEnhancers[_owner][index].amount == 0
        ) {
            ownedEnhancers[_owner][index] = ownedEnhancers[_owner][
                ownedEnhancers[_owner].length - 1
            ];
            ownedEnhancers[_owner].pop();
        }
    }

    /**
     * @dev Returns ids of all available enhancers for particular user
     */
    function getUserEnhancers(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = ownedEnhancers[_owner].length;
        uint256[] memory _ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _ids[i] = ownedEnhancers[_owner][i].id;
        }
        return _ids;
    }

    /**
     * @dev Returns types of all enhancers that are stored
     */
    function getEnhancerTypes() external view returns (uint8[] memory) {
        uint8[] memory _types = new uint8[](availableEnhancers.length);

        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            _types[index] = availableEnhancers[index].typeId;
        }

        return _types;
    }

    /**
     * @dev Returns amount of enhancers by it"s id
     * for particular user
     */
    function getEnhancersAmount(address _owner, uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 index = 0; index < len; index++) {
            if (ownedEnhancers[_owner][index].id == id) {
                return ownedEnhancers[_owner][index].amount;
            }
        }
        return 0;
    }

    function findEnhancerById(uint256 _id) private view returns (uint256) {
        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            if (_id == availableEnhancers[index].id) {
                return index;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns all stored enhancer
     * that are available
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory)
    {
        return availableEnhancers;
    }
}

// File: contracts\libs\CellData.sol


pragma solidity ^0.8.0;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_MAD,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO || _class == Class.SPLITTABLE_MAD || _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
    }
}

// File: contracts\interfaces\ICellRepository.sol


pragma solidity ^0.8.0;
/**
 * @title Interface for interaction with particular cell
 */
interface ICellRepository {
    

    function addMetaCell(CellData.Cell memory _cell) external;

    function removeMetaCell(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external;

    function getMetaCell(address _owner, uint256 _tokenId)
        external
        view
        returns (CellData.Cell memory);
}

// File: contracts\interfaces\IMarketPlace.sol


pragma solidity ^0.8.0;
interface IMarketPlace {
    /**
     * @dev emits when token adress is changed
     */
    event TokenAdressChanged(address);

    /**
     * @dev emits when laboratory adress is changed
     */
    event LaboratoryAddressChanged(address);

    /**
     * @dev emits when modules adress is changed
     */
    event ModulesAddressChanged(address);

    /**
     * @dev emits when wallet adress is changed
     */
    event WalletAddressChanged(address);

    /**
     * @dev emits when token price is changed
     */
    event TokenPriceChanged(uint256);

    /**
     * @dev emits module box is added to marketplace
     */
    event NanoCellAddedToMarketPlace(uint256);

    /**
     * @dev emits module box is removed from marketplace
     */
    event NanoCellRemovedFromMarketPlace(uint256);

    /**
     * @dev emits module is added to marketplace
     */
    event ModuleAddedToMarketPlace(uint256);

    /**
     * @dev emits module is removed from marketplace
     */
    event ModuleRemovedFromMarketPlace(uint256);

    /**
     * @dev Event emits when user successful bought a token
     * @param id of the cells sold
     */
    event MetaCellSold(uint256 id);

    /**
     * @dev Event emits when user successful bought a token
     * @param id of the cells sold
     */
    event NanoCellSold(uint256 id);

    /**
     * @dev Event emits when user successful bought a module
     * @param id of the module sold
     */
    event ModuleSold(uint256 id);

    

    /**
     * @dev Event emits when user successful added cell to marketplace
     * @param _tokenId id of the cell
     */
    event MetaCellAddedToMarketplace(uint256 _tokenId);

    

    /**
     * @dev Event emits when user successful added cell to marketplace
     * @param _tokenId id of the cell
     */
    event MetaCellRemovedFromMarketPlace(uint256 _tokenId);

    /**
     * @dev Event emits when user updated enhancer price
     */
    event MetaCellPriceUpdated(uint256 _tokenId);

    /**
     * @dev Event emits when user updated enhancer price
     */
    event NanoCellPriceUpdated(uint256 _tokenId);

    /**
     * @dev Event emits when user updated enhancer price
     */
    event ModulePriceUpdated(uint256 _tokenId);

    /**
     * @dev function that sets ERC20 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC20 token
     */
    function setMDMAToken(address _address) external;

    /**
     * @dev function that sets ERC721 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC721 token
     */
    function setMetaCellToken(address _address) external;

    /**
     * @dev function that sets ERC721 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC721 token
     */
    function setNanoCellToken(address _address) external;

    /**
     * @dev function that sets laboratory address.
     * @dev emits LaboratoryAddressChanged
     * @param _address is address of ERC721 token
     */
    function setLaboratory(address _address) external;

    /**
     * @dev set modules contract address
     * @dev emits ModulesAddressChanged
     */
    function setModulesAddress(address _address) external;

    /**
     * @dev  returns modules contract address
     */
    function getModulesAddress() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getMDMAToken() external view returns (address);

    /**
     * @dev withdraw MDMA rokens to owner
     */
    function withdrawMDMATokens(address token) external;

    /**
     * @dev function that returns ERC20 token address
     */
    function getMetaCellToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getNanoCellToken() external view returns (address);

    /**
     * @dev function that returns ERC721 token address
     */
    function getLaboratory() external view returns (address);

    /**
     * @dev function thats sets price of ERC20 token.
     * @dev emits TokenPriceChanged
     * @param _price is amount per 1 ERC20 token
     */
    function setMDMATokenPrice(uint256 _price) external;

    /**
     * @dev function that returns price per 1 token.
     */
    function getMDMATokenPrice() external view returns (uint256);

    /**
     * @dev payable function thata allows to buy ERC20 token for ether
     * @param _amount amount of ERC20 tokens to buy
     */
    function buyMDMAToken(uint256 _amount) external payable;

    /**
     * @dev Buy enhancers for ETH
     */
    function buyEnhancerForETH(uint256 _enhancerId, uint256 _amount)
        external
        payable;

    /**
     * @dev Buy enhancers for ERC20
     */
    function buyEnhancerForToken(
        address _tokenAddress,
        uint256 _enhancerId,
        uint256 amount
    ) external;

    /**
     * @dev Returns amount of availbale enhancers by given id
     */
    function getEnhancersAmount(uint256 _id) external view returns (uint256);

    /**
     * @dev Returns enhancer info by it's id
     */
    function getEnhancer(uint256 id)
        external
        view
        returns (CellEnhancer.Enhancer memory);

    /**
     * @dev returns all available enhancers
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory);

    /**
     * @dev Payable function transfers token to new owner's address.
     * @param _tokenId id of the cell
     */
    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable;

    /**
     * @dev Marks meta cell token as available for selling
     * @param _tokenId id of the cell
     * @param _price selling price
     */
    function sellMetaCell(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Updates token sell price
     * @param _tokenId id of the cell
     * @param _newPrice new price of the token
     */
    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice) external;

    /**
     * @dev Marks token as unavailable for selling
     * @param _tokenId id of the cell
     */
    function removeCellFromSale(uint256 _tokenId) external;

    /**
     * @dev Returns all tokens that on sale now as an array of IDs
     */
    function getOnSaleMetaCells()
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev transfers module from one user to another
     */
    function buyNanoCell(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellNanoCell(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeNanoCellFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellsOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellPrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateNanoCellPrice(uint256 id, uint256 price) external;

    /**
     * @dev transfers module from one user to another
     */
    function buyModule(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellModule(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeModuleFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getModulesOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getModulesPrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateModulesPrice(uint256 id, uint256 price) external;

    function numberOfEnhancersType() external view returns (uint);
}

// File: contracts\interfaces\IMintable.sol


pragma solidity ^0.8.0;

abstract contract IMintable {
    function burn(uint256) external virtual;

    function mint(address, uint256) external virtual returns (uint256);
}

// File: contracts\libs\Module.sol


pragma solidity ^0.8.0;

library Modules {
    struct ModuleBox {
        // id for internal usage;
        uint256 id;
        // owner of module
        address owner;
        // time when module will be ready to be opened
        uint256 expired;
    }
}

// File: contracts\interfaces\IModuleBox.sol


pragma solidity ^0.8.0;
abstract contract IModuleBox {
    using Counters for Counters.Counter;
    Counters.Counter internal boxCounter;
    mapping(address => EnumerableSet.UintSet) internal boxIds;
    mapping(uint256 => Modules.ModuleBox) internal boxes;
    uint256 internal pricePerBox;

    event ModuleBoxCreated(uint256 id, uint256 expired);

    event ModuleBoxOpened(uint256 id);

    event ModuleBoxPriceChanged(uint256 id);

    /**
     * @dev set price per box
     */
    function setPricePerBox(uint256 price) external virtual;

    /**
     * @dev returns price per 1 box
     */
    function getPricePerBox() external view virtual returns (uint256);

    /**
     * @dev creates lootbox module for user
     * @dev ModuleBoxCreated to be emitted
     */
    function buyBox(address owner) external virtual;

    /**
     * @dev openBox is minting ERC721 token to owner
     * @dev returns tokenId
     * @dev BoxOpened to be emitted
     */
    function openBox(uint256 id) external virtual;

    /**
     * @dev getBoxById returns full info about box
     */
    function getBoxById(uint256 id)
        external
        view
        virtual
        returns (Modules.ModuleBox memory);

    /**
     * @dev returns all available for particular user box ids
     */
    function getUserBoxes(address owner)
        external
        view
        virtual
        returns (uint256[] memory);
}

// File: contracts\Marketplace.sol


pragma solidity ^0.8.0;
contract Marketplace is IAdmin, IEnhancer, IMarketPlace, IModuleBox, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    event FeeQuoteAmountUpdated(uint256);

    mapping(uint256 => uint256) private enhancersAmount;
    mapping(uint256 => uint256) private modulesOnSale;
    mapping(uint256 => uint256) private nanoCellOnSale;

    uint256[] private sellingMetaCells;
    address[] private metaCellsOwners;

    Counters.Counter private enhancerIds;
    EnumerableSet.UintSet private nanoCells;
    EnumerableSet.UintSet private modules;

    address private laboratory;
    address private mdmaTokenAddress;
    address private metaCellTokenAddress;
    address private nanoCellTokenAddress;
    
    address private feeWallet;
    address private module;
    uint256 private mdmaTokenPrice;
    uint256 private feeQuote;
    uint256 private pricePerMetaCell;

    constructor() {
        _addAdmin(msg.sender);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address owner = owner();
        super.transferOwnership(newOwner);
        _addAdmin(newOwner);
        _removeAdmin(owner);
    }

    function addAdmin(address _admin) external override onlyOwner {
        _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external override onlyOwner {
        _removeAdmin(_admin);
    }

    function setMDMAToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        mdmaTokenAddress = _address;
        emit TokenAdressChanged(_address);
    }


    function setMetaCellToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        metaCellTokenAddress = _address;
        emit TokenAdressChanged(_address);
    }

    function setNanoCellToken(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        nanoCellTokenAddress = _address;
        emit TokenAdressChanged(_address);
    }

    function setLaboratory(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        laboratory = _address;
        emit LaboratoryAddressChanged(_address);
    }

    function setModulesAddress(address _address) external override isAdmin {
        require(_address != address(0), "Address should not be empty");
        module = _address;
        emit ModulesAddressChanged(_address);
    }

    function getMDMAToken() external view override returns (address) {
        return mdmaTokenAddress;
    }

    function withdrawMDMATokens(address token) external override onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }

    function getMetaCellToken() external view override returns (address) {
        return metaCellTokenAddress;
    }

    function getNanoCellToken() external view override returns (address) {
        return nanoCellTokenAddress;
    }

    function getLaboratory() external view override returns (address) {
        return laboratory;
    }

    function setMDMATokenPrice(uint256 _price) external override isAdmin {
        mdmaTokenPrice = _price;
        emit TokenPriceChanged(_price);
    }

    function getMDMATokenPrice() external view override returns (uint256) {
        return mdmaTokenPrice;
    }

    function setFeeWallet(address payable _feeWallet) external isAdmin {
        require(_feeWallet != address(0), "Address should not be empty");
        feeWallet = _feeWallet;
        emit WalletAddressChanged(_feeWallet);
    }

    function getFeeWallet() external view returns (address) {
        return feeWallet;
    }

    function setFeeQuota(uint256 _feeQuote) external isAdmin {
        feeQuote = _feeQuote;
        emit FeeQuoteAmountUpdated(feeQuote);
    }

    function getFeeQuote() external view returns (uint256) {
        return feeQuote;
    }

    function getFeeAmount(uint256 _price) public view returns (uint256) {
        return _price.mul(feeQuote).div(100);
    }

    function getModulesAddress() external view override returns (address) {
        return module;
    }

    function buyMDMAToken(uint256 _amount) external payable override {
        require(
            msg.value >= _amount.mul(mdmaTokenPrice) / 1 ether,
            "Not enough ether to buy"
        );

        IMintable(mdmaTokenAddress).mint(msg.sender, _amount);
        payable(feeWallet).transfer(msg.value);
    }

    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external override isAdmin {
        enhancerIds.increment();
        uint256 _newId = enhancerIds.current();

        CellEnhancer.Enhancer memory newEnhancer = CellEnhancer.Enhancer(
            _newId,
            _typeId,
            _probability,
            _basePrice,
            _name,
            _tokenAddress
        );
        enhancersAmount[_newId] = _amount;
        IEnhancerRepository(laboratory).addAvailableEnhancers(newEnhancer);

        emit EnhancerCreated(_newId);
    }

    function buyEnhancerForETH(uint256 _enhancerId, uint256 _amount)
        external
        payable
        override
    {
        require(
            enhancersAmount[_enhancerId] >= _amount,
            "Not enough enhancer amount"
        );
        CellEnhancer.Enhancer memory enhancer = IEnhancerRepository(laboratory)
            .getEnhancerInfo(_enhancerId);
        require(
            enhancer.tokenAddress == address(0),
            "You are not able to buy this enhancer"
        );
        require(
            enhancer.basePrice.mul(_amount) <= msg.value,
            "Not enough funds"
        );
        payable(feeWallet).transfer(msg.value);
        _buyEnhancer(_enhancerId, _amount);
    }

    function buyEnhancerForToken(
        address _tokenAddress,
        uint256 _enhancerId,
        uint256 _amount
    ) external override {
        require(
            enhancersAmount[_enhancerId] >= _amount,
            "Not enough enhancer amount"
        );
        require(_tokenAddress != address(0), "Incorrect address");
        CellEnhancer.Enhancer memory enhancer = IEnhancerRepository(laboratory)
            .getEnhancerInfo(_enhancerId);
        require(
            enhancer.tokenAddress == _tokenAddress,
            "You are not able to buy this enhancer"
        );
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            enhancer.basePrice.mul(_amount)
        );
        _buyEnhancer(_enhancerId, _amount);
    }

    function _buyEnhancer(uint256 _enhancerId, uint256 _amount) private {
        IEnhancerRepository(laboratory).increaseEnhancersAmount(
            msg.sender,
            _enhancerId,
            _amount
        );
        enhancersAmount[_enhancerId] = enhancersAmount[_enhancerId].sub(
            _amount
        );
        emit EnhancerBought(_enhancerId);
    }

    function modifyEnhancer(
        CellEnhancer.Enhancer memory _enhancer,
        uint256 _amount
    ) external override isAdmin {
        require(
            IEnhancerRepository(laboratory)
                .getEnhancerInfo(_enhancer.id)
                .typeId == _enhancer.typeId,
            "Enhancer type doesnt match"
        );
        require(
            IEnhancerRepository(laboratory)
                .getEnhancerInfo(_enhancer.id)
                .tokenAddress == _enhancer.tokenAddress,
            "Enhancer token address does not match"
        );
        IEnhancerRepository(laboratory).addAvailableEnhancers(_enhancer);
        if (_amount > 0) {
            enhancersAmount[_enhancer.id] = _amount;
        }

        emit EnhancerModified(_enhancer.id, _enhancer.typeId);
    }

    function addEnhancersAmount(uint256 _id, uint256 _amount)
        external
        override
        isAdmin
    {
        uint256 amount = enhancersAmount[_id].add(_amount);
        enhancersAmount[_id] = amount;

        emit EnhancersAmountIncreased(_id, enhancersAmount[_id]);
    }

    function getEnhancersAmount(uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        return enhancersAmount[_id];
    }

    function removeEnhancerFromSale(uint256 id)
        external
        override(IEnhancer)
        isAdmin
    {
        enhancersAmount[id] = 0;
        emit EnhancersRemoved(id);
    }

    function getEnhancer(uint256 _id)
        external
        view
        override
        returns (CellEnhancer.Enhancer memory)
    {
        return IEnhancerRepository(laboratory).getEnhancerInfo(_id);
    }

    function getAllEnhancers()
        external
        view
        override
        returns (CellEnhancer.Enhancer[] memory)
    {
        return IEnhancerRepository(laboratory).getAllEnhancers();
    }

    function getOnSaleMetaCells()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return (metaCellsOwners, sellingMetaCells);
    }

    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable
        override
    {
        // remove token from sale list
        uint256 index = getCellIndex(_tokenId);
        require(index != type(uint256).max, "Token is not found in cell list");

        // save cell before remove from old owner:
        CellData.Cell memory cell = ICellRepository(metaCellTokenAddress)
            .getMetaCell(_oldOwner, _tokenId);
        require(msg.value == cell.price, "Incorrect price");
        // 1. Internal operations
        ICellRepository(metaCellTokenAddress).removeMetaCell(
            _tokenId,
            _oldOwner
        );
        // update cell with new owner:
        cell.user = msg.sender;
        cell.onSale = false;
        uint256 feeAmount = getFeeAmount(cell.price);
        // 2. External operations
        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(metaCellTokenAddress).safeTransferFrom(
            _oldOwner,
            msg.sender,
            _tokenId,
            ""
        );

        // send funds to _oldOwner
        _oldOwner.transfer(msg.value.sub(feeAmount));

        ICellRepository(metaCellTokenAddress).addMetaCell(cell);

        if (sellingMetaCells.length > 1 && metaCellsOwners.length > 1) {
            sellingMetaCells[index] = sellingMetaCells[
                sellingMetaCells.length - 1
            ];
            metaCellsOwners[index] = metaCellsOwners[
                metaCellsOwners.length - 1
            ];
        }
        sellingMetaCells.pop();
        metaCellsOwners.pop();

        emit MetaCellSold(_tokenId);
    }

    function getCellIndex(uint256 _tokenId) internal view returns (uint256) {
        uint256 index;
        for (index = 0; index < sellingMetaCells.length; index++) {
            if (sellingMetaCells[index] == _tokenId) {
                return index;
            }
        }

        return type(uint256).max;
    }

    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice)
        external
        override
    {
        require(
            _newPrice > 0 && _newPrice != type(uint256).max,
            "Invalid price"
        );
        require(_tokenId != type(uint256).max, "Invalid token");

        CellData.Cell memory cell = ICellRepository(metaCellTokenAddress)
            .getMetaCell(msg.sender, _tokenId);
        require(msg.sender == cell.user, "You are not the owner");
        cell.price = _newPrice;

        // update cell in repository
        ICellRepository(metaCellTokenAddress).updateMetaCell(cell, msg.sender);

        emit MetaCellPriceUpdated(_tokenId);
    }

    function removeCellFromSale(uint256 _tokenId) external override {
        // remove token from sale list
        uint256 index = getCellIndex(_tokenId);
        require(index != type(uint256).max, "Invalid token index");

        CellData.Cell memory cell = ICellRepository(metaCellTokenAddress)
            .getMetaCell(msg.sender, _tokenId);
        require(msg.sender == cell.user, "You are not the owner");

        cell.onSale = false;

        // update cell in repository; marketplace should be allowed caller
        ICellRepository(metaCellTokenAddress).updateMetaCell(cell, msg.sender);

        if (sellingMetaCells.length > 1 && metaCellsOwners.length > 1) {
            sellingMetaCells[index] = sellingMetaCells[
                sellingMetaCells.length - 1
            ];
            metaCellsOwners[index] = metaCellsOwners[
                metaCellsOwners.length - 1
            ];
        }
        sellingMetaCells.pop();
        metaCellsOwners.pop();

        emit MetaCellRemovedFromMarketPlace(_tokenId);
    }

    function sellMetaCell(uint256 _tokenId, uint256 _price) external override {
        require(_price > 0 && _price != type(uint256).max, "Invalid price");
        require(_tokenId != type(uint256).max, "Invalid token");

        CellData.Cell memory cell = ICellRepository(metaCellTokenAddress)
            .getMetaCell(msg.sender, _tokenId);
        require(msg.sender == cell.user, "You are not the owner");
        require(!cell.onSale, "Token already added to sale list");

        // set price and sale flag for cell
        cell.price = _price;
        cell.onSale = true;

        // update cell in repository
        ICellRepository(metaCellTokenAddress).updateMetaCell(cell, msg.sender);

        // add to array of selling tokens
        sellingMetaCells.push(_tokenId);
        metaCellsOwners.push(cell.user);

        emit MetaCellAddedToMarketplace(_tokenId);
    }

    function buyModule(uint256 id) external override {
        require(modulesOnSale[id] != 0, "Empty price");
        require(IERC721(module).ownerOf(id) != msg.sender, "You are the owner");
        require(
            IERC20(mdmaTokenAddress).balanceOf(msg.sender) > modulesOnSale[id],
            "Not enough funds"
        );
        IERC20(mdmaTokenAddress).transferFrom(
            msg.sender,
            address(this),
            modulesOnSale[id]
        );
        uint256 feeAmount = getFeeAmount(modulesOnSale[id]);
        IERC20(mdmaTokenAddress).approve(
            address(this),
            modulesOnSale[id].sub(feeAmount)
        );
        IERC20(mdmaTokenAddress).transferFrom(
            address(this),
            IERC721(module).ownerOf(id),
            modulesOnSale[id].sub(feeAmount)
        );

        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(module).safeTransferFrom(
            IERC721(module).ownerOf(id),
            msg.sender,
            id,
            ""
        );
        delete modulesOnSale[id];
        EnumerableSet.remove(modules, id);
        emit ModuleSold(id);
    }

    function sellModule(uint256 id, uint256 price) external override {
        require(price != 0, "Invalid price");
        require(IERC721(module).ownerOf(id) == msg.sender, "Invalid owner");
        modulesOnSale[id] = price;
        EnumerableSet.add(modules, id);
        emit ModuleAddedToMarketPlace(id);
    }

    function removeModuleFromSale(uint256 id) external override {
        require(modulesOnSale[id] != 0, "Module is not on sale");
        require(IERC721(module).ownerOf(id) == msg.sender, "Invalid owner");
        delete modulesOnSale[id];
        EnumerableSet.remove(modules, id);
        emit ModuleRemovedFromMarketPlace(id);
    }

    function getModulesOnSale()
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(modules);
    }

    function getModulesPrice(uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return modulesOnSale[id];
    }

    function updateModulesPrice(uint256 id, uint256 price) external override {
        require(
            IERC721(module).ownerOf(id) == msg.sender,
            "You are not the owner"
        );
        require(
            EnumerableSet.contains(modules, id),
            "Module is not in marketplace"
        );
        modulesOnSale[id] = price;
        emit ModulePriceUpdated(id);
    }

    function buyNanoCell(uint256 id) external override {
        require(nanoCellOnSale[id] != 0, "Empty price");
        require(
            IERC721(nanoCellTokenAddress).ownerOf(id) != msg.sender,
            "You are the owner"
        );
        require(
            IERC20(mdmaTokenAddress).balanceOf(msg.sender) > nanoCellOnSale[id],
            "Not enough funds"
        );
        IERC20(mdmaTokenAddress).transferFrom(
            msg.sender,
            address(this),
            nanoCellOnSale[id]
        );
        uint256 feeAmount = getFeeAmount(nanoCellOnSale[id]);
        IERC20(mdmaTokenAddress).approve(
            address(this),
            nanoCellOnSale[id].sub(feeAmount)
        );
        IERC20(mdmaTokenAddress).transferFrom(
            address(this),
            IERC721(nanoCellTokenAddress).ownerOf(id),
            nanoCellOnSale[id].sub(feeAmount)
        );

        // NOTE: marketplace(this contract) should be approved by token owner to transfer cell
        IERC721(nanoCellTokenAddress).safeTransferFrom(
            IERC721(nanoCellTokenAddress).ownerOf(id),
            msg.sender,
            id,
            ""
        );
        delete nanoCellOnSale[id];
        EnumerableSet.remove(nanoCells, id);
        emit NanoCellSold(id);
    }

    function sellNanoCell(uint256 id, uint256 price) external override {
        require(price != 0, "Invalid price");
        require(
            IERC721(nanoCellTokenAddress).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        nanoCellOnSale[id] = price;
        EnumerableSet.add(nanoCells, id);
        emit NanoCellAddedToMarketPlace(id);
    }

    function removeNanoCellFromSale(uint256 id) external override {
        require(nanoCellOnSale[id] != 0, "Module is not on sale");
        require(
            IERC721(nanoCellTokenAddress).ownerOf(id) == msg.sender,
            "Invalid owner"
        );
        delete nanoCellOnSale[id];
        EnumerableSet.remove(nanoCells, id);
        emit NanoCellRemovedFromMarketPlace(id);
    }

    function getNanoCellsOnSale()
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(nanoCells);
    }

    function getNanoCellPrice(uint256 id)
        external
        view
        override
        returns (uint256)
    {
        return nanoCellOnSale[id];
    }

    function updateNanoCellPrice(uint256 id, uint256 price) external override {
        require(
            IERC721(nanoCellTokenAddress).ownerOf(id) == msg.sender,
            "You are not the owner"
        );
        require(
            EnumerableSet.contains(nanoCells, id),
            "Nano Cell is not in marketplace"
        );
        nanoCellOnSale[id] = price;
        emit NanoCellPriceUpdated(id);
    }

    function setPricePerBox(uint256 price) external override isAdmin {
        pricePerBox = price;
        emit ModuleBoxPriceChanged(price);
    }

    function getPricePerBox() external view override returns (uint256) {
        return pricePerBox;
    }

    function buyBox(address owner) external override {
        require(
            IERC20(mdmaTokenAddress).balanceOf(msg.sender) >= pricePerBox,
            "Not enough funds"
        );

        //TODO: ideally we should send mdma directly to feeWallet
        IERC20(mdmaTokenAddress).transferFrom(
            msg.sender,
            address(this),
            pricePerBox
        );

        boxCounter.increment();
        Modules.ModuleBox memory box = Modules.ModuleBox(
            boxCounter.current(),
            owner,
            block.number + 10
        ); // TODO define random range

        boxes[box.id] = box;
        EnumerableSet.add(boxIds[owner], box.id);
        emit ModuleBoxCreated(box.id, box.expired);
    }

    function openBox(uint256 id) external override {
        require(id > 0, "Incorect Box Id");
        require(msg.sender == boxes[id].owner, "You do not own of the module");
        require(block.number >= boxes[id].expired, "Not ready to be opened");

        EnumerableSet.remove(boxIds[msg.sender], id);
        delete boxes[id];
        emit ModuleBoxOpened(id);

        IMintable(module).mint(msg.sender, 1);
    }

    function getBoxById(uint256 id)
        external
        view
        override
        returns (Modules.ModuleBox memory)
    {
        return boxes[id];
    }

    function getUserBoxes(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return EnumerableSet.values(boxIds[owner]);
    }

    function numberOfEnhancersType() external view override returns (uint) {
        return enhancerIds.current();
    }

}