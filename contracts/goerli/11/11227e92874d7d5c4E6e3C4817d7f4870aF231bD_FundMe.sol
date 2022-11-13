//SPDX-License-Identfier:MIT
pragma solidity ^0.8.0;
import "./PriceConverter.sol";
error notOwner();
contract FundMe{
    using PriceConverter for uint256;
    address private immutable i_owner;
    uint256 private minUSD=50*1e18;
    address[] public funders;
    AggregatorV3Interface private priceFeed;
    mapping(address => uint256) public addMoneyMapping;
    constructor (address priceFeedAddress){
        priceFeed=AggregatorV3Interface(priceFeedAddress);
        i_owner=msg.sender;
    }
    function fund() public payable{
        require(msg.value.getConversionRate(priceFeed)<=minUSD,"Dont have enough eth");
        funders.push(msg.sender);
        addMoneyMapping[msg.sender]+=msg.value; 
    }
    modifier onlyOwner{
        if(msg.sender!=i_owner)
        revert notOwner();
        _;
    }
    function withdraw() public onlyOwner {
        for(uint256 i=0;i<funders.length;i++){
            address funder=funders[i];
            addMoneyMapping[funder]=0;
        }
        funders= new address[](0);
        (bool callSuccess,)=payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"Send Failed !");
    }

}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        (,int256 price,,,)=priceFeed.latestRoundData();
        return uint256(price*1e10);
    }
    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 latestPrice=getPrice(priceFeed);
        return (latestPrice*ethAmount)/1e18;
    }
}

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