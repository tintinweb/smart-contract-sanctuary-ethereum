//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./libraries/DataTypes.sol";
import "./interfaces/ICase.sol";
import "./interfaces/IRules.sol";
import "./interfaces/IAvatar.sol";
import "./interfaces/IERC1155RolesTracker.sol";
import "./interfaces/IJurisdictionUp.sol";
// import "./interfaces/IJurisdiction.sol";
import "./interfaces/IAssoc.sol";
// import "./abstract/ContractBase.sol";
import "./abstract/CommonYJUpgradable.sol";
// import "./abstract/ERC1155RolesUpgradable.sol";
import "./abstract/ERC1155RolesTrackerUp.sol";
import "./abstract/Posts.sol";

/**
 * @title Upgradable Case Contract
 * @dev Version 1.1
 */
contract CaseUpgradable is 
    ICase, 
    Posts, 
    // ContractBase,    //Redundant
    CommonYJUpgradable, 
    ERC1155RolesTrackerUp {
    // ERC1155RolesUpgradable {

    //--- Storage
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _ruleIds;  //Track Last Rule ID

    // Contract name
    string public name;
    // Contract symbol
    // string public symbol;
    string public constant symbol = "YJ_CASE";

    //Jurisdiction
    address private _jurisdiction;
    //Contract URI
    // string internal _contract_uri;

    //Stage (Case Lifecycle)
    DataTypes.CaseStage public stage;

    //Rules Reference
    mapping(uint256 => DataTypes.RuleRef) internal _rules;      // Mapping for Case Rules
    mapping(uint256 => bool) public decision;                   // Mapping for Rule Decisions
    
    //--- Modifiers

    //--- Functions
    
    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICase).interfaceId 
            || interfaceId == type(IRules).interfaceId 
            || interfaceId == type(IAssoc).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Initializer
    function initialize (
        address hub, 
        string memory name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] memory addRules, 
        DataTypes.InputRoleToken[] memory assignRoles, 
        address container
    ) public override initializer {
        //Set Parent Container
        _setParentCTX(container);
        //Initializers
        __CommonYJ_init(hub);
        // __setTargetContract(_HUB.getAssoc("avatar"));
        __setTargetContract(IAssoc(address(_HUB)).getAssoc("avatar"));
        //Set Contract URI
        _setContractURI(uri_);
        //Identifiers
        name = name_;
        //Init Default Case Roles
        _roleCreate("admin");
        _roleCreate("subject");     //Filing against
        _roleCreate("plaintiff");   //Filing the case
        _roleCreate("judge");       //Deciding authority
        _roleCreate("witness");     //Witnesses
        _roleCreate("affected");    //Affected Party [?]
        //Auto-Set Creator Wallet as Admin
        _roleAssign(tx.origin, "admin", 1);
        _roleAssign(tx.origin, "plaintiff", 1);
        //Assign Roles
        for (uint256 i = 0; i < assignRoles.length; ++i) {
            _roleAssignToToken(assignRoles[i].tokenId, assignRoles[i].role, 1);

        }
        //Add Rules
        for (uint256 i = 0; i < addRules.length; ++i) {
            _ruleAdd(addRules[i].jurisdiction, addRules[i].ruleId);
        }
    }

    /// Set Parent Container
    function _setParentCTX(address container) internal {
        //Validate
        require(container != address(0), "Invalid Container Address");
        require(IERC165(container).supportsInterface(type(IJurisdiction).interfaceId), "Implmementation Does Not Support Jurisdiction Interface");  //Might Cause Problems on Interface Update. Keep disabled for now.
        //Set        
        _jurisdiction = container;

        //TODO: Use OpenRepo

    }

    /// Assign to a Role
    function roleAssign(address account, string memory role) public override roleExists(role) {
        //Special Validations for 'judge' role
        if (keccak256(abi.encodePacked(role)) == keccak256(abi.encodePacked("judge"))){
            require(_jurisdiction != address(0), "Unknown Parent Container");
            //Validate: Must Hold same role in Containing Jurisdiction
            require(IERC1155RolesTracker(_jurisdiction).roleHas(account, role), "User Required to hold same role in Jurisdiction");
        }
        else{
            //Validate Permissions
            require(
                owner() == _msgSender()      //Owner
                || roleHas(_msgSender(), "admin")    //Admin Role
                // || msg.sender == address(_HUB)   //Through the Hub
                , "INVALID_PERMISSIONS");
        }
        //Add
        _roleAssign(account, role, 1);
    }
    
    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 ownerToken, string memory role) public override roleExists(role) {
        //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _roleAssignToToken(ownerToken, role, 1);
    }
    
    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) public override roleExists(role) {
        //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || balanceOf(_msgSender(), _roleToId("admin")) > 0     //Admin Role
            , "INVALID_PERMISSIONS");
        //Remove
        _roleRemoveFromToken(ownerToken, role, 1);
    }

    // roleRequest() => Event [Communication]

    // roleOffer() (Upon Reception)

    // roleAccept()

    /// Check if Reference ID exists
    function ruleRefExist(uint256 ruleRefId) internal view returns (bool){
        return (_rules[ruleRefId].jurisdiction != address(0) && _rules[ruleRefId].ruleId != 0);
    }

    /// Fetch Rule By Reference ID
    function ruleGet(uint256 ruleRefId) public view returns (DataTypes.Rule memory){
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].jurisdiction).ruleGet(_rules[ruleRefId].ruleId);
    }

    /// Get Rule's Confirmation Data
    function ruleGetConfirmation(uint256 ruleRefId) public view returns (DataTypes.Confirmation memory){
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].jurisdiction).confirmationGet(_rules[ruleRefId].ruleId);
    }

    /// Get Rule's Effects
    function ruleGetEffects(uint256 ruleRefId) public view returns (DataTypes.Effect[] memory){
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].jurisdiction).effectsGet(_rules[ruleRefId].ruleId);
    }

    // function post(string entRole, string uri) 
    // - Post by account + role (in the case, since an account may have multiple roles)

    // function post(uint256 token_id, string entRole, string uri) 
    //- Post by Entity (Token ID or a token identifier struct)
    
    /// Check if the Current Account has Control over a Token
    function _hasTokenControl(uint256 tokenId) internal view returns (bool){
        address ownerAccount = _getAccount(tokenId);
        return (
            // ownerAccount == _msgSender()    //Token Owner
            ownerAccount == tx.origin    //Token Owner (Allows it to go therough the hub)
            || (ownerAccount == _targetContract && owner() == _msgSender()) //Unclaimed Token Controlled by Contract Owner/DAO
        );
    }
    
    /// Add Post 
    /// @param entRole  posting as entitiy in role (posting entity must be assigned to role)
    function post(string calldata entRole, uint256 tokenId, string calldata uri_) external override {     //postRole in the URI
        //Validate that User Controls The Token
        require(_hasTokenControl(tokenId), "SOUL:NOT_YOURS");
        //Validate: Sender Holds The Entity-Role 
        // require(roleHas(_msgSender(), entRole), "ROLE:INVALID_PERMISSION");
        require(roleHas(tx.origin, entRole), "ROLE:NOT_ASSIGNED");    //Validate the Calling Account
        //Validate Stage
        require(stage < DataTypes.CaseStage.Closed, "STAGE:CASE_CLOSED");

        //Post Event
        // emit Post(_msgSender(), entRole, postRole, uri_);
        // emit Post(tx.origin, entRole, postRole, uri_);
        // emit Post(tx.origin, entRole, uri_);
        _post(tx.origin, tokenId, entRole, uri_);
    }

    //--- Rule Reference 

    /// Add Rule Reference
    function ruleAdd(address jurisdiction_, uint256 ruleId_) external {
        //Validate Jurisdiciton implements IRules (ERC165)
        require(IERC165(jurisdiction_).supportsInterface(type(IRules).interfaceId), "Implmementation Does Not Support Rules Interface");  //Might Cause Problems on Interface Update. Keep disabled for now.
        //Validate Sender
        require (_msgSender() == address(_HUB) 
            || roleHas(_msgSender(), "admin") 
            || owner() == _msgSender(), "EXPECTED HUB OR ADMIN");
        //Run
        _ruleAdd(jurisdiction_, ruleId_);
    }

    /// Add Relevant Rule Reference 
    function _ruleAdd(address jurisdiction_, uint256 ruleId_) internal {
        //Assign Rule Reference ID
        _ruleIds.increment(); //Start with 1
        uint256 ruleId = _ruleIds.current();
        //New Rule
        _rules[ruleId].jurisdiction = jurisdiction_;
        _rules[ruleId].ruleId = ruleId_;
        //Get Rule, Get Affected & Add as new Role if Doesn't Exist
        DataTypes.Rule memory rule = ruleGet(ruleId);
        //Validate Rule Active
        require(rule.disabled == false, "Selected rule is disabled");
        if(!roleExist(rule.affected)){
            //Create Affected Role if Missing
            _roleCreate(rule.affected);
        }
        //Event: Rule Reference Added 
        emit RuleAdded(jurisdiction_, ruleId_);
    }
    
    //--- State Changers
    
    /// File the Case (Validate & Open Discussion)  --> Open
    function stageFile() public override {
        //Validate Caller
        require(roleHas(tx.origin, "plaintiff") || roleHas(_msgSender(), "admin") , "ROLE:PLAINTIFF_OR_ADMIN");
        //Validate Lifecycle Stage
        require(stage == DataTypes.CaseStage.Draft, "STAGE:DRAFT_ONLY");
        //Validate - Has Subject
        require(uniqueRoleMembersCount("subject") > 0 , "ROLE:MISSING_SUBJECT");
        //Validate - Prevent Self Report? (subject != affected)

        //Validate Witnesses
        for (uint256 ruleId = 1; ruleId <= _ruleIds.current(); ++ruleId) {
            // DataTypes.Rule memory rule = ruleGet(ruleId);
            DataTypes.Confirmation memory confirmation = ruleGetConfirmation(ruleId);
            //Get Current Witness Headcount (Unique)
            uint256 witnesses = uniqueRoleMembersCount("witness");
            //Validate Min Witness Requirements
            require(witnesses >= confirmation.witness, "INSUFFICIENT_WITNESSES");
        }
        //Case is now Open
        _setStage(DataTypes.CaseStage.Open);
    }

    /// Case Wait For Verdict  --> Pending
    function stageWaitForVerdict() public override {
        //Validate Stage
        require(stage == DataTypes.CaseStage.Open, "STAGE:OPEN_ONLY");
        //TODO: Validate Caller
        // require(roleHas(tx.origin, "judge") || roleHas(_msgSender(), "admin") , "ROLE:JUDGE_OR_ADMIN");
        //Case is now Waiting for Verdict
        _setStage(DataTypes.CaseStage.Verdict);
    }   

    /// Case Stage: Place Verdict  --> Closed
    // function stageVerdict(string calldata uri) public override {
    function stageVerdict(DataTypes.InputDecision[] calldata verdict, string calldata uri_) public override {
        require(roleHas(_msgSender(), "judge") , "ROLE:JUDGE_ONLY");
        require(stage == DataTypes.CaseStage.Verdict, "STAGE:VERDICT_ONLY");

        //Process Verdict
        for (uint256 i = 0; i < verdict.length; ++i) {
            decision[verdict[i].ruleId] = verdict[i].decision;
            if(verdict[i].decision){
                // Rule Confirmed
                _ruleConfirmed(verdict[i].ruleId);
            }
        }

        //Case is now Closed
        _setStage(DataTypes.CaseStage.Closed);
        //Emit Verdict Event
        emit Verdict(uri_, _msgSender());
    }

    /// Case Stage: Reject Case --> Cancelled
    function stageCancel(string calldata uri_) public override {
        require(roleHas(_msgSender(), "judge") , "ROLE:JUDGE_ONLY");
        require(stage == DataTypes.CaseStage.Verdict, "STAGE:VERDICT_ONLY");
        //Case is now Closed
        _setStage(DataTypes.CaseStage.Cancelled);
        //Cancellation Event
        emit Cancelled(uri_, _msgSender());
    }

    /// Change Case Stage
    function _setStage(DataTypes.CaseStage stage_) internal {
        //Set Stage
        stage = stage_;
        //Stage Change Event
        emit Stage(stage);
    }

    /// Rule (Action) Confirmed (Currently Only Judging Avatars)
    function _ruleConfirmed(uint256 ruleId) internal {
        //Get Avatar Contract
        // IAvatar avatarContract = IAvatar(_HUB.getAssoc("avatar"));
        IAvatar avatarContract = IAvatar(IAssoc(address(_HUB)).getAssoc("avatar"));

        /* REMOVED for backward compatibility while in dev mode.
        //Validate Avatar Contract Interface
        require(IERC165(address(avatarContract)).supportsInterface(type(IAvatar).interfaceId), "Invalid Avatar Contract");
        */

        //Fetch Case's Subject(s)
        uint256[] memory subjects = uniqueRoleMembers("subject");
        //Each Subject
        for (uint256 i = 0; i < subjects.length; ++i) {
            //Get Subject's Token ID For 
            // uint256 tokenId = avatarContract.tokenByAddress(subjects[i]);
            uint256 tokenId = subjects[i];
            if(tokenId > 0){
                DataTypes.Effect[] memory effects = ruleGetEffects(ruleId);
                //Run Each Effect
                for (uint256 j = 0; j < effects.length; ++j) {
                    DataTypes.Effect memory effect = effects[j];
                    bool direction = effect.direction;
                    //Register Rep in Jurisdiction      //{name:'professional', value:5, direction:false}
                    IJurisdiction(_jurisdiction).repAdd(address(avatarContract), tokenId, effect.name, direction, effect.value);
                }
            }

        }
        
        //Rule Confirmed Event
        emit RuleConfirmed(ruleId);
    }

    /// Get Token URI by Token ID
    function uri(uint256 token_id) public view returns (string memory) {
        return _tokenURIs[token_id];
    }
    
    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external override {
        //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _setRoleURI(role, _tokenURI);
    }
   
    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external override {
        //Validate Permissions
        require( owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        //Set
        _setContractURI(contract_uri);
    }

    // function nextStage(string calldata uri) public {
        // if (sha3(myEnum) == sha3("Bar")) return MyEnum.Bar;
    // }

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
    /* DEPRECAED - Using Boolean
    /// Rating Categories
    enum Rating {
        Negative,   //0
        Positive    //1
    }
    */

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
        Enforcement,
        Closed,
        Cancelled
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
        //     //Describe an event
        //     affected: "investors",  //Plaintiff Role (Filing the case)
        // string affected;    //[PONDER] Doest this really belong here? Is that part of the unique combination, or should this be an array, or an eadge?      //MOVED TO Rule
    }

    //--- Rules
    
    // Rule Object
    struct Rule {
        bytes32 about;      //About What (Action's GUID)      //TODO: Maybe Call This 'actionGUID'? 
        string affected;    // affected: "investors",  //Plaintiff Role (Filing the case)
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
        // ruling: "judge"|"jury"|"democracy",  //Decision Maker
        bool evidence;
        // evidence: true, //Require Evidence
        uint witness;
        // witness: 1,  //Minimal number of witnesses
    }

    //--- Case Data

    //Rule Reference
    struct RuleRef {
        address jurisdiction;
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

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface ICase {
    
    //-- Functions

    /// Initialize
    function initialize(address hub, string memory name_, string calldata uri_, DataTypes.RuleRef[] memory addRules, DataTypes.InputRoleToken[] memory assignRoles, address container) external ;

    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external;

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 ownerToken, string memory role) external;
        
    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) external;

    // RoleRequest()

    // RoleOffered()

    // RoleAccepted()

    // RoleAssigned()

    /// File the Case (Validate & Open Discussion)  --> Open
    function stageFile() external;

    /// Case Wait For Verdict  --> Pending
    function stageWaitForVerdict() external;

    /// Case Stage: Place Verdict  --> Closed
    // function stageVerdict(string calldata uri) external;
    function stageVerdict(DataTypes.InputDecision[] calldata verdict, string calldata uri) external;

    /// Case Stage: Reject Case --> Cancelled
    function stageCancel(string calldata uri) external;

    /// Add Post 
    function post(string calldata entRole, uint256 tokenId, string calldata uri) external;

    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external;

    //--- Events

    /// Case Stage Change
    event Stage(DataTypes.CaseStage stage);

    /// Post Verdict
    event Verdict(string uri, address account);

    /// Case Cancelation Data
    event Cancelled(string uri, address account);

    /// Rule Reference Added
    event RuleAdded(address jurisdiction, uint256 ruleId);

    //Rule Confirmed
    event RuleConfirmed(uint256 ruleId);

    //Rule Denied (Changed from Confirmed)
    // event RuleDenied(uint256 ruleId);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IRules {
    
    /// Expose Action Repo Address
    // function actionRepo() external view returns (address);

    ///Get Rule
    function ruleGet(uint256 id) external view returns (DataTypes.Rule memory);

    /// Update Confirmation Method for Action
    // function confirmationSet(uint256 id, DataTypes.Confirmation memory confirmation) external;

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) external view returns (DataTypes.Confirmation memory);

    /// Get Rule's Effects
    function effectsGet(uint256 id) external view returns (DataTypes.Effect[] memory);

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

// import "../libraries/DataTypes.sol";

interface IAvatar {

    //--- Functions

    /// Get Token ID by Address
    function tokenByAddress(address owner) external view returns (uint256);

    /// Mint (Create New Avatar for oneself)
    function mint(string memory tokenURI) external returns (uint256);

    /// Add (Create New Avatar Without an Owner)
    function add(string memory tokenURI) external returns (uint256);

    /// Update Token's Metadata
    function update(uint256 tokenId, string memory uri) external returns (uint256);

    /// Add Reputation (Positive or Negative)
    function repAdd(uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /// Map Account to Existing Token
    function tokenOwnerAdd(address owner, uint256 tokenId) external;

    /// Remove Account from Existing Token
    function tokenOwnerRemove(address owner, uint256 tokenId) external;

    //--- Events
    
	/// URI Change Event
    event URI(string value, uint256 indexed id);    //Copied from ERC1155

    /// Reputation Changed
    event ReputationChange(uint256 indexed id, string domain, bool rating, uint256 score);

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

interface IJurisdiction {
    
    //--- Functions

    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external;

    /// Initialize
    function initialize(address hub, string calldata name_, string calldata uri_) external;

    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Disable Case
    function caseDisable(address caseContract) external;

    /// Check if Case is Owned by This Contract (& Active)
    function caseHas(address caseContract) external view returns (bool);

    /// Join jurisdiction as member
    function join() external returns (uint256);

    /// Leave member role in current jurisdiction
    function leave() external returns (uint256);

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

    /// Make a new Case
    // function caseMake(
    //     string calldata name_, 
    //     string calldata uri_, 
    //     DataTypes.RuleRef[] calldata addRules, 
    //     DataTypes.InputRoleToken[] calldata assignRoles, 
    //     PostInput[] calldata posts
    // ) external returns (address);
    // function caseMakeOpen(
    //     string calldata name_, 
    //     string calldata uri_, 
    //     DataTypes.RuleRef[] calldata addRules, 
    //     DataTypes.InputRoleToken[] calldata assignRoles, 
    //     PostInput[] calldata posts
    // ) external returns (address);
    
    /// Add Reputation (Positive or Negative)
    function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    //-- Rule Func.

    /// Create New Rule
    // function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation) external returns (uint256);
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation, DataTypes.Effect[] memory effects) external returns (uint256);

    /// Update Rule
    // function ruleUpdate(uint256 id, DataTypes.Rule memory rule) external;
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) external;
    
    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external;
        
    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external;


    //--- Events

    /// New Case Created
    event CaseCreated(uint256 indexed id, address contractAddress);    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAssoc {
    
    //--- Functions

    //Get Contract Association
    function getAssoc(string memory key) external view returns(address);

    //--- Events

    /// Association Set
    event Assoc(string key, address contractAddr);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/ICommonYJ.sol";
import "../interfaces/IHub.sol";
import "../libraries/DataTypes.sol";
import "../abstract/ContractBase.sol";

/**
 * Common Protocol Functions
 */
abstract contract CommonYJUpgradable is 
        ICommonYJ, 
        ContractBase, 
        OwnableUpgradeable {
    
    //--- Storage

    // address internal _HUB;    //Hub Contract
    IHub internal _HUB;    //Hub Contract
    

    //--- Functions

    /// Initializer
    function __CommonYJ_init(address hub) internal onlyInitializing {
        //Set Protocol's Config Address
        _setHub(hub);
    }

    /// Inherit owner from Protocol's config
    function owner() public view override(ICommonYJ, OwnableUpgradeable) returns (address) {
        return _HUB.owner();
    }

    /// Get Current Hub Contract Address
    function getHub() external view override returns(address) {
        return _getHub();
    }

    /// Set Hub Contract
    function _getHub() internal view returns(address) {
        return address(_HUB);
    }
    
    /// Change Hub (Move To a New Hub)
    function setHub(address hubAddr) external override {
        require(_msgSender() == address(_HUB), "HUB:UNAUTHORIZED_CALLER");
        _setHub(hubAddr);
    }

    /// Set Hub Contract
    function _setHub(address hubAddr) internal {
        //Validate Contract's Designation
        require(keccak256(abi.encodePacked(IHub(hubAddr).role())) == keccak256(abi.encodePacked("YJHub")), "Invalid Hub Contract");
        //Set
        _HUB = IHub(hubAddr);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IERC1155RolesTracker.sol";
import "./ERC1155GUIDTrackerUp.sol";

/**
 * @title Sub-Groups with Role NFTs
 * @dev ERC1155 using GUID as Role
 * To Extend Cases & Jutisdictions
 * - Create Roles
 * - Assign Roles
 * - Remove Roles
 * ---- 
 * - [TODO] request + approve 
 * - [TODO] offer + accept
 * 
 * References: 
 *  Fractal DAO Access Control  https://github.com/fractal-framework/fractal-contracts/blob/93bc0e845a382673f3714e7df858e846d0f10b37/contracts/AccessControl.sol
 *  OZ Access Control  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 */
abstract contract ERC1155RolesTrackerUp is 
        IERC1155RolesTracker, 
        ERC1155GUIDTrackerUp {
    
    //--- Storage

    //--- Modifiers
    modifier roleExists(string memory role) {
        require(roleExist(role), "INEXISTENT_ROLE");
        _;
    }
    
    /* CANCELLED
    /// [TEST] Validate that account hold one of the role in Array
    modifier onlyRoles(string[] calldata roles) {
        bool hasRole;
        for (uint256 i = 0; i < roles.length; ++i) {
            if(roleHas(_msgSender(), roles[i])) hasRole = true;
        }
        require(hasRole, "ROLE:INVALID_PERMISSION");
        _;
    }

    /// Validate that account hold one of the role in Array //Only works when the role is a parameter
    modifier onlyRole(string calldata role) {
        require(roleHas(_msgSender(), role), "ROLE:INVALID_PERMISSION");
        _;
    }
    */

    //--- Functions

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155RolesTracker).interfaceId || super.supportsInterface(interfaceId);
    }

    //** Role Functions

    /// Unique Members Count (w/Token)
    function uniqueRoleMembers(string memory role) public override view returns (uint256[] memory) {
        return uniqueMembers(_roleToId(role));
    }

    /// Unique Members Count (w/Token)
    function uniqueRoleMembersCount(string memory role) public override view returns (uint256) {
        // return uniqueMembers(_roleToId(role)).length;
        return uniqueMembersCount(_roleToId(role));
    }

    /// Check if Role Exists
    function roleExist(string memory role) public view override returns (bool) {
        return _GUIDExists(_stringToBytes32(role));
    }

    /// Check if Soul Token is assigned to role
    function roleHasByToken(uint256 soulToken, string memory role) public view override returns (bool) {
        return GUIDHasByToken(soulToken, _stringToBytes32(role));
    }

    /// Check if account is assigned to role
    function roleHas(address account, string memory role) public view override returns (bool) {
        return GUIDHas(account, _stringToBytes32(role));
    }

    /// [TEST] Has Any of These Roles
    function rolesHas(address account, string[] memory roles) public view returns (bool) {
        for (uint256 i = 0; i < roles.length; ++i) {
            if(roleHas(account, roles[i])){
                return true;
            } 
        }
        return false;
    }

    /// Assign Someone Else to a Role
    function _roleAssign(address account, string memory role, uint256 amount) internal roleExists(role) {
        //Validate Account Has Token
        require(_getExtTokenId(account) != 0, "ERC1155RolesTracker: account must own a token on source contract");
        //Assign
        _GUIDAssign(account, _stringToBytes32(role), amount);
        //TODO: Role Assigned Event?
    }
    
    /// Assign Tethered Token to a Role
    function _roleAssignToToken(uint256 ownerToken, string memory role, uint256 amount) internal roleExists(role) {
        //Assign
        _GUIDAssignToToken(ownerToken, _stringToBytes32(role), amount);
        //TODO: Role Assigned Event?
    }

    /// Remove Someone Else from a Role
    function _roleRemoveFromToken(uint256 ownerToken, string memory role, uint256 amount) internal roleExists(role) {
        _GUIDRemoveFromToken(ownerToken, _stringToBytes32(role), amount);
        //TODO: Role Removed Event?
    }

    /// Remove Someone Else from a Role
    function _roleRemove(address account, string memory role, uint256 amount) internal roleExists(role) {
        _GUIDRemove(account, _stringToBytes32(role), amount);
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

    /// Get Metadata URI by Role
    function roleURI(string calldata role) public view override roleExists(role) returns(string memory) {
        return _tokenURIs[_roleToId(role)];
    }
    
    /// Set Role's Metadata URI
    function _setRoleURI(string memory role, string memory _tokenURI) internal virtual roleExists(role) {
        uint256 tokenId = _roleToId(role);
        _tokenURIs[tokenId] = _tokenURI;
        //URI Changed Event
        emit RoleURIChange(_tokenURI, role);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "../interfaces/IPosts.sol";   //Unecessary

/**
 * @title Rules Contract 
 * @dev To Extend or Be Used by Jurisdictions
 * - Hold, Update, Delete & Serve Rules
 */
abstract contract Posts {
    
    //--- Storage

    /* DEPRECATED
    //Post Input Struct
    struct PostInput {      //DEPRECATE - Localize to Jurisdiction
        string entRole;
        string uri;
    }
    */

    //--- Events

    /// General Post / Evidence, etc'
    // event Post(address indexed account, string entRole, string postRole, string uri);        //postRole Moved to uri
    // event Post(address indexed account, string entRole, string uri); //Added Caller Token ID
    event Post(address indexed account, uint256 tokenId, string entRole, string uri);

    //--- Functions

    /// Add Post 
    /// @param origin  caller address
    /// @param tokenId  posting as entitiy SBT
    /// @param entRole  posting as entitiy in role (posting entity must be assigned to role)
    /// @param uri      post data uri
    // function post(uint256 token_id, string calldata uri) external override {     //Post by Token ID (May later use Entity GUID as Caller)
    // function post(string calldata entRole, string calldata postRole, string calldata uri) external override {        //Explicit postRole
    // function _post(address origin, string calldata entRole, string calldata uri) internal {
    function _post(address origin, uint256 tokenId, string calldata entRole, string calldata uri) internal {
        // emit Post(origin, entRole, uri);
        emit Post(origin, tokenId, entRole, uri);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    
    //-- Events

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IHub {
    
    //--- Functions

    /// Arbitrary contract symbol
    function symbol() external view returns (string memory);
    
    /// Arbitrary contract designation signature
    function role() external view returns (string memory);
    
    /// Get Owner
    function owner() external view returns (address);

    //Repo Address
    function repoAddr() external view returns(address);

    /// Make a new Jurisdiction
    function jurisdictionMake(string calldata name_, string calldata uri_) external returns (address);

    /// Make a new Case
    // function caseMake(string calldata name_, DataTypes.RuleRef[] memory addRules, DataTypes.InputRole[] memory assignRoles) external returns (address);
    function caseMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] memory addRules, 
        DataTypes.InputRoleToken[] memory assignRoles
    ) external returns (address);

    /// Update Hub
    function hubChange(address newHubAddr) external;

    //Get Avatar Contract Address
    // function avatarContract() external view returns (address);

    //Get History Contract Address
    // function historyContract() external view returns (address);

    /// Add Reputation (Positive or Negative)       /// Opinion Updated
    function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /* MOVED to IAssoc
    //Get Contract Association
    function getAssoc(string memory key) external view returns(address);
    */
    
    //--- Events

    /// Beacon Contract Chnaged
    event UpdatedImplementation(string name, address implementation);

    /// New Contract Created
    event ContractCreated(string name, address contractAddress);

    /// New Contract Created
    event HubChanged(address contractAddress);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IContractBase.sol";

/**
 * @title Basic Contract Funtionality (For all contracts)
 * @dev To Extend by any other contract
 */
abstract contract ContractBase is IContractBase {
    
    //--- Storage

    //Contract URI
    string internal _contract_uri;

    //--- Functions

    /**
     * @dev Contract URI
     *  https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view override returns (string memory) {
        return _contract_uri;
    }
    
    /// Set Contract URI
    function _setContractURI(string calldata contract_uri) internal {
        //Set
        _contract_uri = contract_uri;
        //Contract URI Changed Event
        emit ContractURI(contract_uri);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IContractBase {
    
    //--- Functions

    /// Contract URI
    function contractURI() external view returns (string memory);

    //-- Events
    
    /// Contract URI Changed
    event ContractURI(string);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";  //Track Token Supply & Check 
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../abstract/ERC1155TrackerUpgradable.sol";
import "../interfaces/IERC1155GUIDTracker.sol";
import "../libraries/AddressArray.sol";

/**
 * @title 2D ERC1155Tracker -- Members + Groups (Meaningful Global Unique Identifiers for each Token ID)
 * @dev use GUID as a meaningful index
 */
abstract contract ERC1155GUIDTrackerUp is 
        IERC1155GUIDTracker, 
        ERC1155TrackerUpgradable {

    //--- Storage
    // using Strings for uint256;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _tokenIds; //Track Last Token ID
    using AddressArray for address[];
    
    mapping(bytes32 => uint256) internal _GUID; //NFTs as GUID

    //Token Metadata URI
    mapping(uint256 => string) internal _tokenURIs; //Token Metadata URI

    //--- Modifiers

    modifier GUIDExists(bytes32 guid) {
        require(_GUIDExists(guid), "INEXISTENT_GUID");
        _;
    }

    //--- Functions

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155GUIDTracker).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Check if Soul Token is assigned to GUID
    function GUIDHasByToken(uint256 soulToken, bytes32 guid) public view override returns (bool) {
        return (balanceOfToken(soulToken, _GUIDToId(guid)) > 0);
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
    // function GUIDExists(bytes32 guid) internal view returns (bool) {
    //     return (_GUID[guid] != 0);
    // }

    /// Check if GUID Exists
    function _GUIDExists(bytes32 guid) internal view returns (bool) {
        return (_GUID[guid] != 0);
    }

    /// Assign Token
    function _GUIDAssign(address account, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUIDToId(guid);  //_GUID[guid];
        //Mint Token
        _mint(account, tokenId, amount, "");
        //Retrun New Token ID
        return tokenId;
    }
    
    /// Assign Token
    function _GUIDAssignToToken(uint256 soulToken, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUIDToId(guid);  //_GUID[guid];
        //Mint Token
        _mintForToken(soulToken, tokenId, amount, "");
        //Retrun New Token ID
        return tokenId;
    }

    /// Unassign Token
    function _GUIDRemove(address account, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUID[guid];
        //Validate
        require(balanceOf(account, tokenId) > 0, "NOT_ASSIGNED");
        //Burn Token
        _burn(account, tokenId, amount);
        //Retrun New Token ID
        return tokenId;
    }

    /// Unassign Token
    function _GUIDRemoveFromToken(uint256 soulToken, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUID[guid];
        //Validate
        // require(balanceOf(account, tokenId) > 0, "NOT_ASSIGNED");
        //Burn Token
        _burnForToken(soulToken, tokenId, amount);
        //Retrun New Token ID
        return tokenId;
    }

    /// Translate GUID to Token ID
    function _GUIDToId(bytes32 guid) internal view GUIDExists(guid) returns(uint256) {
        return _GUID[guid];
    }

    /// Set Token's Metadata URI
    function _setGUIDURI(bytes32 guid, string memory _tokenURI) internal virtual GUIDExists(guid) {
        uint256 tokenId = _GUIDToId(guid);
        _tokenURIs[tokenId] = _tokenURI;
        //URI Changed Event
        emit GUIDURIChange(_tokenURI, guid);
    }

    /// Get Metadata URI by GUID
    function GUIDURI(bytes32 guid) public view override returns(string memory) {
        return _tokenURIs[_GUIDToId(guid)];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IERC1155Tracker.sol";
import "../interfaces/IAvatar.sol";
import "../libraries/AddressArray.sol";
import "../libraries/UintArray.sol";

/**
 * @title ERC1155 Tracker Upgradable
 * @dev This contract is to be attached to an ERC721 (SoulBoundToken)  contract and mapped to its tokens
 */
abstract contract ERC1155TrackerUpgradable is 
        Initializable, 
        ContextUpgradeable, 
        ERC165Upgradeable, 
        IERC1155Tracker {

    using AddressUpgradeable for address;
    using AddressArray for address[];
    using UintArray for uint256[];
    
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Manage Balances by External Token ID
    mapping(uint256 => mapping(uint256 => uint256)) private _balances;

    //Index Unique Members for each TokenId
    mapping(uint256 => uint256[]) internal _uniqueMemberTokens;

    // Target Contract (External Source)
    address _targetContract;

    /// Get Target Contract
    function getTargetContract() public view virtual override returns (address) {
        return _targetContract;
    }

    /// Set Target Contract
    function __setTargetContract(address targetContract) internal virtual {
        //Validate IERC721
        // require(IERC165(targetContract).supportsInterface(type(IERC721).interfaceId), "Target Expected to Support IERC721");
        require(IERC165(targetContract).supportsInterface(type(IAvatar).interfaceId), "Target contract expected to support IAvatar");
        _targetContract = targetContract;
        // _targetContract = IERC721(targetContract);
    }

    /// Get a Token ID Based on account address (Throws)
    function getExtTokenId(address account) public view returns(uint256) {
        //Validate Input
        require(account != _targetContract, "ERC1155Tracker: source contract address is not a valid account");
        //Get
        uint256 ownerToken = _getExtTokenId(account);
        //Validate Output
        require(ownerToken != 0, "ERC1155Tracker: requested account not found on source contract");
        //Return
        return ownerToken;
    }

    /// Get a Token ID Based on account address
    function _getExtTokenId(address account) internal view returns (uint256) {
        // require(account != address(0), "ERC1155Tracker: address zero is not a valid account");       //Redundant 
        require(account != _targetContract, "ERC1155Tracker: source contract address is not a valid account");
        //Run function on destination contract
        // return IAvatar(_targetContract).tokenByAddress(account);
        uint256 ownerToken = IAvatar(_targetContract).tokenByAddress(account);
        //Validate
        // require(ownerToken != 0, "ERC1155Tracker: account not found on source contract");
        //Return
        return ownerToken;
    }

    /// Unique Members Count (w/Token)
    function uniqueMembers(uint256 id) public view override returns (uint256[] memory) {
        return _uniqueMemberTokens[id];
    }

    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) public view override returns (uint256) {
        return uniqueMembers(id).length;
    }

    /// Get Owner Account By Owner Token
    function _getAccount(uint256 extTokenId) internal view returns (address) {
        return IERC721(_targetContract).ownerOf(extTokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            // interfaceId == type(IERC1155Upgradeable).interfaceId ||
            // interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
     /* REMOVED - Unecessary
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }
    */

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        // return _balances[id][account];
        // return _balances[id][getExtTokenId(account)];
        return balanceOfToken(getExtTokenId(account), id);
    }

    /**
     * Check balance by External Token ID
     */
    function balanceOfToken(uint256 extTokenId, uint256 id) public view override returns (uint256) {
        return _balances[id][extTokenId];
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
     * /
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
     * /
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
     * /
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 ownerFrom = _getExtTokenId(from);
        uint256 ownerTo = _getExtTokenId(to);

        // uint256 fromBalance = _balances[id][from];
        uint256 fromBalance = _balances[id][ownerFrom];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            // _balances[id][from] = fromBalance - amount;
            _balances[id][ownerFrom] = fromBalance - amount;
        }
        // _balances[id][to] += amount;
        _balances[id][ownerTo] += amount;

        emit TransferSingle(operator, from, to, id, amount);
        emit TransferByToken(operator, ownerFrom, ownerTo, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        // _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
     * /
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

        uint256 ownerFrom = _getExtTokenId(from);
        uint256 ownerTo = _getExtTokenId(to);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            // uint256 fromBalance = _balances[id][from];
            uint256 fromBalance = _balances[id][ownerFrom];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                // _balances[id][from] = fromBalance - amount;
                _balances[id][ownerFrom] = fromBalance - amount;
            }
            // _balances[id][to] += amount;
            _balances[id][ownerTo] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        emit TransferBatchByToken(operator, ownerFrom, ownerTo, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        // _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
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
     /* REMOVED - Unecessary
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    */

    /// Mint for Address Owner
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _mintActual(to, getExtTokenId(to), id, amount, data);
    }
    
    /// Mint for External Token Owner
    function _mintForToken(uint256 toToken, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _mintActual(_getAccount(toToken), toToken, id, amount, data);
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
    function _mintActual(
        address to,
        uint256 toToken,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _beforeTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        // _balances[id][to] += amount;
        _balances[id][toToken] += amount;
        
        emit TransferSingle(operator, address(0), to, id, amount);
        emit TransferByToken(operator, 0, toToken, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _afterTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        // _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
        uint256 toToken = getExtTokenId(to);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _beforeTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // _balances[ids[i]][to] += amounts[i];
            _balances[ids[i]][toToken] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        emit TransferBatchByToken(operator, 0, toToken, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _afterTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        // _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /// Burn Token for Account
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        _burnActual(from, getExtTokenId(from), id, amount);
    }

    /// Burn Token by External Token Owner
    function _burnForToken(uint256 fromToken, uint256 id, uint256 amount) internal virtual {
        _burnActual(_getAccount(fromToken), fromToken, id, amount);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burnActual(
        address from,
        uint256 fromToken,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        _beforeTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");

        // uint256 fromBalance = _balances[id][from];
        uint256 fromBalance = _balances[id][fromToken];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            // _balances[id][from] = fromBalance - amount;
            _balances[id][fromToken] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
        emit TransferByToken(operator, fromToken, 0, id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
        _afterTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");
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
        uint256 fromToken = getExtTokenId(from);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        _beforeTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            // uint256 fromBalance = _balances[id][from];
            uint256 fromBalance = _balances[id][fromToken];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                // _balances[id][from] = fromBalance - amount;
                _balances[id][fromToken] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
        emit TransferBatchByToken(operator, fromToken, 0, ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
        _afterTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");
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

    /// An 'onwer' Address (Not Address 0 and not Target Contract)
    function _isOwnerAddress(address addr) internal view returns(bool){
        return (addr != address(0) && addr != _targetContract);
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
    
    /// @dev Hook that is called before any token transfer
    function _beforeTokenTransferTracker(
        address operator,
        uint256 fromToken,
        uint256 toToken,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if(toToken != 0){
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                //If New Owner 
                if(_balances[id][toToken] == 0){
                    //Register New Owner
                    _uniqueMemberTokens[id].push(toToken);
                }
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /// @dev Hook that is called after any token transfer
    function _afterTokenTransferTracker(
        address operator,
        uint256 fromToken,
        uint256 toToken,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if(fromToken != 0){
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                //If Owner Ran Out of Tokens
                if(_balances[id][fromToken] == 0){
                    //Remvoed Owner
                    _uniqueMemberTokens[id].removeItem(fromToken);
                }
            }
        }
    }

    /* Unecessary, because token's aren't really controlled by the account anymore
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    */

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC1155GUIDTracker {

    //--- Functions 
/*
    /// Unique Members Addresses
    function uniqueMembers(uint256 id) external view returns (address[] memory);
    
    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) external view returns (uint256);
*/
    /// Check if account is assigned to role
    function GUIDHas(address account, bytes32 guid) external view returns (bool);
    
    /// Get Metadata URI by GUID
    function GUIDURI(bytes32 guid) external view returns(string memory);

    /// Check if Soul Token is assigned to GUID
    function GUIDHasByToken(uint256 soulToken, bytes32 guid) external view returns (bool);

    //--- Events

    /// New GUID Created
    event GUIDCreated(uint256 indexed id, bytes32 guid);
    
    /// URI Change Event
    event GUIDURIChange(string value, bytes32 indexed guid);
   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Basic Array Functionality
 */
library AddressArray {

    /// Remove Address From Array
    function removeItem(address[] storage array, address targetAddress) internal {
        removeIndex(array, findIndex(array, targetAddress));
    }
    
    /// Remove Address From Array
    function removeIndex(address[] storage array, uint256 index) internal {
        require(index < array.length, "AddressArray:INDEX_OUT_OF_BOUNDS");
        array[index] = array[array.length-1];
        array.pop();
    }

    /// Find Address Index in Array
    function findIndex(address[] storage array, address value) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; ++i) {
            if(array[i] == value) return i;
        }
        revert("AddressArray:ITEM_NOT_IN_ARRAY");
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Tracker is IERC165Upgradeable {

    
    /// Get Target Contract
    function getTargetContract() external view returns (address);

    /// Unique Members Addresses
    function uniqueMembers(uint256 id) external view returns (uint256[] memory);
    
    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) external view returns (uint256);
    

    /// Single Token Transfer
    event TransferByToken(address indexed operator, uint256 indexed fromOwnerToken, uint256 indexed toOwnerToken, uint256 id, uint256 value);

    /// Batch Token Transfer
    event TransferBatchByToken(
        address indexed operator,
        uint256 indexed fromOwnerToken, 
        uint256 indexed toOwnerToken,
        uint256[] ids,
        uint256[] values
    );

    //-- Tranditional Functions

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
     * Check balance by Origin Token ID
     */
    function balanceOfToken(uint256 originTokenId, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * /
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
     * /
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Basic Array Functionality
 */
library UintArray {

    /// Remove Item From Array
    function removeItem(uint256[] storage array, uint256 targetAddress) internal {
        removeIndex(array, findIndex(array, targetAddress));
    }
    
    /// Remove Item From Array
    function removeIndex(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "UintArray:INDEX_OUT_OF_BOUNDS");
        array[index] = array[array.length-1];
        array.pop();
    }

    /// Find Item Index in Array
    function findIndex(uint256[] storage array, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; ++i) {
            if(array[i] == value) return i;
        }
        revert("UintArray:ITEM_NOT_IN_ARRAY");
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
interface IERC165Upgradeable {
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