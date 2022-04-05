pragma solidity >=0.6.12;

import './PancakeLibrary.sol';
import './IERC20.sol';
import './IPancakePair.sol';


contract SandwichBot {

  //using SafeMath for uint256;

  address wbnb;
  address factory;

  constructor(address _wbnb,address _factory) public {
    wbnb = _wbnb;
    factory = _factory;
  }


  function buy(uint256 amount,uint256 multiple ,address buyToken) public{
    amount = amount * multiple;
    uint256 wbnbBalance = IERC20(wbnb).balanceOf(address(this))/2;
    amount = wbnbBalance < amount ? wbnbBalance : amount;
    address[] memory path = new address[](2);
    path[0] = wbnb;
    path[1] = buyToken;
    uint256[] memory amounts = PancakeLibrary.getAmountsOut(factory, amount, path);
    _swap(path, amounts);
    uint256 buyTokenBalance = IERC20(buyToken).balanceOf(address(this));
    require(buyTokenBalance >= amounts[1],'not get a good price');
  }

  function sell(address sellToken) public{
    uint256 sellTokenBalance = IERC20(sellToken).balanceOf(address(this));
    address[] memory path = new address[](2);
    path[0] = sellToken;
    path[1] = wbnb;
    uint256[] memory amounts = PancakeLibrary.getAmountsOut(factory, sellTokenBalance, path);
    _swap(path,amounts);
  }

  function _swap(address[] memory path,uint256[] memory amounts) internal {
    address pair = PancakeLibrary.pairFor(factory, path[0], path[1]);
    IERC20(path[0]).transfer(pair, amounts[0]);
    (address token0,) = PancakeLibrary.sortTokens(path[0], path[1]);
    (uint256 amount0Out, uint256 amount1Out) = token0 == path[0] ? (uint(0),amounts[1]) : (amounts[1],uint(0));

    IPancakePair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
  }


}