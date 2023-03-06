/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SkadiPublicPresale {
    uint256 addressesCount;

    uint256 presaleMinAllocation;
    uint256 presaleMaxAllocation;

    uint256 totalFund;
    address owner;

    address[] addressList;
    address withdrawalAddress;

    mapping(address => uint256) currentPayments;

    constructor(address _withdrawalAddress) {
        owner = msg.sender;

        withdrawalAddress = _withdrawalAddress;

        addressesCount = 0;

        presaleMinAllocation = 0.00001 ether;
        presaleMaxAllocation = 12 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setPresaleMinAllocation(uint256 _presaleMinAllocation) external onlyOwner {
        presaleMinAllocation = _presaleMinAllocation;
    }

    function setPresaleMaxAllocation(uint256 _presaleMaxAllocation) external onlyOwner {
        presaleMaxAllocation = _presaleMaxAllocation;
    }

    function getPresaleMinAllocation() public view returns (uint256) {
        return presaleMinAllocation;
    }

    function getPresaleMaxAllocation() public view returns (uint256) {
        return presaleMaxAllocation;
    }

    function getAddressCurrentPayments(address _address) public view returns (uint256) {
        return currentPayments[_address];
    }

    function payPresale() public payable {
        require(msg.value + currentPayments[msg.sender] >= presaleMinAllocation, "Payment above minimum allocation");
        require(msg.value + currentPayments[msg.sender] <= presaleMaxAllocation, "Payment above maximum allocation");
        currentPayments[msg.sender] += msg.value;
        totalFund += msg.value;
        addressesCount++;
    }

    function withdraw() public onlyOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function getCurrentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalFund() public view returns (uint256) {
        return totalFund;
    }

    function getAddressesCount() public view returns (uint256) {
        return addressesCount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getWithdrawalAddress() public view returns (address) {
        return withdrawalAddress;
    }
}