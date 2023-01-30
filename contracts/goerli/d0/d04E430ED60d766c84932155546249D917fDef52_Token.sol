// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint256 coinFormule;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor()     {
        name = "Test Coin";
        symbol = "TCN";
        decimals = 18;
        coinFormule = uint256(10) ** decimals;
        totalSupply = 100 * coinFormule;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 value = _value * coinFormule;
        require(balanceOf[msg.sender] >= value, "Insufficient funds"); // validar saldo de wallet
        balanceOf[msg.sender] -= value; // restar saldo de wallet emisor
        balanceOf[_to] += value; // agregar saldo a wallet receptor
        emit Transfer(msg.sender, _to, value); // disparar evento de transferencia
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // persona autorizada Y para gestionar n tokens de X
        uint256 value = _value * coinFormule;
        allowance[msg.sender][_spender] = value;
        emit Approval(msg.sender, _spender, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 value = _value * coinFormule;
        require(balanceOf[_from] >= value, "Insufficient amount of coins"); // validar que owner tenga los tokens a gestionar por terceros
        require(allowance[_from][msg.sender] >= value, "Unauthorized to manage the funds of this wallet"); // quien este llamando esta funcion tenga los permisos
        balanceOf[_from] -= value;
        balanceOf[_to] += value;
        allowance[_from][msg.sender] -= value; // restar tokens permitidos usados
        emit Transfer(_from, _to, value);
        return true;
    }

    function getNow() public view returns(uint) {
        return block.timestamp;
    }
}