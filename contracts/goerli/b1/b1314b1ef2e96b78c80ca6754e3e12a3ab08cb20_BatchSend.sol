/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: GPL3.0

pragma solidity 0.8.17;

contract BatchSend {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function batchSend(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external payable {
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success,) = targets[i].call{value: values[i]}(datas[i]);
            require(success);
        }
    }

    function withdraw() external {
        (bool success,) = owner.call{value: address(this).balance}("");
        success = false;
    }
}