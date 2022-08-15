/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: Logic
pragma solidity ^0.8.16;
//envent 
contract TestEvent {
    //每个事件最多有3个带indexed的变量
    //着indexed关键字，每个indexed标记的变量可以理解为检索事件的索引“键”
    //不带indexed的变量 表示为存储在该事件中的数据
    event Log(address indexed addr0,address indexed addr1,address indexed addr2,uint num,string info);

    function test(address addr1,address addr2,uint num) public {
        address from = msg.sender;
        address to = addr1;
        //发行、散播事件 记录在交易的logs中
        emit Log(from,to,addr2,num,"airdrop");
    }


}