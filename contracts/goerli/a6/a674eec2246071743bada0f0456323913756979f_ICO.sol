/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.17;

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

// File: contracts/priceUSD.sol


pragma solidity ^0.8.7;


contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
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
}
// File: contracts/presale.sol


pragma solidity ^0.8.17;

interface assetERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function decimal() external returns(uint256);
    function transferFrom(address from, address to, uint tokens) external  returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ICO is PriceConsumerV3{
    assetERC20 token;
    uint public tokenForDollar = 2;
    address  tknowner;
    
    event tokensam(uint ammount);

    constructor(assetERC20 tokenaddress, address  tokenowner) {
        token = tokenaddress;
        tknowner = tokenowner;
    }

    function buyToken() public payable {
        require(msg.value > 0, "pay price");
        // uint amount = (msg.value/10**token.decimal()) * tokenForDollar;
        uint amount = (msg.value * uint256(getLatestPrice()))/1 ether;
        amount = (amount*tokenForDollar)/1e8;
        emit tokensam(amount);
        token.transferFrom(tknowner, msg.sender, amount);
      
    }

    // function sellToken(uint tokenTosell) public  {

        
    //     // uint amount = tokenTosell/tokenForDollar * 10**token.decimal();
    //     // payable (msg.sender).transfer(amount);
    // }
    // 
    function sellToken(uint tokentoSell) public payable {
        require(token.balanceOf (msg.sender) > 0, "you don't have any tokens");
        // uint amount = tokenForDollar * 10**token.decimal() * msg.value / 1e18;
        token.transferFrom(msg.sender, tknowner, tokentoSell);
        // uint ammount = ((10**18)/100) *tokentoSell;
        uint ammount = (tokentoSell*1e18)/10**token.decimal();
        ammount = ammount /tokenForDollar;
        payable (msg.sender).transfer(ammount);
        // payable(msg.sender).transfer(amount);
    }
}