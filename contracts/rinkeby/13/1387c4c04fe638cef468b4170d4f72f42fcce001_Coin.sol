/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Coin {   
     //定义一个合约，合约名字叫coin
    address public minter; 
    
    //定义一个公开的地址变量，叫minter

    mapping (address => uint) public balances; //定义一个叫balances的映射类数据。

    event Sent(address from, address to, uint amount); 

    constructor() {
        minter = msg.sender;
    }   //构造函数，创建合约时运行。给minter赋初始值。

    function mint(address receiver, uint amount) public {  //创建一个叫mint的函数，调用的时候需要输入两个变量，一个叫receiver的地址变量，一个叫amoount的整型变量
        require(msg.sender == minter); //判断消息的发送者是不是合约的创建者
        require(amount <= 1e60);  //判断铸造的数量是不是小于1e60个。
        balances[receiver] += amount;  //
    }

    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], "Money not enough.");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

}