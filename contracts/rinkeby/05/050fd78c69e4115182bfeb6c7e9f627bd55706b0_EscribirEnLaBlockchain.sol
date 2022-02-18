/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract EscribirEnLaBlockchain {

    string text;

    function Escribir (string calldata _texto) public {
        text = _texto;
    }

    function Leer () public view returns(string memory) {
        return text;
    }
}