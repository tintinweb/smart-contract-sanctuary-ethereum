/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.4.24;
 
//SafeMath Funcio nes para tener un unico fichero
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Funcion aprobar y ejecutar
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 

// Contrato principal
 
contract AyalaPujo is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "CHD";
        name = "ChadCoin"; //APe => mono
        decimals = 10;
        _totalSupply = 690000000000000000; // 69 millones
        balances[0x433aE212D872fbcd463b145c41271686D7fddb1f] = _totalSupply;
        emit Transfer(address(0), 0x433aE212D872fbcd463b145c41271686D7fddb1f, _totalSupply);
    }

    // Funciones principales
    function totalSupply() public constant returns (uint) {                                 // Total de la criptomopneda
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {         // Saber el balance que posee una direccion
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {              // Tranferir a una billetera n cantidad
        uint256 fee = (tokens  * 5) / 100;
        tokens -= fee;

        // Enviar al destinatario su dinero
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, 0x433aE212D872fbcd463b145c41271686D7fddb1f, fee);
        
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {          // Aporbar transaccion
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {    // Transferir de a a b
        
        uint256 fee = (tokens  * 5) / 100;
        tokens -= fee;

        // Enviar al destinatario su dinero
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        emit Transfer(from, 0x433aE212D872fbcd463b145c41271686D7fddb1f, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {      // Parecido a confirmar, necesario para añadir liquedez en uniswap
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {       // Funcion para confirmar y lanzar
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}