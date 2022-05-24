// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IAddressBookFactory.sol";
import "./AddressBookDeployer.sol";

error SubscriptionNotFound();
error OutOfBounds();

/// @title Subscriptions
/// @dev TBD if to keep it this way or to use address book entries to store subscriptions
/// @author Vincenzo Ferrara (vinceferro)
contract Subscriptions {
    constructor() {}

    mapping(address => address[]) public subscriptions;

    event Subscribed(address indexed subscriber, address indexed book);
    event Unsubscribed(address indexed subscriber, address indexed book);

    /// @notice Subscribes a subscriber to an address book
    /// @dev reverts if the subscription to the address book already exists
    /// @param book The address of the address book to subscribe to
    function subscribe(address book) external {
        (, bool found) = _indexOf(book);
        if (found) {
            revert SubscriptionNotFound();
        }
        subscriptions[msg.sender].push(book);

        emit Subscribed(msg.sender, book);
    }

    /// @notice Unsubscribes a subscriber from an address book
    /// @dev reverts if the subscription to the address book does not exist
    /// @param book The address of the address book to unsubscribe from
    function unsubscribe(address book) external {
        (uint256 index, bool found) = _indexOf(book);
        if (!found) {
            revert SubscriptionNotFound();
        }
        _deleteEntry(index);

        emit Unsubscribed(msg.sender, book);
    }

    /// @notice Returns the index of the given address book in the subscriptions array
    /// @param book The address of the address book to search for
    /// @return index The index of the address book in the subscriptions array
    /// @return found Whether the address book was found
    function _indexOf(address book) public view returns (uint256, bool) {
        for (uint256 i = 0; i < subscriptions[msg.sender].length; i++) {
            if (subscriptions[msg.sender][i] == book) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /// @notice Deletes the entry at the given index in the subscriptions array
    /// @dev reverts if the index is invalid
    /// @param index The index of the entry to delete
    function _deleteEntry(uint256 index) internal {
        if (index >= subscriptions[msg.sender].length) {
            revert OutOfBounds();
        }
        uint256 lastIndex = subscriptions[msg.sender].length - 1;
        if (index != lastIndex) {
            subscriptions[msg.sender][index] = subscriptions[msg.sender][
                lastIndex
            ];
        }
        delete subscriptions[msg.sender][lastIndex];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title The interface for the Address Book Factory
/// @notice The Address Book Factory facilitates creation of Address Books
/// Heavily inspired by IUniswapV3Factory.sol
/// @author Vincenzo Ferrara (vinceferro)
interface IAddressBookFactory {
    /// @notice Emitted when an address book is created
    /// @param owner The owner of the address book
    /// @param index The index of the address book
    /// @param book The address of the address book
    event AddressBookCreated(
        address indexed owner,
        uint256 indexed index,
        address book
    );

    /// @notice Creates a new Address Book owned by the message sender
    /// @return book The address of the newly created address book
    function createAddressBook() external returns (address book);

    /// @notice Returns the address book address for a given owner and an index, 0 if it is out of bound
    /// @param owner The address of the owner of the address book
    /// @param index The index of the address book
    function getAddressBook(address owner, uint256 index)
        external
        view
        returns (address book);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IAddressBookDeployer.sol";

import "./AddressBook.sol";

/// @title Address Book Deployer
/// @author Vincenzo Ferrara (vinceferro)
contract AddressBookDeployer is IAddressBookDeployer {
    struct Parameters {
        address owner;
    }

    /// @inheritdoc IAddressBookDeployer
    Parameters public override parameters;

    /// @dev Deploys an address book with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the address book.
    /// @param owner The owner of the address book
    /// @param index The index of the address book
    function deploy(address owner, uint256 index)
        internal
        returns (address book)
    {
        parameters = Parameters({owner: owner});
        book = address(
            new AddressBook{salt: keccak256(abi.encode(owner, index))}()
        );
        delete parameters;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IAddressBookDeployer.sol";
import "./interfaces/IAddressBook.sol";
import "./utils/StrictOwnable.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

error EntryNotFound();

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error OnlyOwnerAccess();

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