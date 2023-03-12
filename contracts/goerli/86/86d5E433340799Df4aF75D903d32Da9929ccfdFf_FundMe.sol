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

import './PriceConverter.sol';

contract FundMe {
    using PriceConverter for uint256;
    uint public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountToBeFunded;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, 'Only can withdraw funds');
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConvertionRate(priceFeed) >= MINIMUM_USD,
            'Please send sufficient funds'
        );
        funders.push(msg.sender);
        addressToAmountToBeFunded[msg.sender] =
            addressToAmountToBeFunded[msg.sender] +
            msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = funders[funderIndex];
            addressToAmountToBeFunded[funder] = 0;
        }

        funders = new address[](0);

        (bool tranferSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }('');
        require(tranferSuccess, 'withdraw fails');
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
    function getConvertionRate(
        uint value,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 usdPricePerEth = getPrice(priceFeed);
        // as both usdPricePerEth and value (Wei) in multiple of 1e18
        // After multiplecation we need to divide it by 1e18 to keep correct unit
        return (value * usdPricePerEth) / 1e18;
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price value is already multiple of 1e8
        // eg: 3000.1 is 300010000000
        return uint256(price * 1e10);
    }
}