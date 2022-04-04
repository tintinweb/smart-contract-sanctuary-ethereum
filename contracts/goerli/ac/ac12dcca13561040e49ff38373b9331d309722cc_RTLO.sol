/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT


contract RTLO {

    event Add(uint256 x, uint256 y, uint256 result);
    event Sub(uint256 x, uint256 y, uint256 result);

    function _add(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    function add(uint256 x, uint256 y) public {
        uint256 result = _add(x, y);
        emit Add(x,y,result);
    }

    function sub(uint256 x, uint256 y) public {
        uint256 result = _sub(/*bigger Number*/x, y/*samller number*//*subtraction*/);
        emit Sub(x,y,result);
    }

    function subRTL(uint256 x, uint256 y) public {
        uint256 result = _sub(/*bigger Number‮/*rebmun rellams*/y , x/*‭/*subtraction*/);
        emit Sub(x,y,result);
    }
}