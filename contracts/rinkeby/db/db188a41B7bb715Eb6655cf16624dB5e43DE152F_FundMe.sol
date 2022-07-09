// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe_NotOwner();
contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;

    address public immutable owner;
	AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeed){
        owner = msg.sender;
		s_priceFeed = AggregatorV3Interface(priceFeed);

    }
    mapping(address => uint256) public addressToEthAmount;

    function fundme() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Not Enough");
        funders.push(msg.sender);
        addressToEthAmount[msg.sender] = msg.value;

    }


    function withdraw() public onlyOwner {
        for(uint256 index; index < funders.length; index++){
            address funder = funders[index];
            addressToEthAmount[funder] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Failed to withdraw");
    }

    modifier onlyOwner(){
        if(msg.sender != owner) revert FundMe_NotOwner();
        _;
    }

	receive() external payable {
		fundme();
	}

	fallback() external payable {
		fundme();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
	function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
			(,int256 price,,,) = priceFeed.latestRoundData();
			// ethereum interms of usd
			return uint256(price * 1e10);
		}
		
	function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
			uint256 ethPrice = getPrice(priceFeed);
			uint256 ethUSD = (ethPrice * ethAmount) / 1e18;
			return ethUSD;
		}

}