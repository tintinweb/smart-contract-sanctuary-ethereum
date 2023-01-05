// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title Base Constants
 * @dev Append-only extendable, only use internal constants!
 */
abstract contract BaseConstants {
    // =========
    // Constants
    // =========

    /**
     * @dev Reentrancy mutex unlocked state.
     */
    uint256 internal constant _REENTRANCY_LOCK_UNLOCKED = 1;

    /**
     * @dev Reentrancy mutex locked state.
     */
    uint256 internal constant _REENTRANCY_LOCK_LOCKED = 2;

    /**
     * @dev These are modules that are only accessible by a single address.
     */
    uint16 internal constant _MODULE_TYPE_SINGLE_PROXY = 1;

    /**
     * @dev These are modules that have many addresses.
     */
    uint16 internal constant _MODULE_TYPE_MULTI_PROXY = 2;

    /**
     * @dev These are modules that are called internally by the system and don't have any public proxies.
     */
    uint16 internal constant _MODULE_TYPE_INTERNAL = 3;

    /**
     * @dev Module id of built-in upgradeable installer module.
     */
    uint32 internal constant _MODULE_ID_INSTALLER = 1;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {IBaseModule} from "./interfaces/IBaseModule.sol";

// Internals
import {Base} from "./internals/Base.sol";

/**
 * @title Base Module
 * @dev Upgradeable.
 */
abstract contract BaseModule is IBaseModule, Base {
    // ==========
    // Immutables
    // ==========

    /**
     * @notice Module id.
     */
    uint32 private immutable _moduleId;

    /**
     * @notice Module type.
     */
    uint16 private immutable _moduleType;

    /**
     * @notice Module version.
     */
    uint16 private immutable _moduleVersion;

    // =========
    // Modifiers
    // =========

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() virtual {
        address messageSender = _unpackMessageSender();

        if (messageSender != _owner) revert Unauthorized();

        _;
    }

    // ===========
    // Constructor
    // ===========

    /**
     * @param moduleId_ Module id.
     * @param moduleType_ Module type.
     * @param moduleVersion_ Module version.
     */
    constructor(uint32 moduleId_, uint16 moduleType_, uint16 moduleVersion_) {
        if (moduleId_ == 0) revert InvalidModuleId();
        if (moduleType_ == 0 || moduleType_ > _MODULE_TYPE_INTERNAL)
            revert InvalidModuleType();
        if (moduleVersion_ == 0) revert InvalidModuleVersion();

        _moduleId = moduleId_;
        _moduleType = moduleType_;
        _moduleVersion = moduleVersion_;
    }

    // ==============
    // View functions
    // ==============

    /**
     * @notice Get module id.
     * @return Module id.
     */
    function moduleId() external view virtual override returns (uint32) {
        return _moduleId;
    }

    /**
     * @notice Get module type.
     * @return Module type.
     */
    function moduleType() external view virtual override returns (uint16) {
        return _moduleType;
    }

    /**
     * @notice Get module version.
     * @return Module version.
     */
    function moduleVersion() external view virtual override returns (uint16) {
        return _moduleVersion;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {IBaseState} from "./interfaces/IBaseState.sol";

// Sources
import {BaseConstants} from "./BaseConstants.sol";

/**
 * @title Base State
 * @dev Append-only, extendable after __gap: first 50 slots (0-49) are reserved.
 *
 * @dev Storage layout:
 * | Name            | Type                                                | Slot | Offset | Bytes |
 * |-----------------|-----------------------------------------------------|------|--------|-------|
 * | _reentrancyLock | uint256                                             | 0    | 0      | 32    |
 * | _owner          | address                                             | 1    | 0      | 20    |
 * | _pendingOwner   | address                                             | 2    | 0      | 20    |
 * | _modules        | mapping(uint32 => address)                          | 3    | 0      | 32    |
 * | _proxies        | mapping(uint32 => address)                          | 4    | 0      | 32    |
 * | _trusts         | mapping(address => struct TBaseState.TrustRelation) | 5    | 0      | 32    |
 * | __gap           | uint256[44]                                         | 6    | 0      | 1408  |
 */
abstract contract BaseState is IBaseState, BaseConstants {
    // =======
    // Storage
    // =======

    /**
     * @notice Reentrancy lock.
     * @dev Slot 0 (32 bytes).
     * Booleans are more expensive than uint256 or any type that takes up a full
     * word because each write operation emits an extra SLOAD to first read the
     * slot's contents, replace the bits taken up by the boolean, and then write
     * back. This is the compiler's defense against contract upgrades and
     * pointer aliasing, and it cannot be disabled.
     *
     * The values being non-zero value makes deployment a bit more expensive,
     * but in exchange the refund on every call to `nonReentrant` will be lower in
     * amount. Since refunds are capped to a percentage of the total
     * transaction's gas, it is best to keep them low in cases like this one, to
     * increase the likelihood of the full refund coming into effect.
     */
    uint256 internal _reentrancyLock;

    /**
     * @notice Protocol owner.
     * @dev Slot 1 (20 bytes).
     */
    address internal _owner;

    /**
     * @notice Pending protocol owner.
     * @dev Slot 2 (20 bytes).
     */
    address internal _pendingOwner;

    /**
     * @notice Module id => module implementation.
     * @dev Slot 3 (32 bytes).
     */
    mapping(uint32 => address) internal _modules;

    /**
     * @notice Module id => proxy address (only for single-proxy modules).
     * @dev Slot 4 (32 bytes).
     */
    mapping(uint32 => address) internal _proxies;

    /**
     * @notice Proxy address => TrustRelation { moduleId, moduleImplementation }.
     * @dev Slot 5 (32 bytes).
     */
    mapping(address => TrustRelation) internal _trusts;

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * The size of the __gap array is calculated so that the amount of storage used by a
     * contract always adds up to the same number (in this case 50 storage slots, 0 to 49).
     * @dev Slot 6 (1408 bytes).
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {TBaseState, IBaseState} from "./IBaseState.sol";

/**
 * @title Base Test Interface
 */
interface TBase is TBaseState {
    // ======
    // Errors
    // ======

    error EmptyError();

    error Reentrancy();

    error InternalModule();

    error InvalidModuleId();

    error InvalidModuleType();
}

/**
 * @title Base Interface
 */
interface IBase is IBaseState, TBase {

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {TBase, IBase} from "./IBase.sol";

/**
 * @title Base Installer Test Interface
 */
interface TBaseModule is TBase {
    // ======
    // Errors
    // ======

    error FailedToLog();

    error InvalidModuleVersion();

    error Unauthorized();
}

/**
 * @title Base Module Interface
 */
interface IBaseModule is IBase, TBaseModule {
    function moduleId() external view returns (uint32);

    function moduleType() external view returns (uint16);

    function moduleVersion() external view returns (uint16);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title Base State Test Interface
 */
interface TBaseState {
    // =====
    // Types
    // =====

    struct TrustRelation {
        // Packed slot: 4 + 20 = 24
        uint32 moduleId; // 0 is untrusted.
        address moduleImplementation; // only non-0 for external single-proxy modules.
    }
}

/**
 * @title BaseState Interface
 */
interface IBaseState is TBaseState {

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title Proxy Test Interface
 */
interface TProxy {

}

/**
 * @title Proxy Interface
 */
interface IProxy is TProxy {
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {IBase} from "../interfaces/IBase.sol";

// Internals
import {Proxy} from "./Proxy.sol";

// Sources
import {BaseState} from "../BaseState.sol";

/**
 * @title Base
 * @dev Extendable.
 */
abstract contract Base is IBase, BaseState {
    // =========
    // Modifiers
    // =========

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported.
     */
    modifier nonReentrant() virtual {
        // On the first call to `nonReentrant`, _status will be `_REENTRANCY_LOCK_UNLOCKED`.
        if (_reentrancyLock != _REENTRANCY_LOCK_UNLOCKED) revert Reentrancy();

        // Any calls to `nonReentrant` after this point will fail.
        _reentrancyLock = _REENTRANCY_LOCK_LOCKED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200).
        _reentrancyLock = _REENTRANCY_LOCK_UNLOCKED;
    }

    // ==================
    // Internal functions
    // ==================

    /**
     * @dev Create or return proxy by module id.
     * @param moduleId_ Module id.
     */
    function _createProxy(uint32 moduleId_, uint16 moduleType_)
        internal
        virtual
        returns (address)
    {
        if (moduleId_ == 0) revert InvalidModuleId();
        if (moduleType_ == 0 || moduleType_ > _MODULE_TYPE_INTERNAL)
            revert InvalidModuleType();

        if (moduleType_ == _MODULE_TYPE_INTERNAL) revert InternalModule();

        if (_proxies[moduleId_] != address(0)) return _proxies[moduleId_];

        address proxyAddress = address(new Proxy());

        if (
            moduleType_ == _MODULE_TYPE_SINGLE_PROXY ||
            moduleType_ == _MODULE_TYPE_MULTI_PROXY
        ) _proxies[moduleId_] = proxyAddress;

        _trusts[proxyAddress].moduleId = moduleId_;

        return proxyAddress;
    }

    // TODO: write test for this and evaluate its use

    /**
     * @dev Call internal module.
     * @param moduleId_ Module id.
     * @param input_ Input data.
     */
    function _callInternalModule(uint32 moduleId_, bytes memory input_)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory result) = _modules[moduleId_].delegatecall(
            input_
        );

        if (!success) _revertBytes(result);

        return result;
    }

    /**
     * @dev Unpack message sender from calldata.
     * @return messageSender_ Message sender.
     */
    function _unpackMessageSender()
        internal
        pure
        virtual
        returns (address messageSender_)
    {
        // Calldata: [original calldata (N bytes)][original msg.sender (20 bytes)][proxy address (20 bytes)]
        assembly {
            messageSender_ := shr(0x60, calldataload(sub(calldatasize(), 0x28)))
        }
    }

    /**
     * @dev Unpack proxy address from calldata.
     * @return proxyAddress_ Proxy address.
     */
    function _unpackProxyAddress()
        internal
        pure
        virtual
        returns (address proxyAddress_)
    {
        // Calldata: [original calldata (N bytes)][original msg.sender (20 bytes)][proxy address (20 bytes)]
        assembly {
            proxyAddress_ := shr(0x60, calldataload(sub(calldatasize(), 0x14)))
        }
    }

    /**
     * @dev Revert with error message.
     * @param errorMessage_ Error message.
     */
    function _revertBytes(bytes memory errorMessage_) internal pure {
        if (errorMessage_.length > 0) {
            assembly {
                revert(add(32, errorMessage_), mload(errorMessage_))
            }
        }

        revert EmptyError();
    }

    // TODO: REMOVE
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Interfaces
import {IProxy} from "../interfaces/IProxy.sol";

/**
 * @title Proxy
 * @dev Proxies are non-upgradeable stub contracts that have two jobs:
 * - Forward method calls from external users to the dispatcher.
 * - Receive method calls from the dispatcher and log events as instructed
 * @dev Execution takes place within the dispatcher storage context, not the proxy's.
 * @dev Non-upgradeable.
 */
contract Proxy is IProxy {
    // =========
    // Constants
    // =========

    /// @dev `bytes4(keccak256(bytes("proxyToModuleImplementation(address)")))`.
    bytes4 private constant _PROXY_ADDRESS_TO_MODULE_IMPLEMENTATION_SELECTOR =
        0xf2b124bd;

    // ==========
    // Immutables
    // ==========

    /**
     * @dev Deployer address.
     */
    address internal immutable _deployer;

    // ===========
    // Constructor
    // ===========

    constructor() payable {
        _deployer = msg.sender;
    }

    // ==============
    // View functions
    // ==============

    /**
     * @notice Returns implementation address by resolving through the `Dispatcher`.
     * @dev To prevent selector clashing avoid using the `implementation()` selector inside of modules.
     * @return address Implementation address or zero address if unresolved.
     */
    function implementation() external view returns (address) {
        // TODO: optimize this for bytecode size
        // TODO: how to handle possible selector clash?

        (bool success, bytes memory response) = _deployer.staticcall(
            abi.encodeWithSelector(
                _PROXY_ADDRESS_TO_MODULE_IMPLEMENTATION_SELECTOR,
                address(this)
            )
        );

        if (success) {
            return abi.decode(response, (address));
        } else {
            return address(0);
        }
    }

    // ==================
    // Fallback functions
    // ==================

    /**
     * @dev Will run if no other function in the contract matches the call data.
     */
    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address deployer_ = _deployer;

        // If the caller is the deployer, instead of re-enter - issue a log message.
        if (msg.sender == deployer_) {
            // Calldata: [number of topics as uint8 (1 byte)][topic #i (32 bytes)]{0,4}[extra log data (N bytes)]
            assembly {
                // We take full control of memory in this inline assembly block because it will not return to
                // Solidity code. We overwrite the Solidity scratch pad at memory position 0.
                mstore(0x00, 0x00)

                // Copy all transaction data into memory starting at location `31`.
                calldatacopy(0x1F, 0x00, calldatasize())

                // Since the number of topics only occupy 1 byte of the calldata, we store the calldata starting at
                // location `31` so the number of topics is stored in the first 32 byte chuck of memory and we can
                // leverage `mload` to get the corresponding number.
                switch mload(0x00)
                case 0 {
                    // 0 Topics
                    // log0(memory[offset:offset+len])
                    log0(0x20, sub(calldatasize(), 0x01))
                }
                case 1 {
                    // 1 Topic
                    // log1(memory[offset:offset+len], topic0)
                    log1(0x40, sub(calldatasize(), 0x21), mload(0x20))
                }
                case 2 {
                    // 2 Topics
                    // log2(memory[offset:offset+len], topic0, topic1)
                    log2(
                        0x60,
                        sub(calldatasize(), 0x41),
                        mload(0x20),
                        mload(0x40)
                    )
                }
                case 3 {
                    // 3 Topics
                    // log3(memory[offset:offset+len], topic0, topic1, topic2)
                    log3(
                        0x80,
                        sub(calldatasize(), 0x61),
                        mload(0x20),
                        mload(0x40),
                        mload(0x60)
                    )
                }
                case 4 {
                    // 4 Topics
                    // log4(memory[offset:offset+len], topic0, topic1, topic2, topic3)
                    log4(
                        0xA0,
                        sub(calldatasize(), 0x81),
                        mload(0x20),
                        mload(0x40),
                        mload(0x60),
                        mload(0x80)
                    )
                }
                // The EVM doesn't support more than 4 topics, so in case the number of topics is not within the
                // range {0..4} something probably went wrong and we should revert.
                default {
                    revert(0, 0)
                }

                // Return 0
                return(0, 0)
            }
        } else {
            // Calldata: [calldata (N bytes)]
            assembly {
                // We take full control of memory in this inline assembly block because it will not return to Solidity code.
                // We overwrite the Solidity scratch pad at memory position 0 with the `dispatch()` function signature,
                // occuping the first 4 bytes.
                mstore(
                    0x00,
                    0xe9c4a3ac00000000000000000000000000000000000000000000000000000000
                )

                // Copy msg.data into memory, starting at position `4`.
                calldatacopy(0x04, 0x00, calldatasize())

                // We store the address of the `msg.sender` at location `4 + calldatasize()`.
                mstore(add(0x04, calldatasize()), shl(0x60, caller()))

                // Call so that execution happens within the main context.
                // Out and outsize are 0 because we don't know the size yet.
                // Calldata: [dispatch() selector (4 bytes)][calldata (N bytes)][msg.sender (20 bytes)]
                let result := call(
                    gas(),
                    deployer_,
                    0,
                    0,
                    // 0x18 is the length of the selector + an address, 24 bytes, in hex.
                    add(0x18, calldatasize()),
                    0,
                    0
                )

                // Copy the returned data into memory, starting at position `0`.
                returndatacopy(0x00, 0x00, returndatasize())

                switch result
                case 0 {
                    // If result is 0, revert.
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }

    // TODO: REMOVE
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Sources
import {BaseModule} from "../../src/BaseModule.sol";

// Implementations
import {ImplementationState} from "./ImplementationState.sol";

/**
 * @title Implementation Module
 */
contract ImplementationModule is BaseModule, ImplementationState {
    // ===========
    // Constructor
    // ===========

    constructor(
        uint32 _moduleId,
        uint16 _moduleType,
        uint16 _moduleVersion
    ) BaseModule(_moduleId, _moduleType, _moduleVersion) {}

    // ==========
    // Test stubs
    // ==========
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// Sources
import {BaseState} from "../../src/BaseState.sol";

/**
 * @title Implementation State
 *
 * @dev Storage layout:
 * | Name                    | Type                                                | Slot | Offset | Bytes |
 * |-------------------------|-----------------------------------------------------|------|--------|-------|
 * | _reentrancyLock         | uint256                                             | 0    | 0      | 32    |
 * | _owner                  | address                                             | 1    | 0      | 20    |
 * | _pendingOwner           | address                                             | 2    | 0      | 20    |
 * | _modules                | mapping(uint32 => address)                          | 3    | 0      | 32    |
 * | _proxies                | mapping(uint32 => address)                          | 4    | 0      | 32    |
 * | _trusts                 | mapping(address => struct TBaseState.TrustRelation) | 5    | 0      | 32    |
 * | __gap                   | uint256[44]                                         | 6    | 0      | 1408  |
 * | _implementationState0   | bytes32                                             | 50   | 0      | 32    |
 * | _implementationState1   | uint256                                             | 51   | 0      | 32    |
 * | _implementationState2   | address                                             | 52   | 0      | 20    |
 * | getImplementationState3 | address                                             | 53   | 0      | 20    |
 * | getImplementationState4 | bool                                                | 53   | 20     | 1     |
 * | _implementationState5   | mapping(address => uint256)                         | 54   | 0      | 32    |
 */
contract ImplementationState is BaseState {
    // =======
    // Storage
    // =======

    /**
     * @notice Implementation state 0.
     * @dev Slot 51 (32 bytes).
     */
    bytes32 internal _implementationState0;

    /**
     * @notice Implementation state 1.
     * @dev Slot 52 (32 bytes).
     */
    uint256 internal _implementationState1;

    /**
     * @notice Implementation state 2.
     * @dev Slot 53 (20 bytes).
     */
    address internal _implementationState2;

    /**
     * @notice Implementation state 3.
     * @dev Slot 54 (20 bytes).
     */
    address public getImplementationState3 = address(0xAAAA);

    /**
     * @notice Implementation state 4.
     * @dev Slot 54 (20 byte offset, 1 byte).
     */
    bool public getImplementationState4 = true;

    /**
     * @notice Implementation state 4.
     * @dev Slot 54 (32 bytes).
     */
    mapping(address => uint256) internal _implementationState5;

    // ==========
    // Test stubs
    // ==========

    function getImplementationState0() public view returns (bytes32) {
        return _implementationState0;
    }

    function getImplementationState1() public view returns (uint256) {
        return _implementationState1;
    }

    function getImplementationState2() public view returns (address) {
        return _implementationState2;
    }

    function getImplementationState5(
        address location_
    ) public view returns (uint256) {
        return _implementationState5[location_];
    }

    function setImplementationState0(bytes32 message_) public {
        _implementationState0 = message_;
    }

    function setImplementationState1(uint256 number_) public {
        _implementationState1 = number_;
    }

    function setImplementationState2(address location_) public {
        _implementationState2 = location_;
    }

    function setImplementationState3(address location_) public {
        getImplementationState3 = location_;
    }

    function setImplementationState4(bool value_) public {
        getImplementationState4 = value_;
    }

    function setImplementationState5(
        address location_,
        uint256 number_
    ) public {
        _implementationState5[location_] = number_;
    }
}