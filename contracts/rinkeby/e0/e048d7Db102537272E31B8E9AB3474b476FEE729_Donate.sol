/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Donate {

    address public owner; 

    uint public doneeCount; 
    mapping(uint => Donee) doneeMap; 

    constructor() {
        owner = msg.sender;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier validDonee(uint doneeID){
        require(doneeID > 0 && doneeID <= doneeCount);
        _;
    }
    event DoneeEvent (
        address addr,
        uint goal,
        uint amount,
        uint donorCount,
        bool status
    );

    function setDonee(address addr,uint goal) public onlyOwner {
        for (uint256 i = 0; i < doneeCount; i++) {
            Donee storage d = doneeMap[i+1];
            if(d.addr == addr){
                d.goal = goal;
                return;
            }
        }

        doneeCount++;
        Donee storage donee = doneeMap[doneeCount];
        donee.addr = addr;
        donee.goal = goal;
        donee.status = true;
    }
    function donate(uint doneeID) public payable validDonee(doneeID){
        Donee storage donee = doneeMap[doneeID];
        require(donee.status);

        if(!donee.donorMap[msg.sender].used){ 
            donee.donorCount++;
        }
        
        donee.amount += msg.value; 

        Donor storage donor = donee.donorMap[msg.sender];
        donor.addr = msg.sender;
        donor.amount = msg.value;
        donor.used = true;

        if(donee.amount >= donee.goal) {
            emit DoneeEvent(donee.addr, donee.goal, donee.amount, donee.donorCount, donee.status);
        }

    }

    function transfer(uint doneeID) public onlyOwner validDonee(doneeID) {
        Donee storage donee = doneeMap[doneeID];
        if(donee.amount >= donee.goal){

            payable(donee.addr).transfer(donee.goal);
        }else{

            revert();
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getDonee(uint doneeID) public view validDonee(doneeID) returns (address doneeAddr,uint doneeGoal, uint doneeAmount, bool doneeStatus){
        return (doneeMap[doneeID].addr,doneeMap[doneeID].goal, doneeMap[doneeID].amount, doneeMap[doneeID].status);
    }

    function setStatus(uint doneeID, bool doneeStatus) public onlyOwner {
        Donee storage d = doneeMap[doneeID];
        d.status = doneeStatus;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    fallback() external {

    }
    receive() payable external {

    }

}

struct Donee {
    address addr; 
    uint goal; 
    uint amount; 
    uint donorCount; 
    bool status; 
    mapping(address => Donor) donorMap; 

}

 struct Donor {
     address addr; 
     uint amount; 
     bool used;
 }