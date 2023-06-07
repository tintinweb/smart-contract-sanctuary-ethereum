/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BridgeEvents {
    uint16 public nativeChainId;
    uint256 actionId;
    // Incomming transaction parameters
    struct InstallmentIn {
        uint256 amount; // Transfered amount > 0, < 2^256
        uint16 chainId; // Original chain nonce
        string tokenSymbol; // Ex.: USDT, BNB...
        address payable destinationAddress; // Address - to be compatible with EVM
    }

    // Outgoing transaction parameters
    // Ex.: [100000000000000000000, 2, "USDT", "0x738b2B2153d78Fc8E690b160a6fC919B2C88b6A4"]
    struct InstallmentOut {
        uint256 amount; // Transfered amount > 0, < 2^256
        uint16 chainId; // Destination chain nonce
        string tokenSymbol; // Ex.: USDT, BNB...
        string destinationAddress; // String - compatibility with non-EVMs
    }

    // BRIDGE EVENTS

    event SendInstallment(
        uint256 amount,
        bytes32 txId,
        uint16 fromChain,
        uint16 toChain,
        string tokenSymbol,
        string toAddress
    );

    event ReceivedInstallment(
        uint256 amount,
        bytes32 txId,
        uint16 fromChain,
        uint16 toChain,
        string tokenSymbol,
        address toAddress
    );

    constructor(uint16 _nativeChainId) {
        nativeChainId = _nativeChainId;
        actionId = 0;
    }

    // Ex.: 0x50ae95fb7b2153fdd233d118d278419cf1edb6d5290008af66adb139ea6e3a4c
    // Ex.: [100000000000000000000, 2, "USDT", "0x738b2B2153d78Fc8E690b160a6fC919B2C88b6A4"]
    function receiveInstallment(
        bytes32 txId, // Separated, to be used as stored key
        InstallmentIn memory params // The stored value
    ) external {
        // Inform the UI
        emit ReceivedInstallment(
            params.amount,
            txId,
            params.chainId,
            nativeChainId,
            params.tokenSymbol,
            params.destinationAddress
        );
    }

    // Ex.: [100000000000000000000, 2, "USDT", "0x738b2B2153d78Fc8E690b160a6fC919B2C88b6A4"]
    function sendInstallment(InstallmentOut memory params) external {
        actionId++;
        bytes32 txId = keccak256(
            abi.encodePacked(nativeChainId, "-", params.chainId, "-", actionId)
        );
        // Notify the Validators
        emit SendInstallment(
            params.amount,
            txId,
            nativeChainId,
            params.chainId,
            params.tokenSymbol,
            params.destinationAddress
        );
    }
}