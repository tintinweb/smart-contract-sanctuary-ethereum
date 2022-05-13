/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.2;

contract Test {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 9;
    string public name = "Not Token";
    string public symbol = "NTKN";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    function addTokenTototalSupply(uint _value) public {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender] + _value;
        totalSupply = totalSupply + _value;

    }
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}