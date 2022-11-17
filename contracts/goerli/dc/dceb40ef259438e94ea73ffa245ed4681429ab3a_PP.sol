/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

pragma solidity ^0.8.4;
 
contract PP
{
    mapping (address => uint) public balances;
    mapping (address => mapping (address=>uint)) public allowance;
 
    uint private totalSupply = 1000 * 10 ** 18;
    string public name = "PP Token";
    string public symbol = "PP";
    uint public decimals = 18;
 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
 
    constructor(){
        balances[msg.sender]=totalSupply;
    }
 
    function balanceOf(address user) public view returns (uint)
    {
        return balances[user];
         
    }
 
    function transfer(address to, uint value) public returns (bool)
    {
        require(balanceOf(msg.sender)>=value, "Solde insuffisant");
        balances[to]+=value;
        balances[msg.sender]-=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
 
    function TransferFrom(address from, address to, uint value) public  returns (bool)
    {
        require(balanceOf(from)>=value, "Solde insuffisant");
        require(allowance[from][msg.sender]>=value, "Delegation insuffisante");
        balances[to]+=value;
        balances[from]-=value;
        emit Transfer(from, to, value);
        return true;
    }
 
    function approve(address spender, uint value) public  returns (bool)
    {
        allowance[msg.sender][spender]=value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
 
}