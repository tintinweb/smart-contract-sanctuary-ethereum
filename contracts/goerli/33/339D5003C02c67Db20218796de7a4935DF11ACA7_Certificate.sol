/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

contract Certificate {
    /*
        {
            "0xffff": {
                "aslkdkoo20oldkk": true,
            },

        }
    */
    mapping(address => mapping(string => bool)) public certificates;

    function issue(address userAddress, string memory hash) public {
        certificates[userAddress][hash] = true;
    }
}