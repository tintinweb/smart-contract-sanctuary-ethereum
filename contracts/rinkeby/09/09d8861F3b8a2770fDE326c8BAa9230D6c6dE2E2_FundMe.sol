// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

import "./PriceConverter.sol";

// lower gas to create contract
// constant, immutable
// each character in string also takes up space so we can change the require()

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  // (step1) uint256 public minUSD = 50;
  // constant does not take up storage
  uint256 public constant MINIMUM_USD = 50 * 1e18;

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable iOwner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    iOwner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  // NOTE: smart contracts can hold funds just like how wallets can
  // NOTE: 'payable' modifier allows function to receive ether
  function fund() public payable {
    // set minimum fund amount in USD
    // NOTE: eth converter https://eth-converter.com/
    // NOTE: msg is global. msg.value is how much Wei sent when calling this function

    // (step 1) require(msg.value > 1e18, "Didn't send enough!"); // 1e18 = 1 x 10 ^ 18 = 1000000000000000000 Wei = 1 ETH
    // msg.value gets sent as first parameter in getConversionRate()
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Didn't send enough!"
    ); // 1e18 = 1 x 10 ^ 18 = 1000000000000000000 Wei = 1 ETH
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function widthdraw() public onlyOwner {
    // (step 1) make sure only owner of contract can withdraw
    // require(msg.sender == owner, "Sender is not owner");

    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      // since withdrawing we are resetting the amount funded by people (addresses)
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }

    // reset array
    funders = new address[](0);

    // widthraw the funds (3 ways)
    // NOTE: check solidity-by-example.org/sending-ether for good reference

    // 1. transfer
    // NOTE: capped at 2300 gas. If goes over, the tansfer fails and it throws and error and revert transaction
    // NOTE: this keyword is referring to this contract
    // NOTE: need to typecast msg.sender because
    // msg.sender = address whereas
    // payable (msg.sender) = payable address
    payable(msg.sender).transfer(address(this).balance);

    // 2. send
    // NOTE: capped at 2300 gas. If goes over, the send returns a bool and doesn't error so we need a require() to revert transaction
    bool sendSuccess = payable(msg.sender).send(address(this).balance);
    require(sendSuccess, "Send failed");

    // 3. call (preferred way to transfer funds as of now)
    // NOTE: no capped gas, returns bool for success/fail
    // (step 1) (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  // NOTE: if we know we'll need to check for owner in a lot of functions
  //       we can use modifer so modifier will get executed first before the
  //       rest of the function
  modifier onlyOwner() {
    // make sure only owner of contract can withdraw
    //require(msg.sender == iOwner, "Sender is not owner");

    if (msg.sender != iOwner) {
      revert NotOwner();
    }

    _; // means execute rest of the code...
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NOTE: Using chainlink data feed to get real time price https://docs.chain.link/docs/get-the-latest-price/
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // ABI
    // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e -> https://docs.chain.link/docs/ethereum-addresses/ go to Rinkby section for test net
    // NOTE: Aggregator interface https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
    priceFeed = AggregatorV3Interface(priceFeed);

    // NOTE: (unit80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
    // Since only need int price we can write it like the below:
    (, int256 price, , , ) = priceFeed.latestRoundData();

    // ETH in terms of USD
    // e.g. 3000.00000000 -> 8 decimals
    // NOTE: Aggregator has a function decimals() that tells us it is 8 decimals places
    // Since we need to compare this USD value to our Wei value, we need to convert this numeber to Wei which is 18 decimals,
    // so add 10 more decimal places
    // Since we are also comparing this price (int256) to our minUSD (uint256) we can typecast
    return uint256(price * 1e10);
  }

  // function getVersion() internal view returns (uint256) {
  //   AggregatorV3Interface priceFeed = AggregatorV3Interface(
  //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
  //   );
  //   return priceFeed.version();
  // }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // e.g. getPrice() = 3000_000000000000000000
    // ethAmount = 1_000000000000000000
    // ethAmountInUSD = 3000.00000000000000000
    uint256 ethPrice = getPrice(priceFeed);

    uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUSD;
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