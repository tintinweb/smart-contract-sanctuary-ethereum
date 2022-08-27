//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract fundContract {
    address owner;

    mapping(address => uint256) public donators;

    address[] public donators_addresses;

    AggregatorV3Interface priceFeed;

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function minDonation() public view returns (uint256) {
        return (5 * 10**27) / uint256(getPrice());
    }

    function donate() public payable {
        require(
            msg.value >= minDonation(),
            "Not enough funds: Min donation is 50$"
        );
        donators[msg.sender] += msg.value;
        donators_addresses.push(msg.sender);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i; i < donators_addresses.length; i++) {
            donators[donators_addresses[i]] = 0;
        }
        //donators_addresses array will be initialized to 0
        donators_addresses = new address[](0);
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