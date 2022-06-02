/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Marriage {

    struct _marriage {
        string prenom1;
        string prenom2;
    }

    uint256 count = 0;
    mapping(uint256 => _marriage) public marriages;

    function createMarriage(string memory prenom1, string memory prenom2) public payable {
        count++;
        marriages[count] = _marriage(prenom1, prenom2);
    }
}