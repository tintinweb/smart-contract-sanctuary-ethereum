// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

//*~~~> SPDX-License-Identifier: MIT OR Apache-2.0
/*~~~>
    Thank you Phunks, your inspiration and phriendship meant the world to me and helped me through hard times.
      Never stop phighting, never surrender, always stand up for what is right and make the best of all situations towards all people.
      Phunks are phreedom phighters!
        "When the power of love overcomes the love of power the world will know peace." - Jimi Hendrix <3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 <~~~*/
pragma solidity  >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface RoleProvider {
  function hasTheRole(bytes32 role, address _address) external returns(bool);
  function hasContractRole(address _address) external returns(bool);
  function fetchAddress(bytes32 _var) external returns(address);
}
interface MarketMint {
  function fetchNFTsCreatedCount() external returns(uint);
}
interface Collections {
  function canOfferToken(address token) external returns(bool);
}
contract RewardsControl is ReentrancyGuard, Pausable {
  using SafeMath for uint;
  using Counters for Counters.Counter;

  /*~~~> 
    token addresses for ERC20 deposits;
  <~~~*/
  address[] tokenAddresses;

  address roleAdd;

  //*~~~> amount of ETH to split between Users;
  uint public userEth;
  //*~~~> amount of ETH to split between Devs;
  uint public devEth;
  //*~~~> amount of ETH to split between DAO;
  uint public daoEth;

  //*~~~> Platform fee
  uint public fee;

  //*~~~> upgradable proxy contract addresses
  bytes32 public constant DAO = keccak256("DAO");

  bytes32 public constant NFTADD = keccak256("NFT");

  bytes32 public constant MINT = keccak256("MINT");

  bytes32 public constant COLLECTION = keccak256("COLLECTION");

  /*~~~> Open storage indexes <~~~*/
  uint[] private openStorage;

  Counters.Counter private _devs;
  Counters.Counter private _users;
  Counters.Counter private _nftHodlers;
  Counters.Counter private _tokens;

  mapping(uint256 => User) private idToUser; //Internal index => User
  mapping(uint256 => NftHodler) private idToHodler; //Internal index => Hodler
  mapping(uint256 => NftHodler) private nftIdToHodler; // Tracking NFT ids => Hodler placement, to limit claims
  mapping(address => User) private addressToUser;
  mapping(address => uint256) private addressToId; //For user Id
  mapping(address => uint256) private addressToTokenId; // For token Id
  mapping(uint256 => UserRewardToken) private idToUserToken;
  mapping(uint256 => DevRewardToken) private idToDevToken;
  mapping(uint256 => DaoRewardToken) private idToDaoToken;
  mapping(uint256 => DevTeam) private idToDevTeam;
  mapping(address => uint256) private addressToDevTeamId;
  mapping(uint256 => ClaimClock) private idToClock;
  
  //*~~~> set initial ERC20 to avoid accessing an out-of-bounds or negative index
  constructor(address _role, address _phunky) {
    roleAdd = _role;
    _tokens.increment();
    uint newTokenId = _tokens.current();
    addressToTokenId[_phunky] = newTokenId;
    fee = 200;
  }

  //*~~~> Declaring object structures for Split Rewards & Tokens <~~~*/
  struct User {
    bool canClaim;
    uint claims;
    uint timestamp;
    uint userId;
    address userAddress;
  }
  struct NftHodler {
    uint timestamp;
    uint hodlerId;
    uint tokenId;
  }
  struct DevTeam {
    uint timestamp;
    uint devId;
    address devAddress;
  }
  struct UserRewardToken {
    uint tokenId;
    uint tokenAmount;
    address tokenAddress;
  }
  struct DevRewardToken {
    uint tokenId;
    uint tokenAmount;
    address tokenAddress;
  }
  struct DaoRewardToken {
    uint tokenId;
    uint tokenAmount;
    address tokenAddress;
  }
  struct ClaimClock {
    uint alpha; // initial claim cutoff
    uint delta; // mid claim cutoff
    uint omega; // final claim cutoff
    uint howManyUsers; // total user count set with each distribution call
  }
  
  /*~~~>
    Roles for designated accessibility
  <~~~*/
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE"); 
  bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
  modifier hasAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(DEV_ROLE, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }
  modifier hasContractAdmin(){
    require(RoleProvider(roleAdd).hasContractRole(msg.sender), "DOES NOT HAVE CONTRACT ROLE");
    _;
  }

  // Admin only functions to set proxy addresses
  function setRoleAddress(address _role) public hasAdmin returns(bool){
    roleAdd = _role;
    return true;
  }

  //*~~~> Declaring event structures
  event NewUser(uint indexed userId, address indexed userAddress);
  event RewardsClaimed(address indexed userAddress);
  event NewDev(address indexed devAddress);
  event RemovedDev(address indexed devAddress);
  event DevClaimed(address indexed devAddress);
  event SetTime(uint indexed alpha, uint delta, uint omega, uint currentUserCount);
  event Received(address, uint);

  /// @notice
  /*~~~>
    For setting fees for the Bids, Offers, MarketMint and Marketplace contracts
    Base fee set at 2% (i.e. value * 200 / 10,000) 
    Future fees can be set by the controlling DAO 
  <~~~*/
  function setFee(uint _fee) public hasAdmin returns (bool) {
    fee = _fee;
    return true;
  }

  /// @notice
  /*~~~>
    for adding dev addresses to claimable array
  <~~~*/
  /// @dev
  /*~~~>
    devAddress: new dev;
  <~~~*/
  /// @return Bool
  function addDev(address devAddress) public nonReentrant hasDevAdmin returns(bool) {
    uint devLen = _devs.current();
    bool added;
    for (uint i; i<devLen;i++){
      DevTeam memory _dev = idToDevTeam[i+1];
      // recycle old indexes if available
      if(_dev.devAddress==address(0x0)){
        idToDevTeam[i+1] = DevTeam(block.timestamp, _dev.devId, devAddress);
        addressToDevTeamId[devAddress] = i+1;
        added = true;
      }
    }
    if(!added){
      _devs.increment();
      uint id = _devs.current();
      idToDevTeam[id] = DevTeam(block.timestamp, id, devAddress);
      addressToDevTeamId[devAddress] = id;
    }
    emit NewDev(devAddress);
    return true;
  }

  /// @notice
  /*~~~>
    for removing dev addresses from claimable array
  <~~~*/
  /// @dev
  /*~~~>
    devAddress: dev to be removed;
  <~~~*/
  /// @return removed Bool
  function removeDev(address devAddress) public hasDevAdmin nonReentrant returns(bool) {
    uint id = addressToDevTeamId[devAddress];
    DevTeam memory _dev = idToDevTeam[id];
    idToDevTeam[id] = DevTeam(0, _dev.devId, address(0x0));
    emit RemovedDev(devAddress);
    return true;
  }

  /// @notice
    /*~~~> 
      Creating new users for rewards
        <~~~*/
   /// @dev
    /*~~~>
     userAddress: user address;
        <~~~*/
    /// @return Bool
  function createUser(address userAddress) public hasContractAdmin nonReentrant returns(bool) {
    uint userId;
    uint len = openStorage.length;
    if (len>=1){
      userId=openStorage[len-1];
      _remove();
    } else {
      _users.increment();
      userId = _users.current();
    }
    addressToId[userAddress] = userId;
    User memory user = User(true, 0, block.timestamp, userId, userAddress);
    idToUser[userId] = user;
    addressToUser[userAddress] = user; 
    emit NewUser(userId, userAddress);
    return true;
  }

  /// @notice
    /*~~~> 
      Creating new NFT hodler placements for rewards
        <~~~*/
   /// @dev
    /*~~~>
     tokenId: NFT tokenId to track claims;
        <~~~*/
    /// @return Bool
  function createNftHodler(uint tokenId) public hasContractAdmin nonReentrant returns(bool) {
    address mrktNft = RoleProvider(roleAdd).fetchAddress(NFTADD);
    _nftHodlers.increment();
    uint hodlerId = _nftHodlers.current();
    NftHodler memory hodler = NftHodler(block.timestamp, hodlerId, tokenId);
    nftIdToHodler[tokenId] = hodler;
    idToHodler[hodlerId] = hodler; 
    emit NewUser(hodlerId, mrktNft);
    return true;
  }
  
  /// @notice
  //*~~~> Resetting the user data to revoke claim access after last item sells
  /// @dev
    /*~~~>
     userAddress: user address;
        <~~~*/
  /// @return Bool
  function setUser(bool canClaim, address userAddress) public hasContractAdmin nonReentrant returns(bool) {
    uint userId = addressToId[userAddress];
    User memory user = idToUser[userId];
    if (canClaim){
      idToUser[userId] = User(true, 0, user.timestamp, user.userId, userAddress);
    } else {
      // push old user Id for recycling
      openStorage.push(userId);
      // reset user address to Id mapping
      addressToId[userAddress] = 0;
      idToUser[userId] = User(false, 0, 0, user.userId,  address(0x0));
    }
    return true;
  }

  /*~~~> Public function anyone can call to split the accumulated user rewards
    When called, the current timestamp is saved as alpha time.
    Old aplha time becomes delta,
      old delta time becomes omega.
    Total user count is saved.
    Can only be called every 2 days.
  <~~~*/
  function setClaimClock() public nonReentrant {
    address mintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    uint users = fetchUserAmnt();
    uint nfts = MarketMint(mintAdd).fetchNFTsCreatedCount();
    ClaimClock memory clock = idToClock[8];
    require(clock.alpha < (block.timestamp - 2 days));
    uint alpha = block.timestamp;
    uint delta = clock.alpha;
    uint omega = clock.delta;
    uint totalUsers = users.add(nfts);
    idToClock[8] = ClaimClock(alpha, delta, omega, totalUsers);
    emit SetTime(alpha, delta, omega, totalUsers);
  }

  //*~~~> Claims all eligible rewards for user
  function claimRewards() public nonReentrant {
    uint id = addressToId[msg.sender];
    User memory user = idToUser[id];
    ClaimClock memory clock = idToClock[8];
    require(user.canClaim==true,"Ineligible!");
    /*~~~> Distribute according to timestamp cutoff
      if user.timestamp:
          > clock.alpha = no claims;
          < clock.alpha > clock.delta && claims == 0 = full claim, else no claim;
          < clock.delta > clock.omega && claims <= 1 = 1/2 claim, else no claim;
          < clock.omega && claims <= 2 = 1/3 claim, else no claim;
          claims == 3 no claims;
    <~~~*/
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  :
      ///*~~~> user.timestamp == 99, is less than alpha, greater than omega, 0 claims, gets rewards
    if (user.timestamp < clock.alpha && user.timestamp > clock.delta){
      if (user.claims==0){
        uint userSplits = userEth.div(clock.howManyUsers);
        payable(msg.sender).transfer(userSplits);
        userEth = userEth.sub(userSplits);
        /// update new amount
        uint tokenLen = _tokens.current();
      for (uint i; i < tokenLen; i++) {
        UserRewardToken memory toke = idToUserToken[i+1];
        if(toke.tokenAmount > 0){
          uint ercSplit = (toke.tokenAmount.div(clock.howManyUsers)).div(3);
          IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit);
          /// update new amount
          toke.tokenAmount = toke.tokenAmount.sub(ercSplit);
        }
      }
        user.claims+=1;
      }
    }
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  :
      ///*~~~> user.timestamp == 97, is less than delta, greater than omega, 1 or less claims, gets 1/2 full rewards
    if (user.timestamp < clock.delta && user.timestamp > clock.omega){
      if(user.claims <= 1){
        uint userSplits = userEth.div(clock.howManyUsers);
        payable(msg.sender).transfer(userSplits.div(2));
        /// update new amount
        userEth = userEth.sub(userSplits);
        uint tokenLen = _tokens.current();
      for (uint i; i < tokenLen; i++) {
        UserRewardToken memory toke = idToUserToken[i+1];
        if(toke.tokenAmount > 0){
          uint ercSplit = (toke.tokenAmount.div(clock.howManyUsers)).div(3);
          IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit);
          /// update new amount
          toke.tokenAmount = toke.tokenAmount.sub(ercSplit);
        }
      }
        user.claims+=1;
      }
    }
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  :
      ///*~~~> user.timestamp == 95, is less than omega, 2 or less claims, gets 1/3 full reward
    if (user.timestamp < clock.omega && user.claims <= 2){
      uint userSplits = userEth.div(clock.howManyUsers);
      payable(msg.sender).transfer(userSplits.div(3));
      /// update new amount
      userEth = userEth.sub(userSplits);
      uint tokenLen = _tokens.current();
      for (uint i; i < tokenLen; i++) {
        UserRewardToken memory toke = idToUserToken[i+1];
        if(toke.tokenAmount > 0){
          uint ercSplit = (toke.tokenAmount.div(clock.howManyUsers)).div(3);
          IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit);
          /// update new amount
          toke.tokenAmount = toke.tokenAmount.sub(ercSplit);
        }
      }
      user.claims+=1;
    }
  }

  //*~~~> Claims eligible rewards for NFT holders <~~~*//
  function claimNFTRewards(uint nftId) public nonReentrant {
    ClaimClock memory clock = idToClock[8];
    
    address mrktNft = RoleProvider(roleAdd).fetchAddress(NFTADD);

    ///*~~~> require msg.sender to be a platform NFT holder
    require(IERC721(mrktNft).balanceOf(msg.sender) > 0, "Ineligible!");

    NftHodler memory hodler = nftIdToHodler[nftId];
    ///*~~~> Limiting claim abilities to once a day
    require(hodler.timestamp < (block.timestamp - 1 days));

    uint splits = userEth.div(clock.howManyUsers);
    payable(msg.sender).transfer(splits);
    /// update new amount
    userEth = userEth.sub(splits);
    
    uint len = _tokens.current();
    for (uint i; i < len; i++) {
      UserRewardToken memory toke = idToUserToken[i+1];
      if(toke.tokenAmount > 0){
        uint ercSplit = (toke.tokenAmount.div(clock.howManyUsers));
        /// transfer token amount divided by total user amount 
        IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit);
         /// update new amount
        toke.tokenAmount = toke.tokenAmount.sub(ercSplit);
      }
    }
    emit RewardsClaimed(msg.sender);
  }

  /*~~~>
    Allows Dev addresses to withdraw
    Only an address that exists in the dev array will receive anything.
  <~~~*/
  function claimDevRewards() public nonReentrant {
    uint devId = addressToDevTeamId[msg.sender];
    DevTeam memory dev = idToDevTeam[devId];
    /// ensuring msg.sender is a dev address
    require(dev.devAddress == msg.sender);

    ///*~~~> Limiting claim abilities to once a day
    require(dev.timestamp  < (block.timestamp - 1 days), "Ineligible!");
    
    uint devSplit = devEth.div(_devs.current());
    /// transfer devEth divided by total dev amount
    payable(dev.devAddress).transfer(devSplit);
    /// update new amount
    devEth = devEth.sub(devSplit);
    uint len = _tokens.current();
    for (uint i; i < len; i++) {
      DevRewardToken memory token = idToDevToken[i+1];
      if(token.tokenAmount > 0){
        uint ercSplit = (token.tokenAmount.div(_devs.current()));
        /// transfer token amount divided by total dev amount 
        IERC20(token.tokenAddress).transfer(payable(dev.devAddress), ercSplit);
        token.tokenAmount = token.tokenAmount.sub(ercSplit);
        idToDevTeam[devId] = DevTeam(block.timestamp, devId, dev.devAddress);
      }
    }
    emit DevClaimed(msg.sender);
  }

  function splitRewards(uint _split) public payable returns(bool) {
    require(msg.value == _split);
    // divide fee between Users, Devs and DAO
    // split fee in 3 parts, 2/3 to users, 1/3 to dao
    uint partySplit = _split.div(3);
    // userSplit is 2/3 of fee
    uint userSplit = _split.sub(partySplit);
    // split dao in 4 parts, 
    // 3/4 to dao, 1/4 to devs
    uint devSplit = partySplit.div(4);
    uint daoSplit = partySplit.sub(devSplit);

    userEth = userEth.add(userSplit);
    daoEth = daoEth.add(daoSplit);
    devEth = devEth.add(devSplit);
    return true;
  }


  /// @notice
  /*~~~>
    Splits rewarded ERC20 tokens to all users
  <~~~*/
  /// @dev
  /*~~~>
    amount: how much ERC20 to be deposited
    tokenAddress: contract address of the ERC20
  <~~~*/
  /// @return Bool
  function depositERC20Rewards(uint amount, address tokenAddress) public returns(bool){
    require(Collections(RoleProvider(roleAdd).fetchAddress(COLLECTION)).canOfferToken(tokenAddress)==true);
    
    // split fee in 3 parts, 2/3 to users, 1/3 to dao
    uint partySplit = amount.div(3);
    // userSplit is 2/3 of fee
    uint userSplit = amount.sub(partySplit);
    // split dao in 4 parts, 
    // 3/4 to dao, 
    uint devSplit = partySplit.div(4);
    // 1/4 to devs
    uint daoSplit = partySplit.sub(devSplit);
    uint tokenId = addressToTokenId[tokenAddress];
    //*~~~> Check to see if the token address exists already
    if(tokenId>0) {
      // add received funds to total user token amount
      UserRewardToken memory userToken = idToUserToken[tokenId];
      uint newAmnt = userToken.tokenAmount.add(userSplit);
      idToUserToken[tokenId] = UserRewardToken(tokenId, newAmnt, tokenAddress);
      // add received funds to devTokenAmount
      DevRewardToken memory devToken = idToDevToken[tokenId];
      uint newDevAmnt = devToken.tokenAmount.add(devSplit);
      idToDevToken[tokenId] = DevRewardToken(tokenId, newDevAmnt, tokenAddress);
      // add received funds to daoTokenAmount
      DaoRewardToken memory daoToken = idToDaoToken[tokenId];
      uint newDaoAmnt = daoToken.tokenAmount.add(daoSplit);
      idToDaoToken[tokenId] = DaoRewardToken(tokenId, newDaoAmnt, tokenAddress);
    } else { //*~~~> else create a new ID for it
      _tokens.increment();
      uint newTokenId = _tokens.current();
      addressToTokenId[tokenAddress] = newTokenId;
      tokenAddresses[newTokenId] = tokenAddress;
      // add received funds to total user token amount
      UserRewardToken memory userToken = idToUserToken[newTokenId];
      uint newAmnt = userToken.tokenAmount.add(userSplit);
      idToUserToken[newTokenId] = UserRewardToken(newTokenId, newAmnt, tokenAddress);
      // add received funds to devTokenAmount
      DevRewardToken memory devToken = idToDevToken[newTokenId];
      uint newDevAmnt = devToken.tokenAmount.add(devSplit);
      idToDevToken[newTokenId] = DevRewardToken(newTokenId, newDevAmnt, tokenAddress);
      // add received funds to daoTokenAmount
      DaoRewardToken memory daoToken = idToDaoToken[newTokenId];
      uint newDaoAmnt = daoToken.tokenAmount.add(daoSplit);
      idToDaoToken[newTokenId] = DaoRewardToken(newTokenId, newDaoAmnt, tokenAddress);
    }
    emit Received(tokenAddress, amount); 
    return true;  
  }

  /// @notice
  /*~~~> 
    Functions for claiming Dao rewards
  <~~~*/
  /// @dev
  /*~~~>
    Withdraws Eth deposited, 
      then checks against the Rewards deposited for withdraw,
      then checks against Redemptions for withdraw;
    Resets claimAmounts back to 0;
  <~~~*/
  function claimDaoRewards() public nonReentrant {
    address daoAdd = RoleProvider(roleAdd).fetchAddress(DAO);
    require(msg.sender == daoAdd);
    payable(daoAdd).transfer(daoEth);
    daoEth = daoEth.sub(daoEth);
    /// update new amount
    uint count = _tokens.current();
    for (uint i; i < count; i++) {
      DaoRewardToken memory token = idToDaoToken[i+1];
      if (token.tokenAmount > 0) {
        IERC20(token.tokenAddress).transfer(daoAdd, token.tokenAmount);
         /// update new amount inline
        idToDaoToken[token.tokenId] = DaoRewardToken(token.tokenId, 0, token.tokenAddress);
      }
    }
  }

    /// @notice 
  /*~~~> 
    Internal function for removing elements from an array
    Only used for internal storage array index recycling

      In order to reduce storage array size of listed items 
        while maintaining specific enumerable id's, 
        any sold or removed item spots are recycled by referring to their index,
        else a new storage spot is created;

        We use the last item in the storage (length of array - 1 for 0 based index position),
        in order to pop off the item and avoid rewriting 
  <~~~*/
  function _remove() internal {
      openStorage.pop();
    }

  //*~~~> Fee for contract use
    function getFee() public view returns(uint){
    return fee;
  }  

  //*~~~> Read functions for fetching amounts and data
  function fetchUsers() public view returns (User[] memory user){
    uint howMany = _users.current();
    User[] memory users = new User[](howMany);
    for (uint i; i < howMany; i++) {
      if (idToUser[i+1].canClaim) {
        User storage currentUser = idToUser[i+1];
        users[i] = currentUser;
      }
    }
    return users;
  }

  function fetchHodler(uint tokenId) public view returns (NftHodler memory){
    NftHodler memory hodler = nftIdToHodler[tokenId];
    return hodler;
  }

  function fetchDevs() public view returns (DevTeam[] memory dev){
    uint howMany = _devs.current();
    DevTeam[] memory devs = new DevTeam[](howMany);
    for (uint i; i < howMany; i++) {
      if (idToDevTeam[i+1].devAddress != address(0x0)) {
        DevTeam storage currentDev = idToDevTeam[i+1];
        devs[i] = currentDev;
      }
    }
    return devs;
  }

  function fetchUserAmnt() public view returns (uint amount) {
    uint count = _users.current();
    for (uint i; i < count; i++) {
      if (idToUser[i+1].canClaim == true) {
        amount++;
      }
    }
    return amount;
  }

  function fetchUserRewardTokens() public view returns (UserRewardToken[] memory token){
    uint count = _tokens.current();
    UserRewardToken[] memory tokens = new UserRewardToken[](count);
    for (uint i; i < count; i++) {
      tokens[i] = idToUserToken[i+1];
    }
    return tokens;
  }
  function fetchDevRewardTokens() public view returns (DevRewardToken[] memory token){
    uint count = _tokens.current();
    DevRewardToken[] memory tokens = new DevRewardToken[](count);
    for (uint i; i < count; i++) {
      tokens[i] = idToDevToken[i+1];
    }
    return tokens;
  }
  function fetchDaoRewardTokens() public view returns (DaoRewardToken[] memory token){
    uint count = _tokens.current();
    DaoRewardToken[] memory tokens = new DaoRewardToken[](count);
    for (uint i; i < count; i++) {
      tokens[i] = idToDaoToken[i+1];
    }
    return tokens;
  }

  function fetchUserByAddress(address userAdd) public view returns (User memory user){
    user = addressToUser[userAdd]; 
    return user;
  }

  function fetchClaimTime() public view returns (ClaimClock memory time){
    return idToClock[8];
  }

  //*~~~> Fallback functions
  function transferNft(address receiver, address nftContract, uint tokenId) public hasAdmin {
    IERC721(nftContract).safeTransferFrom(address(this), receiver, tokenId);
  }

  function transfer1155(address receiver, address nftContract, uint tokenId, uint amount) public hasAdmin {
    IERC1155(nftContract).safeTransferFrom(address(this), receiver, tokenId, amount, "");
  }

  ///@notice DEV operations for emergency functions
  function pause() public hasDevAdmin {
      _pause();
  }
  function unpause() public hasDevAdmin {
      _unpause();
  }

  ///@notice
  /*~~~> External ETH transfer forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address _from, address _to);
  receive() external payable {
    payable(roleAdd).transfer(msg.value);
      emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }

  function onERC721Received(
      address, 
      address, 
      uint256, 
      bytes calldata
    )external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}