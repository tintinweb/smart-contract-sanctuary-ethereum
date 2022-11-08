// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///@title UnrolledCordic.sol
///@author Gabriel Barros, Diego Nehab
pragma solidity ^0.8.0;

library UnrolledCordic {
    uint256 constant one = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant log2_e = 0xb8aa3b295c17f0bbbe87fed0691d3e88eb577aa8dd695a588b25166cd1a13248;

    uint64 constant N = 64;
    uint256 constant log2_ks0 = 0xb31fb7d64898b3e15c01a39fbd687a02934f0979a3715fd4ae00d1cfdeb43d0;
    uint256 constant log2_ks1 = 0xb84e236bd563ba016fe50b6ef0851802dcf2d0b85a453105aeb4dd63bf61cc;
    uint256 constant log2_ks2 = 0xb8a476150dfe4001713d62f7957c3002e24ca6e87e8a8005c3e0ffc29d593;
    uint256 constant log2_ks3 = 0xb8a9ded47c110001715305002e4b0002e2a32762fa6c0005c53ac47e94d9;
    uint256 constant log2_ks4 = 0xb8aa35640a80000171545f3d72b00002e2a8905062300005c55067f6e59;
    uint256 constant log2_ks5 = 0xb8aa3acd07000001715474e164000002e2a8e6e01f000005c551c2359a;

    function log2m64(uint256 x) internal pure returns (uint256) {
        uint256 y = 0;
        uint256 t;

        unchecked {
            // round(log_2(1+1/2^i)*2^64) for i = 1..4 packed into 64bits each
            t = x + (x >> 1);
            if (t < one) {
                x = t;
                y += log2_ks0 << 192;
            }
            t = x + (x >> 2);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 64) << 192;
            }
            t = x + (x >> 3);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 128) << 192;
            }
            t = x + (x >> 4);
            if (t < one) {
                x = t;
                y += (log2_ks0 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 5..8 packed into 64bits each
            t = x + (x >> 5);
            if (t < one) {
                x = t;
                y += log2_ks1 << 192;
            }
            t = x + (x >> 6);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 64) << 192;
            }
            t = x + (x >> 7);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 128) << 192;
            }
            t = x + (x >> 8);
            if (t < one) {
                x = t;
                y += (log2_ks1 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 9..12 packed into 64bits each
            t = x + (x >> 9);
            if (t < one) {
                x = t;
                y += log2_ks2 << 192;
            }
            t = x + (x >> 10);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 64) << 192;
            }
            t = x + (x >> 11);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 128) << 192;
            }
            t = x + (x >> 12);
            if (t < one) {
                x = t;
                y += (log2_ks2 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 13..16 packed into 64bits each
            t = x + (x >> 13);
            if (t < one) {
                x = t;
                y += log2_ks3 << 192;
            }
            t = x + (x >> 14);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 64) << 192;
            }
            t = x + (x >> 15);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 128) << 192;
            }
            t = x + (x >> 16);
            if (t < one) {
                x = t;
                y += (log2_ks3 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 17..20 packed into 64bits each
            t = x + (x >> 17);
            if (t < one) {
                x = t;
                y += log2_ks4 << 192;
            }
            t = x + (x >> 18);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 64) << 192;
            }
            t = x + (x >> 19);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 128) << 192;
            }
            t = x + (x >> 20);
            if (t < one) {
                x = t;
                y += (log2_ks4 >> 192) << 192;
            }
            // round(log_2(1+1/2^i)*2^64) for i = 21..24 packed into 64bits each
            t = x + (x >> 21);
            if (t < one) {
                x = t;
                y += log2_ks5 << 192;
            }
            t = x + (x >> 22);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 64) << 192;
            }
            t = x + (x >> 23);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 128) << 192;
            }
            t = x + (x >> 24);
            if (t < one) {
                x = t;
                y += (log2_ks5 >> 192) << 192;
            }

            uint256 r = one - x;
            y += mulhi128(log2_e, mulhi128(r, one + (r >> 1)) << 1) << 1;
            return y >> (255 - 64);
        }
    }

    function log2Times1e18(uint256 val) external pure returns (uint256) {
        int256 il = ilog2(val);
        uint256 skewedRes;
        unchecked {
            if (il + 1 <= 255) {
                skewedRes = (uint256(il + 1) << N) - log2m64(val << (255 - uint256(il + 1)));
            } else {
                skewedRes = (uint256(il + 1) << N) - log2m64(val >> uint256((il + 1) - 255));
            }
            return (skewedRes * 1e18) >> N;
        }
    }

    function mulhi128(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >> 128) * (b >> 128);
        }
    }

    function ilog2(uint256 val) internal pure returns (int256) {
        require(val > 0, "must be greater than zero");
        unchecked {
            return 255 - int256(clz(val));
        }
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) internal pure returns (uint256) {
        if (_num == 0) return 256;
        unchecked {
            uint256 n = 0;
            if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) {
                n = n + 128;
                _num = _num << 128;
            }
            if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) {
                n = n + 64;
                _num = _num << 64;
            }
            if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 32;
                _num = _num << 32;
            }
            if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 16;
                _num = _num << 16;
            }
            if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 8;
                _num = _num << 8;
            }
            if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 4;
                _num = _num << 4;
            }
            if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 2;
                _num = _num << 2;
            }
            if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) {
                n = n + 1;
            }

            return n;
        }
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

/// @title Block Selector Library

pragma solidity ^0.8.0;

import "@cartesi/util/contracts/UnrolledCordic.sol";

library Eligibility {
    uint256 constant C_40 = 40; // 40 blocks
    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256 * 1e18; // 256 with 18 decimal places
    uint256 constant UINT256_MAX = 2 ** 256 - 1;

    /// @notice Check when address is allowed to produce block
    /// @param _difficulty difficulty of current selection process
    /// @param _ethBlockStamp ethereum block number when current selection started
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function whenCanProduceBlock(
        uint256 _difficulty,
        uint256 _ethBlockStamp,
        address _user,
        uint256 _weight
    ) external view returns (uint256) {
        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        // cannot produce if weight is zero
        //slither-disable-next-line  incorrect-equality
        if (getSelectionBlocksPassed(_ethBlockStamp) == 0 || _weight == 0) {
            return UINT256_MAX;
        }

        uint256 multiplier;
        // we want overflow and underflow on purpose
        unchecked {
            multiplier =
                DIFFICULTY_BASE_MULTIPLIER -
                getLogOfRandom(_user, _ethBlockStamp);
        }

        uint256 blocksToWait = (_difficulty * multiplier) / (_weight * 1e12);
        // restore the multiple 256 based on current block number
        //slither-disable-next-line  divide-before-multiply
        uint256 cycleOf256 = C_256 *
            ((block.number - _ethBlockStamp - C_40 - 1) / C_256);

        return blocksToWait + _ethBlockStamp + C_40 + cycleOf256;
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _user address to calculate log of random
    /// @param _ethBlockStamp main chain block number of last sidechain block
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(
        address _user,
        uint256 _ethBlockStamp
    ) internal view returns (uint256) {
        // seed for goal takes a block in the future (+40) so it is harder to manipulate
        bytes32 currentGoal = blockhash(
            getSeed(_ethBlockStamp + C_40, block.number)
        );
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(
            keccak256(abi.encodePacked(hashedAddress, currentGoal))
        );

        return UnrolledCordic.log2Times1e18(distance);
    }

    function getSeed(
        uint256 _previousTarget,
        uint256 _currentBlock
    ) internal pure returns (uint256) {
        uint256 diff = _currentBlock - _previousTarget;
        //slither-disable-next-line  divide-before-multiply
        uint256 res = diff / C_256;

        // if difference is multiple of 256 (256, 512, 1024)
        // preserve old target
        //slither-disable-next-line  incorrect-equality
        if (diff % C_256 == 0) {
            return _previousTarget + ((res - 1) * C_256);
        }

        //slither-disable-next-line  divide-before-multiply
        return _previousTarget + (res * C_256);
    }

    /// @notice Returns the duration in blocks of current selection proccess
    /// @param _ethBlockStamp ethereum block number of last sidechain block
    /// @return number of ethereum blocks passed since last selection goal was defined
    /// @dev blocks passed resets when target resets
    function getSelectionBlocksPassed(
        uint256 _ethBlockStamp
    ) internal view returns (uint256) {
        unchecked {
            // new goal block is decided 40 blocks after sidechain block is created
            uint256 goalBlock = _ethBlockStamp + C_40;

            // target hasnt been set
            if (goalBlock >= block.number) return 0;

            uint256 blocksPassed = block.number - goalBlock;

            // if blocksPassed is multiple of 256, 256 blocks have passed
            // this avoids blocksPassed going to zero right before target change
            //slither-disable-next-line  incorrect-equality
            if (blocksPassed % C_256 == 0) return C_256;

            return blocksPassed % C_256;
        }
    }
}