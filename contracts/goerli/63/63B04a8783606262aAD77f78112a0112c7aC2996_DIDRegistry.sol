// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

// DID registry contract
contract DIDRegistry {
    // Mapping of DIDs to identity structures
    mapping(string => Identity) public identities;

    // Identity structure
    struct Identity {
        // DID owner
        address owner;
        // DID attributes
        bytes32[] attributes;
    }

    // Event for DID registration
    event DIDRegistered(string did);

    // Function to register a DID
    function registerDID(string memory did) public {
        // Check if the DID is already registered
        require(msg.sender == tx.origin, "DID already registered");

        // Set the DID owner to the contract caller
        identities[did].owner = msg.sender;

        // Emit the DIDRegistered event
        emit DIDRegistered(did);
    }

    // Function to add attributes to a DID
    function addAttributes(
        string memory did,
        bytes32[] memory attributes
    ) public {
        // Check if the DID is owned by the contract caller
        require(
            identities[did].owner == msg.sender,
            "Only the DID owner can add attributes"
        );

        // Add the attributes to the DID
        for (uint i = 0; i < attributes.length; i++) {
            identities[did].attributes.push(attributes[i]);
        }
    }

    // Function to get the attributes for a DID
    function getAttributes(
        string memory did
    ) public view returns (bytes32[] memory) {
        // Return the attributes for the DID
        return identities[did].attributes;
    }
}