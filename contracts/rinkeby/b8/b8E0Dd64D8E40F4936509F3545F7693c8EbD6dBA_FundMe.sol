// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


import "AggregatorV3Interface.sol";


contract FundMe {
    address public owner;

    address[] public funders;

    AggregatorV3Interface public priceFeed;
    

    mapping(address => uint256) public  addressToAmtFunded; 

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    
    function fund() public payable   {

        uint256  minimumUSD = 50 * 10 ** 8 ;

        require(getConversionRate(msg.value) >= minimumUSD,"you need more money!" );


        addressToAmtFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        // ETH => USD

    }

    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // 2118.94175649
        return uint256(answer * 10000000000);
    }

    // function getCreateOwner()

    function getConversionRate(uint256 _ethAmt) public view returns(uint256)
    {
        uint256 ethPrice = getPrice();

        uint256 ethAmtInUSD = (ethPrice * _ethAmt) / 10000000000;

        return ethAmtInUSD;


    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++)
        {
            address funder = funders[funderIndex];
            addressToAmtFunded[funder] = 0;
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