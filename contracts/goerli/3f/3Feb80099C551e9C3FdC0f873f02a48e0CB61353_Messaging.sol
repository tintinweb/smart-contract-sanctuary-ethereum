/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// File: interfaces/IStarknetCore.sol


pragma solidity ^0.8.13;

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

// File: Messaging.sol



pragma solidity ^0.8.0;


contract Messaging {
    IStarknetCore starknetCore;
    uint256 private CLAIM_SELECTOR;
    uint256 private EvaluatorContractAddress;

    constructor(address starknetCore_) {
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

    function sendMessage(uint256 l2_user) public {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2_user;
        starknetCore.sendMessageToL2(
            EvaluatorContractAddress,
            CLAIM_SELECTOR,
            payload
        );
    }
}