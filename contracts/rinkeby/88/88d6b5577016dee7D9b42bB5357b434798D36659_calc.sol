/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract calc {
    uint256 operationCounter;

    constructor() {
        operationCounter = 0;
    }

    function Add(int256 x, int256 y) public returns (int256) {
        require(validate_sum(x,y));
        
        operationCounter++;
        return x+y;
    }

    function Mul(int256 x, int256 y) public returns (int256) {
        require(validate_mul(x,y));
        
        operationCounter++;
        return x*y;
    }

    function Sub(int256 x, int256 y) public returns (int256) {
        require(validate_sum(x, -y));
        
        operationCounter++;
        return x - y;
    }

    function Div(int256 x, int256 y) public returns (int256, uint256) {

        require(validate_div(x, y));

        operationCounter++;
        int256 quotient  = x / y;

        (uint256 posX, uint256 posY, uint256 posQuotient) = toPositiveTrio(x,y,quotient);
        uint256 remainder = posX - (posY * posQuotient);

        return (quotient, remainder);
    }

    function getOperationCounter() view public returns (uint256) {
        return operationCounter;
    }

    function validate_sum(int256 x, int256 y) pure private returns (bool) {
        int256 sum = x + y;
        if(x > 0 && y > 0 && sum < 0) {
            return false;
        } else if (x < 0 && y < 0 && sum > 0) {
            return false;
        }

        return true;
    }

    function validate_mul(int256 x, int256 y) pure private returns (bool) {
        if((x == 0) || (y == 0))  {
            return true;
        }

        int256 mul = x * y;
        return (x == (mul / y));
    }

    function validate_div(int256, int256 y) pure private returns (bool) {
        return (y != 0);
    }

    function toPositiveTrio(int256 x, int256 y, int256 q) pure private returns (uint256, uint256, uint256) {
        uint256 posX;
        uint256 posY;
        uint256 posQ;

        if(x > 0) {
            posX = uint256(x);
        } else {
            posX = uint256(-x);
        }

        
        if(y > 0) {
            posY = uint256(y);
        } else {
            posY = uint256(-y);
        }

        if(q > 0) {
            posQ = uint256(q);
        } else {
            posQ = uint256(-q);
        }

        return (posX,posY, posQ);
    }
}