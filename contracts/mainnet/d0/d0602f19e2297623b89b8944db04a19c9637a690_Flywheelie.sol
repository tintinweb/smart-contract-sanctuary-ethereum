// SPDX-License-Identifier: MIT
// Tommy Genesis Flywheelie

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "Ownable.sol";
import "ICvxCrvDeposit.sol";
import "ICurveFactoryPool.sol";


contract Flywheelie is Ownable {
   using SafeERC20 for IERC20;
   address public constant CURVE_CVXCRV_CRV_POOL = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
   address public constant CVXCRV_DEPOSIT = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;
   address public constant CRV_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;
   address public constant CVXCRV_TOKEN = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
   int128 public constant CVXCRV_CRV_INDEX = 0;
   int128 public constant CVXCRV_CVXCRV_INDEX = 1;
   ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);

   constructor() {
      IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, type(uint256).max);
      IERC20(CVXCRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);
   }

   function _cvxCrvToCrv(uint256 amount, address recipient, uint256 minAmountOut) internal returns (uint256) {
      try crvCvxCrvSwap.exchange(
            CVXCRV_CVXCRV_INDEX,
            CVXCRV_CRV_INDEX,
            amount,
            minAmountOut,
            recipient) returns (uint256 _out) {
         return _out;
      } catch Error(string memory) {
         return 0;
      } catch (bytes memory) {
         return 0;
      }

   }

   function _toCvxCrv() internal returns (uint256) {
      uint256 _crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));
      ICvxCrvDeposit(CVXCRV_DEPOSIT).deposit(_crvBalance, false);
      return _crvBalance;
   }

   function wheelie(address tokenIn, uint256 amountIn, uint256 minOut) public {
      require(tokenIn == CVXCRV_TOKEN || tokenIn == CRV_TOKEN, "can only supply cvxCRV or CRV");
      require(amountIn > minOut, "Can't receive more than you put in");
      IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
      uint256 onhand;
      if(tokenIn == CVXCRV_TOKEN) {
         onhand = _cvxCrvToCrv(amountIn, address(this), minOut);
      } else {
         onhand = amountIn;
      }
      while(true) { // should always end on cvxcrv after breaking for failed swap
         if(onhand == 0) { break; }
         _toCvxCrv();
         onhand = _cvxCrvToCrv(onhand, address(this), minOut);
      }
      onhand = IERC20(CVXCRV_TOKEN).balanceOf(address(this));
      IERC20(CVXCRV_TOKEN).safeTransfer(msg.sender, onhand);
   }

   // safety function incase tokens or eth get stuck, potential airdrop claims, etc.
   function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bool, bytes memory) {
      (bool success, bytes memory result) = _to.call{value:_value}(_data);
      return (success, result);
   }

}