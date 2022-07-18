//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title A contract for crowd funding
 *   @author Dwaipayan Guha
 *   @notice Demo contract
 *   @dev Implements price feeds
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert FundMe__NotOwner();
        }
        //require(i_owner == msg.sender, "Not the owner!");
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        //require is a requirement
        //msg.value accesses the value component of the tx
        //value's unit is wei. 1e18 wei = 1 eth
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Not enough ether"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the s_funders array
        s_funders = new address[](0);

        //withdraw
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    function cheapWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //this function returns a tuple out of which we only need price, hence all commas
        return uint256(price * 1e10);
    }

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