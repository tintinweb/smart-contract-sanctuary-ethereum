/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface FrameDataStore {
    function getData(
        string memory _key,
        uint256 _startPage,
        uint256 _endPage
    ) external view returns (bytes memory);

    function getMaxPageNumber(string memory _key)
        external
        view
        returns (uint256);

    function getAllDataFromPage(
        string memory _key,
        uint256 _startPage
    ) external view returns (bytes memory);
}

contract Frame {
    string name = "";

    struct Asset {
        string wrapperKey;
        string key;
    }

    FrameDataStore public coreDepStorage;
    FrameDataStore public assetStorage;
    
    mapping(uint256 => Asset) public depsList;
    uint256 public depsCount;

    mapping(uint256 => Asset) public assetList;
    uint256 public assetsCount;

    uint256 public renderPagesCount;
    mapping(uint256 => uint256[4]) public renderIndex;

    bool initSuccess = false;

    constructor() {}

    function init(
        address _coreDepStorage,
        address _assetStorage,
        string[2][] calldata _deps,
        string[2][] calldata _assets,
        uint256[4][] calldata _renderIndex
    ) public {
        require(!initSuccess, "Frame: Can't re-init contract");

        _setCoreDepStorage(FrameDataStore(_coreDepStorage));
        _setAssetStorage(FrameDataStore(_assetStorage));
        _setDeps(_deps);
        _setAssets(_assets);
        _setRenderIndex(_renderIndex);

        initSuccess = true;
    }

    function setName(string memory _name) public {
        require(bytes(name).length < 3, "Frame: Name already set");
        name = _name;
    }

    // Internal 

    function _setDeps(string[2][] calldata _deps) internal {
        for (uint256 dx; dx < _deps.length; dx++) {
            depsList[dx] = Asset({ wrapperKey: _deps[dx][0], key: _deps[dx][1] });
            depsCount++;
        }
    }

    function _setAssets(string[2][] calldata _assets) internal {
        for (uint256 ax; ax < _assets.length; ax++) {
            assetList[ax] = Asset({ wrapperKey: _assets[ax][0], key: _assets[ax][1] });
            assetsCount++;
        }
    }

    function _setCoreDepStorage(FrameDataStore _storage) internal {
        coreDepStorage = _storage;
    }

    function _setAssetStorage(FrameDataStore _storage) internal {
        assetStorage = _storage;
    }

    function _setRenderIndex(uint256[4][] calldata _index) internal {
        for (uint256 idx; idx < _index.length; idx++) {
            renderPagesCount++;
            renderIndex[idx] = _index[idx];
        }
        renderPagesCount = _index.length;
    }

    // Read-only

    function renderWrapper() public view returns (string memory) {
        return string(coreDepStorage.getAllDataFromPage("[email protected].0", 0));
    }

    function renderPage(uint256 _rpage) public view returns (string memory) {
        // Index item format: [startAsset, endAsset, startAssetPage, endAssetPage]
        uint256[4] memory indexItem = renderIndex[_rpage];
        uint256 startAtAsset = indexItem[0];
        uint256 endAtAsset = indexItem[1];
        uint256 startAtPage = indexItem[2];
        uint256 endAtPage = indexItem[3];
        string memory result = "";

        for (uint256 idx = startAtAsset; idx < endAtAsset + 1; idx++) {
            bool idxIsDep = idx + 1 <= depsCount;
            uint256 adjustedIdx = idxIsDep ? idx : idx - depsCount;
            FrameDataStore idxStorage = idxIsDep ? coreDepStorage : assetStorage;
            Asset memory idxAsset = idxIsDep ? depsList[idx] : assetList[adjustedIdx];

            uint256 startPage = idx == startAtAsset ? startAtPage : 0;
            uint256 endPage = idx == endAtAsset
                ? endAtPage
                : idxStorage.getMaxPageNumber(idxAsset.key);

            // If starting at zero, include first part of an asset's wrapper
            if (startPage == 0) {
                result = string.concat(
                    result, 
                    string(
                        abi.encodePacked(
                            coreDepStorage.getData(idxAsset.wrapperKey, 0, 0)
                        )
                    )
                );
            }

            result = string.concat(
                result,
                string(
                    abi.encodePacked(
                        idxStorage.getData(idxAsset.key, startPage, endPage)
                    )
                )
            );

            // If needed, include last part of an asset's wrapper
            bool endingEarly = idx == endAtAsset &&
                endAtPage != idxStorage.getMaxPageNumber(idxAsset.key);

            if (!endingEarly) {
                result = string.concat(
                    result, 
                    string(
                        abi.encodePacked(
                            coreDepStorage.getData(
                                idxAsset.wrapperKey, 1, 1
                            )
                        )
                    )
                );
            }
        }

        if (_rpage == 0) {
            result = string.concat(string(coreDepStorage.getData("[email protected]", 0, 0)), result);
        }
        
        if (_rpage == (renderPagesCount - 1)) {
            result = string.concat(result, string(coreDepStorage.getData("[email protected]", 1, 1)));
        }

        return result;
    }
}