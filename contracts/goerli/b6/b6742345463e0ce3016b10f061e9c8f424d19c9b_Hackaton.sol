/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hackaton {

    bytes32 private stateHash;

    event DataAdded(bytes data);
    
    function addData(bytes memory data) public {
        stateHash = keccak256(bytes.concat(stateHash, data));
        emit DataAdded(data);
    }

    function doSomethingCool(bytes32  hash) public {
        require(hash == stateHash, "You can not do something cool because your hash is invalid");

        // Do something cool
    }

    // Only for debugging
    function read() external view returns (bytes32) {
        return stateHash;
    }
}