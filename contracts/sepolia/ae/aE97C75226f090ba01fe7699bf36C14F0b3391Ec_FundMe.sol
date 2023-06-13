// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./PriceConverter.sol";

error Unauthorized();

contract FundMe {
    address public immutable i_owner;
    AggregatorV3Interface public immutable i_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public fundersToAmountFunded;

    function fund() public payable {
        if (msg.value.getConvertionRate(i_priceFeed) <= MINIMUM_USD) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < funders.length; i++) {
            if (msg.sender != funders[i]) {
                funders.push(msg.sender);
            } else {
                return;
            }
        }
        fundersToAmountFunded[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            fundersToAmountFunded[funders[i]] = 0;
        }

        funders = new address[](0);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Unauthorized();
        }
        _;
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

pragma solidity ^0.8.18;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        return (ethPrice * ethAmount) / 1e18;
    }
}