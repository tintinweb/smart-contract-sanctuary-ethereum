// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract Ex2{
    IStarknetCore starknetCore;
    uint256 private CLAIM_SELECTOR;
    uint256 private EvaluatorContractAddress;

    constructor(
        address starknetCore_
    ) {
        starknetCore = IStarknetCore(starknetCore_);

    }

    function setClaimSelector(uint256 _claimSelector) external {
        CLAIM_SELECTOR = _claimSelector;
    }

    function setEvaluatorContractAddress(uint256 _evaluatorContractAddress)
        external
    {
        EvaluatorContractAddress = _evaluatorContractAddress;
    }

    function sendMessageToL2(uint256 l2_user) public returns(bool){
        uint256[] memory sender_payload = new uint256[](1);
        sender_payload[0] = l2_user;
        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            CLAIM_SELECTOR,
            sender_payload
        );
        return true;
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