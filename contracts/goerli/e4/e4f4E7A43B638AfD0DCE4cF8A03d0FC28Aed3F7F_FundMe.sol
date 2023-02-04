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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
// importing AggregatorV3Interface of ChainLink Data Feeds.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    address public immutable i_owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public immutable priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.convertEthToUSD(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        // reset array
        funders = new address[](0);

        /*
            Withdraw Funds: 
                1. transfer
                2. send
                3. call
            solidity by example
        */
        // transfer
        payable(msg.sender).transfer(address(this).balance); // throws error if failed

        // send
        bool sendStatus = payable(msg.sender).send(address(this).balance); // returns boolean
        require(sendStatus, "Send Failed");

        // call
        (bool callStatus, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callStatus, "Call Failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// importing AggregatorV3Interface of ChainLink Data Feeds.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getEthPriceInUSD(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        /* since we are interacting with a smart contract outside of ours,
        we need its ABI and Adderss. */

        /* 
            Network: Eth Goerli Testnet
            Aggregator: ETH/USD
            Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        */

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function convertEthToUSD(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPriceInUSD = getEthPriceInUSD(priceFeed);
        uint256 calculatedUSD = (ethAmount * ethPriceInUSD) /
            1000000000000000000;
        return calculatedUSD;
    }
}