// SPDX-License-Identifier: MIT.

pragma solidity ^0.8.9;

interface IStarknetCore {
    // Consumes a message that was sent from an L2 contract. Returns the hash of the message
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);
}

contract TestGatewayContract {
    // The StarkNet core contract
    IStarknetCore starknetCore;

    mapping(uint256 => bool) public withdrawAllowances;

    uint256 constant MESSAGE_APPROVE = 1;

    constructor(IStarknetCore _starknetCore) {
        starknetCore = _starknetCore;
    }

    function receiveFromStorageProver(
        uint256 userAddress,
        uint256 L2StorageProverAddress
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = MESSAGE_APPROVE;
        payload[1] = userAddress;

        // L2StorageProverAddress is passed in as an input but we should eventually hardcode it into the contract
        starknetCore.consumeMessageFromL2(L2StorageProverAddress, payload);

        withdrawAllowances[userAddress] = true;
    }
}