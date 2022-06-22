/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IL1Helper {
    function wrapAndRelayTokens(address _receiver, bytes calldata _data) external payable;
}

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 _value) external;

    function approve(address _to, uint256 _value) external;
}

/// @notice Tornado (Nova) tasker for SushiSwap Furo.
contract TornadoTasker {
    IL1Helper private immutable l1Helper;
    IWETH private immutable weth;

    constructor(IL1Helper _l1Helper, IWETH _weth) payable {
        l1Helper = _l1Helper;
        weth = _weth;
    }

    receive() external payable {}

    function onTaskReceived(bytes calldata data) external payable {
        // decode data for task
        (address _receiver, bytes memory _data) = abi.decode(data, (address, bytes));
        // fetch wETH balance and convert to ETH
        weth.withdraw(weth.balanceOf(address(this)));
        // task ETH to Tornado relayer with data
        l1Helper.wrapAndRelayTokens{value: address(this).balance}(_receiver, _data);
    }
}