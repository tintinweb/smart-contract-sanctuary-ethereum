// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// Contract deploy Address: 0x82c005347D73F813A8b247729890Ccfe280E7cA1

// mkdir xxx
// cd xxx
// npm init --yes
// npm install --save-dev hardhat
// npx hardhat
// //window要安装
// npm install --save-dev @nomicfoundation/hardhat-toolbox
// npm install --save-dev @nomiclabs/hardhat-ethers
// npm install dotenv
// npx hardhat compile
// npx hardhat run scripts/deploy.js


contract HelloWorld {
    //事件
    //智能合约事件是你的合约将区块链上发生的事情传达给你的应用进程前端的一种方式，它可以监听某些事件并在它们发生时采取行动
   event UpdateMessage(string oldStr, string newStr);
   
   //状态变量
   //状态变量是它的值永久存储在合约存储中的变量。关键字public使变量可以从合约外部访问，并创建一个函数，其他合约或客户端可以调用该函数来访问该值
   string public message;
   
   //构造函数
   //与许多基于类的面向对象语言有类似，构造函数是一种仅在创建合约时执行的特殊函数
   constructor(string memory initMessage){
    message = initMessage;
   }

   function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdateMessage(oldMsg, newMessage);
   }
}