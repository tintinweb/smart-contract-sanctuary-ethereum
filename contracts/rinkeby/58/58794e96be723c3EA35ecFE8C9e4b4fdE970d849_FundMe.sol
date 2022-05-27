// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    
    mapping (address=>uint) public addressToAmount;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        uint minimumUSD = 50 * 10 ** 8;
        require(getConversionRate(msg.value) >= minimumUSD);
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
    //    msg.sender.transfer(address(this).balance);
        // payable(msg.sender).transfer(address(this).balance);
        address payable payable_addr = payable(msg.sender);
        payable_addr.transfer(address(this).balance);

       for (uint256 i = 0; i < funders.length; i++) {
           address funder = funders[i];
           addressToAmount[funder] = 0;
       }

       funders = new address[](0);
    }

    // RINKEBY PRICE FEED ADDRESS IS USED

    function getVersion() public view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int price,,,) = priceFeed.latestRoundData();
        return uint(price);
    }

    // 10000000000000000
    function getConversionRate(uint amtInWei) public view returns (uint) {
        uint ethUSD = getPrice();
        uint amtUSD = (ethUSD * amtInWei) / 10 ** 18;
        return amtUSD;
        // 17.94
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