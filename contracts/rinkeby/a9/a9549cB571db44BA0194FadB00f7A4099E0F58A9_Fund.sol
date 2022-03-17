// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fund {
    address public owner;
    mapping (address => uint) private donators;
    address[] private donatorsAddresses;

    constructor(){
        owner = msg.sender;
    }

    receive() external payable{
        pay();
    }

    modifier ownerable(){
        require(owner == msg.sender, "You are not an owner!");
        _;
    }

    modifier withdrawable(uint amount){
        require(amount != 0 && amount <= address(this).balance, "Incorrect amount");
        _;
    }

    function withdraw(address payable _addr, uint amount) ownerable withdrawable(amount) external{
        _addr.transfer(amount);
    }

    function getDonators() external view returns(address[] memory){
        return donatorsAddresses;
    }

    function getDonationAmountByAddr(address _addr) external view returns(uint){
        return donators[_addr];
    }

    function pay() public payable{
        require(msg.value != 0, "Donation can not be 0!");
        if(!isAddrExists(msg.sender)){
            donatorsAddresses.push(msg.sender);
        }
        donators[msg.sender] += msg.value;
    }

    function isAddrExists(address _addr) internal view returns(bool){
        if (donators[_addr] > 0){
            return true;
        } else {
            return false;
        }
    }
}