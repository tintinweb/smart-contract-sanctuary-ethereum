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

// Using some advanced solidity to use gas more efficiently: 
// - constant, immutable
// - custom error in require revert
// - special function: receive, fallback

// Some more advanced Solidity:
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner(); // idea

contract FundMe {
    using PriceConverter for uint256;


    // constant, immutable => state variables
    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address public immutable i_contractOwner;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner {
        // require(msg.sender == i_contractOwner, "Sender is not owner!");
        // replace by custom error
        if (msg.sender != i_contractOwner) {
            // revert("Sender is not owner!");
            revert NotOwner();
        }
        _; 
    }
    
    constructor(address priceFeedAddress) {
        i_contractOwner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH! Haha"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

   
    function withdraw() public onlyOwner {
        // for loop: starting index; ending index; step amount
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset an array
        funders = new address[](0); // reset all with value of 0

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");

    }


    // What happens if someone sends this contract ETH without calling the fund function ?
    // Ví dụ: send ETH từ Metamask wallet tới contract mà không gọi fund() function
    receive() external payable  {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// get chainlink data feed contract interface from: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library can't declare any state variable and you can't send ether.
library PriceConverter {
  // We could make this public, but then we'd have to deploy it
  function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    // remove this fixed code => using param priceFeed
    
    // AggregatorV3Interface priceFeed = AggregatorV3Interface(
    // // Goerli ETH / USD Address
    // // https://docs.chain.link/docs/ethereum-addresses/
    //   0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // );
    
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
    // or (Both will do the same thing)
    // return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
  }

  // 1000000000
  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // or (Both will do the same thing)
    // uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 1 * 10 ** 18 == 1000000000000000000
    // the actual ETH/USD conversion rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }

  function getVersion() public view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    );
    return priceFeed.version();
  }
}