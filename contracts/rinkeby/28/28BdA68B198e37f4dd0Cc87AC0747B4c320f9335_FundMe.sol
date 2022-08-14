//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConvertor.sol";

//gas 958055// const 935561
//transaction cost 833,091 // const 813,531

error FundMe_NotOwner();

/**@title A crowd funding contract
 * @author Rob
 * @notice the Contract is for demo
 * @dev This Implements price feeds as our library
 
 */

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    //cost 813531
    //non const 833103
    address[] public funders;
    mapping(address => uint256) public AddrsstoFunds;
    address public immutable i_owner;

    modifier OnlyOwner() {
        //require(msg.sender ==i_owner, "not owner");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        //non 23600
        //immutable 21508
    }

    function fund() public payable {
        require(
            msg.value.GetConversionPrice(priceFeed) >= MINIMUM_USD,
            "not enough funds"
        );
        funders.push(msg.sender);
        AddrsstoFunds[msg.sender] += msg.value;
    }

    function withdrawal() public OnlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "not owner");

        for (
            uint256 fundersIndex = 0;
            fundersIndex > funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            AddrsstoFunds[funder] = 0;
            funders = new address[](0);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// address- 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

library PriceConvertor {
    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function GetConversionPrice(
        uint256 EthAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 EthPrice = getPrice(priceFeed);
        uint256 EthPriceinUsd = (EthAmount * EthPrice) / 1e18;
        return EthPriceinUsd;
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