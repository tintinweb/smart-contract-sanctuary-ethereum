// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Difficulty Library

pragma solidity ^0.8.0;

library Difficulty {
    uint32 constant ADJUSTMENT_BASE = 1e6; // 1M

    /// @notice Calculates new difficulty parameter
    function getNewDifficulty(
        uint256 _minDifficulty,
        uint256 _difficulty,
        uint256 _difficultyAdjustmentParameter,
        uint256 _targetInterval,
        uint256 _blocksPassed
    ) external pure returns (uint256) {
        uint256 adjustment = (_difficulty * _difficultyAdjustmentParameter) /
            ADJUSTMENT_BASE +
            1;

        // @dev to save gas on evaluation, instead of returning the _oldDiff when the target
        // was exactly matched - we increase the difficulty.
        if (_blocksPassed <= _targetInterval) {
            return _difficulty + adjustment;
        }

        uint256 newDiff = _difficulty - adjustment;

        return newDiff > _minDifficulty ? newDiff : _minDifficulty;
    }
}