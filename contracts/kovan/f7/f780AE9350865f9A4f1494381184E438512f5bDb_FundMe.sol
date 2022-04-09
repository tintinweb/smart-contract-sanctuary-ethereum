//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface private priceFeed =
        AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    mapping(address => uint256) public addressToAmount;
    address private owner;
    address[] private funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable onlyNonOwner {
        uint256 usrAmtInWEI = msg.value;
        uint256 minimumUSD = 50;
        uint256 minimumUSDinWEI = getConversionUSDToWEI(minimumUSD);
        uint256 minimumUSDinGWEI = minimumUSDinWEI / (10**9);

        require(
            usrAmtInWEI >= minimumUSDinWEI,
            "You need to spend more ETH - minimum 50 USD!"
        );
        addressToAmount[msg.sender] += usrAmtInWEI;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only admin can withdraw funds!");
        _;
    }
    modifier onlyNonOwner() {
        require(owner != msg.sender, "Only non admin can fund this!");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmount[funders[i]] = 0;
        }
        funders = new address[](0);
    }

    function getConversionUSDToWEI(uint256 inputAmtUSD)
        private
        pure
        returns (uint256)
    {
        uint256 usdToEth = inputAmtUSD * (10**9) * (10**9) * (10**8);
        usdToEth = usdToEth / getPriceHardCode();
        return usdToEth;
    }

    function getPriceHardCode() private pure returns (uint256) {
        // returns price of (10 ** 8) ETH in USD
        uint256 ans = 332451516808;
        return ans;
    }

    function getPrice() private view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
        //332451516808
    }

    function getPriceAll()
        private
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerInRound
        ) = priceFeed.latestRoundData();
        return (roundId, answer, startedAt, updatedAt, answerInRound);
    }
}

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