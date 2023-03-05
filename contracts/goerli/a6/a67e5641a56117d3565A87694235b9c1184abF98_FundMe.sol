//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public fundingMap;
    address[] public addresses;
    AggregatorV3Interface priceFeed =
        AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        //minimum usd
        uint256 minimumUSD = 1 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "less than the minimum"
        );

        fundingMap[msg.sender] += msg.value;
        addresses.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        //aggregatorv3 interface is the import from chainlink
        //we assign priceFeed name to an actual contract on the goerli chain
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return (uint256(answer * 10**10));
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        //calling the previus fuction to get price
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUSD;
    }

    function withdraw() public payable {
        payable(msg.sender).transfer(fundingMap[msg.sender]);
        fundingMap[msg.sender] == 0;
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i; i < addresses.length; i++) {
            fundingMap[addresses[i]] = 0;
        }
        addresses = new address[](0);
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