/**
 *Submitted for verification at Etherscan.io on 2022-05-25
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
    address public Owner;

    constructor(address ExchangeToken){
        ERC20TokenAddress = ExchangeToken;
        Owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == Owner,"Only owner can access !");
        _;
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

    function GetContractEth(uint256 _stakeAmount) onlyOwner external returns(bool) {
        bool sent = payable(Owner).send(_stakeAmount);
        require(sent, "invalid balance");
        return true;
    }

    function UpdateOwner(address newOwner) onlyOwner external returns(bool) {
        Owner = newOwner;
        return true;
    }
}