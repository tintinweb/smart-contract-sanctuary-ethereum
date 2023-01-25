// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity 0.8.17;

import "./interfaces/IDisperseNative.sol";

/**
 * @title DisperseNative
 * @author Tim Loh
 */
contract DisperseNative is IDisperseNative {
    function disperseNative(address[] calldata recipients, uint256[] calldata values) external payable override {
        require(recipients.length > 0, "Disperse: length");
        require(recipients.length == values.length, "Disperse: diff len");

        emit NativeDispersed(msg.value, recipients.length);

        for (uint256 i = 0; i < recipients.length; ++i) {
            require(recipients[i] != address(0), "Disperse: recipient");
            require(values[i] != 0, "Disperse: value");

            // https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
            // https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
            // slither-disable-next-line arbitrary-send-eth,calls-loop
            payable(recipients[i]).transfer(values[i]);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2023 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title DisperseNative Interface
 * @author Tim Loh
 * @notice Interface for DisperseNative where native tokens will be dispersed to multiple recipients
 */
interface IDisperseNative {
    /**
     * @notice Emitted when native tokens have been successfully dispersed
     * @param total Total amount transferred
     * @param numRecipients Total number of recipients
     */
    event NativeDispersed(
        uint256 total,
        uint256 numRecipients
    );

    function disperseNative(address[] calldata recipients, uint256[] calldata values) external payable;
}