/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.7;

interface IERC20 {
    function initialize(
        string calldata name,
        string calldata symbol,
        address minter,
        uint256 cap,
        string calldata blob,
        address collector
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    function minter() external view returns(address);    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function cap() external view returns (uint256);
    function isMinter(address account) external view returns (bool);
    function isInitialized() external view returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function proposeMinter(address newMinter) external;
    function approveMinter() external;
}

interface IDTFactory {
    function createToken(string calldata blob, string calldata name, string calldata symbol, uint256 cap) external returns (address token);
    function getCurrentTokenCount() external view returns (uint256);
    function getTokenTemplate() external view returns (address);
    event TokenCreated(
        address indexed newTokenAddress,
        address indexed templateAddress,
        string indexed tokenName
    );

    event TokenRegistered(
        address indexed tokenAddress,
        string tokenName,
        string tokenSymbol,
        uint256 tokenCap,
        address indexed registeredBy,
        string indexed blob
    );
}

interface IBFactory {
    function newBPool() external returns (address bpool);
    event BPoolCreated(
        address indexed newBPoolAddress,
        address indexed bpoolTemplateAddress
    );
    
    event BPoolRegistered(
        address bpoolAddress,
        address indexed registeredBy
    );
}

interface IMetadata {
    function create(
        address dataToken,
        bytes calldata flags,
        bytes calldata data
    ) external;
    function update(
        address dataToken,
        bytes calldata flags,
        bytes calldata data
    ) external;
}

interface IBPool {
    function setup(
        address dataTokenAddress, 
        uint256 dataTokenAmount,
        uint256 dataTokenWeight,
        address baseTokenAddress, 
        uint256 baseTokenAmount,
        uint256 baseTokenWeight,
        uint256 swapFee
    ) external;
}

contract ShareOwnership {
    IDTFactory _dtFactory;
    IBFactory _bFactory;
    IMetadata _metaData;
    address public coOwner1;
    address public coOwner2;

    struct DataAsset {
        string blob;
        string name;
        string symbol;
        string author;
        uint256 cap;
        address creator;
        address dataTokenAddress;
        address bpoolAddress;
    }

    mapping(address => uint) public distribution;
    mapping(address => uint) initialLiquidity;
    DataAsset[] public dataAssets;


    modifier authCoowner() {
      require(msg.sender == coOwner1 || msg.sender == coOwner2, "!Coowner");
      _;
    }

    constructor(address owner1, address owner2) public {
        _dtFactory = IDTFactory(0x3fd7A00106038Fb5c802c6d63fa7147Fe429E83a);
        _bFactory = IBFactory(0x53eDF9289B0898e1652Ce009AACf8D25fA9A42F8);
        _metaData = IMetadata(0xFD8a7b6297153397B7eb4356C47dbd381d58bFF4);
        coOwner1 = owner1;
        coOwner2 = owner2;
        distribution[coOwner1] = 50;
        distribution[coOwner2] = 50;
    }

    /**
     * @dev addInitialLiquidity
     *      Add initial liquidity to the smart contract which will then 
     *      be used to add initial liquidity to the data asset’s 
     *      liquidity pool for dynamic pricing.
     * @param amount is initial liquidity amount
     */
    function addInitialLiquidity(uint amount) external authCoowner {
      require(amount > 0, "0 amount");
      initialLiquidity[msg.sender] += amount;
    }

    /**
     * @dev createDataAsset
     *      Create a data asset
     * @param blob is blob of the new data asset
     * @param name token name
     * @param symbol token symbol
     * @param cap the maximum total supply
     * @param author is author of the new data asset
     */
    function createDataAsset(string calldata blob, string calldata name, string calldata symbol, string calldata author, uint256 cap) external authCoowner {
      address dataTokenAddress = _dtFactory.createToken(blob, name, symbol, cap);
      dataAssets.push(DataAsset(blob, name, symbol, author, cap, msg.sender, dataTokenAddress, address(0)));
    }

    function mint(uint256 dataAssetId) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        _mint(dataAsset.dataTokenAddress, dataAsset.cap);
    }
    
    function _mint(address dataTokenAddress, uint256 amount) public authCoowner {
        IERC20 dataToken = IERC20(dataTokenAddress);
        // uint256 decimals = dataToken.decimals();
        dataToken.mint(address(this), amount);
    }

    function minter(uint256 dataAssetId) public view authCoowner returns (address) {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        return _minter(dataAsset.dataTokenAddress);
    }

    function _minter(address dataTokenAddress) public view authCoowner returns (address) {
        IERC20 dataToken = IERC20(dataTokenAddress);
        return dataToken.minter();
    }

    function createMetadata(uint256 dataAssetId, bytes memory flags, bytes memory data) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        _createMetadata(dataAsset.dataTokenAddress, flags, data);
    }

    function _createMetadata(address dataTokenAddress, bytes memory flags, bytes memory data) public authCoowner {
        _metaData.create(dataTokenAddress, flags, data);
    }

    function newBPool(uint256 dataAssetId) public authCoowner {
        DataAsset storage dataAsset = dataAssets[dataAssetId];
        dataAsset.bpoolAddress = _bFactory.newBPool();
    }

    function approve(uint256 dataAssetId) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        IERC20 dataToken = IERC20(dataAsset.dataTokenAddress);
        // uint256 decimals = dataToken.decimals();
        dataToken.approve(dataAsset.bpoolAddress, dataAsset.cap);
        IERC20 baseToken = IERC20(0x8967BCF84170c91B0d24D4302C2376283b0B3a07);
        // uint256 decimals = dataToken.decimals();
        baseToken.approve(dataAsset.bpoolAddress, dataAsset.cap);
    }

    function setupBPool(
        uint256 dataAssetId,
        uint256 dataTokenAmount,
        uint256 dataTokenWeight,
        address baseTokenAddress, // OCEAN token address on linkeby is 0x8967BCF84170c91B0d24D4302C2376283b0B3a07
        uint256 baseTokenAmount,
        uint256 baseTokenWeight,
        uint256 swapFee
    ) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        _setupBPool(dataAsset.bpoolAddress, dataAsset.dataTokenAddress, dataTokenAmount, dataTokenWeight, baseTokenAddress, baseTokenAmount, baseTokenWeight, swapFee);
    }

    function _setupBPool(
        address bpoolAddress,
        address dataTokenAddress, 
        uint256 dataTokenAmount,
        uint256 dataTokenWeight,
        address baseTokenAddress, 
        uint256 baseTokenAmount,
        uint256 baseTokenWeight,
        uint256 swapFee
    ) public authCoowner {
        IBPool bPool = IBPool(bpoolAddress);
        bPool.setup(dataTokenAddress, dataTokenAmount, dataTokenWeight, baseTokenAddress, baseTokenAmount, baseTokenWeight, swapFee);
    }

    function claim(uint256 dataAssetId) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        _claim(dataAsset.dataTokenAddress);
    }

    function _claim(address dataTokenAddress) public authCoowner {
        IERC20 dataToken = IERC20(dataTokenAddress);
        uint256 balance = dataToken.balanceOf(address(this));

        uint256 amount1 = balance * distribution[coOwner1] / 100;
        uint256 amount2 = balance * distribution[coOwner2] / 100;

        dataToken.transfer(coOwner1, amount1);
        dataToken.transfer(coOwner2, amount2);
    }
}