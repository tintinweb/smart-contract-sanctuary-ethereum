/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: GPL-3.6

// Extension from class contract that will add employees and a bonus to be sent on Christmas.
pragma solidity >=0.7.0 <0.9.0;

contract Fabrication{

    uint256 public units;
    address payable public owner;
    //simpler and faster than array
    mapping (address => bool) public admins;
    uint256 public lastChangeTimestamp; //unixtime


    uint256 private bonus;
    address payable[] private employees;
    uint256 private christmasDay=1671924224; 

    modifier isOwner(){
        require(msg.sender == owner, "Unauthorized action");
        _; //logic of the final function
    }

    modifier isAuthorized(){

        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    constructor(uint256 initialUnits, uint256 etherBonus){
        owner = payable(msg.sender);
        bonus=etherBonus; //Christmas Bonus
        units=initialUnits;
        lastChangeTimestamp=block.timestamp;
    }

    function setUnits(uint256 newUnits) isAuthorized public{
        //only the owner can do this
        require(block.timestamp > lastChangeTimestamp + 1 minutes, "Elapsed time less than 1 minute before last change.");
        units=newUnits;
        lastChangeTimestamp=block.timestamp;
    }

    function incrementUnits(uint256 inc) payable public{
        require(msg.value >= inc * 1 ether, "Not enough value to increment units.");
        units = units + inc;
    }

    function decrementUnits(uint256 inc) payable public{
    require(msg.value >= inc * 10 ether, "Not enough value to decrement units.");
    units = units - inc;
    }

    function addAdmin(address newAdmin) isOwner public {
        admins[newAdmin]=true;
    }
    

    function removeAdmin(address _admin) isOwner public {
        admins[_admin]=false;
    }

    function addEmployee(address payable newEmployee) isAuthorized payable public {
        require(msg.value >= bonus * 1 ether, "Not enough value to add employee.");
        employees.push(newEmployee);
    }

    function payChristmasBonus() public {
        require(block.timestamp > christmasDay);
        require(address(this).balance >= (employees.length * bonus), "Not enough balance to pay bonus to eveyone. You are the grinch.");
        for (uint i = 0; i < employees.length; i++) {
            address payable u = employees[i];
            u.transfer(bonus * 1 ether);
        }
    }

    function addBalance(uint256 balance) isAuthorized payable public{
        require(msg.value >= balance * 1 ether, "Not enough balance to add.");
    }

    function balance() isOwner public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() isOwner public {
        owner.transfer(balance());
    }

    receive() external payable{} 
}