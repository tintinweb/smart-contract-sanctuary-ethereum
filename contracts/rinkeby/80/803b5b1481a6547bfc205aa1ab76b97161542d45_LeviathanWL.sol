/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LeviathanWL {
    uint miniWhitelistCount;
    uint bigWhitelistCount;

    uint miniWhitelistAllocation;
    uint bigWhitelistAllocation;

    uint totalFund;
    address owner;

    address [] addressList;
    
    mapping(address => bool) miniWhitelistAddresses;
    mapping(address => bool) bigWhitelistAddresses;
    mapping(address => uint256) currentPayments;

    constructor() {
        owner = msg.sender;
        miniWhitelistCount = 0;
        bigWhitelistCount = 0;
        bigWhitelistAllocation = 500000000000000000000;
        miniWhitelistAllocation = 100000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setBigWhitelistAllocation(uint _bigWhitelistAllocation) external onlyOwner{
        bigWhitelistAllocation = _bigWhitelistAllocation;
    }

    function setMiniWhitelistAllocation(uint _MiniWhitelistAllocation) external onlyOwner{
        miniWhitelistAllocation = _MiniWhitelistAllocation;
    }

    function getMiniWhitelistAllocation() view public returns(uint) {
        return miniWhitelistAllocation;
    }

    function getBigWhitelistAllocation() view public returns(uint) {
        return bigWhitelistAllocation;
    }

    function getAddressCurrentPayments(address _address) view public returns(uint) {
        return currentPayments[_address];
    }

    function payWL(uint256 _amount) public {
        require(bigWhitelistAddresses[msg.sender] || miniWhitelistAddresses[msg.sender], "User is not whitelisted");
        if (bigWhitelistAddresses[msg.sender] && miniWhitelistAddresses[msg.sender]) {
            require(_amount + currentPayments[msg.sender] <= miniWhitelistAllocation + bigWhitelistAllocation, "Payment above maximum allocation");
        } else if (bigWhitelistAddresses[msg.sender]) {
            require(_amount + currentPayments[msg.sender] <= bigWhitelistAllocation, "Payment above maximum allocation");
        } else if (miniWhitelistAddresses[msg.sender]) {
            require(_amount + currentPayments[msg.sender] <= miniWhitelistAllocation, "Payment above maximum allocation");
        }
        currentPayments[msg.sender] += _amount;
        totalFund += _amount;
    }

    function addBigWhitelistAddress(address _address) external onlyOwner {
        if (bigWhitelistAddresses[_address] != true) {
            bigWhitelistAddresses[_address] = true;
            bigWhitelistCount ++;
        }
    }

    function addMultipleBigAddresses(address[] memory addBigAddressList) external onlyOwner{
        for (uint i=0; i < addBigAddressList.length; i++) {
            if (bigWhitelistAddresses[addBigAddressList[i]] != true) {
                bigWhitelistAddresses[addBigAddressList[i]] = true;
                bigWhitelistCount ++;
            }
        }
    }

    function removeBigWhitelistAddress(address _address) external onlyOwner {
        bigWhitelistAddresses[_address] = false;
        bigWhitelistCount --;
    }

    function addMiniWhitelistAddress(address _address) external onlyOwner {
        if (miniWhitelistAddresses[_address] != true) {
            miniWhitelistAddresses[_address] = true;
            miniWhitelistCount ++;
        }
    }

    function addMultipleMiniAddresses(address[] memory addMiniAddressList) external onlyOwner{
        for (uint i=0; i < addMiniAddressList.length; i++) {
            if (miniWhitelistAddresses[addMiniAddressList[i]] != true) {
                miniWhitelistAddresses[addMiniAddressList[i]] = true;
                miniWhitelistCount ++;
            }
        }
    }

    function removeMiniWhitelistAddress(address _address) external onlyOwner {
        miniWhitelistAddresses[_address] = false;
        miniWhitelistCount --;
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    function IsMiniWhitelisted(address _whitelistedAddress) public view returns(bool) {
        bool userIsMiniWhitelisted = miniWhitelistAddresses[_whitelistedAddress];
        return userIsMiniWhitelisted;
    }

    function IsBigWhitelisted(address _whitelistedAddress) public view returns(bool) {
        bool userIsBigWhitelisted = miniWhitelistAddresses[_whitelistedAddress];
        return userIsBigWhitelisted;
    }

    function getCurrentBalance() view public returns(uint) {
        return address(this).balance;
    }

    function getTotalFund() view public returns(uint) {
        return totalFund;
    }

    function getMiniWhitelistCount() view public returns(uint) {
        return miniWhitelistCount;
    }

    function getBigWhitelistCount() view public returns(uint) {
        return bigWhitelistCount;
    }

    function getOwner() view public returns(address) {
        return owner;
    }

}