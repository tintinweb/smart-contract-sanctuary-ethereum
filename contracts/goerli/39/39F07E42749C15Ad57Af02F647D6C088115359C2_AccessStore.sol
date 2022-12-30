// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "./interfaces/IAccessStore.sol";

contract AccessStore is IAccessStore {
    mapping(bytes32 => Access[]) accessStore;     // accessID => Access[]

    ///
    function getAccess(bytes32 accessID) external view returns(Access[] memory) {
        return accessStore[accessID];
    }

    ///
    // Returns 1 on update or 2 on insert
    function setAccess(bytes32 accessID, Access memory o) external returns(uint8)
    {
        for(uint i; i < accessStore[accessID].length; i++) {
            if (accessStore[accessID][i].idHash == o.idHash) {
                accessStore[accessID][i].idEncr = o.idEncr;
                accessStore[accessID][i].keyEncr = o.keyEncr;
                accessStore[accessID][i].level = o.level;
                return 1;
            }
        }

        accessStore[accessID].push(o);
        return 2;
    }

    ///
    function getAccessByIdHash(bytes32 accessID, bytes32 accessIdHash) external view returns(Access memory) 
    {
        for (uint i; i < accessStore[accessID].length; i++){
            if (accessStore[accessID][i].idHash == accessIdHash) {
                return accessStore[accessID][i];
            }
        }

        revert("NFD");
    }

    ///
    function userAccess(bytes32 userID, AccessKind kind, bytes32 idHash) external view returns (Access memory) 
    {
        bytes32 accessID = keccak256(abi.encode(userID, kind));
        for(uint i; i < accessStore[accessID].length; i++){
            if (accessStore[accessID][i].idHash == idHash) {
                return accessStore[accessID][i];
            }
        }

        // Checking groups
        accessID = keccak256(abi.encode(userID, AccessKind.UserGroup));
        for (uint i = 0; i < accessStore[accessID].length; i++) {
            for (uint j = 0; j < accessStore[accessID].length; j++) {
                if (accessStore[accessID][j].idHash == idHash) {
                    return accessStore[accessID][j];
                }
            }
        }

        return Access(bytes32(0), new bytes(0), new bytes(0), AccessLevel.NoAccess);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

interface IAccessStore {
    enum AccessLevel { NoAccess, Owner, Admin, Read }
    enum AccessKind { Doc, DocGroup, UserGroup }
    
    struct Access {
        bytes32      idHash;
        bytes        idEncr;    // id encrypted by access key
        bytes        keyEncr;   // access key encrypted by user private key
        AccessLevel  level;
    }

    function getAccess(bytes32 accessID) external view returns(Access[] memory);
    function setAccess(bytes32 accessID, Access memory o) external returns(uint8);
    function getAccessByIdHash(bytes32 accessID, bytes32 accessIdHash) external view returns(Access memory);
    function userAccess(bytes32 userID, AccessKind kind, bytes32 idHash) external view returns (Access memory);
}