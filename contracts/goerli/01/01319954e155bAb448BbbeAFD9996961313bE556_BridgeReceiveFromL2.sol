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


contract BridgeReceiveFromL2 {

    IStarknetCore starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    uint256 EvaluatorContractAddress = 2526149038677515265213650328426051013974292914551952046681512871525993794969;
    uint256 l2_user = 1943269151862530175093541856709987426477488245381860452130698027176723259294;


    constructor() {}


    function consumeMessage(uint256 l2_evaluator, uint256 user_l2) public {

        uint256[] memory payload = new uint256[](1);
        payload[0] = user_l2;

        starknetCore.consumeMessageFromL2(l2_evaluator, payload);
  
    }

}