//SPDX-License-Identifier:MIT
//solhint-disable-next-line
pragma solidity ^0.8.8;

import "./PriceConvertor.sol";

error FundMe__notOwner();

/** @title Crowd funding Contract
    @author Bilal Rasool
    @notice This contract is a demo for funding
    @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConvertor for uint256;
    uint256 private constant MIN_USD = 1 * 10**18;
    address public immutable i_owner;
    address[] public s_funders;
    mapping(address => uint256) public s_addressesFunding;

    AggregatorV3Interface public s_priceFeed;

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Fund More YOU BOZO!!!"
        );
        s_funders.push(msg.sender);
        s_addressesFunding[msg.sender] += msg.value;
    }

    function getVersion(address s_priceFeedAddress)
        public
        view
        returns (uint256)
    {
        return AggregatorV3Interface(s_priceFeedAddress).version();
    }

    modifier onlyOwnwer() {
        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _;
    }

    function withdraw() public payable onlyOwnwer {
        for (uint256 index = 0; index < s_funders.length; index++) {
            address funder = s_funders[index];
            s_addressesFunding[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callState, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callState, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwnwer {
        address[] memory funderstemp = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funderstemp.length;
            funderIndex++
        ) {
            address funder = funderstemp[funderIndex];
            s_addressesFunding[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }
     function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressesFunding[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier:MIT
//solhint-disable-next-line
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 priceUSD = ((ethPrice * ethAmount) / 1) * 1000000000000000000;
        return priceUSD;
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