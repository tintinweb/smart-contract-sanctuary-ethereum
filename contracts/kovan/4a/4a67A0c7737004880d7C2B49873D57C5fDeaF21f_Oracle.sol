/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
    function getTargetAssets()
        external
        view
        returns (
            string[] memory,
            uint256,
            uint256
        );

    function getSymbolAddress() external view returns (address);
    function getSymbolPrice() external view returns (uint256);
    function getSymbolMarketCap() external view returns (uint256);
    function getSymbolTargetPercentage() external view returns (uint256);
}

contract Owner {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Oracle is Owner {
    string public portfolio_name = "polygon_ecosystem_gaming_top_5";
    string public version = "v0.01";
    string[] public targetAssetList;
    struct Assets {
        string symbol;
        address assetAddress;
        uint256 price;
        uint256 marketCap;
        uint256 targetPercentage;
        uint256 lastUpdated;
    }

    Assets[] public assets;
    mapping(string => address) public symbolToAssetAddress;
    mapping(string => uint256) public symbolToPrice;
    mapping(string => uint256) public symbolToMarketCap;
    mapping(string => uint256) public symbolToTargetPercentage;
    mapping(string => uint256) public symbolToLastUpdated;

    function addAsset(
        string memory _symbol,
        address _assetAddress,
        uint256 _price,
        uint256 _marketCap,
        uint256 _targetPercentage
    ) public onlyOwner {
        uint256 _lastUpdated = block.timestamp;
        assets.push(
            Assets({
                symbol: _symbol,
                assetAddress: _assetAddress,
                price: _price,
                marketCap: _marketCap,
                targetPercentage: _targetPercentage,
                lastUpdated: _lastUpdated
            })
        );
        symbolToAssetAddress[_symbol] = _assetAddress;
        symbolToPrice[_symbol] = _price;
        symbolToMarketCap[_symbol] = _marketCap;
        symbolToTargetPercentage[_symbol] = _targetPercentage;
        symbolToLastUpdated[_symbol] = _lastUpdated;
        targetAssetList.push(_symbol);
    }

    function updateAsset(
        string memory _symbol,
        uint256 _price,
        uint256 _marketCap,
        uint256 _targetPercentage) public onlyOwner {
            uint256 _lastUpdated = block.timestamp;
            for (uint256 i = 0; i < assets.length; i++) {
                if (
                    keccak256(abi.encodePacked(_symbol)) ==
                    keccak256(abi.encodePacked(assets[i].symbol))
                ) {
                    assets[i].price = _price;
                    assets[i].marketCap = _marketCap;
                    assets[i].targetPercentage = _targetPercentage;
                    assets[i].lastUpdated = _lastUpdated;
                    symbolToPrice[_symbol] = _price;
                    symbolToMarketCap[_symbol] = _marketCap;
                    symbolToTargetPercentage[_symbol] = _targetPercentage;
                    symbolToLastUpdated[_symbol] = _lastUpdated;
                }
            }
    }

    function updateAssetPrice(
        string memory _symbol,
        uint256 _price) public onlyOwner {
            uint256 _lastUpdated = block.timestamp;
            for (uint256 i = 0; i < assets.length; i++) {
                if (
                    keccak256(abi.encodePacked(_symbol)) ==
                    keccak256(abi.encodePacked(assets[i].symbol))
                ) {
                    assets[i].price = _price;
                    assets[i].lastUpdated = _lastUpdated;
                    symbolToPrice[_symbol] = _price;
                    symbolToLastUpdated[_symbol] = _lastUpdated;
                }
            }
    }

    function removeAsset(string memory _symbol) public onlyOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(abi.encodePacked(_symbol)) ==
                keccak256(abi.encodePacked(assets[i].symbol))
            ) {
                require(i < assets.length);
                assets[i] = assets[assets.length - 1];
                assets.pop();
            }
        }
        for (uint256 i = 0; i < targetAssetList.length; i++) {
            if (
                keccak256(abi.encodePacked(_symbol)) ==
                keccak256(abi.encodePacked(targetAssetList[i]))
            ) {
                require(i < targetAssetList.length);
                targetAssetList[i] = targetAssetList[
                    targetAssetList.length - 1
                ];
                targetAssetList.pop();
            }
        }
    }

    function getTargetAssets()
        external
        view
        returns (string[] memory, uint256)
    {
        uint256 listLength = targetAssetList.length;
        return (targetAssetList, listLength);
    }

    function getSymbolAddress(string memory _symbol)
        external
        view
        returns (address)
    {
        address symbolAddress = symbolToAssetAddress[_symbol];
        return (symbolAddress);
    }

    function getSymbolPrice(string memory _symbol)
        external
        view
        returns (uint256)
    {
        uint256 symbolPrice = symbolToPrice[_symbol];
        return (symbolPrice);
    }

    function getSymbolMarketCap(string memory _symbol)
        external
        view
        returns (uint256)
    {
        uint256 symbolMarketCap = symbolToMarketCap[_symbol];
        return (symbolMarketCap);
    }

    function getSymbolTargetPercentage(string memory _symbol)
        external
        view
        returns (uint256)
    {
        uint256 symbolTargetPercentage = symbolToTargetPercentage[_symbol];
        return (symbolTargetPercentage);
    }

    function getSymbolLastUpdated(string memory _symbol)
        external
        view
        returns (uint256)
    {
        uint256 symbolLastUpdated = symbolToLastUpdated[_symbol];
        return (symbolLastUpdated);
    }
}