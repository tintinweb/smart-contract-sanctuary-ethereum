/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ORG3 {
    uint256 public orgCount;

    struct Organization {
        string primaryDomain; // a ens domain
        uint256 fileCount;
        mapping (uint256 => string) fileNames; 
        mapping (uint256 => string) encryptedHashes; 
        mapping (uint256 => string) symmetricKeys;
        mapping (uint256 => string) accessRequirements; // accessRequirement: a.eth/b.eth/c.eth
    }

    constructor() {
        orgCount = 1;
    }

    mapping (uint256 => Organization) public allOrganizations;
    mapping (string => uint256) public organizationIds;

    function getAllData(string calldata primaryDomain) external view returns (string[] memory) {
        uint256 fileCount = allOrganizations[organizationIds[primaryDomain]].fileCount;
        string[] memory ret = new string[](fileCount*4);
        for (uint i = 0; i < fileCount; i++) {
            ret[i] = allOrganizations[organizationIds[primaryDomain]].fileNames[i];
        }
        for (uint i = 0; i < fileCount; i++) {
            ret[fileCount+i] = allOrganizations[organizationIds[primaryDomain]].encryptedHashes[i];
        }
        for (uint i = 0; i < fileCount; i++) {
            ret[fileCount*2+i] = allOrganizations[organizationIds[primaryDomain]].symmetricKeys[i];
        }
        for (uint i = 0; i < fileCount; i++) {
            ret[fileCount*3+i] = allOrganizations[organizationIds[primaryDomain]].accessRequirements[i];
        }
        return ret;
    }

    function createOrganization(string calldata primaryDomain) external returns (uint256) {
        require(organizationIds[primaryDomain] == 0, "Organization existed");
        
        uint256 orgId = orgCount;
        Organization storage o = allOrganizations[orgId];
        o.primaryDomain = primaryDomain;
        o.fileCount = 0;
        organizationIds[primaryDomain] = orgId;

        orgCount = orgCount + 1;
        return orgId;
    }

    function addFile(string calldata primaryDomain, string calldata filename, string calldata encryptedHash, string calldata symmetricKey, string calldata accessRequirement) external returns (uint256){
        require(organizationIds[primaryDomain] != 0 , "Organization does not exist");

        Organization storage o = allOrganizations[organizationIds[primaryDomain]];
        uint256 fileId = o.fileCount;
        o.fileNames[fileId] = filename;
        o.encryptedHashes[fileId] = encryptedHash;
        o.symmetricKeys[fileId] = symmetricKey;
        o.accessRequirements[fileId] = accessRequirement;

        o.fileCount = o.fileCount + 1;
        return 1;
    }
    
}