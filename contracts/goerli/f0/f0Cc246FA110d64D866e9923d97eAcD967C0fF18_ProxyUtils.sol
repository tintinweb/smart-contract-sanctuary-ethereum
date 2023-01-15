/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "MGovernance.sol";

/*
  Implements Generic Governance, applicable for both proxy and main contract, and possibly others.
  Notes:
   The use of the same function names by both the Proxy and a delegated implementation
   is not possible since calling the implementation functions is done via the default function
   of the Proxy. For this reason, for example, the implementation of MainContract (MainGovernance)
   exposes mainIsGovernor, which calls the internal _isGovernor method.
*/
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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;
import "MGovernance.sol";

/*
  Holds the governance slots for ALL entities, including proxy and the main contract.
*/
contract GovernanceStorage {
    // A map from a Governor tag to its own GovernanceInfoStruct.
    mapping(string => GovernanceInfoStruct) internal governanceInfo; //NOLINT uninitialized-state.
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface Identity {
    /*
      Allows a caller, typically another contract,
      to ensure that the provided address is of the expected type and version.
    */
    function identify() external pure returns (string memory);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
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
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Governance.sol";
import "GovernanceStorage.sol";

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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "GovernanceStorage.sol";

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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "SubContractor.sol";
import "ProxyGovernance.sol";
import "ProxyStorage.sol";
import "StorageSlots.sol";

contract ProxyUtils is SubContractor, StorageSlots, ProxyGovernance, ProxyStorage {
    event ImplementationActivationRescheduled(
        address indexed implementation,
        uint256 updatedActivationTime
    );

    function initialize(
        bytes calldata /* data */
    ) external override {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize() external view override returns (uint256) {
        return 0;
    }

    function storedActivationDelay() internal view returns (uint256 delay) {
        bytes32 slot = UPGRADE_DELAY_SLOT;
        assembly {
            delay := sload(slot)
        }
        return delay;
    }

    function updateImplementationActivationTime(
        address implementation,
        bytes calldata data,
        bool finalize
    ) external onlyGovernance {
        uint256 updatedActivationTime = block.timestamp + storedActivationDelay();

        // We assume the Proxy is of the old format.
        bytes32 oldFormatInitHash = keccak256(abi.encode(data, finalize));
        require(
            initializationHash_DEPRECATED[implementation] == oldFormatInitHash,
            "IMPLEMENTATION_NOT_PENDING"
        );

        // Converting address to bytes32 to match the mapping key type.
        bytes32 implementationKey;
        assembly {
            implementationKey := implementation
        }
        uint256 pendingActivationTime = enabledTime[implementationKey];

        require(pendingActivationTime > 0, "IMPLEMENTATION_NOT_PENDING");

        // Current value is checked to be within a reasonable delay. If it's over 6 months from now,
        // it's assumed that the activation time is configured under a different set of rules.
        require(
            pendingActivationTime < block.timestamp + 180 days,
            "INVALID_PENDING_ACTIVATION_TIME"
        );

        if (updatedActivationTime < pendingActivationTime) {
            enabledTime[implementationKey] = updatedActivationTime;
            emit ImplementationActivationRescheduled(implementation, updatedActivationTime);
        }
    }

    function validatedSelectors() external pure override returns (bytes4[] memory selectors) {
        // This sub-contract has no selectors to validate.
        selectors = new bytes4[](0);
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_ProxyUtils_2022_2";
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

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
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Identity.sol";

interface SubContractor is Identity {
    function initialize(bytes calldata data) external;

    function initializerSize() external view returns (uint256);

    /*
      Returns an array with selectors for validation.
      These selectors are the critical ones for maintaining self custody and anti censorship.
      During the upgrade process, as part of the sub-contract validation, the MainDispatcher
      validates that the selectos are mapped to the correct sub-contract.
    */
    function validatedSelectors() external pure returns (bytes4[] memory);
}