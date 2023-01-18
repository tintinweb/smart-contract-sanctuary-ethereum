// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract MevWalletV1Factory {
    error CreationFailed(); // 0xd786d393
    error InitFailed(bytes); // 0x225d0a58

    // 0x0070c3b37cbd33a8f91033a749a5e534a86edc8c2a4c6155b9c53e99ffd59437
    event Proxy(address);

    function createWallet(bytes32 salt, address owner) public returns (address) {
        // we commit to the owner so that deployment txns cannot be frontrun
        // (or rather, a frontrun will create _exactly_ the same) state
        salt = keccak256(abi.encode(salt, owner));
        address p;
        assembly {
            let buf := mload(0x40)
            mstore(buf, 0x3d602880600a3d3981f3363d3d373d3d3d363d6e4096437C84E1B0927D5ED44F)
            mstore(add(buf, 0x20), 0x45F6b35af43d82803e903d91602657fd5bf30000000000000000000000000000)

            p := create2(0, buf, 0x32, salt)
        }
        if (p == address(0)) revert CreationFailed();

        bytes memory data = abi.encodeWithSignature("initialize(address)", [owner]);
        bool s;
        (s, data) = p.call(data);
        if (!s) revert InitFailed(data);
        emit Proxy(p);
        return p;
    }

    function createWallet(bytes32 salt) public returns (address) {
        return createWallet(salt, msg.sender);
    }
}

// 3d602d80600a3d3981f3363d3d373d3d3d363d
// 63 4096437C84E1B0927D5ED44F 45F6b3
// 5af43d82803e903d91602b57fd5bf3