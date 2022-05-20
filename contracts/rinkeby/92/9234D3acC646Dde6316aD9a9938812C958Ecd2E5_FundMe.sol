// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//import "AggregatorV3Interface.sol";
//        /home/nocpi/.brownie/packages/smartcontractkit/[email protected]/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "AggregatorV3Interface.sol";

contract FundMe {
    // Add a constructor, so only the owner of the contract can withdraw funds.
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 usdAmount = (ethPrice * ethAmount) / 10000000000;
        return usdAmount;
    }

    function fund() public payable {
        // $5
        uint256 minimumUSD = 5 * 10**18;

        // Use `require` as opposed to `if` and then `revert`.  It's cleaner and cheaper.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Minimum of $50 worth of ETH required."
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Chainlink call
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            ,
            //uint80 roundId,
            int256 answer, //uint256 startedAt, //uint256 updatedAt, //uint80 answeredInRound
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // Ethereum price with precision=8 but no decimals.
    }

    /*
    function withdraw() public payable {
        // Transfer this contranct's balance to the address that called the withdraw function.
        require(msg.sender == owner, "Only the owner of the contract can withdraw funds.");
        payable (msg.sender).transfer(address(this).balance);
    }
    */

    // Modifiers are used to change the behavior of a function in a declarative way.
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can withdraw funds."
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
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