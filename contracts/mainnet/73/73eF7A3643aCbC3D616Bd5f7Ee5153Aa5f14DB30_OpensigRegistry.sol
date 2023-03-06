/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title Opensig Registry
 * @author Bubble Protocol
 *
 * EVM version of the OpenSig blockchain registry.  Signatures can be registered once.
 */
contract OpensigRegistry {

    /**
     * @dev emitted each time a new published signature is registered.
     */
    event Signature(uint256 time, address indexed signer, bytes32 indexed signature, bytes data);

    /**
     * @dev registry of published signatures.
     */
    mapping (bytes32 => bool) private signatures;
    
    /**
     * @dev Registers the given signature and emits it along with the block timestamp and given data.
     */
    function registerSignature(bytes32 sig_, bytes memory data_) public {
        require(!signatures[sig_], "signature already published");
        signatures[sig_] = true;
        emit Signature(block.timestamp, msg.sender, sig_, data_);
    }

    /**
     * @dev Returns true if the given signature has already been registered
     */
    function isRegistered(bytes32 sig_) public view returns (bool) {
        return signatures[sig_];
    }
    
}