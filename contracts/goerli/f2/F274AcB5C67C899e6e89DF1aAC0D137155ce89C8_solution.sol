// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStarknetCore.sol";
import "./interfaces/ISolution.sol";

contract solution is ISolution {
    mapping(address => uint256) public storage_testing;
    IStarknetCore starknetCore;
    uint256 private CLAIM_SELECTOR;

    constructor(address starknetCore_, uint256 _CLAIM_SELECTOR) {
        starknetCore = IStarknetCore(starknetCore_);
        CLAIM_SELECTOR = _CLAIM_SELECTOR;
    }

    function getStorage() public view returns (uint256) {
        return storage_testing[msg.sender];
    }

    function setStorage(uint256 value) public {
        storage_testing[msg.sender] = value;
    }

    function mintL2Nft(uint256 EvaluatorContractAddress, uint256 l2_user)
        public
    {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            CLAIM_SELECTOR,
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