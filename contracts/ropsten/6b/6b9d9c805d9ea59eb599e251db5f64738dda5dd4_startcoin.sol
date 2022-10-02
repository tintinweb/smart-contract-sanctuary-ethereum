/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IERC20{

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract startcoin is IERC20{
    string name="OnlyStart";
    string symbol="OS";
    uint decimals=1;
    uint override public totalSupply;

    address founder;
    mapping(address=>uint)balances;
    mapping(address=>mapping(address=>uint))allowed;
constructor(){
    totalSupply=100;
    founder=msg.sender;
    balances[founder]=totalSupply;
}
function balanceOf(address tokenOwner) public override view returns (uint balance){
    return balances[tokenOwner];
}
 function transfer(address to, uint tokens) public override returns (bool success){
     require(balances[msg.sender]>=tokens);
     balances[to]+=tokens;
     balances[msg.sender]-=tokens;

     emit Transfer(msg.sender,to,tokens);
    return true;
 }
 function allowance(address tokenOwner, address spender) public override view returns (uint remaining){
     return allowed[tokenOwner][spender];
 }
 function approve(address spender, uint tokens) public override returns (bool success){
     require(balances[msg.sender]>=tokens);
     require(tokens>0);
     allowed[msg.sender][spender]=tokens;

     emit Approval(msg.sender,spender,tokens);
     return true;
 }
 function transferFrom(address from, address to, uint tokens) public override returns (bool success){
    require(allowed[from][msg.sender]>=tokens);
    require(balances[from]>=tokens);
    balances[from]-=tokens;
    allowed[from][msg.sender]-=tokens;
    balances[to]+=tokens;

    emit Approval(from,to,tokens);
    return true;
 }

}