/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;




struct GovernanceInfoStruct {
    mapping(address => bool) effectiveGovernors;
    address candidateGovernor;
    bool initialized;
}

abstract contract MGovernance {
    function _isGovernor(address testGovernor) internal view virtual returns (bool);

    /*
      Allows calling the function only by a Governor.
    */
    modifier onlyGovernance() {
        require(_isGovernor(msg.sender), "ONLY_GOVERNANCE");
        _;
    }
}
/*
  Holds the governance slots for ALL entities, including proxy and the main contract.
*/
contract GovernanceStorage {
    // A map from a Governor tag to its own GovernanceInfoStruct.
    mapping(string => GovernanceInfoStruct) internal governanceInfo; //NOLINT uninitialized-state.
}



abstract contract Governance is MGovernance {
    event LogNominatedGovernor(address nominatedGovernor);
    event LogNewGovernorAccepted(address acceptedGovernor);
    event LogRemovedGovernor(address removedGovernor);
    event LogNominationCancelled();

    function getGovernanceInfo() internal view virtual returns (GovernanceInfoStruct storage);

    /*
      Current code intentionally prevents governance re-initialization.
      This may be a problem in an upgrade situation, in a case that the upgrade-to implementation
      performs an initialization (for real) and within that calls initGovernance().

      Possible workarounds:
      1. Clearing the governance info altogether by changing the MAIN_GOVERNANCE_INFO_TAG.
         This will remove existing main governance information.
      2. Modify the require part in this function, so that it will exit quietly
         when trying to re-initialize (uncomment the lines below).
    */
    function initGovernance() internal {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(!gub.initialized, "ALREADY_INITIALIZED");
        gub.initialized = true; // to ensure addGovernor() won't fail.
        // Add the initial governer.
        addGovernor(msg.sender);
    }

    function _isGovernor(address testGovernor) internal view override returns (bool) {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        return gub.effectiveGovernors[testGovernor];
    }

    /*
      Cancels the nomination of a governor candidate.
    */
    function _cancelNomination() internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        gub.candidateGovernor = address(0x0);
        emit LogNominationCancelled();
    }

    function _nominateNewGovernor(address newGovernor) internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(!_isGovernor(newGovernor), "ALREADY_GOVERNOR");
        gub.candidateGovernor = newGovernor;
        emit LogNominatedGovernor(newGovernor);
    }

    /*
      The addGovernor is called in two cases:
      1. by _acceptGovernance when a new governor accepts its role.
      2. by initGovernance to add the initial governor.
      The difference is that the init path skips the nominate step
      that would fail because of the onlyGovernance modifier.
    */
    function addGovernor(address newGovernor) private {
        require(!_isGovernor(newGovernor), "ALREADY_GOVERNOR");
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        gub.effectiveGovernors[newGovernor] = true;
    }

    function _acceptGovernance() internal {
        // The new governor was proposed as a candidate by the current governor.
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(msg.sender == gub.candidateGovernor, "ONLY_CANDIDATE_GOVERNOR");

        // Update state.
        addGovernor(gub.candidateGovernor);
        gub.candidateGovernor = address(0x0);

        // Send a notification about the change of governor.
        emit LogNewGovernorAccepted(msg.sender);
    }

    /*
      Remove a governor from office.
    */
    function _removeGovernor(address governorForRemoval) internal onlyGovernance {
        require(msg.sender != governorForRemoval, "GOVERNOR_SELF_REMOVE");
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(_isGovernor(governorForRemoval), "NOT_GOVERNOR");
        gub.effectiveGovernors[governorForRemoval] = false;
        emit LogRemovedGovernor(governorForRemoval);
    }
}



/**
  The Proxy contract is governed by one or more Governors of which the initial one is the
  deployer of the contract.

  A governor has the sole authority to perform the following operations:

  1. Nominate additional governors (:sol:func:`proxyNominateNewGovernor`)
  2. Remove other governors (:sol:func:`proxyRemoveGovernor`)
  3. Add new `implementations` (proxied contracts)
  4. Remove (new or old) `implementations`
  5. Update `implementations` after a timelock allows it

  Adding governors is performed in a two step procedure:

  1. First, an existing governor nominates a new governor (:sol:func:`proxyNominateNewGovernor`)
  2. Then, the new governor must accept governance to become a governor (:sol:func:`proxyAcceptGovernance`)

  This two step procedure ensures that a governor public key cannot be nominated unless there is an
  entity that has the corresponding private key. This is intended to prevent errors in the addition
  process.

  The governor private key should typically be held in a secure cold wallet or managed via a
  multi-sig contract.
*/
/*
  Implements Governance for the proxy contract.
  It is a thin wrapper to the Governance contract,
  which is needed so that it can have non-colliding function names,
  and a specific tag (key) to allow unique state storage.
*/
contract ProxyGovernance is GovernanceStorage, Governance {
    // The tag is the string key that is used in the Governance storage mapping.
    string public constant PROXY_GOVERNANCE_TAG = "StarkEx.Proxy.2019.GovernorsInformation";

    /*
      Returns the GovernanceInfoStruct associated with the governance tag.
    */
    function getGovernanceInfo() internal view override returns (GovernanceInfoStruct storage) {
        return governanceInfo[PROXY_GOVERNANCE_TAG];
    }

    function proxyIsGovernor(address testGovernor) external view returns (bool) {
        return _isGovernor(testGovernor);
    }

    function proxyNominateNewGovernor(address newGovernor) external {
        _nominateNewGovernor(newGovernor);
    }

    function proxyRemoveGovernor(address governorForRemoval) external {
        _removeGovernor(governorForRemoval);
    }

    function proxyAcceptGovernance() external {
        _acceptGovernance();
    }

    function proxyCancelNomination() external {
        _cancelNomination();
    }
}


/**
  StorageSlots holds the arbitrary storage slots used throughout the Proxy pattern.
  Storage address slots are a mechanism to define an arbitrary location, that will not be
  overlapped by the logical contracts.
*/
contract StorageSlots {
    // Storage slot with the address of the current implementation.
    // The address of the slot is keccak256("StarkWare2019.implemntation-slot").
    // We need to keep this variable stored outside of the commonly used space,
    // so that it's not overrun by the logical implementation (the proxied contract).
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x177667240aeeea7e35eabe3a35e18306f336219e1386f7710a6bf8783f761b24;

    // Storage slot with the address of the call-proxy current implementation.
    // The address of the slot is keccak256("'StarkWare2020.CallProxy.Implemntation.Slot'").
    // We need to keep this variable stored outside of the commonly used space.
    // so that it's not overrun by the logical implementation (the proxied contract).
    bytes32 internal constant CALL_PROXY_IMPL_SLOT =
        0x7184681641399eb4ad2fdb92114857ee6ff239f94ad635a1779978947b8843be;

    // This storage slot stores the finalization flag.
    // Once the value stored in this slot is set to non-zero
    // the proxy blocks implementation upgrades.
    // The current implementation is then referred to as Finalized.
    // Web3.solidityKeccak(['string'], ["StarkWare2019.finalization-flag-slot"]).
    bytes32 internal constant FINALIZED_STATE_SLOT =
        0x7d433c6f837e8f93009937c466c82efbb5ba621fae36886d0cac433c5d0aa7d2;

    // Storage slot to hold the upgrade delay (time-lock).
    // The intention of this slot is to allow modification using an EIC.
    // Web3.solidityKeccak(['string'], ['StarkWare.Upgradibility.Delay.Slot']).
    bytes32 public constant UPGRADE_DELAY_SLOT =
        0xc21dbb3089fcb2c4f4c6a67854ab4db2b0f233ea4b21b21f912d52d18fc5db1f;
}

/*
  Common Utility librarries.
  I. Addresses (extending address).
*/
library Addresses {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function performEthTransfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}(""); // NOLINT: low-level-calls.
        require(success, "ETH_TRANSFER_FAILED");
    }

    /*
      Safe wrapper around ERC20/ERC721 calls.
      This is required because many deployed ERC20 contracts don't return a value.
      See https://github.com/ethereum/solidity/issues/4116.
    */
    function safeTokenContractCall(address tokenAddress, bytes memory callData) internal {
        require(isContract(tokenAddress), "BAD_TOKEN_ADDRESS");
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = tokenAddress.call(callData);
        require(success, string(returndata));

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "TOKEN_OPERATION_FAILED");
        }
    }

    /*
      Validates that the passed contract address is of a real contract,
      and that its id hash (as infered fromn identify()) matched the expected one.
    */
    function validateContractId(address contractAddress, bytes32 expectedIdHash) internal {
        require(isContract(contractAddress), "ADDRESS_NOT_CONTRACT");
        (bool success, bytes memory returndata) = contractAddress.call( // NOLINT: low-level-calls.
            abi.encodeWithSignature("identify()")
        );
        require(success, "FAILED_TO_IDENTIFY_CONTRACT");
        string memory realContractId = abi.decode(returndata, (string));
        require(
            keccak256(abi.encodePacked(realContractId)) == expectedIdHash,
            "UNEXPECTED_CONTRACT_IDENTIFIER"
        );
    }
}

/*
  II. StarkExTypes - Common data types.
*/
library StarkExTypes {
    // Structure representing a list of verifiers (validity/availability).
    // A statement is valid only if all the verifiers in the list agree on it.
    // Adding a verifier to the list is immediate - this is used for fast resolution of
    // any soundness issues.
    // Removing from the list is time-locked, to ensure that any user of the system
    // not content with the announced removal has ample time to leave the system before it is
    // removed.
    struct ApprovalChainData {
        address[] list;
        // Represents the time after which the verifier with the given address can be removed.
        // Removal of the verifier with address A is allowed only in the case the value
        // of unlockedForRemovalTime[A] != 0 and unlockedForRemovalTime[A] < (current time).
        mapping(address => uint256) unlockedForRemovalTime;
    }
}

/*
  Holds the Proxy-specific state variables.
  This contract is inherited by the GovernanceStorage (and indirectly by MainStorage)
  to prevent collision hazard.
*/
contract ProxyStorage is GovernanceStorage {
    // NOLINTNEXTLINE: naming-convention uninitialized-state.
    mapping(address => bytes32) internal initializationHash_DEPRECATED;

    // The time after which we can switch to the implementation.
    // Hash(implementation, data, finalize) => time.
    mapping(bytes32 => uint256) internal enabledTime;

    // A central storage of the flags whether implementation has been initialized.
    // Note - it can be used flexibly enough to accommodate multiple levels of initialization
    // (i.e. using different key salting schemes for different initialization levels).
    mapping(bytes32 => bool) internal initialized;
}



contract Proxy is ProxyStorage, ProxyGovernance, StorageSlots {
    // Emitted when the active implementation is replaced.
    event ImplementationUpgraded(address indexed implementation, bytes initializer);

    // Emitted when an implementation is submitted as an upgrade candidate and a time lock
    // is activated.
    event ImplementationAdded(address indexed implementation, bytes initializer, bool finalize);

    // Emitted when an implementation is removed from the list of upgrade candidates.
    event ImplementationRemoved(address indexed implementation, bytes initializer, bool finalize);

    // Emitted when the implementation is finalized.
    event FinalizedImplementation(address indexed implementation);

    using Addresses for address;

    string public constant PROXY_VERSION = "3.0.1";

    constructor() public {
        initGovernance();
    }

    function setUpgradeActivationDelay(uint256 delayInSeconds) private {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            sstore(slot, delayInSeconds)
        }
    }

    function getUpgradeActivationDelay() public view returns (uint256 delay) {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            delay := sload(slot)
        }
        return delay;
    }

    /*
      Returns the address of the current implementation.
    */
    // NOLINTNEXTLINE external-function.
    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    /*
      Returns true if the implementation is frozen.
      If the implementation was not assigned yet, returns false.
    */
    function implementationIsFrozen() private returns (bool) {
        address _implementation = implementation();

        // We can't call low level implementation before it's assigned. (i.e. ZERO).
        if (_implementation == address(0x0)) {
            return false;
        }

        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = _implementation.delegatecall(
            abi.encodeWithSignature("isFrozen()")
        );
        require(success, string(returndata));
        return abi.decode(returndata, (bool));
    }

    /*
      This method blocks delegation to initialize().
      Only upgradeTo should be able to delegate call to initialize().
    */
    function initialize(
        bytes calldata /*data*/
    ) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    modifier notFinalized() {
        require(isNotFinalized(), "IMPLEMENTATION_FINALIZED");
        _;
    }

    /*
      Forbids calling the function if the implementation is frozen.
      This modifier relies on the lower level (logical contract) implementation of isFrozen().
    */
    modifier notFrozen() {
        require(!implementationIsFrozen(), "STATE_IS_FROZEN");
        _;
    }

    /*
      This entry point serves only transactions with empty calldata. (i.e. pure value transfer tx).
      We don't expect to receive such, thus block them.
    */
    receive() external payable {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }

    /*
      Contract's default function. Delegates execution to the implementation contract.
      It returns back to the external caller whatever the implementation delegated code returns.
    */
    fallback() external payable {
        address _implementation = implementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

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

    /*
      Sets the implementation address of the proxy.
    */
    function setImplementation(address newImplementation) private {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    /*
      Returns true if the contract is not in the finalized state.
    */
    function isNotFinalized() public view returns (bool notFinal) {
        bytes32 slot = FINALIZED_STATE_SLOT;
        uint256 slotValue;
        assembly {
            slotValue := sload(slot)
        }
        notFinal = (slotValue == 0);
    }

    /*
      Marks the current implementation as finalized.
    */
    function setFinalizedFlag() private {
        bytes32 slot = FINALIZED_STATE_SLOT;
        assembly {
            sstore(slot, 0x1)
        }
    }

    /*
      Introduce an implementation and its initialization vector,
      and start the time-lock before it can be upgraded to.
      addImplementation is not blocked when frozen or finalized.
      (upgradeTo API is blocked when finalized or frozen).
    */
    function addImplementation(
        address newImplementation,
        bytes calldata data,
        bool finalize
    ) external onlyGovernance {
        require(newImplementation.isContract(), "ADDRESS_NOT_CONTRACT");

        bytes32 implVectorHash = keccak256(abi.encode(newImplementation, data, finalize));

        uint256 activationTime = block.timestamp + getUpgradeActivationDelay();

        enabledTime[implVectorHash] = activationTime;
        emit ImplementationAdded(newImplementation, data, finalize);
    }

    /*
      Removes a candidate implementation.
      Note that it is possible to remove the current implementation. Doing so doesn't affect the
      current implementation, but rather revokes it as a future candidate.
    */
    function removeImplementation(
        address removedImplementation,
        bytes calldata data,
        bool finalize
    ) external onlyGovernance {
        bytes32 implVectorHash = keccak256(abi.encode(removedImplementation, data, finalize));

        // If we have initializer, we set the hash of it.
        uint256 activationTime = enabledTime[implVectorHash];
        require(activationTime > 0, "UNKNOWN_UPGRADE_INFORMATION");
        delete enabledTime[implVectorHash];
        emit ImplementationRemoved(removedImplementation, data, finalize);
    }

    /*
      Upgrades the proxy to a new implementation, with its initialization.
      to upgrade successfully, implementation must have been added time-lock agreeably
      before, and the init vector must be identical ot the one submitted before.

      Upon assignment of new implementation address,
      its initialize will be called with the initializing vector (even if empty).
      Therefore, the implementation MUST must have such a method.

      Note - Initialization data is committed to in advance, therefore it must remain valid
      until the actual contract upgrade takes place.

      Care should be taken regarding initialization data and flow when planning the contract upgrade.

      When planning contract upgrade, special care is also needed with regard to governance
      (See comments in Governance.sol).
    */
    // NOLINTNEXTLINE: reentrancy-events timestamp.
    function upgradeTo(
        address newImplementation,
        bytes calldata data,
        bool finalize
    ) external payable onlyGovernance notFinalized notFrozen {
        bytes32 implVectorHash = keccak256(abi.encode(newImplementation, data, finalize));
        uint256 activationTime = enabledTime[implVectorHash];
        require(activationTime > 0, "UNKNOWN_UPGRADE_INFORMATION");
        require(newImplementation.isContract(), "ADDRESS_NOT_CONTRACT");

        // On the first time an implementation is set - time-lock should not be enforced.
        require(
            activationTime <= block.timestamp || implementation() == address(0x0),
            "UPGRADE_NOT_ENABLED_YET"
        );

        setImplementation(newImplementation);

        // NOLINTNEXTLINE: low-level-calls controlled-delegatecall.
        (bool success, bytes memory returndata) = newImplementation.delegatecall(
            abi.encodeWithSelector(this.initialize.selector, data)
        );
        require(success, string(returndata));

        // Verify that the new implementation is not frozen post initialization.
        // NOLINTNEXTLINE: low-level-calls controlled-delegatecall.
        (success, returndata) = newImplementation.delegatecall(
            abi.encodeWithSignature("isFrozen()")
        );
        require(success, "CALL_TO_ISFROZEN_REVERTED");
        require(!abi.decode(returndata, (bool)), "NEW_IMPLEMENTATION_FROZEN");

        if (finalize) {
            setFinalizedFlag();
            emit FinalizedImplementation(newImplementation);
        }

        emit ImplementationUpgraded(newImplementation, data);
    }
}