/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract RevocationRegistry {

    // map the hash of the issued credential to address of the issuer to blocknumber
    mapping(bytes32 => mapping(address => uint)) private revocations;

    event Revoked(address indexed issuer, bytes32 indexed digest);

    /**
     * @dev revoke a credential by an issuer.
     * It maps the hash of the credential with the issuer (the message sender) 
     *  to the blocknumber at which the credential is revoked
     *
     * @param digest the keccak256 hash of the verifiable credential
     *
     * Emits an {Revoked} event.
     *
     * Requirements:
     * - the credential is not already revoked
     */
    function revoke(bytes32 digest) public {
        require(revocations[digest][msg.sender] == 0, "claim has been already revoked");
        revocations[digest][msg.sender] = block.number;
        emit Revoked(msg.sender, digest);
    }

    /**
     * @dev check if a credential is revoked.
     *
     * @param issuer the address of the issuer
     * @param digest the keccak256 hash of the verifiable credential
     *
     * @return Zero if the credential has not been revoked. otherwise the number of
     * the block at which the credential has been revoked
     */
    function revoked(address issuer, bytes32 digest) public view returns (uint) {
        return revocations[digest][issuer];
    }

}