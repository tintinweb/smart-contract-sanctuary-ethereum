/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
// 3/15 作業，設計出一個簡易的去中心化銀行，功能有存錢、領錢、轉帳、查詢餘額，並根據以下註解寫出程式碼。
// 另外，請善用 msg.sender、msg.value
pragma solidity ^0.8.0;

contract SimpleBank{

    // 需要一個 mapping 用於存放某地址目前的餘額（使用private!!）
    mapping(address => uint) private balances;
    
    // 需要兩個全域變數（分別是銀行的模樣，請使用ipfs Hash上傳；銀行的名字。使用public!!）
    string public bankPicture;
    string public bankName;

    // 建構子constructor（為合約部署上區塊鏈後執行的第一個方法）
    constructor(string memory _name, string memory ipfsHash) {

        //指定圖片
        bankPicture = string(abi.encodePacked("https://ipfs.io/ipfs/",ipfsHash));

        //指定名字
        bankName = _name;
    } 
    
    // 存錢 方法
    function deposit() public payable returns(uint balance, bool success){

        // require()內必須為true，才會執行下方的程式碼
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);
        
        // 存錢者增加餘額
        balances[msg.sender] += msg.value;

        // 回傳兩個參數（1.存的餘額 2.true）
        return (balances[msg.sender],true);
    }
    
    // 領錢 方法
    function withdraw(uint withdrawAmount) public returns(uint remainingBal, bool success){

        // 先判斷提領的數量必小於或等於提領者的餘額
        require(withdrawAmount <= balances[msg.sender]);

        //提領者餘額減少
        balances[msg.sender] -= withdrawAmount;
        //將提領的錢轉給提領者
        payable(msg.sender).transfer(withdrawAmount);
        // 回傳兩個數 --> 1.剩餘餘額 2.成功提領（以boolean代表）
        return (balances[msg.sender],true);
    }

    // 轉幣 方法
    function _transfer(address _to, uint _value)public returns(uint balance, bool success) {
        
        // 先判斷轉帳的數量必小於或等於轉帳者的餘額
        require(balances[msg.sender] >= _value);

        // 轉幣者將餘額扣除轉走的數量
        balances[msg.sender] -= _value;
        // 收錢者增加餘額數量
        balances[_to] += _value;

         // 回傳兩個數 --> 1.剩餘餘額 2.成功提領（以boolean代表）
        return (balances[msg.sender],true);
    }
    
    // 查詢某地址地餘額 方法
    function balanceOf(address _addr)public view returns(uint){

       // 只有自己可以查看自己的餘額 
       require(_addr == msg.sender);

       // 回傳查詢者的餘額
       return balances[_addr];
   }

   // 修改銀行名稱 方法
   function setName(string calldata _name)public{
       bankName = _name;
   } 

   // 修改銀行圖片 方法
   function setIpfsPic(string calldata _picture)public{
       bankPicture = _picture;
   } 
    
}