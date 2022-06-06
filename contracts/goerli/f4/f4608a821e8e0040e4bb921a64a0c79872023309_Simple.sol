// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract Simple {
    uint256 a = 1234;
    bytes32 b = 'a';
    string c = "asdf";

    function run() public view returns (uint, bytes32, string memory){
        return (a, b, c);
    }
}