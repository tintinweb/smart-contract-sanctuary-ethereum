/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// File: contracts/UniswapV2Library.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

// File: contracts/wojakPriceFeed.sol

pragma solidity >=0.8.20;



contract wojakPriceFeed {

    // address private targetToken = '0x6982508145454Ce325dDbE47a25d4ec3d2311933'; // mainnet
    // address private mainToken = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; // mainnet
    address private mainToken = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // testnet 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D
    address private targetToken = 0x85502dD13fCc64d6Fff7430c62aDDA217dE44F7e; // testnet

    address private factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // mainnet
    address private wethChainLinkPriceFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; // mainnet
    address private uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

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
            uint256 tmp;
            address pair =  IUniswapV2Factory(uniswapFactory).getPair(mainToken, targetToken);
            (resA, resB, ) = IUniswapV2Pair(pair).getReserves();
            if (mainToken < targetToken) {
                tmp = resA;
                resA = resB;
                resB = tmp;
            }
            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = dataFeed.latestRoundData();
            int256 nresB = int256(resB);
            int256 nresA = int256(resA);
            answer = int256(price * nresB / nresA );
        }

    function feedback()
        external
        view
        returns (int256 )
        {

            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = dataFeed.latestRoundData();
            return price;
        }
    
}