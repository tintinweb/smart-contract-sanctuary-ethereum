/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    function twentyPercentOfWithShift(uint32 value) public pure returns (uint256) {
        return (value << 1) / 10;
    }

    function twentyPercentOfWithMult(uint32 value) public pure returns (uint256) {
        return (value * 2) / 10;
    }
}