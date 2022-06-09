/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.4.24;
 
//Safe Math Interface


 
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
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract NToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    address public owner;
    
    
    




    event Burn(address indexed from, uint256 value);
    
    bool public paused;

    function setPaused(bool _paused) public {
        require(msg.sender == owner, "You are not the owner");
        paused = _paused;
    }


   



 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        owner=msg.sender;


        
        symbol = "NAG";
        name = "NAG Coin";
        decimals = 2;
        _totalSupply = 100000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        require(paused == false, "Contract Paused");
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        require(paused == false, "Contract Paused");
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        require(paused == false, "Contract Paused");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        require(paused == false, "Contract Paused");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(paused == false, "Contract Paused");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        require(paused == false, "Contract Paused");
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(paused == false, "Contract Paused");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }

    
    function burn(uint256 _value) returns (bool success) {
        require(paused == false, "Contract Paused");
        require(msg.sender == owner , "only adimin has this acess");
        if (balances[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                      // Subtract from the sender
        _totalSupply = SafeMath.safeSub(_totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    
    function _mintToken(uint _value) public returns (bool){
        require(paused == false, "Contract Paused");
        require(msg.sender == owner , "only adimin has this acess");
        _totalSupply += _value;
        balances[msg.sender] += _value;
        return true;

        
    }

   
    
  
    
}