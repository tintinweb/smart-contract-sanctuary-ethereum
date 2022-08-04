//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./PriceConvertor.sol"; 

error NotOwner();

contract FundMe {

    using PriceConvertor for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping (address => uint256) public addressToAmountFunded;
    address public immutable i_owner;
    // we pass the address price feed depending on the chain we are on

		AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
				priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >=  MINIMUM_USD,"Didn't send enough");   //1e18 = 1*10**18 == 1ETH (in wei)
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder =  funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // reseting the array
       (bool callSuccess,) =  payable(msg.sender).call{value: address(this).balance}("");
       require(callSuccess, "Call failed");
    }
     
    modifier onlyOwner{
        // require(msg.sender == i_owner, "Only owner can withdraw");
        if(msg.sender != i_owner) {
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

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {

function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256) { 
        uint256 ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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