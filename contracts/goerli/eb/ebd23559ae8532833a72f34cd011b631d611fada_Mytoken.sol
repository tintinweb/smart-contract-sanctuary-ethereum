/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
// File: erc20Token.sol



pragma solidity >=0.5.0 <0.9.0; 

interface ERC20Interface { 
    function totalSupply() external view returns (uint); 
    function balanceOf(address tokenOwner) external view returns (uint balance); 
    function transfer(address to, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Mytoken is ERC20Interface{
    string public name="Qodeleaf";    //name of the token 
    string public symbol ="QLF";      //symbol like  BTC, ETH
    string public decimal="0";
    uint public override totalSupply;
    address public founder;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;


    constructor(){
        totalSupply=10000;
        founder=msg.sender;             //set the founder of token at deployment time
        balances[founder]=totalSupply;  //set the limit of tokens of this contract
    }

    //get the token balance
    function balanceOf(address tokenOwner) public view override returns(uint balance){
        return balances[tokenOwner];
    }

    //transfer tokens from founder account
    function transfer(address to, uint tokens) public override returns(bool success){
        require(balances[msg.sender]>=tokens);
        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        emit Transfer(msg.sender,to,tokens);
        return true;
    }


    //tokens need to be approved after transfer
    function approve(address spender, uint tokens) public override returns(bool success){     
        require(balances[msg.sender]>=tokens);
        require(tokens>0);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    //tokens need to be allowed 
    function allowance(address tokenOwner, address spender) public view override returns(uint noOfTokens){  
        return allowed[tokenOwner][spender];
    }


    //transfer tokens without owner
    function transferFrom(address from, address to, uint tokens) public override returns(bool success){   
        require(allowed[from][to]>=tokens);
        require(balances[from]>=tokens);
        balances[from]-=tokens;
        balances[to]+=tokens;
        return true;
    }


}