/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: contracts/Contract3.sol

pragma solidity ^0.8.7;
//Contract transfer to token contract
contract Nft{
    

    constructor() public {
      mmutable_start_time = block.timestamp;
    }

    uint256 public winner;
    address private owner;
    uint256 public totalGold;
    uint256 public totalBlue;
    uint256 public price = 1 ether/1000;
    uint256 private mmutable_start_time;
    uint256 STEP = 1 minutes;
    uint256 OWNER_PERCENTAGE = 40;
    uint256 passingTime;
    uint256 timeDifference;

    mapping(address => uint) public userBlue;
    mapping(address => uint) public userGold;
   
    function getPayable(uint256 vote) public payable{
        passingTime = block.timestamp-mmutable_start_time;
        timeDifference = passingTime/STEP;
        price = (price + (timeDifference*1 ether/100000));
        require(msg.value == price*vote);
    } 


    function getPayablePrice(uint256 vote) public payable{
        passingTime = block.timestamp-mmutable_start_time;
        timeDifference = passingTime/STEP;
        price = (price + (timeDifference*1 ether/100000));
    } 

    function getPrice() public view returns(uint256){
        return price;
    }

    function getOwnerPercentage() public view returns(uint256){
        return address(this).balance*OWNER_PERCENTAGE/100;
    }
    

    function setBlue(uint256 vote) public payable {
        getPayable(vote);
        userBlue[msg.sender]+=vote;
        totalBlue+vote;
    }


    function balanceOf() public view returns(uint256) {
        return address(this).balance;
    }

}