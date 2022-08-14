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
    ) external payable returns (bool txSuccess, bytes memory txData) {
        // (bool success, bytes memory txResult) = to.delegatecall(
        //     abi.encodeWithSelector(bytes4(keccak256(bytes(callData))), callData)
        // );
        // (bool success, bytes memory txResult) = to.delegatecall(
        //     abi.encodeWithSelector(bytes4(keccak256(bytes(callData))), value)
        // );
        (bool success, bytes memory txResult) = to.delegatecall(callData);
        require(success, "tx failed");
        emit TestEvent(networkId, tokenAddress, amount, userAddress, slippage);
        return (success, txResult);
    }
}