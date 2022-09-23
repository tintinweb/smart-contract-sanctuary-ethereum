// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    uint256 public usdValue;
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 5;
        usdValue = ConvertWeiInUsd(msg.value);
        require(usdValue >= minimumUSD, "You need to spend more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // ETH to USD conversion rate

    function ConvertWeiInUsd(uint256 _gwei) public view returns (uint256) {
        AggregatorV3Interface latestRoundData = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 answer, , , ) = latestRoundData.latestRoundData();
        return
            (_gwei * uint256(answer)) /
            (10**uint256(latestRoundData.decimals())) /
            (10**18);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not allowed to carry this transaction"
        );
        _;
    }

    function Withdraw() public payable onlyOwner {
        msg.sender.transfer(addressToAmountFunded[msg.sender]);
        for (uint256 x = 0; x < funders.length; x++) {
            addressToAmountFunded[funders[x]] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
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