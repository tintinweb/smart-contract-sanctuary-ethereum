// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import "PolybitOracle.sol";

contract PolybitOracleFactory {
    address public oracleOwner;
    PolybitOracle[] internal oracleArray;
    address[] internal oracleAddressList;
    string public oracleVersion;

    constructor(address _oracleOwner, string memory _oracleVersion) {
        oracleOwner = _oracleOwner;
        oracleVersion = _oracleVersion;
    }

    modifier onlyOracleOwner() {
        require(msg.sender == oracleOwner);
        _;
    }

    // Creates a new Oracle and stores the address in the Oracle Factory's list.
    function createOracle(
        string memory _strategyName,
        string memory _strategyId
    ) public onlyOracleOwner {
        PolybitOracle Oracle = new PolybitOracle(
            oracleVersion,
            oracleOwner,
            _strategyName,
            _strategyId
        );
        oracleArray.push(Oracle);
        oracleAddressList.push(address(Oracle));
    }

    // Returns Oracle address at index X of the Oracle list.
    function getOracle(uint256 _index) public view returns (address) {
        return oracleAddressList[_index];
    }

    // Returns an array of Oracle addresses.
    function getListOfOracles() public view returns (address[] memory) {
        return oracleAddressList;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract PolybitOracle {
    string public oracleVersion;
    string public oracleStatus;
    address public oracleOwner;
    string public strategyName;
    string public strategyId;
    address[] public targetAssetList;

    // Holds the current assets set by the Strategy for the Oracle
    struct Assets {
        string symbol;
        address tokenAddress;
        uint256 price;
        uint256 liquidity;
        uint256 rwEquallyBalanced;
        uint256 rwLiquidity;
        uint256 rwMaxAssetCap;
        uint256 lastUpdated;
    }

    Assets[] public assets;
    mapping(address => string) internal tokenAddressToSymbol;
    mapping(address => uint256) internal tokenAddressToPrice;
    mapping(address => uint256) internal tokenAddressToLiquidity;
    mapping(address => uint256) internal tokenAddressTorwEquallyBalanced;
    mapping(address => uint256) internal tokenAddressTorwLiquidity;
    mapping(address => uint256) internal tokenAddressTorwMaxAssetCap;
    mapping(address => uint256) public tokenAddressToLastUpdated;

    constructor(
        string memory _oracleVersion,
        address _oracleOwner,
        string memory _strategyName,
        string memory _strategyId
    ) {
        oracleVersion = _oracleVersion;
        oracleOwner = _oracleOwner;
        strategyName = _strategyName;
        strategyId = _strategyId;
    }

    modifier onlyOracleOwner() {
        require(msg.sender == oracleOwner);
        _;
    }

    function setOracleStatus(string memory _status) public onlyOracleOwner {
        oracleStatus = _status;
    }

    // Adds a new asset (token) to the Oracle. Checks if asset already exists to prevent duplicate entries.
    function addAsset(
        string memory _symbol,
        address _tokenAddress,
        uint256 _price,
        uint256 _liquidity,
        uint256 _rwEquallyBalanced,
        uint256 _rwLiquidity,
        uint256 _rwMaxAssetCap
    ) public onlyOracleOwner {
        bool assetExists = false;
        if (assets.length > 0) {
            for (uint256 i = 0; i < assets.length; i++) {
                if (
                    keccak256(abi.encodePacked(_tokenAddress)) ==
                    keccak256(abi.encodePacked(assets[i].tokenAddress))
                ) {
                    assetExists = true;
                }
            }
        }
        require(assetExists == false, "Asset already exists.");
        uint256 _lastUpdated = block.timestamp;
        assets.push(
            Assets({
                symbol: _symbol,
                tokenAddress: _tokenAddress,
                price: _price,
                liquidity: _liquidity,
                rwEquallyBalanced: _rwEquallyBalanced,
                rwLiquidity: _rwLiquidity,
                rwMaxAssetCap: _rwMaxAssetCap,
                lastUpdated: _lastUpdated
            })
        );
        tokenAddressToSymbol[_tokenAddress] = _symbol;
        tokenAddressToPrice[_tokenAddress] = _price;
        tokenAddressToLiquidity[_tokenAddress] = _liquidity;
        tokenAddressTorwEquallyBalanced[_tokenAddress] = _rwEquallyBalanced;
        tokenAddressTorwLiquidity[_tokenAddress] = _rwLiquidity;
        tokenAddressTorwMaxAssetCap[_tokenAddress] = _rwMaxAssetCap;
        tokenAddressToLastUpdated[_tokenAddress] = _lastUpdated;
        targetAssetList.push(_tokenAddress);
    }

    // Updates an existing asset (token). Only the variables price, liquidity, and risk weightings are updatable.
    function updateAsset(
        address _tokenAddress,
        uint256 _price,
        uint256 _liquidity,
        uint256 _rwEquallyBalanced,
        uint256 _rwLiquidity,
        uint256 _rwMaxAssetCap
    ) public onlyOracleOwner {
        uint256 _lastUpdated = block.timestamp;
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(abi.encodePacked(_tokenAddress)) ==
                keccak256(abi.encodePacked(assets[i].tokenAddress))
            ) {
                assets[i].price = _price;
                assets[i].liquidity = _liquidity;
                assets[i].rwEquallyBalanced = _rwEquallyBalanced;
                assets[i].rwLiquidity = _rwLiquidity;
                assets[i].rwMaxAssetCap = _rwMaxAssetCap;
                assets[i].lastUpdated = _lastUpdated;
                tokenAddressToPrice[_tokenAddress] = _price;
                tokenAddressToLiquidity[_tokenAddress] = _liquidity;
                tokenAddressTorwEquallyBalanced[
                    _tokenAddress
                ] = _rwEquallyBalanced;
                tokenAddressTorwLiquidity[_tokenAddress] = _rwLiquidity;
                tokenAddressTorwMaxAssetCap[_tokenAddress] = _rwMaxAssetCap;
                tokenAddressToLastUpdated[_tokenAddress] = _lastUpdated;
            }
        }
    }

    // Function to update a single variable (price). Price changes will be more volatile,
    // so this function should allow the Oracle Admin to save gas.
    function updateAssetPrice(address _tokenAddress, uint256 _price)
        public
        onlyOracleOwner
    {
        uint256 _lastUpdated = block.timestamp;
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(abi.encodePacked(_tokenAddress)) ==
                keccak256(abi.encodePacked(assets[i].tokenAddress))
            ) {
                assets[i].price = _price;
                assets[i].lastUpdated = _lastUpdated;
                tokenAddressToPrice[_tokenAddress] = _price;
                tokenAddressToLastUpdated[_tokenAddress] = _lastUpdated;
            }
        }
    }

    // Removes a single asset (token) from the Oracle.
    function removeAsset(address _tokenAddress) public onlyOracleOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(abi.encodePacked(_tokenAddress)) ==
                keccak256(abi.encodePacked(assets[i].tokenAddress))
            ) {
                require(i < assets.length);
                assets[i] = assets[assets.length - 1];
                assets.pop();
            }
        }
        for (uint256 i = 0; i < targetAssetList.length; i++) {
            if (
                keccak256(abi.encodePacked(_tokenAddress)) ==
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

    // Returns the target asset list as an array of addresses.
    function getTargetAssets() external view returns (address[] memory) {
        return targetAssetList;
    }

    // Returns the asset's symbol, given the address.
    function getTokenAddressSymbol(address _tokenAddress)
        external
        view
        returns (string memory)
    {
        string memory tokenAddressSymbol = tokenAddressToSymbol[_tokenAddress];
        return tokenAddressSymbol;
    }

    // Returns the asset's price, given the address.
    function getTokenAddressPrice(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressPrice = tokenAddressToPrice[_tokenAddress];
        return tokenAddressPrice;
    }

    // Returns the asset's liquidity, given the address.
    function getTokenAddressLiquidity(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressLiquidity = tokenAddressToLiquidity[_tokenAddress];
        return tokenAddressLiquidity;
    }

    // Returns the asset's target percentage, given the address and the wallet's risk weighting.
    function getTokenAddressTargetPercentage(
        address _tokenAddress,
        string memory _targetRiskWeighting
    ) external view returns (uint256) {
        uint256 _target = 0;
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwEquallyBalanced"))
        ) {
            _target = tokenAddressTorwEquallyBalanced[_tokenAddress];
        }
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwLiquidity"))
        ) {
            _target = tokenAddressTorwLiquidity[_tokenAddress];
        }
        if (
            keccak256(abi.encodePacked(_targetRiskWeighting)) ==
            keccak256(abi.encodePacked("rwMaxAssetCap"))
        ) {
            _target = tokenAddressTorwMaxAssetCap[_tokenAddress];
        }
        return _target;
    }

    // Returns the timestamp when the asset's information was last updated in the Oracle.
    function getTokenAddressLastUpdated(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressLastUpdated = tokenAddressToLastUpdated[
            _tokenAddress
        ];
        return tokenAddressLastUpdated;
    }
}