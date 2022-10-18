// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Data stored per-account.
struct AccountData {
    uint80 id;
    address recovery;
}

/// @notice Interface for the account registry.
interface IAccountRegistry {
    function resolveId(address subject) external view returns (uint80 id);
    function createAccount(address subject) external returns (uint80 id);
}

/// @notice Account registry that allows an address to create/claim their account
contract AccountRegistry is IAccountRegistry {
    // ---
    // Events
    // ---

    /// @notice A new account was created
    event AccountCreated(
        uint80 indexed id,
        address indexed subject,
        address recovery
    );

    // ---
    // Errors
    // ---

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists();

    /// @notice Recovery address cannot be provided if msg.sender is not the
    /// account address
    error InvalidRegistration();

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint80 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => AccountData) public accounts;

    // ---
    // Account functionality
    // ---

    /// @notice Create an account with no recovery address.
    function createAccount(address subject) external returns (uint80 id) {
        id = _createAccount(subject, address(0));
    }

    /// @notice Create a new account with a recovery address. Can only be called
    /// if subject is msg.sender
    function createAccountWithRecovery(address subject, address recovery)
        external
        returns (uint80 id)
    {
        if (msg.sender != subject) revert InvalidRegistration();
        id = _createAccount(subject, recovery);
    }

    /// @notice Internal create logic
    function _createAccount(address subject, address recovery)
        internal
        returns (uint80 id)
    {
        if (accounts[subject].id != 0) revert AccountAlreadyExists();
        id = ++totalAccountCount;
        accounts[subject] = AccountData({id: id, recovery: recovery});
        emit AccountCreated(id, subject, recovery);
    }

    // ---
    // Views
    // ---

    /// @notice Determine the account ID for an address.
    function resolveId(address subject) external view returns (uint80 id) {
        id = accounts[subject].id;
    }
}