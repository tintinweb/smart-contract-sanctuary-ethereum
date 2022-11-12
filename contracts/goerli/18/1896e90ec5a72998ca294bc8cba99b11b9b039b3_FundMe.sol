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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PriceConverter.sol";

/// Only owner can withdraw tokens
error NotOwner();
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 1 * 10**18;
    address[] public funders;
    address public /*immutable*/  i_owner;
    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) public addressToAmountFunded;
    
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,

            "Didn't send enough " 
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner{
        for (uint256 funderInd = 0; funderInd < funders.length; ++funderInd)
        {
            address funder = funders[funderInd];
            addressToAmountFunded[funder] = 0;
        }
        // rset the array
        funders = new address[](0);

        // transfer funds:-
        // TO_ADDRESS.....(AMOUNT)

        /*
        // 1. transfer [Not recommended]
        // reverted automatically if failed
        payable(msg.sender).transfer(address(this).balance);

        // 2. send [Not recommended]
        // return a status variable
        bool sendStatus = payable(msg.sender).send(address(this).balance);
        require(sendStatus, "Send Failed");
        */

        // 3. call [recommended]
        // return 2 variable (status, data)
        (bool callSuccess, /*bytes memory dataReturned*/)  = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

     modifier onlyOwner {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    // receive function 
    receive() external payable {
        fund();
    }

    fallback() external payable{
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ETH/USD contract Address for goerili 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price have 12 digit
        // eg. 132590514126
        // actual price = 1325.90514126
        // since all of the calculation is in wei
        // format this by multiply 1e10 or (1 ^ 10)
        // and price become 1325905141260000000000
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // price of 1 eth in USdoller
        uint256 ethPrice = getPrice(priceFeed);
        // multiply ethPrice with the ethAmount provided by user (in wei)
        uint256 ethAmountINUsd = (ethAmount * ethPrice) / 1e18;
        // returns the value of ethamount provided in USDoller
        return ethAmountINUsd;
    }
}