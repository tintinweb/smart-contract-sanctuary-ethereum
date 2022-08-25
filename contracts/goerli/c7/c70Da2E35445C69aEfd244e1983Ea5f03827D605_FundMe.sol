// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e10;

    mapping(address => uint256) private funderToAmount;
    address[] private funders;

    AggregatorV3Interface private priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConverisonRate(priceFeed) >= MINIMUM_USD,
            "Send ETH amount at least equal to 50 USD"
        );
        if (funderToAmount[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        funderToAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory _funders = funders;
        for (uint256 i = 0; i < _funders.length; i++) {
            funderToAmount[_funders[i]] = 0;
        }
        funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 _index) public view returns (address) {
        return funders[_index];
    }

    function getFunderToAmount(address _funder) public view returns (uint256) {
        return funderToAmount[_funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConverisonRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUSD;
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