// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {IAccountRegistry, AccountData} from "./interfaces/IAccountRegistry.sol";

/// @notice The account registry manages mappings from an address to an account
/// ID.
/// - Accounts are identified by a uint64 ID
/// - Accounts are owned by an address
/// - Accounts can be recovered by a recovery address
/// - Accounts can broadcast arbitrary strings, keyed by a topic, as blockchain events
contract AccountRegistry is IAccountRegistry, Owned {
    // ---
    // Events
    // ---

    /// @notice A new account was created
    event AccountCreated(
        uint64 indexed id,
        address indexed subject,
        address recovery,
        string metadata
    );

    /// @notice Broadcast a message from an account
    event AccountBroadcast(uint64 indexed id, string topic, string message);

    /// @notice An account's address has changed
    event AccountTransfered(uint64 indexed id, address newOwner);

    /// @notice An account's recovery address has changed
    event AccountRecoverySet(uint64 indexed id, address newRecoveryAddress);

    /// @notice A new address has be authorized or un-authorized to issue accounts
    event AccountIssuerSet(address indexed issuer, bool authorized);

    // ---
    // Errors
    // ---

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists();

    /// @notice Recovery address cannot be provided if msg.sender is not the
    /// account address
    error InvalidRegistration();

    /// @notice Recovery was attempted from an invalid address
    error InvalidRecovery();

    /// @notice No account exists for msg.sender
    error NoAccount();

    /// @notice Account issuance is not yet public and a non-issuer attempted to
    /// create an account.
    error NotAuthorizedAccountIssuer();

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint64 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => AccountData) public accounts;

    /// @notice Mapping from an address to a boolean indicating whether it is
    /// authorized to issue accounts.
    mapping(address => bool) public isAccountIssuer;

    // ---
    // Constructor
    // ---

    constructor(address _contractOwner) Owned(_contractOwner) {}

    // ---
    // Owner functionality
    // ---

    /// @notice Authorize or unauthorize an address to issue accounts
    function setAccountIssuer(address issuer, bool authorized)
        external
        onlyOwner
    {
        isAccountIssuer[issuer] = authorized;
        emit AccountIssuerSet(issuer, authorized);
    }

    // ---
    // Account creation functionality
    // ---

    /// @notice Permissionlessly create an account with no recovery address.
    /// msg.sender can be any address. Subject must not yet have an account
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id)
    {
        id = _createAccount(subject, address(0), metadata);
    }

    /// @notice Create a new account with a recovery address. Can only be called
    /// if subject is msg.sender
    function createAccountWithRecovery(
        address subject,
        address recovery,
        string calldata metadata
    ) external returns (uint64 id) {
        if (msg.sender != subject) revert InvalidRegistration();

        id = _createAccount(subject, recovery, metadata);
    }

    /// @notice Internal create logic
    function _createAccount(
        address subject,
        address recovery,
        string memory metadata
    ) internal returns (uint64 id) {
        if (accounts[subject].id != 0) revert AccountAlreadyExists();
        if (owner != address(0) && !isAccountIssuer[msg.sender]) {
            revert NotAuthorizedAccountIssuer();
        }

        id = ++totalAccountCount;
        accounts[subject] = AccountData({id: id, recovery: recovery});
        emit AccountCreated(id, subject, recovery, metadata);
    }

    // ---
    // Account functionality
    // ---

    /// @notice Broadcast a message as an account.
    function broadcast(string calldata topic, string calldata message)
        external
    {
        uint64 id = accounts[msg.sender].id;
        if (id == 0) revert NoAccount();

        emit AccountBroadcast(id, topic, message);
    }

    /// @notice Transfer the account to another address. Other address must not
    /// have an account, and msg.sender must currently own the account
    function transferAccount(address newOwner) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[msg.sender];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Transfer the account to another address as the recovery address.
    /// New address must not have an account, and msg.sender must be the
    /// account's recovery address
    function recoverAccount(address oldOwner, address newOwner) external {
        AccountData memory maccount = accounts[oldOwner];
        if (maccount.recovery != msg.sender) revert InvalidRecovery();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[oldOwner];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Set the recovery address for an account. msg.sender must be the
    /// account owner
    function setRecovery(address recovery) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();

        accounts[msg.sender].recovery = recovery;
        emit AccountRecoverySet(maccount.id, recovery);
    }

    // ---
    // Views
    // ---

    /// @notice Get the account ID for an address.
    function resolveId(address subject) external view returns (uint64 id) {
        id = accounts[subject].id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored per account.
struct AccountData {
    uint64 id;
    address recovery;
}

/// @notice The account registry manages mappings from an address to an account
/// ID.
interface IAccountRegistry {
    /// @notice Permissionlessly create an account with no recovery address.
    /// msg.sender can be any address. Subject must not yet have an account
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id);

    /// @notice Get the account ID for an address.
    function resolveId(address subject) external view returns (uint64 id);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}