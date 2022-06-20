//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// Brownie can download directly from Github
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public address_to_amount_funded; // Can't go through all keys in a mapping. need to create a seperate array
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 min_USD = 50 * 10**18;
        require(
            get_conversion_rate(msg.value) >= min_USD,
            "You need to spend more Ethereum brah"
        );
        address_to_amount_funded[msg.sender] = msg.value;
        funders.push(msg.sender);
        // Need ETH to USD conversion rate. no decimals on solidity
        // No chainlink nodes on testnet.
        // Interfaces compile down to ABI. Always need an ABI to interact with a contract
    }

    function get_version() public view returns (uint256) {
        AggregatorV3Interface price_feed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return price_feed.version();
    }

    function get_price() public view returns (uint256) {
        AggregatorV3Interface price_feed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = price_feed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function get_conversion_rate(uint256 eth_amount)
        public
        view
        returns (uint256)
    {
        uint256 eth_price = get_price();
        uint256 eth_amount_in_usd = (eth_price * eth_amount) /
            1000000000000000000;
        return eth_amount_in_usd;
        // 0.000001188513010280
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // This means run the rest of the code
    }

    function withdraw() public payable onlyOwner {
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance); // This is a keyword to refer to the contract that you are currently in.
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            address_to_amount_funded[funder] = 0;
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