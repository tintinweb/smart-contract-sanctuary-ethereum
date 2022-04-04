// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract AgreementRegistry {
    mapping(bytes32 => mapping(address => Signature)) public agreements;

    function signDoc(
        bytes32 documentHash,
        uint8 sign_v,
        bytes32 sign_r,
        bytes32 sign_s
    ) public {
        // signature verification
        require(ecrecover(documentHash, sign_v, sign_r, sign_s) == msg.sender);

        agreements[documentHash][msg.sender] = Signature(
            sign_v,
            sign_r,
            sign_s
        );
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}