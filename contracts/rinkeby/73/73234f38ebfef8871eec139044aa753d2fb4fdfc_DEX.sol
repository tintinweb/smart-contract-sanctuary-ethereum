/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract DEX {
    IERC20 public token;
    address public owner;
    uint public tokensInOneEth = 50;
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor(address contractAddress, address _owner){
        token =  IERC20(contractAddress);
        owner = _owner;
    }
    function buy() payable public{
        uint totalNumOfTokens = (msg.value * tokensInOneEth);
        token.transferFrom(owner, msg.sender, totalNumOfTokens);
        emit Bought(totalNumOfTokens);
    }
    function payEther()public payable{

    } 
    function checkBalance() public view returns(uint){
        return address(this).balance;
    }

     function sell(uint256 amountOfTokensToSell) payable public {
        // require(amountOfTokensToSell > 0, "You need to sell at least some tokens");
        // uint256 allowance = token.allowance(msg.sender, address(this));
        // require(allowance >=amountOfTokensToSell, "Check the token allowance");
        uint256 valueInEth = (amountOfTokensToSell * 1 ether) / tokensInOneEth;
        token.transferFrom(msg.sender, owner, amountOfTokensToSell);
        payable(msg.sender).transfer(valueInEth);
        emit Sold(amountOfTokensToSell);
    }
    
}