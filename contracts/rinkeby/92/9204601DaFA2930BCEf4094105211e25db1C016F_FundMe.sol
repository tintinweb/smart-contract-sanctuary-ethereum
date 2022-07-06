// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    address payable public i_owner;
    uint256 minimumFee = 50 * 10**8;
    address[] public funders;
    uint256 public s_favNum;
    AggregatorV3Interface internal s_priceFeed;

    mapping(address => uint256) addressToAmountFunded;

    constructor(address priceFeedAddress) {
        i_owner = payable(msg.sender);
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // modifier onlyOwner() {
    //     require(msg.sender == i_owner, "only the owner can witdraw");
    //     _;
    // }

    error fundMe__needMoreEth();
    error fundMe__onlyOwnerCanWithdraw();

    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 price = uint256(answer);
        return price;
    }

    function fund() public payable {
        uint256 amount = (msg.value * getPrice(s_priceFeed)) / 10**18;
        if (amount < minimumFee) {
            revert fundMe__needMoreEth();
        }
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public {
        if (i_owner != msg.sender) {
            revert fundMe__onlyOwnerCanWithdraw();
        }
        i_owner.transfer(address(this).balance);
        for (uint256 index; index < funders.length; index++) {
            addressToAmountFunded[funders[index]] = 0;
        }
        funders = new address[](0);
    }

    function getFundersLength() public view returns (uint256) {
        return funders.length;
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