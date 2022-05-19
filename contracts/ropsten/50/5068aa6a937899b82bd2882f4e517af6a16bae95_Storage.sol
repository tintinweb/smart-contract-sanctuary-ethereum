/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 < 0.7.0; /* pragma 為版本的宣告 */
/* contract 為合約的宣告 */
contract Storage {
 /* public 為訪問修飾詞, 添加在變數前面, 可讓變數具有公開的特性,
可以隨時查看 */
 address public owner;
/* address 變數, 佔有 20Bytes */
 uint public storedData;
/* unsigned integer, 無號整數, 默認為 256bit, 大小可調整 e.g
uint8, uint32, ….. uint256, */
 /* constructor 為構造函數, 只在合約發布時執行 */
 constructor() public {
  owner = msg.sender;
/* msg.sender 是函數的呼叫者, 是一個 address */
 }
 /* function 函數宣告 */
 function set(uint data) public {
  require(owner == msg.sender);
/* 條件判斷, 若滿足條件則往下執行, 若不滿足則返回,
回復所有狀態*/
  storedData = data;
 }
}