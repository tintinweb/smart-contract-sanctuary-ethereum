/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: Q5.ExchangeETH.sol
//SPDX-License-Identifier: none
pragma solidity ^0.8.1;

interface ExchnageTokenInterace{
    function mintExternal(address receiver, uint256 amount) external returns(bool);
    function burnExterna(address account,uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ETHexchange {
    address private ERC20TokenAddress;   

    constructor(address ExchangeToken){
        ERC20TokenAddress = ExchangeToken;
    }

    //mapping (address => uint256) _balances;

    function ETH2ExcToken(uint256 amount) public payable returns(bool){
       // _balances[msg.sender] += amount;
        ExchnageTokenInterace(ERC20TokenAddress).mintExternal(msg.sender, amount);
        return true;
    }    

    function BalanceOf(address user)public view returns(uint256){
        return ExchnageTokenInterace(ERC20TokenAddress).balanceOf(user);
    }

    function ContractBalance()public view returns(uint256){
        return address(this).balance;
    }
}