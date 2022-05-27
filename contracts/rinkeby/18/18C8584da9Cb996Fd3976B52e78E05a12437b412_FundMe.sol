/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

// import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol"; // brownie revision 1

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    // AggregatorV3Interface public priceFeed; // brownie revision 1

    constructor() {
        // constructor(address _priceFeed) {
        // brownie revision 1
        // priceFeed = AggregatorV3Interface(_priceFeed); // brownie revision 1
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumEthUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumEthUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface( // brownie revision 1
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface( // brownie revision 1
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
        // return uint256(answer);

        // 3283.566884620000000000
        // 3171.697244390000000000
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        uint256 ethAmountInUSD = (ethPrice / 1000000000000000000) * ethAmount;
        return ethAmountInUSD;
        // return (ethAmountInUSD / 1000000000000000000);

        // 3283000
    }

    function numOfDecimals() external view returns (uint8) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.decimals();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // Only want the contract admin/owner

        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getSender() public view returns (address) {
        return msg.sender;
    }

    function getSenderValue() public payable returns (uint256) {
        uint256 senderValue = msg.value;
        return senderValue;
    }
}