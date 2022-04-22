/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Test1  {

    bytes32 b32;
    string public str;

    mapping(uint256 => string) public acc_str;

    function input_1(bytes32 b) external
    {
            b32 = b;
    }

    function input_2(string memory str_in) external
    {
            str = str_in;
    }

    function input_3(uint256 tokenid, string memory str_in) external
    {
        acc_str[tokenid] = str_in;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getbyes32() public view returns (bytes32 b32) 
    {
        return b32;
    }

    function view_string() public view returns (string memory) 
    {
        return bytes32ToString(b32);
    }

}