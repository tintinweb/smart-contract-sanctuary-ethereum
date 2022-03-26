// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IEverscale.sol";
pragma experimental ABIEncoderV2;


interface IBridge is IEverscale {
    struct Round {
        uint32 end;
        uint32 ttl;
        uint32 relays;
        uint32 requiredSignatures;
    }

    function updateMinimumRequiredSignatures(uint32 _minimumRequiredSignatures) external;
    function setConfiguration(EverscaleAddress calldata _roundRelaysConfiguration) external;
    function updateRoundTTL(uint32 _roundTTL) external;

    function isRelay(
        uint32 round,
        address candidate
    ) external view returns (bool);

    function isBanned(
        address candidate
    ) external view returns (bool);

    function isRoundRotten(
        uint32 round
    ) external view returns (bool);

    function verifySignedEverscaleEvent(
        bytes memory payload,
        bytes[] memory signatures
    ) external view returns (uint32);

    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;

    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    function setRoundSubmitter(address _roundSubmitter) external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(EverscaleAddress configuration);
    event UpdateRoundSubmitter(address _roundSubmitter);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IEverscale {
    struct EverscaleAddress {
        int8 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "../IEverscale.sol";


interface IMultiVault is IEverscale {
    enum Fee { Deposit, Withdraw }
    enum TokenType { Native, Alien }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
    }

    struct NativeWithdrawalParams {
        EverscaleAddress native;
        TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
    }

    function defaultDepositFee() external view returns (uint);
    function defaultWithdrawFee() external view returns (uint);

    function apiVersion() external view returns (string memory api_version);

    function initialize(
        address _bridge,
        address _governance,
        EverscaleAddress memory _rewards
    ) external;

    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (EverscaleAddress memory);

    function blacklistAddToken(address token) external;
    function blacklistRemoveToken(address token) external;

    function setTokenDepositFee(address token, uint _depositFee) external;
    function setTokenWithdrawFee(address token, uint _withdrawFee) external;

    function setDefaultDepositFee(uint _defaultDepositFee) external;
    function setDefaultWithdrawFee(uint _defaultWithdrawFee) external;

    function rewards() external view returns (EverscaleAddress memory);

    function configurationAlien() external view returns (EverscaleAddress memory);
    function configurationNative() external view returns (EverscaleAddress memory);

    function withdrawalIds(bytes32) external view returns (bool);
    function bridge() external view returns(address);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function emergencyShutdown() external view returns (bool);
    function setEmergencyShutdown(bool active) external;

    function setConfigurationAlien(EverscaleAddress memory _configuration) external;
    function setConfigurationNative(EverscaleAddress memory _configuration) external;

    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;

    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint amount
    ) external;

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function migrateAlienTokenToVault(
        address token,
        address vault
    ) external;

    event BlacklistTokenAdded(address token);
    event BlacklistTokenRemoved(address token);

    event UpdateDefaultDepositFee(uint fee);
    event UpdateDefaultWithdrawFee(uint fee);

    event UpdateBridge(address bridge);
    event UpdateConfiguration(TokenType _type, int128 wid, uint256 addr);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateTokenDepositFee(address token, uint256 fee);
    event UpdateTokenWithdrawFee(address token, uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);

    event TokenMigrated(address token, address vault);

    event TokenActivated(
        address token,
        uint activation,
        bool isNative,
        uint depositFee,
        uint withdrawFee
    );

    event TokenCreated(
        address token,
        int8 native_wid,
        uint256 native_addr,
        string name,
        string symbol,
        uint8 decimals
    );

    event AlienTransfer(
        uint256 base_chainId,
        uint160 base_token,
        string name,
        string symbol,
        uint8 decimals,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr
    );

    event NativeTransfer(
        int8 native_wid,
        uint256 native_addr,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr
    );

    event Deposit(
        TokenType _type,
        address sender,
        address token,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint256 amount,
        uint256 fee
    );

    event Withdraw(
        TokenType _type,
        bytes32 payloadId,
        address token,
        address recipient,
        uint256 amunt,
        uint256 fee
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IMultiVaultToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external;

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IVaultBasic.sol";


interface IVault is IVaultBasic {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalSkim;
        uint256 totalLoss;
        address rewardsManager;
        EverscaleAddress rewards;
    }

    struct PendingWithdrawalParams {
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function initialize(
        address _token,
        address _bridge,
        address _governance,
        uint _targetDecimals,
        EverscaleAddress memory _rewards
    ) external;

    function withdrawGuardian() external view returns (address);

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawals(
        address user,
        uint id
    ) external view returns (PendingWithdrawalParams memory);
    function pendingWithdrawalsTotal() external view returns (uint);

    function managementFee() external view returns (uint256);
    function performanceFee() external view returns (uint256);

    function strategies(
        address strategyId
    ) external view returns (StrategyParams memory);
    function withdrawalQueue() external view returns (address[20] memory);

    function withdrawLimitPerPeriod() external view returns (uint256);
    function undeclaredWithdrawLimit() external view returns (uint256);
    function withdrawalPeriods(
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);

    function depositLimit() external view returns (uint256);
    function debtRatio() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function lastReport() external view returns (uint256);
    function lockedProfit() external view returns (uint256);
    function lockedProfitDegradation() external view returns (uint256);

    function setWithdrawGuardian(address _withdrawGuardian) external;
    function setStrategyRewards(
        address strategyId,
        EverscaleAddress memory _rewards
    ) external;
    function setLockedProfitDegradation(uint256 degradation) external;
    function setDepositLimit(uint256 limit) external;
    function setPerformanceFee(uint256 fee) external;
    function setManagementFee(uint256 fee) external;
    function setWithdrawLimitPerPeriod(uint256 _withdrawLimitPerPeriod) external;
    function setUndeclaredWithdrawLimit(uint256 _undeclaredWithdrawLimit) external;
    function setWithdrawalQueue(address[20] memory queue) external;
    function setPendingWithdrawalBounty(uint256 id, uint256 bounty) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount,
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;
    function deposit(
        EverscaleAddress memory recipient,
        uint256[] memory amount,
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;
    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    ) external;

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    ) external returns (
        bool instantWithdrawal,
        PendingWithdrawalId memory pendingWithdrawalId
    );

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    ) external;

    function withdraw(
        uint256 id,
        uint256 amountRequested,
        address recipient,
        uint256 maxLoss,
        uint bounty
    ) external returns(uint256);

    function addStrategy(
        address strategyId,
        uint256 _debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 _performanceFee
    ) external;

    function updateStrategyDebtRatio(
        address strategyId,
        uint256 _debtRatio
    )  external;

    function updateStrategyMinDebtPerHarvest(
        address strategyId,
        uint256 minDebtPerHarvest
    ) external;

    function updateStrategyMaxDebtPerHarvest(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) external;

    function updateStrategyPerformanceFee(
        address strategyId,
        uint256 _performanceFee
    ) external;

    function migrateStrategy(
        address oldVersion,
        address newVersion
    ) external;

    function revokeStrategy(
        address strategyId
    ) external;
    function revokeStrategy() external;


    function totalAssets() external view returns (uint256);
    function debtOutstanding(address strategyId) external view returns (uint256);
    function debtOutstanding() external view returns (uint256);

    function creditAvailable(address strategyId) external view returns (uint256);
    function creditAvailable() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);
    function expectedReturn(address strategyId) external view returns (uint256);

    function report(
        uint256 profit,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function skim(address strategyId) external;

    function forceWithdraw(
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;


    event PendingWithdrawalUpdateBounty(address recipient, uint256 id, uint256 bounty);
    event PendingWithdrawalCancel(address recipient, uint256 id, uint256 amount);
    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes32 payloadId
    );
    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 requestedAmount,
        uint256 redeemedAmount
    );
    event PendingWithdrawalFill(
        address recipient,
        uint256 id
    );
    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        ApproveStatus approveStatus
    );

    event UpdateWithdrawLimitPerPeriod(uint256 withdrawLimitPerPeriod);
    event UpdateUndeclaredWithdrawLimit(uint256 undeclaredWithdrawLimit);
    event UpdateDepositLimit(uint256 depositLimit);

    event UpdatePerformanceFee(uint256 performanceFee);
    event UpdateManagementFee(uint256 managenentFee);

    event UpdateWithdrawGuardian(address withdrawGuardian);
    event UpdateWithdrawalQueue(address[20] queue);

    event StrategyUpdateDebtRatio(address indexed strategy, uint256 debtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 minDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 maxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 performanceFee);
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
    event StrategyRevoked(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event StrategyAddedToQueue(address indexed strategy);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalSkim,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );
    event StrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    );
    event StrategyUpdateRewards(
        address strategyId,
        int128 wid,
        uint256 addr
    );
    event FactoryDeposit(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes1 separator,
        bytes level3
    );

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "../IEverscale.sol";


interface IVaultBasic is IEverscale {
    struct WithdrawalParams {
        EverscaleAddress sender;
        uint256 amount;
        address recipient;
        uint32 chainId;
    }

    function bridge() external view returns (address);
    function configuration() external view returns (EverscaleAddress memory);
    function withdrawalIds(bytes32) external view returns (bool);
    function rewards() external view returns (EverscaleAddress memory);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function token() external view returns (address);
    function targetDecimals() external view returns (uint256);
    function tokenDecimals() external view returns (uint256);

    function depositFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);

    function emergencyShutdown() external view returns (bool);

    function apiVersion() external view returns (string memory api_version);

    function setDepositFee(uint _depositFee) external;
    function setWithdrawFee(uint _withdrawFee) external;

    function setConfiguration(EverscaleAddress memory _configuration) external;
    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;
    function setEmergencyShutdown(bool active) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    ) external;

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) external view returns(WithdrawalParams memory);

    function sweep(address _token) external;

    // Events
    event Deposit(
        uint256 amount,
        int128 wid,
        uint256 addr
    );

    event InstantWithdrawal(
        bytes32 payloadId,
        address recipient,
        uint256 amount
    );

    event UpdateBridge(address bridge);
    event UpdateConfiguration(int128 wid, uint256 addr);
    event UpdateTargetDecimals(uint256 targetDecimals);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateDepositFee(uint256 fee);
    event UpdateWithdrawFee(uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "./../interfaces/multivault/IMultiVault.sol";
import "./../interfaces/IEverscale.sol";


library MultiVaultLibrary {
    function decodeNativeWithdrawalEventData(
        bytes memory eventData
    ) internal pure returns (IMultiVault.NativeWithdrawalParams memory) {
        (
            int8 native_wid,
            uint256 native_addr,

            string memory name,
            string memory symbol,
            uint8 decimals,

            uint128 amount,
            uint160 recipient,
            uint256 chainId
        ) = abi.decode(
            eventData,
            (
                int8, uint256,
                string, string, uint8,
                uint128, uint160, uint256
            )
        );

        return IMultiVault.NativeWithdrawalParams({
            native: IEverscale.EverscaleAddress(native_wid, native_addr),
            meta: IMultiVault.TokenMeta(name, symbol, decimals),
            amount: amount,
            recipient: address(recipient),
            chainId: chainId
        });
    }

    function decodeAlienWithdrawalEventData(
        bytes memory eventData
    ) internal pure returns (IMultiVault.AlienWithdrawalParams memory) {
        (
            uint160 token,
            uint128 amount,
            uint160 recipient,
            uint256 chainId
        ) = abi.decode(
            eventData,
            (uint160, uint128, uint160, uint256)
        );

        return IMultiVault.AlienWithdrawalParams({
            token: address(token),
            amount: uint256(amount),
            recipient: address(recipient),
            chainId: chainId
        });
    }

    /// @notice Calculates the CREATE2 address for token, based on the Everscale sig
    /// @param native_wid Everscale token workchain ID
    /// @param native_addr Everscale token address body
    /// @return token Token address
    function getNativeToken(
        int8 native_wid,
        uint256 native_addr
    ) internal view returns (address token) {
        token = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(native_wid, native_addr)),
            hex'f906ad1ce83ab732d793f0a6616e037f193f2bb624880b305bf4af30b8ab228e' // MultiVaultToken init code hash
        )))));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./../interfaces/multivault/IMultiVault.sol";
import "./../interfaces/multivault/IMultiVaultToken.sol";
import "./../interfaces/IBridge.sol";
import "./../interfaces/vault/IVault.sol";

import "./../libraries/MultiVaultLibrary.sol";

import "./MultiVaultToken.sol";
import "./../utils/ChainId.sol";


uint constant MAX_BPS = 10_000;
uint constant FEE_LIMIT = MAX_BPS / 2;
address constant ZERO_ADDRESS = address(0);

uint8 constant DECIMALS_LIMIT = 18;
uint256 constant SYMBOL_LENGTH_LIMIT = 32;
uint256 constant NAME_LENGTH_LIMIT = 32;


string constant API_VERSION = '0.1.1';


/// @notice Vault, based on Octus Bridge. Allows to transfer arbitrary tokens from Everscale
/// to EVM and backwards. Everscale tokens are called "natives" (eg QUBE). EVM tokens are called
/// "aliens" (eg AAVE).
/// Inspired by Yearn Vault V2.
contract MultiVault is IMultiVault, ReentrancyGuard, Initializable, ChainId {
    using SafeERC20 for IERC20;

//    function getInitHash() public pure returns(bytes32){
//        bytes memory bytecode = type(MultiVaultToken).creationCode;
//        return keccak256(abi.encodePacked(bytecode));
//    }

    mapping (address => Token) tokens_;
    mapping (address => EverscaleAddress) natives_;

    uint public override defaultDepositFee;
    uint public override defaultWithdrawFee;

    bool public override emergencyShutdown;

    address public override bridge;
    mapping(bytes32 => bool) public override withdrawalIds;
    EverscaleAddress rewards_;
    EverscaleAddress configurationNative_;

    address public override governance;
    address pendingGovernance;
    address public override guardian;
    address public override management;

    // STORAGE UPDATE 1
    EverscaleAddress configurationAlien_;

    /// @notice Get token information
    /// @param _token Token address
    function tokens(
        address _token
    ) external view override returns (Token memory) {
        return tokens_[_token];
    }

    /// @notice Get native Everscale token address for EVM token
    /// @param _token Token address
    function natives(
        address _token
    ) external view override returns (EverscaleAddress memory) {
        return natives_[_token];
    }

    /// @notice Rewards address
    /// @return Everscale address, used for collecting rewards.
    function rewards()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return rewards_;
    }

    /// @notice Native configuration address
    /// @return Everscale address, used for verifying native withdrawals
    function configurationNative()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationNative_;
    }

    /// @notice Alien configuration address
    /// @return Everscale address, used for verifying alien withdrawals
    function configurationAlien()
        external
        view
        override
    returns (EverscaleAddress memory) {
        return configurationAlien_;
    }

    modifier tokenNotBlacklisted(address token) {
        require(!tokens_[token].blacklisted);

        _;
    }

    modifier initializeToken(address token) {
        if (tokens_[token].activation == 0) {
            // Non-activated tokens are always aliens

            require(
                IERC20Metadata(token).decimals() <= DECIMALS_LIMIT &&
                bytes(IERC20Metadata(token).symbol()).length <= SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(token).name()).length <= NAME_LENGTH_LIMIT
            );

            _activateToken(token, false);
        }

        _;
    }

    modifier onlyEmergencyDisabled() {
        require(!emergencyShutdown, "Vault: emergency mode enabled");

        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);

        _;
    }

    modifier onlyPendingGovernance() {
        require(msg.sender == pendingGovernance);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        require(msg.sender == governance || msg.sender == management);

        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(msg.sender == governance || msg.sender == guardian);

        _;
    }

    modifier withdrawalNotSeenBefore(bytes memory payload) {
        bytes32 withdrawalId = keccak256(payload);

        require(!withdrawalIds[withdrawalId], "Vault: withdraw payload already seen");

        _;

        withdrawalIds[withdrawalId] = true;
    }

    modifier respectFeeLimit(uint fee) {
        require(fee <= FEE_LIMIT);

        _;
    }

    /// @notice Vault API version. Used to track the deployed version of this contract.
    //  @return api_version Current API version
    function apiVersion()
        external
        override
        pure
        returns (string memory api_version)
    {
        return API_VERSION;
    }

    /// @notice MultiVault initializer
    /// @param _bridge Bridge address
    /// @param _governance Governance address
    /// @param _rewards Everscale address for receiving rewards
    function initialize(
        address _bridge,
        address _governance,
        EverscaleAddress memory _rewards
    ) external override initializer {
        bridge = _bridge;
        emit UpdateBridge(bridge);

        governance = _governance;
        emit UpdateGovernance(governance);

        rewards_ = _rewards;
        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Add token to blacklist. Only native token can be blacklisted.
    /// Blacklisted tokens cant be deposited or withdrawn.
    /// @param token Token address
    function blacklistAddToken(
        address token
    ) public override onlyGovernance tokenNotBlacklisted(token) {
        tokens_[token].blacklisted = true;

        emit BlacklistTokenAdded(token);
    }

    /// @notice Remove token from blacklist.
    /// @param token Token address
    function blacklistRemoveToken(
        address token
    ) external override onlyGovernance {
        require(tokens_[token].blacklisted);

        tokens_[token].blacklisted = false;

        emit BlacklistTokenRemoved(token);
    }

    /// @notice Set address to receive fees.
    /// This may be called only by `governance`
    /// @param _rewards Rewards receiver in Everscale network
    function setRewards(
        EverscaleAddress memory _rewards
    ) external override onlyGovernance {
        rewards_ = _rewards;

        emit UpdateRewards(rewards_.wid, rewards_.addr);
    }

    /// @notice Set default deposit fee.
    /// @param _defaultDepositFee Default deposit fee, should be less than FEE_LIMIT
    function setDefaultDepositFee(
        uint _defaultDepositFee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_defaultDepositFee)
    {
        defaultDepositFee = _defaultDepositFee;

        emit UpdateDefaultDepositFee(defaultDepositFee);
    }

    /// @notice Set default withdraw fee.
    /// @param _defaultWithdrawFee Default withdraw fee, should be less than FEE_LIMIT
    function setDefaultWithdrawFee(
        uint _defaultWithdrawFee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_defaultWithdrawFee)
    {
        defaultWithdrawFee = _defaultWithdrawFee;

        emit UpdateDefaultWithdrawFee(defaultWithdrawFee);
    }

    /// @notice Set deposit fee for specific token.
    /// This may be called only by `owner` or `management`.
    /// @param token Token address
    /// @param _depositFee Deposit fee, must be less than FEE_LIMIT.
    function setTokenDepositFee(
        address token,
        uint _depositFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_depositFee)
    {
        tokens_[token].depositFee = _depositFee;

        emit UpdateTokenDepositFee(token, _depositFee);
    }

    /// @notice Set withdraw fee for specific token.
    /// This may be called only by `governance` or `management`
    /// @param token Token address, must be enabled
    /// @param _withdrawFee Withdraw fee, must be less than FEE_LIMIT.
    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_withdrawFee)
    {
        tokens_[token].withdrawFee = _withdrawFee;

        emit UpdateTokenWithdrawFee(token, _withdrawFee);
    }

    /// @notice Set alien configuration address.
    /// @param _configuration The address to use for alien configuration.
    function setConfigurationAlien(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationAlien_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Alien,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Set native configuration address.
    /// @param _configuration The address to use for native configuration.
    function setConfigurationNative(
        EverscaleAddress memory _configuration
    ) external override onlyGovernance {
        configurationNative_ = _configuration;

        emit UpdateConfiguration(
            TokenType.Native,
            _configuration.wid,
            _configuration.addr
        );
    }

    /// @notice Nominate new address to use as a governance.
    /// The change does not go into effect immediately. This function sets a
    /// pending change, and the governance address is not updated until
    /// the proposed governance address has accepted the responsibility.
    /// This may only be called by the `governance`.
    /// @param _governance The address requested to take over Vault governance.
    function setGovernance(
        address _governance
    ) external override onlyGovernance {
        pendingGovernance = _governance;

        emit NewPendingGovernance(pendingGovernance);
    }

    /// @notice Once a new governance address has been proposed using `setGovernance`,
    /// this function may be called by the proposed address to accept the
    /// responsibility of taking over governance for this contract.
    /// This may only be called by the `pendingGovernance`.
    function acceptGovernance()
        external
        override
        onlyPendingGovernance
    {
        governance = pendingGovernance;

        emit UpdateGovernance(governance);
    }

    /// @notice Changes the management address.
    /// This may only be called by `governance`
    /// @param _management The address to use for management.
    function setManagement(
        address _management
    )
        external
        override
        onlyGovernance
    {
        management = _management;

        emit UpdateManagement(management);
    }

    /// @notice Changes the address of `guardian`.
    /// This may only be called by `governance`.
    /// @param _guardian The new guardian address to use.
    function setGuardian(
        address _guardian
    )
        external
        override
        onlyGovernance
    {
        guardian = _guardian;

        emit UpdateGuardian(guardian);
    }

    /// @notice Activates or deactivates MultiVault emergency shutdown.
    ///     During emergency shutdown:
    ///     - Deposits are disabled
    ///     - Withdrawals are disabled
    /// This may only be called by `governance` or `guardian`.
    /// @param active If `true`, the MultiVault goes into Emergency Shutdown. If `false`, the MultiVault goes back into
    ///     Normal Operation.
    function setEmergencyShutdown(
        bool active
    ) external override {
        if (active) {
            require(msg.sender == guardian || msg.sender == governance);
        } else {
            require(msg.sender == governance);
        }

        emergencyShutdown = active;

        emit EmergencyShutdown(active);
    }

    /// @notice Transfer tokens to the Everscale. Works both for native and alien tokens.
    /// Approve is required only for alien tokens deposit.
    /// @param recipient Everscale recipient.
    /// @param token EVM token address, should not be blacklisted.
    /// @param amount Amount of tokens to transfer.
    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint amount
    )
        external
        override
        nonReentrant
        tokenNotBlacklisted(token)
        initializeToken(token)
        onlyEmergencyDisabled
    {
        uint fee = calculateMovementFee(amount, token, Fee.Deposit);

        bool isNative = tokens_[token].isNative;

        if (isNative) {
            IMultiVaultToken(token).burn(
                msg.sender,
                amount
            );

            _transferToEverscaleNative(token, recipient, amount - fee);

            if (fee > 0) _transferToEverscaleNative(token, rewards_, fee);
        } else {
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );

            _transferToEverscaleAlien(token, recipient, amount - fee);

            if (fee > 0) _transferToEverscaleAlien(token, rewards_, fee);
        }

        emit Deposit(
            isNative ? TokenType.Native : TokenType.Alien,
            msg.sender,
            token,
            recipient.wid,
            recipient.addr,
            amount,
            fee
        );
    }

    /// @notice Save withdrawal for native token
    /// @param payload Withdraw payload
    /// @param signatures Payload signatures
    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationNative_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        NativeWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeNativeWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Derive token address
        // Depends on the withdrawn token source
        address token = _getNativeWithdrawalToken(withdrawal);

        // Ensure token is not blacklisted
        require(!tokens_[token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            token,
            Fee.Withdraw
        );

        IMultiVaultToken(token).mint(
            withdrawal.recipient,
            withdrawal.amount - fee
        );

        if (fee > 0) _transferToEverscaleNative(token, rewards_, fee);

        emit Withdraw(
            TokenType.Native,
            payloadId,
            token,
            withdrawal.recipient,
            withdrawal.amount,
            fee
        );
    }

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            configurationAlien_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        AlienWithdrawalParams memory withdrawal = MultiVaultLibrary.decodeAlienWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == getChainID());

        // Ensure token is not blacklisted
        require(!tokens_[withdrawal.token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = calculateMovementFee(
            withdrawal.amount,
            withdrawal.token,
            Fee.Withdraw
        );

        IERC20(withdrawal.token).safeTransfer(
            withdrawal.recipient,
            withdrawal.amount - fee
        );

        if (fee > 0) _transferToEverscaleAlien(withdrawal.token, rewards_, fee);

        emit Withdraw(
            TokenType.Alien,
            payloadId,
            withdrawal.token,
            withdrawal.recipient,
            withdrawal.amount,
            fee
        );
    }

    function migrateAlienTokenToVault(
        address token,
        address vault
    )
        external
        override
        onlyGovernance
    {
        require(tokens_[token].activation > 0);
        require(!tokens_[token].isNative);

        require(IVault(vault).token() == token);
        require(IVault(token).governance() == governance);

        tokens_[token].blacklisted = true;

        IERC20(token).safeTransfer(
            vault,
            IERC20(token).balanceOf(address(this))
        );

        emit TokenMigrated(token, vault);
    }

    /// @notice Calculates fee for deposit or withdrawal.
    /// @param amount Amount of tokens.
    /// @param _token Token address.
    /// @param fee Fee type (Deposit = 0, Withdraw = 1).
    function calculateMovementFee(
        uint256 amount,
        address _token,
        Fee fee
    ) public view returns (uint256) {
        Token memory token = tokens_[_token];

        uint tokenFee = fee == Fee.Deposit ? token.depositFee : token.withdrawFee;

        return tokenFee * amount / MAX_BPS;
    }

    function getNativeToken(
        int8 native_wid,
        uint256 native_addr
    ) external view returns (address) {
        return MultiVaultLibrary.getNativeToken(native_wid, native_addr);
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        tokens_[token].activation = block.number;
        tokens_[token].blacklisted = false;
        tokens_[token].isNative = isNative;
        tokens_[token].depositFee = defaultDepositFee;
        tokens_[token].withdrawFee = defaultWithdrawFee;

        emit TokenActivated(
            token,
            block.number,
            isNative,
            defaultDepositFee,
            defaultWithdrawFee
        );
    }

    function _transferToEverscaleNative(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        EverscaleAddress memory native = natives_[_token];

        emit NativeTransfer(
            native.wid,
            native.addr,
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _transferToEverscaleAlien(
        address _token,
        EverscaleAddress memory recipient,
        uint amount
    ) internal {
        emit AlienTransfer(
            getChainID(),
            uint160(_token),
            IERC20Metadata(_token).name(),
            IERC20Metadata(_token).symbol(),
            IERC20Metadata(_token).decimals(),
            uint128(amount),
            recipient.wid,
            recipient.addr
        );
    }

    function _getNativeWithdrawalToken(
        NativeWithdrawalParams memory withdrawal
    ) internal returns (address token) {
        token = MultiVaultLibrary.getNativeToken(
            withdrawal.native.wid,
            withdrawal.native.addr
        );

        if (tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            natives_[token] = withdrawal.native;
        }
    }

    function _deployTokenForNative(
        EverscaleAddress memory native,
        TokenMeta memory meta
    ) internal returns (address token) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked('Octus ', meta.name)),
            string(abi.encodePacked('oct', meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }

    function _processWithdrawEvent(
        bytes memory payload,
        bytes[] memory signatures,
        EverscaleAddress memory configuration
    ) internal returns (EverscaleEvent memory) {
        require(
            IBridge(bridge).verifySignedEverscaleEvent(payload, signatures) == 0,
            "Vault: signatures verification failed"
        );

        // Decode Everscale event
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == configuration.wid &&
            _event.configurationAddress == configuration.addr
        );

        return _event;
     }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "../interfaces/multivault/IMultiVaultToken.sol";


contract MultiVaultToken is IMultiVaultToken, Context, IERC20, IERC20Metadata, Ownable {
    uint activation;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol} and {decimals}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external override {
        require(activation == 0);

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        activation = block.number;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function mint(
        address account,
        uint amount
    ) external override onlyOwner {
        _mint(account, amount);
    }

    function burn(
        address account,
        uint amount
    ) external override onlyOwner {
        _burn(account, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


contract ChainId {
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}