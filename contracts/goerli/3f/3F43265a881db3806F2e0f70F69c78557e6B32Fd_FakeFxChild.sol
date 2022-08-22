// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/// @dev This is NOT a secure FxChild contract implementation!
/// DO NOT USE in production.

/**
 * @title FxChild child contract for state receiver
 */
contract FakeFxChild {
    function onStateReceive(
        uint256 stateId,
        address receiver,
        address rootMessageSender,
        bytes memory data
    ) external {
        IFxMessageProcessor(receiver).processMessageFromRoot(stateId, rootMessageSender, data);
    }
}