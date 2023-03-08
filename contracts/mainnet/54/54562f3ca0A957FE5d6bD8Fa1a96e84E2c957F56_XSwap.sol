// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
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
library StorageSlot {
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
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library NativeClaimer {
    struct State {
        uint256 _valueClaimed;
    }

    function claimed(NativeClaimer.State memory claimer_) internal pure returns (uint256) {
        return claimer_._valueClaimed;
    }

    function unclaimed(NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return msg.value - claimer_._valueClaimed;
    }

    function claim(NativeClaimer.State memory claimer_, uint256 value_) internal view {
        require(unclaimed(claimer_) >= value_, "NC: insufficient msg value");
        claimer_._valueClaimed += value_;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

abstract contract NativeReceiver {
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {NativeClaimer} from "./NativeClaimer.sol";
import {TokenHelper} from "./TokenHelper.sol";

abstract contract NativeReturnMods {
    using NativeClaimer for NativeClaimer.State;

    modifier returnUnclaimedNative(NativeClaimer.State memory claimer_) {
        require(claimer_.claimed() == 0, "NR: claimer already in use");
        _;
        TokenHelper.transferFromThis(TokenHelper.NATIVE_TOKEN, msg.sender, claimer_.unclaimed());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenCheck} from "../swap/Swap.sol";

library TokenChecker {
    function checkMin(TokenCheck calldata check_, uint256 amount_) internal pure returns (uint256) {
        order(check_); min(check_, amount_);
        return capMax(check_, amount_);
    }

    function checkMinMax(TokenCheck calldata check_, uint256 amount_) internal pure {
        order(check_); min(check_, amount_); max(check_, amount_);
    }

    function checkMinMaxToken(TokenCheck calldata check_, uint256 amount_, address token_) internal pure {
        order(check_); min(check_, amount_); max(check_, amount_); token(check_, token_);
    }

    function order(TokenCheck calldata check_) private pure {
        require(check_.minAmount <= check_.maxAmount, "TC: unordered min/max amounts");
    }

    function min(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ >= check_.minAmount, "TC: insufficient token amount");
    }

    function max(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ <= check_.maxAmount, "TC: excessive token amount");
    }

    function token(TokenCheck calldata check_, address token_) private pure {
        require(token_ == check_.token, "TC: wrong token address");
    }

    function capMax(TokenCheck calldata check_, uint256 amount_) private pure returns (uint256) {
        return amount_ < check_.maxAmount ? amount_ : check_.maxAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NativeClaimer} from "./NativeClaimer.sol";

library TokenHelper {
    using NativeClaimer for NativeClaimer.State;

    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier whenNonZero(uint256 amount_) {
        if (amount_ == 0) return;
        _;
    }

    function isNative(address token_) internal pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    function balanceOf(address token_, address owner_, NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return isNative(token_) ? _nativeBalanceOf(owner_, claimer_) : IERC20(token_).balanceOf(owner_);
    }

    function balanceOfThis(address token_, NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return balanceOf(token_, address(this), claimer_);
    }

    function transferToThis(address token_, address from_, uint256 amount_, NativeClaimer.State memory claimer_) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            require(from_ == msg.sender, "TH: native allows sender only");
            claimer_.claim(amount_);
        } else SafeERC20.safeTransferFrom(IERC20(token_), from_, address(this), amount_);
    }

    function transferFromThis(address token_, address to_, uint256 amount_) internal whenNonZero(amount_) {
        isNative(token_) ? Address.sendValue(payable(to_), amount_) : SafeERC20.safeTransfer(IERC20(token_), to_, amount_);
    }

    function approveOfThis(address token_, address spender_, uint256 amount_) internal whenNonZero(amount_) returns (uint256 sendValue) {
        if (isNative(token_)) sendValue = amount_;
        else SafeERC20.safeApprove(IERC20(token_), spender_, amount_);
    }

    function revokeOfThis(address token_, address spender_) internal {
        if (!isNative(token_)) SafeERC20.safeApprove(IERC20(token_), spender_, 0);
    }

    function _nativeBalanceOf(address owner_, NativeClaimer.State memory claimer_) private view returns (uint256 balance) {
        if (owner_ == msg.sender) balance = claimer_.unclaimed();
        else {
            balance = owner_.balance;
            if (owner_ == address(this)) balance -= claimer_.unclaimed();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {SimpleInitializable} from "../misc/SimpleInitializable.sol";
import {Withdrawable} from "../withdraw/Withdrawable.sol";

contract Delegate is SimpleInitializable, Ownable, Withdrawable, NativeReceiver {
    constructor() {
        _initializeWithSender();
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }

    function setOwner(address newOwner_) external whenInitialized onlyInitializer {
        _transferOwnership(newOwner_);
    }

    function _checkWithdraw() internal view override {
        _ensureInitialized();
        _checkOwner();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";
import {Withdraw} from "../withdraw/Withdrawable.sol";
import {Delegate} from "./Delegate.sol";

contract DelegateManager {
    address private immutable _delegatePrototype;
    address private immutable _withdrawWhitelist;

    constructor(address delegatePrototype_, address withdrawWhitelist_) {
        _delegatePrototype = delegatePrototype_;
        _withdrawWhitelist = withdrawWhitelist_;
    }

    modifier onlyWhitelistedWithdrawer() {
        require(AccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender), "DM: withdrawer not whitelisted");
        _;
    }

    function predictDelegateDeploy(address account_) public view returns (address) {
        return Clones.predictDeterministicAddress(_delegatePrototype, _calcSalt(account_));
    }

    function deployDelegate(address account_) public returns (address) {
        Delegate delegate = Delegate(payable(Clones.cloneDeterministic(_delegatePrototype, _calcSalt(account_))));
        delegate.initialize();
        delegate.transferOwnership(account_);
        return address(delegate);
    }

    function isDelegateDeployed(address account_) public view returns (bool) {
        return Address.isContract(predictDelegateDeploy(account_));
    }

    function withdraw(address account_, Withdraw[] calldata withdraws_) external onlyWhitelistedWithdrawer {
        Delegate delegate = Delegate(payable(predictDelegateDeploy(account_)));
        address savedOwner = delegate.owner();
        delegate.setOwner(address(this));
        delegate.withdraw(withdraws_);
        delegate.setOwner(savedOwner);
    }

    function _calcSalt(address account_) private pure returns (bytes32) {
        return bytes20(account_);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library AccountCounter {
    uint256 private constant _ACCOUNT_MIXIN = 0xacc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0;
    uint256 private constant _NULL_INDEX = type(uint256).max;

    struct State {
        uint256[] _accounts;
        uint256[] _counts;
        uint256 _size;
    }

    using AccountCounter for State;

    function create(uint256 maxSize_) internal pure returns (AccountCounter.State memory accountCounter) {
        accountCounter._accounts = new uint256[](maxSize_);
        accountCounter._counts = new uint256[](maxSize_);
    }

    function size(AccountCounter.State memory accountCounter_) internal pure returns (uint256) {
        return accountCounter_._size;
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_, bool insert_) internal pure returns (uint256) {
        uint256 targetAccount = uint160(account_) ^ _ACCOUNT_MIXIN;
        for (uint256 i = 0; i < accountCounter_._accounts.length; i++) {
            uint256 iAccount = accountCounter_._accounts[i];
            if (iAccount == targetAccount) return i;
            if (iAccount == 0) {
                if (!insert_) return _NULL_INDEX;
                accountCounter_._accounts[i] = targetAccount;
                accountCounter_._size = i + 1;
                return i;
            }
        }
        if (!insert_) return _NULL_INDEX;
        revert("AC: insufficient size");
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return indexOf(accountCounter_, account_, true);
    }

    function isNullIndex(uint256 index_) internal pure returns (bool) {
        return index_ == _NULL_INDEX;
    }

    function accountAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (address) {
        return address(uint160(accountCounter_._accounts[index_] ^ _ACCOUNT_MIXIN));
    }

    function get(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return getAt(accountCounter_, indexOf(accountCounter_, account_));
    }

    function getAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (uint256) {
        return accountCounter_._counts[index_];
    }

    function set(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure {
        setAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function setAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure {
        accountCounter_._counts[index_] = count_;
    }

    function add(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure returns (uint256 newCount) {
        return addAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function addAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) + count_;
        setAt(accountCounter_, index_, newCount);
    }

    function sub(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure returns (uint256 newCount) {
        return subAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function subAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) - count_;
        setAt(accountCounter_, index_, newCount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LifeControl is Ownable, Pausable {
    event Terminated(address account);

    bool public terminated;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _requireNotTerminated();
        _unpause();
    }

    function terminate() public onlyOwner whenPaused {
        _requireNotTerminated();
        terminated = true;
        emit Terminated(_msgSender());
    }

    function _requireNotTerminated() private view {
        require(!terminated, "LC: terminated");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract SimpleInitializable {
    function _initializerStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(0x4c943a984a6327bfee4b36cd148236ae13d07c9a3fe7f9857f4809df3e826db1);
    }

    modifier init() {
        _ensureNotInitialized();
        _initializeWithSender();
        _;
    }

    modifier whenInitialized() {
        _ensureInitialized();
        _;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer(), "SI: sender not initializer");
        _;
    }

    function initializer() public view returns (address) {
        return _initializerStorage().value;
    }

    function initialized() public view returns (bool) {
        return initializer() != address(0);
    }

    function initialize() external init {
        _initialize();
    }

    function _initialize() internal virtual;

    function _initializeWithSender() internal {
        _initializerStorage().value = msg.sender;
    }

    function _ensureInitialized() internal view {
        require(initialized(), "SI: not initialized");
    }

    function _ensureNotInitialized() internal view {
        require(!initialized(), "SI: already initialized");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeERC20, IERC20Permit} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureDecomposer} from "./SignatureDecomposer.sol";

contract PermitResolver is SignatureDecomposer {
    function resolvePermit(address token_, address from_, uint256 amount_, uint256 deadline_, bytes calldata signature_) external {
        SafeERC20.safePermit(IERC20Permit(token_), from_, msg.sender, amount_, deadline_, v(signature_), r(signature_), s(signature_));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

abstract contract SignatureDecomposer {
    function r(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[0:32]); }
    function s(bytes calldata sig_) internal pure returns (bytes32) { return bytes32(sig_[32:64]); }
    function v(bytes calldata sig_) internal pure returns (uint8) { return uint8(bytes1(sig_[64:65])); }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

struct TokenCheck {
    address token;
    uint256 minAmount;
    uint256 maxAmount;
}

struct TokenUse {
    address protocol;
    uint256 chain;
    address account;
    uint256[] inIndices;
    TokenCheck[] outs;
    bytes args; // Example of reserved value: 0x44796E616D6963 ("Dynamic")
}

struct SwapStep {
    uint256 chain;
    address swapper;
    address sponsor;
    uint256 nonce;
    uint256 deadline;
    TokenCheck[] ins;
    TokenCheck[] outs;
    TokenUse[] uses;
}

struct Swap {
    address account;
    SwapStep[] steps;
}

struct StealthSwap {
    uint256 chain;
    address swapper;
    address account;
    bytes32[] stepHashes;
}

struct UseParams {
    uint256 chain;
    address account;
    TokenCheck[] ins;
    uint256[] inAmounts;
    TokenCheck[] outs;
    bytes args;
    address msgSender;
    bytes msgData;
}

interface IUseProtocol {
    function use(UseParams calldata params) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NativeClaimer} from "../asset/NativeClaimer.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {NativeReturnMods} from "../asset/NativeReturnMods.sol";
import {TokenChecker} from "../asset/TokenChecker.sol";
import {TokenHelper} from "../asset/TokenHelper.sol";
import {DelegateManager} from "../delegate/DelegateManager.sol";
import {AccountCounter} from "../misc/AccountCounter.sol";
import {PermitResolver} from "../permit/PermitResolver.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";
import {Withdraw} from "../withdraw/Withdrawable.sol";
import {Swap, SwapStep, TokenUse, StealthSwap, TokenCheck, IUseProtocol, UseParams} from "./Swap.sol";
import {SwapSignatureValidator} from "./SwapSignatureValidator.sol";

struct Permit {
    address resolver;
    address token;
    uint256 amount;
    uint256 deadline;
    bytes signature;
}

struct Call {
    address target;
    bytes data;
}

struct SwapParams {
    Swap swap;
    bytes swapSignature;
    uint256 stepIndex;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

struct StealthSwapParams {
    StealthSwap swap;
    bytes swapSignature;
    SwapStep step;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

contract Swapper is NativeReceiver, NativeReturnMods {
    using AccountCounter for AccountCounter.State;

    address private immutable _swapSignatureValidator;
    address private immutable _permitResolverWhitelist;
    address private immutable _useProtocolWhitelist;
    address private immutable _delegateManager;
    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    constructor(address swapSignatureValidator_, address permitResolverWhitelist_, address useProtocolWhitelist_, address delegateManager_) {
        _swapSignatureValidator = swapSignatureValidator_;
        _permitResolverWhitelist = permitResolverWhitelist_;
        _useProtocolWhitelist = useProtocolWhitelist_;
        _delegateManager = delegateManager_;
    }

    function swap(SwapParams calldata params_) external payable {
        _checkSwapEnabled();
        require(params_.stepIndex < params_.swap.steps.length, "SW: no step with provided index");
        SwapStep calldata step = params_.swap.steps[params_.stepIndex];
        _validateSwapSignature(params_.swap, params_.swapSignature);
        _performSwapStep(params_.swap.account, step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function swapStealth(StealthSwapParams calldata params_) external payable {
        _checkSwapEnabled();
        _validateStealthSwapSignature(params_.swap, params_.swapSignature, params_.step);
        _performSwapStep(params_.swap.account, params_.step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function _checkSwapEnabled() internal view virtual {} // Nothing is hindering by default

    function _validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) private view {
        if (_isSignaturePresented(swapSignature_))
            SwapSignatureValidator(_swapSignatureValidator).validateSwapSignature(swap_, swapSignature_);
        else _validateSwapManualCaller(swap_.account);
    }

    function _validateStealthSwapSignature(StealthSwap calldata stealthSwap_, bytes calldata stealthSwapSignature_, SwapStep calldata step_) private view {
        if (_isSignaturePresented(stealthSwapSignature_))
            SwapSignatureValidator(_swapSignatureValidator).validateStealthSwapStepSignature(step_, stealthSwap_, stealthSwapSignature_);
        else {
            _validateSwapManualCaller(stealthSwap_.account);
            SwapSignatureValidator(_swapSignatureValidator).findStealthSwapStepIndex(step_, stealthSwap_); // Ensure presented
        }
    }

    function _isSignaturePresented(bytes calldata signature_) private pure returns (bool) {
        return signature_.length > 0;
    }

    function _validateSwapManualCaller(address account_) private view {
        require(msg.sender == account_, "SW: caller must be swap account");
    }

    function _performSwapStep(address account_, SwapStep calldata step_, Permit[] calldata permits_, uint256[] calldata inAmounts_, Call calldata call_, bytes[] calldata useArgs_) private {
        require(step_.deadline > block.timestamp, "SW: swap step expired");
        require(step_.chain == block.chainid, "SW: wrong swap step chain");
        require(step_.swapper == address(this), "SW: wrong swap step swapper");
        require(step_.ins.length == inAmounts_.length, "SW: in amounts length mismatch");

        _useNonce(account_, step_.nonce);
        _usePermits(account_, permits_);

        uint256[] memory outAmounts = _performCall(account_, step_.sponsor, step_.ins, inAmounts_, step_.outs, call_);
        _performUses(step_.uses, useArgs_, step_.outs, outAmounts);
    }

    function _useNonce(address account_, uint256 nonce_) private {
        require(!_usedNonces[account_][nonce_], "SW: invalid nonce");
        _usedNonces[account_][nonce_] = true;
    }

    function _usePermits(address account_, Permit[] calldata permits_) private {
        for (uint256 i = 0; i < permits_.length; i++)
            _usePermit(account_, permits_[i]);
    }

    function _usePermit(address account_, Permit calldata permit_) private {
        require(_isWhitelistedResolver(permit_.resolver), "SW: permitter not whitelisted");
        PermitResolver(permit_.resolver).resolvePermit(permit_.token, account_, permit_.amount, permit_.deadline, permit_.signature);
    }

    function _isWhitelistedResolver(address resolver_) private view returns (bool) {
        return AccountWhitelist(_permitResolverWhitelist).isAccountWhitelisted(resolver_);
    }

    function _performCall(address account_, address sponsor_, TokenCheck[] calldata ins_, uint256[] calldata inAmounts_, TokenCheck[] calldata outs_, Call calldata call_) private returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        return _performCallWithReturn(account_, sponsor_, ins_, inAmounts_, outs_, call_, nativeClaimer);
    }

    function _performCallWithReturn(address account_, address sponsor_, TokenCheck[] calldata ins_, uint256[] calldata inAmounts_, TokenCheck[] calldata outs_, Call calldata call_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        for (uint256 i = 0; i < ins_.length; i++)
            TokenChecker.checkMinMax(ins_[i], inAmounts_[i]);

        AccountCounter.State memory inAmountsByToken = AccountCounter.create(ins_.length);
        for (uint256 i = 0; i < ins_.length; i++)
            inAmountsByToken.add(ins_[i].token, inAmounts_[i]);

        address delegate = DelegateManager(_delegateManager).predictDelegateDeploy(account_);
        require(sponsor_ == account_ || sponsor_ == delegate || _isWhitelistedResolver(sponsor_), "SW: sponsor not allowed");
        if (sponsor_ == delegate) _claimDelegateCallIns(account_, inAmountsByToken);
        else _claimSponsorCallIns(sponsor_, inAmountsByToken, nativeClaimer_);

        AccountCounter.State memory outBalances = AccountCounter.create(outs_.length);
        for (uint256 i = 0; i < outs_.length; i++) {
            address token = outs_[i].token;
            uint256 sizeBefore = outBalances.size();
            uint256 tokenIndex = outBalances.indexOf(token);
            if (sizeBefore != outBalances.size())
                outBalances.setAt(tokenIndex, TokenHelper.balanceOfThis(token, nativeClaimer_));
        }
        uint256 totalOutTokens = outBalances.size();

        uint256 sendValue = _approveAssets(inAmountsByToken, call_.target);
        bytes memory result = Address.functionCallWithValue(call_.target, call_.data, sendValue);
        _revokeAssets(inAmountsByToken, call_.target);

        for (uint256 i = 0; i < totalOutTokens; i++) {
            uint256 tokenInIndex = inAmountsByToken.indexOf(outBalances.accountAt(i), false);
            if (!AccountCounter.isNullIndex(tokenInIndex))
                outBalances.subAt(i, inAmountsByToken.getAt(tokenInIndex));
        }

        for (uint256 i = 0; i < totalOutTokens; i++)
            outBalances.setAt(i, TokenHelper.balanceOfThis(outBalances.accountAt(i), nativeClaimer_) - outBalances.getAt(i));

        outAmounts = abi.decode(result, (uint256[]));
        require(outAmounts.length == outs_.length, "SW: out amounts length mismatch");

        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = TokenChecker.checkMin(outs_[i], outAmounts[i]);
            outAmounts[i] = amount;
            uint256 tokenIndex = outBalances.indexOf(outs_[i].token, false);
            require(outBalances.getAt(tokenIndex) >= amount, "SW: insufficient out amount");
            outBalances.subAt(tokenIndex, amount);
        }
    }

    function _claimDelegateCallIns(address account_, AccountCounter.State memory inAmountsByToken_) private {
        Withdraw[] memory withdraws = new Withdraw[](inAmountsByToken_.size());
        for (uint256 i = 0; i < inAmountsByToken_.size(); i++)
            withdraws[i] = Withdraw({token: inAmountsByToken_.accountAt(i), amount: inAmountsByToken_.getAt(i), to: address(this)});

        if (!DelegateManager(_delegateManager).isDelegateDeployed(account_))
            DelegateManager(_delegateManager).deployDelegate(account_);
        DelegateManager(_delegateManager).withdraw(account_, withdraws);
    }

    function _claimSponsorCallIns(address sponsor_, AccountCounter.State memory inAmountsByToken_, NativeClaimer.State memory nativeClaimer_) private {
        for (uint256 i = 0; i < inAmountsByToken_.size(); i++)
            TokenHelper.transferToThis(inAmountsByToken_.accountAt(i), sponsor_, inAmountsByToken_.getAt(i), nativeClaimer_);
    }

    function _approveAssets(AccountCounter.State memory amountsByToken_, address spender_) private returns (uint256 sendValue) {
        for (uint256 i = 0; i < amountsByToken_.size(); i++)
            sendValue += TokenHelper.approveOfThis(amountsByToken_.accountAt(i), spender_, amountsByToken_.getAt(i));
    }

    function _revokeAssets(AccountCounter.State memory amountsByToken_, address spender_) private {
        for (uint256 i = 0; i < amountsByToken_.size(); i++)
            TokenHelper.revokeOfThis(amountsByToken_.accountAt(i), spender_);
    }

    function _performUses(TokenUse[] calldata uses_, bytes[] calldata useArgs_, TokenCheck[] calldata useIns_, uint256[] memory useInAmounts_) private {
        uint256 dynamicArgsCursor = 0;
        for (uint256 i = 0; i < uses_.length; i++) {
            bytes calldata args = uses_[i].args;
            if (_shouldUseDynamicArgs(args)) {
                require(dynamicArgsCursor < useArgs_.length, "SW: not enough dynamic use args");
                args = useArgs_[dynamicArgsCursor];
                dynamicArgsCursor++;
            }
            _performUse(uses_[i], args, useIns_, useInAmounts_);
        }
        require(dynamicArgsCursor == useArgs_.length, "SW: too many dynamic use args");
    }

    function _shouldUseDynamicArgs(bytes calldata args_) private pure returns (bool) {
        if (args_.length != 7) return false;
        return bytes7(args_) == 0x44796E616D6963; // "Dynamic" in ASCII
    }

    function _performUse(TokenUse calldata use_, bytes calldata args_, TokenCheck[] calldata useIns_, uint256[] memory useInAmounts_) private {
        require(AccountWhitelist(_useProtocolWhitelist).isAccountWhitelisted(use_.protocol), "SW: use protocol not whitelisted");

        TokenCheck[] memory ins = new TokenCheck[](use_.inIndices.length);
        uint256[] memory inAmounts = new uint256[](use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            uint256 inIndex = use_.inIndices[i];
            require(useInAmounts_[inIndex] != type(uint256).max, "SW: input already spent");
            ins[i] = useIns_[inIndex];
            inAmounts[i] = useInAmounts_[inIndex];
            useInAmounts_[inIndex] = type(uint256).max; // Mark as spent
        }

        AccountCounter.State memory useInAmounts = AccountCounter.create(use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++)
            useInAmounts.add(ins[i].token, inAmounts[i]);

        uint256 sendValue = _approveAssets(useInAmounts, use_.protocol);
        IUseProtocol(use_.protocol).use{value: sendValue}(UseParams({chain: use_.chain, account: use_.account, ins: ins, inAmounts: inAmounts, outs: use_.outs, args: args_, msgSender: msg.sender, msgData: msg.data}));
        _revokeAssets(useInAmounts, use_.protocol);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TokenCheck, TokenUse, SwapStep, Swap, StealthSwap} from "./Swap.sol";

contract SwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) public pure {
        require(swap_.steps.length > 0, "SV: swap has no steps");
        address signer = ECDSA.recover(_hashTypedDataV4(_hashSwap(swap_), swap_.steps[0].chain, swap_.steps[0].swapper), swapSignature_);
        require(signer == swap_.account, "SV: invalid swap signature");
    }

    function validateStealthSwapStepSignature(SwapStep calldata swapStep_, StealthSwap calldata stealthSwap_, bytes calldata stealthSwapSignature_) public pure returns (uint256 stepIndex) {
        address signer = ECDSA.recover(_hashTypedDataV4(_hashStealthSwap(stealthSwap_), stealthSwap_.chain, stealthSwap_.swapper), stealthSwapSignature_);
        require(signer == stealthSwap_.account, "SV: invalid s-swap signature");
        return findStealthSwapStepIndex(swapStep_, stealthSwap_);
    }

    function findStealthSwapStepIndex(SwapStep calldata swapStep_, StealthSwap calldata stealthSwap_) public pure returns (uint256 stepIndex) {
        bytes32 stepHash = _hashSwapStep(swapStep_);
        for (uint256 i = 0; i < stealthSwap_.stepHashes.length; i++)
            if (stealthSwap_.stepHashes[i] == stepHash) return i;
        revert("SV: no step hash match in s-swap");
    }

    function _hashTypedDataV4(bytes32 structHash_, uint256 chainId_, address verifyingContract_) private pure returns (bytes32) {
        bytes32 domainSeparator = keccak256(abi.encode(0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, 0x759f8d0a6b014b7601ff701e703719d70a717971c25deb97628336c51d9e7d86, 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, chainId_, verifyingContract_));
        return ECDSA.toTypedDataHash(domainSeparator, structHash_);
    }

    function _hashSwap(Swap calldata swap_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x09b148e744e0e1801943dd449b1fa4d29b7172ff190d22f95b1bb7e5df52e37d, swap_.account, _hashSwapSteps(swap_.steps)));
    }

    function _hashSwapSteps(SwapStep[] calldata swapSteps_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(swapSteps_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < swapSteps_.length; i++) {
            bytes32 hash = _hashSwapStep(swapSteps_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashSwapStep(SwapStep calldata swapStep_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x5302e49a52f1122ff531999c0f7afcb4d2bfefa7562dfefbdb7ed114d495ea6a, swapStep_.chain, swapStep_.swapper, swapStep_.sponsor, swapStep_.nonce, swapStep_.deadline, _hashTokenChecks(swapStep_.ins), _hashTokenChecks(swapStep_.outs), _hashTokenUses(swapStep_.uses)));
    }

    function _hashTokenChecks(TokenCheck[] calldata tokenChecks_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(tokenChecks_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < tokenChecks_.length; i++) {
            bytes32 hash = _hashTokenCheck(tokenChecks_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashTokenCheck(TokenCheck calldata tokenCheck_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x382391664c9ae06333b02668b6d763ab547bd70c71636e236fdafaacf1e55bdd, tokenCheck_.token, tokenCheck_.minAmount, tokenCheck_.maxAmount));
    }

    function _hashTokenUses(TokenUse[] calldata tokenUses_) private pure returns (bytes32) {
        bytes memory bytesToHash = new bytes(tokenUses_.length << 5); // * 0x20
        uint256 offset; assembly { offset := add(bytesToHash, 0x20) }
        for (uint256 i = 0; i < tokenUses_.length; i++) {
            bytes32 hash = _hashTokenUse(tokenUses_[i]);
            assembly { mstore(offset, hash) offset := add(offset, 0x20) }
        }
        return keccak256(bytesToHash);
    }

    function _hashTokenUse(TokenUse calldata tokenUse_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x192f17c5e66907915b200bca0d866184770ff7faf25a0b4ccd2ef26ebd21725a, tokenUse_.protocol, tokenUse_.chain, tokenUse_.account, keccak256(abi.encodePacked(tokenUse_.inIndices)), _hashTokenChecks(tokenUse_.outs), keccak256(tokenUse_.args)));
    }

    function _hashStealthSwap(StealthSwap calldata stealthSwap_) private pure returns (bytes32) {
        return keccak256(abi.encode(0x0f2b1c8dae54aa1b96d626d678ec60a7c6d113b80ccaf635737a6f003d1cbaf5, stealthSwap_.chain, stealthSwap_.swapper, stealthSwap_.account, keccak256(abi.encodePacked(stealthSwap_.stepHashes))));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SimpleInitializable} from "../misc/SimpleInitializable.sol";

contract AccountWhitelist is Ownable, SimpleInitializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AccountAdded(address account);
    event AccountRemoved(address account);

    EnumerableSet.AddressSet private _accounts;

    constructor() {
        _initializeWithSender();
    }

    function getWhitelistedAccounts() external view returns (address[] memory) {
        return _accounts.values();
    }

    function isAccountWhitelisted(address account_) external view returns (bool) {
        return _accounts.contains(account_);
    }

    function addAccountToWhitelist(address account_) external whenInitialized onlyOwner {
        require(_accounts.add(account_), "AW: account already included");
        emit AccountAdded(account_);
    }

    function removeAccountFromWhitelist(address account_) external whenInitialized onlyOwner {
        require(_accounts.remove(account_), "AW: account already excluded");
        emit AccountRemoved(account_);
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Withdrawable} from "./Withdrawable.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";

abstract contract WhitelistWithdrawable is Withdrawable {
    address private immutable _withdrawWhitelist;

    constructor(address withdrawWhitelist_) {
        _withdrawWhitelist = withdrawWhitelist_;
    }

    function _checkWithdraw() internal view override {
        require(AccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender), "WW: withdrawer not whitelisted");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenHelper} from "../asset/TokenHelper.sol";

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

abstract contract Withdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws_) external virtual {
        _checkWithdraw();
        for (uint256 i = 0; i < withdraws_.length; i++) {
            Withdraw calldata w = withdraws_[i];
            TokenHelper.transferFromThis(w.token, w.to, w.amount);
            emit Withdrawn(w.token, w.amount, w.to);
        }
    }

    function _checkWithdraw() internal view virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Swapper} from "./core/swap/Swapper.sol";
import {WhitelistWithdrawable} from "./core/withdraw/WhitelistWithdrawable.sol";
import {LifeControl} from "./core/misc/LifeControl.sol";

struct XSwapConstructorParams {
    address swapSignatureValidator;
    address permitResolverWhitelist;
    address useProtocolWhitelist;
    address delegateManager;
    address withdrawWhitelist;
    address lifeControl;
}

contract XSwap is Swapper, WhitelistWithdrawable {
    address private immutable _lifeControl;

    constructor(XSwapConstructorParams memory params_)
        WhitelistWithdrawable(params_.withdrawWhitelist)
        Swapper(params_.swapSignatureValidator, params_.permitResolverWhitelist, params_.useProtocolWhitelist, params_.delegateManager) {
        _lifeControl = params_.lifeControl;
    }

    function _checkSwapEnabled() internal view override {
        require(!LifeControl(_lifeControl).paused(), "XS: swapping paused");
    }
}