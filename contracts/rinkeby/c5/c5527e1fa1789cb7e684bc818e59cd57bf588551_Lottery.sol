// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery{

    struct participant{
        
        uint numberOfEntries;
    }

    string public nameLottery;
    address  public owner;
    address payable[] public arrayParticipants;
    mapping (address => participant) public mapParticipants;
    uint public startDate ;
    uint public endDate;
    uint public pickedDate;
    uint public priceOfEntrance;
    bool public hasEnded = false;
    bool public ownerWithdrawedCommision = false;
    uint public indexFirstPrize;
    uint public indexSecondPrize;
    uint public maxNumberOfEntries;

   constructor (address _owner,string memory _nameLottery,uint _endDate, uint  _priceOfEntrace, uint  _maxNumberOfEntries) {
        nameLottery = _nameLottery;
        maxNumberOfEntries = _maxNumberOfEntries;
        owner = _owner;
        endDate = _endDate;
        startDate = block.timestamp;
        priceOfEntrance = _priceOfEntrace * 1000000000000000000 wei;
     
    
    }


   
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    


    function enter() public payable {
        require(msg.value >= priceOfEntrance, "Incorrect amount!"); 
        require (msg.value < priceOfEntrance + 3000000 wei, "Incorrect amount!");
        require(mapParticipants[msg.sender].numberOfEntries < maxNumberOfEntries,"To many entries");

        if(mapParticipants[msg.sender].numberOfEntries == 0)
        {
          
            mapParticipants[msg.sender] = participant(1);
            
        }
        else
        {
            mapParticipants[msg.sender].numberOfEntries += 1;
            
        }
        arrayParticipants.push(payable(msg.sender));

    }

    function getRandomNumber(uint number) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp, block.number, block.difficulty,number)));
    }
    
  
    function pickWinner() public payable onlyowner{
        
        require(address(this).balance > 0, "Balance is 0");
        require(hasEnded == false);
        
        indexFirstPrize = getRandomNumber(1) % arrayParticipants.length;
        indexSecondPrize = getRandomNumber(2) % arrayParticipants.length;
        
       
        arrayParticipants[indexFirstPrize].transfer(address(this).balance / 100 * 70);
        arrayParticipants[indexSecondPrize].transfer(address(this).balance / 100 * 83);
        

        hasEnded = true;

        pickedDate = block.timestamp;
        
    }
     function withdrawCommision() public onlyowner()
     {
        require(hasEnded == true, "Please pick the winner first!");
        require(ownerWithdrawedCommision == false, "You receive the commsision");
        address payable copy;
        copy = payable(owner);
        copy.transfer(address(this).balance);
        ownerWithdrawedCommision = true;
     }
    

    function getWinner1() public view returns(address)
    {
        require(hasEnded == true);
        return arrayParticipants[indexFirstPrize];
    }

    function getWinner2() public view returns(address)
    {
        require(hasEnded == true);
        return arrayParticipants[indexSecondPrize];
    }

    function getPlayers() public view returns(address payable[] memory)
    {
        return arrayParticipants;
    }
    
    function getNumberOfEntriesForUser() public view returns(uint){
        return mapParticipants[msg.sender].numberOfEntries;
    }

    modifier onlyowner() {
        require(msg.sender == owner);
      _;
    }
}