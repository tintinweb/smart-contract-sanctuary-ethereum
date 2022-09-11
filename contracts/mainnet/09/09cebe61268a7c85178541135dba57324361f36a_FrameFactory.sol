//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./CloneFactory.sol";

interface IFrameDataStore {
    function saveData(string memory _key, uint128 _pageNumber, bytes memory _b) external;
    function lock() external;
}

interface IFrameDataStoreFactory {
    function createFrameDataStore(string memory _name, string memory _version) external returns (address);
}

interface IFrame {
    struct Asset {
        string wrapperKey;
        string key;
        address wrapperStore;
        address store;
    }

    function init(
        Asset[] calldata _deps,
        address _sourceStore,
        address _pageWrapStore,
        uint256[4][] calldata _renderMap
    ) external;

    function setName(string calldata _name) external;
}

contract FrameFactory is CloneFactory {
    address public libraryAddress;

    event FrameCreated(address newAddress);

    constructor() {}

    function setLibraryAddress(address _libraryAddress) public  {
        require(libraryAddress == address(0), "FrameFactory: Library already set");
        libraryAddress = _libraryAddress;
    }

    function createFrameWithSource(
        IFrameDataStoreFactory _frameDataStoreFactory,
        IFrame.Asset[] memory _deps,
        bytes[] calldata _newData,
        address _pageWrapStore,
        uint256[4][] calldata _renderMap,
        string calldata _name
    ) public returns (address)  {
        // Create new frame contract and new datastore contract
        address clone = createClone(libraryAddress);
        address sourceStore = _frameDataStoreFactory.createFrameDataStore(_name, "1.0.0");

        // Saves data and sets internalStore to an dep with an empty store address
        uint256 newAssetAddedCursor = 0;
        for (uint256 dx = 0; dx < _deps.length; dx++) {
          if (_deps[dx].store == address(0)) {
            // Save data to new store
            IFrameDataStore(sourceStore).saveData(_deps[dx].key, 0, _newData[newAssetAddedCursor]);
            newAssetAddedCursor++;

            // Replace item
            _deps[dx].store = sourceStore;
          }
        }

        // Init frame
        IFrame(clone).init(
            _deps,
            sourceStore,
            _pageWrapStore,
            _renderMap
        );

        // Set frame name
        IFrame(clone).setName(_name);
        
        // Lock newly created data store
        IFrameDataStore(sourceStore).lock();

        emit FrameCreated(clone);
        return clone;
    }
}