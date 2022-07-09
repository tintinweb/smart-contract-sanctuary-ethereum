//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../libraries/DataTypes.sol";
import "../interfaces/IERC1155RolesTracker.sol";
import "../interfaces/IRules.sol";
import "../interfaces/IActionRepo.sol";
import "../interfaces/ICommonYJ.sol";
import "../interfaces/IGameUp.sol";
import "../public/interfaces/IOpenRepo.sol";

/**
 * @title Rule Repository
 * @dev Contract as a Service -- Retains Rules for Other Contracts
 * To be used by a contract that implements IERC1155RolesTracker
 * Version 1.0
 * - Sender expected to be a protocol entity
 * - Sender expected to support getHub() & repoAddr()
 */
contract RuleRepo is IRules {

    //--- Storage

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _ruleIds;

    //Rule Data
    mapping(address => mapping(uint256 => DataTypes.Rule)) internal _rules;
    mapping(address => mapping(uint256 => DataTypes.Confirmation)) internal _ruleConfirmation;  //Rule Confirmations
    mapping(address => mapping(uint256 => DataTypes.Effect[])) internal _effects;  //Rule Efects (Consequences))   //effects[id][] => {direction:true, value:5, name:'personal'}  // Generic, Iterable & Extendable/Flexible
    // mapping(address => mapping(uint256 => string) internal _uri;

    //--- Functions

    //** Protocol Functions
    
    //Use Self (Main Game)
    function game() internal view returns (IGame) {
        return IGame(address(msg.sender));
    }

    /// Hub Address
    function hubAddress() internal view returns (address) {
        return ICommonYJ(msg.sender).getHub();
    }

    //Get Data Repo Address (From Hub)
    function repoAddr() public view returns (address) {
        return ICommonYJ(msg.sender).repoAddr();
    }

    //Get Assoc Repo
    function repo() internal view returns (IOpenRepo) {
        return IOpenRepo(repoAddr());
    }

    //** Rule Management

    //-- Getters

    /// Get Rule
    function ruleGet(uint256 id) public view override returns (DataTypes.Rule memory) {
        return _rules[msg.sender][id];
    }

    /// Get Rule's Effects
    function effectsGet(uint256 id) public view override returns (DataTypes.Effect[] memory){
        return _effects[msg.sender][id];
    }

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) public view override returns (DataTypes.Confirmation memory){
        return _ruleConfirmation[msg.sender][id];
    }

    //-- Setters

    /// Create New Rule
    function ruleAdd(
        DataTypes.Rule memory rule, 
        DataTypes.Confirmation memory confirmation, 
        DataTypes.Effect[] memory effects
    ) public override returns (uint256) {
        //Validate Caller's Permissions
        require(IERC1155RolesTracker(msg.sender).roleHas(tx.origin, "admin"), "Admin Only");
        
        //Validate rule.about -- actionGUID Exists
        address actionRepo = repo().addressGetOf(hubAddress(), "history");

        IActionRepo(actionRepo).actionGet(rule.about);  //Revetrs if does not exist
        //Add Rule
        uint256 id = _ruleAdd(rule, effects);

        //Set Confirmations
        _confirmationSet(id, confirmation);
        return id;
    }

    /// Update Rule
    function ruleUpdate(
        uint256 id, 
        DataTypes.Rule memory rule, 
        DataTypes.Effect[] memory effects
    ) external override {
        //Validate Caller's Permissions
        require(IERC1155RolesTracker(msg.sender).roleHas(tx.origin, "admin"), "Admin Only");
        //Update Rule
        _ruleUpdate(id, rule, effects);
    }

    /// Set Disable Status for Rule
    function ruleDisable(uint256 id, bool disabled) external override {
         //Validate Caller's Permissions
        require(IERC1155RolesTracker(msg.sender).roleHas(tx.origin, "admin"), "Admin Only");
        //Disable Rule
        _ruleDisable(id, disabled);
    }

    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external override {
        //Validate Caller's Permissions
        require(IERC1155RolesTracker(msg.sender).roleHas(tx.origin, "admin"), "Admin Only");
        //Set Confirmations
        _confirmationSet(id, confirmation);
    }

    /*
    /// TODO: Update Rule's Effects
    function ruleEffectsUpdate(uint256 id, DataTypes.Effect[] memory effects) external override {
        //Validate Caller's Permissions
        require(IERC1155RolesTracker(msg.sender).roleHas(tx.origin, "admin"), "Admin Only");
        //Set Effects
        
    }
    */

    /// Generate a Global Unique Identifier for a Rule
    // function ruleGUID(DataTypes.Rule memory rule) public pure override returns (bytes32) {
        // return bytes32(keccak256(abi.encode(rule.about, rule.affected, rule.negation, rule.tool)));
        // return bytes32(keccak256(abi.encode(ruleId, gameId)));
    // }

    /// Add Rule
    function _ruleAdd(DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) internal returns (uint256) {
        //Add New Rule
        _ruleIds.increment();
        uint256 id = _ruleIds.current();
        //Set
        _ruleSet(id, rule, effects);
        //Return
        return id;
    }

    /// Disable Rule
    function _ruleDisable(uint256 id, bool disabled) internal {
        _rules[msg.sender][id].disabled = disabled;
        //Event
        emit RuleDisabled(id, disabled);
    }
    
    /// Remove Rule
    function _ruleRemove(uint256 id) internal {
        delete _rules[msg.sender][id];
        //Event
        emit RuleRemoved(id);
    }

    //TODO: Separate Rule Effects Update from Rule Update

    /// Set Rule
    function _ruleSet(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) internal {
        //Set
        _rules[msg.sender][id] = rule;
        //Rule Updated Event
        emit Rule(id, rule.about, rule.affected, rule.uri, rule.negation);

        // emit RuleEffects(id, rule.effects.environmental, rule.effects.personal, rule.effects.social, rule.effects.professional);
        for (uint256 i = 0; i < effects.length; ++i) {
            _effects[msg.sender][id].push(effects[i]);
            //Effect Added Event
            emit RuleEffect(id, effects[i].direction, effects[i].value, effects[i].name);
        }
    }

    /// Update Rule
    function _ruleUpdate(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) internal {
        //Remove Current Effects
        delete _effects[msg.sender][id];
        //Update Rule
        _ruleSet(id, rule, effects);
    }
    
    /* REMOVED - This should probably be in the implementing Contract
    /// Update Confirmation Method for Action
    function confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) external override {
        //TODO: Validate Caller's Permissions
        _confirmationSet(id, confirmation);
    }
    */

    /// Set Action's Confirmation Object
    function _confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) internal {
        //Save
        _ruleConfirmation[msg.sender][id] = confirmation;
        //Event
        emit Confirmation(id, confirmation.ruling, confirmation.evidence, confirmation.witness);
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
library CountersUpgradeable {
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

    //--- Incidents

    //Incident Lifecycle
    enum IncidentStage {
        Draft,
        Open,           // Filed -- Confirmation/Discussion (Evidence, Witnesses, etc’)
        Verdict,        // Awaiting Decision (Authority, Jury, vote, etc’)
        Action,         // Remedy - Reward / Punishment / Compensation
        Appeal,
        Enforcement,
        Closed,
        Cancelled       // Denied / Withdrawn
    }

    //--- Actions

    // Semantic Action Entity
    struct Action {
        string name;    // Title: "Breach of contract",  
        string text;    // text: "The founder of the project must comply with the terms of the contract with investors",  //Text Description
        string uri;     //Additional Info
        SVO entities;
        // Confirmation confirmation;          //REMOVED - Confirmations a part of the Rule, Not action
    }

    struct SVO {    //Action's Core (System Role Mapping) (Immutable)
        string subject;
        string verb;
        string object;
        string tool; //[TBD]
    }

    //--- Rules
    
    // Rule Object
    struct Rule {
        bytes32 about;      //About What (Action's GUID)      //TODO: Maybe Call This 'actionGUID'? 
        string affected;    //Affected Role. E.g. "investors"
        bool negation;      //0 - Commision  1 - Omission
        string uri;         //Test & Conditions
        bool disabled;      //1 - Rule Disabled
    }
    
    // Effect Structure
    struct Effect {
        string name;
        uint8 value;    // value: 5
        bool direction; // Direction: -
        // Confidence/Strictness: [?]
    }
    
    //Rule Confirmation Method
    struct Confirmation {
        string ruling;
        // ruling: "authority"|"jury"|"democracy",  //Decision Maker
        bool evidence;
        // evidence: true, //Require Evidence
        uint witness;
        // witness: 1,  //Minimal number of witnesses
    }

    //--- Incident Data

    //Rule Reference
    struct RuleRef {
        address game;
        uint256 ruleId;
    }
    
    //-- Function Inputs Structs

    //Role Input Struct
    struct InputRole {
        address account;
        string role;
    }

    //Role Input Struct (for Token)
    struct InputRoleToken {
        uint256 tokenId;
        string role;
    }

    //Decision (Verdict) Input
    struct InputDecision {
        uint256 ruleId;
        bool decision;
    }

    //Role Name Input Struct
    // struct InputRoleMapping {
    //     string role;
    //     string name;
    // }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.4;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IERC1155RolesTracker {

    //--- Functions

    /// Unique Members Addresses
    function uniqueRoleMembers(string memory role) external view returns (uint256[] memory);

    /// Unique Members Count (w/Token)
    function uniqueRoleMembersCount(string memory role) external view returns (uint256);    

    /// Check if Role Exists
    function roleExist(string memory role) external view returns (bool);

    /// Check if account is assigned to role
    function roleHas(address account, string calldata role) external view returns (bool);

    /// Check if Soul Token is assigned to role
    function roleHasByToken(uint256 soulToken, string memory role) external view returns (bool);

    /// Get Metadata URI by Role
    function roleURI(string calldata role) external view returns(string memory);

    //--- Events

    /// New Role Created
    event RoleCreated(uint256 indexed id, string role);

    /// URI Change Event
    event RoleURIChange(string value, string role);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IRules {
    
    /// Expose Action Repo Address
    // function actionRepo() external view returns (address);

    ///Get Rule
    function ruleGet(uint256 id) external view returns (DataTypes.Rule memory);

    /// Get Rule's Effects
    function effectsGet(uint256 id) external view returns (DataTypes.Effect[] memory);

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) external view returns (DataTypes.Confirmation memory);

    /// Update Confirmation Method for Action
    // function confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) external;

    //--
    
    /// Generate a Global Unique Identifier for a Rule
    // function ruleGUID(DataTypes.Rule memory rule) external pure returns (bytes32);


    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation, DataTypes.Effect[] memory effects) external returns (uint256);

    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) external;
    
    /// Set Disable Status for Rule
    function ruleDisable(uint256 id, bool disabled) external;

    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external;
  
    //--- Events

    /// Action Repository (HISTORY) Set
    // event ActionRepoSet(address actionRepo);

    /// Rule Added or Changed
    event Rule(uint256 indexed id, bytes32 about, string affected, string uri, bool negation);

    /// Rule Disabled Status Changed
    event RuleDisabled(uint256 id, bool disabled);

    /// Rule Removed
    event RuleRemoved(uint256 indexed id);

    /// Rule's Effects
    // event RuleEffects(uint256 indexed id, int8 environmental, int8 personal, int8 social, int8 professional);
    /// Generic Role Effect
    event RuleEffect(uint256 indexed id, bool direction, uint8 value, string name);

    /// Action Confirmation Change
    event Confirmation(uint256 indexed id, string ruling, bool evidence, uint witness);

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

    /// Action URI Updated
    event ActionURI(bytes32 indexed guid, string uri);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Common Protocol Functions
 */
interface ICommonYJ {
    
    /// Inherit owner from Protocol's config
    function owner() external view returns (address);
    
    // Change Hub (Move To a New Hub)
    function setHub(address hubAddr) external;

    /// Get Hub Contract
    function getHub() external view returns(address);
    
    //Repo Address
    function repoAddr() external view returns(address);

    /// Generic Config Get Function
    // function confGet(string memory key) external view returns(string memory);

    /// Generic Config Set Function
    // function confSet(string memory key, string memory value) external;

    //-- Events

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IGame {
    
    //--- Functions

    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external;

    /// Initialize
    function initialize(address hub, string calldata name_, string calldata uri_) external;

    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Generic Config Get Function
    function confGet(string memory key) external view returns(string memory);

    /// Generic Config Set Function
    function confSet(string memory key, string memory value) external;

    /// Add Post 
    function post(string calldata entRole, uint256 tokenId, string calldata uri) external;

    /// Disable Incident
    function incidentDisable(address incidentContract) external;

    /// Check if Incident is Owned by This Contract (& Active)
    function incidentHas(address incidentContract) external view returns (bool);

    /// Join game as member
    function join() external returns (uint256);

    /// Leave member role in current game
    function leave() external returns (uint256);

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri) external;

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 toToken, string memory role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) external;

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external;

    /// Create a new Role
    // function roleCreate(address account, string calldata role) external;

    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external;


    /// Add Reputation (Positive or Negative)
    function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;



    /* MOVED TO IRules
    //-- Rule Func.

    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation, DataTypes.Effect[] memory effects) external returns (uint256);

    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) external;
    
    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external;

    */

    


    //--- Events

    /// New Incident Created
    event IncidentCreated(uint256 indexed id, address contractAddress);    

    /// Nominate
    event Nominate(address account, uint256 indexed id, string uri);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IOpenRepo {

    //--- Functions

    //-- Addresses  

    /// Get Association
    function addressGet(string memory key) external view returns(address);

    /// Get Contract Association
    function addressGetOf(address originContract, string memory key) external view returns(address);

    /// Get First Address in Index
    function addressGetIndexOf(address originContract, string memory key, uint256 index) external view returns(address);

    /// Get First Address in Index
    function addressGetIndex(string memory key, uint256 index) external view returns(address);

    /// Get All Address in Slot
    function addressGetAllOf(address originContract, string memory key) external view returns(address[] memory);
    
    /// Get All Address in Slot
    function addressGetAll(string memory key) external view returns(address[] memory);

    /// Set  Association
    function addressSet(string memory key, address value) external;

    /// Add Address to Slot
    function addressAdd(string memory key, address value) external;

    /// Remove Address from Slot
    function addressRemove(string memory key, address value) external;

    //-- Booleans

    /// Get Association
    function boolGet(string memory key) external view returns(bool);

    /// Get Contract Association
    function boolGetOf(address originContract, string memory key) external view returns(bool);

    /// Get First Address in Index
    function boolGetIndexOf(address originContract, string memory key, uint256 index) external view returns(bool);

    /// Get First Address in Index
    function boolGetIndex(string memory key, uint256 index) external view returns(bool);

    /// Set  Association
    function boolSet(string memory key, bool value) external;

    /// Add Address to Slot
    function boolAdd(string memory key, bool value) external;

    /// Remove Address from Slot
    function boolRemove(string memory key, bool value) external;


    //-- Strings

    /// Get Association
    function stringGet(string memory key) external view returns(string memory);

    /// Get Contract Association
    function stringGetOf(address originAddress, string memory key) external view returns(string memory);

    /// Get First Address in Index
    function stringGetIndexOf(address originAddress, string memory key, uint256 index) external view returns(string memory);

    /// Get First Address in Index
    function stringGetIndex(string memory key, uint256 index) external view returns(string memory);

    /// Set  Association
    function stringSet(string memory key, string memory value) external;

    /// Add Address to Slot
    function stringAdd(string memory key, string memory value) external;

    /// Remove Address from Slot
    function stringRemove(string memory key, string memory value) external;


    //--- Events

    //-- Addresses

    /// Association Set
    event AddressSet(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressAdd(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressRemoved(address originAddress, string key, address destinationAddress);


    //-- Booleans

    /// Association Set
    event BoolSet(address originContract, string key, bool value);

    /// Association Added
    event BoolAdd(address originContract, string key, bool value);

    /// Association Added
    event BoolRemoved(address originContract, string key, bool value);


    //-- Strings

    /// Association Set
    event StringSet(address originAddress, string key, string value);

    /// Association Added
    event StringAdd(address originAddress, string key, string value);

    /// Association Added
    event StringRemoved(address originAddress, string key, string value);


}