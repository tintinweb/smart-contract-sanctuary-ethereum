/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;


contract sign{
    mapping (address => string) public signatures;

    function signMe(address signer, string memory signature) public returns(string memory){
        signatures[signer] = signature;
        return signature;
    }

    function getSignature(address whichToCheck) public view returns(string memory){
        return signatures[whichToCheck];
    }

}