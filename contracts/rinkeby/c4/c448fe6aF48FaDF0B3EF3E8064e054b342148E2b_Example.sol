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

    struct Person {
        string name;
        address wallet;
    }

    struct Mail {
        Person from;
        Person to;
        string contents;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant PERSON_TYPEHASH =
        keccak256("Person(string name,address wallet)");

    bytes32 constant MAIL_TYPEHASH =
        keccak256(
            "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
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

    function hash(Person memory person) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERSON_TYPEHASH,
                    keccak256(bytes(person.name)),
                    person.wallet
                )
            );
    }

    function hash(Mail memory mail) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAIL_TYPEHASH,
                    hash(mail.from),
                    hash(mail.to),
                    keccak256(bytes(mail.contents))
                )
            );
    }

    function verify(Mail memory mail, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(mail))
        );
        return ecrecover(digest, v, r, s) == mail.from.wallet;
    }

    function VerifyMessage(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        // Example signed message
        Mail memory mail_ = Mail({
            from: Person({
               name: "Jimmy1",
               wallet: 0xE3aB08aA64a335c5a36b01e064cd5635745771AC
            }),
            to: Person({
                name: "Jimmy2",
                wallet: 0x001ABBc0661aE1590A7dda452B46763c60136e70
            }),
            contents: "Hello"
        });
        assert(verify(mail_, v, r, s));
        return true;
    }
}