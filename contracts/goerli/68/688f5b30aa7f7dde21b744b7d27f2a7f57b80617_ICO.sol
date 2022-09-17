/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity ^0.5.17;

interface assetERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external  returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ICO{
    assetERC20 token;
    uint public tokenForEth = 100;
    address  tknowner;
    constructor(assetERC20 tokenaddress, address  tokenowner) public {
        token = tokenaddress;
        tknowner = tokenowner;
    }

    function buyToken() public payable{
        require(msg.value > 0, "pay price");
        uint amount = msg.value * tokenForEth;
        token.transferFrom(tknowner, msg.sender, amount);
      
    }
}