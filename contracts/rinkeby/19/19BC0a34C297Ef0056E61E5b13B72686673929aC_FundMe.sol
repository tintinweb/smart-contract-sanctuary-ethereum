//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";


/**@title A contract for fundraising
* @author Chukwuebuka Okafor
* @notice This contract is to demo a sample funding contract
* @dev This implements price feeds as our library

 */
contract FundMe {
    ///Type declarations
    using PriceConverter for uint256;
    uint256 public minimumUsd = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        //constructor runs once when the contract is deployed
        //therefore, when the code is deployed, constructor tells it what address to use for the priceFeed based on the value of priceFeedAddress
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //refactored getConversionRate() function
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough ETH!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // without modifier: require(msg.sender == owner, "Sender is not owner!");
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            //resetting the mapping
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    //using a modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner!");
        _;
    }
}

//0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //we removed the stuff we didn't care about and replaced them with commas!
        return uint256(answer * 1e10);
    }

    //converting msg.value from ETH to USD.
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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