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

contract L1ExerciseSolution3 {
    IStarknetCore public constant STARKNET_CORE = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);

    function consumeMessage(uint256 _l2Evaluator, uint256 _l2User) public {        
        uint256[] memory payload = new uint256[](1);
        payload[0] = _l2User;

        STARKNET_CORE.consumeMessageFromL2(_l2Evaluator, payload);
    }
}