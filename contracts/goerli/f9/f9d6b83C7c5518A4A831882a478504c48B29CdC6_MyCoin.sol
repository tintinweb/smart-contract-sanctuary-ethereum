/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MyCoin{

    // Variables de Clase
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256) ) public allowance;

    // Eventos
    // Los eventos reciben parametros con el keyword indexed
    // Esto hace que el valor del parametro quede registrado en una tabla indexada que puede ser buscada y filtrada
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //Constructor
    constructor(){
        name = "MyCoin";
        symbol = "MYC";
        decimals = 3;
        totalSupply = 1000000 * (uint256(10) ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function getDecimals() public view returns(uint8){
        return decimals;
    }

    // Metodos
    function transfer(address _to, uint256 _value) public returns (bool success){
        // Se comprueba si el importe (_value) a transferir es superior al saldo de la cuenta
        // Se comprueba si la direccion tiene fondos
        require(balanceOf[msg.sender] >= _value, "Error: MyCoin.transfer: La cuenta no tiene fondos suficientes.");

        //Si tiene fondos, se realiza la transferencia de valor
        //Al emisor se le descuenta el importe
        balanceOf[msg.sender] -= _value;
        //Al receptor se le suma el importe
        balanceOf[_to] += _value;

        //Se realiza la llamada al evento
        emit Transfer(msg.sender, _to, _value);

        //Si la ejecucion llega a esta sentencia la ejecucion ha sido correcta
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){  
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //Se comprueba que el dueño (emisor) tenga los tokens
        require(balanceOf[_from] >= _value, "Error: MyCoin.transferFrom: La cuenta no tiene fondos suficientes.");

        //Se comprueba que quien ejecuta la llamada (msg.sender) tiene permiso para gastar los tokens del emisor (_from)
        require( allowance[_from][msg.sender] >= _value, "Error: MyCoin.transferFrom: No tiene permisos para gastar fondos del emisor.");

        //Al emisor se le descuenta el importe y al receptor se le suma el importe
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        //Se resta el valor de la transferencia del total de los tokens que se tiene permiso para transferir.
        //Si se tiene permiso para gestionar 10 tokens y se gestionan 5 tokens.
        //A partir de la transferencia solo debe tener permiso para transferir 10 - 5.
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);

        return true;
    }

    function getBalanceOf(address _address) public view returns (uint256){
        return balanceOf[_address];
    }
}