//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Signature {
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

    struct Order {
        Person from;
        Person to;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant PERSON_TYPEHASH = keccak256(
        "Person(string name,address wallet)"
    );

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(Person from,Person to)Person(string name,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor () {
        DOMAIN_SEPARATOR = hash1(EIP712Domain({
            name: "Bitsliced",
            version: '1',
            chainId: 5,
            verifyingContract: address(this)
        }));
    }

    function hash1(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash2(Person memory person) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PERSON_TYPEHASH,
            keccak256(bytes(person.name)),
            person.wallet
        ));
    }

    function hash3(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            hash2(order.from),
            hash2(order.to)
        ));
    }

    function verify(Order memory order, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash3(order)
        ));
        return ecrecover(digest, v, r, s) == order.from.wallet;
    }
}