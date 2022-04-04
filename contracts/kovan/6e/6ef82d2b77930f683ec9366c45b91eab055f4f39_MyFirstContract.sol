/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract MyFirstContract {
    string private myString = 'Access denied';
    uint private id;

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setAccess(string memory access) public { 
        myString = access;
    }
    function getAccess() public view returns (string memory){
        return myString;
    }

    function generateIdIfGranted() public returns (string memory){
        if(keccak256(bytes(myString)) == keccak256(bytes('Access granted'))){
            id = uint(keccak256(abi.encode(block.difficulty)));
            return toString(id);
        }else{
            return 'Access denied';
        }
    }
}