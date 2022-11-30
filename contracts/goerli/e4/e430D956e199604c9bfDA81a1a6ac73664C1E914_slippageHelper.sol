// SPDX-License-Identifier: MIT
pragma solidity = 0.8.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "s003");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "s004");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "s005");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s006");
        uint256 c = a / b;
        return c;
    }
}

contract slippageHelper {
    using SafeMath for uint256;

    function getSlippageMin(uint256 _amount,uint256 _slippage) external pure returns (uint256) {
        uint256 left = uint256(10**18).sub(_slippage);
        return _amount.mul(left).div(10**18);
    }


    function getSlippageMax(uint256 _amount,uint256 _slippage) external pure returns (uint256) {
        uint256 all = uint256(10**18).add(_slippage);
        return _amount.mul(all).div(10**18);
    }

    function massGetSlippageMin(uint256[] memory _amountList,uint256 _slippage) external pure returns (uint256[] memory AmountList) {
        AmountList = new uint256[](_amountList.length);
        uint256 left = uint256(10**18).sub(_slippage);
        for (uint256 i=0;i<_amountList.length;i++) {
           AmountList[i] =  _amountList[i].mul(left).div(10**18);
        }
    }

    function massGetSlippageMax(uint256[] memory _amountList,uint256 _slippage) external pure returns (uint256[] memory AmountList) {
        AmountList = new uint256[](_amountList.length);
        uint256 all = uint256(10**18).add(_slippage);
        for (uint256 i=0;i<_amountList.length;i++) {
           AmountList[i] =  _amountList[i].mul(all).div(10**18);
        }
    }
}