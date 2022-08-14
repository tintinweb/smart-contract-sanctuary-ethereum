//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./priceFeed.sol";

contract Fundme is priceFeed {
    address public owner;

    uint256 public minimumValue;

    struct Funders {
        address addresFunders;
        uint256 amount;
    }

    Funders[] public funders;

    mapping(address => uint256) public addressToAmount;

    address public priceFeedd;

    constructor(uint256 _minimumValue, address addresblock) {
        owner = msg.sender;
        minimumValue = _minimumValue * 1e18;
        priceFeedd = addresblock;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are no the owner");
        _;
    }

    function fundContract() public payable {
        uint256 valueInUsd = convertEthToUsd(msg.value, priceFeedd);
        require(valueInUsd > minimumValue, "send more eth");
        addressToAmount[msg.sender] = msg.value;
        funders.push(Funders(msg.sender, msg.value));
    }

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmount[funders[i].addresFunders] = 0;
            funders[i].amount = 0;
        }

        (bool sendMoney, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sendMoney, "not suceesfull");
    }

    receive() external payable {
        fundContract();
    }

    fallback() external payable {
        fundContract();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract priceFeed {
    function getEthPriceInUsd(address priceAddress)
        internal
        view
        returns (uint256)
    {
        AggregatorV3Interface PriceFeed = AggregatorV3Interface(priceAddress);
        (, int256 price, , , ) = PriceFeed.latestRoundData();
        return uint256(price);
    }

    function convertEthToUsd(uint256 _amount, address priceAddress)
        internal
        view
        returns (uint256)
    {
        uint256 priceUsd = getEthPriceInUsd(priceAddress) * 1e10;
        uint256 amountInEth = (_amount * priceUsd) / 1e18;
        return amountInEth;
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