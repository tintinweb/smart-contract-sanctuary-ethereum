// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IStarknetCore.sol";

contract L1Consumption {

    IStarknetCore immutable starknetcore;

    constructor(IStarknetCore _starknetcore) {
        require(address(_starknetcore) != address(0), "Address is a zero address");
        starknetcore = _starknetcore;
    } 

    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;

        starknetcore.consumeMessageFromL2(l2ContractAddress, payload);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.
      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Starts the cancellation of an L1 to L2 message.
      A message can be canceled messageCancellationDelay() seconds after this function is called.
      Note: This function may only be called for a message that is currently pending and the caller
      must be the sender of the that message.
    */
    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;

    /**
      Cancels an L1 to L2 message, this function should be called messageCancellationDelay() seconds
      after the call to startL1ToL2MessageCancellation().
    */
    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;
}