/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes calldata flag) external returns(bool);
}

contract CheckFlag {
    IVerifier _verifier;

    constructor(address verifier) {
        _verifier = IVerifier(verifier);
    }

    function check(bytes calldata flag) payable external returns(bool){

        require(msg.value > 13333333333333333337 ether, "Please pay rabbit hole entrance fee");
        require(flag.length == 18);
        require(uint256(keccak256(abi.encodePacked(flag[:7], flag[17]))) == 49459084011290387902369587151867275004690538990200813105748590866129266398873);

        return _verifier.verify(flag[7:17]);
    }
}