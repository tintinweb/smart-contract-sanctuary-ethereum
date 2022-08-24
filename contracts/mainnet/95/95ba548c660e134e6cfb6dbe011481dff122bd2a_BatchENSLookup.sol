/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Batch ENS Lookup
// Author: 0xInuarashi
// https://twitter.com/0xInuarashi || 0xInuarashi#1234

interface iReverseRegistrar {
    function node(address addr) external view returns (bytes32);
}

interface iReverseResolver {
    function name(bytes32 resolver) external view returns (string memory);
}

contract BatchENSLookup {
    // Interfaces
    iReverseRegistrar public ENSReverseRegistrar = 
        iReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    iReverseResolver public ENSReverseResolver = 
        iReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);
    
    // Batch Lookup ENS
    function batchENSLookup(address[] calldata addresses_) external view
    returns (string[] memory) {
        uint256 l = addresses_.length;
        string[] memory _batchENS = new string[] (l);

        for (uint256 i = 0; i < addresses_.length; i++) {
            // First, find the bytes32 registrar
            bytes32 _registrar = ENSReverseRegistrar.node(addresses_[i]);
            // Then, find the ENS from the resolver
            string memory _ens = ENSReverseResolver.name(_registrar);
            // Add it to the array
            _batchENS[i] = _ens;
        }

        return _batchENS;
    }

    // Batch Lookup Registrar
    function batchRegistrarLookup(address[] calldata addresses_) public view
    returns (bytes32[] memory) {
        uint256 l = addresses_.length;
        bytes32[] memory _batchRegistrar = new bytes32[] (l);

        for (uint256 i = 0; i < addresses_.length; i++) {
            // First, find the bytes32 registrar
            bytes32 _registrar = ENSReverseRegistrar.node(addresses_[i]);
            // Then, add it to the array
            _batchRegistrar[i] = _registrar;
        }

        return _batchRegistrar;
    }
}