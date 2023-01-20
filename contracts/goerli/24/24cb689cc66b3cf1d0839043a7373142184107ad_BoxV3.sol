// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BoxV3 {
    uint256 private val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }

    function dsc() external {
        val -= 1;
    }

    function incBy(uint32 n) external {
        val += n;
    }

    function dscBy(uint32 n) external {
        val -= n;
    }

    function sumArray(int128[] memory n)
        public
        pure
        returns (int256, int128[] memory)
    {
        int256 sum = 0;
        for (uint128 i = 0; i < n.length; i++) {}
        return (sum, n);
    }

    function getVal() public view returns (uint256) {
        return val;
    }
}