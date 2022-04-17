// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded; //to keep the track of people who send us money

    address[] public funders;

    address public owner;

    constructor() public {
        //constructor gets called instantly when the contract is deployed
        owner = msg.sender;
    }

    function fund() public payable {
        // this payable keyword says that this fund function can be used to pay things
        uint256 minimumusd = 50 * 10 * 18;
        require(
            getconversionrate(msg.value) >= minimumusd,
            "You need to spend more eth you stupid brokeass"
        ); //if you used a require statement it will check the truthiness of the given statement
        addressToAmountFunded[msg.sender] += msg.value; //msg.sender is the sender of function called and msg.value is how much they send
        funders.push(msg.sender);
    }

    function getversion() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return pricefeed.version();
    }

    function getprice() public view returns (uint256) {
        //we are doin this to get usd - eth price
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); //got this address from https://docs.chain.link/docs/ethereum-addresses/
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pricefeed.latestRoundData();
        return uint256(answer);
        //3058.43451491  last 8 digits are in dec
    }

    function getconversionrate(uint256 ethamount)
        public
        view
        returns (uint256)
    {
        uint256 ethprice = getprice();
        uint256 ethamountinusd = (ethprice * ethamount) / 1000000000000000000;
        return ethamountinusd;
    }

    modifier onlyowner() {
        require(msg.sender == owner, "FUCK OFF");
        _;
    }

    function withdraw() public payable onlyowner {
        payable(msg.sender).transfer(address(this).balance); //transfer function is used to send money from one address to another, this keyword basically means the contract you are currently in
        for (
            uint256 funderindex = 0;
            funderindex < funders.length;
            funderindex++
        ) {
            address funder = funders[funderindex];
            addressToAmountFunded[funder] = 0;
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