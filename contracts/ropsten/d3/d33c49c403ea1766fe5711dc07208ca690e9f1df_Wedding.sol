/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Wedding {

    struct _wedding {
        string firstname1;
        string firstname2;
    }

    uint256 count = 0;
    mapping(uint256 => _wedding) public weddings;

    function createWedding(string memory firstname1, string memory firstname2) public returns(uint256 _count) {
        count++;
        weddings[count] = _wedding(firstname1, firstname2);
        return _count;
    }
}