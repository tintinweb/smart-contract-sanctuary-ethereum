// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    //using library for specific type
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //list of address.
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //want to set a minimum amount to usd!
        //getConversionRate(msg.value) it change after using our own library.
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enouph!"
        );
        //taking the eth sender account's address.
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /*starting index, ending index, step amount*/
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //reset an Array, (0) is the count of object inside the array
        funders = new address[](0);

        //actualy withdraw the funds

        //1.transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        //2.send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed!");

        //3.call /best way for now.
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //if someone accedently send money or call the wrong function receive will call the fund function.
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // dont need this line because we pass it as parameter
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //ETH in terms of USD
        //3000.00000000
        return uint256(answer * 1e10); // 1**10 = 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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