// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./PriceConverter.sol";

contract FamilySavings {
    using PriceConverter for uint256;

    // TODO: daily withdrawal limit for each allowed address; event when money received or withdrawn

	address private immutable owner;

	mapping(address => uint256) private amountSent;

	mapping(address => bool) private allowedToWithdraw;

    AggregatorV3Interface public priceFeed;

	constructor(address priceFeedAddress) {
		owner = address(msg.sender);
		allowedToWithdraw[msg.sender] = true;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	receive() external payable {
		amountSent[msg.sender] += msg.value;
	}

	function myTotalAmountSent() public view returns (uint256) {
		return amountSent[msg.sender];
	}

	function setAllowedAddress(address _address, bool _canWithdraw) public {
		require(msg.sender == owner, "Not the owner");
		allowedToWithdraw[_address] = _canWithdraw;
	}

	function withdraw(uint256 _usdAmount) public {
		require(allowedToWithdraw[msg.sender] == true, "Address unallowed to withdraw");
        uint256 _amount = _usdAmount.fromUsdToWei(priceFeed);
		require(_amount <= address(this).balance, "Too low balance");
		payable(msg.sender).transfer(_amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x9326BFA02ADD2366b30bacB125260Af641031331 // kovan
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10 ** 10); // decimals as 18 digits
    }

    function fromUsdToWei(uint256 usdAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 weiPrice = ethPrice / 10 ** 18;
        uint256 usdAmountInWei = usdAmount / weiPrice;
        return usdAmountInWei;
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