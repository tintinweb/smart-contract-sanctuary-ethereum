// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BytesUtils.sol";
import "./IOnChainMonkey.sol";

// @author mande.eth
// @notice Verify if a monkey is naked (clothes = 0 and hat = 0).
contract IsMonkeyNaked {
    // adding the .slice() method on bytes
    using BytesUtils for bytes;

    // OCM contract address    
    address immutable _ocm;

    constructor(address ocm_){
        _ocm = ocm_;
    }

    // @dev compares the attribute string slices to verify
    // if the given `tokenId_` is a naked monkey.
    function isNaked(uint256 tokenId_) external view returns(bool) {
        bytes memory attrs = bytes(IOnChainMonkey(_ocm).getAttributes(tokenId_));

        bytes1 hat = bytes1(attrs.slice(0, 1));
        bytes1 clothes = bytes1(attrs.slice(6, 7));

        // if fur is a double digit trait
        if(clothes == bytes1(0x20)) clothes = bytes1(attrs.slice(7, 8));
        
        return hat == bytes1(0x30) && clothes == bytes1(0x30);
    }
}