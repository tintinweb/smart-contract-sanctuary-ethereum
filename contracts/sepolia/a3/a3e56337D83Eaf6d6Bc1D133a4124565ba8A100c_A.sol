/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

pragma solidity 0.8.19;

contract A {
    function a() external view returns (uint256) {
        uint256 b = 1 > 2 ? 1 ://5; /*
        3;
        // */
        return b;
    }
}