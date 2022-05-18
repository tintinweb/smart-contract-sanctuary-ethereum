// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

contract testing_sha{
    function test(bytes32 test_string) public view returns(bytes32){
        return sha256(abi.encodePacked(test_string));
    }
}