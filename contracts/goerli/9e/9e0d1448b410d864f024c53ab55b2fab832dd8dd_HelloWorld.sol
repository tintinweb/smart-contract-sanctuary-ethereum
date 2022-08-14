/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// My First Smart Contract 
// SPDX-License-Identifier: Test
pragma solidity ^0.8.0;

contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
    function VerifyMessage(bytes32 _hashedMessage, bytes32 _domain, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
	  bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                _domain,
                _hashedMessage
            )
        );
        address signer = ecrecover(digest, _v, _r, _s);
        return signer;
    }
}