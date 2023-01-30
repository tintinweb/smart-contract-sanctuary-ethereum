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
        name = "Test Coin JS";
        symbol = "TCJS";
        decimals = 18;
        coinFormule = uint256(10) ** decimals;
        totalSupply = 1000 * coinFormule;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient funds"); // validar saldo de wallet
        balanceOf[msg.sender] -= _value; // restar saldo de wallet emisor
        balanceOf[_to] += _value; // agregar saldo a wallet receptor
        emit Transfer(msg.sender, _to, _value); // disparar evento de transferencia
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // persona autorizada Y para gestionar n tokens de X
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient amount of coins"); // validar que owner tenga los tokens a gestionar por terceros
        require(allowance[_from][msg.sender] >= _value, "Unauthorized to manage the funds of this wallet"); // quien este llamando esta funcion tenga los permisos
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value; // restar tokens permitidos usados
        emit Transfer(_from, _to, _value);
        return true;
    }

    function getNow() public view returns(uint) {
        return block.timestamp;
    }
}