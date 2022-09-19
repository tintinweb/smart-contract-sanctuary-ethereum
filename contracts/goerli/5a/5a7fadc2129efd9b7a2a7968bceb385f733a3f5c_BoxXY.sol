/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BoxXY {
    struct Xy {
        uint x;
        uint y;
    }
    Xy private value;

    function getValue() public view returns (uint, uint) {
        return (value.x, value.y);
    }

    function setValue(Xy calldata newXy) external {
        value = newXy;
    }
}