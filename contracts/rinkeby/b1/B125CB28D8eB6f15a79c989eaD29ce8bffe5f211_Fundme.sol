// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "AggregatorV3Interface.sol";

contract Fundme {

    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }
    mapping(address => uint256) public AddressToAmountFunded; 

    function fund() public payable {
        uint256 minimumUSD = 20 * 10 ** 9;
        require(getConversionRate(msg.value) >= minimumUSD, "you need to spend more than 20$ worth of ethereum!!");
        AddressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    // returns price of ethereum in wei
    function getPrice() public view returns(uint256) {
      AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
      (,int256 answer,,,) = priceFeed.latestRoundData();
      return uint256(answer * 10 ** 9);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) { 
        uint256 ethPrice = getPrice();
        uint256 ethAmountinUSD = (ethPrice * ethAmount) / (10 ** 18); 
        return ethAmountinUSD;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner can call withdraw function!!");
        _;
    }

    function withdraw() payable public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) {
            AddressToAmountFunded[funders[fundersIndex]] = 0;
            // funders[fundersIndex]
        }
        funders = new address[](0);
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