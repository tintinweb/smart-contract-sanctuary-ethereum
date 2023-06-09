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

/// @title An instantiator of memory managers
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "./MMInterface.sol";
import "@cartesi/util/contracts/Merkle.sol";

contract MMInstantiator is InstantiatorImpl, MMInterface, Decorated {
    // the provider will fill the memory for the client to read and write
    // memory starts with hash and all values that are inserted are first verified
    // then client can read inserted values and write some more
    // finally the provider has to update the hash to account for writes

    struct ReadWrite {
        bool wasRead;
        uint64 position;
        bytes8 value;
    }

    // IMPLEMENT GARBAGE COLLECTOR AFTER AN INSTACE IS FINISHED!
    struct MMCtx {
        address owner;
        address provider;
        bytes32 initialHash;
        bytes32 newHash; // hash after some write operations have been proved
        ReadWrite[] history;
        state currentState;
    }

    mapping(uint256 => MMCtx) internal instance;

    // These are the possible states and transitions of the contract.
    //
    // +---+
    // |   |
    // +---+
    //   |
    //   | instantiate
    //   v
    // +---------------+    | proveRead
    // | WaitingProofs |----| proveWrite
    // +---------------+
    //   |
    //   | finishProofPhase
    //   v
    // +----------------+    |read
    // | WaitingReplay  |----|write
    // +----------------+
    //   |
    //   | finishReplayPhase
    //   v
    // +----------------+
    // | FinishedReplay |
    // +----------------+
    //

    event MemoryCreated(uint256 _index, bytes32 _initialHash);
    event ValueProved(
        uint256 _index,
        bool _wasRead,
        uint64 _position,
        bytes8 _value
    );
    event ValueRead(uint256 _index, uint64 _position, bytes8 _value);
    event ValueWritten(uint256 _index, uint64 _position, bytes8 _value);
    event FinishedProofs(uint256 _index);
    event FinishedReplay(uint256 _index);

    /// @notice Instantiate a memory manager instance.
    /// @param _provider address that will provide memory values/proofs.
    /// @param _initialHash hash before divergence, in which both client and provider agree.
    /// @return MemoryManager index.
    function instantiate(
        address _owner,
        address _provider,
        bytes32 _initialHash
    ) public override returns (uint256) {
        MMCtx storage currentInstance = instance[currentIndex];
        currentInstance.owner = _owner;
        currentInstance.provider = _provider;
        currentInstance.initialHash = _initialHash;
        currentInstance.newHash = _initialHash;
        currentInstance.currentState = state.WaitingProofs;
        emit MemoryCreated(currentIndex, _initialHash);

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Proves that a certain value in current memory is correct
    // @param _position The address of the value to be confirmed
    // @param _value The value in that address to be confirmed
    // @param proof The proof that this value is correct
    function proveRead(
        uint256 _index,
        uint64 _position,
        bytes8 _value,
        bytes32[] memory proof
    )
        public
        onlyInstantiated(_index)
        onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingProofs,
            "CurrentState is not WaitingProofs, cannot proveRead"
        );
        require(
            Merkle.getRoot(_position, _value, proof) ==
                instance[_index].newHash,
            "Merkle proof does not match"
        );
        instance[_index].history.push(ReadWrite(true, _position, _value));
        emit ValueProved(_index, true, _position, _value);
    }

    /// @notice Register a write operation and update newHash
    /// @param _position to be written
    /// @param _oldValue before write
    /// @param _newValue to be written
    /// @param proof The proof that the old value was correct
    function proveWrite(
        uint256 _index,
        uint64 _position,
        bytes8 _oldValue,
        bytes8 _newValue,
        bytes32[] memory proof
    )
        public
        onlyInstantiated(_index)
        onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingProofs,
            "CurrentState is not WaitingProofs, cannot proveWrite"
        );
        // check proof of old value
        require(
            Merkle.getRoot(_position, _oldValue, proof) ==
                instance[_index].newHash,
            "Merkle proof of write does not match"
        );
        // update root
        instance[_index].newHash = Merkle.getRoot(_position, _newValue, proof);
        instance[_index].history.push(ReadWrite(false, _position, _newValue));
        emit ValueProved(_index, false, _position, _newValue);
    }

    /// @notice Stop memory insertion and start read and write phase
    function finishProofPhase(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        onlyBy(instance[_index].provider)
        increasesNonce(_index)
    {
        require(
            instance[_index].currentState == state.WaitingProofs,
            "CurrentState is not WaitingProofs, cannot finishProofPhase"
        );
        instance[_index].currentState = state.WaitingReplay;
        emit FinishedProofs(_index);
    }

    /// @notice Stop write (or read) phase
    function finishReplayPhase(uint256 _index)
        public
        override
        onlyInstantiated(_index)
        onlyBy(instance[_index].owner)
        increasesNonce(_index)
    {
        require(stateIsWaitingReplay(_index), "State of MM should be WaitingReplay");
        delete (instance[_index].history);
        instance[_index].currentState = state.FinishedReplay;

        deactivate(_index);
        emit FinishedReplay(_index);
    }

    // getter methods
    function getRWArrays(uint256 _index)
    public
    override
    view
    returns (
        uint64[] memory,
        bytes8[] memory,
        bool[] memory
    )
    {
        ReadWrite[] storage his = instance[_index].history;
        uint256 length = his.length;
        uint64[] memory positions = new uint64[](length);
        bytes8[] memory values = new bytes8[](length);
        bool[] memory isRead = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            positions[i] = his[i].position;
            values[i] = his[i].value;
            isRead[i] = his[i].wasRead;
        }

        return (positions, values, isRead);
    }

    function isConcerned(uint256 _index, address _user)
        public
        override
        view
        returns (bool)
    {
        return instance[_index].provider == _user;
    }

    function getState(uint256 _index, address)
        public
        view
        onlyInstantiated(_index)
        returns (
            address _provider,
            bytes32 _initialHash,
            bytes32 _newHash,
            uint256 _numberSubmitted,
            bytes32 _currentState
        )
    {
        MMCtx memory i = instance[_index];

        return (
            i.provider,
            i.initialHash,
            i.newHash,
            i.history.length,
            getCurrentState(_index)
        );
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

    function provider(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (address)
    {
        return instance[_index].provider;
    }

    function initialHash(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        return instance[_index].initialHash;
    }

    function newHash(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        return instance[_index].newHash;
    }

    // state getters

    function getCurrentState(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        if (instance[_index].currentState == state.WaitingProofs) {
            return "WaitingProofs";
        }
        if (instance[_index].currentState == state.WaitingReplay) {
            return "WaitingReplay";
        }
        if (instance[_index].currentState == state.FinishedReplay) {
            return "FinishedReplay";
        }
        require(false, "Unrecognized state");
    }

    /// @notice Get the worst case scenario duration for a specific state
    /// @param _roundDuration security parameter, the max time an agent
    //          has to react and submit one simple transaction
    /// @param _timeToStartMachine time to build the machine for the first time
    function getMaxStateDuration(
        state _state,
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) private pure returns (uint256) {
        if (_state == state.WaitingProofs) {
            // proving siblings is assumed to be free
            // so its time to start the machine
            // + one round duration to send the proofs
            // + one transaction for finishProofPhase transaction
            return _timeToStartMachine + uint256(2) * _roundDuration;
        }
        if (_state == state.WaitingReplay) {
            // one transaction for the step function to be completed
            return _roundDuration;
        }
        if (_state == state.FinishedReplay) {
            // one transaction for finishReplay transaction
            return _roundDuration;
        }

        require(false, "Unrecognized state");
    }

    function getCurrentStateDeadline(
        uint256 _index,
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    )   public
        override
        view
        onlyInstantiated(_index)
        returns (uint256)
    {
        return getMaxStateDuration(
            instance[_index].currentState,
            _roundDuration,
            _timeToStartMachine
        );
    }

    /// @notice Get the worst case scenario duration for an instance of this contract
    /// @param _roundDuration security parameter, the max time an agent
    //          has to react and submit one simple transaction
    /// @param _timeToStartMachine time to build the machine for the first time
    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) public override pure returns (uint256) {
        uint256 waitingProofsDuration = getMaxStateDuration(
            state.WaitingProofs,
            _roundDuration,
            _timeToStartMachine
        );

        uint256 waitingReplayDuration = getMaxStateDuration(
            state.WaitingReplay,
            _roundDuration,
            _timeToStartMachine
        );

        uint256 finishProofsDuration = getMaxStateDuration(
            state.WaitingProofs,
            _roundDuration,
            _timeToStartMachine
        );

        return
            waitingProofsDuration +
            waitingReplayDuration +
            finishProofsDuration;
    }

    // remove these functions and change tests accordingly
    function stateIsWaitingProofs(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingProofs;
    }

    function stateIsWaitingReplay(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.WaitingReplay;
    }

    function stateIsFinishedReplay(uint256 _index)
        public
        override
        view
        onlyInstantiated(_index)
        returns (bool)
    {
        return instance[_index].currentState == state.FinishedReplay;
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

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


/// @title Library for Merkle proofs
pragma solidity ^0.7.0;


library Merkle {
    function getPristineHash(uint8 _log2Size) public pure returns (bytes32) {
        require(_log2Size >= 3, "Has to be at least one word");
        require(_log2Size <= 64, "Cannot be bigger than the machine itself");

        bytes8 value = 0;
        bytes32 runningHash = keccak256(abi.encodePacked(value));

        for (uint256 i = 3; i < _log2Size; i++) {
            runningHash = keccak256(abi.encodePacked(runningHash, runningHash));
        }

        return runningHash;
    }

    function getRoot(uint64 _position, bytes8 _value, bytes32[] memory proof) public pure returns (bytes32) {
        bytes32 runningHash = keccak256(abi.encodePacked(_value));

        return getRootWithDrive(
            _position,
            3,
            runningHash,
            proof
        );
    }

    function getRootWithDrive(
        uint64 _position,
        uint8 _logOfSize,
        bytes32 _drive,
        bytes32[] memory siblings
    ) public pure returns (bytes32)
    {
        require(_logOfSize >= 3, "Must be at least a word");
        require(_logOfSize <= 64, "Cannot be bigger than the machine itself");

        uint64 size = uint64(2) ** _logOfSize;

        require(((size - 1) & _position) == 0, "Position is not aligned");
        require(siblings.length == 64 - _logOfSize, "Proof length does not match");

        bytes32 drive = _drive;

        for (uint64 i = 0; i < siblings.length; i++) {
            if ((_position & (size << i)) == 0) {
                drive = keccak256(abi.encodePacked(drive, siblings[i]));
            } else {
                drive = keccak256(abi.encodePacked(siblings[i], drive));
            }
        }

        return drive;
    }

    function getLog2Floor(uint256 number) public pure returns (uint8) {

        uint8 result = 0;

        uint256 checkNumber = number;
        checkNumber = checkNumber >> 1;
        while (checkNumber > 0) {
            ++result;
            checkNumber = checkNumber >> 1;
        }

        return result;
    }

    function isPowerOf2(uint256 number) public pure returns (bool) {

        uint256 checkNumber = number;
        if (checkNumber == 0) {
            return false;
        }

        while ((checkNumber & 1) == 0) {
            checkNumber = checkNumber >> 1;
        }

        checkNumber = checkNumber >> 1;

        if (checkNumber == 0) {
            return true;
        }

        return false;
    }

    /// @notice Calculate the root of Merkle tree from an array of power of 2 elements
    /// @param hashes The array containing power of 2 elements
    /// @return byte32 the root hash being calculated
    function calculateRootFromPowerOfTwo(bytes32[] memory hashes) public pure returns (bytes32) {
        // revert when the input is not of power of 2
        require(isPowerOf2(hashes.length), "The input array must contain power of 2 elements");

        if (hashes.length == 1) {
            return hashes[0];
        }else {
            bytes32[] memory newHashes = new bytes32[](hashes.length >> 1);

            for (uint256 i = 0; i < hashes.length; i += 2) {
                newHashes[i >> 1] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
            }

            return calculateRootFromPowerOfTwo(newHashes);
        }
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

/// @title Interface for memory manager instantiator
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface MMInterface is Instantiator {
    enum state {WaitingProofs, WaitingReplay, FinishedReplay}

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _owner,
        address _provider,
        bytes32 _initialHash
    ) external returns (uint256);

    function newHash(uint256 _index) external view returns (bytes32);

    function finishProofPhase(uint256 _index) external;

    function finishReplayPhase(uint256 _index) external;

    function getRWArrays(
        uint256 _index
    )
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