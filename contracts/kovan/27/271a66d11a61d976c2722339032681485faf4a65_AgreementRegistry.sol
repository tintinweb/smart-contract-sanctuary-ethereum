// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract AgreementRegistry {
    event Signature(
        bytes32 indexed documentHash,
        address indexed pubKey,
        uint8 sign_v,
        bytes32 sign_r,
        bytes32 sign_s
    );

    function signDoc(
        bytes32 documentHash,
        uint8 sign_v,
        bytes32 sign_r,
        bytes32 sign_s
    ) public {
        // verification sign on blockchein
        require(ecrecover(documentHash, sign_v, sign_r, sign_s) == msg.sender);

        emit Signature(documentHash, msg.sender, sign_v, sign_r, sign_s);
    }
}