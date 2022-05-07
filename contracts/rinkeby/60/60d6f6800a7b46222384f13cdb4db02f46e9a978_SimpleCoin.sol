/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract SimpleCoin {

    uint public totalSupply;  //Número de "moedas"
    mapping(address => uint) public balanceOf;  //Quantidade destinada a uma carteira
    address public owner;   //Criador

    string public name = "Meu Token de Teste";
    string public symbol = "MTKT";
    uint8 public decimals = 3; 

    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    //Regra só é executada pelo criador
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {

        owner = msg.sender; //Define o criador
        totalSupply = 1000 * 10 ** decimals;   //Define a quantidade de "moedas"
        balanceOf[owner] = totalSupply;   //Define que todas as "moedas" vão para o criador

    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        require(_from != address(0));
        require(_to != address(0));

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        //require(balanceOf[msg.sender] >= _value);
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    //Muda o criador
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    //Transferencia
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

}