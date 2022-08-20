/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
進階題二－不引用原有標準 ERC20 檔案，完成部署 ERC20 合約，並將 Token 傳送至指定錢包地址
部署方式：Remix 部署方式改選使用 Injected Web3（Metamask），部署至 Goerli 測試鏈
此作業目的為可更理解 Token 實際是什麼

不透過原有的標準 ERC20 檔案，思考如何用學習到的語法自行撰寫一個可以自訂 name, symbol
該智能合約必須完成 totalSupply, balanceOf 與 transfer 的方法使用。
傳送完成的 ERC20 Token 至（0x977e01DDd064e404227eea9E30a5a36ABFDeF93D）地址
貼 程式碼 Gist 連結或是 Verify 開源的智能合約 & 交易成功的截圖

    - totalSupply
    - balanceOf
    - transfer
*/

contract SCCoin {
    address owner;
    //ERC20 Token name, $symbol
    string public name;
    string public symbol;
    //Max token amount
    uint256 public totalSupply;

    mapping(address => uint256) private accountBalances;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        totalSupply += _initialSupply;

        owner = msg.sender;
        accountBalances[owner] = _initialSupply;

    }
    // TODO: 轉錢給別人
    event Transfer(address _from, address _to, uint256 _amount);
    // TODO: Transfer 事件
    function transfer(address _to, uint256 _amount) public {
        //
        require(accountBalances[msg.sender] >= _amount, "You don't have enough balance!");
        //
        accountBalances[msg.sender] -= _amount; 
        accountBalances[_to] += _amount;
        //log to console
        emit Transfer(msg.sender, _to, _amount);
    }
    // TODO: 查詢某人錢包的餘額
    //
    function checkBalance(address _to) public view returns (uint256 balance){
        return accountBalances[_to];
    }
}