/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)
/*

contract ERC20Interface {
function totalSupply() public view returns (uint); function balanceOf(address tokenOwner) public view returns (uint balance);
function allowance(address tokenOwner, address spender) public view returns (uint remaining); function transfer (address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success); function transferFrom(address from, address to, uint tokens) public returns (bool success);
event Transfer (address indexed from, address indexed to, uint tokens); event Approval (address indexed tokenOwner, address indexed spender, uint tokens);
}
*/
pragma solidity ^0.8.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";



contract GAB {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    //18 decimales
    uint256 public constant decimals = 18;
    string public constant name = "GAB";
    string public constant symbol = "GAB";
    //Definir mi dirección para recibir el impuesto
    address my_contract;
    uint256 fee;
    uint256 _totalSupply;

    constructor() {
       
       _totalSupply = 1000000000000000000000;
       _balances[msg.sender] = _totalSupply;
       my_contract = address(this);
       
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] -= amount;
        _balances[to] += amount ;

        /*Extraer impuesto*/
        fee= (amount * 5/100);
        /*Enviar importe menos impuesto al destinatario*/
        emit Transfer(msg.sender, to, (amount - fee) * decimals);
        /*Recibir el impuesto*/
        emit Transfer(msg.sender, my_contract, fee * decimals);

        return true;
    }

    function transferFrom(address owner, address buyer, uint256 amount) public returns (bool) {
        require(amount <= _balances[owner]);
        require(amount <= _allowances[owner][msg.sender]);

        _balances[owner] -= amount;
        _allowances[owner][msg.sender] -= amount;
        
        /*Extraer impuesto*/
        fee= (amount * 5/100);
        /*Enviar importe menos impuesto al destinatario*/
        emit Transfer(owner, buyer, (amount - fee));
        /*Recibir el impuesto*/
        emit Transfer(owner, my_contract, fee );
        
        _balances[buyer] += amount;

        return true;
    }



    
}