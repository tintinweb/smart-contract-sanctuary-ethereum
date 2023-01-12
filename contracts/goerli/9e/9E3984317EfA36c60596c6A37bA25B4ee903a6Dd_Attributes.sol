// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library Attributes {
    enum Code { 
        Status,                // 0
        ID,                    // 1
        IDEncr,                // 2
        KeyEncr,               // 3
        DocBaseUIDHash,        // 4
        DocUIDEncrypted,       // 5
        DealCid,               // 6
        MinerAddress,          // 7
        Content,               // 8
        ContentEncr,           // 9
        DescriptionEncr,       // 10
        PasswordHash,          // 11
        Timestamp,             // 12
        NameEncr,              // 13
        GroupDoctorsIDHash,    // 14
        GroupAllDocsIDHash     // 15
    }

    struct Attribute {
        Code  code;
        bytes value;
    }

    function get(Attribute[] memory _p, Code a) 
        public 
        pure 
        returns (bytes memory) 
    {
        for (uint i = 0; i < _p.length; i++) {
            if (_p[i].code == a) return _p[i].value;
        }
        return new bytes(0);
    }
}