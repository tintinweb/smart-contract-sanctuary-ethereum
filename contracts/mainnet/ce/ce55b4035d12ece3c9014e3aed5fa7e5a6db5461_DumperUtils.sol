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
interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Router {
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
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

contract DumperUtils {
  uint256 public constant MAX_SLIPPAGE = 100000;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  IUniswapV2Factory public constant UNI_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  IUniswapV2Router public constant UNI_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IUniswapV2Factory public constant SUSHI_FACTORY = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
  IUniswapV2Router public constant SUSHI_ROUTER = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

  // @notice send ERC20 to this contract before calling dump to sell them on uniswap v2 for ETH
  // @param _tokens array of tokens to sell
  // @param _dumper address of the dumper contract
  // @param _slippage the slippage to use for each token (in %, from 0 to 100000)
  function getDumpParams(
    address[] calldata _tokens, 
    address _dumper,
    uint256 _slippage
  ) external view returns (Trade[] memory _trades) {
    _trades = new Trade[](_tokens.length);
    address[] memory _path = new address[](2);
    uint256[] memory _uniRes = new uint256[](2);
    uint256[] memory _sushiRes = new uint256[](2);
    _path[1] = WETH;

    uint256 _bal;
    uint256 _bestRes;
    address _token;
    bool _isUniBest;

    for (uint256 i = 0; i < _tokens.length; i++) {
      _token = _tokens[i];
      _path[0] = address(_token);
      _bal = ERC20(_token).balanceOf(_dumper);
      _uniRes = UNI_ROUTER.getAmountsOut(_bal, _path);
      _sushiRes = SUSHI_ROUTER.getAmountsOut(_bal, _path);
      _isUniBest = _uniRes[1] > _sushiRes[1];
      _bestRes = _isUniBest ? _uniRes[1] : _sushiRes[1];
      _bestRes -= _bestRes * _slippage / MAX_SLIPPAGE;
      _trades[i] = Trade(
        _token,
        uint96(_bal),
        (_isUniBest ? UNI_FACTORY : SUSHI_FACTORY).getPair(_token, WETH),
        uint96(_bestRes)
      );
    }
  }
}