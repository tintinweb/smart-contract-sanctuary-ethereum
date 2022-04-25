/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-22;
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply()public view returns(uint256);
    function balanceof_Owner(address _owner) public view returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function transfer(address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    event Approval(address indexed _owner,
                   address indexed _spender,
                   uint256 _value);
    
    event Transfer(address indexed _from,
                   address indexed _to,
                   uint256 _value);
}
// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
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

contract Jembio is ERC20Interface, SafeMath{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address=> mapping(address => uint256)) allowed;
    
    constructor() public
    {
        name="Jembio";
        symbol="JEMBIO";
        decimals=18;
        _totalSupply=10000000000000000000000000;
        balances[msg.sender]=_totalSupply;
         emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function totalSupply() public view returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }

   
    function balanceof_Owner(address _owner) public view returns(uint)
    {
        return balances[_owner];
        
    }
 
    function approve(address _spender,uint _amount)public returns(bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender,_spender,_amount);
        return true;
    }

    function transfer(address _to,uint _amount) public returns(bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender],_amount); 
        balances[_to]= safeAdd(balances[_to],_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
        
    }

    function transferFrom(address _from,address _to, uint _amount) public returns(bool success)
    {
        balances[_from] = safeSub(balances[_from], _amount);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Transfer(_from, _to, _amount);
        return true;

        
    }
    function allowance(address _owner,address _spender) public view returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }
}