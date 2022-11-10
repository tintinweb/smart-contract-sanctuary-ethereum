// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "./Interfaces/IHats.sol";

/// @notice Single owner authorization mixin using Hats Protocol
/// @dev Common logic across initializable and standard versions
/// @author Hats Protocol
abstract contract HatsOwnedCommon {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerHatUpdated(
        uint256 indexed ownerHat,
        address indexed hatsAddress
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    IHats internal HATS;
    uint256 public ownerHat;

    modifier onlyOwner() virtual {
        require(HATS.isWearerOfHat(msg.sender, ownerHat), "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwnerHat(uint256 _ownerHat, address _hatsContract)
        public
        virtual
        onlyOwner
    {
        uint256 changes;

        if (ownerHat != _ownerHat) {
            ownerHat = _ownerHat;
            // max of 2, so will never overflow
            unchecked {
                ++changes;
            }
        }

        IHats hats = IHats(_hatsContract);

        if (HATS != hats) {
            HATS = hats;
            // max of 2, so will never overflow
            unchecked {
                ++changes;
            }
        }

        require(changes > 0, "NO CHANGES");

        emit OwnerHatUpdated(_ownerHat, _hatsContract);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONs
    //////////////////////////////////////////////////////////////*/

    function getHatsContract() public view returns (address) {
        return address(HATS);
    }
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "./Interfaces/IHats.sol";
import "./HatsOwnedCommon.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Single owner authorization mixin using Hats Protocol
/// @dev For inheretence into contracts deployed as proxies. Forked from solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol).
/// @author Hats Protocol
abstract contract HatsOwnedInitializable is HatsOwnedCommon, Initializable {
    /*//////////////////////////////////////////////////////////////
                               INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function _HatsOwned_init(uint256 _ownerHat, address _hatsContract)
        internal
        onlyInitializing
    {
        ownerHat = _ownerHat;
        HATS = IHats(_hatsContract);

        emit OwnerHatUpdated(_ownerHat, _hatsContract);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

interface IHats {
    function hatSupply(uint256 _hatId) external view returns (uint32);

    function createHat(
        uint256 admin,
        string memory details, // encode as bytes32 ??
        uint32 maxSupply,
        address oracle,
        address conditions
    ) external returns (uint256 hatId);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool);

    function batchMintHats(uint256[] memory _hatIds, address[] memory _wearers)
        external
        returns (bool);

    function getHatStatus(uint256 hatId) external returns (bool);

    function setHatStatus(uint256 hatId, bool newStatus)
        external
        returns (bool);

    function getHatWearerStatus(uint256 hatId, address wearer)
        external
        returns (bool);

    function setHatWearerStatus(
        uint256 hatId,
        address wearer,
        bool revoke,
        bool wearerStanding
    ) external returns (bool);

    function renounceHat(uint256 _hatId) external;

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) external;

    function batchTransferHats(
        uint256[] memory _hatIds,
        address[] memory _froms,
        address[] memory _tos
    ) external;

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address oracle,
            address conditions,
            bool active
        );

    function isTopHat(uint256 _hatId) external pure returns (bool);

    function isWearerOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isAdminOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function getHatLevel(uint256 _hatId) external pure returns (uint8 level);

    function isActive(uint256 _hatId) external view returns (bool);

    function isInGoodStanding(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function balanceOf(address wearer, uint256 hatId)
        external
        view
        returns (uint256 balance);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "hats-auth/HatsOwnedInitializable.sol";
import "zodiac/guard/BaseGuard.sol";
import "zodiac/interfaces/IAvatar.sol";
import "@gnosis.pm/safe-contracts/contracts/common/StorageAccessible.sol";
import "./Interfaces/IGnosisSafe.sol";
// import "forge-std/Test.sol"; // remove after testing
import "@gnosis.pm/safe-contracts/contracts/common/SignatureDecoder.sol";

contract HatsSignerGate is BaseGuard, SignatureDecoder, HatsOwnedInitializable {
    // Cannot disable this guard
    error CannotDisableThisGuard(address guard);

    // Cannot disable protected modules
    error CannotDisableProtectedModules(address module);

    // Must wear the owner hat to make changes to this contract
    error NotOwnerHatWearer(address user);

    // Must wear the signer hat to become a signer
    error NotSignerHatWearer(address user);

    // Valid signers must wear the signer hat at time of execution
    error InvalidSigners();

    // This contract can only be set once as a zodiac guard on `safe`
    error GuardAlreadySet();

    // Can't remove a signer if they're still wearing the signer hat
    error StillWearsSignerHat(address signer);

    // This module will always be a signer on the Safe
    error NeedAtLeastTwoSigners();

    error MaxSignersReached();

    // Target threshold must be lower than maxSigners
    error InvalidTargetThreshold();

    // Min threshold cannot be higher than maxSigners or targetThreshold
    error InvalidMinThreshold();

    // Signers already owners on the safe don't need to claim
    error SignerAlreadyClaimed(address signer);

    error FailedExecChangeThreshold();
    error FailedExecAddSigner();
    error FailedExecRemoveSigner();

    // Cannot exec tx if safeOnwerCount < minThreshold
    error BelowMinThreshold(uint256 minThreshold, uint256 safeOwnerCount);

    event TargetThresholdSet(uint256 threshold);
    event MinThresholdSet(uint256 threshold);

    IGnosisSafe public safe;
    uint256 public signersHatId;
    uint256 public minThreshold;
    uint256 public targetThreshold;
    uint256 public maxSigners;
    uint256 public signerCount;

    string public version;

    uint256 guardEntries;

    address internal constant SENTINEL_OWNERS = address(0x1);

    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT =
        0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH =
        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    constructor() initializer {
        _HatsOwned_init(1, address(0x1));
    }

    function setUp(bytes memory initializeParams) public initializer {
        (
            uint256 _ownerHatId,
            uint256 _signersHatId,
            address _safe,
            address _hats,
            uint256 _minThreshold,
            uint256 _targetThreshold,
            uint256 _maxSigners,
            string memory _version
        ) = abi.decode(
                initializeParams,
                (
                    uint256,
                    uint256,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    string
                )
            );

        _HatsOwned_init(_ownerHatId, _hats);
        signersHatId = _signersHatId;
        maxSigners = _maxSigners;
        safe = IGnosisSafe(_safe);

        _setTargetThreshold(_targetThreshold);
        _setMinThreshold(_minThreshold);
        version = _version;

        signerCount = 0;
    }

    function setTargetThreshold(uint256 _targetThreshold) public onlyOwner {
        if (_targetThreshold != targetThreshold) {
            _setTargetThreshold(_targetThreshold);

            if (signerCount > 1) _setSafeThreshold(_targetThreshold);

            emit TargetThresholdSet(_targetThreshold);
        }
    }

    function _setTargetThreshold(uint256 _targetThreshold) internal {
        // (, uint32 maxSupply, , , , ) = HATS.viewHat(signersHatId);
        if (
            _targetThreshold > maxSigners
            // || _targetThreshold >= maxSupply
        ) revert InvalidTargetThreshold();

        targetThreshold = _targetThreshold;
    }

    function _setSafeThreshold(uint256 _targetThreshold) internal {
        uint256 newThreshold = _targetThreshold;
        uint256 signerCount_ = signerCount; // save an SLOAD

        // ensure that txs can't execute if fewer signers than target threshold
        if (signerCount_ <= _targetThreshold) {
            newThreshold = signerCount_;
        }
        if (newThreshold != safe.getThreshold()) {
            bytes memory data = abi.encodeWithSelector(
                IGnosisSafe.changeThreshold.selector,
                newThreshold
            );

            bool success = safe.execTransactionFromModule(
                address(safe), // to
                0, // value
                data, // data
                Enum.Operation.Call // operation
            );

            if (!success) {
                revert FailedExecChangeThreshold();
            }
        }
    }

    function setMinThreshold(uint256 _minThreshold) public onlyOwner {
        _setMinThreshold(_minThreshold);
        emit MinThresholdSet(_minThreshold);
    }

    function _setMinThreshold(uint256 _minThreshold) internal {
        if (_minThreshold > maxSigners || _minThreshold > targetThreshold) {
            revert InvalidMinThreshold();
        }

        minThreshold = _minThreshold;
    }

    /// @notice tallies the number of existing safe owners that wear the signer hat, sets signerCount to that value, and updates the safe threshold if necessary
    /// @dev does NOT remove invalid safe owners
    function reconcileSignerCount() public {
        address[] memory owners = safe.getOwners();
        uint256 validSignerCount = _countValidSigners(owners);

        // count the existing safe owners that wear the signer hat
        // for (uint256 i = 0; i < owners.length; ++i) {
        //     if (HATS.isWearerOfHat(owners[i], signersHatId)) ++validSignerCount;
        // }

        // update the signer count accordingly
        signerCount = validSignerCount;

        if (
            validSignerCount <= targetThreshold &&
            validSignerCount != safe.getThreshold()
        ) {
            bytes memory data = abi.encodeWithSelector(
                IGnosisSafe.changeThreshold.selector,
                validSignerCount
            );

            bool success = safe.execTransactionFromModule(
                address(safe), // to
                0, // value
                data, // data
                Enum.Operation.Call // operation
            );

            if (!success) {
                revert FailedExecChangeThreshold();
            }
        }
    }

    function _countValidSigners(address[] memory owners)
        internal
        returns (uint256 validSignerCount)
    {
        // count the existing safe owners that wear the signer hat
        for (uint256 i = 0; i < owners.length; ++i) {
            if (HATS.isWearerOfHat(owners[i], signersHatId)) ++validSignerCount;
        }
    }

    function claimSigner() public {
        if (signerCount == maxSigners) {
            revert MaxSignersReached();
        }

        address claimer = msg.sender;

        if (safe.isOwner(claimer)) {
            revert SignerAlreadyClaimed(claimer);
        }

        if (!HATS.isWearerOfHat(claimer, signersHatId)) {
            revert NotSignerHatWearer(claimer);
        }

        uint256 newSignerCount = signerCount;

        // otherwise, we add the claimer as a new owner on the safe and update the threshold accordingly
        uint256 currentThreshold = safe.getThreshold();
        uint256 newThreshold = currentThreshold;

        bytes memory addOwnerData;
        address[] memory owners = safe.getOwners();
        address thisAddress = address(this);

        // if the only owner is a non-signer (ie this module set as an owner on initialization), replace it with the claimer
        if (owners.length == 1 && owners[0] == thisAddress) {
            // prevOwner will always be the sentinel when owners.length == 1

            // set up the swapOwner call
            addOwnerData = abi.encodeWithSelector(
                IGnosisSafe.swapOwner.selector,
                SENTINEL_OWNERS, // prevOwner
                thisAddress, // oldOwner
                claimer // newOwner
            );
            ++newSignerCount;
        } else {
            // otherwise, add the claimer as a new owner
            ++newSignerCount;

            // ensure that txs can't execute if fewer signers than target threshold
            if (newSignerCount <= targetThreshold) {
                newThreshold = newSignerCount;
            }

            // set up the addOwner call
            addOwnerData = abi.encodeWithSelector(
                IGnosisSafe.addOwnerWithThreshold.selector,
                claimer,
                newThreshold
            );
        }

        // execute the call
        bool success = safe.execTransactionFromModule(
            address(safe), // to
            0, // value
            addOwnerData, // data
            Enum.Operation.Call // operation
        );

        if (!success) {
            revert FailedExecAddSigner();
        }

        // increment signer count
        signerCount = newSignerCount;
    }

    function removeSigner(address _signer) public {
        if (HATS.isWearerOfHat(_signer, signersHatId)) {
            revert StillWearsSignerHat(_signer);
        }

        bytes memory removeOwnerData;
        address[] memory owners = safe.getOwners();
        address thisAddress = address(this);
        address prevOwner;

        uint256 currentThreshold = safe.getThreshold();
        uint256 newThreshold = currentThreshold;
        uint256 newSignerCount;

        if (signerCount == 1) {
            prevOwner = findPrevOwner(owners, thisAddress);

            // make address(this) the only owner
            removeOwnerData = abi.encodeWithSelector(
                IGnosisSafe.swapOwner.selector,
                prevOwner, // prevOwner
                _signer, // oldOwner
                thisAddress // newOwner
            );
        } else {
            uint256 validSignerCount = _countValidSigners(owners);

            uint256 currentSignerCount = signerCount; // save an SLOAD

            if (validSignerCount == currentSignerCount) {
                newSignerCount = currentSignerCount;
            } else {
                --newSignerCount;
            }

            // ensure that txs can't execute if fewer signers than target threshold
            if (newSignerCount <= targetThreshold) {
                newThreshold = newSignerCount;
            }

            prevOwner = findPrevOwner(owners, _signer);

            removeOwnerData = abi.encodeWithSelector(
                IGnosisSafe.removeOwner.selector,
                prevOwner,
                _signer,
                newThreshold
            );

            // decrement signerCount
            signerCount = newSignerCount;
        }

        bool success = safe.execTransactionFromModule(
            address(safe), // to
            0, // value
            removeOwnerData, // data
            Enum.Operation.Call // operation
        );

        if (!success) {
            revert FailedExecRemoveSigner();
        }
    }

    // find the previous owner, ie the pointer to the owner we want to remove from the safe owners linked list
    function findPrevOwner(address[] memory _owners, address owner)
        internal
        pure
        returns (address)
    {
        address prevOwner = SENTINEL_OWNERS;

        for (uint256 i = 0; i < _owners.length; ++i) {
            if (_owners[i] == owner) {
                if (i == 0) break;
                prevOwner = _owners[i - 1];
            }
        }

        return prevOwner;
    }

    // solhint-disallow-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    // pre-flight check
    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external override {
        uint256 safeOwnerCount = safe.getOwners().length;

        if (safeOwnerCount < minThreshold) {
            revert BelowMinThreshold(minThreshold, safeOwnerCount);
        }

        // get the tx hash
        bytes32 txHash = safe.getTransactionHash( // Transaction info
            to,
            value,
            data,
            operation,
            safeTxGas,
            // Payment info
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            // Signature info
            // We subtract 1 since nonce was just incremented in the parent function call
            safe.nonce() - 1
        );

        uint256 validSigCount = countValidSignatures(
            txHash,
            signatures,
            signatures.length / 65
        );

        // revert if there aren't enough valid signatures
        if (validSigCount < safe.getThreshold()) {
            revert InvalidSigners();
        }

        ++guardEntries;
    }

    /// @notice from https://github.com/gnosis/zodiac-guard-mod/blob/988ebc7b71e352f121a0be5f6ae37e79e47a4541/contracts/ModGuard.sol#L86
    /// @dev Prevent avatar owners (eg Safe signers) to remove this contract as a guard or as a module
    // TODO check on safety changes to above
    function checkAfterExecution(bytes32, bool) external override {
        if (
            abi.decode(
                StorageAccessible(address(safe)).getStorageAt(
                    uint256(GUARD_STORAGE_SLOT),
                    1
                ),
                (address)
            ) != address(this)
        ) {
            revert CannotDisableThisGuard(address(this));
        }

        if (!IAvatar(address(safe)).isModuleEnabled(address(this))) {
            revert CannotDisableProtectedModules(address(this));
        }

        --guardEntries;
    }

    // modified from https://github.com/safe-global/safe-contracts/blob/c36bcab46578a442862d043e12a83fec41143dec/contracts/GnosisSafe.sol#L240
    function countValidSignatures(
        bytes32 dataHash,
        bytes memory signatures,
        uint256 sigCount
    ) public view returns (uint256 validSigCount) {
        // There cannot be an owner with address 0.
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;

        for (i = 0; i < sigCount; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            dataHash
                        )
                    ),
                    v - 4,
                    r,
                    s
                );
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            if (HATS.isWearerOfHat(currentOwner, signersHatId)) ++validSigCount;
        }
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.4;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGnosisSafe {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) external;

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) external;

    function changeThreshold(uint256 _threshold) external;

    function nonce() external returns (uint256);

    function getThreshold() external returns (uint256);

    function approvedHashes(address approver, bytes32 hash)
        external
        returns (uint256);

    function domainSeparator() external view returns (bytes32);

    function getOwners() external view returns (address[] memory);

    function setGuard(address guard) external;

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isOwner(address owner) external returns (bool);
}