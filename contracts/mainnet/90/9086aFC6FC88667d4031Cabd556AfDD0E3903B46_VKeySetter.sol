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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Delegator
 * @author Railgun Contributors
 * @notice 'Owner' contract for all railgun contracts
 * delegates permissions to other contracts (voter, role)
 */
contract Delegator is Ownable {
  /*
  Mapping structure is calling address => contract => function signature
  0 is used as a wildcard, so permission for contract 0 is permission for
  any contract, and permission for function signature 0 is permission for
  any function.

  Comments below use * to signify wildcard and . notation to separate address/contract/function.

  caller.*.* allows caller to call any function on any contract
  caller.X.* allows caller to call any function on contract X
  caller.*.Y allows caller to call function Y on any contract
  */
  mapping(address => mapping(address => mapping(bytes4 => bool))) public permissions;

  event GrantPermission(
    address indexed caller,
    address indexed contractAddress,
    bytes4 indexed selector
  );
  event RevokePermission(
    address indexed caller,
    address indexed contractAddress,
    bytes4 indexed selector
  );

  /**
   * @notice Sets initial admin
   */
  constructor(address _admin) {
    Ownable.transferOwnership(_admin);
  }

  /**
   * @notice Sets permission bit
   * @dev See comment on permissions mapping for wildcard format
   * @param _caller - caller to set permissions for
   * @param _contract - contract to set permissions for
   * @param _selector - selector to set permissions for
   * @param _permission - permission bit to set
   */
  function setPermission(
    address _caller,
    address _contract,
    bytes4 _selector,
    bool _permission
  ) public onlyOwner {
    // If permission set is different to new permission then we execute, otherwise skip
    if (permissions[_caller][_contract][_selector] != _permission) {
      // Set permission bit
      permissions[_caller][_contract][_selector] = _permission;

      // Emit event
      if (_permission) {
        emit GrantPermission(_caller, _contract, _selector);
      } else {
        emit RevokePermission(_caller, _contract, _selector);
      }
    }
  }

  /**
   * @notice Checks if caller has permission to execute function
   * @param _caller - caller to check permissions for
   * @param _contract - contract to check
   * @param _selector - function signature to check
   * @return if caller has permission
   */
  function checkPermission(
    address _caller,
    address _contract,
    bytes4 _selector
  ) public view returns (bool) {
    /* 
    See comment on permissions mapping for structure
    Comments below use * to signify wildcard and . notation to separate contract/function
    */
    return (_caller == Ownable.owner() ||
      permissions[_caller][_contract][_selector] || // Owner always has global permissions
      permissions[_caller][_contract][0x0] || // Permission for function is given
      permissions[_caller][address(0)][_selector] || // Permission for _contract.* is given
      permissions[_caller][address(0)][0x0]); // Global permission is given
  }

  /**
   * @notice Calls function
   * @dev calls to functions on this contract are intercepted and run directly
   * this is so the voting contract doesn't need to have special cases for calling
   * functions other than this one.
   * @param _contract - contract to call
   * @param _data - calldata to pass to contract
   * @return success - whether call succeeded
   * @return returnData - return data from function call
   */
  function callContract(
    address _contract,
    bytes calldata _data,
    uint256 _value
  ) public returns (bool success, bytes memory returnData) {
    // Get selector
    bytes4 selector = bytes4(_data);

    // Intercept calls to this contract
    if (_contract == address(this)) {
      if (selector == this.setPermission.selector) {
        // Decode call data
        (address caller, address calledContract, bytes4 _permissionSelector, bool permission) = abi
          .decode(abi.encodePacked(_data[4:]), (address, address, bytes4, bool));

        // Call setPermission
        setPermission(caller, calledContract, _permissionSelector, permission);

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.transferOwnership.selector) {
        // Decode call data
        address newOwner = abi.decode(abi.encodePacked(_data[4:]), (address));

        // Call transferOwnership
        Ownable.transferOwnership(newOwner);

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.renounceOwnership.selector) {
        // Call renounceOwnership
        Ownable.renounceOwnership();

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else {
        // Return failed with empty ReturnData bytes
        bytes memory empty;
        return (false, empty);
      }
    }

    // Check permissions
    require(
      checkPermission(msg.sender, _contract, selector),
      "Delegator: Caller doesn't have permission"
    );

    // Call external contract and return
    // solhint-disable-next-line avoid-low-level-calls
    return _contract.call{ value: _value }(_data);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Delegator } from "./Delegator.sol";
import { Verifier, VerifyingKey } from "../logic/Verifier.sol";

/**
 * @title VKeySetter
 * @author Railgun Contributors
 * @notice
 */
contract VKeySetter is Ownable {
  Delegator public delegator;
  Verifier public verifier;

  // Lock adding new vKeys once this boolean is flipped
  enum VKeySetterState {
    SETTING,
    WAITING,
    COMMITTING
  }

  VKeySetterState public state;

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  // Owner can set vKeys in setting state
  // Owner can always change contract to waiting state
  // Governance is required to change state to committing state
  // Owner can only change contract to setting state when in committing state

  modifier onlySetting() {
    require(state == VKeySetterState.SETTING, "VKeySetter: Contract is not in setting state");
    _;
  }

  // modifier onlyWaiting() {
  //   require(state == VKeySetterState.WAITING, "VKeySetter: Contract is not in waiting state");
  //   _;
  // }

  modifier onlyCommitting() {
    require(state == VKeySetterState.COMMITTING, "VKeySetter: Contract is not in committing state");
    _;
  }

  modifier onlyDelegator() {
    require(msg.sender == address(delegator), "VKeySetter: Caller isn't governance");
    _;
  }

  /**
   * @notice Sets initial admin and delegator and verifier contract addresses
   */
  constructor(address _admin, Delegator _delegator, Verifier _verifier) {
    Ownable.transferOwnership(_admin);
    delegator = _delegator;
    verifier = _verifier;
  }

  /**
   * @notice Sets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   * @param _verifyingKey - verifyingKey to set
   */
  function setVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments,
    VerifyingKey calldata _verifyingKey
  ) public onlyOwner onlySetting {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function getVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) external view returns (VerifyingKey memory) {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Sets verification key
   * @param _nullifiers - array of nullifier values of keys
   * @param _commitments - array of commitment values of keys
   * @param _verifyingKey - array of keys
   */
  function batchSetVerificationKey(
    uint256[] calldata _nullifiers,
    uint256[] calldata _commitments,
    VerifyingKey[] calldata _verifyingKey
  ) external {
    for (uint256 i = 0; i < _nullifiers.length; i += 1) {
      setVerificationKey(_nullifiers[i], _commitments[i], _verifyingKey[i]);
    }
  }

  /**
   * @notice Commits verification keys to contract
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function commitVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) public onlyOwner onlyCommitting {
    // NOTE: The vkey configuration must EXACTLY match the desired vkey configuration on the verifier contract
    // Leaving a vkey empty on this contract can be used to delete a vkey on the verifier contract by setting
    // the values to 0

    delegator.callContract(
      address(verifier),
      abi.encodeWithSelector(
        Verifier.setVerificationKey.selector,
        _nullifiers,
        _commitments,
        verificationKeys[_nullifiers][_commitments]
      ),
      0
    );
  }

  /**
   * @notice Commits verification keys to contract as batch
   * @param _nullifiers - array of nullifier values of keys
   * @param _commitments - array of commitment values of keys
   */
  function batchCommitVerificationKey(
    uint256[] calldata _nullifiers,
    uint256[] calldata _commitments
  ) external {
    for (uint256 i = 0; i < _nullifiers.length; i += 1) {
      commitVerificationKey(_nullifiers[i], _commitments[i]);
    }
  }

  /**
   * @notice Set state to 'setting'
   */
  function stateToSetting() external onlyOwner onlyCommitting {
    state = VKeySetterState.SETTING;
  }

  /**
   * @notice Set state to 'waiting'
   */
  function stateToWaiting() external onlyOwner {
    state = VKeySetterState.WAITING;
  }

  /**
   * @notice Set state to 'committing'
   */
  function stateToCommitting() external onlyDelegator {
    state = VKeySetterState.COMMITTING;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
// Verification bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
// Use 0x000000000000000000000000000000000000dEaD as an alternative known burn address
// https://etherscan.io/address/0x000000000000000000000000000000000000dEaD
address constant VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

bytes32 constant ACCEPT_RAILGUN_RESPONSE = keccak256(abi.encodePacked("Accept Railgun Session"));

struct ShieldRequest {
  CommitmentPreimage preimage;
  ShieldCiphertext ciphertext;
}

enum TokenType {
  ERC20,
  ERC721,
  ERC1155
}

struct TokenData {
  TokenType tokenType;
  address tokenAddress;
  uint256 tokenSubID;
}

struct CommitmentCiphertext {
  bytes32[4] ciphertext; // Ciphertext order: IV & tag (16 bytes each), encodedMPK (senderMPK XOR receiverMPK), random & amount (16 bytes each), token
  bytes32 blindedSenderViewingKey;
  bytes32 blindedReceiverViewingKey;
  bytes annotationData; // Only for sender to decrypt
  bytes memo; // Added to note ciphertext for decryption
}

struct ShieldCiphertext {
  bytes32[3] encryptedBundle; // IV shared (16 bytes), tag (16 bytes), random (16 bytes), IV sender (16 bytes), receiver viewing public key (32 bytes)
  bytes32 shieldKey; // Public key to generate shared key from
}

enum UnshieldType {
  NONE,
  NORMAL,
  REDIRECT
}

struct BoundParams {
  uint16 treeNumber;
  uint72 minGasPrice; // Only for type 0 transactions
  UnshieldType unshield;
  uint64 chainID;
  address adaptContract;
  bytes32 adaptParams;
  // For unshields do not include an element in ciphertext array
  // Ciphertext array length = commitments - unshields
  CommitmentCiphertext[] commitmentCiphertext;
}

struct Transaction {
  SnarkProof proof;
  bytes32 merkleRoot;
  bytes32[] nullifiers;
  bytes32[] commitments;
  BoundParams boundParams;
  CommitmentPreimage unshieldPreimage;
}

struct CommitmentPreimage {
  bytes32 npk; // Poseidon(Poseidon(spending public key, nullifying key), random)
  TokenData token; // Token field
  uint120 value; // Note value
}

struct G1Point {
  uint256 x;
  uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
  uint256[2] x;
  uint256[2] y;
}

struct VerifyingKey {
  string artifactsIPFSHash;
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[] ic;
}

struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
  uint256 private constant PRIME_Q =
    21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 private constant PAIRING_INPUT_SIZE = 24;
  uint256 private constant PAIRING_INPUT_WIDTH = 768; // PAIRING_INPUT_SIZE * 32

  /**
   * @notice Computes the negation of point p
   * @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
   * @return result
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    if (p.x == 0 && p.y == 0) return G1Point(0, 0);

    // check for valid points y^2 = x^3 +3 % PRIME_Q
    uint256 rh = mulmod(p.x, p.x, PRIME_Q); //x^2
    rh = mulmod(rh, p.x, PRIME_Q); //x^3
    rh = addmod(rh, 3, PRIME_Q); //x^3 + 3
    uint256 lh = mulmod(p.y, p.y, PRIME_Q); //y^2
    require(lh == rh, "Snark: Invalid negation");

    return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
  }

  /**
   * @notice Adds 2 G1 points
   * @return result
   */
  function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    // Format inputs
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;

    // Setup output variables
    bool success;
    G1Point memory result;

    // Add points
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
    }

    // Check if operation succeeded
    require(success, "Snark: Add Failed");

    return result;
  }

  /**
   * @notice Scalar multiplies two G1 points p, s
   * @dev The product of a point on G1 and a scalar, i.e.
   * p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   * points p.
   * @return r - result
   */
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
    }

    // Check multiplication succeeded
    require(success, "Snark: Scalar Multiplication Failed");
  }

  /**
   * @notice Performs pairing check on points
   * @dev The result of computing the pairing check
   * e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   * For example,
   * pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   * @return if pairing check passed
   */
  function pairing(
    G1Point memory _a1,
    G2Point memory _a2,
    G1Point memory _b1,
    G2Point memory _b2,
    G1Point memory _c1,
    G2Point memory _c2,
    G1Point memory _d1,
    G2Point memory _d2
  ) internal view returns (bool) {
    uint256[PAIRING_INPUT_SIZE] memory input = [
      _a1.x,
      _a1.y,
      _a2.x[0],
      _a2.x[1],
      _a2.y[0],
      _a2.y[1],
      _b1.x,
      _b1.y,
      _b2.x[0],
      _b2.x[1],
      _b2.y[0],
      _b2.y[1],
      _c1.x,
      _c1.y,
      _c2.x[0],
      _c2.x[1],
      _c2.y[0],
      _c2.y[1],
      _d1.x,
      _d1.y,
      _d2.x[0],
      _d2.x[1],
      _d2.y[0],
      _d2.y[1]
    ];

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, input, PAIRING_INPUT_WIDTH, out, 0x20)
    }

    // Check if operation succeeded
    require(success, "Snark: Pairing Verification Failed");

    return out[0] != 0;
  }

  /**
   * @notice Verifies snark proof against proving key
   * @param _vk - Verification Key
   * @param _proof - snark proof
   * @param _inputs - inputs
   */
  function verify(
    VerifyingKey memory _vk,
    SnarkProof memory _proof,
    uint256[] memory _inputs
  ) internal view returns (bool) {
    // Compute the linear combination vkX
    G1Point memory vkX = G1Point(0, 0);

    // Loop through every input
    for (uint256 i = 0; i < _inputs.length; i += 1) {
      // Make sure inputs are less than SNARK_SCALAR_FIELD
      require(_inputs[i] < SNARK_SCALAR_FIELD, "Snark: Input > SNARK_SCALAR_FIELD");

      // Add to vkX point
      vkX = add(vkX, scalarMul(_vk.ic[i + 1], _inputs[i]));
    }

    // Compute final vkX point
    vkX = add(vkX, _vk.ic[0]);

    // Verify pairing and return
    return
      pairing(
        negate(_proof.a),
        _proof.b,
        _vk.alpha1,
        _vk.beta2,
        vkX,
        _vk.gamma2,
        _proof.c,
        _vk.delta2
      );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { VERIFICATION_BYPASS, SnarkProof, Transaction, BoundParams, VerifyingKey, SNARK_SCALAR_FIELD } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/**
 * @title Verifier
 * @author Railgun Contributors
 * @notice Verifies snark proof
 * @dev Functions in this contract statelessly verify proofs, nullifiers and adaptID should be checked in RailgunLogic.
 */
contract Verifier is OwnableUpgradeable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement __gap
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Verifying key set event
  event VerifyingKeySet(uint256 nullifiers, uint256 commitments, VerifyingKey verifyingKey);

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  /**
   * @notice Sets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   * @param _verifyingKey - verifyingKey to set
   */
  function setVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments,
    VerifyingKey calldata _verifyingKey
  ) public onlyOwner {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;

    emit VerifyingKeySet(_nullifiers, _commitments, _verifyingKey);
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitments out this verification key is for
   */
  function getVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) public view returns (VerifyingKey memory) {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Calculates hash of transaction bound params for snark verification
   * @param _boundParams - bound parameters
   * @return bound parameters hash
   */
  function hashBoundParams(BoundParams calldata _boundParams) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(_boundParams))) % SNARK_SCALAR_FIELD;
  }

  /**
   * @notice Verifies inputs against a verification key
   * @param _verifyingKey - verifying key to verify with
   * @param _proof - proof to verify
   * @param _inputs - input to verify
   * @return proof validity
   */
  function verifyProof(
    VerifyingKey memory _verifyingKey,
    SnarkProof calldata _proof,
    uint256[] memory _inputs
  ) public view returns (bool) {
    return Snark.verify(_verifyingKey, _proof, _inputs);
  }

  /**
   * @notice Verifies a transaction
   * @param _transaction to verify
   * @return transaction validity
   */
  function verify(Transaction calldata _transaction) public view returns (bool) {
    uint256 nullifiersLength = _transaction.nullifiers.length;
    uint256 commitmentsLength = _transaction.commitments.length;

    // Retrieve verification key
    VerifyingKey memory verifyingKey = verificationKeys[nullifiersLength][commitmentsLength];

    // Check if verifying key is set
    require(verifyingKey.alpha1.x != 0, "Verifier: Key not set");

    // Calculate inputs
    uint256[] memory inputs = new uint256[](2 + nullifiersLength + commitmentsLength);
    inputs[0] = uint256(_transaction.merkleRoot);

    // Hash bound parameters
    inputs[1] = hashBoundParams(_transaction.boundParams);

    // Loop through nullifiers and add to inputs
    for (uint256 i = 0; i < nullifiersLength; i += 1) {
      inputs[2 + i] = uint256(_transaction.nullifiers[i]);
    }

    // Loop through commitments and add to inputs
    for (uint256 i = 0; i < commitmentsLength; i += 1) {
      inputs[2 + nullifiersLength + i] = uint256(_transaction.commitments[i]);
    }

    // Verify snark proof
    bool validity = verifyProof(verifyingKey, _transaction.proof, inputs);

    // Always return true in gas estimation transaction
    // This is so relayer fees can be calculated without needing to compute a proof
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin == VERIFICATION_BYPASS) {
      return true;
    } else {
      return validity;
    }
  }

  uint256[49] private __gap;
}