/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13; // 最新版之編譯器版本

contract erc20test {
    // 需要的變數
    address public owner;
    mapping(address => uint) balances;      // 地址 => 餘額
    mapping(address => mapping (address => uint256)) allowed; // 擁有者 => 花費者 => 可用多少 
    uint256 _totalSupply;
    uint8 _decimal;
    string nameAndSymbol;

    // 建構元
    constructor(){
        owner = msg.sender;
        balances[msg.sender] = 1000;
        _totalSupply = 1000;
        _decimal = 0;
        nameAndSymbol = "erc20test";
    }

    // 代幣名
    function name() public view returns (string memory) {
        return nameAndSymbol;
    }

    // 代幣象徵or縮寫
    function symbol() public view returns (string memory) {
        return nameAndSymbol;
    }

    // 代幣支援10進位位數
    function decimals() public view returns (uint8) {
        return _decimal;
    }

    // 總共有多少代幣
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 地址擁有多少代幣
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 針對自己地址的轉帳
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "not enough token");
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // 針對授權的轉帳
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require((balances[_from] >= _value) && (allowed[_from][msg.sender] >= _value), "not enough token");
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 授權
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 發費者可以用擁有者多少代幣
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // 跟合約擁有者要一點代幣
    function getSomeToken() public returns (bool success) {
        require(balances[msg.sender] == 0, "You already have some token");
        require(balances[owner] > 5, "Owner have not enough token");
        balances[owner] = balances[owner] - 5;
        balances[msg.sender] = 5;
        return true;
    }

    // 轉帳發生時的廣播
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // 授權發生時的廣播
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}