/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MsgData {
    event Data(bytes data, bytes4 sig);
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // input0: addr: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // input1: amt : 1
    function transfer(address addr, uint256 amt) public {
        bytes memory data = msg.data;

        // msg.sig 表示当前方法函数签名（4字节）
        // msg.sig 等价于 this.transfer.selector
        emit Data(data, msg.sig);
    }

    //output: 
    // - data: 0xa9059cbb0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000001
    // - sig: 0xa9059cbb

    // 对data进行分析：
    // 0xa9059cbb //前四字节
    // 0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4 //第一个参数占位符（32字节）
    // 0000000000000000000000000000000000000000000000000000000000000001 //第二个参数占位符（32字节）
}