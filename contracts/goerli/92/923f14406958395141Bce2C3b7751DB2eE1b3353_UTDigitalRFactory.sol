// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../traitregistry/ECRegistryV3c.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../implementers/UTDigitalRedeemStorage.sol";
import "../implementers/UTDigitalRedeemController.sol";
import "../extras/recovery/BlackHolePrevention.sol";

interface IRandom {
    function setAuth(address, bool) external;
}

/**
* @dev This factory is used to create new traits (perks) in a community
*/
contract UTDigitalRFactory is Ownable, BlackHolePrevention {
    using Strings  for uint32; 

    uint256     public constant     version              = 20230604;

    uint8       public constant     TRAIT_TYPE           = 6;            // Digital redeemables
    string      public constant     REGISTRY_KEY_FACTORY = "TRAIT_TYPE_6_FACTORY";
    bytes32     public constant     TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");

    // enum RedeemMode {
    //     random,                                 // 0 - Random redeem from the vault (with VRF)
    //     first                                   // 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
    // }

    struct inputTraitStruct {
        uint16  communityId;                    // Community ID
        uint16  start;                          // Validity start period of the trait
        uint16  end;                            // Validity start period of the trait
        bool    enabled;                        // Can be locked
        string  ipfsHash;                       // The desriptor file hash on IPFS
        string  name;                           // Name of the trait (perk)
        uint32  tokenNum;                       // The serial number of the token contract to use (under key TOKEN_xx where xx = tokenNum )
        uint8   maxTokensToRedeem;              // How many tokens can be claimed (in any chunks)
        address collectionToRedeemFrom;         // Token contract address (ERC721Enumerable) where the user gets a token from
                                                // If collectionToRedeemFrom == address(0) --> the user may pick the collection from the vault)
        uint8   redeemMode;                     // 0 - Random redeem from the vault (with VRF)
                                                // 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
    }

    /**
     * @dev addTrait() is called from the UTC to create a new trait (perk) in a community for a specific token
     * note Tokens are marked in the Community registry with keys TOKEN_xx (where xx = 1,2,...)
     *      For each token the corresponding Trait Registry can be found under keys TRAIT_REGISTRY_xx
     *      In the input structure, tokenNum designates which community token - and thus which corresponding 
     *      Trait registry should be used.
     *      This contract must have COMMUNITY_REGISTRY_ADMIN on RoleManagerInstance - so it can update keys in
     *      any Community registry
     *      It creates one storage contract per trait and one (singleton) logic controller for the trait type.
     *      It grants access to the controller in order to be able to write into the trait storage
     *      This contract must have admin right in RANDOMV2_SSP_TRAIT_DROPPER - so it can grant role
     *      any Community registry
     *      It validates that this is the current factory according to the keys in the Galaxis Registry
     */
    function addTrait(
        inputTraitStruct calldata _inputTrait
    ) external returns (uint16 traitId) {

        // Get Galaxis registry
        IRegistryConsumer GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

        // Validate if this contract is the current version to be used. Else fail
        address DigitalRFactoryAddr = GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_FACTORY);
        require(DigitalRFactoryAddr == address(this), "UTDigitalRFactory: Not current DigitalRFactory");

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_inputTrait.communityId);
        require(
            crAddr != address(0),
            "UTDigitalRFactory: Invalid community ID"
        );
        // Get community registry
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);
        
        // Get trait registry
        ECRegistryV3c traitRegistry = ECRegistryV3c(thisCommunityRegistry.getRegistryAddress(string(abi.encodePacked("TRAIT_REGISTRY_", _inputTrait.tokenNum.toString()))));

        // Trait registry must exist!
        require(
            address(traitRegistry) != address(0),
            "UTDigitalRFactory: Trait Registry not installed"
        );

        // Check if caller is TRAIT_REGISTRY_ADMIN
        require(
            traitRegistry.isAllowed(TRAIT_REGISTRY_ADMIN, msg.sender),
            "UTDigitalRFactory: Unauthorized"
        );

        // maxTokensToRedeem should be > 0
        require(
            _inputTrait.maxTokensToRedeem > 0,
            "UTDigitalRFactory: maxTokensToRedeem should be > 0"
        );

        // Get next available ID for the new trait
        traitId = traitRegistry.traitCount();

        // Get the NFT address
        address ERC721 = thisCommunityRegistry.getRegistryAddress(string(abi.encodePacked("TOKEN_", _inputTrait.tokenNum.toString())));

        // NFT must exist!
        require(
            ERC721 != address(0),
            "UTDigitalRFactory: Token not installed"
        );

        // Add role for this factory to write into TraitRegistry
        if(!thisCommunityRegistry.hasRole(TRAIT_REGISTRY_ADMIN, address(this))) {
            thisCommunityRegistry.grantRole(TRAIT_REGISTRY_ADMIN, address(this));
        }

        // Deploy _controller_ ONLY if not yet deployed for this TRAIT_TYPE
        UTDigitalRedeemController controllerCtr;
        address controllerAddr = traitRegistry.getDefaultTraitControllerByType(TRAIT_TYPE);
        if(controllerAddr == address(0)) {

            // Deploy _controller_
            controllerCtr = new UTDigitalRedeemController(ERC721, address(traitRegistry), 0, 0, address(thisCommunityRegistry));

            // Set this controller as default for this TRAIT_TYPE
            traitRegistry.setDefaultTraitControllerType(address(controllerCtr), TRAIT_TYPE);
        } else {
            controllerCtr = UTDigitalRedeemController(controllerAddr);
        }

        // Deploy _storage_
        UTDigitalRedeemStorage storageCtr = new UTDigitalRedeemStorage(address(traitRegistry), traitId, _inputTrait.maxTokensToRedeem, _inputTrait.redeemMode, _inputTrait.collectionToRedeemFrom);

        // Add the trait to the trait registry
        ECRegistryV3c.traitStruct[] memory traits = new ECRegistryV3c.traitStruct[](1);
        traits[0] = ECRegistryV3c.traitStruct(traitId, TRAIT_TYPE, _inputTrait.start, _inputTrait.end, _inputTrait.enabled, address(storageCtr), _inputTrait.ipfsHash, _inputTrait.name);
        traitRegistry.addTrait(traits);

        // Grant access to the Controller for this trait
        traitRegistry.setTraitControllerAccess(address(controllerCtr), traitId, true);

        // Grant access to the Controller for using the VRF (random) contract
        IRandom random = IRandom(GalaxisRegistry.getRegistryAddress("RANDOMV2_SSP_TRAIT_DROPPER"));
        random.setAuth(address(controllerCtr), true);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IRegistryConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

abstract contract ProxyProtection {
    address                                 placeholder1;                // Allocate space for the proxy
    bool                                    placeholder2;                // Allocate space for the proxy
}

contract ECRegistryV3c is ProxyProtection, Ownable {

    uint256                 public constant version              = 20230512;

    bytes32                 public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    bytes32                 public constant TRAIT_DROP_ADMIN     = keccak256("TRAIT_DROP_ADMIN");

    IRegistryConsumer       public          GalaxisRegistry;
    CommunityRegistry       public          myCommunityRegistry;
    bool                                    initialised;

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;                  // Range start for type 1/2 traits               
        uint16  end;                    // Range end for type 1/2 traits               
        bool    enabled;                // Frontend is responsible to hide disabled traits
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;               // IPFS address to store trait data (icon, etc.)
        string  name;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;

    // token data
    mapping(uint16 => mapping(uint16 => uint8) ) public tokenData;

    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;
    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;
    mapping( uint8 => address ) public defaultTraitControllerAddressByType;

    /*
    *   Events
    */
    event traitControllerEvent(address _address);

    // Traits master data change
    event newTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    // Tokens
    event updateTraitDataEvent(uint16 indexed _id);
    event tokenTraitChangeEvent(uint16 indexed _traitId, uint16 indexed _tokenId, bool mode);


    constructor () {
        initialised = true;                 // GOLDEN protection
    }

    function init(uint32  _communityId, address _owner) external {
        _init(_communityId, _owner);
    }

    function _init(uint32  _communityId, address _owner) internal virtual {
        require(!initialised,"TraitRegistry: Already initialised");
        initialised = true;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // Get Galaxis registry
        if(chainId == 1 || chainId == 5 || chainId == 137 || chainId == 80001 || chainId == 1337 || chainId == 31337 || chainId == 80001) {
            GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "TraitRegistry: invalid chainId");
        }

        // Needed to handle owner behind proxy
        _transferOwnership(_owner);

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);
        myCommunityRegistry = CommunityRegistry(crAddr);

        // Only the GOLDEN version can exist without valid community ID
        address GoldenECRegistryAddr = GalaxisRegistry.getRegistryAddress("GOLDEN_TRAIT_REGISTRY");
        if( GoldenECRegistryAddr != address(this) ) {
            require(crAddr != address(0), "TraitRegistry: Invalid community ID");
        }
    }

    function getTrait(uint16 id) public view returns (traitStruct memory)
    {
        return traits[id];
    }

    function getTraits() public view returns (traitStruct[] memory)
    {
        traitStruct[] memory retval = new traitStruct[](traitCount);
        for(uint16 i = 0; i < traitCount; i++) {
            retval[i] = traits[i];
        }
        return retval;
    }

    function addTrait(
        traitStruct[] calldata _newTraits
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {

        for (uint8 i = 0; i < _newTraits.length; i++) {

            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.id =           _newTraits[i].id;
            newT.name =         _newTraits[i].name;
            newT.traitType =    _newTraits[i].traitType;
            newT.start =        _newTraits[i].start;
            newT.end =          _newTraits[i].end;
            newT.enabled =      _newTraits[i].enabled;
            newT.ipfsHash =    _newTraits[i].ipfsHash;
            newT.storageImplementer = _newTraits[i].storageImplementer;

            emit newTraitMasterEvent(newT.id, newT.name, newT.storageImplementer, newT.traitType, newT.start, newT.end );
        }
    }

    function updateTrait(
        uint16 _index,
        string memory _name,
        address _storageImplementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end,
        bool    _enabled,
        string memory _ipfsHash
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        traits[_index].name = _name;
        traits[_index].storageImplementer = _storageImplementer;
        traits[_index].ipfsHash = _ipfsHash;
        traits[_index].enabled = _enabled;
        traits[_index].traitType = _traitType;
        traits[_index].start = _start;
        traits[_index].end = _end;

        emit updateTraitMasterEvent(traits[_index].id, _name, _storageImplementer, _traitType, _start, _end);
    }

    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) {
        _setTraitUnchecked(traitID, tokenId, _value);
    }

    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) returns(bool) {
        return _setTrait(traitID, tokenId, _value);
    }

    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) public onlyTraitController(traitID) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _setTraitUnchecked(traitID, tokenIds[i], _value[i]);
        }
    }

    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) public onlyTraitController(traitID) returns(uint16 changes) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            if(_setTrait(traitID, tokenIds[i], _value)) {
                changes++;
            }
        }
    }

    function _setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) internal {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
        } else {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
        }
        emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
    }

    // This will only emit event if there was actually a state change!
    // Returns: wasSet - was there any state change
    // Reason: this is being called many times from the various random trait dropper contracts
    function _setTrait(uint16 traitID, uint16 tokenId, bool _value) internal returns(bool wasSet) {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            wasSet = uint8(tokenData[traitID][byteNum] & 2**bitPos) == 0;
            if (wasSet) {
                tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
                emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
            }
        } else {
            wasSet = uint8(tokenData[traitID][byteNum] & 2**bitPos) != 0;
            if (wasSet) {
                tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
                emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
            }
        }
    }

    // set trait data
    function setData(uint16 traitId, uint16[] memory _ids, uint8[] memory _data) public onlyTraitController(traitId) {
        for (uint16 i = 0; i < _data.length; i++) {
            tokenData[traitId][_ids[i]] = _data[i];
        }
        emit updateTraitDataEvent(traitId);
    }

    /*
    *   View Methods
    */

    /*
    * _perPage = 1250 in order to load 10000 tokens ( 10000 / 8; starting from 0 )
    */
    function getData(uint16 traitId, uint8 _page, uint16 _perPage) public view returns (uint8[] memory) {
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues = new uint8[](max);
        while(i < max) {
            retValues[j] = tokenData[traitId][i];
            j++;
            i++;
        }
        return retValues;
    }

    function getTokenData(uint16 tokenId) public view returns (uint8[] memory) {
        uint8[] memory retValues = new uint8[](getByteCountToStoreTraitData());
        // calculate positions for our token
        for(uint16 i = 0; i < traitCount; i++) {
            if(hasTrait(i, tokenId)) {
                uint8 byteNum = uint8(i / 8);
                retValues[byteNum] = uint8(retValues[byteNum] | 2 ** uint8(i - byteNum * 8));
            }
        }
        return retValues;
    }

    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _returnCount = getByteCountToStoreTraitData();
        uint8[] memory retValues = new uint8[](_returnCount);
        for(uint8 i = 0; i < _returnCount; i++) {
            retValues[i] = traitControllerAccess[_addr][i];
        }
        return retValues;
    }

    function getByteCountToStoreTraitData() internal view returns (uint16) {
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < traitCount) {
            _returnCount++;
        }
        return _returnCount;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].storageImplementer;
    }

    function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result)
    {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        bool _result = tokenData[traitID][byteNum] & (0x01 * 2**bitPos) != 0;
        bool _returnVal = (traits[traitID].traitType == 1) ? !_result: _result;
        if(traits[traitID].traitType == 2) {
            // range trait
            if(traits[traitID].start <= tokenId && tokenId <= traits[traitID].end) {
                _returnVal = !_result;
            }
        }
        return _returnVal;
    }

    /*
    *   Admin Stuff
    */

    function setDefaultTraitControllerType(address _addr, uint8 _traitType) external onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        defaultTraitControllerAddressByType[_traitType] = _addr;
        emit traitControllerEvent(_addr);
    }

    function getDefaultTraitControllerByType(uint8 _traitType) external view returns (address) {
        return defaultTraitControllerAddressByType[_traitType];
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        emit traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        emit traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return hasRole(TRAIT_DROP_ADMIN, _addr) || _addr == owner() || traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "TraitRegistry: Unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) {
        return( user == owner() || hasRole(role, user));
    }

    function hasRole(bytes32 key, address user) public view returns (bool) {
        return myCommunityRegistry.hasRole(key, user);
    }

    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "TraitRegistry: Not Authorised"
        );
        _;
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/*
 *    ██████  ██  ██████  ██ ████████  █████  ██          ██████  ███████ ██████  ███████ ███████ ███    ███ 
 *    ██   ██ ██ ██       ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ████  ████ 
 *    ██   ██ ██ ██   ███ ██    ██    ███████ ██          ██████  █████   ██   ██ █████   █████   ██ ████ ██ 
 *    ██   ██ ██ ██    ██ ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ██  ██  ██ 
 *    ██████  ██  ██████  ██    ██    ██   ██ ███████     ██   ██ ███████ ██████  ███████ ███████ ██      ██ 
 *                                                                                                     
 *                                                                                                       
 *    ███████ ████████  ██████  ██████   █████   ██████  ███████                                             
 *    ██         ██    ██    ██ ██   ██ ██   ██ ██       ██                                                  
 *    ███████    ██    ██    ██ ██████  ███████ ██   ███ █████                                               
 *         ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██                                                  
 *    ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████                                             
 *
 *
 *    GALAXIS - Digital Redemption Trait Storage
 *
 */

import "./UTGenericDroppableStorage.sol";

contract UTDigitalRedeemStorage is UTGenericDroppableStorage {

    uint256     public constant  version                = 20230601;

    uint8       public constant  TRAIT_TYPE             = 6;    // Digital redemption
    uint8       public immutable maxTokensToRedeem;             // Number of NFTs the user may ask for with this trait - how many tokens can be claimed (in any chunks)
    uint8       public immutable redeemMode;                    // 0 - Random redeem from the vault (with VRF), 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
    address     public immutable collectionToRedeemFrom;        // Token contract address (ERC721Enumerable) where the user gets a token from
                                                                // If collectionToRedeemFrom == address(0) --> the user may pick the collection from the vault)
                                                                
    // -- Trait storage per tokenID --
    // tokenID => uint8 value
    mapping(uint16 => uint8) data;

    // Events
    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(
        address _registry,
        uint16  _traitId,
        uint8   _maxTokensToRedeem,                 // How many tokens can be claimed (in any chunks)
        uint8   _redeemMode,                        // 0 - Random redeem from the vault (with VRF), 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
        address _collectionToRedeemFrom             // Token contract address (ERC721Enumerable) where the user gets a token from

    ) UTGenericStorage(_registry, _traitId) {
        maxTokensToRedeem = _maxTokensToRedeem;
        redeemMode = _redeemMode;
        collectionToRedeemFrom = _collectionToRedeemFrom;
    }

    // update multiple token values at once
    function setData(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    // update one token value
    function setValue(uint16 _tokenId, uint8 _value) public onlyAllowed {
        data[_tokenId] = _value;
        emit updateTraitEvent(_tokenId, _value);
    }

    // get trait value for one token
    function getValue(uint16 _tokenId) public view returns (uint8) {
        return data[_tokenId];
    }

    // get trait values for an array of tokens
    function getValues(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_tokenIds.length);
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            retval[i] = data[_tokenIds[i]];
        }
        return retval;
    }

    // get trait values for a range of tokens
    function getValues(uint16 _start, uint16 _len) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_len);
        for(uint16 i = 0; i < _len; i++) {
            retval[i] = data[i+_start];
        }
        return retval;
    }

    // --- For interface: IGenericDroppableStorage ---
    // These functions must be implemented for this trait to be used with UTGenericDropper contract

    // Update one token value to TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return bool - was the trait actually opened (or already in a non initial state)?
    function addTraitToToken(uint16 _tokenId) public onlyAllowed returns(bool wasSet) {
        if (data[_tokenId] == TRAIT_INITIAL_VALUE) {
            data[_tokenId] = TRAIT_OPEN_VALUE;
            emit updateTraitEvent(_tokenId, TRAIT_OPEN_VALUE);
            return true;
        } else {
            return false;            
        }
    }

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    // addTraitToToken() was not called from the loop to skip the recurring "onlyAllowed"
    function addTraitOnMultiple(uint16[] memory tokenIds) public onlyAllowed returns(uint16 changes) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            if (data[tokenIds[i]] == TRAIT_INITIAL_VALUE) {
                data[tokenIds[i]] = TRAIT_OPEN_VALUE;
                emit updateTraitEvent(tokenIds[i], TRAIT_OPEN_VALUE);
                changes++;
            }
        }
    }

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) public view returns(bool) {
        return getValue(_tokenId) != 0;
    }

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) public view returns(uint8) {
        return getValue(_tokenId);
    }

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        return getValues(_tokenIds);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/*
 *    ██████  ██  ██████  ██ ████████  █████  ██          ██████  ███████ ██████  ███████ ███████ ███    ███ 
 *    ██   ██ ██ ██       ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ████  ████ 
 *    ██   ██ ██ ██   ███ ██    ██    ███████ ██          ██████  █████   ██   ██ █████   █████   ██ ████ ██ 
 *    ██   ██ ██ ██    ██ ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ██  ██  ██ 
 *    ██████  ██  ██████  ██    ██    ██   ██ ███████     ██   ██ ███████ ██████  ███████ ███████ ██      ██ 
 *                                                                                                     
 *                                                                                                       
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████  
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████  
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██ 
 *                                                                                                     
 *    GALAXIS - Digital Redemption Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTDigitalRedeemStorage contract
 *
 */

import "./UTGenericTimedController.sol";
import "./UTDigitalRedeemVault.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat/console.sol";

contract UTDigitalRedeemController is UTGenericTimedController, UTDigitalRedeemVault {

    uint256     public constant version     = 202300609;

    uint8       public constant TRAIT_TYPE  = 6;                // Digital redemption
    string      public constant APP         = "digitalredeem";  // Application in the claim URL

    event contractControllerEvent(address _address, bool mode);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime,
        address _communityRegistry
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) BlackHolePreventionForCROwner(_communityRegistry)
    {
    }

    function setValue(uint16[] memory tokenId, uint8 value, address traitStorage) public {
        require(
            !locked,
            "UT Digital Redeem Controller: contract locked"
        );
        require(
            tokenId.length > 0,
            "UT Digital Redeem Controller: at least 1 token"
        );
        require(
            getTimestamp() > startTime,
            "UT Digital Redeem Controller: before start time"
        );
        require(
            getTimestamp() < endTime,
            "UT Digital Redeem Controller: after end time"
        );

        ITraitStorage storageCtr = ITraitStorage(traitStorage);

        // Read all current states
        uint8[] memory values = storageCtr.getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            uint8  currentValue = values[i];
            // console.log("setValue: ", currentTokenId, currentValue, value);

            // Business logic (simple)
            if(currentValue >= TRAIT_OPEN_VALUE && value > currentValue && value <= (TRAIT_OPEN_VALUE + storageCtr.maxTokensToRedeem()) ) {
                // From state 1 - "Open to redeem" to any state till (1 + storage.maxTokensToRedeem) - Only owner of the NFT can change it
                require(
                    erc721.ownerOf(currentTokenId) == msg.sender,
                    "UT Digital Redeem Controller: not owner of token"
                );

                uint8 tokensToDrop = value - currentValue;
                _requestDropFromVault(storageCtr.collectionToRedeemFrom(), currentTokenId, traitStorage, tokensToDrop );

                // This will happen in the VRF callback !
                // ITraitStorage(traitStorage).setValue(currentTokenId, value);
            } else {
                require(
                    false,
                    "UT Digital Redeem Controller: invalid state"
                );
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CommunityList is AccessControlEnumerable { 

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");


    uint256                              public numberOfEntries;

    struct community_entry {
        string      name;
        address     registry;
        uint32      id;
    }
    
    mapping(uint32 => community_entry)  public communities;   // community_id => record
    mapping(uint256 => uint32)           public index;         // entryNumber => community_id for enumeration

    event CommunityAdded(uint256 pos, string community_name, address community_registry, uint32 community_id);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
    }

    function addCommunity(uint32 community_id, string memory community_name, address community_registry) external onlyRole(CONTRACT_ADMIN) {
        uint256 pos = numberOfEntries++;
        index[pos]  = community_id;
        communities[community_id] = community_entry(community_name, community_registry, community_id);
        emit CommunityAdded(pos, community_name, community_registry, community_id);
    }

}

pragma solidity ^0.8.13;

interface IRegistryConsumer {

    function getRegistryAddress(string memory key) external view returns (address) ;

    function getRegistryBool(string memory key) external view returns (bool);

    function getRegistryUINT(string memory key) external view returns (uint256) ;

    function getRegistryString(string memory key) external view returns (string memory) ;

    function isAdmin(address user) external view returns (bool) ;

    function isAppAdmin(address app, address user) external view returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract CommunityRegistry is AccessControlEnumerable  {

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");


    uint32                      public  community_id;
    string                      public  community_name;
    address                     public  community_admin;

    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

   // mapping(address => bool)    public  admins;

    mapping(address => mapping(address => bool)) public app_admins;

    mapping (uint => string)    public  addressEntries;
    mapping (uint => string)    public  uintEntries;
    mapping (uint => string)    public  boolEntries;
    mapping (uint => string)    public  stringEntries;
    uint                        public  numberOfAddresses;
    uint                        public  numberOfUINTs;
    uint                        public  numberOfBooleans;
    uint                        public  numberOfStrings;

    uint                        public  nextAdmin;
    mapping(address => bool)    public  adminHas;
    mapping(uint256 => address) public  adminEntries;
    mapping(address => uint256) public  appAdminCounter;
    mapping(address =>mapping(uint256 =>address)) public appAdminEntries;

    address                     public  owner;

    bool                                initialised;

    bool                        public  independant;

    event IndependanceDay(bool gain_independance);

    modifier onlyAdmin() {
        require(isCommunityAdmin(COMMUNITY_REGISTRY_ADMIN),"CommunityRegistry : Unauthorised");
        _;
    }

    // function isCommunityAdmin(bytes32 role) public view returns (bool) {
    //     if (independant){        
    //         return(
    //             msg.sender == owner ||
    //             admins[msg.sender]
    //         );
    //     } else {            
    //        IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
    //        return(
    //             msg.sender == owner || 
    //             hasRole(DEFAULT_ADMIN_ROLE,msg.sender) ||
    //             ac.hasRole(role,msg.sender));
    //     }
    // }

    function isCommunityAdmin(bytes32 role) internal view returns (bool) {
        return isUserCommunityAdmin( role, msg.sender);
    }

    function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
        if (user == owner || hasRole(DEFAULT_ADMIN_ROLE,user) ) return true;
        if (independant){        
            return(
                hasRole(role,user)
            );
        } else {            
           IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
           return(
                ac.hasRole(role,user));
        }
    }

    function grantRole(bytes32 key, address user) public override(AccessControl,IAccessControl) onlyAdmin {
        _grantRole(key,user);
    }
 
    constructor (
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) {
        _init(_community_id,_community_admin,_community_name);
    }

    
    function init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) external {
        _init(_community_id,_community_admin,_community_name);
    }

    function _init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) internal {
        require(!initialised,"This can only be called once");
        initialised = true;
        community_id = _community_id;
        community_name  = _community_name;
        community_admin = _community_admin;
        _setupRole(DEFAULT_ADMIN_ROLE, community_admin); // default admin = launchpad
        owner = msg.sender;
    }



    event AdminUpdated(address user, bool isAdmin);
    event AppAdminChanged(address app,address user,bool state);
    //===
    event AddressChanged(string key, address value);
    event UintChanged(string key, uint256 value);
    event BooleanChanged(string key, bool value);
    event StringChanged(string key, string value);

    function setIndependant(bool gain_independance) external onlyAdmin {
        if (independant != gain_independance) {
                independant = gain_independance;
                emit IndependanceDay(gain_independance);
        }
    }


    function setAdmin(address user,bool status ) external onlyAdmin {
        if (status)
            _grantRole(COMMUNITY_REGISTRY_ADMIN,user);
        else
            _revokeRole(COMMUNITY_REGISTRY_ADMIN,user);
    }

    function hash(string memory field) internal pure returns (bytes32) {
        return keccak256(abi.encode(field));
    }

    function setRegistryAddress(string memory fn, address value) external onlyAdmin {
        bytes32 hf = hash(fn);
        addresses[hf] = value;
        addressEntries[numberOfAddresses++] = fn;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external onlyAdmin {
        bytes32 hf = hash(fn);
        booleans[hf] = value;
        boolEntries[numberOfBooleans++] = fn;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external onlyAdmin {
        bytes32 hf = hash(fn);
        strings[hf] = value;
        stringEntries[numberOfStrings++] = fn;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external onlyAdmin {
        bytes32 hf = hash(fn);
        uints[hf] = value;
        uintEntries[numberOfUINTs++] = fn;
        emit UintChanged(fn,value);
    }

    function setAppAdmin(address app, address user, bool state) external {
        require(
            msg.sender == IOwnable(app).owner() ||
            app_admins[app][msg.sender],
            "You do not have access permission"
        );
        app_admins[app][user] = state;
        if (state)
            appAdminEntries[app][appAdminCounter[app]++] = user;
        emit AppAdminChanged(app,user,state);
    }

    function getRegistryAddress(string memory key) external view returns (address) {
        return addresses[hash(key)];
    }

    function getRegistryBool(string memory key) external view returns (bool) {
        return booleans[hash(key)];
    }

    function getRegistryUINT(string memory key) external view returns (uint256) {
        return uints[hash(key)];
    }

    function getRegistryString(string memory key) external view returns (string memory) {
        return strings[hash(key)];
    }

 

    function isAppAdmin(address app, address user) external view returns (bool) {
        return 
            user == IOwnable(app).owner() ||
            app_admins[app][user];
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHolePrevention is Ownable {
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";
import "../interfaces/IGenericDroppableStorage.sol";
import "./UTGenericStorage.sol";

abstract contract UTGenericDroppableStorage is UTGenericStorage, IGenericDroppableStorage {
    uint8              constant     TRAIT_INITIAL_VALUE = 0;
    uint8              constant     TRAIT_OPEN_VALUE = 1;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IECRegistry {
    function addTrait(traitStruct[] memory) external; 
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    // ---- Change start ----
    function setTrait(uint16 traitID, uint16 tokenID, bool) external returns (bool);
    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external;
    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) external returns(uint16 changes);
    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) external;
    function getTrait(uint16 id) external view returns (traitStruct memory);
    function getTraits() external view returns (traitStruct[] memory);
    // ---- Change end ----
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
    function getDefaultTraitControllerByType(uint8) external view returns (address);
    function setDefaultTraitControllerType(address, uint8) external;
    function setTraitControllerAccess(address, uint16, bool) external;
    function traitCount() external view returns (uint16);

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;
        uint16  end;
        bool    enabled;
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;
        string  name;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IGenericDroppableStorage {
    // Update one token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: bool - was the trait actually opened?
    function addTraitToToken(uint16 _tokenId) external returns(bool);

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    function addTraitOnMultiple(uint16[] memory tokenIds) external returns(uint16 changes);

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) external view returns(bool);

    // // Was the trait activated (meaning it has non zero uint8 value) on multiple token
    // function haveTrait(uint16[] memory _tokenId) external view returns(bool[] memory);

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) external view returns(uint8);

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) external view returns (uint8[] memory);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IECRegistry.sol";

abstract contract UTGenericStorage {
    uint16      public immutable    traitId;
    IECRegistry public immutable    ECRegistry;

    constructor(
        address _registry,
        uint16 _traitId
    ) {       
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "UTStorage: Not Authorised"
        );
        _;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function isAllowed(bytes32 role, address user) external view returns (bool);
}

abstract contract UTGenericTimedController {
    bytes32             public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    IERC721             public erc721;                      // NFT ToolBox
    ITraitRegistry      public registry;                    // Trait registry
    bool                public locked       = false;
    uint256             public startTime;
    uint256             public endTime;

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) {
        erc721 = IERC721(_erc721);
        registry = ITraitRegistry(_registry);
        startTime = _startTime;
        endTime = _endTime == 0 ? 9999999999 : _endTime;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    struct contractInfo {
        address erc721;
        address registry;
        bool    locked;
        uint256 startTime;
        uint256 endTime;
        bool    available;
    }

    function tellEverything() external view returns (contractInfo memory) {
        return contractInfo(
            address(erc721),
            address(registry),
            locked,
            startTime,
            endTime,
            (getTimestamp() >= startTime && getTimestamp() <= endTime && !locked )
        );
    }

    /*
    *   Admin Stuff - For controlling the toggleLock() funtion
    */

    function toggleLock() public {
        require(
            registry.isAllowed(TRAIT_REGISTRY_ADMIN, msg.sender),
            "UTController: Not authorised"
        );
        locked = !locked;
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRegistryConsumer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../extras/recovery/BlackHolePreventionForCROwner.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// import "hardhat/console.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, uint8 _value) external;
    function getValue(uint16 _tokenId) external view returns (uint8);
    function getValues(uint16[] memory _tokenIds) external view returns (uint8[] memory);
    function traitId() external view returns (uint16);
    function maxTokensToRedeem() external view returns (uint8);
    function collectionToRedeemFrom() external view returns (address);
    function redeemMode() external view returns (uint8);
}

abstract contract UTDigitalRedeemVault is ERC721Holder, BlackHolePreventionForCROwner {
    string                         public constant  REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP_TRAIT_DROPPER";
    uint8                                 constant  TRAIT_OPEN_VALUE = 1;
    IRegistryConsumer              public constant  GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet tokenContracts;

    enum RedeemMode {
        random,                             // 0 - Random redeem from the vault (with VRF)
        first                               // 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
        // pick                             // 2 - Nonrandom redeem from the vault (user may select which card to transfer from vault) (no VRF) - NOT supported yet
    }

    enum ErrorCode {
        ok,                                 // 0 - 
        non_erc721,                         // 1 - 
        not_enough_token,                   // 2 - 
        claim_over_limit                    // 3 - 
    }

    struct dropStruct {
        uint256                     requestId;              // Request Id from chainlink
        address                     erc721;                 // Token contract of the user's NFT
        address                     traitStorage;           // The trait storage is needed to handle race conditions (the user requested the claim so we need to check if someone changing the trait value before the callback)
        uint16                      tokenId;                // Token Id that initiated the request
        address                     recipient;              // Address that initiated the request
        uint8                       tokensToDrop;           // Number of digital redeemable NFTs the user requested
        uint256                     randomNumber;           // Filled by VRF callback
        bool                        randomReceived;         // VRF was received
        bool                        randomProcessed;        // The token was transfered
        ErrorCode                   errorCode;              // Stores error on VRF callback side (here we do not want to revert)
    }

    struct vaultDetails {                             // Structure to return detailed data from vault token contracts
        address                     erc721;
        string                      name;
        string                      symbol;
        uint256                     balance;
        string                      firstTokenURI;
    }

    uint32                          public              currentDropCount;

    mapping(uint32 => dropStruct)   public              drops;
    mapping(uint256 => uint32)      public              requestToDropIndex;

    // claimedTokens[traitId][tokenId][n] --> n-th received NFT for the trait+token
    mapping(uint16 => mapping(uint16 => mapping(uint16 => uint16) ) ) public claimedTokens;

    // traitTokenToDropIndex[traitId][tokenId] --> the used dropIndex for the trait+token
    mapping(uint16 => mapping(uint16 => uint32) ) public traitTokenToDropIndex;

    // Events
    event vaultDropRequested(uint32 index);
    event vaultDropProcess(uint32 index);

    // Errors
    error claimOverLimit(uint8 value);
    error notEnoughToken(uint8 value);
    error notERC721Enumerable(address value);
    error unauthorisedCall(address value);
    error invalidCollection(address value);

    /**
     * @dev Called from the trait controller when user claims the digital redeemable
     *      Depending on redeem mode:
     *          - Transfer cards directly
     *          - Calls VRF
     */
    function _requestDropFromVault(address _erc721, uint16 _tokenId, address _traitStorage, uint8 _tokensToDrop) internal {
        // Pre-check
        IERC721Enumerable  token = IERC721Enumerable(_erc721);
        if (!token.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            revert notERC721Enumerable(_erc721);
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance < _tokensToDrop ) {
            revert notEnoughToken(_tokensToDrop);
        }

        ITraitStorage traitStorage = ITraitStorage(_traitStorage);
        uint8 newTraitValue = traitStorage.getValue(_tokenId) + _tokensToDrop;
        if (newTraitValue > TRAIT_OPEN_VALUE + traitStorage.maxTokensToRedeem()) {
            revert claimOverLimit(newTraitValue);
        }

        uint16 traitId = traitStorage.traitId();

        // Prepare drop structure
        dropStruct storage currentDrop = drops[++currentDropCount];
        currentDrop.erc721             = _erc721;
        currentDrop.traitStorage       = _traitStorage;
        currentDrop.tokenId            = _tokenId;
        currentDrop.tokensToDrop       = _tokensToDrop;
        currentDrop.recipient          = msg.sender;
        if (traitStorage.redeemMode() == uint8(RedeemMode.random)) {
            // Random drop requested
            currentDrop.requestId          = IRandomNumberProvider(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
            requestToDropIndex[currentDrop.requestId] = currentDropCount;
            emit vaultDropRequested(currentDropCount);
        } else {
            // Nonrandom (first) drop requested
            for(uint16 i = 0; i < _tokensToDrop; i++) {       
                uint256 tokenId = token.tokenOfOwnerByIndex(address(this), 0);
                token.safeTransferFrom(address(this), msg.sender, tokenId);
                claimedTokens[traitId][_tokenId][i] = uint16(tokenId);
            }
            traitStorage.setValue(_tokenId, newTraitValue);         // Set storage to new state value
            emit vaultDropProcess(currentDropCount);
        }

        traitTokenToDropIndex[traitId][_tokenId] = currentDropCount;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        if (msg.sender != GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)) {
            revert unauthorisedCall(msg.sender);
        }

        dropStruct storage drop = drops[requestToDropIndex[_requestId]];

        drop.randomNumber = _random;
        drop.randomReceived = true;
        transferRandom(requestToDropIndex[_requestId]);
        emit vaultDropProcess(requestToDropIndex[_requestId]);
    }

    /**
     * @dev Called in the VRF callback part - transfers the randomly picked token from the vault to the user
     */
    function transferRandom(uint32 _dropId) internal {

        dropStruct memory drop = drops[_dropId];
        uint8 tokensToDrop = drop.tokensToDrop;
        uint256 initRandom = drop.randomNumber;
        uint256 random = initRandom;
        drops[_dropId].randomProcessed = true;

        IERC721Enumerable  token = IERC721Enumerable(drop.erc721);
        if (!token.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            // UTDigitalRedeemVault: not an ERC721Enumerable
            drops[_dropId].errorCode = ErrorCode.non_erc721;
            return;
        }
        uint256 balance = token.balanceOf(address(this));
        if (balance < tokensToDrop ) {
            // UTDigitalRedeemVault: Not enough tokens in vault
            drops[_dropId].errorCode = ErrorCode.not_enough_token;
            return;
        }

        ITraitStorage traitStorage = ITraitStorage(drop.traitStorage);
        uint8 newTraitValue = traitStorage.getValue(drop.tokenId) + drop.tokensToDrop;
        if ( newTraitValue > TRAIT_OPEN_VALUE + traitStorage.maxTokensToRedeem()) {
            //  UTDigitalRedeemVault: claim over limit
            drops[_dropId].errorCode = ErrorCode.claim_over_limit;
            return;
        }

        uint16 traitId = traitStorage.traitId();
        traitTokenToDropIndex[traitId][drop.tokenId] = _dropId;     // If the claim was started multiple times and if the VRF failed, then let the later callback update the dropId in the traitTokenToDropIndex mapping

        traitStorage.setValue(drop.tokenId, newTraitValue);         // Set storage to new state value

        for(uint16 i = 0; i < tokensToDrop; i++) {       
            uint256 tokenPos = random % balance;
            uint256 tokenId = token.tokenOfOwnerByIndex(address(this), tokenPos);
            token.transferFrom(address(this), drop.recipient, tokenId);
            claimedTokens[traitId][drop.tokenId][i] = uint16(tokenId);
            balance--;
            random = random >> 1;
            if (random < balance) {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }
        }
    }

    /**
     * @dev Called during token transfer if called with safeTransferFrom() from an ERC721 token
     * note The vault may receive its tokens via
     *        - using safeTransferFrom(): in this case it will check if the token is in the accepted list, else revert
     *        - directly minting to this vault address or using transferFrom: in this case the notifyVault() should be called for the contract to be registered
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {

        // Only accept ERC721Enumerable
        if (!IERC721Enumerable(msg.sender).supportsInterface(type(IERC721Enumerable).interfaceId)) {
            revert notERC721Enumerable(msg.sender);
        }

        // Do not accept any kind of random tokens, only those approved by the community owner
        if (!tokenContracts.contains(msg.sender)) {
            revert invalidCollection(msg.sender);
        }

        return this.onERC721Received.selector;
    }

    /**
     * @dev Registers the new token contract into the tokenContractAddress set
     * note The vault may receive its tokens via
     *        - using safeTransferFrom(): in this case it will check if the token is in the accepted list, else revert
     *        - directly minting to this vault address or using transferFrom: in this case the notifyVault() should be called for the contract to be registered
     */
    function notifyVault(address tokenContractAddress) external onlyAllowed {
        if (!IERC721Enumerable(tokenContractAddress).supportsInterface(type(IERC721Enumerable).interfaceId)) {
            revert notERC721Enumerable(tokenContractAddress);
        }
        tokenContracts.add(tokenContractAddress);
    }

    function getVaultLength() public view returns (uint256) {
        return tokenContracts.length();
    }

    function getVaultAt(uint256 _index) public view returns (address) {
        return tokenContracts.at(_index);
    }

    function getVaultContains(address _addr) public view returns (bool) {
        return tokenContracts.contains(_addr);
    }

    /**
     * @dev Return all token contracts known by the vault
     *      Has an unbounded cost!
     */
    function getAllVaults() public view returns (address[] memory)
    {
        return tokenContracts.values();
    }

    /**
     * @dev Return detailed information about each token contract with a representative token's uri inside the vault's address
     *      Has an unbounded cost!
     */
    function getAllVaultsDetails() public view returns (vaultDetails[] memory retval)
    {
        uint256 vaultLength = tokenContracts.length();
        retval = new vaultDetails[](vaultLength);
        for(uint16 contractIdx = 0; contractIdx < vaultLength; contractIdx++) {
            address tokenContract = tokenContracts.at(contractIdx);
            IERC721Enumerable erc721 = IERC721Enumerable(tokenContract);
            uint256 balance = erc721.balanceOf(address(this));
            IERC165 erc165 = IERC165(tokenContract);
            if (erc165.supportsInterface(type(IERC721Metadata).interfaceId)) {
                // IERC721Metadata available
                IERC721Metadata metaData = IERC721Metadata(tokenContract);
                if (balance > 0) {
                    // Use the first token owned by the vault as a representative
                    retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, metaData.tokenURI(erc721.tokenOfOwnerByIndex(address(this), 0)));
                } else {
                    try metaData.tokenURI(1) returns (string memory uri) {
                        // Use the first token as a representative
                        retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, uri);
                    } catch {
                        // Not even a minted token
                        retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, "");
                    }
                }
            } else {
                // No IERC721Metadata available
                retval[contractIdx] = vaultDetails(tokenContract , "", "", balance, "");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberProvider {
    function requestRandomNumber() external returns (uint256 requestId);
    function requestRandomNumberWithCallback() external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICommunityRegistry {
    function community_admin() external view returns (address);
}

contract BlackHolePreventionForCROwner {

    ICommunityRegistry             public immutable communityRegistry;

    constructor(
        address _communityRegistry
    ) {
        communityRegistry = ICommunityRegistry(_communityRegistry);
    }

    modifier onlyAllowed() { 
        require(
            communityRegistry.community_admin() == msg.sender,
            "BlackHolePreventionForCROwner: Not authorised"
        );
        _;
    }

    // blackhole prevention methods

    function retrieveETH() external onlyAllowed {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) public onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    function retrieveMultiple721(address _tracker, uint256[] memory ids) external onlyAllowed {
        for (uint16 i = 0; i < ids.length; i++) {
            retrieve721(_tracker, ids[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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