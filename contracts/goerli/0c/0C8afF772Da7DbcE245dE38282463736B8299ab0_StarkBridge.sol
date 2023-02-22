// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;


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


contract StarkBridge {

    IStarknetCore starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    uint256 EvaluatorContractAddress = 2526149038677515265213650328426051013974292914551952046681512871525993794969;
    uint256 ex2_selector = 897827374043036985111827446442422621836496526085876968148369565281492581228;
    uint256 l2_user = 1943269151862530175093541856709987426477488245381860452130698027176723259294;


    constructor() {}


    function sendMessageL2() public {

        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;

        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            ex2_selector,
            sender_payload
        );
    }

}