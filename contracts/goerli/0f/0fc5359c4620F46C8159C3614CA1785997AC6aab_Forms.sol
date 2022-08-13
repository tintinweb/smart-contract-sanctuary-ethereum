// https://zkforms.crypto
/*
 *        _    _____                        
 *    ___| | _|  ___|__  _ __ _ __ ___  ___ 
 *   |_  / |/ / |_ / _ \| '__| '_ ` _ \/ __|
 *    / /|   <|  _| (_) | |  | | | | | \__ \
 *   /___|_|\_\_|  \___/|_|  |_| |_| |_|___/
 * oooooooooooooooooooooooooooooooooooooooooooooooooo
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier{
    function verifyProof(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory input) external returns (bool);
}

contract Forms{
    IVerifier public immutable verifier;
    mapping(string => bool) public formMap;
    
    modifier responseNotDuplicate(string memory id) {
        require(formMap[id] == false, "already responded");
        _;
    }

    constructor(IVerifier _verifier) { 
        verifier = _verifier; 
    }

    function submit(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[12] memory input, string memory id) public responseNotDuplicate(id) {
        require(verifier.verifyProof(a, b, c, input), "Invalid proof");
        formMap[id] == true;
    }
}