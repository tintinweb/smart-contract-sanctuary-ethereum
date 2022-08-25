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

import "./ApprovalChain.sol";
import "./AvailabilityVerifiers.sol";
import "./Freezable.sol";
import "./MainGovernance.sol";
import "./Verifiers.sol";
import "./SubContractor.sol";

contract AllVerifiers is
    SubContractor,
    MainGovernance,
    Freezable,
    ApprovalChain,
    AvailabilityVerifiers,
    Verifiers
{
    function initialize(
        bytes calldata /* data */
    ) external override {
        revert("NOT_IMPLEMENTED");
    }

    function initializerSize() external view override returns (uint256) {
        return 0;
    }

    function validatedSelectors() external pure override returns (bytes4[] memory selectors) {
        uint256 len_ = 1;
        uint256 index_ = 0;

        selectors = new bytes4[](len_);
        selectors[index_++] = Freezable.unFreeze.selector;
        require(index_ == len_, "INCORRECT_SELECTORS_ARRAY_LENGTH");
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_AllVerifiers_2022_2";
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

import "./MainStorage.sol";
import "./IFactRegistry.sol";
import "./IQueryableFactRegistry.sol";
import "./Identity.sol";
import "./MApprovalChain.sol";
import "./MFreezable.sol";
import "./MGovernance.sol";
import "./Addresses.sol";
import {ApprovalChainData} from "./StarkExTypes.sol";

/*
  Implements a data structure that supports instant registration
  and slow time-locked removal of entries.
*/
abstract contract ApprovalChain is MainStorage, MApprovalChain, MGovernance, MFreezable {
    using Addresses for address;

    event LogRemovalIntent(address entry, string entryId);
    event LogRegistered(address entry, string entryId);
    event LogRemoved(address entry, string entryId);

    function addEntry(
        ApprovalChainData storage chain,
        address entry,
        uint256 maxLength,
        string memory identifier
    ) internal override onlyGovernance notFrozen {
        address[] storage verifiers = chain.verifiers;
        require(entry.isContract(), "ADDRESS_NOT_CONTRACT");
        bytes32 hash_real = keccak256(abi.encodePacked(Identity(entry).identify()));
        bytes32 hash_identifier = keccak256(abi.encodePacked(identifier));
        require(hash_real == hash_identifier, "UNEXPECTED_CONTRACT_IDENTIFIER");
        require(verifiers.length < maxLength, "CHAIN_AT_MAX_CAPACITY");
        require(findEntry(verifiers, entry) == ENTRY_NOT_FOUND, "ENTRY_ALREADY_EXISTS");

        // Verifier must have at least one fact registered before adding to chain,
        // unless it's the first verifier in the chain.
        require(
            verifiers.length == 0 || IQueryableFactRegistry(entry).hasRegisteredFact(),
            "ENTRY_NOT_ENABLED"
        );
        chain.verifiers.push(entry);
        emit LogRegistered(entry, identifier);
    }

    function findEntry(address[] storage verifiers, address entry)
        internal
        view
        override
        returns (uint256)
    {
        uint256 n_entries = verifiers.length;
        for (uint256 i = 0; i < n_entries; i++) {
            if (verifiers[i] == entry) {
                return i;
            }
        }

        return ENTRY_NOT_FOUND;
    }

    function safeFindEntry(address[] storage verifiers, address entry)
        internal
        view
        override
        returns (uint256 idx)
    {
        idx = findEntry(verifiers, entry);

        require(idx != ENTRY_NOT_FOUND, "ENTRY_DOES_NOT_EXIST");
    }

    function announceRemovalIntent(
        ApprovalChainData storage chain,
        address entry,
        uint256 removalDelay
    ) internal override onlyGovernance notFrozen {
        safeFindEntry(chain.verifiers, entry);
        require(block.timestamp + removalDelay > block.timestamp, "INVALID_REMOVAL_DELAY");
        require(chain.verifierAllowedRemovalTime[entry] == 0, "ALREADY_ANNOUNCED");

        chain.verifierAllowedRemovalTime[entry] = block.timestamp + removalDelay;
        emit LogRemovalIntent(entry, Identity(entry).identify());
    }

    function removeEntry(ApprovalChainData storage chain, address entry)
        internal
        override
        onlyGovernance
        notFrozen
    {
        address[] storage verifiers = chain.verifiers;
        // Make sure entry exists.
        uint256 idx = safeFindEntry(verifiers, entry);
        uint256 verifierAllowedRemovalTime = chain.verifierAllowedRemovalTime[entry];

        require(verifierAllowedRemovalTime > 0, "REMOVAL_NOT_ANNOUNCED");
        require(block.timestamp >= verifierAllowedRemovalTime, "REMOVAL_NOT_ENABLED_YET");

        uint256 n_entries = verifiers.length;

        // Removal of last entry is forbidden.
        require(n_entries > 1, "LAST_ENTRY_MAY_NOT_BE_REMOVED");

        if (idx != n_entries - 1) {
            verifiers[idx] = verifiers[n_entries - 1];
        }
        verifiers.pop();
        delete chain.verifierAllowedRemovalTime[entry];
        emit LogRemoved(entry, Identity(entry).identify());
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

import "./ProxyStorage.sol";
import "./Addresses.sol";
import {ApprovalChainData} from "./StarkExTypes.sol";

/*
  Holds ALL the main contract state (storage) variables.
*/
contract MainStorage is ProxyStorage {
    uint256 internal constant LAYOUT_LENGTH = 2**64;

    address escapeVerifierAddress; // NOLINT: constable-states.

    // Global dex-frozen flag.
    bool stateFrozen; // NOLINT: constable-states.

    // Time when unFreeze can be successfully called (UNFREEZE_DELAY after freeze).
    uint256 unFreezeTime; // NOLINT: constable-states.

    // Pending deposits.
    // A map STARK key => asset id => vault id => quantized amount.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) pendingDeposits;

    // Cancellation requests.
    // A map STARK key => asset id => vault id => request timestamp.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) cancellationRequests;

    // Pending withdrawals.
    // A map STARK key => asset id => quantized amount.
    mapping(uint256 => mapping(uint256 => uint256)) pendingWithdrawals;

    // vault_id => escape used boolean.
    mapping(uint256 => bool) escapesUsed;

    // Number of escapes that were performed when frozen.
    uint256 escapesUsedCount; // NOLINT: constable-states.

    // NOTE: fullWithdrawalRequests is deprecated, and replaced by forcedActionRequests.
    // NOLINTNEXTLINE naming-convention.
    mapping(uint256 => mapping(uint256 => uint256)) fullWithdrawalRequests_DEPRECATED;

    // State sequence number.
    uint256 sequenceNumber; // NOLINT: constable-states uninitialized-state.

    // Validium Vaults Tree Root & Height.
    uint256 validiumVaultRoot; // NOLINT: constable-states uninitialized-state.
    uint256 validiumTreeHeight; // NOLINT: constable-states uninitialized-state.

    // Order Tree Root & Height.
    uint256 orderRoot; // NOLINT: constable-states uninitialized-state.
    uint256 orderTreeHeight; // NOLINT: constable-states uninitialized-state.

    // True if and only if the address is allowed to add tokens.
    mapping(address => bool) tokenAdmins;

    // This mapping is no longer in use, remains for backwards compatibility.
    mapping(address => bool) userAdmins_DEPRECATED; // NOLINT: naming-convention.

    // True if and only if the address is an operator (allowed to update state).
    mapping(address => bool) operators; // NOLINT: uninitialized-state.

    // Mapping of contract ID to asset data.
    mapping(uint256 => bytes) assetTypeToAssetInfo; // NOLINT: uninitialized-state.

    // Mapping of registered contract IDs.
    mapping(uint256 => bool) registeredAssetType; // NOLINT: uninitialized-state.

    // Mapping from contract ID to quantum.
    mapping(uint256 => uint256) assetTypeToQuantum; // NOLINT: uninitialized-state.

    // This mapping is no longer in use, remains for backwards compatibility.
    mapping(address => uint256) starkKeys_DEPRECATED; // NOLINT: naming-convention.

    // Mapping from STARK public key to the Ethereum public key of its owner.
    mapping(uint256 => address) ethKeys; // NOLINT: uninitialized-state.

    // Timelocked state transition and availability verification chain.
    ApprovalChainData verifiersChain;
    ApprovalChainData availabilityVerifiersChain;

    // Batch id of last accepted proof.
    uint256 lastBatchId; // NOLINT: constable-states uninitialized-state.

    // Mapping between sub-contract index to sub-contract address.
    mapping(uint256 => address) subContracts; // NOLINT: uninitialized-state.

    mapping(uint256 => bool) permissiveAssetType_DEPRECATED; // NOLINT: naming-convention.
    // ---- END OF MAIN STORAGE AS DEPLOYED IN STARKEX2.0 ----

    // Onchain-data version configured for the system.
    uint256 onchainDataVersion_DEPRECATED; // NOLINT: naming-convention constable-states.

    // Counter of forced action request in block. The key is the block number.
    mapping(uint256 => uint256) forcedRequestsInBlock;

    // ForcedAction requests: actionHash => requestTime.
    mapping(bytes32 => uint256) forcedActionRequests;

    // Mapping for timelocked actions.
    // A actionKey => activation time.
    mapping(bytes32 => uint256) actionsTimeLock;

    // Append only list of requested forced action hashes.
    bytes32[] actionHashList;
    // ---- END OF MAIN STORAGE AS DEPLOYED IN STARKEX3.0 ----
    // ---- END OF MAIN STORAGE AS DEPLOYED IN STARKEX4.0 ----

    // Rollup Vaults Tree Root & Height.
    uint256 rollupVaultRoot; // NOLINT: constable-states uninitialized-state.
    uint256 rollupTreeHeight; // NOLINT: constable-states uninitialized-state.

    uint256 globalConfigCode; // NOLINT: constable-states uninitialized-state.

    // Reserved storage space for Extensibility.
    // Every added MUST be added above the end gap, and the __endGap size must be reduced
    // accordingly.
    // NOLINTNEXTLINE: naming-convention.
    uint256[LAYOUT_LENGTH - 40] private __endGap; // __endGap complements layout to LAYOUT_LENGTH.
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

import "./GovernanceStorage.sol";

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
import {GovernanceInfoStruct} from "./Governance.sol";

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

import "./MGovernance.sol";

/*
  Implements Generic Governance, applicable for both proxy and main contract, and possibly others.
  Notes:
   The use of the same function names by both the Proxy and a delegated implementation
   is not possible since calling the implementation functions is done via the default function
   of the Proxy. For this reason, for example, the implementation of MainContract (MainGovernance)
   exposes mainIsGovernor, which calls the internal _isGovernor method.
*/
struct GovernanceInfoStruct {
    mapping(address => bool) effectiveGovernors;
    address candidateGovernor;
    bool initialized;
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

        // Emit governance information.
        emit LogNominatedGovernor(msg.sender);
        emit LogNewGovernorAccepted(msg.sender);
    }

    function _isGovernor(address user) internal view override returns (bool) {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        return gub.effectiveGovernors[user];
    }

    /*
      Cancels the nomination of a governor candidate.
    */
    function _cancelNomination() internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        if (gub.candidateGovernor != address(0x0)) {
            gub.candidateGovernor = address(0x0);
            emit LogNominationCancelled();
        }
    }

    function _nominateNewGovernor(address newGovernor) internal onlyGovernance {
        GovernanceInfoStruct storage gub = getGovernanceInfo();
        require(newGovernor != address(0x0), "BAD_ADDRESS");
        require(!_isGovernor(newGovernor), "ALREADY_GOVERNOR");
        require(gub.candidateGovernor == address(0x0), "OTHER_CANDIDATE_PENDING");
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

abstract contract MGovernance {
    function _isGovernor(address user) internal view virtual returns (bool);

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

/*
  Common Utility Libraries.
  I. Addresses (extending address).
*/
library Addresses {
    /*
      Note: isContract function has some known limitation.
      See https://github.com/OpenZeppelin/
      openzeppelin-contracts/blob/master/contracts/utils/Address.sol.
    */
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

// Structure representing a list of verifiers (validity/availability).
// A statement is valid only if all the verifiers in the list agree on it.
// Adding a verifier to the list is immediate - this is used for fast resolution of
// any soundness issues.
// Removing a verifier from the list is time-locked, to ensure that any user of the system
// not content with the announced removal has ample time to leave the system before it is
// removed.
struct ApprovalChainData {
    address[] verifiers;
    // Represents the time after which the verifier with the given address can be removed.
    // Removal of the verifier with address A is allowed only in the case the value
    // of verifierAllowedRemovalTime[A] != 0 and verifierAllowedRemovalTime[A] < (current time).
    mapping(address => uint256) verifierAllowedRemovalTime;
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

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);
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

import "./IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {
    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact() external view returns (bool);
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
      Allows a caller to ensure that the provided address is of the expected type and version.
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

import {ApprovalChainData} from "./StarkExTypes.sol";

/*
  Implements a data structure that supports instant registration
  and slow time-locked removal of entries.
*/
abstract contract MApprovalChain {
    uint256 constant ENTRY_NOT_FOUND = uint256(~0);

    /*
      Adds the given verifier (entry) to the chain.
      Fails if the size of the chain is already >= maxLength.
      Fails if identifier is not identical to the value returned from entry.identify().
    */
    function addEntry(
        ApprovalChainData storage chain,
        address entry,
        uint256 maxLength,
        string memory identifier
    ) internal virtual;

    /*
      Returns the index of the verifier in the list if it exists and returns ENTRY_NOT_FOUND
      otherwise.
    */
    function findEntry(address[] storage verifiers, address entry)
        internal
        view
        virtual
        returns (uint256);

    /*
      Same as findEntry(), except that it reverts if the verifier is not found.
    */
    function safeFindEntry(address[] storage verifiers, address entry)
        internal
        view
        virtual
        returns (uint256 idx);

    /*
      Updates the verifierAllowedRemovalTime field of the given verifier to
        current time + removalDelay.
      Reverts if the verifier is not found.
    */
    function announceRemovalIntent(
        ApprovalChainData storage chain,
        address entry,
        uint256 removalDelay
    ) internal virtual;

    /*
      Removes a verifier assuming the expected time has passed.
    */
    function removeEntry(ApprovalChainData storage chain, address entry) internal virtual;
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

abstract contract MFreezable {
    /*
      Returns true if the exchange is frozen.
    */
    function isFrozen() public view virtual returns (bool); // NOLINT: external-function.

    /*
      Forbids calling the function if the exchange is frozen.
    */
    modifier notFrozen() {
        require(!isFrozen(), "STATE_IS_FROZEN");
        _;
    }

    function validateFreezeRequest(uint256 requestTime) internal virtual;

    /*
      Allows calling the function only if the exchange is frozen.
    */
    modifier onlyFrozen() {
        require(isFrozen(), "STATE_NOT_FROZEN");
        _;
    }

    /*
      Freezes the exchange.
    */
    function freeze() internal virtual;
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

import "./MApprovalChain.sol";
import "./LibConstants.sol";
import "./MainStorage.sol";

/**
  A :sol:mod:`Committee` contract is a contract that the exchange service sends committee member
  signatures to attesting that they have a copy of the data over which a new Merkel root is to be
  accepted as the new state root. In addition, the exchange contract can call an availability
  verifier to check if such signatures were indeed provided by a sufficient number of committee
  members as hard coded in the :sol:mod:`Committee` contract for a given state transition
  (as reflected by the old and new vault and order roots).

  The exchange contract will normally query only one :sol:mod:`Committee` contract for data
  availability checks. However, in the event that the committee needs to be updated, additional
  availability verifiers may be registered with the exchange contract by the
  contract :sol:mod:`MainGovernance`. Such new availability verifiers are then also be required to
  attest to the data availability for state transitions and only if all the availability verifiers
  attest to it, the state transition is accepted.

  Removal of availability verifiers is also the responsibility of the :sol:mod:`MainGovernance`.
  The removal process is more sensitive than availability verifier registration as it may affect the
  soundness of the system. Hence, this is performed in two steps:

  1. The :sol:mod:`MainGovernance` first announces the intent to remove an availability verifier by calling :sol:func:`announceAvailabilityVerifierRemovalIntent`
  2. After the expiration of a `VERIFIER_REMOVAL_DELAY` time lock, actual removal may be performed by calling :sol:func:`removeAvailabilityVerifier`

  The removal delay ensures that a user concerned about the soundness of the system has ample time
  to leave the exchange.
*/
abstract contract AvailabilityVerifiers is MainStorage, LibConstants, MApprovalChain {
    function getRegisteredAvailabilityVerifiers()
        external
        view
        returns (address[] memory _verifers)
    {
        return availabilityVerifiersChain.verifiers;
    }

    function isAvailabilityVerifier(address verifierAddress) external view returns (bool) {
        return findEntry(availabilityVerifiersChain.verifiers, verifierAddress) != ENTRY_NOT_FOUND;
    }

    function registerAvailabilityVerifier(address verifier, string calldata identifier) external {
        addEntry(availabilityVerifiersChain, verifier, MAX_VERIFIER_COUNT, identifier);
    }

    function announceAvailabilityVerifierRemovalIntent(address verifier) external {
        announceRemovalIntent(availabilityVerifiersChain, verifier, VERIFIER_REMOVAL_DELAY);
    }

    function removeAvailabilityVerifier(address verifier) external {
        removeEntry(availabilityVerifiersChain, verifier);
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

contract LibConstants {
    // Durations for time locked mechanisms (in seconds).
    // Note that it is known that miners can manipulate block timestamps
    // up to a deviation of a few seconds.
    // This mechanism should not be used for fine grained timing.

    // The time required to cancel a deposit, in the case the operator does not move the funds
    // to the off-chain storage.
    uint256 public constant DEPOSIT_CANCEL_DELAY = 2 days;

    // The time required to freeze the exchange, in the case the operator does not execute a
    // requested full withdrawal.
    uint256 public constant FREEZE_GRACE_PERIOD = 7 days;

    // The time after which the exchange may be unfrozen after it froze. This should be enough time
    // for users to perform escape hatches to get back their funds.
    uint256 public constant UNFREEZE_DELAY = 365 days;

    // Maximal number of verifiers which may co-exist.
    uint256 public constant MAX_VERIFIER_COUNT = uint256(64);

    // The time required to remove a verifier in case of a verifier upgrade.
    uint256 public constant VERIFIER_REMOVAL_DELAY = FREEZE_GRACE_PERIOD + (21 days);

    address constant ZERO_ADDRESS = address(0x0);

    uint256 constant K_MODULUS = 0x800000000000011000000000000000000000000000000000000000000000001;

    uint256 constant K_BETA = 0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;

    uint256 internal constant MASK_250 =
        0x03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant MASK_240 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 public constant MAX_FORCED_ACTIONS_REQS_PER_BLOCK = 10;

    uint256 constant QUANTUM_UPPER_BOUND = 2**128;
    uint256 internal constant MINTABLE_ASSET_ID_FLAG = 1 << 250;

    // The 64th bit (indexed 63, counting from 0) is a flag indicating a rollup vault id.
    uint256 constant ROLLUP_VAULTS_BIT = 63;
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

import "./LibConstants.sol";
import "./MFreezable.sol";
import "./MGovernance.sol";
import "./MainStorage.sol";

/*
  Implements MFreezable.
*/
abstract contract Freezable is MainStorage, LibConstants, MGovernance, MFreezable {
    event LogFrozen();
    event LogUnFrozen();

    function isFrozen() public view override returns (bool) {
        return stateFrozen;
    }

    function validateFreezeRequest(uint256 requestTime) internal override {
        require(requestTime != 0, "FORCED_ACTION_UNREQUESTED");
        // Verify timer on escape request.
        uint256 freezeTime = requestTime + FREEZE_GRACE_PERIOD;

        // Prevent wraparound.
        assert(freezeTime >= FREEZE_GRACE_PERIOD);
        require(block.timestamp >= freezeTime, "FORCED_ACTION_PENDING"); // NOLINT: timestamp.

        // Forced action requests placed before freeze, are no longer valid after the un-freeze.
        require(freezeTime > unFreezeTime, "REFREEZE_ATTEMPT");
    }

    function freeze() internal override notFrozen {
        unFreezeTime = block.timestamp + UNFREEZE_DELAY;

        // Update state.
        stateFrozen = true;

        // Log event.
        emit LogFrozen();
    }

    function unFreeze() external onlyFrozen onlyGovernance {
        require(block.timestamp >= unFreezeTime, "UNFREEZE_NOT_ALLOWED_YET");

        // Update state.
        stateFrozen = false;

        // Increment roots to invalidate them, w/o losing information.
        validiumVaultRoot += 1;
        rollupVaultRoot += 1;
        orderRoot += 1;

        // Log event.
        emit LogUnFrozen();
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

import "./Governance.sol";
import "./GovernanceStorage.sol";

/**
  The StarkEx contract is governed by one or more Governors of which the initial one is the
  deployer of the contract.

  A governor has the sole authority to perform the following operations:

  1. Nominate additional governors (:sol:func:`mainNominateNewGovernor`)
  2. Remove other governors (:sol:func:`mainRemoveGovernor`)
  3. Add new :sol:mod:`Verifiers` and :sol:mod:`AvailabilityVerifiers`
  4. Remove :sol:mod:`Verifiers` and :sol:mod:`AvailabilityVerifiers` after a timelock allows it
  5. Nominate Operators (see :sol:mod:`Operator`) and Token Administrators (see :sol:mod:`TokenRegister`)

  Adding governors is performed in a two step procedure:

  1. First, an existing governor nominates a new governor (:sol:func:`mainNominateNewGovernor`)
  2. Then, the new governor must accept governance to become a governor (:sol:func:`mainAcceptGovernance`)

  This two step procedure ensures that a governor public key cannot be nominated unless there is an
  entity that has the corresponding private key. This is intended to prevent errors in the addition
  process.

  The governor private key should typically be held in a secure cold wallet.
*/
/*
  Implements Governance for the StarkDex main contract.
  The wrapper methods (e.g. mainIsGovernor wrapping _isGovernor) are needed to give
  the method unique names.
  Both Proxy and StarkExchange inherit from Governance. Thus, the logical contract method names
  must have unique names in order for the proxy to successfully delegate to them.
*/
contract MainGovernance is GovernanceStorage, Governance {
    // The tag is the sting key that is used in the Governance storage mapping.
    string public constant MAIN_GOVERNANCE_INFO_TAG = "StarkEx.Main.2019.GovernorsInformation";

    /*
      Returns the GovernanceInfoStruct associated with the governance tag.
    */
    function getGovernanceInfo() internal view override returns (GovernanceInfoStruct storage) {
        return governanceInfo[MAIN_GOVERNANCE_INFO_TAG];
    }

    function mainIsGovernor(address user) external view returns (bool) {
        return _isGovernor(user);
    }

    function mainNominateNewGovernor(address newGovernor) external {
        _nominateNewGovernor(newGovernor);
    }

    function mainRemoveGovernor(address governorForRemoval) external {
        _removeGovernor(governorForRemoval);
    }

    function mainAcceptGovernance() external {
        _acceptGovernance();
    }

    function mainCancelNomination() external {
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

import "./MApprovalChain.sol";
import "./LibConstants.sol";
import "./MainStorage.sol";

/**
  A Verifier contract is an implementation of a STARK verifier that the exchange service sends
  STARK proofs to. In addition, the exchange contract can call a verifier to check if a valid proof
  has been accepted for a given state transition (typically described as a hash on the public input
  of the assumed proof).

  The exchange contract will normally query only one verifier contract for proof validity checks.
  However, in the event that the verifier algorithm needs to updated, additional verifiers may be
  registered with the exchange contract by the contract :sol:mod:`MainGovernance`. Such new
  verifiers are then also be required to attest to the validity of state transitions and only if all
  the verifiers attest to the validity the state transition is accepted.

  Removal of verifiers is also the responsibility of the :sol:mod:`MainGovernance`. The removal
  process is more sensitive than verifier registration as it may affect the soundness of the system.
  Hence, this is performed in two steps:

  1. The :sol:mod:`MainGovernance` first announces the intent to remove a verifier by calling :sol:func:`announceVerifierRemovalIntent`
  2. After the expiration of a `VERIFIER_REMOVAL_DELAY` time lock, actual removal may be performed by calling :sol:func:`removeVerifier`

  The removal delay ensures that a user concerned about the soundness of the system has ample time
  to leave the exchange.
*/
abstract contract Verifiers is MainStorage, LibConstants, MApprovalChain {
    function getRegisteredVerifiers() external view returns (address[] memory _verifers) {
        return verifiersChain.verifiers;
    }

    function isVerifier(address verifierAddress) external view returns (bool) {
        return findEntry(verifiersChain.verifiers, verifierAddress) != ENTRY_NOT_FOUND;
    }

    function registerVerifier(address verifier, string calldata identifier) external {
        addEntry(verifiersChain, verifier, MAX_VERIFIER_COUNT, identifier);
    }

    function announceVerifierRemovalIntent(address verifier) external {
        announceRemovalIntent(verifiersChain, verifier, VERIFIER_REMOVAL_DELAY);
    }

    function removeVerifier(address verifier) external {
        removeEntry(verifiersChain, verifier);
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

import "./Identity.sol";

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