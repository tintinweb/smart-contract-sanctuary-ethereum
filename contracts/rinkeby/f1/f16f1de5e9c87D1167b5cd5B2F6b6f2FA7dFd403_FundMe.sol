// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

//37560320089995800 Wei
contract FundMe{

    mapping(address=>uint) public addressToBalance;
    AggregatorV3Interface public priceFeed;
    address[] public funders;
    address private owner;

    constructor(){
        owner = msg.sender;
        
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }
    function fund() public payable{
        uint256 minimumUSD = 50 * 10**18;
        
        uint usdValue = getConversionRate(msg.value);
        
        require(usdValue >= minimumUSD, "Wrong value!");
        addressToBalance[msg.sender] += msg.value;
        funders.push(msg.sender); 
    }

       function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    function getConversionRate(uint _value) internal view returns(uint){
        uint latestPrice = uint(getPrice());
        return (_value * latestPrice) / 1000000000000000000;
    }

    function getPrice() public view returns(uint256){
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint(answer * 10000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        for(uint i=0; i<funders.length; i++){
            addressToBalance[funders[i]] = 0;
        }
        funders = new address[](0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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