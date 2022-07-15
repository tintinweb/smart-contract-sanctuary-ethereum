/// SPDX-License-Identifier: MPL-2.0

pragma solidity =0.8.15;

/// @title SecureRpcProvvider
/// @author Manifold Finance, Inc
/// @custom:security <[email protected]>
contract SecureRpcProvider {

   /// @return timestamp
   function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    
    /// @return blockGaslimit
    function blockGaslimit() external view returns (uint256) {
        return block.gaslimit;
    }
    /// @return blockNumber
    function blockNumber() external view returns (uint256) {
        return block.number;
    }

    /// @return block.timestamp
    function blockTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
    
    
    function isSecureRpcProvider() external view returns (bool) {
        return false;
    }

    /// @return current block timestamp
    function getBlockTimeStamp() external view returns (uint256) {
        return block.timestamp;
    }
    

    /// @return chainId
    function getChainId() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}