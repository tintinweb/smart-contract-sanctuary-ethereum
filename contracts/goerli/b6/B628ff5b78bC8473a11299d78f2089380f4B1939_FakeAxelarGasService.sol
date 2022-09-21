// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract FakeAxelarGasService {
    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable {
        emit NativeGasPaidForContractCall(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            msg.value,
            refundAddress
        );
    }
}