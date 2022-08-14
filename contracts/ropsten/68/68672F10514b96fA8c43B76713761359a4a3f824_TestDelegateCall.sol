// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract TestDelegateCall {
    event TestEvent(uint256 networkId, address tokenAddress, uint256 amount, address userAddress, uint256 slippage);

    function testExecute(
        address to,
        bytes calldata callData,
        uint256 networkId,
        address tokenAddress,
        uint256 amount,
        address userAddress,
        uint256 slippage
    ) external returns (bool txSuccess, bytes memory txData) {
        (bool success, bytes memory txResult) = to.delegatecall(callData);
        require(success, "tx failed");
        emit TestEvent(networkId, tokenAddress, amount, userAddress, slippage);
        return (success, txResult);
    }
}