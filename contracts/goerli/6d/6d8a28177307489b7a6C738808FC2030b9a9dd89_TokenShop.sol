//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "AggregatorV3Interface.sol";

interface TokenInterface {
        function mint(address account, uint256 amount) external returns (bool);
}

contract TokenShop {

    AggregatorV3Interface internal priceFeed;
    TokenInterface public minter;
    uint256 public tokenPrice = 2000; //1 token = 20.00 usd, with 2 decimal places
    address public owner;

    constructor(address tokenAddress) {
        minter = TokenInterface(tokenAddress);
        /**
        * Network: Goerli
        * Aggregator: ETH/USD
        * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        */
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        owner = msg.sender;
    }

    /**
    * Returns the latest price
    */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function tokenAmount(uint256 amountETH) public view returns (uint256) {
        //Sent amountETH, how many usd I have
        uint256 ethUsd = uint256(getLatestPrice());
        uint256 amountUSD = amountETH * ethUsd / 1000000000000000000; //ETH = 18 decimal places
        uint256 amountToken = amountUSD / tokenPrice / 10000;  //2 decimal places
        return amountToken;
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        uint256 amountToken = tokenAmount(msg.value);
        minter.mint(msg.sender, amountToken);
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