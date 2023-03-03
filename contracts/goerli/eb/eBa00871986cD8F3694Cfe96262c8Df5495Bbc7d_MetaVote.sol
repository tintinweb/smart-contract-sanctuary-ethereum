/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MetaVote {
    // Storage

    /// A mapping of elections to the addresses of their creators
    mapping (bytes32 => address) public elections;

    // Events
    event ElectionCreated(bytes32 indexed electionId, string metadataURI, bytes metadataBlob);
    event Vote(address indexed voter, bytes value, bytes32 indexed electionId);
    event TagAdded(bytes32 indexed electionId, string indexed tag);

    /// Election metadata should conform to the MetaVote JSON Schema.
    /// @param electionId  A user-generated unique identifier for the election
    /// @param metadataURI  A URI to the metadata describing the election. Immutable data is preferred.
    /// @param metadataBlob  A blob of metadata conforming to the MetaVote election JSON schema.
    function createElection(
        bytes32 electionId,
        string calldata metadataURI,
        bytes calldata metadataBlob
    ) external {
        require(elections[electionId] == address(0x0), "Election already exists.");
        elections[electionId] = msg.sender;
        emit ElectionCreated(electionId, metadataURI, metadataBlob);
    }

    function vote(bytes32 electionId, bytes calldata value) external {
        require(elections[electionId] != address(0x0), "Election does not exist.");
        emit Vote(msg.sender, value, electionId);
    }

    /// Add a tag to an election to allow searching and filtering.
    /// `msg.sender` must be the address that created the election via createElection().
    function addSearchableTag(bytes32 electionId, string calldata tag) external {
        require(elections[electionId] != address(0x0), "Election does not exist.");
        require(msg.sender == elections[electionId], "Sender is not the election creator.");
        emit TagAdded(electionId, tag);
    }

  }