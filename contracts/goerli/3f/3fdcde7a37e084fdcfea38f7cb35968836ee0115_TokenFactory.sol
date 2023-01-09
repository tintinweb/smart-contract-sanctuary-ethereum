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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IToken} from "./tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "./tokens/interfaces/IFixedPriceToken.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Observability, IObservability} from "./observability/Observability.sol";
import {TokenProxy} from "./TokenProxy.sol";
import {ITokenFactory} from "./interfaces/ITokenFactory.sol";

contract TokenFactory is Ownable2Step, ITokenFactory {
    /// @notice mapping of all tokens created by this factory
    mapping(address => bool) public isToken;

    /// @notice mapping of all deployed implementations
    mapping(address => bool) private deployments;

    /// @notice mapping of all upgrades
    /// @notice previousImplementation => newImplementation => isValid
    mapping(address => mapping(address => bool)) private upgrades;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    constructor() {
        o11y = address(new Observability());
    }

    /// @notice Creates a new token contract with the given implementation and data
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone) {
        clone = address(new TokenProxy(tokenImpl, ""));
        isToken[clone] = true;

        if (!deployments[tokenImpl]) revert NotDeployed(tokenImpl);
        IObservability(o11y).emitCloneDeployed(msg.sender, clone);

        // Initialize clone.
        IFixedPriceToken(clone).initialize(msg.sender, data);
    }

    /// @notice checks if an implementation is valid
    function isValidDeployment(address impl) external view returns (bool) {
        return deployments[impl];
    }

    /// @notice registers a new implementation
    function registerDeployment(address impl) external onlyOwner {
        deployments[impl] = true;
        IObservability(o11y).emitDeploymentTargetRegistererd(impl);
    }

    /// @notice unregisters an implementation
    function unregisterDeployment(address impl) external onlyOwner {
        delete deployments[impl];
        IObservability(o11y).emitDeploymentTargetUnregistered(impl);
    }

    /// @notice checks if an upgrade is valid
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external view returns (bool) {
        return upgrades[prevImpl][newImpl];
    }

    /// @notice registers a new upgrade
    function registerUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        upgrades[prevImpl][newImpl] = true;

        IObservability(o11y).emitUpgradeRegistered(prevImpl, newImpl);
    }

    /// @notice unregisters an upgrade
    function unregisterUpgrade(
        address prevImpl,
        address newImpl
    ) external onlyOwner {
        delete upgrades[prevImpl][newImpl];

        IObservability(o11y).emitUpgradeUnregistered(prevImpl, newImpl);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "./lib/proxy/ERC1967Proxy.sol";

contract TokenProxy is ERC1967Proxy {
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITokenFactory {
    error InvalidUpgrade(address impl);
    error NotDeployed(address impl);

    /// @notice Creates a new token contract with the given implementation and data
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone);

    /// @notice checks if an implementation is valid
    function isValidDeployment(address impl) external view returns (bool);

    /// @notice registers a new implementation
    function registerDeployment(address impl) external;

    /// @notice unregisters an implementation
    function unregisterDeployment(address impl) external;

    /// @notice checks if an upgrade is valid
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external returns (bool);

    /// @notice registers a new upgrade
    function registerUpgrade(address prevImpl, address newImpl) external;

    /// @notice unregisters an upgrade
    function unregisterUpgrade(address prevImpl, address newImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice The external ERC1967Upgrade events and errors
interface IERC1967Upgrade {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

import {IERC1967Upgrade} from "../interfaces/IERC1967Upgrade.sol";
import {ERC1967Upgrade} from "./ERC1967Upgrade.sol";

/// @title ERC1967Proxy
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Proxy.sol)
/// - Inherits a modern, minimal ERC1967Upgrade
contract ERC1967Proxy is IERC1967Upgrade, Proxy, ERC1967Upgrade {
    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @dev Initializes the proxy with an implementation contract and encoded function call
    /// @param _logic The implementation address
    /// @param _data The encoded function call
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev The address of the current implementation
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {IERC1967Upgrade} from "../interfaces/IERC1967Upgrade.sol";
import {Address} from "../utils/Address.sol";

/// @title ERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (
                bytes32 slot
            ) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title EIP712
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/Address.sol)
/// - Uses custom errors `INVALID_TARGET()` & `DELEGATE_CALL_FAILED()`
/// - Adds util converting address to bytes32
library Address {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Utility to convert an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(
        address _target,
        bytes memory _data
    ) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(
        bool _success,
        bytes memory _returndata
    ) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IObservability, IObservabilityEvents} from "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    function emitCloneDeployed(address owner, address clone) external override {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    /// @notice Emitted when a sale has occured
    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external override {
        emit Sale(msg.sender, to, pricePerToken, amount);
    }

    /// @notice Emitted when funds have been withdrawn
    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external override {
        emit FundsWithdrawn(msg.sender, withdrawnBy, withdrawnTo, amount);
    }

    /// @notice Emitted when a new implementation is registered
    function emitDeploymentTargetRegistererd(address impl) external override {
        emit DeploymentTargetRegistered(impl);
    }

    /// @notice Emitted when an implementation is unregistered
    function emitDeploymentTargetUnregistered(address impl) external override {
        emit DeploymentTargetUnregistered(impl);
    }

    /// @notice Emitted when a new upgrade is registered
    function emitUpgradeRegistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeRegistered(prevImpl, impl);
    }

    /// @notice Emitted when an upgrade is unregistered
    function emitUpgradeUnregistered(
        address prevImpl,
        address impl
    ) external override {
        emit UpgradeUnregistered(prevImpl, impl);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address clone
    );

    /// @notice Emitted when a sale has occured
    event Sale(
        address indexed clone,
        address indexed to,
        uint256 pricePerToken,
        uint256 amount
    );

    /// @notice Emitted when funds have been withdrawn
    event FundsWithdrawn(
        address indexed clone,
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount
    );

    /// @notice Emitted when a new implementation is registered
    event DeploymentTargetRegistered(address indexed impl);

    /// @notice Emitted when an implementation is unregistered
    event DeploymentTargetUnregistered(address indexed impl);

    /// @notice Emitted when an upgrade is registered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the registered upgrade
    event UpgradeRegistered(address indexed prevImpl, address indexed newImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the unregistered upgrade
    event UpgradeUnregistered(
        address indexed prevImpl,
        address indexed newImpl
    );
}

interface IObservability {
    function emitCloneDeployed(address owner, address clone) external;

    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external;

    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external;

    function emitDeploymentTargetRegistererd(address impl) external;

    function emitDeploymentTargetUnregistered(address imp) external;

    function emitUpgradeRegistered(address prevImpl, address impl) external;

    function emitUpgradeUnregistered(address prevImpl, address impl) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IHTMLRenderer {
    struct FileType {
        string name;
        address fileSystem;
        uint8 fileType;
    }

    function initilize(address owner) external;

    /// @notice Returns the HTML for the given script and imports
    function generateURI(
        FileType[] calldata imports,
        string calldata script
    ) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IHTMLRenderer} from "../../renderer/interfaces/IHTMLRenderer.sol";

interface IFixedPriceToken {
    struct SaleInfo {
        uint16 artistProofCount;
        uint64 startTime;
        uint64 endTime;
        uint112 price;
    }

    error SaleNotActive();
    error InvalidPrice();
    error SoldOut();
    error ProofsMinted();

    /// @notice initialize the token
    function initialize(address owner, bytes calldata data) external;

    /// @notice contruct a generic data URI from token data
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _animationURL,
        string memory _image
    ) external pure returns (string memory);

    /// @notice generate a preview URI for the token
    function generatePreviewURI(
        string memory tokenId
    ) external view returns (string memory);

    /// @notice generate the full script for the token
    function generateFullScript(
        uint256 tokenId
    ) external view returns (string memory);

    /// @notice get the script for the contract
    function getScript() external view returns (string memory);

    /// @notice set the script for the contract
    function setScript(string memory script) external;

    /// @notice get the preview base URI for the token
    function setPreviewBaseURL(string memory uri) external;

    /// @notice set the html renderer for the token
    function setHTMLRenderer(address _htmlRenderer) external;

    /// @notice add multiple imports to the token
    function addManyImports(
        IHTMLRenderer.FileType[] calldata _imports
    ) external;

    /// @notice set a single import to the token for a given index
    function setImport(
        uint256 index,
        IHTMLRenderer.FileType calldata _import
    ) external;

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IToken {
    struct TokenInfo {
        string name;
        string symbol;
        string description;
        address fundsRecipent;
        uint256 maxSupply;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();
    error MaxSupplyReached();

    /// @notice returns the total supply of tokens
    function totalSupply() external returns (uint256);

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool);

    /// @notice mint a token for the given address
    function safeMint(address to) external;

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external;

    /// @notice sets the minter status for the given user
    function setMinter(address user, bool isAllowed) external;
}