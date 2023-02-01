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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
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
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LasmStaking is Ownable,ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 rewardToken;

    bool public enableStaking;
    uint public totalRewardTokenAmount;
    uint public totalStakedToken;

    uint[4] public durations;
    uint[4] public rates;
    uint[3] public bonusRate;

    struct info{
        uint amount;
        uint lastClaim;
        uint stakeTime;
        uint durationCode;
        uint position;
        uint earned;
        uint bonus;
        uint lockedNftCount;
        uint unLockedNftTime;
    }

    mapping(address=>mapping(uint=>info)) public userStaked; //USER > ID > INFO
    mapping(address=>uint) public userId;
    mapping(address=>uint) public userTotalEarnedReward;
    mapping(address=>uint) public userTotalStaked;
    mapping(address=>uint[]) public stakedIds;


    IERC721 nftCollection;
    uint MIN_LOCKED_PERIOD;

    mapping(address => EnumerableSet.UintSet) private currentLockedNftTokens;

    event StakeAdded(
        address indexed _usr,
        uint _amount,
        uint startStakingTime,
        uint8 _durationCode,
        uint _stakedIndex
    );
    event Unstaked(address indexed _usr, uint _stakeIndex);
    event ClaimReward(address indexed _from, uint _claimedTime, uint _stakeIndex);
    event ClaimRewardAll(address indexed _from, uint _claimedTime, uint _amount);
    event RewardTokenRewardAdded(address indexed _from, uint256 _amount);
    event RewardTokenRewardRemoved(address indexed _to, uint256 _amount);
    event UpdateDuration(address indexed _from);
    event UpdateRate(address indexed _from);
    event UpdateBonusRate(address indexed _from);
    event LockNft(address account, uint256 nftCount);
    event UnLockNft(address account, uint256 nftCount);

    constructor() {
        durations = [30 days, 180 days, 365 days, 730 days];
        rates = [100, 700, 1500, 3200];
        bonusRate = [300, 75, 50];

        MIN_LOCKED_PERIOD = 365 days;
    }

    function setEnable(bool bEnable) external onlyOwner {
        enableStaking = bEnable;
    }

    function setRewardToken(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Wrong token address");
        rewardToken = _token;
    }

    function addRewardToken(uint256 _amount)
        external
        onlyOwner
    {
        totalRewardTokenAmount += _amount;
    }

    function withdrawRewardToken(uint256 _amount)
        external
        onlyOwner
    {
        require(_amount <= IERC20(rewardToken).balanceOf(address(this)), "Insufficient balance");
        totalRewardTokenAmount -= _amount;

        rewardToken.transfer(msg.sender, _amount);
    }

    function setNftCollection(IERC721 _nftCollection) external onlyOwner {
        require(address(_nftCollection) != address(0), "Wrong NFT collection address");
        nftCollection = _nftCollection;
    }

    function updateDuration(uint[4] memory _durations) external onlyOwner {
        durations = _durations;
        emit UpdateDuration(msg.sender);
    }

    function updateRate(uint[4] memory _rates) external onlyOwner {
        rates = _rates;
        emit UpdateRate(msg.sender);
    }

    function updateBonusRate(uint[3] memory _bonusRates) external onlyOwner {
        bonusRate = _bonusRates;
        emit UpdateBonusRate(msg.sender);
    }

    function stake(uint _amount, uint8 _durationCode, uint256 _lockNftCount) external nonReentrant {
        require(enableStaking,"Execution enableStaking");
        require(_durationCode < 4,"Invalid duration with lock nft count");

        if (_lockNftCount > 0) {
            require(nftCollection.balanceOf(msg.sender) >= _lockNftCount, "Invalid lock nft count");
            require(durations[_durationCode] >= MIN_LOCKED_PERIOD, "Invalid duration");
        }
        
        userId[msg.sender]++;

        uint bonus = calculateBonusRate(_durationCode, _lockNftCount);

        userStaked[msg.sender][userId[msg.sender]] = info(_amount, block.timestamp, block.timestamp,
                                                            _durationCode, stakedIds[msg.sender].length, 
                                                            0, bonus, _lockNftCount, 0);

        stakedIds[msg.sender].push(userId[msg.sender]);

        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Amount not sent");

        _lockNft(_lockNftCount);

        totalStakedToken += _amount;
        userTotalStaked[msg.sender] += _amount;

        emit StakeAdded(
            msg.sender,
            _amount,
            block.timestamp,
            _durationCode,
            stakedIds[msg.sender].length - 1
        );
    }

    function _lockNft(uint256 _nftCount) private {
        if (_nftCount == 0)
            return;

        uint tokenId;
        uint[] memory tokenIds = new uint[](_nftCount);
        for (uint256 i = 0; i < _nftCount; i++) {
            tokenId = IERC721Enumerable(address(nftCollection)).tokenOfOwnerByIndex(msg.sender, i);
            tokenIds[i] = tokenId;
        }

        for (uint256 i = 0; i < _nftCount; i++) {
            currentLockedNftTokens[msg.sender].add(tokenIds[i]);

            nftCollection.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit LockNft(msg.sender, _nftCount);
    }

    function calculateBonusRate(uint _durationCode, uint nftCount) public view returns (uint result) {
        if (durations[_durationCode] < MIN_LOCKED_PERIOD)
            return 0;

        if (nftCount <= 10) {
            result = bonusRate[0] + (nftCount - 1) * bonusRate[1];     // additional 0.75% for each item until 10 pieces
        }
        else if (nftCount > 10 && nftCount <= 15) {
            result = bonusRate[0] + 9 * bonusRate[1] + (nftCount - 10) * bonusRate[2];   // additional 0.5% for each item over 10 pieces
        }
        else {
            result = bonusRate[0] + 9 * bonusRate[1] + 5 * bonusRate[2];
        }
    }

    function getReward(address _user, uint _id) public view returns(uint reward) {
        info storage userInfo = userStaked[_user][_id];
        if (userInfo.unLockedNftTime == 0) {
            uint timeDiff = block.timestamp - userInfo.lastClaim;
            reward = userInfo.amount 
                    * timeDiff
                    * (rates[userInfo.durationCode] + userInfo.bonus) 
                    / (durations[userInfo.durationCode] * 10000);
        }
        else {
            if (userInfo.unLockedNftTime > userInfo.lastClaim) {
                uint timeDiff1 = block.timestamp - userInfo.unLockedNftTime;
                uint timeDiff2 = userInfo.unLockedNftTime - userInfo.lastClaim;

                uint reward1 = userInfo.amount 
                                * timeDiff1
                                * rates[userInfo.durationCode] 
                                / (durations[userInfo.durationCode] * 10000);

                uint reward2 = userInfo.amount 
                                * timeDiff2
                                * (rates[userInfo.durationCode] + userInfo.bonus) 
                                / (durations[userInfo.durationCode] * 10000);

                reward = reward1 + reward2;
            }
            else {
                uint timeDiff = block.timestamp - userInfo.lastClaim;
                reward = userInfo.amount 
                        * timeDiff
                        * rates[userInfo.durationCode]
                        / (durations[userInfo.durationCode] * 10000);
            }
        }
    }

    function getAllReward(address _user) public view returns(uint amount) {
        uint length = stakedIds[_user].length;
        for(uint i=0; i<length; i++){
            uint amountOfIndex = getReward(_user, stakedIds[_user][i]);
            amount += amountOfIndex;
        }
    }

    function getStakedInfo(address _user) public view 
        returns (info[] memory infors, uint[] memory claimable, uint[] memory pending) {
        uint length = stakedIds[_user].length;
        infors = new info[](length);
        claimable = new uint[](length);
        pending = new uint[](length);

        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[_user][stakedIds[_user][i]];
            infors[i] = userInfo;
            pending[i] = getReward(_user, stakedIds[_user][i]);
            claimable[i] = claimableReward(_user, stakedIds[_user][i]);
        }
    }

    function claimableReward(address _user, uint _id) public view returns(uint) {
        info storage userInfo = userStaked[_user][_id];

        if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
            return 0;

        return getReward(_user, _id);
    }

    function claimableAllReward(address _user) public view returns(uint) {
        uint amount;
        uint length = stakedIds[_user].length;
        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[_user][stakedIds[_user][i]];
            if (userInfo.amount == 0)
                continue;

            if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
                continue;

            uint amountIndex = getReward(_user, stakedIds[_user][i]);
            amount += amountIndex;
        }

        return amount;
    }

    function _claim(uint _id) private {
        require(userStaked[msg.sender][_id].amount != 0, "Invalid ID");

        uint amount = getReward(msg.sender, _id);
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Insufficient token to pay your reward right now"
        );

        rewardToken.transfer(msg.sender, amount);

        info storage userInfo = userStaked[msg.sender][_id];
        userInfo.lastClaim = block.timestamp;
        userInfo.earned += amount;

        userTotalEarnedReward[msg.sender] += amount;
        totalRewardTokenAmount -= amount;
    }

    function claimReward(uint _id) public nonReentrant {
        info storage userInfo = userStaked[msg.sender][_id];
        require (block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], 
            "Not claim yet, Locked period still.");

        _claim(_id);

        emit ClaimReward(msg.sender, block.timestamp, _id);
    }

    function claimAllReward() public nonReentrant {
        uint amount;
        uint length = stakedIds[msg.sender].length;
        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[msg.sender][stakedIds[msg.sender][i]];
            if (userInfo.amount == 0)
                continue;

            if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
                continue;

            uint amountIndex = getReward(msg.sender, stakedIds[msg.sender][i]);
            if (amountIndex == 0)
                continue;

            userInfo.lastClaim = block.timestamp;
            userInfo.earned += amountIndex;
            amount += amountIndex;
        }

        rewardToken.transfer(msg.sender, amount);
        totalRewardTokenAmount -= amount;
        userTotalEarnedReward[msg.sender] += amount;

        emit ClaimRewardAll(msg.sender, block.timestamp, amount);
    }

    function unstake(uint _amount, uint _id) external nonReentrant{
        _claim(_id);

        info storage userInfo = userStaked[msg.sender][_id];
        require(userInfo.amount != 0 && _amount <= userInfo.amount ,"Invalid ID");
        require(block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], "Not unlocked yet");

        if (_amount == userInfo.amount) {
            popSlot(_id);

            delete userStaked[msg.sender][_id];
        }
        else
            userInfo.amount -= _amount;

        require(
            rewardToken.balanceOf(address(this)) >= _amount,
            "Insufficient token to unstake right now"
        );

        rewardToken.transfer(msg.sender, _amount);

        totalStakedToken -= _amount;
        userTotalStaked[msg.sender] -= _amount;

        emit Unstaked(msg.sender, _id);
    }

    function unstake(uint _id) external nonReentrant{
        _claim(_id);

        info storage userInfo = userStaked[msg.sender][_id];
        require(userInfo.amount != 0,"Invalid ID");
        require(block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], "Not unlocked yet");

        require(
            rewardToken.balanceOf(address(this)) >= userInfo.amount,
            "Insufficient token to unstake right now"
        );

        rewardToken.transfer(msg.sender, userInfo.amount);

        popSlot(_id);
        delete userStaked[msg.sender][_id];

        totalStakedToken -= userInfo.amount;
        userTotalStaked[msg.sender] -= userInfo.amount;

        emit Unstaked(msg.sender, _id);
    }

    function popSlot(uint _id) internal {
        uint length = stakedIds[msg.sender].length;
        bool replace = false;
        for (uint256 i=0; i<length; i++) {
            if (stakedIds[msg.sender][i] == _id)
                replace = true;
            if (replace && i<length-1)
                stakedIds[msg.sender][i] = stakedIds[msg.sender][i+1];
        }
        stakedIds[msg.sender].pop();
    }

    function unLockNft(uint _userStakeId) public nonReentrant {
        info storage userInfo = userStaked[msg.sender][_userStakeId];
        uint tokenId;
        uint[] memory tokenIds = new uint[](userInfo.lockedNftCount);
        for (uint256 i = 0; i < userInfo.lockedNftCount; i++) {
            tokenId = currentLockedNftTokens[msg.sender].at(i);

            require(block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], "Can't unlock the Nft item");

            nftCollection.transferFrom(address(this), msg.sender, tokenId);

            tokenIds[i] = tokenId;
        }

        for (uint256 i = 0; i < userInfo.lockedNftCount; i++) {
            currentLockedNftTokens[msg.sender].remove(tokenIds[i]);
        }

        userInfo.lockedNftCount = 0;
        userInfo.unLockedNftTime = block.timestamp;

        emit UnLockNft(msg.sender, userInfo.lockedNftCount);
    }

    function getTokenIdsOfOwner(address _account) public view returns(uint[] memory) {
        uint nNftCount = currentLockedNftTokens[_account].length();

        uint[] memory tokenIds = new uint[](nNftCount);
        for (uint i=0; i<nNftCount; i++) {
            tokenIds[i] = currentLockedNftTokens[_account].at(i);
        }

        return tokenIds;
    }
}