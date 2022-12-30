/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SvgData {
    string public svg;

    function encode(string memory _svg) public pure returns (bytes memory) {
        return abi.encodePacked(_svg);
    }

}