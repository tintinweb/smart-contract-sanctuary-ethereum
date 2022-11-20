/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity 0.8.11;


contract MathOrder {
    function aMulBDivC(uint256 a, uint256 b, uint256 c) public pure returns (uint256) {
        return a * b / c;
    }

    function aDivCMulB(uint256 a, uint256 b, uint256 c) public pure returns (uint256) {
        return a / c * b;
    }
}