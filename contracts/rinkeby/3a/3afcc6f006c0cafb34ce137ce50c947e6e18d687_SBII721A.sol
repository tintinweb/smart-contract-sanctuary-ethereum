/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/flat.sol

pragma solidity ^0.8.0;

interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)




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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File contracts/ERC721ASBUpgradable.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐


// ERC721A Creator: Chiru Labs
// GJ mate. interesting design :)








error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error AllOwnershipsHaveBeenSet();
error QuantityMustBeNonZero();
error NoTokensMintedYet();
error InvalidQueryRange();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 *
 * Speedboat team modified version of ERC721A - upgradable
 */
contract ERC721ASBUpgradable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public nextOwnerToExplicitlySet;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     * SB: change to public. anyone are free to pay the gas lol :P
     */
    function setOwnersExplicit(uint256 quantity) public {
        if (quantity == 0) revert QuantityMustBeNonZero();
        if (_currentIndex == _startTokenId()) revert NoTokensMintedYet();
        uint256 _nextOwnerToExplicitlySet = nextOwnerToExplicitlySet;
        if (_nextOwnerToExplicitlySet == 0) {
            _nextOwnerToExplicitlySet = _startTokenId();
        }
        if (_nextOwnerToExplicitlySet >= _currentIndex)
            revert AllOwnershipsHaveBeenSet();

        // Index underflow is impossible.
        // Counter or index overflow is incredibly unrealistic.
        unchecked {
            uint256 endIndex = _nextOwnerToExplicitlySet + quantity - 1;

            // Set the end index to be the last token index
            if (endIndex + 1 > _currentIndex) {
                endIndex = _currentIndex - 1;
            }

            for (uint256 i = _nextOwnerToExplicitlySet; i <= endIndex; i++) {
                if (
                    _ownerships[i].addr == address(0) && !_ownerships[i].burned
                ) {
                    TokenOwnership memory ownership = _ownershipOf(i);
                    _ownerships[i].addr = ownership.addr;
                    _ownerships[i].startTimestamp = ownership.startTimestamp;
                }
            }

            nextOwnerToExplicitlySet = endIndex + 1;
        }
    }

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId)
        public
        view
        returns (TokenOwnership memory)
    {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds)
        external
        view
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](
                tokenIdsLength
            );
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (
                uint256 i = start;
                i != stop && tokenIdsIdx != tokenIdsMaxLength;
                ++i
            ) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function __ERC721A_init(string memory name_, string memory symbol_)
        public
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1; // SB: change to start from 1 - modified from original 0. since others SB's code reserve 0 for a random stuff
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() &&
            !_checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)



/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)






/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/lighthouse.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐



contract Lighthouse is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER");
    string public constant MODEL = "SBII-Lighthouse-test";

    event newContract(address ad, string name, string contractType);
    mapping(string => mapping(string => address)) public projectAddress;
    mapping(string => address) public nameOwner;
    mapping(address => string[]) private registeredProject;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function listRegistered(address wallet)
        public
        view
        returns (string[] memory)
    {
        return registeredProject[wallet];
    }

    function registerContract(
        string memory name,
        address target,
        string memory contractType,
        address requester
    ) public onlyRole(DEPLOYER_ROLE) {
        if (nameOwner[name] == address(0)) {
            nameOwner[name] = requester;
            registeredProject[requester].push(name);
        } else {
            require(nameOwner[name] == requester, "taken");
        }
        require(projectAddress[name][contractType] == address(0), "taken");
        projectAddress[name][contractType] = target;
        emit newContract(target, name, contractType);
    }

    function giveUpContract(string memory name, string memory contractType)
        public
    {
        require(nameOwner[name] == msg.sender, "not your name");
        projectAddress[name][contractType] = address(0);
    }

    function giveUpName(string memory name) public {
        require(nameOwner[name] == msg.sender, "not your name");
        nameOwner[name] = address(0);
    }

    function yeetContract(string memory name, string memory contractType)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        projectAddress[name][contractType] = address(0);
    }

    function yeetName(string memory name) public onlyRole(DEFAULT_ADMIN_ROLE) {
        nameOwner[name] = address(0);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


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


// File contracts/paymentUtil.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐




library paymentUtil {
    using SafeERC20 for IERC20;

    function processPayment(address token, uint256 amount) public {
        if (token == address(0)) {
            require(msg.value >= amount, "invalid payment");
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }
}


// File contracts/quartermaster.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐



contract Quartermaster is AccessControl {
    bytes32 public constant QUATERMASTER_ROLE = keccak256("QUATERMASTER");
    string public constant MODEL = "SBII-Quartermaster-test";

    struct Fees {
        uint128 onetime;
        uint128 bip;
        address token;
    }
    event updateFees(uint128 onetime, uint128 bip, address token);
    mapping(bytes32 => Fees) serviceFees;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(QUATERMASTER_ROLE, msg.sender);
    }

    function setFees(
        string memory key,
        uint128 _onetime,
        uint128 _bip,
        address _token
    ) public onlyRole(QUATERMASTER_ROLE) {
        serviceFees[keccak256(abi.encode(key))] = Fees({
            onetime: _onetime,
            bip: _bip,
            token: _token
        });
        emit updateFees(_onetime, _bip, _token);
    }

    function getFees(string memory key) public view returns (Fees memory) {
        return serviceFees[keccak256(abi.encode(key))];
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)










/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)





/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)



/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)



/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)







/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]


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
library EnumerableSetUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)






/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n Γö£Γòû 2 + 1, and for v in (302): v ╬ô├¬├¬ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)



/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)




/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)


/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/ISBMintable.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐


interface ISBMintable {
    function mintNext(address reciever, uint256 amount) external;

    function mintTarget(address reciever, uint256 target) external;
}


// File contracts/ISBRandomness.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐


interface ISBRandomness {
    function getRand(bytes32 seed) external returns (bytes32);
}


// File contracts/ISBShipable.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐


interface ISBShipable {
    function initialize(
        bytes calldata initArg,
        uint128 bip,
        address feeReceiver
    ) external;
}


// File contracts/SBII721.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐












// @dev speedboat v2 erc721 = SBII721
contract SBII721 is
    Initializable,
    ContextUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    ISBMintable,
    ISBShipable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using StringsUpgradeable for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public constant MODEL = "SBII-721-test";
    uint256 private lastID;

    struct Round {
        uint128 price;
        uint32 quota;
        uint16 amountPerUser;
        bool isActive;
        bool isPublic;
        bool isMerkleMode; // merkleMode will override price, amountPerUser, and TokenID if specify
        bool exist;
        address tokenAddress; // 0 for base asset
    }

    struct Conf {
        bool allowNFTUpdate;
        bool allowConfUpdate;
        bool allowContract;
        bool allowPrivilege;
        bool randomAccessMode;
        bool allowTarget;
        bool allowLazySell;
        uint64 maxSupply;
    }

    Conf public config;
    string[] roundNames;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private walletList;
    mapping(bytes32 => bytes32) private merkleRoot;
    mapping(bytes32 => Round) private roundData;
    mapping(uint256 => bool) private nonceUsed;

    mapping(bytes32 => mapping(address => uint256)) mintedInRound;

    string private _baseTokenURI;
    address private feeReceiver;
    uint256 private bip;
    address public beneficiary;

    ISBRandomness public randomness;

    function listRole()
        external
        pure
        returns (string[] memory names, bytes32[] memory code)
    {
        names = new string[](2);
        code = new bytes32[](2);

        names[0] = "MINTER";
        names[1] = "ADMIN";

        code[0] = MINTER_ROLE;
        code[1] = DEFAULT_ADMIN_ROLE;
    }

    function grantRoles(bytes32 role, address[] calldata accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            super.grantRole(role, accounts[i]);
        }
    }

    function revokeRoles(bytes32 role, address[] calldata accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            super.revokeRole(role, accounts[i]);
        }
    }

    function setBeneficiary(address _beneficiary)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(beneficiary == address(0), "already set");
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        beneficiary = _beneficiary;
    }

    function setMaxSupply(uint64 _maxSupply)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(config.maxSupply == 0, "already set");
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        config.maxSupply = _maxSupply;
    }

    function listRoleWallet(bytes32 role)
        public
        view
        returns (address[] memory roleMembers)
    {
        uint256 count = getRoleMemberCount(role);
        roleMembers = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            roleMembers[i] = getRoleMember(role, i);
        }
    }

    function listToken(address wallet)
        public
        view
        returns (uint256[] memory tokenList)
    {
        tokenList = new uint256[](balanceOf(wallet));
        for (uint256 i = 0; i < balanceOf(wallet); i++) {
            tokenList[i] = tokenOfOwnerByIndex(wallet, i);
        }
    }

    function listRounds() public view returns (string[] memory) {
        return roundNames;
    }

    function roundInfo(string memory roundName)
        public
        view
        returns (Round memory)
    {
        return roundData[keccak256(abi.encodePacked(roundName))];
    }

    function massMint(address[] calldata wallets, uint256[] calldata amount)
        public
    {
        require(config.allowPrivilege, "df");
        require(hasRole(MINTER_ROLE, msg.sender), "require permission");
        for (uint256 i = 0; i < wallets.length; i++) {
            _mintNext(wallets[i], amount[i]);
        }
    }

    function mintNext(address reciever, uint256 amount) public override {
        require(config.allowPrivilege, "df");
        require(hasRole(MINTER_ROLE, msg.sender), "require permission");
        _mintNext(reciever, amount);
    }

    function _mintNext(address reciever, uint256 amount) internal {
        if (config.maxSupply != 0) {
            require(totalSupply() + amount <= config.maxSupply);
        }
        if (!config.randomAccessMode) {
            for (uint256 i = 0; i < amount; i++) {
                _mint(reciever, lastID + 1 +i);
            }
            lastID += amount;

        } else {
            for (uint256 i = 0; i < amount; i++) {
                _mint(reciever, _random(msg.sender, i));
            }
        }
    }

    function _random(address ad, uint256 num) internal returns (uint256) {
        return
            uint256(randomness.getRand(keccak256(abi.encodePacked(ad, num))));
    }

    function updateURI(string memory newURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowNFTUpdate, "not available");
        _baseTokenURI = newURI;
    }

    function mintTarget(address reciever, uint256 target) public override {
        require(config.allowPrivilege, "df");
        require(hasRole(MINTER_ROLE, msg.sender), "require permission");
        _mintTarget(reciever, target);
    }

    function _mintTarget(address reciever, uint256 target) internal {
        require(config.allowTarget, "df");
        require(config.randomAccessMode, "df");
        if (config.maxSupply != 0) {
            require(totalSupply() + 1 <= config.maxSupply);
        }
        _mint(reciever, target);
    }

    function requestMint(Round storage thisRound, uint256 amount) internal {
        require(thisRound.isActive, "not active");
        require(thisRound.quota >= amount, "out of stock");
        if (!config.allowContract) {
            require(tx.origin == msg.sender, "not allow contract");
        }
        thisRound.quota -= uint32(amount);
    }

    /// magic overload

    function mint(string memory roundName, uint256 amount)
        public
        payable
        nonReentrant
    {
        bytes32 key = keccak256(abi.encodePacked(roundName));
        Round storage thisRound = roundData[key];

        requestMint(thisRound, amount);

        // require(thisRound.isActive, "not active");
        // require(thisRound.quota >= amount, "out of stock");
        // if (!config.allowContract) {
        //     require(tx.origin == msg.sender, "not allow contract");
        // }
        // thisRound.quota -= uint32(amount);

        require(!thisRound.isMerkleMode, "wrong data");

        if (!thisRound.isPublic) {
            require(walletList[key].contains(msg.sender));
            require(
                mintedInRound[key][msg.sender] + amount <=
                    thisRound.amountPerUser,
                "out of quota"
            );
            mintedInRound[key][msg.sender] += amount;
        } else {
            require(amount <= thisRound.amountPerUser, "nope"); // public round can mint multiple time
        }

        paymentUtil.processPayment(
            thisRound.tokenAddress,
            thisRound.price * amount
        );

        _mintNext(msg.sender, amount);
    }

    function mint(
        string memory roundName,
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        bytes32[] memory proof
    ) public payable {
        bytes32 key = keccak256(abi.encodePacked(roundName));

        Round storage thisRound = roundData[key];

        requestMint(thisRound, amount);

        // require(thisRound.isActive, "not active");
        // require(thisRound.quota >= amount, "out of quota");
        // thisRound.quota -= uint32(amount);

        require(thisRound.isMerkleMode, "invalid");

        bytes32 data = hash(
            wallet,
            amount,
            tokenID,
            nonce,
            pricePerUnit,
            denominatedAsset,
            address(this),
            block.chainid
        );
        require(_merkleCheck(data, merkleRoot[key], proof), "fail merkle");

        _useNonce(nonce);
        if (wallet != address(0)) {
            require(wallet == msg.sender, "nope");
        }

        require(amount * tokenID == 0, "pick one"); // such a lazy check lol

        if (amount > 0) {
            paymentUtil.processPayment(denominatedAsset, pricePerUnit * amount);
            _mintNext(wallet, amount);
        } else {
            paymentUtil.processPayment(denominatedAsset, pricePerUnit);
            _mintTarget(wallet, tokenID);
        }
    }

    function mint(
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        bytes memory signature
    ) public payable {
        bytes32 data = hash(
            wallet,
            amount,
            tokenID,
            nonce,
            pricePerUnit,
            denominatedAsset,
            address(this),
            block.chainid
        );

        require(config.allowLazySell, "not available");
        require(config.allowPrivilege, "not available");

        require(_verifySig(data, signature));

        _useNonce(nonce);
        if (wallet != address(0)) {
            require(wallet == msg.sender, "nope");
        }

        require(amount * tokenID == 0, "pick one"); // such a lazy check lol

        if (amount > 0) {
            paymentUtil.processPayment(denominatedAsset, pricePerUnit * amount);
            _mintNext(wallet, amount);
        } else {
            paymentUtil.processPayment(denominatedAsset, pricePerUnit);
            _mintTarget(wallet, tokenID);
        }
    }

    /// magic overload end

    // this is 721 version. in 20 or 1155 will use the same format but different interpretation
    // wallet = 0 mean any
    // tokenID = 0 mean next
    // amount will overide tokenID
    // denominatedAsset = 0 mean chain token (e.g. eth)
    // chainID is to prevent replay attack

    function hash(
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        address refPorject,
        uint256 chainID
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    wallet,
                    amount,
                    tokenID,
                    nonce,
                    pricePerUnit,
                    denominatedAsset,
                    refPorject,
                    chainID
                )
            );
    }

    function _toSignedHash(bytes32 data) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(data);
    }

    function _verifySig(bytes32 data, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            hasRole(MINTER_ROLE, ECDSA.recover(_toSignedHash(data), signature));
    }

    function _merkleCheck(
        bytes32 data,
        bytes32 root,
        bytes32[] memory merkleProof
    ) internal pure returns (bool) {
        return MerkleProof.verify(merkleProof, root, data);
    }

    /// ROUND

    function newRound(
        string memory roundName,
        uint128 _price,
        uint32 _quota,
        uint16 _amountPerUser,
        bool _isActive,
        bool _isPublic,
        bool _isMerkle,
        address _tokenAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));

        require(!roundData[key].exist, "already exist");
        roundNames.push(roundName);
        roundData[key] = Round({
            price: _price,
            quota: _quota,
            amountPerUser: _amountPerUser,
            isActive: _isActive,
            isPublic: _isPublic,
            isMerkleMode: _isMerkle,
            tokenAddress: _tokenAddress,
            exist: true
        });
    }

    function triggerRound(string memory roundName, bool _isActive)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        roundData[key].isActive = _isActive;
    }

    function setMerkleRoot(string memory roundName, bytes32 root)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        merkleRoot[key] = root;
    }

    function updateRound(
        string memory roundName,
        uint128 _price,
        uint32 _quota,
        uint16 _amountPerUser,
        bool _isPublic
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        roundData[key].price = _price;
        roundData[key].quota = _quota;
        roundData[key].amountPerUser = _amountPerUser;
        roundData[key].isPublic = _isPublic;
    }

    function addRoundWallet(string memory roundName, address[] memory wallets)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        for (uint256 i = 0; i < wallets.length; i++) {
            walletList[key].add(wallets[i]);
        }
    }

    function removeRoundWallet(
        string memory roundName,
        address[] memory wallets
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        for (uint256 i = 0; i < wallets.length; i++) {
            walletList[key].remove(wallets[i]);
        }
    }

    function getRoundWallet(string memory roundName)
        public
        view
        returns (address[] memory)
    {
        return walletList[keccak256(abi.encodePacked(roundName))].values();
    }

    function isQualify(address wallet, string memory roundName)
        public
        view
        returns (bool)
    {
        Round memory x = roundInfo(roundName);
        if (!x.isActive) {
            return false;
        }
        if (x.quota == 0) {
            return false;
        }
        bytes32 key = keccak256(abi.encodePacked(roundName));
        if (!x.isPublic && !walletList[key].contains(wallet)) {
            return false;
        }
        if (mintedInRound[key][wallet] >= x.amountPerUser) {
            return false;
        }
        return true;
    }

    function listQualifiedRound(address wallet)
        public
        view
        returns (string[] memory)
    {
        string[] memory valid = new string[](roundNames.length);
        for (uint256 i = 0; i < roundNames.length; i++) {
            if (isQualify(wallet, roundNames[i])) {
                valid[i] = roundNames[i];
            }
        }
        return valid;
    }

    function burnNonce(uint256[] calldata nonces)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowPrivilege, "df");

        for (uint256 i = 0; i < nonces.length; i++) {
            nonceUsed[nonces[i]] = true;
        }
    }

    function resetNonce(uint256[] calldata nonces)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowPrivilege, "df");

        for (uint256 i = 0; i < nonces.length; i++) {
            nonceUsed[nonces[i]] = false;
        }
    }

    function _useNonce(uint256 nonce) internal {
        require(!nonceUsed[nonce], "used");
        nonceUsed[nonce] = true;
    }

    /// ROUND end ///

    function initialize(
        bytes calldata initArg,
        uint128 _bip,
        address _feeReceiver
    ) public initializer {
        feeReceiver = _feeReceiver;
        bip = _bip;

        (
            string memory name,
            string memory symbol,
            string memory baseTokenURI,
            address owner,
            bool _allowNFTUpdate,
            bool _allowConfUpdate,
            bool _allowContract,
            bool _allowPrivilege,
            bool _randomAccessMode,
            bool _allowTarget,
            bool _allowLazySell
        ) = abi.decode(
                initArg,
                (
                    string,
                    string,
                    string,
                    address,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool
                )
            );

        __721Init(name, symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);

        _baseTokenURI = baseTokenURI;
        config = Conf({
            allowNFTUpdate: _allowNFTUpdate,
            allowConfUpdate: _allowConfUpdate,
            allowContract: _allowContract,
            allowPrivilege: _allowPrivilege,
            randomAccessMode: _randomAccessMode,
            allowTarget: _allowTarget,
            allowLazySell: _allowLazySell,
            maxSupply: 0
        });
    }

    function updateConfig(
        bool _allowNFTUpdate,
        bool _allowConfUpdate,
        bool _allowContract,
        bool _allowPrivilege,
        bool _allowTarget,
        bool _allowLazySell
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(config.allowConfUpdate);
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        config.allowNFTUpdate = _allowNFTUpdate;
        config.allowConfUpdate = _allowConfUpdate;
        config.allowContract = _allowContract;
        config.allowPrivilege = _allowPrivilege;
        config.allowTarget = _allowTarget;
        config.allowLazySell = _allowLazySell;
    }

    function withdraw(address tokenAddress) public nonReentrant {
        address reviver = beneficiary;
        if (beneficiary == address(0)) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
            reviver = msg.sender;
        }
        if (tokenAddress == address(0)) {
            payable(feeReceiver).transfer(
                (address(this).balance * bip) / 10000
            );
            payable(reviver).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(
                feeReceiver,
                (token.balanceOf(address(this)) * bip) / 10000
            );
            token.safeTransfer(reviver, token.balanceOf(address(this)));
        }
    }

    function setRandomness(address _randomness)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        randomness = ISBRandomness(_randomness);
    }

    function contractURI() external view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "contract_uri"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "uri/", tokenId.toString()));
    }

    // @dev boring section -------------------

    function __721Init(string memory name, string memory symbol) internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


// File contracts/SBII721A.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐










// @dev speedboat v2 erc721A = modified SBII721A
// @dev should treat this code as experimental.
contract SBII721A is
    Initializable,
    ERC721ASBUpgradable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    ISBMintable,
    ISBShipable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using StringsUpgradeable for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public constant MODEL = "SBII-721A-EARLYACCESS";

    struct Round {
        uint128 price;
        uint32 quota;
        uint16 amountPerUser;
        bool isActive;
        bool isPublic;
        bool isMerkleMode; // merkleMode will override price, amountPerUser, and TokenID if specify
        bool exist;
        address tokenAddress; // 0 for base asset
    }

    struct Conf {
        bool allowNFTUpdate;
        bool allowConfUpdate;
        bool allowContract;
        bool allowPrivilege;
        bool randomAccessMode;
        bool allowTarget;
        bool allowLazySell;
        uint64 maxSupply;
    }

    Conf public config;
    string[] public roundNames;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private walletList;
    mapping(bytes32 => bytes32) private merkleRoot;
    mapping(bytes32 => Round) private roundData;
    mapping(uint256 => bool) private nonceUsed;

    mapping(bytes32 => mapping(address => uint256)) mintedInRound;

    string private _baseTokenURI;
    address private feeReceiver;
    uint256 private bip;
    address public beneficiary;

    function listRole()
        public
        pure
        returns (string[] memory names, bytes32[] memory code)
    {
        names = new string[](2);
        code = new bytes32[](2);

        names[0] = "MINTER";
        names[1] = "ADMIN";

        code[0] = MINTER_ROLE;
        code[1] = DEFAULT_ADMIN_ROLE;
    }

    function grantRoles(bytes32 role, address[] calldata accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            super.grantRole(role, accounts[i]);
        }
    }

    function revokeRoles(bytes32 role, address[] calldata accounts) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            super.revokeRole(role, accounts[i]);
        }
    }

    function setBeneficiary(address _beneficiary)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(beneficiary == address(0), "already set");
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        beneficiary = _beneficiary;
    }

    // 0 = unlimited, can only set once.
    function setMaxSupply(uint64 _maxSupply)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(config.maxSupply == 0, "already set");
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        config.maxSupply = _maxSupply;
    }

    function listRoleWallet(bytes32 role)
        public
        view
        returns (address[] memory roleMembers)
    {
        uint256 count = getRoleMemberCount(role);
        roleMembers = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            roleMembers[i] = getRoleMember(role, i);
        }
    }

    function listToken(address wallet)
        public
        view
        returns (uint256[] memory tokenList)
    {
        return tokensOfOwner(wallet);
    }

    function listRounds() public view returns (string[] memory) {
        return roundNames;
    }

    function roundInfo(string memory roundName)
        public
        view
        returns (Round memory)
    {
        return roundData[keccak256(abi.encodePacked(roundName))];
    }

    function massMint(address[] calldata wallets, uint256[] calldata amount)
        public
    {
        require(config.allowPrivilege, "disabled feature");
        require(hasRole(MINTER_ROLE, msg.sender), "require permission");
        for (uint256 i = 0; i < wallets.length; i++) {
            mintNext(wallets[i], amount[i]);
        }
    }

    function mintNext(address reciever, uint256 amount) public override {
        require(config.allowPrivilege, "disabled feature");
        require(hasRole(MINTER_ROLE, msg.sender), "require permission");
        _mintNext(reciever, amount);
    }

    function _mintNext(address reciever, uint256 amount) internal {
        if (config.maxSupply != 0) {
            require(totalSupply() + amount <= config.maxSupply);
        }
        _safeMint(reciever, amount); // 721A mint
    }

    function _random(address ad, uint256 num) internal returns (uint256) {
        revert("not supported by 721a la");
    }

    function updateURI(string memory newURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowNFTUpdate, "not available");
        _baseTokenURI = newURI;
    }

    function mintTarget(address reciever, uint256 target) public override {
        revert("not supported by 721a la");
    }

    function requestMint(Round storage thisRound, uint256 amount) internal {
        require(thisRound.isActive, "not active");
        require(thisRound.quota >= amount, "out of stock");
        if (!config.allowContract) {
            require(tx.origin == msg.sender, "not allow contract");
        }
        thisRound.quota -= uint32(amount);
    }

    /// magic overload

    function mint(string memory roundName, uint256 amount)
        public
        payable
        nonReentrant
    {
        bytes32 key = keccak256(abi.encodePacked(roundName));
        Round storage thisRound = roundData[key];

        requestMint(thisRound, amount);

        // require(thisRound.isActive, "not active");
        // require(thisRound.quota >= amount, "out of stock");
        // if (!config.allowContract) {
        //     require(tx.origin == msg.sender, "not allow contract");
        // }
        // thisRound.quota -= uint32(amount);

        require(!thisRound.isMerkleMode, "wrong data");

        if (!thisRound.isPublic) {
            require(walletList[key].contains(msg.sender));
            require(
                mintedInRound[key][msg.sender] + amount <=
                    thisRound.amountPerUser,
                "out of quota"
            );
            mintedInRound[key][msg.sender] += amount;
        } else {
            require(amount <= thisRound.amountPerUser, "nope"); // public round can mint multiple time
        }

        paymentUtil.processPayment(
            thisRound.tokenAddress,
            thisRound.price * amount
        );

        _mintNext(msg.sender, amount);
    }

    function mint(
        string memory roundName,
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        bytes32[] memory proof
    ) public payable {
        bytes32 key = keccak256(abi.encodePacked(roundName));
        Round storage thisRound = roundData[key];

        requestMint(thisRound, amount);

        // require(thisRound.isActive, "not active");
        // require(thisRound.quota >= amount, "out of quota");
        // thisRound.quota -= uint32(amount);

        require(thisRound.isMerkleMode, "invalid");

        bytes32 data = hash(
            wallet,
            amount,
            tokenID,
            nonce,
            pricePerUnit,
            denominatedAsset,
            address(this),
            block.chainid
        );
        require(_merkleCheck(data, merkleRoot[key], proof), "fail merkle");

        _useNonce(nonce);
        if (wallet != address(0)) {
            require(wallet == msg.sender, "nope");
        }

        require(amount > 0, "pick one"); // such a lazy check lol
        require(tokenID == 0, "nope"); // such a lazy check lol

        paymentUtil.processPayment(denominatedAsset, pricePerUnit * amount);
        _mintNext(wallet, amount);
    }

    function mint(
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        bytes memory signature
    ) public payable {
        bytes32 data = hash(
            wallet,
            amount,
            tokenID,
            nonce,
            pricePerUnit,
            denominatedAsset,
            address(this),
            block.chainid
        );
        require(config.allowLazySell, "not available");
        require(config.allowPrivilege, "not available");

        require(_verifySig(data, signature));

        _useNonce(nonce);
        if (wallet != address(0)) {
            require(wallet == msg.sender, "nope");
        }

        require(amount > 0, "pick one"); // such a lazy check lol
        require(tokenID == 0, "nope"); // such a lazy check lol

        paymentUtil.processPayment(denominatedAsset, pricePerUnit * amount);
        _mintNext(wallet, amount);
    }

    /// magic overload end

    // this is 721 version. in 20 or 1155 will use the same format but different interpretation
    // wallet = 0 mean any
    // tokenID = 0 mean next
    // amount will overide tokenID
    // denominatedAsset = 0 mean chain token (e.g. eth)
    // chainID is to prevent replay attack

    function hash(
        address wallet,
        uint256 amount,
        uint256 tokenID,
        uint256 nonce,
        uint256 pricePerUnit,
        address denominatedAsset,
        address refPorject,
        uint256 chainID
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    wallet,
                    amount,
                    tokenID,
                    nonce,
                    pricePerUnit,
                    denominatedAsset,
                    refPorject,
                    chainID
                )
            );
    }

    function _toSignedHash(bytes32 data) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(data);
    }

    function _verifySig(bytes32 data, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            hasRole(MINTER_ROLE, ECDSA.recover(_toSignedHash(data), signature));
    }

    function _merkleCheck(
        bytes32 data,
        bytes32 root,
        bytes32[] memory merkleProof
    ) internal pure returns (bool) {
        return MerkleProof.verify(merkleProof, root, data);
    }

    /// ROUND

    function newRound(
        string memory roundName,
        uint128 _price,
        uint32 _quota,
        uint16 _amountPerUser,
        bool _isActive,
        bool _isPublic,
        bool _isMerkle,
        address _tokenAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));

        require(!roundData[key].exist, "already exist");
        roundNames.push(roundName);
        roundData[key] = Round({
            price: _price,
            quota: _quota,
            amountPerUser: _amountPerUser,
            isActive: _isActive,
            isPublic: _isPublic,
            isMerkleMode: _isMerkle,
            tokenAddress: _tokenAddress,
            exist: true
        });
    }

    function triggerRound(string memory roundName, bool _isActive)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        roundData[key].isActive = _isActive;
    }

    function setMerkleRoot(string memory roundName, bytes32 root)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        merkleRoot[key] = root;
    }

    function updateRound(
        string memory roundName,
        uint128 _price,
        uint32 _quota,
        uint16 _amountPerUser,
        bool _isPublic
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        roundData[key].price = _price;
        roundData[key].quota = _quota;
        roundData[key].amountPerUser = _amountPerUser;
        roundData[key].isPublic = _isPublic;
    }

    function addRoundWallet(string memory roundName, address[] memory wallets)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        for (uint256 i = 0; i < wallets.length; i++) {
            walletList[key].add(wallets[i]);
        }
    }

    function removeRoundWallet(
        string memory roundName,
        address[] memory wallets
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        bytes32 key = keccak256(abi.encodePacked(roundName));
        for (uint256 i = 0; i < wallets.length; i++) {
            walletList[key].remove(wallets[i]);
        }
    }

    function getRoundWallet(string memory roundName)
        public
        view
        returns (address[] memory)
    {
        return walletList[keccak256(abi.encodePacked(roundName))].values();
    }

    function isQualify(address wallet, string memory roundName)
        public
        view
        returns (bool)
    {
        Round memory x = roundInfo(roundName);
        if (!x.isActive) {
            return false;
        }
        if (x.quota == 0) {
            return false;
        }
        bytes32 key = keccak256(abi.encodePacked(roundName));
        if (!x.isPublic && !walletList[key].contains(wallet)) {
            return false;
        }
        if (mintedInRound[key][wallet] >= x.amountPerUser) {
            return false;
        }
        return true;
    }

    function listQualifiedRound(address wallet)
        public
        view
        returns (string[] memory)
    {
        string[] memory valid = new string[](roundNames.length);
        for (uint256 i = 0; i < roundNames.length; i++) {
            if (isQualify(wallet, roundNames[i])) {
                valid[i] = roundNames[i];
            }
        }
        return valid;
    }

    function burnNonce(uint256[] calldata nonces)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowPrivilege, "disabled feature");

        for (uint256 i = 0; i < nonces.length; i++) {
            nonceUsed[nonces[i]] = true;
        }
    }

    function resetNonce(uint256[] calldata nonces)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(config.allowPrivilege, "disabled feature");

        for (uint256 i = 0; i < nonces.length; i++) {
            nonceUsed[nonces[i]] = false;
        }
    }

    function _useNonce(uint256 nonce) internal {
        require(!nonceUsed[nonce], "used");
        nonceUsed[nonce] = true;
    }

    /// ROUND end ///

    function initialize(
        bytes calldata initArg,
        uint128 _bip,
        address _feeReceiver
    ) public initializer {
        feeReceiver = _feeReceiver;
        bip = _bip;

        (
            string memory name,
            string memory symbol,
            string memory baseTokenURI,
            address owner,
            bool _allowNFTUpdate,
            bool _allowConfUpdate,
            bool _allowContract,
            bool _allowPrivilege,
            bool _randomAccessMode,
            bool _allowTarget,
            bool _allowLazySell
        ) = abi.decode(
                initArg,
                (
                    string,
                    string,
                    string,
                    address,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool,
                    bool
                )
            );

        __721AInit(name, symbol);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);

        _baseTokenURI = baseTokenURI;
        config = Conf({
            allowNFTUpdate: _allowNFTUpdate,
            allowConfUpdate: _allowConfUpdate,
            allowContract: _allowContract,
            allowPrivilege: _allowPrivilege,
            randomAccessMode: _randomAccessMode,
            allowTarget: _allowTarget,
            allowLazySell: _allowLazySell,
            maxSupply: 0
        });
    }

    function updateConfig(
        bool _allowNFTUpdate,
        bool _allowConfUpdate,
        bool _allowContract,
        bool _allowPrivilege,
        bool _allowTarget,
        bool _allowLazySell
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(config.allowConfUpdate);
        // require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        config.allowNFTUpdate = _allowNFTUpdate;
        config.allowConfUpdate = _allowConfUpdate;
        config.allowContract = _allowContract;
        config.allowPrivilege = _allowPrivilege;
        config.allowTarget = _allowTarget;
        config.allowLazySell = _allowLazySell;
    }

    function withdraw(address tokenAddress) public nonReentrant {
        address reviver = beneficiary;
        if (beneficiary == address(0)) {
            require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
            reviver = msg.sender;
        }
        if (tokenAddress == address(0)) {
            payable(feeReceiver).transfer(
                (address(this).balance * bip) / 10000
            );
            payable(reviver).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(
                feeReceiver,
                (token.balanceOf(address(this)) * bip) / 10000
            );
            token.safeTransfer(reviver, token.balanceOf(address(this)));
        }
    }

    function contractURI() external view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "contract_uri"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "uri/", tokenId.toString()));
    }

    // @dev boring section -------------------

    function __721AInit(string memory name, string memory symbol) internal {
        __ReentrancyGuard_init_unchained();
        __ERC721A_init(name, symbol);
        __AccessControlEnumerable_init_unchained();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721ASBUpgradable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File @openzeppelin/contracts-upgradeable/finance/[email protected]


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)





/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}


// File contracts/SBIIPayment.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐




// @dev
contract SBIIPayment is Initializable, PaymentSplitterUpgradeable, ISBShipable {
    string public constant MODEL = "SBII-paymentSplitterU-test";
    bool public allowUpdate;

    function initialize(
        bytes memory initArg,
        uint128 bip,
        address feeReceiver
    ) public override initializer {
        (address[] memory payee, uint256[] memory share) = abi.decode(
            initArg,
            (address[], uint256[])
        );
        __PaymentSplitter_init(payee, share);
        // no fee no fee feeReceiver
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)


/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/ShipyardII.sol


// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.
//  ╬ô├▓├╢╬ô├▓├ë╬ô├▓├╣╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ë ╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢├«╬ô├╢├ç╬ô├╢├ë╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝ ╬ô├╢┬╝╬ô├╢├«╬ô├╢┬╝╬ô├╢├ë╬ô├╢┬╝╬ô├╢├«╬ô├╢├ç╬ô├╢├ë
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓├╣╬ô├╢┬ú╬ô├╢├ç╬ô├╢├┐╬ô├╢┬ú╬ô├╢├▒ ╬ô├╢┬ú╬ô├╢├▒  ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢┬ú╬ô├╢Γöñ╬ô├╢├ë╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢┬ú╬ô├╢├ç╬ô├╢├▒ ╬ô├╢├⌐ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├ë ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐ ╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐╬ô├╢├⌐ ╬ô├╢├⌐
//  ╬ô├▓├£╬ô├▓├ë╬ô├▓┬Ñ╬ô├╢Γöñ  ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢Γöñ ╬ô├╢Γöñ ╬ô├╢Γöño╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐ ╬ô├╢Γöñ ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐╬ô├╢├ç╬ô├╢Γöñ╬ô├╢├┐╬ô├╢Γöñ╬ô├╢├╢╬ô├╢├ç╬ô├╢├┐







contract Shipyard is Ownable {
    event NewShip(string reserveName, address newShip, string shipType);

    mapping(bytes32 => address) public shipImplementation;
    mapping(bytes32 => string) public shipTypes;

    Quartermaster public quarterMaster;
    Lighthouse public lighthouse;

    string public constant MODEL = "SBII-shipyard-test";

    constructor() {}

    function setSail(
        string calldata shipType,
        string calldata reserveName,
        bytes calldata initArg
    ) external payable returns (address) {
        bytes32 key = keccak256(abi.encodePacked(shipType));
        require(shipImplementation[key] != address(0), "not exist");
        Quartermaster.Fees memory fees = quarterMaster.getFees(shipType);

        paymentUtil.processPayment(fees.token, fees.onetime);

        address clone = ClonesUpgradeable.clone(shipImplementation[key]);
        ISBShipable(clone).initialize(initArg, fees.bip, address(this));
        lighthouse.registerContract(
            reserveName,
            clone,
            shipTypes[key],
            msg.sender
        );
        emit NewShip(reserveName, clone, shipTypes[key]);
        return clone;
    }

    function getPrice(string calldata shipType)
        public
        view
        returns (Quartermaster.Fees memory)
    {
        return quarterMaster.getFees(shipType);
    }

    function addBlueprint(
        string memory shipName,
        string memory shipType,
        address implementation
    ) public onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(shipName));
        shipImplementation[key] = implementation;
        shipTypes[key] = shipType;
    }

    function removeBlueprint(string memory shipName) public onlyOwner {
        shipImplementation[keccak256(abi.encodePacked(shipName))] = address(0);
    }

    function withdraw(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function setQM(address qm) public onlyOwner {
        quarterMaster = Quartermaster(qm);
    }

    function setLH(address lh) public onlyOwner {
        lighthouse = Lighthouse(lh);
    }

    receive() external payable {}

    fallback() external payable {}
}