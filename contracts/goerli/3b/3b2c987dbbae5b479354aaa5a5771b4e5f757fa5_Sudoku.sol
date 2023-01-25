/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool);
}

contract Sudoku {
    address public verifierAddr;

    constructor(address _verifierAddr) {
        verifierAddr = _verifierAddr;
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        return IVerifier(verifierAddr).verifyProof(a, b, c, input);
    }
}