/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract CTCoin {
    
    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint256 public remainSupply;
    address public owner;

    event mintE(address to, uint256 amount);
    event transferE(address from, address to, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        remainSupply = _totalSupply;
        owner = msg.sender;
    }
    
    mapping(address => uint256) private balanceOf;

    function Mint(uint256 _amount) external {
        require(_amount > 0, "Amount can't be zero");
        require(_amount < remainSupply, "Exceed total supply");
        balanceOf[msg.sender] += _amount;
        unchecked {
            remainSupply -= _amount;
        }
        
        emit mintE(msg.sender, _amount);
    }


    // TODO: Transfer 事件
    function Transfer(address _to, uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Not enough balance!");

        // TODO: 轉錢給別人
        unchecked {
            balanceOf[msg.sender] -= _amount;
        }
        balanceOf[_to] += _amount;

        emit transferE(msg.sender, _to, _amount);
    }

    // TODO: 查詢某人錢包的餘額
    function BalanceOf(address _address) external view returns(uint256) {
        return balanceOf[_address];
    }
    
}