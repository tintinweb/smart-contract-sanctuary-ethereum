/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataLocation {
    
    uint[] public arr;

    function assigned() public pure returns(uint x, bool y, string memory z) {
        x = 100;
        y = true;
        z = 'Nikhil';
    }

    function desctructuring() public pure returns(uint, bool, string memory) {
        (uint x, , string memory z) = assigned();
        return (x, false, z);
    }

    function arrayOutput() public view returns(uint[] memory) {
        return arr;
    }
    
 }