/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract EIP20  {

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    address public owner;
    uint256 public totalSupply;
    
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor()  {
		uint256 _initialAmount = 1000000000000000000000000;
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = "VIVI Token";                                   // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = "VVT";                               // Set the symbol for display purposes
        owner = msg.sender;    //SE DEFINE EL PROPIETARIO DEL SC QUE ES msg.sender
    }

    function transfer(address _destinatariodeTokens, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value,"no tienes tantos tokens");  //COMPRUEBA Q EMISOR TIENE LOS TOKES NECESARIOS SI NO DA ERROR
        balances[msg.sender] -= _value;         //AL EMISOR SE LE RESTAN LOS TOKENS Q QUIERE ENVIAR 
        balances[_destinatariodeTokens] += _value;  //SE SUMAN LOS TOKENS AL DESTINATARIO
        emit Transfer(msg.sender, _destinatariodeTokens, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowances = allowed[_from][msg.sender];  //COMPRUEBO Q TENGO PERMISOS PARA RX TOKES DEL EMISOR
        require(balances[_from] >= _value && allowances >= _value); 
        balances[_to] += _value;
        balances[_from] -= _value;  //quitamos los tokes de la dirección que se van a sacar

            allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

   
   //FUNCION XRA CONSULTAR CUANTOS TOKENS TIENE UNA DIRECCION
   function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //Funcion xra PERMITIR Q el _spender pueda gestionar de mis Tokens la cantidad que se haya puesto
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
    
    //HASTA AQUI LAS FUNCIONES OBLIGATORIAS
    
    
	function burn(uint256 _tokensaEliminar) public returns(bool success) {
         require(msg.sender == owner, "only owner");  //SOLO EN OWNER PUEDE ELIMINAR TOKENS
         require(balances[msg.sender] >= _tokensaEliminar);
        totalSupply -= _tokensaEliminar;    //SE ELIMINAN LOS TOKENS QUEMADOS DEL TOTAL SUPPLY
         balances[msg.sender] -= _tokensaEliminar;   //SE ELIMINAN LOS TOKENS DEL BALANCE TOTAL DEL OWNER
        return true;
    }
    
	function mint(uint256 _nuevosTokens) internal returns(bool success) {
        totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        emit Transfer(address(0), msg.sender, _nuevosTokens); 
        return true;
    }
    receive () external payable  {   //   receive() external payable {
       
       uint newTokens = msg.value * 100;  // 0.01 ethers = 1 token
       require(newTokens >= 10000000000000000, "not enough gas");  //minimum buy 0.01 tokens ES LO MINIMO Q SE REQUIERE COMPRAR
       mint(newTokens);  //ESTO INDICA Q SOLO EL OWNER PUEDE CREAR NUEVOS TOKENS
    }
	
    /*function mint(uint256 _nuevosTokens) internal returns(bool success) {
        require(msg.sender == owner, "only owner");
        totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        return true;
    }
    receive () external payable  {   //   receive() external payable {
        totalSupply += 1000000000000000000;
        balances[msg.sender] += 1000000000000000000;
    }*/
    
}


//0x58326bAF8F6c35A0CEFC772B69e6B87B39447Bf2