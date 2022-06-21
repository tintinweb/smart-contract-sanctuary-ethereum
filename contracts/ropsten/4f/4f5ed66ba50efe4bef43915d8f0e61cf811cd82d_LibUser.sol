pragma solidity ^0.8.7;

import "./Lib1.sol";
import "./Lib2.sol";

contract LibUser {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return Math1.add(a, b);
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return Math2.sub(a, b);
    }
}