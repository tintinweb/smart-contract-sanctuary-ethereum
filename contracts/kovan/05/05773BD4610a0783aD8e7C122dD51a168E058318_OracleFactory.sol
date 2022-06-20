pragma solidity >0.8.0;

import "Oracle.sol";

contract OracleFactory {
    address public oracleOwner;
    Oracle[] internal oracleArray;
    address[] internal oracleAddressList;
    string public oracleVersion;

    constructor(string memory _oracleVersion) {
        oracleOwner = msg.sender;
        oracleVersion = _oracleVersion;
    }

    event Event(string msg, address ref);

    function createOracle(
        string memory _portfolioName,
        string memory _portfolioId
    ) public {
        Oracle SpaceTimeOracle = new Oracle(
            oracleVersion,
            oracleOwner,
            _portfolioName,
            _portfolioId
        );
        oracleArray.push(SpaceTimeOracle);
        oracleAddressList.push(address(SpaceTimeOracle));

        emit Event("address", address(oracleAddressList[0]));
    }

    function getOracle(uint256 _index) public view returns (address) {
        return oracleAddressList[_index];
    }

    function getListOfOracles() public view returns (address[] memory) {
        return oracleAddressList;
    }
}

pragma solidity ^0.8.0;

contract Oracle {
    address public oracleOwner;
    string public portfolioName;
    string public portfolioId;
    string public oracleVersion;
    address[] public targetAssetList;
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
        string memory _portfolioName,
        string memory _portfolioId
    ) {
        oracleVersion = _oracleVersion;
        oracleOwner = _oracleOwner;
        portfolioName = _portfolioName;
        portfolioId = _portfolioId;
    }

    modifier onlyOracleOwner() {
        require(msg.sender == oracleOwner);
        _;
    }

    function addAsset(
        string memory _symbol,
        address _tokenAddress,
        uint256 _price,
        uint256 _liquidity,
        uint256 _rwEquallyBalanced,
        uint256 _rwLiquidity,
        uint256 _rwMaxAssetCap
    ) public onlyOracleOwner {
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

    function getTargetAssets()
        external
        view
        returns (address[] memory, uint256)
    {
        uint256 listLength = targetAssetList.length;
        return (targetAssetList, listLength);
    }

    function getTokenAddressSymbol(address _tokenAddress)
        external
        view
        returns (string memory)
    {
        string memory tokenAddressSymbol = tokenAddressToSymbol[_tokenAddress];
        return (tokenAddressSymbol);
    }

    function getTokenAddressPrice(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressPrice = tokenAddressToPrice[_tokenAddress];
        return (tokenAddressPrice);
    }

    function getTokenAddressLiquidity(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressLiquidity = tokenAddressToLiquidity[_tokenAddress];
        return (tokenAddressLiquidity);
    }

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

    function getTokenAddressLastUpdated(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        uint256 tokenAddressLastUpdated = tokenAddressToLastUpdated[
            _tokenAddress
        ];
        return (tokenAddressLastUpdated);
    }
}