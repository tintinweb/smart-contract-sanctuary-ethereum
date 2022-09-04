/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

interface ISemaphore {
    function addMember(uint256 groupId, uint256 identityCommitment) external;
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;
    function verifyProof(uint256 groupId, bytes32 signal, uint256 nullifierHash, uint256 externalNullifier, uint256[8] calldata proof) external;
}

contract TazMessage { 
    address public owner;
    
    // Stores the address of the Semaphore contract used for verifications
    ISemaphore public semaContract;
    
    // Nested mappiing that stores the members (by group) that 
    // have been added to the Semaphore contract through this contract
    mapping(uint256 => mapping(uint256 => bool)) internal groups;

    // Emitted when a member is added to a group on the Semaphore contract
    event MemberAdded(uint256 indexed groupId, uint256 identityCommitment);
    
    // Emitted when a message is added
    event MessageAdded(string parentMessageId, string messageId, string messageContent);    

    // Constructor sets the address of the Semaphore contract
    constructor(ISemaphore semaContractAddr) {
        owner = msg.sender;
        semaContract = semaContractAddr;
    }

    // Updates the group admin address on the Semaphore contract.
    // This method exists to allow for the group admin to be updated on the Semaphore contract
    // when this contract is updated and deployed to a new address, so that a new Semaphore 
    // group doesn't have to be created.
    function updateSemaphoreGroupAdmin(uint256 groupId, address newAdmin) external {
        require(msg.sender == owner);
        
        semaContract.updateGroupAdmin(groupId, newAdmin);
    }
    
    // Checks if a member has been added to a group through this contract 
    function memberExists(uint256 groupId, uint256 identityCommitment) internal view returns (bool) {
        return groups[groupId][identityCommitment];
    }

    // Adds a member to a group on the Semaphore contract, and tracks members added through this contract
    function addMember(uint256 groupId, uint256 identityCommitment) external {        
        require(msg.sender == owner);
        
        // Check that the member has not already been added
        require(!memberExists(groupId, identityCommitment), "Member has already been added to this group");
        
        // Add the member to the Semaphore contract
        semaContract.addMember(groupId, identityCommitment);

        // Set a flag to store the added status of this member
        groups[groupId][identityCommitment] = true;

        // Emit an event indicating the successful member addition
        emit MemberAdded(groupId, identityCommitment);
    }

    // Verifies a proof and adds a message
    function addMessage(
        string memory messageId, 
        string memory messageContent, 
        uint256 groupId, 
        bytes32 signal, 
        uint256 nullifierHash, 
        uint256 externalNullifier, 
        uint256[8] calldata proof) external {

        // Verify proof with Sempahore contract
        semaContract.verifyProof(groupId, signal, nullifierHash, externalNullifier, proof);

        // Emit event with message if verification was successful 
        emit MessageAdded("", messageId, messageContent);
    }

    // Verifies a proof and replies to an existing message
    function replyToMessage(
        string memory parentMessageId, 
        string memory messageId, 
        string memory messageContent,
        uint256 groupId, 
        bytes32 signal, 
        uint256 nullifierHash, 
        uint256 externalNullifier, 
        uint256[8] calldata proof) external {

        // Require a valid parentMessageId
        require(bytes(parentMessageId).length > 0, "Invalid ID provided for parent message");
        
        // Verify proof with Sempahore contract
        semaContract.verifyProof(groupId, signal, nullifierHash, externalNullifier, proof);

        // Emit event with message if verification was successful 
        emit MessageAdded(parentMessageId, messageId, messageContent);
    }
}