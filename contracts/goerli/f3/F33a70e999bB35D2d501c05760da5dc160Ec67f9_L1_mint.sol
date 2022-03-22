// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IStarknetCore.sol";
import "ISolution.sol";

contract L1_mint is ISolution {
    IStarknetCore starknetCore;

    constructor() {
        starknetCore = IStarknetCore(
            0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        );
    }

    function mint_nft(uint256 l2user, uint256 EvaluatorContractAddress) public {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2user;
        uint256 selector = 897827374043036985111827446442422621836496526085876968148369565281492581228;
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            selector,
            sender_payload
        );
    }

    function consumeMessage(uint256 l2ContractAddress, uint256 l2User)
        external
        override
    {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
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