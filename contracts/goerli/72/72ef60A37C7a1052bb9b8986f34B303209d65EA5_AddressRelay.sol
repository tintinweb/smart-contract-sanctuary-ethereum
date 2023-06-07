// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {OwnableUDS} from "./implementations/OwnableUDS.sol";
import {IAddressRelay, Implementation} from "./interfaces/IAddressRelay.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

/**
 * @author Created by HeyMint Launchpad https://join.heymint.xyz
 * @notice This contract contains the base logic for ERC-721A tokens deployed with HeyMint
 */
contract AddressRelay is IAddressRelay, OwnableUDS {
    mapping(bytes4 => address) public selectorToImplAddress;
    mapping(bytes4 => bool) public supportedInterfaces;
    bytes4[] selectors;
    address[] implAddresses;
    address public fallbackImplAddress;
    bool public relayFrozen;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // IERC165
        supportedInterfaces[0x7f5828d0] = true; // IERC173
        supportedInterfaces[0xd9b67a26] = true; // ERC-1155
        supportedInterfaces[0x0e89341c] = true; // ERC1155MetadataURI
        supportedInterfaces[0x2a55205a] = true; // IERC2981
    }

    /**
     * @notice Permanently freezes the relay so no more selectors can be added or removed
     */
    function freezeRelay() external onlyOwner {
        relayFrozen = true;
    }

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            selectorToImplAddress[selector] = _implAddress;
            selectors.push(selector);
        }
        bool implAddressExists = false;
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                implAddressExists = true;
                break;
            }
        }
        if (!implAddressExists) {
            implAddresses.push(_implAddress);
        }
    }

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            delete selectorToImplAddress[selector];
            for (uint256 j = 0; j < selectors.length; j++) {
                if (selectors[j] == selector) {
                    // this just sets the value to 0, but doesn't remove it from the array
                    delete selectors[j];
                    break;
                }
            }
        }
    }

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                // this just sets the value to 0, but doesn't remove it from the array
                delete implAddresses[i];
                break;
            }
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                delete selectorToImplAddress[selectors[i]];
                delete selectors[i];
            }
        }
    }

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        if (implAddress == address(0)) {
            implAddress = fallbackImplAddress;
        }
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns the implementation address for a given function selector. Throws an error if function does not exist.
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddressNoFallback(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory)
    {
        uint256 trueImplAddressCount = 0;
        uint256 implAddressesLength = implAddresses.length;
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] != address(0)) {
                trueImplAddressCount++;
            }
        }
        Implementation[] memory impls = new Implementation[](
            trueImplAddressCount
        );
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] == address(0)) {
                continue;
            }
            address implAddress = implAddresses[i];
            bytes4[] memory selectors_;
            uint256 selectorCount = 0;
            uint256 selectorsLength = selectors.length;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectorCount++;
                }
            }
            selectors_ = new bytes4[](selectorCount);
            uint256 selectorIndex = 0;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectors_[selectorIndex] = selectors[j];
                    selectorIndex++;
                }
            }
            impls[i] = Implementation(implAddress, selectors_);
        }
        return impls;
    }

    /**
     * @notice Return all the function selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory) {
        uint256 selectorCount = 0;
        uint256 selectorsLength = selectors.length;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorCount++;
            }
        }
        bytes4[] memory selectorArr = new bytes4[](selectorCount);
        uint256 selectorIndex = 0;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorArr[selectorIndex] = selectors[i];
                selectorIndex++;
            }
        }
        return selectorArr;
    }

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(
        address _fallbackAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        fallbackImplAddress = _fallbackAddress;
    }

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external onlyOwner {
        supportedInterfaces[_interfaceId] = _supported;
    }

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }
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
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- external ------------- */

    function owner() public view virtual returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct Implementation {
    address implAddress;
    bytes4[] selectors;
}

interface IAddressRelay {
    /**
     * @notice Returns the fallback implementation address
     */
    function fallbackImplAddress() external returns (address);

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external;

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external;

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(address _implAddress) external;

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address implAddress_);

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory impls_);

    /**
     * @notice Return all the fucntion selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory selectors_);

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(address _fallbackAddress) external;

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external;

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}