// SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.18;
//Imports
import "./PriceConverter.sol";
//error
error FundMe__Unauthorized();

/**
 * @title This is a contract for crowd funding
 * @author Fahm21
 * @notice This is just a sample and should not be used for live development
 * @dev This contract gives us the current eth price, stores funder and more
 */

contract FundMe {
    //Type declaration
    using PriceConverter for uint256;

    //state variables
    address[] private s_funders;
    mapping(address => uint256) private s_fundersToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    //events
    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__Unauthorized();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    function fund() public payable {
        if (msg.value.getConvertionRate(s_priceFeed) <= MINIMUM_USD) {
            revert FundMe__Unauthorized();
        }

        s_fundersToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory cheapfunders = s_funders;

        for (uint i = 0; i < cheapfunders.length; i++) {
            s_fundersToAmountFunded[cheapfunders[i]] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert FundMe__Unauthorized();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAmountFunded(address funder) public view returns (uint256) {
        return s_fundersToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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