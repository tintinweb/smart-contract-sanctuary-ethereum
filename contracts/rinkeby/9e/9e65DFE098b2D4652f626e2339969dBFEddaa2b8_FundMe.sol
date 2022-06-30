// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Steve Place
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address public immutable owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address _priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Please cover entry fee!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    // function withdraw() public onlyOwner {
    //     uint256 fundersLength = funders.length; // memory variable for gas optimization
    //     for (uint256 i = 0; i < fundersLength; i++) {
    //         addressToAmountFunded[funders[i]] = 0;
    //     }
    //     funders = new address[](0);
    //     (bool sent, ) = owner.call{value: address(this).balance}("");
    //     require(sent, "Failed to withdraw Ether");
    // }

    function withdraw() public onlyOwner {
        address[] memory m_funders = funders;
        for (uint256 i = 0; i < m_funders.length; i++) {
            addressToAmountFunded[m_funders[i]] = 0;
        }
        funders = new address[](0);
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw Ether");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // get price to 18 decimals
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return (ethAmount * getPrice(priceFeed)) / 1e18;
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