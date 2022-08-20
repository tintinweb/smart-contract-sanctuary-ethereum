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

contract JessCoinAdvanced {
    string public symbol;
    string public name;
    uint256 public totalSupply;
    mapping (address => uint256) public addressMapping;
    address owner;
    event Transfer(address _from, address _to, uint256 amount);
    event Mint(address _to, uint256 amount);
    uint256 public remainSupply;

    constructor(string memory _name, string memory _symbol, uint256  _initSupply){
        owner = msg.sender;
        totalSupply+= _initSupply;
        symbol = _symbol;
        name = _name;
        addressMapping[owner] = _initSupply;
        remainSupply += _initSupply;
    }
    

   
    function transfer(address _to, uint256 _amount) public{
        require(addressMapping[msg.sender] >= _amount, "Your balance is not enough.");
        require(_amount <= remainSupply, "RemainSupply is not enough.");

        addressMapping[msg.sender] -= _amount;
        addressMapping[_to] += _amount;
        //記錄剩餘數量
        remainSupply -= _amount;

        emit Transfer(msg.sender, _to, _amount);

    }

    function mint(address account, uint256 amount) public{
       require(account != address(0), "ERC20: mint to the zero address.");
       require(amount >= remainSupply, "Coin is not enough.");

       remainSupply -= amount;
       addressMapping[account] += amount;

       emit Mint( account, amount);
    }
    

    // 檢查餘額
    function balanceOf(address _address) public view returns(uint256){
        return  addressMapping[_address];
    }

    
    
}