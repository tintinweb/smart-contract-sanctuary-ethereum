// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
  uint256 public undefinedNumber;
  int256 public undefinedInt;
  string public undefinedString;
  bool public undefinedBoolean;
  bytes2 public undefinedBytes2;
  bytes32 public undefinedBytes32;
  address public undefinedAddress;

  uint8 public newUint8 = 255;
  uint16 public newUint16 = 65535;
  uint32 public newUint32 = 4294967295;
  int256 public newInt = -123;
  string public newString = "elo";
  bool public newBoolean = true;
  bytes2 public newBytes2 = "yo";
  bytes32 public newBytes32 = "cat";
  address public newAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

  string public publicKey = "411VM";

  // uint256 public numb = 999;
  // bytes public fullName;

  // function removePubKey() public {
  //     publicKey = "";
  // }

  // function setPubKey(string calldata _newPubKey) public {
  //     publicKey = _newPubKey;
  // }

  function setFullName() public pure returns (uint256) {
    return 411;
  }

  using PriceConverter for uint256;
  event Funded(address indexed from, uint256 amount);

  mapping(address => uint256) public addressToAmountFunded;
  address[] public funders;
  // Could we make this constant?  /* hint: no! We should make it immutable! */
  address public owner;
  uint256 public constant MINIMUM_USD = 50 * 10**18;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "You need to spend more ETH!"
    );
    // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
    emit Funded(msg.sender, msg.value);
  }

  modifier onlyOwner() {
    // require(msg.sender == owner);
    if (msg.sender != owner) revert NotOwner();
    _;
  }

  function withdraw() public payable onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  function elo() public {
    owner = msg.sender;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
  // We could make this public, but then we'd have to deploy it
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversion rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}