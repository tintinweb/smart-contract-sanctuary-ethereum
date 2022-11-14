/**
 *Submitted for verification at Etherscan.io on 2022-11-14
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

contract ExerciseSolutionEx2 {
    uint256 L2_EVALUATOR =
        0x595bfeb84a5f95de3471fc66929710e92c12cce2b652cd91a6fef4c5c09cd99;
    uint256 EX2_FUNCTION_SELECTOR = 6649906;
    uint256 L2_USER_ADDRESS =
        0x073eb291861D13Aa2584626Fb8759ACbDAD2C513A487254a993D6Fd2c6dC3Be4;
    IStarknetCore starknetCore =
        IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);

    function setEvaluatorContractAddress() external {
        uint256[] memory payload = new uint256[](1);
        payload[0] = L2_USER_ADDRESS;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            L2_EVALUATOR,
            EX2_FUNCTION_SELECTOR,
            payload
        );
    }
}