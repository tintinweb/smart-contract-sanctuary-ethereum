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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

/*
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 * See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);
    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /** 
    *
    * !!!!!!!!!!!!!!
    * !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    * !!!!!!!!!!!!!!
    *
    * @notice Transfer `amount` tokens from `msg.sender` to `dst`
    * @param dst The address of the destination account
    * @param amount The number of tokens to transfer
    */
    function transfer(address dst, uint256 amount) external;
    /** 
    *
    * !!!!!!!!!!!!!!
    * !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    * !!!!!!!!!!!!!!
    *
    * @notice Transfer `amount` tokens from `src` to `dst`
    * @param src The address of the source account
    * @param dst The address of the destination account
    * @param amount The number of tokens to transfer
    */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;
    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);
    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _whom) external view returns (uint256);
    function allowance(address _src, address _dst) external view returns (uint256);
    function approve(address _dst, uint256 _amt) external returns (bool);
    function transfer(address _dst, uint256 _amt) external returns (bool);
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

interface IPausablePool {
    // Getter method
    function paused() external view returns (bool);

    // Setter methods
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IERC20Modified.sol";
import "./IVolmexPool.sol";
import "./IPausablePool.sol";
import "./IVolmexProtocol.sol";

interface IVolmexController {
    event AdminFeeUpdated(uint256 adminFee);
    event CollateralSwapped(
        uint256 volatilityAmountConsumed,
        uint256 collateralOutAmount,
        uint256 protocolFee,
        uint256 poolFee,
        uint256 indexed stableCoinIndex,
        address indexed token
    );
    event PoolSwapped(
        uint256 volatilityInAmount,
        uint256 volatilityOutAmount,
        uint256 protocolFee,
        uint256[2] poolFee,
        uint256 indexed stableCoinIndex,
        address[2] tokens
    );
    event PoolAdded(uint256 indexed poolIndex, address indexed pool);
    event StableCoinAdded(uint256 indexed stableCoinIndex, address indexed stableCoin);
    event ProtocolAdded(uint256 poolIndex, uint256 stableCoinIndex, address indexed protocol);
    event PoolTokensCollected(address indexed owner, uint256 amount);

    // Getter methods
    function stableCoinIndex() external view returns (uint256);
    function poolIndex() external view returns (uint256);
    function pools(uint256 _index) external view returns (IVolmexPool);
    function stableCoins(uint256 _index) external view returns (IERC20Modified);
    function isPool(address _pool) external view returns (bool);
    function precisionRatios(uint256 _index) external view returns (uint256);
    function protocols(
        uint256 _poolIndex,
        uint256 _stableCoinIndex
    ) external view returns (IVolmexProtocol);

    // Setter methods
    function addPool(IVolmexPool _pool) external;
    function addStableCoin(IERC20Modified _stableCoin) external;
    function togglePause(bool _isPause) external;
    function collect(IVolmexPool _pool) external;
    function addProtocol(
        uint256 _poolIndex,
        uint256 _stableCoinIndex,
        IVolmexProtocol _protocol
    ) external;
    function swapCollateralToVolatility(
        uint256[2] calldata _amounts,
        address _tokenOut,
        uint256[2] calldata _indices
    ) external;
    function swapVolatilityToCollateral(
        uint256[2] calldata _amounts,
        uint256[2] calldata _indices,
        IERC20Modified _tokenIn
    ) external;
    function swapBetweenPools(
        address[2] calldata _tokens,
        uint256[2] calldata _amounts,
        uint256[3] calldata _indices
    ) external;
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external;
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external;
    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external;
    function transferAssetToPool(
        IERC20Modified _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IVolmexProtocol.sol";

interface IVolmexOracle {
    event SymbolIndexUpdated(uint256 indexed _index);
    event BaseVolatilityIndexUpdated(uint256 indexed baseVolatilityIndex);
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );
    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );
    event LeveragedVolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 leverage,
        uint256 baseVolatilityIndex
    );

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function volatilityLastUpdateTimestamp(uint256 _index) external view returns (uint256);
    function volatilityLeverageByIndex(uint256 _index) external view returns (uint256);
    function baseVolatilityIndex(uint256 _index) external view returns (uint256);
    function indexCount() external view returns (uint256);
    function latestRoundData(uint256 _index)
        external
        view
        returns (uint256 answer, uint256 lastUpdateTimestamp);
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external;
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "../libs/tokens/Token.sol";
import "./IVolmexProtocol.sol";
import "./IVolmexRepricer.sol";
import "./IVolmexController.sol";

interface IVolmexPool is IERC20 {
    struct Record {
        uint256 leverage;
        uint256 balance;
    }

    event Swapped(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut,
        uint256 fee,
        uint256 tokenBalanceIn,
        uint256 tokenBalanceOut,
        uint256 tokenLeverageIn,
        uint256 tokenLeverageOut
    );
    event Joined(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
    event Exited(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
    event Repriced(
        uint256 repricingBlock,
        uint256 balancePrimary,
        uint256 balanceComplement,
        uint256 leveragePrimary,
        uint256 leverageComplement,
        uint256 newLeveragePrimary,
        uint256 newLeverageComplement,
        uint256 estPricePrimary,
        uint256 estPriceComplement
    );
    event Called(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event ControllerSet(address indexed controller);
    event FeeParamsSet(
        uint256 baseFee,
        uint256 maxFee,
        uint256 feeAmpPrimary,
        uint256 feeAmpComplement
    );
    event AdminFeeUpdated(uint256 fee);
    event VolatilityIndexUpdated(uint256 newIndex);
    event ExposureLimitUpdated(uint256 exposureLimitPrimary, uint256 exposureLimitComplement);

    // Getter methods
    function repricingBlock() external view returns (uint256);
    function baseFee() external view returns (uint256);
    function feeAmpPrimary() external view returns (uint256);
    function feeAmpComplement() external view returns (uint256);
    function maxFee() external view returns (uint256);
    function pMin() external view returns (uint256);
    function qMin() external view returns (uint256);
    function exposureLimitPrimary() external view returns (uint256);
    function exposureLimitComplement() external view returns (uint256);
    function protocol() external view returns (IVolmexProtocol);
    function repricer() external view returns (IVolmexRepricer);
    function volatilityIndex() external view returns (uint256);
    function finalized() external view returns (bool);
    function upperBoundary() external view returns (uint256);
    function adminFee() external view returns (uint256);
    function getLeverage(address _token) external view returns (uint256);
    function getBalance(address _token) external view returns (uint256);
    function tokens(uint256 _index) external view returns (address);
    function getLeveragedBalance(Record memory r) external pure returns (uint256);
    function getTokenAmountOut(
        address _tokenIn,
        uint256 _tokenAmountIn
    ) external view returns (uint256, uint256);

    // Setter methods
    function setController(IVolmexController _controller) external;
    function joinPool(uint256 _poolAmountOut, uint256[2] calldata _maxAmountsIn, address _receiver) external;
    function exitPool(uint256 _poolAmountIn, uint256[2] calldata _minAmountsOut, address _receiver) external;
    function togglePause(bool _isPause) external;
    function reprice() external;
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    ) external returns (uint256, uint256);
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external;
    function updateExposureLimit(
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external returns (uint256, uint256);
    function redeem(uint256 _positionTokenQty) external returns (uint256, uint256);
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external returns (uint256, uint256);
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IVolmexOracle.sol";

interface IVolmexRepricer {
    // Event emitted when the allowed delay in the oracle price is updated
    event AllowedDelayUpdated(uint256 newDuration);

    // Getter method
    function oracle() external view returns (IVolmexOracle);

    // Setter methods
    function sqrtWrapped(int256 value) external pure returns (int256);
    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );
    function updateAllowedDelay(uint256 _newDuration) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "../../maths/Num.sol";
import "../../interfaces/IERC20.sol";

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed _src, address indexed _dst, uint256 _amt);
    event Transfer(address indexed _src, address indexed _dst, uint256 _amt);

    function _mint(uint256 _amt) internal {
        _balance[address(this)] = _balance[address(this)] + _amt;
        _totalSupply = _totalSupply + _amt;
        emit Transfer(address(0), address(this), _amt);
    }

    function _burn(uint256 _amt) internal {
        require(_balance[address(this)] >= _amt, "INSUFFICIENT_BAL");
        _balance[address(this)] = _balance[address(this)] - _amt;
        _totalSupply = _totalSupply - _amt;
        // Total supply cannot be zero to make sure join pool works after finalization
        require(_totalSupply != 0, "Supply cannot be zero");
        emit Transfer(address(this), address(0), _amt);
    }

    function _move(
        address _src,
        address _dst,
        uint256 _amt
    ) internal {
        require(_balance[_src] >= _amt, "INSUFFICIENT_BAL");
        _balance[_src] = _balance[_src] - _amt;
        _balance[_dst] = _balance[_dst] + _amt;
        emit Transfer(_src, _dst, _amt);
    }

    function _push(address _to, uint256 _amt) internal {
        _move(address(this), _to, _amt);
    }

    function _pull(address _from, uint256 _amt) internal {
        _move(_from, address(this), _amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function approve(address _dst, uint256 _amt) external override returns (bool) {
        _allowance[msg.sender][_dst] = _amt;
        emit Approval(msg.sender, _dst, _amt);
        return true;
    }

    function increaseApproval(address _dst, uint256 _amt) external returns (bool) {
        _allowance[msg.sender][_dst] = _allowance[msg.sender][_dst] + _amt;
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function decreaseApproval(address _dst, uint256 _amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][_dst];
        if (_amt > oldValue) {
            _allowance[msg.sender][_dst] = 0;
        } else {
            _allowance[msg.sender][_dst] = oldValue - _amt;
        }
        emit Approval(msg.sender, _dst, _allowance[msg.sender][_dst]);
        return true;
    }

    function transfer(address _dst, uint256 _amt) external override returns (bool) {
        _move(msg.sender, _dst, _amt);
        return true;
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[_src][msg.sender];
        require(msg.sender == _src || _amt <= oldValue, "TOKEN_BAD_CALLER");
        _move(_src, _dst, _amt);
        if (msg.sender != _src && oldValue != type(uint128).max) {
            _allowance[_src][msg.sender] = oldValue - _amt;
            emit Approval(msg.sender, _dst, _allowance[_src][msg.sender]);
        }
        return true;
    }

    function allowance(address _src, address _dst) external view override returns (uint256) {
        return _allowance[_src][_dst];
    }

    function balanceOf(address _whom) external view override returns (uint256) {
        return _balance[_whom];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _setName(string memory _poolName) internal {
        _name = _poolName;
    }

    function _setSymbol(string memory _poolSymbol) internal {
        _symbol = _poolSymbol;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

contract TokenMetadataGenerator {
    function _formatMeta(
        string memory _prefix,
        string memory _concatenator,
        string memory _postfix
    ) internal pure returns (string memory) {
        return _concat(_prefix, _concat(_concatenator, _postfix));
    }

    function _makeTokenName(string memory _baseName, string memory _postfix)
        internal
        pure
        returns (string memory)
    {
        return _formatMeta(_baseName, " ", _postfix);
    }

    function _makeTokenSymbol(string memory _baseName, string memory _postfix)
        internal
        pure
        returns (string memory)
    {
        return _formatMeta(_baseName, "-", _postfix);
    }

    function _concat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

contract Const {
    uint256 public constant BONE = 10**18;
    int256 public constant iBONE = int256(BONE);
    uint256 public constant MAX_IN_RATIO = BONE / 2;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "abdk-libraries-solidity/ABDKMathQuad.sol";

import "./Num.sol";
import "../interfaces/IVolmexPool.sol";

contract Math is Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                 bI          1                                         //
    // bO = tokenBalanceOut         sP =  ----  *  ----------                                    //
    // sF = swapFee                        bO      ( 1 - sF )                                    //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 ratio = _div(_tokenBalanceIn, _tokenBalanceOut);
        uint256 scale = _div(BONE, BONE - _swapFee);
        spotPrice = _mul(ratio, scale);
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \   \                 //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  |  |                 //
    // sF = swapFee                     \      \ ( bI + ( aI * ( 1 - sF )) /   /                 //
    **********************************************************************************************/
    function _calcOutGivenIn(
        uint256 _tokenBalanceIn,
        uint256 _tokenBalanceOut,
        uint256 _tokenAmountIn,
        uint256 _swapFee
    ) internal pure returns (uint256 tokenAmountOut) {
        uint256 adjustedIn = BONE - _swapFee;
        adjustedIn = _mul(_tokenAmountIn, adjustedIn);
        uint256 y = _div(_tokenBalanceIn, _tokenBalanceIn + adjustedIn);
        uint256 bar = BONE - y;
        tokenAmountOut = _mul(_tokenBalanceOut, bar);
    }

    /**
     * @notice Used to calculate the out amount after fee deduction
     */
    function _calculateAmountOut(
        uint256 _poolAmountIn,
        uint256 _ratio,
        uint256 _tokenReserve,
        uint256 _upperBoundary,
        uint256 _adminFee
    ) internal pure returns (uint256 amountOut, uint256 feeAmount) {
        uint256 tokenAmount = _mul(_div(_poolAmountIn, _upperBoundary), BONE);
        amountOut = _mul(_ratio, _tokenReserve);
        if (amountOut > tokenAmount) {
            feeAmount = _div(_mul(tokenAmount, _adminFee), 10000);
            amountOut = amountOut - feeAmount;
        }
    }

    /**
     * @notice Used to calculate the collateral/volatility amount after interaction with VolmexProtocol
     */
    function _calculateAssetQuantity(
        uint256 _amount,
        uint256 _feePercent,
        bool _isVolatilityRequired,
        uint256 _volatilityCapRatio,
        uint256 _precisionRatio
    ) internal pure returns (uint256 amount, uint256 protocolFee) {
        uint256 effectiveAmount = _isVolatilityRequired ? _amount : _amount / _precisionRatio;

        protocolFee = ((effectiveAmount * _feePercent) / 10000);
        effectiveAmount = effectiveAmount - protocolFee;

        amount = _isVolatilityRequired
            ? (effectiveAmount / _volatilityCapRatio) * _precisionRatio
            : effectiveAmount;
    }

    /**
     * @notice Used to calculate the amountIn and amountOut, provided max amount
     */
    function _getSwappedAssetAmount(
        address _tokenIn,
        uint256 _maxAmountIn,
        IVolmexPool _pool,
        bool _isInverse
    )
        internal
        view
        returns (
            uint256 swapAmount,
            uint256 amountOut,
            uint256 fee
        )
    {
        uint256 leverageBalance = _mul(
            _pool.getLeverage(_pool.tokens(0)),
            _pool.getBalance(_pool.tokens(0))
        );
        uint256 iLeverageBalance = _mul(
            _pool.getLeverage(_pool.tokens(1)),
            _pool.getBalance(_pool.tokens(1))
        );

        swapAmount = _volatililtyAmountToSwap(
            _maxAmountIn,
            _isInverse ? iLeverageBalance : leverageBalance,
            _isInverse ? leverageBalance : iLeverageBalance,
            0
        );
        (amountOut, fee) = _pool.getTokenAmountOut(_tokenIn, swapAmount);
        swapAmount = _volatililtyAmountToSwap(
            _maxAmountIn,
            _isInverse ? iLeverageBalance : leverageBalance,
            _isInverse ? leverageBalance : iLeverageBalance,
            fee
        );
        (amountOut, fee) = _pool.getTokenAmountOut(_tokenIn, swapAmount);
    }

    /**
     * Reference: https://excalidraw.com/#json=Rg2qV51HsIX2OoRZVQ-FK,9Y3xGthsEf1sXnB_H4V7Zw
     */
    function _volatililtyAmountToSwap(
        uint256 _maxAmount,
        uint256 _leverageBalanceOfIn,
        uint256 _leverageBalanceOfOut,
        uint256 _fee
    ) private pure returns (uint256 swapAmount) {
        uint256 R = BONE - _fee;
        uint256 B = ((_leverageBalanceOfIn * BONE) +
            (_leverageBalanceOfOut * R) -
            (_maxAmount * R)) / 10**6;

        uint256 numerator = ABDKMathQuad.toUInt(
            ABDKMathQuad.sqrt(
                ABDKMathQuad.fromUInt(
                    (B * B) + (4 * R * _leverageBalanceOfIn * _maxAmount) * (10**6)
                )
            )
        ) - B;

        swapAmount = numerator / ((2 * R) / 10**6);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./Const.sol";

contract Num is Const {
    function _subSign(uint256 _a, uint256 _b) internal pure returns (uint256, bool) {
        if (_a >= _b) {
            return (_a - _b, false);
        } else {
            return (_b - _a, true);
        }
    }

    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        uint256 c0 = _a * _b;
        uint256 c1 = c0 + (BONE / 2);
        c = c1 / BONE;
    }

    function _div(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, "DIV_ZERO");
        uint256 c0 = _a * BONE;
        uint256 c1 = c0 + (_b / 2);
        c = c1 / _b;
    }

    function _min(uint256 _first, uint256 _second) internal pure returns (uint256) {
        if (_first < _second) {
            return _first;
        }
        return _second;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import "./libs/tokens/TokenMetadataGenerator.sol";
import "./libs/tokens/Token.sol";
import "./maths/Math.sol";
import "./interfaces/IEIP20NonStandard.sol";
import "./interfaces/IVolmexRepricer.sol";
import "./interfaces/IVolmexProtocol.sol";
import "./interfaces/IVolmexPool.sol";
import "./interfaces/IVolmexController.sol";

/**
 * @title Volmex Pool Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexPool is
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC165StorageUpgradeable,
    Token,
    Math,
    TokenMetadataGenerator,
    IVolmexPool
{
    // Interface ID of VolmexRepricer contract, hashId = 0x822da258
    bytes4 private constant _IVOLMEX_REPRICER_ID = type(IVolmexRepricer).interfaceId;
    // Interface ID of VolmexPool contract, hashId = 0x71e45f88
    bytes4 private constant _IVOLMEX_POOL_ID = type(IVolmexPool).interfaceId;
    // Interface ID of VolmexController contract, hashId = 0xe8f8535b
    bytes4 private constant _IVOLMEX_CONTROLLER_ID = type(IVolmexController).interfaceId;
    // Number of tokens the pool can hold
    uint256 private constant _BOUND_TOKENS = 2;

    // Used to prevent the re-entry
    bool private _mutex;
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool public finalized;
    // Address of the pool tokens
    address[_BOUND_TOKENS] public tokens;

    // This is mapped by token addresses
    mapping(address => Record) public records;

    // Address of the pool controller
    IVolmexController public controller;
    // Value of the current block number while repricing
    uint256 public repricingBlock;
    // Value of upper boundary, set in reference of volatility cap ratio { 250 * 10**18 }
    uint256 public upperBoundary;
    // fee of the pool, used to calculate the swap fee
    uint256 public baseFee;
    // fee on the primary token, used to calculate swap fee, when the swap in asset is primary
    uint256 public feeAmpPrimary;
    // fee on the complement token, used to calculate swap fee, when the swap in asset is complement
    uint256 public feeAmpComplement;
    // Max fee on the swap operation
    uint256 public maxFee;
    // Minimum amount of tokens in the pool
    uint256 public pMin;
    // Minimum amount of token required for swap
    uint256 public qMin;
    // Difference in the primary token amount while swapping with the complement token
    uint256 public exposureLimitPrimary;
    // Difference in the complement token amount while swapping with the primary token
    uint256 public exposureLimitComplement;
    // The amount of collateral required to mint both the volatility tokens
    uint256 public denomination;
    // Address of the volmex repricer contract
    IVolmexRepricer public repricer;
    // Address of the volmex protocol contract
    IVolmexProtocol public protocol;
    // Number value of the volatility token index at oracle { 0 - ETHV, 1 - BTCV }
    uint256 public volatilityIndex;
    // Percentage of fee deducted for admin
    uint256 public adminFee;

    /**
     * @notice Used to log the callee's sig, address and data
     */
    modifier logs() {
        emit Called(msg.sig, msg.sender, msg.data);
        _;
    }

    /**
     * @notice Used to prevent the re-entry
     */
    modifier lock() {
        require(!_mutex, "VolmexPool: REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    /**
     * @notice Used to prevent multiple call to view methods
     */
    modifier viewlock() {
        require(!_mutex, "VolmexPool: REENTRY");
        _;
    }

    /**
     * @notice Used to check the pool is finalised
     */
    modifier onlyFinalized() {
        require(finalized, "VolmexPool: Pool is not finalized");
        _;
    }

    /**
     * @notice Used to check the protocol is not settled
     */
    modifier onlyNotSettled() {
        require(!protocol.isSettled(), "VolmexPool: Protocol is settled");
        _;
    }

    /**
     * @notice Used to check the caller is controller
     */
    modifier onlyController() {
        require(msg.sender == address(controller), "VolmexPool: Caller is not controller");
        _;
    }

    /**
     * @notice Initialize the pool contract with required elements
     *
     * @dev Checks, the protocol is a contract
     * @dev Sets repricer, protocol and controller addresses
     * @dev Sets upperBoundary, volatilityIndex and denomination
     * @dev Make the Pool token name and symbol
     *
     * @param _repricer Address of the volmex repricer contract
     * @param _protocol Address of the volmex protocol contract
     * @param _volatilityIndex Index of the volatility price in oracle
     * @param _baseFee Fee of the pool contract
     * @param _maxFee Max fee of the pool while swap
     * @param _feeAmpPrimary Fee on the primary token
     * @param _feeAmpComplement Fee on the complement token
     *
     * NOTE: The baseFee is set 0.02 * 10^18 currently, and it can only be set once. Be cautious
     */
    function initialize(
        IVolmexRepricer _repricer,
        IVolmexProtocol _protocol,
        uint256 _volatilityIndex,
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement,
        address _owner
    ) external initializer {
        require(
            IERC165Upgradeable(address(_repricer)).supportsInterface(_IVOLMEX_REPRICER_ID),
            "VolmexPool: Repricer does not supports interface"
        );
        require(address(_protocol) != address(0), "VolmexPool: protocol address can't be zero");

        repricer = _repricer;
        protocol = _protocol;
        upperBoundary = protocol.volatilityCapRatio() * BONE;
        volatilityIndex = _volatilityIndex;
        denomination = protocol.volatilityCapRatio();
        adminFee = 30;
        tokens[0] = address(protocol.volatilityToken());
        tokens[1] = address(protocol.inverseVolatilityToken());

        _setName(_makeTokenName(protocol.volatilityToken().name(), protocol.collateral().name()));
        _setSymbol(
            _makeTokenSymbol(protocol.volatilityToken().symbol(), protocol.collateral().symbol())
        );

        _setFeeParams(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);

        __Ownable_init();
        __Pausable_init_unchained();
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_POOL_ID);
        _transferOwnership(_owner);
    }

    /**
     * @notice Set controller of the Pool
     *
     * @param _controller Address of the pool contract controller
     */
    function setController(IVolmexController _controller) external onlyOwner {
        require(
            IERC165Upgradeable(address(_controller)).supportsInterface(_IVOLMEX_CONTROLLER_ID),
            "VolmexPool: Not Controller"
        );
        controller = _controller;

        emit ControllerSet(address(controller));
    }

    /**
     * @notice Used to update the admin fee
     */
    function updateAdminFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10000, "VolmexPool: _fee should be smaller than 10000");
        adminFee = _fee;

        emit AdminFeeUpdated(_fee);
    }

    /**
     * @notice Used to update the volatility index for oracle price tracking
     */
    function updateVolatilityIndex(uint256 _newIndex) external onlyOwner {
        volatilityIndex = _newIndex;

        emit VolatilityIndexUpdated(_newIndex);
    }

    /**
     * @notice Used to set exposure limit
     * @param _exposureLimitPrimary Primary to complement swap difference limit
     * @param _exposureLimitComplement Complement to primary swap difference limit
     */
    function updateExposureLimit(
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement
    ) external onlyOwner {
        exposureLimitPrimary = _exposureLimitPrimary;
        exposureLimitComplement = _exposureLimitComplement;
        emit ExposureLimitUpdated(exposureLimitPrimary, exposureLimitComplement);
    }

    /**
     * @notice Used to finalise the pool with the required attributes and operations
     *
     * @dev Checks, pool is finalised, caller is owner, supplied token balance
     * should be equal
     * @dev Binds the token, and its leverage and balance
     * @dev Calculates the initial pool supply, mints and transfer to the controller
     *
     * @param _primaryBalance Balance amount of primary token
     * @param _primaryLeverage Leverage value of primary token
     * @param _complementBalance  Balance amount of complement token
     * @param _complementLeverage  Leverage value of complement token
     * @param _exposureLimitPrimary Primary to complement swap difference limit
     * @param _exposureLimitComplement Complement to primary swap difference limit
     * @param _pMin Minimum amount of tokens in the pool
     * @param _qMin Minimum amount of token required for swap
     */
    function finalize(
        uint256 _primaryBalance,
        uint256 _primaryLeverage,
        uint256 _complementBalance,
        uint256 _complementLeverage,
        uint256 _exposureLimitPrimary,
        uint256 _exposureLimitComplement,
        uint256 _pMin,
        uint256 _qMin,
        address _receiver
    ) external logs lock onlyNotSettled onlyController {
        require(!finalized, "VolmexPool: Pool is finalized");

        require(
            _primaryBalance == _complementBalance,
            "VolmexPool: Assets balance should be same"
        );

        require(baseFee > 0, "VolmexPool: baseFee should be larger than 0");

        pMin = _pMin;
        qMin = _qMin;
        exposureLimitPrimary = _exposureLimitPrimary;
        exposureLimitComplement = _exposureLimitComplement;

        finalized = true;

        _bind(address(protocol.volatilityToken()), _primaryBalance, _primaryLeverage, _receiver);
        _bind(
            address(protocol.inverseVolatilityToken()),
            _complementBalance,
            _complementLeverage,
            _receiver
        );

        uint256 initPoolSupply = denomination * _primaryBalance;

        uint256 collateralDecimals = uint256(protocol.collateral().decimals());
        if (collateralDecimals < 18) {
            initPoolSupply = initPoolSupply * (10**(18 - collateralDecimals));
        }

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(_receiver, initPoolSupply);
    }

    /**
     * @notice Used to add liquidity to the pool
     *
     * @dev The token amount in of the pool will be calculated and pulled from LP
     *
     * @param _poolAmountOut Amount of pool token mint and transfer to LP
     * @param _maxAmountsIn Max amount of pool assets an LP can supply
     */
    function joinPool(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        address _receiver
    ) external logs lock onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = _div(_poolAmountOut, poolTotal);
        require(ratio != 0, "VolmexPool: Invalid math approximation");

        for (uint256 i = 0; i < _BOUND_TOKENS; i++) {
            address token = tokens[i];
            uint256 bal = records[token].balance;
            // This can't be tested, as the div method will fail, due to zero supply of lp token
            // The supply of lp token is greater than zero, means token reserve is greater than zero
            // Also, in the case of swap, there's some amount of tokens available pool more than qMin
            require(bal > 0, "VolmexPool: Insufficient balance in Pool");
            uint256 tokenAmountIn = _mul(ratio, bal);
            require(tokenAmountIn <= _maxAmountsIn[i], "VolmexPool: Amount in limit exploit");
            records[token].balance = records[token].balance + tokenAmountIn;
            emit Joined(_receiver, token, tokenAmountIn);
            _pullUnderlying(token, _receiver, tokenAmountIn);
        }

        _mintPoolShare(_poolAmountOut);
        _pushPoolShare(_receiver, _poolAmountOut);
    }

    /**
     * @notice Used to remove liquidity from the pool
     *
     * @dev The token amount out of the pool will be calculated and pushed to LP,
     * and pool token are pulled and burned
     *
     * @param _poolAmountIn Amount of pool token transfer to the pool
     * @param _minAmountsOut Min amount of pool assets an LP wish to redeem
     */
    function exitPool(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        address _receiver
    ) external logs lock onlyFinalized onlyController {
        uint256 poolTotal = totalSupply();
        uint256 ratio = _div(_poolAmountIn, poolTotal);
        require(ratio != 0, "VolmexPool: Invalid math approximation");

        for (uint256 i = 0; i < _BOUND_TOKENS; i++) {
            address token = tokens[i];
            uint256 bal = records[token].balance;
            require(bal > 0, "VolmexPool: Insufficient balance in Pool");
            (uint256 tokenAmountOut, ) = _calculateAmountOut(
                _poolAmountIn,
                ratio,
                bal,
                upperBoundary,
                adminFee
            );
            require(tokenAmountOut >= _minAmountsOut[i], "VolmexPool: Amount out limit exploit");
            records[token].balance = records[token].balance - tokenAmountOut;
            emit Exited(_receiver, token, tokenAmountOut);
            _pushUnderlying(token, _receiver, tokenAmountOut);
        }

        _pullPoolShare(_receiver, _poolAmountIn);
        _burnPoolShare(_poolAmountIn);
    }

    /**
     * @notice Used to swap the pool asset
     *
     * @dev Checks the token address, should be different
     * @dev token amount in should be greater than qMin
     * @dev reprices the assets
     * @dev Calculates the token amount out and spot price
     * @dev Perform swaps
     *
     * @param _tokenIn Address of the pool asset which the user supply
     * @param _tokenAmountIn Amount of asset the user supply
     * @param _tokenOut Address of the pool asset which the user wants
     * @param _minAmountOut Minimum amount of asset the user wants
     * @param _receiver Address of the contract/user from tokens are pulled
     * @param _toController Bool value, if `true` push to controller, else to `_receiver`
     */
    function swapExactAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _receiver,
        bool _toController
    )
        external
        logs
        lock
        whenNotPaused
        onlyFinalized
        onlyNotSettled
        onlyController
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        require(_tokenIn != _tokenOut, "VolmexPool: Passed same token addresses");
        require(_tokenAmountIn >= qMin, "VolmexPool: Amount in quantity should be larger");

        reprice();

        Record memory inRecord = records[_tokenIn];
        Record memory outRecord = records[_tokenOut];

        require(
            _tokenAmountIn <=
                _mul(_min(getLeveragedBalance(inRecord), inRecord.balance), MAX_IN_RATIO),
            "VolmexPool: Amount in max ratio exploit"
        );

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            0
        );

        uint256 fee = _calcFee(
            inRecord,
            _tokenAmountIn,
            outRecord,
            tokenAmountOut,
            tokens[0] == _tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        tokenAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            fee
        );
        require(tokenAmountOut >= _minAmountOut, "VolmexPool: Amount out limit exploit");

        uint256 _spotPriceBefore = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            0
        );

        spotPriceAfter = _performSwap(
            _tokenIn,
            _tokenAmountIn,
            _tokenOut,
            tokenAmountOut,
            _spotPriceBefore,
            fee,
            _receiver,
            _toController
        );
    }

    /**
     * @notice Used to pause the contract
     *
     * @param _isPause Boolean value to pause or unpause the position token { true = pause, false = unpause }
     */
    function togglePause(bool _isPause) external onlyController {
        _isPause ? _pause() : _unpause();
    }

    /**
     * @notice getter, used to fetch the token amount out and fee
     *
     * @param _tokenIn Address of the token in
     * @param _tokenAmountIn Amount of in token
     */
    function getTokenAmountOut(address _tokenIn, uint256 _tokenAmountIn)
        external
        view
        returns (uint256 minAmountOut, uint256 fee)
    {
        (Record memory inRecord, Record memory outRecord) = _getRepriced(_tokenIn);

        minAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            0
        );

        fee = _calcFee(
            inRecord,
            _tokenAmountIn,
            outRecord,
            minAmountOut,
            tokens[0] == _tokenIn ? feeAmpPrimary : feeAmpComplement
        );

        minAmountOut = _calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            _tokenAmountIn,
            fee
        );
    }

    /**
     * @notice Used to get the leverage of provided token address
     *
     * @param _token Address of the token, either primary or complement
     *
     * Can't remove this method, because struct of this contract can't be fetched in controller contract.
     * We will need to unpack the struct.
     */
    function getLeverage(address _token) external view viewlock returns (uint256) {
        return records[_token].leverage;
    }

    /**
     * @notice Used to get the balance of provided token address
     *
     * @param _token Address of the token. either primary or complement
     */
    function getBalance(address _token) external view viewlock returns (uint256) {
        return records[_token].balance;
    }

    /**
     * @notice Used to calculate the leverage of primary and complement token
     *
     * @dev checks if the repricing block is same, returns for true
     * @dev Fetches the est price of primary, complement and averaged
     * @dev Calculates the primary and complement leverage
     */
    function reprice() public {
        if (repricingBlock == block.number) return;
        repricingBlock = block.number;

        Record storage primaryRecord = records[tokens[0]];
        Record storage complementRecord = records[tokens[1]];

        uint256 estPricePrimary;
        uint256 estPriceComplement;
        uint256 estPrice;
        (estPricePrimary, estPriceComplement, estPrice) = repricer.reprice(volatilityIndex);

        uint256 primaryRecordLeverageBefore = primaryRecord.leverage;
        uint256 complementRecordLeverageBefore = complementRecord.leverage;

        uint256 leveragesMultiplied = _mul(
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore
        );

        primaryRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    _div(
                        _mul(leveragesMultiplied, _mul(complementRecord.balance, estPrice)),
                        primaryRecord.balance
                    )
                )
            )
        );
        complementRecord.leverage = _div(leveragesMultiplied, primaryRecord.leverage);
        emit Repriced(
            repricingBlock,
            primaryRecord.balance,
            complementRecord.balance,
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore,
            primaryRecord.leverage,
            complementRecord.leverage,
            estPricePrimary,
            estPriceComplement
        );
    }

    function getLeveragedBalance(Record memory r) public pure returns (uint256) {
        return _mul(r.balance, r.leverage);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     * This will revert due to insufficient balance or insufficient allowance.
     * This function returns the actual amount received,
     * which may be less than `amount` if there is a fee attached to the transfer.
     * @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     * See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _pullUnderlying(
        address _erc20,
        address _from,
        uint256 _amount
    ) internal virtual returns (uint256) {
        uint256 balanceBefore = IERC20(_erc20).balanceOf(address(this));
        controller.transferAssetToPool(IERC20Modified(_erc20), _from, _amount);

        bool success;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "VolmexPool: Token transfer failed");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(_erc20).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "VolmexPool: Token transfer overflow met");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function _getRepriced(address _tokenIn)
        private
        view
        returns (Record memory inRecord, Record memory outRecord)
    {
        Record memory primaryRecord = records[tokens[0]];
        Record memory complementRecord = records[tokens[1]];

        (, , uint256 estPrice) = repricer.reprice(volatilityIndex);

        uint256 primaryRecordLeverageBefore = primaryRecord.leverage;
        uint256 complementRecordLeverageBefore = complementRecord.leverage;

        uint256 leveragesMultiplied = _mul(
            primaryRecordLeverageBefore,
            complementRecordLeverageBefore
        );

        primaryRecord.leverage = uint256(
            repricer.sqrtWrapped(
                int256(
                    _div(
                        _mul(leveragesMultiplied, _mul(complementRecord.balance, estPrice)),
                        primaryRecord.balance
                    )
                )
            )
        );
        complementRecord.leverage = _div(leveragesMultiplied, primaryRecord.leverage);

        inRecord = tokens[0] == _tokenIn ? primaryRecord : complementRecord;
        outRecord = tokens[1] == _tokenIn ? primaryRecord : complementRecord;
    }

    function _calcFee(
        Record memory _inRecord,
        uint256 _tokenAmountIn,
        Record memory _outRecord,
        uint256 _tokenAmountOut,
        uint256 _feeAmp
    ) private view returns (uint256 fee) {
        int256 ifee;
        (ifee, ) = _calc(
            [int256(_inRecord.balance), int256(_inRecord.leverage), int256(_tokenAmountIn)],
            [int256(_outRecord.balance), int256(_outRecord.leverage), int256(_tokenAmountOut)],
            int256(baseFee),
            int256(_feeAmp),
            int256(maxFee)
        );
        require(ifee > 0, "VolmexPool: Fee should be greater than 0");
        fee = uint256(ifee);
    }

    /**
     * @notice Sets all type of fees
     *
     * @dev Checks the contract is finalised and caller is controller of the pool
     *
     * @param _baseFee Fee of the pool contract
     * @param _maxFee Max fee of the pool while swap
     * @param _feeAmpPrimary Fee on the primary token
     * @param _feeAmpComplement Fee on the complement token
     */
    function _setFeeParams(
        uint256 _baseFee,
        uint256 _maxFee,
        uint256 _feeAmpPrimary,
        uint256 _feeAmpComplement
    ) private logs lock onlyNotSettled {
        baseFee = _baseFee;
        maxFee = _maxFee;
        feeAmpPrimary = _feeAmpPrimary;
        feeAmpComplement = _feeAmpComplement;

        emit FeeParamsSet(_baseFee, _maxFee, _feeAmpPrimary, _feeAmpComplement);
    }

    function _performSwap(
        address _tokenIn,
        uint256 _tokenAmountIn,
        address _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _spotPriceBefore,
        uint256 _fee,
        address _receiver,
        bool _toController
    ) private returns (uint256 spotPriceAfter) {
        Record storage inRecord = records[_tokenIn];
        Record storage outRecord = records[_tokenOut];

        _requireBoundaryConditions(
            inRecord,
            _tokenAmountIn,
            outRecord,
            _tokenAmountOut,
            tokens[0] == _tokenIn ? exposureLimitPrimary : exposureLimitComplement
        );

        _updateLeverages(inRecord, _tokenAmountIn, outRecord, _tokenAmountOut);

        inRecord.balance = inRecord.balance + _tokenAmountIn;
        outRecord.balance = outRecord.balance - _tokenAmountOut;

        spotPriceAfter = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            0
        );

        // spotPriceAfter will remain larger, becasue after swap, the out token
        // balance will decrease. equation -> leverageBalance(_inToken) / leverageBalance(outToken)
        require(spotPriceAfter >= _spotPriceBefore, "VolmexPool: Amount max in ratio exploit");
        // _spotPriceBefore will remain smaller, because _tokenAmountOut will be smaller than _tokenAmountIn
        // because of the fee and oracle price.
        require(
            _spotPriceBefore <= _div(_tokenAmountIn, _tokenAmountOut),
            "VolmexPool: Amount in max in ratio exploit other"
        );

        emit Swapped(
            _tokenIn,
            _tokenOut,
            _tokenAmountIn,
            _tokenAmountOut,
            _fee,
            inRecord.balance,
            outRecord.balance,
            inRecord.leverage,
            outRecord.leverage
        );

        _pullUnderlying(_tokenIn, _receiver, _tokenAmountIn);
        _pushUnderlying(
            _tokenOut,
            _toController ? address(controller) : _receiver,
            _tokenAmountOut
        );
    }

    function _requireBoundaryConditions(
        Record storage _inToken,
        uint256 _tokenAmountIn,
        Record storage _outToken,
        uint256 _tokenAmountOut,
        uint256 _exposureLimit
    ) private view {
        require(
            getLeveragedBalance(_outToken) - _tokenAmountOut > qMin,
            "VolmexPool: Leverage boundary exploit"
        );
        require(
            _outToken.balance - _tokenAmountOut > qMin,
            "VolmexPool: Non leverage boundary exploit"
        );

        uint256 lowerBound = _div(pMin, upperBoundary - pMin);
        uint256 upperBound = _div(upperBoundary - pMin, pMin);
        uint256 value = _div(
            getLeveragedBalance(_inToken) + _tokenAmountIn,
            getLeveragedBalance(_outToken) - _tokenAmountOut
        );

        require(lowerBound < value, "VolmexPool: Lower boundary");
        require(value < upperBound, "VolmexPool: Upper boundary");

        (uint256 numerator, bool sign) = _subSign(
            _inToken.balance + _tokenAmountIn + _tokenAmountOut,
            _outToken.balance
        );

        if (!sign) {
            uint256 denominator = (_inToken.balance + _tokenAmountIn + _outToken.balance) -
                _tokenAmountOut;

            require(
                _div(numerator, denominator) < _exposureLimit,
                "VolmexPool: Exposure boundary"
            );
        }
    }

    function _updateLeverages(
        Record storage _inToken,
        uint256 _tokenAmountIn,
        Record storage _outToken,
        uint256 _tokenAmountOut
    ) private {
        _outToken.leverage = _div(
            getLeveragedBalance(_outToken) - _tokenAmountOut,
            _outToken.balance - _tokenAmountOut
        );
        require(_outToken.leverage > 0, "VolmexPool: Out token leverage can not be zero");

        _inToken.leverage = _div(
            getLeveragedBalance(_inToken) + _tokenAmountIn,
            _inToken.balance + _tokenAmountIn
        );
        require(_inToken.leverage > 0, "VolmexPool: In token leverage can not be zero");
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     * error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     * insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     * it is >= amount, this should not revert in normal conditions.
     * @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     * See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function _pushUnderlying(
        address _erc20,
        address _to,
        uint256 _amount
    ) private {
        IEIP20NonStandard(_erc20).transfer(_to, _amount);

        bool success;
        //solium-disable-next-line security/no-inline-assembly
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "VolmexPool: Token out transfer failed");
    }

    /**
     * @notice Used to bind the token, and its leverage and balance
     *
     * @dev This method will transfer the provided assets balance to pool from controller
     */
    function _bind(
        address _token,
        uint256 _balance,
        uint256 _leverage,
        address _receiver
    ) private {
        require(_balance >= qMin, "VolmexPool: Unsatisfied min balance supplied");
        require(_leverage > 0, "VolmexPool: Token leverage should be greater than 0");

        records[_token] = Record({ leverage: _leverage, balance: _balance });

        _pullUnderlying(_token, _receiver, _balance);
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `lock` or otherwise ensure reentry-safety

    function _pullPoolShare(address _from, uint256 _amount) private {
        _pull(_from, _amount);
    }

    function _pushPoolShare(address _to, uint256 _amount) private {
        _push(_to, _amount);
    }

    function _mintPoolShare(uint256 _amount) private {
        _mint(_amount);
    }

    function _burnPoolShare(uint256 _amount) private {
        _burn(_amount);
    }

    function _spow3(int256 _value) private pure returns (int256) {
        return (((_value * _value) / iBONE) * _value) / iBONE;
    }

    function _calcExpEndFee(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _expEnd
    ) private pure returns (int256) {
        int256 inBalanceLeveraged = _inRecord[0] * _inRecord[1];
        int256 tokenAmountIn1 = (inBalanceLeveraged * (_outRecord[0] - _inRecord[0])) /
            (inBalanceLeveraged + (_outRecord[0] * _outRecord[1]));

        int256 inBalanceLeveragedChanged = inBalanceLeveraged + _inRecord[2] * iBONE;
        int256 tokenAmountIn2 = (inBalanceLeveragedChanged *
            (_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2])) /
            (inBalanceLeveragedChanged + (_outRecord[0] * _outRecord[1]) - _outRecord[2] * iBONE);

        return
            (tokenAmountIn1 *
                _baseFee +
                tokenAmountIn2 *
                (_baseFee + (_feeAmp * ((_expEnd * _expEnd) / iBONE)) / 3)) /
            (tokenAmountIn1 + tokenAmountIn2);
    }

    function _calc(
        int256[3] memory _inRecord,
        int256[3] memory _outRecord,
        int256 _baseFee,
        int256 _feeAmp,
        int256 _maxFee
    ) private pure returns (int256 fee, int256 expStart) {
        expStart = _calcExpStart(_inRecord[0], _outRecord[0]);

        int256 _expEnd = ((_inRecord[0] - _outRecord[0] + _inRecord[2] + _outRecord[2]) * iBONE) /
            (_inRecord[0] + _outRecord[0] + _inRecord[2] - _outRecord[2]);

        if (expStart >= 0) {
            fee =
                _baseFee +
                (_feeAmp * (_spow3(_expEnd) - _spow3(expStart))) /
                (3 * (_expEnd - expStart));
        } else if (_expEnd <= 0) {
            fee = _baseFee;
        } else {
            fee = _calcExpEndFee(_inRecord, _outRecord, _baseFee, _feeAmp, _expEnd);
        }

        if (_maxFee < fee) {
            fee = _maxFee;
        }

        if (iBONE / 1000 > fee) {
            fee = iBONE / 1000;
        }
    }

    function _calcExpStart(int256 _inBalance, int256 _outBalance) private pure returns (int256) {
        return ((_inBalance - _outBalance) * iBONE) / (_inBalance + _outBalance);
    }

    uint256[10] private __gap;
}