/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract Test {

    function getBlockhash(uint blockNumber) public view returns(bytes32){
        return blockhash(blockNumber); // 指定区块的区块哈希 —— 仅可用于最新的 256 个区块且不包括当前区块，否则返回 0 。
    }

    uint public basefee  = block.basefee ; // 当前区块的基础费用
    uint public chainid = block.chainid; // 当前链 id
    address public coinbase = block.coinbase; // 挖出当前区块的矿工地址
    uint public difficulty = block.difficulty; // 当前区块难度
    uint public gaslimit = block.gaslimit; // 当前区块 gas 限额
    uint public number = block.number; // 当前区块号
    uint public timestamp = block.timestamp; // 自 unix epoch 起始当前区块以秒计的时间戳

    function getGasleft() public view returns(uint256){
        return gasleft(); // 剩余的 gas
    }


    function getGas() public view returns(uint256){
        return tx.gasprice;
    }

    bytes public data = msg.data; // 完整的 calldata
    address public sender = msg.sender; //  消息发送者（当前调用）
    bytes4 public sig = msg.sig; // calldata 的前 4 字节（也就是函数标识符）
    uint public value = msg.value; // 随消息发送的 wei 的数量

    address public origin = tx.origin; // 交易发起者（完全的调用链）

}