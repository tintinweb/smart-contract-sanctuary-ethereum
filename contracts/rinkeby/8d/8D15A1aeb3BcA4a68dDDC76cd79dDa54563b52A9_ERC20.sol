/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Token
{
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner)  external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract ERC20 is Token 
{
    address public Owner;
    string public constant name ="Musharraf Coin";
    string public constant symbol ="MSN";
    uint public constant decimals =18;
    uint internal totalSupply_;        
    mapping(address => uint) public  balances;
    mapping(address => mapping (address => uint)) public  allowed;

constructor()
{

Owner = msg.sender;
totalSupply_ = 1000000 * 10 ** decimals;
balances[msg.sender] = totalSupply_;

}//CONSTRUCTOR ENDED HERE

function totalSupply() external view returns (uint)
{
        return totalSupply_;
}

function balanceOf(address tokenAddress) external view returns (uint) {

    return balances[tokenAddress];
}

//Transfer token to the account
function transfer(address receiver, uint numTokens) external returns (bool){
    
    require( numTokens <= balances[msg.sender] , "Requested Number of Tokens not available!");
    balances[msg.sender] -= numTokens;
    balances[receiver] += numTokens;
    emit Transfer(msg.sender, receiver, numTokens);
    return true;

}

//Transfer tokens from an account to another account
function transferFrom(address owner, address buyer, uint numTokens) external returns(bool){
    require(numTokens <= balances[owner],"Balance is not available");
    require(numTokens <= allowed[owner][msg.sender],"Address is not allowed to transfer"); 
    balances[owner] -= numTokens;
    allowed[owner][msg.sender] -= numTokens;
    balances[buyer] += numTokens;
    emit Transfer(owner, buyer, numTokens);
    return true;
}

//approve the token transfer
function approve(address delegate, uint numTokens) external returns (bool){
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
}
//Get the allowance status of an account
function allowance(address owner, address delegate) external view returns (uint) {
    return allowed[owner][delegate];
}

}