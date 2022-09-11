/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IFrameDataStore {
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
    struct Asset {
        string wrapperKey;
        string key;
        address wrapperStore;
        address store;
    }

    string public name = "";
    bool public initSuccess = false;
    
    mapping(uint256 => Asset) public depsList;
    uint256 public depsCount;

    IFrameDataStore public pageWrapStore;
    IFrameDataStore public sourceStore;

    uint256 public renderPagesCount;
    mapping(uint256 => uint256[4]) public renderMap;

    constructor() {}

    function init(
        Asset[] calldata _deps,
        address _sourceStore,
        address _pageWrapStore,
        uint256[4][] calldata _renderMap
    ) public {
        require(!initSuccess, "Frame: Can't re-init contract");

        _setDeps(_deps);
        _setRenderMap(_renderMap);

        sourceStore = IFrameDataStore(_sourceStore);
        pageWrapStore = IFrameDataStore(_pageWrapStore);
        
        initSuccess = true;
    }

    function setName(string memory _name) public {
        require(bytes(name).length < 3, "Frame: Name already set");
        name = _name;
    }

    // Internal 

    function _setDeps(Asset[] calldata _deps) internal {
        for (uint256 dx; dx < _deps.length; dx++) {
            depsList[dx] = _deps[dx];
        }
        depsCount = _deps.length;
    }

    function _setRenderMap(uint256[4][] calldata _map) internal {
        for (uint256 idx; idx < _map.length; idx++) {
            renderPagesCount++;
            renderMap[idx] = _map[idx];
        }
        renderPagesCount = _map.length;
    }

    function _compareStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function _isB64JsWrapperString(string memory _a) internal pure returns (bool) {
        return _compareStrings("[email protected]", _a);
    }

    function _isImportmapWrapperString(string memory _a) internal pure returns (bool) {
        return _compareStrings("[email protected]", _a);
    }

    function _isAssetDep(uint256 _index) internal view returns (bool) {
        return _index < depsCount;
    }

    function _getAssetWithWrapperString(
        IFrameDataStore _assetStorage,
        IFrameDataStore _wrapperStorage,
        Asset memory _asset, 
        uint256 _fromPage, 
        uint256 _toPage
    ) internal view returns (string memory) {
        string memory result = "";
        if (_fromPage == 0) {
            result = string(
                abi.encodePacked(
                    _wrapperStorage.getData(_asset.wrapperKey, 0, 0)
                )
            );
        }
        result = string.concat(
            result,
            string(
                abi.encodePacked(
                    _assetStorage.getData(_asset.key, _fromPage, _toPage)
                )
            )
        );
        if (_toPage == _assetStorage.getMaxPageNumber(_asset.key)) {
            result = string.concat(
                result,
                string(
                    abi.encodePacked(
                        _wrapperStorage.getData(_asset.wrapperKey, 1, 1)
                    )
                )
            );
        }
        return result;
    }

    // Read-only

    function renderPage(uint256 _rpage) public view returns (string memory) {
        // Index item format: [startAsset, endAsset, startAssetPage, endAssetPage]
        uint256[4] memory indexItem = renderMap[_rpage];
        uint256 startAtAssetIndex = indexItem[0];
        uint256 endAtAssetIndex = indexItem[1];
        uint256 startAtPage = indexItem[2];
        uint256 endAtPage = indexItem[3];
        string memory result = "";

        // Iterate over assets in the index item
        for (uint256 idx = startAtAssetIndex; idx < endAtAssetIndex + 1; idx++) {
            Asset memory idxAsset = depsList[idx];
            IFrameDataStore idxStorage = IFrameDataStore(idxAsset.store);
            IFrameDataStore idxWrapStorage = IFrameDataStore(idxAsset.wrapperStore);

            bool isIdxAtEndAssetIndex = idx == endAtAssetIndex;
            uint256 startPage = idx == startAtAssetIndex ? startAtPage : 0;
            uint256 endPage = isIdxAtEndAssetIndex
                ? endAtPage
                : idxStorage.getMaxPageNumber(idxAsset.key);

            string memory newStuff = _getAssetWithWrapperString(idxStorage, idxWrapStorage, idxAsset, startPage, endPage);
            result = string.concat(result, newStuff);

            address sourceStoreAddr = address(sourceStore);
            bool isIdxAssetLastDep = address(idxAsset.store) != sourceStoreAddr && address(depsList[idx + 1].store) == sourceStoreAddr;
            bool hasCompletedAsset = endPage == idxStorage.getMaxPageNumber(idxAsset.key);
            bool isNextAssetImportMap = _isImportmapWrapperString(depsList[idx + 1].wrapperKey);

            if (_isB64JsWrapperString(idxAsset.wrapperKey) && hasCompletedAsset) {
              if (isIdxAssetLastDep) {
                result = string.concat(
                    result, 
                    string(
                        abi.encodePacked(
                            pageWrapStore.getData("[email protected]", 1, 1),
                            pageWrapStore.getData("[email protected]", 0, 0)
                        )
                    )
                );
              } 
              if (isNextAssetImportMap) {
                  string memory importKeysJsString = string(
                      abi.encodePacked(
                          pageWrapStore.getData("[email protected]", 0, 0)
                      )
                  );

                  // Inject a list of import key names to the page
                  for (uint256 dx = 0; dx < depsCount; dx++) {
                      if(_isImportmapWrapperString(depsList[dx].wrapperKey)) {
                          importKeysJsString = string.concat(
                              string.concat(importKeysJsString, '"'), 
                              string.concat(depsList[dx].key, '"')
                          );

                          if (dx != depsCount - 1) {
                              importKeysJsString = string.concat(importKeysJsString, ',');
                          }
                      }
                  }

                  importKeysJsString = string.concat(
                      string.concat(
                          importKeysJsString, 
                          string(
                              abi.encodePacked(
                                  pageWrapStore.getData("[email protected]", 1, 1)
                              )
                          )
                      ),
                      string(
                          abi.encodePacked(
                              pageWrapStore.getData("[email protected]", 0, 0)
                          )
                      )
                  );

                  result = string.concat(result, importKeysJsString);
              } 
            }
            
            // Finishing deps
            if (isIdxAssetLastDep && hasCompletedAsset) {
                if(_isImportmapWrapperString(idxAsset.wrapperKey)){
                    result = string.concat(
                        result, 
                        string(
                            abi.encodePacked(
                                pageWrapStore.getData("[email protected]", 1, 1),
                                pageWrapStore.getData("[email protected]", 1, 1),
                                pageWrapStore.getData("[email protected]", 0, 0)
                            )
                        )
                    );
                } else {
                    result = string.concat(
                        result, 
                        string(
                            abi.encodePacked(
                                pageWrapStore.getData("[email protected]", 1, 1),
                                pageWrapStore.getData("[email protected]", 0, 0)
                            )
                        )
                    );
                }
                
            }

        }

        if (_rpage == 0) {
            result = string.concat(
                string(
                    abi.encodePacked(
                        pageWrapStore.getData("[email protected]", 0, 0),
                        pageWrapStore.getData("[email protected]", 0, 0)
                    )
                ),
            result);
        }
        
        if (_rpage == (renderPagesCount - 1)) {
            result = string.concat(
                result,
                string(
                    abi.encodePacked(
                        pageWrapStore.getData("[email protected]", 1, 1), 
                        pageWrapStore.getData("[email protected]", 1, 1)
                    )
                )
            );
        }

        return result;
    }
}