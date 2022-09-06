// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Gourmet {
    mapping(uint256 => uint256) shopResult;
    event rateLog(uint256 shopId, uint256 result);

    function Rating(
        uint256 _shopId,
        uint256 _uStar,
        uint256 _userPoint
    ) external {
        uint256 result;
        uint256 param = 10000 / _userPoint;
        if (shopResult[_shopId] == 0) {
            result = _uStar * 10;
        } else {
            if (param == 100) {
                result = (shopResult[_shopId] + _uStar * 10) / 2;
            } else {
                result =
                    (shopResult[_shopId] * param + _uStar * 1000) /
                    (param + 100);
            }
        }
        shopResult[_shopId] = result;
        emit rateLog(_shopId, shopResult[_shopId]);
    }

    fallback() external payable {}

    receive() external payable {}
}