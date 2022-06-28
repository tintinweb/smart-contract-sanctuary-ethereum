/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
// 合约地址:  0xcf1C13F648BfA07a5D5D2A1f3617eb492bBE78Ec
contract EtherWallet {

    // 定义合约owner , 可支付地址
    address payable public owner;

    constructor() payable {
        // 初始化: 部署合约的地址 设置为 owner 
        owner = payable(msg.sender);
    }

    // receive 函数 , 用于接收 ETH , 没有 该函数的合约, 无法接收ETH 
    receive() external payable {}


    // 提取 ETH , 只能 owner 提取 
    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    // 查询合约余额 
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}