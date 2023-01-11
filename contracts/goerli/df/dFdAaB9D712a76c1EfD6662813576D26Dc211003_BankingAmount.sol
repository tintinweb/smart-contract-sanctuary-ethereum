// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT LICENSED
pragma solidity ^0.8.8;

/* This contract is about sending your ETH to the BANK(contract) and retieve when you need or 
   you can send to someone
   function:
   payment
   withdraw
   send_to
   View_deposited amount
*/
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract BankingAmount{
    using PriceConverter for uint256;
    address public contractOwner;
    struct Custmers{
        address CustmerAddress;
        uint256 amount;
    }
    AggregatorV3Interface public PriceFeed;
    constructor(address PriceFeedAddress){
       contractOwner= msg.sender;
       PriceFeed=AggregatorV3Interface(PriceFeedAddress);
    }
    Custmers[] public people;
    mapping(address => uint256) public Balance;

    function payment() public payable{
        people.push(Custmers(msg.sender,msg.value.getConversionRate(PriceFeed)));
        Balance[msg.sender]= Balance[msg.sender]+ msg.value.getConversionRate(PriceFeed);
    }
    function ViewAmount(address USER_ADDRESS) public view returns(uint256){
        return Balance[USER_ADDRESS];
    }
    function send_to(address payable to_receiever) public payable{
        address from_user=msg.sender;
        (bool sent,) = to_receiever.call{value: Balance[from_user]}("");
        require(sent, "Failed to send Ether");
        Balance[to_receiever]=Balance[to_receiever]+Balance[from_user];
        Balance[from_user]=0;
    }
    function withDraw() public payable{
        address withdraw=msg.sender;
        (bool sent,)=withdraw.call{value:Balance[withdraw]}("");
        require(sent, "Failed to withdraw Ether");
        Balance[withdraw]=0;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}