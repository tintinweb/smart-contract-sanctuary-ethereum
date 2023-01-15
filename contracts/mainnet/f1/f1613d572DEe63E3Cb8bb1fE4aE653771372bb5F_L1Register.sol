// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import "../RegisterHandler.sol";

contract L1Register is RegisterHandler {
    // Get credential public key from a user's address
    mapping(address => bytes) public userPubkey;
    // Is a public key registered
    mapping(bytes => bool) public isPubkeyRegistered;

    function _register(Account memory _account) internal override {
        userPubkey[_account.owner] = _account.publicKey;
        isPubkeyRegistered[_account.publicKey] = true;
        emit PublicKey(_account.owner, _account.publicKey);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IRegisterHandler {
    event PublicKey(address indexed owner, bytes key);

    struct Account {
        address owner;
        bytes publicKey;
    }

    function register(Account memory account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { IRegisterHandler } from "./interfaces/IRegisterHandler.sol";

contract RegisterHandler is IRegisterHandler {
    function register(Account memory _account) public override {
        require(_account.owner == msg.sender, "only owner can be registered");
        _register(_account);
    }

    function _register(Account memory _account) internal virtual {
        emit PublicKey(_account.owner, _account.publicKey);
    }
}