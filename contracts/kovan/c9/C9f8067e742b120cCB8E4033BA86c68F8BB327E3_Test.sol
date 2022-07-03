/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.8.0;

contract Test{
    string text;

    function Escribir(string calldata _text) public {
        text = _text;
    }

    function Leer() public view returns (string memory){
        return text;
    }
}