/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    uint private a = 50;
    address owner = 0x9286C6b42cf190a421E545F5960Bde71839e9BAc;

modifier onlyowner {
    require(msg.sender == owner, "bot owner");
    _;
}
    function get() public view onlyowner returns(uint) {
        return a;
    }
}