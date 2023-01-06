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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IElement {

    struct Signature {
        uint8 signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Property {
        address propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct BatchSignedOrder {
        address maker;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 startNonce;
        address erc20Token;
        address platformFeeRecipient;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes collectionsBytes;
    }

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct Parameter {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
    }

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct Parameters {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
        bytes collections;
    }

    function buyERC721Ex(
        NFTSellOrder calldata sellOrder,
        Signature calldata signature,
        address taker,
        bytes calldata takerData
    ) external payable;

    function batchBuyERC721sEx(
        NFTSellOrder[] calldata sellOrders,
        Signature[] calldata signatures,
        address[] calldata takers,
        bytes[] calldata takerDatas,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    function buyERC1155Ex(
        ERC1155SellOrder calldata sellOrder,
        Signature calldata signature,
        address taker,
        uint128 erc1155BuyAmount,
        bytes calldata takerData
    ) external payable;

    function batchBuyERC1155sEx(
        ERC1155SellOrder[] calldata sellOrders,
        Signature[] calldata signatures,
        address[] calldata takers,
        uint128[] calldata erc1155TokenAmounts,
        bytes[] calldata takerDatas,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    function sellERC721(
        NFTBuyOrder calldata buyOrder,
        Signature calldata signature,
        uint256 erc721TokenId,
        bool unwrapNativeToken,
        bytes calldata takerData
    ) external;

    function sellERC1155(
        ERC1155BuyOrder calldata buyOrder,
        Signature calldata signature,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        bool unwrapNativeToken,
        bytes calldata takerData
    ) external;

    function fillBatchSignedERC721Order(
        Parameter calldata parameter,
        bytes calldata collections
    ) external payable;

    /// @param additional1 [96 bits(withdrawETHAmount) + 160 bits(erc20Token)]
    /// @param additional2 [8 bits(revertIfIncomplete) + 88 bits(unused) + 160 bits(royaltyFeeRecipient)]
    function fillBatchSignedERC721Orders(
        Parameters[] calldata parameters,
        uint256 additional1,
        uint256 additional2
    ) external payable;
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {BaseExchangeModule} from "./BaseExchangeModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {IElement} from "../../../interfaces/IElement.sol";

// Notes:
// - supports filling listings (both ERC721/ERC1155)
// - supports filling offers (both ERC721/ERC1155)

contract ElementModule is BaseExchangeModule {
    using SafeERC20 for IERC20;

    // --- Fields ---

    IElement public constant EXCHANGE =
        IElement(0x20F780A973856B93f63670377900C1d2a50a77c4);

    // --- Constructor ---

    constructor(address owner, address router)
        BaseModule(owner)
        BaseExchangeModule(router)
    {}

    // --- Fallback ---

    receive() external payable {}

    // --- [ERC721] Single ETH listing ---

    function acceptETHListingERC721(
        IElement.NFTSellOrder calldata order,
        IElement.Signature calldata signature,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC721Ex(
            order,
            signature,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Single ERC20 listing ---

    function acceptERC20ListingERC721(
        IElement.NFTSellOrder calldata order,
        IElement.Signature calldata signature,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC721Ex(
            order,
            signature,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Multiple ETH listings ---

    function acceptETHListingsERC721(
        IElement.NFTSellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC721sEx(
            orders,
            signatures,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Multiple ERC20 listings ---

    function acceptERC20ListingsERC721(
        IElement.NFTSellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC721sEx(
            orders,
            signatures,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Single ETH listing V2 ---

    function acceptETHListingERC721V2(
        IElement.BatchSignedOrder calldata order,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _fillBatchSignedOrder(
            order,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Single ERC20 listing V2 ---

    function acceptERC20ListingERC721V2(
        IElement.BatchSignedOrder calldata order,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _fillBatchSignedOrder(
            order,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Multiple ETH listings V2 ---

    function acceptETHListingsERC721V2(
        IElement.BatchSignedOrder[] calldata orders,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _fillBatchSignedOrders(
            orders,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC721] Multiple ERC20 listings V2 ---

    function acceptERC20ListingsERC721V2(
        IElement.BatchSignedOrder[] calldata orders,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _fillBatchSignedOrders(
            orders,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC1155] Single ETH listing ---

    function acceptETHListingERC1155(
        IElement.ERC1155SellOrder calldata order,
        IElement.Signature calldata signature,
        uint128 amount,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC1155Ex(
            order,
            signature,
            amount,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC1155] Single ERC20 listing ---

    function acceptERC20ListingERC1155(
        IElement.ERC1155SellOrder calldata order,
        IElement.Signature calldata signature,
        uint128 amount,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC1155Ex(
            order,
            signature,
            amount,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC1155] Multiple ETH listings ---

    function acceptETHListingsERC1155(
        IElement.ERC1155SellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        uint128[] calldata amounts,
        ETHListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundETHLeftover(params.refundTo)
        chargeETHFees(fees, params.amount)
    {
        // Execute fill
        _buyERC1155sEx(
            orders,
            signatures,
            amounts,
            params.fillTo,
            params.revertIfIncomplete,
            params.amount
        );
    }

    // --- [ERC1155] Multiple ERC20 listings ---

    function acceptERC20ListingsERC1155(
        IElement.ERC1155SellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        uint128[] calldata amounts,
        ERC20ListingParams calldata params,
        Fee[] calldata fees
    )
        external
        payable
        nonReentrant
        refundERC20Leftover(params.refundTo, params.token)
        chargeERC20Fees(fees, params.token, params.amount)
    {
        // Approve the exchange if needed
        _approveERC20IfNeeded(params.token, address(EXCHANGE), params.amount);

        // Execute fill
        _buyERC1155sEx(
            orders,
            signatures,
            amounts,
            params.fillTo,
            params.revertIfIncomplete,
            0
        );
    }

    // --- [ERC721] Single offer ---

    function acceptERC721Offer(
        IElement.NFTBuyOrder calldata order,
        IElement.Signature calldata signature,
        OfferParams calldata params,
        uint256 tokenId,
        Fee[] calldata fees
    ) external nonReentrant {
        // Approve the exchange if needed
        _approveERC721IfNeeded(IERC721(order.nft), address(EXCHANGE));

        // Execute fill
        try EXCHANGE.sellERC721(order, signature, tokenId, false, "") {
            // Pay fees
            uint256 feesLength = fees.length;
            for (uint256 i; i < feesLength; ) {
                Fee memory fee = fees[i];
                _sendERC20(fee.recipient, fee.amount, order.erc20Token);

                unchecked {
                    ++i;
                }
            }

            // Forward any left payment to the specified receiver
            _sendAllERC20(params.fillTo, order.erc20Token);
        } catch {
            // Revert if specified
            if (params.revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }

        // Refund any ERC721 leftover
        _sendAllERC721(params.refundTo, IERC721(order.nft), tokenId);
    }

    // --- [ERC1155] Single offer ---

    function acceptERC1155Offer(
        IElement.ERC1155BuyOrder calldata order,
        IElement.Signature calldata signature,
        uint128 amount,
        OfferParams calldata params,
        uint256 tokenId,
        Fee[] calldata fees
    ) external nonReentrant {
        // Approve the exchange if needed
        _approveERC1155IfNeeded(IERC1155(order.erc1155Token), address(EXCHANGE));

        // Execute fill
        try EXCHANGE.sellERC1155(order, signature, tokenId, amount, false, "") {
            // Pay fees
            uint256 feesLength = fees.length;
            for (uint256 i; i < feesLength; ) {
                Fee memory fee = fees[i];
                _sendERC20(fee.recipient, fee.amount, order.erc20Token);

                unchecked {
                    ++i;
                }
            }

            // Forward any left payment to the specified receiver
            _sendAllERC20(params.fillTo, order.erc20Token);
        } catch {
            // Revert if specified
            if (params.revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }

        // Refund any ERC1155 leftover
        _sendAllERC1155(params.refundTo, IERC1155(order.erc1155Token), tokenId);
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

    function _buyERC721Ex(
        IElement.NFTSellOrder calldata order,
        IElement.Signature calldata signature,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        // Execute fill
        try EXCHANGE.buyERC721Ex{value: value}(order, signature, receiver, "") {
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC721sEx(
        IElement.NFTSellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        uint256 length = orders.length;

        address[] memory takers = new address[](length);
        for (uint256 i; i < length; ) {
            takers[i] = receiver;
            unchecked { ++i; }
        }

        // Execute fill
        try EXCHANGE.batchBuyERC721sEx{value: value}(
            orders,
            signatures,
            takers,
            new bytes[](length),
            revertIfIncomplete
        ) {} catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _fillBatchSignedOrder(
        IElement.BatchSignedOrder calldata order,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        IElement.Parameter memory parameter;
        parameter.r = order.r;
        parameter.s = order.s;

        // data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
        parameter.data1 =
            (order.startNonce << 200) | (uint256(order.v) << 192) |
            (order.listingTime << 160) | uint256(uint160(order.maker));

        // data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
        uint256 taker = uint256(uint160(receiver));
        parameter.data2 =
            ((taker >> 96) << 192) | (order.expirationTime << 160) | uint256(uint160(order.erc20Token));

        // data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
        parameter.data3 =
            (taker << 160) | uint256(uint160(order.platformFeeRecipient));

        // Execute fill
        try EXCHANGE.fillBatchSignedERC721Order{value: value}(parameter, order.collectionsBytes) {
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _fillBatchSignedOrders(
        IElement.BatchSignedOrder[] calldata orders,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        uint256 length = orders.length;
        uint256 taker = uint256(uint160(receiver));

        IElement.Parameters[] memory parameters = new IElement.Parameters[](length);
        for (uint256 i; i < length; ) {
            IElement.BatchSignedOrder calldata order = orders[i];

            IElement.Parameters memory parameter;
            parameter.r = order.r;
            parameter.s = order.s;
            parameter.collections = order.collectionsBytes;

            // data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
            parameter.data1 =
                (order.startNonce << 200) | (uint256(order.v) << 192) |
                (order.listingTime << 160) | uint256(uint160(order.maker));

            // data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
            parameter.data2 =
                ((taker >> 96) << 192) | (order.expirationTime << 160) | uint256(uint160(order.erc20Token));

            // data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
            parameter.data3 =
                (taker << 160) | uint256(uint160(order.platformFeeRecipient));

            parameters[i] = parameter;
            unchecked { ++i; }
        }

        // Execute fill
        uint256 additional2 = revertIfIncomplete ? (1 << 248) : 0;
        try EXCHANGE.fillBatchSignedERC721Orders{value: value}(parameters, 0, additional2) {
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC1155Ex(
        IElement.ERC1155SellOrder calldata order,
        IElement.Signature calldata signature,
        uint128 amount,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        try EXCHANGE.buyERC1155Ex{value: value}(order, signature, receiver, amount, "") {
        } catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }

    function _buyERC1155sEx(
        IElement.ERC1155SellOrder[] calldata orders,
        IElement.Signature[] calldata signatures,
        uint128[] calldata amounts,
        address receiver,
        bool revertIfIncomplete,
        uint256 value
    ) internal {
        uint256 length = orders.length;

        address[] memory takers = new address[](length);
        for (uint256 i; i < length; ) {
            takers[i] = receiver;
            unchecked { ++i; }
        }

        // Execute fill
        try EXCHANGE.batchBuyERC1155sEx{value: value}(
            orders,
            signatures,
            takers,
            amounts,
            new bytes[](length),
            revertIfIncomplete
        ) {} catch {
            // Revert if specified
            if (revertIfIncomplete) {
                revert UnsuccessfulFill();
            }
        }
    }
}