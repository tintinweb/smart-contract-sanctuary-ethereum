/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]
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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
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
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        onlyInitializing
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/security/[email protected]

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File contracts/interfaces/ISodiumWalletFactory.sol

pragma solidity ^0.8.0;

interface ISodiumWalletFactory {
    /* ===== EVENTS ===== */

    // Emitted when a Sodium Wallet is created for a user
    event WalletCreated(address indexed owner, address wallet);

    /* ===== METHODS ===== */

    function createWallet(address borrower) external returns (address);
}

// File contracts/libraries/Types.sol

pragma solidity ^0.8.0;

// A library containing structs and enums used on the Sodium Protocol

library Types {
    // Indicates type of collateral
    enum Collateral {
        ERC721,
        ERC1155
    }

    // Represents an ongoing loan
    struct Loan {
        // Requested loan length
        uint256 length;
        // End of loan
        uint256 end;
        // End of potential loan auction
        uint256 auctionEnd;
        // ID of collateral
        uint256 tokenId;
        // Total funds added to the loan
        uint256 liquidity;
        // Loan lenders in lending queue order
        address[] lenders;
        // In-order principals of lenders in `lenders`
        uint256[] principals;
        // In-order APRs of said prinicpals
        uint256[] APRs;
        // Timestamps at which  contributions of lenders in `lenders` were added
        uint256[] timestamps;
        // Address of collateral's contract
        address tokenAddress;
        // The currency the loan is made in
        address currency;
        // The loan's borrower
        address borrower;
        // Address holding loan collateral
        address wallet;
        // Debt repaid by borrower
        uint256 repayment;
        // Indicates type of collateral
        Collateral collateralType;
    }

    // Encapsulates information required for a lender's meta-transaction
    struct MetaContribution {
        // Signature - used to infer meta-lender's address
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Total funds the meta-lender has offered
        uint256 available;
        // The APR the meta-lender has offered said funds at
        uint256 APR;
        // The limit up to which the funds can be used to increase loan liquidity
        uint256 liquidityLimit;
        // Lender's loan-specific meta-contribution nonce
        uint256 nonce;
    }

    // Encapsulates a collateral auction's state
    struct Auction {
        // Address of current highest bidder
        address bidder;
        // Their non-boosted bid => equal to the actual funds they sent
        uint256 rawBid;
        // Their boosted bid
        uint256 effectiveBid;
    }

    // Parameters for a loan request via Sodium Core
    struct RequestParams {
        // The requested amount
        uint256 amount;
        // Their starting APR
        uint256 APR;
        // Requested length of the loan
        uint256 length;
        // Loan currency - zero address used for an ETH loan
        address currency;
    }

    // Contains information needed to validate that a set of meta-contributions have not been withdrawn
    struct NoWithdrawalSignature {
        // The deadline up to which the signature is valid
        uint256 deadline;
        // Signature
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Used to identify a token (ERC721) or type of token
    struct Token {
        // Address of the token's contract
        address tokenAddress;
        // ID of the token
        uint256 tokenId;
    }
}

// File contracts/interfaces/ISodiumWallet.sol

pragma solidity ^0.8.0;

interface ISodiumWallet {
    function initialize(
        address _owner,
        address _core,
        address _registry
    ) external;

    function execute(
        address[] calldata contractAddresses,
        bytes[] memory calldatas,
        uint256[] calldata values
    ) external payable;

    function transferERC721(
        address recipient,
        address tokenAddress,
        uint256 tokenId
    ) external;

    function transferERC1155(
        address recipient,
        address tokenAddress,
        uint256 tokenId
    ) external;

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);
}

// File contracts/interfaces/ISodiumCore.sol

pragma solidity ^0.8.0;

interface ISodiumCore {
    /* ===== EVENTS ===== */

    // Emitted when a user requests a loan by sending collateral to the Core
    event RequestMade(
        uint256 indexed id,
        address indexed requester,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 APR,
        uint256 length,
        address currency
    );

    // Emitted when a borrower cancels their request before adding any funds and converting it to an active loan
    event RequestWithdrawn(uint256 indexed requestId);

    // Emitted when a meta-lenders funds are added to a loan
    // One emitted each meta-contribution => can be multiple in a single call
    event FundsAdded(
        uint256 indexed loanId,
        address lender,
        uint256 amount,
        uint256 APR
    );

    // Emitted when a borrower repays an amount of loan debt to a lender
    event RepaymentMade(
        uint256 indexed loanId,
        address indexed lender,
        uint256 principal,
        uint256 interest,
        uint256 fee
    );

    // Emitted when a bid is made on an auction for liquidated collateral
    event BidMade(
        uint256 indexed id,
        address indexed bidder,
        uint256 bid,
        uint256 index
    );

    // Emitted when a user instant-purchases auctioned collateral
    event PurchaseMade(uint256 indexed id);

    // Emitted when auction proceeds reimburse a lender
    // Seperate event to `RepaymentMade` as no fees are collected in auction
    event AuctionRepaymentMade(
        uint256 indexed auctionId,
        address indexed lender,
        uint256 amount
    );

    // Emitted when a collateral auction is resolved.
    event AuctionConcluded(uint256 indexed id, address indexed winner);

    // Emitted when protocol parameter setters are called by Core owner
    event FeeUpdated(uint256 feeNumerator, uint256 feeDenominator);
    event AuctionLengthUpdated(uint256 auctionLength);
    event WalletFactoryUpdated(address walletFactory);
    event TreasuryUpdated(address treasury);
    event MetaContributionValidatorUpdated(address validator);

    /* ===== METHODS ===== */

    function initialize(
        string calldata name,
        string calldata version,
        uint256 numerator,
        uint256 denominator,
        uint256 length,
        address factory,
        address payable treasury,
        address validator
    ) external;

    function onERC721Received(
        address requester,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155Received(
        address requester,
        address,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function withdraw(uint256 requestId) external;

    function borrowETH(
        uint256 loanId,
        Types.MetaContribution[] calldata metaContributions,
        uint256[] calldata amounts,
        Types.NoWithdrawalSignature calldata noWithdrawalSignature
    ) external;

    function borrowERC20(
        uint256 loanId,
        Types.MetaContribution[] calldata metaContributions,
        uint256[] calldata amounts,
        Types.NoWithdrawalSignature calldata noWithdrawalSignature
    ) external;

    function repayETH(uint256 loanId) external payable;

    function repayERC20(uint256 loanId, uint256 amount) external;

    function bidETH(uint256 auctionId, uint256 index) external payable;

    function bidERC20(
        uint256 auctionId,
        uint256 amount,
        uint256 index
    ) external;

    function purchaseETH(uint256 auctionId) external payable;

    function purchaseERC20(uint256 auctionId) external;

    function resolveAuctionETH(uint256 auctionId) external;

    function resolveAuctionERC20(uint256 auctionId) external;

    // function getLoan(uint256 loanId) external view returns (Types.Loan memory);

    // function getWallet(address borrower) external view returns (address);

    // function getAuction(uint256 auctionId)
    //     external
    //     view
    //     returns (Types.Auction memory);

    function setFee(uint256 numerator, uint256 denominator) external;

    function setAuctionLength(uint256 length) external;

    function setWalletFactory(address factory) external;

    function setTreasury(address payable treasury) external;

    function setValidator(address validator) external;
}

// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.0;

interface IWETH is IERC20Upgradeable {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// File contracts/libraries/Maths.sol

pragma solidity ^0.8.0;

// A library for performing calculations used by the Sodium Protocol

// Units:
// - Loan durations are in seconds
// - APRs are in basis points

// Interest
// - Meta-lenders earn interest on the bigger of the following:
//   - the loan's duration
//   - half the borrowers requested loan length
// - Interest increases discretely every hour

// Fees:
// - There are two components to protocol fees:
//   - The borrower pays a fee, equal to a fraction of the interest earned, on top of that interest
//   - This amount is also taken from the interest itself
// - Fraction is feeNumerator / feeDenominator

library Maths {
    // Calculate the interest and fee required for a given APR, principal, and duration
    function calculateInterestAndFee(
        uint256 principal,
        uint256 APR,
        uint256 duration,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) internal pure returns (uint256, uint256) {
        // Interest increases every hour
        duration = (duration / 3600) * 3600;

        uint256 baseInterest = (principal * APR * duration) / 3650000 days;

        uint256 baseFee = (baseInterest * feeNumerator) / feeDenominator;

        return (baseInterest - baseFee, baseFee * 2);
    }

    function principalPlusInterest(
        uint256 principal,
        uint256 APR,
        uint256 duration
    ) internal pure returns (uint256) {
        // Interest increases every hour
        duration = (duration / 3600) * 3600;

        uint256 interest = (principal * APR * duration) / 3650000 days;

        return principal + interest;
    }

    // Calculates the maximum principal reduction for an input amount of available funds
    function partialPaymentParameters(
        uint256 available,
        uint256 APR,
        uint256 duration,
        uint256 feeNumerator,
        uint256 feeDenominator
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Obtain max principal reduction via  => available funds = max reduction + corresponding interest + corresponding fee
        uint256 reductionNumerator = available * feeDenominator * 3650000 days;

        uint256 reductionDenominator = (feeDenominator * 3650000 days) +
            (duration * APR * (feeNumerator + feeDenominator));

        uint256 reduction = reductionNumerator / reductionDenominator;

        // Interest increases every hour
        duration = (duration / 3600) * 3600;

        uint256 baseInterest = (reduction * APR * duration) / 3650000 days;

        uint256 baseFee = (baseInterest * feeNumerator) / feeDenominator;

        return (reduction, baseInterest - baseFee, baseFee * 2);
    }
}

// File contracts/SodiumCore.sol

pragma solidity ^0.8.0;

/// @title Sodium Core Contract
/// @notice Manages loans and collateral auctions on the Sodium Protocol
/// @dev WARNING! This contract is vulnerable to ERC20-transfer reentrancy => this is to save gas
contract SodiumCore is
    ISodiumCore,
    Initializable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /* ===== LIBRARIES ===== */

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ==================== STATE ==================== */

    /* ===== ADDRESSES ===== */

    // Used to deploy new Sodium Wallets
    ISodiumWalletFactory public sodiumWalletFactory;

    // The WETH contract used during ETH-loan-related functionality
    // See https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
    IWETH private constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // The address to which fees collected by the protocol are sent
    address payable public sodiumTreasury;

    // Validates meta-contributions as not having been withdrawn by meta-lenders
    address public metaContributionValidator;

    /* ===== PROTOCOL PARAMETERS ===== */

    // The protocol's fee is stored as a fraction
    uint256 public feeNumerator;
    uint256 public feeDenominator;

    // The length of the protocol's collateral auction in seconds
    uint256 public auctionLength;

    /* ===== PROTOCOL STATE ===== */

    // Maps a user to their Sodium Wallet
    mapping(address => address) private wallets;

    // Maps a loan's ID to its state-encapsulating `Loan` struct
    mapping(uint256 => Types.Loan) private loans;

    // Maps an auction's ID to its state-encapsulating `Auction` struct
    mapping(uint256 => Types.Auction) private auctions;

    /* ===== NONCES ===== */

    /// @notice Get a meta-lender's meta-contibution nonce
    mapping(uint256 => mapping(address => uint256)) public nonces;

    // Used to create distinct IDs for same-collateral ERC1155 loans
    uint256 private ERC1155Nonce;

    // EIP-712 type hash for meta-contributions
    bytes32 private constant META_CONTRIBUTION_TYPE_HASH =
        keccak256(
            "MetaContribution(uint256 id,uint256 available,uint256 APR,uint256 liquidityLimit,uint256 nonce)"
        );

    /* ===== MODIFIERS ===== */

    // Reverts unless in-auction
    modifier duringAuctionOnly(uint256 auctionId) {
        require(
            block.timestamp > loans[auctionId].end &&
                block.timestamp < loans[auctionId].auctionEnd,
            "19"
        );
        _;
    }

    /* ===== INITIALIZER ===== */

    /// @notice Proxy initializer function
    /// @param name The contract name used to verify EIP-712 meta-contribution signatures
    /// @param version The contract version used to verify EIP-712 meta-contribution signatures
    function initialize(
        string calldata name,
        string calldata version,
        uint256 numerator,
        uint256 denominator,
        uint256 length,
        address factory,
        address payable treasury,
        address validator
    ) public override initializer {
        __EIP712_init(name, version);
        __Ownable_init();
        feeNumerator = numerator;
        feeDenominator = denominator;
        auctionLength = length;
        sodiumWalletFactory = ISodiumWalletFactory(factory);
        sodiumTreasury = treasury;
        metaContributionValidator = validator;
    }

    /* ===== RECEIVE ===== */

    // Allows core to unwrap WETH
    receive() external payable {}

    /* ==================== LOANS ==================== */

    /* ===== MAKE REQUESTS ===== */

    /// @notice Initiates a loan request when called by an ERC721 contract during a `safeTransferFrom` call
    /// @param data Request parameters ABI-encoded into a `RequestParams` struct
    function onERC721Received(
        address requester,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Block timestamp included in ID hash to ensure subsequent same-collateral loans have distinct IDs
        uint256 requestId = uint256(
            keccak256(abi.encode(tokenId, msg.sender, block.timestamp))
        );

        // Decode request information and execute request logic
        address wallet = _executeRequest(
            abi.decode(data, (Types.RequestParams)),
            requestId,
            tokenId,
            requester,
            msg.sender,
            Types.Collateral.ERC721
        );

        // Transfer collateral to wallet
        IERC721Upgradeable(msg.sender).transferFrom(
            address(this),
            wallet,
            tokenId
        );

        return this.onERC721Received.selector;
    }

    /// @notice Initiates a loan request when called by an ERC1155 contract during a `safeTransferFrom` call
    /// @param data Request parameters ABI-encoded into a `RequestParams` struct
    function onERC1155Received(
        address requester,
        address,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(value == 1, "2");

        // Nonce included in hash to allow distinct IDs for same-collateral loans
        uint256 requestId = uint256(
            keccak256(abi.encode(tokenId, msg.sender, ERC1155Nonce))
        );

        // Increment nonce
        ERC1155Nonce++;

        // Decode request information and execute request logic
        address wallet = _executeRequest(
            abi.decode(data, (Types.RequestParams)),
            requestId,
            tokenId,
            requester,
            msg.sender,
            Types.Collateral.ERC1155
        );

        // Transfer collateral to wallet
        IERC1155Upgradeable(msg.sender).safeTransferFrom(
            address(this),
            wallet,
            tokenId,
            1,
            ""
        );

        return this.onERC1155Received.selector;
    }

    /* ===== CANCEL REQUESTS ===== */

    /// @notice Used by borrower to withdraw collateral from loan requests that have not been converted into active loans
    /// @param requestId The ID of the target request
    function withdraw(uint256 requestId) external override {
        // Check no unpaid lenders
        require(loans[requestId].lenders.length == 0, "5");

        // Ensure borrower calling
        address borrower = loans[requestId].borrower;
        require(msg.sender == borrower, "6");

        // Transfer collateral to borrower
        _transferCollateral(
            loans[requestId].tokenAddress,
            loans[requestId].tokenId,
            loans[requestId].wallet,
            borrower,
            loans[requestId].collateralType
        );

        delete loans[requestId];

        emit RequestWithdrawn(requestId);
    }

    /* ===== ADD META-CONTRIBUTIONS ===== */

    /// @notice Used by borrower to add funds to an ETH request/loan
    /// @dev Unwraps meta-lender WETH then sends resulting ETH to borrower
    /// @param id The ID of the target request/loan to which the meta-contributions are to be added
    /// @param metaContributions One or more signed lender meta-contributions
    /// @param amounts The amount of each meta-contribution's available funds that are to be added to the loan
    /// @param noWithdrawalSignature A signature of the meta-contributions that indicates they have not been withdrawn
    function borrowETH(
        uint256 id,
        Types.MetaContribution[] calldata metaContributions,
        uint256[] calldata amounts,
        Types.NoWithdrawalSignature calldata noWithdrawalSignature
    ) external override {
        Types.Loan storage loan = loans[id];

        require(loan.currency == address(0), "3");

        address borrower = _preAdditionLogic(
            loan,
            metaContributions,
            noWithdrawalSignature
        );

        // Keep track of liquidity using stack => initialise as current value
        uint256 liquidity = loan.liquidity;

        // Track total ETH added (sum of amounts)
        uint256 total = 0;

        // Iterate over meta-contributions in order
        for (uint256 i = 0; i < metaContributions.length; i++) {
            address lender = _processMetaContribution(
                id,
                amounts[i],
                liquidity,
                metaContributions[i]
            );

            // Transfer WETH to contract
            WETH.transferFrom(lender, address(this), amounts[i]);

            // Update tracked quantities
            total += amounts[i];
            liquidity += amounts[i];
        }

        // Convert all lender WETH into ETH
        WETH.withdraw(total);

        // Save loan's final liquidity
        loan.liquidity = liquidity;

        // Send ETH after state changes to avoid reentrancy
        payable(borrower).transfer(total);
    }

    /// @notice Used by borrower to add funds to an ERC20 loan
    /// @dev Transfers core-approved meta-lender tokens to the borrower
    /// @param id The ID of the target request/loan to which the meta-contributions are to be added
    /// @param metaContributions One or more signed lender meta-contributions
    /// @param amounts The amount of each meta-contribution's available funds that are to be added to the loan
    /// @param noWithdrawalSignature A signature of the meta-contributions that indicates they have not been withdrawn
    function borrowERC20(
        uint256 id,
        Types.MetaContribution[] calldata metaContributions,
        uint256[] calldata amounts,
        Types.NoWithdrawalSignature calldata noWithdrawalSignature
    ) external override {
        Types.Loan storage loan = loans[id];

        require(loan.currency != address(0), "4");

        address borrower = _preAdditionLogic(
            loan,
            metaContributions,
            noWithdrawalSignature
        );

        // Keep track of liquidity using stack
        uint256 liquidity = loan.liquidity;

        address currency = loan.currency;

        // Iterate over meta-contributions in order
        for (uint256 i = 0; i < metaContributions.length; i++) {
            address lender = _processMetaContribution(
                id,
                amounts[i],
                liquidity,
                metaContributions[i]
            );

            // Transfer funds to borrower
            IERC20Upgradeable(currency).safeTransferFrom(
                lender,
                borrower,
                amounts[i]
            );

            liquidity += amounts[i];
        }

        // Save new loan liquidity into storage
        loan.liquidity = liquidity;
    }

    /* ===== REPAY DEBT ===== */

    /// @notice Used to repay an ETH loan
    /// @dev No auth required as no gain to be made from repaying someone else's loan
    /// @dev Sent ETH (msg.value) is used for the repayment
    /// @param loanId The ID of the target loan
    function repayETH(uint256 loanId) external payable override {
        // Ensure ETH loan being repaid
        require(loans[loanId].currency == address(0), "3");

        // Wrap sent ETH to use for repayment
        WETH.deposit{value: msg.value}();

        // Set `from` to this contract as it owns the WETH
        _executeRepayment(loanId, msg.value, address(WETH), address(this));
    }

    /// @notice Used to repay an ERC20 loan
    /// @dev No auth required as no gain to be made from repaying someone else's loan
    /// @dev The Core must be granted approval over the tokens used for repayment
    /// @param loanId The ID of the target loan
    /// @param amount The amount of tokens to repay
    function repayERC20(uint256 loanId, uint256 amount) external override {
        _executeRepayment(loanId, amount, loans[loanId].currency, msg.sender);
    }

    /* ==================== AUCTION ==================== */

    /* ===== BID ===== */

    /// @notice Make an ETH bid in a collateral auction
    /// @dev WARNING: Do not bid higher than purchase amount => purchase instead
    /// @dev Set index parameter to the length of the lending queue if no boost available
    /// @param auctionId The ID of the target auction
    /// @param index The index of the caller in the lending queue => requests a boost
    function bidETH(uint256 auctionId, uint256 index)
        external
        payable
        override
        duringAuctionOnly(auctionId)
    {
        require(loans[auctionId].currency == address(0), "3");

        address previousBidder = auctions[auctionId].bidder;
        uint256 previousRawBid = auctions[auctionId].rawBid;

        _executeBid(auctionId, msg.value, index);

        // Repay previous bidder if needed
        if (previousBidder != address(0)) {
            _nonBlockingTransfer(previousBidder, previousRawBid);
        }
    }

    /// @notice Make an bid of some ERC20 tokens for some auctioned collateral
    /// @dev WARNING! Do not bid higher than purchase amount => purchase instead
    /// @dev Set index parameter to the length of the lending queue if no boost available
    /// @param auctionId The ID of the target auction
    /// @param index The index of the caller in the lending queue => requests a boost
    /// @param amount The amount of tokens to bid
    /// @param index The index of the caller in the lending queue => requests a boost
    function bidERC20(
        uint256 auctionId,
        uint256 amount,
        uint256 index
    ) external override duringAuctionOnly(auctionId) {
        address currency = loans[auctionId].currency;
        address bidder = auctions[auctionId].bidder;

        // Repay previous bidder if needed
        if (bidder != address(0)) {
            IERC20Upgradeable(currency).safeTransfer(
                bidder,
                auctions[auctionId].rawBid
            );
        }

        // Transfer bid to the Core
        // Call will fail if to zero address (cant't be used on ETH loans)
        IERC20Upgradeable(currency).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        _executeBid(auctionId, amount, index);
    }

    /* ===== PURCHASE ===== */

    /// @notice Purchase in-auction collateral instantly with ETH
    /// @dev Requires settling all unpaid lender debts plus any repayments the borrower has made
    /// @dev If the caller is an unpaid lender, a borrower who has repaid, or the most recent bidder, a purchase discount will be applied accordingly
    /// @param auctionId The ID of the collateral's auction
    function purchaseETH(uint256 auctionId)
        external
        payable
        override
        duringAuctionOnly(auctionId)
        nonReentrant
    {
        Types.Loan storage loan = loans[auctionId];
        Types.Auction memory auction = auctions[auctionId];

        require(loan.currency == address(0), "3");

        // Track funds remaing to carry out payments required for purchase
        uint256 remainingFunds = msg.value;

        if (msg.sender == auction.bidder) {
            // Add raw bid to purchase funds if bidder is the caller
            remainingFunds += auction.rawBid;
        } else {
            // Otherwise pay back bidder
            _nonBlockingTransfer(auction.bidder, auction.rawBid);
        }

        address borrower = loan.borrower;
        uint256 repayment = loan.repayment;

        if (borrower != msg.sender && repayment != 0) {
            // Pay back borrower's repayment
            _nonBlockingTransfer(borrower, repayment);

            // Update remaining funds
            remainingFunds -= repayment;
        }

        // Wrap remaining funds to pay meta-lenders back in WETH
        WETH.deposit{value: remainingFunds}();

        uint256 numberOfLenders = loan.lenders.length;

        for (uint256 i = 0; i < numberOfLenders; i++) {
            address lender = loan.lenders[i];

            // Repay lender if they are not the caller
            if (lender != msg.sender) {
                // Calculate total owed to lender
                uint256 owed = Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.end - loan.timestamps[i]
                );

                // This will revert if insufficient funds sent to repay lenders
                remainingFunds -= owed;

                // Pay lender fully
                WETH.transfer(lender, owed);

                emit AuctionRepaymentMade(auctionId, lender, owed);
            }
        }

        _auctionCleanup(auctionId, msg.sender);

        emit PurchaseMade(auctionId);
    }

    /// @notice Purchase in-auction collateral instantly with ERC20
    /// @dev Requires settling all unpaid lender debts plus any repayments the borrower has made
    /// @dev If the caller is an unpaid lender, a borrower who has repaid, or the most recent bidder, a purchase discount will be applied accordingly
    /// @dev Tokens used for purchase must be approved to the core before calling
    /// @param auctionId The ID of the collateral's auction
    function purchaseERC20(uint256 auctionId)
        external
        override
        duringAuctionOnly(auctionId)
    {
        Types.Auction memory auction = auctions[auctionId];
        Types.Loan storage loan = loans[auctionId];

        address currency = loan.currency;
        require(currency != address(0), "4");

        if (auction.bidder != address(0)) {
            // Pay back bidder
            // Funds are returned before paying other debt if bidder is the caller
            IERC20Upgradeable(currency).safeTransfer(
                auction.bidder,
                auction.rawBid
            );
        }

        address borrower = loan.borrower;
        uint256 repayment = loan.repayment;

        if (borrower != msg.sender && repayment != 0) {
            // Pay back borrower if not the caller => will fail if to zero address
            IERC20Upgradeable(currency).safeTransferFrom(
                msg.sender,
                borrower,
                repayment
            );
        }

        uint256 numberOfLenders = loan.lenders.length;

        for (uint256 i = 0; i < numberOfLenders; i++) {
            address lender = loan.lenders[i];

            // Repay lender if they are not the caller
            if (lender != msg.sender) {
                // Calculate total owed to lender
                uint256 owed = Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.end - loan.timestamps[i]
                );

                // Pay lender fully
                IERC20Upgradeable(currency).safeTransferFrom(
                    msg.sender,
                    lender,
                    owed
                );

                emit AuctionRepaymentMade(auctionId, lender, owed);
            }
        }

        _auctionCleanup(auctionId, msg.sender);

        emit PurchaseMade(auctionId);
    }

    /* ===== RESOLVE AUCTION ===== */

    /// @notice Resolve an ETH-auction after it has finished
    /// @dev Pays back debts using WETH and sends collateral to the auction winner
    /// @param auctionId The ID of the finished auction
    function resolveAuctionETH(uint256 auctionId) external override {
        require(loans[auctionId].currency == address(0), "3");

        WETH.deposit{value: auctions[auctionId].rawBid}();

        _resolveAuction(auctionId, address(WETH));
    }

    /// @notice Resolve an ERC20-auction after it has finished
    /// @dev Pays back debts using WETH and sends collateral to the auction winner
    /// @param auctionId The ID of the finished auction
    function resolveAuctionERC20(uint256 auctionId) external override {
        address currency = loans[auctionId].currency;

        require(currency != address(0), "4");

        _resolveAuction(auctionId, currency);
    }

    // /* ==================== GETTERS ==================== */

    // These are used for testing, but are not required for deployment

    // function getLoan(uint256 loanId) public view returns (Types.Loan memory) {
    //     return loans[loanId];
    // }

    // function getWallet(address borrower) public view returns (address) {
    //     return wallets[borrower];
    // }

    // function getAuction(uint256 auctionId)
    //     public
    //     view
    //     returns (Types.Auction memory)
    // {
    //     return auctions[auctionId];
    // }

    /* ==================== ADMIN ==================== */

    function setFee(uint256 numerator, uint256 denominator)
        external
        override
        onlyOwner
    {
        feeNumerator = numerator;
        feeDenominator = denominator;
        emit FeeUpdated(numerator, denominator);
    }

    function setAuctionLength(uint256 length) external override onlyOwner {
        auctionLength = length;
        emit AuctionLengthUpdated(length);
    }

    function setWalletFactory(address factory) external override onlyOwner {
        sodiumWalletFactory = ISodiumWalletFactory(factory);
        emit WalletFactoryUpdated(factory);
    }

    function setTreasury(address payable treasury) external override onlyOwner {
        sodiumTreasury = treasury;
        emit TreasuryUpdated(treasury);
    }

    function setValidator(address validator) external override onlyOwner {
        metaContributionValidator = validator;
        emit MetaContributionValidatorUpdated(validator);
    }

    /* ==================== INTERNAL ==================== */

    // Performs shared request logic:
    // - creates a new Sodium Wallet for the requester if they do not have one already
    // - saves request information in a `Loan` struct
    function _executeRequest(
        Types.RequestParams memory requestParams,
        uint256 requestId,
        uint256 tokenId,
        address requester,
        address tokenAddress,
        Types.Collateral collateralType
    ) internal returns (address) {
        address wallet = wallets[requester];

        // If user's wallet is zero address => their first loan => create a new wallet
        if (wallet == address(0)) {
            // Deploy
            wallet = sodiumWalletFactory.createWallet(requester);

            // Register
            wallets[requester] = wallet;
        }

        // Save request details
        loans[requestId] = Types.Loan(
            requestParams.length,
            0,
            0,
            tokenId,
            0,
            new address[](0),
            new uint256[](0),
            new uint256[](0),
            new uint256[](0),
            tokenAddress,
            requestParams.currency,
            requester,
            wallet,
            0,
            collateralType
        );

        // Log request details
        emit RequestMade(
            requestId,
            requester,
            tokenAddress,
            tokenId,
            requestParams.amount,
            requestParams.APR,
            requestParams.length,
            requestParams.currency
        );

        return wallet;
    }

    // Performs shared pre-fund addition logic:
    // - checks caller is borrower
    // - sets loan end if first time funds are added
    // - ensures auction has not started
    // - checks meta-contributions have not been recinded using `noWithdrawalSignature`
    function _preAdditionLogic(
        Types.Loan storage loan,
        Types.MetaContribution[] calldata metaContributions,
        Types.NoWithdrawalSignature calldata noWithdrawalSignature
    ) internal returns (address) {
        address borrower = loan.borrower;

        require(msg.sender == borrower, "6");

        if (loan.lenders.length == 0) {
            // Set end of loan if it is the first addition
            uint256 end = loan.length + block.timestamp;

            loan.end = end;

            // Fix loan's auction length at time of loan start
            loan.auctionEnd = end + auctionLength;
        } else {
            // Check that loan is not over (in auction)
            require(block.timestamp < loan.end, "14");
        }

        // Nonce in metaContributions ensures no replayability of signature
        bytes32 hash = keccak256(
            abi.encode(noWithdrawalSignature.deadline, metaContributions)
        );

        // Load signed message
        bytes32 signed = ECDSAUpgradeable.toEthSignedMessageHash(hash);

        // Determine signer
        address signer = ECDSAUpgradeable.recover(
            signed,
            noWithdrawalSignature.v,
            noWithdrawalSignature.r,
            noWithdrawalSignature.s
        );

        // Get assurance from validator that meta-contributions are non-withdrawn
        require(signer == metaContributionValidator, "7");

        require(block.timestamp <= noWithdrawalSignature.deadline, "8");

        return borrower;
    }

    // Verifies and executes a meta-contribution:
    // - checks meta-lender has offered sufficient funds
    // - checks meta-lender's liquidity limit is not surpassed
    // - derives lender from signature
    function _processMetaContribution(
        uint256 id,
        uint256 amount,
        uint256 currentLiquidity,
        Types.MetaContribution calldata contribution
    ) internal returns (address) {
        require(amount <= contribution.available, "9");

        require(amount + currentLiquidity <= contribution.liquidityLimit, "10");

        // Calculate lender's signed EIP712 message
        bytes32 hashStruct = keccak256(
            abi.encode(
                META_CONTRIBUTION_TYPE_HASH,
                id,
                contribution.available,
                contribution.APR,
                contribution.liquidityLimit,
                contribution.nonce
            )
        );
        bytes32 digest = _hashTypedDataV4(hashStruct);

        // Assume signer is lender
        address lender = ECDSAUpgradeable.recover(
            digest,
            contribution.v,
            contribution.r,
            contribution.s
        );

        // Avoid meta-contribution replay via lender nonce
        require(contribution.nonce == nonces[id][lender], "11");
        nonces[id][lender]++;

        // Update loan state
        loans[id].principals.push(amount);
        loans[id].lenders.push(lender);
        loans[id].APRs.push(contribution.APR);
        loans[id].timestamps.push(block.timestamp);

        emit FundsAdded(id, lender, amount, contribution.APR);

        return lender;
    }

    // Performs shared repayment logic:
    // - checks loan is ongoing
    // - pays back lenders from the top of the lending queue (loan.lenders)
    // - returns collateral if full repayment
    function _executeRepayment(
        uint256 loanId,
        uint256 amount,
        address currency,
        address from
    ) internal {
        Types.Loan storage loan = loans[loanId];

        // For front end convenience
        require(loan.borrower != address(0), "13");

        // Can only repay an active loan
        require(block.timestamp < loan.end, "14");

        // Track funds remaining for repayment
        uint256 remainingFunds = amount;

        // Borrowers must pay interest on at least half the requested loan length
        uint256 minimumDuration = loan.length / 2;

        // Iterate through lenders from top of lending queue and pay them back
        for (uint256 i = loan.lenders.length; 0 < i; i--) {
            uint256 principal = loan.principals[i - 1];

            // // Borrowers must pay interest on at least half the requested loan length
            // uint256 minimumDuration = loan.length / 2;

            uint256 timePassed = block.timestamp - loan.timestamps[i - 1];

            uint256 effectiveLoanDuration = timePassed > minimumDuration
                ? timePassed
                : minimumDuration;

            // Calculate outstanding interest and fee
            (uint256 interest, uint256 fee) = Maths.calculateInterestAndFee(
                principal,
                loan.APRs[i - 1],
                effectiveLoanDuration,
                feeNumerator,
                feeDenominator
            );

            address lender = loan.lenders[i - 1];

            // Partial vs complete lender repayment
            if (remainingFunds < principal + interest + fee) {
                // Get partial payment parameters
                (principal, interest, fee) = Maths.partialPaymentParameters(
                    remainingFunds,
                    loan.APRs[i - 1],
                    effectiveLoanDuration,
                    feeNumerator,
                    feeDenominator
                );

                // Update the outstanding principal of the debt owed to the lender
                loan.principals[i - 1] -= principal;

                // Ensure loop termination
                i = 1;
            } else if (remainingFunds == principal + interest + fee) {
                // Complete repayment of lender using all remaining funds
                loan.lenders.pop();

                // Ensure loop termination
                i = 1;
            } else {
                // Complete repayment with funds left over
                loan.lenders.pop();
            }

            // Repay lender
            IERC20Upgradeable(currency).safeTransferFrom(
                from,
                lender,
                principal + interest
            );

            // Send fee
            IERC20Upgradeable(currency).safeTransferFrom(
                from,
                sodiumTreasury,
                fee
            );

            // Decreasing funds available for further repayment
            remainingFunds -= principal + interest + fee;

            emit RepaymentMade(loanId, lender, principal, interest, fee);
        }

        if (loan.lenders.length == 0) {
            // If no lender debts => return collateral
            _transferCollateral(
                loan.tokenAddress,
                loan.tokenId,
                loan.wallet,
                loan.borrower,
                loan.collateralType
            );

            delete loans[loanId];
        } else {
            // Increase overall borrower repayment by repaid amount
            loan.repayment += amount;
        }
    }

    // Performs shared bid logic:
    // - attempts to apply boost if lender index passed
    // - checks effective bid is greater than previous
    function _executeBid(
        uint256 auctionId,
        uint256 amount,
        uint256 index
    ) internal {
        Types.Loan storage loan = loans[auctionId];
        Types.Auction storage auction = auctions[auctionId];

        // Save raw bid pre-boost
        auction.rawBid = amount;

        // Boost bid if lender index entered
        if (index != loan.lenders.length) {
            // Check caller is lender at index
            require(msg.sender == loan.lenders[index], "15");

            // Calculate starting boundary of lender liquidity
            uint256 lenderLiquidityStart = 0;
            for (uint256 i = 0; i < index; i++) {
                lenderLiquidityStart += Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.end - loan.timestamps[i]
                );
            }

            // Boost bid with loaned lender liqudity
            if (amount >= lenderLiquidityStart) {
                amount += Maths.principalPlusInterest(
                    loan.principals[index],
                    loan.APRs[index],
                    loan.end - loan.timestamps[index]
                );
            }
        }

        // Check post-boost bid is greater than previous
        require(auction.effectiveBid < amount, "16");

        auction.effectiveBid = amount;
        auction.bidder = msg.sender;

        emit BidMade(auctionId, msg.sender, amount, index);
    }

    // Performs shared auction-resolution functionality:
    // - ensures loan's auction is over
    // - pays lenders from the bottom of the lending queue (loan.lenders)
    // - repays any borrower repayment with any funds remaining after lender repayment
    // - transfers collateral to winner (via _auctionCleanup)
    function _resolveAuction(uint256 auctionId, address currency) internal {
        Types.Loan storage loan = loans[auctionId];

        uint256 numberOfLenders = loan.lenders.length;

        // Check loan has lender debts => ensures loan.end is non-zero
        require(numberOfLenders != 0, "17");

        // Check auction has finished
        require(loan.auctionEnd < block.timestamp, "18");

        Types.Auction memory auction = auctions[auctionId];

        // Pay off all possible lenders with bid => start at bottom of lending queue
        for (uint256 i = 0; i < numberOfLenders; i++) {
            address lender = loan.lenders[i];

            // Repay lender if they are not the caller
            if (lender != msg.sender) {
                // Calculate total owed to lender
                uint256 owed = Maths.principalPlusInterest(
                    loan.principals[i],
                    loan.APRs[i],
                    loan.end - loan.timestamps[i]
                );

                if (auction.rawBid <= owed) {
                    // Pay lender with remaining
                    IERC20Upgradeable(currency).safeTransfer(
                        lender,
                        auction.rawBid
                    );

                    auction.rawBid = 0;

                    emit AuctionRepaymentMade(
                        auctionId,
                        lender,
                        auction.rawBid
                    );

                    // Stop payment iteration as no more available funds
                    break;
                } else {
                    // Pay lender fully
                    IERC20Upgradeable(currency).safeTransfer(lender, owed);

                    // Update remaining funds
                    auction.rawBid -= owed;

                    emit AuctionRepaymentMade(auctionId, lender, owed);
                }
            }
        }

        // Send remaining funds to borrower to compensate for any loan repayment they have made
        if (auction.rawBid != 0) {
            IERC20Upgradeable(currency).safeTransfer(
                loan.borrower,
                auction.rawBid
            );
        }

        // Set winner to first lender if no bids made
        address winner = auction.bidder == address(0)
            ? loan.lenders[0]
            : auction.bidder;

        _auctionCleanup(auctionId, winner);

        emit AuctionConcluded(auctionId, winner);
    }

    // Performs end-of-purchase logic that is shared between ETH & ERC20 purchases
    function _auctionCleanup(uint256 auctionId, address winner) internal {
        // Send collateral to purchaser
        _transferCollateral(
            loans[auctionId].tokenAddress,
            loans[auctionId].tokenId,
            loans[auctionId].wallet,
            winner,
            loans[auctionId].collateralType
        );

        delete auctions[auctionId];

        delete loans[auctionId];
    }

    // Transfers collateral from a sodium wallet to a recipient
    function _transferCollateral(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        Types.Collateral collateralType
    ) internal {
        if (collateralType == Types.Collateral.ERC721) {
            ISodiumWallet(from).transferERC721(to, tokenAddress, tokenId);
        } else {
            ISodiumWallet(from).transferERC1155(to, tokenAddress, tokenId);
        }
    }

    // Avoids DOS resulting from from Core ETH transfers made to contracts that don't accept ETH
    function _nonBlockingTransfer(address recipient, uint256 amount) internal {
        // Attempt to send ETH to recipient
        (bool success, ) = recipient.call{value: amount}("");

        // If repayment fails => avoid blocking and send funds to treasury
        if (!success) {
            sodiumTreasury.transfer(amount);
        }
    }

    // Contract owner is authorized to perform upgrades (Open Zep UUPS)
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}