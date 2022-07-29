/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract TokenURIOverride {
    function tokenURI(
        address lockAddress,
        address operator,
        address owner,
        uint256 keyId,
        uint256 expirationTimestamp
    ) external view returns (string memory) {
        return "ipfs://Qmcb6Mn6BxbXJyDdR2QvHrEcwtqrBD5br5xNkdGBCMT7FX";
    }
}