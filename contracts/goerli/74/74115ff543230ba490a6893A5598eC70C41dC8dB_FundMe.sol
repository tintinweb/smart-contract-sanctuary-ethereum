//get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// without constant - current gas = 918755
// added constant keyword - new gas = 898773

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18; // can use constant since will never change

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    //875314 with immutable owner
    //898761 without immutable owner

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // msg.sender will be whoever deployed the contract.
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to set a minimum amount in USD
        // 1. How do we send Eth to this contract
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH!"
        );
        funders.push(msg.sender);
        // addressToAmountFunded[msg.sender] = msg.value; <-- This previously which is an error since it means that the same funder sending funds twice will overwrite rather than add in the mapping.
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // starting index, stop condition, step amount
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            /* under index should automatically be set zero. Redundancy?*/
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the funders array, with zero elements inside
        funders = new address[](0);

        // actually withdraw the funds

        // TRANSFER
        // msg.sender is type 'address'
        // payable(msg.sender) is type 'payable address' --> only payable addresses can do transfers
        // payable(msg.sender).transfer(address(this).balance);
        // SEND
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!")
        // CALL --> recommended way to transfer amounts
        (
            bool callSuccess, /*bytes memory dataReturned* --> can leave the trailing comma as var not needed*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // represents the code of the function
    }

    // What happens when someone sends our contract ETH without using the fund function?

    // Special functions
    receive() external payable {
        // runs when ETH sent without call data no msg.data
        fund();
    }

    fallback() external payable {
        // runs when ETH sent with call data msg.data
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
        // We need two things to interact with external contracts.
        // ABI
        // Address 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // USD price of ETH to 8 decimal places.
        return uint256(price * 1e10); // type cast to uint and convert to correct decimal places. Price is currently to 8 decimals so add 10 more to get the equivalent Wei
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