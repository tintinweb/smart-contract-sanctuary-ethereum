/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
contract Q {

    function Equal(string memory input) public pure returns(uint ){
        bytes32 IN = keccak256(abi.encode(input)); 
        bytes32 HE = keccak256(abi.encode("hello"));
        bytes32 HI = keccak256(abi.encode("hi"));
        bytes32 MO = keccak256(abi.encode("move"));
    if (IN == HE) {
        return 1;
    } else if (IN ==HI) {
        return 2;
    } else if (IN == MO) {
        return 3;
    } else {
        return 4;
    }
}
}