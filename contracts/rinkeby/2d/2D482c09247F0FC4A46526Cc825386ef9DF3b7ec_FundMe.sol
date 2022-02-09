// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    // priceFeed - address of inteface for current pair (like ETH/USD)
    // https://docs.chain.link/docs/ethereum-addresses/
    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);

        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumEth = getEntranceFee();

        require(msg.value >= minimumEth, "You need to spend more ETH!");

        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    // get version of AggregatorV3Interface
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // get current price eth to usd in wei (with 18 decimals)
    function latestRoundData() public view returns (uint256) {
        /* 
        (
                    uint80 roundID, 
                    int price,
                    uint startedAt,
                    uint timeStamp,
                    uint80 answeredInRound
                ) = priceFeed.latestRoundData();
        */
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    // get current price eth to usd in wei (with 18 decimals)
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // answer is 8-decimals number
        // since we using wei (18 decimals), we need to add 10

        return uint256(answer * 1e10);
    }

    // RETURN CURRENT AMOUNT IN WEI (MUST CONVERT FROM WEI TO GET USD!!!)
    function ethToUsd(uint256 _ethAmount) public view returns (uint256) {
        // has 18 decimals
        uint256 price = getPrice();

        return (price * _ethAmount) / 1 ether;
    }

    // convert usd to eth (get max eth by giving usd)
    function usdToEth(uint256 _usdAmount) public view returns (uint256) {
        // set to same decimals count
        uint256 usdAmount = _usdAmount * 1 ether;

        // already has 18 decimals
        uint256 price = getPrice();

        // we need to multiply our minimumUSD on 18 decimals to get number with 18 decimals
        // in other case while dividing 18 decimals by 18 decimals we will get 0 decimals number (solidity doesn't provide floating numbers with . (decimals))
        uint256 maxEthPerUsd = (usdAmount * 1 ether) / price;

        return maxEthPerUsd;
    }

    // get entrance fee - minimum amount of eth that person should pay

    function getEntranceFee() public view returns (uint256) {
        return usdToEth(50);
    }

    // modifier that checks that sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You aren't the owner of the contract!");

        _;
    }

    // to withdraw all funds to owner and clear array of funders and funder's mapping
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(address(msg.sender)).call{
            value: address(this).balance
        }("");

        require(success);

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];

            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
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