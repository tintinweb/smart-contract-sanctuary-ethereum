// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// @title Bank interface
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank {
    /// @notice returns the token used internally
    function getToken() external view returns (IERC20);

    /// @notice get balance of `_owner`
    /// @param _owner account owner
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice transfer `_value` tokens from bank to `_to`
    /// @notice decrease the balance of caller by `_value`
    /// @param _to account that will receive `_value` tokens
    /// @param _value amount of tokens to be transfered
    function transferTokens(address _to, uint256 _value) external;

    /// @notice transfer `_value` tokens from caller to bank
    /// @notice increase the balance of `_to` by `_value`
    /// @dev you may need to call `token.approve(bank, _value)`
    /// @param _to account that will have their balance increased by `_value`
    /// @param _value amount of tokens to be transfered
    function depositTokens(address _to, uint256 _value) external;

    /// @notice `value` tokens were transfered from the bank to `to`
    /// @notice the balance of `from` was decreased by `value`
    /// @dev is triggered on any successful call to `transferTokens`
    /// @param from the account/contract that called `transferTokens` and
    ///              got their balance decreased by `value`
    /// @param to the one that received `value` tokens from the bank
    /// @param value amount of tokens that were transfered
    event Transfer(address indexed from, address to, uint256 value);

    /// @notice `value` tokens were transfered from `from` to bank
    /// @notice the balance of `to` was increased by `value`
    /// @dev is triggered on any successful call to `depositTokens`
    /// @param from the account/contract that called `depositTokens` and
    ///              transfered `value` tokens to the bank
    /// @param to the one that got their balance increased by `value`
    /// @param value amount of tokens that were transfered
    event Deposit(address from, address indexed to, uint256 value);
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Rollups facet
pragma solidity ^0.8.0;

import {IRollups, Phase} from "../interfaces/IRollups.sol";
import {Result} from "../interfaces/IValidatorManager.sol";

import {LibRollups} from "../libraries/LibRollups.sol";
import {LibInput} from "../libraries/LibInput.sol";
import {LibOutput} from "../libraries/LibOutput.sol";
import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";

contract RollupsFacet is IRollups {
    ////
    //                             All claims agreed OR challenge period ended
    //                              functions: claim() or finalizeEpoch()
    //                        +--------------------------------------------------+
    //                        |                                                  |
    //               +--------v-----------+   new input after IPAD     +---------+----------+
    //               |                    +--------------------------->+                    |
    //   START  ---> | Input Accumulation |   firt claim after IPAD    | Awaiting Consensus |
    //               |                    +--------------------------->+                    |
    //               +-+------------------+                            +-----------------+--+
    //                 ^                                                                 ^  |
    //                 |                                              dispute resolved   |  |
    //                 |  dispute resolved                            before challenge   |  |
    //                 |  after challenge     +--------------------+  period ended       |  |
    //                 |  period ended        |                    +---------------------+  |
    //                 +----------------------+  Awaiting Dispute  |                        |
    //                                        |                    +<-----------------------+
    //                                        +--------------------+    conflicting claim
    ///

    using LibRollups for LibRollups.DiamondStorage;
    using LibInput for LibInput.DiamondStorage;
    using LibOutput for LibOutput.DiamondStorage;
    using LibValidatorManager for LibValidatorManager.DiamondStorage;

    /// @notice claim the result of current epoch
    /// @param _epochHash hash of epoch
    /// @dev ValidatorManager makes sure that msg.sender is allowed
    ///      and that claim != bytes32(0)
    /// TODO: add signatures for aggregated claims
    function claim(bytes32 _epochHash) public override {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        LibInput.DiamondStorage storage inputDS = LibInput.diamondStorage();
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();

        Result result;
        bytes32[2] memory claims;
        address payable[2] memory claimers;

        Phase currentPhase = Phase(rollupsDS.currentPhase_int);
        uint256 inputAccumulationStart = rollupsDS.inputAccumulationStart;
        uint256 inputDuration = rollupsDS.inputDuration;

        if (
            currentPhase == Phase.InputAccumulation &&
            block.timestamp > inputAccumulationStart + inputDuration
        ) {
            currentPhase = Phase.AwaitingConsensus;
            rollupsDS.currentPhase_int = uint32(Phase.AwaitingConsensus);
            emit PhaseChange(Phase.AwaitingConsensus);

            // warns input of new epoch
            inputDS.onNewInputAccumulation();
            // update timestamp of sealing epoch proposal
            rollupsDS.sealingEpochTimestamp = uint32(block.timestamp);
        }

        require(
            currentPhase == Phase.AwaitingConsensus,
            "Phase != AwaitingConsensus"
        );
        (result, claims, claimers) = validatorManagerDS.onClaim(
            payable(msg.sender),
            _epochHash
        );

        // emit the claim event before processing it
        // so if the epoch is finalized in this claim (consensus)
        // the number of final epochs doesnt gets contaminated
        emit Claim(
            outputDS.getNumberOfFinalizedEpochs(),
            msg.sender,
            _epochHash
        );

        rollupsDS.resolveValidatorResult(result, claims, claimers);
    }

    /// @notice finalize epoch after timeout
    /// @dev can only be called if challenge period is over
    function finalizeEpoch() public override {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();

        Phase currentPhase = Phase(rollupsDS.currentPhase_int);
        require(
            currentPhase == Phase.AwaitingConsensus,
            "Phase != Awaiting Consensus"
        );

        uint256 sealingEpochTimestamp = rollupsDS.sealingEpochTimestamp;
        uint256 challengePeriod = rollupsDS.challengePeriod;
        require(
            block.timestamp > sealingEpochTimestamp + challengePeriod,
            "Challenge period not over"
        );

        require(
            validatorManagerDS.currentClaim != bytes32(0),
            "No Claim to be finalized"
        );

        rollupsDS.startNewEpoch();
    }

    /// @notice returns index of current (accumulating) epoch
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    ///      of finalized epochs array, else there are two non finalized epochs,
    ///      one awaiting consensus/dispute and another accumulating input
    function getCurrentEpoch() public view override returns (uint256) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return rollupsDS.getCurrentEpoch();
    }

    /// @notice returns the current phase
    function getCurrentPhase() public view returns (Phase) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return Phase(rollupsDS.currentPhase_int);
    }

    /// @notice returns the input accumulation start timestamp
    function getInputAccumulationStart() public view returns (uint256) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return uint256(rollupsDS.inputAccumulationStart);
    }

    /// @notice returns the sealing epoch timestamp
    function getSealingEpochTimestamp() public view returns (uint256) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return uint256(rollupsDS.sealingEpochTimestamp);
    }

    /// @notice returns the input duration in seconds
    function getInputDuration() public view returns (uint256) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return uint256(rollupsDS.inputDuration);
    }

    /// @notice returns the challenge period in seconds
    function getChallengePeriod() public view returns (uint256) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return uint256(rollupsDS.challengePeriod);
    }

    /// @notice returns the machine's template hash
    function getTemplateHash() public view returns (bytes32) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        return rollupsDS.templateHash;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Rollups interface
pragma solidity >=0.7.0;

// InputAccumulation - Inputs being accumulated for currrent epoch
// AwaitingConsensus - No disagreeing claims (or no claims)
// AwaitingDispute - Waiting for dispute to be over
// inputs received during InputAccumulation will be included in the
// current epoch. Inputs received while WaitingClaims or ChallengesInProgress
// are accumulated for the next epoch
enum Phase {
    InputAccumulation,
    AwaitingConsensus,
    AwaitingDispute
}

interface IRollups {
    /// @notice claim the result of current epoch
    /// @param _epochHash hash of epoch
    /// @dev ValidatorManager makes sure that msg.sender is allowed
    ///      and that claim != bytes32(0)
    /// TODO: add signatures for aggregated claims
    function claim(bytes32 _epochHash) external;

    /// @notice finalize epoch after timeout
    /// @dev can only be called if challenge period is over
    function finalizeEpoch() external;

    /// @notice returns index of current (accumulating) epoch
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    ///      of finalized epochs array, else there are two epochs two non
    ///      finalized epochs, one awaiting consensus/dispute and another
    ///      accumulating input
    function getCurrentEpoch() external view returns (uint256);

    /// @notice claim submitted
    /// @param epochHash claim being submitted by this epoch
    /// @param claimer address of current claimer
    /// @param epochNumber number of the epoch being submitted
    event Claim(
        uint256 indexed epochNumber,
        address claimer,
        bytes32 epochHash
    );

    /// @notice epoch finalized
    /// @param epochNumber number of the epoch being finalized
    /// @param epochHash claim being submitted by this epoch
    event FinalizeEpoch(uint256 indexed epochNumber, bytes32 epochHash);

    /// @notice dispute resolved
    /// @param winner winner of dispute
    /// @param loser loser of dispute
    /// @param winningClaim initial claim of winning validator
    event ResolveDispute(address winner, address loser, bytes32 winningClaim);

    /// @notice phase change
    /// @param newPhase new phase
    event PhaseChange(Phase newPhase);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Validator Manager interface
pragma solidity >=0.7.0;

// NoConflict - No conflicting claims or consensus
// Consensus - All validators had equal claims
// Conflict - Claim is conflicting with previous one
enum Result {
    NoConflict,
    Consensus,
    Conflict
}

// TODO: What is the incentive for validators to not just copy the first claim that arrived?
interface IValidatorManager {
    /// @notice get current claim
    function getCurrentClaim() external view returns (bytes32);

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title ClaimsMask library
pragma solidity >=0.8.8;

// ClaimsMask is used to keep track of the number of claims for up to 8 validators
// | agreement mask | consensus goal mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
// |     8 bits     |        8 bits       |      30 bits       |      30 bits       | ... |      30 bits       |
// In Validator Manager, #claims_validator indicates the #claims the validator has made.
// In Fee Manager, #claims_validator indicates the #claims the validator has redeemed. In this case,
//      agreement mask and consensus goal mask are not used.

type ClaimsMask is uint256;

library LibClaimsMask {
    uint256 constant claimsBitLen = 30; // #bits used for each #claims

    /// @notice this function creates a new ClaimsMask variable with value _value
    /// @param  _value the value following the format of ClaimsMask
    function newClaimsMask(uint256 _value) internal pure returns (ClaimsMask) {
        return ClaimsMask.wrap(_value);
    }

    /// @notice this function creates a new ClaimsMask variable with the consensus goal mask set,
    ///         according to the number of validators
    /// @param  _numValidators the number of validators
    function newClaimsMaskWithConsensusGoalSet(uint256 _numValidators)
        internal
        pure
        returns (ClaimsMask)
    {
        require(_numValidators <= 8, "up to 8 validators");
        uint256 consensusMask = (1 << _numValidators) - 1;
        return ClaimsMask.wrap(consensusMask << 240); // 256 - 8 - 8 = 240
    }

    /// @notice this function returns the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    ///     this index can be obtained though `getNumberOfClaimsByIndex` function in Validator Manager
    function getNumClaims(ClaimsMask _claimsMask, uint256 _validatorIndex)
        internal
        pure
        returns (uint256)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 bitmask = (1 << claimsBitLen) - 1;
        return
            (ClaimsMask.unwrap(_claimsMask) >>
                (claimsBitLen * _validatorIndex)) & bitmask;
    }

    /// @notice this function increases the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the increase amount
    function increaseNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        uint256 currentNum = getNumClaims(_claimsMask, _validatorIndex);
        uint256 newNum = currentNum + _value; // overflows checked by default with sol0.8
        return setNumClaims(_claimsMask, _validatorIndex, newNum);
    }

    /// @notice this function sets the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the set value
    function setNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        require(_value <= ((1 << claimsBitLen) - 1), "ClaimsMask Overflow");
        uint256 bitmask = ~(((1 << claimsBitLen) - 1) <<
            (claimsBitLen * _validatorIndex));
        uint256 clearedClaimsMask = ClaimsMask.unwrap(_claimsMask) & bitmask;
        _claimsMask = ClaimsMask.wrap(
            clearedClaimsMask | (_value << (claimsBitLen * _validatorIndex))
        );
        return _claimsMask;
    }

    /// @notice get consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function clearAgreementMask(ClaimsMask _claimsMask)
        internal
        pure
        returns (ClaimsMask)
    {
        uint256 clearedMask = ClaimsMask.unwrap(_claimsMask) & ((1 << 248) - 1); // 256 - 8 = 248
        return ClaimsMask.wrap(clearedMask);
    }

    /// @notice get the entire agreement mask
    /// @param  _claimsMask the ClaimsMask value
    function getAgreementMask(ClaimsMask _claimsMask)
        internal
        pure
        returns (uint256)
    {
        return (ClaimsMask.unwrap(_claimsMask) >> 248); // get the first 8 bits
    }

    /// @notice check if a validator has already claimed
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function alreadyClaimed(ClaimsMask _claimsMask, uint256 _validatorIndex)
        internal
        pure
        returns (bool)
    {
        // get the first 8 bits. Then & operation on the validator's bit to see if it's set
        return
            (((ClaimsMask.unwrap(_claimsMask) >> 248) >> _validatorIndex) &
                1) != 0;
    }

    /// @notice set agreement mask for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function setAgreementMask(ClaimsMask _claimsMask, uint256 _validatorIndex)
        internal
        pure
        returns (ClaimsMask)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 setMask = (ClaimsMask.unwrap(_claimsMask) |
            (1 << (248 + _validatorIndex))); // 256 - 8 = 248
        return ClaimsMask.wrap(setMask);
    }

    /// @notice get the entire consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function getConsensusGoalMask(ClaimsMask _claimsMask)
        internal
        pure
        returns (uint256)
    {
        return ((ClaimsMask.unwrap(_claimsMask) << 8) >> 248); // get the second 8 bits
    }

    /// @notice remove validator from the ClaimsMask
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function removeValidator(ClaimsMask _claimsMask, uint256 _validatorIndex)
        internal
        pure
        returns (ClaimsMask)
    {
        require(_validatorIndex < 8, "index out of range");
        uint256 claimsMaskValue = ClaimsMask.unwrap(_claimsMask);
        // remove validator from agreement bitmask
        uint256 zeroMask = ~(1 << (_validatorIndex + 248)); // 256 - 8 = 248
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from consensus goal mask
        zeroMask = ~(1 << (_validatorIndex + 240)); // 256 - 8 - 8 = 240
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from #claims
        return
            setNumClaims(ClaimsMask.wrap(claimsMaskValue), _validatorIndex, 0);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Dispute Manager library
pragma solidity ^0.8.0;

import {LibRollups} from "../libraries/LibRollups.sol";

library LibDisputeManager {
    using LibRollups for LibRollups.DiamondStorage;

    /// @notice initiates a dispute betweent two players
    /// @param claims conflicting claims
    /// @param claimers addresses of senders of conflicting claim
    /// @dev this is a mock implementation that just gives the win
    ///      to the address in the first posititon of claimers array
    function initiateDispute(
        bytes32[2] memory claims,
        address payable[2] memory claimers
    ) internal {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();
        rollupsDS.resolveDispute(claimers[0], claimers[1], claims[0]);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Fee Manager library
pragma solidity ^0.8.0;

import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";
import {IBank} from "../IBank.sol";

library LibFeeManager {
    using LibValidatorManager for LibValidatorManager.DiamondStorage;
    using LibFeeManager for LibFeeManager.DiamondStorage;
    using LibClaimsMask for ClaimsMask;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("FeeManager.diamond.storage");

    struct DiamondStorage {
        address owner; // owner of Fee Manager
        uint256 feePerClaim;
        IBank bank; // bank that holds the tokens to pay validators
        bool lock; // reentrancy lock
        // A bit set used for up to 8 validators.
        // The first 16 bits are not used to keep compatibility with the validator manager contract.
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // |     not used    | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     16 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask numClaimsRedeemed;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function onlyOwner(DiamondStorage storage ds) internal view {
        require(ds.owner == msg.sender, "caller is not the owner");
    }

    /// @notice this function can be called to check the number of claims that's redeemable for the validator
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function numClaimsRedeemable(DiamondStorage storage ds, address _validator)
        internal
        view
        returns (uint256)
    {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 totalClaims = validatorManagerDS.claimsMask.getNumClaims(
            valIndex
        );
        uint256 redeemedClaims = ds.numClaimsRedeemed.getNumClaims(valIndex);

        // underflow checked by default with sol0.8
        // which means if the validator is removed, calling this function will
        // either return 0 or revert
        return totalClaims - redeemedClaims;
    }

    /// @notice this function can be called to check the number of claims that has been redeemed for the validator
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function getNumClaimsRedeemed(DiamondStorage storage ds, address _validator)
        internal
        view
        returns (uint256)
    {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 redeemedClaims = ds.numClaimsRedeemed.getNumClaims(valIndex);

        return redeemedClaims;
    }

    /// @notice contract owner can reset the value of fee per claim
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _value the new value of fee per claim
    function resetFeePerClaim(DiamondStorage storage ds, uint256 _value)
        internal
    {
        // before resetting the feePerClaim, pay fees for all validators as per current rates
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        for (
            uint256 valIndex;
            valIndex < validatorManagerDS.maxNumValidators;
            valIndex++
        ) {
            address validator = validatorManagerDS.validators[valIndex];
            if (validator != address(0)) {
                uint256 nowRedeemingClaims = ds.numClaimsRedeemable(validator);
                if (nowRedeemingClaims > 0) {
                    ds.numClaimsRedeemed = ds
                        .numClaimsRedeemed
                        .increaseNumClaims(valIndex, nowRedeemingClaims);

                    uint256 feesToSend = nowRedeemingClaims * ds.feePerClaim; // number of erc20 tokens to send
                    ds.bank.transferTokens(validator, feesToSend); // will revert if transfer fails
                    // emit the number of claimed being redeemed, instead of the amount of tokens
                    emit FeeRedeemed(validator, nowRedeemingClaims);
                }
            }
        }
        ds.feePerClaim = _value;
        emit FeePerClaimReset(_value);
    }

    /// @notice this function can be called to redeem fees for validators
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator that is redeeming
    function redeemFee(DiamondStorage storage ds, address _validator) internal {
        // follow the Checks-Effects-Interactions pattern for security

        // ** checks **
        uint256 nowRedeemingClaims = ds.numClaimsRedeemable(_validator);
        require(nowRedeemingClaims > 0, "nothing to redeem yet");

        // ** effects **
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        ds.numClaimsRedeemed = ds.numClaimsRedeemed.increaseNumClaims(
            valIndex,
            nowRedeemingClaims
        );

        // ** interactions **
        uint256 feesToSend = nowRedeemingClaims * ds.feePerClaim; // number of erc20 tokens to send
        ds.bank.transferTokens(_validator, feesToSend); // will revert if transfer fails
        // emit the number of claimed being redeemed, instead of the amount of tokens
        emit FeeRedeemed(_validator, nowRedeemingClaims);
    }

    /// @notice removes a validator
    /// @param ds diamond storage pointer
    /// @param index index of validator to be removed
    function removeValidator(DiamondStorage storage ds, uint256 index)
        internal
    {
        ds.numClaimsRedeemed = ds.numClaimsRedeemed.setNumClaims(index, 0);
    }

    /// @notice emitted on resetting feePerClaim
    event FeePerClaimReset(uint256 value);

    /// @notice emitted on ERC20 funds redeemed by validator
    event FeeRedeemed(address validator, uint256 claims);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Input library
pragma solidity ^0.8.0;

import {LibRollups} from "../libraries/LibRollups.sol";

library LibInput {
    using LibRollups for LibRollups.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Input.diamond.storage");

    struct DiamondStorage {
        // always needs to keep track of two input boxes:
        // 1 for the input accumulation of next epoch
        // and 1 for the messages during current epoch. To save gas we alternate
        // between inputBox0 and inputBox1
        bytes32[] inputBox0;
        bytes32[] inputBox1;
        uint256 inputDriveSize; // size of input flashdrive
        uint256 currentInputBox;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice get input inside inbox of currently proposed claim
    /// @param ds diamond storage pointer
    /// @param index index of input inside that inbox
    /// @return hash of input at index index
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getInput(DiamondStorage storage ds, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return
            ds.currentInputBox == 0 ? ds.inputBox1[index] : ds.inputBox0[index];
    }

    /// @notice get number of inputs inside inbox of currently proposed claim
    /// @param ds diamond storage pointer
    /// @return number of inputs on that input box
    /// @dev currentInputBox being zero means that the inputs for
    ///      the claimed epoch are on input box one
    function getNumberOfInputs(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return
            ds.currentInputBox == 0 ? ds.inputBox1.length : ds.inputBox0.length;
    }

    /// @notice add input to processed by next epoch
    /// @param ds diamond storage pointer
    /// @param input input to be understood by offchain machine
    /// @dev offchain code is responsible for making sure
    ///      that input size is power of 2 and multiple of 8 since
    ///      the offchain machine has a 8 byte word
    function addInput(DiamondStorage storage ds, bytes memory input)
        internal
        returns (bytes32)
    {
        return addInputFromSender(ds, input, msg.sender);
    }

    /// @notice add internal input to processed by next epoch
    /// @notice this function is to be reserved for internal usage only
    /// @notice for normal inputs, call `addInput` instead
    /// @param ds diamond storage pointer
    /// @param input input to be understood by offchain machine
    /// @dev offchain code is responsible for making sure
    ///      that input size is power of 2 and multiple of 8 since
    ///      the offchain machine has a 8 byte word
    function addInternalInput(DiamondStorage storage ds, bytes memory input)
        internal
        returns (bytes32)
    {
        return addInputFromSender(ds, input, address(this));
    }

    /// @notice add input from a specific sender to processed by next epoch
    /// @notice this function is to be reserved for internal usage only
    /// @notice for normal inputs, call `addInput` instead
    /// @param ds diamond storage pointer
    /// @param input input to be understood by offchain machine
    /// @param sender input sender address
    /// @dev offchain code is responsible for making sure
    ///      that input size is power of 2 and multiple of 8 since
    ///      the offchain machine has a 8 byte word
    function addInputFromSender(
        DiamondStorage storage ds,
        bytes memory input,
        address sender
    ) internal returns (bytes32) {
        LibRollups.DiamondStorage storage rollupsDS = LibRollups
            .diamondStorage();

        require(input.length <= ds.inputDriveSize, "input len: [0,driveSize]");

        // notifyInput returns true if that input
        // belongs to a new epoch
        if (rollupsDS.notifyInput()) {
            swapInputBox(ds);
        }

        // points to correct inputBox
        bytes32[] storage inputBox = ds.currentInputBox == 0
            ? ds.inputBox0
            : ds.inputBox1;

        // get current epoch index
        uint256 currentEpoch = rollupsDS.getCurrentEpoch();

        // keccak 64 bytes into 32 bytes
        bytes32 keccakMetadata = keccak256(
            abi.encode(
                sender,
                block.number,
                block.timestamp,
                currentEpoch, // epoch index
                inputBox.length // input index
            )
        );

        bytes32 keccakInput = keccak256(input);

        bytes32 inputHash = keccak256(abi.encode(keccakMetadata, keccakInput));

        // add input to correct inbox
        inputBox.push(inputHash);

        emit InputAdded(
            currentEpoch,
            inputBox.length - 1,
            sender,
            block.timestamp,
            input
        );

        return inputHash;
    }

    /// @notice called when a new input accumulation phase begins
    ///         swap inbox to receive inputs for upcoming epoch
    /// @param ds diamond storage pointer
    function onNewInputAccumulation(DiamondStorage storage ds) internal {
        swapInputBox(ds);
    }

    /// @notice called when a new epoch begins, clears deprecated inputs
    /// @param ds diamond storage pointer
    function onNewEpoch(DiamondStorage storage ds) internal {
        // clear input box for new inputs
        // the current input box should be accumulating inputs
        // for the new epoch already. So we clear the other one.
        ds.currentInputBox == 0 ? delete ds.inputBox1 : delete ds.inputBox0;
    }

    /// @notice changes current input box
    /// @param ds diamond storage pointer
    function swapInputBox(DiamondStorage storage ds) internal {
        ds.currentInputBox = (ds.currentInputBox == 0) ? 1 : 0;
    }

    /// @notice input added
    /// @param epochNumber which epoch this input belongs to
    /// @param inputIndex index of the input just added
    /// @param sender msg.sender
    /// @param timestamp block.timestamp
    /// @param input input data
    event InputAdded(
        uint256 indexed epochNumber,
        uint256 indexed inputIndex,
        address sender,
        uint256 timestamp,
        bytes input
    );
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output library
pragma solidity ^0.8.0;

library LibOutput {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Output.diamond.storage");

    struct DiamondStorage {
        mapping(uint256 => uint256) voucherBitmask;
        bytes32[] epochHashes;
        bool lock; //reentrancy lock
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice to be called when an epoch is finalized
    /// @param ds diamond storage pointer
    /// @param epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(DiamondStorage storage ds, bytes32 epochHash) internal {
        ds.epochHashes.push(epochHash);
    }

    /// @notice get number of finalized epochs
    /// @param ds diamond storage pointer
    function getNumberOfFinalizedEpochs(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return ds.epochHashes.length;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Rollups library
pragma solidity ^0.8.0;

import {Phase} from "../interfaces/IRollups.sol";
import {Result} from "../interfaces/IValidatorManager.sol";

import {LibInput} from "../libraries/LibInput.sol";
import {LibOutput} from "../libraries/LibOutput.sol";
import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibDisputeManager} from "../libraries/LibDisputeManager.sol";

library LibRollups {
    using LibInput for LibInput.DiamondStorage;
    using LibOutput for LibOutput.DiamondStorage;
    using LibValidatorManager for LibValidatorManager.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Rollups.diamond.storage");

    struct DiamondStorage {
        bytes32 templateHash; // state hash of the cartesi machine at t0
        uint32 inputDuration; // duration of input accumulation phase in seconds
        uint32 challengePeriod; // duration of challenge period in seconds
        uint32 inputAccumulationStart; // timestamp when current input accumulation phase started
        uint32 sealingEpochTimestamp; // timestamp on when a proposed epoch (claim) becomes challengeable
        uint32 currentPhase_int; // current phase in integer form
    }

    /// @notice epoch finalized
    /// @param epochNumber number of the epoch being finalized
    /// @param epochHash claim being submitted by this epoch
    event FinalizeEpoch(uint256 indexed epochNumber, bytes32 epochHash);

    /// @notice dispute resolved
    /// @param winner winner of dispute
    /// @param loser loser of dispute
    /// @param winningClaim initial claim of winning validator
    event ResolveDispute(address winner, address loser, bytes32 winningClaim);

    /// @notice phase change
    /// @param newPhase new phase
    event PhaseChange(Phase newPhase);

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice called when new input arrives, manages the phase changes
    /// @param ds diamond storage pointer
    /// @dev can only be called by input contract
    function notifyInput(DiamondStorage storage ds) internal returns (bool) {
        Phase currentPhase = Phase(ds.currentPhase_int);
        uint256 inputAccumulationStart = ds.inputAccumulationStart;
        uint256 inputDuration = ds.inputDuration;

        if (
            currentPhase == Phase.InputAccumulation &&
            block.timestamp > inputAccumulationStart + inputDuration
        ) {
            ds.currentPhase_int = uint32(Phase.AwaitingConsensus);
            emit PhaseChange(Phase.AwaitingConsensus);
            return true;
        }
        return false;
    }

    /// @notice called when a dispute is resolved by the dispute manager
    /// @param ds diamond storage pointer
    /// @param winner winner of dispute
    /// @param loser loser of dispute
    /// @param winningClaim initial claim of winning validator
    function resolveDispute(
        DiamondStorage storage ds,
        address payable winner,
        address payable loser,
        bytes32 winningClaim
    ) internal {
        Result result;
        bytes32[2] memory claims;
        address payable[2] memory claimers;
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();

        (result, claims, claimers) = validatorManagerDS.onDisputeEnd(
            winner,
            loser,
            winningClaim
        );

        // restart challenge period
        ds.sealingEpochTimestamp = uint32(block.timestamp);

        emit ResolveDispute(winner, loser, winningClaim);
        resolveValidatorResult(ds, result, claims, claimers);
    }

    /// @notice resolve results returned by validator manager
    /// @param ds diamond storage pointer
    /// @param result result from claim or dispute operation
    /// @param claims array of claims in case of new conflict
    /// @param claimers array of claimers in case of new conflict
    function resolveValidatorResult(
        DiamondStorage storage ds,
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory claimers
    ) internal {
        if (result == Result.NoConflict) {
            Phase currentPhase = Phase(ds.currentPhase_int);
            if (currentPhase != Phase.AwaitingConsensus) {
                ds.currentPhase_int = uint32(Phase.AwaitingConsensus);
                emit PhaseChange(Phase.AwaitingConsensus);
            }
        } else if (result == Result.Consensus) {
            startNewEpoch(ds);
        } else {
            // for the case when result == Result.Conflict
            Phase currentPhase = Phase(ds.currentPhase_int);
            if (currentPhase != Phase.AwaitingDispute) {
                ds.currentPhase_int = uint32(Phase.AwaitingDispute);
                emit PhaseChange(Phase.AwaitingDispute);
            }
            LibDisputeManager.initiateDispute(claims, claimers);
        }
    }

    /// @notice starts new epoch
    /// @param ds diamond storage pointer
    function startNewEpoch(DiamondStorage storage ds) internal {
        LibInput.DiamondStorage storage inputDS = LibInput.diamondStorage();
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();

        // reset input accumulation start and deactivate challenge period start
        ds.currentPhase_int = uint32(Phase.InputAccumulation);
        emit PhaseChange(Phase.InputAccumulation);
        ds.inputAccumulationStart = uint32(block.timestamp);
        ds.sealingEpochTimestamp = type(uint32).max;

        bytes32 finalClaim = validatorManagerDS.onNewEpoch();

        // emit event before finalized epoch is added to the Output storage
        emit FinalizeEpoch(outputDS.getNumberOfFinalizedEpochs(), finalClaim);

        outputDS.onNewEpoch(finalClaim);
        inputDS.onNewEpoch();
    }

    /// @notice returns index of current (accumulating) epoch
    /// @param ds diamond storage pointer
    /// @return index of current epoch
    /// @dev if phase is input accumulation, then the epoch number is length
    ///      of finalized epochs array, else there are two non finalized epochs,
    ///      one awaiting consensus/dispute and another accumulating input
    function getCurrentEpoch(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();

        uint256 finalizedEpochs = outputDS.getNumberOfFinalizedEpochs();

        Phase currentPhase = Phase(ds.currentPhase_int);

        return
            currentPhase == Phase.InputAccumulation
                ? finalizedEpochs
                : finalizedEpochs + 1;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Validator Manager library
pragma solidity ^0.8.0;

import {Result} from "../interfaces/IValidatorManager.sol";

import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";
import {LibFeeManager} from "../libraries/LibFeeManager.sol";

library LibValidatorManager {
    using LibClaimsMask for ClaimsMask;
    using LibFeeManager for LibFeeManager.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("ValidatorManager.diamond.storage");

    struct DiamondStorage {
        bytes32 currentClaim; // current claim - first claim of this epoch
        address payable[] validators; // up to 8 validators
        uint256 maxNumValidators; // the maximum number of validators, set in the constructor
        // A bit set used for up to 8 validators.
        // The first 8 bits are used to indicate whom supports the current claim
        // The second 8 bits are used to indicate those should have claimed in order to reach consensus
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // | agreement mask | consensus mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     8 bits     |     8 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask claimsMask;
    }

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice called when a dispute ends in rollups
    /// @param ds diamond storage pointer
    /// @param winner address of dispute winner
    /// @param loser address of dispute loser
    /// @param winningClaim the winnning claim
    /// @return result of dispute being finished
    function onDisputeEnd(
        DiamondStorage storage ds,
        address payable winner,
        address payable loser,
        bytes32 winningClaim
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        removeValidator(ds, loser);

        if (winningClaim == ds.currentClaim) {
            // first claim stood, dont need to update the bitmask
            return
                isConsensus(ds)
                    ? emitDisputeEndedAndReturn(
                        Result.Consensus,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    )
                    : emitDisputeEndedAndReturn(
                        Result.NoConflict,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    );
        }

        // if first claim lost, and other validators have agreed with it
        // there is a new dispute to be played
        if (ds.claimsMask.getAgreementMask() != 0) {
            return
                emitDisputeEndedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, winningClaim],
                    [getClaimerOfCurrentClaim(ds), winner]
                );
        }
        // else there are no valdiators that agree with losing claim
        // we can update current claim and check for consensus in case
        // the winner is the only validator left
        ds.currentClaim = winningClaim;
        updateClaimAgreementMask(ds, winner);
        return
            isConsensus(ds)
                ? emitDisputeEndedAndReturn(
                    Result.Consensus,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                )
                : emitDisputeEndedAndReturn(
                    Result.NoConflict,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                );
    }

    /// @notice called when a new epoch starts
    /// @param ds diamond storage pointer
    /// @return current claim
    function onNewEpoch(DiamondStorage storage ds) internal returns (bytes32) {
        // reward validators who has made the correct claim by increasing their #claims
        claimFinalizedIncreaseCounts(ds);

        bytes32 tmpClaim = ds.currentClaim;

        // clear current claim
        ds.currentClaim = bytes32(0);
        // clear validator agreement bit mask
        ds.claimsMask = ds.claimsMask.clearAgreementMask();

        emit NewEpoch(tmpClaim);
        return tmpClaim;
    }

    /// @notice called when a claim is received by rollups
    /// @param ds diamond storage pointer
    /// @param sender address of sender of that claim
    /// @param claim claim received by rollups
    /// @return result of claim, Consensus | NoConflict | Conflict
    /// @return [currentClaim, conflicting claim] if there is Conflict
    ///         [currentClaim, bytes32(0)] if there is Consensus or NoConflcit
    /// @return [claimer1, claimer2] if there is  Conflcit
    ///         [claimer1, address(0)] if there is Consensus or NoConflcit
    function onClaim(
        DiamondStorage storage ds,
        address payable sender,
        bytes32 claim
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        require(claim != bytes32(0), "empty claim");
        require(isValidator(ds, sender), "sender not allowed");

        // require the validator hasn't claimed in the same epoch before
        uint256 index = getValidatorIndex(ds, sender);
        require(
            !ds.claimsMask.alreadyClaimed(index),
            "sender had claimed in this epoch before"
        );

        // cant return because a single claim might mean consensus
        if (ds.currentClaim == bytes32(0)) {
            ds.currentClaim = claim;
        } else if (claim != ds.currentClaim) {
            return
                emitClaimReceivedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, claim],
                    [getClaimerOfCurrentClaim(ds), sender]
                );
        }
        updateClaimAgreementMask(ds, sender);

        return
            isConsensus(ds)
                ? emitClaimReceivedAndReturn(
                    Result.Consensus,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                )
                : emitClaimReceivedAndReturn(
                    Result.NoConflict,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                );
    }

    /// @notice emits dispute ended event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitDisputeEndedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit DisputeEnded(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice emits claim received event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitClaimReceivedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    )
        internal
        returns (
            Result,
            bytes32[2] memory,
            address payable[2] memory
        )
    {
        emit ClaimReceived(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice only call this function when a claim has been finalized
    ///         Either a consensus has been reached or challenge period has past
    /// @param ds pointer to diamond storage
    function claimFinalizedIncreaseCounts(DiamondStorage storage ds) internal {
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            // if a validator agrees with the current claim
            if ((agreementMask & (1 << i)) != 0) {
                // increase #claims by 1
                ds.claimsMask = ds.claimsMask.increaseNumClaims(i, 1);
            }
        }
    }

    /// @notice removes a validator
    /// @param ds diamond storage pointer
    /// @param validator address of validator to be removed
    function removeValidator(DiamondStorage storage ds, address validator)
        internal
    {
        LibFeeManager.DiamondStorage storage feeManagerDS = LibFeeManager
            .diamondStorage();
        for (uint256 i; i < ds.validators.length; i++) {
            if (validator == ds.validators[i]) {
                // put address(0) in validators position
                ds.validators[i] = payable(0);
                // remove the validator from ValidatorManager's claimsMask
                ds.claimsMask = ds.claimsMask.removeValidator(i);
                // remove the validator from FeeManager's claimsMask (#redeems)
                feeManagerDS.removeValidator(i);
                break;
            }
        }
    }

    /// @notice check if consensus has been reached
    /// @param ds pointer to diamond storage
    function isConsensus(DiamondStorage storage ds)
        internal
        view
        returns (bool)
    {
        ClaimsMask claimsMask = ds.claimsMask;
        return
            claimsMask.getAgreementMask() == claimsMask.getConsensusGoalMask();
    }

    /// @notice get one of the validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @return validator that agreed with current claim
    function getClaimerOfCurrentClaim(DiamondStorage storage ds)
        internal
        view
        returns (address payable)
    {
        // TODO: we are always getting the first validator
        // on the array that agrees with the current claim to enter a dispute
        // should this be random?
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            if (agreementMask & (1 << i) != 0) {
                return ds.validators[i];
            }
        }
        revert("Agreeing validator not found");
    }

    /// @notice updates mask of validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @param sender address of validator that will be included in mask
    function updateClaimAgreementMask(
        DiamondStorage storage ds,
        address payable sender
    ) internal {
        uint256 validatorIndex = getValidatorIndex(ds, sender);
        ds.claimsMask = ds.claimsMask.setAgreementMask(validatorIndex);
    }

    /// @notice check if the sender is a validator
    /// @param ds pointer to diamond storage
    /// @param sender sender address
    function isValidator(DiamondStorage storage ds, address sender)
        internal
        view
        returns (bool)
    {
        require(sender != address(0), "address 0");

        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return true;
        }

        return false;
    }

    /// @notice find the validator and return the index or revert
    /// @param ds pointer to diamond storage
    /// @param sender validator address
    /// @return validator index or revert
    function getValidatorIndex(DiamondStorage storage ds, address sender)
        internal
        view
        returns (uint256)
    {
        require(sender != address(0), "address 0");
        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return i;
        }
        revert("validator not found");
    }

    /// @notice get number of claims the sender has made
    /// @param ds pointer to diamond storage
    /// @param _sender validator address
    /// @return #claims
    function getNumberOfClaimsByAddress(
        DiamondStorage storage ds,
        address payable _sender
    ) internal view returns (uint256) {
        for (uint256 i; i < ds.validators.length; i++) {
            if (_sender == ds.validators[i]) {
                return getNumberOfClaimsByIndex(ds, i);
            }
        }
        // if validator not found
        return 0;
    }

    /// @notice get number of claims by the index in the validator set
    /// @param ds pointer to diamond storage
    /// @param index the index in validator set
    /// @return #claims
    function getNumberOfClaimsByIndex(DiamondStorage storage ds, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ds.claimsMask.getNumClaims(index);
    }

    /// @notice get the maximum number of validators defined in validator manager
    /// @param ds pointer to diamond storage
    /// @return the maximum number of validators
    function getMaxNumValidators(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return ds.maxNumValidators;
    }
}