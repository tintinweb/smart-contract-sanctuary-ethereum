//  SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address=>uint) public senderaddresstoamontvalue;
    address public owner = msg.sender;
    address[] funders;
    AggregatorV3Interface public price_feed;

    constructor(address price_feed_address)  {
        price_feed = AggregatorV3Interface(price_feed_address);
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "You are NOT authorized to perform this withdrawal!");
      _;
    }

    function get_entrance_fee()public view returns(uint){
        //minimum USD
        uint minimumUSD = 5 * (10**18);
        uint price = getPrice();
        uint precision = 1 * (10**18);
        return (minimumUSD * precision) / price;
    }

    function fund() public payable {
        uint minimumUSD = 5 * (10 ** 18);
        require(getConversionRate(msg.value) >= minimumUSD, "You need to send more than $50!");
        senderaddresstoamontvalue[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdrawFunds() public onlyOwner payable {
      payable(msg.sender).transfer(address(this).balance);
      for (uint fundersarray = 0; fundersarray<funders.length; fundersarray++){
        address funder = funders[fundersarray];
        senderaddresstoamontvalue[funder] = 0;
      }
      funders = new address[](0);
    }

    function getVersion() public view returns(uint){
        return price_feed.version();
    }

    function getPrice() public view returns(uint){
        (,int256 answer,,,) = price_feed.latestRoundData();
        uint8 decimal = uint8(getDecimals());
        uint multiplier = uint(10 ** (18 - uint(decimal)));
        return uint(uint(answer) * multiplier);
    }

    function getDecimals() public view returns(uint8){
      return price_feed.decimals();
    } 
    
    function getEtherPrice(uint weiPrice) public pure returns(uint){
      return (weiPrice / (10 ** 18));
    }
    
    function getConversionRate(uint ethAmount) public view returns(uint){
      return (ethAmount * getEtherPrice(getPrice()));
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