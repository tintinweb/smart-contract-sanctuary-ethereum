// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Box5 {
    string public version;

    function v1() public  returns(string memory){
        version ="v1";
        return version;
    }
    function v2() public {
        version ="v2";
    }
}