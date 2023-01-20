/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: docs.chain.link/samples/TokenShop.sol

//Begin

pragma solidity 0.8.13;


interface TokenInterface {
        function mint(address account, uint256 amount) external returns (bool);
}

contract TokenShop {
    
    AggregatorV3Interface internal priceFeed;
    TokenInterface public minter;
    uint256 public tokenPrice = 2000; //1 token = 20.00 usd, with 2 decimal places
    address public owner;
    
    constructor(address tokenMinter) {
        minter = TokenInterface(tokenMinter);
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

    receive() external payable {
        uint256 amountToken = tokenAmount(msg.value);
        minter.mint(msg.sender, amountToken);
    }

    modifier onlyOwner() {
            require(msg.sender == owner);
            _;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }


    function withdrawMoney() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function withdrawMoneyOwner() external onlyOwner {
        address payable to = payable(owner);
        to.transfer(getBalance());
    }
}
//End