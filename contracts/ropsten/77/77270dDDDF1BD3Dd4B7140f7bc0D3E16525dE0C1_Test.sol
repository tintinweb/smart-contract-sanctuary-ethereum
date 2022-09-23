/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Test {
    bytes32 public bytesF1;
    bytes32 public bytesF2;

    function test1() public {
        address vAddress = 0x5f0Ff52DF8df2c5351c47b6711C33f36C5402909;
        string memory name = "test";
        string memory version = "v1";
        uint256 chainId = 1;

        bytesF1 = keccak256(
            abi.encode(
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                vAddress
            )
        );
    }

    function test2() public {
        address vAddress = 0x5f0Ff52DF8df2c5351c47b6711C33f36C5402909;
        string memory name = "test";
        string memory version = "v1";
        uint256 chainId = 1;

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 0x20), mload(name))
            let versionHash := keccak256(add(version, 0x20), mload(version))

            // Load free memory pointer
            let mem := mload(0x40)

            // Store params in memory
            mstore(mem, nameHash)
            mstore(add(mem, 0x20), versionHash)
            mstore(add(mem, 0x40), chainId)
            mstore(add(mem, 0x60), vAddress)

            // Compute hash
            sstore(bytesF2.slot, keccak256(mem, 0x80))
        }
    }
}