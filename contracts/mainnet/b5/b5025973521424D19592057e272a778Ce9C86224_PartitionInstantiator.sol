// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

/// @title Partition instantiator
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "./PartitionInterface.sol";

contract PartitionInstantiator is
    InstantiatorImpl,
    Decorated,
    PartitionInterface
{
    uint256 constant MAX_QUERY_SIZE = 20;

    // IMPLEMENT GARBAGE COLLECTOR AFTER AN INSTACE IS FINISHED!
    struct PartitionCtx {
        address challenger;
        address claimer;
        uint256 finalTime; // hashes provided between 0 and finalTime (inclusive)
        mapping(uint256 => bool) timeSubmitted; // marks a time as submitted
        mapping(uint256 => bytes32) timeHash; // hashes are signed by claimer
        uint256 querySize;
        uint256[] queryArray;
        uint256 timeOfLastMove;
        uint256 roundDuration;
        uint256 partitionGameIndex; // number of interactions that already happened in the partition interaction
        state currentState;
        uint256 divergenceTime;
    }

    //Swap internal/private when done with testing
    mapping(uint256 => PartitionCtx) internal instance;

    // These are the possible states and transitions of the contract.
    //
    //          +---+
    //          |   |
    //          +---+
    //            |
    //            | instantiate
    //            v
    //          +---------------+  claimVictoryByTimeout  +---------------+
    //          | WaitingHashes |------------------------>| ChallengerWon |
    //          +---------------+                         +---------------+
    //            |  ^
    // replyQuery |  | makeQuery
    //            v  |
    //          +--------------+   claimVictoryByTimeout  +------------+
    //          | WaitingQuery |------------------------->| ClaimerWon |
    //          +--------------+                          +------------+
    //            |
    //            | presentDivergence
    //            v
    //          +-----------------+
    //          | DivergenceFound |
    //          +-----------------+
    //

    event PartitionCreated(uint256 _index);
    event QueryPosted(uint256 _index);
    event HashesPosted(uint256 _index);
    event ChallengeEnded(uint256 _index, uint8 _state);
    event DivergenceFound(
        uint256 _index,
        uint256 _timeOfDivergence,
        bytes32 _hashAtDivergenceTime,
        bytes32 _hashRigthAfterDivergenceTime
    );

    /// @notice Instantiate a partition instance.
    /// @param _challenger address of the challenger.
    /// @param _claimer address of the claimer.
    /// @param _initialHash hash in which both claimer and challenger agree on
    /// @param _claimerFinalHash final hash claimed by claimer
    /// @param _finalTime max cycle of the machine for that computation
    /// @param _querySize size of postedHashes and postedTimes
    /// @param _roundDuration duration of the round (security param)
    /// @return Partition index.
    function instantiate(
        address _challenger,
        address _claimer,
        bytes32 _initialHash,
        bytes32 _claimerFinalHash,
        uint256 _finalTime,
        uint256 _querySize,
        uint256 _roundDuration
    ) public override returns (uint256) {
        require(
            _challenger != _claimer,
            "Challenger and claimer have the same address"
        );
        require(_finalTime > 0, "Final Time has to be bigger than zero");
        require(_querySize > 2, "Query Size must be bigger than 2");
        require(
            _querySize < MAX_QUERY_SIZE,
            "Query Size must be less than max"
        );
        require(
            _roundDuration > 50,
            "Round Duration has to be greater than 50 seconds"
        );
        instance[currentIndex].challenger = _challenger;
        instance[currentIndex].claimer = _claimer;
        instance[currentIndex].finalTime = _finalTime;
        instance[currentIndex].timeSubmitted[0] = true;
        instance[currentIndex].timeSubmitted[_finalTime] = true;
        instance[currentIndex].timeHash[0] = _initialHash;
        instance[currentIndex].timeHash[_finalTime] = _claimerFinalHash;
        instance[currentIndex].querySize = _querySize;
        // Creates queryArray with the correct size
        instance[currentIndex].queryArray = new uint256[](
            instance[currentIndex].querySize
        );
        // slice the interval, placing the separators in queryArray
        slice(currentIndex, 0, instance[currentIndex].finalTime);
        instance[currentIndex].roundDuration = _roundDuration;
        instance[currentIndex].timeOfLastMove = block.timestamp;
        instance[currentIndex].currentState = state.WaitingHashes;
        emit PartitionCreated(currentIndex);
        emit QueryPosted(currentIndex);

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Answer the query (only claimer can call it).
    /// @param postedTimes An array (of size querySize) with the times that have
    /// been queried.
    /// @param postedHashes An array (of size querySize) with the hashes
    /// corresponding to the queried times
    function replyQuery(
        uint256 _index,
        uint256[] memory postedTimes,
        bytes32[] memory postedHashes
    )
        public
        onlyInstantiated(_index)
        onlyBy(instance[_index].claimer)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingHashes,
            "CurrentState is not WaitingHashes, cannot replyQuery"
        );
        require(
            postedTimes.length == instance[_index].querySize,
            "postedTimes.length != querySize"
        );
        require(
            postedHashes.length == instance[_index].querySize,
            "postedHashes.length != querySize"
        );
        for (uint256 i = 0; i < instance[_index].querySize; i++) {
            // make sure the claimer knows the current query
            require(
                postedTimes[i] == instance[_index].queryArray[i],
                "postedTimes[i] != queryArray[i]"
            );
            // cannot rewrite previous answer
            if (!instance[_index].timeSubmitted[postedTimes[i]]) {
                instance[_index].timeSubmitted[postedTimes[i]] = true;
                instance[_index].timeHash[postedTimes[i]] = postedHashes[i];
            }
        }
        instance[_index].currentState = state.WaitingQuery;
        instance[_index].timeOfLastMove = block.timestamp;
        instance[_index].partitionGameIndex++;
        emit HashesPosted(_index);
    }

    /// @notice Makes a query (only challenger can call it).
    /// @param queryPiece is the index of queryArray corresponding to the left
    /// limit of the next interval to be queried.
    /// @param leftPoint confirmation of the leftPoint of the interval to be
    /// split. Should be an aggreement point.
    /// @param rightPoint confirmation of the rightPoint of the interval to be
    /// split. Should be a disagreement point.
    function makeQuery(
        uint256 _index,
        uint256 queryPiece,
        uint256 leftPoint,
        uint256 rightPoint
    )
        public
        onlyInstantiated(_index)
        onlyBy(instance[_index].challenger)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingQuery,
            "CurrentState is not WaitingQuery, cannot makeQuery"
        );
        require(
            queryPiece < instance[_index].querySize - 1,
            "queryPiece is bigger than querySize - 1"
        );
        // make sure the challenger knows the previous query
        require(
            leftPoint == instance[_index].queryArray[queryPiece],
            "leftPoint != queryArray[queryPiece]"
        );
        require(
            rightPoint == instance[_index].queryArray[queryPiece + 1],
            "rightPoint != queryArray[queryPiece]"
        );
        // no unitary queries. in unitary case, present divergence instead.
        // by avoiding unitary queries one forces the contest to end
        require(rightPoint - leftPoint > 1, "Interval is less than one");
        slice(_index, leftPoint, rightPoint);
        instance[_index].currentState = state.WaitingHashes;
        instance[_index].timeOfLastMove = block.timestamp;
        emit QueryPosted(_index);
    }

    /// @notice Claim victory for opponent timeout.
    function claimVictoryByTime(uint256 _index)
        public
        onlyInstantiated(_index)
        increasesNonce(_index)
    {
        bool afterDeadline = (block.timestamp >
            instance[_index].timeOfLastMove +
                getMaxStateDuration(
                    instance[_index].currentState,
                    instance[_index].roundDuration,
                    40, // time to build machine for the first time
                    instance[_index].querySize,
                    instance[_index].partitionGameIndex,
                    instance[_index].finalTime,
                    500 // 500 pico seconds per instruction
                ));

        if (
            (msg.sender == instance[_index].challenger) &&
            (instance[_index].currentState == state.WaitingHashes) &&
            afterDeadline
        ) {
            instance[_index].currentState = state.ChallengerWon;
            deactivate(_index);
            emit ChallengeEnded(_index, uint8(instance[_index].currentState));
            return;
        }
        if (
            (msg.sender == instance[_index].claimer) &&
            (instance[_index].currentState == state.WaitingQuery) &&
            afterDeadline
        ) {
            instance[_index].currentState = state.ClaimerWon;
            deactivate(_index);
            emit ChallengeEnded(_index, uint8(instance[_index].currentState));
            return;
        }
        revert("Fail to ClaimVictoryByTime in current condition");
    }

    /// @notice Present a precise time of divergence (can only be called by
    /// challenger).
    /// @param _divergenceTime The time when the divergence happended. It
    /// should be a point of aggreement, while _divergenceTime + 1 should be a
    /// point of disagreement (both queried).
    function presentDivergence(uint256 _index, uint256 _divergenceTime)
        public
        onlyInstantiated(_index)
        onlyBy(instance[_index].challenger)
        increasesNonce(_index)
    {
        require(
            _divergenceTime < instance[_index].finalTime,
            "divergence time has to be less than finalTime"
        );
        require(
            instance[_index].timeSubmitted[_divergenceTime],
            "divergenceTime has to have been submitted"
        );
        require(
            instance[_index].timeSubmitted[_divergenceTime + 1],
            "divergenceTime + 1 has to have been submitted"
        );

        instance[_index].divergenceTime = _divergenceTime;
        instance[_index].currentState = state.DivergenceFound;
        deactivate(_index);
        emit ChallengeEnded(_index, uint8(instance[_index].currentState));
        emit DivergenceFound(
            _index,
            instance[_index].divergenceTime,
            instance[_index].timeHash[instance[_index].divergenceTime],
            instance[_index].timeHash[instance[_index].divergenceTime + 1]
        );
    }

    /// @notice Get the worst case scenario duration for a specific state
    /// @param _roundDuration security parameter, the max time an agent
    //          has to react and submit one simple transaction
    /// @param _timeToStartMachine time to build the machine for the first time
    /// @param _partitionSize size of partition, how many instructions the
    //          will run to reach the necessary hash
    /// @param _partitionGameIndex number of interactions that already happened
    //          in the partition interaction
    /// @param _maxCycle number of instructions until the machine is forcibly halted
    /// @param _picoSecondsToRunInsn time the offchain will take to run one instruction
    function getMaxStateDuration(
        state _state,
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _partitionGameIndex,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) private pure returns (uint256) {
        // TO-DO: when we have DUMP then we can remove the partitionSize - 1 multiplier
        uint256 currentPartitionSize = _maxCycle /
            (_partitionSize**_partitionGameIndex);

        if (_partitionGameIndex != 0) {
            currentPartitionSize = currentPartitionSize * (_partitionSize - 1);
        }

        if (_state == state.WaitingQuery) {
            return
                _timeToStartMachine +
                ((currentPartitionSize * _picoSecondsToRunInsn) / 1e12) +
                _roundDuration;
        }
        if (_state == state.WaitingHashes) {
            return
                _timeToStartMachine +
                ((currentPartitionSize * _picoSecondsToRunInsn) / 1e12) +
                _roundDuration;
        }
        if (
            _state == state.ClaimerWon ||
            _state == state.ChallengerWon ||
            _state == state.DivergenceFound
        ) {
            return 0; // final state
        }
        require(false, "Unrecognized state");
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
    ) public override pure returns (uint256) {
        uint256 waitingQueryDuration = getMaxStateDuration(
            state.WaitingQuery,
            _roundDuration,
            _timeToStartMachine,
            _partitionSize,
            0, //_partitionGameIndex "worst case" is zero
            _maxCycle,
            _picoSecondsToRunInsn
        );

        uint256 waitingHashesDuration = getMaxStateDuration(
            state.WaitingHashes,
            _roundDuration,
            _timeToStartMachine,
            _partitionSize,
            0, //_partitionGameIndex "worst case" is zero
            _maxCycle,
            _picoSecondsToRunInsn
        );

        // TO-DO: When we have DUMP this should be 2 should be 1 / (1 - 1/querySize)
        // also has to add the round duration for each state transition
        return
            (uint256(2) * waitingQueryDuration) +
            (uint256(2) * waitingHashesDuration) +
            (_roundDuration * log2OverTwo(_maxCycle));
    }

    // Getters methods

    function getCurrentStateDeadline(uint _index) public override view
        onlyInstantiated(_index)
        returns (uint time)
    {
        PartitionCtx storage i = instance[_index];
        time = i.timeOfLastMove +
            getMaxStateDuration(
                i.currentState,
                i.roundDuration,
                40,
                i.querySize,
                i.partitionGameIndex,
                i.finalTime,
                500
        ); //deadline (40 seconds to build machine, 500 pico seconds per insn
    }

    function getState(uint256 _index, address)
        public
        view
        returns (
            //onlyInstantiated(_index)
            address _challenger,
            address _claimer,
            uint256[] memory _queryArray,
            bool[] memory _submittedArray,
            bytes32[] memory _hashArray,
            bytes32 _currentState,
            uint256[] memory _uintValues
        )
    {
        PartitionCtx storage i = instance[_index];

        uint256[] memory uintValues = new uint256[](4);
        uintValues[0] = i.finalTime;
        uintValues[1] = i.querySize;
        uintValues[2] =
            i.timeOfLastMove +
            getMaxStateDuration(
                i.currentState,
                i.roundDuration,
                40,
                i.querySize,
                i.partitionGameIndex,
                i.finalTime,
                500
            ); //deadline (40 seconds to build machine, 500 pico seconds per insn
        uintValues[3] = i.divergenceTime;

        bool[] memory submittedArray = new bool[](MAX_QUERY_SIZE);
        bytes32[] memory hashArray = new bytes32[](MAX_QUERY_SIZE);

        for (uint256 j = 0; j < i.querySize; j++) {
            submittedArray[j] = instance[_index].timeSubmitted[i.queryArray[j]];
            hashArray[j] = instance[_index].timeHash[i.queryArray[j]];
        }

        // we have to duplicate the code for getCurrentState because of
        // "stack too deep"
        bytes32 currentState;
        if (i.currentState == state.WaitingQuery) {
            currentState = "WaitingQuery";
        }
        if (i.currentState == state.WaitingHashes) {
            currentState = "WaitingHashes";
        }
        if (i.currentState == state.ChallengerWon) {
            currentState = "ChallengerWon";
        }
        if (i.currentState == state.ClaimerWon) {
            currentState = "ClaimerWon";
        }
        if (i.currentState == state.DivergenceFound) {
            currentState = "DivergenceFound";
        }

        return (
            i.challenger,
            i.claimer,
            i.queryArray,
            submittedArray,
            hashArray,
            currentState,
            uintValues
        );
    }

    /*
    function challenger(uint256 _index) public view returns (address) {
        return instance[_index].challenger;
    }

    function claimer(uint256 _index) public view returns (address) {
        return instance[_index].claimer;
    }

    function finalTime(uint256 _index) public view returns (uint) {
        return instance[_index].finalTime;
    }

    function querySize(uint256 _index) public view returns (uint) {
        return instance[_index].querySize;
    }

    function timeOfLastMove(uint256 _index) public view returns (uint) {
        return instance[_index].timeOfLastMove;
    }

    function roundDuration(uint256 _index) public view returns (uint) {
        return instance[_index].roundDuration;
    }
    */
    function divergenceTime(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (uint256)
    {
        return instance[_index].divergenceTime;
    }

    function timeSubmitted(uint256 _index, uint256 key)
        public
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].timeSubmitted[key];
    }

    function timeHash(uint256 _index, uint256 key)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        return instance[_index].timeHash[key];
    }

    function queryArray(uint256 _index, uint256 i)
        public
        view
        onlyInstantiated(_index)
        returns (uint256)
    {
        return instance[_index].queryArray[i];
    }

    function getPartitionGameIndex(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (uint256)
    {
        return instance[_index].partitionGameIndex;
    }

    function getQuerySize(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (uint256)
    {
        return instance[_index].querySize;
    }

    // state getters

    function isConcerned(uint256 _index, address _user)
        public
        override
        view
        returns (bool)
    {
        return ((instance[_index].challenger == _user) ||
            (instance[_index].claimer == _user));
    }

    function getSubInstances(uint256, address)
        public
        override
        pure
        returns (address[] memory, uint256[] memory)
    {
        address[] memory a = new address[](0);
        uint256[] memory i = new uint256[](0);
        return (a, i);
    }

    function getCurrentState(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.WaitingQuery) {
            return "WaitingQuery";
        }
        if (instance[_index].currentState == state.WaitingHashes) {
            return "WaitingHashes";
        }
        if (instance[_index].currentState == state.ChallengerWon) {
            return "ChallengerWon";
        }
        if (instance[_index].currentState == state.ClaimerWon) {
            return "ClaimerWon";
        }
        if (instance[_index].currentState == state.DivergenceFound) {
            return "DivergenceFound";
        }
        require(false, "Unrecognized state");
    }

    // remove these functions and change tests accordingly
    function stateIsWaitingQuery(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingQuery;
    }

    function stateIsWaitingHashes(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingHashes;
    }

    function stateIsChallengerWon(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ChallengerWon;
    }

    function stateIsClaimerWon(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.ClaimerWon;
    }

    function stateIsDivergenceFound(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.DivergenceFound;
    }

    // split an interval using (querySize) points (placed in queryArray)
    // leftPoint rightPoint are always the first and last points in queryArray.
    function slice(
        uint256 _index,
        uint256 leftPoint,
        uint256 rightPoint
    ) internal {
        require(
            rightPoint > leftPoint,
            "rightPoint has to be bigger than leftPoint"
        );
        uint256 i;
        uint256 intervalLength = rightPoint - leftPoint;
        uint256 queryLastIndex = instance[_index].querySize - 1;
        // if intervalLength is not big enough to allow us jump sizes larger then
        // one, we go step by step
        if (intervalLength < 2 * queryLastIndex) {
            for (i = 0; i < queryLastIndex; i++) {
                if (leftPoint + i < rightPoint) {
                    instance[_index].queryArray[i] = leftPoint + i;
                } else {
                    instance[_index].queryArray[i] = rightPoint;
                }
            }
        } else {
            // otherwise: intervalLength = (querySize - 1) * divisionLength + j
            // with divisionLength >= 1 and j in {0, ..., querySize - 2}. in this
            // case the size of maximum slice drops to a proportion of intervalLength
            uint256 divisionLength = intervalLength / queryLastIndex;
            for (i = 0; i < queryLastIndex; i++) {
                instance[_index].queryArray[i] = leftPoint + i * divisionLength;
            }
        }
        instance[_index].queryArray[queryLastIndex] = rightPoint;
    }

    //TODO: It is supposed to be log10 * C, because we're using a partition of 10
    function log2OverTwo(uint256 x) public pure returns (uint256 y) {
        uint256 leading = 256;

        while (x != 0) {
            x = x >> 1;
            leading--;
        }
        // plus one to do an approx ceiling
        return (255 - leading) / 2;
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

pragma solidity ^0.7.0;


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


pragma solidity ^0.7.0;


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

pragma solidity ^0.7.0;

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

// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

/// @title Abstract interface for partition instantiator
pragma solidity ^0.7.0;

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

    function getCurrentStateDeadline(uint _index) external view returns (uint time);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) external view returns (uint256);
}