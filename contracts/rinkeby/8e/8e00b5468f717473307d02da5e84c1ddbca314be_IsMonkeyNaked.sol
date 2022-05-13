// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BytesUtils.sol";
import "./IOnChainMonkey.sol";

// @author mande.eth
// @notice Verify if a monkey is naked (clothes = hat = earrings = 0).
contract IsMonkeyNaked {
    // adding the .slice() method on bytes
    using BytesUtils for bytes;

    // OCM contract address    
    address immutable _ocm;

    constructor(address ocm_){
        _ocm = ocm_;
    }

    // @dev compares slices of the attribute string to verify
    // if the given `tokenId_` is a naked monkey.
    function isNaked(uint256 tokenId_) external view returns(bool) {
        bytes memory attrs = bytes(IOnChainMonkey(_ocm).getAttributes(tokenId_));

        bytes1 hat = bytes1(attrs.slice(0, 1));
        bytes1 clothes = bytes1(attrs.slice(6, 7));
        bytes1 earrings = bytes1(attrs.slice(12, 13));

        // if there is one double digit trait before
        if(clothes == bytes1(0x20)) clothes = bytes1(attrs.slice(7, 8));
        if(earrings == bytes1(0x20)) earrings = bytes1(attrs.slice(13, 14));

        // if there is two double digit trait before
        if(earrings == bytes1(0x2c)) earrings = bytes1(attrs.slice(14, 15));
        
        return (hat | clothes | earrings) == bytes1(0x30);
    }
}