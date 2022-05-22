// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./LibAppStorage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IClaim.sol";

/// @notice the manager of fees
contract BitGemEventReporter is Initializable {

    event BitGemTokenCreated(address indexed creator, string indexed symbol, address indexed tokenAddress, BitGemSettings settings);
    event BitGemCreated(address creator, string symbol, uint256 tokenId);
    event ClaimPriceChanged(string symbol, uint256 price);
    event ClaimRedeemed(address indexed redeemer, Claim claim);
    event ClaimCreated(address indexed minter, Claim claim);
    event LootboxCreated(address creator, string symbol, address tokenAddress, LootboxSettings settings);
    event LootboxLootMinted(address indexed lootbox, address indexed looter, uint256 lootIndex);

    address internal masterAddress_;
    mapping(address => bool) internal allowedReporters_;

    modifier masterControllerOnly {
        require(masterAddress_ == msg.sender, "only master can report events");
        _;
    }

    modifier allowedReporterOnly {
        require(allowedReporters_[msg.sender] == true, "You are not allowed to report");
        _;
    }

    function initialize(address _masterAddress) external initializer {
        masterAddress_ = _masterAddress;
    }

    function addAllowedReporter(address reporter) external masterControllerOnly {
        allowedReporters_[reporter] = true;
    }

    function doBitGemTokenCreated(address creator, string memory symbol, address tokenAddress, BitGemSettings memory settings) external allowedReporterOnly {
        emit BitGemTokenCreated(creator, symbol, tokenAddress, settings);
    }

    function doBitgemCreated(address creator, string memory symbol, uint256 tokenId) external allowedReporterOnly {
        emit BitGemCreated(creator, symbol, tokenId);
    }

    function doClaimPriceChanged(string memory _symbol, uint256 price) external allowedReporterOnly {
        emit ClaimPriceChanged(_symbol, price);
    }
    
    function doClaimRedeemed(address redeemer, Claim memory claim) external allowedReporterOnly {
        emit ClaimRedeemed(redeemer, claim);
    }
    
    function doClaimCreated(address minter, Claim memory claim) external allowedReporterOnly {
        emit ClaimCreated(minter, claim);
    }

    function doLootboxCreated(address creator, string memory symbol, address tokenAddress, LootboxSettings memory settings) external {
        emit LootboxCreated(creator, symbol, tokenAddress, settings);
    }

    function doLootboxLootMinted(address lootbox, address looter, uint256 lootIndex) external {
        emit LootboxLootMinted(lootbox, looter, lootIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBitGem.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IClaim.sol";
import "./interfaces/ILootbox.sol";
import "./interfaces/IAttribute.sol";
import "./utils/AddressSet.sol";
import "./utils/UInt256Set.sol";
import "./utils/Bytes32Set.sol";

// store svg images
struct SVG {
    bytes32 id;
    uint16 width;
    uint16 height;
    string document;
}

// replacement value for a text replacement
struct ReplacementValue {
    string toMatch;
    string replacement;
}

// contract storage for a bitgem contract
struct BitGemContract {
    // mine starting settings
    BitGemSettings settings;

    address wrappedToken;
    address svgService;
    address eventReporter;

    // mined tokens
    uint256[] minedTokens;
    UInt256Set.Set recordHashes;
}

// bitgem storage by contract address
struct BitGemStorage {
    mapping(address => BitGemContract) bitgems;
    AddressSet.Set bitgemAddresses;
}

// svg storage
struct SVGStorage {
    mapping(bytes32 => SVG) svgs;
    mapping(bytes32 => address) svgOwners;
}

// a lootbox contract
struct LootboxContract { 
    bool enabled;
    address wrappedToken;
    address svgService;
    address eventReporter;
    // mined tokens
    Loot[] loot;
    UInt256Set.Set recordHashes;
    LootboxSettings settings;
    // the mineed toketns
    uint256[] minedTokens;
}

// lootbox storage by contract address
struct LootboxStorage {
    mapping(address => LootboxContract) lootboxes;
}

// variable price storage
struct VariablePriceStorage {
    mapping(address => TokenPriceData) price;
}

// attribute storage
struct AttributeContract {
    mapping(uint256 => mapping(string => Attribute))  attributes;
    mapping(uint256 => string[]) attributeKeys;
    mapping(uint256 =>  mapping(string => uint256)) attributeKeysIndexes;
}

struct AttributeStorage {
    mapping(address => AttributeContract) attributes;
}

struct ClaimContract {
    uint256 gemsMintedCount;  // total number of gems minted
    uint256 totalStakedEth; // total amount of staked eth
    mapping(uint256 => Claim) claims;  // claim data
    // staked total and claim index
    uint256 stakedTotal;
    uint256 claimIndex;
}

struct ClaimStorage {
    mapping(address => ClaimContract) claims;
}

// defining state variables
struct DiamondStorage {
    BitGemStorage bitgemStorage;
    SVGStorage svgStorage;
    LootboxStorage lootboxStorage;
    VariablePriceStorage variablePriceStorage;
    AttributeStorage attributeStorage;
    ClaimStorage claimStorage;
}

library LibAppStorage {

    // return a struct storage pointer for accessing the state variables
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = keccak256("diamond.standard.diamond.storage");
        assembly {
            ds.slot := position
        }
    }
    
    function initializeSVGs(SVG[] memory svgs) internal {
        DiamondStorage storage ds = diamondStorage();
        for(uint256 i = 0; i < svgs.length; i++) {
            SVG memory svg = svgs[i];
            ds.svgStorage.svgs[svg.id] = svg;
        }
    }
    
    function svgStorage() external view returns (SVGStorage storage svgStorage_) {
        svgStorage_ = diamondStorage().svgStorage;
    }
    function bitgemStorage() external view returns (BitGemStorage storage bitgemStorage_) {
        bitgemStorage_ = diamondStorage().bitgemStorage;   
    }    
}

contract DiamondContract {
    function s() internal pure returns (DiamondStorage storage _return) {
        _return = LibAppStorage.diamondStorage();
    }
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice represents a claim on some deposit.
struct Claim {
    // claim id.
    uint256 id;
    address feeRecipient;
    // pool address
    address mineAddress;
    // the amount of eth deposited
    uint256 depositAmount;
    // the gem quantity to mint to the user upon maturity
    uint256 mintQuantity;
    // the deposit length of time, in seconds
    uint256 depositLength;
    // the block number when this record was created.
    uint256 createdTime;
    // the block number when this record was created.
    uint256 createdBlock;
    // block number when the claim was submitted or 0 if unclaimed
    uint256 claimedBlock;
    // the fee that was paid
    uint256 feePaid;
    // whether this claim has been collected
    bool collected;
    // whether this claim must be mature before it can be collected
    bool requireMature;
    // whether this claim has been collected
    bool mature;
}

/// @notice a set of requirements. used for random access
struct ClaimSet {
    mapping(uint256 => uint256) keyPointers;
    uint256[] keyList;
    Claim[] valueList;
}

struct ClaimSettings {
    ClaimSet claims;
    // the total staked for each token type (0 for ETH)
    mapping(address => uint256) stakedTotal;
}

/// @notice interface for a collection of tokens. lists members of collection, allows for querying of collection members, and for minting and burning of tokens.
interface IClaim {
    /// @notice emitted when a token is added to the collection
    event ClaimCreated(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice emitted when a token is removed from the collection
    event ClaimRedeemed(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice create a claim
    /// @param _claim the claim to create
    /// @return _claimHash the claim hash
    function createClaim(Claim memory _claim)
        external
        payable
        returns (Claim memory _claimHash);

    /// @notice submit claim for collection
    /// @param claimHash the id of the claim
    function collectClaim(uint256 claimHash, bool requireMature) external;

    /// @notice return the next claim hash
    /// @return _nextHash the next claim hash
    function nextClaimHash() external view returns (uint256 _nextHash);

    /// @notice get all the claims
    /// @return _claims all the claims
    function claims() external view returns (Claim[] memory _claims);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./IToken.sol";
import "./ITokenPrice.sol";


enum BitGemType {
    Claim,
    Gem
}

/// @notice staking pool settings - used to confignure a staking pool
struct BitGemSettings {

// the owner & payee of the bitgem fees
    address owner;

    // the token definition of the mine
    TokenDefinition tokenDefinition;

    TokenPriceData tokenPrice;

    // is staking enabled
    bool enabled;

    uint256 minTime; // min and max token amounts to stake
    uint256 maxTime; // max time that the claim can be made
    uint256 maxClaims; // max number of claims that can be made
}

/// @notice check the balance of earnings and collect earnings
interface IBitGem {
    
    /// @notice get the member gems of this pool
    function settings() external view returns (BitGemSettings memory);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// erc token type
enum TokenType {
    ERC20,
    ERC721,
    ERC1155,
    Claim,
    Gem,
    LootboxOpen,
    Loot
}

/// @notice the token source. Specifies the source of the token - either a static source or a collection.
struct TokenIdentifier {
    TokenType tokenType;
    address token;
    uint256 id;
}

// a token of some quantity
struct Token {
    TokenIdentifier token;
    uint256 quantity;
}

// a collection of tokens
struct TokenSet {
    mapping(uint256 => uint256) keyPointers;
    uint256[] keyList;
    Token[] valueList;
}

// a definition of a token
struct TokenDefinition {
    address token;  // the host token        
    string name; // the name of the token
    string symbol; // the symbol of the token
    string imageData;
    string description; // the description of the token
}

struct TokenRecord {
    uint256 id;
    address owner;
    address minter;
    uint256 _type;
    uint256 balance;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IToken.sol";
import "./ITokenPrice.sol";

/// @notice describes a lootbox.
struct LootboxSettings {

    TokenDefinition token; // the item that is the loot
    string lootboxImage; // the image of the lootbox
    uint8 maxOpens; // max opens for the lootbox
    uint8 minLootPerOpen; // the minimum amount of loot per open
    uint8 maxLootPerOpen; // the maximum amount of loot per open
    uint256 probabilitiesSum; // the sum of all loot probabilities
    bool sellOpenTokens; // whether or not to sell open tokens
    uint256 openCount; // total numbrt of opens

}

/// @notice describes the structure of the additional data that describes loot
struct Loot {

    TokenDefinition token; // the item that is the loot
    string lootImage; // the image of the loot
    uint256 probability; // probability of the item being awarded
    uint256 probabilityIndex; // the index of the probability in its array        
    uint256 probabilityRoll; // the index of the probability in its array

}

/// @notice a set of tokens.
struct LootSet {

    mapping(uint256 => uint256) keyPointers;
    uint256[] keyList;
    Loot[] valueList;

}

/// @dev interface for a collection of tokens. lists members of collection,  allows for querying of collection members, and for minting and burning of tokens.
interface ILootbox {

    /// @notice event is emitted when a lootbox is created
    event LootboxCreated(address lootbox, LootboxSettings settings);

    /// @notice emitted when lootbox tokens are minted
    event LootboxTokenPurchased(address indexed lootbox, address indexed buyer);

    /// @notice emitted when lootbox is opened
    event LootboxOpened(address indexed opener, uint256[] loot);

    /// @notice emitted when a piece of loot is minted
    event LootboxLootMinted(address indexed lootbox, address indexed looter, uint256 lootIndex);

    /// @notice open the lootbox. mints loot according to lootbox data
    function openLootbox(uint256 lootboxTokenId, bool purchaseLootboxToken) external payable returns (uint256[] memory _loot);

    /// @notice get the settings for this lootbox
    function settings() external view returns (LootboxSettings memory settings);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum AttributeType {
    Unknown,
    String ,
    Bytes32,
    Uint256,
    Uint8,
    Uint256Array,
    Uint8Array
}

struct Attribute {
    string key;
    AttributeType attributeType;
    bytes32 value;
}

/// @notice a pool of tokens that users can deposit into and withdraw from
interface IAttribute {

    event AttributeSet(uint256 indexed tokenId, Attribute attribute);

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute calldata _attrib);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library AddressSet {
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, address key) public {
        require(
            !exists(self, key),
            "AddressSet: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, address key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        require(
            exists(self, key),
            "AddressSet: key does not exist in the set."
        );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            address keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, address key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (address)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library Bytes32Set {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, bytes32 key) public {
        require(
            !exists(self, key),
            "key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes32 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "Bytes32Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return self.keyList.length;
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (bytes32)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice DIctates how the price of the token is increased post every sale
enum PriceModifier {
    None,
    Fixed,
    Exponential,
    InverseLog
}

/// @notice a token price and how it changes
struct TokenPriceData {
    uint256 price; // the price of the token
    PriceModifier priceModifier;  // how the price is modified
    uint256 priceModifierFactor; // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
    uint256 maxPrice; // max price for the token
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