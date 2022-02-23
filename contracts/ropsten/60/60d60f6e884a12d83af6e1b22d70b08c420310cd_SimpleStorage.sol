/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract SimpleStorage {
    string public constant name = "SimpleStorage";

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant MESSAGE_HASH =
    keccak256("Data(address sender, uint value)");

    uint256 storedData;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId
            )
        );
    }

    function checkPermitRecoverAddress(
        address sender,
        uint256 value,
        bytes memory sig
    ) public view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MESSAGE_HASH, sender, value))
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress;
    }
}