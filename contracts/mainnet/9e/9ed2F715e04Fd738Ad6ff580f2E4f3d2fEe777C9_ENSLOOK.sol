/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface iReverseRegistrar {
    function node(address addr) external view returns (bytes32);
}

interface iReverseResolver {
    function name(bytes32 resolver) external view returns (string memory);
}

contract ENSLOOK {

    iReverseRegistrar public ENSReverseRegistrar = iReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    iReverseResolver public ENSReverseResolver = iReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);
    
    function ensLookup(address[] calldata addresses_) external view returns (string[] memory) {
        uint256 l = addresses_.length;
        string[] memory _batchENS = new string[] (l);
        for (uint256 i = 0; i < addresses_.length; i++) {
            bytes32 _registrar = ENSReverseRegistrar.node(addresses_[i]);
            string memory _ens = ENSReverseResolver.name(_registrar);
            _batchENS[i] = _ens;
        }
        return _batchENS;
    }
}