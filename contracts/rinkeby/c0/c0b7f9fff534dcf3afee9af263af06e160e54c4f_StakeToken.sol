/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: Q5..Staker.sol
//SPDX-License-Identifier: none
pragma solidity ^0.8.1;

interface RewardTokenInterace{
    function mintExternal(address receiver, uint256 amount) external returns(bool);
    function burnExterna(address account,uint256 amount) external returns(bool);
}

interface StakeTokenInterface{
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract StakeToken {
     address private StakeTokenAddress;   
     address private TokenAddress;   

     mapping(address => uint256) _stakeBalances;

    constructor(address StakeTokenAdd, address ExchangeTokenAddress){
        StakeTokenAddress = StakeTokenAdd;
        TokenAddress = ExchangeTokenAddress;
    }

    function stakeToken(uint256 amount) external returns(bool){
        require(StakeTokenInterface(TokenAddress).allowance(msg.sender, address(this)) >= amount, "Please approve contract !!");
        bool success = StakeTokenInterface(TokenAddress).transferFrom(msg.sender, address(this), amount);
        _stakeBalances[msg.sender] += amount;
        RewardTokenInterace(StakeTokenAddress).mintExternal(msg.sender, amount);
        
        return success;
    }

    function InfoStake(address account) public view returns(uint256){
        return _stakeBalances[account];
    }

    function unstakeToken(uint256 amount) external returns(bool, bool){
        require(_stakeBalances[msg.sender] >= amount, "Invalid User !");
        bool success1 = StakeTokenInterface(TokenAddress).transfer(msg.sender, amount);
        bool success2 = RewardTokenInterace(StakeTokenAddress).burnExterna(msg.sender, amount);
        _stakeBalances[msg.sender] -=amount;
        return (success1, success2);
    }


}