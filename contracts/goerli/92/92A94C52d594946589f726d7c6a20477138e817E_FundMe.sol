// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error fundMe_notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_funderAddressToFund;
    address private immutable i_owner;

    AggregatorV3Interface private immutable priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier is_owner() {
        if (i_owner != msg.sender) {
            revert fundMe_notOwner();
        }
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't sent enough!"
        );
        s_funders.push(msg.sender);
        s_funderAddressToFund[msg.sender] = msg.value;
    }

    function withdraw() public payable is_owner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_funderAddressToFund[funders[i]] = 0;
        }

        s_funders = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(isSuccess, "Withdrawal failed unexpectedly, Try again!");
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    function getFunder(uint256 indexNo) public view returns (address) {
        return s_funders[indexNo];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFundFromFunderAddress(address _funderAddress)
        public
        view
        returns (uint256)
    {
        return s_funderAddressToFund[_funderAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 latestPriceEth, , , ) = priceFeed.latestRoundData();

        return uint256(latestPriceEth * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 latestEthPrice = getPrice(priceFeed);

        uint256 convertedPrice = (latestEthPrice * ethAmount) / 1e17;

        return convertedPrice;
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