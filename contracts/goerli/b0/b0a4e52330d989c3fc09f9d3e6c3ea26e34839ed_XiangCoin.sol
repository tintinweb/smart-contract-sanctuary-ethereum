/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract XiangCoin {

    string public name;                 //token的名稱
    string public symbol;               //token的符號
    uint256 public token_total_supply;  //token總量;    
    mapping(address => uint256) private account_balance; // 查詢某人錢包的餘額
    address owner;

    //自訂name,symbol,
    constructor(string memory _name, string memory _symbol, uint256 init_token){
        name = _name;
        symbol = _symbol;
        token_total_supply += init_token;
        owner = msg.sender;
        account_balance[owner] = init_token;
    }

    event Transfer(address from, address to, uint256 amount);

    //Transfer
    function transfer(address to, uint256 amount) public {
        require(amount > 0 , "Amount must be over 0.");  //檢查傳送數量是否大於0
        require(account_balance[msg.sender] >= amount, "Not enough tokens can transfer."); //檢查傳送者的token數量是否大於amount

        account_balance[msg.sender] -= amount;  //傳送者扣錢
        account_balance[to] += amount;          //接收者增加錢

        emit Transfer(msg.sender, to, amount);  //紀錄事件
    }
    
    //balanceOf  查詢某個錢包內的token數量
    function balanceOf(address anyone) public view returns (uint256){
        return account_balance[anyone];
    }
}