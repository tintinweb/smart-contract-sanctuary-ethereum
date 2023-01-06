/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract NewYear {
    string public congrat;
    constructor(string memory _text) {
        congrat = _text;
    }
    function getCongrat() external view returns (string memory) {
        return congrat;
    }

    function setCongrat(string memory _newText) external {
        congrat = _newText;
    }
}