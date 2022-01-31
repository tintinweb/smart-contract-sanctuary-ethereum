/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.4.18;
 
contract SimpleTokenCoin {
    
    string public constant name = "Cromlehg token";
    
    string public constant symbol = "CROM1";
    
    uint32 public constant decimals = 18;
    
    uint public totalSupply = 0;
    
    mapping (address => uint) balances;
    
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] -= _value; 
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        return true; 
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        return false;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return 0;
    }

    function mint(address _to, uint _value) public {
      assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
      balances[_to] += _value;
      totalSupply += _value;
      Transfer(0x0, _to, _value);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}