// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Mintable ERC721 Extension
 *
 * @notice Defines mint capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface MintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns (bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

}

/**
 * @title Batch Mintable ERC721 Extension
 *
 * @notice Defines batch minting capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface BatchMintable {
	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Burnable ERC721 Extension
 *
 * @notice Defines burn capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Basil Gorin
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Identifiable Token
 *
 * @notice Marker interface for the smart contracts having TOKEN_UID public property,
 *      usually these are ERC20/ERC721/ERC1155 token smart contracts
 *
 * @dev TOKEN_UID is used as an enhancement to ERC165 and helps better identifying
 *      deployed smart contracts
 *
 * @author Basil Gorin
 */
interface IdentifiableToken {
	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 * @dev Example value: 0x0bcafe95bec2350659433fc61cb9c4fbe18719da00059d525154dfe0d6e8c8fd
	 */
	function TOKEN_UID() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/LandLib.sol";

/**
 * @title Land ERC721 Metadata
 *
 * @notice Defines metadata-related capabilities for LandERC721 token.
 *      This interface should be treated as a definition of what metadata is for LandERC721,
 *      and what operations are defined/allowed for it.
 *
 * @author Basil Gorin
 */
interface LandERC721Metadata {
	/**
	 * @notice Presents token metadata in a well readable form,
	 *      with the Internal Land Structure included, as a `PlotView` struct
	 *
	 * @notice Reconstructs the internal land structure of the plot based on the stored
	 *      Tier ID, Plot Size, Generator Version, and Seed
	 *
	 * @param _tokenId token ID to query metadata view for
	 * @return token metadata as a `PlotView` struct
	 */
	function viewMetadata(uint256 _tokenId) external view returns (LandLib.PlotView memory);

	/**
	 * @notice Presents token metadata "as is", without the Internal Land Structure included,
	 *      as a `PlotStore` struct;
	 *
	 * @notice Doesn't reconstruct the internal land structure of the plot, allowing to
	 *      access Generator Version, and Seed fields "as is"
	 *
	 * @param _tokenId token ID to query on-chain metadata for
	 * @return token metadata as a `PlotStore` struct
	 */
	function getMetadata(uint256 _tokenId) external view returns (LandLib.PlotStore memory);

	/**
	 * @notice Verifies if token has its metadata set on-chain; for the tokens
	 *      in existence metadata is immutable, it can be set once, and not updated
	 *
	 * @dev If `exists(_tokenId) && hasMetadata(_tokenId)` is true, `setMetadata`
	 *      for such a `_tokenId` will always throw
	 *
	 * @param _tokenId token ID to check metadata existence for
	 * @return true if token ID specified has metadata associated with it
	 */
	function hasMetadata(uint256 _tokenId) external view returns (bool);

	/**
	 * @dev Sets/updates token metadata on-chain; same metadata struct can be then
	 *      read back using `getMetadata()` function, or it can be converted to
	 *      `PlotView` using `viewMetadata()` function
	 *
	 * @dev The metadata supplied is validated to satisfy (regionId, x, y) uniqueness;
	 *      non-intersection of the sites coordinates within a plot is guaranteed by the
	 *      internal land structure generator algorithm embedded into the `viewMetadata()`
	 *
	 * @dev Metadata for non-existing tokens can be set and updated unlimited
	 *      amount of times without any restrictions (except the constraints above)
	 * @dev Metadata for an existing token can only be set, it cannot be updated
	 *      (`setMetadata` will throw if metadata already exists)
	 *
	 * @param _tokenId token ID to set/updated the metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function setMetadata(uint256 _tokenId, LandLib.PlotStore memory _plot) external;

	/**
	 * @dev Removes token metadata
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function removeMetadata(uint256 _tokenId) external;

	/**
	 * @dev Mints the token and assigns the metadata supplied
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Consider minting with `safeMint` (and setting metadata before),
	 *      for the "safe mint" like behavior
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint and set metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function mintWithMetadata(address _to, uint256 _tokenId, LandLib.PlotStore memory _plot) external;
}

/**
 * @title Land Descriptor
 *
 * @notice Auxiliary module which is dynamically injected into LandERC721 contract
 *      to override the default ERC721.tokenURI behaviour
 *
 * @notice This can be used, for example, to enable on-chain generation of the SVG
 *      image representation of the land plot, encoding it into base64 string, and
 *      using it instead of token URI pointing to some off-chain sotrage location
 *
 * @dev Can be dynamically injected into LandERC721 at any time, can be dynamically detached
 *      from the LandERC721 once attached (injected)
 *
 * @author Pedro Bergamini, Basil Gorin
 */
interface LandDescriptor {
	/**
	 * @notice Creates SVG image with the land plot metadata painted on it,
	 *      encodes the generated SVG into base64 URI string
	 *
	 * @param _tokenId token ID of the land plot to generate SVG for
	 */
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Pair Price Oracle, a.k.a. Pair Oracle
 *
 * @notice Generic interface used to consult on the Uniswap-like token pairs conversion prices;
 *      one pair oracle is used to consult on the exchange rate within a single token pair
 *
 * @notice See also: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle
 *
 * @author Basil Gorin
 */
interface PairOracle {
	/**
	 * @notice Updates the oracle with the price values if required, for example
	 *      the cumulative price at the start and end of a period, etc.
	 *
	 * @dev This function is part of the oracle maintenance flow
	 */
	function update() external;

	/**
	 * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
	 *      bought if the specified amount of token A to be sold
	 *
	 * @dev This function is part of the oracle usage flow
	 *
	 * @param token token A (token to sell) address
	 * @param amountIn amount of token A to sell
	 * @return amountOut amount of token B to be bought
	 */
	function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

/**
 * @title Price Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 *
 * @author Basil Gorin
 */
interface PriceOracleRegistry {
	/**
	 * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
	 *
	 * @param tokenA token A (token to sell) address
	 * @param tokenB token B (token to buy) address
	 * @return pairOracle pair price oracle address for A/B token pair
	 */
	function getPriceOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}

/**
 * @title Land Sale Price Oracle
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 *
 * @author Basil Gorin
 */
interface LandSalePriceOracle {
	/**
	 * @notice Powers the ETH/ILV Land token price conversion, used when
	 *      selling the land for sILV to determine how much sILV to accept
	 *      instead of the nominated ETH price
	 *
	 * @notice Note that sILV price is considered to be equal to ILV price
	 *
	 * @dev Implementation must guarantee not to return zero, absurdly small
	 *      or big values, it must guarantee the price is up to date with some
	 *      reasonable update interval threshold
	 *
	 * @param ethOut amount of ETH sale contract is expecting to get
	 * @return ilvIn amount of sILV sale contract should accept instead
	 */
	function ethToIlv(uint256 ethOut) external returns (uint256 ilvIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Land Library
 *
 * @notice A library defining data structures related to land plots (used in Land ERC721 token),
 *      and functions transforming these structures between view and internal (packed) representations,
 *      in both directions.
 *
 * @notice Due to some limitations Solidity has (ex.: allocating array of structures in storage),
 *      and due to the specific nature of internal land structure
 *      (landmark and resource sites data is deterministically derived from a pseudo random seed),
 *      it is convenient to separate data structures used to store metadata on-chain (store),
 *      and data structures used to present metadata via smart contract ABI (view)
 *
 * @notice Introduces helper functions to detect and deal with the resource site collisions
 *
 * @author Basil Gorin
 */
library LandLib {
	/**
	 * @title Resource Site View
	 *
	 * @notice Resource Site, bound to a coordinates (x, y) within the land plot
	 *
	 * @notice Resources can be of two major types, each type having three subtypes:
	 *      - Element (Carbon, Silicon, Hydrogen), or
	 *      - Fuel (Crypton, Hyperion, Solon)
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct Site {
		/**
		 * @dev Site type:
		 *        1) Carbon (element),
		 *        2) Silicon (element),
		 *        3) Hydrogen (element),
		 *        4) Crypton (fuel),
		 *        5) Hyperion (fuel),
		 *        6) Solon (fuel)
		 */
		uint8 typeId;

		/**
		 * @dev x-coordinate within a plot
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within a plot
		 */
		uint16 y;
	}

	/**
	 * @title Land Plot View
	 *
	 * @notice Land Plot, bound to a coordinates (x, y) within the region,
	 *      with a rarity defined by the tier ID, sites, and (optionally)
	 *      a landmark, positioned on the internal coordinate grid of the
	 *      specified size within a plot.
	 *
	 * @notice Land plot coordinates and rarity are predefined (stored off-chain).
	 *      Number of sites (and landmarks - 0/1) is defined by the land rarity.
	 *      Positions of sites, types of sites/landmark are randomized and determined
	 *      upon land plot creation.
	 *
	 * @dev View only structure, used in public API/ABI, not used in on-chain storage
	 */
	struct PlotView {
		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains,
		 *      matches the number of element sites in sites[] array
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains,
		 *      matches the number of fuel sites in sites[] array
		 */
		uint8 fuelSites;

		/**
		 * @dev Element/fuel sites within the plot
		 */
		Site[] sites;
	}

	/**
	 * @title Land Plot Store
	 *
	 * @notice Land Plot data structure as it is stored on-chain
	 *
	 * @notice Contains the data required to generate `PlotView` structure:
	 *      - regionId, x, y, tierId, size, landmarkTypeId, elementSites, and fuelSites are copied as is
	 *      - version and seed are used to derive array of sites (together with elementSites, and fuelSites)
	 *
	 * @dev On-chain optimized structure, has limited usage in public API/ABI
	 */
	struct PlotStore {
		/**
		 * @dev Generator Version, reserved for the future use in order to tweak the
		 *      behavior of the internal land structure algorithm
		 */
		uint8 version;

		/**
		 * @dev Region ID defines the region on the map in IZ:
		 *        1) Abyssal Basin
		 *        2) Brightland Steppes
		 *        3) Shardbluff Labyrinth
		 *        4) Crimson Waste
		 *        5) Halcyon Sea
		 *        6) Taiga Boreal
		 *        7) Crystal Shores
		 */
		uint8 regionId;

		/**
		 * @dev x-coordinate within the region
		 */
		uint16 x;

		/**
		 * @dev y-coordinate within the region
		 */
		uint16 y;

		/**
		 * @dev Tier ID defines land rarity and number of sites within the plot
		 */
		uint8 tierId;

		/**
		 * @dev Plot Size, limits the (x, y) coordinates for the sites
		 */
		uint16 size;

		/**
		 * @dev Landmark Type ID:
		 *        0) no Landmark
		 *        1) Carbon Landmark,
		 *        2) Silicon Landmark,
		 *        3) Hydrogen Landmark (Eternal Spring),
		 *        4) Crypton Landmark,
		 *        5) Hyperion Landmark,
		 *        6) Solon Landmark (Fallen Star),
		 *        7) Arena
		 *
		 * @dev Landmark is always positioned in the center of internal grid
		 */
		uint8 landmarkTypeId;

		/**
		 * @dev Number of Element Sites (Carbon, Silicon, or Hydrogen) this plot contains
		 */
		uint8 elementSites;

		/**
		 * @dev Number of Fuel Sites (Crypton, Hyperion, or Solon) this plot contains
		 */
		uint8 fuelSites;

		/**
		 * @dev Pseudo-random Seed to generate Internal Land Structure,
		 *      should be treated as already used to derive Landmark Type ID
		 */
		uint160 seed;
	}

	/**
	 * @dev Tightly packs `PlotStore` data struct into uint256 representation
	 *
	 * @param store `PlotStore` data struct to pack
	 * @return packed `PlotStore` data struct packed into uint256
	 */
	function pack(PlotStore memory store) internal pure returns (uint256 packed) {
		return uint256(store.version) << 248
			| uint248(store.regionId) << 240
			| uint240(store.x) << 224
			| uint224(store.y) << 208
			| uint208(store.tierId) << 200
			| uint200(store.size) << 184
			| uint184(store.landmarkTypeId) << 176
			| uint176(store.elementSites) << 168
			| uint168(store.fuelSites) << 160
			| uint160(store.seed);
	}

	/**
	 * @dev Unpacks `PlotStore` data struct from uint256 representation
	 *
	 * @param packed uint256 packed `PlotStore` data struct
	 * @return store unpacked `PlotStore` data struct
	 */
	function unpack(uint256 packed) internal pure returns (PlotStore memory store) {
		return PlotStore({
			version:        uint8(packed >> 248),
			regionId:       uint8(packed >> 240),
			x:              uint16(packed >> 224),
			y:              uint16(packed >> 208),
			tierId:         uint8(packed >> 200),
			size:           uint16(packed >> 184),
			landmarkTypeId: uint8(packed >> 176),
			elementSites:   uint8(packed >> 168),
			fuelSites:      uint8(packed >> 160),
			seed:           uint160(packed)
		});
	}

	/**
	 * @dev Expands `PlotStore` data struct into a `PlotView` view struct
	 *
	 * @dev Derives internal land structure (resource sites the plot has)
	 *      from Number of Element/Fuel Sites, Plot Size, and Seed;
	 *      Generator Version is not currently used
	 *
	 * @param store on-chain `PlotStore` data structure to expand
	 * @return `PlotView` view struct, expanded from the on-chain data
	 */
	function plotView(PlotStore memory store) internal pure returns (PlotView memory) {
		// copy most of the fields as is, derive resource sites array inline
		return PlotView({
			regionId:       store.regionId,
			x:              store.x,
			y:              store.y,
			tierId:         store.tierId,
			size:           store.size,
			landmarkTypeId: store.landmarkTypeId,
			elementSites:   store.elementSites,
			fuelSites:      store.fuelSites,
			// derive the resource sites from Number of Element/Fuel Sites, Plot Size, and Seed
			sites:          getResourceSites(store.seed, store.elementSites, store.fuelSites, store.size, 2)
		});
	}

	/**
	 * @dev Based on the random seed, tier ID, and plot size, determines the
	 *      internal land structure (resource sites the plot has)
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the internal structure
	 * @param elementSites number of element sites plot has
	 * @param fuelSites number of fuel sites plot has
	 * @param gridSize plot size `N` of the land plot to derive internal structure for
	 * @param siteSize implied size `n` of the resource sites
	 * @return sites randomized array of resource sites
	 */
	function getResourceSites(
		uint256 seed,
		uint8 elementSites,
		uint8 fuelSites,
		uint16 gridSize,
		uint8 siteSize
	) internal pure returns (Site[] memory sites) {
		// derive the total number of sites
		uint8 totalSites = elementSites + fuelSites;

		// denote the grid (plot) size `N`
		// denote the resource site size `n`

		// transform coordinate system (1): normalization (x, y) => (x / n, y / n)
		// if `N` is odd this cuts off border coordinates x = N - 1, y = N - 1
		uint16 normalizedSize = gridSize / siteSize;

		// after normalization (1) is applied, isomorphic grid becomes effectively larger
		// due to borders capturing effect, for example if N = 4, and n = 2:
		//      | .. |                                              |....|
		// grid |....| becomes |..| normalized which is effectively |....|
		//      |....|         |..|                                 |....|
		//      | .. |                                              |....|
		// transform coordinate system (2): cut the borders, and reduce grid size to be multiple of 2
		// if `N/2` is odd this cuts off border coordinates x = N/2 - 1, y = N/2 - 1
		normalizedSize = (normalizedSize - 2) / 2 * 2;

		// define coordinate system: an isomorphic grid on a square of size [size, size]
		// transform coordinate system (3): pack an isomorphic grid on a rectangle of size [size, 1 + size / 2]
		// transform coordinate system (4): (x, y) -> y * size + x (two-dimensional Cartesian -> one-dimensional segment)
		// define temporary array to determine sites' coordinates
		uint16[] memory coords;
		// generate site coordinates in a transformed coordinate system (on a one-dimensional segment)
		// cut off four elements in the end of the segment to reserve space in the center for a landmark
		(seed, coords) = getCoords(seed, totalSites, normalizedSize * (1 + normalizedSize / 2) - 4);

		// allocate number of sites required
		sites = new Site[](totalSites);

		// define the variables used inside the loop outside the loop to help compiler optimizations
		// site type ID is de facto uint8, we're using uint16 for convenience with `nextRndUint16`
		uint16 typeId;
		// site coordinates (x, y)
		uint16 x;
		uint16 y;

		// determine the element and fuel sites one by one
		for(uint8 i = 0; i < totalSites; i++) {
			// determine next random number in the sequence, and random site type from it
			(seed, typeId) = nextRndUint16(seed, i < elementSites? 1: 4, 3);

			// determine x and y
			// reverse transform coordinate system (4): x = size % i, y = size / i
			// (back from one-dimensional segment to two-dimensional Cartesian)
			x = coords[i] % normalizedSize;
			y = coords[i] / normalizedSize;

			// reverse transform coordinate system (3): unpack isomorphic grid onto a square of size [size, size]
			// fix the "(0, 0) left-bottom corner" of the isomorphic grid
			if(2 * (1 + x + y) < normalizedSize) {
				x += normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}
			// fix the "(size, 0) right-bottom corner" of the isomorphic grid
			else if(2 * x > normalizedSize && 2 * x > 2 * y + normalizedSize) {
				x -= normalizedSize / 2;
				y += 1 + normalizedSize / 2;
			}

			// move the site from the center (four positions near the center) to a free spot
			if(x >= normalizedSize / 2 - 1 && x <= normalizedSize / 2
			&& y >= normalizedSize / 2 - 1 && y <= normalizedSize / 2) {
				// `x` is aligned over the free space in the end of the segment
				// x += normalizedSize / 2 + 2 * (normalizedSize / 2 - x) + 2 * (normalizedSize / 2 - y) - 4;
				x += 5 * normalizedSize / 2 - 2 * (x + y) - 4;
				// `y` is fixed over the free space in the end of the segment
				y = normalizedSize / 2;
			}

			// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
			// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
			uint16 offset = gridSize / siteSize % 2 + gridSize % siteSize;

			// based on the determined site type and coordinates, allocate the site
			sites[i] = Site({
				typeId: uint8(typeId),
				// reverse transform coordinate system (2): recover borders (x, y) => (x + 1, y + 1)
				// if `N/2` is odd recover previously cut off border coordinates x = N/2 - 1, y = N/2 - 1
				// reverse transform coordinate system (1): (x, y) => (n * x, n * y), where n is site size
				// if `N` is odd recover previously cut off border coordinates x = N - 1, y = N - 1
				x: (1 + x) * siteSize + offset,
				y: (1 + y) * siteSize + offset
			});
		}

		// return the result
		return sites;
	}

	/**
	 * @dev Based on the random seed and tier ID determines the landmark type of the plot.
	 *      Random seed is consumed for tiers 3 and 4 to randomly determine one of three
	 *      possible landmark types.
	 *      Tier 5 has its landmark type predefined (arena), lower tiers don't have a landmark.
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @param seed random seed to consume and derive the landmark type based on
	 * @param tierId tier ID of the land plot
	 * @return landmarkTypeId landmark type defined by its ID
	 */
	function getLandmark(uint256 seed, uint8 tierId) internal pure returns (uint8 landmarkTypeId) {
		// depending on the tier, land plot can have a landmark
		// tier 3 has an element landmark (1, 2, 3)
		if(tierId == 3) {
			// derive random element landmark
			return uint8(1 + seed % 3);
		}
		// tier 4 has a fuel landmark (4, 5, 6)
		if(tierId == 4) {
			// derive random fuel landmark
			return uint8(4 + seed % 3);
		}
		// tier 5 has an arena landmark
		if(tierId == 5) {
			// 7 - arena landmark
			return 7;
		}

		// lower tiers (0, 1, 2) don't have any landmark
		// tiers greater than 5 are not defined
		return 0;
	}

	/**
	 * @dev Derives an array of integers with no duplicates from the random seed;
	 *      each element in the array is within [0, size) bounds and represents
	 *      a two-dimensional Cartesian coordinate point (x, y) presented as one-dimensional
	 *
	 * @dev Function works in a deterministic way and derives the same data
	 *      for the same inputs; the term "random" in comments means "pseudo-random"
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive coordinates from
	 * @param length number of elements to generate
	 * @param size defines array element bounds [0, size)
	 * @return nextSeed next pseudo-random "used" seed
	 * @return coords the resulting array of length `n` with random non-repeating elements
	 *      in [0, size) range
	 */
	function getCoords(
		uint256 seed,
		uint8 length,
		uint16 size
	) internal pure returns (uint256 nextSeed, uint16[] memory coords) {
		// allocate temporary array to store (and determine) sites' coordinates
		coords = new uint16[](length);

		// generate site coordinates one by one
		for(uint8 i = 0; i < coords.length; i++) {
			// get next number and update the seed
			(seed, coords[i]) = nextRndUint16(seed, 0, size);
		}

		// sort the coordinates
		sort(coords);

		// find the if there are any duplicates, and while there are any
		for(int256 i = findDup(coords); i >= 0; i = findDup(coords)) {
			// regenerate the element at duplicate position found
			(seed, coords[uint256(i)]) = nextRndUint16(seed, 0, size);
			// sort the coordinates again
			// TODO: check if this doesn't degrade the performance significantly (note the pivot in quick sort)
			sort(coords);
		}

		// shuffle the array to compensate for the sorting made before
		seed = shuffle(seed, coords);

		// return the updated used seed, and generated coordinates
		return (seed, coords);
	}

	/**
	 * @dev Based on the random seed, generates next random seed, and a random value
	 *      not lower than given `offset` value and able to have `options` different
	 *      possible values
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param offset the minimum possible output
	 * @param options number of different possible values to output
	 * @return nextSeed next pseudo-random "used" seed
	 * @return rndVal random value in the [offset, offset + options) range
	 */
	function nextRndUint16(
		uint256 seed,
		uint16 offset,
		uint16 options
	) internal pure returns (
		uint256 nextSeed,
		uint16 rndVal
	) {
		// generate next random seed first
		nextSeed = uint256(keccak256(abi.encodePacked(seed)));

		// derive random value with the desired properties from
		// the newly generated seed
		rndVal = offset + uint16(nextSeed % options);

		// return the result as tuple
		return (nextSeed, rndVal);
	}

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotView` view structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
/*
	function loc(PlotView memory plot) internal pure returns (uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}
*/

	/**
	 * @dev Plot location is a combination of (regionId, x, y), it's effectively
	 *      a 3-dimensional coordinate, unique for each plot
	 *
	 * @dev The function extracts plot location from the plot and represents it
	 *      in a packed form of 3 integers constituting the location: regionId | x | y
	 *
	 * @param plot `PlotStore` data store structure to extract location from
	 * @return Plot location (regionId, x, y) as a packed integer
	 */
	function loc(PlotStore memory plot) internal pure returns (uint40) {
		// tightly pack the location data and return
		return uint40(plot.regionId) << 32 | uint32(plot.y) << 16 | plot.x;
	}

	/**
	 * @dev Site location is a combination of (x, y), unique for each site within a plot
	 *
	 * @dev The function extracts site location from the site and represents it
	 *      in a packed form of 2 integers constituting the location: x | y
	 *
	 * @param site `Site` view structure to extract location from
	 * @return Site location (x, y) as a packed integer
	 */
/*
	function loc(Site memory site) internal pure returns (uint32) {
		// tightly pack the location data and return
		return uint32(site.y) << 16 | site.x;
	}
*/

	/**
	 * @dev Finds first pair of repeating elements in the array
	 *
	 * @dev Assumes the array is sorted ascending:
	 *      returns `-1` if array is strictly monotonically increasing,
	 *      index of the first duplicate found otherwise
	 *
	 * @param arr an array of elements to check
	 * @return index found duplicate index, or `-1` if there are no repeating elements
	 */
	function findDup(uint16[] memory arr) internal pure returns (int256 index) {
		// iterate over the array [1, n], leaving the space in the beginning for pair comparison
		for(uint256 i = 1; i < arr.length; i++) {
			// verify if there is a strict monotonically increase violation
			if(arr[i - 1] >= arr[i]) {
				// return its index if yes
				return int256(i - 1);
			}
		}

		// return `-1` if no violation was found - array is strictly monotonically increasing
		return -1;
	}

	/**
	 * @dev Shuffles an array if integers by making random permutations
	 *      in the amount equal to the array size
	 *
	 * @dev The input seed is considered to be already used to derive some random value
	 *      from it, therefore the function derives a new one by hashing the previous one
	 *      before generating the random value; the output seed is "used" - output random
	 *      value is derived from it
	 *
	 * @param seed random seed to consume and derive next random value from
	 * @param arr an array to shuffle
	 * @return nextSeed next pseudo-random "used" seed
	 */
	function shuffle(uint256 seed, uint16[] memory arr) internal pure returns(uint256 nextSeed) {
		// define index `j` to permute with loop index `i` outside the loop to help compiler optimizations
		uint16 j;

		// iterate over the array one single time
		for(uint16 i = 0; i < arr.length; i++) {
			// determine random index `j` to swap with the loop index `i`
			(seed, j) = nextRndUint16(seed, 0, uint16(arr.length));

			// do the swap
			(arr[i], arr[j]) = (arr[j], arr[i]);
		}

		// return the updated used seed
		return seed;
	}

	/**
	 * @dev Sorts an array of integers using quick sort algorithm
	 *
	 * @dev Quick sort recursive implementation
	 *      Source:   https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      See also: https://www.geeksforgeeks.org/quick-sort/
	 *
	 * @param arr an array to sort
	 */
	function sort(uint16[] memory arr) internal pure {
		quickSort(arr, 0, int256(arr.length) - 1);
	}

	/**
	 * @dev Quick sort recursive implementation
	 *      Source:     https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
	 *      Discussion: https://blog.cotten.io/thinking-in-solidity-6670c06390a9
	 *      See also:   https://www.geeksforgeeks.org/quick-sort/
	 */
	// TODO: review the implementation code
	function quickSort(uint16[] memory arr, int256 left, int256 right) private pure {
		int256 i = left;
		int256 j = right;
		if(i >= j) {
			return;
		}
		uint16 pivot = arr[uint256(left + (right - left) / 2)];
		while(i <= j) {
			while(arr[uint256(i)] < pivot) {
				i++;
			}
			while(pivot < arr[uint256(j)]) {
				j--;
			}
			if(i <= j) {
				(arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
				i++;
				j--;
			}
		}
		if(left < j) {
			quickSort(arr, left, j);
		}
		if(i < right) {
			quickSort(arr, i, right);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../interfaces/ERC721SpecExt.sol";
import "../interfaces/LandERC721Spec.sol";
import "../interfaces/IdentifiableSpec.sol";
import "../interfaces/PriceOracleSpec.sol";
import "../lib/LandLib.sol";
import "../utils/UpgradeableAccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Land Sale
 *
 * @notice Enables the Land NFT sale via dutch auction mechanism
 *
 * @notice The proposed volume of land is approximately 100,000 plots, split amongst the 7 regions.
 *      The volume is released over a series of staggered sales with the first sale featuring
 *      about 20,000 land plots (tokens).
 *
 * @notice Land plots are sold in sequences, each sequence groups tokens which are sold in parallel.
 *      Sequences start selling one by one with the configurable time interval between their start.
 *      A sequence is available for a sale for a fixed (configurable) amount of time, meaning they
 *      can overlap (tokens from several sequences are available on sale simultaneously) if this
 *      amount of time is bigger than interval between sequences start.
 *
 * @notice The sale operates in a configurable time interval which should be aligned with the
 *      total number of sequences, their duration, and start interval.
 *      Sale smart contract has no idea of the total number of sequences and doesn't validate
 *      if these timings are correctly aligned.
 *
 * @notice Starting prices of the plots are defined by the plot tier in ETH, and are configurable
 *      within the sale contract per tier ID.
 *      Token price declines over time exponentially, price halving time is configurable.
 *      The exponential price decline simulates the price drop requirement which may be formulates
 *      something like "the price drops by 'x' % every 'y' minutes".
 *      For example, if x = 2, and y = 1, "the price drops by 2% every minute", the halving
 *      time is around 34 minutes.
 *
 * @notice Sale accepts ETH and sILV as a payment currency, sILV price is supplied by on-chain
 *      price oracle (sILV price is assumed to be equal to ILV price)
 *
 * @notice The data required to mint a plot includes (see `PlotData` struct):
 *      - token ID, defines a unique ID for the land plot used as ERC721 token ID
 *      - sequence ID, defines the time frame when the plot is available for sale
 *      - region ID (1 - 7), determines which tileset to use in game,
 *      - coordinates (x, y) on the overall world map, indicating which grid position the land sits in,
 *      - tier ID (1 - 5), the rarity of the land, tier is used to create the list of sites,
 *      - size (w, h), defines an internal coordinate system within a plot,
 *
 * @notice Since minting a plot requires at least 32 bytes of data and due to a significant
 *      amount of plots to be minted (about 100,000), pre-storing this data on-chain
 *      is not a viable option (2,000,000,000 of gas only to pay for the storage).
 *      Instead, we represent the whole land plot data collection on sale as a Merkle tree
 *      structure and store the root of the Merkle tree on-chain.
 *      To buy a particular plot, the buyer must know the entire collection and be able to
 *      generate and present the Merkle proof for this particular plot.
 *
 * @notice The input data is a collection of `PlotData` structures; the Merkle tree is built out
 *      from this collection, and the tree root is stored on the contract by the data manager.
 *      When buying a plot, the buyer also specifies the Merkle proof for a plot data to mint.
 *
 * @notice Layer 2 support (ex. IMX minting)
 *      Sale contract supports both L1 and L2 sales.
 *      L1 sale mints the token in layer 1 network (Ethereum mainnet) immediately,
 *      in the same transaction it is bought.
 *      L2 sale doesn't mint the token and just emits an event containing token metadata and owner;
 *      this event is then picked by the off-chain process (daemon) which mints the token in a
 *      layer 2 network (IMX, https://www.immutable.com/)
 *
 * @dev A note on randomness
 *      Current implementation uses "on-chain randomness" to mint a land plot, which is calculated
 *      as a keccak256 hash of some available parameters, like token ID, buyer address, and block
 *      timestamp.
 *      This can be relatively easy manipulated not only by miners, but even by clients wrapping
 *      their transactions into the smart contract code when buying (calling a `buy` function).
 *      It is considered normal and acceptable from the security point of view since the value
 *      of such manipulation is low compared to the transaction cost.
 *      This situation can change, however, in the future sales when more information on the game
 *      is available, and when it becomes more clear how resource types and their positions
 *      affect the game mechanics, and can be used to benefit players.
 *
 * @dev A note on timestamps
 *      Current implementation uses uint32 to represent unix timestamp, and time intervals,
 *      it is not designed to be used after February 7, 2106, 06:28:15 GMT (unix time 0xFFFFFFFF)
 *
 * @dev Merkle proof verification is based on OpenZeppelin implementation, see
 *      https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
 *
 * @author Basil Gorin
 */
contract LandSale is UpgradeableAccessControl {
	// Use Zeppelin MerkleProof Library to verify Merkle proofs
	using MerkleProof for bytes32[];
	// Use Land Library to pack `PlotStore` struct to uint256
	using LandLib for LandLib.PlotStore;

	/**
	 * @title Plot Data, a.k.a. Sale Data
	 *
	 * @notice Data structure modeling the data entry required to mint a single plot.
	 *      The contract is initialized with the Merkle root of the plots collection Merkle tree.
	 * @dev When buying a plot this data structure must be supplied together with the
	 *      Merkle proof allowing to verify the plot data belongs to the original collection.
	 */
	struct PlotData {
		/// @dev Token ID, defines a unique ID for the land plot used as ERC721 token ID
		uint32 tokenId;
		/// @dev Sequence ID, defines the time frame when the plot is available for sale
		uint32 sequenceId;
		/// @dev Region ID defines the region on the map in IZ
		uint8 regionId;
		/// @dev x-coordinate within the region plot
		uint16 x;
		/// @dev y-coordinate within the region plot
		uint16 y;
		/// @dev Tier ID defines land rarity and number of sites within the plot
		uint8 tierId;
		/// @dev Plot size, limits the (x, y) coordinates for the sites
		uint16 size;
	}

	/**
	 * @notice Deployed LandERC721 token address to mint tokens of
	 *      (when they are bought via the sale)
	 */
	address public targetNftContract;

	/**
	 * @notice Deployed sILV (Escrowed Illuvium) ERC20 token address,
	 *      accepted as a payment option alongside ETH
	 * @dev Note: sILV ERC20 implementation never returns "false" on transfers,
	 *      it throws instead; we don't use any additional libraries like SafeERC20
	 *      to transfer sILV therefore
	 */
	address public sIlvContract;

	/**
	 * @notice Land Sale Price Oracle is used to convert the token prices from USD
	 *      to ETH or sILV (ILV)
	 */
	address public priceOracle;

	/**
	 * @notice Input data root, Merkle tree root for the collection of plot data elements,
	 *      available on sale
	 *
	 * @notice Merkle root effectively "compresses" the (potentially) huge collection of elements
	 *      and allows to store it in a single 256-bits storage slot on-chain
	 */
	bytes32 public root;

	/**
	 * @dev Sale start unix timestamp, scheduled sale start, the time when the sale
	 *      is scheduled to start, this is the time when sale activates,
	 *      the time when the first sequence sale starts, that is
	 *      when tokens of the first sequence become available on sale
	 * @dev The sale is active after the start (inclusive)
	 */
	uint32 public saleStart;

	/**
	 * @dev Sale end unix timestamp, this is the time when sale deactivates,
	 *      and tokens of the last sequence become unavailable
	 * @dev The sale is active before the end (exclusive)
	 */
	uint32 public saleEnd;

	/**
	 * @dev Price halving time, the time required for a token price to reduce to the
	 *      half of its initial value
	 * @dev Defined in seconds
	 */
	uint32 public halvingTime;

	/**
	 * @dev Time flow quantum, price update interval, used by the price calculation algorithm,
	 *      the time is rounded down to be multiple of quantum when performing price calculations;
	 *      setting this value to one effectively disables its effect;
	 * @dev Defined in seconds
	 */
	uint32 public timeFlowQuantum;

	/**
	 * @dev Sequence duration, time limit of how long a token / sequence can be available
	 *      for sale, first sequence stops selling at `saleStart + seqDuration`, second
	 *      sequence stops selling at `saleStart + seqOffset + seqDuration`, and so on
	 * @dev Defined in seconds
	 */
	uint32 public seqDuration;

	/**
	 * @dev Sequence start offset, first sequence starts selling at `saleStart`,
	 *      second sequence starts at `saleStart + seqOffset`, third at
	 *      `saleStart + 2 * seqOffset` and so on at `saleStart + n * seqOffset`,
	 *      where `n` is zero-based sequence ID
	 * @dev Defined in seconds
	 */
	uint32 public seqOffset;

	/**
	 * @dev Sale paused unix timestamp, the time when sale was paused,
	 *     non-zero value indicates that the sale is currently in a paused state
	 *     and is not operational
	 *
	 * @dev Pausing a sale effectively pauses "own time" of the sale, this is achieved
	 *     by tracking cumulative sale pause duration (see `pauseDuration`) and taking it
	 *     into account when evaluating current sale time, prices, sequences on sale, etc.
	 *
	 * @dev Erased (set to zero) when sale start time is modified (see initialization, `initialize()`)
	 */
	uint32 public pausedAt;

	/**
	 * @dev Cumulative sale pause duration, total amount of time sale stayed in a paused state
	 *      since the last time sale start time was set (see initialization, `initialize()`)
	 *
	 * @dev Is increased only when sale is resumed back from the paused state, is not updated
	 *      when the sale is in a paused state
	 *
	 * @dev Defined in seconds
	 */
	uint32 public pauseDuration;

	/**
	 * @dev Tier start prices, starting token price for each (zero based) Tier ID,
	 *      defined in ETH, can be converted into sILV via Uniswap/Sushiswap price oracle,
	 *      sILV price is defined to be equal to ILV price
	 */
	uint96[] public startPrices;

	/**
	 * @dev Sale beneficiary address, if set - used to send funds obtained from the sale;
	 *      If not set - contract accumulates the funds on its own deployed address
	 */
	address payable public beneficiary;

	/**
	 * @dev A bitmap of minted tokens, required to support L2 sales:
	 *      when token is not minted in L1 we still need to track it was sold using this bitmap
	 *
	 * @dev Bitmap is stored as an array of uint256 data slots, each slot holding
	 *     256 bits of the entire bitmap.
	 *     An array itself is stored as a mapping with a zero-index integer key.
	 *     Each mapping entry represents the state of 256 tokens (each bit corresponds to a
	 *     single token)
	 *
	 * @dev For a token ID `n`,
	 *      the data slot index `i` is `n / 256`,
	 *      and bit index within a slot `j` is `n % 256`
	 */
	mapping(uint256 => uint256) public mintedTokens;

	/**
	 * @notice Enables the L1 sale, buying tokens in L1 public function
	 *
	 * @notice Note: sale could be activated/deactivated by either sale manager, or
	 *      data manager, since these roles control sale params, and items on sale;
	 *      However both sale and data managers require some advanced knowledge about
	 *      the use of the functions they trigger, while switching the "sale active"
	 *      flag is very simple and can be done much more easier
	 *
	 * @dev Feature FEATURE_L1_SALE_ACTIVE must be enabled in order for
	 *      `buyL1()` function to be able to succeed
	 */
	uint32 public constant FEATURE_L1_SALE_ACTIVE = 0x0000_0001;

	/**
	 * @notice Enables the L2 sale, buying tokens in L2 public function
	 *
	 * @notice Note: sale could be activated/deactivated by either sale manager, or
	 *      data manager, since these roles control sale params, and items on sale;
	 *      However both sale and data managers require some advanced knowledge about
	 *      the use of the functions they trigger, while switching the "sale active"
	 *      flag is very simple and can be done much more easier
	 *
	 * @dev Feature FEATURE_L2_SALE_ACTIVE must be enabled in order for
	 *      `buyL2()` function to be able to succeed
	 */
	uint32 public constant FEATURE_L2_SALE_ACTIVE = 0x0000_0002;

	/**
	 * @notice Pause manager is responsible for:
	 *      - sale pausing (pausing/resuming the sale in case of emergency)
	 *
	 * @dev Role ROLE_PAUSE_MANAGER allows sale pausing/resuming via pause() / resume()
	 */
	uint32 public constant ROLE_PAUSE_MANAGER = 0x0001_0000;

	/**
	 * @notice Data manager is responsible for supplying the valid input plot data collection
	 *      Merkle root which then can be used to mint tokens, meaning effectively,
	 *      that data manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_DATA_MANAGER allows setting the Merkle tree root via setInputDataRoot()
	 */
	uint32 public constant ROLE_DATA_MANAGER = 0x0002_0000;

	/**
	 * @notice Sale manager is responsible for:
	 *      - sale initialization (setting up sale timing/pricing parameters)
	 *
	 * @dev Role ROLE_SALE_MANAGER allows sale initialization via initialize()
	 */
	uint32 public constant ROLE_SALE_MANAGER = 0x0004_0000;

	/**
	 * @notice People do mistake and may send ERC20 tokens by mistake; since
	 *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
	 *      sent to the smart contract, except the sILV which is a payment token
	 *      and can be withdrawn by the withdrawal manager only
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
	 *      on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

	/**
	 * @notice Withdrawal manager is responsible for withdrawing funds obtained in sale
	 *      from the sale smart contract via pull/push mechanisms:
	 *      1) Pull: no pre-setup is required, withdrawal manager executes the
	 *         withdraw function periodically to withdraw funds
	 *      2) Push: withdrawal manager sets the `beneficiary` address which is used
	 *         by the smart contract to send funds to when users purchase land NFTs
	 *
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows to set the `beneficiary` address via
	 *      - setBeneficiary()
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows pull withdrawals of funds:
	 *      - withdraw()
	 *      - withdrawTo()
	 */
	uint32 public constant ROLE_WITHDRAWAL_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setInputDataRoot()
	 *
	 * @param _by an address which executed the operation
	 * @param _root new Merkle root value
	 */
	event RootChanged(address indexed _by, bytes32 _root);

	/**
	 * @dev Fired in initialize()
	 *
	 * @param _by an address which executed the operation
	 * @param _saleStart sale start unix timestamp, and first sequence start time
	 * @param _saleEnd sale end unix timestamp, should match with the last sequence end time
	 * @param _halvingTime price halving time (seconds), the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum (seconds), price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration (seconds), time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset (seconds), each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices (wei), starting token price for each (zero based) Tier ID
	 */
	event Initialized(
		address indexed _by,
		uint32 _saleStart,
		uint32 _saleEnd,
		uint32 _halvingTime,
		uint32 _timeFlowQuantum,
		uint32 _seqDuration,
		uint32 _seqOffset,
		uint96[] _startPrices
	);

	/**
	 * @dev Fired in pause()
	 *
	 * @param _by an address which executed the operation
	 * @param _pausedAt when the sale was paused (unix timestamp)
	 */
	event Paused(address indexed _by, uint32 _pausedAt);

	/**
	 * @dev Fired in resume(), optionally in initialize() (only if sale start is changed)
	 *
	 * @param _by an address which executed the operation
	 * @param _pausedAt when the sale was paused (unix timestamp)
	 * @param _resumedAt when the sale was resumed (unix timestamp)
	 * @param _pauseDuration cumulative sale pause duration (seconds)
	 */
	event Resumed(address indexed _by, uint32 _pausedAt, uint32 _resumedAt, uint32 _pauseDuration);

	/**
	 * @dev Fired in setBeneficiary
	 *
	 * @param _by an address which executed the operation
	 * @param _beneficiary new beneficiary address or zero-address
	 */
	event BeneficiaryUpdated(address indexed _by, address indexed _beneficiary);

	/**
	 * @dev Fired in withdraw() and withdrawTo()
	 *
	 * @param _by an address which executed the operation
	 * @param _to an address which received the funds withdrawn
	 * @param _eth amount of ETH withdrawn (wei)
	 * @param _sIlv amount of sILV withdrawn (wei)
	 */
	event Withdrawn(address indexed _by, address indexed _to, uint256 _eth, uint256 _sIlv);

	/**
	 * @dev Fired in buyL1()
	 *
	 * @param _by an address which had bought the plot
	 * @param _tokenId Token ID, part of the off-chain plot metadata supplied externally
	 * @param _sequenceId Sequence ID, part of the off-chain plot metadata supplied externally
	 * @param _plot on-chain plot metadata minted token, contains values copied from off-chain
	 *      plot metadata supplied externally, and generated values such as seed
	 * @param _eth ETH price of the lot (wei, non-zero)
	 * @param _sIlv sILV price of the lot (wei, zero if paid in ETH)
	 */
	event PlotBoughtL1(
		address indexed _by,
		uint32 indexed _tokenId,
		uint32 indexed _sequenceId,
		LandLib.PlotStore _plot,
		uint256 _eth,
		uint256 _sIlv
	);

	/**
	 * @dev Fired in buyL2()
	 *
	 * @param _by an address which had bought the plot
	 * @param _tokenId Token ID, part of the off-chain plot metadata supplied externally
	 * @param _sequenceId Sequence ID, part of the off-chain plot metadata supplied externally
	 * @param _plot on-chain plot metadata minted token, contains values copied from off-chain
	 *      plot metadata supplied externally, and generated values such as seed
	 * @param _eth ETH price of the lot (wei, non-zero)
	 * @param _sIlv sILV price of the lot (wei, zero if paid in ETH)
	 */
	event PlotBoughtL2(
		address indexed _by,
		uint32 indexed _tokenId,
		uint32 indexed _sequenceId,
		LandLib.PlotStore _plot,
		uint256 _plotPacked,
		uint256 _eth,
		uint256 _sIlv
	);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @dev Binds the sale smart contract instance to
	 *      1) the target NFT smart contract address to be used to mint tokens (Land ERC721),
	 *      2) sILV (Escrowed Illuvium) contract address to be used as one of the payment options
	 *      3) Price Oracle contract address to be used to determine ETH/sILV price
	 *
	 * @param _nft target NFT smart contract address
	 * @param _sIlv sILV (Escrowed Illuvium) contract address
	 * @param _oracle price oracle contract address
	 */
	function postConstruct(address _nft, address _sIlv, address _oracle) public virtual initializer {
		// verify the inputs are set
		require(_nft != address(0), "target contract is not set");
		require(_sIlv != address(0), "sILV contract is not set");
		require(_oracle != address(0), "oracle address is not set");

		// verify the inputs are valid smart contracts of the expected interfaces
		require(
			ERC165(_nft).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_nft).supportsInterface(type(MintableERC721).interfaceId)
			&& ERC165(_nft).supportsInterface(type(LandERC721Metadata).interfaceId),
			// note: ImmutableMintableERC721 is not required by the sale
			"unexpected target type"
		);
		require(ERC165(_oracle).supportsInterface(type(LandSalePriceOracle).interfaceId), "unexpected oracle type");
		// for the sILV ERC165 check is unavailable, but we can check some ERC20 functions manually
		require(ERC20(_sIlv).balanceOf(address(this)) < type(uint256).max);
		require(ERC20(_sIlv).transfer(address(0x1), 0) && ERC20(_sIlv).transferFrom(address(this), address(0x1), 0));

		// assign the addresses
		targetNftContract = _nft;
		sIlvContract = _sIlv;
		priceOracle = _oracle;

		// execute all parent initializers in cascade
		UpgradeableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @dev `startPrices` getter; the getters solidity creates for arrays
	 *      may be inconvenient to use if we need an entire array to be read
	 *
	 * @return `startPrices` as is - as an array of uint96
	 */
	function getStartPrices() public view virtual returns (uint96[] memory) {
		// read `startPrices` array into memory and return
		return startPrices;
	}

	/**
	 * @notice Restricted access function to update input data root (Merkle tree root),
	 *       and to define, effectively, the tokens to be created by this smart contract
	 *
	 * @dev Requires executor to have `ROLE_DATA_MANAGER` permission
	 *
	 * @param _root Merkle tree root for the input plot data collection
	 */
	function setInputDataRoot(bytes32 _root) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_DATA_MANAGER), "access denied");

		// update input data Merkle tree root
		root = _root;

		// emit an event
		emit RootChanged(msg.sender, _root);
	}

	/**
	 * @notice Verifies the validity of a plot supplied (namely, if it's registered for the sale)
	 *      based on the Merkle root of the plot data collection (already defined on the contract),
	 *      and the Merkle proof supplied to validate the particular plot data
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to verify
	 * @param proof Merkle proof for the plot data supplied
	 * @return true if plot is valid (belongs to registered collection), false otherwise
	 */
	function isPlotValid(PlotData memory plotData, bytes32[] memory proof) public view virtual returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(
				plotData.tokenId,
				plotData.sequenceId,
				plotData.regionId,
				plotData.x,
				plotData.y,
				plotData.tierId,
				plotData.size
			));

		// verify the proof supplied, and return the verification result
		return proof.verify(root, leaf);
	}

	/**
	 * @dev Restricted access function to set up sale parameters, all at once,
	 *      or any subset of them
	 *
	 * @dev To skip parameter initialization, set it to `-1`,
	 *      that is a maximum value for unsigned integer of the corresponding type;
	 *      for `_startPrices` use a single array element with the `-1` value to skip
	 *
	 * @dev Example: following initialization will update only `_seqDuration` and `_seqOffset`,
	 *      leaving the rest of the fields unchanged
	 *      initialize(
	 *          0xFFFFFFFF, // `_saleStart` unchanged
	 *          0xFFFFFFFF, // `_saleEnd` unchanged
	 *          0xFFFFFFFF, // `_halvingTime` unchanged
	 *          21600,      // `_seqDuration` updated to 6 hours
	 *          3600,       // `_seqOffset` updated to 1 hour
	 *          [0xFFFFFFFFFFFFFFFFFFFFFFFF] // `_startPrices` unchanged
	 *      )
	 *
	 * @dev Sale start and end times should match with the number of sequences,
	 *      sequence duration and offset, if `n` is number of sequences, then
	 *      the following equation must hold:
	 *         `saleStart + (n - 1) * seqOffset + seqDuration = saleEnd`
	 *      Note: `n` is unknown to the sale contract and there is no way for it
	 *      to accurately validate other parameters of the equation above
	 *
	 * @dev Input params are not validated; to get an idea if these params look valid,
	 *      refer to `isActive() `function, and it's logic
	 *
	 * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
	 *
	 * @param _saleStart sale start unix timestamp, and first sequence start time
	 * @param _saleEnd sale end unix timestamp, should match with the last sequence end time
	 * @param _halvingTime price halving time (seconds), the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum (seconds), price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration (seconds), time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset (seconds), each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices (wei), starting token price for each (zero based) Tier ID
	 */
	function initialize(
		uint32 _saleStart,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleEnd,             // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _halvingTime,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _timeFlowQuantum,     // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqDuration,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqOffset,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint96[] memory _startPrices // <<<--- keep type in sync with the body type(uint96).max !!!
	) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_SALE_MANAGER), "access denied");

		// Note: no input validation at this stage, initial params state is invalid anyway,
		//       and we're not limiting sale manager to set these params back to this state

		// set/update sale parameters (allowing partial update)
		// 0xFFFFFFFF, 32 bits
		if(_saleStart != type(uint32).max) {
			// update the sale start itself, and
			saleStart = _saleStart;

			// erase the cumulative pause duration
			pauseDuration = 0;

			// if the sale is in paused state (non-zero `pausedAt`)
			if(pausedAt != 0) {
				// emit an event first - to log old `pausedAt` value
				emit Resumed(msg.sender, pausedAt, now32(), 0);

				// erase `pausedAt`, effectively resuming the sale
				pausedAt = 0;
			}
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleEnd != type(uint32).max) {
			saleEnd = _saleEnd;
		}
		// 0xFFFFFFFF, 32 bits
		if(_halvingTime != type(uint32).max) {
			halvingTime = _halvingTime;
		}
		// 0xFFFFFFFF, 32 bits
		if(_timeFlowQuantum != type(uint32).max) {
			timeFlowQuantum = _timeFlowQuantum;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqDuration != type(uint32).max) {
			seqDuration = _seqDuration;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqOffset != type(uint32).max) {
			seqOffset = _seqOffset;
		}
		// 0xFFFFFFFFFFFFFFFFFFFFFFFF, 96 bits
		if(_startPrices.length != 1 || _startPrices[0] != type(uint96).max) {
			startPrices = _startPrices;
		}

		// emit an event
		emit Initialized(msg.sender, saleStart, saleEnd, halvingTime, timeFlowQuantum, seqDuration, seqOffset, startPrices);
	}

	/**
	 * @notice Verifies if sale is in the active state, meaning that it is properly
	 *      initialized with the sale start/end times, sequence params, etc., and
	 *      that the current time is within the sale start/end bounds
	 *
	 * @notice Doesn't check if the plot data Merkle root `root` is set or not;
	 *      active sale state doesn't guarantee that an item can be actually bought
	 *
	 * @dev The sale is defined as active if all of the below conditions hold:
	 *      - sale start is now or in the past
	 *      - sale end is in the future
	 *      - halving time is not zero
	 *      - sequence duration is not zero
	 *      - there is at least one starting price set (zero price is valid)
	 *
	 * @return true if sale is active, false otherwise
	 */
	function isActive() public view virtual returns (bool) {
		// calculate sale state based on the internal sale params state and return
		return pausedAt == 0
			&& saleStart <= ownTime()
			&& ownTime() < saleEnd
			&& halvingTime > 0
			&& timeFlowQuantum > 0
			&& seqDuration > 0
			&& startPrices.length > 0;
	}

	/**
	 * @dev Restricted access function to pause running sale in case of emergency
	 *
	 * @dev Pausing/resuming doesn't affect sale "own time" and allows to resume the
	 *      sale process without "loosing" any items due to the time passed when paused
	 *
	 * @dev The sale is resumed using `resume()` function
	 *
	 * @dev Requires transaction sender to have `ROLE_PAUSE_MANAGER` role
	 */
	function pause() public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_PAUSE_MANAGER), "access denied");

		// check if sale is not in the paused state already
		require(pausedAt == 0, "already paused");

		// do the pause, save the paused timestamp
		// note for tests: never set time to zero in tests
		pausedAt = now32();

		// emit an event
		emit Paused(msg.sender, now32());
	}

	/**
	 * @dev Restricted access function to resume previously paused sale
	 *
	 * @dev Pausing/resuming doesn't affect sale "own time" and allows to resume the
	 *      sale process without "loosing" any items due to the time passed when paused
	 *
	 * @dev Resuming the sale before it is scheduled to start doesn't have any effect
	 *      on the sale flow, and doesn't delay the sale start
	 *
	 * @dev Resuming the sale which was paused before the scheduled start delays the sale,
	 *      and moves scheduled sale start by the amount of time it was paused after the
	 *      original scheduled start
	 *
	 * @dev The sale is paused using `pause()` function
	 *
	 * @dev Requires transaction sender to have `ROLE_PAUSE_MANAGER` role
	 */
	function resume() public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_PAUSE_MANAGER), "access denied");

		// check if the sale is in a paused state
		require(pausedAt != 0, "already running");

		// if sale has already started
		if(now32() > saleStart) {
			// update the cumulative sale pause duration, taking into account that
			// if sale was paused before its planned start, pause duration counts only from the start
			// note: we deliberately subtract `pausedAt` from the current time first
			// to fail fast if `pausedAt` is bigger than current time (this can never happen by design)
			pauseDuration += now32() - (pausedAt < saleStart? saleStart: pausedAt);
		}

		// emit an event first - to log old `pausedAt` value
		emit Resumed(msg.sender, pausedAt, now32(), pauseDuration);

		// do the resume, erase the paused timestamp
		pausedAt = 0;
	}

	/**
	 * @dev Restricted access function to update the sale beneficiary address, the address
	 *      can be set, updated, or "unset" (deleted, set to zero)
	 *
	 * @dev Setting the address to non-zero value effectively activates funds withdrawal
	 *      mechanism via the push pattern
	 *
	 * @dev Setting the address to zero value effectively deactivates funds withdrawal
	 *      mechanism via the push pattern (pull mechanism can be used instead)
	 */
	function setBeneficiary(address payable _beneficiary) public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// update the beneficiary address
		beneficiary = _beneficiary;

		// emit an event
		emit BeneficiaryUpdated(msg.sender, _beneficiary);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds back to transaction sender
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdraw(bool _ethOnly) public virtual {
		// delegate to `withdrawTo`
		withdrawTo(payable(msg.sender), _ethOnly);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds to the address specified
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _to an address to send funds to
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdrawTo(address payable _to, bool _ethOnly) public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// verify withdrawal address is set
		require(_to != address(0), "recipient not set");

		// ETH value to send
		uint256 ethBalance = address(this).balance;

		// sILV value to send
		uint256 sIlvBalance = _ethOnly? 0: ERC20(sIlvContract).balanceOf(address(this));

		// verify there is a balance to send
		require(ethBalance > 0 || sIlvBalance > 0, "zero balance");

		// if there is ETH to send
		if(ethBalance > 0) {
			// send the entire balance to the address specified
			_to.transfer(ethBalance);
		}

		// if there is sILV to send
		if(sIlvBalance > 0) {
			// send the entire balance to the address specified
			ERC20(sIlvContract).transfer(_to, sIlvBalance);
		}

		// emit en event
		emit Withdrawn(msg.sender, _to, ethBalance, sIlvBalance);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Doesn't allow to rescue sILV tokens, use withdraw/withdrawTo instead
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// verify rescue manager is not trying to withdraw sILV:
		// we have a withdrawal manager to help with that
		require(_contract != sIlvContract, "sILV access denied");

		// perform the transfer as requested, without any checks
		require(ERC20(_contract).transfer(_to, _value), "ERC20 transfer failed");
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, now (block.timestamp)
	 *
	 * @dev Adjusts current time for the sale pause duration `pauseDuration`, using
	 *      own time `ownTime()`
	 *
	 * @dev Throws if `now` is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 * @return current price of the token specified
	 */
	function tokenPriceNow(uint32 sequenceId, uint16 tierId) public view virtual returns (uint256) {
		// delegate to `tokenPriceAt` using adjusted current time as `t`
		return tokenPriceAt(sequenceId, tierId, ownTime());
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, at a given time `t` (own time)
	 *
	 * @dev Throws if `t` is outside the [saleStart, saleEnd) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 * @param t unix timestamp of interest, time to evaluate the price at (own time)
	 * @return price of the token specified at some unix timestamp `t` (own time)
	 */
	function tokenPriceAt(uint32 sequenceId, uint16 tierId, uint32 t) public view virtual returns (uint256) {
		// calculate sequence sale start
		uint32 seqStart = saleStart + sequenceId * seqOffset;
		// calculate sequence sale end
		uint32 seqEnd = seqStart + seqDuration;

		// verify `t` is in a reasonable bounds [saleStart, saleEnd)
		require(saleStart <= t && t < saleEnd, "invalid time");

		// ensure `t` is in `[seqStart, seqEnd)` bounds; no price exists outside the bounds
		require(seqStart <= t && t < seqEnd, "invalid sequence");

		// verify the initial price is set (initialized) for the tier specified
		require(startPrices.length > tierId, "invalid tier");

		// convert `t` from "absolute" to "relative" (within a sequence)
		t -= seqStart;

		// apply the time flow quantum: make `t` multiple of quantum
		t /= timeFlowQuantum;
		t *= timeFlowQuantum;

		// calculate the price based on the derived params - delegate to `price`
		return price(startPrices[tierId], halvingTime, t);
	}

	/**
	 * @dev Calculates dutch auction price after the time of interest has passed since
	 *      the auction has started
	 *
	 * @dev The price is assumed to drop exponentially, according to formula:
	 *      p(t) = p0 * 2^(-t/t0)
	 *      The price halves every t0 seconds passed from the start of the auction
	 *
	 * @dev Calculates with the precision p0 * 2^(-1/256), meaning the price updates
	 *      every t0 / 256 seconds
	 *      For example, if halving time is one hour, the price updates every 14 seconds
	 *
	 * @param p0 initial price (wei)
	 * @param t0 price halving time (seconds)
	 * @param t elapsed time (seconds)
	 * @return price after `t` seconds passed, `p = p0 * 2^(-t/t0)`
	 */
	function price(uint256 p0, uint256 t0, uint256 t) public pure virtual returns (uint256) {
		// perform very rough price estimation first by halving
		// the price as many times as many t0 intervals have passed
		uint256 p = p0 >> t / t0;

		// if price halves (decreases by 2 times) every t0 seconds passed,
		// than every t0 / 2 seconds passed it decreases by sqrt(2) times (2 ^ (1/2)),
		// every t0 / 2 seconds passed it decreases 2 ^ (1/4) times, and so on

		// we've prepared a small cheat sheet here with the pre-calculated values for
		// the roots of the degree of two 2 ^ (1 / 2 ^ n)
		// for the resulting function to be monotonically decreasing, it is required
		// that (2 ^ (1 / 2 ^ n)) ^ 2 <= 2 ^ (1 / 2 ^ (n - 1))
		// to emulate floating point values, we present them as nominator/denominator
		// roots of the degree of two nominators:
		uint56[8] memory sqrNominator = [
			1_414213562373095, // 2 ^ (1/2)
			1_189207115002721, // 2 ^ (1/4)
			1_090507732665257, // 2 ^ (1/8) *
			1_044273782427413, // 2 ^ (1/16) *
			1_021897148654116, // 2 ^ (1/32) *
			1_010889286051700, // 2 ^ (1/64)
			1_005429901112802, // 2 ^ (1/128) *
			1_002711275050202  // 2 ^ (1/256)
		];
		// roots of the degree of two denominator:
		uint56 sqrDenominator =
			1_000000000000000;

		// perform up to 8 iterations to increase the precision of the calculation
		// dividing the halving time `t0` by two on every step
		for(uint8 i = 0; i < sqrNominator.length && t > 0 && t0 > 1; i++) {
			// determine the reminder of `t` which requires the precision increase
			t %= t0;
			// halve the `t0` for the next iteration step
			t0 /= 2;
			// if elapsed time `t` is big enough and is "visible" with `t0` precision
			if(t >= t0) {
				// decrease the price accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
			// if elapsed time `t` is big enough and is "visible" with `2 * t0` precision
			// (this is possible sometimes due to rounding errors when halving `t0`)
			if(t >= 2 * t0) {
				// decrease the price again accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
		}

		// return the result
		return p;
	}

	/**
	 * @notice Sells a plot of land (Land ERC721 token) from the sale to executor.
	 *      Executor must supply the metadata for the land plot and a Merkle tree proof
	 *      for the metadata supplied.
	 *
	 * @notice Mints the token bought immediately on L1 as part of the buy transaction
	 *
	 * @notice Metadata for all the plots is stored off-chain and is publicly available
	 *      to buy plots and to generate Merkle proofs
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev Requires FEATURE_L1_SALE_ACTIVE feature to be enabled
	 *
	 * @dev Throws if current time is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to buy
	 * @param proof Merkle proof for the plot data supplied
	 */
	function buyL1(PlotData memory plotData, bytes32[] memory proof) public virtual payable {
		// verify L1 sale is active
		require(isFeatureEnabled(FEATURE_L1_SALE_ACTIVE), "L1 sale disabled");

		// execute all the validations, process payment, construct the land plot
		(LandLib.PlotStore memory plot, uint256 pEth, uint256 pIlv) = _buy(plotData, proof);

		// mint the token in L1 with metadata - delegate to `mintWithMetadata`
		LandERC721Metadata(targetNftContract).mintWithMetadata(msg.sender, plotData.tokenId, plot);

		// emit an event
		emit PlotBoughtL1(msg.sender, plotData.tokenId, plotData.sequenceId, plot, pEth, pIlv);
	}

	/**
	 * @notice Sells a plot of land (Land ERC721 token) from the sale to executor.
	 *      Executor must supply the metadata for the land plot and a Merkle tree proof
	 *      for the metadata supplied.
	 *
	 * @notice Doesn't mint the token bought immediately on L1 as part of the buy transaction,
	 *      only `PlotBoughtL2` event is emitted instead, which is picked by off-chain process
	 *      and then minted in L2
	 *
	 * @notice Metadata for all the plots is stored off-chain and is publicly available
	 *      to buy plots and to generate Merkle proofs
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev Requires FEATURE_L2_SALE_ACTIVE feature to be enabled
	 *
	 * @dev Throws if current time is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to buy
	 * @param proof Merkle proof for the plot data supplied
	 */
	function buyL2(PlotData memory plotData, bytes32[] memory proof) public virtual payable {
		// verify L2 sale is active
		require(isFeatureEnabled(FEATURE_L2_SALE_ACTIVE), "L2 sale disabled");

		// buying in L2 requires EOA buyer, otherwise we cannot guarantee L2 mint:
		// an address which doesn't have private key cannot be registered with IMX
		// note: should be used with care, see https://github.com/ethereum/solidity/issues/683
		require(msg.sender == tx.origin, "L2 sale requires EOA");

		// execute all the validations, process payment, construct the land plot
		(LandLib.PlotStore memory plot, uint256 pEth, uint256 pIlv) = _buy(plotData, proof);

		// note: token is not minted in L1, it will be picked by the off-chain process and minted in L2

		// emit an event
		emit PlotBoughtL2(msg.sender, plotData.tokenId, plotData.sequenceId, plot, plot.pack(), pEth, pIlv);
	}

	/**
	 * @dev Auxiliary function used in both `buyL1` and `buyL2` functions to
	 *      - execute all the validations required,
	 *      - process payment,
	 *      - generate random seed to derive internal land structure (landmark and sites), and
	 *      - construct the `LandLib.PlotStore` data structure representing land plot bought
	 *
	 * @dev See `buyL1` and `buyL2` functions for more details
	 */
	function _buy(
		PlotData memory plotData,
		bytes32[] memory proof
	) internal virtual returns (
		LandLib.PlotStore memory plot,
		uint256 pEth,
		uint256 pIlv
	) {
		// check if sale is active (and initialized)
		require(isActive(), "inactive sale");

		// make sure plot data Merkle root was set (sale has something on sale)
		require(root != 0x00, "empty sale");

		// verify the plot supplied is a valid/registered plot
		require(isPlotValid(plotData, proof), "invalid plot");

		// verify if token is not yet minted and mark it as minted
		_markAsMinted(plotData.tokenId);

		// process the payment, save the ETH/sILV lot prices
		// a note on reentrancy: `_processPayment` may execute a fallback function on the smart contract buyer,
		// which would be the last execution statement inside `_processPayment`; this execution is reentrancy safe
		// not only because 2,300 transfer function is used, but primarily because all the "give" logic is executed after
		// external call, while the "withhold" logic is executed before the external call
		(pEth, pIlv) = _processPayment(plotData.sequenceId, plotData.tierId);

		// generate the random seed to derive internal land structure (landmark and sites)
		// hash the token ID, block timestamp and tx executor address to get a seed
		uint256 seed = uint256(keccak256(abi.encodePacked(plotData.tokenId, now32(), msg.sender)));

		// allocate the land plot metadata in memory
		plot = LandLib.PlotStore({
			version: 0,
			regionId: plotData.regionId,
			x: plotData.x,
			y: plotData.y,
			tierId: plotData.tierId,
			size: plotData.size,
			// use generated seed to derive the Landmark Type ID, seed is considered "used" after that
			landmarkTypeId: LandLib.getLandmark(seed, plotData.tierId),
			elementSites: 3 * plotData.tierId,
			fuelSites: plotData.tierId < 2? plotData.tierId: 3 * (plotData.tierId - 1),
			// store low 160 bits of the "used" seed in the plot structure
			seed: uint160(seed)
		});

		// return the results as a tuple
		return (plot, pEth, pIlv);
	}

	/**
	 * @dev Verifies if token is minted and marks it as minted
	 *
	 * @dev Throws if token is already minted
	 *
	 * @param tokenId token ID to check and mark as minted
	 */
	function _markAsMinted(uint256 tokenId) internal virtual {
		// calculate bit location to set in `mintedTokens`
		// slot index
		uint256 i = tokenId / 256;
		// bit location within the slot
		uint256 j = tokenId % 256;

		// verify bit `j` at slot `i` is not set
		require(mintedTokens[i] >> j & 0x1 == 0, "already minted");
		// set bit `j` at slot index `i`
		mintedTokens[i] |= 0x1 << j;
	}

	/**
	 * @dev Verifies if token is minted
	 *
	 * @param tokenId token ID to check if it's minted
	 */
	function exists(uint256 tokenId) public view returns(bool) {
		// calculate bit location to check in `mintedTokens`
		// slot index: i = tokenId / 256
		// bit location within the slot: j = tokenId % 256

		// verify if bit `j` at slot `i` is set
		return mintedTokens[tokenId / 256] >> tokenId % 256 & 0x1 == 1;
	}

	/**
	 * @dev Charges tx executor in ETH/sILV, based on if ETH is supplied in the tx or not:
	 *      - if ETH is supplied, charges ETH only (throws if value supplied is not enough)
	 *      - if ETH is not supplied, charges sILV only (throws if sILV transfer fails)
	 *
	 * @dev Sends the change (for ETH payment - if any) back to transaction executor
	 *
	 * @dev Internal use only, throws on any payment failure
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 */
	function _processPayment(uint32 sequenceId, uint16 tierId) internal virtual returns (uint256 pEth, uint256 pIlv) {
		// determine current token price
		pEth = tokenPriceNow(sequenceId, tierId);

		// current land sale version doesn't support free tiers (ID: 0)
		require(pEth != 0, "unsupported tier");

		// if ETH is not supplied, try to process sILV payment
		if(msg.value == 0) {
			// convert price `p` to ILV/sILV
			pIlv = LandSalePriceOracle(priceOracle).ethToIlv(pEth);

			// LandSaleOracle implementation guarantees the price to have meaningful value,
			// we still check "close to zero" price case to be extra safe
			require(pIlv > 1_000, "price conversion error");

			// verify sender sILV balance and allowance to improve error messaging
			// note: `transferFrom` would fail anyway, but sILV deployed into the mainnet
			//       would just fail with "arithmetic underflow" without any hint for the cause
			require(ERC20(sIlvContract).balanceOf(msg.sender) >= pIlv, "not enough funds available");
			require(ERC20(sIlvContract).allowance(msg.sender, address(this)) >= pIlv, "not enough funds supplied");

			// if beneficiary address is set, transfer the funds directly to the beneficiary
			// otherwise, transfer the funds to the sale contract for the future pull withdrawal
			// note: sILV.transferFrom always throws on failure and never returns `false`, however
			//       to keep this code "copy-paste safe" we do require it to return `true` explicitly
			require(
				ERC20(sIlvContract).transferFrom(msg.sender, beneficiary != address(0)? beneficiary: address(this), pIlv),
				"ERC20 transfer failed"
			);

			// no need for the change processing here since we're taking the amount ourselves

			// return ETH price and sILV price actually charged
			return (pEth, pIlv);
		}

		// process ETH payment otherwise

		// ensure amount of ETH send
		require(msg.value >= pEth, "not enough ETH");

		// if beneficiary address is set
		if(beneficiary != address(0)) {
			// transfer the funds directly to the beneficiary
			// note: beneficiary cannot be a smart contract with complex fallback function
			//       by design, therefore we're using the 2,300 gas transfer
			beneficiary.transfer(pEth);
		}
		// if beneficiary address is not set, funds remain on
		// the sale contract address for the future pull withdrawal

		// if there is any change sent in the transaction
		// (most of the cases there will be a change since this is a dutch auction)
		if(msg.value > pEth) {
			// transfer the change back to the transaction executor (buyer)
			// note: calling the sale contract by other smart contracts with complex fallback functions
			//       is not supported by design, therefore we're using the 2,300 gas transfer
			payable(msg.sender).transfer(msg.value - pEth);
		}

		// return the ETH price charged
		return (pEth, 0);
	}

	/**
	 * @notice Current time adjusted to count for the total duration sale was on pause
	 *
	 * @dev If sale operates in a normal way, without emergency pausing involved, this
	 *      is always equal to the current time;
	 *      if sale is paused for some period of time, this duration is subtracted, the
	 *      sale "slows down", and behaves like if it had a delayed start
	 *
	 * @return sale own time, current time adjusted by `pauseDuration`
	 */
	function ownTime() public view virtual returns (uint32) {
		// subtract total pause duration from the current time (if any) and return
		return now32() - pauseDuration;
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now32() public view virtual returns (uint32) {
		// return current block timestamp
		return uint32(block.timestamp);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Upgradeable Access Control List // ERC1967Proxy
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @dev This is an upgradeable version of the ACL, based on Zeppelin implementation for ERC1967,
 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
 *      see https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
 *
 * @author Basil Gorin
 */
abstract contract UpgradeableAccessControl is UUPSUpgradeable {
	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
	 *      the amount of storage used by a contract always adds up to the 50.
	 *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;

	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @notice Upgrade manager is responsible for smart contract upgrades,
	 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
	 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
	 *
	 * @dev Role ROLE_UPGRADE_MANAGER allows passing the _authorizeUpgrade() check
	 * @dev Role ROLE_UPGRADE_MANAGER has single bit at position 254 enabled
	 */
	uint256 public constant ROLE_UPGRADE_MANAGER = 0x4000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @dev UUPS initializer, sets the contract owner to have full privileges
	 *
	 * @param _owner smart contract owner having full privileges
	 */
	function _postConstruct(address _owner) internal virtual initializer {
		// grant owner full privileges
		userRoles[_owner] = FULL_PRIVILEGES_MASK;

		// fire an event
		emit RoleUpdated(msg.sender, _owner, FULL_PRIVILEGES_MASK, FULL_PRIVILEGES_MASK);
	}

	/**
	 * @notice Returns an address of the implementation smart contract,
	 *      see ERC1967Upgrade._getImplementation()
	 *
	 * @return the current implementation address
	 */
	function getImplementation() public view virtual returns (address) {
		// delegate to `ERC1967Upgrade._getImplementation()`
		return _getImplementation();
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns (uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns (uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns (bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns (bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}

	/**
	 * @inheritdoc UUPSUpgradeable
	 */
	function _authorizeUpgrade(address) internal virtual override {
		// caller must have a permission to upgrade the contract
		require(isSenderInRole(ROLE_UPGRADE_MANAGER), "access denied");
	}
}