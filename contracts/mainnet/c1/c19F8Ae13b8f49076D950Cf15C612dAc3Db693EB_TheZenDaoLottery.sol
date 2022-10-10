/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity ^0.8.0;

contract TheZenDaoLottery {
    uint256 public constant seed = uint256(keccak256("thezendao.io"));

    function random(
        uint256 min,
        uint256 max,
        uint256 index
    ) external view returns (uint256) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint256 diff = max - min + 1;
        uint256 randomVar = uint256(keccak256(abi.encodePacked(seed, index))) % diff;
        return randomVar + min;
    }
}