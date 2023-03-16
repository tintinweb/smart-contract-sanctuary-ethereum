/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: GPL-3.0
/* 
该合约实现了一个基本的 ERC20 标准发币合约，包括以下功能：

初始化时指定总量，将所有代币分配给合约创建者。
支持转账方法 transfer，在转账时会检查余额是否充足，并触发转账事件。
*/
pragma solidity ^0.8.0;

// 声明 Solidity 版本号
contract MyToken {
    // 定义名为 MyToken 的合约

    string public name = "iTokon";     // Token 名称
    string public symbol = "iTK";     // Token 缩写
    uint8 public decimals = 18;        // Token 小数位数
    uint256 public totalSupply;        // Token 总量

    mapping(address => uint256) public balanceOf;
    // 定义公共映射，将每个账户的地址与其余额关联起来

    event Transfer(address indexed from, address indexed to, uint256 value);
    // 定义转账事件，用于记录交易信息

    constructor(uint256 initialSupply) {
        // 合约构造函数，在创建合约时初始化总量和发行者余额

        totalSupply = initialSupply;    // 初始化总量
        balanceOf[msg.sender] = initialSupply;   // 初始化发行者余额
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        // 实现转账方法

        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        // 检查转账人余额是否足够，如果不足，则终止函数执行并抛出异常

        balanceOf[msg.sender] -= value;    // 发送者扣除转账金额
        balanceOf[to] += value;            // 接收者增加转账金额
        emit Transfer(msg.sender, to, value);   // 触发转账事件，记录交易信息
        return true;   // 返回成功状态
    }
}