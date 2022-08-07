/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed

interface Lib {
    function test() external pure returns (uint256);
}

contract Test {
    Lib public lib;

    constructor(address libAddress) {
        lib = Lib(libAddress);
    }
    

    function heh() public view returns (uint256) {
        return lib.test();
    }
}