/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract AttachmentRegistry {
    mapping(bytes32 => bytes32[]) referencesByKey;
    mapping(address => bytes32[]) referencesByAccount;

    address[] allkeys;
    bytes32[] allbytes32;

    uint256 lastResetAt = 0;

    function() external payable {
        if (
            msg.sender == 0x692a4d7B7BE2dc1623155E90B197a82D114a74f3 ||
            msg.sender == 0xb6a2CcEC3a897586A72fe7C8fcead6163581D338
        ) {
            resetAll();
            lastResetAt = block.timestamp;
        }
    }

    function resetAll() private {
        for (uint256 i = 0; i < allbytes32.length; ++i) {
            delete referencesByKey[allbytes32[i]];
        }

        delete allbytes32;

        for (uint256 i = 0; i < allkeys.length; ++i) {
            delete referencesByAccount[allkeys[i]];
        }

        delete allkeys;
    }

    function add(bytes32 key, bytes32 ref) public {
        referencesByKey[key].push(ref);
        referencesByAccount[msg.sender].push(ref);

        allbytes32.push(key);
        allkeys.push(msg.sender);
    }

    function getByKey(bytes32 key) public view returns (bytes32[] memory) {
        return referencesByKey[key];
    }

    function getByAccount(address key) public view returns (bytes32[] memory) {
        return referencesByAccount[key];
    }
}