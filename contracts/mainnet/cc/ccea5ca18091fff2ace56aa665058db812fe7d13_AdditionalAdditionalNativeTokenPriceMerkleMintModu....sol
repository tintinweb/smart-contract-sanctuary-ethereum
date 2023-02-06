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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC721Collective} from "./IERC721Collective.sol";

/**
 * @title ERC165CheckerERC721Collective
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Utility allowing implementing factories, modules etc. to verify whether an
 * address implements IERC721Collective.
 */

abstract contract ERC165CheckerERC721Collective {
    /// Only proceed if collective implements IERC721Collective interface
    /// @param collective collective to check
    modifier onlyCollectiveInterface(address collective) {
        _checkCollectiveInterface(collective);
        _;
    }

    function _checkCollectiveInterface(address collective) internal view {
        require(
            ERC165Checker.supportsInterface(
                collective,
                type(IERC721Collective).interfaceId
            ),
            "ERC165CheckerERC721Collective: collective address does not implement proper interface"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ITokenEnforceable} from "src/contracts/TokenEnforceable/ITokenEnforceable.sol";
import {IERC721UpgradeableFork} from "./IERC721UpgradeableFork.sol";
import {IERC1644} from "src/contracts/utils/IERC1644.sol";

/**
 * @title IERC721CollectiveUnchained
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for only functions defined in `ERC721Collective` (excludes
 * inherited and overridden functions)
 */
interface IERC721CollectiveUnchained is IERC1644 {
    event RendererUpdated(address indexed implementation);
    event RendererLocked();

    /**
     * Initializes `ERC721Collective`.
     *
     * Emits an `Initialized` event.
     *
     * @param name_ Name of token
     * @param symbol_ Symbol of token
     * @param mintGuard_ Address of mint guard
     * @param burnGuard_ Address of burn guard
     * @param transferGuard_ Address of transfer guard
     * @param renderer_ Address of renderer
     */
    function __ERC721Collective_init(
        string memory name_,
        string memory symbol_,
        address mintGuard_,
        address burnGuard_,
        address transferGuard_,
        address renderer_
    ) external;

    /**
     * @return Number of currently-existing tokens (tokens that have been
     * minted and that have not been burned).
     */
    function totalSupply() external view returns (uint256);

    // name(), symbol(), and tokenURI() overriding ERC721UpgradeableFork
    // declared in IERC721Fork

    /**
     * @return The address of the token Renderer. The contract at this address
     * is assumed to implement the IRenderer interface.
     */
    function renderer() external view returns (address);

    /**
     * @return True iff the Renderer cannot be changed.
     */
    function rendererLocked() external view returns (bool);

    /**
     * Update the address of the token Renderer. The contract at the passed-in
     * address is assumed to implement the IRenderer interface.
     *
     * Emits a `RendererUpdated` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - Renderer must not be locked.
     * @param implementation Address of new Renderer
     */
    function updateRenderer(address implementation) external;

    /**
     * Irreversibly prevents the token contract owner from changing the token
     * Renderer.
     *
     * Emits a `RendererLocked` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     */
    function lockRenderer() external;

    // supportsInterface(bytes4 interfaceId) overriding ERC1644 declared in
    // IERC1644

    /**
     * @return True after successfully executing mint and transfer of
     * `nextTokenId` to `account`.
     *
     * Emits a `Transfer` event with `address(0)` as `from`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * @param account The account to receive the minted token.
     */
    function mintTo(address account) external returns (bool);

    /**
     * @return True after successfully bulk minting and transferring the
     * `nextTokenId` through `nextTokenId + amount` tokens to `account`.
     *
     * Emits a `Transfer` event (with `address(0)` as `from`) for each token
     * that is minted.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * @param account The account to receive the minted tokens.
     * @param amount The number of tokens to be minted.
     */
    function bulkMintToOneAddress(address account, uint256 amount)
        external
        returns (bool);

    /**
     * @return True after successfully bulk minting and transferring one of the
     * `nextTokenId` through `nextTokenId + accounts.length` tokens to each of
     * the addresses in `accounts`.
     *
     * Emits a `Transfer` event (with `address(0)` as `from`) for each token
     * that is minted.
     *
     * Requirements:
     * - `accounts` cannot have length 0.
     * - None of the addresses in `accounts` can be the zero address.
     * @param accounts The accounts to receive the minted tokens.
     */
    function bulkMintToNAddresses(address[] calldata accounts)
        external
        returns (bool);

    /**
     * @return True after successfully burning `tokenId`.
     *
     * Emits a `Transfer` event with `address(0)` as `to`.
     *
     * Requirements:
     * - The caller must either own or be approved to spend the `tokenId` token.
     * - `tokenId` must exist.
     * @param tokenId The tokenId to be burned.
     */
    function redeem(uint256 tokenId) external returns (bool);

    // controllerRedeem() and controllerTransfer() declared in IERC1644

    /**
     * Sets the default royalty fee percentage for the ERC721.
     *
     * A custom royalty fee will override the default if set for specific tokenIds.
     *
     * Requirements:
     * - The caller must be the token contract owner.
     * - `isControllable` must be true.
     * @param receiver The account to receive the royalty.
     * @param feeNumerator The fee amount in basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /**
     * Sets a custom royalty fee percentage for the specified `tokenId`.
     *
     * Requirements:
     * - The caller must be the token contract owner.
     * - `isControllable` must be true.
     * - `tokenId` must exist.
     * @param tokenId The tokenId to set a custom royalty for.
     * @param receiver The account to receive the royalty.
     * @param feeNumerator The fee amount in basis points.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external;
}

/**
 * @title IERC721Collective
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for all functions in ERC721Collective, including inherited and
 * overridden functions.
 */
interface IERC721Collective is
    ITokenEnforceable,
    IERC721UpgradeableFork,
    IERC721CollectiveUnchained
{

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @title IERC721UpgradeableFork
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for functions defined in ERC721UpgradeableFork, a fork of
 * OpenZeppelin's ERC721Upgradeable with additional tokenId-tracking and
 * royalty functionality.
 */
interface IERC721UpgradeableFork is IERC721MetadataUpgradeable {
    /**
     * @return ID of the first token that will be minted.
     */
    // solhint-disable-next-line func-name-mixedcase
    function STARTING_TOKEN_ID() external view returns (uint256);

    /**
     * @return Max consecutive tokenIds of bulk-minted tokens whose owner can
     * be stored as address(0). This number is capped to reduce the cost of
     * owner lookup.
     */
    // solhint-disable-next-line func-name-mixedcase
    function OWNER_ID_STAGGER() external view returns (uint256);

    /**
     * @return ID of the next token that will be minted. Existing tokens are
     * limited to IDs between `STARTING_TOKEN_ID` and `_nextTokenId` (including
     * `STARTING_TOKEN_ID` and excluding `_nextTokenId`, though not all of these
     * IDs may be in use if tokens have been burned).
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @return receiver Address that should receive royalties from sales.
     * @return royaltyAmount How much royalty that should be sent to `receiver`,
     * denominated in the same unit of exchange as `salePrice`.
     * @param tokenId The token being sold.
     * @param salePrice The sale price of the token, denominated in any unit of
     * exchange. The royalty amount will be denominated and should be paid in
     * that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IAdministrable} from "src/contracts/utils/Administrable/IAdministrable.sol";
import {IBatchable} from "src/contracts/utils/Batchable/IBatchable.sol";
import {ITokenRecoverable} from "src/contracts/utils/TokenRecoverable/ITokenRecoverable.sol";
import {IGuard} from "src/contracts/guards/IGuard.sol";

/**
 * @title ITokenEnforceable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for tokens with modular conditions on mint, burn, and transfer
 * functions enforced by Guard contracts, such as `ERC20Club` and
 * `ERC721Collective`.
 */
interface ITokenEnforceable is IAdministrable, IBatchable, ITokenRecoverable {
    event ControlDisabled(address indexed controller);
    event GuardUpdated(GuardType indexed guard, address indexed implementation);
    event GuardLocked(
        bool mintGuardLocked,
        bool burnGuardLocked,
        bool transferGuardLocked
    );

    /**
     * @return True iff the token contract owner is allowed to mint, burn, or
     * transfer on behalf of arbitrary addresses.
     */
    function isControllable() external view returns (bool);

    /**
     * @return The address of the Guard used to determine whether a mint is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function mintGuard() external view returns (IGuard);

    /**
     * @return The address of the Guard used to determine whether a burn is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function burnGuard() external view returns (IGuard);

    /**
     * @return The address of the Guard used to determine whether a transfer is
     * allowed. The contract at this address is assumed to implement the IGuard
     * interface.
     */
    function transferGuard() external view returns (IGuard);

    /**
     * @return True iff the mint Guard cannot be changed.
     */
    function mintGuardLocked() external view returns (bool);

    /**
     * @return True iff the burn Guard cannot be changed.
     */
    function burnGuardLocked() external view returns (bool);

    /**
     * @return True iff the transfer Guard cannot be changed.
     */
    function transferGuardLocked() external view returns (bool);

    /**
     * @return True iff a token can be minted, burned, or transferred by a
     * particular operator, from a particular sender (`from` is address 0 iff
     * the token is being minted), to a particular recipient (`to` is address 0
     * iff the token is being burned).
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);

    /**
     * @return owner The address of the token contract owner
     */
    function owner() external view returns (address);

    /**
     * Irreversibly disables the token contract owner from minting, burning,
     * and transferring on behalf of arbitrary addresses.
     *
     * Emits a `ControlDisabled` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     */
    function disableControl() external;

    /**
     * Irreversibly prevents the token contract owner from changing the mint,
     * burn, and/or transfer Guards.
     *
     * If at least one guard was requested to be locked, emits a `GuardLocked`
     * event confirming whether each Guard is locked.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * @param mintGuardLock If true, the mint Guard will be locked. If false,
     * does nothing to the mint Guard.
     * @param burnGuardLock If true, the mint Guard will be locked. If false,
     * does nothing to the burn Guard.
     * @param transferGuardLock If true, the mint Guard will be locked. If
     * false, does nothing to the transfer Guard.
     */
    function lockGuards(
        bool mintGuardLock,
        bool burnGuardLock,
        bool transferGuardLock
    ) external;

    /**
     * Update the address of the Guard for minting. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Mint`.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - The mint Guard must not be locked.
     * @param implementation Address of new mint Guard
     */
    function updateMintGuard(address implementation) external;

    /**
     * Update the address of the Guard for burning. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Burn`.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - The burn Guard must not be locked.
     * @param implementation Address of new burn Guard
     */
    function updateBurnGuard(address implementation) external;

    /**
     * Update the address of the Guard for transferring. The contract at the
     * passed-in address is assumed to implement the IGuard interface.
     *
     * Emits a `GuardUpdated` event with `GuardType.Transfer`.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - The transfer Guard must not be locked.
     * @param implementation Address of transfer Guard
     */
    function updateTransferGuard(address implementation) external;

    /**
     * Transfers ownership of the contract to a new account (`newOwner`)
     *
     * Emits an `OwnershipTransferred` event.
     *
     * Requirements:
     * - The caller must be the current owner.
     * @param newOwner Address that will become the owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * Leaves the contract without an owner. After calling this function, it
     * will no longer be possible to call `onlyOwner` functions.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function renounceOwnership() external;
}

enum GuardType {
    Mint,
    Burn,
    Transfer
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {MerkleList} from "src/contracts/modules/utils/MerkleList.sol";
import {NativePrice} from "src/contracts/modules/utils/NativePrice.sol";
import {MinterTracker} from "src/contracts/modules/utils/MinterTracker.sol";
import {ERC165CheckerERC721Collective} from "src/contracts/ERC721Collective/ERC165CheckerERC721Collective.sol";
import {IERC721Collective} from "src/contracts/ERC721Collective/IERC721Collective.sol";
import {TokenRecoverable} from "src/contracts/utils/TokenRecoverable/TokenRecoverable.sol";

/**
 * @title AdditionalAdditionalNativeTokenPriceMerkleMintModule
 * @author Syndicate Inc.
 * @dev AdditionalAdditional: When two Merkle claims aren't enough, and you need
 * three! This is an additional mint module for Merkle claims. It is identical
 * to NativeTokenPriceMerkleMintModule, but the additional deployment allows us
 * to have three different claim amounts for a single Collective. The
 * NativeTokenPriceMerkleMintModule should be preferred, this exists only as an
 * additional fallback.
 *
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * A Module that allows the owner of an ERC721Collective to "airdrop" a list of
 * recipient addresses and mint amounts as a Merkle tree, and allows recipients
 * on that list to mint their allocated tokens in exchange for a native
 * token-denominated price per token set by the owner.
 */
contract AdditionalAdditionalNativeTokenPriceMerkleMintModule is
    MerkleList,
    NativePrice,
    MinterTracker,
    ERC165CheckerERC721Collective,
    TokenRecoverable
{
    event CollectiveTokenMinted(
        address indexed collective,
        address indexed account,
        uint256 indexed amount
    );

    constructor(address admin) TokenRecoverable(admin) {}

    /// Enforce that a requested mint action is allowed given the token's parameters
    /// @param collective Address of token attempting to claim
    /// @param merkleProof List of hashes to traverse merkle tree to prove airdrop
    /// @param amount Number of collective tokens to mint
    function mint(
        address collective,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) external payable onlyCollectiveInterface(collective) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        verifyProof(collective, merkleProof, leaf);

        collectNativePrice(collective, amount);
        checkMintMax(collective, amount);

        IERC721Collective(collective).bulkMintToOneAddress(msg.sender, amount);

        emit CollectiveTokenMinted(collective, msg.sender, amount);
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending NativeToken to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {
        revert("NativePriceMerkleMintModule: non-existent function");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IGuard
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for a Guard that governs whether a token can be minted, burned, or
 * transferred by a particular operator, from a particular sender (`from` is
 * address 0 iff the token is being minted), to a particular recipient (`to` is
 * address 0 iff the token is being burned).
 */
interface IGuard {
    /**
     * @return True iff the transaction is allowed
     * @param operator Transaction msg.sender
     * @param from Token sender
     * @param to Token recipient
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function isAllowed(
        address operator,
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/**
 * @title MerkleList
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a Module to verify that some data (a Merkle
 * "leaf", such as an address) has a valid proof in a Merkle tree (such as a
 * list of addresses) added by the token owner.
 */
abstract contract MerkleList is TokenOwnerChecker {
    mapping(address => bytes32) public merkleRoot;

    event MerkleRootUpdated(address indexed token, bytes32 indexed root);

    function verifyProof(
        address token,
        bytes32[] calldata merkleProof,
        bytes32 leaf
    ) internal {
        require(
            merkleRoot[token] > 0,
            "MerkleList: Merkle root has not been set"
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot[token], leaf);
        require(valid, "MerkleList: Valid proof required");
    }

    /// Set merkle root
    /// @param token Token address
    /// @param root New merkle root
    /// @notice Only available to token owner
    function updateMerkleRoot(address token, bytes32 root)
        external
        onlyTokenOwner(token)
    {
        merkleRoot[token] = root;
        emit MerkleRootUpdated(token, root);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "src/contracts/utils/IOwner.sol";

/**
 * @title MinterTracker
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a Module to track the number of tokens each
 * member has minted *through that Module* and enforce a maximum total number
 * of tokens all members can mint *through that Module*.
 */
abstract contract MinterTracker {
    // token => max
    mapping(address => uint256) public mintMax;
    // token => member => number minted
    mapping(address => mapping(address => uint256)) public numberMinted;

    event MintMaxUpdated(address indexed token, uint256 indexed max);

    function checkMintMax(address token) internal {
        if (mintMax[token] > 0) {
            require(
                mintMax[token] > numberMinted[token][msg.sender],
                "MinterTracker: Address has reached mint max"
            );
            numberMinted[token][msg.sender] =
                numberMinted[token][msg.sender] +
                1;
        }
    }

    function checkMintMax(address token, uint256 amount) internal {
        if (mintMax[token] > 0) {
            require(
                mintMax[token] >= numberMinted[token][msg.sender] + amount,
                "MinterTracker: Address has reached mint max"
            );
            numberMinted[token][msg.sender] =
                numberMinted[token][msg.sender] +
                amount;
        }
    }

    /// Set eth price
    /// @param token Token address
    /// @param _mintMax New merkle root
    /// @notice Only available to token owner
    function updateMintMax(address token, uint256 _mintMax) external {
        require(
            msg.sender == IOwner(token).owner(),
            "MinterTracker: Only owner can set mint max"
        );
        mintMax[token] = _mintMax;
        emit MintMaxUpdated(token, _mintMax);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "src/contracts/utils/IOwner.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/**
 * @title NativePrice
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a price, denominated in the chain's native
 * token (e.g. Eth on Ethereum Mainnet) and specified by the token contract
 * owner, to be deducted from an address.
 */
abstract contract NativePrice is TokenOwnerChecker {
    mapping(address => uint256) public nativePrice;

    event NativePriceUpdated(address indexed token, uint256 indexed price);

    function collectNativePrice(address token) internal {
        require(
            msg.value == nativePrice[token],
            "NativePrice: Incorrect amount of nativeToken sent"
        );

        if (nativePrice[token] > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(IOwner(token).owner()).call{
                value: msg.value
            }("");
            require(success, "MintPrice: Failed to send nativeToken");
        }
    }

    function collectNativePrice(address token, uint256 amount) internal {
        require(
            msg.value == nativePrice[token] * amount,
            "NativePrice: Incorrect amount of nativeToken sent"
        );

        if (nativePrice[token] > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(IOwner(token).owner()).call{
                value: msg.value
            }("");
            require(success, "MintPrice: Failed to send nativeToken");
        }
    }

    /// Set eth price
    /// @param token Token address
    /// @param price New merkle root
    /// @notice Only available to token owner
    function updateNativePrice(address token, uint256 price)
        external
        onlyTokenOwner(token)
    {
        nativePrice[token] = price;
        emit NativePriceUpdated(token, price);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IAdministrable} from "./IAdministrable.sol";

/**
 * @title Administrable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Access control utility allowing any number of addresses to be granted "admin"
 * status and permission to execute functions with the `onlyAdmin` modifier.
 */
abstract contract Administrable is Context, IAdministrable {
    mapping(address => bool) private _admins;

    /**
     * Initializes `Administrable` with the caller as the original admin.
     *
     * Emits an `AdminGranted` event.
     */
    constructor() {
        _grantAdmin(_msgSender());
    }

    modifier onlyAdmin() virtual {
        _checkAdmin();
        _;
    }

    /**
     * @return True iff `account` is an admin.
     * @param account The address that may be an admin.
     */
    function isAdmin(address account) public view virtual returns (bool) {
        return _admins[account];
    }

    /**
     * Internal helper function that reverts if the caller is not an admin.
     */
    function _checkAdmin() internal view virtual {
        require(isAdmin(_msgSender()), "Administrable: admin-only function");
    }

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address to grant admin status
     */
    function grantAdmin(address account) public virtual onlyAdmin {
        _grantAdmin(account);
    }

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address from which admin status should be revoked
     */
    function revokeAdmin(address account) public virtual onlyAdmin {
        _revokeAdmin(account);
    }

    /**
     * Allows the caller to renounce admin status.
     *
     * Emits an `AdminRevoked` event iff the caller was an admin until this
     * call.
     */
    function renounceAdmin() public virtual {
        _revokeAdmin(_msgSender());
    }

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     * @param account The address to grant admin status
     */
    function _grantAdmin(address account) internal virtual {
        if (!isAdmin(account)) {
            _admins[account] = true;
            emit AdminGranted(account, _msgSender());
        }
    }

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     * @param account The address from which admin status should be revoked
     */
    function _revokeAdmin(address account) internal virtual {
        if (isAdmin(account)) {
            _admins[account] = false;
            emit AdminRevoked(account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IAdministrable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for an access control utility allowing any number of addresses to
 * be granted "admin" status and permission to execute functions with the
 * `onlyAdmin` modifier.
 */
interface IAdministrable {
    event AdminGranted(address indexed account, address indexed operator);
    event AdminRevoked(address indexed account, address indexed operator);

    /**
     * @return True iff `account` is an admin.
     * @param account The address that may be an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * Grants admin status to `account`.
     *
     * Emits an `AdminGranted` event iff `account` was not already an admin.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address to grant admin status
     */
    function grantAdmin(address account) external;

    /**
     * Revokes admin status from `account`.
     *
     * Emits an `AdminRevoked` event iff `account` was an admin until this call.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param account The address from which admin status should be revoked
     */
    function revokeAdmin(address account) external;

    /**
     * Allows the caller to renounce admin status.
     *
     * Emits an `AdminRevoked` event iff the caller was an admin until this
     * call.
     */
    function renounceAdmin() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IAdministrable} from "src/contracts/utils/Administrable/IAdministrable.sol";

/**
 * @title IBatchable (unchained)
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for `Batchable`, the abstract utility that should be inherited by
 * any contracts with functions that should be restricted to admins and the
 * batcher (`Batcher`) being operated by an admin.
 *
 * This "unchained" interface excludes inherited and overriden functions.
 */
interface IBatchableUnchained {
    event BatcherUpdated(address batcher);

    /**
     * @return The address of the transaction Batcher.
     */
    function batcher() external view returns (address);

    /**
     * Update the address of the Batcher.
     *
     * Emits a `BatcherUpdated` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * @param batcher_ Address of new batcher
     */
    function updateBatcher(address batcher_) external;
}

/**
 * @title IBatchable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for `Batchable`, the abstract utility that should be inherited by
 * any contracts with functions that should be restricted to admins and the
 * batcher (`Batcher`) being operated by an admin.
 *
 * This interface includes inherited and overridden functions.
 */
interface IBatchable is IBatchableUnchained, IAdministrable {

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IERC1644 Controller Token Operation (part of the ERC1400 Security
 * Token Standards)
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * See https://github.com/ethereum/EIPs/issues/1644. Data and operatorData
 * parameters were removed.
 */
interface IERC1644 {
    event ControllerRedemption(
        address account,
        address indexed from,
        uint256 value
    );

    event ControllerTransfer(
        address controller,
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * Burns `tokenId` without checking whether the caller owns or is approved
     * to spend the token.
     *
     * Emits a `Transfer` event with `address(0)` as `to` AND a
     * `ControllerRedemption` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - `isControllable` must be true.
     * @param account The account whose token will be burned.
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function controllerRedeem(
        address account,
        uint256 value // amount (ERC20) or tokenId (ERC721))
    ) external;

    /**
     * Transfers `tokenId` token from `from` to `to`, without checking whether
     * the caller owns or is approved to spend the token.
     *
     * Emits a `Transfer` event AND a `ControllerRedemption` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * - `isControllable` must be true.
     * @param from The account sending the token.
     * @param to The account to receive the token.
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function controllerTransfer(
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

interface IOwner {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "./IOwner.sol";

/**
 * @title TokenOwnerChecker
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Utility for use by any Module or Guard that needs to check if an address is
 * the owner of the TokenEnforceable (ERC20Club or ERC721Collective)
 */

abstract contract TokenOwnerChecker {
    /**
     * Only proceed if msg.sender owns TokenEnforceable contract
     * @param token TokenEnforceable whose owner to check
     */
    modifier onlyTokenOwner(address token) {
        _onlyTokenOwner(token);
        _;
    }

    function _onlyTokenOwner(address token) internal view {
        require(
            msg.sender == IOwner(token).owner(),
            "TokenOwnerChecker: Caller not token owner"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title ITokenRecoverable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for a token recovery utility allowing ERC20 and ERC721 tokens
 * erroneously sent to the contract to be returned.
 */
interface ITokenRecoverable {
    event TokenRecoveredERC20(
        address indexed recipient,
        address indexed erc20,
        uint256 amount
    );
    event TokenRecoveredERC721(
        address indexed recipient,
        address indexed erc721,
        uint256 tokenId
    );

    /**
     * Transfers ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - This contract must have a balance in `erc20` of at least `amount`.
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external;

    /**
     * Transfers ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - `tokenId` must exist in `erc721`.
     * - `tokenId` in `erc721` must be owned by this contract.
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Administrable} from "src/contracts/utils/Administrable/Administrable.sol";
import {ITokenRecoverable} from "./ITokenRecoverable.sol";

/**
 * @title TokenRecoverable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Token recovery utility allowing ERC20 and ERC721 tokens erroneously sent to
 * the contract to be returned.
 */
abstract contract TokenRecoverable is Administrable, ITokenRecoverable {
    // Using safeTransfer since interacting with other ERC20s
    using SafeERC20 for IERC20;

    /**
     * Initializes `TokenRecoverable` with a passed-in address as the first
     * admin.
     *
     * Emits an `AdminGranted` event.
     *
     * @dev Unlike `TokenRecoverableUpgradeable`'s initializer, this
     * constructor does NOT take an `admin_` argument, and instead confers
     * admin status on the caller.
     */
    constructor(address admin_) {
        _grantAdmin(admin_);
    }

    /**
     * Transfers ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - This contract must have a balance in `erc20` of at least `amount`.
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external onlyAdmin {
        IERC20(erc20).safeTransfer(recipient, amount);
        emit TokenRecoveredERC20(recipient, erc20, amount);
    }

    /**
     * Transfers ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - `tokenId` must exist in `erc721`.
     * - `tokenId` in `erc721` must be owned by this contract.
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external onlyAdmin {
        IERC721(erc721).transferFrom(address(this), recipient, tokenId);
        emit TokenRecoveredERC721(recipient, erc721, tokenId);
    }
}