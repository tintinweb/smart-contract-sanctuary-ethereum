/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract IPFS_Registry {
    // Store struct definition
    struct Esim {
        uint id;
        string hardwareId;
        string esimId;
    }

    // Mapping from esim id to esim struct
    mapping(uint => Esim) public esims;

    // Array of all esim IDs
    uint[] public esimIds;

    // Registers a new esim
    function newRegistration(uint _id, string memory _hardwareId, string memory _esimId) private {
        // Create a new esim
        Esim memory newEsim = Esim(_id, _hardwareId, _esimId);

        // Add the new esim to the mapping
        esims[_id] = newEsim;

        // Add the esim id to the array of all esim IDs
        esimIds.push(_id);
    }

    // Edits an existing esim registration
    function editRegistration(uint _id, string memory _hardwareId, string memory _esimId) private {
        // Retrieve the esim from the mapping
        Esim storage esim = esims[_id];

        // Update the esim's hardwareId and esimId
        esim.hardwareId = _hardwareId;
        esim.esimId = _esimId;
    }

    // Returns the esimIds array
    function getEsimIds() public view returns (uint[] memory) {
        return esimIds;
    }

    // Returns an esim by esimID
    function getEsim(uint _id) public view returns (uint id, string memory hardwareId, string memory esimId) {
        // Retrieve the esim from the mapping
        Esim storage esim = esims[_id];

        // Return the esim's id, hardwareId, and esimId
        return (esim.id, esim.hardwareId, esim.esimId);
    }
}