// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IStarknetCore.sol";
import "./interfaces/ISolution.sol";

contract ExerciseSolution is ISolution {
    IStarknetCore starknetCore;
    address private evaluatorContractAddressL1;
    uint256 private evaluatorContractAddressL2;
    uint256 private constant EX2_SELECTOR =
        897827374043036985111827446442422621836496526085876968148369565281492581228;

    event L2MessageConsumed(
        uint256 indexed l2From,
        uint256 indexed l2User,
        bytes32 msgHash
    );

    constructor(
        address _starknetCore,
        address _evaluatorContractAddressL1,
        uint256 _evaluatorContractAddressL2
    ) {
        starknetCore = IStarknetCore(_starknetCore);
        evaluatorContractAddressL1 = _evaluatorContractAddressL1;
        evaluatorContractAddressL2 = _evaluatorContractAddressL2;
    }

    function triggerEvaluatorEx2Handler(uint256 l2_user) external {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        starknetCore.sendMessageToL2(
            evaluatorContractAddressL2,
            EX2_SELECTOR,
            sender_payload
        );
    }

    function consumeMessage(uint256 l2ContractAddress, uint256 l2User)
        external
    {
        require(
            msg.sender == evaluatorContractAddressL1,
            "Only L1 Evaluator can call this function"
        );
        uint256[] memory message_payload = new uint256[](1);
        message_payload[0] = l2User;
        bytes32 msgHash = starknetCore.consumeMessageFromL2(
            l2ContractAddress,
            message_payload
        );
        emit L2MessageConsumed(l2ContractAddress, l2User, msgHash);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ISolution {
    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external;
}