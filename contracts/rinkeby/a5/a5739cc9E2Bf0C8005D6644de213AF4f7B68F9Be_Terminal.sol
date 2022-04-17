// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ITerminal.sol";

contract Terminal is ITerminal, Initializable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    address public override superAdmin;

    //  rate to locked in treasury, defualt to 50%
    uint256 public override lockRate; // 1 => 1%

    uint256 public override tapFee; // 1 => 1%

    uint256 public override contributeFee; // 1 => 0.1%

    // the amount of ETH that each project is responsible for.
    mapping(uint256 => uint256) public override balanceOf;

    address public override devTreasury;

    IProjects public override projects;

    IFundingCycles public override fundingCycles;

    IMembershipPassBooth public override membershipPassBooth;

    IDAOGovernorBooster public override daoGovernorBooster;

    ITerminalDirectory public override terminalDirectory;

    /**
     * @notice  Due to a requirement of the proxy-based upgradeability system, no constructors can be used in upgradeable contracts.
     * @param _projects A DAO's contract which mints ERC721 represent project's ownership and transfers.
     * @param _fundingCycles A funding cycle configuration store. (DAO Creator can launch mutiple times.)
     * @param _passBooth The tiers with the Membership-pass this DAO has
     * @param _governorBooster The governor booster
     * @param _devTreasury dev treasury address, receive contribute fee and tap fee
     * @param _admin super admin
     */
    function initialize(
        IProjects _projects,
        IFundingCycles _fundingCycles,
        IMembershipPassBooth _passBooth,
        IDAOGovernorBooster _governorBooster,
        ITerminalDirectory _terminalDirectory,
        address _devTreasury,
        address _admin
    ) public initializer {
        if (
            _projects == IProjects(address(0)) ||
            _fundingCycles == IFundingCycles(address(0)) ||
            _passBooth == IMembershipPassBooth(address(0)) ||
            _governorBooster == IDAOGovernorBooster(address(0)) ||
            _terminalDirectory == ITerminalDirectory(address(0)) ||
            _devTreasury == address(0) ||
            _admin == address(0)
        ) revert ZeroAddress();

        __ReentrancyGuard_init();
        projects = _projects;
        fundingCycles = _fundingCycles;
        membershipPassBooth = _passBooth;
        daoGovernorBooster = _governorBooster;
        terminalDirectory = _terminalDirectory;
        devTreasury = _devTreasury;
        superAdmin = _admin;
        contributeFee = 1;
        tapFee = 4;
        lockRate = 50;
    }

    /**
     * @notice Deploy a DAO, this will mint an ERC721 into the `_owner`'s account, and configure a first funding cycle.
     * @param _owner The address who will own the DAO.
     * @param _handle The unique handle name for the DAO
     * @param _projectURI optional metadata for the DAO
     * @param _contractURI contract level data, for intergrating the NFT to OpenSea
     * @param _membershipPassURI metadata for membershippass nft
     * @param _tiers The total tiers of the Membership-pas
     * @param _params funding cycle parameters
     * @param _auctionedPass auctioned pass information
     */
    function createDao(
        address _owner,
        bytes32 _handle,
        string memory _projectURI,
        string memory _contractURI,
        string memory _membershipPassURI,
        ImmutablePassTier[] calldata _tiers,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external override {
        _validateConfigProperties(_auctionedPass);

        uint256 _projectId = projects.create(_owner, _handle, _projectURI, this);

        uint256[] memory tierFee;
        uint256[] memory tierCapacity;

        for (uint256 i = 0; i < _tiers.length; i++) {
            tierFee[i] = _tiers[i].tierFee;
            tierCapacity[i] = _tiers[i].tierCapacity;
        }

        address membershipPass = membershipPassBooth.issue(
            _projectId,
            _membershipPassURI,
            _contractURI,
            tierFee,
            tierCapacity
        );

        // @param projects the IProjects
        daoGovernorBooster.createGovernor(_projectId, membershipPass, superAdmin);

        fundingCycles.configure(
            _projectId,
            _params.duration,
            _params.cycleLimit,
            _params.target,
            lockRate,
            _auctionedPass
        );
    }

    /**
     * @notice Create the new Funding Cycle for spesific project, need to check the reserve 
     amount pass in Treasury. And

     * @param _projectId The project id of the dao
     * @param _params The parameters for funding cycle.
     * @param _auctionedPass auctioned pass information
     */
    function createNewFundingCycle(
        uint256 _projectId,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external override {
        _validateConfigProperties(_auctionedPass);
        _validateAllZeroReserved(_auctionedPass);

        uint256 latestFundingCycleId = fundingCycles.latestIdFundingProject(_projectId);

        FundingCycleProperties memory property = fundingCycles.configure(
            _projectId,
            _params.duration,
            _params.cycleLimit,
            _params.target,
            lockRate,
            _auctionedPass
        );

        require(
            property.id == latestFundingCycleId,
            "Terminal::createNewFundingCycle: CURRENT FUNDING CYCLE STILL ACTIVE"
        );
    }

    /**
     * @notice Contribute ETH to a dao
     * @param _projectId The ID of the DAO being contribute to.
     * @param _beneficiary The address to print Tickets for.
     * @param _payData The payment informations
     * @param _memo The memo that will be attached in the published event after purchasing.
     */
    function contribute(
        uint256 _projectId,
        address _beneficiary,
        uint256[] memory _payData,
        string memory _memo
    ) external payable override {
        FundingCycleProperties memory _fundingCycle = fundingCycles.currentOf(_projectId);
        uint256 _fundingCycleId = _fundingCycle.id;
        if (_fundingCycleId == 0) revert FundingCycleNotExist();

        // Make sure its not paused.
        if (_fundingCycle.isPaused) revert FundingCyclePaused();

        uint256 amount;
        PayInfoWithWeight[] memory _payInfoWithWeights;
        for (uint256 i = 0; i < _payData.length; i++) {
            (, uint256 weight, uint256 salePrice, , , , ) = fundingCycles
                .fundingCycleIdAuctionedPass(_fundingCycleId, i);
            amount = amount.add(_payData[i].mul(salePrice));
            _payInfoWithWeights[i] = PayInfoWithWeight({amount: _payData[i], weight: weight});
        }
        // contribute fee amount
        uint256 feeAmount = amount.mul(contributeFee.div(100));
        if (msg.value < amount.add(feeAmount)) revert InsufficientBalance();

        // update tappable and locked balance
        fundingCycles.updateLocked(_projectId, _fundingCycleId, amount);

        // Transfer fee to the dev address
        AddressUpgradeable.sendValue(payable(devTreasury), feeAmount);

        // Add to the balance of the project.
        balanceOf[_projectId] += amount;

        membershipPassBooth.stake(_projectId, _fundingCycleId, _beneficiary, _payInfoWithWeights);

        emit Pay(_projectId, _fundingCycleId, _beneficiary, amount, _payData, _memo);
    }

    /**
     * @notice Community members can mint the  membership pass for free
               For those who has the specific NFT in wallet, enable to claim free pass.

     * @param _projectId The ID of the DAO being contribute to.
     * @param _fundingCycleId The funding cycle id
     * @param _beneficiary The address to get the airdrop.
     * @param _memo memo attached when purchase
     */
    function communityContribute(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _beneficiary,
        string memory _memo
    ) external override {
        if (_fundingCycleId == 0) revert FundingCycleNotExist();

        if (membershipPassBooth.airdropClaimedOf(_beneficiary, _fundingCycleId))
            revert AlreadyClaimed();

        uint256[] memory tierIds;
        uint256[] memory amounts;
        uint256 tierSize = membershipPassBooth.tierSizeOf(_projectId);
        for (uint256 i = 0; i < tierSize; i++) {
            (uint256 id, , , , uint256 communityAmount, address communityVoucher, ) = fundingCycles
                .fundingCycleIdAuctionedPass(_fundingCycleId, i);
            tierIds[i] = id;
            amounts[i] = 0;
            if (
                IERC721(communityVoucher).balanceOf(_beneficiary) > 0 &&
                communityAmount - membershipPassBooth.airdropClaimedAmountOf(_fundingCycleId, id) >
                0
            ) {
                amounts[i] = 1;
            }
        }

        if (tierIds.length == 0) revert NoCommunityTicketLeft();

        membershipPassBooth.airdropBatchMintTicket(
            _projectId,
            _fundingCycleId,
            _beneficiary,
            tierIds,
            amounts
        );

        emit Airdrop(_projectId, _fundingCycleId, _beneficiary, tierIds, amounts, _memo);
    }

    /**
     * @notice Claim menbershippass or refund overlow part

     * @param _from user address
     * @param _projectId the project id to claim
     * @param _fundingCycleId the funding cycle id to claim
     */
    function claimPassOrRefund(
        address _from,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external override nonReentrant {
        FundingCycleProperties memory _fundingCycle = fundingCycles.getFundingCycle(_projectId);
        if (_fundingCycleId == 0) revert FundingCycleNotExist();

        if (block.timestamp <= _fundingCycle.duration + _fundingCycle.start)
            revert BadClaimPeriod();
        if (membershipPassBooth.claimedOf(_from, _fundingCycleId)) revert AlreadyClaimed();

        uint256 _refundAmount = getRefundingAmount(_from, _projectId, _fundingCycleId);
        if (_refundAmount > 0) {
            balanceOf[_projectId] = balanceOf[_projectId] - _refundAmount;
            AddressUpgradeable.sendValue(payable(_from), _refundAmount);
        }
        uint256[] memory _offeringAmounts = getOfferingAmount(_from, _projectId, _fundingCycleId);
        membershipPassBooth.batchMintTicket(_projectId, _fundingCycleId, _from, _offeringAmounts);

        emit Claim(_projectId, _fundingCycleId, _from, _refundAmount, _offeringAmounts);
    }

    /**
     * @notice Tap into funds that have been contributed to a project's funding cycles
     * @dev Anyone can tap funds on a project's behalf
     * @param _projectId The ID of the project to which the funding cycle being tapped belongs.
     * @param _amount The amount being tapped
     */
    function tap(uint256 _projectId, uint256 _amount) external override nonReentrant {
        // get a reference to this project's current balance, including any earned yield.
        uint256 _balance = balanceOf[_projectId];
        if (_amount > _balance) revert InsufficientBalance();

        // register the funds as tapped. Get the ID of the funding cycle that was tapped.
        fundingCycles.tap(_projectId, _amount);

        // removed the tapped funds from the project's balance.
        balanceOf[_projectId] = _balance - _amount;

        uint256 _feeAmount = _amount.mul(tapFee).div(100);
        uint256 _tappableAmount = _amount.sub(_feeAmount);
        address payable _projectOwner = payable(projects.ownerOf(_projectId));
        AddressUpgradeable.sendValue(payable(devTreasury), _feeAmount);
        AddressUpgradeable.sendValue(_projectOwner, _tappableAmount);

        emit Tap(_projectId, _projectOwner, _feeAmount, _tappableAmount);
    }

    /**
     * @notice Unlock the locked balance in dao treasury
     * @dev Only daoGovernor contract
     * @param _projectId The Id of the project to unlock
     * @param _unlockAmount The amount being unlocked
     */
    function unLockTreasury(uint256 _projectId, uint256 _unlockAmount) external override {
        if (msg.sender != address(daoGovernorBooster)) revert OnlyGovernor();

        fundingCycles.unlock(_projectId, _unlockAmount);

        emit UnlockTreasury(_projectId, _unlockAmount);
    }

    /**
     * @notice Get offering tickets by funding cycle
     
     * @param _from user address
     * @param _projectId the project id of contribute dao
     * @param _fundingCycleId the funding cycle id
     * @return amounts The amount of Pass offering in this funding cycle.
     */
    function getOfferingAmount(
        address _from,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) public view returns (uint256[] memory amounts) {
        uint256[] memory _allocations = membershipPassBooth.getUserAllocation(
            _from,
            _projectId,
            _fundingCycleId
        );

        for (uint256 i = 0; i < _allocations.length; i++) {
            (, , , uint256 saleAmount, , , ) = fundingCycles.fundingCycleIdAuctionedPass(
                _fundingCycleId,
                i
            );
            amounts[i] = _allocations[i].mul(saleAmount).div(1e6);
        }
    }

    /**
     * @notice Estimate allocate tickets
     * @param _projectId project id
     * @param _fundingCycleId funding cycle id
     * @param _payData payment info
     */
    function getEstimatingAmount(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256[] memory _payData
    ) external view returns (uint256[] memory amounts) {
        uint256[] memory _weights;
        for (uint256 i = 0; i < _payData.length; i++) {
            (, uint256 weight, , , , , ) = fundingCycles.fundingCycleIdAuctionedPass(
                _fundingCycleId,
                i
            );
            _weights[i] = _payData[i] * weight;
        }
        uint256[] memory _allocations = membershipPassBooth.getEstimatingUserAllocation(
            _projectId,
            _fundingCycleId,
            _weights
        );
        for (uint256 i = 0; i < _allocations.length; i++) {
            (, , , uint256 saleAmount, , , ) = fundingCycles.fundingCycleIdAuctionedPass(
                _fundingCycleId,
                i
            );
            amounts[i] = _allocations[i].mul(saleAmount).div(1e6);
        }
    }

    /**
     * @notice Get offering tickets by funding cycle
     * @param _from user address
     * @param _projectId the project id of contribute dao
     * @param _fundingCycleId the funding cycle id
     */
    function getRefundingAmount(
        address _from,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) public view returns (uint256 amount) {
        uint256[] memory _offeringAmounts = getOfferingAmount(_from, _projectId, _fundingCycleId);
        for (uint256 i = 0; i < _offeringAmounts.length; i++) {
            (, , uint256 salePrice, , , , ) = fundingCycles.fundingCycleIdAuctionedPass(
                _fundingCycleId,
                i
            );
            (uint256 _amount, , ) = membershipPassBooth.depositedWeightBy(
                _from,
                _fundingCycleId,
                i
            );
            amount += _amount.sub(_offeringAmounts[i]).mul(salePrice);
        }
    }

    /**
     * @notice Calculate the unsold tickets by funding cycle id
     * @param _fundingCycleId the funding cycle id
     */
    function getUnSoldTickets(uint256 _fundingCycleId) public view returns (uint256) {}

    /**
      * @notice Validate the Config Setting For Passes For The Fundraising this time. 

      * @param _auctionedPasses The ID of the funding cycle
     */
    function _validateConfigProperties(AuctionedPass[] calldata _auctionedPasses) private view {
        AuctionedPass memory _lastAuction = _auctionedPasses[_auctionedPasses.length - 1];
        if (_lastAuction.weight != 1) revert("Last weight must be 1");

        for (uint256 i = 0; i < _auctionedPasses.length; i++) {
            if (i < _auctionedPasses.length - 1) {
                uint256 priceMultiplier = _auctionedPasses[i].salePrice.mod(_lastAuction.salePrice);
                uint256 weightMultiplier = _auctionedPasses[i].weight.mod(_lastAuction.weight);
                if (
                    priceMultiplier > 0 ||
                    weightMultiplier > 0 ||
                    priceMultiplier != weightMultiplier
                ) revert MultiplierNotMatch();
            }

            if (
                _auctionedPasses[i].communityVoucher != address(0) &&
                !IERC721(_auctionedPasses[i].communityVoucher).supportsInterface(0x80ac58cd)
            ) revert Voucher721(_auctionedPasses[i].communityVoucher);
        }
    }

    function _validateAllZeroReserved(AuctionedPass[] calldata _auctionedPasses) private pure {
        bool allZero = true;
        for (uint256 i = 0; i < _auctionedPasses.length; i++) {
            if (_auctionedPasses[i].reservedAmount != 0) {
                allZero = false;
            }
        }
        if (allZero) {
            revert AllReservedAmoungZero();
        }
    }

    function setPausedFundingCycleProject(uint256 _projectId, bool _paused)
        external
        returns (bool)
    {
        require(
            msg.sender != projects.ownerOf(_projectId) || msg.sender != superAdmin,
            "FundingCycle: UNAUTHORIZED"
        );
        return fundingCycles.setPauseFundingCycle(_projectId, _paused);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";

enum ProposalState {
    Pending,
    Active,
    Queued,
    Failed,
    Expired,
    Executed
}

struct Proposal {
    string uri;
    uint256 id;
    bytes32 hash;
    uint256 start;
    uint256 end;
    uint256 minVoters;
    uint256 minVotes;
    ProposalState state;
}

struct Vote {
    uint256 totalVoters;
    uint256 totalVotes;
}

struct NFTStake {
    uint256 tokenId;
    uint256 amount; // ERC721: 1
    uint256 timestamp;
}

interface IDAOGovernorBooster {
    /************************* EVENTS *************************/
    event CreateGovernor(uint256 indexed projectId, address membershipPass, address admin);

    event ProposalCreated(
        uint256 indexed projectId,
        address indexed from,
        uint256 proposalId,
        Proposal proposal
    );

    event ExecuteProposal(
        uint256 indexed projectId,
        address indexed from,
        uint256 proposalId,
        uint8 proposalResult
    );

    event StakeNFT(uint256 indexed projectId, address indexed from, NFTStake[] membershipPass);

    event UnStakeNFT(uint256 indexed projectId, address indexed from);

    /************************* ERRORS *************************/
    error InsufficientBalance();
    error UnknowProposal();
    error BadPeriod();
    error InvalidSignature();
    error TransactionNotMatch();
    error TransactionReverted();
    error NotProjectOwner();
    error UnAuthorized();
    error AlreadyStaked();

    /************************* VIEW FUNCTIONS *************************/
    function createGovernor(
        uint256 _projectId,
        address _membershipPass,
        address _admin
    ) external;

    function propose(
        uint256 _projectId,
        address _proposer,
        Proposal memory _properties,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata
    ) external payable returns (uint256);

    function execute(
        uint256 _projectId,
        uint256 _proposalId,
        uint8 _proposeResult,
        bytes memory _signatureBySigner,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data
    ) external returns (bytes memory);

    function stakeNFT(
        uint256 _projectId,
        address _from,
        NFTStake[] memory _membershipPass
    ) external returns (uint256);

    function unStakeNFT(uint256 _projectId, address _recepient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct AuctionedPass {
    // tier id, indexed from 0
    uint256 id;
    uint256 weight;
    uint256 salePrice;
    // the amount of tickets open for sale in this round
    uint256 saleAmount;
    // the amount of tickets airdroped to community
    uint256 communityAmount;
    // who own the community vouchers can free mint the community ticket
    address communityVoucher;
    // the amount of tickets reserved to next round
    uint256 reservedAmount;
}

// 1st funding cycle:
// gold ticket (erc1155) :  11 salePrice 1 reserveampiunt

// silver ticket: 10 salePrice  2 reserveampiunt

struct FundingCycleProperties {
    uint256 id;
    uint256 projectId;
    uint256 previousId;
    uint256 start;
    uint256 target;
    uint256 lockRate;
    uint256 deposited;
    uint256 tappable;
    uint256 locked;
    uint256 unLocked;
    bool reachMaxLock;
    uint256 duration;
    bool isPaused;
    uint256 cycleLimit;
}

struct FundingCycleParameter {
    uint256 duration;
    uint256 cycleLimit;
    uint256 target;
}

interface IFundingCycles {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event FundingCycleExist(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        address caller
    );

    event Init(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 previous,
        uint256 start
    );

    error InsufficientBalance();

    function latestIdFundingProject(uint256 _projectId) external view returns (uint256);

    function fundingCycleIdAuctionedPass(uint256 _projectId, uint256 _tierId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        );

    function count() external view returns (uint256);

    function MAX_CYCLE_LIMIT() external view returns (uint256);

    function getFundingCycle(uint256 _fundingCycleId)
        external
        view
        returns (FundingCycleProperties memory);

    function configure(
        uint256 _projectId,
        uint256 _duration,
        uint256 _cycleLimit,
        uint256 _target,
        uint256 _lockRate,
        AuctionedPass[] memory _auctionedPass
    ) external returns (FundingCycleProperties memory);

    function currentOf(uint256 _projectId) external view returns (FundingCycleProperties memory);

    function setPauseFundingCycle(uint256 _projectId, bool _paused) external returns (bool);

    function updateLocked(uint256 _projectId, uint256 _fundingCycleId, uint256 _amount) external;

    function tap(uint256 _projectId, uint256 _amount) external;

    function unlock(uint256 _projectId, uint256 _amount) external;

    function getTappableAmount(uint256 _projectId) external view returns (uint256);

    function getUnLockableAmount(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IMembershipPass is IERC1155, IERC2981 {
    /************************* EVENTS *************************/

    event MintPass(address indexed account, uint256 indexed tier, uint256 amount);

    event BatchMintPass(address indexed _account, uint256[] _tiers, uint256[] _amounts);

    /************************* VIEW FUNCTIONS *************************/

    function feeCollector() external view returns (address);

    /**
     * @notice
     * Contract-level metadata for OpenSea
     * see https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice
     * Implement ERC2981, but actually the most marketplaces have their own royalty logic
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount);

    /************************* STATE MODIFYING FUNCTIONS *************************/

    function mintPassForMember(
        address _account,
        uint256 _token,
        uint256 _amount
    ) external;

    function batchMintPassForMember(
        address _account,
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMembershipPass.sol";
import "./IRoyaltyDistributor.sol";

struct PayInfoWithWeight {
    uint256 amount;
    uint256 weight;
}
struct WeightInfo {
    uint256 amount;
    uint256 baseWeight;
    uint256 sqrtWeight;
}

interface IMembershipPassBooth {
    /************************* EVENTS *************************/
    event Issue(
        uint256 indexed projectId,
        string uri,
        address membershipPass,
        uint256[] tierFee,
        uint256[] tierCapacity
    );

    event BatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    event AirdropBatchMintTicket(
        address indexed from,
        uint256 indexed projectId,
        uint256[] tiers,
        uint256[] amounts
    );

    /************************* VIEW FUNCTIONS *************************/
    function tierSizeOf(uint256 _projectId) external view returns (uint256);

    function membershipPassOf(uint256 _projectId) external view returns (IMembershipPass);

    function royaltyDistributorOf(uint256 _projectId) external view returns (IRoyaltyDistributor);

    function totalSqrtWeightBy(uint256 _fundingCycleId, uint256 _tierId) external returns (uint256);

    function depositedWeightBy(
        address _from,
        uint256 _fundingCycleId,
        uint256 _tierId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedOf(address _from, uint256 _fundingCycleId) external returns (bool);

    function airdropClaimedAmountOf(uint256 _fundingCycleId, uint256 _tierId)
        external
        returns (uint256);

    function issue(
        uint256 _projectId,
        string memory _uri,
        string memory _contractURI,
        uint256[] memory _tierFee,
        uint256[] memory _tierCapacity
    ) external returns (address);

    function stake(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        PayInfoWithWeight[] memory _payInfo
    ) external;

    function batchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _amounts
    ) external;

    function airdropBatchMintTicket(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _from,
        uint256[] memory _tierIds,
        uint256[] memory _amounts
    ) external;

    function getUserAllocation(
        address _user,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external view returns (uint256[] memory);

    function getEstimatingUserAllocation(
        uint256 _projectId,
        uint256 _fundingCycleId,
        uint256[] memory _weights
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";

interface IProjects is IERC721 {
    error EmptyHandle();
    error TakenedHandle();

    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        address caller
    );

    event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

    event SetUri(uint256 indexed projectId, string uri, address caller);

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyDistributor {
	/**
	 * @notice
	 * Claim according to votes share
	 */
	function claimRoyalties() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IProjects.sol";
import "./IFundingCycles.sol";
import "./ITerminalDirectory.sol";
import "./IDAOGovernorBooster.sol";
import "./IMembershipPassBooth.sol";

struct ImmutablePassTier {
    uint256 id;
    uint256 tierFee;
    uint256 multiplier;
    uint256 tierCapacity;
}

interface ITerminal {
    event Pay(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 amount,
        uint256[] payData,
        string note
    );

    event Airdrop(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256[] tierIds,
        uint256[] amounts,
        string note
    );

    event Claim(
        uint256 indexed projectId,
        uint256 indexed fundingCycleId,
        address indexed beneficiary,
        uint256 refundAmount,
        uint256[] offeringAmounts
    );

    event Tap(
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 govFeeAmount,
        uint256 netTransferAmount
    );

    event UnlockTreasury(uint256 indexed projectId, uint256 unlockAmount);

    error MultiplierNotMatch();
    error Voucher721(address _voucher);
    error NoCommunityTicketLeft();
    error AllReservedAmoungZero();
    error FundingCycleNotExist();
    error FundingCyclePaused();
    error InsufficientBalance();
    error AlreadyClaimed();
    error ZeroAddress();
    error BadClaimPeriod();
    error OnlyGovernor();

    function superAdmin() external view returns (address);

    function lockRate() external view returns (uint256);

    function tapFee() external view returns (uint256);

    function contributeFee() external view returns (uint256);

    function devTreasury() external view returns (address);

    function projects() external view returns (IProjects);

    function fundingCycles() external view returns (IFundingCycles);

    function membershipPassBooth() external view returns (IMembershipPassBooth);

    function daoGovernorBooster() external view returns (IDAOGovernorBooster);

    function terminalDirectory() external view returns (ITerminalDirectory);

    function balanceOf(uint256 _projectId) external view returns (uint256);

    function createDao(
        address _owner,
        bytes32 _handle,
        string memory _projectURI,
        string memory _contractURI,
        string memory _membershipPassURI,
        ImmutablePassTier[] memory _tiers,
        FundingCycleParameter memory _params,
        AuctionedPass[] memory _auctionedPass
    ) external;

    function createNewFundingCycle(
        uint256 projectId,
        FundingCycleParameter calldata _params,
        AuctionedPass[] calldata _auctionedPass
    ) external;

    /**
     * @notice
     * Contribute to a project
     */
    function contribute(
        uint256 _projectId,
        address _beneficiary,
        uint256[] memory _payData,
        string memory _memo
    ) external payable;

    /**
     * @notice
     * Community members can mint the  membership pass for free
     */
    function communityContribute(
        uint256 _projectId,
        uint256 _fundingCycleId,
        address _beneficiary,
        string memory _memo
    ) external;

    /**
     * @notice
     * Claim menbershippass or refund overlow part
     */
    function claimPassOrRefund(
        address _from,
        uint256 _projectId,
        uint256 _fundingCycleId
    ) external;

    /**
     * @notice
     * Tap into funds that have been contributed to a project's funding cycles
     */
    function tap(uint256 _projectId, uint256 _amount) external;

    /**
     * @notice Unlock the locked balance in dao treasury
     */
    function unLockTreasury(uint256 _projectId, uint256 _unlockAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITerminal.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;
}