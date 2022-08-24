/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

////import "../../utils/AddressUpgradeable.sol";

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

////import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IWrapNFT is IERC721Receiver {
    event Stake(address msgSender, address nftAddress, uint256 tokenId);

    event Redeem(address msgSender, address nftAddress, uint256 tokenId);

    function originalAddress() external view returns (address);

    function stake(uint256 tokenId) external returns (uint256);

    function redeem(uint256 tokenId) external;
}




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
////import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDoNFTV2 is IERC721Receiver {
    enum DoNFTModelType {
        ERC4907Model, // 0
        WrapModel // 1
    }

    struct DoNftInfoV2 {
        uint256 originalNftId;
        address originalNftAddress;
        uint64 nonce;
        uint64 startTime;
        uint64 endTime;
    }

    event MetadataUpdate(uint256 tokenId);


    function getModelType() external view returns (DoNFTModelType);

    function mintVNft(address oNftAddress,uint256 originalNftId) external returns (uint256);

    function mint(
        uint256 tokenId,
        uint64 startTime,
        uint64 endTime,
        address to,
        address user
    ) external returns (uint256 tid);

    function setMaxDuration(uint64 v) external;

    function getMaxDuration() external view returns (uint64);

    function getDoNftInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 originalNftId,
            address originalNftAddress,
            uint64 nonce,
            uint64 startTime,
            uint64 endTime
        );

    function getOriginalNftId(uint256 tokenId) external view returns (uint256);

    function getOriginalNftAddress(uint256 tokenId) external view returns (address);

    function getNonce(uint256 tokenId) external view returns (uint64);

    function getStartTime(uint256 tokenId) external view returns (uint64);

    function getEndTime(uint256 tokenId) external view returns (uint64);

    function getVNftId(address originalNftAddress, uint256 originalNftId) external view returns (uint256);

    function getUser(address originalNftAddress, uint256 originalNftId) external view returns (address);

    function isVNft(uint256 tokenId) external view returns (bool);

    function isValidNow(uint256 tokenId) external view returns (bool);

    function checkIn(address to, uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);

    function couldRedeem(uint256 tokenId) external view returns (bool);

    function redeem(uint256 tokenId) external;
}




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    function initOwnableContract(address _owner, address _admin) internal {
        owner = _owner;
        admin = _admin;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, "onlyAdmin");
        _;
    }

    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }

    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.6.6 <0.9.0;

interface IMarketV2 {
    enum OrderType {
        Public, // 0
        Private, // 1
        Event_Private //2
    }

    struct Lending {  
        address lender; 
        uint64 maxEndTime; 
        uint32 nonce; 
        address doNftAddress; //160 
        uint64 minDuration; // 64  
        OrderType orderType; //8 
        uint256 doNftId;      // 256
        address paymentToken; //160
        uint64 createTime; //64 
        address privateOrderRenter;  //160
        uint96 pricePerDay; //96 
        
    }

    struct PaymentNormal {
        address token;
        uint256 pricePerDay;
    }

    struct RoyaltyInfo {
        address royaltyAdmin;
        address beneficiary;
        uint32 royaltyFee;
    }

    event CreateLendOrderV2(   
        address lender, 
        uint64 maxEndTime, 
        OrderType orderType, 
        address erc4907NftAddress,
        uint96 pricePerDay, 
        uint256 erc4907NftId, 
        address doNftAddress,
        uint64 minDuration, 
        uint256 doNftId, 
        address paymentToken, 
        address privateOrderRenter 
    );

    event CancelLendOrder(address lender, address nftAddress, uint256 nftId);
   
    event FulfillOrderV2(  
        address renter,  
        uint64 startTime, 
        address lender, 
        uint64 endTime,  
        address erc4907NftAddress,  
        uint256 erc4907NftId, 
        address doNftAddress, 
        uint256 doNftId,
        uint256 newId,
        address paymentToken,
        uint96 pricePerDay
    );

    event Paused(address account);
    event Unpaused(address account);

    event RoyaltyAdminChanged(address operator, address erc4907NftAddress, address royaltyAdmin);
    event RoyaltyBeneficiaryChanged(address operator, address erc4907NftAddress, address beneficiary);
    event RoyaltyFeeChanged(address operator, address erc4907NftAddress, uint32 royaltyFee);

    function createLendOrder( 
        address doNftAddress,
        uint64 maxEndTime, 
        OrderType orderType, 
        uint256 doNftId, 
        address paymentToken, 
        uint96 pricePerDay,  
        address privateOrderRenter, 
        uint64 minDuration 
    ) external;




    function mintAndCreateLendOrder(
        address erc4907NftAddress, 
        uint96 pricePerDay, 
        address doNftAddress, 
        uint64 maxEndTime, 
        uint256 erc4907NftId, 
        address paymentToken,
        uint64 minDuration,
        OrderType orderType,  
        address privateOrderRenter
    ) external;

    function cancelLendOrder(address nftAddress, uint256 nftId) external;

    function getLendOrder(address nftAddress, uint256 nftId)
        external
        view
        returns (Lending memory);

    function fulfillOrderNow(
        address doNftAddress, 
        uint64 duration, 
        uint256 doNftId,  
        address user,  
        address paymentToken, 
        uint96 pricePerDay 
    ) external payable returns (uint256 tid);

    function setMarketFee(uint256 fee) external;

    function getMarketFee() external view returns (uint256);

    function setMarketBeneficiary(address payable beneficiary) external;

    function claimMarketFee(address[] calldata paymentTokens) external;

    function setRoyaltyAdmin(address erc4907NftAddress, address royaltyAdmin) external;
      
    function getRoyaltyAdmin(address erc4907NftAddress) external view returns(address);

    function setBeneficiary(address erc4907NftAddress, address  beneficiary) external; 

    function getBeneficiary(address erc4907NftAddress) external view returns (address);

    function balanceOfRoyalty(address erc4907NftAddress, address paymentToken) external view returns (uint256);

    function setRoyaltyFee(address erc4907NftAddress, uint32 royaltyFee) external;

    function getRoyaltyFee(address erc4907NftAddress) external view returns (uint32);

    function claimRoyalty(address erc4907NftAddress, address[] calldata paymentTokens) external;

    function isLendOrderValid(address nftAddress, uint256 nftId) external view returns (bool);

    function setPause(bool v) external;
}




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

////import "./IERC721.sol";
////import "./IERC721Receiver.sol";
////import "./extensions/IERC721Metadata.sol";
////import "../../utils/Address.sol";
////import "../../utils/Context.sol";
////import "../../utils/Strings.sol";
////import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}




/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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


/** 
 *  SourceUnit: /Users/wangjiahui/wwj_workspace/double/double-hardhat/contracts/v2/MarketV2V2.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
////import "@openzeppelin/contracts/utils/Address.sol";
////import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
////import "./IMarketV2.sol";
////import "../OwnableContract.sol";
////import "./IDoNFTV2.sol";
////import "../dualRoles/wrap/IWrapNFT.sol";

contract MarketV2 is OwnableContract, ReentrancyGuardUpgradeable, IMarketV2 {
    uint64 private constant E5 = 1e5;
    mapping(address => mapping(uint256 => Lending)) internal lendingMap;
    
    // erc4907NftAddress  => mapping(paymentToken => balance)
    mapping(address => mapping(address => uint256)) internal royaltyIncomeMap;

    // erc4907NftAddress => RoyaltyInfo
    mapping(address => RoyaltyInfo) internal royaltyInfoMap;

    //      paymentToken  balance
    mapping(address => uint256) public marketBalanceOfFee;
    address payable public marketBeneficiary;
    uint256 private marketFee;
    uint64 public maxIndate;
    bool public isPausing;

    function initialize(address owner_, address admin_) public initializer {
        __ReentrancyGuard_init();
        initOwnableContract(owner_, admin_);
        maxIndate = 365 days;
        marketFee = 2500;
    }

    function onlyApprovedOrOwner(
        address spender,
        address nftAddress,
        uint256 nftId
    ) internal view {
        address _owner = ERC721(nftAddress).ownerOf(nftId);
        require(
            spender == _owner ||
                ERC721(nftAddress).getApproved(nftId) == spender ||
                ERC721(nftAddress).isApprovedForAll(_owner, spender),
            "only approved or owner"
        );
    }

    function onlyNftOwner(
        address nftAddress,
        uint256 nftId
    ) internal view {
        address _owner = IERC721(nftAddress).ownerOf(nftId);
        require( msg.sender == _owner, "only owner");
    }

    modifier whenNotPaused() {
        require(!isPausing, "is pausing");
        _;
    }

        

    function mintAndCreateLendOrder(
        address erc4907NftAddress, 
        uint96 pricePerDay, 
        address doNftAddress,  
        uint64 maxEndTime, 
        uint256 erc4907NftId, 
        address paymentToken,
        uint64 minDuration, 
        OrderType orderType, 
        address privateOrderRenter
    ) public nonReentrant {

        uint256 doNftId;
        if(IDoNFTV2(doNftAddress).getModelType() == IDoNFTV2.DoNFTModelType.WrapModel){
            doNftId = _mintVForWrap(erc4907NftAddress, doNftAddress, erc4907NftId);
        }else{
            doNftId = _mintVFor4907(erc4907NftAddress, doNftAddress, erc4907NftId);
        }
        createLendOrder(
            doNftAddress,
            maxEndTime,
            orderType,
            doNftId,
            paymentToken,
            pricePerDay,
            privateOrderRenter,
            minDuration
        ); 
    }


    

    function _mintVForWrap(
        address wNftAddress,
        address doNftAddress,
        uint256 oNftId
    ) internal returns (uint256 nftId) {   

        address oNftAddress = IWrapNFT(wNftAddress).originalAddress();
        onlyNftOwner(oNftAddress, oNftId);
        nftId = IDoNFTV2(doNftAddress).mintVNft(oNftAddress, oNftId);
    }



    function _mintVFor4907(
        address oNftAddress,
        address doNftAddress,
        uint256 oNftId
    ) internal returns (uint256 nftId) {    
    
        onlyNftOwner(oNftAddress, oNftId);
        nftId = IDoNFTV2(doNftAddress).mintVNft(oNftAddress, oNftId);
    }

    function _setLending (Lending memory slending,address doNftAddress,uint256 doNftId, 
    address originalNftAddress,uint256 originalNftId) internal{

        Lending storage lending = lendingMap[doNftAddress][doNftId];
        lending.lender = slending.lender;
        lending.doNftAddress = doNftAddress;
        lending.doNftId = doNftId;
        lending.maxEndTime = slending.maxEndTime;
        lending.minDuration = slending.minDuration;
        lending.nonce = uint32(slending.nonce);
        lending.createTime = uint64(block.timestamp);
        lending.orderType = slending.orderType;
        lending.paymentToken = slending.paymentToken;
        lending.privateOrderRenter = slending.privateOrderRenter;
        lending.pricePerDay = slending.pricePerDay;

        emit CreateLendOrderV2(
            lending.lender,
            lending.maxEndTime,
            lending.orderType,
            originalNftAddress,
            lending.pricePerDay,
            originalNftId,
            lending.doNftAddress,
            lending.minDuration,
            lending.doNftId,
            lending.paymentToken,
            lending.privateOrderRenter            
        );
    }

    



    function createLendOrder(
        address doNftAddress,
        uint64 maxEndTime, 
        OrderType orderType, 
        uint256 doNftId, 
        address paymentToken, 
        uint96 pricePerDay,  
        address privateOrderRenter, 
        uint64 minDuration 
    ) public whenNotPaused {
        onlyApprovedOrOwner(msg.sender, doNftAddress, doNftId); // todo : remove , check approve outside
        require(maxEndTime > block.timestamp, "invalid maxEndTime");

        // todo : use getDoNftInfo for gas saving
        require(
            minDuration <= IDoNFTV2(doNftAddress).getMaxDuration(),
            "Error: invalid minDuration"
        );
        
        (uint256 originalNftId,
            address originalNftAddress,
            uint64 nonce,
             ,
            uint64 dEnd) = IDoNFTV2(doNftAddress).getDoNftInfo(doNftId);

        if (maxEndTime > dEnd) {
            maxEndTime = dEnd;
        }
        if (maxEndTime > block.timestamp + maxIndate) {
            maxEndTime = uint64(block.timestamp) + maxIndate;
        }

        address _owner = IERC721(doNftAddress).ownerOf(doNftId);
    
        Lending memory lending = Lending(_owner,maxEndTime,uint32(nonce),doNftAddress,minDuration,orderType,
        doNftId,paymentToken,uint64(block.timestamp),privateOrderRenter,pricePerDay);
        
        _setLending(lending, doNftAddress, doNftId,originalNftAddress,originalNftId);

    }

    function cancelLendOrder(address nftAddress, uint256 nftId)
        public
        whenNotPaused
    {
        onlyApprovedOrOwner(msg.sender, nftAddress, nftId);
        delete lendingMap[nftAddress][nftId];
        emit CancelLendOrder(msg.sender, nftAddress, nftId);
    }

    function getLendOrder(address nftAddress, uint256 nftId)
        public
        view
        returns (Lending memory)
    {
        return lendingMap[nftAddress][nftId];
    }



    function fulfillOrderNow(
        address doNftAddress, 
        uint64 duration, 
        uint256 doNftId,  
        address user,  
        address paymentToken, 
        uint96 pricePerDay 

    ) public payable  whenNotPaused nonReentrant returns (uint256 tid) {
        require(isLendOrderValid(doNftAddress, doNftId), "invalid order");
        Lending storage lending = lendingMap[doNftAddress][doNftId];
        require(paymentToken == lending.paymentToken && pricePerDay == lending.pricePerDay,"invalid lending");

        if (lending.orderType == OrderType.Private || lending.orderType == OrderType.Event_Private) {
            require(msg.sender == lending.privateOrderRenter, "invalid renter");
        }
        uint64 endTime = uint64(block.timestamp + duration - 1);
        if (endTime > lending.maxEndTime) {
            endTime = lending.maxEndTime;
        }
         (uint256 originalNftId,
            address originalNftAddress,
            ,
            ,
            uint64 dEnd) = IDoNFTV2(doNftAddress).getDoNftInfo(doNftId);

        if (endTime > dEnd) {
            endTime = dEnd;
        }
        if (!(endTime == dEnd || endTime == lending.maxEndTime)) {
            require(duration >= lending.minDuration, "duration < minDuration");
        }

        _fulfillOrderNow(originalNftAddress,
        originalNftId,
        doNftAddress,
        endTime,
        doNftId,
        lending.lender,
        user,
        lending.paymentToken,
        lending.pricePerDay
         );                
    }

    function _fulfillOrderNow(
        address originalNftAddress,
        uint256 originalNftId,
        address doNftAddress,
        uint64 endTime,
        uint256 doNftId,
        address lender,
        address user,
        address paymentToken,
        uint96 pricePerDay
    ) 
    internal 
    returns (uint256 tid)
    {
        uint64 startTime = uint64(block.timestamp);

        distributePayment(doNftAddress, doNftId, startTime, endTime,paymentToken,pricePerDay);
        
        tid = IDoNFTV2(doNftAddress).mint(
            doNftId,
            startTime,
            endTime,
            msg.sender,
            user
          );

        emit FulfillOrderV2(
            msg.sender,
            startTime,
            lender,
            endTime,
            originalNftAddress,
            originalNftId,
            doNftAddress,
            doNftId,
            tid,
            paymentToken,
            pricePerDay
        );
    }

    function distributePayment(
        address nftAddress,
        uint256 nftId,
        uint64 startTime,
        uint64 endTime,
        address paymentToken,
        uint96 pricePerDay
    )
        internal
        returns (
            uint256 totalPrice,
            uint256 leftTotalPrice,
            uint256 curFee,
            uint256 curRoyalty
        )
    {
        if (pricePerDay == 0) return (0, 0, 0, 0);
        totalPrice = (pricePerDay * (endTime - startTime + 1)) / 86400;
        curFee = (totalPrice * marketFee) / E5;

        RoyaltyInfo storage royaltyInfo = royaltyInfoMap[nftAddress];

        curRoyalty = totalPrice * royaltyInfo.royaltyFee / E5;
        leftTotalPrice = totalPrice - curFee - curRoyalty;

        royaltyIncomeMap[nftAddress][paymentToken] += curRoyalty;
        marketBalanceOfFee[paymentToken] += curFee;

        if (paymentToken == address(0)) {
            require(msg.value >= totalPrice, "payment is not enough");
            Address.sendValue(
                payable(ERC721(nftAddress).ownerOf(nftId)),
                leftTotalPrice
            );
            if (msg.value > totalPrice) {
                Address.sendValue(payable(msg.sender), msg.value - totalPrice);
            }
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(paymentToken),
                msg.sender,
                address(this),
                totalPrice
            );

            SafeERC20.safeTransfer(
                IERC20(paymentToken),
                ERC721(nftAddress).ownerOf(nftId),
                leftTotalPrice
            );
        }
    }

    function setMarketFee(uint256 fee_) public onlyAdmin {
        require(fee_ <= 1e4, "invalid fee");
        marketFee = fee_;
    }

    function getMarketFee() public view returns (uint256) {
        return marketFee;
    }

    function setMarketBeneficiary(address payable beneficiary_)
        public
        onlyOwner
    {
        marketBeneficiary = beneficiary_;
    }

    function claimMarketFee(address[] calldata paymentTokens)
        public
        whenNotPaused
        nonReentrant
    {
        require(msg.sender == marketBeneficiary, "not beneficiary");
        for (uint256 index = 0; index < paymentTokens.length; index++) {
            uint256 balance = marketBalanceOfFee[paymentTokens[index]];
            if (balance > 0) {
                if (paymentTokens[index] == address(0)) {
                    Address.sendValue(marketBeneficiary, balance);
                } else {
                    SafeERC20.safeTransfer(
                        IERC20(paymentTokens[index]),
                        marketBeneficiary,
                        balance
                    );
                }
                marketBalanceOfFee[paymentTokens[index]] = 0;
            }
        }
    }

    function setRoyaltyAdmin(address erc4907NftAddress, address royaltyAdmin) public onlyAdmin {
        RoyaltyInfo storage royaltyInfo = royaltyInfoMap[erc4907NftAddress];
        royaltyInfo.royaltyAdmin = royaltyAdmin;
        emit RoyaltyAdminChanged(msg.sender, erc4907NftAddress, royaltyAdmin);
    }

    function getRoyaltyAdmin(address erc4907NftAddress) public view returns(address) {
        return royaltyInfoMap[erc4907NftAddress].royaltyAdmin;
    }

    function setBeneficiary(address erc4907NftAddress, address  beneficiary) public {
        require(beneficiary != address(0), "invalid beneficiary");
        RoyaltyInfo storage royaltyInfo = royaltyInfoMap[erc4907NftAddress];
        require(msg.sender == royaltyInfo.royaltyAdmin, "msg.sender is not royaltyAdmin");        
        royaltyInfo.beneficiary = beneficiary;
        emit RoyaltyBeneficiaryChanged(msg.sender, erc4907NftAddress, beneficiary);
    }

    function getBeneficiary(address erc4907NftAddress) public view returns (address) {
        return royaltyInfoMap[erc4907NftAddress].beneficiary;
    }

    function setRoyaltyFee(address erc4907NftAddress, uint32 royaltyFee) public {
        require(royaltyFee <= 10000, "fee exceeds 10pct");

        RoyaltyInfo storage royaltyInfo = royaltyInfoMap[erc4907NftAddress];
        require(msg.sender == royaltyInfo.royaltyAdmin, "msg.sender is not royaltyAdmin");
        royaltyInfo.royaltyFee = royaltyFee;

        emit RoyaltyFeeChanged(msg.sender, erc4907NftAddress, royaltyFee);
    }

    function getRoyaltyFee(address erc4907NftAddress) public view returns (uint32){
        return royaltyInfoMap[erc4907NftAddress].royaltyFee;
    }

    function claimRoyalty(address erc4907NftAddress, address[] calldata paymentTokens)
        public
        whenNotPaused
        nonReentrant
    {
        RoyaltyInfo storage royaltyInfo = royaltyInfoMap[erc4907NftAddress];
        address  _beneficiary = royaltyInfo.beneficiary;
        require(msg.sender == _beneficiary, "not beneficiary");
        for (uint256 index = 0; index < paymentTokens.length; index++) {
            address paymentToken = paymentTokens[index];

            uint256 balance = royaltyIncomeMap[erc4907NftAddress][paymentToken];
            if (balance > 0) {
                if (paymentTokens[index] == address(0)) {
                    Address.sendValue(payable(_beneficiary), balance);
                } else {
                    SafeERC20.safeTransfer(
                        IERC20(paymentTokens[index]),
                        _beneficiary,
                        balance
                    );
                }
                royaltyIncomeMap[erc4907NftAddress][paymentToken] = 0;
            }
        }
    }

    function balanceOfRoyalty(address erc4907NftAddress, address paymentToken) public view returns (uint256)
    {
        return royaltyIncomeMap[erc4907NftAddress][paymentToken];
    }

    function isLendOrderValid(address doNftAddress, uint256 doNftId)
        public
        view
        returns (bool)
    {
        Lending storage lending = lendingMap[doNftAddress][doNftId];
        if (isPausing) {
            return false;
        }
        return
            lending.doNftId > 0 &&
            lending.maxEndTime > block.timestamp &&
            lending.nonce == IDoNFTV2(doNftAddress).getNonce(doNftId);
    }

    function setPause(bool pause_) public onlyAdmin {
        isPausing = pause_;
        if (isPausing) {
            emit Paused(address(this));
        } else {
            emit Unpaused(address(this));
        }
    }

    function setMaxIndate(uint64 max_) public onlyAdmin {
        maxIndate = max_;
    }

    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (success) {
                results[i] = result;
            }
        }
        return results;
    }
}