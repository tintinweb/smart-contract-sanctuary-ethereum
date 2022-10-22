// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";

error FundMe__MinimumFundAmount();
error FundMe__OwnerError();

/** @title Fund donation contract
 *  @author Pattrick collins
 *  @notice Fund donation contract dev
 *  @dev Fund donation contract dev
 */
contract FundMe {
    // Type declarations
    using PriceConvertor for uint256;

    // State declarations
    uint256 public constant minimumUSD = 10;
    address immutable ownerWallet;
    address[] public funders;
    mapping(address => uint256) public fundersHistory;
    AggregatorV3Interface public priceFeed;

    // modifiers
    modifier isOwner() {
        if (msg.sender != ownerWallet) revert FundMe__OwnerError();
        _;
    }

    // functions
    constructor(address priceFeedAddress) {
        ownerWallet = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     *  @notice Fund donation contract dev
     *  @dev implelemtnts fund function for this conteract
     */
    function fund() public payable {
        // if (msg.value.getConversionRate(priceFeed) < (minimumUSD * 1e18))
        //     revert FundMe__MinimumFundAmount();
        require(
            msg.value.getConversionRate(priceFeed) > (minimumUSD * 1e18),
            "SpendMoreETH"
        );

        funders.push(msg.sender);
        fundersHistory[msg.sender] = msg.value;
    }

    function withdraw() public isOwner {
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            fundersHistory[funder] = 0;
        }
        funders = new address[](0);
        // send funds
        (bool callRes, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callRes, "call operation didn't work");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/** @title PriceConvertor contract
 *  @author Pattrick collins
 *  @notice PriceConvertor
 *  @dev PriceConvertor
 */
library PriceConvertor {
    function lastETHUSDPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 lastprice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(lastprice * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = lastETHUSDPrice(priceFeed);
        uint256 amountOnUSD = (ethAmount * ethPrice) / 1e18;
        return amountOnUSD;
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