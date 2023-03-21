// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     *
     */
    event Deposit(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     *
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     *
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     *
     */
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     *
     */
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     */
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     *
     */
    function withdraw(address asset, uint256 amount, address to) external;

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     *
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     *
     */
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     *
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IDODOApprove {
    function claimTokens(address token, address who, address dest, uint256 amount) external;
    function getDODOProxy() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IMarginTrading {
    //---------------event-----------------
    event FlashLoans(address[] assets, uint256[] amounts, uint256[] modes, address mainToken);
    event OpenPosition(
        address indexed swapAddress, address[] swapApproveToken, address[] tradAssets, uint256[] tradAmounts
    );
    event ClosePosition(
        uint8 _flag,
        address indexed swapAddress,
        address[] swapApproveToken,
        address[] tradAssets,
        uint256[] tradAmounts,
        address[] withdrawAssets,
        uint256[] withdrawAmounts,
        uint256[] _rateMode,
        uint256[] _returnAmounts
    );

    event LendingPoolWithdraw(address indexed asset, uint256 indexed amount, uint8 _flag);

    event LendingPoolDeposit(address indexed asset, uint256 indexed amount, uint8 _flag);

    event LendingPoolRepay(address indexed asset, uint256 indexed amount, uint256 indexed rateMode, uint8 _flag);

    event WithdrawERC20(address indexed marginAddress, uint256 indexed marginAmount, bool indexed margin, uint8 _flag);
    
    event WithdrawETH(uint256 indexed marginAmount, bool indexed margin, uint8 _flag);

    //---------------view-----------------

    function user() external view returns (address _userAddress);

    function getContractAddress() external view returns (address _lendingPoolAddress, address _WETHAddress);

    //---------------function-----------------
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function executeFlashLoans(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external;

    function lendingPoolWithdraw(address _asset, uint256 _amount, uint8 _flag) external;

    function lendingPoolDeposit(address _asset, uint256 _amount, uint8 _flag) external;

    function lendingPoolRepay(address _repayAsset, uint256 _repayAmt, uint256 _rateMode, uint8 _flag) external;

    function withdrawERC20(address _marginAddress, uint256 _marginAmount, bool _margin, uint8 _flag) external;

    function withdrawETH(bool _margin, uint256 _marginAmount, uint8 _flag) external payable;

    function initialize(address _lendingPool, address _weth, address _user) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IMarginTradingFactory {
    //---------------event-----------------
    event MarginTradingCreated(
        address indexed userAddress, address indexed marginAddress, uint256 userMarginNum, uint8 _flag
    );

    event DepositMarginTradingERC20(
        address _marginTradingAddress, address _marginAddress, uint256 _marginAmount, bool _margin, uint8 _flag
    );

    event DepositMarginTradingETH(address _marginTradingAddress, uint256 _marginAmount, bool _margin, uint8 _flag);

    event ExecuteMarginTradingFlashLoans(
        address indexed _marginTradingAddress, address[] assets, uint256[] amounts, uint256[] modes
    );

    //---------------view-----------------

    function getCreateMarginTradingAddress(
        uint256 _num,
        uint8 _flag,
        address _user
    ) external view returns (address _ad);

    function getUserMarginTradingNum(address _user) external view returns (uint256 _crossNum, uint256 _isolateNum);

    function isAllowedProxy(address _marginTradingAddress, address _proxy) external view returns (bool);

    //---------------function-----------------

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function createMarginTrading(
        uint8 _flag,
        bytes calldata depositParams,
        bytes calldata executeParams
    ) external payable returns (address margin);

    function executeMarginTradingFlashLoans(
        address _marginTradingAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external;

    function depositMarginTradingERC20(
        address _marginTradingAddress,
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) external;

    function depositMarginTradingETH(address _marginTradingAddress, bool _margin, uint8 _flag) external payable;

    function addFlashLoanProxy(address _marginTradingAddress, address _proxy) external;

    function removeFlashLoanProxy(address _marginTradingAddress, address _oldProxy) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {ILendingPool, IFlashLoanReceiver} from "../aaveLib/Interfaces.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMarginTrading} from "./interfaces/IMarginTrading.sol";
import {IMarginTradingFactory} from "./interfaces/IMarginTradingFactory.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Types} from "./Types.sol";
/**
 * @author  DODO
 * @title   MarginTrading
 * @dev     To save contract size, most of the function implements are moved to LiquidationLibrary.
 * @notice  This contract serves as a user-managed asset contract, responsible for interacting with Aave, including functions such as opening, closing, repaying, and withdrawing.
 */
contract MarginTrading is OwnableUpgradeable, IMarginTrading, IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    ILendingPool internal lendingPool;

    IWETH internal WETH;

    address private _USER;

    modifier onlyUser() {
        require(_USER == msg.sender, "caller is not the user");
        _;
    }

    modifier onlyLendingPool() {
        require(address(lendingPool) == msg.sender, "caller is not the lendingPool");
        _;
    }

    modifier onlyDeposit() {
        require(
            _USER == msg.sender || owner() == msg.sender,
            "caller is unauthorized"
        );
        _;
    }

    modifier onlyFlashLoan() {
        require(
            _USER == msg.sender || owner() == msg.sender
                || IMarginTradingFactory(owner()).isAllowedProxy(address(this), msg.sender),
            "caller is unauthorized"
        );
        _;
    }

    /// @notice Obtaining the address of the user who owns this contract.
    /// @return _userAddress User address
    function user() external view returns (address _userAddress) {
        return _USER;
    }

    /// @notice Get owner address
    /// @return _ad Owner address
    function getOwner() external view returns (address _ad) {
        _ad = owner();
    }

    /// @notice Query the addresses of relevant external contracts.
    /// @return _lendingPoolAddress lendingPool address
    /// @return _WETHAddress weth address
    function getContractAddress() external view returns (address _lendingPoolAddress, address _WETHAddress) {
        return (address(lendingPool), address(WETH));
    }


    function initialize(address _lendingPool, address _weth, address _user) external initializer {
        __Ownable_init();
        lendingPool = ILendingPool(_lendingPool);
        WETH = IWETH(_weth);
        _USER = _user;
    }

    receive() external payable {}

    // ============ Functions ============
    
    /// @notice Execution methods for opening and closing.
    /// @dev Execute a flash loan and pass the parameters to the executeOperation method.
    /// @param assets Borrowing assets
    /// @param amounts Borrowing assets amounts
    /// @param modes Borrowing assets premiums
    /// @param mainToken initiator address
    /// @param params The parameters for the execution logic.
    function executeFlashLoans(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external onlyFlashLoan {
        address receiverAddress = address(this);

        // the various assets to be flashed

        // the amount to be flashed for each asset

        // 0 = no debt, 1 = stable, 2 = variable

        address onBehalfOf = address(this);
        // DODOSwap 地址+参数, DepositToken 地址 和 数量
        // bytes memory params = "";
        lendingPool.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, Types.REFERRAL_CODE);
        emit FlashLoans(assets, amounts, modes, mainToken);
    }

    /// @notice LendingPool flashloan callback function, returns true upon successful execution.
    /// @dev It internally implements three operations: partial closure, full closure, and opening.
    /// @dev Opening: Borrowing token through flash loan, swapping it into deposit token, and depositing it into Aave to complete the opening process.
    /// @dev Partial closure: Borrowing Aave deposit token through flash loan, swapping it into borrowed token, repaying according to the balance, then extracting token from Aave deposit to repay the flash loan.
    /// @dev Full closure: Borrowing Aave deposit token through flash loan, swapping it into borrowed token, repaying all debts, returning the remaining debt tokens to the user, then extracting token from Aave deposit to repay the flash loan.
    /// @param _assets Borrowing assets
    /// @param _amounts Borrowing assets amounts
    /// @param _premiums Borrowing assets premiums
    /// @param _initiator initiator address
    /// @param _params The parameters for the execution logic.
    /// @return Returns true upon successful execution.
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address _initiator,
        bytes calldata _params
    ) external override onlyLendingPool returns (bool) {
        //decode params exe swap and deposit
        {
            (
                uint8 _flag,
                address _swapAddress,
                address _swapApproveTarget,
                address[] memory _swapApproveToken,
                bytes memory _swapParams,
                address[] memory _tradeAssets,
                address[] memory _withdrawAssets,
                uint256[] memory _withdrawAmounts,
                uint256[] memory _rateMode,
                address[] memory _debtTokens
            ) = abi.decode(
                _params,
                (uint8, address, address, address[], bytes, address[], address[], uint256[], uint256[], address[])
            );
            if (_flag == 0 || _flag == 2) {
                //close
                _closetrade(
                    _flag,
                    _swapAddress,
                    _swapApproveTarget,
                    _swapApproveToken,
                    _swapParams,
                    _tradeAssets,
                    _withdrawAssets,
                    _withdrawAmounts,
                    _rateMode,
                    _debtTokens
                );
            }
            if (_flag == 1) {
                //open
                _opentrade(_swapAddress, _swapApproveTarget, _swapApproveToken, _swapParams, _tradeAssets);
            }
        }
        return true;
    }

    /// @notice Withdraws the token collateral from the lending pool
    /// @param _asset Asset token address
    /// @param _amount Asset token Amount
    /// @param _flag Operation flag
    function lendingPoolWithdraw(address _asset, uint256 _amount, uint8 _flag) external onlyUser {
        _lendingPoolWithdraw(_asset, _amount, _flag);
    }


    /// @notice Deposits the token liquidity onto the lending pool as collateral
    /// @param _asset Asset token address
    /// @param _amount Asset token Amount
    /// @param _flag Operation flag
    function lendingPoolDeposit(address _asset, uint256 _amount, uint8 _flag) external onlyDeposit {
        _lendingPoolDeposit(_asset, _amount, _flag);
    }

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned 
    /// @param _repayAsset Repay asset token address
    /// @param _repayAmt Repay Asset token Amount
    /// @param _rateMode Rate mode 1: stable mode debt, 2: variable mode debt
    /// @param _flag Operation flag
    function lendingPoolRepay(
        address _repayAsset,
        uint256 _repayAmt,
        uint256 _rateMode,
        uint8 _flag
    ) external onlyUser {
        _lendingPoolRepay(_repayAsset, _repayAmt, _rateMode, _flag);
    }

    /// @notice Withdraw ERC20 Token transfer to user
    /// @param _marginAddress ERC20 token address
    /// @param _marginAmount ERC20 token Amount
    /// @param _margin Whether the token source is collateral
    /// @param _flag Operation flag
    function withdrawERC20(
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) external onlyUser {
        if (_margin) {
            _lendingPoolWithdraw(_marginAddress, _marginAmount, _flag);
        }
        IERC20(_marginAddress).transfer(msg.sender, _marginAmount);
        emit WithdrawERC20(_marginAddress, _marginAmount, _margin, _flag);
    }

    /// @notice Withdraw ETH send to user
    /// @dev Convert WETH to ETH and send it to the user.
    /// @param _marginAmount ETH Amount
    /// @param _margin Whether the token source is collateral
    /// @param _flag Operation flag
    function withdrawETH(bool _margin, uint256 _marginAmount, uint8 _flag) external payable onlyUser {
        if (_margin) {
            _lendingPoolWithdraw(address(WETH), _marginAmount, _flag);
        }
        WETH.withdraw(_marginAmount);
        _safeTransferETH(msg.sender, _marginAmount);
        emit WithdrawETH(_marginAmount, _margin, _flag);
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable onlyUser returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            results[i] = result;
        }
    }

    // =========== internal ==========

    /// @notice Execute the open
    /// @dev Authorize the token first, then perform the swap operation. After successful execution, deposit the token into Aave.
    /// @param _swapAddress Swap address
    /// @param _swapApproveTarget Swap Approve address
    /// @param _swapApproveToken The address of the token that requires swap authorization.
    /// @param _swapParams Swap calldata
    /// @param _tradeAssets Deposit to aave token address
    function _opentrade(
        address _swapAddress,
        address _swapApproveTarget,
        address[] memory _swapApproveToken,
        bytes memory _swapParams,
        address[] memory _tradeAssets
    ) internal {
        if (_swapParams.length > 0) {
            // approve to swap route
            for (uint256 i = 0; i < _swapApproveToken.length; i++) {
                IERC20(_swapApproveToken[i]).approve(_swapApproveTarget, type(uint256).max);
            }

            (bool success,) = _swapAddress.call(_swapParams);
            require(success, "dodoswap fail");
        }
        uint256[] memory _tradeAmounts = new uint256[](_tradeAssets.length);
        for (uint256 i = 0; i < _tradeAssets.length; i++) {
            _tradeAmounts[i] = IERC20(_tradeAssets[i]).balanceOf(address(this));
            _lendingPoolDeposit(_tradeAssets[i], _tradeAmounts[i], 1);
        }
        emit OpenPosition(_swapAddress, _swapApproveToken, _tradeAssets, _tradeAmounts);
    }

    /// @notice Execute the close
    /// @dev Partial closure: Perform swap authorization, then execute swap and repay according to the balance.
    /// @dev Full closure: Perform swap authorization, then execute swap, repay according to the borrowed amount, and return the excess tokens to the user.
    /// @param _flag Operation flag
    /// @param _swapAddress Swap address
    /// @param _swapApproveTarget Swap Approve address
    /// @param _swapApproveToken The address of the token that requires swap authorization.
    /// @param _swapParams Swap calldata
    /// @param _tradeAssets Swap out token address,borrowing token address
    /// @param _withdrawAssets Swap in token address,deposit to aave token address
    /// @param _withdrawAmounts Swap in token amount,deposit to aave token amount
    /// @param _rateMode Rate mode 1: stable mode debt, 2: variable mode debt
    /// @param _debtTokens Debt token Address
    function _closetrade(
        uint8 _flag,
        address _swapAddress,
        address _swapApproveTarget,
        address[] memory _swapApproveToken,
        bytes memory _swapParams,
        address[] memory _tradeAssets,
        address[] memory _withdrawAssets,
        uint256[] memory _withdrawAmounts,
        uint256[] memory _rateMode,
        address[] memory _debtTokens
    ) internal {
        if (_swapParams.length > 0) {
            // approve to swap route
            for (uint256 i = 0; i < _swapApproveToken.length; i++) {
                IERC20(_swapApproveToken[i]).approve(_swapApproveTarget, type(uint256).max);
            }

            (bool success,) = _swapAddress.call(_swapParams);
            require(success, "dodoswap fail");
        }
        uint256[] memory _tradeAmounts = new uint256[](_tradeAssets.length);
        if (_flag == 2) {
            for (uint256 i = 0; i < _debtTokens.length; i++) {
                _tradeAmounts[i] = (IERC20(_debtTokens[i]).balanceOf(address(this)));
            }
        } else {
            for (uint256 i = 0; i < _tradeAssets.length; i++) {
                _tradeAmounts[i] = (IERC20(_tradeAssets[i]).balanceOf(address(this)));
            }
        }
        for (uint256 i = 0; i < _tradeAssets.length; i++) {
            _lendingPoolRepay(_tradeAssets[i], _tradeAmounts[i], _rateMode[i], 1);
        }
        for (uint256 i = 0; i < _withdrawAssets.length; i++) {
            _lendingPoolWithdraw(_withdrawAssets[i], _withdrawAmounts[i], 1);
            IERC20(_withdrawAssets[i]).approve(address(lendingPool), _withdrawAmounts[i]);
        }
        uint256[] memory _returnAmounts = new uint256[](_tradeAssets.length);
        if (_flag == 2) {
            //Withdraw to user
            for (uint256 i = 0; i < _tradeAssets.length; i++) {
                _returnAmounts[i] = IERC20(_tradeAssets[i]).balanceOf(address(this));
                IERC20(_tradeAssets[i]).transfer(_USER, _returnAmounts[i]);
            }
        }
        emit ClosePosition(
            _flag,
            _swapAddress,
            _swapApproveToken,
            _tradeAssets,
            _tradeAmounts,
            _withdrawAssets,
            _withdrawAmounts,
            _rateMode,
            _returnAmounts
            );
    }

    /// @notice Withdraws the token from the lending pool
    /// @dev Token authorization, then withdraw from lendingPool.
    /// @param _asset Asset token address
    /// @param _amount Asset token Amount
    /// @param _flag Operation flag
    function _lendingPoolWithdraw(address _asset, uint256 _amount, uint8 _flag) internal {
        _approveToken(address(lendingPool), _asset, _amount);
        lendingPool.withdraw(_asset, _amount, address(this));
        emit LendingPoolWithdraw(_asset, _amount, _flag);
    }


    /// @notice Deposits the token liquidity onto the lending pool as collateral
    /// @dev Token authorization, then deposits to lendingPool.
    /// @param _asset Asset token address
    /// @param _amount Asset token Amount
    /// @param _flag Operation flag
    function _lendingPoolDeposit(address _asset, uint256 _amount, uint8 _flag) internal {
        _approveToken(address(lendingPool), _asset, _amount);
        lendingPool.deposit(_asset, _amount, address(this), Types.REFERRAL_CODE);
        emit LendingPoolDeposit(_asset, _amount, _flag);
    }

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned 
    /// @param _repayAsset Repay asset token address
    /// @param _repayAmt Repay Asset token Amount
    /// @param _rateMode Rate mode 1: stable mode debt, 2: variable mode debt
    /// @param _flag Operation flag
    function _lendingPoolRepay(address _repayAsset, uint256 _repayAmt, uint256 _rateMode, uint8 _flag) internal {
        // approve the repayment from this contract
        _approveToken(address(lendingPool), _repayAsset, _repayAmt);
        lendingPool.repay(_repayAsset, _repayAmt, _rateMode, address(this));
        emit LendingPoolRepay(_repayAsset, _repayAmt, _rateMode, _flag);
    }

    function _approveToken(address _address, address _tokenAddress, uint256 _tokenAmount) internal {
        if (IERC20(_tokenAddress).allowance(address(this), _address) < _tokenAmount) {
            IERC20(_tokenAddress).approve(_address, type(uint256).max);
        }
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IMarginTrading} from "./interfaces/IMarginTrading.sol";
import {IMarginTradingFactory} from "./interfaces/IMarginTradingFactory.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IDODOApprove} from "./interfaces/IDODOApprove.sol";
import {MarginTrading} from "./MarginTrading.sol";

contract MarginTradingFactory is Ownable,  IMarginTradingFactory{
    event CleanToken(address _tokenAddress, address _to, uint256 _amount);

    event CleanETH(address _to, uint256 _amount);

    address public immutable MARGIN_TRADING_TEMPLATE;
    address internal LendingPool;
    IWETH internal WETH;
    IDODOApprove internal DODOApprove;
    // user => approveAddress = > bool
    mapping(address => mapping(address => bool)) public ALLOWED_FLASH_LOAN;

    mapping(address => address[]) public crossMarginTrading;

    mapping(address => address[]) public isolatedMarginTrading;

    //user approve close address
    constructor(address _lendingPool, address _weth, address _DODOApprove, address _template) public {
        LendingPool = _lendingPool;
        WETH = IWETH(_weth);
        MARGIN_TRADING_TEMPLATE = _template;
        DODOApprove = IDODOApprove(_DODOApprove);
    }

    receive() external payable {}

    /// @notice Get the marginTrading contract address created by the user.
    /// @param _num MarginTrading contract Num
    /// @param _flag 1 -cross , 2 - isolated
    /// @param _user User address
    /// @return _ad User marginTrading contract
    function getCreateMarginTradingAddress(
        uint256 _num,
        uint8 _flag,
        address _user
    ) external view returns (address _ad) {
        _ad =
            Clones.predictDeterministicAddress(MARGIN_TRADING_TEMPLATE, keccak256(abi.encodePacked(_user, _num, _flag)));
    }

    /// @notice To get the number of marginTrading contracts created by a user.
    /// @param _user User address
    /// @return _crossNum User cross marginTrading contract num
    /// @return _isolateNum User isolate marginTrading contract num
    function getUserMarginTradingNum(address _user) external view returns (uint256 _crossNum, uint256 _isolateNum) {
        _crossNum = crossMarginTrading[_user].length;
        _isolateNum = isolatedMarginTrading[_user].length;
    }

    /// @notice Get whether the proxyAddress is allowed to call the marginTrading contract.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy user address
    /// @return True is Allowed
    function isAllowedProxy(address _marginTradingAddress, address _proxy) external view returns (bool) {
        return ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy];
    }

    
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            results[i] = result;
        }
    }

    // ============ Functions ============

    /// @notice Add the proxy address that is allowed to execute flashloan operations.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy address
    function addFlashLoanProxy(address _marginTradingAddress, address _proxy) external {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "caller is not the user");
        ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy] = true;
    }

    
    /// @notice Delete the proxy address that is allowed to execute flash loan operation.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy address
    function removeFlashLoanProxy(address _marginTradingAddress, address _proxy) external {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "caller is not the user");
        ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy] = false;
    }

    /// @notice Create a marginTrading contract for the user, deposit funds, and open a position.
    /// @dev 1.Create a marginTrading contract for the user.
    /// @dev 2.Make a deposit.
    /// @dev 3.Execute the executeFlashLoans method of the marginTrading contract to open a position.
    /// @param _flag 1 -cross , 2 - isolated
    /// @param depositParams Deposit execution parameters.
    /// @param executeParams The parameters for executing the executeFlashLoans function in the marginTrading contract.
    /// @return marginTrading Create marginTrading address
    function createMarginTrading(
        uint8 _flag,
        bytes calldata depositParams,
        bytes calldata executeParams
    ) external payable returns (address marginTrading) {
        if (_flag == 1) {
            marginTrading = Clones.cloneDeterministic(
                MARGIN_TRADING_TEMPLATE,
                keccak256(abi.encodePacked(msg.sender, crossMarginTrading[msg.sender].length, _flag))
            );
            crossMarginTrading[msg.sender].push(marginTrading);
            emit MarginTradingCreated(msg.sender, marginTrading, crossMarginTrading[msg.sender].length, _flag);
        }
        if (_flag == 2) {
            marginTrading = Clones.cloneDeterministic(
                MARGIN_TRADING_TEMPLATE,
                keccak256(abi.encodePacked(msg.sender, isolatedMarginTrading[msg.sender].length, _flag))
            );
            isolatedMarginTrading[msg.sender].push(marginTrading);
            emit MarginTradingCreated(msg.sender, marginTrading, isolatedMarginTrading[msg.sender].length, _flag);
        }
        //调用marginTrading地址的合约中的"initialize"方法,LendingPool,WETH,user
        IMarginTrading(marginTrading).initialize(LendingPool, address(WETH), msg.sender);
        if (depositParams.length > 0) {
            (
                uint8 _depositFlag, //1- erc20 2-eth
                address _tokenAddres,
                uint256 _depositAmount
            ) = abi.decode(depositParams, (uint8, address, uint256));
            if (_depositFlag == 1) {
                _depositMarginTradingERC20(marginTrading, _tokenAddres, _depositAmount, false, uint8(1));
            }
            if (_depositFlag == 2) {
                depositMarginTradingETH(marginTrading, false, uint8(1));
            }
        }
        if (executeParams.length > 0) {
            (
                address[] memory _assets,
                uint256[] memory _amounts,
                uint256[] memory _modes,
                address _mainToken,
                bytes memory _params
            ) = abi.decode(executeParams, (address[], uint256[], uint256[], address, bytes));
            _executeMarginTradingFlashLoans(marginTrading, _assets, _amounts, _modes, _mainToken, _params);
        }
    }

    /// @notice Execution marginTrading executeFlashLoans methods for opening and closing.
    /// @dev Execute a flash loan and pass the parameters to the executeOperation method.
    /// @param assets Borrowing assets
    /// @param amounts Borrowing assets amounts
    /// @param modes Borrowing assets premiums
    /// @param mainToken initiator address
    /// @param params The parameters for the execution logic.
    function executeMarginTradingFlashLoans(
        address _marginTradingAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external {
        _executeMarginTradingFlashLoans(_marginTradingAddress, assets, amounts, modes, mainToken, params);
    }

    /// @notice User deposits ERC20 token into marginTrading contract.
    /// @dev Use DODOApprove to allow users to deposit ERC20 tokens into the marginTrading contract.
    /// @param _marginTradingAddress User marginTrading contract address
    /// @param _marginAddress Margin token address
    /// @param _marginAmount Margin token amount
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function depositMarginTradingERC20(
        address _marginTradingAddress,
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) external {
        _depositMarginTradingERC20(_marginTradingAddress, _marginAddress, _marginAmount, _margin, _flag);
    }

    /// @notice User deposits ETH into marginTrading contract.
    /// @dev Convert ETH to ERC20 token using the WETH contract, and then deposit it into the marginTrading contract.
    /// @param _marginTradingAddress User marginTrading contract address
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function depositMarginTradingETH(address _marginTradingAddress, bool _margin, uint8 _flag) public payable {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory:caller is not the user");
        WETH.deposit{value: msg.value}();
        WETH.transfer(_marginTradingAddress, msg.value);
        if (_margin) {
            IMarginTrading(_marginTradingAddress).lendingPoolDeposit(address(WETH), msg.value, _flag);
        }
        emit DepositMarginTradingETH(_marginTradingAddress, msg.value, _margin, _flag);
    }

    /// @notice Owner clean contract ERC20 token
    /// @param _tokenAddress send ERC20 token address
    /// @param _to To address
    /// @param _amt send ERC20 token amount
    function cleanToken(address _tokenAddress, address _to, uint256 _amt) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amt);
        emit CleanToken(_tokenAddress, _to, _amt);
    }

    /// @notice Owner clean contract ETH.
    /// @param _to To address
    /// @param _amt send ETH amount
    function cleanETH(address _to, uint256 _amt) external onlyOwner {
        (bool success,) = _to.call{value: _amt}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
        emit CleanETH(_to, _amt);
    }

    // =========== internal ==========

    /// @notice Execution marginTrading contract methods for opening and closing.
    /// @dev Execute a flash loan and pass the parameters to the executeOperation method.
    /// @param _marginTradingAddress MarginTrading contract address
    /// @param assets Borrowing assets
    /// @param amounts Borrowing assets amounts
    /// @param modes Borrowing assets premiums
    /// @param mainToken initiator address
    /// @param params The parameters for the execution logic.
    function _executeMarginTradingFlashLoans(
        address _marginTradingAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory modes,
        address mainToken,
        bytes memory params
    ) internal {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory: caller is not the user");
        IMarginTrading(_marginTradingAddress).executeFlashLoans(assets, amounts, modes, mainToken, params);
    }

    /// @notice Deposits ERC20 token into marginTrading contract.
    /// @param _marginTradingAddress MarginTrading contract address
    /// @param _marginAddress margin token address
    /// @param _marginAmount margin token Amount
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function _depositMarginTradingERC20(
        address _marginTradingAddress,
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) internal {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory:caller is not the user");
        DODOApprove.claimTokens(_marginAddress, msg.sender, _marginTradingAddress, _marginAmount);
        if (_margin) {
            IMarginTrading(_marginTradingAddress).lendingPoolDeposit(_marginAddress, _marginAmount, _flag);
        }
        emit DepositMarginTradingERC20(_marginTradingAddress, _marginAddress, _marginAmount, _margin, _flag);
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0*/

pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

library Types {
    uint16 internal constant REFERRAL_CODE = uint16(0);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0*/

pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {InitializableOwnable} from "./InitializableOwnable.sol";

/**
 * @title DODOApprove
 * @author DODO Breeder
 *
 * @notice Handle authorizations in DODO platform
 */
contract DODOApprove is InitializableOwnable {
    using SafeERC20 for IERC20;

    // ============ Storage ============
    uint256 private constant _TIMELOCK_DURATION_ = 3 days;
    uint256 private constant _TIMELOCK_EMERGENCY_DURATION_ = 24 hours;
    uint256 public _TIMELOCK_;
    address public _PENDING_DODO_PROXY_;
    address public _DODO_PROXY_;

    // ============ Events ============

    event SetDODOProxy(address indexed oldProxy, address indexed newProxy);

    // ============ Modifiers ============
    modifier notLocked() {
        require(_TIMELOCK_ <= block.timestamp, "SetProxy is timelocked");
        _;
    }

    function init(address owner, address initProxyAddress) external {
        initOwner(owner);
        _DODO_PROXY_ = initProxyAddress;
    }

    function unlockSetProxy(address newDodoProxy) public onlyOwner {
        if (_DODO_PROXY_ == address(0)) {
            _TIMELOCK_ = block.timestamp + _TIMELOCK_EMERGENCY_DURATION_;
        } else {
            _TIMELOCK_ = block.timestamp + _TIMELOCK_DURATION_;
        }
        _PENDING_DODO_PROXY_ = newDodoProxy;
    }

    function lockSetProxy() public onlyOwner {
        _PENDING_DODO_PROXY_ = address(0);
        _TIMELOCK_ = 0;
    }

    function setDODOProxy() external onlyOwner notLocked {
        emit SetDODOProxy(_DODO_PROXY_, _PENDING_DODO_PROXY_);
        _DODO_PROXY_ = _PENDING_DODO_PROXY_;
        lockSetProxy();
    }

    function claimTokens(address token, address who, address dest, uint256 amount) external {
        require(msg.sender == _DODO_PROXY_, "DODOApprove:Access restricted");
        if (amount > 0) {
            IERC20(token).safeTransferFrom(who, dest, amount);
        }
    }

    function getDODOProxy() public view returns (address) {
        return _DODO_PROXY_;
    }

    // Make forge coverage ignore
    function testSuccess() public {}
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0*/

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

import {IDODOApprove} from "./IDODOApprove.sol";
import {InitializableOwnable} from "./InitializableOwnable.sol";

interface IDODOApproveProxy {
    function isAllowedProxy(address _proxy) external view returns (bool);
    function claimTokens(address token, address who, address dest, uint256 amount) external;
}

/**
 * @title DODOApproveProxy
 * @author DODO Breeder
 *
 * @notice Allow different version dodoproxy to claim from DODOApprove
 */
contract DODOApproveProxy is InitializableOwnable {
    // ============ Storage ============
    uint256 private constant _TIMELOCK_DURATION_ = 3;
    mapping(address => bool) public _IS_ALLOWED_PROXY_;
    uint256 public _TIMELOCK_;
    address public _PENDING_ADD_DODO_PROXY_;
    address public immutable _DODO_APPROVE_;

    // ============ Modifiers ============
    modifier notLocked() {
        require(_TIMELOCK_ <= block.timestamp, "SetProxy is timelocked");
        _;
    }

    constructor(address dodoApporve) {
        _DODO_APPROVE_ = dodoApporve;
    }

    function init(address owner, address[] memory proxies) external {
        initOwner(owner);
        for (uint256 i = 0; i < proxies.length; i++) {
            _IS_ALLOWED_PROXY_[proxies[i]] = true;
        }
    }

    function unlockAddProxy(address newDodoProxy) public onlyOwner {
        _TIMELOCK_ = block.timestamp + _TIMELOCK_DURATION_;
        _PENDING_ADD_DODO_PROXY_ = newDodoProxy;
    }

    function lockAddProxy() public onlyOwner {
        _PENDING_ADD_DODO_PROXY_ = address(0);
        _TIMELOCK_ = 0;
    }

    function addDODOProxy() external onlyOwner notLocked {
        _IS_ALLOWED_PROXY_[_PENDING_ADD_DODO_PROXY_] = true;
        lockAddProxy();
    }

    function removeDODOProxy(address oldDodoProxy) public onlyOwner {
        _IS_ALLOWED_PROXY_[oldDodoProxy] = false;
    }

    function claimTokens(address token, address who, address dest, uint256 amount) external {
        require(_IS_ALLOWED_PROXY_[msg.sender], "NOT_ALLOWED_PROXY");
        IDODOApprove(_DODO_APPROVE_).claimTokens(token, who, dest, amount);
    }

    function isAllowedProxy(address _proxy) external view returns (bool) {
        return _IS_ALLOWED_PROXY_[_proxy];
    }

    // Make forge coverage ignore
    function testSuccess() public {}
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0*/

pragma solidity 0.8.15;

interface IDODOApprove {
    function claimTokens(address token, address who, address dest, uint256 amount) external;
    function getDODOProxy() external view returns (address);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0*/

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract MockAaveERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed user, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");

        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address account, uint256 amount) external {
        balances[account] = balances[account] + amount;
    }

    // comment this function out because Ethersjs cannot tell two functions with same name
    // function mint(uint256 amount) external {
    //     balances[msg.sender] = balances[msg.sender] + amount;
    // }

    // Make forge coverage ignore
    function testSuccess() public {}

    function burn(address user, uint256 amount) external {
        require(amount <= balances[user], "BALANCE_NOT_ENOUGH");
        balances[user] = balances[user] - amount;
        balances[address(0)] = balances[address(0)] + amount;
        emit Burn(user, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed user, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function mint(address account, uint256 amount) external {
        balances[account] = balances[account] + amount;
    }

    // comment this function out because Ethersjs cannot tell two functions with same name
    // function mint(uint256 amount) external {
    //     balances[msg.sender] = balances[msg.sender] + amount;
    // }

    // Make forge coverage ignore
    function testSuccess() public {}

    function burn(address user, uint256 amount) external {
        require(amount <= balances[user], "BALANCE_NOT_ENOUGH");
        balances[user] = balances[user] - amount;
        balances[address(0)] = balances[address(0)] + amount;
        emit Burn(user, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import {IFlashLoanReceiver} from "../aaveLib/Interfaces.sol";

contract MockLendingPool {
    MockERC20 public depositToken; //存入token
    MockERC20 public borrowToken; //借贷token

    MockERC20 public aToken; //标记存款
    MockERC20 public debtToken; //标记借款

    event Withdraw(address asset, address user, address to, uint256 amountToWithdraw);

    event Deposit(address asset, address sender, address onBehalfOf, uint256 amount, uint16 referralCode);

    event Borrow(address asset, address sender, address onBehalfOf, uint256 amount);

    event Repay(address asset, address onBehalfOf, address user, uint256 amount);

    event FlashLoan(
        address receiverAddress,
        address sender,
        address[] assets,
        uint256[] currentAmount,
        uint256[] currentPremium,
        uint16 referralCode
    );

    constructor(MockERC20 _deposit, MockERC20 _borrow, MockERC20 _aToken, MockERC20 _debtToken) public {
        depositToken = _deposit;
        borrowToken = _borrow;
        aToken = _aToken;
        debtToken = _debtToken;
    }

    function setToken(MockERC20 _depositToken, MockERC20 _borrowToken) public {
        depositToken = _depositToken;
        borrowToken = _borrowToken;
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 userBalance = aToken.balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount > userBalance) {
            amountToWithdraw = userBalance;
        }

        aToken.burn(to, amountToWithdraw);

        depositToken.transfer(to, amount);

        emit Withdraw(asset, to, to, amountToWithdraw);

        return amountToWithdraw;
    }

    function borrow(address asset, uint256 amount, address onBehalfOf) external {
        borrowToken.transfer(onBehalfOf, amount);

        debtToken.mint(onBehalfOf, amount);

        emit Borrow(asset, msg.sender, onBehalfOf, amount);
    }

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        depositToken.transferFrom(onBehalfOf, address(this), amount);

        aToken.mint(onBehalfOf, amount);

        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }

    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256) {
        require(amount <= debtToken.balanceOf(onBehalfOf), "amount > debtTokenBalance");

        borrowToken.transferFrom(onBehalfOf, address(this), amount);

        debtToken.burn(onBehalfOf, amount);

        emit Repay(asset, onBehalfOf, msg.sender, amount);

        return amount;
    }

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external {
        uint256 borrowAmounts = amounts[0];

        uint256[] memory _premiums = new uint256[](1);
        if (modes[0] == 0) {
            _premiums[0] = (borrowAmounts * 9) / 10000;
            borrowAmounts = (borrowAmounts * 10009) / 10000;
        }
        borrowToken.transfer(onBehalfOf, borrowAmounts);

        IFlashLoanReceiver(msg.sender).executeOperation(assets, amounts, _premiums, msg.sender, params);

        if (modes[0] == 0) {
            borrowToken.transferFrom(onBehalfOf, address(this), borrowAmounts);
        } else {
            debtToken.mint(onBehalfOf, borrowAmounts);
        }

        emit FlashLoan(receiverAddress, msg.sender, assets, amounts, _premiums, referralCode);
    }

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) public {
        uint256 debtAmount = debtToken.balanceOf(user);
        require(debtToCover <= debtAmount / 2, "liquidation debtAmount too more");
        borrowToken.transferFrom(msg.sender, address(this), debtToCover);
        debtToken.burn(user, debtToCover);
        if (receiveAToken) {
            aToken.transferFrom(user, msg.sender, (debtToCover * 105) / 100);
        } else {
            depositToken.transfer(msg.sender, (debtToCover * 105) / 100);
            aToken.burn(user, (debtToCover * 105) / 100);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import {IFlashLoanReceiver} from "../aaveLib/Interfaces.sol";

contract MockLendingPoolV2 {
    MockERC20 public daiToken;
    MockERC20 public wethToken;

    mapping(address => address) public aToken; //标记存款
    mapping(address => address) public debtToken; //标记借款

    event Withdraw(
        address asset,
        address user,
        address to,
        uint256 amountToWithdraw
    );

    event Deposit(
        address asset,
        address sender,
        address onBehalfOf,
        uint256 amount,
        uint16 referralCode
    );

    event Borrow(
        address asset,
        address sender,
        address onBehalfOf,
        uint256 amount
    );

    event Repay(
        address asset,
        address onBehalfOf,
        address user,
        uint256 amount
    );

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    event FlashLoan(
        address receiverAddress,
        address sender,
        address[] assets,
        uint256[] currentAmount,
        uint256[] currentPremium,
        uint16 referralCode
    );

    constructor(
        address _daiToken,
        address _wethToken,
        address[] memory _aToken,
        address[] memory _debtToken
    ) public {
        daiToken = MockERC20(_daiToken);
        wethToken = MockERC20(_wethToken);
        aToken[_daiToken] = _aToken[0];
        aToken[_wethToken] = _aToken[1];
        debtToken[_daiToken] = _debtToken[0];
        debtToken[_wethToken] = _debtToken[1];
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        uint256 userBalance = MockERC20(aToken[asset]).balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount > userBalance) {
            amountToWithdraw = userBalance;
        }

        MockERC20(aToken[asset]).burn(to, amountToWithdraw);

        MockERC20(asset).transfer(to, amount);

        emit Withdraw(asset, to, to, amountToWithdraw);

        return amountToWithdraw;
    }

    function borrow(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external {
        MockERC20(asset).transfer(onBehalfOf, amount);

        MockERC20(debtToken[asset]).mint(onBehalfOf, amount);

        emit Borrow(asset, msg.sender, onBehalfOf, amount);
    }

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        MockERC20(asset).transferFrom(onBehalfOf, address(this), amount);

        MockERC20(aToken[asset]).mint(onBehalfOf, amount);

        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256) {
        require(
            amount <= MockERC20(debtToken[asset]).balanceOf(onBehalfOf),
            "amount > debtTokenBalance"
        );

        MockERC20(asset).transferFrom(onBehalfOf, address(this), amount);

        MockERC20(debtToken[asset]).burn(onBehalfOf, amount);

        emit Repay(asset, onBehalfOf, msg.sender, amount);

        return amount;
    }

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external {
        uint256 borrowAmounts = amounts[0];

        uint256[] memory _premiums = new uint256[](1);
        if (modes[0] == 0) {
            _premiums[0] = (borrowAmounts * 9) / 10000;
            borrowAmounts = (borrowAmounts * 10009) / 10000;
        }
        MockERC20(assets[0]).transfer(onBehalfOf, amounts[0]);

        IFlashLoanReceiver(msg.sender).executeOperation(
            assets,
            amounts,
            _premiums,
            msg.sender,
            params
        );

        if (modes[0] == 0) {
            MockERC20(assets[0]).transferFrom(
                onBehalfOf,
                address(this),
                borrowAmounts
            );
        } else {
            MockERC20(debtToken[assets[0]]).mint(onBehalfOf, borrowAmounts);
        }

        emit FlashLoan(
            receiverAddress,
            msg.sender,
            assets,
            amounts,
            _premiums,
            referralCode
        );
    }

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) public {
        uint256 debtAmount = MockERC20(debt).balanceOf(user);
        require(
            debtToCover <= debtAmount / 2,
            "liquidation debtAmount too more"
        );
        //简单粗暴直接 1：1
        address borrowToken;
        address depositToken;
        if (debtToken[address(daiToken)] == debt) {
            borrowToken = address(daiToken);
            depositToken = address(wethToken);
        } else {
            borrowToken = address(wethToken);
            depositToken = address(daiToken);
        }
        MockERC20(borrowToken).transferFrom(
            msg.sender,
            address(this),
            debtToCover
        );
        MockERC20(debt).burn(user, debtToCover);
        if (receiveAToken) {
            MockERC20(aToken[depositToken]).transferFrom(
                user,
                msg.sender,
                (debtToCover * 105) / 100
            );
        } else {
            MockERC20(depositToken).transfer(
                msg.sender,
                (debtToCover * 105) / 100
            );
            MockERC20(aToken[depositToken]).burn(
                user,
                (debtToCover * 105) / 100
            );
        }
        emit LiquidationCall(
            aToken[depositToken],
            debt,
            user,
            debtToCover,
            (debtToCover * 105) / 100,
            msg.sender,
            receiveAToken
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import "./DODOApproveProxy.sol";

contract MockRouter {
    DODOApproveProxy public dodoApproveProxy;

    constructor(DODOApproveProxy _dodoApproveProxy) {
        dodoApproveProxy = _dodoApproveProxy;
    }

    function swap(address fromToken, address toToken, uint256 fromAmount) public {
        uint256 fromTokenBalance = MockERC20(fromToken).balanceOf(address(this));
        uint256 toTokenBalance = MockERC20(toToken).balanceOf(address(this));
        uint256 toAmount = toTokenBalance - (toTokenBalance * fromTokenBalance) / (fromTokenBalance + fromAmount);
        dodoApproveProxy.claimTokens(fromToken, msg.sender, address(this), fromAmount);
        MockERC20(toToken).transfer(msg.sender, toAmount);
    }

    function encodeFlashLoan(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _modes,
        address _mainToken,
        bytes memory _params
    ) public pure returns (bytes memory result) {
        result = abi.encode(_assets, _amounts, _modes, _mainToken, _params);
    }

    function encodeExecuteParams(
        uint8 _flag,
        address _swapAddress,
        address _swapApproveTarget,
        address[] memory _swapApproveToken,
        bytes memory _swapParams,
        address[] memory _tradeAssets,
        address[] memory _withdrawAssets,
        uint256[] memory _withdrawAmounts,
        uint256[] memory _rateMode,
        address[] memory _debtTokens
    ) public pure returns (bytes memory result) {
        result = abi.encode(
            _flag,
            _swapAddress,
            _swapApproveTarget,
            _swapApproveToken,
            _swapParams,
            _tradeAssets,
            _withdrawAssets,
            _withdrawAmounts,
            _rateMode,
            _debtTokens
        );
    }

    function encodeDepositParams(
        uint8 _depositFlag, //1- erc20 2-eth
        address _tokenAddres,
        uint256 _depositAmount
    ) public pure returns (bytes memory result) {
        result = abi.encode(_depositFlag, _tokenAddres, _depositAmount);
    }

    function getSwapCalldata(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) public pure returns (bytes memory swapParams) {
        swapParams = abi.encodeWithSignature("swap(address,address,uint256)", fromToken, toToken, fromAmount);
    }

    function getRouterToAmount(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) public view returns (uint256 toAmount) {
        uint256 fromTokenBalance = MockERC20(fromToken).balanceOf(address(this));
        uint256 toTokenBalance = MockERC20(toToken).balanceOf(address(this));
        toAmount = toTokenBalance - (toTokenBalance * fromTokenBalance) / (fromTokenBalance + fromAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function testSuccess() public {}
}