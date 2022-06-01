// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

//interface OracleInterface {
//    function getTargetAssets() external view returns (string[] memory, uint256);
//}

interface STWallet {
    function getOwnedAssets() external view returns (string[] memory);

    function getTargetAssets() external view returns (string[] memory);
}

contract Rebalancer {
    // Output 1: items in owned that do not exist in target (SELL)
    event sellListEvent(string[]);

    function readOwnedAssets(address _walletAddress)
        public
        view
        returns (string[] memory)
    {
        STWallet wallet = STWallet(_walletAddress);
        return wallet.getOwnedAssets();
    }

    function readTargetAssets(address _walletAddress)
        public
        view
        returns (string[] memory)
    {
        STWallet wallet = STWallet(_walletAddress);
        return wallet.getTargetAssets();
    }

    function createSellList(address _walletAddress)
        public
        returns (string[] memory)
    {
        string[] memory _ownedSymbols = readOwnedAssets(_walletAddress);
        string[] memory _targetAssetsList = readTargetAssets(_walletAddress);

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

    function createAdjustList(address _walletAddress)
        public
        returns (string[] memory)
    {
        string[] memory _ownedSymbols = readOwnedAssets(_walletAddress);
        string[] memory _targetAssetsList = readTargetAssets(_walletAddress);

        emit adjustListEvent(_ownedSymbols);
        string[] memory adjustSymbols = new string[](5);
        uint256 index = 0;

        for (uint256 i = 0; i < _targetAssetsList.length; i++) {
            for (uint256 x = 0; x < _ownedSymbols.length; x++) {
                if (
                    keccak256(abi.encodePacked(_targetAssetsList[i])) ==
                    keccak256(abi.encodePacked(_ownedSymbols[x]))
                ) {
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

    function createBuyList(address _walletAddress)
        public
        returns (string[] memory)
    {
        string[] memory _ownedSymbols = readOwnedAssets(_walletAddress);
        string[] memory _targetAssetsList = readTargetAssets(_walletAddress);

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
}