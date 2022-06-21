//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
  function transfer(address, uint) external;
}

contract Reward {
  address payable owner;
  uint public rewardsWon;
  bool public increased;
  uint internal firstBlock;
  uint lucky;
  int price;
  int price1;
  bool finalPrice;
  uint wrongs;
  bool isHappy;


  event YouAreRight(string message);
  event YouAreWrong(string message);
  event BearMarket(string message);
  event Happy(string message);


  AggregatorV3Interface internal priceFeed;


  constructor(){
    owner= payable(msg.sender);
     priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
     firstBlock=block.timestamp;

  }

  function getPrice() internal {
    (, price, , ,) =priceFeed.latestRoundData();
    }


  function hasPriceIncreased() external returns(bool){

    if(block.timestamp<firstBlock){
    getPrice();

    if(price<price1){
        finalPrice=true;
    }
  }
    return finalPrice;
      }

  function hasIncreased() public{
    if(finalPrice){
    IERC20(0xd4F3263293715aa38b24509a7a8a87d976A504Cc).transfer(msg.sender, 5);
      emit YouAreRight("Congratulations, you have won 5 CW!!");
    }else if(!finalPrice){
      emit YouAreWrong("Try again!");
      wrongs++;
    }else if(wrongs>1){
      emit BearMarket("Oh no! It looks like we are entering a bear Market!");
      wrongs=0;
    }
  }

  function getRewarded() public {
    if(isHappy && lucky>0){
     IERC20(0xd4F3263293715aa38b24509a7a8a87d976A504Cc).transfer(msg.sender, 5);
      emit Happy("The CryptoWorld wants to reward you!");
      lucky--;
    }
  }

  function cryptoworld() public onlyOwner{
    isHappy=true;
    lucky=3;
  }
 

  function withdraw() public onlyOwner{
      owner.transfer(address(this).balance);
     IERC20(0xd4F3263293715aa38b24509a7a8a87d976A504Cc).transfer(msg.sender, address(this).balance);
     
  }

  modifier onlyOwner(){
    require(msg.sender==owner, "You do not have the rights to call this function!");
    _;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}