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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title Investment Fund interface
 */
interface IInvestmentFund {
    struct Details {
        string name;
        address currency;
        address investmentNft;
        address treasuryWallet;
        uint16 managementFee;
        uint256 cap;
        uint256 totalInvestment;
        uint256 totalIncome;
        Payout[] payouts;
        bytes32 state;
    }

    struct Payout {
        uint256 value;
        uint248 blockNumber;
        bool inProfit;
    }

    /**
     * @dev Emitted when breakeven for investment fund is reached
     * @param breakeven Breakeven value
     */
    event BreakevenReached(uint256 indexed breakeven);

    /**
     * @dev Emitted when investment cap is reached
     * @param cap Cap value
     */
    event CapReached(uint256 cap);

    /**
     * @dev Emitted when user invests in fund
     * @param investor Investor address
     * @param currency Currency used for investment
     * @param value Amount of tokens spent for investment
     * @param fee Amount of tokens spent for fee
     */
    event Invested(address indexed investor, address indexed currency, uint256 value, uint256 fee);

    /**
     * @dev Emitted when new profit is provided to investment fund
     * @param investmentFund Address of investment fund to which profit is provided
     * @param value Amount of tokens withdrawn
     * @param blockNumber Number of block in which profit is provided
     */
    event ProfitProvided(address indexed investmentFund, uint256 value, uint256 indexed blockNumber);

    /**
     * @dev Emitted when user withdraws profit from fund
     * @param recipient Recipient address
     * @param currency Currency used for withdrawal
     * @param amount Amount of tokens withdrawn
     */
    event ProfitWithdrawn(address indexed recipient, address indexed currency, uint256 amount);

    /**
     * @dev Emitted when project is added to a fund
     * @param caller Address that added project
     * @param project Project address
     */
    event ProjectAdded(address indexed caller, address indexed project);

    /**
     * @dev Emitted when project is removed from a fund
     * @param caller Address that removed project
     * @param project Project address
     */
    event ProjectRemoved(address indexed caller, address indexed project);

    /**
     * @dev Invests 'amount' number of USD Coin tokens to investment fund.
     *
     * Requirements:
     * - 'amount' must be greater than zero.
     * - Caller must have been allowed in USD Coin to move this token by {approve}.
     *
     * Emits a {Invested} event.
     *
     * @param amount Amount of tokens to be invested
     */
    function invest(uint240 amount) external;

    /**
     * @dev Withdraws 'amount' number of USD Coin tokens using investment NFT.
     *
     * Emits a {Withdrawn} event.
     *
     * @param amount Amount of tokens to be withdrawn
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Returns amount of profit payouts made within a fund.
     */
    function getPayoutsCount() external view returns (uint256);

    /**
     * @dev Returns funds available for account to be withdrawn.
     *
     * @param account Wallet address for which to check available funds
     */
    function getAvailableFunds(address account) external view returns (uint256);

    /**
     * @dev Returns carry fee for requested withdrawal amount. Raises exception if amount is higher than available funds.
     *
     * Requirements:
     * - 'amount' must be lower or equal to withdrawal available funds returned from 'getAvailableFunds' method.
     *
     * @param account Wallet address for which to retrieve withdrawal details
     * @param amount Amount of funds requested to withdraw
     */
    function getWithdrawalCarryFee(address account, uint256 amount) external view returns (uint256);

    /**
     * @dev Adds project to investment fund. Throws if project already exists in fund.
     *
     * Requirements:
     * - Project must support IProject interface
     * - Project must not exist in fund
     *
     * Emits ProjectAdded event
     *
     * @param project Address of project to be added
     */
    function addProject(address project) external;

    /**
     * @dev Returns list of projects within a fund
     */
    function listProjects() external view returns (address[] memory);

    /**
     * @dev Returns number of projects within fund
     */
    function getProjectsCount() external view returns (uint256);

    /**
     * @dev Rmoves a projects from fund
     *
     * Requirements:
     * - Project must exist in fund
     *
     * Emits ProjectRemoved event
     *
     * @param project Address of project to be added
     */
    function removeProject(address project) external;

    /**
     * @dev Provides 'amount' number of USD Coin tokens to be distributed between investors.
     *
     * Emits a {ProfitProvided} event.
     *
     * @param amount Amount of tokens provided within payout
     */
    function provideProfit(uint256 amount) external;

    /**
     * @dev Returns if fund is already in profit (breakeven is reached).
     */
    function isInProfit() external view returns (bool);

    /**
     * @dev Returns public details of investment fund
     */
    function getDetails() external view returns (Details memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IInvestmentNFT is IERC721Enumerable {
    function mint(address to, uint256 value) external;

    function burn(uint256 tokenId) external;

    function getInvestmentValue(address account) external view returns (uint256);

    function getPastInvestmentValue(address account, uint256 blockNumber) external view returns (uint256);

    function getTotalInvestmentValue() external view returns (uint256);

    function getPastTotalInvestmentValue(uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title IProject interface
 */
interface IProject {
    struct ProjectDetails {
        string name;
        bytes32 status;
        address vestingContract;
    }

    /**
     * @dev Emitted when token vesting contract changes
     * @param caller Address that sets vesting contract
     * @param oldVesting Address of old vesting contract
     * @param newVesting Address of new vesting contract
     */
    event VestingContractChanged(address indexed caller, address indexed oldVesting, address indexed newVesting);

    /**
     * @dev Sets project token vesting contract
     * @param vesting_ Address of vesting contract
     */
    function setVesting(address vesting_) external;

    /**
     * @dev Returns project details
     */
    function getDetails() external view returns (ProjectDetails memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IInvestmentFund.sol";
import "./interfaces/IInvestmentNFT.sol";
import "./interfaces/IProject.sol";
import "./LibFund.sol";
import "./StateMachine.sol";

/**
 * @title Investment Fund contract
 */
contract InvestmentFund is StateMachine, IInvestmentFund, ReentrancyGuard, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PayoutPtr {
        uint256 index;
        uint256 withdrawn;
    }

    string public name;
    IERC20 public currency;
    IInvestmentNFT public investmentNft;
    address public treasuryWallet;
    uint16 public managementFee;
    uint256 public cap;
    uint256 public totalInvestment;
    uint256 public totalIncome;

    Payout[] public payouts;
    mapping(address => uint256) public userTotalWithdrawal; // maps account into total withdrawal amount

    mapping(address => PayoutPtr) private _currentPayout; // maps account into payout recently used for withdrawal
    EnumerableSet.AddressSet private _projects;

    /**
     * @dev Initializes the contract
     * @param name_ Investment fund name
     * @param currency_ Address of currency for investments
     * @param investmentNft_ Address of investment NFT contract
     * @param treasuryWallet_ Address of treasury wallet
     * @param managementFee_ Management fee in basis points
     * @param cap_ Cap value
     */
    constructor(
        string memory name_,
        address currency_,
        address investmentNft_,
        address treasuryWallet_,
        uint16 managementFee_,
        uint256 cap_
    ) StateMachine(LibFund.STATE_EMPTY) {
        require(currency_ != address(0), "Invalid currency address");
        require(investmentNft_ != address(0), "Invalid NFT address");
        require(treasuryWallet_ != address(0), "Invalid treasury wallet address");
        require(managementFee_ < 10000, "Invalid management fee");
        require(cap_ > 0, "Invalid investment cap");
        require(
            IERC165(investmentNft_).supportsInterface(type(IInvestmentNFT).interfaceId) == true,
            "Required interface not supported"
        );

        name = name_;
        currency = IERC20(currency_);
        investmentNft = IInvestmentNFT(investmentNft_);
        treasuryWallet = treasuryWallet_;
        managementFee = managementFee_;
        cap = cap_;

        _initializeStates();
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function invest(uint240 amount) external override onlyAllowedStates nonReentrant {
        require(amount > 0, "Invalid amount invested");

        uint256 newTotalInvestment = totalInvestment + amount;
        require(newTotalInvestment <= cap, "Total invested funds exceed cap");

        if (newTotalInvestment >= cap) {
            currentState = LibFund.STATE_CAP_REACHED;
            emit CapReached(cap);
        }

        totalInvestment = newTotalInvestment;

        _invest(msg.sender, amount);
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function withdraw(uint256 amount) external onlyAllowedStates nonReentrant {
        require(amount > 0, "Attempt to withdraw zero tokens");

        (uint256 actualAmount, uint256 carryFee, PayoutPtr memory currentPayout) = _getWithdrawalDetails(
            msg.sender,
            amount
        );

        require(actualAmount == amount, "Withdrawal amount exceeds available funds");

        userTotalWithdrawal[msg.sender] += amount;
        _currentPayout[msg.sender] = currentPayout;

        emit ProfitWithdrawn(msg.sender, address(currency), amount);

        if (carryFee > 0) {
            _transfer(currency, treasuryWallet, carryFee);
        }
        _transfer(currency, msg.sender, amount - carryFee);
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function getPayoutsCount() external view returns (uint256) {
        return payouts.length;
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function getAvailableFunds(address account) external view returns (uint256) {
        uint256 availableFunds = _getRemainingFundsFromRecentPayout(account);
        for (uint256 i = _currentPayout[account].index + 1; i < payouts.length; i++) {
            availableFunds += _getUserIncomeFromPayout(account, i);
        }
        return availableFunds;
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function getWithdrawalCarryFee(address account, uint256 amount) external view returns (uint256) {
        (uint256 actualAmount, uint256 carryFee, ) = _getWithdrawalDetails(account, amount);
        require(actualAmount == amount, "Withdrawal amount exceeds available funds");
        return carryFee;
    }

    function addProject(address project) external onlyAllowedStates {
        // TODO: limit role access
        require(project != address(0), "Project is zero address");

        emit ProjectAdded(msg.sender, project);
        require(_projects.add(project), "Project already exists");
    }

    function listProjects() external view returns (address[] memory) {
        return _projects.values();
    }

    function getProjectsCount() external view returns (uint256) {
        return _projects.length();
    }

    function removeProject(address project) external onlyAllowedStates {
        // TODO: limit role access
        emit ProjectRemoved(msg.sender, project);
        require(_projects.remove(project), "Project does not exist");
    }

    function startCollectingFunds() external onlyAllowedStates {
        // TODO: limit role access
        currentState = LibFund.STATE_FUNDS_IN;
    }

    function stopCollectingFunds() external onlyAllowedStates {
        // TODO: limit role access
        currentState = LibFund.STATE_CAP_REACHED;
    }

    function deployFunds() external onlyAllowedStates {
        // TODO: limit role access
        currentState = LibFund.STATE_FUNDS_DEPLOYED;
    }

    function activateFund() external onlyAllowedStates {
        // TODO: limit role access
        currentState = LibFund.STATE_ACTIVE;
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function provideProfit(uint256 amount) external onlyAllowedStates nonReentrant {
        // TODO: limit role access
        require(amount > 0, "Zero profit provided");

        uint256 newTotalIncome = totalIncome + amount;

        if (isInProfit()) {
            payouts.push(Payout(amount, uint248(block.number), true));
        } else {
            if (newTotalIncome > totalInvestment) {
                emit BreakevenReached(totalInvestment);
                uint256 profitAboveBreakeven = newTotalIncome - totalInvestment;
                payouts.push(Payout(amount - profitAboveBreakeven, uint248(block.number), false));
                payouts.push(Payout(profitAboveBreakeven, uint248(block.number), true));
            } else {
                payouts.push(Payout(amount, uint248(block.number), false));
                if (newTotalIncome == totalInvestment) {
                    emit BreakevenReached(totalInvestment);
                }
            }
        }

        totalIncome = newTotalIncome;

        emit ProfitProvided(address(this), amount, block.number);

        _transferFrom(currency, msg.sender, address(this), amount);
    }

    function closeFund() external onlyAllowedStates {
        // TODO: limit role access
        currentState = LibFund.STATE_CLOSED;
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function isInProfit() public view returns (bool) {
        return totalIncome >= totalInvestment;
    }

    /**
     * @inheritdoc IInvestmentFund
     */
    function getDetails() external view returns (Details memory) {
        return
            Details(
                name,
                address(currency),
                address(investmentNft),
                treasuryWallet,
                managementFee,
                cap,
                totalInvestment,
                totalIncome,
                payouts,
                currentState
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IInvestmentFund).interfaceId || super.supportsInterface(interfaceId);
    }

    function _initializeStates() internal {
        allowFunction(LibFund.STATE_EMPTY, this.addProject.selector);
        allowFunction(LibFund.STATE_EMPTY, this.removeProject.selector);
        allowFunction(LibFund.STATE_EMPTY, this.startCollectingFunds.selector);
        allowFunction(LibFund.STATE_FUNDS_IN, this.invest.selector);
        allowFunction(LibFund.STATE_FUNDS_IN, this.stopCollectingFunds.selector);
        allowFunction(LibFund.STATE_CAP_REACHED, this.deployFunds.selector);
        allowFunction(LibFund.STATE_FUNDS_DEPLOYED, this.activateFund.selector);
        allowFunction(LibFund.STATE_ACTIVE, this.provideProfit.selector);
        allowFunction(LibFund.STATE_ACTIVE, this.withdraw.selector);
        allowFunction(LibFund.STATE_ACTIVE, this.closeFund.selector);
    }

    function _invest(address investor, uint256 amount) internal {
        uint256 fee = (uint256(amount) * managementFee) / LibFund.BASIS_POINT_DIVISOR;

        emit Invested(investor, address(currency), amount, fee);

        _transferFrom(currency, investor, treasuryWallet, fee);
        _transferFrom(currency, investor, address(this), amount - fee);
        investmentNft.mint(investor, amount);
    }

    /**
     * @dev Returns actual withdrawal amount, carry fee and new current user payout for requested withdrawal amount.
     * @dev If actual amount is lower than the requested one it means that the latter is not available.
     *
     * @param account Wallet address for which to retrieve withdrawal details
     * @param requestedAmount Amount of funds requested to withdraw
     *
     * @return actualAmount Actual amount to withdraw - requested one if available or the maximum available otherwise
     * @return carryFee Carry fee taken on withdraw
     * @return newCurrentPayout Payout index with withdrawn amount after actual amount is withdrawn
     */
    function _getWithdrawalDetails(
        address account,
        uint256 requestedAmount
    ) private view returns (uint256 actualAmount, uint256 carryFee, PayoutPtr memory newCurrentPayout) {
        uint256 payoutIndex = _currentPayout[account].index;

        uint256 fundsFromPayout = _getRemainingFundsFromRecentPayout(account);
        if (requestedAmount <= fundsFromPayout) {
            return (
                requestedAmount,
                _calculateCarryFeeFromPayout(account, payoutIndex, requestedAmount),
                PayoutPtr(payoutIndex, _currentPayout[account].withdrawn + requestedAmount)
            );
        } else {
            actualAmount = fundsFromPayout;

            while (++payoutIndex < payouts.length) {
                fundsFromPayout = _getUserIncomeFromPayout(account, payoutIndex);

                if (requestedAmount <= actualAmount + fundsFromPayout) {
                    fundsFromPayout = requestedAmount - actualAmount;
                    return (
                        requestedAmount,
                        carryFee + _calculateCarryFeeFromPayout(account, payoutIndex, fundsFromPayout),
                        PayoutPtr(payoutIndex, fundsFromPayout)
                    );
                }
                carryFee += _calculateCarryFeeFromPayout(account, payoutIndex, fundsFromPayout);
                actualAmount += fundsFromPayout;
            }
            return (actualAmount, carryFee, PayoutPtr(payoutIndex - 1, fundsFromPayout));
        }
    }

    function _getUserIncomeFromPayout(address account, uint256 payoutIndex) private view returns (uint256) {
        require(payoutIndex < payouts.length, "Payout does not exist");

        Payout memory payout = payouts[payoutIndex];
        require(payout.blockNumber <= block.number, "Invalid payout block number");

        return _calculateUserIncomeInBlock(payout.value, account, payout.blockNumber);
    }

    function _calculateUserIncomeInBlock(
        uint256 value,
        address account,
        uint256 blockNumber
    ) private view returns (uint256) {
        uint256 totalInvestmentInBlock = (blockNumber < block.number)
            ? investmentNft.getPastTotalInvestmentValue(blockNumber)
            : investmentNft.getTotalInvestmentValue();

        if (totalInvestmentInBlock != 0) {
            uint256 walletInvestmentInBlock = (blockNumber < block.number)
                ? investmentNft.getPastInvestmentValue(account, blockNumber)
                : investmentNft.getInvestmentValue(account);

            return (value * walletInvestmentInBlock) / totalInvestmentInBlock;
        } else {
            return 0;
        }
    }

    function _getRemainingFundsFromRecentPayout(address account) private view returns (uint256) {
        PayoutPtr memory currentPayout = _currentPayout[account];
        return _getUserIncomeFromPayout(account, currentPayout.index) - currentPayout.withdrawn;
    }

    function _getCarryFeeDiscount(address /* account */, uint256 /* blockNumber */) private pure returns (uint256) {
        // carry fee will be calculated based on account staking conditions
        return 0;
    }

    function _calculateCarryFee(address account, uint256 blockNumber, uint256 amount) private pure returns (uint256) {
        uint256 carryFee = LibFund.DEFAULT_CARRY_FEE - _getCarryFeeDiscount(account, blockNumber);
        return (carryFee * amount) / LibFund.BASIS_POINT_DIVISOR;
    }

    function _calculateCarryFeeFromPayout(
        address account,
        uint256 payoutIndex,
        uint256 amount
    ) private view returns (uint256) {
        return
            (payouts[payoutIndex].inProfit && amount > 0)
                ? _calculateCarryFee(account, payouts[payoutIndex].blockNumber, amount)
                : 0;
    }

    function _transferFrom(IERC20 erc20Token, address from, address to, uint256 amount) private {
        require(erc20Token.transferFrom(from, to, amount), "Currency transfer failed");
    }

    function _transfer(IERC20 erc20Token, address to, uint256 amount) private {
        require(erc20Token.transfer(to, amount), "Currency transfer failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibFund {
    uint256 public constant BASIS_POINT_DIVISOR = 10000; // 100% in basis points
    uint256 public constant DEFAULT_CARRY_FEE = 5000;

    bytes32 public constant STATE_EMPTY = "Empty"; // 0x456d707479000000000000000000000000000000000000000000000000000000
    bytes32 public constant STATE_FUNDS_IN = "FundsIn"; // 0x46756e6473496e00000000000000000000000000000000000000000000000000
    bytes32 public constant STATE_CAP_REACHED = "CapReached"; // 0x4361705265616368656400000000000000000000000000000000000000000000
    bytes32 public constant STATE_FUNDS_DEPLOYED = "FundsDeployed"; // 0x46756e64734465706c6f79656400000000000000000000000000000000000000
    bytes32 public constant STATE_ACTIVE = "Active"; // 0x4163746976650000000000000000000000000000000000000000000000000000
    bytes32 public constant STATE_CLOSED = "Closed"; // 0x436c6f7365640000000000000000000000000000000000000000000000000000
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IInvestmentFund.sol";
import "./interfaces/IInvestmentNFT.sol";
import "./LibFund.sol";

contract StateMachine {
    bytes32 public currentState;
    mapping(bytes32 => mapping(bytes4 => bool)) internal functionsAllowed;

    /**
     * @dev Limits access for current state
     * @dev Only functions allowed using allowFunction are permitted
     */
    modifier onlyAllowedStates() {
        require(functionsAllowed[currentState][msg.sig], "Not allowed in current state");
        _;
    }

    constructor(bytes32 initialState) {
        currentState = initialState;
    }

    function allowFunction(bytes32 state, bytes4 selector) internal {
        functionsAllowed[state][selector] = true;
    }
}