// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface OracleInterface {
    function getTargetAssets() external view returns (string[] memory, uint256);
}

contract Rebalancer {
    // Output 1: items in owned that do not exist in target (SELL)
    event sellListEvent(string[]);

    function sellList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssetsList
    ) internal returns (string[] memory) {
        string[] memory sellSymbols = new string[](5);
        uint256 index = 0;
        for (uint256 x = 0; x < _ownedSymbols.length; x++) {
            for (uint256 i = 0; i < _targetAssetsList.length; i++) {
                if (
                    keccak256(abi.encodePacked(_ownedSymbols[x])) ==
                    keccak256(abi.encodePacked(_targetAssetsList[i]))
                ) {
                    if (x < _ownedSymbols.length) {
                        _ownedSymbols[x] = "!Removed!";
                    } else {
                        delete _ownedSymbols;
                    }
                }
            }
            if (
                keccak256(abi.encodePacked(_ownedSymbols[x])) !=
                keccak256(abi.encodePacked("!Removed!"))
            ) {
                sellSymbols[index] = _ownedSymbols[x];
                index = index + 1;
            }
        }
        emit sellListEvent(sellSymbols);
        return sellSymbols;
    }

    // Output 2: items in target that exist in owned (ADJUST)
    event adjustListEvent(string[]);
    event adjustListItem(string);

    function adjustList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssetsList
    ) internal returns (string[] memory) {
        emit adjustListEvent(_ownedSymbols);
        string[] memory adjustSymbols = new string[](5);
        uint256 index = 0;

        for (uint256 i = 0; i < _targetAssetsList.length; i++) {
            for (uint256 x = 0; x < _ownedSymbols.length; x++) {
                if (
                    keccak256(abi.encodePacked(_targetAssetsList[i])) ==
                    keccak256(abi.encodePacked(_ownedSymbols[x]))
                ) {
                    emit adjustListItem(_ownedSymbols[x]);
                    adjustSymbols[index] = _ownedSymbols[x];
                    index = index + 1;
                }
            }
        }
        emit adjustListEvent(adjustSymbols);
        return adjustSymbols;
    }

    // Output 3: items in target that do not exist in owned (BUY)
    event buyListEvent(string[]);

    function buyList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssetsList
    ) internal returns (string[] memory) {
        string[] memory buySymbols = new string[](5);
        uint256 index = 0;

        for (uint256 x = 0; x < _targetAssetsList.length; x++) {
            for (uint256 i = 0; i < _ownedSymbols.length; i++) {
                if (
                    keccak256(abi.encodePacked(_targetAssetsList[x])) ==
                    keccak256(abi.encodePacked(_ownedSymbols[i]))
                ) {
                    if (x < _targetAssetsList.length) {
                        _targetAssetsList[x] = "!Removed!";
                    } else {
                        delete _targetAssetsList;
                    }
                }
            }
            if (
                keccak256(abi.encodePacked(_targetAssetsList[x])) !=
                keccak256(abi.encodePacked("!Removed!"))
            ) {
                buySymbols[index] = _targetAssetsList[x];
                index = index + 1;
            }
        }
        emit buyListEvent(buySymbols);
        return buySymbols;
    }

    //
    // INTERFACE FOR WALLET
    //
    //string[] public ownedSymbols = ["A", "B", "Z", "D"];
    //string[] public targetAssets = ["B", "Z", "Q"];
    string[] public sellSymbolsList;
    string[] public adjustSymbolsList;
    string[] public buySymbolsList;

    function getSellList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssets
    ) internal {
        string[] memory sellResult = sellList(_ownedSymbols, _targetAssets);
        for (uint256 x = 0; x < sellResult.length; x++) {
            if (
                keccak256(abi.encodePacked(sellResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                sellSymbolsList.push(sellResult[x]);
            }
        }
    }

    function getAdjustList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssets
    ) internal {
        string[] memory adjustResult = adjustList(_ownedSymbols, _targetAssets);
        for (uint256 x = 0; x < adjustResult.length; x++) {
            if (
                keccak256(abi.encodePacked(adjustResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                adjustSymbolsList.push(adjustResult[x]);
            }
        }
    }

    function getBuyList(
        string[] memory _ownedSymbols,
        string[] memory _targetAssets
    ) internal {
        string[] memory buyResult = buyList(_ownedSymbols, _targetAssets);
        for (uint256 x = 0; x < buyResult.length; x++) {
            if (
                keccak256(abi.encodePacked(buyResult[x])) !=
                keccak256(abi.encodePacked(""))
            ) {
                buySymbolsList.push(buyResult[x]);
            }
        }
    }

    function getTargetAssets(string[] memory _owned, string[] memory _target)
        public
    {
        //(string[] memory targetAssets, ) = OracleInterface(_oracleAddress)
        //    .getTargetAssets();
        getSellList(_owned, _target);
        getAdjustList(_owned, _target);
        getBuyList(_owned, _target);
    }
}