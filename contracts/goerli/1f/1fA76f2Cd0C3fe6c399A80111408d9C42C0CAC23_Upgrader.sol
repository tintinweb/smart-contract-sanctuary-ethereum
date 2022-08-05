// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISETH} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol";
import {Errors} from "./libs/Errors.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20.sol";

contract Upgrader is AccessControlEnumerable {

    // role identifier for upgrader caller
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_CALLER_ROLE_ID");
    uint8 public constant SUPERTOKEN_DECIMALS = 18;
    ISETH public immutable nativeSuperToken;


    modifier onlyIfNativeSupported() {
        if(address(nativeSuperToken) == address(0)) {
            revert Errors.NativeSuperTokenNotSupported();
        }
        _;
    }

    constructor(address defaultAdmin, address ntSuperToken, address[] memory upgraders) {
        if (defaultAdmin == address(0)) revert Errors.ZeroAddress();
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        nativeSuperToken = ISETH(ntSuperToken);
        for (uint256 i = 0; i < upgraders.length; i++) {
            if (upgraders[i] == address(0)) revert Errors.ZeroAddress();
            _setupRole(UPGRADER_ROLE, upgraders[i]);
        }
    }

    /**
     * @dev Upgrade ERC20 tokens to Super Tokens on behalf of an account.
     * @param superToken Super Token to upgrade to
     * @param account Account for which to upgrade
     * @param amount Amount of ERC20 tokens to be upgraded
     * @notice For the call to succeed, this contract needs to have sufficient allowance on the underlying ERC20 tokens.
     * @notice If `msg.sender` equals `account`, it doesn't need to have the upgrader role.
     */
    function upgrade(
        ISuperToken superToken,
        address account,
        uint256 amount
    )
        external
    {
        if (msg.sender != account && !hasRole(UPGRADER_ROLE, msg.sender)) {
           revert Errors.OperationNotAllowed();
        }

        // We first transfer ERC20 tokens from the given account to this contract ...
        IERC20WithDecimals erc20Token = IERC20WithDecimals(superToken.getUnderlyingToken());
        if (address(erc20Token) == address(0)) {
            revert Errors.SuperTokenNotUnderlying();
        }
        uint256 beforeBalance = superToken.balanceOf(address(this));
        if (!erc20Token.transferFrom(account, address(this), amount)) {
            revert Errors.ERC20TransferFromRevert();
        }
        // ... then upgrade them to Super Tokens, scaling the amount in case decimals differ ...
        erc20Token.approve(address(superToken), amount);
        superToken.upgrade(_toSuperTokenAmount(amount, erc20Token.decimals()));
        
        // ... then transfer the newly minted Super Tokens to the account
        if (!superToken.transfer(account, superToken.balanceOf(address(this)) - beforeBalance)) {
            revert Errors.ERC20TransferRevert();
        }
    }

    /**
     * @dev Downgrade Super Tokens to ERC20 tokens on behalf of an account.
     * @param superToken Super Token to downgrade - must be included in `supportedSuperTokens`
     * @param account Account for which to downgrade
     * @param amount Amount of Super Tokens to be downgraded
     * @notice For the call to succeed, this contract needs to have sufficient allowance on the Super Token.
     * @notice If `msg.sender` equals `account`, it doesn't need to have the upgrader role.
     */
    function downgrade(
        ISuperToken superToken,
        address account,
        uint256 amount
    )
        external
    {
        if (msg.sender != account && !hasRole(UPGRADER_ROLE, msg.sender)) {
            revert Errors.OperationNotAllowed();
        }

        // We first transfer Super Tokens from the given account to this contract ...
        if (!superToken.transferFrom(account, address(this), amount)) {
            revert Errors.ERC20TransferFromRevert();
        }
        // ... then downgrade them to ERC20 tokens ...
        IERC20WithDecimals erc20Token = IERC20WithDecimals(superToken.getUnderlyingToken());
        uint256 beforeBalance = erc20Token.balanceOf(address(this));
        superToken.downgrade(amount);

        // then transfer the unwrapped ERC20 tokens to the account, scaling the amount in case decimals differ
        if (!erc20Token.transfer(account, erc20Token.balanceOf(address(this)) - beforeBalance)) {
            revert Errors.ERC20TransferRevert();
        }
    }

    /**
     * @dev Upgrade Native Coin to Super Tokens.
     */
    function upgradeByETH() external payable onlyIfNativeSupported {
        _upgradeByETH();
    }

    /**
     * @dev Downgrade Super Tokens to Native Coin.
     * @param wad Amount of Super Tokens to be downgraded
     * @notice For the call to succeed, this contract needs to have sufficient allowance on the Super Token.
     */
    function downgradeToETH(uint256 wad) external onlyIfNativeSupported {
        uint256 beforeBalance = address(this).balance;

        // We first transfer Super Tokens from the given account to this contract ...
        if (!nativeSuperToken.transferFrom(msg.sender, address(this), wad)) {
            revert Errors.ERC20TransferFromRevert();
        }
        nativeSuperToken.downgradeToETH(wad);
        payable(msg.sender).transfer(address(this).balance - beforeBalance);
    }

    // fallback function which mints Super Tokens for received ETH
    receive() external payable onlyIfNativeSupported {
        if(msg.sender != address(nativeSuperToken)) {
            _upgradeByETH();
        }
    }

    // upgrade coin to Native Super Token
    function _upgradeByETH() internal {
        uint256 beforeBalance = nativeSuperToken.balanceOf(address(this));
        nativeSuperToken.upgradeByETH{value: msg.value }();
        // ... then transfer the newly minted Super Tokens to the account
        if (!nativeSuperToken.transfer(msg.sender, nativeSuperToken.balanceOf(address(this)) - beforeBalance)) {
            revert Errors.ERC20TransferRevert();
        }
    }

    // converts erc20 amount based o2n the given er20 decimals to Super Token amount
    function _toSuperTokenAmount(uint256 amount, uint8 decimals)
        private pure
        returns (uint256 adjustedAmount)
    {
        if (decimals < SUPERTOKEN_DECIMALS) {
            adjustedAmount = amount * (10 ** (SUPERTOKEN_DECIMALS - decimals));
        } else if (decimals > SUPERTOKEN_DECIMALS) {
            adjustedAmount = amount / (10 ** (decimals - SUPERTOKEN_DECIMALS));
        } else {
            adjustedAmount = amount;
        }
    }

    /******************
     * ADMIN INTERFACE
     ******************/

    /**
     * @dev Allows admin to add address to upgrader role
     * @param newUpgradeCaller address
     */
    function addUpgrader(address newUpgradeCaller) external {
        if (newUpgradeCaller == address(0)) revert Errors.OperationNotAllowed();
        grantRole(UPGRADER_ROLE, newUpgradeCaller);
    }

    /**
     * @dev Allows admin to remove address from upgrader role
     * @param oldUpgradeCaller address
     */
    function revokeUpgrader(address oldUpgradeCaller) external {
        revokeRole(UPGRADER_ROLE, oldUpgradeCaller);
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperfluidGovernance } from "./ISuperfluidGovernance.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperTokenFactory } from "./ISuperTokenFactory.sol";
import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperApp } from "./ISuperApp.sol";
import {
    BatchOperation,
    ContextDefinitions,
    FlowOperatorDefinitions,
    SuperAppDefinitions,
    SuperfluidGovernanceConfigs
} from "./Definitions.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

/**
 * @title Host interface
 * @author Superfluid
 * NOTE:
 * This is the central contract of the system where super agreement, super app
 * and super token features are connected.
 *
 * The Superfluid host contract is also the entry point for the protocol users,
 * where batch call and meta transaction are provided for UX improvements.
 *
 */
interface ISuperfluid {

    /**************************************************************************
     * Time
     *
     * > The Oracle: You have the sight now, Neo. You are looking at the world without time.
     * > Neo: Then why can't I see what happens to her?
     * > The Oracle: We can never see past the choices we don't understand.
     * >       - The Oracle and Neo conversing about the future of Trinity and the effects of Neo's choices
     *************************************************************************/

    function getNow() external view returns (uint256);

    /**************************************************************************
     * Governance
     *************************************************************************/

    /**
     * @dev Get the current governance address of the Superfluid host
     */
    function getGovernance() external view returns(ISuperfluidGovernance governance);

    /**
     * @dev Replace the current governance with a new one
     */
    function replaceGovernance(ISuperfluidGovernance newGov) external;
    /**
     * @dev Governance replaced event
     * @param oldGov Address of the old governance contract
     * @param newGov Address of the new governance contract
     */
    event GovernanceReplaced(ISuperfluidGovernance oldGov, ISuperfluidGovernance newGov);

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    /**
     * @dev Register a new agreement class to the system
     * @param agreementClassLogic Initial agreement class code
     *
     * Modifiers:
     *  - onlyGovernance
     */
    function registerAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class registered event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type registered
     * @param code Address of the new agreement
     */
    event AgreementClassRegistered(bytes32 agreementType, address code);

    /**
    * @dev Update code of an agreement class
    * @param agreementClassLogic New code for the agreement class
    *
    * Modifiers:
    *  - onlyGovernance
    */
    function updateAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class updated event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type updated
     * @param code Address of the new agreement
     */
    event AgreementClassUpdated(bytes32 agreementType, address code);

    /**
    * @notice Check if the agreement type is whitelisted
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function isAgreementTypeListed(bytes32 agreementType) external view returns(bool yes);

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementClassListed(ISuperAgreement agreementClass) external view returns(bool yes);

    /**
    * @notice Get agreement class
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function getAgreementClass(bytes32 agreementType) external view returns(ISuperAgreement agreementClass);

    /**
    * @dev Map list of the agreement classes using a bitmap
    * @param bitmap Agreement class bitmap
    */
    function mapAgreementClasses(uint256 bitmap)
        external view
        returns (ISuperAgreement[] memory agreementClasses);

    /**
    * @notice Create a new bitmask by adding a agreement class to it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**
    * @notice Create a new bitmask by removing a agreement class from it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**************************************************************************
    * Super Token Factory
    **************************************************************************/

    /**
     * @dev Get the super token factory
     * @return factory The factory
     */
    function getSuperTokenFactory() external view returns (ISuperTokenFactory factory);

    /**
     * @dev Get the super token factory logic (applicable to upgradable deployment)
     * @return logic The factory logic
     */
    function getSuperTokenFactoryLogic() external view returns (address logic);

    /**
     * @dev Update super token factory
     * @param newFactory New factory logic
     */
    function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;
    /**
     * @dev SuperToken factory updated event
     * @param newFactory Address of the new factory
     */
    event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);

    /**
     * @notice Update the super token logic to the latest
     * @dev Refer to ISuperTokenFactory.Upgradability for expected behaviours
     */
    function updateSuperTokenLogic(ISuperToken token) external;
    /**
     * @dev SuperToken logic updated event
     * @param code Address of the new SuperToken logic
     */
    event SuperTokenLogicUpdated(ISuperToken indexed token, address code);

    /**************************************************************************
     * App Registry
     *************************************************************************/

    /**
     * @dev Message sender declares it as a super app
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     */
    function registerApp(uint256 configWord) external;
    /**
     * @dev App registered event
     * @param app Address of jailed app
     */
    event AppRegistered(ISuperApp indexed app);

    /**
     * @dev Message sender declares it as a super app, using a registration key
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     * @param registrationKey The registration key issued by the governance
     */
    function registerAppWithKey(uint256 configWord, string calldata registrationKey) external;

    /**
     * @dev Message sender declares app as a super app
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     * NOTE: only factory contracts authorized by governance can register super apps
     */
    function registerAppByFactory(ISuperApp app, uint256 configWord) external;

    /**
     * @dev Query if the app is registered
     * @param app Super app address
     */
    function isApp(ISuperApp app) external view returns(bool);

    /**
     * @dev Query app level
     * @param app Super app address
     */
    function getAppLevel(ISuperApp app) external view returns(uint8 appLevel);

    /**
     * @dev Get the manifest of the super app
     * @param app Super app address
     */
    function getAppManifest(
        ISuperApp app
    )
        external view
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        );

    /**
     * @dev Query if the app has been jailed
     * @param app Super app address
     */
    function isAppJailed(ISuperApp app) external view returns (bool isJail);

    /**
     * @dev Whitelist the target app for app composition for the source app (msg.sender)
     * @param targetApp The target super app address
     */
    function allowCompositeApp(ISuperApp targetApp) external;

    /**
     * @dev Query if source app is allowed to call the target app as downstream app
     * @param app Super app address
     * @param targetApp The target super app address
     */
    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view
        returns (bool isAppAllowed);

    /**************************************************************************
     * Agreement Framework
     *
     * Agreements use these function to trigger super app callbacks, updates
     * app allowance and charge gas fees.
     *
     * These functions can only be called by registered agreements.
     *************************************************************************/

    /**
     * @dev (For agreements) StaticCall the app before callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return cbdata            Data returned from the callback.
     */
    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory cbdata);

    /**
     * @dev (For agreements) Call the app after callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return newCtx
     */
    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory newCtx);

    /**
     * @dev (For agreements) Create a new callback stack
     * @param  ctx                     The current ctx, it will be validated.
     * @param  app                     The super app.
     * @param  appAllowanceGranted     App allowance granted so far.
     * @param  appAllowanceUsed        App allowance used so far.
     * @return newCtx
     */
    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appAllowanceGranted,
        int256 appAllowanceUsed,
        ISuperfluidToken appAllowanceToken
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Pop from the current app callback stack
     * @param  ctx                     The ctx that was pushed before the callback stack.
     * @param  appAllowanceUsedDelta   App allowance used by the app.
     * @return newCtx
     *
     * [SECURITY] NOTE:
     * - Here we cannot do assertValidCtx(ctx), since we do not really save the stack in memory.
     * - Hence there is still implicit trust that the agreement handles the callback push/pop pair correctly.
     */
    function appCallbackPop(
        bytes calldata ctx,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Use app allowance.
     * @param  ctx                      The current ctx, it will be validated.
     * @param  appAllowanceWantedMore   See app allowance for more details.
     * @param  appAllowanceUsedDelta    See app allowance for more details.
     * @return newCtx
     */
    function ctxUseAllowance(
        bytes calldata ctx,
        uint256 appAllowanceWantedMore,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Jail the app.
     * @param  app                     The super app.
     * @param  reason                  Jail reason code.
     * @return newCtx
     */
    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev Jail event for the app
     * @param app Address of jailed app
     * @param reason Reason the app is jailed (see Definitions.sol for the full list)
     */
    event Jail(ISuperApp indexed app, uint256 reason);

    /**************************************************************************
     * Contextless Call Proxies
     *
     * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
     * with agreements or apps.
     *
     * NOTE: The contextual call data should be generated using
     * abi.encodeWithSelector. The context parameter should be set to "0x",
     * an empty bytes array as a placeholder to be replaced by the host
     * contract.
     *************************************************************************/

     /**
      * @dev Call agreement function
      * @param agreementClass The agreement address you are calling
      * @param callData The contextual call data with placeholder ctx
      * @param userData Extra user data being sent to the super app callbacks
      */
     function callAgreement(
         ISuperAgreement agreementClass,
         bytes calldata callData,
         bytes calldata userData
     )
        external
        //cleanCtx
        //isAgreement(agreementClass)
        returns(bytes memory returnedData);

    /**
     * @notice Call app action
     * @dev Main use case is calling app action in a batch call via the host
     * @param callData The contextual call data
     *
     * NOTE: See "Contextless Call Proxies" above for more about contextual call data.
     */
    function callAppAction(
        ISuperApp app,
        bytes calldata callData
    )
        external
        //cleanCtx
        //isAppActive(app)
        //isValidAppAction(callData)
        returns(bytes memory returnedData);

    /**************************************************************************
     * Contextual Call Proxies and Context Utilities
     *
     * For apps, they must use context they receive to interact with
     * agreements or apps.
     *
     * The context changes must be saved and returned by the apps in their
     * callbacks always, any modification to the context will be detected and
     * the violating app will be jailed.
     *************************************************************************/

    /**
     * @dev Context Struct
     *
     * NOTE on backward compatibility:
     * - Non-dynamic fields are padded to 32bytes and packed
     * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
     * - The order of the fields hence should not be rearranged in order to be backward compatible:
     *    - non-dynamic fields will be parsed at the same memory location,
     *    - and dynamic fields will simply have a greater offset than it was.
     */
    struct Context {
        //
        // Call context
        //
        // callback level
        uint8 appLevel;
        // type of call
        uint8 callType;
        // the system timestamp
        uint256 timestamp;
        // The intended message sender for the call
        address msgSender;

        //
        // Callback context
        //
        // For callbacks it is used to know which agreement function selector is called
        bytes4 agreementSelector;
        // User provided data for app callbacks
        bytes userData;

        //
        // App context
        //
        // app allowance granted
        uint256 appAllowanceGranted;
        // app allowance wanted by the app callback
        uint256 appAllowanceWanted;
        // app allowance used, allowing negative values over a callback session
        int256 appAllowanceUsed;
        // app address
        address appAddress;
        // app allowance in super token
        ISuperfluidToken appAllowanceToken;
    }

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // onlyAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData);

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // isAppActive(app)
        returns (bytes memory newCtx);

    function decodeCtx(bytes calldata ctx)
        external pure
        returns (Context memory context);

    function isCtxValid(bytes calldata ctx) external view returns (bool);

    /**************************************************************************
    * Batch call
    **************************************************************************/
    /**
     * @dev Batch operation data
     */
    struct Operation {
        // Operation type. Defined in BatchOperation (Definitions.sol)
        uint32 operationType;
        // Operation target
        address target;
        // Data specific to the operation
        bytes data;
    }

    /**
     * @dev Batch call function
     * @param operations Array of batch operations
     */
    function batchCall(Operation[] memory operations) external;

    /**
     * @dev Batch call function for trusted forwarders (EIP-2771)
     * @param operations Array of batch operations
     */
    function forwardBatchCall(Operation[] memory operations) external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * TODO: turning these off because solidity-coverage doesn't like it
     *************************************************************************/

     /* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev Require the ctx being valid.
     modifier requireValidCtx(bytes memory ctx) virtual;

     /// @dev Assert the ctx being valid.
     modifier assertValidCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperToken } from "../superfluid/ISuperToken.sol";


/**
 * @title Super ETH (SETH) custom token interface
 * @author Superfluid
 */
interface ISETHCustom {
    // using native token
    function upgradeByETH() external payable;
    function upgradeByETHTo(address to) external payable;
    function downgradeToETH(uint wad) external;
}

/**
 * @title Super ETH (SETH) full interface
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface ISETH is ISETHCustom, ISuperToken {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    error SuperTokenRequired();
    error NativeSuperTokenNotSupported();
    error ZeroAddress();
    error OperationNotAllowed();
    error SuperTokenNotUnderlying();
    error ERC20TransferRevert();
    error ERC20TransferFromRevert();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20WithDecimals {
    /**
         * @dev Returns the decimals of token.
     */
    function decimals() external view returns (uint8);

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperfluidToken  } from "./ISuperfluidToken.sol";
import { ISuperfluid } from "./ISuperfluid.sol";


/**
 * @title Superfluid governance interface
 * @author Superfluid
 */
interface ISuperfluidGovernance {

    /**
     * @dev Replace the current governance with a new governance
     */
    function replaceGovernance(
        ISuperfluid host,
        address newGov) external;

    /**
     * @dev Register a new agreement class
     */
    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass) external;

    /**
     * @dev Update logics of the contracts
     *
     * NOTE:
     * - Because they might have inter-dependencies, it is good to have one single function to update them all
     */
    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    ) external;

    /**
     * @dev Update supertoken logic contract to the latest that is managed by the super token factory
     */
    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens) external;
    
    /**
     * @dev Set configuration as address value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    ) external;
    
    /**
     * @dev Set configuration as uint256 value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @dev Clear configuration
     */
    function clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    ) external;

    /**
     * @dev Get configuration as address value
     */
    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (address value);

    /**
     * @dev Get configuration as uint256 value
     */
    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (uint256 value);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";


/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {

    /**************************************************************************
     * Basic information
     *************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /**
     * @dev Encoded liquidation type data mainly used for handling stack to deep errors
     *
     * Note:
     * - version: 1
     * - liquidationType key:
     *    - 0 = reward account receives reward (PIC period)
     *    - 1 = liquidator account receives reward (Pleb period)
     *    - 2 = liquidator account receives reward (Pirate period/bailout)
     */
    struct LiquidationTypeData {
        uint256 version;
        uint8 liquidationType;
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /**
    * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
    * @param account for the query
    * @param timestamp Time of balance
    * @return availableBalance Real-time balance
    * @return deposit Account deposit
    * @return owedDeposit Account owed Deposit
    */
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit);

    /**
     * @notice Calculate the realtime balance given the current host.getNow() value
     * @dev realtimeBalanceOf with timestamp equals to block timestamp
     * @param account for the query
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOfNow(
       address account
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp);

    /**
    * @notice Check if account is critical
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @param timestamp The time we'd like to check if the account is critical (should use future)
    * @return isCritical Whether the account is critical
    */
    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isCritical);

    /**
    * @notice Check if account is critical now (current host.getNow())
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @return isCritical Whether the account is critical
    */
    function isAccountCriticalNow(
        address account
    )
        external view
        returns(bool isCritical);

    /**
     * @notice Check if account is solvent
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is solvent (should use future)
     * @return isSolvent
     */
    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isSolvent);

    /**
     * @notice Check if account is solvent now
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @return isSolvent
     */
    function isAccountSolventNow(
        address account
    )
        external view
        returns(bool isSolvent);

    /**
    * @notice Get a list of agreements that is active for the account
    * @dev An active agreement is one that has state for the account
    * @param account Account to query
    * @return activeAgreements List of accounts that have non-zero states for the account
    */
    function getAccountActiveAgreements(address account)
       external view
       returns(ISuperAgreement[] memory activeAgreements);


   /**************************************************************************
    * Super Agreement hosting functions
    *************************************************************************/

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement created event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementCreated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view
        returns(bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement updated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementUpdated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external;
    /**
     * @dev Agreement terminated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */
    event AgreementTerminated(
        address indexed agreementClass,
        bytes32 id
    );

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * NOTE
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external;
    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */
    event AgreementStateUpdated(
        address indexed agreementClass,
        address indexed account,
        uint256 slotId
    );

    /**
     * @dev Get data of the slot of the state of an agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view
        returns (bytes32[] memory slotData);

    /**
     * @notice Settle balance from an account by the agreement
     * @dev The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * Modifiers:
     *  - onlyAgreement
     */
    function settleBalance(
        address account,
        int256 delta
    )
        external;

    /**
     * @dev Make liquidation payouts (v2)
     * @param id Agreement ID
     * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
     * @param targetAccount Account of the stream sender
     * @param rewardAmount The amount the reward recepient account will receive
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     *
     * - If a bailout is required (bailoutAmount > 0)
     *   - the actual reward (single deposit) goes to the executor,
     *   - while the reward account becomes the bailout account
     *   - total bailout include: bailout amount + reward amount
     *   - the targetAccount will be bailed out
     * - If a bailout is not required
     *   - the targetAccount will pay the rewardAmount
     *   - the liquidator (reward account in PIC period) will receive the rewardAmount
     *
     * Modifiers:
     *  - onlyAgreement
     */
    function makeLiquidationPayoutsV2
    (
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount,
        bool useDefaultRewardAccount,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external;
    /**
     * @dev Agreement liquidation event v2 (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param targetAccount Account of the stream sender
     * @param rewardAccount Account that collects the reward or bails out insolvent accounts
     * @param rewardAmount The amount the reward recipient account balance should change by
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
     *
     * NOTE:
     * Reward account rule:
     * - if the agreement is liquidated during the PIC period
     *   - the rewardAccount will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
     *   - the targetAccount will pay for the rewardAmount
     * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
     *   - the liquidatorAccount will get the rewardAmount (remaining deposit)
     *   - the targetAccount will pay for the rewardAmount
     * - if the targetAccount is insolvent
     *   - the liquidatorAccount will get the rewardAmount (single deposit)
     *   - the rewardAccount will pay for both the rewardAmount and bailoutAmount
     *   - the targetAccount will receive the bailoutAmount
     */
    event AgreementLiquidatedV2(
        address indexed agreementClass,
        bytes32 id,
        address indexed liquidatorAccount,
        address indexed targetAccount,
        address rewardAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta,
        bytes liquidationTypeData
    );

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *************************************************************************/

     /// @dev The msg.sender must be host contract
     //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

    /**************************************************************************
     * DEPRECATED
     *************************************************************************/

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     *
     * NOTE:
     *
     * [DEPRECATED] Use AgreementLiquidatedV2 instead
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     *
     * NOTE:
     *
     * [DEPRECATED] Use AgreementLiquidatedV2 instead
     */
    event Bailout(
        address indexed bailoutAccount,
        uint256 bailoutAmount
    );

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * NOTE:
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperfluid } from "./ISuperfluid.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {

    /**
     * @dev Initialize the contract
     */
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    ) external;

    /**************************************************************************
    * TokenInfo & ERC777
    *************************************************************************/

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: SuperToken always uses 18 decimals.
     *
     * Note: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(TokenInfo) returns (uint8);

    /**************************************************************************
    * ERC20 & ERC777
    *************************************************************************/

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns(uint256 balance);

    /**************************************************************************
    * ERC20
    *************************************************************************/

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}. This is
     *         zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external override(IERC20) view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
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
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's
     *         allowance.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**************************************************************************
    * ERC777
    *************************************************************************/

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     *         means all token operations (creation, movement and destruction) must have
     *         amounts that are a multiple of this number.
     *
     * For super token contracts, this value is 1 always
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev If send or receive hooks are registered for the caller and `recipient`,
     *      the corresponding functions will be called with `data` and empty
     *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external override(IERC777) view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external override(IERC777) view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    /**
     * @dev Mint new tokens for the account
     *
     * Modifiers:
     *  - onlySelf
     */
    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    ) external;

   /**
    * @dev Burn existing tokens for the account
    *
    * Modifiers:
    *  - onlySelf
    */
   function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
   ) external;

   /**
    * @dev Transfer `amount` tokens from the `sender` to `recipient`.
    * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
    * spend tokens of `sender`.
    *
    * Modifiers:
    *  - onlySelf
    */
   function selfTransferFrom(
        address sender,
        address spender,
        address recipient,
        uint256 amount
   ) external;

   /**
    * @dev Give `spender`, `amount` allowance to spend the tokens of
    * `account`.
    *
    * Modifiers:
    *  - onlySelf
    */
   function selfApproveFor(
        address account,
        address spender,
        uint256 amount
   ) external;

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns(address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * NOTE: It will use ´transferFrom´ to get tokens. Before calling this
     * function you should ´approve´ this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to received upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * NOTE: It will use ´transferFrom´ to get tokens. Before calling this
     * function you should ´approve´ this contract
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are upgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

    /**************************************************************************
    * Batch Operations
    *************************************************************************/

    /**
    * @dev Perform ERC20 approve by host contract.
    * @param account The account owner to be approved.
    * @param spender The spender of account owner's funds.
    * @param amount Number of tokens to be approved.
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationApprove(
        address account,
        address spender,
        uint256 amount
    ) external;

    /**
    * @dev Perform ERC20 transfer from by host contract.
    * @param account The account to spend sender's funds.
    * @param spender  The account where the funds is sent from.
    * @param recipient The recipient of thefunds.
    * @param amount Number of tokens to be transferred.
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    ) external;

    /**
    * @dev Upgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be upgraded (in 18 decimals)
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationUpgrade(address account, uint256 amount) external;

    /**
    * @dev Downgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be downgraded (in 18 decimals)
    *
    * Modifiers:
    *  - onlyHost
    */
    function operationDowngrade(address account, uint256 amount) external;


    /**************************************************************************
    * Function modifiers for access control and parameter validations
    *
    * While they cannot be explicitly stated in function definitions, they are
    * listed in function definition comments instead for clarity.
    *
    * NOTE: solidity-coverage not supporting it
    *************************************************************************/

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperToken } from "./ISuperToken.sol";

import {
    IERC20,
    ERC20WithTokenInfo
} from "../tokens/ERC20WithTokenInfo.sol";

/**
 * @title Super token factory interface
 * @author Superfluid
 */
interface ISuperTokenFactory {

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /// @dev Initialize the contract
    function initialize() external;

    /**
     * @dev Get the current super token logic used by the factory
     */
    function getSuperTokenLogic() external view returns (ISuperToken superToken);

    /**
     * @dev Upgradability modes
     */
    enum Upgradability {
        /// Non upgradable super token, `host.updateSuperTokenLogic` will revert
        NON_UPGRADABLE,
        /// Upgradable through `host.updateSuperTokenLogic` operation
        SEMI_UPGRADABLE,
        /// Always using the latest super token logic
        FULL_UPGRADABE
    }

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token
     * @param underlyingToken Underlying ERC20 token
     * @param underlyingDecimals Underlying token decimals
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     */
    function createERC20Wrapper(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token with extra token info
     * @param underlyingToken Underlying ERC20 token
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     *
     * NOTE:
     * - It assumes token provide the .decimals() function
     */
    function createERC20Wrapper(
        ERC20WithTokenInfo underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external;

    /**
      * @dev Super token logic created event
      * @param tokenLogic Token logic address
      */
    event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

    /**
      * @dev Super token created event
      * @param token Newly created super token address
      */
    event SuperTokenCreated(ISuperToken indexed token);

    /**
      * @dev Custom super token created event
      * @param token Newly created custom super token address
      */
    event CustomSuperTokenCreated(ISuperToken indexed token);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {

    /**
     * @dev Get the type of the agreement class
     */
    function agreementType() external view returns (bytes32);

    /**
     * @dev Calculate the real-time balance for the account of this agreement class
     * @param account Account the state belongs to
     * @param time Time used for the calculation
     * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
     * @return deposit Account deposit amount of this agreement
     * @return owedDeposit Account owed deposit amount of this agreement
     */
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        );

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperToken } from "./ISuperToken.sol";

/**
 * @title SuperApp interface
 * @author Superfluid
 * @dev Be aware of the app being jailed, when the word permitted is used.
 *
 */
interface ISuperApp {

    /**
     * @dev Callback before a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * NOTE:
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
     * @dev Callback after a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param cbdata The data returned from the before-hook callback.
     * @param ctx The context data.
     * @return newCtx The current context of the transaction.
     *
     * NOTE:
     * - State changes is permitted.
     * - Only revert with a "reason" is permitted.
     */
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
     * @dev Callback before a new agreement is updated.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * NOTE:
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);


    /**
    * @dev Callback after a new agreement is updated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * NOTE:
    * - State changes is permitted.
    * - Only revert with a "reason" is permitted.
    */
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
    * @dev Callback before a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param ctx The context data.
    * @return cbdata A free format in memory data the app can use to pass
    *          arbitary information to the after-hook callback.
    *
    * NOTE:
    * - It will be invoked with `staticcall`, no state changes are permitted.
    * - Revert is not permitted.
    */
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
    * @dev Callback after a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * NOTE:
    * - State changes is permitted.
    * - Revert is not permitted.
    */
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

/**
 * @title Super app definitions library
 * @author Superfluid
 */
library SuperAppDefinitions {

    /**************************************************************************
    / App manifest config word
    /**************************************************************************/

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 constant internal APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 constant internal APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 constant internal APP_LEVEL_SECOND = 1 << 1;

    function getAppLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 constant internal APP_JAIL_BIT = 1 << 15;
    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**************************************************************************
    / Callback implementation bit masks
    /**************************************************************************/
    uint256 constant internal AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 constant internal BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 constant internal AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 constant internal BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 constant internal AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 constant internal BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 constant internal AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**************************************************************************
    / App Jail Reasons
    /**************************************************************************/

    uint256 constant internal APP_RULE_REGISTRATION_ONLY_IN_CONSTRUCTOR = 1;
    uint256 constant internal APP_RULE_NO_REGISTRATION_FOR_EOA = 2;
    uint256 constant internal APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 constant internal APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 constant internal APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 constant internal APP_RULE_CTX_IS_READONLY = 20;
    uint256 constant internal APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 constant internal APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 constant internal APP_RULE_MAX_APP_LEVEL_REACHED = 40;

    // Validate configWord cleaness for future compatibility, or else may introduce undefined future behavior
    function isConfigWordClean(uint256 configWord) internal pure returns (bool) {
        return (configWord & ~(APP_LEVEL_MASK | APP_JAIL_BIT | AGREEMENT_CALLBACK_NOOP_BITMASKS)) == uint256(0);
    }
}

/**
 * @title Context definitions library
 * @author Superfluid
 */
library ContextDefinitions {

    /**************************************************************************
    / Call info
    /**************************************************************************/

    // app level
    uint256 constant internal CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 constant internal CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 constant internal CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 constant internal CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo)
        internal pure
        returns (uint8 appLevel, uint8 callType)
    {
        appLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appLevel, uint8 callType)
        internal pure
        returns (uint256 callInfo)
    {
        return uint256(appLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }

}

/**
 * @title Flow Operator definitions library
  * @author Superfluid
 */
 library FlowOperatorDefinitions {
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_CREATE = uint8(1) << 0;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_UPDATE = uint8(1) << 1;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_DELETE = uint8(1) << 2;
    uint8 constant internal AUTHORIZE_FULL_CONTROL =
        AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE;
    uint8 constant internal REVOKE_FLOW_OPERATOR_CREATE = ~(uint8(1) << 0);
    uint8 constant internal REVOKE_FLOW_OPERATOR_UPDATE = ~(uint8(1) << 1);
    uint8 constant internal REVOKE_FLOW_OPERATOR_DELETE = ~(uint8(1) << 2);

    function isPermissionsClean(uint8 permissions) internal pure returns (bool) {
        return (
            permissions & ~(AUTHORIZE_FLOW_OPERATOR_CREATE
                | AUTHORIZE_FLOW_OPERATOR_UPDATE
                | AUTHORIZE_FLOW_OPERATOR_DELETE)
            ) == uint8(0);
    }
 }

/**
 * @title Batch operation library
 * @author Superfluid
 */
library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes calldata, bytes userdata)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
}

/**
 * @title Superfluid governance configs library
 * @author Superfluid
 */
library SuperfluidGovernanceConfigs {

    bytes32 constant internal SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");
    bytes32 constant internal CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");
    bytes32 constant internal SUPERTOKEN_MINIMUM_DEPOSIT_KEY = 
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.trustedForwarder",
            forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
            deployer,
            registrationKey));
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.factory",
            factory));
    }

    function decodePPPConfig(uint256 pppConfig) internal pure returns (uint256 liquidationPeriod, uint256 patricianPeriod) {
        liquidationPeriod = (pppConfig >> 32) & type(uint32).max;
        patricianPeriod = pppConfig & type(uint32).max;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

/**
 * @title ERC20 token info interface
 * @author Superfluid
 * @dev ERC20 standard interface does not specify these functions, but
 *      often the token implementations have them.
 */
interface TokenInfo {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInfo } from "./TokenInfo.sol";

/**
 * @title ERC20 token with token info interface
 * @author Superfluid
 * @dev Using abstract contract instead of interfaces because old solidity
 *      does not support interface inheriting other interfaces
 * solhint-disable-next-line no-empty-blocks
 *
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {}