// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/**
 * @notice extract global manifest constants
 * @dev hash b28717930d5c821c80736e02d025efa7f9cb615e deployed to 0xaDFDc9ADe7B4199179E0eeF0ce8e67E12a92A50F
 */
library Constant {
    uint256 public constant UINT_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @notice minimum quorum
    uint256 public constant MINIMUM_PROJECT_QUORUM = 1;

    /// @notice minimum vote duration
    /// @dev For security reasons this must be a relatively long time compared to seconds
    uint256 public constant MINIMUM_VOTE_DURATION = 1 hours;

    /// @notice minimum vote delay
    /// @dev A vote delay is recommended to support cancellation of votes, however it is not
    ///      required
    uint256 public constant MINIMUM_VOTE_DELAY = 0 days;

    // timelock setup

    /// @notice maximum time allowed after the nonce to successfully execute the time lock
    uint256 public constant TIMELOCK_GRACE_PERIOD = 14 days;
    /// @notice the minimum lock period
    uint256 public constant TIMELOCK_MINIMUM_DELAY = MINIMUM_VOTE_DURATION;
    /// @notice the maximum lock period
    uint256 public constant TIMELOCK_MAXIMUM_DELAY = 30 days;

    /// @notice limit for string information in meta data
    uint256 public constant STRING_DATA_LIMIT = 1024;

    /// @notice The maximum priority fee
    uint256 public constant MAXIMUM_REBATE_PRIORITY_FEE = 2 gwei;
    /// @notice The vote rebate gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REBATE_BASE_GAS = 36000;
    /// @notice The maximum refundable gas used
    uint256 public constant MAXIMUM_REBATE_GAS_USED = 200_000;
    /// @notice the maximum allowed gas fee for rebate
    uint256 public constant MAXIMUM_REBATE_BASE_FEE = 200 gwei;

    uint32 public constant VERSION_1 = 1;

    /// @notice Compute the length of any string in solidity
    /// @dev This method is expensive and is used only for validating
    ///      inputs on the creation of new Governance contract
    ///      or upon the configuration of a new vote
    function len(string memory str) external pure returns (uint256) {
        uint256 bytelength = bytes(str).length;
        uint256 i = 0;
        uint256 length;
        for (length = 0; i < bytelength; length++) {
            bytes1 b = bytes(str)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return length;
    }

    /**
     * Calculate the hash code of the specified transaction.  This is used as the transaction id
     * for marking the transaction as queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 The 32 byte hash of the transaction
     */
    function getTxHash(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _signature, _calldata, _scheduleTime));
    }
}