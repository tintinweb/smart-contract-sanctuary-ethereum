// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERSRegistry} from "./interface/IERSRegistry.sol";

contract ERSRegistry is IERSRegistry {
    bytes32 constant CLAIM_TYPEHASH =
        keccak256("Claim(bytes32 chipId,address claimant)");

    bytes32 DOMAIN_SEPARATOR;
    
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        

    mapping(bytes32 => Record) records;

    event Sig(address sig);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("DopamineERS"),
                keccak256("0.1.0"),
                4,
                address(this)
            )
        );
    }

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
        private view
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

    function verifyChip(bytes32 chip, uint8 v, bytes32 r, bytes32 s, bytes32 signature) external {
        address computedAddress = address(uint160(uint256(chip)));
        address fromSig = ecrecover(signature, v, r, s);
        emit Sig(computedAddress);
        emit Sig(fromSig);
    }

    function verify(
        bytes32 chipId,
        address claimant,
        bytes32 sig,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 ov,
        bytes32 or,
        bytes32 os
    ) external {
        address originalOwner = ecrecover(hashClaim(chipId, claimant), v, r, s);
        emit Sig(originalOwner);
        address computedAddress = address(uint160(uint256(chipId)));
        address fromSig = ecrecover(sig, ov, or, os);
        // require(fromSig == computedAddress, "invalid eip 191 sig");
        emit Sig(fromSig);
        emit Sig(computedAddress);
        // emit Sig(sig);
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