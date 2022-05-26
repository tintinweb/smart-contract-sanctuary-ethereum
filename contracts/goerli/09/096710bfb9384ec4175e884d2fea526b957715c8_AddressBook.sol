/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title An interface for a contract that is capable of deploying Address Books
/// @notice A contract that constructs an address book must implement this to pass arguments to the address book
/// Heavily inspired by IUniswapV3PoolDeployer.sol
/// @dev This is used to avoid having constructor arguments in the address book contract, which results in the init code hash
/// of the address book being constant allowing the CREATE2 address of the address book to be cheaply computed on-chain
/// @author Vincenzo Ferrara (vinceferro)
interface IAddressBookDeployer {
    /// @notice Get the parameters to be used in constructing the address book, set transiently during creation.
    /// @dev Called by the address book constructor to fetch the parameters of the address book
    /// @return owner The owner of the address book
    function parameters() external view returns (address owner);
}error EntryNotFound();

/// @title An interface for an address book contract
/// @author Vincenzo Ferrara (vinceferro)
interface IAddressBook {
    enum Tipology {
        EOA,
        CONTRACT
    }

    struct Entry {
        string name;
        Tipology tipology;
        address entryAddress;
        string[] labels;
    }

    event EntryAdded(
        address indexed addressBook,
        uint256 indexed index,
        Entry entry
    );

    event EntryUpdated(
        address indexed addressBook,
        uint256 indexed index,
        Entry entry
    );

    event EntryDeleted(
        address indexed addressBook,
        uint256 indexed index,
        Entry entry
    );

    /// @notice Get the entries in the address book
    /// @return entries The entries in the address book
    function getEntries() external view returns (Entry[] memory entries);

    /// @notice Get a single entry
    /// @param index The index of the entry to get
    /// @return entry The entry at the index in the address book
    function getEntry(uint256 index) external view returns (Entry memory entry);

    /// @notice Add an entry to the address book
    /// @param name The name of the entry
    /// @param tipology The tipology of the entry
    /// @param entryAddress The address of the entry
    /// @param labels The labels of the entry
    /// @return entry The entry that was added
    function addEntry(
        string calldata name,
        Tipology tipology,
        address entryAddress,
        string[] calldata labels
    ) external returns (Entry memory);

    /// @notice Add multiple entries to the address book
    /// @param names The names of the entries
    /// @param tipologies The tipologies of the entries
    /// @param entryAddresses The addresses of the entries
    /// @param labels The labels of the entries
    /// @return entries The entries that were added
    function addEntries(
        string[] calldata names,
        Tipology[] calldata tipologies,
        address[] calldata entryAddresses,
        string[][] calldata labels
    ) external returns (Entry[] memory);

    /// @notice Update an entry in the address book
    /// @param index The index of the entry to update
    /// @param name The name of the entry
    /// @param tipology The tipology of the entry
    /// @param entryAddress The address of the entry
    /// @param labels The labels of the entry
    /// @return entry The entry that was updated
    function updateEntry(
        uint256 index,
        string calldata name,
        Tipology tipology,
        address entryAddress,
        string[] calldata labels
    ) external returns (Entry memory);

    /// @notice Delete an entry from the address book
    /// @param index The index of the entry to delete
    /// @return entry The entry that was deleted
    function deleteEntry(uint256 index) external returns (Entry memory);
}error OnlyOwnerAccess();

/// @title An abstract contract for ownable contracts with an immutable owner
/// @author Vincenzo Ferrara (vinceferro)
abstract contract StrictOwnable {
    /// @notice owner of the specific address book
    address public owner;

    /// @notice modifiers that allow access only to the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerAccess();
        }
        _;
    }
}
/// @title Address Book contract to manage a list of addresses
/// @author Vincenzo Ferrara (vinceferro)
contract AddressBook is IAddressBook, StrictOwnable {
    Entry[] public entries;

    constructor() {
        (owner) = IAddressBookDeployer(msg.sender).parameters();
    }

    /// @inheritdoc IAddressBook
    function getEntries() external view override returns (Entry[] memory) {
        return entries;
    }

    /// @inheritdoc IAddressBook
    function getEntry(uint256 index)
        external
        view
        override
        returns (Entry memory)
    {
        return entries[index];
    }

    /// @inheritdoc IAddressBook
    function addEntry(
        string calldata name,
        Tipology tipology,
        address entryAddress,
        string[] calldata labels
    ) external override onlyOwner returns (Entry memory) {
        return _addEntry(name, tipology, entryAddress, labels);
    }

    /// @inheritdoc IAddressBook
    function addEntries(
        string[] calldata names,
        Tipology[] calldata tipologies,
        address[] calldata entryAddresses,
        string[][] calldata labels
    ) external override onlyOwner returns (Entry[] memory newEntries) {
        newEntries = new Entry[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            newEntries[i] = _addEntry(
                names[i],
                tipologies[i],
                entryAddresses[i],
                labels[i]
            );
        }
    }

    function _addEntry(
        string memory name,
        Tipology tipology,
        address entryAddress,
        string[] memory labels
    ) internal returns (Entry memory entry) {
        entry.name = name;
        entry.tipology = tipology;
        entry.entryAddress = entryAddress;
        entry.labels = labels;
        entries.push(entry);

        emit EntryAdded(address(this), entries.length - 1, entry);
    }

    /// @inheritdoc IAddressBook
    function updateEntry(
        uint256 index,
        string calldata name,
        Tipology tipology,
        address entryAddress,
        string[] calldata labels
    ) external override onlyOwner returns (Entry memory) {
        if (index >= entries.length) {
            revert EntryNotFound();
        }
        return _updateEntry(index, name, tipology, entryAddress, labels);
    }

    function _updateEntry(
        uint256 index,
        string memory name,
        Tipology tipology,
        address entryAddress,
        string[] memory labels
    ) internal returns (Entry memory) {
        Entry storage entry = entries[index];
        entry.name = name;
        entry.tipology = tipology;
        entry.entryAddress = entryAddress;
        entry.labels = labels;

        emit EntryUpdated(address(this), index, entry);
        return entry;
    }

    /// @inheritdoc IAddressBook
    function deleteEntry(uint256 index)
        external
        override
        onlyOwner
        returns (Entry memory)
    {
        if (index >= entries.length) {
            revert EntryNotFound();
        }
        return _deleteEntry(index);
    }

    function _deleteEntry(uint256 index) internal returns (Entry memory entry) {
        entry = entries[index];
        uint256 lastIndex = entries.length - 1;
        if (index != lastIndex) {
            entries[index] = entries[lastIndex];
        }
        delete entries[lastIndex];

        emit EntryDeleted(address(this), index, entry);
    }
}