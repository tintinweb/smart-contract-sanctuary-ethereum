// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStarknetCore.sol";


contract L1ReceiveMsgFromL2 {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    constructor(
        address starknetCore_
    ) public {
        starknetCore = IStarknetCore(starknetCore_);
    }

    // The address of the L2 contract that interacts with this L1 contract
    uint256 constant fromAddress = uint256(0x595bfeb84a5f95de3471fc66929710e92c12cce2b652cd91a6fef4c5c09cd99);
    // uint256 constant sender_address = uint256(0x471E613A7C5d3b89E3c22CD5C3367885B2ee6538);

     /**
      Consumes a message that was sent from an L2 contract.
     */
    function consumeMessage(bytes32 messageToL2) public {

        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](1);
        payload[0] = uint256(messageToL2);

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(fromAddress, payload);

    }
        
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
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

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}