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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
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
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity ^0.8.9;

interface ISeaport {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address recipient;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address recipient;
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    function matchAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Adapted from:
// https://github.com/boringcrypto/BoringSolidity/blob/e74c5b22a61bfbadd645e51a64aa1d33734d577a/contracts/BoringOwnable.sol
contract TwoStepOwnable {
    // --- Fields ---

    address public owner;
    address public pendingOwner;

    // --- Events ---

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // --- Errors ---

    error InvalidParams();
    error Unauthorized();

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    // --- Methods ---

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        if (msg.sender != _pendingOwner) {
            revert Unauthorized();
        }

        owner = _pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, _pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TwoStepOwnable} from "../../misc/TwoStepOwnable.sol";

// Notes:
// - includes common helpers useful for all modules

abstract contract BaseModule is TwoStepOwnable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Events ---

    event CallExecuted(address target, bytes data, uint256 value);

    // --- Errors ---

    error UnsuccessfulCall();
    error UnsuccessfulPayment();
    error WrongParams();

    // --- Constructor ---

    constructor(address owner) TwoStepOwnable(owner) {}

    // --- Owner ---

    // To be able to recover anything that gets stucked by mistake in the module,
    // we allow the owner to perform any arbitrary call. Since the goal is to be
    // stateless, this should only happen in case of mistakes. In addition, this
    // method is also useful for withdrawing any earned trading rewards.
    function makeCalls(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external payable onlyOwner nonReentrant {
        uint256 length = targets.length;
        for (uint256 i = 0; i < length; ) {
            _makeCall(targets[i], data[i], values[i]);
            emit CallExecuted(targets[i], data[i], values[i]);

            unchecked {
                ++i;
            }
        }
    }

    // --- Helpers ---

    function _sendETH(address to, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = payable(to).call{value: amount}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    function _sendERC20(
        address to,
        uint256 amount,
        IERC20 token
    ) internal {
        if (amount > 0) {
            token.safeTransfer(to, amount);
        }
    }

    function _makeCall(
        address target,
        bytes memory data,
        uint256 value
    ) internal {
        (bool success, ) = payable(target).call{value: value}(data);
        if (!success) {
            revert UnsuccessfulCall();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {BaseModule} from "../BaseModule.sol";

// Notes:
// - includes common helpers useful for all marketplace/exchange modules

abstract contract BaseExchangeModule is BaseModule {
    using SafeERC20 for IERC20;

    // --- Structs ---

    // Every fill execution has the following parameters:
    // - `fillTo`: the recipient of the received items
    // - `refundTo`: the recipient of any refunds
    // - `revertIfIncomplete`: whether to revert or skip unsuccessful fills

    // The below `ETHListingParams` and `ERC20ListingParams` rely on the
    // off-chain execution encoder to ensure that the orders filled with
    // the passed in listing parameters exactly match (eg. order amounts
    // and payment tokens match).

    struct ETHListingParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
        // The total amount of ETH to be provided when filling
        uint256 amount;
    }

    struct ERC20ListingParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
        // The ERC20 payment token for the listings
        IERC20 token;
        // The total amount of `token` to be provided when filling
        uint256 amount;
    }

    struct OfferParams {
        address fillTo;
        address refundTo;
        bool revertIfIncomplete;
    }

    struct Fee {
        address recipient;
        uint256 amount;
    }

    // --- Fields ---

    address public immutable router;

    // --- Errors ---

    error UnsuccessfulFill();

    // --- Constructor ---

    constructor(address routerAddress) {
        router = routerAddress;
    }

    // --- Modifiers ---

    modifier refundETHLeftover(address refundTo) {
        _;

        uint256 leftover = address(this).balance;
        if (leftover > 0) {
            _sendETH(refundTo, leftover);
        }
    }

    modifier refundERC20Leftover(address refundTo, IERC20 token) {
        _;

        uint256 leftover = token.balanceOf(address(this));
        if (leftover > 0) {
            token.safeTransfer(refundTo, leftover);
        }
    }

    modifier chargeETHFees(Fee[] calldata fees, uint256 amount) {
        if (fees.length == 0) {
            _;
        } else {
            uint256 balanceBefore = address(this).balance;

            _;

            uint256 length = fees.length;
            if (length > 0) {
                uint256 balanceAfter = address(this).balance;
                uint256 actualPaid = balanceBefore - balanceAfter;

                uint256 actualFee;
                for (uint256 i = 0; i < length; ) {
                    // Adjust the fee to what was actually paid
                    actualFee = (fees[i].amount * actualPaid) / amount;
                    if (actualFee > 0) {
                        _sendETH(fees[i].recipient, actualFee);
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    modifier chargeERC20Fees(
        Fee[] calldata fees,
        IERC20 token,
        uint256 amount
    ) {
        if (fees.length == 0) {
            _;
        } else {
            uint256 balanceBefore = token.balanceOf(address(this));

            _;

            uint256 length = fees.length;
            if (length > 0) {
                uint256 balanceAfter = token.balanceOf(address(this));
                uint256 actualPaid = balanceBefore - balanceAfter;

                uint256 actualFee;
                for (uint256 i = 0; i < length; ) {
                    // Adjust the fee to what was actually paid
                    actualFee = (fees[i].amount * actualPaid) / amount;
                    if (actualFee > 0) {
                        token.safeTransfer(fees[i].recipient, actualFee);
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    // --- Helpers ---

    function _sendAllETH(address to) internal {
        _sendETH(to, address(this).balance);
    }

    function _sendAllERC20(address to, IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(to, balance);
        }
    }

    function _sendAllERC721(
        address to,
        IERC721 token,
        uint256 tokenId
    ) internal {
        if (token.ownerOf(tokenId) == address(this)) {
            token.safeTransferFrom(address(this), to, tokenId);
        }
    }

    function _sendAllERC1155(
        address to,
        IERC1155 token,
        uint256 tokenId
    ) internal {
        uint256 balance = token.balanceOf(address(this), tokenId);
        if (balance > 0) {
            token.safeTransferFrom(address(this), to, tokenId, balance, "");
        }
    }

    function _approveERC20IfNeeded(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.approve(spender, amount - allowance);
        }
    }

    function _approveERC721IfNeeded(IERC721 token, address operator) internal {
        bool isApproved = token.isApprovedForAll(address(this), operator);
        if (!isApproved) {
            token.setApprovalForAll(operator, true);
        }
    }

    function _approveERC1155IfNeeded(IERC1155 token, address operator)
        internal
    {
        bool isApproved = token.isApprovedForAll(address(this), operator);
        if (!isApproved) {
            token.setApprovalForAll(operator, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {ISeaport} from "../../../interfaces/ISeaport.sol";

// Notes on the Seaport module:
// - supports filling listings (both ERC721/ERC1155)
// - supports filling offers (both ERC721/ERC1155)

contract SeaportModule is BaseExchangeModule {
    // --- Structs ---

    struct SeaportETHListingWithPrice {
        ISeaport.AdvancedOrder order;
        uint256 price;
    }

    // --- Fields ---

    ISeaport public constant EXCHANGE =
        ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- Single ETH listing ---

    function acceptETHListing(
        ISeaport.AdvancedOrder calldata order,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                params.amount
            )
            : _fillSingleOrder(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                params.amount
            );
    }

    // --- Single ERC20 listing ---

    function acceptERC20Listing(
        ISeaport.AdvancedOrder calldata order,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                0
            )
            : _fillSingleOrder(
                order,
                new ISeaport.CriteriaResolver[](0),
                params.fillTo,
                0
            );
    }

    // --- Multiple ETH listings ---

    function acceptETHListings(
        SeaportETHListingWithPrice[] calldata orders,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        uint256 length = orders.length;
        ISeaport.CriteriaResolver[]
            memory criteriaResolvers = new ISeaport.CriteriaResolver[](0);

        // Execute the fills
        if (params.revertIfIncomplete) {
            for (uint256 i; i < length; ) {
                _fillSingleOrderWithRevertIfIncomplete(
                    orders[i].order,
                    criteriaResolvers,
                    params.fillTo,
                    orders[i].price
                );

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < length; ) {
                _fillSingleOrder(
                    orders[i].order,
                    criteriaResolvers,
                    params.fillTo,
                    orders[i].price
                );

                unchecked {
                    ++i;
                }
            }
        }
    }

    // --- Multiple ERC20 listings ---

    function acceptERC20Listings(
        ISeaport.AdvancedOrder[] calldata orders,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        uint256 length = orders.length;
        ISeaport.CriteriaResolver[]
            memory criteriaResolvers = new ISeaport.CriteriaResolver[](0);

        // Execute the fills
        if (params.revertIfIncomplete) {
            for (uint256 i; i < length; ) {
                _fillSingleOrderWithRevertIfIncomplete(
                    orders[i],
                    criteriaResolvers,
                    params.fillTo,
                    0
                );

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < length; ) {
                _fillSingleOrder(
                    orders[i],
                    criteriaResolvers,
                    params.fillTo,
                    0
                );

                unchecked {
                    ++i;
                }
            }
        }
    }

    // --- Single ERC721 offer ---

    function acceptERC721Offer(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        OfferParams calldata params,
        Fee[] calldata fees
    ) external nonReentrant {
        // Extract the ERC721 token from the consideration items
        ISeaport.ConsiderationItem calldata nftItem = order
            .parameters
            .consideration[0];
        if (
            nftItem.itemType != ISeaport.ItemType.ERC721 &&
            nftItem.itemType != ISeaport.ItemType.ERC721_WITH_CRITERIA
        ) {
            revert WrongParams();
        }
        IERC721 nftToken = IERC721(nftItem.token);

        // Extract the payment token from the offer items
        ISeaport.OfferItem calldata paymentItem = order.parameters.offer[0];
        IERC20 paymentToken = IERC20(paymentItem.token);

        // Approve the exchange if needed
        _approveERC721IfNeeded(nftToken, address(EXCHANGE));
        _approveERC20IfNeeded(
            paymentToken,
            address(EXCHANGE),
            type(uint256).max
        );

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                criteriaResolvers,
                address(this),
                0
            )
            : _fillSingleOrder(order, criteriaResolvers, address(this), 0);

        uint256 identifier = nftItem.itemType == ISeaport.ItemType.ERC721
            ? nftItem.identifierOrCriteria
            : criteriaResolvers[0].identifier;

        // Pay fees
        if (nftToken.ownerOf(identifier) != address(this)) {
            // Only pay fees if the fill was successful
            uint256 feesLength = fees.length;
            for (uint256 i; i < feesLength; ) {
                Fee memory fee = fees[i];
                _sendERC20(fee.recipient, fee.amount, paymentToken);

                unchecked {
                    ++i;
                }
            }
        }

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, nftToken, identifier);

        // Forward any left payment to the specified receiver
        _sendAllERC20(params.fillTo, paymentToken);
    }

    // --- Single ERC1155 offer ---

    function acceptERC1155Offer(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        OfferParams calldata params,
        Fee[] calldata fees
    ) external nonReentrant {
        // Extract the ERC1155 token from the consideration items
        ISeaport.ConsiderationItem calldata nftItem = order
            .parameters
            .consideration[0];
        if (
            nftItem.itemType != ISeaport.ItemType.ERC1155 &&
            nftItem.itemType != ISeaport.ItemType.ERC1155_WITH_CRITERIA
        ) {
            revert WrongParams();
        }
        IERC1155 nftToken = IERC1155(nftItem.token);

        // Extract the payment token from the offer items
        ISeaport.OfferItem calldata paymentItem = order.parameters.offer[0];
        IERC20 paymentToken = IERC20(paymentItem.token);

        // Approve the exchange if needed
        _approveERC1155IfNeeded(nftToken, address(EXCHANGE));
        _approveERC20IfNeeded(
            paymentToken,
            address(EXCHANGE),
            type(uint256).max
        );

        uint256 identifier = nftItem.itemType == ISeaport.ItemType.ERC1155
            ? nftItem.identifierOrCriteria
            : criteriaResolvers[0].identifier;

        uint256 balanceBefore = nftToken.balanceOf(address(this), identifier);

        // Execute the fill
        params.revertIfIncomplete
            ? _fillSingleOrderWithRevertIfIncomplete(
                order,
                criteriaResolvers,
                address(this),
                0
            )
            : _fillSingleOrder(order, criteriaResolvers, address(this), 0);

        uint256 balanceAfter = nftToken.balanceOf(address(this), identifier);

        // Pay fees
        uint256 amountFilled = balanceBefore - balanceAfter;
        if (amountFilled > 0) {
            uint256 feesLength = fees.length;
            for (uint256 i; i < feesLength; ) {
                Fee memory fee = fees[i];
                _sendERC20(
                    fee.recipient,
                    // Only pay fees for the amount that was actually filled
                    (fee.amount * amountFilled) / order.numerator,
                    paymentToken
                );

                unchecked {
                    ++i;
                }
            }
        }

        // Refund any ERC1155 leftover
        _sendAllERC1155(params.refundTo, nftToken, identifier);

        // Forward any left payment to the specified receiver
        _sendAllERC20(params.fillTo, paymentToken);
    }

    // --- Generic handler (used for Seaport-based approvals) ---

    function matchOrders(
        ISeaport.Order[] calldata orders,
        ISeaport.Fulfillment[] calldata fulfillments
    ) external nonReentrant {
        // We don't perform any kind of input or return value validation,
        // so this function should be used with precaution - the official
        // way to use it is only for Seaport-based approvals
        EXCHANGE.matchOrders(orders, fulfillments);
    }

    // --- ERC721 / ERC1155 hooks ---

    // Single token offer acceptance can be done approval-less by using the
    // standard `safeTransferFrom` method together with specifying data for
    // further contract calls. An example:
    // `safeTransferFrom(
    //      0xWALLET,
    //      0xMODULE,
    //      TOKEN_ID,
    //      0xABI_ENCODED_ROUTER_EXECUTION_CALLDATA_FOR_OFFER_ACCEPTANCE
    // )`

    function onERC721Received(
        address, // operator,
        address, // from
        uint256, // tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // tokenId
        uint256, // amount
        bytes calldata data
    ) external returns (bytes4) {
        if (data.length > 0) {
            _makeCall(router, data, 0);
        }

        return this.onERC1155Received.selector;
    }

    // --- Internal ---

    // NOTE: In lots of cases, Seaport will not revert if fills were not
    // fully executed. An example of that is partial filling, which will
    // successfully fill any amount that is still available (including a
    // zero amount). One way to ensure that we revert in case of partial
    // executions is to check the order's filled amount before and after
    // we trigger the fill (we can use Seaport's `getOrderStatus` method
    // to check). Since this can be expensive in terms of gas, we have a
    // separate method variant to be called when reverts are enabled.

    function _fillSingleOrder(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        address receiver,
        uint256 value
    ) internal {
        // Execute the fill
        try
            EXCHANGE.fulfillAdvancedOrder{value: value}(
                order,
                criteriaResolvers,
                bytes32(0),
                receiver
            )
        {} catch {}
    }

    function _fillSingleOrderWithRevertIfIncomplete(
        ISeaport.AdvancedOrder calldata order,
        // Use `memory` instead of `calldata` to avoid `Stack too deep` errors
        ISeaport.CriteriaResolver[] memory criteriaResolvers,
        address receiver,
        uint256 value
    ) internal {
        // Cache the order's hash
        bytes32 orderHash = _getOrderHash(order.parameters);

        // Before filling, get the order's filled amount
        uint256 beforeFilledAmount = _getFilledAmount(orderHash);

        // Execute the fill
        bool success;
        try
            EXCHANGE.fulfillAdvancedOrder{value: value}(
                order,
                criteriaResolvers,
                bytes32(0),
                receiver
            )
        returns (bool fulfilled) {
            success = fulfilled;
        } catch {
            revert UnsuccessfulFill();
        }

        if (!success) {
            revert UnsuccessfulFill();
        } else {
            // After successfully filling, get the order's filled amount
            uint256 afterFilledAmount = _getFilledAmount(orderHash);

            // Make sure the amount filled as part of this call is correct
            if (afterFilledAmount - beforeFilledAmount != order.numerator) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _getOrderHash(
        // Must use `memory` instead of `calldata` for the below cast
        ISeaport.OrderParameters memory orderParameters
    ) internal view returns (bytes32 orderHash) {
        // `OrderParameters` and `OrderComponents` share the exact same
        // fields, apart from the last one, so here we simply treat the
        // `orderParameters` argument as `OrderComponents` and then set
        // the last field to the correct data
        ISeaport.OrderComponents memory orderComponents;
        assembly {
            orderComponents := orderParameters
        }
        orderComponents.counter = EXCHANGE.getCounter(orderParameters.offerer);

        orderHash = EXCHANGE.getOrderHash(orderComponents);
    }

    function _getFilledAmount(bytes32 orderHash)
        internal
        view
        returns (uint256 totalFilled)
    {
        (, , totalFilled, ) = EXCHANGE.getOrderStatus(orderHash);
    }
}