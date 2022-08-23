//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceConverter.sol";
// constant, immutable

// 901,447 gas
// 881,936 gas

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18; usually constants have all caps
    // 21,393 gas - constant
    // 23,493 gas - non-constant
    // 21,393 * 6000000000 = 128,358,000,000,000 = $0.240799608
    // 23,493 * 6000000000 = 140,958,000,000,000 = $0.264437208

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // require(getConversionRate(msg.value) > minimumUsd, "Didn't send enough!"); // access the value attribute with global keyword 'msg'
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );

        funders.push(msg.sender); // msg.sender is the address
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function wihdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner!"); -> will use modifiers instead
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset array
        funders = new address[](0); // resetting array (0),(1) ..how many elements the new array should have
        // actually withdraw the funds

        // transfer
        // msg.sender = type address
        //payable(msg.sender) = type payable address
        payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // call - recomended way to send and receive blockchain native token
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}(""); // dataReturned is string so we need memory
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // only what we need
        require(callSuccess, "Call failed");
        // revert(); -you can revert wherever you want
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!"); - use custom error instead
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // represents the rest of the code from the function where the modifier is used
    }

    // What happens if someone sends this contract ETH without calling the fund function?

    // receive() - special function
    receive() external payable {
        fund();
    }

    // fallback() - special function
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000; covert from int256 to uint256
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH

        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 36 zeros if not divided
        // 2999.999999999999999999 = 2999e21 ->3000
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