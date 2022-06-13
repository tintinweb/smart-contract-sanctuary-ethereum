/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

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

contract L1L2Msg {

    IStarknetCore starknetCore;
    uint256 private evaluatorContractAddress;
    uint256 EX2_SELECTOR = 897827374043036985111827446442422621836496526085876968148369565281492581228;

    constructor (address starknetCore_, uint256 evaluatorContractAddress_) {
        starknetCore = IStarknetCore(starknetCore_);
        evaluatorContractAddress = evaluatorContractAddress_;

    }

    function createNftFromL1(uint256 l2_user) public {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            evaluatorContractAddress,
            EX2_SELECTOR,
            sender_payload
        );
    }

}