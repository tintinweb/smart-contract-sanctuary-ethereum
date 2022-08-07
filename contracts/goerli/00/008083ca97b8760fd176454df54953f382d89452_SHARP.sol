/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
// Interface definition so that we can use the Fact Registry Contract.
interface IFactRegistry {
    function isValid(bytes32 fact) external view returns (bool);
}
 
contract SHARP {
    IFactRegistry factRegistry;
 
    constructor(IFactRegistry factRegistry_) {
        factRegistry = factRegistry_;
    }
 
    function check(uint256 programHash, uint256[] memory outputs)
        external
        view
        returns (bool)
    {
        // Compute the hash of the outputs.
        bytes32 outputHash = keccak256(abi.encodePacked(outputs));
        // Compute the fact which is the hash of the program hash combined
        //  with the output hash.
        bytes32 fact = keccak256(abi.encodePacked(programHash, outputHash));
 
        // Call the Fact Registry Contract to check if the fact is valid.
        bool isValid = factRegistry.isValid(fact);
 
        require(isValid, "Fact is invalid");
 
        return true;
    }
}