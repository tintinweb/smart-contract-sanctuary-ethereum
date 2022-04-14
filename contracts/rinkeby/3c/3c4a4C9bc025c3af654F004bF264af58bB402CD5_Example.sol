// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Verify account ownership
contract Example {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant CONTENTS_TYPEHASH =
        keccak256(
            "string contents"
        );

    bytes32 DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = hash(
            EIP712Domain({
                name: "EIP712_TEST",
                version: "1",
                chainId: 1,
                verifyingContract: address(this)
            })
        );
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hash(string memory contents) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CONTENTS_TYPEHASH,
                    keccak256(bytes(contents))
                )
            );
    }

    function verify(string memory contents, uint8 v, bytes32 r, bytes32 s) internal view returns (address) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(contents))
        );
        address signer = ecrecover(digest, v, r, s);
        return signer;
    }

    function VerifyMessage(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address) {
        // Example signed message
        string memory contents = "Hello";
        return verify(contents, v, r, s);
    }
}