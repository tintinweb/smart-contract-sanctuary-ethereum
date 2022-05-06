/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


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



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


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



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



pragma solidity ^0.8.0;


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity ^0.8.0;



contract LiquidForge is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 

    uint256 public  PAD_DISTRIBUTION_AMOUNT;
    uint256 public  TIGER_DISTRIBUTION_AMOUNT;
    uint256 public  FUNDAE_DISTRIBUTION_AMOUNT;
    uint256 public  LEGENDS_DISTRIBUTION_AMOUNT;
    uint256 public  AZUKI_DISTRIBUTION_AMOUNT;

    mapping (uint256 => bool) public padClaimed;
    mapping (uint256 => bool) public tigerClaimed;
    mapping (uint256 => bool) public fundaeClaimed;
    mapping (uint256 => bool) public legendsClaimed;
    mapping (uint256 => bool) public azukiClaimed;

    //addresses 
    address nullAddress = 0x0000000000000000000000000000000000000000;
    address public legendsAddress;
    address public padAddress;
    address public tigerAddress;
    address public cubsAddress;
    address public fundaeAddress;
    address public azukiAddress;
    address public membershipAddress;

    address public erc20Address;

    //uint256's 
    uint256 public expiration; 
    uint256 public minBlockToClaim; 
    //rate governs how often you receive your token
    uint256 public legendsRate; 
    uint256 public padRate; 
    uint256 public tigerRate; 
    uint256 public cubsRate; 
    uint256 public fundaeRate; 
    uint256 public azukiRate; 
  
    // mappings 

    mapping(uint256 => uint256) public _legendsForgeBlocks;
    mapping(uint256 => address) public _legendsTokenForges;

    mapping(uint256 => uint256) public _padForgeBlocks;
    mapping(uint256 => address) public _padTokenForges;
 
    mapping(uint256 => uint256) public _tigerForgeBlocks;
    mapping(uint256 => address) public _tigerTokenForges;

    mapping(uint256 => uint256) public _cubsForgeBlocks;
    mapping(uint256 => address) public _cubsTokenForges;

    mapping(uint256 => uint256) public _fundaeForgeBlocks;
    mapping(uint256 => address) public _fundaeTokenForges;

    mapping(uint256 => uint256) public _azukiForgeBlocks;
    mapping(uint256 => address) public _azukiTokenForges;

    mapping(address => EnumerableSet.UintSet) private _membershipForges;


    constructor(
      address _padAddress,
      address _legendsAddress,
      address _tigerAddress,
      address _cubsAddress,
      address _fundaeAddress,
      address _azukiAddress,
      address _membershipAddress ,
      address _erc20Address

    ) {
        padAddress = _padAddress;
        padRate = 0;
        legendsAddress = _legendsAddress;
        legendsRate = 0;
        tigerAddress = _tigerAddress;
        tigerRate = 0;
        cubsAddress = _cubsAddress;
        cubsRate = 0;
        fundaeAddress = _fundaeAddress;
        fundaeRate = 0;
        azukiAddress = _azukiAddress;
        azukiRate = 0;
        expiration = block.number + 0;
        erc20Address = _erc20Address;
        membershipAddress = _membershipAddress;
       PAD_DISTRIBUTION_AMOUNT = 5000000000000000000;
       TIGER_DISTRIBUTION_AMOUNT = 5000000000000000000;
       FUNDAE_DISTRIBUTION_AMOUNT = 5000000000000000000;
       AZUKI_DISTRIBUTION_AMOUNT = 5000000000000000000;
       LEGENDS_DISTRIBUTION_AMOUNT = 25000000000000000000;
       minBlockToClaim = 1;

        _pause();
 
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Set this to a expiration block to disable the ability to continue accruing tokens past that block number. which is caclculated as current block plus the parm

    // Set a multiplier for how many tokens to earn each time a block passes. and the min number of blocks needed to pass to claim rewards

    function setRates(uint256 _legendsRate,uint256 _cubsRate, uint256 _padRate, uint256 _tigerRate, uint256 _fundaeRate, uint256 _azukiRate, uint256 _minBlockToClaim, uint256 _expiration ) public onlyOwner() {
      legendsRate = _legendsRate;
      cubsRate = _cubsRate;
      padRate = _padRate;
      tigerRate = _tigerRate;
      fundaeRate = _fundaeRate;
      azukiRate = _azukiRate;
      minBlockToClaim = _minBlockToClaim;
      expiration = block.number + _expiration;
    }

    function rewardClaimable(uint256 tokenId, address nftaddress ) public view returns (bool) {
        uint256 blockCur = Math.min(block.number, expiration);
        if(nftaddress == legendsAddress && _legendsForgeBlocks[tokenId] > 0){
           return (blockCur - _legendsForgeBlocks[tokenId]  > minBlockToClaim);
        }
        if(nftaddress == padAddress && _padForgeBlocks[tokenId] > 0){
           return (blockCur - _padForgeBlocks[tokenId]  > minBlockToClaim);
        }
        if(nftaddress == tigerAddress && _tigerForgeBlocks[tokenId] > 0){
           return (blockCur - _tigerForgeBlocks[tokenId]  > minBlockToClaim);
        }
        if(nftaddress == cubsAddress && _cubsForgeBlocks[tokenId] > 0){
           return (blockCur - _cubsForgeBlocks[tokenId]  > minBlockToClaim);
        }
        if(nftaddress == fundaeAddress && _fundaeForgeBlocks[tokenId] > 0){
           return (blockCur - _fundaeForgeBlocks[tokenId]  > minBlockToClaim);
        }
        if(nftaddress == azukiAddress && _azukiForgeBlocks[tokenId] > 0){
           return (blockCur - _azukiForgeBlocks[tokenId]  > minBlockToClaim);
        }
       return false;
    }

        //reward amount by address/tokenIds[]
    function calculateReward(address account, uint256 tokenId,address nftaddress ) 
      public 
      view 
      returns (uint256) 
    {
        if (nftaddress == legendsAddress){
      require(Math.min(block.number, expiration) > _legendsForgeBlocks[tokenId], "Invalid blocks");
      return legendsRate * 
          (_legendsTokenForges[tokenId] == account ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _legendsForgeBlocks[tokenId]);
        }
        if (nftaddress == tigerAddress){
      require(Math.min(block.number, expiration) > _tigerForgeBlocks[tokenId], "Invalid blocks");
      return tigerRate * 
          (_tigerTokenForges[tokenId] == account ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _tigerForgeBlocks[tokenId]);
        }
        if (nftaddress == cubsAddress){
      require(Math.min(block.number, expiration) > _cubsForgeBlocks[tokenId], "Invalid blocks");
      return cubsRate * 
          (_cubsTokenForges[tokenId] == account ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _cubsForgeBlocks[tokenId]);
        }
        if (nftaddress == padAddress){
      require(Math.min(block.number, expiration) > _padForgeBlocks[tokenId], "Invalid blocks");
      return padRate * 
          (_padTokenForges[tokenId] == account ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _padForgeBlocks[tokenId]);
        }
        if (nftaddress == azukiAddress){
      require(Math.min(block.number, expiration) > _azukiForgeBlocks[tokenId], "Invalid blocks");
      return azukiRate * 
          (_azukiTokenForges[tokenId] == account ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _azukiForgeBlocks[tokenId]);
        }
        return 0;
    }


    //reward claim function 
    function ClaimRewards(uint256[] calldata tokenIds, address nftaddress) public whenNotPaused {
        uint256 reward; 
        uint256 blockCur = Math.min(block.number, expiration);
        EnumerableSet.UintSet storage forgeSet = _membershipForges[msg.sender];

        require(forgeSet.length() > 0, "No Membership Forged");

        if (nftaddress==legendsAddress) {
                for (uint256 i; i < tokenIds.length; i++) {
                    require(IERC721(legendsAddress).ownerOf(tokenIds[i]) == msg.sender);
                    require(blockCur - _legendsForgeBlocks[tokenIds[i]]  > minBlockToClaim);                  
                }

            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],legendsAddress);
                _legendsForgeBlocks[tokenIds[i]] = blockCur;
            }

                for(uint256 i; i < tokenIds.length; ++i) {
                    uint256 tokenId = tokenIds[i];
                    if(!legendsClaimed[tokenId]) {
                        legendsClaimed[tokenId] = true;
                        reward += LEGENDS_DISTRIBUTION_AMOUNT;
                    }
                }
        }

        if(nftaddress==padAddress) {
            for (uint256 i; i < tokenIds.length; i++) {
                    require(IERC721(padAddress).ownerOf(tokenIds[i]) == msg.sender);
                    require(blockCur - _padForgeBlocks[tokenIds[i]]  > minBlockToClaim);                  
                }

            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],padAddress);
                _padForgeBlocks[tokenIds[i]] = blockCur;
            }

            for(uint256 i; i < tokenIds.length; ++i) {
                    uint256 tokenId = tokenIds[i];
                    if(!padClaimed[tokenId]) {
                        padClaimed[tokenId] = true;
                        reward += PAD_DISTRIBUTION_AMOUNT;
                    }
                }

        }

        if(nftaddress==tigerAddress){
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(tigerAddress).ownerOf(tokenIds[i]) == msg.sender);
            require(blockCur - _tigerForgeBlocks[tokenIds[i]]  > minBlockToClaim);
            
                }

            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],tigerAddress);
                _tigerForgeBlocks[tokenIds[i]] = blockCur;
            }

            for(uint256 i; i < tokenIds.length; ++i) {
                    uint256 tokenId = tokenIds[i];
                    if(!tigerClaimed[tokenId]) {
                        tigerClaimed[tokenId] = true;
                        reward += TIGER_DISTRIBUTION_AMOUNT;
                    }
                }
        }

        if(nftaddress==cubsAddress){
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(cubsAddress).ownerOf(tokenIds[i]) == msg.sender);
            require(blockCur - _cubsForgeBlocks[tokenIds[i]]  > minBlockToClaim);
            
                } 

            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],cubsAddress);
                _cubsForgeBlocks[tokenIds[i]] = blockCur;
            }

        }

        if (nftaddress==fundaeAddress){
            for (uint256 i; i < tokenIds.length; i++) {
                    require(IERC721(fundaeAddress).ownerOf(tokenIds[i]) == msg.sender);
                    require(blockCur - _fundaeForgeBlocks[tokenIds[i]]  > minBlockToClaim);
                    
                }
            

            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],fundaeAddress);
                _fundaeForgeBlocks[tokenIds[i]] = blockCur;
            }

            for(uint256 i; i < tokenIds.length; ++i) {
                    uint256 tokenId = tokenIds[i];
                    if(!fundaeClaimed[tokenId]) {
                        fundaeClaimed[tokenId] = true;
                        reward += FUNDAE_DISTRIBUTION_AMOUNT;
                    }
                }
        }
        
        if(nftaddress==azukiAddress){
            for (uint256 i; i < tokenIds.length; i++) {
                    require(IERC721(azukiAddress).ownerOf(tokenIds[i]) == msg.sender);
                    require(blockCur - _azukiForgeBlocks[tokenIds[i]]  > minBlockToClaim);
                    
                }            
            for (uint256 i; i < tokenIds.length; i++) {
                reward += calculateReward(msg.sender, tokenIds[i],azukiAddress);
                _azukiForgeBlocks[tokenIds[i]] = blockCur;
            }

            for(uint256 i; i < tokenIds.length; ++i) {
                    uint256 tokenId = tokenIds[i];
                    if(!azukiClaimed[tokenId]) {
                        azukiClaimed[tokenId] = true;
                        reward += AZUKI_DISTRIBUTION_AMOUNT;
                    }
                }
        }

      if (reward > 0) {
        IERC20(erc20Address).transfer(msg.sender, reward);
      }
    }

        //forge function. 
    function Forge(uint256[] calldata tokenIds,address nftaddress) external whenNotPaused {
        uint256 blockCur = block.number;
        EnumerableSet.UintSet storage forgeSet = _membershipForges[msg.sender];
        require(forgeSet.length() > 0, "No Membership Forged");
        if (nftaddress==legendsAddress) {
            for (uint256 i; i < tokenIds.length; i++) {
                require(IERC721(legendsAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that Legend");
                require(_legendsTokenForges[tokenIds[i]] != msg.sender);            
            }
            for (uint256 i; i < tokenIds.length; i++) {
                _legendsTokenForges[tokenIds[i]] = msg.sender;
                _legendsForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
        if (nftaddress==padAddress) {
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(padAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that PAD");
            require(_padTokenForges[tokenIds[i]] != msg.sender);
            }

            for (uint256 i; i < tokenIds.length; i++) {
                _padTokenForges[tokenIds[i]] = msg.sender;
                _padForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
        if (nftaddress==tigerAddress){
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(tigerAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that Tiger");
            require(_tigerTokenForges[tokenIds[i]] != msg.sender);
            }
            
            for (uint256 i; i < tokenIds.length; i++) {
                _tigerTokenForges[tokenIds[i]] = msg.sender;
                _tigerForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
        if (nftaddress==cubsAddress){
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(cubsAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that Cub");
            require(_cubsTokenForges[tokenIds[i]] != msg.sender);
            }
        
            for (uint256 i; i < tokenIds.length; i++) {
                _cubsTokenForges[tokenIds[i]] = msg.sender;
                _cubsForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
        if (nftaddress==fundaeAddress) {
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(fundaeAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that Fundae");
            require(_fundaeTokenForges[tokenIds[i]] != msg.sender);
            }
            
            for (uint256 i; i < tokenIds.length; i++) {
                _fundaeTokenForges[tokenIds[i]] = msg.sender;
                _fundaeForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
        if (nftaddress==azukiAddress) {
            for (uint256 i; i < tokenIds.length; i++) {
            require(IERC721(azukiAddress).ownerOf(tokenIds[i]) == msg.sender,"you do not own that Fundae");
            require(_azukiTokenForges[tokenIds[i]] != msg.sender);
            }
            
            for (uint256 i; i < tokenIds.length; i++) {
                _azukiTokenForges[tokenIds[i]] = msg.sender;
                _azukiForgeBlocks[tokenIds[i]] = blockCur;
            }
        }
    }

 //check forge amount. 
    function membershipForgesOf(address account)
      external 
      view 
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage forgeSet = _membershipForges[account];
      uint256[] memory tokenIds = new uint256[] (forgeSet.length());

      for (uint256 i; i < forgeSet.length(); i++) {
        tokenIds[i] = forgeSet.at(i);
      }

      return tokenIds;
    }
  
    //forge function. 
    function membershipForge(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != membershipAddress, "Invalid address");


        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(membershipAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );

            _membershipForges[msg.sender].add(tokenIds[i]);
        }
    }

    //withdrawal function.
    function membershipWithdraw(uint256[] calldata tokenIds) external whenNotPaused nonReentrant() {

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _membershipForges[msg.sender].contains(tokenIds[i]),
                "Staking: token not forgeed"
            );

            _membershipForges[msg.sender].remove(tokenIds[i]);

            IERC721(membershipAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    //withdrawal function.
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
        IERC20(erc20Address).transfer(msg.sender, tokenSupply);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

   

}