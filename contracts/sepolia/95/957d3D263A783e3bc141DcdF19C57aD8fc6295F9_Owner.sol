/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract Owner {
    
    string public constant name = "Some";
    bytes32 private DOMAIN_SEPARATOR;
    
    constructor(bytes32 _DOMAINSEPARATOR)  {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = _DOMAINSEPARATOR;
    }
}