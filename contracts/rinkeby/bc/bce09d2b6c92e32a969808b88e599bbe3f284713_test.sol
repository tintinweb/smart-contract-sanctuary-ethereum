/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract test {
    uint128[16] x;

    function getX() public view returns(uint128[16] memory xx) {
        return x;
    }

    function uploadX(string[16] calldata input) public {
        uint128[16] memory temp_x;
        for(uint i=0; i<16; i++) {
            temp_x[i] = stringToUint(input[i]);
        }
        x = temp_x;
    }

    function stringToUint(string memory s) public pure returns (uint128 result) {
        bytes memory b = bytes(s);
        uint128 res = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            res = res * 10 + uint128(uint8(b[i]) - 48); // bytes and int are not compatible with the operator -.
        }
        result = res;
    }
}