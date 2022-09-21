// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import 'hardhat/console.sol';
import './PriceConverter.sol';

error NotOwner();

/**
 * @title A contract for crowd funding
 * @author Roman Scher
 * @notice This contract is to demo a sample funding contract
 */
contract FundMe {
    uint256 public constant MINIMUM_USD = 50;

    address[] public funders;
    mapping(address => uint256) public amountFundedByAddress;
    AggregatorV3Interface public priceFeed;
    address public immutable owner;

    modifier isOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        //require(msg.sender == owner, "You are not the owner!");
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // function getEthUsdPrice() public view returns (uint256) {
    //     return PriceConverter.getEtherPriceInUsd(priceFeed);
    // }

    /**
     * @notice Funds this contract
     */
    function fund() public payable {
        // console.log(
        //     'Ether price is: ',
        //     PriceConverter.getEtherPriceInUsd(priceFeed)
        // );
        uint256 valueInUsd = PriceConverter.convertWeiToUsd(
            msg.value,
            priceFeed
        );
        require(valueInUsd >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        amountFundedByAddress[msg.sender] = msg.value;
    }

    /**
     * @notice Funds this contract
     */
    function withdraw() public isOwner {
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            amountFundedByAddress[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }

    // function cheaperWithdraw() public payable isOwner {
    //     address[] memory fundersInMemory = funders;
    //     for (uint256 index = 0; index < fundersInMemory.length; index++) {
    //         address funder = fundersInMemory[index];
    //         amountFundedByAddress[funder] = 0;
    //     }
    //     funders = new address[](0);
    //     (bool success, ) = msg.sender.call{value: address(this).balance}('');
    //     require(success, 'Withdraw failed');
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
    uint8 private constant ETHER_TO_WEI_NUMBER_OF_DECIMALS = 18;
    uint256 private constant WEI_PER_ETHER = 1e18;

    function getEtherPriceInUsd(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 priceNumberOfDecimals = priceFeed.decimals();

        // usd per eth
        // 1 ether (1e18) / 3000.00000000 usd
        // 1e18 wei * 1e18 / 3000.00000000 * 1e18 usd
        // 1e36 wei / 3000,00000000,0000000000
        // 1e36 / 3000e18

        uint256 priceToWeiPriceMultiplier = 10 **
            (ETHER_TO_WEI_NUMBER_OF_DECIMALS - priceNumberOfDecimals);
        uint256 weiPrice = uint256(price) * priceToWeiPriceMultiplier;
        return weiPrice;
    }

    function getWeiPerUsd(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 etherPriceInUsd = getEtherPriceInUsd(priceFeed);
        uint256 weiPerUsd = (WEI_PER_ETHER * WEI_PER_ETHER) / etherPriceInUsd;
        return weiPerUsd;
    }

    function convertWeiToUsd(
        uint256 amountInWei,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 weiPerUsd = getWeiPerUsd(priceFeed);
        uint256 usd = amountInWei / weiPerUsd;
        return usd;
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