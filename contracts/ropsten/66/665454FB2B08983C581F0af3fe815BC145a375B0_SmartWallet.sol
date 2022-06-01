// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

contract SmartWallet {
    function execute(
        address to,
        bytes calldata callData,
        uint256 value
    ) external returns (bool txStatus, bytes memory data) {
        (bool success, bytes memory txData) = to.call{value: value}(callData);
        require(success, "tx failed");
        return (success, txData);
    }
}