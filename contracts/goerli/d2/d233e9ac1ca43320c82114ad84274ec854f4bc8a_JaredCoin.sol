/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
進階題二－不引用原有標準 ERC20 檔案，完成部署 ERC20 合約，並將 Token 傳送至指定錢包地址

不透過原有的標準 ERC20 檔案，自訂 name, symbol
傳送完成的 ERC20 Token 至（0x977e01DDd064e404227eea9E30a5a36ABFDeF93D）地址
貼 程式碼 Gist 連結或是 Verify 開源的智能合約 & 交易成功的截圖
*/

contract JaredCoin {
    string public name;
    string public symbol;

    //總供應量
    uint256 public totalSupply;
    
    //查詢錢包
    mapping(address => uint256) private accountBalence;
    
    
    address owner;

    event Transfer(address _from , address _to , uint256 _amount);
    // 自訂 name symbol
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        totalSupply += _initialSupply;

        owner = msg.sender;
        accountBalence[owner] = _initialSupply;
    }


    

    // TODO: Transfer 事件
    function transfer(address _to , uint256 _amount) public {
        //檢查錢包
        require(accountBalence[msg.sender] >= _amount, "no enough balance" );

        // msg.sender = 轉帳者 | _to = 接收者
        accountBalence[msg.sender] -= _amount ;
        accountBalence[_to] += _amount;

        //紀錄轉帳事件
        emit Transfer(msg.sender , _to , _amount);
    }

    // TODO: 查詢某人錢包的餘額
    function balanceOf(address _address) public view returns (uint256) {
        return accountBalence[_address];
    }
}