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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
pragma solidity 0.8.13;

import "./IPaymentSplitter.sol";
import "./IChangeDaoNFTFactory.sol";
import "./IController.sol";

/**
 * @title IChangeDaoNFT
 * @author ChangeDao
 */
interface IChangeDaoNFT {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a baseURI is set
     */
    event BaseURISet(string oldBaseURI, string newBaseURI);

    /**
     * @notice Emitted when a fundingClone is set
     * @dev This needs to be the address type so that the fundingClone variable can accommodate other types of contracts in the future other than SharedFunding.sol. Do not set it to a contract type (ex, ISharedFunding).
     */
    event FundingCloneSet(address indexed fundingClone);

    /**
     * @notice Emitted when the default royalty is set
     */
    event DefaultRoyaltySet(
        IPaymentSplitter indexed receiver,
        uint96 indexed feeNumerator
    );

    /**
     * @notice Emitted when a creator is registered
     */
    event CreatorRegistered(address indexed creator);

    /**
     * @notice Emitted when a changeDaoNFTclone is initialized
     */
    event ChangeDaoNFTInitialized(
        address indexed changeMaker,
        IChangeDaoNFT indexed changeDaoNFTImplementation,
        IChangeDaoNFT changeDaoNFTClone,
        string movementName,
        string projectName,
        string baseURI
    );

    /* ============== Implementation Getter Functions ============== */

    function feeNumerator() external view returns (uint96);

    function changeDaoNFTFactory() external view returns (IChangeDaoNFTFactory);

    function controller() external view returns (IController);

    /* ============== Clone Getter Functions ============== */

    function changeDaoNFTImplementation() external view returns (IChangeDaoNFT);

    function changeMaker() external view returns (address);

    function hasSetFundingClone() external view returns (bool);

    function baseURI() external view returns (string memory);

    ///@dev This needs to be the address type so that the fundingClone variable can accommodate other types of contracts in the future other than SharedFunding.sol.
    function fundingClone() external view returns (address);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /* ============== Initialize ============== */

    function initialize(
        address _changeMaker,
        IChangeDaoNFT _changeDaoNFTImplementation,
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory baseURI_
    ) external;

    /* ============== Mint Function ============== */

    function mint(uint256 _tokenId, address _owner) external;

    /* ============== NFT Configuration Functions--Clone ============== */

    function setBaseURI(string memory _newBaseURI) external;

    function setFundingClone(
        address _fundingClone, // use address type, not interface or contract type
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external;

    function setDefaultRoyalty(
        IPaymentSplitter _receiver,
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external;

    /* ============== NFT Configuration Function--Implementation ============== */

    function setFeeNumerator(uint96 _feeNumerator) external;

    /* ============== Contract Address Setter Functions ============== */

    function setChangeDaoNFTFactory(IChangeDaoNFTFactory _changeDaoNFTFactory)
        external;

    function setController(IController _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IChangeDaoNFT.sol";
import "./IController.sol";

/**
 * @title IChangeDaoNFTFactory
 * @author ChangeDao
 */
interface IChangeDaoNFTFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a changeDaoNFT clone is created
     */
    event ChangeDaoNFTCloneCreated(
        IChangeDaoNFT indexed changeDaoNFTClone,
        address indexed changeMaker
    );

    /* ============== Getter Functions ============== */

    function controller() external view returns (IController);

    function changeDaoNFTImplementation() external view returns (IChangeDaoNFT);

    /* ============== Factory Function ============== */

    function createChangeDaoNFT(
        address _changeMaker,
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory _baseURI
    ) external returns (IChangeDaoNFT);

    /* ============== Setter Functions ============== */

    function setController(IController _controller) external;

    function setChangeDaoNFTImplementation(
        IChangeDaoNFT _newCDNFTImplementation
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IChangeMakers
 * @author ChangeDao
 */

interface IChangeMakers {
    /* ============== Events ============== */

    /**
     * @notice Emitted when ChangeDao adds an address to approvedChangeMakers mapping
     */
    event ChangeMakerApproved(address indexed changeMaker);

    /**
     * @notice Emitted when ChangeDao removes an address from approvedChangeMakers mapping
     */
    event ChangeMakerRevoked(address indexed changeMaker);

    /* ============== Getter Function ============== */

    function approvedChangeMakers(address _changeMaker)
        external
        view
        returns (bool);

    /* ============== Setter Functions ============== */

    function approveChangeMaker(address _changeMaker) external;

    function revokeChangeMaker(address _changeMaker) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IChangeMakers.sol";
import "./IPaymentSplitterFactory.sol";
import "./ISharedFundingFactory.sol";
import "./IChangeDaoNFTFactory.sol";
import "./IChangeDaoNFT.sol";
import "./IPaymentSplitter.sol";

/**
 * @title IController
 * @author ChangeDao
 */
interface IController {
    /* ============== Getter Functions ============== */

    function changeDaoNFTFactory() external view returns (IChangeDaoNFTFactory);

    function paymentSplitterFactory()
        external
        view
        returns (IPaymentSplitterFactory);

    function sharedFundingFactory()
        external
        view
        returns (ISharedFundingFactory);

    function changeMakers() external view returns (IChangeMakers);

    /* ============== Clone Creation Functions ============== */

    function createNFTAndPSClones(
        string memory _movementName,
        string memory _projectName,
        address[] memory _creators,
        string memory _baseURI,
        address[] memory _royaltiesPayees,
        uint256[] memory _royaltiesShares,
        address[] memory _fundingPayees,
        uint256[] memory _fundingShares
    ) external;

    function callSharedFundingFactory(
        IChangeDaoNFT _changeDaoNFTClone,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        bool _isPaused
    ) external;

    /* ============== Pause Functions ============== */

    function pause() external;

    function unpause() external;

    /* ============== Contract Setter Functions ============== */

    function setChangeDaoNFTFactory(
        IChangeDaoNFTFactory _newChangeDaoNFTFactory
    ) external;

    function setChangeMakers(IChangeMakers _newChangeMakers) external;

    function setPaymentSplitterFactory(IPaymentSplitterFactory _newPSFactory)
        external;

    function setSharedFundingFactory(ISharedFundingFactory _newSFFactory)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IFundingAllocations
 * @author ChangeDao
 */

interface IFundingAllocations {
    /* ============== Events ============== */

    /**
     * @notice Emitted when owner sets a new address for ChangeDao's wallet
     */
    event NewWallet(address indexed changeDaoWallet);

    /**
     * @notice Emitted when owner sets new royalties share amount for ChangeDao
     */
    event SetRoyaltiesShares(uint256 indexed shareAmount);

    /**
     * @notice Emitted when owner sets new funding share amount for ChangeDao
     */
    event SetFundingShares(uint256 indexed shareAmount);

    /* ============== Getter Functions ============== */

    function changeDaoWallet() external view returns (address payable);

    function changeDaoRoyalties() external view returns (uint256);
    
    function changeDaoFunding() external view returns (uint256);

    /* ============== Setter Functions ============== */

    function setChangeDaoRoyalties(uint256 _royaltiesShares) external;

    function setChangeDaoFunding(uint256 _fundingShares) external;

    function setChangeDaoWallet(address payable _changeDaoWallet) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IFundingAllocations.sol";

/**
 * @title IPaymentSplitter
 * @author ChangeDao
 */
interface IPaymentSplitter {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a payee is added to the _payees array
     */
    event PayeeAdded(address indexed account, uint256 indexed shares);

    /**
     * @notice Emitted when ETH is released to an address
     */
    event ETHPaymentReleased(address indexed to, uint256 indexed amount);

    /**
     * @notice Emitted when DAI or USDC is released to an address
     */
    event StablecoinPaymentReleased(
        IERC20 indexed token,
        address indexed to,
        uint256 indexed amount
    );

    /**
     * @notice Emitted when the contract directly receives ETH
     */
    event ETHPaymentReceived(address indexed from, uint256 indexed amount);

    /**
     * @notice Emitted when a paymentSplitter clone is initialized
     */
    event PaymentSplitterInitialized(
        address indexed changeMaker,
        bytes32 indexed contractType,
        IPaymentSplitter indexed paymentSplitterCloneAddress,
        uint256 changeDaoShares,
        address changeDaoWallet,
        IFundingAllocations allocations
    );

    /* ============== Receive ============== */

    receive() external payable;

    /* ============== Initialize ============== */

    function initialize(
        address _changeMaker,
        bytes32 _contractType,
        IFundingAllocations _allocations,
        address[] memory payees_,
        uint256[] memory shares_
    ) external payable;

    /* ============== Getter Functions ============== */

    function changeDaoShares() external view returns (uint256);

    function changeDaoWallet() external view returns (address payable);

    function DAI_ADDRESS() external view returns (IERC20);

    function USDC_ADDRESS() external view returns (IERC20);

    function payeesLength() external view returns (uint256);

    function getPayee(uint256 _index) external view returns (address);

    function totalShares() external view returns (uint256);

    function totalReleasedETH() external view returns (uint256);

    function totalReleasedERC20(IERC20 _token) external view returns (uint256);

    function shares(address _account) external view returns (uint256);

    function recipientReleasedETH(address _account)
        external
        view
        returns (uint256);

    function recipientReleasedERC20(IERC20 _token, address _account)
        external
        view
        returns (uint256);

    function pendingETHPayment(address _account)
        external
        view
        returns (uint256);

    function pendingERC20Payment(IERC20 _token, address _account)
        external
        view
        returns (uint256);

    /* ============== Release Functions ============== */

    function releaseETH(address payable _account) external;

    function releaseERC20(IERC20 _token, address _account) external;

    function releaseAll(address payable _account) external;

    function releaseAllFundingTypes(
        address[] memory _fundingTokens,
        address payable _account
    ) external;

    function ownerReleaseAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IFundingAllocations.sol";
import "./IPaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./IController.sol";

/**
 * @title IPaymentSplitterFactory
 * @author ChangeDao
 */
interface IPaymentSplitterFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a fundingPSClone is created
     */
    event FundingPSCloneDeployed(
        PaymentSplitter indexed fundingPSClone,
        IChangeDaoNFT indexed changeDaoNFTClone
    );

    /**
     * @notice Emitted when a royaltiesPSClone is created
     */
    event RoyaltiesPSCloneDeployed(
        IPaymentSplitter indexed royaltiesPSClone,
        IChangeDaoNFT indexed changeDaoNFTClone
    );

    /* ============== Getter Functions ============== */

    function paymentSplitter() external view returns (IPaymentSplitter);

    function allocations() external view returns (IFundingAllocations);

    function controller() external view returns (IController);

    /* ============== Factory Functions ============== */

    function createRoyaltiesPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) external returns (IPaymentSplitter);

    function createFundingPSClone(
        IChangeDaoNFT _changeDaoNFTClone,
        address[] memory _payees,
        uint256[] memory _shares,
        address _changeMaker
    ) external returns (PaymentSplitter);

    /* ============== Setter Functions ============== */

    function setPaymentSplitterImplementation(IPaymentSplitter _paymentSplitter)
        external;

    function setFundingAllocations(IFundingAllocations _allocations) external;

    function setController(IController _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../PaymentSplitter/PaymentSplitter.sol";
import "./IPaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./IFundingAllocations.sol";

/**
 * @title ISharedFunding
 * @author ChangeDao
 */
interface ISharedFunding {
    /* ============== Events ============== */

    /**
     * @notice Emitted when courtesy minting
     */
    event CourtesyMint(uint256 indexed tokenId, address indexed owner);

    /**
     * @notice Emitted when funding with ETH
     */
    event EthFunding(
        uint256 indexed fundingAmountInEth,
        uint256 indexed tipInEth,
        address indexed funder,
        uint256 fundingAmountInUsd,
        uint256 tipInUsd,
        uint256 refundInEth
    );

    /**
     * @notice Emitted when a new fundingPSClone is set
     */
    event NewFundingPSClone(PaymentSplitter indexed fundingPSClone);

    /**
     * @notice Emitted when setting max amount of mints in public period
     */
    event NewMaxMintAmountPublic(uint32 indexed maxMintAmountPublic);

    /**
     * @notice Emitted when setting max amount of mints in rainbow period
     */
    event NewMaxMintAmountRainbow(uint32 indexed maxMintAmountRainbow);

    /**
     * @notice Emitted when minting with fundPublic()
     */
    event PublicMint(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed mintPrice
    );

    /**
     * @notice Emitted when minting with fundRainbow()
     */
    event RainbowMint(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed mintPrice
    );

    /**
     * @notice Emitted when sharedFundingClone is initialized
     */
    event SharedFundingInitialized(
        ISharedFunding indexed sharedFundingClone,
        IChangeDaoNFT indexed changeDaoNFTClone,
        IFundingAllocations allocations,
        uint256 mintPrice,
        uint64 totalMints,
        uint32 maxMintAmountRainbow,
        uint32 maxMintAmountPublic,
        uint256 rainbowDuration,
        bytes32 rainbowMerkleRoot,
        PaymentSplitter fundingPSClone,
        address indexed changeMaker,
        uint256 deployTime
    );

    /**
     * @notice Emitted when funding type is DAI or USDC
     */
    event StablecoinFunding(
        IERC20 indexed token,
        uint256 indexed fundingAmountInUsd,
        uint256 indexed tipInUsd,
        address funder
    );

    /**
     * @notice Emitted when zero minting
     */
    event ZeroMint(uint256 indexed tokenId, address indexed owner);

    /* ============== State Variable Getter Functions ============== */

    function DAI_ADDRESS() external view returns (IERC20);

    function USDC_ADDRESS() external view returns (IERC20);

    function ETH_USD_DATAFEED() external view returns (address);

    function totalMints() external view returns (uint64);

    function mintPrice() external view returns (uint256);

    function deployTime() external view returns (uint256);

    function rainbowDuration() external view returns (uint256);

    function maxMintAmountRainbow() external view returns (uint32);

    function maxMintAmountPublic() external view returns (uint32);

    function changeMaker() external view returns (address);

    function hasZeroMinted() external view returns (bool);

    function rainbowMerkleRoot() external view returns (bytes32);

    function fundingPSClone() external view returns (PaymentSplitter);

    function changeDaoNFTClone() external view returns (IChangeDaoNFT);

    function allocations() external view returns (IFundingAllocations);

    /* ============== Receive ============== */

    receive() external payable;

    /* ============== Initialize ============== */

    function initialize(
        IChangeDaoNFT _changeDaoNFTClone,
        IFundingAllocations _allocations,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        address _changeMaker,
        bool _isPaused
    ) external;

    /* ============== Mint Functions ============== */

    function zeroMint(address _recipient) external;

    function courtesyMint(address _recipient, uint256 _mintAmount) external;

    function fundRainbow(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount,
        bytes32[] memory _proof
    ) external payable;

    function fundPublic(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount
    ) external payable;

    /* ============== Conversion Function ============== */

    function convertUsdAmountToEth(uint256 _amountInUsd)
        external
        view
        returns (uint256);

    /* ============== Getter Functions ============== */

    function getRainbowExpiration() external view returns (uint256);

    function getMintedTokens() external view returns (uint256);

    /* ============== Pause Functions ============== */

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../PaymentSplitter/PaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./ISharedFunding.sol";
import "./IFundingAllocations.sol";
import "./IController.sol";
import "./IPaymentSplitter.sol";

/**
 * @title ISharedFundingFactory
 * @author ChangeDao
 */
interface ISharedFundingFactory {
    /* ============== Events ============== */

    /**
     * @notice Emitted when a sharedFundingClone is created
     */
    event SharedFundingCreated(
        IChangeDaoNFT indexed changeDaoNFTClone,
        ISharedFunding indexed sharedFundingClone,
        bool isPaused
    );

    /* ============== Getter Functions ============== */

    function controller() external view returns (IController);

    function sharedFunding() external view returns (ISharedFunding);

    function allocations() external view returns (IFundingAllocations);

    /* ============== Factory Function ============== */

    /**
     * @dev Needs to return address type, not ISharedFunding type!!!
     * @dev NOTE: sharedFundingClone must be of address type.  This will be stored on the changeDaoNFTClone.  Future versions of the application might have different funding contracts, and so the type must remain agnostic (use address) instead of being tied to a specific contract interface (do not use ISharedFunding).
     */
    function createSharedFundingClone(
        IChangeDaoNFT _changeDaoNFTClone,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        address _changeMaker,
        bool _isPaused
    ) external returns (address); // must return address type!

    /* ============== Setter Functions ============== */

    function setSharedFundingImplementation(ISharedFunding _sharedFunding)
        external;

    function setFundingAllocations(IFundingAllocations _allocations) external;

    function setController(IController _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPaymentSplitter.sol";

/**
 * @title PaymentSplitter
 * @author ChangeDao
 * @notice Implementation contract for royaltiesPSClones and fundingPSClones
 * @dev Modification of OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
contract PaymentSplitter is IPaymentSplitter, Ownable, Initializable {
    /* ============== Clone State Variables ============== */

    uint256 public override changeDaoShares;
    address payable public override changeDaoWallet;
    bytes32 private constant _CHANGEDAO_FUNDING = "CHANGEDAO_FUNDING";
    bytes32 private constant _CHANGEDAO_ROYALTIES = "CHANGEDAO_ROYALTIES";
    address private constant _ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public immutable override DAI_ADDRESS;
    IERC20 public immutable override USDC_ADDRESS;

    uint256 private _totalShares;
    mapping(address => uint256) private _shares;
    address[] private _payees;

    uint256 private _totalReleasedETH;
    mapping(address => uint256) private _recipientReleasedETH;

    mapping(IERC20 => uint256) private _totalReleasedERC20;
    mapping(IERC20 => mapping(address => uint256))
        private _recipientReleasedERC20;

    /* ============== Receive ============== */

    /**
     * @dev Accepts ETH sent directly to the contract
     */
    receive() external payable virtual override {
        emit ETHPaymentReceived(_msgSender(), msg.value);
    }

    /* ============== Constructor ============== */

    /**
     * @param _daiAddress DAI address
     * @param _usdcAddress USDC address
     */
    constructor(IERC20 _daiAddress, IERC20 _usdcAddress) payable initializer {
        DAI_ADDRESS = _daiAddress;
        USDC_ADDRESS = _usdcAddress;
    }

    /* ============== Initialize ============== */

    /**
     * @notice Initializes the paymentSplitter clone.
     * @param _changeMaker Address of the changeMaker that is making the project
     * @param _contractType Must be bytes32 "CHANGEDAO_FUNDING" or "CHANGEDAO_ROYALTIES"
     * @param _allocations FundingAllocations address
     * @param payees_ Array of recipient addresses
     * @param shares_ Array of share amounts for recipients
     */
    function initialize(
        address _changeMaker,
        bytes32 _contractType,
        IFundingAllocations _allocations,
        address[] memory payees_,
        uint256[] memory shares_
    ) public payable override initializer {
        /** Set changeDao's share amount based on values set per contract type in FundingAllocations contract */
        if (_contractType == _CHANGEDAO_FUNDING) {
            changeDaoShares = _allocations.changeDaoFunding();
        } else if (_contractType == _CHANGEDAO_ROYALTIES) {
            changeDaoShares = _allocations.changeDaoRoyalties();
        } else revert("PS: Invalid contract type");

        changeDaoWallet = payable(_allocations.changeDaoWallet());

        require(
            payees_.length == shares_.length,
            "PS: payees and shares length mismatch"
        );
        require(payees_.length > 0, "PS: no payees");
        require(payees_.length <= 35, "PS: payees exceed 35");
        uint256 sharesSum;

        for (uint256 i = 0; i < payees_.length; i++) {
            _addPayee(payees_[i], shares_[i]);
            sharesSum += shares_[i];
        }
        _addPayee(changeDaoWallet, changeDaoShares);
        sharesSum += changeDaoShares;
        require(sharesSum == 10000, "PS: total shares do not equal 10000");

        emit PaymentSplitterInitialized(
            _changeMaker,
            _contractType,
            IPaymentSplitter(this),
            changeDaoShares,
            changeDaoWallet,
            _allocations
        );
    }

    /* ============== Getter Functions ============== */

    /**
     * @dev Getter for the number of recipient addresses
     */
    function payeesLength() public view override returns (uint256) {
        return _payees.length;
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     * @param _index Index of payee address in _payees array
     */
    function getPayee(uint256 _index) public view override returns (address) {
        return _payees[_index];
    }

    /**
     * @dev Getter for the total shares held by all payees.
     */
    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleasedETH() public view override returns (uint256) {
        return _totalReleasedETH;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20 contract.
     * @param _token ERC20 token address
     */
    function totalReleasedERC20(IERC20 _token)
        public
        view
        override
        returns (uint256)
    {
        return _totalReleasedERC20[_token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     * @param _account Address of recipient
     */
    function shares(address _account) public view override returns (uint256) {
        return _shares[_account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     * @param _account Address of recipient
     */
    function recipientReleasedETH(address _account)
        public
        view
        override
        returns (uint256)
    {
        return _recipientReleasedETH[_account];
    }

    /**
   * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an IERC20 contract.
   * @param _token ERC20 token address
   * @param _account Address of recipient 

   */
    function recipientReleasedERC20(IERC20 _token, address _account)
        public
        view
        override
        returns (uint256)
    {
        return _recipientReleasedERC20[_token][_account];
    }

    /**
     * @dev Returns the amount of ETH held for a given shareholder.
     * @param _account Address of recipient
     */
    function pendingETHPayment(address _account)
        public
        view
        override
        returns (uint256)
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleasedETH();
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedETH(_account)
        );
        return payment;
    }

    /**
     * @dev Returns the amount of DAI or USDC held for a given shareholder.
     * @param _token ERC20 token address
     * @param _account Address of recipient
     */
    function pendingERC20Payment(IERC20 _token, address _account)
        public
        view
        override
        returns (uint256)
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = _token.balanceOf(address(this)) +
            totalReleasedERC20(_token);
        uint256 alreadyReleased = recipientReleasedERC20(_token, _account);

        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            alreadyReleased
        );
        return payment;
    }

    /* ============== Release Functions ============== */

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the total shares and their previous withdrawals.
     * @param _account Address of recipient
     */
    function releaseETH(address payable _account) public virtual override {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleasedETH();
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedETH(_account)
        );

        if (payment == 0) return;

        _recipientReleasedETH[_account] += payment;
        _totalReleasedETH += payment;

        Address.sendValue(_account, payment);
        emit ETHPaymentReleased(_account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20 contract.
     * @param _token ERC20 token address
     * @param _account Address of recipient
     */
    function releaseERC20(IERC20 _token, address _account)
        public
        virtual
        override
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = _token.balanceOf(address(this)) +
            totalReleasedERC20(_token);
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedERC20(_token, _account)
        );

        if (payment == 0) return;

        _recipientReleasedERC20[_token][_account] += payment;
        _totalReleasedERC20[_token] += payment;

        SafeERC20.safeTransfer(_token, _account, payment);
        emit StablecoinPaymentReleased(_token, _account, payment);
    }

    /**
     * @dev Convenience function to release an account's ETH, DAI and USDC in one call
     * @param _account Address of recipient
     */
    function releaseAll(address payable _account) public override {
        releaseERC20(DAI_ADDRESS, _account);
        releaseERC20(USDC_ADDRESS, _account);
        releaseETH(_account);
    }

    /**
     * @notice Convenience function to release ETH and ERC20 tokens (not just DAI and USDC)
     * @dev Caller should exclude any tokens with zero balance to avoide wasting gas
     * @dev Any non-ERC20 or ETH addresses will revert
     * @param _account Address of recipient
     * @param _fundingTokens Array of funding token addresses to be released to _account
     */
    function releaseAllFundingTypes(
        address[] memory _fundingTokens,
        address payable _account
    ) external override {
        for (uint256 i; i < _fundingTokens.length; i++) {
            if (_fundingTokens[i] != _ETH_ADDRESS) {
                releaseERC20(IERC20(_fundingTokens[i]), _account);
            } else {
                releaseETH(_account);
            }
        }
    }

    /**
     * @dev ChangeDao can release any funds inadvertently sent to the implementation contract
     */
    function ownerReleaseAll() external override onlyOwner {
        SafeERC20.safeTransfer(
            DAI_ADDRESS,
            owner(),
            DAI_ADDRESS.balanceOf(address(this))
        );
        SafeERC20.safeTransfer(
            USDC_ADDRESS,
            owner(),
            USDC_ADDRESS.balanceOf(address(this))
        );
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /* ============== Internal Functions ============== */

    /**
     * @dev Internal logic for computing the pending payment of an `account` given the token historical balances and already released amounts.
     */
    function _pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) private view returns (uint256) {
        return
            (_totalReceived * _shares[_account]) /
            _totalShares -
            _alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param _account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address _account, uint256 shares_) private {
        require(_account != address(0), "PS: account is the zero address");
        require(shares_ > 0, "PS: shares are 0");
        require(_shares[_account] == 0, "PS: account already has shares");

        _payees.push(_account);
        _shares[_account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(_account, shares_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISharedFundingFactory.sol";

/**
 * @title SharedFundingFactory
 * @author ChangeDao
 * @notice Generates SharedFunding clone
 * @dev ChangeDao admin is the owner
 */
contract SharedFundingFactory is ISharedFundingFactory, Ownable {
    /* ============== State Variables ============== */

    IController public override controller;
    ISharedFunding public override sharedFunding;
    IFundingAllocations public override allocations;

    /* ============== Constructor ============== */

    /**
     * @param _sharedFunding Sets SharedFunding address
     * @param _allocations Sets FundingAllocations address
     */
    constructor(ISharedFunding _sharedFunding, IFundingAllocations _allocations)
    {
        sharedFunding = _sharedFunding;
        allocations = _allocations;
    }

    /* ============== Factory Function ============== */

    /**
     * @notice Creates sharedFundingClone
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _mintPrice mintPrice
     * @param _totalMints totalMints
     * @param _maxMintAmountRainbow maxMintAmountRainbow
     * @param _maxMintAmountPublic maxMintAmountPublic
     * @param _rainbowDuration rainbowDuration
     * @param _rainbowMerkleRoot rainbowMerkleRoot
     * @param _fundingPSClone fundingPSClone address
     * @param _changeMaker Address of the changeMaker that is making the sharedFundingClone
     * @param _isPaused pause status
     */
    function createSharedFundingClone(
        IChangeDaoNFT _changeDaoNFTClone,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        address _changeMaker,
        bool _isPaused
    ) external override returns (address) {
        require(
            _msgSender() == address(controller),
            "SFF: Controller is not caller"
        );

        address payable sharedFundingClone = payable(
            Clones.clone(address(sharedFunding))
        );

        ISharedFunding(sharedFundingClone).initialize(
            _changeDaoNFTClone,
            allocations,
            _mintPrice,
            _totalMints,
            _maxMintAmountRainbow,
            _maxMintAmountPublic,
            _rainbowDuration,
            _rainbowMerkleRoot,
            _fundingPSClone,
            _changeMaker,
            _isPaused
        );

        emit SharedFundingCreated(
            _changeDaoNFTClone,
            ISharedFunding(sharedFundingClone),
            _isPaused
        );
        return sharedFundingClone;
    }

    /* ============== Setter Functions ============== */

    /**
     * @notice Sets address for the SharedFunding implementation contract
     * @param _sharedFunding SharedFunding address
     */
    function setSharedFundingImplementation(ISharedFunding _sharedFunding)
        external
        override
        onlyOwner
    {
        sharedFunding = _sharedFunding;
    }

    /**
     * @notice Sets address for the FundingAllocations contract
     * @param _allocations FundingAllocations address
     */
    function setFundingAllocations(IFundingAllocations _allocations)
        external
        override
        onlyOwner
    {
        allocations = _allocations;
    }

    /**
     * @notice Sets address for the Controller contract
     * @param _controller Controller address
     */
    function setController(IController _controller)
        external
        override
        onlyOwner
    {
        controller = _controller;
    }
}