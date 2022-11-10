/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

pragma solidity ^0.8.14;

contract Calculator {
    function add(uint256 x, uint256 y) public pure returns (uint256) {
        return x / y;
    }

    function sub(uint256 x, uint256 y) public pure returns (uint256) {
        return x / y;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

}