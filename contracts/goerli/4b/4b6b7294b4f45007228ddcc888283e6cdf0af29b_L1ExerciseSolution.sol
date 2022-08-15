/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

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

contract L1ExerciseSolution {
    IStarknetCore public constant STARKNET_CORE = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    uint256 public constant EX2_SELECTOR = 897827374043036985111827446442422621836496526085876968148369565281492581228;
    uint256 public constant EVALUATOR_ADDRESS = 2526149038677515265213650328426051013974292914551952046681512871525993794969;

    function triggerEx2L2(uint256 _l2User) public {        
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = _l2User;

        // Send the message to the StarkNet core contract.
        STARKNET_CORE.sendMessageToL2(
            EVALUATOR_ADDRESS,
            EX2_SELECTOR,
            sender_payload
        );
    }
}