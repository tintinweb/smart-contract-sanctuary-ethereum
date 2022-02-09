/**
 *Submitted for verification at Etherscan.io on 2021-03-28
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

interface IChainLinkFeed {
  function latestAnswer() external view returns (int256);
}

interface IKeep3rV1 {
  function totalBonded() external view returns (uint256);

  function bonds(address keeper, address credit) external view returns (uint256);

  function votes(address keeper) external view returns (uint256);
}

interface IKeep3rV2Oracle {
  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 points
  ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo);
}

contract TestKeep3rHelperV1 {
  uint256 public nextFastGas = 86000000000;
  uint256 public nextQuote = 300;
  IKeep3rV1 public kp3r;
  address public weth;

  uint256 public constant MIN = 11;
  uint256 public constant MAX = 12;
  uint256 public constant BASE = 10;
  uint256 public constant SWAP = 300000;
  uint256 public constant TARGETBOND = 200e18;
  uint256 public constant NEXT_QUOTE_BASE = 1_000;

  function setNextFastGas(uint256 _nextFastGas) public {
    nextFastGas = _nextFastGas;
  }

  function setNextQuote(uint256 _nextQuote) public {
    nextQuote = _nextQuote;
  }

  function setKP3R(address _kp3r) public {
    kp3r = IKeep3rV1(_kp3r);
  }

  function quote(uint256 eth) public view returns (uint256 amountOut) {
    amountOut = (eth * nextQuote) / NEXT_QUOTE_BASE;
  }

  function getFastGas() external view returns (uint256) {
    return nextFastGas;
  }

  function bonds(address keeper) public view returns (uint256) {
    return kp3r.bonds(keeper, address(kp3r)) + (kp3r.votes(keeper));
  }

  function getQuoteLimitFor(address origin, uint256 gasUsed) public view returns (uint256) {
    uint256 _quote = quote((gasUsed + SWAP) * nextFastGas);
    uint256 _min = (_quote * MIN) / BASE;
    uint256 _boost = (_quote * MAX) / BASE;
    uint256 _bond = Math.min(bonds(origin), TARGETBOND);
    return Math.max(_min, (_boost * _bond) / TARGETBOND);
  }

  function getQuoteLimit(uint256 gasUsed) external view returns (uint256) {
    return getQuoteLimitFor(tx.origin, gasUsed);
  }
}