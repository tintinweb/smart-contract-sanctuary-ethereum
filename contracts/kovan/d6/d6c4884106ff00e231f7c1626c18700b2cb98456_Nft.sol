/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: contracts/NewContract.sol

pragma solidity ^0.8.7;
//Contract transfer to token contract
contract Nft{

    //update
    
    constructor()  {
      mmutable_start_time = block.timestamp;
      mmutable_end_time = 1955389108;
    }

    uint256 public winner=0;
    address private owner;
    uint256 public totalGold;
    uint256 public totalBlue;
    uint256 public price = 1 ether/1000;
    uint256 private mmutable_start_time;
    uint256 private mmutable_end_time;
    uint256 STEP = 1 minutes;
    uint256 public OWNER_PERCENTAGE = 40;
    uint256 passingTime;
    uint256 timeDifference;

    error ErrorValue();

    mapping(address => uint) public userBlue;
    mapping(address => uint) public userGold;
   
    function calculatePrice(uint256 vote) internal view returns (uint256) {
        uint256 timeDif = block.timestamp - mmutable_start_time;
        return (price + (timeDif / STEP) * 0.00001 ether)*vote;
    }

    function getOwnerPercentage() public view returns(uint256){
        return address(this).balance*OWNER_PERCENTAGE/100;
    }

    function setBlue(uint256 vote) public payable {
        uint256 prices = calculatePrice(vote);
        if (msg.value < prices) revert ErrorValue();
        userBlue[msg.sender]+=vote;
        totalBlue+=vote;
    }

    function setGold(uint256 vote) public payable {
        uint256 prices = calculatePrice(vote);
         if (msg.value < prices) revert ErrorValue();
        userGold[msg.sender]+=vote;
        totalGold+=vote;
    }
    
    function setSendOwnerPercantage(uint256 amount ) 
    public {
        OWNER_PERCENTAGE-=amount;
    }

    function setPayable() public {
         payable(msg.sender).transfer(1000);
    }


    function odulhakkimiver() public view {
        require(block.timestamp >  mmutable_end_time,"bitmedi");
        if(winner==1){
            require(userBlue[msg.sender]!=0,"hakkinizyok");
        }else if(winner==2){
            require(userGold[msg.sender]!=0,"hakkinizyok");
        }
    }

    function contractEndTime() public view {
        require(block.timestamp < mmutable_end_time,"finish");
    } 

}