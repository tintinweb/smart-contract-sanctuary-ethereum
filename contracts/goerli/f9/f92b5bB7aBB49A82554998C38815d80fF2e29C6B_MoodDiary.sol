/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// 指定solidity版本
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// 一个设置今天心情的案例

// 定义合约
contract MoodDiary{
    
    // 创建一个心情变量
    string mood;
    
    // 创建一个写入函数将今日心情存储到状态变量上
    function setMood(string memory _mood) public{
        mood = _mood;
    }
    
    // 创建一个读取函数获取今日心情
    function getMood() public view returns(string memory){
        return mood;
    }
}