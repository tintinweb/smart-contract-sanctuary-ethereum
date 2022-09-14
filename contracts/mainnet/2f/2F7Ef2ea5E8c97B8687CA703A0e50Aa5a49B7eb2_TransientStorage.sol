/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





contract TransientStorage {
    mapping (string => bytes32) public tempStore;

    /// @notice Set a bytes32 value by a string key
    /// @dev Anyone can add a value because it's only used per tx
    function setBytes32(string memory _key, bytes32 _value) public {
        tempStore[_key] = _value;
    }


    /// @dev Can't enforce per tx usage so caller must be careful reading the value
    function getBytes32(string memory _key) public view returns (bytes32) {
        return tempStore[_key];
    }
}