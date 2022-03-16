/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

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

contract Token is ERC20Interface{
    string public name = "Croma";
    string public symbol = "CRM";
    string public decimal = "0";
    // uint public override totalSupply;
    address public founder;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;
    uint _totalSupply;
    constructor(uint supply) {
        _totalSupply = supply;
        founder = msg.sender;
        balances[founder] = _totalSupply;
    }

    function totalSupply() public view override returns(uint){
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public override returns (bool success){
        require(balances[msg.sender]>=tokens);
        balances[msg.sender]-= tokens; // balances[msg.sender] = balances[msg.sender]-tokens;
        balances[to]+= tokens; //balances[to]= balances[to]+tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns(bool success){
        require(balances[msg.sender]>=tokens);
        require(tokens>0);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns(uint noOfTokens){
       return allowed[tokenOwner][spender];
    }

    function transferFrom(address from,address to,uint tokens) public override returns(bool success){
        require(balances[from]>= tokens);
        require(allowed[from][to]>=tokens);
        balances[from]-= tokens;
        balances[to]+= tokens;
        return true;
    }

}