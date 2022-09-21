// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract FakeAxelarGateway {
    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    function callContract(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload
    ) external {
        emit ContractCall(
            msg.sender,
            destinationChain,
            destinationContractAddress,
            keccak256(payload),
            payload
        );
    }
}