/**
 *Submitted for verification at Etherscan.io on 2022-06-17
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
    ) external payable;
}

// Rinkeby testnet
contract SenderWithFallback02c {

    // The Multichain anycall contract on Rinkeby testnet
    address private anycallContractRinkeby = 0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02;

    address ownerAddress;

    // Destination contract on FTM testnet
    address receiverContract;

    // Destination chain id
    uint256 destinationChainId = 4002; // FTM testnet

    event SendNumber(uint256 number);

    event AnyFallbackCalled();
    event AnyExecuteCalled();
    event StandardReceiveCalled();
    event StandardFallbackCalled();

    constructor() {
        ownerAddress = msg.sender;
    }

    function setReceiverContract(address _receiverContract) external {
        require(msg.sender == ownerAddress);

        receiverContract = _receiverContract;
    }

    function send(uint256 _number) external payable {
        emit SendNumber(_number);

        require(receiverContract != address(0), "receiverContract is not defined");

        CallProxy(anycallContractRinkeby).anyCall{value : msg.value}(
            receiverContract,
            abi.encode(_number),
            address(this),
            destinationChainId,
            2 // fees paid on source chain
        );
    }

    function anyFallback(address, bytes calldata) public {
        emit AnyFallbackCalled();
    }

    function anyExecute(bytes memory) external returns (bool success, bytes memory result) {
        emit AnyExecuteCalled();

        success = true;
        result = '';
    }

    receive() external payable {
        emit StandardReceiveCalled();
    }

    fallback() external payable {
        emit StandardFallbackCalled();
    }
}