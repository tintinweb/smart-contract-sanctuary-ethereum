/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract ConstraintsVerifier {
    bool isVerified = true;

    function verifyProof(bytes memory proof, uint[] memory pubSignals) external view returns (bool) {
        require(proof.length > 0, "PricingOracle: Invalid proof");
        require(pubSignals.length == 2, "PricingOracle: Invalid pubSignals");
        uint256 minLength = pubSignals[1];
        require(minLength >= 3, "PricingOracle: Length less than 3");
        return isVerified;
    }   
    
    constructor() {
    }
}