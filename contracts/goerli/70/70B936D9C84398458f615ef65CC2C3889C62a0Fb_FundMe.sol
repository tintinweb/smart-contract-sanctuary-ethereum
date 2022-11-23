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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // version of the solidity

import "contracts/PriceConverter.sol";
contract FundMe{

    using PriceConverter for uint256;
    uint256 public minimumUsd=50 *1e18;

    address[] public funders;

    address public owner;

    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        owner=msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"not allowed for you.");
        _;
    }

    function fund() public payable {

        require(msg.value.getConversionRate(priceFeed) >= minimumUsd,'Not enough ether');
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        //reset the array
        funders = new address[](0);

        //withraw funds
        (bool callSuccess,)= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"call failed.");
    }

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }

}


//

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // version of the solidity

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){

        (,int256 price,,,) =priceFeed.latestRoundData();
        return uint256( price * 1e10);
    }

    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountinUsd = (ethPrice*ethAmount)/1e18;
        return ethAmountinUsd;
    }
}