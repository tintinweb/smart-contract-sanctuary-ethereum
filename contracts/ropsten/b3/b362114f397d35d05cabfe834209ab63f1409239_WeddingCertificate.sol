/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0

    pragma solidity ^0.8.14;

    contract WeddingCertificate {
        string private married1;
        string private married2;

        constructor(string memory _married1, string memory _married2) {
            married1 = _married1;
            married2 = _married2;
        }

        function getMarriedNames () public view returns (string memory) {
            string memory names = string.concat(married1, "and ", married2);
            return names;
        }

        function setMariedNames (string memory _married1, string memory _married2) public {
            married1 = _married1;
            married2 = _married2;
        }
    }