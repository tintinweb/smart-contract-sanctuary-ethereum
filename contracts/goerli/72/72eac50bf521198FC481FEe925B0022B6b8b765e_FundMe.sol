// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";
// at the time of writing, goerli network to be selected

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    //using constant for var that are set only 1 time make it more gas efficient
    // initial deploy 831,183
    // using constant 811,025
    address public immutable i_owner; // convention to name immutable var like this

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "you are not the owner");
        // string consume more gas. Custom error use less
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        // 1.How to send ETH to this contract ?
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough ETH");
        // 1eth = 1e18 = 1 * 10 ** 18 == 1000000000000000000
        // could be msg.value >= 1e18

        // msg.value.getConversionRate() === getConversionRate(msg.value)
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() payable public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length ; funderIndex ++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    //important to handle the case if someone trigger a function that doesn't exist or just send eth to the contract
    // otherwise we get eth in the balance but no record of funder
    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// to get rid of this : yarn add --dev @chainlink/contracts

library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
         // ETH in terms of USD
        //returns 3000.00000000 ( 8 decimals ) we need 18 decimals
        return uint256(price * 1e10); // 1**10
    }


    function getVersion() internal view returns (uint256){
      // get the address of the right contract here  :https://docs.chain.link/docs/ethereum-addresses/
      AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
      return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // 1e18
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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