// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

contract ENSResolver {
    // Same address for Mainnet, Ropsten, Rinkerby, Gorli and other networks;
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function computeNameHash(bytes memory _name) private pure returns (bytes32 nameHash) {
        nameHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        nameHash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(nameHash, keccak256(abi.encodePacked("eth")))),keccak256(abi.encodePacked(_name))));
    }

    function resolve(string memory _name) public virtual view returns (address) {
        bytes memory name = abi.encodePacked(_name);
        uint nameLength = name.length;
        require(nameLength > 7, "impossible ENS address");
        require(
            name[nameLength-4] == 0x2E &&
            name[nameLength-3] == 0x65 &&
            name[nameLength-2] == 0x74 &&
            name[nameLength-1] == 0x68,
            "ENS name must end with \".eth\""
        );

        bytes memory strippedName = new bytes(nameLength-4);
        for (uint i = 0; i < nameLength-4; i++) {
            strippedName[i] = name[i];
        }

        Resolver resolver = ens.resolver(computeNameHash(strippedName));
        return resolver.addr(computeNameHash(strippedName));
    }
}

abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}