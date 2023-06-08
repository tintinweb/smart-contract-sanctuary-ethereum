/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity ^0.4.11;

contract Token {

    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Origin is StandardToken {

    function () {
        throw;
    }

    string public name;                   
    string public symbol;                 
    string public version = 'V0.1';       

    uint8 public constant decimals = 18;                              
    uint256 public constant PRECISION = (10 ** uint256(decimals));  

    function Origin(
    uint256 _initialAmount,
    string _tokenName,
    string _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount * PRECISION;   
        totalSupply = _initialAmount * PRECISION;            
        name = _tokenName;                                   
        symbol = _tokenSymbol;                               
    }

    function multisend(address[] dests, uint256[] values)  returns (uint256) {

        uint256 i = 0;
        while (i < dests.length) {
            require(balances[msg.sender] >= values[i]);
            transfer(dests[i], values[i]);
            i += 1;
        }
        return(i);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

}