// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe1 {
    mapping(address => uint256) public addressToAmountFunded1;

    address[] public funder1;
    address public owner1;

    // Call instance when it deploy
    constructor() public {
        owner1 = msg.sender;
    }

    function fund1() public payable {
        uint256 minimunUSD1 = 2 * 10**18;
        require(
            getConversionRate1(msg.value) >= minimunUSD1,
            "You need. more ETH!"
        );

        addressToAmountFunded1[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate
        funder1.push(msg.sender);
    }

    function getVersion1() public view returns (uint256) {
        // ETH/USD
        // Kovan
        AggregatorV3Interface priceFeed1 = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // Rinkbly
        // AggregatorV3Interface priceFeed1 = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed1.version();
    }

    function getPrice1() public view returns (uint256) {
        // Kovan
        AggregatorV3Interface priceFeed1 = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // Rinkbly
        // AggregatorV3Interface priceFeed1 = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // Return only value that you want from (tuples)
        (, int256 answer, , , ) = priceFeed1.latestRoundData();
        // Change type of var

        // Return 18 decimals
        return uint256(answer * 10000000000);
        //  2,527.75685444
    }

    // 1000000000 Gwei = 1 ETH
    function getConversionRate1(uint256 ethAMount1)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice1 = getPrice1();
        uint256 ethAMountInUsd1 = (ethPrice1 * ethAMount1) /
            1000000000000000000;
        return ethAMountInUsd1;
        // 1 wei = 0.000002628911697510 usd
    }

    modifier onlyOwner1() {
        require(msg.sender == owner1);

        // Run the rest of the code
        _;
    }

    // Only owner CAN BE WITDRAW
    function witdraw1() public payable onlyOwner1 {
        // Solidity >0.8.0
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funder1Index = 0;
            funder1Index < funder1.length;
            funder1Index++
        ) {
            address funder1 = funder1[funder1Index];
            addressToAmountFunded1[funder1] = 0;
        }
        // Create new blank address array
        funder1 = new address[](0);
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