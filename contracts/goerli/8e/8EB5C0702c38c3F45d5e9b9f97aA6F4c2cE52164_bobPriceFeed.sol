/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// File: contracts/UniswapV2Library.sol

pragma solidity >=0.5.0;

interface IUniswapV2Library {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) external pure returns (address pair);
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn) ;
    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}
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

// File: contracts/bobPriceFeed.sol

pragma solidity >=0.8.20;



contract bobPriceFeed {

    // address private targetToken = '0x6982508145454Ce325dDbE47a25d4ec3d2311933'; // mainnet
    // address private mainToken = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; // mainnet
    address private mainToken = 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D; // testnet 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D
    address private targetToken = 0x979c80C31A57C885e5160009ed8FB1e78f496C7D; // testnet

    address private factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // mainnet
    address private wethChainLinkPriceFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; // mainnet
    address private uniswapLibrary = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    AggregatorV3Interface internal dataFeed;

    constructor() {
        dataFeed = AggregatorV3Interface(
            wethChainLinkPriceFeed
        );
    }

    function latestAnswer()
        external
        view
        returns (int256 answer)
        {
            uint256 resA;
            uint256 resB;
            (resA, resB) = IUniswapV2Library(uniswapLibrary).getReserves(factoryAddress, mainToken, targetToken);

            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = dataFeed.latestRoundData();
            answer = int256(price) * int256((resB / resA));
        }
    
}