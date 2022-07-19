/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct metaDataProof {
    address validatorAddress;
    uint8 v; // v of validator signed message
    bytes32 r; // r of validator signed message
    bytes32 s; // s of validator signed message
}

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
    function safeIncreaseAllowance(address router, uint256 amount ) external;
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

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20Template {
    struct RolesERC20 {
        bool minter;
        bool feeManager;
    }
    struct providerFee{
        address providerFeeAddress;
        address providerFeeToken; // address of the token marketplace wants to add fee on top
        uint256 providerFeeAmount; // amount to be transfered to marketFeeCollector
        uint8 v; // v of provider signed message
        bytes32 r; // r of provider signed message
        bytes32 s; // s of provider signed message
        uint256 validUntil; //validity expresses in unix timestamp
        bytes providerData; //data encoded by provider
    }
    struct consumeMarketFee{
        address consumeMarketFeeAddress;
        address consumeMarketFeeToken; // address of the token marketplace wants to add fee on top
        uint256 consumeMarketFeeAmount; // amount to be transfered to marketFeeCollector
    }
    function initialize(
        string[] calldata strings_,
        address[] calldata addresses_,
        address[] calldata factoryAddresses_,
        uint256[] calldata uints_,
        bytes[] calldata bytes_
    ) external returns (bool);
    
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address account, uint256 value) external;
    
    function isMinter(address account) external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permissions(address user)
        external
        view
        returns (RolesERC20 memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cleanFrom721() external;

    function deployPool(
        uint256[] memory ssParams,
        uint256[] memory swapFees,
        address[] memory addresses 
    ) external returns (address);

    function createFixedRate(
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) external returns (bytes32);
    function createDispenser(
        address _dispenser,
        uint256 maxTokens,
        uint256 maxBalance,
        bool withMint,
        address allowedSwapper) external;
        
    function getPublishingMarketFee() external view returns (address , address, uint256);
    function setPublishingMarketFee(
        address _publishMarketFeeAddress, address _publishMarketFeeToken, uint256 _publishMarketFeeAmount
    ) external;

     function startOrder(
        address consumer,
        uint256 serviceIndex,
        providerFee calldata _providerFee,
        consumeMarketFee calldata _consumeMarketFee
     ) external;

     function reuseOrder(
        bytes32 orderTxId,
        providerFee calldata _providerFee
    ) external;
  
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function getERC721Address() external view returns (address);
    function isERC20Deployer(address user) external view returns(bool);
    function getPools() external view returns(address[] memory);
    struct fixedRate{
        address contractAddress;
        bytes32 id;
    }
    function getFixedRates() external view returns(fixedRate[] memory);
    function getDispensers() external view returns(address[] memory);
    function getId() pure external returns (uint8);
    function getPaymentCollector() external view returns (address);
}

interface IERC721Template {
    enum RolesType {
        Manager,
        DeployERC20,
        UpdateMetadata,
        Store
    }

    function balanceOf(address owner) external view returns (uint256 balance);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isERC20Deployer(address acount) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(address from, address to) external;

    function initialize(
        address admin,
        string calldata name,
        string calldata symbol,
        address erc20Factory,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string calldata tokenURI,
        bool transferable
    ) external returns (bool);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

     struct Roles {
        bool manager;
        bool deployERC20;
        bool updateMetadata;
        bool store;
    }
    function getPermissions(address user) external view returns (Roles memory);

    function setDataERC20(bytes32 _key, bytes calldata _value) external;
    function setMetaData(uint8 _metaDataState, string calldata _metaDataDecryptorUrl
        , string calldata _metaDataDecryptorAddress, bytes calldata flags, 
        bytes calldata data,bytes32 _metaDataHash, metaDataProof[] memory _metadataProofs) external;
    function getMetaData() external view returns (string memory, string memory, uint8, bool);

    function createERC20(
        uint256 _templateIndex,
        string[] calldata strings,
        address[] calldata addresses,
        uint256[] calldata uints,
        bytes[] calldata bytess
    ) external returns (address);


    function removeFromCreateERC20List(address _allowedAddress) external;
    function addToCreateERC20List(address _allowedAddress) external;
    function addToMetadataList(address _allowedAddress) external;
    function removeFromMetadataList(address _allowedAddress) external;
    function getId() pure external returns (uint8);
}

interface IERC721Factory {
    struct Template {
        address templateAddress;
        bool isActive;
    }
    struct NftCreateData{
        string name;
        string symbol;
        uint256 templateIndex;
        string tokenURI;
        bool transferable;
        address owner;
    }
    struct ErcCreateData{
        uint256 templateIndex;
        string[] strings;
        address[] addresses;
        uint256[] uints;
        bytes[] bytess;
    }
    struct FixedData{
        address fixedPriceAddress;
        address[] addresses;
        uint256[] uints;
    }
    struct DispenserData{
        address dispenserAddress;
        uint256 maxTokens;
        uint256 maxBalance;
        bool withMint;
        address allowedSwapper;
    }
    struct MetaData {
        uint8 _metaDataState;
        string _metaDataDecryptorUrl;
        string _metaDataDecryptorAddress;
        bytes flags;
        bytes data;
        bytes32 _metaDataHash;
        metaDataProof[] _metadataProofs;
    }
    struct PoolData{
        uint256[] ssParams;
        uint256[] swapFees;
        address[] addresses;
    }

    function deployERC721Contract(
        string memory name,
        string memory symbol,
        uint256 _templateIndex,
        address additionalERC20Deployer,
        address additionalMetaDataUpdater,
        string memory tokenURI,
        bool transferable,
        address owner
    ) external returns (address token);
    function getCurrentNFTCount() external view returns (uint256);
    function getNFTTemplate(uint256 _index)
        external
        view
        returns (Template memory);
    function add721TokenTemplate(address _templateAddress)
        external
        returns (uint256);
    function disable721TokenTemplate(uint256 _index) external;
    function getCurrentNFTTemplateCount() external view returns (uint256);
     function createToken(
        uint256 _templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] memory bytess
    ) external returns (address token);
    function getCurrentTokenCount() external view returns (uint256);
    function getTokenTemplate(uint256 _index)
        external
        view
        returns (Template memory);
    function addTokenTemplate(address _templateAddress) external returns (uint256);
    function createNftWithErc20(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData
    ) external returns (address erc721Address, address erc20Address);
    function createNftWithErc20WithPool(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        PoolData calldata _PoolData
    ) external returns (address erc721Address, address erc20Address, address poolAddress);
    function createNftWithErc20WithFixedRate(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        FixedData calldata _FixedData
    ) external returns (address erc721Address, address erc20Address, bytes32 exchangeId);
    function createNftWithErc20WithDispenser(
        NftCreateData calldata _NftCreateData,
        ErcCreateData calldata _ErcCreateData,
        DispenserData calldata _DispenserData
    ) external returns (address erc721Address, address erc20Address);
    function createNftWithMetaData(
        NftCreateData calldata _NftCreateData,
        MetaData calldata _MetaData
    ) external returns (address erc721Address);
}

contract ValueShareCommunity is IERC721Receiver {
    IERC721Factory _erc721Factory;
    address public coOwner1;
    address public coOwner2;

    address _erc721FactoryAddress = 0x465069D3d6Ec45CDB006ec3E22cC9E8d6f9793eF; // 0x03ABAd83b9f2F182D6C9d3FA70619Abc2edc8ccC
    address _fixedExchangeAddress = 0x65Ee19cd86dE140fE08Bfd5d51e62Fe53e96358f;

    mapping(address => uint) public distribution;

    modifier authCoowner() {
      require(msg.sender == coOwner1 || msg.sender == coOwner2, "!Coowner");
      _;
    }

    struct DataAsset {
        address erc721Address;
        address erc20Address;
        bytes32 exchangeId;
    }

    DataAsset[] public dataAssets;

    constructor(address owner1, address owner2) {
        _erc721Factory = IERC721Factory(_erc721FactoryAddress);
        coOwner1 = owner1;
        coOwner2 = owner2;
        distribution[coOwner1] = 50;
        distribution[coOwner2] = 50;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function deployERC721Contract(
        string memory name,
        string memory symbol,
        uint256 _templateIndex, // 1
        address additionalERC20Deployer, // address(this)
        address additionalMetaDataUpdater, // address(this)
        string memory tokenURI,
        address nftOwner // Should be account address
    ) public authCoowner {
        address nftAddress = _erc721Factory.deployERC721Contract(name, symbol, _templateIndex, additionalERC20Deployer, additionalMetaDataUpdater, tokenURI, true, nftOwner);
        dataAssets.push(DataAsset(nftAddress, address(0), ""));
    }

    function createERC20(
        uint256 dataAssetId,
        string memory name,
        string memory symbol,
        uint256 cap, // 10000000000000000000000
        uint256 feeAmount, // 0
        bytes[] calldata bytess // []
    ) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        string[] memory strings = new string[](2);
        strings[0] = name;
        strings[1] = symbol;

        address[] memory addresses = new address[](4);
        addresses[0] = address(this);
        addresses[1] = address(0);
        addresses[2] = address(0);
        addresses[3] = address(0);

        uint256[] memory uints = new uint256[](2);
        uints[0] = cap;
        uints[1] = feeAmount;

        dataAssets[dataAssetId].erc20Address = _createERC20(
            dataAsset.erc721Address,
            1,
            strings,
            addresses,
            uints,
            bytess
        );
    }

    function _createERC20(
        address nftAddress,
        uint256 _templateIndex,
        string[] memory strings,
        address[] memory addresses,
        uint256[] memory uints,
        bytes[] calldata bytess
    ) public authCoowner returns (address) {
        IERC721Template nft = IERC721Template(nftAddress);
        return nft.createERC20(_templateIndex, strings, addresses, uints, bytess);
    }

    function createFixedRate(
        uint256 dataAssetId,
        address[] memory addresses,
        uint[] memory uints
    ) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];

        dataAssets[dataAssetId].exchangeId = _createFixedRate(
            dataAsset.erc20Address, _fixedExchangeAddress, addresses, uints
        );
    }

    function _createFixedRate(
        address erc20Address,
        address fixedPriceAddress,
        address[] memory addresses,
        uint[] memory uints
    ) public authCoowner returns (bytes32) {
        IERC20Template erc20 = IERC20Template(erc20Address);
        return erc20.createFixedRate(fixedPriceAddress, addresses, uints);
    }

    function setMetaData(
        uint256 dataAssetId,
        uint8 _metaDataState,
        string calldata _metaDataDecryptorUrl,
        string calldata _metaDataDecryptorAddress,
        bytes calldata flags,
        bytes calldata data,
        bytes32 _metaDataHash,
        metaDataProof[] memory _metadataProofs
    ) public authCoowner {
        DataAsset memory dataAsset = dataAssets[dataAssetId];
        _setMetaData(dataAsset.erc721Address, _metaDataState, _metaDataDecryptorUrl, _metaDataDecryptorAddress, flags, data, _metaDataHash, _metadataProofs);
    }

    /*
    --- Generate metadata ---
    import pdb
    import requests
    import hashlib

    NFT_ADDRESS = '0xe89a6e82018a0281d620D74b30897B61CA7F6b71'
    DATATOKEN_ADDRESS = '0xba722EfDf8cF177A3C01e63a2ef889C2F889688D'
    FILE_LINK = 'https://filesamples.com/samples/code/json/sample2.json'

    headers = {
        'authority': 'v4.provider.rinkeby.oceanprotocol.com',
        'accept-language': 'en-US,en;q=0.9',
        'content-type': 'application/octet-stream',
        'origin': 'https://v4.market.oceanprotocol.com',
        'referer': 'https://v4.market.oceanprotocol.com/',
        'sec-ch-ua': '" Not A;Brand";v="99", "Chromium";v="100", "Google Chrome";v="100"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-site',
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36',
    }

    id = "did:op:" + hashlib.sha256((NFT_ADDRESS+'4').encode()).hexdigest()

    data = [{"type": "url", "url": FILE_LINK, "method": "GET"}]

    response = requests.post('https://v4.provider.rinkeby.oceanprotocol.com/api/services/encrypt', headers=headers, json=data)
    encrypted_files = response.text

    data = {
        "@context": [
            "https://w3id.org/did/v1"
        ],
        "id": id,
        "nftAddress": NFT_ADDRESS,
        "version": "4.0.0",
        "chainId": 4,
        "metadata": {
            "created": "2022-04-22T11:50:12Z",
            "updated": "2022-04-22T11:53:12Z",
            "type": "dataset",
            "name": "Test4",
            "description": "TestTestTest",
            "tags": [
                "test"
            ],
            "author": "Test",
            "license": "https://market.oceanprotocol.com/terms",
            "links": [
                FILE_LINK
            ],
            "additionalInformation": {
                "termsAndConditions": True
            }
        },
        "services": [
            {
                "id": 'testFakeId',
                "type": "access",
                "files": encrypted_files,
                "datatokenAddress": DATATOKEN_ADDRESS,
                "serviceEndpoint": "https://v4.provider.rinkeby.oceanprotocol.com",
                "timeout": 0
            }
        ]
    }
    response = requests.post(
        'https://v4.provider.rinkeby.oceanprotocol.com/api/services/encrypt', headers=headers, json=data)
    encryptedDdo  = response.text

    response = requests.post(
        'https://v4.aquarius.oceanprotocol.com/api/aquarius/assets/ddo/validate', headers=headers, json=data)
    */
    function _setMetaData(
        address nftAddress,
        uint8 _metaDataState, // 0
        string calldata _metaDataDecryptorUrl, // https://v4.provider.rinkeby.oceanprotocol.com
        string calldata _metaDataDecryptorAddress, // address(this)
        bytes calldata flags, // 0x02
        bytes calldata data,  // 
        bytes32 _metaDataHash, // 
        metaDataProof[] memory _metadataProofs //
    ) public authCoowner {
        IERC721Template nft = IERC721Template(nftAddress);
        nft.setMetaData(_metaDataState, _metaDataDecryptorUrl, _metaDataDecryptorAddress, flags, data, _metaDataHash, _metadataProofs);   
    }


// [[[Test6,TEST6,'1',https://filesamples.com/samples/code/json/sample2.json,true,'0xE5a35520B7F1cB5ff2Fb723AdD9847c509A7e546']]]
// [[1,[Test6,TEST6],[0xE5a35520B7F1cB5ff2Fb723AdD9847c509A7e546,'0xE5a35520B7F1cB5ff2Fb723AdD9847c509A7e546','0x0000000000000000000000000000000000000000','0x0000000000000000000000000000000000000000'],[10000000000000000000000,0],[]]]
// [[[1,'18','10000','2500000',2000],[1000000000000000,1000000000000000],['0xb0889Fd1146Ff6ab513Ca40e142E13e769b6d813','0x8967BCF84170c91B0d24D4302C2376283b0B3a07','0x6eb0184B64f22fB5e1316221E1eC84988F9E6b12','0xDb01217D8D2f39750e352c70c59E8B35C9e05aeE','0xDb01217D8D2f39750e352c70c59E8B35C9e05aeE','0x33445729086BBEA45305DAB2a4bb148FBc221A22']]]
// [['0x65Ee19cd86dE140fE08Bfd5d51e62Fe53e96358f', ['0x8967BCF84170c91B0d24D4302C2376283b0B3a07','0xE5a35520B7F1cB5ff2Fb723AdD9847c509A7e546','0x9984b2453eC7D99a73A5B3a46Da81f197B753C8d','0x0000000000000000000000000000000000000000'], [18,18,1000000000000000000,0,1]]

    function createNftWithErc20WithFixedRate(
        IERC721Factory.NftCreateData calldata _NftCreateData,
        IERC721Factory.ErcCreateData calldata _ErcCreateData,
        IERC721Factory.FixedData calldata _FixedData
    ) public authCoowner {
        (address erc721Address, address erc20Address, bytes32 exchangeId) = _erc721Factory.createNftWithErc20WithFixedRate(_NftCreateData, _ErcCreateData, _FixedData);
        dataAssets.push(DataAsset(erc721Address, erc20Address, exchangeId));
    }
}