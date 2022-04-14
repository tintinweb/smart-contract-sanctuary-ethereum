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

    struct Mail {
        string contents;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant MAIL_TYPEHASH =
        keccak256(
            "Mail(string contents)"
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

    function hash(Mail memory mail) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAIL_TYPEHASH,
                    keccak256(bytes(mail.contents))
                )
            );
    }

    function verify(Mail memory mail, uint8 v, bytes32 r, bytes32 s) internal view returns (address) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(mail))
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
        Mail memory mail_ = Mail({
            contents: "Hello"
        });
        return verify(mail_, v, r, s);
    }
}