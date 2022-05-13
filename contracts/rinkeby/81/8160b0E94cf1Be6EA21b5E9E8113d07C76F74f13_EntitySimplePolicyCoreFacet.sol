// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { EntityFacetBase, IERC20 } from "./EntityFacetBase.sol";
import "./base/Controller.sol";
import "./base/IEntitySimplePolicyCoreFacet.sol";
import "./base/IDiamondFacet.sol";
import { SimplePolicy, Stakeholders } from "./SimplePolicy.sol";
import "./base/ISimplePolicy.sol";

contract EntitySimplePolicyCoreFacet is EntityFacetBase, IEntitySimplePolicyCoreFacet, IDiamondFacet {
    constructor(address _settings) Controller(_settings) {}

    function getSelectors() public pure override returns (bytes memory) {
        return abi.encodePacked(IEntitySimplePolicyCoreFacet.createSimplePolicy.selector, IEntitySimplePolicyCoreFacet.updateAllowSimplePolicy.selector);
    }

    function _validateSimplePolicyCreation(address _unit, uint256 _limit) internal view {
        require(dataBool["allowSimplePolicy"], "creation disabled");

        uint256 collateralRatio = dataUint256[__a(_unit, "collateralRatio")];
        uint256 maxCapital = dataUint256[__a(_unit, "maxCapital")];
        require((collateralRatio > 0) && (maxCapital > 0), "currency disabled");

        uint256 newTotalLimit = dataUint256[__a(_unit, "totalLimit")] + _limit;
        require(maxCapital >= newTotalLimit, "max capital exceeded");

        uint256 balance = dataUint256[__a(_unit, "balance")];
        require(balance >= (newTotalLimit * collateralRatio) / 1000, "collateral ratio not met");
    }

    function createSimplePolicy(
        bytes32 _id,
        uint256 _startDate,
        uint256 _maturationDate,
        address _unit,
        uint256 _limit,
        Stakeholders memory _stakeholders
    ) external override {
        _validateSimplePolicyCreation(_unit, _limit);
        dataUint256[__a(_unit, "totalLimit")] += _limit;

        _stakeholders.stakeholdersAddresses[_stakeholders.roles.length] = address(this);

        // create policy
        SimplePolicy policy = new SimplePolicy(_id, dataUint256["numSimplePolicies"], address(settings()), msg.sender, _startDate, _maturationDate, _unit, _limit, _stakeholders);

        address policyAddress = address(policy);

        emit NewSimplePolicy(_id, policyAddress);

        _addChild(policyAddress);

        ISimplePolicy policyFacet = ISimplePolicy(policyAddress);
        policyFacet.approveSimplePolicy(_stakeholders.roles, _stakeholders.approvalSignatures);

        emit SimplePolicyApproved(_id, address(policy));

        dataAddress[__i(dataUint256["numSimplePolicies"], "addressByNumber")] = address(policy);
        dataAddress[__b(_id, "addressById")] = address(policy);
        dataUint256["numSimplePolicies"] = dataUint256["numSimplePolicies"] + 1;
    }

    function updateAllowSimplePolicy(bool _allow) external override assertIsSystemManager(msg.sender) {
        dataBool["allowSimplePolicy"] = _allow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./base/EternalStorage.sol";
import "./base/Controller.sol";
import "./base/IMarket.sol";
import "./base/Parent.sol";
import "./base/IMarketFeeSchedules.sol";
import "./base/IERC20.sol";

/**
 * @dev Entity facet base class
 */
abstract contract EntityFacetBase is EternalStorage, Controller, IMarketFeeSchedules, Parent {
    modifier assertIsEntityAdmin(address _addr) {
        require(inRoleGroup(_addr, ROLEGROUP_ENTITY_ADMINS), "must be entity admin");
        _;
    }

    modifier assertIsSystemManager(address _addr) {
        require(inRoleGroup(_addr, ROLEGROUP_SYSTEM_MANAGERS), "must be system mgr");
        _;
    }

    function _assertHasEnoughBalance(address _unit, uint256 _amount) internal view {
        require(dataUint256[__a(_unit, "balance")] >= _amount, "exceeds entity balance");
    }

    function _assertNoTokenSaleInProgress(address _unit) internal view {
        require(dataUint256[__a(_unit, "tokenSaleOfferId")] == 0, "token sale in progress");
    }

    function _tradeOnMarket(
        address _sellUnit,
        uint256 _sellAmount,
        address _buyUnit,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes memory _notifyData
    ) internal returns (uint256) {
        // get mkt
        IMarket mkt = _getMarket();
        // approve mkt to use my tokens
        IERC20 tok = IERC20(_sellUnit);
        tok.approve(address(mkt), _sellAmount);
        // make the offer
        return mkt.executeLimitOffer(_sellUnit, _sellAmount, _buyUnit, _buyAmount, _feeSchedule, _notify, _notifyData);
    }

    function _getMarket() internal view returns (IMarket) {
        return IMarket(settings().getRootAddress(SETTING_MARKET));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./SettingsControl.sol";
import "./AccessControl.sol";

/**
 * @dev Base contract for interacting with the ACL and Settings contracts.
 */
contract Controller is AccessControl, SettingsControl {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) AccessControl(_settings) SettingsControl(_settings) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { SimplePolicy, Stakeholders } from "../SimplePolicy.sol";
import "./ISimplePolicy.sol";

/**
 * @dev Core logic for Simple Policies.
 */
interface IEntitySimplePolicyCoreFacet {
    /**
     * @dev Create a new policy.
     *
     * @param _id Unique id that represents the policy - this is what stakeholder will sign to approve the policy.
     * @param _startDate Start Date.
     * @param _maturationDate Maturation Date.
     * @param _unit Unit.
     * @param _limit Limit.
     * @param _stakeholders data about roles, stakeholder addresses and approval signatures and commissions.
     */
    function createSimplePolicy(
        bytes32 _id,
        uint256 _startDate,
        uint256 _maturationDate,
        address _unit,
        uint256 _limit,
        Stakeholders calldata _stakeholders
    ) external;

    /**
     * @dev Update Allow Simple Policy.
     *
     * @param _allow Allow.
     */
    function updateAllowSimplePolicy(bool _allow) external;

    /**
     * @dev Emitted when a new policy has been created.
     * @param id The policy id.
     * @param simplePolicy The policy address.
     */
    event NewSimplePolicy(bytes32 indexed id, address indexed simplePolicy);

    /**
     * @dev Emitted when a policy is signed.
     * @param id The policy id.
     * @param simplePolicy The policy address.
     */
    event SimplePolicyApproved(bytes32 indexed id, address indexed simplePolicy);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IDiamondFacet {
    function getSelectors() external pure returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./base/Controller.sol";
import "./base/Proxy.sol";
import "./base/Child.sol";
import "./SimplePolicyFacetBase.sol";
import "./base/ISimplePolicyStates.sol";

struct Stakeholders {
    bytes32[] roles;
    address[] stakeholdersAddresses;
    bytes[] approvalSignatures;
    uint256[] commissions; // always has one element more than roles, for nayms treasury
}

contract SimplePolicy is Controller, Proxy, SimplePolicyFacetBase, Child, ISimplePolicyStates {
    constructor(
        bytes32 _id,
        uint256 _number,
        address _settings,
        address _caller,
        uint256 _startDate,
        uint256 _maturationDate,
        address _unit,
        uint256 _limit,
        Stakeholders memory _stakeholders
    ) Controller(_settings) Proxy() {
        require(_limit > 0, "limit not > 0");

        _setParent(msg.sender);
        _setDelegateAddress(settings().getRootAddress(SETTING_SIMPLE_POLICY_DELEGATE));

        // set policy attributes
        dataBytes32["id"] = _id;
        dataUint256["number"] = _number;
        dataUint256["startDate"] = _startDate;
        dataUint256["maturationDate"] = _maturationDate;
        dataAddress["unit"] = _unit;
        dataUint256["limit"] = _limit;
        dataUint256["state"] = POLICY_STATE_CREATED;

        address broker;
        address underwriter;

        // set the roles and commissions
        acl().assignRole(aclContext(), _caller, ROLE_POLICY_OWNER);

        uint256 rolesCount = _stakeholders.roles.length;
        for (uint256 i = 0; i < rolesCount; i += 1) {
            bytes32 role = _stakeholders.roles[i];

            acl().assignRole(aclContext(), _stakeholders.stakeholdersAddresses[i], role);

            if (role == ROLE_BROKER) {
                broker = _stakeholders.stakeholdersAddresses[i];
                dataUint256["brokerCommissionBP"] = _stakeholders.commissions[i];
            } else if (role == ROLE_UNDERWRITER) {
                underwriter = _stakeholders.stakeholdersAddresses[i];
                dataUint256["underwriterCommissionBP"] = _stakeholders.commissions[i];
            } else if (role == ROLE_CLAIMS_ADMIN) {
                dataUint256["claimsAdminCommissionBP"] = _stakeholders.commissions[i];
            }
        }

        // these are always the last item in array, there is one element more than roles count
        // for storing nayms treasury address and it's commission
        dataAddress["treasury"] = _stakeholders.stakeholdersAddresses[rolesCount];
        dataUint256["naymsCommissionBP"] = _stakeholders.commissions[rolesCount];

        bool underwriterRep;
        bool brokerRep;
        (underwriterRep, brokerRep) = _isBrokerOrUnderwriterRep(_caller, broker, underwriter);
        require(underwriterRep || brokerRep, "must be broker or underwriter");

        dataBool["underwriterApproved"] = underwriterRep;
        dataBool["brokerApproved"] = brokerRep;
    }

    function _isBrokerOrUnderwriterRep(
        address _caller,
        address _broker,
        address _underwriter
    ) internal view returns (bool underwriterRep_, bool brokerRep_) {
        bytes32 ctxSystem = acl().getContextAtIndex(0);
        bytes32 ctxBroker = AccessControl(_broker).aclContext();
        bytes32 ctxUnderwriter = AccessControl(_underwriter).aclContext();

        // entity has underwriter role in system context?
        bool isUnderwriter = acl().hasRoleInGroup(ctxSystem, _underwriter, ROLEGROUP_UNDERWRITERS);

        // caller is underwriter entity rep?
        underwriterRep_ = isUnderwriter && acl().hasRoleInGroup(ctxUnderwriter, _caller, ROLEGROUP_ENTITY_REPS);

        // entity has broker role in system context?
        bool isBroker = acl().hasRoleInGroup(ctxSystem, _broker, ROLEGROUP_BROKERS);

        // caller is broker entity rep?
        brokerRep_ = isBroker && acl().hasRoleInGroup(ctxBroker, _caller, ROLEGROUP_ENTITY_REPS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IDiamondUpgradeFacet.sol";
import "./IAccessControl.sol";
import "./ISettingsControl.sol";
import "./IChild.sol";
import "./ISimplePolicyStates.sol";
import "./ISimplePolicyApprovalsFacet.sol";
import "./ISimplePolicyCommissionsFacet.sol";
import "./ISimplePolicyHeartbeatFacet.sol";

/**
 * @dev Super-interface for Simple Policies
 */
abstract contract ISimplePolicy is
    IDiamondUpgradeFacet,
    IAccessControl,
    ISettingsControl,
    IChild,
    ISimplePolicyStates,
    ISimplePolicyApprovalsFacet,
    ISimplePolicyCommissionsFacet,
    ISimplePolicyHeartbeatFacet
{
    /**
     * @dev Get simple policy info.
     */
    function getSimplePolicyInfo()
        external
        view
        virtual
        returns (
            bytes32 id_,
            uint256 number_,
            uint256 startDate_,
            uint256 maturationDate_,
            address unit_,
            uint256 limit_,
            uint256 state_,
            address treasury_
        );

    /**
     * @dev Heartbeat: Ensure the policy and tranche states are up-to-date.
     *
     */
    function checkAndUpdateState() external virtual returns (bool reduceTotalLimit_);

    //   /**
    //  * @dev Verify simple policy.
    //  *
    //  * @param _id Unique id that represents the policy - this is what stakeholder will sign to approve the policy.
    //  */
    // function verifySimplePolicy (bytes32 _id ) external;

    /**
     * @dev take commissions for the premium paid
     *
     * @param _amount total premium amount paid
     */
    function takeCommissions(uint256 _amount) external virtual returns (uint256 netPremiumAmount_);

    /**
     * @dev Get the commission balances for the simple policy.
     */
    function getCommissionBalances()
        external
        view
        virtual
        returns (
            uint256 brokerCommissionBalance_,
            uint256 claimsAdminCommissionBalance_,
            uint256 naymsCommissionBalance_,
            uint256 underwriterCommissionBalance_
        );

    function payCommissions() external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Base contract for any upgradeable contract that wishes to store data.
 */
contract EternalStorage {
    // scalars
    mapping(string => address) dataAddress;
    mapping(string => bytes32) dataBytes32;
    mapping(string => int256) dataInt256;
    mapping(string => uint256) dataUint256;
    mapping(string => bool) dataBool;
    mapping(string => string) dataString;
    mapping(string => bytes) dataBytes;
    // arrays
    mapping(string => address[]) dataManyAddresses;
    mapping(string => bytes32[]) dataManyBytes32s;
    mapping(string => int256[]) dataManyInt256;
    mapping(string => uint256[]) dataManyUint256;

    // helpers
    function __i(uint256 i1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, s));
    }

    function __a(address a1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, s));
    }

    function __aa(
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, a2, s));
    }

    function __b(bytes32 b1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(b1, s));
    }

    function __ii(
        uint256 i1,
        uint256 i2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, i2, s));
    }

    function __ia(
        uint256 i1,
        address a1,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, s));
    }

    function __iaa(
        uint256 i1,
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, s));
    }

    function __iaaa(
        uint256 i1,
        address a1,
        address a2,
        address a3,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, a3, s));
    }

    function __ab(address a1, bytes32 b1) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, b1));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IDiamondUpgradeFacet.sol";
import "./IAccessControl.sol";
import "./ISettingsControl.sol";
import "./IMarketCoreFacet.sol";
import "./IMarketDataFacet.sol";

abstract contract IMarket is IDiamondUpgradeFacet, IAccessControl, ISettingsControl, IMarketCoreFacet, IMarketDataFacet {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IParent.sol";
import "./EternalStorage.sol";

/**
 * @dev Base class for of contracts that create other contracts and wish to keep track of them.
 */
abstract contract Parent is EternalStorage, IParent {
    function getNumChildren() public view override returns (uint256) {
        return dataUint256["numChildContracts"];
    }

    function getChild(uint256 _index) public view override returns (address) {
        return dataAddress[__i(_index, "childContract")];
    }

    function hasChild(address _child) public view override returns (bool) {
        return dataBool[__a(_child, "isChildContract")];
    }

    /**
     * @dev Add a child contract to the list.
     *
     * @param _child address of child contract.
     */
    function _addChild(address _child) internal {
        dataBool[__a(_child, "isChildContract")] = true;
        dataUint256["numChildContracts"] += 1;
        dataAddress[__i(dataUint256["numChildContracts"], "childContract")] = _child;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Market fee schedules
 */
abstract contract IMarketFeeSchedules {
    /**
     * @dev Standard fee is charged.
     */
    uint256 public constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 public constant FEE_SCHEDULE_PLATFORM_ACTION = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./ISettingsControl.sol";
import "./ISettingsKeys.sol";

/**
 * @dev Base contract for interacting with Settings.
 */
contract SettingsControl is EternalStorage, ISettingsControl, ISettingsKeys {
    /**
     * @dev Constructor.
     * @param _settings Settings address.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
    }

    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() public view override returns (ISettings) {
        return ISettings(dataAddress["settings"]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./Address.sol";
import "./EternalStorage.sol";
import "./ISettings.sol";
import "./IACL.sol";
import "./IAccessControl.sol";
import "./IACLConstants.sol";

/**
 * @dev Base contract for interacting with the ACL.
 */
contract AccessControl is EternalStorage, IAccessControl, IACLConstants {
    using Address for address;

    /**
     * @dev Constructor.
     * @param _settings Address of Settings.
     */
    constructor(address _settings) {
        dataAddress["settings"] = _settings;
        dataBytes32["aclContext"] = acl().generateContextFromAddress(address(this));
    }

    /**
     * @dev Check that sender is an admin.
     */
    modifier assertIsAdmin() {
        require(isAdmin(msg.sender), "must be admin");
        _;
    }

    modifier assertBelongsToEntityWithRole(address _user, bytes32 _role) {
        require(_belongsToEntityWithRole(_user, _role), "not a rep of associated entity");
        _;
    }

    function _belongsToEntityWithRole(address _user, bytes32 _role) internal view returns (bool) {
        address entity = _getEntityWithRole(_role);
        return _isRepOfEntity(_user, entity);
    }

    function _getEntityWithRole(bytes32 _role) internal view returns (address) {
        address[] memory entities = acl().getUsersForRole(aclContext(), _role);
        require(entities.length > 0, "no entity with role");
        return entities[0];
    }

    function _isRepOfEntity(address _user, address _entity) internal view returns (bool) {
        // check they are a rep
        bytes32 ctx = AccessControl(_entity).aclContext();
        return inRoleGroupWithContext(ctx, _user, ROLEGROUP_ENTITY_REPS);
    }

    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) public view override returns (bool) {
        return acl().isAdmin(_addr);
    }

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) public view override returns (bool) {
        return inRoleGroupWithContext(aclContext(), _addr, _roleGroup);
    }

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) public view override returns (bool) {
        return acl().hasRoleInGroup(_ctx, _addr, _roleGroup);
    }

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() public view override returns (IACL) {
        return ISettings(dataAddress["settings"]).acl();
    }

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() public view override returns (bytes32) {
        return dataBytes32["aclContext"];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettingsKeys.sol";
import "./IACL.sol";

/**
 * @dev Settings.
 */
abstract contract ISettings is ISettingsKeys {
    /**
     * @dev Get ACL.
     */
    function acl() public view virtual returns (IACL);

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddress(address _context, bytes32 _key) public view virtual returns (address);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddress(bytes32 _key) public view virtual returns (address);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddress(
        address _context,
        bytes32 _key,
        address _value
    ) external virtual;

    /**
     * @dev Get an address.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getAddresses(address _context, bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Get an address in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootAddresses(bytes32 _key) public view virtual returns (address[] memory);

    /**
     * @dev Set an address.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setAddresses(
        address _context,
        bytes32 _key,
        address[] calldata _value
    ) external virtual;

    /**
     * @dev Get a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getBool(address _context, bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Get a boolean in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootBool(bytes32 _key) public view virtual returns (bool);

    /**
     * @dev Set a boolean.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setBool(
        address _context,
        bytes32 _key,
        bool _value
    ) external virtual;

    /**
     * @dev Get a number.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getUint256(address _context, bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Get a number in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootUint256(bytes32 _key) public view virtual returns (uint256);

    /**
     * @dev Set a number.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setUint256(
        address _context,
        bytes32 _key,
        uint256 _value
    ) external virtual;

    /**
     * @dev Get a string.
     *
     * @param _context The context.
     * @param _key The key.
     *
     * @return The value.
     */
    function getString(address _context, bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Get a string in the root context.
     *
     * @param _key The key.
     *
     * @return The value.
     */
    function getRootString(bytes32 _key) public view virtual returns (string memory);

    /**
     * @dev Set a string.
     *
     * @param _context The context.
     * @param _key The key.
     * @param _value The value.
     */
    function setString(
        address _context,
        bytes32 _key,
        string memory _value
    ) external virtual;

    /**
     * @dev Get current block time.
     *
     * @return Block time.
     */
    function getTime() external view virtual returns (uint256);

    // events

    /**
     * @dev Emitted when a setting gets updated.
     * @param context The context.
     * @param key The key.
     * @param caller The caller.
     * @param keyType The type of setting which changed.
     */
    event SettingChanged(address indexed context, bytes32 indexed key, address indexed caller, string keyType);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./ISettings.sol";

interface ISettingsControl {
    /**
     * @dev Get Settings reference.
     * @return Settings reference.
     */
    function settings() external view returns (ISettings);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Settings keys.
 */
contract ISettingsKeys {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant SETTING_MARKET = 0x6f244974cc67342b1bd623d411fd8100ec9eddbac05348e71d1a9296de6264a5;
    bytes32 public constant SETTING_FEEBANK = 0x6a4d660b9f1720511be22f039683db86d0d0d207c2ad9255325630800d4fb539;
    bytes32 public constant SETTING_ETHER_TOKEN = 0xa449044fc5332c1625929b3afecb2f821955279285b4a8406a6ffa8968c1b7cf;
    bytes32 public constant SETTING_ENTITY_IMPL = 0x098afcb3a137a2ba8835fbf7daecb275af5afb3479f12844d5b7bfb8134e7ced;
    bytes32 public constant SETTING_POLICY_IMPL = 0x0e8925aa0bfe65f831f6c9099dd95b0614eb69312630ef3497bee453d9ed40a9;
    bytes32 public constant SETTING_SIMPLE_POLICY_IMPL = 0x770d12e389d70bfd24b0665f4a2c158e8e62c662344fc1c6673989504964d19f;
    bytes32 public constant SETTING_MARKET_IMPL = 0xc72bfe3e0f1799ce0d90c4c72cf8f07d0cfa8121d51cb05d8c827f0896d8c0b6;
    bytes32 public constant SETTING_FEEBANK_IMPL = 0x9574e138325b5c365da8d5cc75cf22323ed6f3ce52fac5621225020a162a4c61;
    bytes32 public constant SETTING_ENTITY_DEPLOYER = 0x1bf52521006d8a3718b0692b7f32c8ee781bfed9e9215eb5b8fc3b34749fb5b5;
    bytes32 public constant SETTING_ENTITY_DELEGATE = 0x063693c9545b949ff498535f9e0aa95ada8e88c062d28e2f219b896e151e1266;
    bytes32 public constant SETTING_POLICY_DELEGATE = 0x5c6c7d4897f0ae38084370e7a61ea386e95c7f54629c0b793a0ac47751f12405;
    bytes32 public constant SETTING_SIMPLE_POLICY_DELEGATE = 0x83453035930126155b4308a2bb28b2dfbd2428519cf16ac1ea949560edda702f;
    // END: Generated by script outputConstants.js
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL (Access Control List).
 */
interface IACL {
    // admin

    /**
     * @dev Check if given address has the admin role.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Assign admin role to given address.
     * @param _addr Address to assign to.
     */
    function addAdmin(address _addr) external;

    /**
     * @dev Remove admin role from given address.
     * @param _addr Address to remove from.
     */
    function removeAdmin(address _addr) external;

    // contexts

    /**
     * @dev Get the no. of existing contexts.
     * @return no. of contexts
     */
    function getNumContexts() external view returns (uint256);

    /**
     * @dev Get context at given index.
     * @param _index Index into list of all contexts.
     * @return context name
     */
    function getContextAtIndex(uint256 _index) external view returns (bytes32);

    /**
     * @dev Get the no. of addresses belonging to (i.e. who have been assigned roles in) the given context.
     * @param _context Name of context.
     * @return no. of addresses
     */
    function getNumUsersInContext(bytes32 _context) external view returns (uint256);

    /**
     * @dev Get the address at the given index in the list of addresses belonging to the given context.
     * @param _context Name of context.
     * @param _index Index into the list of addresses
     * @return the address
     */
    function getUserInContextAtIndex(bytes32 _context, uint256 _index) external view returns (address);

    // users

    /**
     * @dev Get the no. of contexts the given address belongs to (i.e. has an assigned role in).
     * @param _addr Address.
     * @return no. of contexts
     */
    function getNumContextsForUser(address _addr) external view returns (uint256);

    /**
     * @dev Get the contexts at the given index in the list of contexts the address belongs to.
     * @param _addr Address.
     * @param _index Index of context.
     * @return Context name
     */
    function getContextForUserAtIndex(address _addr, uint256 _index) external view returns (bytes32);

    /**
     * @dev Get whether given address has a role assigned in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return true if so
     */
    function userSomeHasRoleInContext(bytes32 _context, address _addr) external view returns (bool);

    // role groups

    /**
     * @dev Get whether given address has a role in the given rolegroup in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function hasRoleInGroup(
        bytes32 _context,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Set the roles for the given role group.
     * @param _roleGroup The role group.
     * @param _roles List of roles.
     */
    function setRoleGroup(bytes32 _roleGroup, bytes32[] calldata _roles) external;

    /**
     * @dev Get whether given given name represents a role group.
     * @param _roleGroup The role group.
     * @return true if so
     */
    function isRoleGroup(bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Get the list of roles in the given role group
     * @param _roleGroup The role group.
     * @return role list
     */
    function getRoleGroup(bytes32 _roleGroup) external view returns (bytes32[] memory);

    /**
     * @dev Get the list of role groups which contain given role
     * @param _role The role.
     * @return rolegroup list
     */
    function getRoleGroupsForRole(bytes32 _role) external view returns (bytes32[] memory);

    // roles

    /**
     * @dev Get whether given address has given role in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     * @return either `DOES_NOT_HAVE_ROLE` or one of the `HAS_ROLE_...` constants
     */
    function hasRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external view returns (uint256);

    /**
     * @dev Get whether given address has any of the given roles in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _roles The role list.
     * @return true if so
     */
    function hasAnyRole(
        bytes32 _context,
        address _addr,
        bytes32[] calldata _roles
    ) external view returns (bool);

    /**
     * @dev Assign a role to the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role.
     */
    function assignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Assign a role to the given address in the given context and id.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role.
     */
    // function assignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    function unassignRole(
        bytes32 _context,
        address _addr,
        bytes32 _role
    ) external;

    /**
     * @dev Remove a role from the given address in the given context.
     * @param _context Context name.
     * @param _id Id.
     * @param _addr Address.
     * @param _role The role to unassign.
     */
    // function unassignRoleToId(bytes32 _context, bytes32 _id, address _addr, bytes32 _role) external;

    /**
     * @dev Get all role for given address in the given context.
     * @param _context Context name.
     * @param _addr Address.
     * @return list of roles
     */
    function getRolesForUser(bytes32 _context, address _addr) external view returns (bytes32[] memory);

    /**
     * @dev Get all addresses for given role in the given context.
     * @param _context Context name.
     * @param _role Role.
     * @return list of roles
     */
    function getUsersForRole(bytes32 _context, bytes32 _role) external view returns (address[] memory);

    // who can assign roles

    /**
     * @dev Add given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should be allowed to assign this role.
     */
    function addAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Remove given rolegroup as an assigner for the given role.
     * @param _roleToAssign The role.
     * @param _assignerRoleGroup The role group that should no longer be allowed to assign this role.
     */
    function removeAssigner(bytes32 _roleToAssign, bytes32 _assignerRoleGroup) external;

    /**
     * @dev Get all rolegroups that are assigners for the given role.
     * @param _role The role.
     * @return list of rolegroups
     */
    function getAssigners(bytes32 _role) external view returns (bytes32[] memory);

    /**
   * @dev Get whether given address can assign given role within the given context.

   * @param _context Context name.
   * @param _assigner Assigner address.
   * @param _assignee Assignee address.
   * @param _role The role to assign.
   * @return one of the `CANNOT_ASSIGN...` or `CAN_ASSIGN_...` constants
   */
    function canAssign(
        bytes32 _context,
        address _assigner,
        address _assignee,
        bytes32 _role
    ) external view returns (uint256);

    // utility methods

    /**
     * @dev Generate the context name which represents the given address.
     *
     * @param _addr Address.
     * @return context name.
     */
    function generateContextFromAddress(address _addr) external pure returns (bytes32);

    /**
     * @dev Emitted when a role group gets updated.
     * @param roleGroup The rolegroup which got updated.
     */
    event RoleGroupUpdated(bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role gets assigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got assigned.
     */
    event RoleAssigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role gets unassigned.
     * @param context The context within which the role got assigned.
     * @param addr The address the role got assigned to.
     * @param role The role which got unassigned.
     */
    event RoleUnassigned(bytes32 indexed context, address indexed addr, bytes32 indexed role);

    /**
     * @dev Emitted when a role assigner gets added.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will be able to assign this role.
     */
    event AssignerAdded(bytes32 indexed role, bytes32 indexed roleGroup);

    /**
     * @dev Emitted when a role assigner gets removed.
     * @param role The role that can be assigned.
     * @param roleGroup The rolegroup that will no longer be able to assign this role.
     */
    event AssignerRemoved(bytes32 indexed role, bytes32 indexed roleGroup);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Collection of functions related to the address type
 *
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 */
library Address {
    /**
     * @dev Returns true if `_account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address _account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(_account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address _account) internal pure returns (address payable) {
        return payable(address(uint160(_account)));
    }

    /**
     * @dev Converts an `address` into `string` hex representation.
     * From https://ethereum.stackexchange.com/a/58341/56159
     */
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IACL.sol";

interface IAccessControl {
    /**
     * @dev Check if given address has admin privileges.
     * @param _addr Address to check.
     * @return true if so
     */
    function isAdmin(address _addr) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given role group in the current context.
     * @param _addr Address to check.
     * @param _roleGroup Rolegroup to check against.
     * @return true if so
     */
    function inRoleGroup(address _addr, bytes32 _roleGroup) external view returns (bool);

    /**
     * @dev Check if given address has a role in the given rolegroup in the given context.
     * @param _ctx Context to check against.
     * @param _addr Address to check.
     * @param _roleGroup Role group to check against.
     * @return true if so
     */
    function inRoleGroupWithContext(
        bytes32 _ctx,
        address _addr,
        bytes32 _roleGroup
    ) external view returns (bool);

    /**
     * @dev Get ACL reference.
     * @return ACL reference.
     */
    function acl() external view returns (IACL);

    /**
     * @dev Get current ACL context.
     * @return the context.
     */
    function aclContext() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev ACL Constants.
 */
abstract contract IACLConstants {
    // BEGIN: Generated by script outputConstants.js
    // DO NOT MANUALLY MODIFY THESE VALUES!
    bytes32 public constant ROLE_APPROVED_USER = 0x9c259f9342405d034b902fd5e1bba083f008e305ea4eb6a0dce9ac9a6256b63a;
    bytes32 public constant ROLE_PENDING_UNDERWRITER = 0xad56f8a5432d383c3e2c11b7b248f889e6ec544090486b3623f0f4ae1fad763b;
    bytes32 public constant ROLE_PENDING_BROKER = 0x3bd41a6d84c7de1e9d18694bd113405090439b9e32d5ab69d575821d513d83b5;
    bytes32 public constant ROLE_PENDING_INSURED_PARTY = 0x052b977cd6067e43b9140f08c53a22b88418f4d3ab7bd811716130d5a20cd8a3;
    bytes32 public constant ROLE_PENDING_CLAIMS_ADMIN = 0x325a96ceff51ae6b22de25dd7b4c8b9532dddf936add8ef16fc99219ff666a84;
    bytes32 public constant ROLE_UNDERWRITER = 0x8858a0dfcbfa158449ee0a3b5dae898cecc0746569152b05bbab9526bcc16864;
    bytes32 public constant ROLE_CAPITAL_PROVIDER = 0x428fa9969c6b3fab7bbdac20b73706f1f670a386be0a76d4060c185898b2aa22;
    bytes32 public constant ROLE_BROKER = 0x2623111b4a77e415ab5147aeb27da976c7a27950b6ec4022b4b9e77176266992;
    bytes32 public constant ROLE_INSURED_PARTY = 0x737de6bdef2e959d9f968f058e3e78b7365d4eda8e4023ecac2d51e3dbfb1401;
    bytes32 public constant ROLE_CLAIMS_ADMIN = 0x391db9b692991836c38aedfd24d7f4c9837739d4ee0664fe4ee6892a51e025a7;
    bytes32 public constant ROLE_ENTITY_ADMIN = 0x0922a3d5a8713fcf92ec8607b882fd2fcfefd8552a3c38c726d96fcde8b1d053;
    bytes32 public constant ROLE_ENTITY_MANAGER = 0xcfd13d23f7313d54f3a6d98c505045c58749561dd04531f9f2422a8818f0c5f8;
    bytes32 public constant ROLE_ENTITY_REP = 0xcca1ad0e9fb374bbb9dc3d0cbfd073ef01bd1d01d5a35bd0a93403fbee64318d;
    bytes32 public constant ROLE_POLICY_OWNER = 0x7f7cc8b2bac31c0e372310212be653d159f17ff3c41938a81446553db842afb6;
    bytes32 public constant ROLE_POLICY_CREATOR = 0x1d60d7146dec74c1b1a9dc17243aaa3b56533f607c16a718bcd78d8d852d6e52;
    bytes32 public constant ROLE_SYSTEM_ADMIN = 0xd708193a9c8f5fbde4d1c80a1e6f79b5f38a27f85ca86eccac69e5a899120ead;
    bytes32 public constant ROLE_SYSTEM_MANAGER = 0x807c518efb8285611b15c88a7701e4f40a0e9a38ce3e59946e587a8932410af8;
    bytes32 public constant ROLEGROUP_APPROVED_USERS = 0x9c687089ee5ebd0bc2ba9c954ebc7a0304b4046890b9064e5742c8c6c7afeab2;
    bytes32 public constant ROLEGROUP_CAPITAL_PROVIDERS = 0x2db57b52c5f263c359ba92194f5590b4a7f5fc1f1ca02f10cea531182851fe28;
    bytes32 public constant ROLEGROUP_POLICY_CREATORS = 0xdd53f360aa973c3daf7ff269398ced1ce7713d025c750c443c2abbcd89438f83;
    bytes32 public constant ROLEGROUP_BROKERS = 0x8d632412946eb879ebe5af90230c7db3f6d17c94c0ecea207c97e15fa9bb77c5;
    bytes32 public constant ROLEGROUP_INSURED_PARTYS = 0x65d0db34d07de31cfb8ca9f95dabc0463ce6084a447abb757f682f36ae3682e3;
    bytes32 public constant ROLEGROUP_CLAIMS_ADMINS = 0x5c7c2bcb0d2dfef15c423063aae2051d462fcd269b5e9b8c1733b3211e17bc8a;
    bytes32 public constant ROLEGROUP_ENTITY_ADMINS = 0x251766d8c7c7a6b927647b0f20c99f490db1c283eb0c482446085aaaa44b5e73;
    bytes32 public constant ROLEGROUP_ENTITY_MANAGERS = 0xa33a59233069411012cc12aa76a8a426fe6bd113968b520118fdc9cb6f49ae30;
    bytes32 public constant ROLEGROUP_ENTITY_REPS = 0x610cf17b5a943fc722922fc6750fb40254c24c6b0efd32554aa7c03b4ca98e9c;
    bytes32 public constant ROLEGROUP_POLICY_OWNERS = 0xc59d706f362a04b6cf4757dd3df6eb5babc7c26ab5dcc7c9c43b142f25da10a5;
    bytes32 public constant ROLEGROUP_SYSTEM_ADMINS = 0xab789755f97e00f29522efbee9df811265010c87cf80f8fd7d5fc5cb8a847956;
    bytes32 public constant ROLEGROUP_SYSTEM_MANAGERS = 0x7c23ac65f971ee875d4a6408607fabcb777f38cf73b3d6d891648646cee81f05;
    bytes32 public constant ROLEGROUP_TRADERS = 0x9f4d1dc1107c7d9d9f533f41b5aa5dbbb3b830e3b597338a8aee228ab083eb3a;
    bytes32 public constant ROLEGROUP_UNDERWRITERS = 0x18ecf8d2173ca8a5766fd7dde3bdb54017dc5413dc07cd6ba1785b63e9c62b82;
    // END: Generated by script outputConstants.js

    // used by canAssign() method
    uint256 public constant CANNOT_ASSIGN = 0;
    uint256 public constant CANNOT_ASSIGN_USER_NOT_APPROVED = 100;
    uint256 public constant CAN_ASSIGN_IS_ADMIN = 1;
    uint256 public constant CAN_ASSIGN_IS_OWN_CONTEXT = 2;
    uint256 public constant CAN_ASSIGN_HAS_ROLE = 3;

    // used by hasRole() method
    uint256 public constant DOES_NOT_HAVE_ROLE = 0;
    uint256 public constant HAS_ROLE_CONTEXT = 1;
    uint256 public constant HAS_ROLE_SYSTEM_CONTEXT = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IDiamondFacet.sol";

abstract contract IDiamondUpgradeFacet is IDiamondFacet {
    // IDiamondFacet

    function getSelectors() public pure override returns (bytes memory) {
        return abi.encodePacked(IDiamondUpgradeFacet.upgrade.selector, IDiamondUpgradeFacet.getVersionInfo.selector);
    }

    // methods

    function upgrade(address[] calldata _facets) external virtual;

    function getVersionInfo()
        external
        pure
        virtual
        returns (
            string memory num_,
            uint256 date_,
            string memory hash_
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMarketCoreFacet {
    /**
     * @dev Execute a limit offer with an observer attached.
     *
     * The observer must implement `IMarketObserver`. It will be notified when the order
     * trades and/or gets cancelled.
     *
     * @param _sellToken token to sell.
     * @param _sellAmount amount to sell.
     * @param _buyToken token to buy.
     * @param _buyAmount Amount to buy.
     * @param _feeSchedule Requested fee schedule, one of the `FEE_SCHEDULE_...` constants.
     * @param _notify `IMarketObserver` to notify when a trade takes place and/or order gets cancelled.
     * @param _notifyData Data to pass through to the notified contract.
     *
     * @return >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the
     * return value is the created offer's id.
     */
    function executeLimitOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule,
        address _notify,
        bytes memory _notifyData
    ) external returns (uint256);

    /**
     * @dev Execute a market offer, ensuring the full amount gets sold.
     *
     * This will revert if the full amount could not be sold.
     *
     * @param _sellToken token to sell.
     * @param _sellAmount amount to sell.
     * @param _buyToken token to buy.
     *
     */
    function executeMarketOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken
    ) external;

    /**
     * @dev Buy an offer
     *
     * @param _offerId offer id.
     * @param _amount amount (upto the offer's `buyAmount`) of offer's `buyToken` to buy with.
     */
    function buy(uint256 _offerId, uint256 _amount) external;

    /**
     * @dev Cancel an offer.
     *
     * This will revert the offer is not longer active.
     *
     * @param _offerId offer id.
     */
    function cancel(uint256 _offerId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMarketDataFacet {
    struct OfferState {
        address creator;
        address sellToken;
        uint256 sellAmount;
        uint256 sellAmountInitial;
        address buyToken;
        uint256 buyAmount;
        uint256 buyAmountInitial;
        uint256 averagePrice;
        uint256 feeSchedule;
        address notify;
        bytes notifyData;
        uint256 state;
    }

    /**
     * @dev Get market config.
     *
     * @return dust_ The dist value.
     * @return feeBP_ The fee value in basis points (1 point = 0.01%).
     */
    function getConfig() external view returns (uint256 dust_, uint256 feeBP_);

    /**
     * @dev Set market fee.
     *
     * @param _feeBP The fee value in basis points.
     */
    function setFee(uint256 _feeBP) external;

    /**
     * @dev Calculate the fee that must be paid for placing the given order.
     *
     * Assuming that the given order will be matched immediately to existing orders,
     * this method returns the fee the caller will have to pay as a taker.
     *
     * @param _sellToken The sell unit.
     * @param _sellAmount The sell amount.
     * @param _buyToken The buy unit.
     * @param _buyAmount The buy amount.
     * @param _feeSchedule Fee schedule.
     *
     * @return feeToken_ The unit in which the fees are denominated.
     * @return feeAmount_ The fee required to place the order.
     */
    function calculateFee(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) external view returns (address feeToken_, uint256 feeAmount_);

    /**
     * @dev Simulate a market offer and calculate the final amount bought.
     *
     * This complements the `executeMarketOffer` method and is useful for when you want to display the average
     * trade price to the user prior to executing the transaction. Note that if the requested `_sellAmount` cannot
     * be sold then the function will throw.
     *
     * @param _sellToken The sell unit.
     * @param _sellAmount The sell amount.
     * @param _buyToken The buy unit.
     *
     * @return The amount that would get bought.
     */
    function simulateMarketOffer(
        address _sellToken,
        uint256 _sellAmount,
        address _buyToken
    ) external view returns (uint256);

    /**
     * @dev Get current best offer for given token pair.
     *
     * This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     *
     * @return offer id, or 0 if no current best is available.
     */
    function getBestOfferId(address _sellToken, address _buyToken) external view returns (uint256);

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256);

    /**
     * @dev Get if offer is active.
     *
     * @param _offerId offer id.
     *
     * @return true if active, false otherwise.
     */
    function isActive(uint256 _offerId) external view returns (bool);

    /**
     * @dev Get offer details.
     *
     * @param _offerId offer id.
     *
     * @return _offerState OfferState struct
     *  creator_ owner/creator.
     *  sellToken_ sell token.
     *  sellAmount_ sell amount.
     *  sellAmountInitial_ initial sell amount.
     *  buyToken_ buy token.
     *  buyAmount_ buy amount.
     *  buyAmountInitial_ initial buy amount.
     *  averagePrice_ average price paid.
     *  feeSchedule_ fee schedule.
     *  notify_ Contract to notify when a trade takes place and/or order gets cancelled.
     *  notifyData_ Data to pass through to the notified contract.
     *  state_ offer state.
     */
    function getOffer(uint256 _offerId) external view returns (OfferState memory _offerState);

    /**
     * @dev Get offer ranked siblings in the sorted offer list.
     *
     * @param _offerId offer id.
     *
     * @return nextOfferId_ id of the next offer in the sorted list of offers for this token pair.
     * @return prevOfferId_ id of the previous offer in the sorted list of offers for this token pair.
     */
    function getOfferSiblings(uint256 _offerId) external view returns (uint256 nextOfferId_, uint256 prevOfferId_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Interface for contracts that create other contracts and wish to keep track of them.
 */
interface IParent {
    /**
     * @dev Get the no. of children created.
     */
    function getNumChildren() external view returns (uint256);

    /**
     * @dev Get child at given 1-based index.
     *
     * @param _index index starting at 1.
     *
     * @return The child contract address.
     */
    function getChild(uint256 _index) external view returns (address);

    /**
     * @dev Get whether this contract is the parent/creator of given child.
     *
     * @param _child potential child contract.
     *
     * @return true if so, false otherwise.
     */
    function hasChild(address _child) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./DiamondProxy.sol";

/**
 * @dev Base class for a general proxy contract which uses a singleton delegate instance to resolve the correct diamond facet for a call.
 */
contract Proxy is DiamondProxy {
    function _setDelegateAddress(address _addr) internal {
        dataAddress["delegate"] = _addr;
    }

    function getDelegateAddress() external view returns (address) {
        return dataAddress["delegate"];
    }

    function resolveFacet(bytes4 _sig) public view override returns (address) {
        return DiamondProxy(payable(dataAddress["delegate"])).resolveFacet(_sig);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
import "./IChild.sol";
import "./EternalStorage.sol";

/**
 * @dev Base class for of all child contracts created by `Parent` contracts.
 */
abstract contract Child is EternalStorage, IChild {
    function getParent() public view override returns (address) {
        return dataAddress["parent"];
    }

    /**
     * @dev Set parent contract. This can only be called once.
     *
     * @param _parent address of parent contract.
     */
    function _setParent(address _parent) internal {
        require(dataAddress["parent"] == address(0), "parent already set");
        dataAddress["parent"] = _parent;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./base/EternalStorage.sol";
import "./base/AccessControl.sol";

/**
 * @dev SimplePolicy facet base class
 */
abstract contract SimplePolicyFacetBase is EternalStorage, AccessControl {
    function getSimplePolicyInfo()
        external
        view
        returns (
            bytes32 id_,
            uint256 number_,
            uint256 startDate_,
            uint256 maturationDate_,
            address unit_,
            uint256 limit_,
            uint256 state_,
            address treasury_
        )
    {
        id_ = dataBytes32["id"];
        number_ = dataUint256["number"];
        startDate_ = dataUint256["startDate"];
        maturationDate_ = dataUint256["maturationDate"];
        unit_ = dataAddress["unit"];
        limit_ = dataUint256["limit"];
        state_ = dataUint256["state"];
        treasury_ = dataAddress["treasury"];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Policy states
 */
abstract contract ISimplePolicyStates {
    /**
     * @dev State: The policy has just been created.
     */
    uint256 public constant POLICY_STATE_CREATED = 0;

    /**
     * @dev State: The policy has been approved by all the relevant stakeholders.
     */
    uint256 public constant POLICY_STATE_APPROVED = 1;

    /**
     * @dev State: The policy initial sale has completed and it is now active.
     */
    uint256 public constant POLICY_STATE_ACTIVE = 2;

    /**
     * @dev State: The policy has matured, but there are pending claims.
     */
    uint256 public constant POLICY_STATE_MATURED = 3;

    /**
     * @dev State: The policy got cancelled.
     */
    uint256 public constant POLICY_STATE_CANCELLED = 4;

    // events
    event SimplePolicyStateUpdated(bytes32 id, uint256 indexed state, address indexed caller);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondExample.sol
/******************************************************************************/

import "./DiamondStorageBase.sol";
import "./DiamondCutter.sol";
import "./IDiamondFacet.sol";
import "./IDiamondProxy.sol";

abstract contract DiamondProxy is DiamondStorageBase, IDiamondProxy {
    constructor() {
        DiamondCutter diamondCutter = new DiamondCutter();
        dataAddress["diamondCutter"] = address(diamondCutter);
    }

    // IDiamondProxy

    function registerFacets(address[] memory _facets) public override {
        require(msg.sender == address(this), "external caller not allowed");
        _registerFacets(_facets);
    }

    // Public methods

    function resolveFacet(bytes4 _sig) public view virtual returns (address) {
        DiamondStorage storage ds = diamondStorage();
        return address(bytes20(ds.facets[_sig]));
    }

    // Internal methods

    function _registerFacets(address[] memory _facets) internal {
        bytes[] memory changes = new bytes[](_facets.length);

        for (uint256 i = 0; i < _facets.length; i += 1) {
            IDiamondFacet f = IDiamondFacet(_facets[i]);
            bytes memory selectors = f.getSelectors();
            changes[i] = abi.encodePacked(_facets[i], selectors);
        }

        _cut(changes);
    }

    // Private methods

    function _cut(bytes[] memory _changes) private {
        bytes memory cutFunction = abi.encodeWithSelector(DiamondCutter.diamondCut.selector, _changes);
        (bool success, ) = dataAddress["diamondCutter"].delegatecall(cutFunction);
        require(success, "Adding functions failed.");
    }

    // Finds facet for function that is called and executes the
    // function if it is found and returns any value.
    fallback() external payable {
        address facet = resolveFacet(msg.sig);
        require(facet != address(0), "Facet not found");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), facet, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondStorageContract.sol
/******************************************************************************/

import "./EternalStorage.sol";

contract DiamondStorageBase is EternalStorage {
    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to the slot in the selectorSlots array.
        // and maps the selectors to the position in the slot.
        // func selector => address facet, uint64 slotsIndex, uint64 slotIndex
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // uint128 numSelectorsInSlot, uint128 selectorSlotsLength
        // selectorSlotsLength is the number of 32-byte slots in selectorSlots.
        // selectorSlotLength is the number of selectors in the last slot of
        // selectorSlots.
        uint256 selectorSlotsLength;
        // tracking initialization state
        // we use this to know whether a call to diamondCut() is part of the initial
        // construction or a later "upgrade" call
        bool initialized;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        // ds_slot = keccak256("diamond.standard.diamond.storage");
        assembly {
            ds.slot := 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondFacet.sol
/******************************************************************************/

import "./DiamondStorageBase.sol";
import "./IDiamondCutter.sol";

contract DiamondCutter is DiamondStorageBase, IDiamondCutter {
    bytes32 constant CLEAR_ADDRESS_MASK = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    bytes32 constant CLEAR_SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    struct SlotInfo {
        uint256 originalSelectorSlotsLength;
        bytes32 selectorSlot;
        uint256 oldSelectorSlotsIndex;
        uint256 oldSelectorSlotIndex;
        bytes32 oldSelectorSlot;
        bool newSlot;
    }

    function diamondCut(bytes[] memory _diamondCut) public override {
        DiamondStorage storage ds = diamondStorage();
        SlotInfo memory slot;
        slot.originalSelectorSlotsLength = ds.selectorSlotsLength;
        uint256 selectorSlotsLength = uint128(slot.originalSelectorSlotsLength);
        uint256 selectorSlotLength = uint128(slot.originalSelectorSlotsLength >> 128);
        if (selectorSlotLength > 0) {
            slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
        }
        // loop through diamond cut
        for (uint256 diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            require(facetCut.length > 20, "Missing facet or selector info.");
            bytes32 currentSlot;
            assembly {
                currentSlot := mload(add(facetCut, 32))
            }
            bytes32 newFacet = bytes20(currentSlot);
            uint256 numSelectors = (facetCut.length - 20) / 4;
            uint256 position = 52;

            // adding or replacing functions
            if (newFacet != 0) {
                // add and replace selectors
                for (uint256 selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut, position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
                    // add
                    if (oldFacet == 0) {
                        ds.facets[selector] = newFacet | (bytes32(selectorSlotLength) << 64) | bytes32(selectorSlotsLength);
                        slot.selectorSlot = (slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> (selectorSlotLength * 32))) | (bytes32(selector) >> (selectorSlotLength * 32));
                        selectorSlotLength++;
                        if (selectorSlotLength == 8) {
                            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
                            slot.selectorSlot = 0;
                            selectorSlotLength = 0;
                            selectorSlotsLength++;
                            slot.newSlot = false;
                        } else {
                            slot.newSlot = true;
                        }
                    }
                    // replace
                    else {
                        require(bytes20(oldFacet) != bytes20(newFacet), "Function cut to same facet.");
                        ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | newFacet;
                    }
                }
            }
            // remove functions
            else {
                for (uint256 selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut, position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
                    require(oldFacet != 0, "Function doesn't exist. Can't remove.");
                    if (slot.selectorSlot == 0) {
                        selectorSlotsLength--;
                        slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
                        selectorSlotLength = 8;
                    }
                    slot.oldSelectorSlotsIndex = uint64(uint256(oldFacet));
                    slot.oldSelectorSlotIndex = uint32(uint256(oldFacet >> 64));
                    bytes4 lastSelector = bytes4(slot.selectorSlot << ((selectorSlotLength - 1) * 32));
                    if (slot.oldSelectorSlotsIndex != selectorSlotsLength) {
                        slot.oldSelectorSlot = ds.selectorSlots[slot.oldSelectorSlotsIndex];
                        slot.oldSelectorSlot =
                            (slot.oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> (slot.oldSelectorSlotIndex * 32))) |
                            (bytes32(lastSelector) >> (slot.oldSelectorSlotIndex * 32));
                        ds.selectorSlots[slot.oldSelectorSlotsIndex] = slot.oldSelectorSlot;
                        selectorSlotLength--;
                    } else {
                        slot.selectorSlot =
                            (slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> (slot.oldSelectorSlotIndex * 32))) |
                            (bytes32(lastSelector) >> (slot.oldSelectorSlotIndex * 32));
                        selectorSlotLength--;
                    }
                    if (selectorSlotLength == 0) {
                        delete ds.selectorSlots[selectorSlotsLength];
                        slot.selectorSlot = 0;
                    }
                    if (lastSelector != selector) {
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                }
            }
        }
        uint256 newSelectorSlotsLength = (selectorSlotLength << 128) | selectorSlotsLength;
        if (newSelectorSlotsLength != slot.originalSelectorSlotsLength) {
            ds.selectorSlotsLength = newSelectorSlotsLength;
        }
        if (slot.newSlot) {
            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
        }
        emit DiamondCut(_diamondCut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IDiamondProxy {
    function registerFacets(address[] calldata _facets) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondHeaders.sol
/******************************************************************************/

interface IDiamondCutter {
    /// @notice _diamondCut is an array of bytes arrays.
    /// This argument is tightly packed for gas efficiency.
    /// That means no padding with zeros.
    /// Here is the structure of _diamondCut:
    /// _diamondCut = [
    ///     abi.encodePacked(facet, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(facet, sel1, sel2, sel4, ...),
    ///     ...
    /// ]
    /// facet is the address of a facet
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    function diamondCut(bytes[] calldata _diamondCut) external;

    event DiamondCut(bytes[] _diamondCut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev The complement to `IParent`.
 */
interface IChild {
    /**
     * @dev Get the parent/creator of this contract.
     */
    function getParent() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Simple Policy approvals methods.
 */
interface ISimplePolicyApprovalsFacet {
    /**
     * @dev Bulk-approve this policy.
     *
     * @param _roles Type of pending role the entity of the caller has.
     * @param _signatures Signatures in order: broker, underwriter, claims admin, insured party
     */
    function approveSimplePolicy(bytes32[] memory _roles, bytes[] memory _signatures) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Simple Policy commissions methods.
 */
interface ISimplePolicyCommissionsFacet {
    /**
     * @dev Get commission rates.
     *
     * @return brokerCommissionBP_ Broker commission basis points.
     * @return claimsAdminCommissionBP_ Claims admin commission basis points.
     * @return naymsCommissionBP_ Nayms commission basis points.
     * @return underwriterCommissionBP_ Underwriter commission basis points.
     */
    function getCommissionRates()
        external
        view
        returns (
            uint256 brokerCommissionBP_,
            uint256 claimsAdminCommissionBP_,
            uint256 naymsCommissionBP_,
            uint256 underwriterCommissionBP_
        );

    /**
     * @dev Get commission balances.
     *
     * @return brokerCommissionBalance_ Broker commission balance.
     * @return claimsAdminCommissionBalance_ Claims admin commission balance.
     * @return naymsCommissionBalance_ Nayms commission balance.
     * @return underwriterCommissionBalance_ Underwriter commission balance.
     */
    function getCommissionBalances()
        external
        view
        returns (
            uint256 brokerCommissionBalance_,
            uint256 claimsAdminCommissionBalance_,
            uint256 naymsCommissionBalance_,
            uint256 underwriterCommissionBalance_
        );

    /**
     * @dev Take commission from supplied amount, in corresponding basis points.
     * This just increases the balance, doesn't actually pay out the commission.
     *
     * @param _amount Premium amount to take commission from.
     *
     * @return netPremiumAmount_ net premium amount after commission.
     */
    function takeCommissions(uint256 _amount) external returns (uint256 netPremiumAmount_);

    /**
     * @dev Zero out commission balances, after paying them out.
     * Entity does the actual transfer, here only balance gets updated.
     */
    function commissionsPayedOut() external;

    /**
     * @dev Get the addresses of stakeholders
     */
    function getStakeholders()
        external
        view
        returns (
            address broker_,
            address underwriter_,
            address claimsAdmin_,
            address feeBank_
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Simple Policy heartbeat methods.
 */
interface ISimplePolicyHeartbeatFacet {
    /**
     * @dev Ensure that the policy state is up-to-date.
     */
    function checkAndUpdateState() external returns (bool reduceTotalLimit_);
}