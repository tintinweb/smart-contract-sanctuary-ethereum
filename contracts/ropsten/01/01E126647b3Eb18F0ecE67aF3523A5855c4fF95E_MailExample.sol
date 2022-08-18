/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

contract MailExample {
    
    struct EIP712Domain {
        string  name;
        string  version;
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

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant PERSON_TYPEHASH = keccak256(
        "Person(string name,address wallet)"
    );

    bytes32 constant MAIL_TYPEHASH = keccak256(
        "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor () {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Ether Mail",
            version: '1',
            chainId: 3,
            verifyingContract: 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC
        }));
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }


    function hash(Person memory person) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PERSON_TYPEHASH,
            keccak256(bytes(person.name)),
            person.wallet
        ));
    }

    function hash(Mail memory mail) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAIL_TYPEHASH,
            hash(mail.from),
            hash(mail.to),
            keccak256(bytes(mail.contents))
        ));
    }

    
    function verifyMail(string memory fromName, address fromAddress, string memory toName, address toAddress, string memory content, bytes memory signMsg) external view returns (address){
        Mail memory mail = Mail({
            from: Person({
               name: fromName,
               wallet: fromAddress
            }),
            to: Person({
                name: toName,
                wallet: toAddress
            }),
            contents: content
        });

        (uint8 v, bytes32 r, bytes32 s) = convertSign(signMsg);   

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(mail)
        ));
        return ecrecover(digest, v, r, s);
    }

    function verifyMsg(string memory message, bytes memory signMsg) external pure returns (address) {
        string memory prefix = "\x19Ethereum Signed Message:\n";
        uint256 length = bytes(message).length;
        string memory lenStr = toString(length);
        string memory finalPrefix = strConcat(prefix, lenStr);

        bytes32 digest = keccak256(bytes(strConcat(finalPrefix, message)));

        (uint8 v, bytes32 r, bytes32 s) = convertSign(signMsg);
        return ecrecover(digest, v, r, s);
    }

    function convertSign(bytes memory message) internal pure returns (uint8, bytes32, bytes32) {
        bytes memory r = new bytes(32);
        bytes memory s = new bytes(32);
        bytes memory v = new bytes(1);
        for(uint i=0; i<message.length; i++) {
            if(i < 32) {
                r[i] = message[i];
            } else if (i < 64) {
                s[i-32] = message[i]; 
            } else if (i == 64) {
                v[0] = message[i];
            }
        }
        return (uint8(bytes1(v)), bytes32(r), bytes32(s));
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bret = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        }
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        }
        return string(bret);
   } 

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}