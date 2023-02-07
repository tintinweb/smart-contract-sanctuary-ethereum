// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Echoer for Nouns Connect Proposal Attribution
/// @notice See nounsconnect.wtf // github.com/ourzora/nouns-connect
/// @dev Simple echoer for proposal attribution
contract NounsConnectEchoer {
    event NounsConnectUsed(address sender, string uri, string attribution);

    function createdWithNounsConnect() external {
        emit NounsConnectUsed(
            msg.sender,
            "https://nounsconnect.wtf",
            "This proposal was created with nouns connect"
        );
    }
}