/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Mono{

    address private owner;
    uint256 private expectedCost = 0.1 ether;
    uint256 public payedCost = 0 ether;
    bool public locked = true;

    struct Person {
        address name;
        bool Payed;
        uint256 payedAmount;
    }

    mapping(address => Person) public registeredPerson;

    event Sent(address from, address to, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUnlock() {
        require(locked == false);
        _;
    }
    
    modifier onlyOnce() {
        require(registeredPerson[msg.sender].Payed== false);
        _;
    }

    constructor(){
        owner =msg.sender;
    }

    function changeLock() external onlyOwner{
        locked = false;
    }

    function setExpectedCost(uint x) public  {
        expectedCost = x ;
    }

    function getExpectedCost() public view returns (uint256) {
        return expectedCost;
    }

    function transferToArtist(address payable receiver) payable external onlyOwner onlyUnlock{
        uint256 myBalance = owner.balance;   
        uint256 amount = msg.value;

        if (expectedCost <= payedCost+0.1 ether && amount == expectedCost){
            myBalance -= amount;
            receiver.transfer(amount);
            locked=true;
            
            emit Sent(msg.sender, receiver,amount);
            
        }else{
            revert();            
        }
    }

    function sendToMono(address payable mono) external  payable onlyOnce{
        address sender=msg.sender;
        uint256 senderBalance = sender.balance;
        uint256 amount = msg.value;
        uint256 myBalance = owner.balance;
        Person memory  person;  

        if (amount <= senderBalance && amount != 0){
            myBalance += amount;
            payedCost+= amount;
            mono.transfer(amount);
           

            person.name = sender;
            person.Payed = true;
            person.payedAmount = amount;
            registeredPerson[sender] =  person;
            emit Sent(msg.sender, mono,amount);
       
        }
    }
}