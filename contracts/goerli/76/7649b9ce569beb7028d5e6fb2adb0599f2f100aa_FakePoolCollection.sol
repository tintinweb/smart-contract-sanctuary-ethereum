/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity 0.8.13;

// From https://github.com/bancorprotocol/contracts-v3/blob/dev/contracts/utility/Fraction.sol

struct Fraction112 {
    uint112 n;
    uint112 d;
}

function zeroFraction112() pure returns (Fraction112 memory) {
    return Fraction112({ n: 0, d: 1 });
}

// From https://github.com/bancorprotocol/contracts-v3/blob/dev/contracts/pools/interfaces/IPoolCollection.sol

struct PoolLiquidity {
    uint128 bntTradingLiquidity; // the BNT trading liquidity
    uint128 baseTokenTradingLiquidity; // the base token trading liquidity
    uint256 stakedBalance; // the staked balance
}

struct AverageRate {
    uint32 blockNumber;
    Fraction112 rate;
}

struct Pool {
    address poolToken; // the pool token of the pool
    uint32 tradingFeePPM; // the trading fee (in units of PPM)
    bool tradingEnabled; // whether trading is enabled
    bool depositingEnabled; // whether depositing is enabled
    AverageRate averageRate; // the recent average rate
    uint256 depositLimit; // the deposit limit
    PoolLiquidity liquidity; // the overall liquidity in the pool
}

contract FakePoolCollection {
  mapping(address => Pool) internal _poolData;

  constructor() {}

  function poolType() public pure returns (uint) {
    return 1;
  }

  function poolData(address token) public view returns (Pool memory) {
    return _poolData[token];
  }

  function addPool(address token, uint32 tradingFee, uint128 bntLiquidity, uint128 baseTokenLiquidity) public {
    Pool memory data = Pool({
      poolToken: token,
      tradingFeePPM: tradingFee,
      tradingEnabled: true,
      depositingEnabled: true,
      averageRate: AverageRate({ blockNumber: 0, rate: zeroFraction112() }),
      depositLimit: 0,
      liquidity: PoolLiquidity({ bntTradingLiquidity: bntLiquidity, baseTokenTradingLiquidity: baseTokenLiquidity, stakedBalance: 0 })
    });
    _poolData[token] = data;
  }
}