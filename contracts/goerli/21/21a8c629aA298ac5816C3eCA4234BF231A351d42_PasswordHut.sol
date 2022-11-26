/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title PasswordHut
 * @dev Smart Contract to Store the IPFS Hashes of Encrypted Credentials of users
 */

contract PasswordHut {

    // Structure of Single Credential
    // credentialID: ID of the Credential
    // status: Is the Credential Currently Active (True) or Inactive (False)
    // ipfsCID: hash CID of IPFS

    struct Credential{
        // Packed uint32 and bool together to Save on Gas
        uint32 credentialID;
        bool status;
        string ipfsCID;
    }

    // Contains list of Credentials based on Different Users
    mapping(address => Credential[]) credentials;

    // Events for New Credential Added, Existing Credential Updated and Deleted Credential
    event NewCredentialAdded(address indexed owner, uint credentialID, string ipfsCID);
    event ExistingCredentialUpdated(address indexed owner, uint credentialID, string ipfsCID);
    event DeletedCredential(address indexed owner, uint credentialID);

    /**
     * @dev function to send all Credentials of a Particular User
     */
    function retrieveCredentials() public view returns (Credential[] memory){
        return credentials[msg.sender];
    }

    // Verifying the correctness of CID hash
    modifier verifyipfsCID(string memory _ipfsCID) {
        require(bytes(_ipfsCID).length == 46, "ipfsCID Submitted is Invalid!");
        _;
    }

    // Verifying the correctness of ID
    modifier verifyID(uint _id){
        require(_id <= credentials[msg.sender].length,"Wrong ID Entered!");
        _;
    }

    /**
     * @dev function to add new Credential by a User
     */
    function addNewCredential(string memory _ipfsCID) public verifyipfsCID(_ipfsCID){
        credentials[msg.sender].push(Credential(uint32(credentials[msg.sender].length), true, _ipfsCID));
        emit NewCredentialAdded(msg.sender, credentials[msg.sender].length - 1, _ipfsCID);
    }

    /**
     * @dev function to update an Existing Credential
     */
    function updateExistingCredential(uint _id, string memory _ipfsCID) public verifyipfsCID(_ipfsCID) verifyID(_id){
        credentials[msg.sender][_id].ipfsCID = _ipfsCID;
        emit ExistingCredentialUpdated(msg.sender, _id, _ipfsCID);
    }

    /**
     * @dev function to delete any Credential
     */
    function deleteCredential(uint _id) public verifyID(_id){
        credentials[msg.sender][_id].status = false;
        emit DeletedCredential(msg.sender, _id);
    }
    
}