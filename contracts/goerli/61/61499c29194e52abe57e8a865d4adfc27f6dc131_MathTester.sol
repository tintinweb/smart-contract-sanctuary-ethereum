// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
import "./FixedPoint.sol";
import "./LogExpMath.sol";
contract MathTester {

    function mulDown(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.mulDown(a, b);
    }

    function mulUp(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.mulUp(a,b);
    }

    function divDown(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.divDown(a, b);
    }

    function divUp(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.divUp(a,b);
    }

    function powDown(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.powDown(a, b);
    }

    function powUp(uint256 a, uint256 b) public view returns(uint256 output){
        return FixedPoint.powUp(a,b);
    }

    function complement(uint256 a) public view returns(uint256 output){
        return FixedPoint.complement(a);
    }

    function bpow(uint256 x, uint256 y) public view returns(uint256 p){
        return LogExpMath.pow(x,y);
    }

    function bexp(int256 x) public view returns(int256 p){
        return LogExpMath.exp(x);
    }

    function bln(int256 x) public view returns(int256 p){
        return LogExpMath.ln(x);
    }

    function bln_36(int256 x) public view returns(int256 p){
        return LogExpMath.ln_36(x);
    }
}