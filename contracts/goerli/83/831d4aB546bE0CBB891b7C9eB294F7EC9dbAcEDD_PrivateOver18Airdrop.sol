// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title over18Airdrop
/// @author Enrico Bottazzi
/// @notice Verify attribute of a claim with ZKP and, if verified, execute logic.

interface IVerifier {
    function verifyProof(uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[72] memory input)
        external view returns(bool);
}

interface IPrivateSoulMinter {
    function claimSignatureHash(uint256) external view returns (bytes32);
    function ownerOf(uint256) external view returns (address);
}

/// @title An example airdrop contract utilizing zk-proof for claim's attributes verification.
contract PrivateOver18Airdrop {

    IVerifier verifier;
    IPrivateSoulMinter privateSoulMinter;

    mapping(address => bool) public isElegibleForAirdrop;

    constructor(
        IVerifier _verifier,
        IPrivateSoulMinter _privateSoulMinter
    ) {
        verifier = _verifier;
        privateSoulMinter = _privateSoulMinter;
    }

    // @notice verifies the validity of the proof, and make further verifications on the public input of the circuit, if verified add the address to the list of eligible addresses
    function collectAirdrop(uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[72] memory input,
            uint256 _tokenID
            ) public 
    {   

        // here I need to call the PrivateSoulMinter contract to get the hash metadata
        // @dev check if the public input used to generate the proof are legit
        require(isElegibleForAirdrop[msg.sender] == false, "You already claimed your airdrop!");
        require(privateSoulMinter.ownerOf(_tokenID) == msg.sender,"This token belongs to another soul");
        require(privateSoulMinter.claimSignatureHash(_tokenID) == keccak256(abi.encodePacked(input[0], input[1], input[2])), "The signature is not valid");
        require(input[3] == 0x152f5044240ef872cf7e6742fe202b9e07ed6188e9e734c09b06939704852358 && input[4] == 0x2865441cd3e276643c84e55004ad259dff282c8c47c6e8c151afacdadf6f6db3, "The claim was signed by a wrong public key");
        require(input[5] == 0x0000000000000000000000000000000087b9b4c689c2024c54d1bf962cb16bce, "Wrong Claim schema used to generate the proof");
        require(input[6] == 0x0000000000000000000000000000000000000000000000000000000000000002, "Invalid slot index used to generate the proof");
        require(input[7] == 0x0000000000000000000000000000000000000000000000000000000000000003, "Invalid operator used to generate the proof");
        require(input[8] == 0x0000000000000000000000000000000000000000000000000000000000000012, "Invalid threshold value used to generate the proof");

        require(
            verifier.verifyProof(a, b, c, input),
            "Proof verification failed"
        );
        isElegibleForAirdrop[msg.sender] = true;
    }
}