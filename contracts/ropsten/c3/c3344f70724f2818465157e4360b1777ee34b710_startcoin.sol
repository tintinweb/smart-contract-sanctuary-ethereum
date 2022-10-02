/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IERC20{

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
/**
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
**/
    event Transfer(address indexed from, address indexed to, uint tokens);
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract startcoin is IERC20{
    string name="OnlyStart";
    string symbol="OS";
    uint decimals=0;
    uint override public totalSupply;

    address founder;
    mapping(address=>uint)balances;
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

}