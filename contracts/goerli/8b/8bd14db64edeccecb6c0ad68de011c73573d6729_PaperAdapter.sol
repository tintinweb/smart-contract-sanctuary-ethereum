// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper Access Token. Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Access Token to a contract
    /// @dev Registers the @param _paperKey with the caller of the function
    /// @param _paperKey The Paper Access Token that is associated with the checkout. You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);

    /// @notice Checks the current registered Paper Access Token for a given contract address
    /// @param _contractAddress The contract address that is to be checked for.
    /// @return address corresponding to the expected paper Access Token that is to be resolved from signature originating from @param _contractAddress
    function checkRegisteredKey(address _contractAddress)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Holder} from "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IRaises} from "../../interfaces/IRaises.sol";
import {ITokens} from "../../interfaces/ITokens.sol";

struct MintERC20Params {
    IRaises raises;
    ITokens tokens;
    IERC20 currency;
    address receiver;
    uint256 mintPrice;
    uint256 tokenId;
}

error Forbidden();

contract MintERC20 is ERC1155Holder {
    using SafeERC20 for IERC20;

    address public immutable adapter;

    constructor() {
        adapter = msg.sender;
    }

    // solhint-disable-next-line comprehensive-interface
    function mint(MintERC20Params calldata params, uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
    {
        if (msg.sender != adapter) revert Forbidden();
        params.currency.safeIncreaseAllowance(address(params.raises), params.mintPrice);
        params.raises.mint(projectId, raiseId, tierId, amount);
        params.tokens.token(params.tokenId).safeTransferFrom(address(this), params.receiver, params.tokenId, amount, "");
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC1155Holder} from "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IRaises} from "../../interfaces/IRaises.sol";
import {ITokens} from "../../interfaces/ITokens.sol";

struct MintETHParams {
    IRaises raises;
    ITokens tokens;
    address receiver;
    uint256 tokenId;
}

error Forbidden();

contract MintETH is ERC1155Holder {
    address public immutable adapter;

    constructor() {
        adapter = msg.sender;
    }

    // solhint-disable-next-line comprehensive-interface
    function mint(MintETHParams calldata params, uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
    {
        if (msg.sender != adapter) revert Forbidden();
        params.raises.mint{value: msg.value}(projectId, raiseId, tierId, amount);
        params.tokens.token(params.tokenId).safeTransferFrom(address(this), params.receiver, params.tokenId, amount, "");
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IPaperKeyManager} from "paper-xyz/keyManager/IPaperKeyManager.sol";

import {Raise} from "../../structs/Raise.sol";
import {Tier, TierType} from "../../structs/Tier.sol";
import {RaiseToken} from "../../libraries/RaiseToken.sol";
import {RaiseData} from "../../structs/RaiseData.sol";
import {Controllable} from "../../abstract/Controllable.sol";
import {IControllable} from "../../interfaces/IControllable.sol";
import {IRaises} from "../../interfaces/IRaises.sol";
import {ITokens} from "../../interfaces/ITokens.sol";
import {IPaperAdapter} from "../../interfaces/IPaperAdapter.sol";
import {ETH} from "../../constants/Constants.sol";
import {MintETH, MintETHParams} from "./MintETH.sol";
import {MintERC20, MintERC20Params} from "./MintERC20.sol";

/// @title PaperAdapter - Adapter for paper.xyz
/// @notice An adapter contract enabling raise mints via paper.xyz payments
contract PaperAdapter is IPaperAdapter, Controllable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant NAME = "PaperAdapter";
    string public constant VERSION = "0.0.1";

    address public raises;
    address public tokens;

    address public immutable mintETHImpl;
    address public immutable mintERC20Impl;

    IPaperKeyManager internal immutable paperKeyManager;

    constructor(address _controller, address _paperKeyManager) Controllable(_controller) {
        mintETHImpl = address(new MintETH());
        mintERC20Impl = address(new MintERC20());
        paperKeyManager = IPaperKeyManager(_paperKeyManager);
    }

    /// @inheritdoc IPaperAdapter
    function mint(
        address receiver,
        uint256 tokenId,
        uint256 mintPrice,
        address currency,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external payable override nonReentrant returns (uint256) {
        bool valid = paperKeyManager.verify(
            keccak256(abi.encode(receiver, tokenId, mintPrice, currency, amount)), nonce, signature
        );
        if (!valid) revert InvalidSignature();
        (, RaiseData memory raiseData) = RaiseToken.decode(tokenId);
        if (currency == ETH) {
            if (mintPrice != 0) revert InvalidMintPrice();
            MintETH(Clones.clone(mintETHImpl)).mint{value: msg.value}(
                MintETHParams({raises: IRaises(raises), tokens: ITokens(tokens), receiver: receiver, tokenId: tokenId}),
                raiseData.projectId,
                raiseData.raiseId,
                raiseData.tierId,
                amount
            );
        } else {
            if (msg.value != 0) revert InvalidMsgValue();
            MintERC20 minter = MintERC20(Clones.clone(mintERC20Impl));
            IERC20(currency).safeTransferFrom(msg.sender, address(minter), mintPrice);
            minter.mint(
                MintERC20Params({
                    raises: IRaises(raises),
                    tokens: ITokens(tokens),
                    currency: IERC20(currency),
                    receiver: receiver,
                    mintPrice: mintPrice,
                    tokenId: tokenId
                }),
                raiseData.projectId,
                raiseData.raiseId,
                raiseData.tierId,
                amount
            );
        }
        return tokenId;
    }

    /// @inheritdoc IPaperAdapter
    function registerPaperKey(address _paperKey) external onlyController {
        bool success = paperKeyManager.register(_paperKey);
        if (!success) revert RegistrationError();
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override(Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "raises") _setRaises(_contract);
        else if (_name == "tokens") _setTokens(_contract);
        else revert InvalidDependency(_name);
    }

    function _setRaises(address _raises) internal {
        emit SetRaises(raises, _raises);
        raises = _raises;
    }

    function _setTokens(address _tokens) internal {
        emit SetTokens(tokens, _tokens);
        tokens = _tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant ONE_BYTE = 0x8;
uint256 constant ONE_BYTE_MASK = type(uint8).max;

uint256 constant TWO_BYTES = 0x10;

uint256 constant FOUR_BYTES = 0x20;
uint256 constant FOUR_BYTE_MASK = type(uint32).max;

uint256 constant THIRTY_BYTES = 0xf0;
uint256 constant THIRTY_BYTE_MASK = type(uint240).max;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev The "dolphin address," a special value representing native ETH.
address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface IPaperAdapter is IControllable, IAnnotated {
    event SetRaises(address oldRaises, address newRaises);
    event SetTokens(address oldTokens, address newTokens);

    error RegistrationError();
    error InvalidSignature();
    error InvalidMintPrice();
    error InvalidMsgValue();

    /// @notice Callback to mint a raise token for paper.xyz credit card payment
    /// integration. Must provide a signature generated by paper.xyz to mint from
    /// this function. This function accepts a number of parameters calculated
    /// off chain in order to minimize the gas cost of minting through the adapter.
    /// @param receiver Final recipient of the minted token.
    /// @param tokenId ID of token to mint. (Project, raise, and tier are decoded
    /// from the tokenId).
    /// @param mintPrice Total cost to mint in base currency. Must be zero for
    /// ETH mints, which instead pass price using `msg.value`.
    /// @param currency Mint currency: ERC20 address or dolphin address for ETH.
    /// @param amount Quantity of tokens to mint.
    /// @param nonce Nonce provided by paper.xyz caller.
    /// @param signature Signature provided by paper.xyz caller.
    /// @return tokenId uint256 Minted token ID.
    function mint(
        address receiver,
        uint256 tokenId,
        uint256 mintPrice,
        address currency,
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external payable returns (uint256);

    /// @notice Register a paper.xyz signer address with this contract, used to
    /// verify paper.xyz generated signatures.
    /// @param _paperKey address of paper.xyz signer account.
    function registerPaperKey(address _paperKey) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {IPausable} from "./IPausable.sol";
import {Raise, RaiseParams, RaiseState, Phase, FeeSchedule} from "../structs/Raise.sol";
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
    /// @notice The raise has started and can no longer be updated.
    error RaiseHasStarted();
    /// @notice The raise has not yet started and is in the Scheduled phase.
    error RaiseNotStarted();
    /// @notice This token tier is sold out, or an attempt to mint would exceed the maximum supply.
    error RaiseSoldOut();
    /// @notice The caller's token balance is zero.
    error ZeroBalance();
    /// @notice One or both fees in the provided fee schedule equal or exceed 100%.
    error InvalidFeeSchedule();

    event CreateRaise(
        uint32 indexed projectId,
        uint32 raiseId,
        RaiseParams params,
        TierParams[] tiers,
        address fanToken,
        address brandToken
    );
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

    event SetFeeSchedule(FeeSchedule oldFeeSchedule, FeeSchedule newFeeSchedule);
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

    /// @notice Set a new fee schedule. May only be called by `controller` contract.
    /// @param _feeSchedule FeeSchedule new fee schedule.
    function setFeeSchedule(FeeSchedule calldata _feeSchedule) external;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenCodec} from "./codecs/TokenCodec.sol";
import {RaiseCodec} from "./codecs/RaiseCodec.sol";
import {TokenData, TokenType} from "../structs/TokenData.sol";
import {RaiseData, TierType} from "../structs/RaiseData.sol";
import {TWO_BYTES} from "../constants/Codecs.sol";

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
        return uint32(tokenId >> TWO_BYTES);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
/// - A Cancelled raise has ended and either did not meet its goal or was
///   cancelled by the raise creator.
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
/// @param timestamps Struct containing presale and public sale start/end times.
/// @param currency Currency for this raise, either an ERC20 token address, or
/// the "dolphin address" for ETH. ERC20 tokens must be allowed by TokenAuth.
/// @param state State of the raise. All new raises begin in Active state.
/// @param projectId Integer ID of the project associated with this raise.
/// @param raiseId Integer ID of this raise.
/// @param tokens Struct containing addresses of this raise's tokens.
/// @param feeSchedule Struct containing fee schedule for this raise.
/// @param raised Total amount of ETH or ERC20 token contributed to this raise.
/// @param balance Creator's share of the total amount raised.
/// @param fees Protocol fees from this raise. raised = balance + fees
struct Raise {
    uint256 goal;
    uint256 max;
    RaiseTimestamps timestamps;
    address currency;
    RaiseState state;
    uint32 projectId;
    uint32 raiseId;
    RaiseTokens tokens;
    FeeSchedule feeSchedule;
    uint256 raised;
    uint256 balance;
    uint256 fees;
}

/// @param presaleStart Start timestamp of the presale phase. During this phase,
/// allowlisted users may mint tokens by providing a Merkle proof.
/// @param presaleEnd End timestamp of the presale phase.
/// @param publicSaleStart Start timestamp of the public sale phase. During this
/// phase, any user may mint a token.
/// @param publicSaleEnd End timestamp of the public sale phase.
struct RaiseTimestamps {
    uint64 presaleStart;
    uint64 presaleEnd;
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
}

/// @param fanToken Address of this raise's ERC1155 fan token.
/// @param brandToken Address of this raise's ERC1155 brand token.
struct RaiseTokens {
    address fanToken;
    address brandToken;
}

/// @param fanFee Protocol fee in basis points for fan token sales.
/// @param brandFee Protocol fee in basis poitns for brand token sales.
struct FeeSchedule {
    uint16 fanFee;
    uint16 brandFee;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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