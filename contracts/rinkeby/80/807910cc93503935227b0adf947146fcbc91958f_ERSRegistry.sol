// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERSRegistry } from "./interface/IERSRegistry.sol";

contract ERSRegistry is IERSRegistry {

    mapping(bytes32 => Record) records;

    constructor() {

    }

    function getRecord(bytes32 chipId) external view returns (Record memory rec) {
        rec = records[chipId];
    }

    function addRecord(bytes32 chipId, address owner, address resolver) external {
        records[chipId] = Record(owner, resolver);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERSRegistry {
    struct Record {
        address owner;
        address resolver;
    }

    
}