/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.4.16 < 0.9.0;

contract Token {

    string  public name = "Erictoken";
    string  public symbol = "ET";
    // 1後面有18個零代表一顆，代表有18個位置的整數來當作小數，用這樣的設計去模擬浮點數運算
    // 不會有真的浮點數出現在智能合約裡面
    uint8   public decimals = 18;
    address public owner;
    // Constructor 可以讓智能合約部署前給定一初始參數
    constructor( ) public {
        uint256 _initialSupply = 1000 * 10**uint(decimals);
        owner = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // 以下這三個東西，只是一個查找的用途，不會改變鏈上狀態
    // mapping就是python的dic的意思
    // 查看某個地址有多少這個代幣 
    mapping(address => uint256) public balanceOf;
    // allowance = 允許誰用多少東西。A(address)允許B(address)用多少代幣(uint256)
    mapping(address => mapping(address => uint256)) public allowance;
    // public會告訴compiler會自動生成一個function,總共有多少幣
    uint256 public totalSupply;

    // 交易
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // approve = 許某個人去吸我錢包的錢
    // 允許誰(_spender),多少錢(_value)
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 到allowance這個 mapping 裡面去改。[msg.sender]就是我，我允許這個[_spender]用多少錢(_value)
        allowance[msg.sender][_spender] = _value;
        // Approval 是一個event ,event可以被釋放(emit)出來，釋放出來的event可以幹嘛，這很像我們平常寫程式，故意去print一些debug 訊息
        // 這個設計的好處是，外面如果有個應用程式想監聽鏈上的一些訊息的時候，他可以很簡單很便宜的去監聽這些event
        // 跟合約本身沒有關西，是給前端用的，類似一個接口，讓他們比較好去聽一些事件的發生
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 從from地址transferFrom到to地址，transferFrom 這麼多(_value)的幣，首先要檢查的是錢包有足夠的錢能夠傳出去
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // require 就是要滿足這個條件,沒滿足就會被擋掉
        // 來源地址的幣balanceOf[_from]要大於想要傳出去的
        require(balanceOf[_from] >=_value,"not enouth token");

        if (_from != msg.sender){
            require(allowance[_from][msg.sender] >=_value);
            allowance[_from][msg.sender] -= _value;
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function freeToken(uint amount) public{
        // msg.sender 就是當時與合約互動的帳戶（address）
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
    }

    function mint(address account,uint amount) public{
        require(owner == msg.sender,"only owner can mint");
        balanceOf[account]+=amount;
        totalSupply +=amount;
    }

}