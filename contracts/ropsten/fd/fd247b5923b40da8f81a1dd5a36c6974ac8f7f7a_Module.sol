/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

struct Pair {
    string key;
    string value;
}

interface IWebPageRenderer {
    function tokenHTML(uint256 tokenId) external view returns (string memory);
}

contract Module is IWebPageRenderer {
    constructor() {}

    function tokenHTML(uint256 tokenId) external view returns (string memory) {
        return
            '<div> <script>console.log("hello webpage"); </script> <div> <h1> tries.eth </h1> </div></div>';
    }
}