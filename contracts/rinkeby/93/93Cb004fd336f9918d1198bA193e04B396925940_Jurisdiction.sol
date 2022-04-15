//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


// import "hardhat/console.sol";

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";  //Track Token Supply & Check 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IJurisdiction.sol";
import "./interfaces/IRules.sol";
import "./interfaces/ICase.sol";
// import "./libraries/DataTypes.sol";
// import "./abstract/Opinions.sol";
import "./abstract/ERC1155Roles.sol";
import "./abstract/Rules.sol";
import "./abstract/CommonYJ.sol";


/**
 * @title Jurisdiction Contract
 * @dev Retains Group Members in Roles
 * V1: Role NFTs
 * - Mints Member NFTs
 * - One for each
 * - All members are the same
 * - Rules
 * - Creates new Cases
 * - Contract URI
 * - [TODO] Validation: Make Sure Account has an Avatar NFT
 * - [TODO] Token URIs for Roles
 * - [TODO] Unique Rule IDs (GUID)
 * V2:  
 * - [TODO] NFT Trackers - Assign Avatars instead of Accounts & Track the owner of the Avatar NFT
 */
contract Jurisdiction is IJurisdiction, Rules, CommonYJ, ERC1155Roles {
    //--- Storage
    string public constant override symbol = "YJ_Jurisdiction";
    using Strings for uint256;

    using Counters for Counters.Counter;
    // Counters.Counter internal _tokenIds; //Track Last Token ID
    Counters.Counter internal _caseIds;  //Track Last Case ID
    
    // Contract name
    string public name;
    // Contract symbol
    // string public symbol;
    //Contract URI
    string internal _contract_uri;

    // mapping(string => uint256) internal _roles;     //NFTs as Roles
    mapping(uint256 => address) internal _cases;      // Mapping for Case Contracts

    // mapping(uint256 => string) internal _rulesURI;      // Mapping Metadata URIs for Individual Role 
    // mapping(uint256 => string) internal _uri;

    //Post Input Struct
    struct PostInput {
        string entRole;
        // string postRole;
        string uri;
    }

    //--- Functions

    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJurisdiction).interfaceId || interfaceId == type(IRules).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor(address hub, address actionRepo) CommonYJ(hub) ERC1155("") Rules(actionRepo){
        name = "Anti-Scam Jurisdiction";
        // symbol = "YJ_J1";
        //Init Default Jurisdiction Roles
        _roleCreate("admin");
        _roleCreate("member");
        _roleCreate("judge");
    }

    //** Case Functions

    /// Make a new Case & File it
    function caseMakeOpen(
        string calldata name_, 
        DataTypes.RuleRef[] calldata addRules, 
        DataTypes.InputRole[] calldata assignRoles, 
        PostInput[] calldata posts
    ) public returns (uint256, address) {
        //Make Case
        (uint256 caseId, address caseContract) = caseMake(name_, addRules, assignRoles, posts);
        //File Case
        ICase(caseContract).stageFile();
        //Return
        return (caseId, caseContract);
    }

    /// Make a new Case
    function caseMake(
        string calldata name_, 
        DataTypes.RuleRef[] calldata addRules, 
        DataTypes.InputRole[] calldata assignRoles, 
        PostInput[] calldata posts
    ) public returns (uint256, address) {
        //TODO: Validate Caller Permissions (Member of Jurisdiction)
        // roleHas(_msgSender(), "admin")  
        // roleHas(_msgSender(), "member") 

        //Assign Case ID
        _caseIds.increment(); //Start with 1
        uint256 caseId = _caseIds.current();
        //Create new Case
        address caseContract = _HUB.caseMake(name_, addRules, assignRoles);
        //Remember Address
        _cases[caseId] = caseContract;
        //New Case Created Event
        emit CaseCreated(caseId, caseContract);
        //Posts
        for (uint256 i = 0; i < posts.length; ++i) {
            // ICase(caseContract).post(posts[i].entRole, posts[i].postRole, posts[i].uri);
            ICase(caseContract).post(posts[i].entRole, posts[i].uri);
        }
        return (caseId, caseContract);
    }
    
    /// Get Case Address by Case ID
    function getCaseById(uint256 caseId) public view returns (address) {
        return _cases[caseId];
    }
    
    //** Role Management

    /// Join a role in current jurisdiction
    function join() external override {
        _GUIDAssign(_msgSender(), _stringToBytes32("member"));
    }

    /// Leave Role in current jurisdiction
    function leave() external override {
        _GUIDRemove(_msgSender(), _stringToBytes32("member"));
    }

    /// Assign Someone Else to a Role
    function roleAssign(address account, string memory role) external override roleExists(role) {
        //Validate Permissions
        require(
            _msgSender() == account         //Self
            || owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        //Add
        _roleAssign(account, role);
    }

    /// Remove Someone Else from a Role
    function roleRemove(address account, string memory role) external override roleExists(role) {
        //Validate Permissions
        require(
            _msgSender() == account         //Self
            || owner() == _msgSender()      //Owner
            || balanceOf(_msgSender(), _roleToId("admin")) > 0     //Admin Token
            , "INVALID_PERMISSIONS");
        //Remove
        _roleRemove(account, role);
    }

    /**
    * @dev Hook that is called before any token transfer. This includes minting and burning, as well as batched variants.
    *  - Max of Single Token for each account
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                //Validate - Max of 1 Per Account
                uint256 id = ids[i];
                require(balanceOf(to, id) == 0, "ALREADY_ASSIGNED_TO_ROLE");
                uint256 amount = amounts[i];
                require(amount == 1, "ONE_TOKEN_MAX");
            }
        }
    }

    //** Rule Management

    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation) public override returns (uint256) {
        //Validate Caller's Permissions
        require(roleHas(_msgSender(), "admin"), "Admin Only");
        //Add Rule
        uint256 id = _ruleAdd(rule);
        //Set Confirmations
        _confirmationSet(id, confirmation);
        return id;
    }
    
    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule) external override {
        //Validate Caller's Permissions
        require(roleHas(_msgSender(), "admin"), "Admin Only");
        //Update Rule
        _ruleUpdate(id, rule);
    }

    /// Get Token URI
    // function tokenURI(uint256 token_id) public view returns (string memory) {
    // function uri(uint256 token_id) public view returns (string memory) {
    //     require(exists(token_id), "NONEXISTENT_TOKEN");
    //     return _tokenURIs[token_id];
    // }
    
    /// Set Action's Metadata URI
    // function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    //     require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    //     _tokenURIs[tokenId] = _tokenURI;
    // }

    // function _actionSetURI(bytes32 guid, string memory uri) internal {
    //     _uri[_GUIDToId(guid)] = uri;
    //     emit ActionURI(guid, uri);
    // }

   /**
     * @dev Contract URI
     *  https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view override returns (string memory) {
        return _contract_uri;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IJurisdiction {
    
    //--- Functions

    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Contract URI
    function contractURI() external view returns (string memory);

    /// Join jurisdiction as member
    function join() external;

    /// Leave member role in current jurisdiction
    function leave() external;

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;
    
    /// Create a new Role
    // function roleCreate(address account, string calldata role) external;

    /// Make a new Case
    // function caseMake(
    //     string calldata name_, 
    //     DataTypes.RuleRef[] calldata addRules, 
    //     DataTypes.InputRole[] calldata assignRoles, 
    //     PostInput[] calldata posts
    // ) external returns (uint256, address);
    
    //-- Rule Func.

    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation) external returns (uint256);

    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule) external;
    

    //--- Events

    /// New Case Created
    event CaseCreated(uint256 indexed id, address contractAddress);    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IRules {
    
    /// Expose Action Repo Address
    function actionRepo() external view returns (address);

    ///Get Rule
    function ruleGet(uint256 id) external view returns (DataTypes.Rule memory);

    /// Update Confirmation Method for Action
    function confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) external;

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) external view returns (DataTypes.Confirmation memory);

    //--- Events

    /// Action Repository (HISTORY) Set
    event ActionRepoSet(address actionRepo);

    /// Rule Added or Changed
    event Rule(uint256 indexed id, bytes32 about, string affected, string uri, bool negation);

    /// Rule Removed
    event RuleRemoved(uint256 indexed id);

    /// Rule's Effects
    event RuleEffects(uint256 indexed id, int8 environmental, int8 personal, int8 social, int8 professional);

    /// Action Confirmation Change
    event Confirmation(uint256 indexed id, string ruling, bool evidence, uint witness);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface ICase {
    
    //-- Functions

    /// Initialize
    // function initialize(string memory name_, string memory symbol_, address hub) external ;
    // function initialize(string memory name_, string memory symbol_, address hub, DataTypes.RuleRef[] memory addRules) external ;
    function initialize(string memory name_, string memory symbol_, address hub, DataTypes.RuleRef[] memory addRules, DataTypes.InputRole[] memory assignRoles) external ;

    /// Contract URI
    function contractURI() external view returns (string memory);

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    // RoleRequest()

    // RoleOffered()

    // RoleAccepted()

    // RoleAssigned()

    /// File the Case (Validate & Open Discussion)  --> Open
    function stageFile() external;

    /// Case Wait For Verdict  --> Pending
    function stageWaitForVerdict() external;

    /// Case Stage: Place Verdict  --> Closed
    function stageVerdict(string calldata uri) external;

    /// Add Post 
    // function post(string calldata entRole, string calldata postRole, string calldata uri) external;
    function post(string calldata entRole, string calldata uri) external;

    //--- Events

    /// Case Stage Change
    event Stage(DataTypes.CaseStage stage);

    /// Post Verdict
    event Verdict(string uri, address account);

    /// General Post / Evidence, etc'
    // event Post(address indexed account, string entRole, string postRole, string uri);        //postRole Moved to uri
    event Post(address indexed account, string entRole, string uri);

    /// Rule Reference Added
    event RuleAdded(address jurisdiction, uint256 ruleId);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IERC1155Roles.sol";
import "./ERC1155GUID.sol";

/**
 * @title Sub-Groups with Role NFTs
 * @dev ERC1155 using GUID as Role
 * To Extend Cases & Jutisdictions
 * - Hold Roles
 * - Assign Roles
 * ---- 
 * - [TODO] request + approve 
 * - [TODO] offer + accept
 * 
 * References: 
 *  Fractal DAO Access Control  https://github.com/fractal-framework/fractal-contracts/blob/93bc0e845a382673f3714e7df858e846d0f10b37/contracts/AccessControl.sol
 *  OZ Access Control  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 */
abstract contract ERC1155Roles is IERC1155Roles, ERC1155GUID {
    
    //--- Storage

    //--- Modifiers
    modifier roleExists(string memory role) {
        require(roleExist(role), "INEXISTENT_ROLE");
        _;
    }
    
    /// Validate that account hold one of the role in Array
    modifier onlyRole(string[] calldata roles) {
        bool hasRole;
        for (uint256 i = 0; i < roles.length; ++i) {
            if(roleHas(_msgSender(), roles[i])) hasRole = true;
        }
        require(hasRole, "ROLE:INVALID_PERMISSION");
        _;
    }

    //--- Functions

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Roles).interfaceId || super.supportsInterface(interfaceId);
    }

    //** Role Functions

    /// Check if Role Exists
    function roleExist(string memory role) public view override returns (bool) {
        return _GUIDExists(_stringToBytes32(role));
    }

    /// Check if account is assigned to role
    function roleHas(address account, string memory role) public view override returns (bool) {
        return GUIDHas(account, _stringToBytes32(role));
    }

    /// Assign Someone Else to a Role
    function _roleAssign(address account, string memory role) internal roleExists(role) {
        _GUIDAssign(account, _stringToBytes32(role));
        //TODO: Role Assigned Event?
    }

    /// Remove Someone Else from a Role
    function _roleRemove(address account, string memory role) internal roleExists(role) {
        _GUIDRemove(account, _stringToBytes32(role));
        //TODO: Role Removed Event?
    }

    /// Translate Role to Token ID
    function _roleToId(string memory role) internal view roleExists(role) returns(uint256) {
        return _GUIDToId(_stringToBytes32(role));
    }

    /// Translate string Roles to GUID hashes
    function _stringToBytes32(string memory str) internal pure returns (bytes32){
        require(bytes(str).length <= 32, "String is too long. Max 32 chars");
        return keccak256(abi.encode(str));
    }

    /// Create a new Role
    function _roleCreate(string memory role) internal returns (uint256) {
        return _GUIDMake(_stringToBytes32(role));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;    //https://docs.soliditylang.org/en/v0.5.2/abi-spec.html?highlight=abiencoderv2

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IRules.sol";
import "../interfaces/IActionRepo.sol";
import "../libraries/DataTypes.sol";


/**
 * @title Rules Contract 
 * @dev To Extend or Be Used by Jurisdictions
 * - Hold, Update, Delete & Serve Rules
 * - Single immutable Action Repo
 */
// abstract contract Rules is IRules, Opinions {
contract Rules is IRules {
    
    //--- Storage

    using Counters for Counters.Counter;
    Counters.Counter private _ruleIds;
    //Action Repository Contract (HISTORY)
    IActionRepo internal _actionRepo;   
    //Rule Data
    mapping(uint256 => DataTypes.Rule) internal _rules;
    //Additional Rule Data
    mapping(uint256 => DataTypes.Confirmation) internal _ruleConfirmation;
    // mapping(uint256 => string) internal _uri;

    //--- Functions

    constructor(address actionRepo_) {
        _setActionsContract(actionRepo_);
    }

    /// Get Rule
    function ruleGet(uint256 id) public view override returns (DataTypes.Rule memory) {
        return _rules[id];
    }

    /// Set Actions Contract
    function _setActionsContract(address actionRepo_) internal {
        require(address(_actionRepo) == address(0), "HISTORY Contract Already Set");
        //String Match - Validate Contract's Designation        //TODO: Maybe Look into Checking the Supported Interface
        require(keccak256(abi.encodePacked(IActionRepo(actionRepo_).symbol())) == keccak256(abi.encodePacked("YJ_HISTORY")), "Expecting HISTORY Contract");
        //Set
        _actionRepo = IActionRepo(actionRepo_);
        //Event
        emit ActionRepoSet(actionRepo_);
    }

    /// Expose Action Repo Address
    function actionRepo() external view override returns (address) {
        return address(_actionRepo);
    }

    /// Add Rule
    function _ruleAdd(DataTypes.Rule memory rule) internal returns (uint256) {
        //Add New Rule
        _ruleIds.increment();
        uint256 id = _ruleIds.current();
        //Set
        _rules[id] = rule;
        //Event
        emit Rule(id, rule.about, rule.affected, rule.uri, rule.negation);
        emit RuleEffects(id, rule.effects.environmental, rule.effects.personal, rule.effects.social, rule.effects.professional);
        return id;
    }

    /// Remove Rule
    function _ruleRemove(uint256 id) internal {
        delete _rules[id];
        //Event
        emit RuleRemoved(id);
    }

    /// Update Rule
    function _ruleUpdate(uint256 id, DataTypes.Rule memory rule) internal {
        //Set
        _rules[id] = rule;
        //Event
        emit Rule(id, rule.about, rule.affected, rule.uri, rule.negation);
        emit RuleEffects(id, rule.effects.environmental, rule.effects.personal, rule.effects.social, rule.effects.professional);
    }

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) public view override returns (DataTypes.Confirmation memory){
        return _ruleConfirmation[id];
    }

    /// Update Confirmation Method for Action
    function confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) external override {
        //TODO: Validate Caller's Permissions
        _confirmationSet(id, confirmation);
    }
    
    /// Set Action's Confirmation Object
    function _confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) internal {
        _ruleConfirmation[id] = confirmation;
        emit Confirmation(id, confirmation.ruling, confirmation.evidence, confirmation.witness);
    }


}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICommonYJ.sol";
import "../interfaces/IHub.sol";
import "../libraries/DataTypes.sol";

/**
 * Common Protocol Functions
 */
abstract contract CommonYJ is ICommonYJ, Ownable {
    
    //--- Storage

    // address internal _HUB;    //Hub Contract
    IHub internal _HUB;    //Hub Contract
    

    //--- Functions

    constructor(address hub){
        //Set Protocol's Config Address
        _setHub(hub);
    }

    /// Inherit owner from Protocol's config
    function owner() public view override (ICommonYJ, Ownable) returns (address) {
        return _HUB.owner();
    }

    /// Set Hub Contract
    function _setHub(address config) internal {
        //Validate Contract's Designation
        require(keccak256(abi.encodePacked(IHub(config).role())) == keccak256(abi.encodePacked("YJHub")), "Invalid Hub Contract");
        //Set
        _HUB = IHub(config);
    }

    /// Set Hub Contract
    function _getHub() internal view returns(address) {
        return address(_HUB);
    }
    
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @title DataTypes
 * @notice A standard library of generally used data types
 */
library DataTypes {

    //---

    /// NFT Identifiers
    struct Entity {
        address account;
        uint256 id;
        uint256 chain;
    }
    /// Rating Domains
    enum Domain {
        Environment,
        Personal,
        Community,
        Professional
    }
    /// Rating Categories
    enum Rating {
        Negative,
        Positive
    }
    

    //--- Cases
    //Case Lifecycle
    // - Draft
    // - Filed / Open -- Confirmation/Discussion (Evidence, Witnesses, etc’)
    //X - Waiting for additional evidence
    // - Pending - Awaiting verdict
    // - Decision/Verdict (Judge, Jury, vote, etc’)
    // - Action / Remedy - Reward / Punishment / Compensation
    // - [Appeal
    // - [Enforcement]
    // - Closed
    // - Cancelled (Denied)
    enum CaseStage {
        Draft,
        Open,
        Verdict,
        Action,
        Appeal,
        Enforcment,
        Closed,
        Cancelled
    }

    //--- Actions

    // Semantic Action Entity
    struct Action {
        // id: 1,
        // uint256 id;  //Outside

        // name: "Breach of contract",  //Title
        string name;
     
        // text: "The founder of the project must comply with the terms of the contract with investors",  //Text Description
        string text;

        // entities:{
        //     //Describe an event
        //     affected: "investor",  //Plaintiff Role (Filing the case)
        //     subject: "founder",     //Accused Role
        //     action: "breach",
        //     object: "contract",
        // },
        SVO entities;
        
        // confirmation:{ //Confirmation Methods [WIP]
        //     //judge: true,
        //     ruling: "judge"|"jury"|"democracy",  //Decision Maker
        //     evidence: true, //Require Evidence
        //     witness: 1,  //Minimal number of witnesses
        // },
        Confirmation confirmation;

        // requirements:{
        //     witness: "Blockchain Expert"
        // }
        // string requirements;
        string uri; //Additional Info
    }

    struct SVO {    //Action's Core (System Role Mapping) (Immutable)
        //     subject: "founder",     //Accused Role
        string subject;
        //     action: "breach",
        string verb;
        //     object: "contract",
        string object;
        string tool; //[TBD]
        //     //Describe an event
        //     affected: "investors",  //Plaintiff Role (Filing the case)
        // string affected;    //[PONDER] Doest this really belong here? Is that part of the unique combination, or should this be an array, or an eadge?      //MOVED TO Rule
    }
    /* DEPRECATED
    struct RoleData {
        // name: "Breach of contract",  //Title
        // string name;   //On URI
        // text: "The founder of the project must comply with the terms of the contract with investors",  //Text Description
        // string text;   //On URI
        string uri; //Misc Additional Info
        Confirmation confirmation;
    }
    */

    //--- Rules
    
    // Rule Object
    struct Rule {
        // string name;
        // string uri;
        //eventId: 1, 

        // uint256 about;    //About What (Token URI +? Contract Address)
        bytes32 about;    //About What (Action's GUID)      //TODO: Maybe Call This 'action'? 

        // affected: "investors",  //Plaintiff Role (Filing the case)
        string affected;    //Moved Here

        bool negation;  //0 - Commision  1 - Omission

        //text: "The founder of the project violated the contract, but this did not lead to the loss or freezing of funds for investors.", //Description For Humans
        // string text;
        // condition: "Investor funds were not frozen nor lost.",
        // string condition;  
        string uri;     //Test & Conditions

        // effect: { //Reputation Change
        //     profiessional:-2,
        //     social: -4
        // }
        // Effect[3] effects;
        Effects effects;
        // consequence:[{ func:'repAdd', param:5 }],    //TBD?
    }
    
    // Effect Object (Changes to Reputation By Type)
    struct Effects {
        int8 environmental;
        int8 personal;
        int8 social;
        int8 professional;
        // Effect environment;
        // Effect personal;
        // Effect social;
        // Effect professional;
    }
    /* Maybe?
    // Effect Structure
    struct Effect {
        // value: 5
        int8 value;
        // Direction: -
        bool direction;
        // Confidence/Strictness: [?]
    }
    */    
    //Rule Confirmation Method
    struct Confirmation {
        //     ruling: "judge"|"jury"|"democracy",  //Decision Maker
        string ruling;
        //     evidence: true, //Require Evidence
        bool evidence;
        //     witness: 1,  //Minimal number of witnesses
        uint witness;
    }

    //--- Case Data

    //Rule Reference
    struct RuleRef {
        address jurisdiction;
        uint256 ruleId;
        // string affected;        //Affected Role. E.g. "investor"     //In Rule
        // Entity affected;
    }
    
    //-- Inputs
    
    //Rule Input Struct (Same as RuleRef)
    // struct InputRule {
    //     address jurisdiction;
    //     uint256 ruleId;
    //     string affected;
    // }

    //Role Input Struct
    struct InputRole {
        address account;
        string role;
    }
    
    //Role Name Input Struct
    struct RoleMappingInput {
        string role;
        string name;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.4;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IERC1155Roles {

    //--- Functions
    /// Check if Role Exists
    function roleExist(string memory role) external view returns (bool);

    /// Check if account is assigned to role
    function roleHas(address account, string calldata role) external view returns (bool);
    
    //--- Events

    /// New Role Created
    event RoleCreated(uint256 indexed id, string role);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";  //Track Token Supply & Check 
// import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IERC1155GUID.sol";

/**
 * @title 2D ERC1155 -- Members + Groups (Meaningful Global Unique Identifiers for each Token ID)
 * @dev use GUID as a meaningful index
 */
abstract contract ERC1155GUID is IERC1155GUID, ERC1155 {

    //--- Storage

    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds; //Track Last Token ID
    mapping(uint256 => uint256) private _uniqueMembers; //Index Unique Members by Role
    mapping(bytes32 => uint256) internal _GUID;     //NFTs as GUID

    //--- Modifiers

    /// Check if GUID Exists
    modifier GUIDExists(bytes32 guid) {
        require(_GUIDExists(guid), "INEXISTENT_GUID");
        _;
    }

    //--- Functions

    /// Unique Members w/Token
    function uniqueMembers(uint256 id) public view override returns (uint256) {
        return _uniqueMembers[id];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155GUID).interfaceId || super.supportsInterface(interfaceId);
    }

    /// Check if account is assigned to GUID
    function GUIDHas(address account, bytes32 guid) public view override returns (bool) {
        return (balanceOf(account, _GUIDToId(guid)) > 0);
    }

    /// Create New GUID
    function _GUIDMake(bytes32 guid) internal returns (uint256) {
        require(_GUIDExists(guid) == false, string(abi.encodePacked(guid, " GUID already exists")));
        //Assign Token ID
        _tokenIds.increment(); //Start with 1
        uint256 tokenId = _tokenIds.current();
        //Map GUID to Token ID
        _GUID[guid] = tokenId;
        //Event
        emit GUIDCreated(tokenId, guid);
        //Return Token ID
        return tokenId;
    }

    /// Check if GUID Exists
    function _GUIDExists(bytes32 guid) internal view returns (bool) {
        return (_GUID[guid] != 0);
    }
    
    /// Assign Token
    function _GUIDAssign(address account, bytes32 guid) internal GUIDExists(guid) {
        uint256 tokenId = _GUIDToId(guid);  //_GUID[guid];
        //Mint GUID Token       //TODO: Support Various Amounts
        _mint(account, tokenId, 1, "");
    }
    
    /// Unassign Token
    function _GUIDRemove(address account, bytes32 guid) internal GUIDExists(guid) {
        uint256 tokenId = _GUID[guid];
        //Validate
        require(balanceOf(account, tokenId) > 0, "NOT_ASSIGNED");
        //Burn GUID Token
        _burn(account, tokenId, 1);
    }

    /// Translate GUID to Token ID
    function _GUIDToId(bytes32 guid) internal view GUIDExists(guid) returns(uint256) {
        return _GUID[guid];
    }

    /// Track Unique Tokens
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) { //Mint
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                if(balanceOf(to, id) == 0){
                    unchecked {
                        ++_uniqueMembers[id];
                    }
                }
            }
        }
        if (to == address(0)) { //Burn
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                if(balanceOf(to, id) == amounts[i]){   //Burn All
                    --_uniqueMembers[id];
                }
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC1155GUID {

    //--- Functions 

    /// Unique Members w/Token
    function uniqueMembers(uint256 id) external view returns (uint256);

    /// Check if account is assigned to role
    function GUIDHas(address account, bytes32 guid) external view returns (bool);
    
    //--- Events

    /// New GUID Created
    event GUIDCreated(uint256 indexed id, bytes32 guid);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IActionRepo {
    
    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Get Owner
    // function owner() external view returns (address);

    /// Generate a Unique Hash for Event
    function actionHash(DataTypes.SVO memory svo) external pure returns (bytes32);

    /// Register New Action
    // function actionAdd(DataTypes.SVO memory svo) external returns (bytes32);
    function actionAdd(DataTypes.SVO memory svo, string memory uri) external returns (bytes32);

    /// Register New Actions in a Batch
    function actionAddBatch(DataTypes.SVO[] memory svos, string[] memory uris) external returns (bytes32[] memory);
        
    /// Update URI for Action
    function actionSetURI(bytes32 guid, string memory uri) external;

    /// Get Action by GUID
    function actionGet(bytes32 guid) external view returns (DataTypes.SVO memory);

    /// Get Action's URI
    function actionGetURI(bytes32 guid) external view returns (string memory);
    
    //--- Events
    
    /// Action Added
    event ActionAdded(uint256 indexed id, bytes32 indexed guid, string subject, string verb, string object, string tool);

    /// Action Removed (No such thing)
    // event ActionRemoved(bytes32 indexed id);

    /// Action URI Updated
    event ActionURI(bytes32 indexed guid, string uri);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Common Protocol Functions
 */
interface ICommonYJ {
    
    /// Inherit owner from Protocol's config
    function owner() external view returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IHub {
    
    //--- Functions

    /// Arbitrary contract designation signature
    function role() external view returns (string memory);
    
    /// Get Owner
    function owner() external view returns (address);
    
    /// Make a new Case
    // function caseMake(string calldata name_) external returns (address);
    function caseMake(string calldata name_, DataTypes.RuleRef[] memory addRules, DataTypes.InputRole[] memory assignRoles) external returns (address);

    //--- Events

    /// Case Implementation Contract Updated
    event UpdatedCaseImplementation(address implementation);

    /// Jurisdiction Implementation Contract Updated
    event UpdatedJurisdictionImplementation(address implementation);

}