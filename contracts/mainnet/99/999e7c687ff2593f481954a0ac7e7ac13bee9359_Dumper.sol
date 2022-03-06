/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;
interface ERC20 {
  function transfer(address _to, uint256 _value) external;
  function approve(address _spender, uint256 _value) external;
  function balanceOf(address _owner) external view returns (uint256);
}
interface IWETH {
  function withdraw(uint256 _value) external;
}
interface IUniswapV2Pair {
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface VM {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

struct Trade {
  address token;
  uint96 amount;
  address pair;
  uint96 wethAmount;
}
/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
      returns (uint256[] memory arr)
    {
      uint256 offset = _getImmutableArgsOffset();
      uint256 el;
      arr = new uint256[](arrLen);
      for (uint64 i = 0; i < arrLen; i++) {
        assembly {
          // solhint-disable-next-line no-inline-assembly
          el := calldataload(add(add(offset, argOffset), mul(i, 32)))
        }
        arr[i] = el;
      }
      return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

contract Dumper is Clone {
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  // @notice send ERC20 to this contract before calling dump to sell them on uniswap v2 for ETH
  // @param _trades array of Trade
  function dump(Trade[] calldata _trades) external payable {
    address owner = _getArgAddress(0);
    require(msg.sender == owner, '1');
    Trade memory _trade;
    ERC20 _tok;
    uint256 _totWeth;
    for (uint256 i = 0; i < _trades.length;) {
      _trade = _trades[i];
      _tok = ERC20(_trade.token);
      _tok.transfer(_trade.pair, _trade.amount);
      IUniswapV2Pair(_trade.pair).swap(
        0, _trade.wethAmount, address(this), new bytes(0)
      );
      unchecked { 
        _totWeth += _trade.wethAmount;
        i++; 
      }
    }
    IWETH(WETH).withdraw(_totWeth);
    selfdestruct(payable(owner));
  }

  function nah(ERC20[] calldata _tokens) external payable {
    // owner should be msg.sender
    require(msg.sender == _getArgAddress(0), '1');
    // transfer all balance in the contract of each token to msg.sender
    for (uint256 i = 0; i < _tokens.length;) {
      ERC20 _tok = _tokens[i];
      _tok.transfer(msg.sender, _tok.balanceOf(address(this)));
      unchecked {
        i++;
      }
    }
  }

  // @notice using fallback instead of `receive` to be compatible with clones-with-immutable-args
  // more info -> https://github.com/wighawag/clones-with-immutable-args/issues/6
  fallback() external payable {}
}