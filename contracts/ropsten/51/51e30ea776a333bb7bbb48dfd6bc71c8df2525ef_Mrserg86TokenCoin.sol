/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.4.18;
  
contract Mrserg86TokenCoin {
    
    string public constant name = "Mrserg86 Token";
    
    string public constant symbol = "SERG1";
    
    uint32 public constant decimals = 18;
    
    uint public totalSupply = 0;
    
    mapping (address => uint) balances;
    
    // mapping (address => mapping(address => uint)) allowed;
    
    function mint(address _to, uint _value) public  {
        assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        totalSupply += _value;
        Transfer(0x0, _to, _value);
    }
    
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint _value) public returns (bool success) {
        if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value; 
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } 
        return false;
    }
    
    function transferFrom() public returns (uint nol) {
        return 0;
    }
    
    function approve() public returns (bool success) {
        return false;
    }
    
    function allowance() public constant returns (bool success) {
        return false;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}