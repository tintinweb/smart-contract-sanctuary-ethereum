// 使用语义版本控制指定 Solidity 的版本。
// 了解更多：https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.3;

// 定义一个名为“HelloWorld”的合约。
// 合约是功能和数据（其状态）的集合。 部署后，合约将驻留在以太坊区块链上的特定地址。 了解更多：https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld {

   // 调用更新函数时发出
   // 智能合约事件是你的合约将区块链上发生的事情传达给你的应用程序前端的一种方式，它可以“监听”某些事件并在它们发生时采取行动。
   event UpdatedMessages(string oldStr, string newStr);

   // 声明一个`string`类型的状态变量`message`。
   // 状态变量是其值永久存储在合约存储中的变量。 关键字 `public` 使变量可以从合约外部访问，并创建一个函数，其他合约或客户端可以调用该函数来访问该值。
   string public message;

   // 与许多基于类的面向对象语言类似，构造函数是一种特殊函数，仅在合约创建时执行。
   // 构造函数用于初始化合约的数据。 了解更多：https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(string memory initMessage) {

      // 接受字符串参数 `initMessage` 并将值设置到合约的 `message` 存储变量中）。
      message = initMessage;
   }

   // 一个接受字符串参数并更新“消息”存储变量的公共函数。
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}