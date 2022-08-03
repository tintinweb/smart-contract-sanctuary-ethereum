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