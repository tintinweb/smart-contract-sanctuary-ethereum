// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice The account registry manages mappings from an address to an account
/// ID.
interface IAccountRegistry {
    /// @notice Permissionlessly create a new account for the subject address.
    /// Subject must not yet have an account
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id);

    /// @notice Get the account ID for an address.
    function resolveId(address subject) external view returns (uint64 id);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAccountRegistry} from "./interfaces/IAccountRegistry.sol";

/// @notice Basic contract that allows creating a new account and registering an
/// exclusive username
/// - Serves as a frontend contract to AccountRegistry to issue names with accounts
/// - Potentially replaced with something more robust in the future, this is a
///     decent way of getting started with issuing usernames while Metalabel is
///     still gated
contract SimpleNameAuthority {
    // ---
    // Errors
    // ---

    /// @notice A name was already used.
    error NameAlreadyExists();

    /// @notice Invalid msg.sender for operation.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new name mapping was created.
    event NameRegistered(string name, uint64 id);

    // ---
    // Storage
    // ---

    /// @notice Mapping from name to account ID.
    mapping(string => uint64) public names;

    /// @notice The account registry.
    IAccountRegistry immutable accounts;

    // ---
    // Constructor
    // ---

    constructor(IAccountRegistry _accounts) {
        accounts = _accounts;
    }

    // ---
    // Name functionality
    // ---

    /// @notice Create a new account and register a name for it.
    function createAccountWithName(
        string calldata name,
        string calldata metadata
    ) external returns (uint64 id) {
        id = accounts.createAccount(msg.sender, metadata);
        _registerName(name, id);
    }

    /// @notice Change the existing name mapping for an account. Only callable
    /// by the account owner.
    function changeName(string calldata oldName, string calldata newName)
        external
    {
        uint64 id = accounts.resolveId(msg.sender);
        if (names[oldName] != id) revert NotAuthorized();
        delete names[oldName];
        _registerName(newName, id);
    }

    /// @notice Register name internal implementation.
    function _registerName(string calldata name, uint64 id) internal {
        if (names[name] != 0) revert NameAlreadyExists();
        names[name] = id;
        emit NameRegistered(name, id);
    }
}