/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IL1Helper {
    function wrapAndRelayTokens(address _receiver, bytes calldata _data) external payable;
}

/// @notice Tornado (Nova) tasker for SushiSwap Furo.
contract TornadoTasker {
    IL1Helper private immutable L1Helper;

    constructor(IL1Helper _L1Helper) payable {
        L1Helper = _L1Helper;
    }

    receive() external payable {}

    function onTaskReceived(bytes calldata data) external payable {
        // decode data for task
        (address _receiver, bytes memory _data) = abi.decode(data, (address, bytes));
        // task ETH to Tornado relayer with data
        L1Helper.wrapAndRelayTokens{value: address(this).balance}(_receiver, _data);
    }
}