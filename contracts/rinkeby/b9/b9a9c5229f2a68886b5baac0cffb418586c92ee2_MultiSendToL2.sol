/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MockBridge {
        function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable
    {}
}

contract MultiSendToL2 {
    address public bridgeAddr = 0x25D8039bB044dC227f741a9e381CA4cEAE2E6aE8;

    function sendToL22(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable
    {
        MockBridge(bridgeAddr).sendToL2{value: amount}(
            chainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
        MockBridge(bridgeAddr).sendToL2{value: amount}(
            chainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
    }
}