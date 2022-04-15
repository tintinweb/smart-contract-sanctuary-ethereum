// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Example {

    function executeSetIfSignatureMatch(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address sender,
        uint256 deadline,
        uint256 x
    ) internal view returns (address) {
        require(block.timestamp < deadline, "Signed transaction expired");

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SetTest")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("set(address sender,uint x,uint deadline)"),
                sender,
                x,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        require(signer == sender, "MyFunction: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }
}