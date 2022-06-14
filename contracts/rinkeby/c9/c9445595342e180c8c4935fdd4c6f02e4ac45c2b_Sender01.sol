/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GLWTPL

pragma solidity ^0.8.14;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;
}

contract Sender01 {

    // The Multichain anycall contract on Rinkeby testnet
    address private anycallContractRinkeby = 0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02;

    address private ownerAddress;

    // Destination contract on FTM testnet
    address private receiverContract;

    // Destination chain id
    uint256 private destinationChainId = 4002; // FTM testnet

    event Send(string message);

    constructor(address _receiverContract) {
        ownerAddress = msg.sender;
        receiverContract = _receiverContract;
    }

    function send(string calldata _message) external {
        emit Send(_message);

        CallProxy(anycallContractRinkeby).anyCall(
            receiverContract,
            abi.encode(_message),
            address(0), // no fallback
            destinationChainId,
            0
        );
    }
}