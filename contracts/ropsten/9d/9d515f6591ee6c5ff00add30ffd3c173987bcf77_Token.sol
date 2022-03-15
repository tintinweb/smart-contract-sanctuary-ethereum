/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

pragma solidity ^0.8.2;

contract Token 
{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "5ire Chain";
    string public symbol = "5ire";
    uint public decimals = 18;
    bool public antiWhale = false;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor()    {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint)    {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool)    {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function antiWhaleTurnOn(bool x) public returns(bool){
        antiWhale = x;
        return true;
    }
    
    function transferFrom(address from, address target, uint value) public returns(bool)    {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        if(antiWhale){
            require((balanceOf(target) + value) <= 10000, 'whales are banned!');
        }
        balances[target] += value;
        balances[from] -= value;
        emit Transfer(from, target, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool)    {
        allowance[msg.sender][spender] = value * 10 ** 18;
        emit Approval(msg.sender, spender, value * 10 ** 18);
        return true;
    }
}