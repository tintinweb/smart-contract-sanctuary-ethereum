/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract test0 {

    function getLegionDecoded(uint256 tokenId) external view returns (string memory) {}

}

contract test1 {
    function sayHello() public pure returns (string memory) {
    }
    function sayLegion(uint256 tokenId) public view returns (string memory) {

    }
    function sayHelloLegion(uint256 tokenId) public view returns (string memory) {

    }
    function formattedLegionOutput(string memory legion) private pure returns (string memory) {
        return concatenate('Hello,', string(abi.encodePacked(legion, '!')));
    }
    function concatenate(string memory a, string memory b) private pure returns (string memory) {
        return string(abi.encodePacked(a,' ',b));
    } 
}