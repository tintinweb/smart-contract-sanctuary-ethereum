// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISolution.sol";
import "./interfaces/IStarknetCore.sol";

contract L1MessageSender {

  IStarknetCore starknetCore;
    uint256 private CLAIM_SELECTOR;
    uint256 private _l2EvaluatorAddress;

    constructor(
        address starknetCore_,
        uint256 _address
    ) {
        starknetCore = IStarknetCore(starknetCore_);
        _l2EvaluatorAddress = _address;

    }

    function setClaimSelector(uint256 _claimSelector) external{
        CLAIM_SELECTOR = _claimSelector;
    }

    function createNftFromL2(uint256 l2_user) public {
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            _l2EvaluatorAddress,
            CLAIM_SELECTOR,
            sender_payload
        );
    }

    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2User;
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ISolution {
    function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external;
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