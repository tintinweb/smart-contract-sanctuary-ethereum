// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract accessControl {
    address oracleAdmin;

    constructor() {
        oracleAdmin = msg.sender;
    }

    modifier onlyOracleAdmin() {
        require(msg.sender == oracleAdmin);
        _;
    }
}

contract Oracle is accessControl {
    string public portfolioName;
    string public oracleVersion = "v0.0.1";
    string[] public targetAssetList;
    struct Assets {
        string symbol;
        address assetAddress;
        uint256 price;
        uint256 marketCap;
        uint256 rwEquallyBalanced;
        uint256 rwMarketCap;
        uint256 rwMaxAssetCap;
        uint256 lastUpdated;
    }

    Assets[] public assets;
    mapping(string => address) internal symbolToAssetAddress;
    mapping(string => uint256) internal symbolToPrice;
    mapping(string => uint256) internal symbolToMarketCap;
    mapping(string => uint256) internal symbolTorwEquallyBalanced;
    mapping(string => uint256) internal symbolTorwMarketCap;
    mapping(string => uint256) internal symbolTorwMaxAssetCap;
    mapping(string => uint256) public symbolToLastUpdated;

    constructor(string memory _portfolioName) {
        portfolioName = _portfolioName;
    }

    function addAsset(
        string memory _symbol,
        address _assetAddress,
        uint256 _price,
        uint256 _marketCap,
        uint256 _rwEquallyBalanced,
        uint256 _rwMarketCap,
        uint256 _rwMaxAssetCap
    ) public onlyOracleAdmin {
        uint256 _lastUpdated = block.timestamp;
        assets.push(
            Assets({
                symbol: _symbol,
                assetAddress: _assetAddress,
                price: _price,
                marketCap: _marketCap,
                rwEquallyBalanced: _rwEquallyBalanced,
                rwMarketCap: _rwMarketCap,
                rwMaxAssetCap: _rwMaxAssetCap,
                lastUpdated: _lastUpdated
            })
        );
        symbolToAssetAddress[_symbol] = _assetAddress;
        symbolToPrice[_symbol] = _price;
        symbolToMarketCap[_symbol] = _marketCap;
        symbolTorwEquallyBalanced[_symbol] = _rwEquallyBalanced;
        symbolTorwMarketCap[_symbol] = _rwMarketCap;
        symbolTorwMaxAssetCap[_symbol] = _rwMaxAssetCap;
        symbolToLastUpdated[_symbol] = _lastUpdated;
        targetAssetList.push(_symbol);
    }

    function updateAsset(
        string memory _symbol,
        uint256 _price,
        uint256 _marketCap,
        uint256 _rwEquallyBalanced,
        uint256 _rwMarketCap,
        uint256 _rwMaxAssetCap
    ) public onlyOracleAdmin {
        uint256 _lastUpdated = block.timestamp;
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(abi.encodePacked(_symbol)) ==
                keccak256(abi.encodePacked(assets[i].symbol))
            ) {
                assets[i].price = _price;
                assets[i].marketCap = _marketCap;
                assets[i].rwEquallyBalanced = _rwEquallyBalanced;
                assets[i].rwMarketCap = _rwMarketCap;
                assets[i].rwMaxAssetCap = _rwMaxAssetCap;
                assets[i].lastUpdated = _lastUpdated;
                symbolToPrice[_symbol] = _price;
                symbolToMarketCap[_symbol] = _marketCap;
                symbolTorwEquallyBalanced[_symbol] = _rwEquallyBalanced;
                symbolTorwMarketCap[_symbol] = _rwMarketCap;
                symbolTorwMaxAssetCap[_symbol] = _rwMaxAssetCap;
                symbolToLastUpdated[_symbol] = _lastUpdated;
            }
        }
    }

    function updateAssetPrice(string memory _symbol, uint256 _price)
        public
        onlyOracleAdmin
    {
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

    function removeAsset(string memory _symbol) public onlyOracleAdmin {
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

    function getSymbolTargetPercentage(
        string memory _symbol,
        string memory _targetRiskWeighting
    ) external view returns (uint256) {
        uint256 _target = 0;
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwEquallyBalanced"))
        ) {
            _target = symbolTorwEquallyBalanced[_symbol];
        }
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwMarketCap"))
        ) {
            _target = symbolTorwMarketCap[_symbol];
        }
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwMaxAssetCap"))
        ) {
            _target = symbolTorwMaxAssetCap[_symbol];
        }
        return _target;
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