// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceBetting{
    AggregatorV3Interface internal priceFeed;
    address public owner;
    int currentPrice;
    uint256 start;
    int priceE;
    event startTimer(uint256 timer);
    event Won(address caller);
    event Lost(address caller);
    mapping(address => uint256) public LoH;
    constructor()
    {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        owner = msg.sender;   
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function payContract() public payable onlyOwner{
        require(msg.value > 0.1 ether && msg.value <= 5 ether,"Value not in range");
    }
 
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

     function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
  
   function getLatestPrice() public view returns(int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return (price / 1e6);
    }

    function setBet(int priceEstimate) public payable  {
       currentPrice = getLatestPrice();
       priceE = priceEstimate;
        require(address(this).balance >= 0.5 ether,"not enough eth in the contract");
        require(msg.value == 0.01 ether,"Fee has to equal 0.01Ether");
        if (priceE > currentPrice){
            LoH[msg.sender]=1;
        } else if (priceE < currentPrice){
             LoH[msg.sender]=2;
        }
         start = block.timestamp + 20 seconds;
         emit startTimer(start);
    }

    function result()public {
    require(block.timestamp >= start,"Timer is not done");
    require(block.timestamp <= start + 30 seconds,
    "You exceeded tx time to approve");
          if(priceE > currentPrice && LoH[msg.sender]==1){
          payable(msg.sender).transfer(0.05 ether); 
          emit Won(msg.sender); 
         }else{
          emit Lost(msg.sender); 
          }
         if(priceE < currentPrice && LoH[msg.sender]==2){
           payable(msg.sender).transfer(0.05 ether); 
           emit Won(msg.sender);
          }else{ 
           emit Lost(msg.sender);
         
        }
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