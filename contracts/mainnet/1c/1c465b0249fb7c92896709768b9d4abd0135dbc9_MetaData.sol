/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/metadata.sol
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.7 <0.9.0;

////// src/metadata.sol
/* pragma solidity ^0.8.7; */

contract MetaData {
    bytes32 public constant DEFAULT_ID = "";

    // correct multiHash construction see https://github.com/multiformats/multihash
    // 0-1  bytes:  hashFunction
    // 1-2  bytes:  size
    // 2-34 bytes:  hash (in most cases 32 bytes but not guranteed)
    event MultiHash(address indexed addr, bytes32 indexed id, bytes multiHash);

    /// @notice publish an IPFS hash as an event
    /// @param multiHash as bytes array
    function publish(bytes calldata multiHash) external {
        emit MultiHash(msg.sender, DEFAULT_ID, multiHash);
    }

    /// @notice publish an IPFS hash as an event with an id
    /// @param multiHash as bytes array
    /// @param id identifier for the multiHash
    function publish(bytes32 id, bytes calldata multiHash) external {
        emit MultiHash(msg.sender, id, multiHash);
    }
}