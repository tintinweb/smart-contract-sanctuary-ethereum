// SPDX-License-Identifier: MIT
pragma solidity ~0.8.16;

interface IFactRegistry {
    function isValid(bytes32 fact) external view returns (bool);
}

contract ProofVerifier {
    // SHARP Goerli contract
    address public constant FACT_REGISTY =
        0xAB43bA48c9edF4C2C4bB01237348D1D7B28ef168;

    uint256 public constant PROGRAM_HASH =
        0x38477aa3daf83ba977d13af8dd288d76da55cfde05ccfc7ee5438f4c56fb0b6;

    error InvalidFact();

    function verifyFact(uint256[] memory outputs) external view returns (bool) {
        bytes32 outputHash = keccak256(abi.encodePacked(outputs));
        bytes32 fact = keccak256(abi.encodePacked(PROGRAM_HASH, outputHash));

        bool valid = IFactRegistry(FACT_REGISTY).isValid(fact);
        if (!valid) revert InvalidFact();

        return true;
    }
}