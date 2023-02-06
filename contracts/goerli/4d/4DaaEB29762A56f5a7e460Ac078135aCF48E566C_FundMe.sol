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
//pragma version

//imports
import "./PriceConverter.sol";

//error messages
error FundMe__NotOwner();

//interfaces, libraries, contracts

/** @title A contract for crowd funding
 *  @author BlockHunt
 *  @notice This contract is to demo a sample funding contract
 *  @dev  This implement price feeds as our library
 */

contract FundMe {
    //type Declarations
    using PriceConverter for uint256;

    //State Variables
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // Could we make this constant?
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;

    AggregatorV3Interface public priceFeed;

    // Events (we have none!)

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     *  @notice This function funds the contract
     *  @dev  This function allows users to fund
     */

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}

// library PriceConverter {
//     // We could make this public, but then we'd have to deploy it
//     function getPrice() internal view returns (uint256) {
//         // Goerli ETH / USD Address
//         // https://docs.chain.link/docs/ethereum-addresses/
//         AggregatorV3Interface priceFeed = AggregatorV3Interface(
//             0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
//         );
//         (, int256 answer, , , ) = priceFeed.latestRoundData();
//         // ETH/USD rate in 18 digit
//         return uint256(answer * 10000000000);
//         // or (Both will do the same thing)
//         // return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
//     }

//     // 1000000000
//     function getConversionRate(
//         uint256 ethAmount
//     ) internal view returns (uint256) {
//         uint256 ethPrice = getPrice();
//         uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
//         return ethAmountInUsd;
//     }

// }