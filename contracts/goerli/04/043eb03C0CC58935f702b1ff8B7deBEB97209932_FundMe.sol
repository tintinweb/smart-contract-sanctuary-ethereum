// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface priceFeed;
    mapping(address => uint256) public addressToAmount;
    address[] public funders;
    address public owner;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function"
        );

        _;
    }

    function fund() public payable {
        uint256 price = getPrice();
        uint256 val = msg.value;
        require((price / (10**8)) * (val / (10**18)) > 5, "Hmm...");
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function is_valid_fund(uint256 wei_num) public view returns (uint256) {
        uint256 price = getPrice();
        uint256 decs = decimals();
        return ((price / (10**decs)) * wei_num) / (10**18);
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function decimals() public view returns (uint256) {
        uint256 decs = priceFeed.decimals();
        return decs;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        uint256 funderLength = funders.length;
        for (uint256 i = 0; i < funderLength; i++) {
            address funderAddress = funders[i];
            addressToAmount[funderAddress] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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