/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: GPL3.0

pragma solidity 0.8.17;

contract TransactionBatcherMEV {
    address public constant owner = 0x04a9EDD12Ed304eFb5E5Fe83109a65E8e84799c3;

    receive() external payable {}

    function batchSend(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external payable {
        uint256 remainingValue = msg.value;
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success,) = targets[i].call{value: values[i]}(datas[i]);
            require(success);
            remainingValue -= values[i];
        }
        block.coinbase.transfer(remainingValue);
    }

    function withdraw() external {
        (bool success,) = owner.call{value: address(this).balance}("");
        success = false;
    }
}