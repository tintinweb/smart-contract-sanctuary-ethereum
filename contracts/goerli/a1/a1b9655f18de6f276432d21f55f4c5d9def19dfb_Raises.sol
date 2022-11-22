// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import {RaiseParams, Raise, RaiseState, RaiseTokens, Phase} from "./structs/Raise.sol";
import {TierParams, TierType, Tier} from "./structs/Tier.sol";
import {RaiseValidator} from "./libraries/validators/RaiseValidator.sol";
import {TierValidator} from "./libraries/validators/TierValidator.sol";
import {Phases} from "./libraries/Phases.sol";
import {IRaises} from "./interfaces/IRaises.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {ITokens} from "./interfaces/ITokens.sol";
import {ITokenAuth} from "./interfaces/ITokenAuth.sol";
import {ITokenDeployer} from "./interfaces/ITokenDeployer.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {IPausable} from "./interfaces/IPausable.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {Pausable} from "./abstract/Pausable.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";
import {Fees} from "./libraries/Fees.sol";
import {ETH} from "./constants/Constants.sol";

/// @title Raises - Crowdfunding mint module
/// @notice Patrons interact with this contract to mint and redeem raise tokens
/// in support of projects.
contract Raises is IRaises, Controllable, Pausable, ReentrancyGuard {
    using RaiseValidator for RaiseParams;
    using TierValidator for TierParams;
    using Phases for Raise;
    using SafeERC20 for IERC20;
    using Address for address payable;

    string public constant NAME = "Raises";
    string public constant VERSION = "0.0.1";

    address public creators;
    address public projects;
    address public minter;
    address public deployer;
    address public tokens;
    address public tokenAuth;

    // projectId => totalRaises
    mapping(uint32 => uint32) public totalRaises;
    // projectId => raiseId => Raise
    mapping(uint32 => mapping(uint32 => Raise)) public raises;
    // projectId => raiseId => Tier[]
    mapping(uint32 => mapping(uint32 => Tier[])) public tiers;
    // projectId => raiseId => tierId => minter address => count
    mapping(uint32 => mapping(uint32 => mapping(uint32 => mapping(address => uint256)))) public mints;

    // token address => accrued protocol fees
    mapping(address => uint256) public fees;

    modifier onlyCreators() {
        if (msg.sender != creators) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc IRaises
    function create(uint32 projectId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        override
        onlyCreators
        whenNotPaused
        returns (uint32 raiseId)
    {
        if (!IProjects(projects).exists(projectId)) {
            revert NotFound();
        }

        params.validate(tokenAuth);

        raiseId = ++totalRaises[projectId];

        // Deploy tokens
        address fanToken = ITokenDeployer(deployer).deploy();
        address brandToken = ITokenDeployer(deployer).deploy();

        _saveRaise(projectId, raiseId, fanToken, brandToken, params);
        _saveTiers(projectId, raiseId, fanToken, brandToken, _tiers);

        emit CreateRaise(projectId, raiseId, params, _tiers, fanToken, brandToken);
    }

    /// @inheritdoc IRaises
    function update(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        override
        onlyCreators
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        Phase phase = raise.phase();

        // Check that raise has not started
        if (phase != Phase.Scheduled) revert RaiseNotScheduled();

        params.validate(tokenAuth);

        address fanToken = raise.tokens.fanToken;
        address brandToken = raise.tokens.brandToken;

        _saveRaise(projectId, raiseId, fanToken, brandToken, params);
        _saveTiers(projectId, raiseId, fanToken, brandToken, _tiers);

        emit UpdateRaise(projectId, raiseId, params, _tiers);
    }

    /// @inheritdoc IRaises
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        return _mint(projectId, raiseId, tierId, amount, new bytes32[](0));
    }

    /// @inheritdoc IRaises
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        return _mint(projectId, raiseId, tierId, amount, proof);
    }

    /// @inheritdoc IRaises
    function settle(uint32 projectId, uint32 raiseId) external override whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        // Check that raise has ended
        if (raise.phase() != Phase.Ended) revert RaiseNotEnded();

        // Effects
        if (raise.raised >= raise.goal) {
            // If the raise has met its goal, transition to Funded
            emit SettleRaise(projectId, raiseId, raise.state = RaiseState.Funded);

            // Add this raise's fees to global fee balance
            fees[raise.currency] += raise.fees;
        } else {
            // Otherwise, transition to Cancelled
            emit SettleRaise(projectId, raiseId, raise.state = RaiseState.Cancelled);
        }
    }

    /// @inheritdoc IRaises
    function cancel(uint32 projectId, uint32 raiseId) external override onlyCreators whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        // Effects
        emit CancelRaise(projectId, raiseId, raise.state = RaiseState.Cancelled);
    }

    /// @inheritdoc IRaises
    function close(uint32 projectId, uint32 raiseId) external override onlyCreators whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);
        if (raise.state != RaiseState.Active) revert RaiseInactive();
        if (raise.raised < raise.goal) revert RaiseGoalNotMet();

        // Effects
        emit CloseRaise(projectId, raiseId, raise.state = RaiseState.Funded);
    }

    /// @inheritdoc IRaises
    function withdraw(uint32 projectId, uint32 raiseId, address receiver)
        external
        override
        nonReentrant
        onlyCreators
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise has been cancelled
        if (raise.state != RaiseState.Funded) revert RaiseNotFunded();

        // Effects

        // Store withdrawal amount
        uint256 amount = raise.balance;

        // Clear raise balance
        raise.balance = 0;

        // Interactions
        // Get raise currency
        address currency = raise.currency;
        if (currency == ETH) {
            // If currency is ETH, send ETH to receiver
            payable(receiver).sendValue(amount);
        } else {
            // If currency is ERC20, transfer tokens to reciever
            IERC20(currency).safeTransfer(receiver, amount);
        }
        emit WithdrawRaiseFunds(projectId, raiseId, receiver, currency, amount);
    }

    /// @inheritdoc IRaises
    function redeem(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise has been cancelled
        if (raise.state != RaiseState.Cancelled) revert RaiseNotCancelled();

        // Get the tier if it exists
        if (tierId > tiers[projectId][raiseId].length - 1) revert NotFound();
        Tier storage tier = tiers[projectId][raiseId][tierId];

        // Effects
        // Calculate refund amount
        uint256 refund = amount * tier.price;

        // Calculate protocol fee and creator take
        (uint256 protocolFee, uint256 creatorTake) = Fees.calculate(tier.tierType, refund);

        // Deduct refund from balance and fees
        raise.balance -= creatorTake;
        raise.fees -= protocolFee;

        // Interactions
        // Burn token (reverts if caller is not owner or approved)
        uint256 tokenId = RaiseToken.encode(tier.tierType, projectId, raiseId, tierId);
        ITokens(tokens).token(tokenId).burn(msg.sender, tokenId, amount);

        // Get raise currency
        address currency = raise.currency;
        if (currency == ETH) {
            // If currency is ETH, send ETH to caller
            payable(msg.sender).sendValue(refund);
        } else {
            // If currency is ERC20, transfer tokens to caller
            IERC20(currency).safeTransfer(msg.sender, refund);
        }
        emit Redeem(projectId, raiseId, tierId, msg.sender, amount, currency, refund);
    }

    /// @inheritdoc IRaises
    function withdrawFees(address currency, address receiver) external override nonReentrant onlyController {
        // Checks
        uint256 balance = fees[currency];

        // Revert if fee balance is zero
        if (balance == 0) revert ZeroBalance();

        // Effects

        // Clear fee balance
        fees[currency] = 0;

        // Interactions
        if (currency == ETH) {
            // If currency is ETH, send ETH to receiver
            payable(receiver).sendValue(balance);
        } else {
            // If currency is ERC20, transfer tokens to receiver
            IERC20(currency).safeTransfer(receiver, balance);
        }
        emit WithdrawFees(receiver, currency, balance);
    }

    /// @inheritdoc IPausable
    function pause() external override onlyController {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external override onlyController {
        _unpause();
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "creators") _setCreators(_contract);
        else if (_name == "projects") _setProjects(_contract);
        else if (_name == "minter") _setMinter(_contract);
        else if (_name == "deployer") _setDeployer(_contract);
        else if (_name == "tokens") _setTokens(_contract);
        else if (_name == "tokenAuth") _setTokenAuth(_contract);
        else revert InvalidDependency(_name);
    }

    /// @inheritdoc IRaises
    function getRaise(uint32 projectId, uint32 raiseId) external view override returns (Raise memory) {
        return _getRaise(projectId, raiseId);
    }

    /// @inheritdoc IRaises
    function getPhase(uint32 projectId, uint32 raiseId) external view override returns (Phase) {
        return _getRaise(projectId, raiseId).phase();
    }

    /// @inheritdoc IRaises
    function getTiers(uint32 projectId, uint32 raiseId) external view override returns (Tier[] memory) {
        return tiers[projectId][raiseId];
    }

    function _setCreators(address _creators) internal {
        emit SetCreators(creators, _creators);
        creators = _creators;
    }

    function _setProjects(address _projects) internal {
        emit SetProjects(projects, _projects);
        projects = _projects;
    }

    function _setMinter(address _minter) internal {
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function _setDeployer(address _deployer) internal {
        emit SetDeployer(deployer, _deployer);
        deployer = _deployer;
    }

    function _setTokens(address _tokens) internal {
        emit SetTokens(tokens, _tokens);
        tokens = _tokens;
    }

    function _setTokenAuth(address _tokenAuth) internal {
        emit SetTokenAuth(tokenAuth, _tokenAuth);
        tokenAuth = _tokenAuth;
    }

    function _getRaise(uint32 projectId, uint32 raiseId) internal view returns (Raise storage raise) {
        // Check that project exists
        if (totalRaises[projectId] == 0) revert NotFound();

        // Get the raise if it exists
        raise = raises[projectId][raiseId];
        if (raise.projectId == 0) revert NotFound();
    }

    function _mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        internal
        returns (uint256 tokenId)
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        Phase phase = raise.phase();
        // Check that raise has started
        if (phase == Phase.Scheduled) revert RaiseNotStarted();

        // Check that raise has not ended
        if (phase == Phase.Ended) revert RaiseEnded();

        // Get the tier if it exists
        if (tierId > tiers[projectId][raiseId].length - 1) revert NotFound();
        Tier storage tier = tiers[projectId][raiseId][tierId];

        // In presale phase, user must provide a valid proof
        if (
            phase == Phase.Presale
                && !MerkleProof.verify(proof, tier.allowListRoot, keccak256(abi.encodePacked(msg.sender)))
        ) revert InvalidProof();

        // Check that tier has remaining supply
        if (tier.minted + amount > tier.supply) revert RaiseSoldOut();

        // Check that caller will not exceed limit per address
        if (mints[projectId][raiseId][tierId][msg.sender] + amount > tier.limitPerAddress) {
            revert AddressMintedMaximum();
        }

        // Calculate mint price.
        uint256 mintPrice = amount * tier.price;

        // Get the currency for this raise. Save for use later.
        address currency = raise.currency;

        if (currency == ETH) {
            // If currency is ETH, msg.value must be mintPrice
            if (msg.value != mintPrice) revert InvalidPaymentAmount();
        } else {
            // If currency is not ETH, msg.value must be zero
            if (msg.value != 0) revert InvalidPaymentAmount();

            // Check that currency has not been removed from the ERC20 allowlist
            if (ITokenAuth(tokenAuth).denied(currency)) revert InvalidCurrency();
        }

        // Calculate total raised
        uint256 totalRaised = raise.raised + mintPrice;

        // If there is a raise maximum, check that payment does not exceed it
        if (raise.max != 0 && totalRaised > raise.max) revert ExceedsRaiseMaximum();

        // Effects

        // Increment per-caller mint count
        mints[projectId][raiseId][tierId][msg.sender] += amount;

        // Increment tier minted count
        tier.minted += amount;

        // Increase raised amount
        raise.raised = totalRaised;

        // Calculate protocol fee and creator take
        (uint256 protocolFee, uint256 creatorTake) = Fees.calculate(tier.tierType, mintPrice);

        // Increase balances
        raise.balance += creatorTake;
        raise.fees += protocolFee;

        // Interactions
        // If currency is not ETH, transfer tokens from caller
        if (currency != ETH) {
            IERC20(currency).safeTransferFrom(msg.sender, address(this), mintPrice);
        }

        // Encode token ID
        tokenId = RaiseToken.encode(tier.tierType, projectId, raiseId, tierId);

        // Mint token to caller
        IMinter(minter).mint(msg.sender, tokenId, amount, "");

        // Emit event
        emit Mint(projectId, raiseId, tierId, msg.sender, amount, proof);
    }

    function _saveRaise(
        uint32 projectId,
        uint32 raiseId,
        address fanToken,
        address brandToken,
        RaiseParams memory params
    ) internal {
        raises[projectId][raiseId] = Raise({
            currency: params.currency,
            goal: params.goal,
            max: params.max,
            presaleStart: params.presaleStart,
            presaleEnd: params.presaleEnd,
            publicSaleStart: params.publicSaleStart,
            publicSaleEnd: params.publicSaleEnd,
            state: RaiseState.Active,
            projectId: projectId,
            raiseId: raiseId,
            tokens: RaiseTokens({fanToken: fanToken, brandToken: brandToken}),
            raised: 0,
            balance: 0,
            fees: 0
        });
    }

    function _saveTiers(
        uint32 projectId,
        uint32 raiseId,
        address fanToken,
        address brandToken,
        TierParams[] memory _tiers
    ) internal {
        delete tiers[projectId][raiseId];
        for (uint256 i; i < _tiers.length;) {
            TierParams memory tierParams = _tiers[i];
            tierParams.validate();
            tiers[projectId][raiseId].push(
                Tier({
                    tierType: tierParams.tierType,
                    price: tierParams.price,
                    supply: tierParams.supply,
                    limitPerAddress: tierParams.limitPerAddress,
                    allowListRoot: tierParams.allowListRoot,
                    minted: 0
                })
            );

            // Register token
            uint256 tokenId = RaiseToken.encode(tierParams.tierType, projectId, raiseId, uint32(i));
            address token = tierParams.tierType == TierType.Fan ? fanToken : brandToken;
            ITokenDeployer(deployer).register(tokenId, token);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Pausable as OZPausable} from "openzeppelin-contracts/security/Pausable.sol";
import {IPausable} from "../interfaces/IPausable.sol";

/// @title Pausable - Pause and unpause functionality
/// @notice Wraps OZ Pausable and adds an IPausable interface.
abstract contract Pausable is IPausable, OZPausable {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

uint256 constant ONE_BYTE = 0x8;
uint256 constant ONE_BYTE_MASK = type(uint8).max;

uint256 constant FOUR_BYTES = 0x20;
uint256 constant FOUR_BYTE_MASK = type(uint32).max;

uint256 constant THIRTY_BYTES = 0xf0;
uint256 constant THIRTY_BYTE_MASK = type(uint240).max;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev The "dolphin address," a special value representing native ETH.
address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";

interface IAllowList is IControllable {
    event Allow(address caller);
    event Deny(address caller);

    /// @notice Check whether the given `caller` address is allowed.
    /// @param caller The caller address.
    /// @return True if caller is allowed, false if caller is denied.
    function allowed(address caller) external view returns (bool);

    /// @notice Check whether the given `caller` address is denied.
    /// @param caller The caller address.
    /// @return True if caller is denied, false if caller is allowed.
    function denied(address caller) external view returns (bool);

    /// @notice Add a caller address to the allowlist.
    /// @param caller The caller address.
    function allow(address caller) external;

    /// @notice Remove a caller address from the allowlist.
    /// @param caller The caller address.
    function deny(address caller) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC1155MetadataURIUpgradeable} from
    "openzeppelin-contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import {IERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";

interface IEmint1155 is IERC1155MetadataURIUpgradeable, IERC2981Upgradeable, IAnnotated, ICommonErrors {
    /// @notice Initialize the cloned Emint1155 token contract.
    /// @param tokens address of tokens module.
    function initialize(address tokens) external;

    /// @notice Get address of metadata module.
    /// @return address of metadata module.
    function metadata() external view returns (address);

    /// @notice Get address of royalties module.
    /// @return address of royalties module.
    function royalties() external view returns (address);

    /// @notice Get address of collection owner. This address has no special
    /// permissions at the contract level, but will be authorized to manage this
    /// token's collection on storefronts like OpenSea.
    /// @return address of collection owner.
    function owner() external view returns (address);

    /// @notice Get contract metadata URI. Used by marketplaces like OpenSea to
    /// retrieve information about the token contract/collection.
    /// @return URI of contract metadata.
    function contractURI() external view returns (string memory);

    /// @notice Mint `amount` tokens with ID `id` to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /// @notice Batch mint tokens to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param ids uint256[] array of token IDs.
    /// @param amounts uint256[] array of quantities to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    /// @notice Burn `amount` of tokens with ID `id` from `account`
    /// @param account address of token owner.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    function burn(address account, uint256 id, uint256 amount) external;

    /// @notice Batch burn tokens from `account` address.
    /// @param account address of token owner.
    /// @param ids uint256[] array of token IDs.
    /// @param amounts uint256[] array of quantities to burn.
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface IMinter is IAllowList, IAnnotated {
    event SetTokens(address oldTokens, address newTokens);

    /// @notice Mint `amount` tokens with ID `id` to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";
import {IAllowList} from "./IAllowList.sol";

interface IProjects is IAllowList, IPausable, IAnnotated {
    event CreateProject(uint32 id);
    event TransferOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);
    event AcceptOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);

    /// @notice Create a new project owned by the given `owner`.
    /// @param owner address of project owner.
    /// @return uint32 Project ID.
    function create(address owner) external returns (uint32);

    /// @notice Start transfer of `projectId` to `newOwner`. The new owner must
    /// accept the transfer in order to assume ownership of the project.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Transfer ownership of `projectId` to `pendingOwner`.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Get owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of project owner.
    function ownerOf(uint32 projectId) external view returns (address);

    /// @notice Get pending owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of pending project owner.
    function pendingOwnerOf(uint32 projectId) external view returns (address);

    /// @notice Check whether project exists by ID.
    /// @param projectId uint32 project ID.
    /// @return True if project exists, false if project does not exist.
    function exists(uint32 projectId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IPausable} from "./IPausable.sol";
import {Raise, RaiseParams, RaiseState, Phase} from "../structs/Raise.sol";
import {Tier, TierParams} from "../structs/Tier.sol";

interface IRaises is IPausable, IControllable, IAnnotated {
    /// @notice Minting token would exceed the raise's configured maximum amount.
    error ExceedsRaiseMaximum();
    /// @notice The raise's goal has not been met.
    error RaiseGoalNotMet();
    /// @notice The given currency address is unknown, invalid, or denied.
    error InvalidCurrency();
    /// @notice The provided payment amount is incorrect.
    error InvalidPaymentAmount();
    /// @notice The provided Merkle proof is invalid.
    error InvalidProof();
    /// @notice This caller address has minted the maximum number of tokens allowed per address.
    error AddressMintedMaximum();
    /// @notice The raise is not in Cancelled state.
    error RaiseNotCancelled();
    /// @notice The raise is not in Funded state.
    error RaiseNotFunded();
    /// @notice The raise has ended.
    error RaiseEnded();
    /// @notice The raise is no longer in Active state.
    error RaiseInactive();
    /// @notice The raise has not yet ended.
    error RaiseNotEnded();
    /// @notice The raise has started and is no longer in Scheduled phase.
    error RaiseNotScheduled();
    /// @notice The raise has not yet started and is in the Scheduled phase.
    error RaiseNotStarted();
    /// @notice This token tier is sold out, or an attempt to mint would exceed the maximum supply.
    error RaiseSoldOut();
    /// @notice The caller's token balance is zero.
    error ZeroBalance();

    event CreateRaise(uint32 indexed projectId, uint32 raiseId, RaiseParams params, TierParams[] tiers, address fanToken, address brandToken);
    event UpdateRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseParams params, TierParams[] tiers);
    event Mint(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address minter,
        uint256 amount,
        bytes32[] proof
    );
    event SettleRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CancelRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event CloseRaise(uint32 indexed projectId, uint32 indexed raiseId, RaiseState newState);
    event WithdrawRaiseFunds(
        uint32 indexed projectId, uint32 indexed raiseId, address indexed receiver, address currency, uint256 amount
    );
    event Redeem(
        uint32 indexed projectId,
        uint32 indexed raiseID,
        uint32 indexed tierId,
        address receiver,
        uint256 tokenAmount,
        address owner,
        uint256 refundAmount
    );
    event WithdrawFees(address indexed receiver, address currency, uint256 amount);

    event SetCreators(address oldCreators, address newCreators);
    event SetProjects(address oldProjects, address newProjects);
    event SetMinter(address oldMinter, address newMinter);
    event SetDeployer(address oldDeployer, address newDeployer);
    event SetTokens(address oldTokens, address newTokens);
    event SetTokenAuth(address oldTokenAuth, address newTokenAuth);

    /// @notice Create a new raise by project ID. May only be called by
    /// approved creators.
    /// @param projectId uint32 project ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    /// @return raiseId Created raise ID.
    function create(uint32 projectId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        returns (uint32 raiseId);

    /// @notice Update a Scheduled raise by project ID and raise ID. May only be
    /// called while the raise's state is Active and phase is Scheduled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param params RaiseParams raise configuration parameters struct.
    /// @param _tiers TierParams[] array of tier configuration parameters structs.
    function update(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory _tiers) external;

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide ETH or approve ERC20 amount
    /// equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Mint `amount` of tokens to caller for the given `projectId`,
    /// `raiseId`, and `tierId`. Caller must provide a Merkle proof. Caller must
    /// provide ETH or approve ERC20 amount equal to total cost.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param proof bytes32[] Merkle proof of inclusion on tier allowlist.
    /// @return tokenId uint256 Minted token ID.
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        external
        payable
        returns (uint256 tokenId);

    /// @notice Settle a raise in the Active state and Ended phase. Sets raise
    /// state to Funded if the goal has been met. Sets raise state to Cancelled
    /// if the goal has not been met.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function settle(uint32 projectId, uint32 raiseId) external;

    /// @notice Cancel a raise, setting its state to Cancelled. May only be
    /// called by `creators` contract. May only be called while raise state is Active.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function cancel(uint32 projectId, uint32 raiseId) external;

    /// @notice Close a raise. May only be called by `creators` contract. May
    /// only be called if raise state is Active and raise goal is met. Sets
    /// state to Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    function close(uint32 projectId, uint32 raiseId) external;

    /// @notice Withdraw raise funds to given `receiver` address. May only be
    /// called by `creators` contract. May only be called if raise state is Funded.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param receiver address send funds to this address.
    function withdraw(uint32 projectId, uint32 raiseId, address receiver) external;

    /// @notice Redeem `amount` of tokens from caller for the given `projectId`,
    /// `raiseId`, and `tierId` and return ETH or ERC20 tokens to caller. May
    /// only be called when raise state is Cancelled.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @param tierId uint32 tier ID.
    /// @param amount uint256 quantity of tokens to redeem.
    function redeem(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount) external;

    /// @notice Withdraw accrued protocol fees for given `currency` to given
    /// `receiver` address. May only be called by `controller` contract.
    /// @param currency address ERC20 token address or special sentinel value for ETH.
    /// @param receiver address send funds to this address.
    function withdrawFees(address currency, address receiver) external;

    /// @notice Get a raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Raise struct.
    function getRaise(uint32 projectId, uint32 raiseId) external view returns (Raise memory);

    /// @notice Get a raise's current Phase by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Phase enum member.
    function getPhase(uint32 projectId, uint32 raiseId) external view returns (Phase);

    /// @notice Get all tiers for a given raise by project ID and raise ID.
    /// @param projectId uint32 project ID.
    /// @param raiseId uint32 raise ID.
    /// @return Array of Tier structs.
    function getTiers(uint32 projectId, uint32 raiseId) external view returns (Tier[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ITokenAuth is IAllowList, IAnnotated {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ITokenDeployer is IAllowList, IAnnotated {
    event SetTokens(address oldTokens, address newTokens);

    function deploy() external returns (address);
    function register(uint256 id, address token) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAnnotated} from "./IAnnotated.sol";
import {IControllable} from "./IControllable.sol";
import {IPausable} from "./IPausable.sol";
import {IEmint1155} from "./IEmint1155.sol";

interface ITokens is IControllable, IAnnotated {
    event SetMinter(address oldMinter, address newMinter);
    event SetDeployer(address oldDeployer, address newDeployer);
    event SetMetadata(address oldMetadata, address newMetadata);
    event SetRoyalties(address oldRoyalties, address newRoyalties);
    event UpdateTokenImplementation(address oldImpl, address newImpl);

    /// @notice Get address of metadata module.
    /// @return address of metadata module.
    function metadata() external view returns (address);

    /// @notice Get address of royalties module.
    /// @return address of royalties module.
    function royalties() external view returns (address);

    /// @notice Get deployed token for given token ID.
    /// @param tokenId uint256 token ID.
    /// @return IEmint1155 interface to deployed Emint1155 token contract.
    function token(uint256 tokenId) external view returns (IEmint1155);

    /// @notice Deploy an Emint1155 token. May only be called by token deployer.
    /// @return address of deployed Emint1155 token contract.
    function deploy() external returns (address);

    /// @notice Register a deployed token's address by token ID.
    /// May only be called by token deployer.
    /// @param tokenId uint256 token ID
    /// @param token address of deployed Emint1155 token contract.
    function register(uint256 tokenId, address token) external;

    /// @notice Update Emint1155 token implementation contract. Bytecode of this
    /// implementation contract will be cloned when deploying a new Emint1155.
    /// May only be called by controller.
    /// @param implementation address of implementation contract.
    function updateTokenImplementation(address implementation) external;

    /// @notice Mint `amount` tokens with ID `id` to `to` address, passing `data`.
    /// @param to address of token reciever.
    /// @param id uint256 token ID.
    /// @param amount uint256 quantity of tokens to mint.
    /// @param data bytes of data to pass to ERC1155 mint function.
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TierType} from "../structs/Tier.sol";

uint256 constant BPS_DENOMINATOR = 10_000;

/// @title Fees - Fee calculator
/// @notice Calculates protocol fee based on token mint price.
library Fees {
    function calculate(TierType tierType, uint256 mintPrice)
        internal
        pure
        returns (uint256 protocolFee, uint256 creatorTake)
    {
        uint256 feeBps = (tierType == TierType.Fan) ? 500 : 2500;
        protocolFee = (feeBps * mintPrice) / BPS_DENOMINATOR;
        creatorTake = mintPrice - protocolFee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Raise, Phase} from "../structs/Raise.sol";

/// @title Phases - Raise schedule calculator
/// @notice Calculates a raise's "phase" based on the current timestamp and the
/// raise's configured schedule.
library Phases {
    function phase(Raise memory raise) internal view returns (Phase) {
        // If it's before presale start, the raise is scheduled
        if (block.timestamp < raise.presaleStart) {
            return Phase.Scheduled;
        }
        // If it's after public sale end, the raise has ended
        if (block.timestamp > raise.publicSaleEnd) {
            return Phase.Ended;
        }
        // We are somewhere between presale start and public sale end.
        if (block.timestamp >= raise.publicSaleStart) {
            // If it's after public sale start, we are in public sale.
            return Phase.PublicSale;
        } else {
            // Presale and public sale might not be continuous, so we may return
            // to the scheduled phase...
            if (block.timestamp > raise.presaleEnd) {
                // If it's after presale end, we are back in scheduled.
                return Phase.Scheduled;
            } else {
                // Otherwise, we must be in presale.
                return Phase.Presale;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenCodec} from "./codecs/TokenCodec.sol";
import {RaiseCodec} from "./codecs/RaiseCodec.sol";
import {TokenData, TokenType} from "../structs/TokenData.sol";
import {RaiseData, TierType} from "../structs/RaiseData.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------- Raise token data is encoded in 30 bytes ----------|
//   4 byte project ID                                   pppppppp
//   4 byte raise ID                             rrrrrrrr
//   4 byte tier ID                      tttttttt
//   1 byte tier type                  TT
//   |------- 17 empty bytes --------|

/// @title RaiseToken - Raise token encoder/decoder
/// @notice Converts numeric token IDs to TokenData/RaiseData structs.
library RaiseToken {
    function encode(TierType _tierType, uint32 _projectId, uint32 _raiseId, uint32 _tierId)
        internal
        pure
        returns (uint256)
    {
        RaiseData memory raiseData =
            RaiseData({tierType: _tierType, projectId: _projectId, raiseId: _raiseId, tierId: _tierId});
        TokenData memory tokenData =
            TokenData({tokenType: TokenType.Raise, encodingVersion: 0, data: RaiseCodec.encode(raiseData)});
        return TokenCodec.encode(tokenData);
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory, RaiseData memory) {
        TokenData memory token = TokenCodec.decode(tokenId);
        RaiseData memory raise = RaiseCodec.decode(token.data);
        return (token, raise);
    }

    function projectId(uint256 tokenId) internal pure returns (uint32) {
        (, RaiseData memory raise) = decode(tokenId);
        return raise.projectId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RaiseData, TierType} from "../../structs/RaiseData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, FOUR_BYTES, FOUR_BYTE_MASK} from "../../constants/Codecs.sol";

// |-------- Raise token data is encoded in 30 bytes -----------|
// 0x000000000000000000000000000000000000000000000000000000000000
// 4 byte project ID                                     pppppppp
// 4 byte raise ID                               rrrrrrrr
// 4 byte tier ID                        tttttttt
// 1 byte tier type                    TT
//   ----------------------------------  17 empty bytes reserved

uint240 constant PROJECT_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant RAISE_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_ID_SIZE = uint240(FOUR_BYTES);
uint240 constant TIER_TYPE_SIZE = uint240(ONE_BYTE);

uint240 constant RAISE_ID_OFFSET = PROJECT_ID_SIZE;
uint240 constant TIER_ID_OFFSET = RAISE_ID_OFFSET + RAISE_ID_SIZE;
uint240 constant TIER_TYPE_OFFSET = TIER_ID_OFFSET + TIER_ID_SIZE;

uint240 constant PROJECT_ID_MASK = uint240(FOUR_BYTE_MASK);
uint240 constant RAISE_ID_MASK = uint240(FOUR_BYTE_MASK) << RAISE_ID_OFFSET;
uint240 constant TIER_ID_MASK = uint240(FOUR_BYTE_MASK) << TIER_ID_OFFSET;
uint240 constant TIER_TYPE_MASK = uint240(ONE_BYTE_MASK) << TIER_TYPE_OFFSET;

bytes17 constant RESERVED_REGION = 0x0;

/// @title RaiseCodec - Raise token encoder/decoder
/// @notice Converts between token data bytes and RaiseData struct.
library RaiseCodec {
    function encode(RaiseData memory raise) internal pure returns (bytes30) {
        bytes memory encoded =
            abi.encodePacked(RESERVED_REGION, raise.tierType, raise.tierId, raise.raiseId, raise.projectId);
        return bytes30(encoded);
    }

    function decode(bytes30 tokenData) internal pure returns (RaiseData memory) {
        uint240 bits = uint240(tokenData);

        uint32 projectId = uint32(bits & PROJECT_ID_MASK);
        uint32 raiseId = uint32((bits & RAISE_ID_MASK) >> RAISE_ID_OFFSET);
        uint32 tierId = uint32((bits & TIER_ID_MASK) >> TIER_ID_OFFSET);
        TierType tierType = TierType((bits & TIER_TYPE_MASK) >> TIER_TYPE_OFFSET);

        return RaiseData({tierType: tierType, tierId: tierId, raiseId: raiseId, projectId: projectId});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenData, TokenType} from "../../structs/TokenData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, THIRTY_BYTE_MASK} from "../../constants/Codecs.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------------------ 30 byte data region -------------------|

uint256 constant TOKEN_TYPE_SIZE = ONE_BYTE;
uint256 constant ENCODING_SIZE = ONE_BYTE;

uint256 constant ENCODING_OFFSET = TOKEN_TYPE_SIZE;
uint256 constant DATA_OFFSET = ENCODING_OFFSET + ENCODING_SIZE;

uint256 constant TOKEN_TYPE_MASK = ONE_BYTE_MASK;
uint256 constant ENCODING_VERSION_MASK = ONE_BYTE_MASK << ENCODING_OFFSET;
uint256 constant DATA_REGION_MASK = THIRTY_BYTE_MASK << DATA_OFFSET;

/// @title RaiseCodec - Token encoder/decoder
/// @notice Converts between token ID and TokenData struct.
library TokenCodec {
    function encode(TokenData memory token) internal pure returns (uint256) {
        bytes memory encoded = abi.encodePacked(token.data, token.encodingVersion, token.tokenType);
        return uint256(bytes32(encoded));
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory) {
        TokenType tokenType = TokenType(tokenId & TOKEN_TYPE_MASK);
        uint8 encodingVersion = uint8((tokenId & ENCODING_VERSION_MASK) >> ENCODING_OFFSET);
        bytes30 data = bytes30(uint240((tokenId & DATA_REGION_MASK) >> DATA_OFFSET));

        return TokenData({tokenType: tokenType, encodingVersion: encodingVersion, data: data});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RaiseParams, RaiseState} from "../../structs/Raise.sol";
import {ITokenAuth} from "../../interfaces/ITokenAuth.sol";
import {ETH} from "../../constants/Constants.sol";

error ValidationError(string message);

library RaiseValidator {
    function validate(RaiseParams memory params, address allowlist) internal view {
        // Currency must be allowlisted
        if (params.currency != ETH) {
            if (ITokenAuth(allowlist).denied(params.currency)) revert ValidationError("invalid token");
        }
        // Zero max means "no maximum"
        if (params.max > 0) {
            // The raise goal cannot be greater than the raise max
            if (params.max < params.goal) {
                revert ValidationError("max < goal");
            }
        }
        // End times must be after start times
        if (params.presaleEnd < params.presaleStart) {
            revert ValidationError("end < start");
        }
        if (params.publicSaleEnd <= params.publicSaleStart) {
            revert ValidationError("end <= start");
        }
        // Public start must be equal to or after presale end
        if (params.publicSaleStart < params.presaleEnd) {
            revert ValidationError("public < presale");
        }
        // Start time must be now or in future. Since we know public start
        // is after presale end and all end times are after start times,
        // we only have to check presale start here.
        if (params.presaleStart < block.timestamp) {
            revert ValidationError("start <= now");
        }
        // Max length of phases is 1 year
        if (params.presaleEnd - params.presaleStart > 365 days) {
            revert ValidationError("too long");
        }
        if (params.publicSaleEnd - params.publicSaleStart > 365 days) {
            revert ValidationError("too long");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TierParams} from "../../structs/Tier.sol";

error ValidationError(string message);

/// @title TierValidator - Tier parameter validator
library TierValidator {
    function validate(TierParams memory tier) internal pure {
        if (tier.supply == 0) {
            revert ValidationError("zero supply");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Tier} from "./Tier.sol";

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
struct RaiseParams {
    uint256 goal;
    uint256 max;
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    address currency;
}

/// @notice A raise may be in one of three states, depending on whether it has
/// ended and has or has not met its goal:
/// - An Active raise has not yet ended.
/// - A Funded raise has ended and met its goal.
/// - A Cancelled raise has ended and did not meet its goal.
enum RaiseState {
    Active,
    Funded,
    Cancelled
}

/// @param goal Target amount to raise. If a raise meets its goal amount, the
/// raise settles as Funded, users keep their tokens, and the owner may withdraw
/// the collected funds. If a raise fails to meet its goual the raise settles as
/// Cancelled and users may redeem their tokens for a refund.
/// @param max Maximum amount to raise.
/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
/// @param state State of the raise. All new raises begin in Active state.
/// @param projectId Integer ID of the project associated with this raise.
/// @param raiseId Integer ID of this raise.
/// @param fanToken Address of this raise's ERC1155 fan token.
/// @param brandToken Address of this raise's ERC1155 brand token.
/// @param raised Total amount of ETH or ERC20 token contributed to this raise.
/// @param balance Creator's share of the total amount raised.
/// @param fees Protocol fees from this raise. raised = balance + fees
struct Raise {
    uint256 goal;
    uint256 max;
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    address currency;
    RaiseState state;
    uint32 projectId;
    uint32 raiseId;
    RaiseTokens tokens;
    uint256 raised;
    uint256 balance;
    uint256 fees;
}

struct RaiseTokens {
    address fanToken;
    address brandToken;
}

/// @notice A raise may be in one of four phases, depending on the timestamps of
/// its presale and public sale phases:
/// - A Scheduled raise is not open for minting. If a raise is Scheduled, it is
/// currently either before the Presale phase or between Presale and PublicSale.
/// - The Presale phase is between the presale start and presale end timestamps.
/// - The PublicSale phase is between the public sale start and public sale end
/// timestamps. PublicSale must be after Presale, but the raise may return to
/// the Scheduled phase in between.
/// - After the public sale end timestamp, the raise has Ended.
enum Phase {
    Scheduled,
    Presale,
    PublicSale,
    Ended
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TierType} from "./Tier.sol";

/// @param projectId Integer ID of the project associated with this raise token.
/// @param raiseId Integer ID of the raise associated with this raise token.
/// @param tierId Integer ID of the tier associated with this raise token.
/// @param tierType Enum indicating whether this is a "fan" or "brand" token.
struct RaiseData {
    uint32 projectId;
    uint32 raiseId;
    uint32 tierId;
    TierType tierType;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum indicating whether a token is a "fan" or "brand" token. Fan
/// tokens are intended for purchase by project patrons and have a lower protocol
/// fee and royalties than brand tokens.
enum TierType {
    Fan,
    Brand
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
struct TierParams {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
/// @param minted Total number of tokens minted in this tier.
struct Tier {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
    uint256 minted;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Enum representing token types. The V1 protocol supports only one
/// token type, "Raise," which represents a crowdfund contribution. However,
/// new token types may be added in the future.
enum TokenType {Raise}

/// @param data 30-byte data region containing encoded token data. The specific
/// format of this data depends on encoding version and token type.
/// @param encodingVersion Encoding version of this token.
/// @param tokenType Enum indicating type of this token. (e.g. Raise)
struct TokenData {
    bytes30 data;
    uint8 encodingVersion;
    TokenType tokenType;
}