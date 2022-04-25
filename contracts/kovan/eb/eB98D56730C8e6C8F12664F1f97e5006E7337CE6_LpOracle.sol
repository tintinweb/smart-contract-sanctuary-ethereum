pragma solidity 0.8;

interface IERC20 {
    function decimals() external view returns (uint256);
}

interface IUniV2 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint128, uint128, uint32);
    function totalSupply() external view returns (uint256);
}

interface AggregatorV3InterfaceMinimal {

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

contract LpOracle is AggregatorV3InterfaceMinimal {

    IUniV2 public immutable pair;

    AggregatorV3InterfaceMinimal public immutable token0Oracle;
    AggregatorV3InterfaceMinimal public immutable token1Oracle;

    uint256 public immutable token0Decimals;
    uint256 public immutable token1Decimals;

    address public immutable weth;

    bool public immutable isWeth0;
    bool public immutable isWeth1;

// mainnet "0x397FF1542f962076d0BFE58eA045FfA2d347ACa0", "0x986b5E1e1755e3C2440e960477f25201B0a8bbD4", "0x0000000000000000000000000000000000000000", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
// kovan "0xe7282e08d2E7e56aA0e075b47a75C1f058428aEC", "0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838", "0x0000000000000000000000000000000000000000", "0x31EeB2d0F9B6fD8642914aB10F4dD473677D80df", "0xd0A1E359811322d97991E03f863a0C30C2cF029C", "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
    constructor(
        IUniV2 _pair,
        AggregatorV3InterfaceMinimal _token0OracleFeed,
        AggregatorV3InterfaceMinimal _token1OracleFeed,
        address token0,
        address token1,
        address _weth
    ) {
        pair = _pair;
        token0Oracle = _token0OracleFeed;
        token1Oracle = _token1OracleFeed;
        token0Decimals = IERC20(token0).decimals();
        token1Decimals = IERC20(token1).decimals();
        weth = _weth;
        isWeth0 = _weth == token0;
        isWeth1 = _weth == token1;
    }

    function latestRoundData() override public view returns (
        uint80,
        int256 answer,
        uint256,
        uint256,
        uint80
    ) {

        int256 answer0;
        int256 answer1;

        (uint256 p0, uint256 p1) = _getPrices();
        (uint256 r0, uint256 r1, ) = pair.getReserves();
    
        uint256 sqrtR = sqrt(r0 * r1);
        uint256 sqrtP = sqrt(p0 * p1);

        answer = int256((2 * sqrtR * sqrtP) / pair.totalSupply());

    }

    function _getPrices() internal view returns (uint256 p0, uint256 p1) {
        if (isWeth0) {
            p0 = 1e18;
        } else {
            (, int256 answer0,,,) = token0Oracle.latestRoundData();
            p0 = uint256(answer0) * (10 ** (18 - token0Decimals));
        }
        if (isWeth1) {
            p1 = 1e18;
        } else {
            (, int256 answer1,,,) = token1Oracle.latestRoundData();
            p1 = uint256(answer1) * (10 ** (18 - token1Decimals));
        }
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

}