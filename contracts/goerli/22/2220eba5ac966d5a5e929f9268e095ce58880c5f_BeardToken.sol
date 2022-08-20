/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeardToken {
    string private _tokenName; // Token 名稱
    string private _symbol; // 縮寫
    uint256 private _totalSupply; // 總發行量
    mapping(address => uint256) private _balances;

    // 自定event
    event Transfer(address from, address to,uint256 amount);

    // 可以自定義名稱 / 符號 / 發行數量
    constructor(uint256 myTotalSupply, string memory myTokenName, string memory mySymbol) {
        _totalSupply = myTotalSupply;
        _tokenName = myTokenName;
        _symbol = mySymbol;
        _balances[msg.sender] = myTotalSupply; // 將所有Token發放給初始創立者
    }

    // 總發行量
    function totalSupply() view external returns (uint256 total) {
        return _totalSupply;
    }

    /* 取得目前的 address 的 balance */
    function balanceOf(address _address) view external returns(uint256 balance) {
        return _balances[_address];
    }

    /* 轉帳功能 */
    function transfer(address to , uint amount) external {
        require(_balances[msg.sender] >= amount, "Your balance is not enough.");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }
}