/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: contracts/Contract3.sol

pragma solidity ^0.8.7;
//Contract transfer to token contract
contract Nft{
    
    constructor() public {
      mmutable_start_time = block.timestamp;
      mmutable_end_time = 1955389108;
    }

    uint256 public winner=1;
    address private owner;
    uint256 public totalGold;
    uint256 public totalBlue;
    uint256 public price = 1 ether/1000;
    uint256 private mmutable_start_time;
    uint256 private mmutable_end_time;
    uint256 STEP = 1 minutes;
    uint256 OWNER_PERCENTAGE = 40;
    uint256 passingTime;
    uint256 timeDifference;

    mapping(address => uint) public userBlue;
    mapping(address => uint) public userGold;
   
    function getPayable(uint256 vote) public payable{
        //contractEndTime();
        passingTime = block.timestamp-mmutable_start_time;
        timeDifference = passingTime/STEP;
        if(timeDifference>0){
        price = (price + (timeDifference*1 ether/100000));
        }
        require(msg.value >= price*vote);
    } 
    function getPayableOnePrice() public payable{
        contractEndTime();
        passingTime = block.timestamp-mmutable_start_time;
        timeDifference = passingTime/STEP;
        price = (price + (timeDifference*1 ether/100000)); 
    } 

    function getOwnerPercentage() public view returns(uint256){
        return address(this).balance*OWNER_PERCENTAGE/100;
    }

    function setBlue(uint256 vote) public payable {
        getPayable(vote);
        userBlue[msg.sender]+=vote;
        totalBlue+=vote;
    }
    function setGold(uint256 vote) public payable {
        getPayable(vote);
        userGold[msg.sender]+=vote;
        totalGold+=vote;
    }

    /*
    function returnTime() public view returns(uint256){
        return block.timestamp;
    }

    function balanceOf() public view returns(uint256) {
        return address(this).balance;
    }*/

    function odulhakkimiver() public {
        require(block.timestamp >  mmutable_end_time,"bitmedi");
        if(winner==1){
            require(userBlue[msg.sender]!=0,"hakkinizyok");
        }else if(winner==2){
            require(userGold[msg.sender]!=0,"hakkinizyok");
        }
    }

    function contractEndTime() public {
        require(block.timestamp < mmutable_end_time,"finish");
    } 

    function fName() public  {
    payable(msg.sender).transfer(100);
    }
    function winnerDetermination() public {
        require(block.timestamp >  mmutable_end_time,"bitmedi");
        if(totalBlue<totalGold){
                winner = 1;
        }else if (totalBlue>totalGold) {
                winner = 2;
        }
    }

}