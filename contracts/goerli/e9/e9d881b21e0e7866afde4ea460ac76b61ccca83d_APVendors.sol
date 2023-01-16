/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract APVendors {
    struct Vendorstruct {
        uint256 id;
        string vendorName;
        bool active;
        uint256 varianceLevel;
        uint256 created;
        uint256 updated;
    }

    // Create a mapping from vendor name to vendor struct
    mapping(bytes32 => Vendorstruct) private vendorsByName;

    // Create a mapping from vendor id to vendor struct
    mapping(uint256 => Vendorstruct) private vendorsById;
    uint256 private totalEntries;

        function contructorFunction(uint256 _totalEntries) public {
        totalEntries = _totalEntries;
    }

    //this function should check if the vendor exists. To prevent duplicate vendors
    function addVendor(
        string memory _vendorName,
        uint256 _varianceLevel
    ) public returns (uint256) {
        // Check that the variance level is non-negative
        require(_varianceLevel >= 0);

        // Create the new vendor struct
        Vendorstruct memory vendor = Vendorstruct(
            totalEntries,
            _vendorName,
            true,
            _varianceLevel,
            block.timestamp,
            block.timestamp
        );

        // Save the new vendor in both mappings
        vendorsByName[keccak256(abi.encodePacked(_vendorName))] = vendor;
        vendorsById[totalEntries] = vendor;

        totalEntries++;
        return totalEntries;
    }

    function getAllVendors() public view returns (Vendorstruct[] memory) {
        Vendorstruct[] memory allVendors = new Vendorstruct[](totalEntries);
        for (uint256 i = 0; i < totalEntries; i++) {
            allVendors[i] = vendorsById[i];
        }
        return allVendors;
    }

    //This fuction is not updating the variance levels. Fix it.
    function updateVarianceLevel(
        string memory _vendorName,
        uint256 _newVarianceLevel
    ) public returns (bool) {
        // Check that the variance level is non-negative
        require(_newVarianceLevel >= 0);

        // Look up the vendor by name
        Vendorstruct storage vendor = vendorsByName[
            keccak256(abi.encodePacked(_vendorName))
        ];

        // Check that the vendor exists
        bytes32 vendorNameHash = keccak256(abi.encodePacked(_vendorName));
        bytes32 vendorNameHash2 = keccak256(
            abi.encodePacked(vendor.vendorName)
        );
        require(vendorNameHash == vendorNameHash2);

        // Update the variance level and
        // update the "updated" timestamp
        vendor.varianceLevel = _newVarianceLevel;
        vendor.updated = block.timestamp;
        return true;
    }

    function deleteVendor(string memory _vendorName) public returns (bool) {
        // Look up the vendor by name
        Vendorstruct storage vendor = vendorsByName[
            keccak256(abi.encodePacked(_vendorName))
        ];

        // Check that the vendor exists
        bytes32 vendorNameHash = keccak256(abi.encodePacked(_vendorName));
        bytes32 vendorNameHash2 = keccak256(
            abi.encodePacked(vendor.vendorName)
        );
        require(vendorNameHash == vendorNameHash2);

        // Set the "active" flag to false
        vendor.active = false;

        return true;
    }

    //create a function that will get vendors by ID and return the name as a string
    function getVendorNameById(
        uint256 _vendorId
    ) public view returns (string memory) {
        //get the vendor from the vendorsById mapping
        Vendorstruct memory vendor = vendorsById[_vendorId];
        //return the vendor's name
        return vendor.vendorName;
    }

    //create a function that will get vendors by name and return the ID as a uint
    function getVendorIdByName(
        string memory _vendorName
    ) public view returns (uint256) {
        //get the vendor from the vendorsByName mapping
        Vendorstruct memory vendor = vendorsByName[
            keccak256(abi.encodePacked(_vendorName))
        ];
        //return the vendor's ID
        return vendor.id;
    }

    //create a function that will check if a vendor exists by name and return a boolean
    function checkVendorExists(
        string memory _vendorName
    ) public view returns (bool) {
        //get the vendor from the vendorsByName mapping
        Vendorstruct memory vendor = vendorsByName[
            keccak256(abi.encodePacked(_vendorName))
        ];
        //return the vendor's ID
        return vendor.active;
    }

    //create a function that will return the variance level of a vendor by ID
    function getVarianceLevelById(
        uint256 _vendorId
    ) public view returns (uint256) {
        //get the vendor from the vendorsById mapping
        Vendorstruct memory vendor = vendorsById[_vendorId];
        //return the vendor's variance level
        return vendor.varianceLevel;
    }
}