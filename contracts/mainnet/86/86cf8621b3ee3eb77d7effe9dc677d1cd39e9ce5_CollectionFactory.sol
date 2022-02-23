// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ICollectionFactory } from "../interfaces/ICollectionFactory.sol";
import { ICollection } from "../interfaces/ICollection.sol";
import { ICollectionCloneable } from "../interfaces/ICollectionCloneable.sol";
import { IOwnable } from "../interfaces/IOwnable.sol";
import { IHashes } from "../interfaces/IHashes.sol";
import { LibClone } from "../lib/LibClone.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollectionFactory
 * @author DEX Labs
 * @notice This contract is the registry for Hashes Collections.
 */
contract CollectionFactory is ICollectionFactory, Ownable, ReentrancyGuard {
    /// @notice A checkpoint for ecosystem settings values. Settings are ABI encoded bytes
    ///         to provide the most flexibility towards various implementation contracts.
    struct SettingsCheckpoint {
        uint64 id;
        bytes settings;
    }

    /// @notice A structure for storing the contract addresses of collection instances.
    struct CollectionContracts {
        bool exists;
        bool cloneable;
        address[] contractAddresses;
    }

    IHashes hashesToken;

    /// @notice collections A mapping of implementation addresses to a struct which
    ///         contains an array of the cloned collections for that implementation.
    mapping(address => CollectionContracts) public collections;

    /// @notice ecosystems An array of the hashed ecosystem names which correspond to
    ///         a settings format which can be used by multiple implementation contracts.
    bytes32[] public ecosystems;

    /// @notice ecosystemSettings A mapping of hashed ecosystem names to an array of
    ///         settings checkpoints. Settings checkpoints contain ABI encoded data
    ///         which can be decoded in implementation addresses that consume them.
    mapping(bytes32 => SettingsCheckpoint[]) public ecosystemSettings;

    /// @notice implementationAddresses A mapping of hashed ecosystem names to an array
    ///         of the implementation addresses for that ecosystem.
    mapping(bytes32 => address[]) public implementationAddresses;

    /// @notice factoryMaintainerAddress An address which has some distinct maintenance abilities. These
    ///         include the ability to remove implementation addresses or collection instances, as well as
    ///         transfer this role to another address. Implementation addresses can choose to use this address
    ///         for certain roles since it is passed through to the initialize function upon creating
    ///         a cloned collection.
    address public factoryMaintainerAddress;

    /// @notice ImplementationAddressAdded Emitted when an implementation address is added.
    event ImplementationAddressAdded(address indexed implementationAddress, bool indexed cloneable);

    /// @notice CollectionCreated Emitted when a Collection is created.
    event CollectionCreated(
        address indexed implementationAddress,
        address indexed collectionAddress,
        address indexed creator
    );

    /// @notice FactoryMaintainerAddressSet Emitted when the factory maintainer address is set.
    event FactoryMaintainerAddressSet(address indexed factoryMaintainerAddress);

    /// @notice ImplementationAddressesRemoved Emitted when implementation addresses are removed.
    event ImplementationAddressesRemoved(address[] implementationAddresses);

    /// @notice CollectionAddressRemoved Emitted when a cloned collection contract address is removed.
    event CollectionAddressRemoved(address indexed implementationAddress, address indexed collectionAddress);

    /// @notice EcosystemSettingsCreated Emitted when ecosystem settings are created.
    event EcosystemSettingsCreated(string ecosystemName, bytes32 indexed hashedEcosystemName, bytes settings);

    /// @notice EcosystemSettingsUpdated Emitted when ecosystem settings are updated.
    event EcosystemSettingsUpdated(bytes32 indexed hashedEcosystemName, bytes settings);

    modifier onlyOwnerOrFactoryMaintainer() {
        require(
            _msgSender() == factoryMaintainerAddress || _msgSender() == owner(),
            "CollectionFactory: must be either factory maintainer or owner"
        );
        _;
    }

    /**
     * @notice Constructor for the Collection Factory.
     */
    constructor(IHashes _hashesToken) {
        // initially set the factoryMaintainerAddress to be the deployer, though this can transfered
        factoryMaintainerAddress = _msgSender();
        hashesToken = _hashesToken;

        // make HashesDAO the owner of this Factory contract
        transferOwnership(IOwnable(address(hashesToken)).owner());
    }

    /**
     * @notice This function adds an implementation address.
     * @param _hashedEcosystemName The ecosystem which this implementation address will reference.
     * @param _implementationAddress The address of the Collection contract.
     * @param _cloneable Whether this implementation address is cloneable.
     */
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool _cloneable
    ) external override {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        CollectionContracts storage collection = collections[_implementationAddress];
        require(!collection.exists, "CollectionFactory: implementation address already exists");
        require(_implementationAddress != address(0), "CollectionFactory: implementation address cannot be 0 address");

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        require(
            ICollection(_implementationAddress).verifyEcosystemSettings(
                getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], blockNumber)
            ),
            "CollectionFactory: implementation address doesn't properly validate ecosystem settings"
        );

        collection.exists = true;
        collection.cloneable = _cloneable;

        implementationAddresses[_hashedEcosystemName].push(_implementationAddress);

        emit ImplementationAddressAdded(_implementationAddress, _cloneable);
    }

    /**
     * @notice This function clones a Hashes Collection implementation contract.
     * @param _implementationAddress The address of the cloneable implementation contract.
     * @param _initializationData The abi encoded initialization data which is consumable
     *        by the implementation contract in its initialize function.
     */
    function createCollection(address _implementationAddress, bytes memory _initializationData)
        external
        override
        nonReentrant
    {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(collection.cloneable, "CollectionFactory: implementation address is not cloneable.");

        ICollectionCloneable clonedCollection = ICollectionCloneable(LibClone.createClone(_implementationAddress));
        collection.contractAddresses.push(address(clonedCollection));

        clonedCollection.initialize(hashesToken, factoryMaintainerAddress, _msgSender(), _initializationData);

        emit CollectionCreated(_implementationAddress, address(clonedCollection), _msgSender());
    }

    /**
     * @notice This function sets the factory maintainer address.
     * @param _factoryMaintainerAddress The address of the factory maintainer.
     */
    function setFactoryMaintainerAddress(address _factoryMaintainerAddress)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        factoryMaintainerAddress = _factoryMaintainerAddress;
        emit FactoryMaintainerAddressSet(_factoryMaintainerAddress);
    }

    /**
     * @notice This function removes implementation addresses from the factory.
     * @param _hashedEcosystemNames The ecosystems which these implementation addresses reference.
     * @param _implementationAddressesToRemove The implementation addresses to remove: either cloneable
     *        implementation addresses or a standalone contracts.
     * @param _indexes The array indexes to be removed. Must be monotonically increasing and match the items
     *        in the other two arrays. This array is provided to reduce the cost of removal.
     */
    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddressesToRemove,
        uint256[] memory _indexes
    ) external override onlyOwnerOrFactoryMaintainer {
        require(
            _hashedEcosystemNames.length == _implementationAddressesToRemove.length &&
                _hashedEcosystemNames.length == _indexes.length,
            "CollectionFactory: arrays provided must be the same length"
        );

        // set this to max int to start so first less-than comparison is always true
        uint256 _previousIndex = 2**256 - 1;

        // iterate through items in reverse order
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                _indexes[_indexes.length - 1 - i] < _previousIndex,
                "CollectionFactory: arrays must be ordered before processing."
            );
            _previousIndex = _indexes[_indexes.length - 1 - i];

            bytes32 _hashedEcosystemName = _hashedEcosystemNames[_indexes.length - 1 - i];
            address _implementationAddress = _implementationAddressesToRemove[_indexes.length - 1 - i];
            uint256 _currentIndex = _indexes[_indexes.length - 1 - i];

            require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
            require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
            address[] storage _implementationAddresses = implementationAddresses[_hashedEcosystemName];
            require(_currentIndex < _implementationAddresses.length, "CollectionFactory: array index out of bounds.");
            require(
                _implementationAddresses[_currentIndex] == _implementationAddress,
                "CollectionFactory: element at array index not equal to implementation address."
            );

            // remove the implementation address from the mapping
            delete collections[_implementationAddress];

            // swap the last element of the array for the one we're removing
            _implementationAddresses[_currentIndex] = _implementationAddresses[_implementationAddresses.length - 1];
            _implementationAddresses.pop();
        }

        emit ImplementationAddressesRemoved(_implementationAddressesToRemove);
    }

    /**
     * @notice This function removes a cloned collection address from the factory.
     * @param _implementationAddress The implementation address of the cloneable contract.
     * @param _collectionAddress The cloned collection address to be removed.
     * @param _index The array index to be removed. This is provided to reduce the cost of removal.
     */
    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external override onlyOwnerOrFactoryMaintainer {
        CollectionContracts storage collection = collections[_implementationAddress];
        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(_index < collection.contractAddresses.length, "CollectionFactory: array index out of bounds.");
        require(
            collection.contractAddresses[_index] == _collectionAddress,
            "CollectionFactory: element at array index not equal to collection address."
        );

        // swap the last element of the array for the one we're removing
        collection.contractAddresses[_index] = collection.contractAddresses[collection.contractAddresses.length - 1];
        collection.contractAddresses.pop();

        emit CollectionAddressRemoved(_implementationAddress, _collectionAddress);
    }

    /**
     * @notice This function creates a new ecosystem setting key in the mapping along with
     *         the initial ABI encoded settings value to be used for that key. The factory maintainer
     *         can create a new ecosystem setting to allow for efficient bootstrapping of a new
     *         ecosystem, but only HashesDAO can update an existing ecosystem.
     * @param _ecosystemName The name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings)
        external
        override
        onlyOwnerOrFactoryMaintainer
    {
        bytes32 hashedEcosystemName = keccak256(abi.encodePacked(_ecosystemName));
        require(
            ecosystemSettings[hashedEcosystemName].length == 0,
            "CollectionFactory: ecosystem settings for this name already exist"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        ecosystems.push(hashedEcosystemName);

        emit EcosystemSettingsCreated(_ecosystemName, hashedEcosystemName, _settings);
    }

    /**
     * @notice This function updates an ecosystem setting which means a new checkpoint is
     *         added to the array of settings checkpoints for that ecosystem. Only HashesDAO
     *         can call this function since these are likely to be more established ecosystems
     *         which have more impact.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _settings The ABI encoded settings data which can be decoded by implementation
     *        contracts which consume this ecosystem.
     */
    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external override onlyOwner {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");
        require(
            implementationAddresses[_hashedEcosystemName].length > 0,
            "CollectionFactory: no implementation addresses for this ecosystem"
        );

        ICollection firstImplementationAddress = ICollection(implementationAddresses[_hashedEcosystemName][0]);
        require(
            firstImplementationAddress.verifyEcosystemSettings(_settings),
            "CollectionFactory: invalid ecosystem settings according to first implementation contract"
        );

        uint64 blockNumber = safe64(block.number, "CollectionFactory: exceeds 64 bits.");
        ecosystemSettings[_hashedEcosystemName].push(SettingsCheckpoint({ id: blockNumber, settings: _settings }));

        emit EcosystemSettingsUpdated(_hashedEcosystemName, _settings);
    }

    /**
     * @notice This function gets the ecosystem settings from a particular ecosystem checkpoint.
     * @param _hashedEcosystemName The hashed name of the ecosystem.
     * @param _blockNumber The block number in which the new Collection was initialized. This is
     *        used to determine which settings were active at the time of Collection creation.
     */
    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        override
        returns (bytes memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem settings not found");

        return getCheckpointedSettings(ecosystemSettings[_hashedEcosystemName], _blockNumber);
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @return An array of Collection addresses.
     */
    function getCollections(address _implementationAddress) external view override returns (address[] memory) {
        require(collections[_implementationAddress].exists, "CollectionFactory: implementation address not found.");
        return collections[_implementationAddress].contractAddresses;
    }

    /**
     * @notice This function returns an array of the Hashes Collections
     *         created through this registry for a particular implementation address.
     * @param _implementationAddress The implementation address.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of Collection addresses.
     */
    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        CollectionContracts storage collection = collections[_implementationAddress];

        require(collection.exists, "CollectionFactory: implementation address not found.");
        require(
            _start < collection.contractAddresses.length &&
                _end <= collection.contractAddresses.length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory collectionsForImplementation = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            collectionsForImplementation[i] = collection.contractAddresses[i];
        }
        return collectionsForImplementation;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems() external view override returns (bytes32[] memory) {
        return ecosystems;
    }

    /**
     * @notice This function gets the list of hashed ecosystem names.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return An array of the hashed ecosystem names.
     */
    function getEcosystems(uint256 _start, uint256 _end) external view override returns (bytes32[] memory) {
        require(
            _start < ecosystems.length && _end <= ecosystems.length && _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        bytes32[] memory _ecosystems = new bytes32[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _ecosystems[i] = ecosystems[i];
        }
        return _ecosystems;
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(bytes32 _hashedEcosystemName)
        external
        view
        override
        returns (address[] memory)
    {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        return implementationAddresses[_hashedEcosystemName];
    }

    /**
     * @notice This function returns an array of the implementation addresses.
     * @param _hashedEcosystemName The ecosystem to fetch implementation addresses from.
     * @param _start The array start index (inclusive).
     * @param _end The array end index (exclusive).
     * @return Array of Hashes Collection implementation addresses.
     */
    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view override returns (address[] memory) {
        require(ecosystemSettings[_hashedEcosystemName].length > 0, "CollectionFactory: ecosystem doesn't exist");
        require(
            _start < implementationAddresses[_hashedEcosystemName].length &&
                _end <= implementationAddresses[_hashedEcosystemName].length &&
                _end > _start,
            "CollectionFactory: Array indices out of bounds"
        );

        address[] memory _implementationAddresses = new address[](_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _implementationAddresses[i] = implementationAddresses[_hashedEcosystemName][i];
        }
        return _implementationAddresses;
    }

    function getCheckpointedSettings(SettingsCheckpoint[] storage _settingsCheckpoints, uint64 _blockNumber)
        private
        view
        returns (bytes storage)
    {
        require(
            _blockNumber >= _settingsCheckpoints[0].id,
            "CollectionFactory: Block number before first settings block"
        );

        // If blocknumber greater than highest checkpoint, just return the latest checkpoint
        if (_blockNumber >= _settingsCheckpoints[_settingsCheckpoints.length - 1].id)
            return _settingsCheckpoints[_settingsCheckpoints.length - 1].settings;

        // Binary search for the matching checkpoint
        uint256 min = 0;
        uint256 max = _settingsCheckpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;

            if (_settingsCheckpoints[mid].id == _blockNumber) {
                return _settingsCheckpoints[mid].settings;
            }
            if (_settingsCheckpoints[mid].id < _blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return _settingsCheckpoints[min].settings;
    }

    function safe64(uint256 n, string memory errorMessage) internal pure returns (uint64) {
        require(n < 2**64, errorMessage);
        return uint64(n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionFactory {
    function addImplementationAddress(
        bytes32 _hashedEcosystemName,
        address _implementationAddress,
        bool cloneable
    ) external;

    function createCollection(address _implementationAddress, bytes memory _initializationData) external;

    function setFactoryMaintainerAddress(address _factoryMaintainerAddress) external;

    function removeImplementationAddresses(
        bytes32[] memory _hashedEcosystemNames,
        address[] memory _implementationAddresses,
        uint256[] memory _indexes
    ) external;

    function removeCollection(
        address _implementationAddress,
        address _collectionAddress,
        uint256 _index
    ) external;

    function createEcosystemSettings(string memory _ecosystemName, bytes memory _settings) external;

    function updateEcosystemSettings(bytes32 _hashedEcosystemName, bytes memory _settings) external;

    function getEcosystemSettings(bytes32 _hashedEcosystemName, uint64 _blockNumber)
        external
        view
        returns (bytes memory);

    function getEcosystems() external view returns (bytes32[] memory);

    function getEcosystems(uint256 _start, uint256 _end) external view returns (bytes32[] memory);

    function getCollections(address _implementationAddress) external view returns (address[] memory);

    function getCollections(
        address _implementationAddress,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);

    function getImplementationAddresses(bytes32 _hashedEcosystemName) external view returns (address[] memory);

    function getImplementationAddresses(
        bytes32 _hashedEcosystemName,
        uint256 _start,
        uint256 _end
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollection {
    function verifyEcosystemSettings(bytes memory _settings) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IHashes } from "./IHashes.sol";

interface ICollectionCloneable {
    function initialize(
        IHashes _hashesToken,
        address _factoryMaintainerAddress,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IOwnable {
    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
    The MIT License (MIT)
    Copyright (c) 2018 Murray Software, LLC.
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

library LibClone {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(eq(mload(clone), mload(other)), eq(mload(add(clone, 0xd)), mload(add(other, 0xd))))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}