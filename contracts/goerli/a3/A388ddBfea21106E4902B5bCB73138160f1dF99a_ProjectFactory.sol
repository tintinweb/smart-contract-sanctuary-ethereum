// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./SaleFactory.sol";
import "./TokenFactory.sol";
import "../token/IToken.sol";
import "../sale/ISaleContract.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../../@galaxis/registries/contracts/Hook.sol";


interface OwnableContract {
    function owner() external view returns (address);
}


contract ProjectFactory is Ownable, BlackHolePrevention {
    using Strings  for uint256; 
    using Strings  for uint32; 
    using Strings  for uint8; 

    IRegistryConsumer               public TheRegistry;
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT  = "RANDOMV2_SSP";
    string              constant    public REGISTRY_KEY_PROJECT_FACTORY_CONTRACT  = "PROJECT_FACTORY";
    string              constant    public REGISTRY_KEY_COMMUNITY_LIST   = "COMMUNITY_LIST";
    string              constant    public REGISTRY_KEY_SSP_FACTORY_HOOK = "SSP_FACTORY_HOOK";
    bytes32             constant    public COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    TokenFactoryV1                  public TokenFactory;
    SaleFactoryV1                   public SaleFactory;


    uint256 public projectCount = 0;
    uint256 public projectIdOffset = 0;
    uint256 public chainid = 0;

    event NewProject(uint256 _projectCount);

    constructor(
        address TokenFactoryAddress,
        address SaleFactoryAddress
    ) {
        uint256 id;
        assembly {
            id := chainid()
        }
        chainid = id;

        if(chainid == 1 || chainid == 5 || chainid == 1337 || chainid == 31337) {
            TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "ProjectFactory: invalid chainId");
        }

        TokenFactory = TokenFactoryV1(TokenFactoryAddress);
        SaleFactory = SaleFactoryV1(SaleFactoryAddress);
    }

    function updateFactoryContracts(
        address TokenFactoryAddress,
        address SaleFactoryAddress
    ) external {
        require(msg.sender == owner(), "ProjectFactory: Not owner!");

        TokenFactory = TokenFactoryV1(TokenFactoryAddress);
        SaleFactory = SaleFactoryV1(SaleFactoryAddress);
    }

    function LaunchProject(
        uint32 communityId,
        SaleConfiguration memory saleConfig,
        TokenConstructorConfig memory tokenConfig
    ) external  {

        // validate this contract is the current version to be used. else fail
        address PROJECT_FACTORY = TheRegistry.getRegistryAddress(REGISTRY_KEY_PROJECT_FACTORY_CONTRACT);
        require(PROJECT_FACTORY == address(this), "ProjectFactory: Not current project factory.");

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress(REGISTRY_KEY_COMMUNITY_LIST));
        (, address crAddr, ) = COMMUNITY_LIST.communities(communityId);
        require(crAddr != address(0), "ProjectFactory: Invalid community ID");
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);
        require(thisCommunityRegistry.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN, msg.sender), "ProjectFactory: Community not owned by sender");
        
        // require(thisCommunityRegistry.community_admin() == msg.sender, "ProjectFactory: Not owned by sender");
            
        saleConfig.projectID = communityId;
        tokenConfig.projectID = communityId;

        // Launch new token contract
        address _newTokenAddress = TokenFactory.deploy(tokenConfig, msg.sender);

        // add the new token contract address into the sale
        saleConfig.token = _newTokenAddress;

        // Launch new sale contract
        address _newSaleAddress = SaleFactory.deploy(saleConfig, msg.sender);

        // Give sale contract TOKEN_CONTRACT_ACCESS_SALE role in Community Registry so it can call mint methods in token
        thisCommunityRegistry.grantRole(
            IToken(_newTokenAddress).TOKEN_CONTRACT_ACCESS_SALE(),
            _newSaleAddress
        );

        // give random number provider access to the token
        IRandomNumberProvider random = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT));
        random.setAuth(address(_newTokenAddress), true);

        // set community token counts 
        uint256 existingTokenCount = thisCommunityRegistry.getRegistryUINT("TOKEN_COUNT");
        thisCommunityRegistry.setRegistryUINT("TOKEN_COUNT", ++existingTokenCount);

        // set new community token address
        thisCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("TOKEN_", existingTokenCount.toString())),
            _newTokenAddress
        );

        // set community sale counts 
        uint256 existingSaleCount = thisCommunityRegistry.getRegistryUINT("SALE_COUNT");
        thisCommunityRegistry.setRegistryUINT("SALE_COUNT", ++existingSaleCount);

        // set new community sale address
        thisCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("SALE_", existingSaleCount.toString())),
            _newSaleAddress
        );

        // call finish hook
        // hook finishHook = hook( TheRegistry.getRegistryAddress(REGISTRY_KEY_SSP_FACTORY_HOOK) );
        // HookData memory data = HookData(
        //     communityId, 
        //     saleConfig,
        //     tokenConfig
        // );
        // finishHook.TJHooker(
        //     "SSP_FACTORY_HOOK_NEW_PROJECT", data
        // );


        emit NewProject(communityId);
    }

    struct HookData {
        uint32 communityId;
        SaleConfiguration saleConfig;
        TokenConstructorConfig tokenConfig;
    }


    struct ProjectDetails {
        address[] tokenContracts;
        address[] saleContracts;
        TokenInfo[] tokenInfo;
        SaleInfo[] saleInfo;
        uint256 chainid;
    }

    function getProjectDetails(uint32 communityId) public view returns (ProjectDetails memory) {

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress(REGISTRY_KEY_COMMUNITY_LIST));
        (, address crAddr, ) = COMMUNITY_LIST.communities(communityId);
        require(crAddr != address(0), "ProjectFactory: Invalid community ID");
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);

        uint256 existingTokenCount = thisCommunityRegistry.getRegistryUINT("TOKEN_COUNT");
        uint256 existingSaleCount = thisCommunityRegistry.getRegistryUINT("SALE_COUNT");

        address[] memory _tokenAddresses = new address[](existingTokenCount);
        TokenInfo[] memory _tokenInfo = new TokenInfo[](existingTokenCount);
        for(uint8 i = 0; i < existingTokenCount; i++) {
            string memory key = string(abi.encodePacked("TOKEN_", (i+1).toString()));
            address thisAddress = thisCommunityRegistry.getRegistryAddress(key);
            if(thisAddress != address(0)) {
                _tokenAddresses[i] = thisAddress;
                _tokenInfo[i] = IToken(thisAddress).tellEverything();
            } 
        }

        address[] memory _saleAddresses = new address[](existingSaleCount);
        SaleInfo[] memory _saleInfo = new SaleInfo[](existingSaleCount);
        for(uint8 i = 0; i < existingSaleCount; i++) {

            string memory key = string(abi.encodePacked("SALE_", (i+1).toString()));
            address thisAddress = thisCommunityRegistry.getRegistryAddress(key);
            if(thisAddress != address(0)) {
                _saleAddresses[i] = thisAddress;
                _saleInfo[i] = ISaleContract(thisAddress).tellEverything();
            } 
        }

        return ProjectDetails(
            _tokenAddresses,
            _saleAddresses,
            _tokenInfo,
            _saleInfo,
            chainid
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../token/LockableRevealERC721EnumerableToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFactoryV1 is Ownable, BlackHolePrevention {

    function deploy(
        TokenConstructorConfig memory tokenConfig,
        address _actualOwner
    ) external returns (address) {
        // Launch new token contract
        LockableRevealERC721EnumerableToken token = new LockableRevealERC721EnumerableToken();
        token.setup(tokenConfig);

        // transfer ownership of the new contract to owner
        token.transferOwnership(_actualOwner);
        return address(token);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../sale/SaleContract.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SaleFactoryV1 is Ownable, BlackHolePrevention {

    function deploy(
        SaleConfiguration memory saleConfig,
        address _actualOwner
    ) external returns (address) {
        // Launch new sale contract
        SaleContract sale = new SaleContract();
        sale.setup(saleConfig);
        
        // transfer ownership of the new contract to owner
        sale.transferOwnership(_actualOwner);
        return address(sale);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRegistryConsumer {
    function getRegistryAddress(string memory key) external view returns (address) ;
    function getRegistryBool(string memory key) external view returns (bool);
    function getRegistryUINT(string memory key) external view returns (uint256) ;
    function getRegistryString(string memory key) external view returns (string memory) ;
    function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct SaleConfiguration {
    uint256 projectID; 
    address token;
    address payable[] wallets;
    uint16[] shares;

    uint256 maxMintPerTransaction;      // How many tokens a transaction can mint
    uint256 maxApprovedSale;            // Max sold in approvedsale across approvedsale eth
    uint256 maxApprovedSalePerAddress;  // Limit discounts per address
    uint256 maxSalePerAddress;

    uint256 approvedsaleStart;
    uint256 approvedsaleEnd;
    uint256 saleStart;
    uint256 saleEnd;

    uint256 fullPrice;
    uint256 maxUserMintable;
    address signer;
    uint256 fullDustPrice;
    bool    ethSaleEnabled;
    bool    erc777SaleEnabled;
    address erc777tokenAddress;
}


struct SaleInfo {
    SaleConfiguration config;
    uint256 userMinted;
    bool    approvedSaleIsActive;
    bool    saleIsActive;
}

struct SaleSignedPayload {
    uint256 projectID;
    uint256 chainID;  // 1 mainnet / 4 rinkeby / 11155111 sepolia / 137 polygon / 80001 mumbai
    bool    free;
    uint16  max_mint;
    address receiver;
    uint256 valid_from;
    uint256 valid_to;
    uint256 eth_price;
    uint256 dust_price;
    bytes   signature;
}

struct tokenPayload {
    uint256 numberOfCards;
    SaleSignedPayload payload;
}

interface ISaleContract {
    function UpdateSaleConfiguration(SaleConfiguration memory) external;
    function UpdateWalletsAndShares(address payable[] memory, uint16[] memory) external;
    function mint(uint256) external payable;
    function crossmint(uint256, address) external payable;
    function mint_approved(SaleSignedPayload memory _payload, uint256 _numberOfCards) external payable;
    function tellEverything() external view returns (SaleInfo memory);
    function getBlockTimestamp() external view returns(uint256);

    // ERC677
    function onTokenTransfer(address from, uint amount, bytes calldata userData) external;
    // ERC777
    function tokensReceived(address, address from, address, uint256 amount, bytes calldata userData, bytes calldata) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct revealStruct {
    uint256 REQUEST_ID;
    uint256 RANDOM_NUM;
    uint256 SHIFT;
    uint256 RANGE_START;
    uint256 RANGE_END;
    bool processed;
}

struct TokenInfoForSale {
    uint256 projectID;
    uint256 maxSupply;
    uint256 reservedSupply;
}

struct TokenInfo {
    string      name;
    string      symbol;
    uint256     projectID;
    uint256     maxSupply;
    uint256     mintedSupply;
    uint256     mintedReserve;
    uint256     reservedSupply;
    uint256     giveawaySupply;
    string      tokenPreRevealURI;
    string      tokenRevealURI;
    bool        transferLocked;
    bool        lastRevealRequested;
    uint256     totalSupply;
    revealStruct[] reveals;
    address     owner;
    address[]   managers;
    address[]   controllers;
}

struct TokenConstructorConfig {
    uint256 projectID;
    uint256 maxSupply;
    string  erc721name;
    string  erc721symbol;
    string  tokenPreRevealURI;
    string  tokenRevealURI;     
    bool    transferLocked;
    uint256 reservedSupply;
    uint256 giveawaySupply;
}

interface IToken {

    function TOKEN_CONTRACT_GIVEAWAY() external returns (bytes32);
    function TOKEN_CONTRACT_ACCESS_SALE() external returns (bytes32);
    function TOKEN_CONTRACT_ACCESS_ADMIN() external returns (bytes32);
    function TOKEN_CONTRACT_ACCESS_LOCK() external returns (bytes32);
    function TOKEN_CONTRACT_ACCESS_REVEAL() external returns (bytes32);

    function mintIncrementalCards(uint256, address) external;
    function mintReservedCards(uint256, address) external;
    function mintGiveawayCard(uint256, address) external;

    function setPreRevealURI(string calldata) external;
    function setRevealURI(string calldata) external;

    function revealAtCurrentSupply() external;
    function lastReveal() external;
    function process(uint256, uint256) external;
    
    function uri(uint256) external view returns (uint256);
    function tokenURI(uint256) external view returns (string memory);

    function setTransferLock(bool) external;
    function hasRole(bytes32, address) external view returns (bool);
    function isAllowed(bytes32, address) external view returns (bool);    

    function getFirstGiveawayCardId() external view returns (uint256);
    function tellEverything() external view returns (TokenInfo memory);
    function getTokenInfoForSale() external view returns (TokenInfoForSale memory);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

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

import "./IRegistry.sol";

interface hookey {

    function Process(bytes memory data) external;
}


contract hook {

    IRegistry reg = IRegistry(0x1e8150050A7a4715aad42b905C08df76883f396F);
 
    function TJHooker(string memory key, bytes calldata data) external {
        hookey hookAddress = hookey(reg.getRegistryAddress(key));
        if (address(hookAddress) == address(0)) return;
        hookAddress.Process(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IToken.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRandomNumberRequester.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../overrides/ERC721Enumerable.sol";

contract LockableRevealERC721EnumerableToken is IToken, ERC721Enumerable, Ownable, BlackHolePrevention {
    using Strings  for uint256; 
 
    bytes32 public constant TOKEN_CONTRACT_GIVEAWAY         = keccak256("TOKEN_CONTRACT_GIVEAWAY");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_SALE      = keccak256("TOKEN_CONTRACT_ACCESS_SALE");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_ADMIN     = keccak256("TOKEN_CONTRACT_ACCESS_ADMIN");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_LOCK      = keccak256("TOKEN_CONTRACT_ACCESS_LOCK");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_REVEAL    = keccak256("TOKEN_CONTRACT_ACCESS_REVEAL");

    

    IRegistryConsumer               public TheRegistry;
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP";

    uint256                         public projectID;
    uint256                         public maxSupply;
    uint256                         public mintedSupply;    // minted incrementally
    uint256                         public mintedReserve;   
    uint256                         public reservedSupply;  // includes giveaway supply
    uint256                         public giveawaySupply;

    string                          public tokenPreRevealURI;
    string                          public tokenRevealURI;
    bool                            public transferLocked;
    bool                            public lastRevealRequested;

    mapping(uint16 => revealStruct) public reveals;
    mapping(uint256 => uint16)      public requestToRevealId;
    string                          public revealURI;
    uint16                          public currentRevealCount;
    string                          public contractURI;
    bool                            _initialized;
    
    CommunityRegistry               public myCommunityRegistry;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractControllers;
    event contractControllerEvent(address _address, bool mode);
    EnumerableSet.AddressSet contractManagers;
    event contractManagerEvent(address _address, bool mode);

    event Locked(bool);
    event RandomProcessed(uint256 stage, uint256 randNumber, uint256 _shiftsBy, uint256 _start, uint256 _end);
    event ContractURIset(string contractURI);

    function setup(TokenConstructorConfig memory config) public onlyOwner {
        require(!_initialized, "Token: Contract already initialized");
       
        ERC721.setup(config.erc721name, config.erc721symbol);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if(chainId == 1 || chainId == 5 || chainId == 1337 || chainId == 31337) {
            TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "Token: invalid chainId");
        }

        projectID           = config.projectID;
        tokenPreRevealURI   = config.tokenPreRevealURI;
        tokenRevealURI      = config.tokenRevealURI;
        maxSupply           = config.maxSupply;
        transferLocked      = config.transferLocked;
        reservedSupply      = config.reservedSupply;
        giveawaySupply      = config.giveawaySupply;

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress("COMMUNITY_LIST"));
        (,address crAddr,) = COMMUNITY_LIST.communities(uint32(projectID));
        myCommunityRegistry = CommunityRegistry(crAddr);

        _initialized = true;
    }


    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        require(!transferLocked, "Token: Transfers are not enabled");
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    /**
     * @dev Sale: mint cards.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_SALE
     */
    function mintIncrementalCards(uint256 numberOfCards, address recipient) external onlyAllowed(TOKEN_CONTRACT_ACCESS_SALE) {
        require(!lastRevealRequested, "Token: Cannot mint after last reveal");
        require(mintedSupply + numberOfCards <= maxSupply - reservedSupply, "Token: This would exceed the number of cards available");
        uint256 mintId = mintedSupply + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedSupply+=numberOfCards;
    }

    /**
     * @dev Admin: mint reserved cards.
     *   Should only mint reserved AFTER the sale is over.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function mintReservedCards(uint256 numberOfCards, address recipient) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve + numberOfCards <= reservedSupply - giveawaySupply, "Token: This would exceed the number of cards reserved cards available");
        uint256 mintId = mintedSupply + mintedReserve + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedReserve+=numberOfCards;
    }

    /**
     * @dev DropRegistry util
     */
    function getFirstGiveawayCardId() public view returns (uint256) {
        return mintedSupply + reservedSupply - giveawaySupply + 1;
    }

    /**
     * @dev DropRegistry: mint specific giveaway card.
     *   Can only mint after reserve has been minted.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_GIVEAWAY
     */
    function mintGiveawayCard(uint256 _index, address _recipient) external onlyAllowed(TOKEN_CONTRACT_GIVEAWAY) {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve == reservedSupply - giveawaySupply, "Token: Must mint reserved cards first");
        uint256 firstIndex = getFirstGiveawayCardId();
        require( _index >= firstIndex && _index < firstIndex + giveawaySupply, "Token: Card id not in range");
        _mint(_recipient, _index);
    }

    /**
     * @dev Admin: set PreRevealURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setPreRevealURI(string calldata _tokenPreRevealURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        tokenPreRevealURI = _tokenPreRevealURI;
    }

    /**
     * @dev Admin: set RevealURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setRevealURI(string calldata _tokenRevealURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        tokenRevealURI = _tokenRevealURI;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to current supply
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_REVEAL
     */
    function revealAtCurrentSupply() external onlyAllowed(TOKEN_CONTRACT_ACCESS_REVEAL) {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < mintedSupply, "Token: Reveal request already exists");
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to max supply
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_REVEAL
     */
    function lastReveal() external onlyAllowed(TOKEN_CONTRACT_ACCESS_REVEAL) {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < maxSupply, "Token: Reveal request already exists");
        lastRevealRequested = true;
        revealStruct storage currentReveal = reveals[++currentRevealCount];
        currentReveal.RANGE_END = mintedSupply + reservedSupply;
        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        require(msg.sender == TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "Token: process() Unauthorised caller");

        // get reveal using _requestId
        uint16 thisRevealId = requestToRevealId[_requestId];
        revealStruct storage thisReveal = reveals[thisRevealId];

        require(!thisReveal.processed, "Token: reveal already processed.");

        if(thisReveal.REQUEST_ID == _requestId) {
            thisReveal.RANDOM_NUM = _random / 2; // Set msb to zero

            // in the very rare case where RANDOM_NUM is 0, use currentReveal.RANGE_END / 3
            if(thisReveal.RANDOM_NUM == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANGE_END * (10 ** 5) / 3;
            }

            thisReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;
            thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            
            // in the very rare case where the shifting result is 0, do it again but divide by 3
            if(thisReveal.SHIFT == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANDOM_NUM / 3;
                thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            }

            thisReveal.processed = true;

            emit RandomProcessed(
                thisRevealId,
                thisReveal.RANDOM_NUM,
                thisReveal.SHIFT,
                thisReveal.RANGE_START,
                thisReveal.RANGE_END
            );

        } else revert("Token: Incorrect requestId received");
    }


    function findRevealRangeForN(uint256 n) public view returns (uint16) {
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            if(n <= reveals[i].RANGE_END) {
                return i;
            }
        }
        return 0;
    }

    function uri(uint256 n) public view returns (uint256) {
        uint16 rangeId = findRevealRangeForN(n); 
        // outside ranges
        if(rangeId == 0) {
            return n;
        }

        revealStruct memory currentReveal = reveals[rangeId];
        uint256 shiftedN = n + currentReveal.SHIFT;
        if (shiftedN <= currentReveal.RANGE_END) {
            return shiftedN;
        }
        return currentReveal.RANGE_START + shiftedN - currentReveal.RANGE_END;
    }

    /**
    * @dev Reserved are always at the end of current minted 
    */
    function _reserved(uint256 _tokenId) public view returns (bool) {
        if(_tokenId > mintedSupply + mintedReserve && _tokenId <= mintedSupply + reservedSupply) {
            return true;
        }
        return false;
    }

    /**
    * @dev Get metadata server url for tokenId
    */
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        require(_exists(_tokenId) || _reserved(_tokenId), 'Token: Token does not exist');

        uint16 rangeId = findRevealRangeForN(_tokenId);
        // outside ranges
        if(rangeId == 0) {
            return tokenPreRevealURI;
        }

        revealStruct memory currentReveal = reveals[rangeId];

        // if random number was not set, return pre reveal
        // TODO: most likely remove this.. as we never get here.. we're already outside range
        if(currentReveal.RANDOM_NUM == 0) {
            return tokenPreRevealURI;
        }

        uint256 newTokenId = uri(_tokenId);        
        string memory folder = (newTokenId % 100).toString(); 
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(tokenRevealURI, folder, slash, file));
    }

    /**
     * @dev Admin: Lock / Unlock transfers
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_LOCK
     */
    function setTransferLock(bool _locked) external onlyAllowed(TOKEN_CONTRACT_ACCESS_LOCK) {
        transferLocked = _locked;
        emit Locked(_locked);
    }


    function hasRole(bytes32 key, address user) public view returns (bool) {
        return myCommunityRegistry.hasRole(key, user);
    }

    /**
     * @dev Admin: Allow / Dissalow addresses
     */

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "Token: Unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) { 
        return( user == owner() || hasRole(role, user));
    }

    function tellEverything() external view returns (TokenInfo memory) {
        
        revealStruct[] memory _reveals = new revealStruct[](currentRevealCount);
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            _reveals[i - 1] = reveals[i];
        }

        uint256 contractManagers_length = contractManagers.length();
        address[] memory _managers = new address[](contractManagers_length);
        for(uint16 i = 0; i < contractManagers_length; i++) {
            _managers[i] = contractManagers.at(i);
        }

        uint256 contractControllers_length = contractControllers.length();
        address[] memory _controllers = new address[](contractControllers_length);
        for(uint16 i = 0; i < contractControllers_length; i++) {
            _controllers[i] = contractControllers.at(i);
        }

        return TokenInfo(
            name(),
            symbol(),
            projectID,
            maxSupply,
            mintedSupply,
            mintedReserve,
            reservedSupply,
            giveawaySupply,
            tokenPreRevealURI,
            tokenRevealURI,
            transferLocked,
            lastRevealRequested,
            totalSupply(),
            _reveals,
            owner(),
            _managers,
            _controllers
        );
    }

    function getTokenInfoForSale() external view returns (TokenInfoForSale memory) {
        return TokenInfoForSale(
            projectID,
            maxSupply,
            reservedSupply
        );
    }

    /**
     * @dev Admin: set setContractURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setContractURI(string memory _contractURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        contractURI = _contractURI;
        emit ContractURIset(_contractURI);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberRequester {
    function process(uint256 rand, uint256 requestId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bool private _initialized;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

    function setup(string memory name_, string memory symbol_) public {
        require(!_initialized, "ERC721: Contract already initialized");
        _name = name_;
        _symbol = symbol_;
        _initialized = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ISaleContract.sol";
import "../token/IToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SaleContract is AccessControlEnumerable, ISaleContract, Ownable, BlackHolePrevention {
    using Strings  for uint256;

    uint256             public  projectID;
    IToken              public  token;

    address payable []  _wallets;
    uint16[]            _shares;
    uint256             _maxMintPerTransaction;
    uint256             _maxApprovedSale;
    uint256             _maxMintPerAddress;
    uint256             _maxApprovedSalePerAddress;
    uint256             _maxSalePerAddress;
    address             _projectSigner;
    uint256             _approvedsaleStart;
    uint256             _approvedsaleEnd;
    uint256             _saleStart;
    uint256             _saleEnd;
    uint256             _fullPrice;
    uint256             _fullDustPrice;    
    bool                _ethSaleEnabled;    
    bool                _erc777SaleEnabled;    
    address             _erc777tokenAddress;

    uint256             _maxUserMintable;
    uint256             _userMinted;
    mapping(address => uint256) public _mintedByWallet;

    bool                _initialized;

    event ApprovedPayloadSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event ApprovedTokenPayloadSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    event ETHSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event TokenSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    uint8 constant TRANSFER_TYPE_ETH = 1;
    uint8 constant TRANSFER_TYPE_ERC20 = 2;
    uint8 constant TRANSFER_TYPE_ERC677 = 3;
    uint8 constant TRANSFER_TYPE_ERC777 = 4;

    uint8 constant BUY_TYPE_APSALE = 1;
    uint8 constant BUY_TYPE_SALE = 2;

    function setup(SaleConfiguration memory config) public onlyOwner {
        require(!_initialized, "Sale: Contract already initialized");
        require(config.projectID > 0, "Sale: Project id must be higher than 0");
        require(config.token != address(0), "Sale: Token address can not be address(0)");
 
        projectID = config.projectID;
        token = IToken(config.token);

        TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
        require(config.projectID == tinfo.projectID, "Sale: Project id must match");

        UpdateSaleConfiguration(config);
        UpdateWalletsAndShares(config.wallets, config.shares);

        // register with erc1820 registry so we can receive ERC777 tokens
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        _initialized = true;
    }

    function UpdateSaleConfiguration(SaleConfiguration memory config) public onlyAllowed {

        // How many tokens a transaction can mint
        _maxMintPerTransaction = config.maxMintPerTransaction;

        // Number of tokens to be sold in approvedsale 
        _maxApprovedSale = config.maxApprovedSale;

        // Limit approvedsale mints per address
        _maxApprovedSalePerAddress = config.maxApprovedSalePerAddress;

        // Limit sale mints per address ( must include _maxApprovedSalePerAddress value )
        _maxSalePerAddress = config.maxSalePerAddress;

        _approvedsaleStart  = config.approvedsaleStart;
        _approvedsaleEnd    = config.approvedsaleEnd;
        _saleStart          = config.saleStart;
        _saleEnd            = config.saleEnd;

        _fullPrice          = config.fullPrice;
        _fullDustPrice      = config.fullDustPrice;
        _ethSaleEnabled     = config.ethSaleEnabled;
        _erc777SaleEnabled  = config.erc777SaleEnabled; 
        _erc777tokenAddress = config.erc777tokenAddress; 

        // if provided use it.
        if(config.maxUserMintable > 0) {
            _maxUserMintable = config.maxUserMintable;
        } else {
            // Calculate how many tokens can be minted through the sale contract by normal users
            TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
            _maxUserMintable = tinfo.maxSupply - tinfo.reservedSupply;
        }

        // Signed data signer address
        _projectSigner = config.signer;
    }

    /**
     * @dev Admin: Update wallets and shares
     */
    function UpdateWalletsAndShares(
        address payable[] memory _newWallets,
        uint16[] memory _newShares
    ) public onlyAllowed {
        require(_newWallets.length == _newShares.length && _newWallets.length > 0, "Sale: Must have at least 1 output wallet");
        uint16 totalShares = 0;
        for (uint8 j = 0; j < _newShares.length; j++) {
            totalShares+= _newShares[j];
        }
        require(totalShares == 10000, "Sale: Shares total must be 10000");
        _shares = _newShares;
        _wallets = _newWallets;
    }

    /**
     * @dev Public Sale minting
     */
    function mint(uint256 _numberOfCards) external payable {
        _internalMint(_numberOfCards, msg.sender, msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Public Sale cross mint
     */
    function crossmint(uint256 _numberOfCards, address _receiver) external payable {
        _internalMint(_numberOfCards, _receiver, msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Public Sale minting
     */
    function _internalMint(uint256 _numberOfCards, address _receiver, uint256 _value, uint8 _section) internal {
        require(checkSaleIsActive(),                            "Sale: Sale is not open");
        require(_numberOfCards <= _maxMintPerTransaction,       "Sale: Over maximum number per transaction");

        uint256 checkPrice = 0;
        uint8 transferType = 0;
        if(_section == TRANSFER_TYPE_ETH) {
            require(_ethSaleEnabled,                            "Sale: ETH Sale is not enabled");
            checkPrice = _fullPrice;
            transferType = TRANSFER_TYPE_ETH;
        } else {
            require(_erc777SaleEnabled,                           "Sale: Token Sale is not enabled");
            checkPrice = _fullDustPrice;
            transferType = TRANSFER_TYPE_ERC20;
        }
        
        uint256 number_of_items = _value / checkPrice;
        require(number_of_items == _numberOfCards,              "Sale: Value sent does not match items requested");
        require(number_of_items * checkPrice == _value,         "Sale: Incorrect amount sent");

        uint256 _sold = _mintedByWallet[_receiver];
        require(_sold < _maxSalePerAddress,                     "Sale: You have already minted your allowance");
        require(_sold + number_of_items <= _maxSalePerAddress,  "Sale: That would put you over your approvedsale limit");
        _mintedByWallet[_receiver]+= number_of_items;

        _mintCards(number_of_items, _receiver);
        _split(_value, transferType);

        if(_section == TRANSFER_TYPE_ETH) {
            emit ETHSale(msg.sender, _receiver, number_of_items, _value);
        } else {
            emit TokenSale(msg.sender, _receiver, number_of_items, _value);
        }
    }

    /**
    * ERC677Receiver
    */
    function onTokenTransfer(address from, uint amount, bytes calldata userData) external {
        checkReceivedTokens(from, amount, userData);
    }

    /**
    * ERC777Receiver
    */
    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
    ) external {
        checkReceivedTokens(from, amount, userData);
    }

    function checkReceivedTokens(address from, uint amount, bytes memory userData) internal {

        require(_erc777tokenAddress == msg.sender, "Invalid token received");

        // Decode userData tokenPayload(uint256, SaleSignedPayload) manually 
        // because solidity doesn't support nested structs
        // 
        // will not work:  tokenPayload memory receivedTokenPayload  = abi.decode(userData, (tokenPayload));

        (uint8 buyType, uint256 numberOfCards, SaleSignedPayload memory payload) = abi.decode(userData, (uint8, uint256, SaleSignedPayload));
        
        if(buyType == BUY_TYPE_APSALE) {

            // Make sure that from is actually the intended receiver
            require(payload.receiver == from, "Payload Verify: Invalid receiver");

            verify_payload_rules(payload, amount, numberOfCards, TRANSFER_TYPE_ERC20);

            _mintedByWallet[payload.receiver]+= numberOfCards;

            // Cards will be minted into the specified receiver
            _mintCards(numberOfCards, payload.receiver);
            
            if(!payload.free) {
                _split(amount, TRANSFER_TYPE_ERC20);
            }

            emit ApprovedTokenPayloadSale(from, from, numberOfCards, amount);

        } else if(buyType == BUY_TYPE_SALE) {
            _internalMint(numberOfCards, from, amount, TRANSFER_TYPE_ERC20);
            emit TokenSale(from, from, numberOfCards, amount);
        }
    }

    /**
     * @dev Internal mint method
     */
    function _mintCards(uint256 numberOfCards, address recipient) internal {
        _userMinted+= numberOfCards;
        require(
            _userMinted <= _maxUserMintable,
            "Sale: Exceeds maximum number of user mintable cards"
        );
        token.mintIncrementalCards(numberOfCards, recipient);
    }

    function verify_payload_rules(SaleSignedPayload memory _payload, uint256 _value, uint256 _numberOfCards, uint8 _section) internal view {

        require(_numberOfCards <= _maxMintPerTransaction, "APSale: Over maximum number per transaction");
        require(_numberOfCards + _userMinted <= _maxApprovedSale, "APSale: ApprovedSale maximum reached");

        // Make sure it can only be called if approvedsale is active
        require(checkApprovedSaleIsActive(), "APSale: ApprovedSale is not active");

        // First make sure the received payload was signed by _projectSigner
        require(verify(_payload), "APSale: SignedPayload verification failed");

        // Make sure that payload.projectID matches
        require(_payload.projectID == projectID, "APSale Verify: Invalid projectID");

        // Make sure that payload.chainID matches
        require(_payload.chainID == block.chainid, "APSale Verify: Invalid chainID");

        // Make sure in date range
        require(_payload.valid_from < _payload.valid_to, "APSale: Invalid from/to range in payload");
        require(
            getBlockTimestamp() >= _payload.valid_from &&
            getBlockTimestamp() <= _payload.valid_to,
            "APSale: Contract time outside from/to range"
        );

        uint256 number_of_items = 0;
        if(_payload.free) {
            number_of_items = _numberOfCards;
            require(_value == 0, "APSale: value needs to be 0");
        } else {

            uint256 checkPrice = 0;
            if(_section == TRANSFER_TYPE_ETH) {
                checkPrice = _payload.eth_price;
            } else {
                // } else if(_section == TRANSFER_TYPE_ERC20) {
                checkPrice = _payload.dust_price;
            }
            
            number_of_items = _value / checkPrice;
            require(number_of_items == _numberOfCards, "APSale: Value sent does not match items requested");
            require(number_of_items * checkPrice == _value, "APSale: Incorrect amount sent");
        }

        uint256 _presold = _mintedByWallet[_payload.receiver];
        require(_presold < _payload.max_mint, "APSale: You have already minted your allowance");
        require(_presold + number_of_items <= _payload.max_mint, "APSale: That would put you over your approvedsale limit");

    }

    /**
     * @dev Mint tokens as specified in the signed payload
     */

    function mint_approved(SaleSignedPayload memory _payload, uint256 _numberOfCards) external payable {

        // Make sure that msg.sender is actually the intended receiver
        require(_payload.receiver == msg.sender, "APSale Verify: Invalid receiver");

        verify_payload_rules(_payload, msg.value, _numberOfCards, TRANSFER_TYPE_ETH);

        _mintedByWallet[msg.sender]+= _numberOfCards;

        // Cards will be minted into the specified receiver
        _mintCards(_numberOfCards, msg.sender);
        
        if(!_payload.free) {
            _split(msg.value, TRANSFER_TYPE_ETH);
        }

        emit ApprovedPayloadSale(msg.sender, msg.sender, _numberOfCards, msg.value);
    }

    /**
     * @dev Verify signed payload
     */
    function verify(SaleSignedPayload memory info) public view returns (bool) {
        require(info.signature.length == 65, "Sale Verify: Invalid signature length");

        bytes memory encodedPayload = abi.encode(
            info.projectID,
            info.chainID,
            info.free,
            info.max_mint,
            info.receiver,
            info.valid_from,
            info.valid_to,
            info.eth_price,
            info.dust_price
        );

        bytes32 hash = keccak256(encodedPayload);

        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = info.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return recovered == _projectSigner;
    }

    /**
     * @dev Is approvedsale active?
     */
    function checkApprovedSaleIsActive() public view returns (bool) {
        if ( (_approvedsaleStart <= getBlockTimestamp()) && (_approvedsaleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Is sale active?
     */
    function checkSaleIsActive() public view returns (bool) {
        if ((_saleStart <= getBlockTimestamp()) && (_saleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Royalties splitter
     */
    receive() external payable {
        _split(msg.value, TRANSFER_TYPE_ETH);
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 amount, uint8 transferType) internal {
        bool sent;
        uint256 _total;

        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 10000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            
            if(transferType == TRANSFER_TYPE_ETH) {
                (sent,) = _wallets[j].call{value: _amount}("");
                require(sent, "Sale: Splitter failed to send ether");
            }
            else if(transferType == TRANSFER_TYPE_ERC20) {
                // using transfer even for 677 / 777 as we do not
                // want to trigger receiver if it's a contract
                sent = IERC20(_erc777tokenAddress).transfer(_wallets[j], _amount);
                require(sent, "Sale: Splitter failed to send ERC20");
            }
        }
    }

    modifier onlyAllowed() { 
        require( msg.sender == owner() || token.isAllowed(token.TOKEN_CONTRACT_ACCESS_SALE(), msg.sender), "Sale: Unauthorised");
        _;
    }
 
    function tellEverything() external view returns (SaleInfo memory) {
        
        return SaleInfo(
            SaleConfiguration(
                projectID,
                address(token),
                _wallets,
                _shares,
                _maxMintPerTransaction,
                _maxApprovedSale,
                _maxApprovedSalePerAddress,
                _maxSalePerAddress,
                _approvedsaleStart,
                _approvedsaleEnd,
                _saleStart,
                _saleEnd,
                _fullPrice,
                _maxUserMintable,
                _projectSigner,
                _fullDustPrice,
                _ethSaleEnabled,
                _erc777SaleEnabled,
                _erc777tokenAddress
            ),
            _userMinted,
            checkApprovedSaleIsActive(),
            checkSaleIsActive()
        );
    }

    function getBlockTimestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRegistry {
    function setRegistryAddress(string memory fn, address value) external ;
    function setRegistryBool(string memory fn, bool value) external ;
    function setRegistryUINT(string memory key) external view returns (uint256) ;
    function setRegistryString(string memory fn, string memory value) external ;
    function setAdmin(address user,bool status ) external;
    function setAppAdmin(address app, address user, bool state) external;

    function getRegistryAddress(string memory key) external view returns (address) ;
    function getRegistryBool(string memory key) external view returns (bool);
    function getRegistryUINT(string memory key) external view returns (uint256) ;
    function getRegistryString(string memory key) external view returns (string memory) ;
    function isAdmin(address user) external view returns (bool) ;
    function isAppAdmin(address app, address user) external view returns (bool);
}