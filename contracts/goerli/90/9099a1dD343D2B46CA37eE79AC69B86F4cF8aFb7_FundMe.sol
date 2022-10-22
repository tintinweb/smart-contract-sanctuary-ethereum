// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__InsufficientAmount();

/** @title A contract for crowd funding
 *  @author Emiliano López
 */
contract FundMe {
    using PriceConverter for uint;

    uint constant MIN_USD = 50 * 1e18;
    address private immutable i_owner;
    address private immutable i_priceFeed;
    address[] private s_funders;
    mapping(address => uint) private s_addressToAmount;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        i_priceFeed = _priceFeed;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value.toUsd(i_priceFeed) < MIN_USD) {
            revert FundMe__InsufficientAmount();
        }
        s_funders.push(msg.sender);
        s_addressToAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory funders = s_funders;
        for (uint i = 0; i < funders.length; i++) {
            s_addressToAmount[funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (address) {
        return i_priceFeed;
    }

    function getFunder(uint index) public view returns (address) {
        return s_funders[index];
    }

    function getFunderAmount(address funder) public view returns (uint) {
        return s_addressToAmount[funder];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(address _priceFeed) internal view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function toUsd(uint ethAmount, address priceFeed)
        internal
        view
        returns (uint)
    {
        return (getPrice(priceFeed) * ethAmount) / 1e18;
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