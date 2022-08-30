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


     /**
      Consumes a message that was sent from an L2 contract.
     */

    function consumeMessage(uint256 l2Contract) external {

        // Define payload
        uint256[] memory payload = new uint256[](1);
        payload[0] = uint256(uint160(msg.sender));

        // Consume the message from the StarkNet core contract.
        starknetCore.consumeMessageFromL2(l2Contract, payload);

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