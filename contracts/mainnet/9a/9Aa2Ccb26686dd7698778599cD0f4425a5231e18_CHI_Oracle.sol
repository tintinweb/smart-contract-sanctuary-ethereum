// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";

interface IPot {
  function chi() external view returns (uint256);

  function rho() external view returns (uint256);

  function dsr() external view returns (uint256);
}

contract CHI_Oracle is IOracleRelay {
  IPot public immutable pot;
  uint256 private constant ONE = 10**27;

  constructor(IPot _pot) {
    pot = _pot;
  }

  function currentValue() external view override returns (uint256 wad) {
    wad = readDrip() / 1e9;
  }


  /// @notice logic and math pulled directly from the pot contract
  /// https://github.com/makerdao/dss/commit/17187f7d47be2f4c71d218785e1155474bbafe8a
  /// https://etherscan.io/address/0x197e90f9fad81970ba7976f33cbd77088e5d7cf7#code
  function readDrip() internal view returns (uint256 tmp) {
    tmp = rmul(rpow(pot.dsr(), (block.timestamp - pot.rho()), ONE), pot.chi());
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = mul(x, y) / ONE;
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  function rpow(
    uint256 x,
    uint256 n,
    uint256 base
  ) internal pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          z := base
        }
        default {
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          z := base
        }
        default {
          z := x
        }
        let half := div(base, 2) // for rounding.
        for {
          n := div(n, 2)
        } n {
          n := div(n, 2)
        } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) {
            revert(0, 0)
          }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) {
            revert(0, 0)
          }
          x := div(xxRound, base)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
              revert(0, 0)
            }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) {
              revert(0, 0)
            }
            z := div(zxRound, base)
          }
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  // returns  price with 18 decimals
  function currentValue() external view returns (uint256);
}