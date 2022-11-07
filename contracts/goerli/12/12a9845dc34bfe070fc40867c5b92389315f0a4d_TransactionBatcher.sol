// File: bench.sol

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

contract TransactionBatcher {
    function batchSend(address[] memory targets, uint[] memory values, bytes[] memory datas) public payable {
        for (uint i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call.value(values[i])(datas[i]);
            if (!success) revert('transaction failed');
        }
    }
}