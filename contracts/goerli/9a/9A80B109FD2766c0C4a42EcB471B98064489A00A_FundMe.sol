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

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();
error DidntSendEnough();
error CallFailed();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 1 * 1e18;

    address public immutable i_ownerAddress;
    address[] public funderAddresses;
    mapping(address => uint256) public fundersFunds;

    AggregatorV3Interface public priceFeedAddress;

    constructor(address _priceFeedAddress) {
        i_ownerAddress = msg.sender;
        priceFeedAddress = AggregatorV3Interface(_priceFeedAddress);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(priceFeedAddress) < MINIMUM_USD) {
            revert DidntSendEnough();
        }

        funderAddresses.push(msg.sender);
        fundersFunds[msg.sender] = fundersFunds[msg.sender] + msg.value;
    }

    function withdrawAllFunds() public onlyOwner {
        for (
            uint256 funderAddressIndex = 0;
            funderAddressIndex < funderAddresses.length;
            funderAddressIndex++
        ) {
            address funderAddress = funderAddresses[funderAddressIndex];
            fundersFunds[funderAddress] = 0;
        }

        funderAddresses = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!(callSuccess)) {
            revert CallFailed();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_ownerAddress) {
            revert NotOwner();
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

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library - similar to contracts, but cannot declare state variables
// or send ether
// add more functionality to different types (primitives)
// all functions are internal
library PriceConverter {
    // the value this is called on is passed as the first input param
    // additional params can be defined too
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeedAddress
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeedAddress.latestRoundData();
        uint256 ethPrice = uint256(price * 1e10);
        uint256 usdAmount = (ethPrice * _ethAmount) / 1e18;
        return usdAmount;
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }
}