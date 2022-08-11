// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ReentrancyGuard} from "../lib/utils/ReentrancyGuard.sol";
import {ERC721Votes} from "../lib/token/ERC721Votes.sol";

import {TokenStorageV1} from "./storage/TokenStorageV1.sol";
import {MetadataRenderer} from "./metadata/MetadataRenderer.sol";
import {IManager} from "../manager/IManager.sol";
import {IToken} from "./IToken.sol";

/// @title Token
/// @author Rohan Kulkarni
/// @notice This contract is a DAO's ERC-721 token contract
contract Token is UUPS, ReentrancyGuard, ERC721Votes, TokenStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The Builder DAO address
    address public immutable builderDAO;

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    /// @param _builderDAO The address of the Builder DAO Treasury
    constructor(address _manager, address _builderDAO) payable initializer {
        manager = IManager(_manager);
        builderDAO = _builderDAO;
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's ERC-721 token
    /// @param _founders The members of the DAO with scheduled token allocations
    /// @param _initStrings The encoded token and metadata initialization strings
    /// @param _metadataRenderer The token's metadata renderer
    /// @param _auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata _founders,
        bytes calldata _initStrings,
        address _metadataRenderer,
        address _auction
    ) external initializer {
        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Store the vesting schedules of each founder
        _storeFounders(_founders);

        // Decode the token initialization strings
        (string memory _name, string memory _symbol, , , ) = abi.decode(_initStrings, (string, string, string, string, string));

        // Initialize the ERC-721 token
        __ERC721_init(_name, _symbol);

        // Store the associated auction house
        auction = _auction;

        // Store the associated metadata renderer
        metadataRenderer = MetadataRenderer(_metadataRenderer);
    }

    ///                                                          ///
    ///                              MINT                        ///
    ///                                                          ///

    /// @notice Mints tokens to the auction house for bidding and handles vesting to the founders & Builder DAO
    function mint() public nonReentrant returns (uint256 tokenId) {
        // Ensure the caller is the auction house
        require(msg.sender == auction, "ONLY_AUCTION");

        // Cannot realistically overflow
        unchecked {
            do {
                // Get the next available token id
                tokenId = totalSupply++;
            } while (_handleFounderVesting(tokenId));
        }

        // Mint the next token to the auction house for bidding
        _mint(auction, tokenId);

        return tokenId;
    }

    /// @dev Overrides _mint to include attribute generation
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal override {
        // Mint the token
        super._mint(_to, _tokenId);

        // Generate the token attributes
        metadataRenderer.generate(_tokenId);
    }

    ///                                                          ///
    ///                           VESTING                        ///
    ///                                                          ///

    /// @dev Checks if a token is elgible to vest, and mints to the recipient if so
    /// @param _tokenId The ERC-721 token id
    function _handleFounderVesting(uint256 _tokenId) private returns (bool) {
        // If the token is for the Builder DAO:
        if (_isForBuilderDAO(_tokenId)) {
            // Mint the token to the Builder DAO
            _mint(builderDAO, _tokenId);

            return true;
        }

        // Otherwise, cache the number of founders
        uint256 numFounders = founders.length;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Get their vesting details
                Founder memory founder = founders[i];

                // If the token id fits their vesting schedule:
                if (_tokenId % founder.allocationFrequency == 0 && block.timestamp < founder.vestingEnd) {
                    // Mint the token to the founder
                    _mint(founder.wallet, _tokenId);

                    return true;
                }
            }

            return false;
        }
    }

    /// @dev If a token is for the Builder DAO
    /// @param _tokenId The ERC-721 token id
    function _isForBuilderDAO(uint256 _tokenId) private pure returns (bool vest) {
        assembly {
            vest := iszero(mod(add(_tokenId, 1), 100))
        }
    }

    /// @dev Stores the vesting details of the DAO's founders
    /// @param _founders The list of founders provided upon deploy
    function _storeFounders(IManager.FounderParams[] calldata _founders) internal {
        // Cache the number of founders
        uint256 numFounders = _founders.length;

        // Used to store each founder
        Founder storage founder;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Allocate storage space
                founders.push();

                // Get the storage location
                founder = founders[i];

                // Store the given details
                founder.allocationFrequency = uint32(_founders[i].allocationFrequency);
                founder.vestingEnd = uint64(_founders[i].vestingEnd);
                founder.wallet = _founders[i].wallet;
            }
        }
    }

    ///                                                          ///
    ///                             BURN                         ///
    ///                                                          ///

    /// @notice Burns a token that did not see any bids
    /// @param _tokenId The ERC-721 token id
    function burn(uint256 _tokenId) public {
        // Ensure the caller is the auction house
        require(msg.sender == auction, "ONLY_AUCTION");

        // Burn the token
        _burn(_tokenId);
    }

    ///                                                          ///
    ///                              URI                         ///
    ///                                                          ///

    /// @notice The URI for a given token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return metadataRenderer.tokenURI(_tokenId);
    }

    /// @notice The URI for the contract
    function contractURI() public view override returns (string memory) {
        return metadataRenderer.contractURI();
    }

    ///                                                          ///
    ///                             OWNER                        ///
    ///                                                          ///

    /// @notice The shared owner of the token and metadata contracts
    function owner() public view returns (address) {
        return metadataRenderer.owner();
    }

    ///                                                          ///
    ///                        CONTRACT UPGRADE                  ///
    ///                                                          ///

    error ONLY_OWNER();

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The address of the new implementation
    function _authorizeUpgrade(address _newImpl) internal view override {
        // Ensure the caller is the shared owner of the token and metadata renderer
        if (msg.sender != owner()) revert ONLY_OWNER();

        // Ensure the implementation is valid
        if (!manager.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Minimal UUPS proxy modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS {
    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address private immutable __self = address(this);

    event Upgraded(address impl);

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    function _authorizeUpgrade(address _impl) internal virtual;

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address _impl) external onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, "", false);
    }

    function upgradeToAndCall(address _impl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, _data, true);
    }

    function _upgradeToAndCallUUPS(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_impl);
        } else {
            try IERC1822Proxiable(_impl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }

            _upgradeToAndCall(_impl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _impl) internal {
        _setImplementation(_impl);

        emit Upgraded(_impl);
    }

    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_TARGET();

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

/// @notice Modern, efficient, and (optionally) safe Ownable
abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error WRONG_PENDING_OWNER();

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    function __Ownable_init(address _owner) internal onlyInitializing {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(owner, _newOwner);

        owner = _newOwner;
    }

    function safeTransferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;

        emit OwnerPending(owner, _newOwner);
    }

    function cancelOwnershipTransfer(address _pendingOwner) public onlyOwner {
        if (_pendingOwner != pendingOwner) revert WRONG_PENDING_OWNER();

        emit OwnerCanceled(owner, _pendingOwner);

        delete pendingOwner;
    }

    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(owner, msg.sender);

        owner = pendingOwner;

        delete pendingOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract ReentrancyGuardStorageV1 {
    uint256 internal _status;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard is Initializable, ReentrancyGuardStorageV1 {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    error REENTRANCY();

    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert REENTRANCY();

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {EIP712} from "../utils/EIP712.sol";
import {ERC721} from "../token/ERC721.sol";

contract ERC721VotesTypesV1 {
    struct Checkpoint {
        uint64 timestamp;
        uint192 votes;
    }
}

contract ERC721VotesStorageV1 is ERC721VotesTypesV1 {
    mapping(address => uint256) public numCheckpoints;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => address) internal delegation;
}

abstract contract ERC721Votes is EIP712, ERC721, ERC721VotesStorageV1 {
    bytes32 internal constant DELEGATION_TYPEHASH = keccak256("Delegation(address from,address to,uint256 nonce,uint256 deadline)");

    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);

    event DelegateVotesChanged(address indexed delegate, uint256 prevVotes, uint256 newVotes);

    error INVALID_TIMESTAMP();

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        _moveDelegateVotes(_from, _to, 1);

        super._afterTokenTransfer(_from, _to, _tokenId);
    }

    function delegates(address _user) external view returns (address) {
        address current = delegation[_user];

        return current == address(0) ? _user : current;
    }

    function delegate(address _to) external {
        _delegate(msg.sender, _to);
    }

    function delegateBySig(
        address _from,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (block.timestamp > _deadline) revert EXPIRED_SIGNATURE();

        bytes32 digest;

        unchecked {
            digest = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATION_TYPEHASH, _from, _to, nonces[_from]++, _deadline)))
            );
        }

        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        if (recoveredAddress == address(0) || recoveredAddress != _from) revert INVALID_SIGNER();

        _delegate(_from, _to);
    }

    function _delegate(address _from, address _to) internal {
        address prevDelegate = delegation[_from];

        delegation[_from] = _to;

        emit DelegateChanged(_from, prevDelegate, _to);

        _moveDelegateVotes(prevDelegate, _to, balanceOf(_from));
    }

    function _moveDelegateVotes(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        unchecked {
            if (_from != _to && _amount > 0) {
                if (_from != address(0)) {
                    uint256 nCheckpoints = numCheckpoints[_from]++;

                    uint256 prevTotalVotes;

                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_from][nCheckpoints - 1].votes;

                    _writeCheckpoint(_from, nCheckpoints, prevTotalVotes, prevTotalVotes - _amount);
                }

                if (_to != address(0)) {
                    uint256 nCheckpoints = numCheckpoints[_to]++;

                    uint256 prevTotalVotes;

                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_to][nCheckpoints - 1].votes;

                    _writeCheckpoint(_to, nCheckpoints, prevTotalVotes, prevTotalVotes + _amount);
                }
            }
        }
    }

    function _writeCheckpoint(
        address _user,
        uint256 _index,
        uint256 _prevTotalVotes,
        uint256 _newTotalVotes
    ) private {
        Checkpoint storage checkpoint = checkpoints[_user][_index];

        checkpoint.votes = uint192(_newTotalVotes);
        checkpoint.timestamp = uint64(block.timestamp);

        emit DelegateVotesChanged(_user, _prevTotalVotes, _newTotalVotes);
    }

    function getVotes(address _user) public view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[_user];

        unchecked {
            return nCheckpoints != 0 ? checkpoints[_user][nCheckpoints - 1].votes : 0;
        }
    }

    function getPastVotes(address _user, uint256 _timestamp) public view returns (uint256) {
        if (_timestamp >= block.timestamp) revert INVALID_TIMESTAMP();

        uint256 nCheckpoints = numCheckpoints[_user];

        if (nCheckpoints == 0) return 0;

        mapping(uint256 => Checkpoint) storage userCheckpoints = checkpoints[_user];

        unchecked {
            uint256 latestCheckpoint = nCheckpoints - 1;

            if (userCheckpoints[latestCheckpoint].timestamp <= _timestamp) return userCheckpoints[latestCheckpoint].votes;

            if (userCheckpoints[0].timestamp > _timestamp) return 0;

            uint256 high = latestCheckpoint;

            uint256 low;

            uint256 avg;

            Checkpoint memory tempCP;

            while (high > low) {
                avg = (low & high) + (low ^ high) / 2;

                tempCP = userCheckpoints[avg];

                if (tempCP.timestamp == _timestamp) {
                    return tempCP.votes;
                } else if (tempCP.timestamp < _timestamp) {
                    low = avg;
                } else {
                    high = avg - 1;
                }
            }

            return userCheckpoints[low].votes;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {MetadataRenderer} from "../metadata/MetadataRenderer.sol";
import {TokenTypesV1} from "../types/TokenTypesV1.sol";

contract TokenStorageV1 is TokenTypesV1 {
    /// @notice The total number of tokens minted
    uint256 public totalSupply;

    /// @notice The minter of the token
    address public auction;

    /// @notice The metadata renderer of the token
    MetadataRenderer public metadataRenderer;

    /// @notice The founders of the DAO
    Founder[] public founders;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../../lib/proxy/UUPS.sol";
import {Ownable} from "../../lib/utils/Ownable.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {LibUintToString} from "sol2string/contracts/LibUintToString.sol";
import {UriEncode} from "sol-uriencode/src/UriEncode.sol";

import {MetadataRendererStorageV1} from "./storage/MetadataRendererStorageV1.sol";
import {Token} from "../Token.sol";
import {IMetadataRenderer} from "./IMetadataRenderer.sol";
import {IManager} from "../../manager/IManager.sol";

/// @title Metadata Renderer
/// @author Iain Nash & Rohan Kulkarni
/// @notice This contract stores, renders, and determines token artwork
contract MetadataRenderer is IMetadataRenderer, UUPS, Ownable, MetadataRendererStorageV1 {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                          CONSTRUCTOR                     ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                          INITIALIZER                     ///
    ///                                                          ///

    /// @notice Initializes an instance of a DAO's metadata renderer
    /// @param _initStrings The encoded token and metadata initialization strings
    /// @param _token The address of the ERC-721 token
    /// @param _founder The address of the founder responsible for adding
    function initialize(
        bytes calldata _initStrings,
        address _token,
        address _founder,
        address _treasury
    ) external initializer {
        // Decode the token initialization strings
        (string memory _name, , string memory _description, string memory _contractImage, string memory _rendererBase) = abi.decode(
            _initStrings,
            (string, string, string, string, string)
        );

        // Store the renderer config
        name = _name;
        description = _description;
        contractImage = _contractImage;
        rendererBase = _rendererBase;

        // Store the token contract
        token = Token(_token);

        // Store the DAO treasury
        treasury = _treasury;

        // Initialize ownership to the founder
        __Ownable_init(_founder);
    }

    ///                                                          ///
    ///                       ADD PROPERTIES                     ///
    ///                                                          ///

    /// @notice Emitted when a property is added
    /// @param id The id of the added property
    /// @param name The name of the added property
    event PropertyAdded(uint256 id, string name);

    /// @notice Emitted when an item for a property is added
    /// @param propertyId The id of the associated property
    /// @param index The index of the item in its property
    event ItemAdded(uint256 propertyId, uint256 index);

    /// @notice Adds properties and items for generating token attributes upon minting
    /// @param _names The names of the properties to add
    /// @param _items The items to add to each property
    /// @param _ipfsGroup The IPFS base URI and extension
    function addProperties(
        string[] calldata _names,
        ItemParam[] calldata _items,
        IPFSGroup calldata _ipfsGroup
    ) external onlyOwner {
        // Cache the length of the IPFS data array for later reference
        uint256 dataLength = data.length;

        // If this is the first upload:
        if (dataLength == 0) {
            // Transfer following ownership of the contract to the DAO treasury
            transferOwnership(treasury);
        }

        // Add IPFS group information
        data.push(_ipfsGroup);

        // Cache the number of properties that already exist
        uint256 numStoredProperties = properties.length;

        // Cache the number of new properties to add
        uint256 numNewProperties = _names.length;

        // Cache the number of new items to add
        uint256 numNewItems = _items.length;

        // Used to store each new property id
        uint256 propertyId;

        unchecked {
            // For each new property:
            for (uint256 i = 0; i < numNewProperties; ++i) {
                // Append one slot of storage space
                properties.push();

                // Compute the property id
                propertyId = numStoredProperties + i;

                // Store the property name
                properties[propertyId].name = _names[i];

                emit PropertyAdded(propertyId, name);
            }

            // For each new item:
            for (uint256 i = 0; i < numNewItems; ++i) {
                // Cache its property id
                uint256 _propertyId = _items[i].propertyId;

                // Offset the IDs for new properties
                if (_items[i].isNewProperty) {
                    _propertyId += numStoredProperties;
                }

                // Get the storage location of its property's items
                // Property IDs under the hood are offset by 1
                Item[] storage propertyItems = properties[_propertyId].items;

                // Append one slot of storage space
                propertyItems.push();

                // Used to store the new item
                Item storage newItem;

                // Used to store the index of the new item
                uint256 newItemIndex;

                // Cannot underflow as `propertyItems.length` is ensured to be at least 1
                newItemIndex = propertyItems.length - 1;

                // Store the new item
                newItem = propertyItems[newItemIndex];

                // Store its associated metadata
                newItem.name = _items[i].name;
                newItem.referenceSlot = uint16(dataLength);

                emit ItemAdded(_propertyId, newItemIndex);
            }
        }
    }

    ///                                                          ///
    ///                     GENERATE ATTRIBUTES                  ///
    ///                                                          ///

    error ONLY_TOKEN();

    /// @notice Generates the attributes for a given token token
    /// @dev Called by the token contract during mint
    /// @param _tokenId The ERC-721 token id
    function generate(uint256 _tokenId) external {
        // Ensure the caller is the token contract
        if (msg.sender != address(token)) revert ONLY_TOKEN();

        // Compute some randomness for the token
        uint256 entropy = _getEntropy(_tokenId);

        // Get the storage location for the token attributes
        uint16[16] storage tokenAttributes = attributes[_tokenId];

        // Cache the number of available properties to choose from
        uint256 numProperties = properties.length;

        // Store the number in the first slot for future reference
        tokenAttributes[0] = uint16(numProperties);

        // Used to store the number of items in each property
        uint256 numItems;

        unchecked {
            // For each property:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Get its number of items
                numItems = properties[i].items.length;

                // Use the previously generated randomness to choose one item in the property
                tokenAttributes[i + 1] = uint16(entropy % numItems);

                // Adjust the randomness
                entropy >>= 16;
            }
        }
    }

    ///                                                          ///
    ///                            URI                           ///
    ///                                                          ///

    /// @notice The contract URI
    function contractURI() external view returns (string memory) {
        return _encodeAsJson(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', contractImage, '"}'));
    }

    /// @notice The URI of a given token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        (bytes memory propertiesAry, bytes memory propertiesQuery) = getProperties(_tokenId);
        return
            _encodeAsJson(
                abi.encodePacked(
                    '{"name": "',
                    name,
                    " #",
                    LibUintToString.toString(_tokenId),
                    '", "description": "',
                    description,
                    '", "image": "',
                    rendererBase,
                    propertiesQuery,
                    '", "properties": {',
                    propertiesAry,
                    "}}"
                )
            );
    }

    ///                                                          ///
    ///                        VIEW PROPERTIES                   ///
    ///                                                          ///

    /// @notice Get the number of properties
    /// @return count of properties
    function propertiesCount() external view returns (uint256) {
        return properties.length;
    }

    /// @notice Get the number of items in a property
    /// @param _propertyId ID of the property to get items for
    function itemsCount(uint256 _propertyId) external view returns (uint256) {
        return properties[_propertyId].items.length;
    }

    /// @notice Returns the properties generated for a token
    /// @param _tokenId The ERC-721 token id
    function getProperties(uint256 _tokenId) public view returns (bytes memory aryAttributes, bytes memory queryString) {
        // Get the attributes for the given token
        uint16[16] memory tokenAttributes = attributes[_tokenId];

        // Compute its query string
        queryString = abi.encodePacked(
            "?contractAddress=",
            StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20),
            "&tokenId=",
            StringsUpgradeable.toString(_tokenId)
        );

        // Cache its number of properties
        uint256 numProperties = tokenAttributes[0];

        // Used to hold the property and item data during
        Property memory property;
        Item memory item;

        // Used to cache the property and item names
        string memory propertyName;
        string memory itemName;

        // Used to get the item data of each generated attribute
        uint256 attribute;

        // Used to store if the last property is found
        bool isLast;

        unchecked {
            // For each of the token's properties:
            for (uint256 i = 0; i < numProperties; ++i) {
                // Check if this is the last iteration
                isLast = i == (numProperties - 1);

                // Get the property data
                property = properties[i];

                // Get the index of its generated attribute for this property
                attribute = tokenAttributes[i + 1];

                // Get the associated item data
                item = property.items[attribute];

                // Cache the names of the property and item
                propertyName = property.name;
                itemName = item.name;

                aryAttributes = abi.encodePacked(aryAttributes, '"', propertyName, '": "', itemName, '"', isLast ? "" : ",");
                queryString = abi.encodePacked(queryString, "&images=", _getImageForItem(item, propertyName));
            }
        }
    }

    ///                                                          ///
    ///                             UTILS                        ///
    ///                                                          ///

    /// @dev Computes pseudo-randomness
    function _getEntropy(uint256 _seed) private view returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, blockhash(block.number), block.coinbase, block.timestamp)));
    }

    /// @notice Encodes s
    function _encodeAsJson(bytes memory _jsonBlob) private pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_jsonBlob)));
    }

    /// @dev Encodes the string from an item in a property
    function _getImageForItem(Item memory _item, string memory _propertyName) private view returns (string memory) {
        return
            UriEncode.uriEncode(
                string(abi.encodePacked(data[_item.referenceSlot].baseUri, _propertyName, "/", _item.name, data[_item.referenceSlot].extension))
            );
    }

    ///                                                          ///
    ///                       UPDATE RENDERING                   ///
    ///                                                          ///

    /// @notice Emitted when the contract description is updated
    /// @param prevDescription The previous contract description
    /// @param newDescription The new contract description
    event DescriptionUpdated(string prevDescription, string newDescription);

    /// @notice Emitted when the renderer base is updated
    /// @param prevRendererBase The previous renderer base
    /// @param newRendererBase The new renderer base
    event RendererBaseUpdated(string prevRendererBase, string newRendererBase);

    /// @notice Updates the contract description
    /// @param _newDescription The new description
    function updateDescription(string memory _newDescription) external onlyOwner {
        emit DescriptionUpdated(description, _newDescription);

        description = _newDescription;
    }

    /// @notice Updates the renderer base
    /// @param _newRendererBase The new renderer base
    function updateRendererBase(string memory _newRendererBase) external onlyOwner {
        emit RendererBaseUpdated(rendererBase, _newRendererBase);

        rendererBase = _newRendererBase;
    }

    ///                                                          ///
    ///                        UPGRADE CONTRACT                  ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract to a valid implementation
    /// @dev This function is called in UUPS `upgradeTo` & `upgradeToAndCall`
    /// @param _impl The address of the new implementation
    function _authorizeUpgrade(address _impl) internal view override onlyOwner {
        if (!manager.isValidUpgrade(_getImplementation(), _impl)) revert INVALID_UPGRADE(_impl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The external interface for the Manager contract
interface IManager {
    /// @notice The ownership config for each founder
    /// @param wallet A wallet or multisig address
    /// @param allocationFrequency The frequency of tokens minted to them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The DAO's ERC-721 token and metadata config
    /// @param initStrings The encoded
    struct TokenParams {
        bytes initStrings; // name, symbol, description, contract image, renderer base
    }

    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    struct GovParams {
        uint256 timelockDelay; // The time between a proposal and its execution
        uint256 votingDelay; // The number of blocks after a proposal that voting is delayed
        uint256 votingPeriod; // The number of blocks that voting for a proposal will take place
        uint256 proposalThresholdBPS; // The number of votes required for a voter to become a proposer
        uint256 quorumVotesBPS; // The number of votes required to support a proposal
    }

    error FOUNDER_REQUIRED();

    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IManager} from "../manager/IManager.sol";
import {IMetadataRenderer} from "./metadata/IMetadataRenderer.sol";

interface IToken {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata tokenInitStrings,
        address metadataRenderer,
        address auction
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function metadataRenderer() external view returns (IMetadataRenderer);

    function auction() external view returns (address);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    function delegates(address account) external view returns (address);

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    error INVALID_TARGET();

    error DELEGATE_CALL_FAILED();

    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)));
    }

    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Address} from "../utils/Address.sol";

contract InitializableStorageV1 {
    uint8 internal _initialized;
    bool internal _initializing;
}

/// @notice Modern Initializable modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error INVALID_INIT();

    error NOT_INITIALIZING();

    error ALREADY_INITIALIZED();

    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract EIP712StorageV1 {
    bytes32 internal _HASHED_NAME;
    bytes32 internal _HASHED_VERSION;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;
    uint256 internal INITIAL_CHAIN_ID;

    mapping(address => uint256) public nonces;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol
abstract contract EIP712 is Initializable, EIP712StorageV1 {
    bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    error EXPIRED_SIGNATURE();

    error INVALID_SIGNER();

    function __EIP712_init(string memory _name, string memory _version) internal onlyInitializing {
        _HASHED_NAME = keccak256(bytes(_name));
        _HASHED_VERSION = keccak256(bytes(_version));

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";
import {Address} from "../utils/Address.sol";
import {Strings} from "../utils/Strings.sol";
import {ERC721TokenReceiver} from "../utils/TokenReceiver.sol";

contract ERC721StorageV1 {
    string public name;

    string public symbol;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;
}

abstract contract ERC721 is Initializable, ERC721StorageV1 {
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error INVALID_ADDRESS();

    error NO_OWNER();

    error NOT_AUTHORIZED();

    error WRONG_OWNER();

    error INVALID_RECIPIENT();

    error ALREADY_MINTED();

    error NOT_MINTED();

    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {}

    function contractURI() public view virtual returns (string memory) {}

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    function __ERC721_init(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            _interfaceId == 0x80ac58cd || // ERC721 Interface ID
            _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
    }

    function balanceOf(address _owner) public view virtual returns (uint256) {
        if (_owner == address(0)) revert INVALID_ADDRESS();

        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        address owner = _ownerOf[_tokenId];

        if (owner == address(0)) revert NO_OWNER();

        return owner;
    }

    function approve(address _to, uint256 _tokenId) public virtual {
        address owner = _ownerOf[_tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NOT_AUTHORIZED();

        getApproved[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual {
        isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        if (_from != _ownerOf[_tokenId]) revert WRONG_OWNER();

        if (_to == address(0)) revert INVALID_RECIPIENT();

        if (msg.sender != _from && !isApprovedForAll[_from][msg.sender] && msg.sender != getApproved[_tokenId]) revert NOT_AUTHORIZED();

        _beforeTokenTransfer(_from, _to, _tokenId);

        unchecked {
            --_balanceOf[_from];

            ++_balanceOf[_to];
        }

        _ownerOf[_tokenId] = _to;

        delete getApproved[_tokenId];

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public virtual {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to == address(0)) revert INVALID_RECIPIENT();

        if (_ownerOf[_tokenId] != address(0)) revert ALREADY_MINTED();

        _beforeTokenTransfer(address(0), _to, _tokenId);

        unchecked {
            ++_balanceOf[_to];
        }

        _ownerOf[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);

        _afterTokenTransfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual {
        address owner = _ownerOf[_tokenId];

        if (owner == address(0)) revert NOT_MINTED();

        _beforeTokenTransfer(owner, address(0), _tokenId);

        unchecked {
            --_balanceOf[owner];
        }

        delete _ownerOf[_tokenId];

        delete getApproved[_tokenId];

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfer(owner, address(0), _tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    error INSUFFICIENT_HEX_LENGTH();

    function toBytes32(string memory _str) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_str, 32))
        }
    }

    function toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }

        uint256 temp = _value;
        uint256 digits;

        while (temp != 0) {
            unchecked {
                ++digits;
                temp /= 10;
            }
        }

        bytes memory buffer = new bytes(digits);

        while (_value != 0) {
            unchecked {
                --digits;
                buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
                _value /= 10;
            }
        }

        return string(buffer);
    }

    /// @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation
    function toHexString(uint256 _address) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);

        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i = 41; i > 1; ) {
            unchecked {
                buffer[i] = _HEX_SYMBOLS[_address & 0xf];
                _address >>= 4;

                --i;
            }
        }

        if (_address != 0) revert INSUFFICIENT_HEX_LENGTH();

        return string(buffer);
    }

    /// @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    function toHexString(uint256 _value, uint256 _length) internal pure returns (string memory) {
        // TODO more precise optimizations like caching
        unchecked {
            bytes memory buffer = new bytes(2 * _length + 2);

            buffer[0] = "0";
            buffer[1] = "x";

            for (uint256 i = 2 * _length + 1; i > 1; ) {
                buffer[i] = _HEX_SYMBOLS[_value & 0xf];
                _value >>= 4;

                --i;
            }

            if (_value != 0) revert INSUFFICIENT_HEX_LENGTH();

            return string(buffer);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract TokenTypesV1 {
    struct Founder {
        uint32 allocationFrequency;
        uint64 vestingEnd;
        address wallet;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibUintToString {
    uint256 private constant MAX_UINT256_STRING_LENGTH = 78;
    uint8 private constant ASCII_DIGIT_OFFSET = 48;

    /// @dev Converts a `uint256` value to a string.
    /// @param n The integer to convert.
    /// @return nstr `n` as a decimal string.
    function toString(uint256 n) 
        internal 
        pure 
        returns (string memory nstr) 
    {
        if (n == 0) {
            return "0";
        }
        // Overallocate memory
        nstr = new string(MAX_UINT256_STRING_LENGTH);
        uint256 k = MAX_UINT256_STRING_LENGTH;
        // Populate string from right to left (lsb to msb).
        while (n != 0) {
            assembly {
                let char := add(
                    ASCII_DIGIT_OFFSET,
                    mod(n, 10)
                )
                mstore(add(nstr, k), char)
                k := sub(k, 1)
                n := div(n, 10)
            }
        }
        assembly {
            // Shift pointer over to actual start of string.
            nstr := add(nstr, k)
            // Store actual string length.
            mstore(nstr, sub(MAX_UINT256_STRING_LENGTH, k))
        }
        return nstr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UriEncode {
    string internal constant _TABLE = "0123456789abcdef";

    function uriEncode(string memory uri)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesUri = bytes(uri);

        string memory table = _TABLE;

        // Max size is worse case all chars need to be encoded
        bytes memory result = new bytes(3 * bytesUri.length);

        /// @solidity memory-safe-assembly
        assembly {
            // Get the lookup table
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Keep track of the final result size string length
            let resultSize := 0

            for {
                let dataPtr := bytesUri
                let endPtr := add(bytesUri, mload(bytesUri))
            } lt(dataPtr, endPtr) {

            } {
                // advance 1 byte
                dataPtr := add(dataPtr, 1)
                let input := and(mload(dataPtr), 127)

                // Check if is valid URI character
                let isValidUriChar := or(
                    and(gt(input, 96), lt(input, 134)), // a 97 / z 133
                    or(
                        and(gt(input, 64), lt(input, 91)), // A 65 / Z 90
                        or(
                          and(gt(input, 47), lt(input, 58)), // 0 48 / 9 57
                          or(
                            or(
                              eq(input, 46), // . 46
                              eq(input, 95)  // _ 95
                            ),
                            or(
                              eq(input, 45),  // - 45
                              eq(input, 126)  // ~ 126
                            )
                          )
                        )
                    )
                )

                switch isValidUriChar
                // If is valid uri character copy character over and increment the result
                case 1 {
                    mstore8(resultPtr, input)
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 1)
                }
                // If the char is not a valid uri character, uriencode the character
                case 0 {
                    mstore8(resultPtr, 37)
                    resultPtr := add(resultPtr, 1)
                    // table[character >> 4] (take the last 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, shr(4, input))))
                    resultPtr := add(resultPtr, 1)
                    // table & 15 (take the first 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, and(input, 15))))
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 3)
                }
            }

            // Set size of result string in memory
            mstore(result, resultSize)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Token} from "../../Token.sol";
import {IMetadataRenderer} from "../IMetadataRenderer.sol";

import {MetadataRendererTypesV1} from "../types/MetadataRendererTypesV1.sol";

contract MetadataRendererStorageV1 is MetadataRendererTypesV1 {
    Token public token;
    address public treasury;

    string public name;
    string public description;

    string internal contractImage;
    string internal rendererBase;

    IMetadataRenderer.IPFSGroup[] internal data;
    Property[] internal properties;

    mapping(uint256 => uint16[16]) internal attributes;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IMetadataRenderer {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(
        bytes calldata initStrings,
        address token,
        address founders,
        address treasury
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string extension;
    }

    function addProperties(
        string[] calldata names,
        ItemParam[] calldata items,
        IPFSGroup calldata ipfsGroup
    ) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function contractURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function propertiesCount() external view returns (uint256);

    function itemsCount(uint256 propertyId) external view returns (uint256);

    function getProperties(uint256 tokenId) external view returns (bytes memory aryAttributes, bytes memory queryString);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract MetadataRendererTypesV1 {
    struct Property {
        string name;
        Item[] items;
    }

    struct Item {
        uint16 referenceSlot;
        string name;
    }
}