// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.2;


import "./DividendPayingToken.sol";
import "./Ownable.sol";

contract  AnimalTeam is DividendPayingToken, Ownable  { 

    address public _stakingContract;   

    modifier onlyStakingContract {
        require (msg.sender == _stakingContract, "u not staking contract"); _;
    } 
    
    constructor(string memory _name, string memory _symbol) public DividendPayingToken(_name, _symbol) {}

    function setStakingContract (address stakingContract) external onlyOwner {
        _stakingContract = stakingContract;
    }    

      function _approve(address, address, uint256) internal override {
        require(false, "Animal_Team_Token: No approvals allowed");
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Animal_Team_Token: No transfers allowed");
    }

    function stake(address account, uint256 amount) external onlyStakingContract {
        _mint(account, amount);
    }

    function unstake(address account, uint256 amount) external onlyStakingContract {
        _burn(account, amount);
    }

    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }
}