// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

contract Decorated {
    // This contract defines several modifiers but does not use
    // them - they will be used in derived contracts.
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Cannot be called now");
        _;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;
interface Instantiator {

    modifier onlyInstantiated(uint256 _index) virtual;

    modifier onlyActive(uint256 _index) virtual;

    modifier increasesNonce(uint256 _index) virtual;

    function isActive(uint256 _index) external view returns (bool);

    function getNonce(uint256 _index) external view returns (uint256);

    function isConcerned(uint256 _index, address _user) external view returns (bool);

    function getSubInstances(uint256 _index, address) external view returns (address[] memory _addresses, uint256[] memory _indices);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "./Instantiator.sol";

abstract contract InstantiatorImpl is Instantiator {
    uint256 public currentIndex = 0;

    mapping(uint256 => bool) internal active;
    mapping(uint256 => uint256) internal nonce;

    modifier onlyInstantiated(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        _;
    }

    modifier onlyActive(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        require(isActive(_index), "Index inactive");
        _;
    }

    modifier increasesNonce(uint256 _index) override {
        nonce[_index]++;
        _;
    }

    function isActive(uint256 _index) public override view returns (bool) {
        return (active[_index]);
    }

    function getNonce(uint256 _index)
        public
        override
        view
        onlyActive(_index)
        returns (uint256 currentNonce)
    {
        return nonce[_index];
    }

    function deactivate(uint256 _index) internal {
        active[_index] = false;
        nonce[_index] = 0;
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

/// @title An instantiator of compute
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "./ComputeInterface.sol";
import "./VGInterface.sol";

contract ComputeInstantiator is InstantiatorImpl, ComputeInterface, Decorated {
    // after instantiation, the claimer will submit the final hash
    // then the challenger can either accept of challenge.
    // in the latter case a verification game will be instantiated
    // to resolve the dispute.

    VGInterface private vg;

    // IMPLEMENT GARBAGE COLLECTOR AFTER AN INSTACE IS FINISHED!
    struct ComputeCtx {
        address challenger;
        address claimer;
        uint256 roundDuration; // time interval to interact with this contract
        uint256 timeOfLastMove; // last time someone made a move with deadline
        address machine; // machine which will run the challenge
        bytes32 initialHash;
        uint256 finalTime;
        bytes32 claimedFinalHash;
        uint256 vgInstance; // instance of verification game in case of dispute
        state currentState;
    }

    mapping(uint256 => ComputeCtx) internal instance;

    // These are the possible states and transitions of the contract.

    // +---+
    // |   |
    // +---+
    //   |
    //   | instantiate
    //   v
    // +--------------+ claimVictoryByTime +-----------------------+
    // | WaitingClaim |------------------->| ClaimerMisseddeadline |
    // +--------------+                    +-----------------------+
    //   |
    //   | submitClaim
    //   v
    // +---------------------+  confirm    +-----------------+
    // | WaitingConfirmation |------------>| ConsensusResult |
    // +---------------------+ or deadline +-----------------+
    //   |
    //   | challenge
    //   v
    // +------------------+ winByVG        +---------------+
    // | WaitingChallenge |--------------->| ChallengerWon |
    // +------------------+                +---------------+
    //   |
    //   |
    //   |                  winByVG        +------------+
    //   +-------------------------------->| ClaimerWon |
    //                                     +------------+
    //

    event ComputeCreated(
        uint256 _index,
        address _challenger,
        address _claimer,
        uint256 _roundDuration,
        address _machineAddress,
        bytes32 _initialHash,
        uint256 _finalTime
    );
    event ClaimSubmitted(uint256 _index, bytes32 _claimedFinalHash);
    event ResultConfirmed(uint256 _index);
    event ChallengeStarted(uint256 _index);
    event ComputeFinished(uint256 _index, uint8 _state);

    constructor(address _vgInstantiatorAddress) {
        vg = VGInterface(_vgInstantiatorAddress);
    }

    /// @notice Instantiates a compute instance.
    /// @param _challenger address of the challenger.
    /// @param _claimer address of the claimer.
    /// @param _roundDuration duration of the round (security param)
    /// @param _machineAddress address of the machine that will run the instruction
    /// @param _initialHash hash in which both claimer and challenger agree on
    /// @param _finalTime max cycle of the machine for that computation
    /// @return Compute index.
    function instantiate(
        address _challenger,
        address _claimer,
        uint256 _roundDuration,
        address _machineAddress,
        bytes32 _initialHash,
        uint256 _finalTime
    ) public override returns (uint256) {
        require(
            _challenger != _claimer,
            "Challenger and Claimer need to differ"
        );
        ComputeCtx storage currentInstance = instance[currentIndex];
        currentInstance.challenger = _challenger;
        currentInstance.claimer = _claimer;
        currentInstance.roundDuration = _roundDuration;
        currentInstance.machine = _machineAddress;
        currentInstance.initialHash = _initialHash;
        currentInstance.finalTime = _finalTime;
        currentInstance.currentState = state.WaitingClaim;
        currentInstance.timeOfLastMove = block.timestamp;

        emit ComputeCreated(
            currentIndex,
            _challenger,
            _claimer,
            _roundDuration,
            _machineAddress,
            _initialHash,
            _finalTime
        );

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Claimer claims the hash of the result of a computation
    /// @param _index Index of instance that the claimer is interacting with
    /// @param _claimedFinalHash hash of the machine after computation is completed.
    function submitClaim(uint256 _index, bytes32 _claimedFinalHash)
        public
        override
        onlyInstantiated(_index)
        onlyBy(instance[_index].claimer)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingClaim,
            "State should be WaitingClaim"
        );
        instance[_index].claimedFinalHash = _claimedFinalHash;
        instance[_index].currentState = state.WaitingConfirmation;

        emit ClaimSubmitted(_index, _claimedFinalHash);
    }

    /// @notice Challenger accepts claim.
    /// @param _index Index of compute instance that the challenger is confirming the claim.
    function confirm(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        onlyBy(instance[_index].challenger)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingConfirmation,
            "State should be WaitingConfirmation"
        );
        instance[_index].currentState = state.ConsensusResult;
        clearInstance(_index);
        emit ResultConfirmed(_index);
    }

    /// @notice Challenger disputes the claim, starting a verification game.
    /// @param _index Index of compute instance which challenger is starting the VG.
    function challenge(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        onlyBy(instance[_index].challenger)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingConfirmation,
            "State should be WaitingConfirmation"
        );
        instance[_index].vgInstance = vg.instantiate(
            instance[_index].challenger,
            instance[_index].claimer,
            instance[_index].roundDuration,
            instance[_index].machine,
            instance[_index].initialHash,
            instance[_index].claimedFinalHash,
            instance[_index].finalTime
        );
        instance[_index].currentState = state.WaitingChallenge;

        emit ChallengeStarted(_index);
    }

    /// @notice In case one of the parties wins the verification game,
    /// then he or she can call this function to claim victory in
    /// this contract as well.
    /// @param _index Index of compute instance which challenger is starting the VG.
    function winByVG(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingChallenge,
            "State is not WaitingChallenge, cannot winByVG"
        );
        uint256 vgIndex = instance[_index].vgInstance;

        if (vg.stateIsFinishedChallengerWon(vgIndex)) {
            challengerWins(_index);
            return;
        }

        if (vg.stateIsFinishedClaimerWon(vgIndex)) {
            claimerWins(_index);
            return;
        }
        revert("State of VG is not final");
    }

    /// @notice Claim victory for opponent timeout.
    function claimVictoryByTime(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        increasesNonce(_index)
    {
        bool afterDeadline = (block.timestamp >
            instance[_index].timeOfLastMove +
                getMaxStateDuration(
                    instance[_index].currentState,
                    instance[_index].roundDuration,
                    40, // time to start machine
                    1, // vg is not instantiated, so it doesnt matter
                    instance[_index].finalTime,
                    500
                )); // pico seconds to run instruction

        require(afterDeadline, "Deadline is not over for this specific state");

        if (
            (msg.sender == instance[_index].challenger) &&
            (instance[_index].currentState == state.WaitingClaim)
        ) {
            instance[_index].currentState = state.ClaimerMissedDeadline;
            deactivate(_index);
            emit ComputeFinished(_index, uint8(instance[_index].currentState));
            return;
        }

        if (
            (msg.sender == instance[_index].claimer) &&
            (instance[_index].currentState == state.WaitingConfirmation)
        ) {
            instance[_index].currentState = state.ConsensusResult;
            deactivate(_index);
            emit ComputeFinished(_index, uint8(instance[_index].currentState));
            return;
        }
        revert("Fail to ClaimVictoryByTime in current condition");
    }

    /// @notice Get the worst case scenario duration for a specific state
    /// @param _roundDuration security parameter, the max time an agent
    //          has to react and submit one simple transaction
    /// @param _timeToStartMachine time to build the machine for the first time
    /// @param _partitionSize size of partition, how many instructions the
    //          will run to reach the necessary hash
    /// @param _maxCycle is the maximum amount of steps a machine can perform
    //          before being forced into becoming halted
    /// @param _picoSecondsToRunInsn time the offchain will take to run one instruction
    function getMaxStateDuration(
        state _state,
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) private view returns (uint256) {
        if (_state == state.WaitingClaim) {
            // time to run entire machine + time to react
            return
                _timeToStartMachine +
                ((_maxCycle * _picoSecondsToRunInsn) / 1e12) +
                _roundDuration;
        }

        if (_state == state.WaitingConfirmation) {
            // time to run entire machine + time to react
            return
                _timeToStartMachine +
                ((_maxCycle * _picoSecondsToRunInsn) / 1e12) +
                _roundDuration;
        }

        if (_state == state.WaitingChallenge) {
            // time to run a verification game + time to react
            return
                vg.getMaxInstanceDuration(
                    _roundDuration,
                    _timeToStartMachine,
                    _partitionSize,
                    _maxCycle,
                    _picoSecondsToRunInsn
                ) + _roundDuration;
        }

        if (
            _state == state.ClaimerWon ||
            _state == state.ChallengerWon ||
            _state == state.ClaimerMissedDeadline ||
            _state == state.ConsensusResult
        ) {
            return 0; // final state
        }

        // XXX: what do we return here? Is this reachable? revert?
    }

    /// @notice Get the worst case scenario duration for an instance of this contract
    /// @param _roundDuration security parameter, the max time an agent
    //          has to react and submit one simple transaction
    /// @param _timeToStartMachine time to build the machine for the first time
    /// @param _partitionSize size of partition, how many instructions the
    //          will run to reach the necessary hash
    /// @param _maxCycle number of instructions until the machine is forcibly halted
    /// @param _picoSecondsToRunInsn time the offchain will take to run one instruction
    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) public view returns (uint256) {
        uint256 waitingClaim = getMaxStateDuration(
            state.WaitingClaim,
            _roundDuration,
            _timeToStartMachine,
            _partitionSize,
            _maxCycle,
            _picoSecondsToRunInsn
        );

        uint256 waitingConfirmation = getMaxStateDuration(
            state.WaitingConfirmation,
            _roundDuration,
            _timeToStartMachine,
            _partitionSize,
            _maxCycle,
            _picoSecondsToRunInsn
        );

        uint256 waitingChallenge = getMaxStateDuration(
            state.WaitingChallenge,
            _roundDuration,
            _timeToStartMachine,
            _partitionSize,
            _maxCycle,
            _picoSecondsToRunInsn
        );

        return waitingClaim + waitingConfirmation + waitingChallenge;
    }

    function isConcerned(uint256 _index, address _user)
        public
        view
        override
        returns (bool)
    {
        return ((instance[_index].challenger == _user) ||
            (instance[_index].claimer == _user));
    }

    function getSubInstances(uint256 _index, address)
        public
        view
        override
        returns (address[] memory _addresses, uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;
        if (instance[_index].currentState == state.WaitingChallenge) {
            a = new address[](1);
            i = new uint256[](1);
            a[0] = address(vg);
            i[0] = instance[_index].vgInstance;
            return (a, i);
        }
        a = new address[](0);
        i = new uint256[](0);
        return (a, i);
    }

    function getState(uint256 _index, address)
        public
        view
        returns (
            address _challenger,
            address _claimer,
            uint256 _deadline,
            address _machine,
            bytes32 _initialHash,
            uint256 _finalTime,
            bytes32 _claimedFinalHash,
            bytes32 _currentState
        )
    {
        ComputeCtx memory i = instance[_index];

        // we have to duplicate the code for getCurrentState because of
        // "stack too deep"

        // this variables only matter on challenging state
        uint256 partitionSize = 1;
        uint256 partitionGameIndex = 1;

        bytes32 currentState;
        if (i.currentState == state.WaitingClaim) {
            currentState = "WaitingClaim";
        }
        if (i.currentState == state.WaitingConfirmation) {
            currentState = "WaitingConfirmation";
        }
        if (i.currentState == state.ClaimerMissedDeadline) {
            currentState = "ClaimerMissedDeadline";
        }
        if (i.currentState == state.WaitingChallenge) {
            currentState = "WaitingChallenge";
            partitionSize = vg.getPartitionQuerySize(i.vgInstance);
            partitionGameIndex = vg.getPartitionGameIndex(i.vgInstance);
        }
        if (i.currentState == state.ChallengerWon) {
            currentState = "ChallengerWon";
        }
        if (i.currentState == state.ClaimerWon) {
            currentState = "ClaimerWon";
        }
        if (i.currentState == state.ConsensusResult) {
            currentState = "ConsensusResult";
        }

        return (
            i.challenger,
            i.claimer,
            i.timeOfLastMove +
                getMaxStateDuration(
                    i.currentState,
                    i.roundDuration,
                    40, // time to start machine
                    partitionSize,
                    i.finalTime,
                    500 // pico seconds to run insn
                ),
            i.machine,
            i.initialHash,
            i.finalTime,
            i.claimedFinalHash,
            currentState
        );
    }

    function getCurrentState(uint256 _index)
        public
        view
        override
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.WaitingClaim) {
            return "WaitingClaim";
        }
        if (instance[_index].currentState == state.WaitingConfirmation) {
            return "WaitingConfirmation";
        }
        if (instance[_index].currentState == state.ClaimerMissedDeadline) {
            return "ClaimerMissedDeadline";
        }
        if (instance[_index].currentState == state.WaitingChallenge) {
            return "WaitingChallenge";
        }
        if (instance[_index].currentState == state.ChallengerWon) {
            return "ChallengerWon";
        }
        if (instance[_index].currentState == state.ClaimerWon) {
            return "ClaimerWon";
        }
        if (instance[_index].currentState == state.ConsensusResult) {
            return "ConsensusResult";
        }
        revert("Unrecognized state");
    }

    // remove these functions and change tests accordingly
    function stateIsWaitingClaim(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingClaim;
    }

    function stateIsWaitingConfirmation(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingConfirmation;
    }

    function stateIsClaimerMissedDeadline(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ClaimerMissedDeadline;
    }

    function stateIsWaitingChallange(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingChallenge;
    }

    function stateIsChallengerWon(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ChallengerWon;
    }

    function stateIsClaimerWon(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ClaimerWon;
    }

    function stateIsConsensusResult(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ConsensusResult;
    }

    function clearInstance(uint256 _index) internal {
        delete instance[_index].challenger;
        delete instance[_index].claimer;
        delete instance[_index].roundDuration;
        delete instance[_index].timeOfLastMove;
        delete instance[_index].machine;
        delete instance[_index].initialHash;
        delete instance[_index].finalTime;
        // !!!!!!!!! should call clear in vgInstance !!!!!!!!!
        delete instance[_index].vgInstance;
        deactivate(_index);
    }

    function challengerWins(uint256 _index) private onlyInstantiated(_index) {
        clearInstance(_index);
        instance[_index].currentState = state.ChallengerWon;
        emit ComputeFinished(_index, uint8(instance[_index].currentState));
    }

    function claimerWins(uint256 _index) private onlyInstantiated(_index) {
        clearInstance(_index);
        instance[_index].currentState = state.ClaimerWon;
        emit ComputeFinished(_index, uint8(instance[_index].currentState));
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

/// @title Interface for compute instantiator
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface ComputeInterface is Instantiator {
    enum state {
        WaitingClaim,
        WaitingConfirmation,
        ClaimerMissedDeadline,
        WaitingChallenge,
        ChallengerWon,
        ClaimerWon,
        ConsensusResult
    }

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _challenger,
        address _claimer,
        uint256 _roundDuration,
        address _machineAddress,
        bytes32 _initialHash,
        uint256 _finalTime
    ) external returns (uint256);

    function submitClaim(uint256 _index, bytes32 _claimedFinalHash) external;

    function confirm(uint256 _index) external;

    function challenge(uint256 _index) external;

    function winByVG(uint256 _index) external;

    function claimVictoryByTime(uint256 _index) external;
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

/// @title Interface for memory manager instantiator
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface MMInterface is Instantiator {
    enum state {
        WaitingProofs,
        WaitingReplay,
        FinishedReplay
    }

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _owner,
        address _provider,
        bytes32 _initialHash
    ) external returns (uint256);

    function newHash(uint256 _index) external view returns (bytes32);

    function finishProofPhase(uint256 _index) external;

    function finishReplayPhase(uint256 _index) external;

    function getRWArrays(uint256 _index)
        external
        view
        returns (
            uint64[] memory,
            bytes8[] memory,
            bool[] memory
        );

    function stateIsWaitingProofs(uint256 _index) external view returns (bool);

    function stateIsWaitingReplay(uint256 _index) external view returns (bool);

    function stateIsFinishedReplay(uint256 _index) external view returns (bool);

    function getCurrentStateDeadline(
        uint256 _index,
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) external view returns (uint256);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) external view returns (uint256);
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

/// @title MachineInterface interface contract
pragma solidity ^0.8.0;

interface MachineInterface {
    event StepGiven(uint8 exitCode);

    function step(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) external returns (uint8, uint256);

    function getMemoryInteractor() external view returns (address);
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

/// @title Abstract interface for partition instantiator
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface PartitionInterface is Instantiator {
    enum state {
        WaitingQuery,
        WaitingHashes,
        ChallengerWon,
        ClaimerWon,
        DivergenceFound
    }

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _challenger,
        address _claimer,
        bytes32 _initialHash,
        bytes32 _claimerFinalHash,
        uint256 _finalTime,
        uint256 _querySize,
        uint256 _roundDuration
    ) external returns (uint256);

    function timeHash(uint256 _index, uint256 key)
        external
        view
        returns (bytes32);

    function divergenceTime(uint256 _index) external view returns (uint256);

    function stateIsWaitingQuery(uint256 _index) external view returns (bool);

    function stateIsWaitingHashes(uint256 _index) external view returns (bool);

    function stateIsChallengerWon(uint256 _index) external view returns (bool);

    function stateIsClaimerWon(uint256 _index) external view returns (bool);

    function stateIsDivergenceFound(uint256 _index)
        external
        view
        returns (bool);

    function getPartitionGameIndex(uint256 _index)
        external
        view
        returns (uint256);

    function getQuerySize(uint256 _index) external view returns (uint256);

    function getCurrentStateDeadline(uint256 _index)
        external
        view
        returns (uint256 time);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) external view returns (uint256);
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

// @title Verification game instantiator
pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/Instantiator.sol";
import "./PartitionInterface.sol";
import "./MMInterface.sol";
import "./MachineInterface.sol";

interface VGInterface is Instantiator {
    enum state {
        WaitPartition,
        WaitMemoryProveValues,
        FinishedClaimerWon,
        FinishedChallengerWon
    }

    function instantiate(
        address _challenger,
        address _claimer,
        uint256 _roundDuration,
        address _machineAddress,
        bytes32 _initialHash,
        bytes32 _claimerFinalHash,
        uint256 _finalTime
    ) external returns (uint256);

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function stateIsFinishedClaimerWon(uint256 _index)
        external
        view
        returns (bool);

    function stateIsFinishedChallengerWon(uint256 _index)
        external
        view
        returns (bool);

    function winByPartitionTimeout(uint256 _index) external;

    function startMachineRunChallenge(uint256 _index) external;

    function settleVerificationGame(uint256 _index) external;

    function claimVictoryByTime(uint256 _index) external;

    //function stateIsWaitPartition(uint256 _index) public view returns (bool);
    //function stateIsWaitMemoryProveValues(uint256 _index) public view
    //  returns (bool);
    //function clearInstance(uint256 _index) internal;
    //function challengerWins(uint256 _index) private;
    //function claimerWins(uint256 _index) private;

    function getPartitionQuerySize(uint256 _index)
        external
        view
        returns (uint256);

    function getPartitionGameIndex(uint256 _index)
        external
        view
        returns (uint256);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) external view returns (uint256);
}