/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

//SPDX-License-Identifier: Unlicense

// File contracts/ConstraintsVerifier.sol

pragma solidity ^0.8.0;

contract ConstraintsVerifier {
    bool isVerified = true;

    function verifyProof(bytes memory proof, uint[] memory pubSignals) external view returns (bool) {
        require(proof.length > 0, "PricingOracleV1: Invalid proof");
        require(pubSignals.length == 2, "PricingOracleV1: Invalid pubSignals");
        uint256 minLength = pubSignals[1];
        require(minLength >= 3, "PricingOracleV1: Length less than 3");
        return isVerified;
    }   
    
    constructor() {
    }
}