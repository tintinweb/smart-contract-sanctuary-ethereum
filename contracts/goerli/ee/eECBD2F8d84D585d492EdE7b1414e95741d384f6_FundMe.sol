// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__notOwner();

/** @title A contract for crowd funding
 * @author Alvaro Teran
 * @notice This contract is a demo of a simple funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    using PriceConverter for uint256;

    address private immutable i_owner;
    uint256 public constant MINIMAL_USDC = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert FundMe__notOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This fuction funds this contract
     * @dev This implements price feeds as our library and do a minimal apportation of 50 USDC
     */

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMAL_USDC,
            "Didn't send enough!"
        );
        
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
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
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Tx failed!");
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunders(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getAddressToAmmountFunded(address funder) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/** @title A contract for price converter
 * @author Alvaro Teran
 * @notice This contract is a demo of a simple funding contract
 * @dev This implements price feeds as our library
 */

library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUSDC = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUSDC;
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