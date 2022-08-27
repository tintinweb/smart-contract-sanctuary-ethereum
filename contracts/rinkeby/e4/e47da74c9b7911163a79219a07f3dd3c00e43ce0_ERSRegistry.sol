// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERSRegistry} from "./interface/IERSRegistry.sol";

contract ERSRegistry is IERSRegistry {
    bytes32 constant CLAIM_TYPEHASH =
        keccak256("Claim(bytes32 chipId,address claimant)");

    bytes32 constant DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                "EIP712Domain(string name,string version,uint256 chainId)",
                keccak256("DopamineERS"),
                keccak256("0.1.0"),
                4
            )
        );

    mapping(bytes32 => Record) records;

    event Sig(address sig);

    constructor() {}

    function getRecord(bytes32 chipId)
        external
        view
        returns (Record memory rec)
    {
        rec = records[chipId];
    }

    function addRecord(
        bytes32 chipId,
        address owner,
        address resolver
    ) external {
        records[chipId] = Record(owner, resolver);
    }

    function hashClaim(bytes32 chipId, address claimant)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(CLAIM_TYPEHASH, chipId, claimant))
                )
            );
    }

    function verify(
        bytes32 chipId,
        address claimant,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        address sig = ecrecover(hashClaim(chipId, claimant), v, r, s);
        emit Sig(sig);
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