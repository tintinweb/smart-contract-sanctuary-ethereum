/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;



contract SignatureContract {

    

    uint256 private m;



    function getSignature() public returns (uint256, bytes32, bytes32, bytes32, bytes32) {

        m = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));

        bytes32 hash = keccak256(abi.encodePacked(m));

        bytes32 r1;

        bytes32 s1;

        bytes32 r2;

        bytes32 s2;

        

        assembly {

            let ptr := mload(0x40)

            mstore(ptr, hash)

            let success := call(gas(), 0x01, 0, ptr, 0x20, ptr, 0x40)

            r1 := mload(ptr)

            s1 := mload(add(ptr, 0x20))

        }

        

        assembly {

            let ptr := mload(0x40)

            mstore(ptr, hash)

            let success := call(gas(), 0x01, 0, ptr, 0x20, ptr, 0x40)

            r2 := mload(ptr)

            s2 := mload(add(ptr, 0x20))

        }

        

        return (m, r1, s1, r2, s2);

    }

}