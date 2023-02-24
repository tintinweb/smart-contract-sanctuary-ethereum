// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
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

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
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

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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
pragma solidity ^0.8.0;

import {SafeAware, ISafe} from "./SafeAware.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

// When the base contract (implementation) that proxies use is created,
// we use this no-op address when an address is needed to make contracts initialized but unusable
address constant IMPL_INIT_NOOP_ADDR = address(1);
ISafe constant IMPL_INIT_NOOP_SAFE = ISafe(payable(IMPL_INIT_NOOP_ADDR));

/**
 * @title EIP1967Upgradeable
 * @dev Minimal implementation of EIP-1967 allowing upgrades of itself by a Safe transaction
 * @dev Note that this contract doesn't have have an initializer as the implementation
 * address must already be set in the correct slot (in our case, the proxy does on creation)
 */
abstract contract EIP1967Upgradeable is SafeAware {
    event Upgraded(IModuleMetadata indexed implementation, string moduleId, uint256 version);

    // EIP1967_IMPL_SLOT = keccak256('eip1967.proxy.implementation') - 1
    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant IMPL_CONTRACT_FLAG = address(0xffff);

    // As the base contract doesn't use the implementation slot,
    // set a flag in that slot so that it is possible to detect it
    constructor() {
        address implFlag = IMPL_CONTRACT_FLAG;
        assembly {
            sstore(EIP1967_IMPL_SLOT, implFlag)
        }
    }

    /**
     * @notice Upgrades the proxy to a new implementation address
     * @dev The new implementation should be a contract that implements a way to perform upgrades as well
     * otherwise the proxy will freeze on that implementation forever, since the proxy doesn't contain logic to change it.
     * It also must conform to the IModuleMetadata interface (this is somewhat of an implicit guard against bad upgrades)
     * @param _newImplementation The address of the new implementation address the proxy will use
     */
    function upgrade(IModuleMetadata _newImplementation) public onlySafe {
        assembly {
            sstore(EIP1967_IMPL_SLOT, _newImplementation)
        }

        emit Upgraded(_newImplementation, _newImplementation.moduleId(), _newImplementation.moduleVersion());
    }

    function _implementation() internal view returns (IModuleMetadata impl) {
        assembly {
            impl := sload(EIP1967_IMPL_SLOT)
        }
    }

    /**
     * @dev Checks whether the context is foreign to the implementation
     * or the proxy by checking the EIP-1967 implementation slot.
     * If we were running in proxy context, the impl address would be stored there
     * If we were running in impl conext, the IMPL_CONTRACT_FLAG would be stored there
     */
    function _isForeignContext() internal view returns (bool) {
        return address(_implementation()) == address(0);
    }

    function _isImplementationContext() internal view returns (bool) {
        return address(_implementation()) == IMPL_CONTRACT_FLAG;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Copied and modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/ERC2771Context.sol (MIT licensed)
 */
abstract contract ERC2771Context is SafeAware {
    // SAFE_SLOT = keccak256("firm.erc2271context.forwarders") - 1
    bytes32 internal constant ERC2271_TRUSTED_FORWARDERS_BASE_SLOT =
        0xde1482070091aef895249374204bcae0fa9723215fa9357228aa489f9d1bd669;

    event TrustedForwarderSet(address indexed forwarder, bool enabled);

    function setTrustedForwarder(address forwarder, bool enabled) external onlySafe {
        _setTrustedForwarder(forwarder, enabled);
    }

    function _setTrustedForwarder(address forwarder, bool enabled) internal {
        _trustedForwarders()[forwarder] = enabled;

        emit TrustedForwarderSet(forwarder, enabled);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders()[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _trustedForwarders() internal pure returns (mapping(address => bool) storage trustedForwarders) {
        assembly {
            trustedForwarders.slot := ERC2271_TRUSTED_FORWARDERS_BASE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";
import {ERC2771Context} from "./ERC2771Context.sol";
import {EIP1967Upgradeable, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "./EIP1967Upgradeable.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

abstract contract FirmBase is EIP1967Upgradeable, ERC2771Context, IModuleMetadata {
    event Initialized(ISafe indexed safe, IModuleMetadata indexed implementation);

    function __init_firmBase(ISafe safe_, address trustedForwarder_) internal {
        // checks-effects-interactions violated so that the init event always fires first
        emit Initialized(safe_, _implementation());

        __init_setSafe(safe_);
        if (trustedForwarder_ != address(0) || trustedForwarder_ != IMPL_INIT_NOOP_ADDR) {
            _setTrustedForwarder(trustedForwarder_, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeAware
 * @dev Base contract for Firm components that need to be aware of a Safe
 * as their admin
 */
abstract contract SafeAware {
    // SAFE_SLOT = keccak256("firm.safeaware.safe") - 1
    bytes32 internal constant SAFE_SLOT = 0xb2c095c1a3cccf4bf97d6c0d6a44ba97fddb514f560087d9bf71be2c324b6c44;

    /**
     * @notice Address of the Safe that this module is tied to
     */
    function safe() public view returns (ISafe safeAddr) {
        assembly {
            safeAddr := sload(SAFE_SLOT)
        }
    }

    error SafeAddressZero();
    error AlreadyInitialized();

    /**
     * @dev Contracts that inherit from SafeAware, including derived contracts as
     * EIP1967Upgradeable or Safe, should call this function on initialization
     * Will revert if called twice
     * @param _safe The address of the GnosisSafe to use, won't be modifiable unless
     * implicitly implemented by the derived contract, which is not recommended
     */
    function __init_setSafe(ISafe _safe) internal {
        if (address(_safe) == address(0)) {
            revert SafeAddressZero();
        }
        if (address(safe()) != address(0)) {
            revert AlreadyInitialized();
        }
        assembly {
            sstore(SAFE_SLOT, _safe)
        }
    }

    error UnauthorizedNotSafe();
    /**
     * @dev Modifier to be used by derived contracts to limit access control to priviledged
     * functions so they can only be called by the Safe
     */
    modifier onlySafe() {
        if (_msgSender() != address(safe())) {
            revert UnauthorizedNotSafe();
        }

        _;
    }

    function _msgSender() internal view virtual returns (address sender); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimum viable interface of a Safe that Firm's protocol needs
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    receive() external payable;

    /**
     * @dev Allows modules to execute transactions
     * @notice Can only be called by an enabled module.
     * @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
     * @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
     */
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Returns if a certain address is an owner of this Safe
     * @return Whether the address is an owner or not
     */
    function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {BaseGuard, Enum} from "safe/base/GuardManager.sol";

import {FirmBase, ISafe, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";

import {ISemaphore} from "./interfaces/ISemaphore.sol";

/**
 * @title Semaphore
 * @author Firm ([email protected])
 * @notice Simple access control system intended to balance permissions between pairs of accounts
 * Compliant with the Safe Guard interface and designed to limit power of Safe owners via multisig txs
 */
contract Semaphore is FirmBase, BaseGuard, ISemaphore {
    string public constant moduleId = "org.firm.semaphore";
    uint256 public constant moduleVersion = 1;

    enum DefaultMode {
        Disallow,
        Allow
    }

    struct SemaphoreState {
        // Configurable state
        DefaultMode defaultMode;
        bool allowDelegateCalls;
        bool allowValueCalls;
        
        // Counters
        uint64 numTotalExceptions;
        uint32 numSigExceptions;
        uint32 numTargetExceptions;
        uint32 numTargetSigExceptions;
    } // 1 slot

    enum ExceptionType {
        Sig,
        Target,
        TargetSig
    }

    struct ExceptionInput {
        bool add;
        ExceptionType exceptionType;
        address caller;
        address target;  // only used for Target and TargetSig (ignored for Sig)
        bytes4 sig;      // only used for Sig and TargetSig (ignored for Target)
    }

    // caller => state
    mapping (address => SemaphoreState) public state;
    // caller => sig => bool (whether executing functions with this sig on any target is an exception to caller's defaultMode)
    mapping (address => mapping (bytes4 => bool)) public sigExceptions;
    // caller => target => bool (whether calling this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => bool)) public targetExceptions;
    // caller => target => sig => bool (whether executing functions with this sig on this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => mapping (bytes4 => bool))) public targetSigExceptions;

    event SemaphoreStateSet(address indexed caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls);
    event ExceptionSet(address indexed caller, bool added, ExceptionType exceptionType, address target, bytes4 sig);

    error ExceptionAlreadySet(ExceptionInput exception);

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(IMPL_INIT_NOOP_SAFE, false, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, bool safeAllowsDelegateCalls, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);

        // state[safe] represents the state when performing checks on the Safe multisig transactions checked via
        // Safe is marked as allowed by default (too dangerous to disallow by default or leave as an option)
        // Value calls are allowed by default for Safe
        _setSemaphoreState(address(safe_), DefaultMode.Allow, safeAllowsDelegateCalls, true);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // STATE AND EXCEPTIONS MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets the base state for a caller
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param defaultMode Whether calls from this caller are allowed by default
     * @param allowDelegateCalls Whether this caller is allowed to perform delegatecalls
     * @param allowValueCalls Whether this caller is allowed to perform calls with non-zero value (native asset transfers)
     */
    function setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) external onlySafe {
        _setSemaphoreState(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    function _setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) internal {
        SemaphoreState storage s = state[caller];
        s.defaultMode = defaultMode;
        s.allowDelegateCalls = allowDelegateCalls;
        s.allowValueCalls = allowValueCalls;

        emit SemaphoreStateSet(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    /**
     * @notice Adds expections to the default mode for calls
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param exceptions Array of new exceptions to be applied
     */
    function addExceptions(ExceptionInput[] calldata exceptions) external onlySafe {
        for (uint256 i = 0; i < exceptions.length;) {
            ExceptionInput memory e = exceptions[i];
            SemaphoreState storage s = state[e.caller];

            if (e.exceptionType == ExceptionType.Sig) {
                if (e.add == sigExceptions[e.caller][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                sigExceptions[e.caller][e.sig] = e.add;
                s.numSigExceptions = e.add ? s.numSigExceptions + 1 : s.numSigExceptions - 1;
            } else if (e.exceptionType == ExceptionType.Target) {
                if (e.add == targetExceptions[e.caller][e.target]) {
                    revert ExceptionAlreadySet(e);
                }
                targetExceptions[e.caller][e.target] = e.add;
                s.numTargetExceptions = e.add ? s.numTargetExceptions + 1 : s.numTargetExceptions - 1;
            } else if (e.exceptionType == ExceptionType.TargetSig) {
                if (e.add == targetSigExceptions[e.caller][e.target][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                targetSigExceptions[e.caller][e.target][e.sig] = e.add;
                s.numTargetSigExceptions = e.add ? s.numTargetSigExceptions + 1 : s.numTargetSigExceptions - 1;
            }

            // A local counter for the specific exception type + the global exception type is added for the caller
            // Since per caller we need 1 slot of storage for its config, we can keep these counters within that same slot
            // As exception checking will be much more frequent and there will be many cases without exceptions,
            // it allows us to perform checks by just reading 1 slot if there are no exceptions and 2 if there's one
            // instead of always having to read 3 different slots (different mappings) for each possible exception that could be set
            s.numTotalExceptions = e.add ? s.numTotalExceptions + 1 : s.numTotalExceptions - 1;

            emit ExceptionSet(e.caller, e.add, e.exceptionType, e.target, e.sig);

            unchecked {
                i++;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // CALL CHECKS (ISEMAPHORE)
    ////////////////////////////////////////////////////////////////////////////////

    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) public view returns (bool) {
        SemaphoreState memory s = state[caller];

        if ((isDelegateCall && !s.allowDelegateCalls) ||
            (value > 0 && !s.allowValueCalls)) {
            return false;
        }

        // If there's an exception for this call, we flip the default mode for the caller
        return isException(s, caller, target, data)
            ? s.defaultMode == DefaultMode.Disallow
            : s.defaultMode == DefaultMode.Allow;
    }

    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) public view returns (bool) {
        if (targets.length != values.length || targets.length != calldatas.length) {
            return false;
        }
        
        SemaphoreState memory s = state[caller];

        if (isDelegateCall && !s.allowDelegateCalls) {
            return false;
        }
        
        for (uint256 i = 0; i < targets.length;) {
            if (values[i] > 0 && !s.allowValueCalls) {
                return false;
            }

            bool isAllowed = isException(s, caller, targets[i], calldatas[i])
                ? s.defaultMode == DefaultMode.Disallow
                : s.defaultMode == DefaultMode.Allow;

            if (!isAllowed) {
                return false;
            }

            unchecked {
                i++;
            }
        }

        return true;
    }

    function isException(SemaphoreState memory s, address from, address target, bytes calldata data) internal view returns (bool) {
        if (s.numTotalExceptions == 0) {
            return false;
        }

        bytes4 sig = data.length >= 4 ? bytes4(data[:4]) : bytes4(0);
        return
            (s.numSigExceptions > 0 && sigExceptions[from][sig]) ||
            (s.numTargetExceptions > 0 && targetExceptions[from][target]) ||
            (s.numTargetSigExceptions > 0 && targetSigExceptions[from][target][sig]);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // SAFE GUARD COMPLIANCE
    ////////////////////////////////////////////////////////////////////////////////

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256, uint256, uint256, address, address payable, bytes memory, address
    ) external view {
        if (!canPerform(msg.sender, to, value, data, operation == Enum.Operation.DelegateCall)) {
            revert ISemaphore.SemaphoreDisallowed();
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISemaphore {
    error SemaphoreDisallowed();
    
    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) external view returns (bool);
    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) external view returns (bool);
}