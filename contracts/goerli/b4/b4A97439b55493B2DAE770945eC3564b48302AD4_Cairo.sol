// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./interfaces/IStarknetCore.sol";

contract Cairo {
    uint256 public EX2_SELECTOR;
    uint256 public EvaluatorContractAddress;
    IStarknetCore public starknetCore;

    constructor() {
        EX2_SELECTOR = 897827374043036985111827446442422621836496526085876968148369565281492581228;
        starknetCore = IStarknetCore(
            0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        );
        EvaluatorContractAddress = 2526149038677515265213650328426051013974292914551952046681512871525993794969;
    }

    function callL2(uint256 l2_user) public {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            EX2_SELECTOR,
            sender_payload
        );
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