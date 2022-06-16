/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: contracts/Contract2.sol


pragma solidity ^0.8.7;

contract Nft{

    constructor() public {
      mmutable_start_time = block.timestamp;
       owner=msg.sender;
    }

    uint256 public winner;
    address private owner;
    uint256 public totalGold;
    uint256 public totalBlue;
    uint256 public price = 1 ether/1000;
    uint256 private mmutable_start_time;
    uint256 STEP = 5 minutes;
    uint256 OWNER_PERCENTAGE = 40;
    uint256 passingTime;
    uint256 timeDifference;

    mapping(address => uint) public userBlue;
    mapping(address => uint) public userGold;
   
    function setBlue(uint256 vote) public payable {
        passingTime = block.timestamp-mmutable_start_time;
        timeDifference = passingTime/STEP;
        price = (price + (timeDifference*1 ether/100000))*vote;
        require(msg.value == vote);
        userBlue[msg.sender]+=vote;
        totalBlue+=vote;
    }


    
    function setOwner() public{
        if(totalGold>totalBlue){
            winner=1;
        }else if(totalGold<totalBlue){
            winner=0;
        }
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getContractBalanc2() public view returns(uint256) {
        return 1000*(OWNER_PERCENTAGE/100);
    }
    
}