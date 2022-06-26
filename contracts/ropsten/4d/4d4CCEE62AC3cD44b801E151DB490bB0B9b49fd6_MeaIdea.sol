/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

pragma solidity ^0.5.4;

contract MeaIdea {
    
    address payable  public owner;
    uint256 public trnsfee;
    
    struct Record {
        address creator;
        uint256 timestamp; //block.timestamp is a uint256 value in seconds since the epoch.
    }
    
    uint256[] public RecordArray;
    mapping (uint256 => Record) records;
        
        
    constructor() public {
        
        owner = msg.sender;
        trnsfee = 1000000;  // as of today (26.02.2019 = 0.14 USD)
    }
        
        
    function setTrnsFee(uint256 _trnsfee) public{
        
        require(msg.sender == owner);
        trnsfee = _trnsfee;
    }
        
    
     
    function setRecord(uint256 _hashID) public payable{
     
        require(msg.value >= trnsfee);
        
        Record storage record = records[_hashID];

        record.creator   = msg.sender;
        record.timestamp = block.timestamp;
        
        RecordArray.push(_hashID);

    }
  
    
    function get_count() view public returns (uint) {
        return RecordArray.length;
    }
    
    function getRecord(uint256 _hashID) view public returns (address, uint256){
        return (records[_hashID].creator, records[_hashID].timestamp);
    }
    
   function is_creator(uint256 _hashID) view public returns (bool){
  
        if (records[_hashID].creator == msg.sender){
             return true;
        } else {
            return false; 
        }
    } 

    function getBalance() view public returns (uint256){
        return address(this).balance;
    }

    function transferBalanceToOwner() public payable{

        if(msg.sender == owner){
            owner.transfer(address(this).balance);
        }
    }
    
    function () payable external{
    }
        
    function kill() public{
        
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
}