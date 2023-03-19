// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "VersionedOwnable.sol";

import "IInstanceRegistryFacade.sol";
import "IInstanceServiceFacade.sol";

import "IChainRegistry.sol";
import "IChainNft.sol";

// registers dip relevant objects for this chain
contract ChainRegistryV01 is
    VersionedOwnable,
    IChainRegistry
{
    using StringsUpgradeable for uint;
    using StringsUpgradeable for address;

    string public constant BASE_DID = "did:nft:eip155:";
    
    // responsibility of dip foundation
    ObjectType public constant UNDEFINED = ObjectType.wrap(0); // detection of uninitialized variables
    ObjectType public constant PROTOCOL = ObjectType.wrap(1); // dip ecosystem overall
    ObjectType public constant CHAIN = ObjectType.wrap(2); // dip ecosystem reach: a registry per chain
    ObjectType public constant REGISTRY = ObjectType.wrap(3); // dip ecosystem reach: a registry per chain
    ObjectType public constant TOKEN = ObjectType.wrap(4); // dip ecosystem token whitelisting (premiums, risk capital)

    // involvement of dip holders
    ObjectType public constant STAKE = ObjectType.wrap(10);

    // responsibility of instance operators
    ObjectType public constant INSTANCE = ObjectType.wrap(20);
    ObjectType public constant PRODUCT = ObjectType.wrap(21);
    ObjectType public constant ORACLE = ObjectType.wrap(22);
    ObjectType public constant RISKPOOL = ObjectType.wrap(23);

    // responsibility of product owners
    ObjectType public constant POLICY = ObjectType.wrap(30);

    // responsibility of riskpool keepers
    ObjectType public constant BUNDLE = ObjectType.wrap(40);

    // keep trak of nft meta data
    mapping(NftId id => NftInfo info) internal _info;
    mapping(ObjectType t => bool isSupported) internal _typeSupported; // which nft types are currently supported for minting

    // keep track of chains and registries
    mapping(ChainId chain => NftId id) internal _chain;
    mapping(ChainId chain => NftId id) internal _registry;
    ChainId [] internal _chainIds;

    // keep track of objects per chain and type
    mapping(ChainId chain => mapping(ObjectType t => NftId [] ids)) internal _object; // which erc20 on which chains are currently supported for minting

    // keep track of objects with a contract address (tokens, instances)
    mapping(ChainId chain => mapping(address implementation => NftId id)) internal _contractObject; // which erc20 on which chains are currently supported for minting

    // keep track of instances, comonents and bundles
    mapping(bytes32 instanceId => NftId id) internal _instance; // which erc20 on which chains are currently supported for minting
    mapping(bytes32 instanceId => mapping(uint256 componentId => NftId id)) internal _component; // which erc20 on which chains are currently supported for minting
    mapping(bytes32 instanceId => mapping(uint256 bundleId => NftId id)) internal _bundle; // which erc20 on which chains are currently supported for minting

    // registy internal data
    IChainNft internal _nft;
    ChainId internal _chainId;
    IStaking internal _staking;
    Version internal _version;


    modifier onlyExisting(NftId id) {
        require(exists(id), "ERROR:CRG-001:TOKEN_ID_INVALID");
        _;
    }


    modifier onlyRegisteredToken(ChainId chain, address token) {
        NftId id = _contractObject[chain][token];
        require(NftId.unwrap(id) > 0, "ERROR:CRG-002:TOKEN_NOT_REGISTERED");
        require(_info[id].t == TOKEN, "ERROR:CRG-003:ADDRESS_NOT_TOKEN");
        _;
    }


    modifier onlyRegisteredInstance(bytes32 instanceId) {
        require(NftId.unwrap(_instance[instanceId]) > 0, "ERROR:CRG-005:INSTANCE_NOT_REGISTERED");
        _;
    }


    modifier onlyRegisteredComponent(bytes32 instanceId, uint256 componentId) {
        require(NftId.unwrap(_component[instanceId][componentId]) > 0, "ERROR:CRG-006:COMPONENT_NOT_REGISTERED");
        _;
    }


    modifier onlyActiveRiskpool(bytes32 instanceId, uint256 riskpoolId) {
        require(NftId.unwrap(_component[instanceId][riskpoolId]) > 0, "ERROR:CRG-010:RISKPOOL_NOT_REGISTERED");
        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.ComponentType cType = instanceService.getComponentType(riskpoolId);
        require(cType == IInstanceServiceFacade.ComponentType.Riskpool, "ERROR:CRG-011:COMPONENT_NOT_RISKPOOL");
        IInstanceServiceFacade.ComponentState state = instanceService.getComponentState(riskpoolId);
        require(state == IInstanceServiceFacade.ComponentState.Active, "ERROR:CRG-012:RISKPOOL_NOT_ACTIVE");
        _;
    }


    modifier onlySameChain(bytes32 instanceId) {
        NftId id = _instance[instanceId];
        require(NftId.unwrap(id) > 0, "ERROR:CRG-020:INSTANCE_NOT_REGISTERED");
        require(block.chainid == toInt(_info[id].chain), "ERROR:CRG-021:DIFFERENT_CHAIN_NOT_SUPPORTED");
        _;
    }


    modifier onlyStaking() {
        require(msg.sender == address(_staking), "ERROR:CRG-030:SENDER_NOT_STAKING");
        _;
    }


    // IMPORTANT 1. version needed for upgradable versions
    // _activate is using this to check if this is a new version
    // and if this version is higher than the last activated version
    function version() public override virtual pure returns(Version) {
        return toVersion(
            toVersionPart(0),
            toVersionPart(1),
            toVersionPart(0));
    }

    // IMPORTANT 2. activate implementation needed
    // is used by proxy admin in its upgrade function
    function activateAndSetOwner(
        address implementation,
        address newOwner,
        address activatedBy
    )
        external
        virtual override
        initializer
    {
        // ensure proper version history
        _activate(implementation, activatedBy);

        // initialize open zeppelin contracts
        __Ownable_init();

        // set main internal variables
        _version = version();
        _chainId = toChainId(block.chainid);

        // set types supported by this version
        _typeSupported[PROTOCOL] = true;
        _typeSupported[CHAIN] = true;
        _typeSupported[REGISTRY] = true;
        _typeSupported[TOKEN] = true;
        _typeSupported[INSTANCE] = true;
        _typeSupported[RISKPOOL] = true;
        _typeSupported[BUNDLE] = true;
        _typeSupported[STAKE] = true;

        transferOwnership(newOwner);
    }


    function setNftContract(
        address nft,
        address newOwner
    )
        external
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ERROR:CRG-040:NEW_OWNER_ZERO");

        require(address(_nft) == address(0), "ERROR:CRG-041:NFT_ALREADY_SET");
        require(nft != address(0), "ERROR:CRG-042:NFT_ADDRESS_ZERO");

        IChainNft nftContract = IChainNft(nft);
        require(nftContract.implementsIChainNft(), "ERROR:CRG-043:NFT_NOT_ICHAINNFT");

        _nft = nftContract;

        // register/mint dip protocol on mainnet and goerli
        if(toInt(_chainId) == 1 || toInt(_chainId) == 5) {
            _registerProtocol(newOwner);
        }
        // register current chain and this registry
        _registerChain(_chainId, newOwner, "");
        _registerRegistry(_chainId, address(this), newOwner, "");
    }


    function setStakingContract(address staking)
        external
        virtual
        onlyOwner
    {
        require(address(_staking) == address(0), "ERROR:CRG-050:STAKING_ALREADY_SET");
        require(staking != address(0), "ERROR:CRG-051:STAKING_ADDRESS_ZERO");
        IStaking stakingContract = IStaking(staking);
        require(stakingContract.implementsIStaking(), "ERROR:CRG-052:STAKING_NOT_ISTAKING");

        _staking = stakingContract;
    }


    function registerChain(ChainId chain, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        return _registerChain(chain, owner(), uri);
    }


    function registerRegistry(ChainId chain, address registry, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        return _registerRegistry(chain, registry, owner(), uri);
    }


    function registerToken(ChainId chain, address token, string memory uri)
        external
        virtual override
        onlyOwner
        returns(NftId id)
    {
        (bytes memory data) = _getTokenData(chain, token);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            TOKEN,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerInstance(
        address instanceRegistry,
        string memory displayName,
        string memory uri
    )
        external 
        virtual override
        onlyOwner
        returns(NftId id)
    {
        (
            ChainId chain,
            bytes memory data
        ) = _getInstanceData(instanceRegistry, displayName);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            INSTANCE,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerComponent(
        bytes32 instanceId, 
        uint256 componentId,
        string memory uri
    )
        external 
        virtual override
        onlyRegisteredInstance(instanceId)
        onlySameChain(instanceId)
        returns(NftId id)
    {
        (
            ChainId chain,
            ObjectType t,
            bytes memory data
        ) = _getComponentData(instanceId, componentId);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            t,
            ObjectState.Approved,
            uri,
            data);
    }


    function registerBundle(
        bytes32 instanceId, 
        uint256 riskpoolId, 
        uint256 bundleId, 
        string memory displayName, 
        uint256 expiryAt
    )
        external
        virtual override
        onlyActiveRiskpool(instanceId, riskpoolId)
        onlySameChain(instanceId)
        returns(NftId id)
    {
        (ChainId chain, bytes memory data) 
        = _getBundleData(instanceId, riskpoolId, bundleId, displayName);

        // mint token for the new erc20 token
        id = _safeMintObject(
            owner(),
            chain,
            BUNDLE,
            ObjectState.Approved,
            "", // uri
            data);
    }



    function registerStake(
        NftId target, 
        address staker
    )
        external
        virtual override
        onlyStaking()
        returns(NftId id)
    {
        require(staker != address(0), "ERROR:CRG-090:STAKER_WITH_ZERO_ADDRESS");
        (bytes memory data) = _getStakeData(
            target,
            _info[target].t);

        // mint new stake nft
        id = _safeMintObject(
            staker,
            _chainId,
            STAKE,
            ObjectState.Approved,
            "", // uri
            data);
    }


    function setObjectState(NftId id, ObjectState stateNew)
        external
        virtual override
        onlyOwner
    {
        _setObjectState(id, stateNew);
    }


    function probeInstance(
        address registryAddress
    )
        public
        virtual override
        view 
        returns(
            bool isContract, 
            uint256 contractSize, 
            ChainId chain,
            bytes32 instanceId,
            bool isValidId,
            IInstanceServiceFacade instanceService
        )
    {
        contractSize = _getContractSize(registryAddress);
        isContract = (contractSize > 0);

        isValidId = false;
        instanceId = bytes32(0);
        instanceService = IInstanceServiceFacade(address(0));

        if(isContract) {
            IInstanceRegistryFacade registry = IInstanceRegistryFacade(registryAddress);

            try registry.getContract("InstanceService") returns(address instanceServiceAddress) {
                instanceService = IInstanceServiceFacade(instanceServiceAddress);
                chain = toChainId(instanceService.getChainId());
                instanceId = instanceService.getInstanceId();
                isValidId = (instanceId == keccak256(abi.encodePacked(block.chainid, registry)));
            }
            catch { } // no-empty-blocks is ok here (see default return values above)
        } 
    }


    function getNft()
        external
        virtual override
        view
        returns(IChainNft nft)
    {
        return _nft;
    }


    function getStaking()
        external
        virtual override
        view
        returns(IStaking staking)
    {
        return _staking;
    }


    function exists(NftId id) public virtual override view returns(bool) {
        return NftId.unwrap(_info[id].id) > 0;
    }


    function chains() external virtual override view returns(uint256 numberOfChains) {
        return _chainIds.length;
    }

    function getChainId(uint256 idx) external virtual override view returns(ChainId chain) {
        require(idx < _chainIds.length, "ERROR:CRG-100:INDEX_TOO_LARGE");
        return _chainIds[idx];
    }


    function objects(ChainId chain, ObjectType t) public view returns(uint256 numberOfObjects) {
        return _object[chain][t].length;
    }


    function getNftId(ChainId chain, ObjectType t, uint256 idx) external view returns(NftId id) {
        require(idx < _object[chain][t].length, "ERROR:CRG-110:INDEX_TOO_LARGE");
        return _object[chain][t][idx];
    }


    function getNftInfo(NftId id) external virtual override view returns(NftInfo memory) {
        require(exists(id), "ERROR:CRG-120:NFT_ID_INVALID");
        return _info[id];
    }


    function ownerOf(NftId id) external virtual override view returns(address nftOwner) {
        return _nft.ownerOf(NftId.unwrap(id));
    }



    function getChainNftId(ChainId chain) external virtual override view returns(NftId id) {
        id = _chain[chain];
        require(exists(id), "ERROR:CRG-130:CHAIN_NOT_REGISTERED");
    }


    function getRegistryNftId(ChainId chain) external virtual override view returns(NftId id) {
        id = _registry[chain];
        require(exists(id), "ERROR:CRG-131:REGISTRY_NOT_REGISTERED");
    }


    function getTokenNftId(
        ChainId chain,
        address token
    )
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _contractObject[chain][token];
        require(exists(id), "ERROR:CRG-133:TOKEN_NOT_REGISTERED");
        require(_info[id].t == TOKEN, "ERROR:CRG-134:OBJECT_NOT_TOKEN");
    }


    function getInstanceNftId(bytes32 instanceId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _instance[instanceId];
        require(exists(id), "ERROR:CRG-135:INSTANCE_NOT_REGISTERED");
    }


    function getComponentNftId(bytes32 instanceId, uint256 componentId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _component[instanceId][componentId];
        require(exists(id), "ERROR:CRG-136:COMPONENT_NOT_REGISTERED");
    }


    function getBundleNftId(bytes32 instanceId, uint256 bundleId)
        external
        virtual override
        view
        returns(NftId id)
    {
        id = _bundle[instanceId][bundleId];
        require(exists(id), "ERROR:CRG-137:BUNDLE_NOT_REGISTERED");
    }


    function decodeRegistryData(NftId id)
        public
        virtual override
        view
        returns(address registry)
    {
        (registry) = _decodeRegistryData(_info[id].data);
    }


    function decodeTokenData(NftId id)
        public
        virtual override
        view
        returns(address token)
    {
        (token) = _decodeTokenData(_info[id].data);
    }


    function decodeInstanceData(NftId id)
        public
        virtual override
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName
        )
    {
        return _decodeInstanceData(_info[id].data);
    }


    function decodeComponentData(NftId id)
        external
        virtual override
        view
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token
        )
    {
        return _decodeComponentData(_info[id].data);
    }


    function decodeBundleData(NftId id)
        external
        virtual override
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName
        )
    {
        return _decodeBundleData(_info[id].data);
    }


    function decodeStakeData(NftId id)
        external
        view
        virtual override
        returns(
            NftId target,
            ObjectType targetType
        )
    {
        return _decodeStakeData(_info[id].data);
    }


    function tokenDID(uint256 tokenId) 
        public 
        view 
        virtual 
        returns(string memory)
    {
        NftId id = NftId.wrap(tokenId);
        require(exists(id), "ERROR:CRG-140:TOKEN_ID_INVALID");

        NftInfo memory info = _info[id];
        NftId registryId = _object[info.chain][REGISTRY][0];
        address registryAt = abi.decode(
            _info[registryId].data, 
            (address));

        return string(
            abi.encodePacked(
                BASE_DID, 
                toString(info.chain),
                "_erc721:",
                toString(registryAt),
                "_",
                toString(tokenId)));
    }

    function toChain(uint256 chainId) public virtual override pure returns(ChainId) {
        return toChainId(chainId);
    }

    function toObjectType(uint256 t) public pure returns(ObjectType) { 
        return ObjectType.wrap(uint8(t));
    }

    function toString(uint256 i) public pure returns(string memory) {
        return StringsUpgradeable.toString(i);
    }

    function toString(ChainId chain) public pure returns(string memory) {
        return StringsUpgradeable.toString(uint40(ChainId.unwrap(chain)));
    }

    function toString(address account) public pure returns(string memory) {
        return StringsUpgradeable.toHexString(account);
    }


    function _registerProtocol(address protocolOwner)
        internal
        virtual
        returns(NftId id)
    {
        require(toInt(_chainId) == 1 || toInt(_chainId) == 5, "ERROR:CRG-200:NOT_ON_MAINNET");
        require(objects(_chainId, PROTOCOL) == 0, "ERROR:CRG-201:PROTOCOL_ALREADY_REGISTERED");

        // mint token for the new chain
        id = _safeMintObject(
            protocolOwner,
            _chainId,
            PROTOCOL,
            ObjectState.Approved,
            "", // uri
            ""); // data
        
        // only one protocol in dip ecosystem
        _typeSupported[PROTOCOL] = false;
    }


    function _registerChain(
        ChainId chain,
        address chainOwner,
        string memory uri
    )
        internal
        virtual
        returns(NftId id)
    {
        require(!exists(_chain[chain]), "ERROR:CRG-210:CHAIN_ALREADY_REGISTERED");

        // mint token for the new chain
        id = _safeMintObject(
            chainOwner,
            chain,
            CHAIN,
            ObjectState.Approved,
            uri,
            "");
    }


    function _registerRegistry(
        ChainId chain,
        address registry,
        address registryOwner,
        string memory uri
    )
        internal
        virtual
        returns(NftId id)
    {
        require(exists(_chain[chain]), "ERROR:CRG-220:CHAIN_NOT_SUPPORTED");
        require(objects(chain, REGISTRY) == 0, "ERROR:CRG-221:REGISTRY_ALREADY_REGISTERED");
        require(registry != address(0), "ERROR:CRG-222:REGISTRY_ADDRESS_ZERO");

        (bytes memory data) = _getRegistryData(chain, registry);

        // mint token for the new registry
        id = _safeMintObject(
            registryOwner,
            chain,
            REGISTRY,
            ObjectState.Approved,
            uri,
            data);
    }


    function _setObjectState(NftId id, ObjectState stateNew)
        internal
        virtual
        onlyExisting(id)
    {
        NftInfo storage info = _info[id];
        ObjectState stateOld = info.state;

        info.state = stateNew;

        emit LogChainRegistryObjectStateSet(id, stateOld, stateNew, msg.sender);
    }


    function _getRegistryData(ChainId chain, address registry)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        require(exists(_chain[chain]), "ERROR:CRG-280:CHAIN_NOT_SUPPORTED");
        require(registry != address(0), "ERROR:CRG-281:REGISTRY_ADDRESS_ZERO");

        data = _encodeRegistryData(registry);
    }


    function _getTokenData(ChainId chain, address token)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        require(exists(_chain[chain]), "ERROR:CRG-290:CHAIN_NOT_SUPPORTED");
        require(!exists(_contractObject[chain][token]), "ERROR:CRG-291:TOKEN_ALREADY_REGISTERED");
        require(token != address(0), "ERROR:CRG-292:TOKEN_ADDRESS_ZERO");

        data = _encodeTokenData(token);
    }


    function _getInstanceData(
        address instanceRegistry,
        string memory displayName
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            bytes memory data
        )
    {
        require(instanceRegistry != address(0), "ERROR:CRG-300:REGISTRY_ADDRESS_ZERO");

        // check instance via provided registry
        (
            bool isContract,
            , // don't care about contract size
            ChainId chainId,
            bytes32 instanceId,
            bool hasValidId,
            // don't care about instanceservice
        ) = probeInstance(instanceRegistry);

        require(isContract, "ERROR:CRG-301:REGISTRY_NOT_CONTRACT");
        require(hasValidId, "ERROR:CRG-302:INSTANCE_ID_INVALID");
        require(exists(_chain[chainId]), "ERROR:CRG-303:CHAIN_NOT_SUPPORTED");
        require(!exists(_contractObject[chainId][instanceRegistry]), "ERROR:CRG-304:INSTANCE_ALREADY_REGISTERED");

        chain = chainId;
        data = _encodeInstanceData(instanceId, instanceRegistry, displayName);
    }


    function _getComponentData(
        bytes32 instanceId,
        uint256 componentId
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            ObjectType t,
            bytes memory data
        )
    {
        require(!exists(_component[instanceId][componentId]), "ERROR:CRG-310:COMPONENT_ALREADY_REGISTERED");

        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.ComponentType cType = instanceService.getComponentType(componentId);

        t = _toObjectType(cType);
        chain = toChainId(instanceService.getChainId());
        address token = address(instanceService.getComponentToken(componentId));
        require(exists(_contractObject[chain][token]), "ERROR:CRG-311:COMPONENT_TOKEN_NOT_REGISTERED");

        data = _encodeComponentData(instanceId, componentId, token);
    }


    function _getBundleData(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        string memory displayName
    )
        internal
        virtual
        view
        returns(
            ChainId chain,
            bytes memory data
        )
    {
        require(!exists(_bundle[instanceId][bundleId]), "ERROR:CRG-320:BUNDLE_ALREADY_REGISTERED");

        IInstanceServiceFacade instanceService = getInstanceServiceFacade(instanceId);
        IInstanceServiceFacade.Bundle memory bundle = instanceService.getBundle(bundleId);
        require(bundle.riskpoolId == riskpoolId, "ERROR:CRG-321:BUNDLE_RISKPOOL_MISMATCH");

        address token = address(instanceService.getComponentToken(riskpoolId));

        chain = toChainId(instanceService.getChainId());
        data = _encodeBundleData(instanceId, riskpoolId, bundleId, token, displayName);
    }


    function _getStakeData(NftId target, ObjectType targetType)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        data = _encodeStakeData(target, targetType);
    }


    function _encodeRegistryData(address registry)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(registry);
    }


    function _decodeRegistryData(bytes memory data)
        internal
        virtual
        view
        returns(address registry)
    {
        return abi.decode(data, (address));
    }


    function _encodeTokenData(address token)
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(token);
    }


    function _decodeTokenData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(address token)
    {
        return abi.decode(data, (address));
    }


    function _encodeInstanceData(
        bytes32 instanceId,
        address registry,
        string memory displayName
    )
        internal
        virtual
        view
        returns(bytes memory data)
    {
        return abi.encode(instanceId, registry, displayName);
    }


    function _decodeInstanceData(bytes memory data) 
        internal
        virtual
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName
        )
    {
        (instanceId, registry, displayName) 
            = abi.decode(data, (bytes32, address, string));
    }


    function _encodeComponentData(
        bytes32 instanceId,
        uint256 componentId,
        address token
    )
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(instanceId, componentId, token);
    }


    function _decodeComponentData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token
        )
    {
        (instanceId, componentId, token)
            = abi.decode(data, (bytes32, uint256, address));
    }


    function _encodeBundleData(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        address token,
        string memory displayName
    )
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(instanceId, riskpoolId, bundleId, token, displayName);
    }


    function _decodeBundleData(bytes memory data) 
        internal 
        virtual 
        view 
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName
        )
    {
        (instanceId, riskpoolId, bundleId, token, displayName) 
            = abi.decode(data, (bytes32, uint256, uint256, address, string));
    }


    function _encodeStakeData(NftId target, ObjectType targetType)
        internal 
        virtual
        pure 
        returns(bytes memory)
    {
        return abi.encode(target, targetType);
    }


    function _decodeStakeData(bytes memory data) 
        internal
        virtual
        view
        returns(
            NftId target,
            ObjectType targetType
        )
    {
        (target, targetType) 
            = abi.decode(data, (NftId, ObjectType));
    }


    function getInstanceServiceFacade(bytes32 instanceId) 
        public
        virtual override
        view
        returns(IInstanceServiceFacade instanceService)
    {
        NftId id = _instance[instanceId];
        (, address registry, ) = decodeInstanceData(id);
        (,,,,, instanceService) = probeInstance(registry);
    }


    function _toObjectType(IInstanceServiceFacade.ComponentType cType)
        internal 
        virtual
        pure
        returns(ObjectType t)
    {
        if(cType == IInstanceServiceFacade.ComponentType.Riskpool) {
            return RISKPOOL;
        }

        if(cType == IInstanceServiceFacade.ComponentType.Product) {
            return PRODUCT;
        }

        return ORACLE;
    }


    function _safeMintObject(
        address to,
        ChainId chain,
        ObjectType t,
        ObjectState state,
        string memory uri,
        bytes memory data
    )
        internal
        virtual
        returns(NftId id)
    {
        require(address(_nft) != address(0), "ERROR:CRG-350:NFT_NOT_SET");
        require(_typeSupported[t], "ERROR:CRG-351:OBJECT_TYPE_NOT_SUPPORTED");

        // mint nft
        id = NftId.wrap(_nft.mint(to, uri));

        // store nft meta data
        NftInfo storage info = _info[id];
        info.id = id;
        info.chain = chain;
        info.t = t;
        info.state = state;
        info.mintedIn = blockNumber();
        info.updatedIn = blockNumber();
        info.version = version();

        // store data if provided        
        if(data.length > 0) {
            info.data = data;
        }

        // general object book keeping
        _object[chain][t].push(id);

        // object type specific book keeping
        if(t == CHAIN) {
            _chain[chain] = id;
            _chainIds.push(chain);
        } else if(t == REGISTRY) {
            _registry[chain] = id;
        } else if(t == TOKEN) {
            (address token) = _decodeTokenData(data);
            _contractObject[chain][token] = id;
        } else if(t == INSTANCE) {
            (bytes32 instanceId, address registry, ) = _decodeInstanceData(data);
            _contractObject[chain][registry] = id;
            _instance[instanceId] = id;
        } else if(
            t == RISKPOOL
            || t == PRODUCT
            || t == ORACLE
        ) {
            (bytes32 instanceId, uint256 componentId, ) = _decodeComponentData(data);
            _component[instanceId][componentId] = id;
        } else if(t == BUNDLE) {
            (bytes32 instanceId, , uint256 bundleId, , ) = _decodeBundleData(data);
            _bundle[instanceId][bundleId] = id;
        }

        emit LogChainRegistryObjectRegistered(id, chain, t, state, to);
    }


    function _getContractSize(address contractAddress)
        internal
        view
        returns(uint256 size)
    {
        assembly {
            size := extcodesize(contractAddress)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "OwnableUpgradeable.sol";

import "Versionable.sol";

contract VersionedOwnable is
    Versionable,
    OwnableUpgradeable
{
    // controlled initialization for controller deployment
    constructor() 
        initializer
    {
        // activation done in parent constructor
        // set msg sender as owner
        __Ownable_init();
    }


    // IMPORTANT this function needs to be implemented by each new version
    // and needs to call _activate() in derived contract implementations
    function activate(address implementation, address activatedBy) external override virtual { 
        _activate(implementation, activatedBy);
    }

    // default implementation for initial deployment by proxy admin
    function activateAndSetOwner(address implementation, address newOwner, address activatedBy)
        external
        virtual
    {
        _activateAndSetOwner(implementation, newOwner, activatedBy);
    }


    function _activateAndSetOwner(address implementation, address newOwner, address activatedBy)
        internal
        virtual 
        initializer
    { 
        // ensure proper version history
        _activate(implementation, activatedBy);

        // initialize open zeppelin contracts
        __Ownable_init();

        // transfer to new owner
        transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "StringsUpgradeable.sol";

import "BaseTypes.sol";
import "IVersionType.sol";

contract Versionable is BaseTypes {

    struct VersionInfo {
        Version version;
        address implementation;
        address activatedBy; // tx.origin
        Blocknumber activatedIn;
        Timestamp activatedAt;
    }

    event LogVersionableActivated(Version version, address implementation, address activatedBy);

    mapping(Version version => VersionInfo info) private _versionHistory;
    Version [] private _versions;


    // controlled activation for controller contract
    constructor() {
        _activate(address(this), msg.sender);
    }

    // IMPORTANT this function needs to be implemented by each new version
    // and needs to call internal function call _activate() 
    function activate(address implementation, address activatedBy)
        external 
        virtual
    { 
        _activate(implementation, activatedBy);
    }


    // can only be called once per contract
    // needs bo be called inside the proxy upgrade tx
    function _activate(
        address implementation,
        address activatedBy
    )
        internal
    {
        Version thisVersion = version();

        require(
            !isActivated(thisVersion),
            "ERROR:VRN-001:VERSION_ALREADY_ACTIVATED"
        );
        
        // require increasing version number
        if(_versions.length > 0) {
            Version lastVersion = _versions[_versions.length - 1];
            require(
                thisVersion > lastVersion,
                "ERROR:VRN-002:VERSION_NOT_INCREASING"
            );
        }

        // update version history
        _versions.push(thisVersion);
        _versionHistory[thisVersion] = VersionInfo(
            thisVersion,
            implementation,
            activatedBy,
            blockNumber(),
            blockTimestamp()
        );

        emit LogVersionableActivated(thisVersion, implementation, activatedBy);
    }


    function isActivated(Version _version) public view returns(bool) {
        return toInt(_versionHistory[_version].activatedIn) > 0;
    }


    // returns current version (ideally immutable)
    function version() public virtual pure returns(Version) {
        return zeroVersion();
    }


    function versionParts()
        external
        virtual 
        view
        returns(
            VersionPart major,
            VersionPart minor,
            VersionPart patch
        )
    {
        return toVersionParts(version());
    }


    function versions() external view returns(uint256) {
        return _versions.length;
    }


    function getVersion(uint256 idx) external view returns(Version) {
        require(idx < _versions.length, "ERROR:VRN-010:INDEX_TOO_LARGE");
        return _versions[idx];
    }


    function getVersionInfo(Version _version) external view returns(VersionInfo memory) {
        require(isActivated(_version), "ERROR:VRN-020:VERSION_UNKNOWN");
        return _versionHistory[_version];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "IBaseTypes.sol";


contract BaseTypes is IBaseTypes {

    function intToBytes(uint256 x, uint8 shift) public override pure returns(bytes memory) {
        return abi.encodePacked(uint16(x << shift));
    }

    function toInt(Blocknumber x) public override pure returns(uint) { return Blocknumber.unwrap(x); }
    function toInt(Timestamp x) public override pure returns(uint) { return Timestamp.unwrap(x); }
    function toInt(ChainId x) public override pure returns(uint) { return uint(uint40(ChainId.unwrap(x))); }

    function blockNumber() public override view returns(Blocknumber) {
        return Blocknumber.wrap(uint32(block.number));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// restriction: uint<n> n needs to be different for each type to support function overloading

// allows for chain ids up to 13 digits
type ChainId is bytes5;

using {
    eqChainId as ==,
    neqChainId as !=
}
    for ChainId global;

function eqChainId(ChainId a, ChainId b) pure returns(bool isSame) { return ChainId.unwrap(a) == ChainId.unwrap(b); }
function neqChainId(ChainId a, ChainId b) pure returns(bool isDifferent) { return ChainId.unwrap(a) != ChainId.unwrap(b); }

function toChainId(uint256 chainId) pure returns(ChainId) { return ChainId.wrap(bytes5(abi.encodePacked(uint40(chainId))));}
function thisChainId() view returns(ChainId) { return toChainId(block.chainid); }

type Timestamp is uint40;

using {
    gtTimestamp as >,
    gteTimestamp as >=,
    ltTimestamp as <,
    lteTimestamp as <=,
    eqTimestamp as ==,
    neqTimestamp as !=
}
    for Timestamp global;

function gtTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) > Timestamp.unwrap(b); }
function gteTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) >= Timestamp.unwrap(b); }

function ltTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) < Timestamp.unwrap(b); }
function lteTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) <= Timestamp.unwrap(b); }

function eqTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) == Timestamp.unwrap(b); }
function neqTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) != Timestamp.unwrap(b); }

function toTimestamp(uint256 timestamp) pure returns(Timestamp) { return Timestamp.wrap(uint40(timestamp));}
function blockTimestamp() view returns(Timestamp) { return toTimestamp(block.timestamp); }
function zeroTimestamp() pure returns(Timestamp) { return toTimestamp(0); }

type Blocknumber is uint32;


interface IBaseTypes {

    function intToBytes(uint256 x, uint8 shift) external pure returns(bytes memory);

    function toInt(Blocknumber x) external pure returns(uint);
    function toInt(Timestamp x) external pure returns(uint);
    function toInt(ChainId x) external pure returns(uint);

    function blockNumber() external view returns(Blocknumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// restriction: uint<n> n needs to be different for each type to support function overloading
type VersionPart is uint16;
type Version is uint48; // to concatenate major,minor,patch version parts

using {
    gtVersion as >,
    gteVersion as >=,
    eqVersion as ==
}
    for Version global;

function gtVersion(Version a, Version b) pure returns(bool isGreaterThan) { return Version.unwrap(a) > Version.unwrap(b); }
function gteVersion(Version a, Version b) pure returns(bool isGreaterOrSame) { return Version.unwrap(a) >= Version.unwrap(b); }
function eqVersion(Version a, Version b) pure returns(bool isSame) { return Version.unwrap(a) == Version.unwrap(b); }

function versionPartToInt(VersionPart x) pure returns(uint) { return VersionPart.unwrap(x); }
function versionToInt(Version x) pure returns(uint) { return Version.unwrap(x); }

function toVersionPart(uint16 versionPart) pure returns(VersionPart) { return VersionPart.wrap(versionPart); }

function toVersion(
    VersionPart major,
    VersionPart minor,
    VersionPart patch
)
    pure
    returns(Version)
{
    uint majorInt = versionPartToInt(major);
    uint minorInt = versionPartToInt(minor);
    uint patchInt = versionPartToInt(patch);

    return Version.wrap(
        uint48(
            (majorInt << 32) + (minorInt << 16) + patchInt));
}


function zeroVersion() pure returns(Version) {
    return toVersion(toVersionPart(0), toVersionPart(0), toVersionPart(0));
}


function toVersionParts(Version _version)
    pure
    returns(
        VersionPart major,
        VersionPart minor,
        VersionPart patch
    )
{
    uint versionInt = versionToInt(_version);
    uint16 majorInt = uint16(versionInt >> 32);

    versionInt -= majorInt << 32;
    uint16 minorInt = uint16(versionInt >> 16);
    uint16 patchInt = uint16(versionInt - (minorInt << 16));

    return (
        toVersionPart(majorInt),
        toVersionPart(minorInt),
        toVersionPart(patchInt)
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;


interface IInstanceRegistryFacade {

    function getContract(bytes32 contractName)
        external
        view
        returns (address contractAddress);
        
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;


import "IERC20Metadata.sol";


// needs to be in sync with definition in IInstanceService
interface IInstanceServiceFacade {

    // needs to be in sync with definition in IComponent
    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    // needs to be in sync with definition in IComponent
    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    // needs to be in sync with definition in IBundle
    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    // needs to be in sync with definition in IBundle
    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function getChainId() external view returns(uint256 chainId);
    function getInstanceId() external view returns(bytes32 instanceId);
    function getInstanceOperator() external view returns(address instanceOperator);

    function getComponentType(uint256 componentId) external view returns(ComponentType componentType);
    function getComponentState(uint256 componentId) external view returns(ComponentState componentState);
    function getComponentToken(uint256 componentId) external view returns(IERC20Metadata token);

    function getBundle(uint256 bundleId) external view returns(Bundle memory bundle);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "IBaseTypes.sol";
import "IVersionType.sol";

import "IStaking.sol";

import "IChainNft.sol";
import "IInstanceRegistryFacade.sol";
import "IInstanceServiceFacade.sol";

type ObjectType is uint8;

using {
    eqObjectType as ==,
    neObjectType as !=
}
    for ObjectType global;

function eqObjectType(ObjectType a, ObjectType b) pure returns(bool isSame) { return ObjectType.unwrap(a) == ObjectType.unwrap(b); }
function neObjectType(ObjectType a, ObjectType b) pure returns(bool isDifferent) { return ObjectType.unwrap(a) != ObjectType.unwrap(b); }


interface IChainRegistry is 
    IBaseTypes 
{

    enum ObjectState {
        Undefined,
        Proposed,
        Approved,
        Suspended,
        Archived,
        Burned
    }


    struct NftInfo {
        NftId id;
        ChainId chain;
        ObjectType t;
        ObjectState state;
        string uri;
        bytes data;
        Blocknumber mintedIn;
        Blocknumber updatedIn;
        Version version;
    }


    event LogChainRegistryObjectRegistered(NftId id, ChainId chain, ObjectType t, ObjectState state, address to);
    event LogChainRegistryObjectStateSet(NftId id, ObjectState stateNew, ObjectState stateOld, address setBy);

    //--- state changing functions ------------------//

    function registerChain(ChainId chain, string memory uri) external returns(NftId id);
    function registerRegistry(ChainId chain, address registry, string memory uri) external returns(NftId id);
    function registerToken(ChainId chain,address token, string memory uri) external returns(NftId id);       


    function registerStake(
        NftId target, 
        address staker
    )
        external
        returns(NftId id);


    function registerInstance(
        address instanceRegistry,
        string memory displayName,
        string memory uri
    )
        external
        returns(NftId id);


    function registerComponent(
        bytes32 instanceId,
        uint256 componentId,
        string memory uri
    )
        external
        returns(NftId id);


    function registerBundle(
        bytes32 instanceId,
        uint256 riskpoolId,
        uint256 bundleId,
        string memory displayName,
        uint256 expiryAt
    )
        external
        returns(NftId id);


    function setObjectState(NftId id, ObjectState state) external;


    //--- view and pure functions ------------------//

    function getNft() external view returns(IChainNft);
    function getStaking() external view returns(IStaking);

    function exists(NftId id) external view returns(bool);

    // generic accessors
    function objects(ChainId chain, ObjectType t) external view returns(uint256 numberOfObjects);
    function getNftId(ChainId chain, ObjectType t, uint256 idx) external view returns(NftId id);
    function getNftInfo(NftId id) external view returns(NftInfo memory);
    function ownerOf(NftId id) external view returns(address nftOwner);

    // chain specific accessors
    function chains() external view returns(uint256 numberOfChains);
    function getChainId(uint256 idx) external view returns(ChainId chain);
    function getChainNftId(ChainId chain) external view returns(NftId id);

    // type specific accessors
    function getRegistryNftId(ChainId chain) external view returns(NftId id);
    function getTokenNftId(ChainId chain, address token) external view returns(NftId id);
    function getInstanceNftId(bytes32 instanceId) external view returns(NftId id);
    function getComponentNftId(bytes32 instanceId, uint256 componentId) external view returns(NftId id);
    function getBundleNftId(bytes32 instanceId, uint256 componentId) external view returns(NftId id);


    function decodeRegistryData(NftId id)
        external
        view
        returns(address registry);


    function decodeTokenData(NftId id)
        external
        view
        returns(address token);


    function decodeInstanceData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            address registry,
            string memory displayName);


    function decodeComponentData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 componentId,
            address token);


    function decodeBundleData(NftId id)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName);


    function decodeStakeData(NftId id)
        external
        view
        returns(
            NftId target,
            ObjectType targetType);


    function toChain(uint256 chainId) 
        external
        pure
        returns(ChainId);

    // only same chain: utility to get reference to instance service for specified instance id
    function getInstanceServiceFacade(bytes32 instanceId) 
        external
        view
        returns(IInstanceServiceFacade instanceService);

    // only same chain:  utilitiv function to probe an instance given its registry address
    function probeInstance(address registry)
        external 
        view 
        returns(
            bool isContract, 
            uint256 contractSize, 
            ChainId chain,
            bytes32 istanceId, 
            bool isValidId, 
            IInstanceServiceFacade instanceService);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "IERC20Metadata.sol";

import "IBaseTypes.sol";
import "IVersionType.sol";
import "UFixedMath.sol";

import "IChainNft.sol";
import "IChainRegistry.sol";
import "IInstanceServiceFacade.sol";


interface IStaking {

    struct StakeInfo {
        NftId id;
        NftId target;
        uint256 stakeBalance;
        uint256 rewardBalance;
        Timestamp createdAt;
        Timestamp updatedAt;
        Version version;
    }

    event LogStakingRewardReservesIncreased(address user, uint256 amount, uint256 newBalance);
    event LogStakingRewardReservesDecreased(address user, uint256 amount, uint256 newBalance);

    event LogStakingRewardRateSet(address user, UFixed oldRewardRate, UFixed newRewardRate);
    event LogStakingStakingRateSet(address user, ChainId chain, address token, UFixed oldStakingRate, UFixed newStakingRate);

    event LogStakingNewStakeCreated(NftId target, address user, NftId id);
    event LogStakingStaked(NftId target, address user, NftId id, uint256 amount, uint256 newBalance);
    event LogStakingUnstaked(NftId target, address user, NftId id, uint256 amount, uint256 newBalance);

    event LogStakingRewardsUpdated(NftId id, uint256 amount, uint256 newBalance);
    event LogStakingRewardsClaimed(NftId id, uint256 amount, uint256 newBalance);

    //--- state changing functions ------------------//

    function refillRewardReserves(uint256 dipAmount) external;
    function withdrawRewardReserves(uint256 dipAmount) external;

    function setRewardRate(UFixed rewardRate) external;
    function setStakingRate(ChainId chain, address token, UFixed stakingRate) external;    

    function createStake(NftId target, uint256 dipAmount) external returns(NftId id);
    function stake(NftId id, uint256 dipAmount) external;
    function unstake(NftId id, uint256 dipAmount) external;  
    function unstakeAndClaimRewards(NftId id) external;
    function claimRewards(NftId id) external;

    //--- view and pure functions ------------------//

    function getRegistry() external view returns(IChainRegistry);

    function rewardRate() external view returns(UFixed rewardRate);
    function rewardBalance() external view returns(uint256 dipAmount);
    function rewardReserves() external view returns(uint256 dipAmount);
    function stakingRate(ChainId chain, address token) external view returns(UFixed stakingRate);
    function getStakingWallet() external view returns(address stakingWallet);
    function getDip() external view returns(IERC20Metadata);

    function isStakeOwner(NftId id, address user) external view returns(bool isOwner);
    function getInfo(NftId id) external view returns(StakeInfo memory info);

    function stakes(NftId target) external view returns(uint256 dipAmount);
    function capitalSupport(NftId target) external view returns(uint256 capitalAmount);

    function isStakingSupportedForType(ObjectType targetType) external view returns(bool isSupported);
    function isStakingSupported(NftId target) external view returns(bool isSupported);
    function isUnstakingSupported(NftId target) external view returns(bool isSupported);

    function calculateRewardsIncrement(StakeInfo memory stakeInfo) external view returns(uint256 rewardsAmount);
    function calculateRewards(uint256 amount, uint256 duration) external view returns(uint256 rewardAmount);

    function calculateRequiredStaking(ChainId chain, address token, uint256 tokenAmount) external view returns(uint256 dipAmount);
    function calculateCapitalSupport(ChainId chain, address token, uint256 dipAmount) external view returns(uint256 tokenAmount);

    function toChain(uint256 chainId) external pure returns(ChainId);

    function toRate(uint256 value, int8 exp) external pure returns(UFixed);
    function rateDecimals() external pure returns(uint256 decimals);

    //--- view and pure functions (target type specific) ------------------//

    function getBundleInfo(NftId bundle)
        external
        view
        returns(
            bytes32 instanceId,
            uint256 riskpoolId,
            uint256 bundleId,
            address token,
            string memory displayName,
            IInstanceServiceFacade.BundleState bundleState,
            Timestamp expiryAt,
            bool stakingSupported,
            bool unstakingSupported,
            uint256 stakeBalance
        );

    function implementsIStaking() external pure returns(bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "Math.sol";

type UFixed is uint256;

using {
    addUFixed as +,
    subUFixed as -,
    mulUFixed as *,
    divUFixed as /,
    gtUFixed as >,
    gteUFixed as >=,
    ltUFixed as <,
    lteUFixed as <=,
    eqUFixed as ==
}
    for UFixed global;

function addUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    return UFixed.wrap(UFixed.unwrap(a) + UFixed.unwrap(b));
}

function subUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    require(a >= b, "ERROR:UFM-010:NEGATIVE_RESULT");

    return UFixed.wrap(UFixed.unwrap(a) - UFixed.unwrap(b));
}

function mulUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    return UFixed.wrap(Math.mulDiv(UFixed.unwrap(a), UFixed.unwrap(b), 10 ** 18));
}

function divUFixed(UFixed a, UFixed b) pure returns(UFixed) {
    require(UFixed.unwrap(b) > 0, "ERROR:UFM-020:DIVISOR_ZERO");

    return UFixed.wrap(
        Math.mulDiv(
            UFixed.unwrap(a), 
            10 ** 18,
            UFixed.unwrap(b)));
}

function gtUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) > UFixed.unwrap(b);
}

function gteUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) >= UFixed.unwrap(b);
}

function ltUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) < UFixed.unwrap(b);
}

function lteUFixed(UFixed a, UFixed b) pure returns(bool isGreaterThan) {
    return UFixed.unwrap(a) <= UFixed.unwrap(b);
}

function eqUFixed(UFixed a, UFixed b) pure returns(bool isEqual) {
    return UFixed.unwrap(a) == UFixed.unwrap(b);
}

function gtz(UFixed a) pure returns(bool isZero) {
    return UFixed.unwrap(a) > 0;
}

function eqz(UFixed a) pure returns(bool isZero) {
    return UFixed.unwrap(a) == 0;
}

function delta(UFixed a, UFixed b) pure returns(UFixed) {
    if(a > b) {
        return a - b;
    }

    return b - a;
}

contract UFixedType {

    enum Rounding {
        Down, // floor(value)
        Up, // = ceil(value)
        HalfUp // = floor(value + 0.5)
    }

    int8 public constant EXP = 18;
    uint256 public constant MULTIPLIER = 10 ** uint256(int256(EXP));
    uint256 public constant MULTIPLIER_HALF = MULTIPLIER / 2;
    
    Rounding public constant ROUNDING_DEFAULT = Rounding.HalfUp;

    function decimals() public pure returns(uint256) {
        return uint8(EXP);
    }

    function itof(uint256 a)
        public
        pure
        returns(UFixed)
    {
        return UFixed.wrap(a * MULTIPLIER);
    }

    function itof(uint256 a, int8 exp)
        public
        pure
        returns(UFixed)
    {
        require(EXP + exp >= 0, "ERROR:FM-010:EXPONENT_TOO_SMALL");
        require(EXP + exp <= 2 * EXP, "ERROR:FM-011:EXPONENT_TOO_LARGE");

        return UFixed.wrap(a * 10 ** uint8(EXP + exp));
    }

    function ftoi(UFixed a)
        public
        pure
        returns(uint256)
    {
        return ftoi(a, ROUNDING_DEFAULT);
    }

    function ftoi(UFixed a, Rounding rounding)
        public
        pure
        returns(uint256)
    {
        if(rounding == Rounding.HalfUp) {
            return Math.mulDiv(UFixed.unwrap(a) + MULTIPLIER_HALF, 1, MULTIPLIER, Math.Rounding.Down);
        } else if(rounding == Rounding.Down) {
            return Math.mulDiv(UFixed.unwrap(a), 1, MULTIPLIER, Math.Rounding.Down);
        } else {
            return Math.mulDiv(UFixed.unwrap(a), 1, MULTIPLIER, Math.Rounding.Up);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "IERC721Enumerable.sol";

import "IChainRegistry.sol";

type NftId is uint256;

using {
    eqNftId as ==,
    neNftId as !=
}
    for NftId global;

function eqNftId(NftId a, NftId b) pure returns(bool isSame) { return NftId.unwrap(a) == NftId.unwrap(b); }
function neNftId(NftId a, NftId b) pure returns(bool isDifferent) { return NftId.unwrap(a) != NftId.unwrap(b); }
function gtz(NftId a) pure returns(bool) { return NftId.unwrap(a) > 0; }
function zeroNftId() pure returns(NftId) { return NftId.wrap(0); }


interface IChainNft is 
    IERC721Enumerable 
{

    function mint(address to, string memory uri) external returns(uint256 tokenId);
    function burn(uint256 tokenId) external;
    function setURI(uint256 tokenId, string memory uri) external;

    function getRegistry() external view returns(IChainRegistry registry);
    function exists(uint256 tokenId) external view returns(bool);

    function implementsIChainNft() external pure returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}