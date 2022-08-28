pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

contract TransactionBatcher {
    function batchSend(address[] memory targets, uint[] memory values, bytes[] memory datas) public payable {
        for (uint i = 0; i < targets.length; i++)
            targets[i].call.value(values[i])(datas[i]);
    }
}