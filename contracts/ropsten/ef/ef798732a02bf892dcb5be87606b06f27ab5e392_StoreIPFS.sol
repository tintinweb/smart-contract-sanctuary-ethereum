/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract StoreIPFS {

    bytes storeIPFSHash; // store ipfs sha256 hash

   
    function store(bytes memory hash) public {
        storeIPFSHash = hash;
    }

    
    function retrieve() public view returns (bytes memory){
        return storeIPFSHash;
    }
}