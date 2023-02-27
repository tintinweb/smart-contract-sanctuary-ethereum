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

import "./PriceConvertor.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

//Following is a Natspec format comments which comes handy when creating userdocs

/**
 * @title A contract for crowd funding
 * @author kushuchiha
 * @notice demo project
 */

contract FundMe {
    using PriceConverter for uint256;

    uint public minusd = 50 * 1e18;

    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        if (msg.sender != owner) revert FundMe__NotOwner();
        _; // do rest of the code
    }

    constructor(address PriceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(PriceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This functions funds the contract
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) > 1e18,
            "Didn't send enough"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        //transfer
        //    payable(msg.sender.transfer(address(this).balance));

        //send
        //    bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //  require(sendSuccess,"Send Failed");

        //call we know it returns 2 var but we dont care about another
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    //first implement everything before underscore
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //ADDRESS : 0x694AA1769357215DE4FAC081bf1f309aDC325306 sepolia eth/usd proxy address
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );
        (, int price, , , ) = priceFeed.latestRoundData(); //commas since other data is also there
        return uint256(price * 1e10);
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x694AA1769357215DE4FAC081bf1f309aDC325306
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}