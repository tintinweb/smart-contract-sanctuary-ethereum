/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./BaseVaultUpgradeable.sol";
import "../library/PercentageUtils.sol";

/**
    @title InvestmentVault

    @author Roberto Cano <robercano>
    
    @notice Investment Vault contract that implements an investment strategy via the configured actions in the vault

    @dev The responsibility of the Vault is to accept immediate deposits and withdrawals while the vault is in the Unlocked state.
    Then when the position is entered, it executes the investment actions in the configured order. If all actions succeed,
    then the Vault is Locked and no more deposits or withdrawals are allowed. The moment the position can be exited, the vault
    exits the position of all actions, also in order, and receives back the remaining funds, including profit or loss

    TODO: Explain the current version of the vault in detail
    
    @dev See {BaseVaultUpgradeable}
 */

contract InvestmentVault is BaseVaultUpgradeable {
    using PercentageUtils for uint256;
    using SafeERC20 for IERC20;

    /// ERRORS
    error InvestmentTotalTooHigh(uint256 actualAmountInvested, uint256 maxAmountToInvest);

    /**
        @inheritdoc IVault
     */
    function enterPosition() external onlyOperator onlyUnlocked nonReentrant {
        _setLifecycleState(LifecycleState.Locked);

        uint256 totalPrincipalAmount = totalAssets();

        uint256 maxAmountToInvest = getTotalPrincipalPercentages().applyPercentage(totalPrincipalAmount);
        uint256 actualAmountInvested = 0;
        address investmentAsset = asset();

        uint256 numActions = getActionsLength();

        for (uint256 i = 0; i < numActions; i++) {
            IAction action = getAction(i);

            uint256 amountToInvest = getPrincipalPercentage(i).applyPercentage(totalPrincipalAmount);

            IERC20(investmentAsset).safeApprove(address(action), amountToInvest);

            action.enterPosition(investmentAsset, amountToInvest);

            actualAmountInvested += amountToInvest;
        }

        if (actualAmountInvested > maxAmountToInvest) {
            revert InvestmentTotalTooHigh(actualAmountInvested, maxAmountToInvest);
        }

        emit VaultPositionEntered(totalPrincipalAmount, actualAmountInvested);
    }

    /**
        @inheritdoc IVault
     */
    function exitPosition() external onlyOperator onlyLocked nonReentrant returns (uint256 newPrincipalAmount) {
        address investmentAsset = asset();

        uint256 totalAmountReturned = 0;

        uint256 numActions = getActionsLength();

        for (uint256 i = 0; i < numActions; i++) {
            IAction action = getAction(i);

            totalAmountReturned += action.exitPosition(investmentAsset);

            IERC20(investmentAsset).safeApprove(address(action), 0);
        }

        _setLifecycleState(LifecycleState.Unlocked);

        newPrincipalAmount = totalAssets();

        // TODO: Apply fees here

        emit VaultPositionExited(newPrincipalAmount);
    }

    /**
        @inheritdoc IVault
     */
    function canPositionBeExited() external view returns (bool canExit) {
        uint256 numActions = getActionsLength();

        for (uint256 i = 0; i < numActions; i++) {
            IAction action = getAction(i);

            if (!action.canPositionBeExited(asset())) {
                return false;
            }
        }

        assert(getLifecycleState() == LifecycleState.Locked);

        return true;
    }

    /**
        @inheritdoc IVault
     */
    function canPositionBeEntered() external view returns (bool canEnter) {
        uint256 numActions = getActionsLength();

        for (uint256 i = 0; i < numActions; i++) {
            IAction action = getAction(i);

            if (!action.canPositionBeEntered(asset())) {
                return false;
            }
        }

        assert(getLifecycleState() == LifecycleState.Unlocked);

        return true;
    }

    /**
        @inheritdoc ERC4626Upgradeable
     */
    function deposit(uint256 assets, address receiver) public override onlyUnlocked returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /**
        @inheritdoc ERC4626Upgradeable
    */
    function mint(uint256 shares, address receiver) public override onlyUnlocked returns (uint256) {
        return super.mint(shares, receiver);
    }

    /**
        @inheritdoc ERC4626Upgradeable
    */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override onlyUnlocked returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    /**
        @inheritdoc ERC4626Upgradeable
    */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override onlyUnlocked returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../common/EmergencyLockUpgradeable.sol";
import "../common/LifecycleStatesUpgradeable.sol";
import "../common/RefundsHelperUpgreadable.sol";
import "../common/RolesManagerUpgradeable.sol";
import "../extensions/ERC4626CapUpgradeable.sol";
import "./FeeManagerUpgradeable.sol";
import "./ActionsManagerUpgradeable.sol";
import "../interfaces/IVault.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
    @title BaseVaultUpgradeable

    @author Roberto Cano <robercano>
    
    @notice Base contract for the Vault contract. It serves as a commonplace to take care of
    the inheritance order and the storage order of the contracts, as this is very important
    to keep consistent in order to be able to upgrade the contracts. The order of the contracts
    is also important to not break the C3 lineralization of the inheritance hierarchy.

    @dev Some of the contracts in the base hierarchy contain storage gaps to account for upgrades
    needed in those contracts. Those gaps allow to add new storage variables without shifting
    variables down the inheritance chain down. The gap is not used here and instead the versioned
    interfaces approach is chosen because it is more explicit.

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract

    @dev The separation between the base vault and the vault itself is based on the upgradeability
    of the contracts. Up to this point all contracts support upgradeability by allocating gaps in
    their storage definitions. Or not allocating gaps, in which case the storage of that particular
    contract cannot be updated. The main vault contract will inherit first from the base vault,
    and then use the versioning contracts to expand its storage in case it is needed.
 */

abstract contract BaseVaultUpgradeable is
    RolesManagerUpgradeable, // Making explicit inheritance here, although it is not necessary
    ERC4626CapUpgradeable,
    EmergencyLockUpgradeable,
    LifecycleStatesUpgradeable,
    RefundsHelperUpgreadable,
    FeeManagerUpgradeable,
    ActionsManagerUpgradeable,
    ReentrancyGuardUpgradeable,
    IVault
{
    // UPGRADEABLE INITIALIZER

    /**
        @notice Takes care of the initialization of all the contracts hierarchy. Any changes
        to the hierarchy will require to review this function to make sure that no initializer
        is called twice, and most importantly, that all initializers are called here

        @param adminAddress The address of the admin of the Vault
        @param strategistAddress The address of the strategist of the Vault
        @param operatorAddress The address of the operator of the Vault
        @param underlyingAsset The address of the asset managed by this vault
        @param underlyingAssetCap The cap on the amount of principal that the vault can manage
        @param managementFee The fee percentage charged for the management of the Vault
        @param performanceFee The fee percentage charged for the performance of the Vault
        @param feesRecipient The address of the account that will receive the fees
        @param actions The list of investment actions to be executed in the Vault
     */
    function initialize(
        address adminAddress,
        address strategistAddress,
        address operatorAddress,
        address underlyingAsset,
        uint256 underlyingAssetCap,
        uint256 managementFee,
        uint256 performanceFee,
        address payable feesRecipient,
        IAction[] calldata actions,
        uint256[] calldata principalPercentages
    ) external initializer {
        // Prepare the list of tokens that are not allowed to be refunded. In particular the underlying
        // asset is not allowed to be refunded to prevent the admin from accidentally refunding the
        // underlying asset
        address[] memory cannotRefundToken = new address[](1);
        cannotRefundToken[0] = underlyingAsset;

        __RolesManager_init_unchained(adminAddress, strategistAddress, operatorAddress);
        __ERC4626Cap_init_unchained(underlyingAssetCap, underlyingAsset);
        __EmergencyLock_init_unchained();
        __LifecycleStates_init_unchained();
        __RefundsHelper_init_unchained(cannotRefundToken, false);
        __FeeManager_init_unchained(managementFee, performanceFee, feesRecipient);
        __ActionsManager_init_unchained(actions, principalPercentages);
        __ReentrancyGuard_init_unchained();
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title PercentageUtils

    @author Roberto Cano <robercano>
    
    @notice Utility library to apply a slippage percentage to an input amount
 */
library PercentageUtils {
    /**
        @notice The number of decimals used for the slippage percentage
     */
    uint256 public constant PERCENTAGE_DECIMALS = 6;

    /**
        @notice The factor used to scale the slippage percentage when calculating the slippage
        on an amount
     */
    uint256 public constant PERCENTAGE_FACTOR = 10**PERCENTAGE_DECIMALS;

    /**
        @notice Percentage of 100% with the given `PERCENTAGE_DECIMALS`
     */
    uint256 public constant PERCENTAGE_100 = 100 * PERCENTAGE_FACTOR;

    /**
        @notice Adds the percentage to the given amount and returns the result
        
        @return The amount after the percentage is applied

        @dev It performs the following operation:
            (100.0 + percentage) * amount
     */
    function addPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return applyPercentage(amount, PERCENTAGE_100 + percentage);
    }

    /**
        @notice Substracts the percentage from the given amount and returns the result
        
        @return The amount after the percentage is applied

        @dev It performs the following operation:
            (100.0 - percentage) * amount
     */
    function substractPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return applyPercentage(amount, PERCENTAGE_100 - percentage);
    }

    /**
        @notice Applies the given percentage to the given amount and returns the result

        @param amount The amount to apply the percentage to
        @param percentage The percentage to apply to the amount

        @return The amount after the percentage is applied
     */
    function applyPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        // TODO: used Math.mulDiv when it is released
        return (amount * percentage) / PERCENTAGE_100;
    }

    /**
        @notice Checks if the given percentage is in range, this is, if it is between 0 and 100

        @param percentage The percentage to check

        @return True if the percentage is in range, false otherwise
     */
    function isPercentageInRange(uint256 percentage) internal pure returns (bool) {
        return percentage <= PERCENTAGE_100;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { RolesManagerUpgradeable } from "./RolesManagerUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice See { IEmergencyLock }

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables
 */

contract EmergencyLockUpgradeable is RolesManagerUpgradeable, PausableUpgradeable, IEmergencyLock {
    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Unchained initializer

        @dev This contract does not need to initialize anything for itself. This contract
        replaces the Pausable contract. The Pausable contracts MUST NOT be used anywhere
        else in the inheritance chain. Assuming this, we can safely initialize the Pausable
        contract here

        @dev The name of the init function is marked as `_unchained` because we assume that the
        Pausable contract is not used anywhere else, and thus the functionality is that of an
        unchained initialization

        @dev The RolesManager contract MUST BE initialized in the Vault/Action contract as it
        it shared among other helper contracts
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EmergencyLock_init_unchained() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    // FUNCTIONS

    /**
        @inheritdoc IEmergencyLock

        @dev Only functions marked with the `whenPaused` modifier will be executed
        when the contract is paused

        @dev This function can only be called when the contract is Unpaused
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
        @inheritdoc IEmergencyLock

        @dev Only functions marked with the `whenUnpaused` modifier will be executed
        when the contract is unpaused

        @dev This function can only be called when the contract is Paused
     */
    function unpause() external onlyAdmin {
        _unpause();
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../interfaces/ILifecycleStates.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
    @title LifecycleStatesUpgradeable

    @author Roberto Cano <robercano>
    
    @notice See { ILifecycleStates }

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables. The LifecycleState enumeration
    can be safely extended without affecting the storage
 */

contract LifecycleStatesUpgradeable is Initializable, ILifecycleStates {
    /// STORAGE

    /**
         @notice The current state of the vault
     */
    LifecycleState private _state;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Initializes the current state to Unlocked

        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize the RolesManagerUpgradeable contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __LifecycleStates_init_unchained() internal onlyInitializing {
        _state = LifecycleState.Unlocked;
    }

    /// MODIFIERS

    /**
        @notice Modifier to scope functions to only be accessible when the state is Unlocked
     */
    modifier onlyUnlocked() {
        require(_state == LifecycleState.Unlocked, "State is not Unlocked");
        _;
    }

    /**
        @notice Modifier to scope functions to only be accessible when the state is Committed
     */
    modifier onlyCommitted() {
        require(_state == LifecycleState.Committed, "State is not Commited");
        _;
    }

    /**
        @notice Modifier to scope functions to only be accessible when the state is Locked
     */
    modifier onlyLocked() {
        require(_state == LifecycleState.Locked, "State is not Locked");
        _;
    }

    /// FUNCTIONS

    /**
        @notice Function to set the new state of the vault
        @param newState The new state of the vault
     */
    function _setLifecycleState(LifecycleState newState) internal {
        LifecycleState prevState = _state;

        _state = newState;

        emit LifecycleStateChanged(prevState, newState);
    }

    /**
        @inheritdoc ILifecycleStates
     */
    function getLifecycleState() public view returns (LifecycleState) {
        return _state;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { RolesManagerUpgradeable } from "./RolesManagerUpgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable as Address } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
    @title RefundsHelperUpgreadable

    @author Roberto Cano <robercano>
    
    @notice See { IRefundsHelper}

    @dev It inherits from the RolesManagerUpgradeable contract to scope the refund functions
    for only the Admin role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the vault. The initialization will happen in the Vault and
    Action contract

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables
 */

contract RefundsHelperUpgreadable is RolesManagerUpgradeable, IRefundsHelper {
    using Address for address payable;

    /// STORAGE

    /**
        @notice The list of tokens that cannot be refunded

        @dev The list is populated at construction time and cannot be changed. For this purpose it
        is private and there is no setter function for it
    */
    mapping(address => bool) private _cannotRefund;

    /**
        @notice Flag to indicate if ETH can be refunded or not

        @dev The flag is set at initialization time and cannot be changed afterwards. For this
        purpose it is private and there is no setter function for it
    */
    bool private _cannotRefundETH;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Marks the given token addresses as `non-refundable`

        @param _cannotRefundToken The list of token addresses that cannot be refunded

        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize the RolesManagerUpgradeable contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __RefundsHelper_init_unchained(address[] memory _cannotRefundToken, bool cannotRefundETH_)
        internal
        onlyInitializing
    {
        for (uint256 i = 0; i < _cannotRefundToken.length; i++) {
            _cannotRefund[_cannotRefundToken[i]] = true;
        }

        _cannotRefundETH = cannotRefundETH_;
    }

    /// FUNCTIONS

    /**
        @inheritdoc IRefundsHelper

        @dev This function can be only called by the admin and only if the token is not in the
        list of tokens that cannot be refunded.
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external onlyAdmin {
        require(!_cannotRefund[token], "Token cannot be refunded");
        require(recipient != address(0), "Recipient address cannot be the null address");

        SafeERC20.safeTransfer(IERC20(token), recipient, amount);
    }

    /**
        @inheritdoc IRefundsHelper

        @dev This function can be only called by the admin and only if ETH is allowed to be
        refunded
     */
    function refundETH(uint256 amount, address payable recipient) external onlyAdmin {
        require(!_cannotRefundETH, "ETH cannot be refunded");
        require(recipient != address(0), "Recipient address cannot be the null address");

        recipient.sendValue(amount);
    }

    /// GETTERS

    /**
        @inheritdoc IRefundsHelper
     */
    function canRefund(address token) public view returns (bool) {
        return !_cannotRefund[token];
    }

    /**
        @inheritdoc IRefundsHelper
     */
    function canRefundETH() public view returns (bool) {
        return !_cannotRefundETH;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
    @title RolesManagerUpgradeable

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states


    @dev It provides a functionality similar to the AccessControl contract from OpenZeppelin. The decision
    to implement the roles manually was made to avoid exposiing a higher attack surface area coming from 
    the AccessControl contract, plus reducing the size of the deployment as well

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`

    @dev This contract is intended to be always initialized in an unchained way as it may be shared
    among different helper contracts that need to scope their functions to the Admin or Keeper role.
 */

contract RolesManagerUpgradeable is Initializable, ContextUpgradeable, IRolesManager {
    // STORAGE

    /**
        @notice The address of the admin role

        @dev The admin role is the only role that can change the other roles, including the Admin itself
     */
    address private _adminAddress;

    /**
        @notice The address of the strategist role

        @dev The strategist role is the one that can change the vault and action parameters related to the
        investment strategy. Things like slippage percentage, maximum premium, principal percentages, etc...
     */
    address private _strategistAddress;

    /**
        @notice The address of the operator role

        @dev The operator role is the one that can cycle the vault and the action through its different states
     */
    address private _operatorAddress;

    /**
        @notice The address of the vault

        @dev The vault address is used in the actions to only allow the vault to call enterPosition and exitPosition
     */
    address private _vaultAddress;

    /// MODIFIERS

    /**
      @notice Modifier to scope functions to only be accessible by the Admin
     */
    modifier onlyAdmin() {
        require(_msgSender() == _adminAddress, "Only the Admin can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Strategist
     */
    modifier onlyStrategist() {
        require(_msgSender() == _strategistAddress, "Only the Strategist can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Operator
     */
    modifier onlyOperator() {
        require(_msgSender() == _operatorAddress, "Only the Operator can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Vault
     */
    modifier onlyVault() {
        require(_msgSender() == _vaultAddress, "Only the Vault can call this function");
        _;
    }

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice This does not chain the initialization to the parent contract.
        Also this contract does not need to initialize anything itself.

        @dev The Vault role is not initialized here. Instead, the admin must call
             `changeVault` to set the vault role address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __RolesManager_init_unchained(
        address adminAddress,
        address strategistAddress,
        address operatorAddress
    ) internal onlyInitializing {
        __changeAdmin(adminAddress);
        __changeStrategist(strategistAddress);
        __changeOperator(operatorAddress);
    }

    /// FUNCTIONS

    /**
        @inheritdoc IRolesManager

        @dev Only the previous Admin can change the address to a new one
     */
    function changeAdmin(address newAdminAddress) external onlyAdmin {
        __changeAdmin(newAdminAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeStrategist(address newStrategistAddress) external onlyAdmin {
        __changeStrategist(newStrategistAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeOperator(address newOperatorAddress) external onlyAdmin {
        __changeOperator(newOperatorAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeVault(address newVaultAddress) external onlyAdmin {
        __changeVault(newVaultAddress);
    }

    /**
        @inheritdoc IRolesManager
     */
    function getAdmin() public view returns (address) {
        return _adminAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getStrategist() public view returns (address) {
        return _strategistAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getOperator() public view returns (address) {
        return _operatorAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getVault() public view returns (address) {
        return _vaultAddress;
    }

    /// INTERNALS

    /**
        @notice See { changeAdmin }
     */
    function __changeAdmin(address newAdminAddress) private {
        require(newAdminAddress != address(0), "New Admin address cannot be the null address");

        address prevAdminAddress = _adminAddress;

        _adminAddress = newAdminAddress;

        emit AdminChanged(prevAdminAddress, newAdminAddress);
    }

    /**
        @notice See { changeStrategist }
     */
    function __changeStrategist(address newStrategistAddress) private {
        require(newStrategistAddress != address(0), "New Strategist address cannot be the null address");

        address prevStrategistAddress = _strategistAddress;

        _strategistAddress = newStrategistAddress;

        emit StrategistChanged(prevStrategistAddress, newStrategistAddress);
    }

    /**
        @notice See { changeOperator }
     */
    function __changeOperator(address newOperatorAddress) private {
        require(newOperatorAddress != address(0), "New Operator address cannot be the null address");

        address prevOperatorAddress = _operatorAddress;

        _operatorAddress = newOperatorAddress;

        emit OperatorChanged(prevOperatorAddress, newOperatorAddress);
    }

    /**
        @notice See { changeVault }
     */
    function __changeVault(address newVaultAddress) private {
        require(newVaultAddress != address(0), "New Vault address cannot be the null address");

        address prevVaultAddress = _vaultAddress;

        _vaultAddress = newVaultAddress;

        emit VaultChanged(prevVaultAddress, newVaultAddress);
    }

    /**
       @dev This empty reserved space is put in place to allow future versions to add new
       variables without shifting down storage in the inheritance chain.
       See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     
       @dev The size of the gap plus the size of the storage variables defined
       above must equal 50 storage slots
     */
    uint256[46] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { RolesManagerUpgradeable } from "../common/RolesManagerUpgradeable.sol";
import { ERC4626Upgradeable } from "../openzeppelin/ERC4626Upgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
    @title ERC4626CapUpgradeable

    @author Roberto Cano <robercano>
    
    @notice Adds a cap to the amount of principal that the vault can manage, thus imposing
    a restriction on deposits and mints

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables
 */

contract ERC4626CapUpgradeable is ERC4626Upgradeable, RolesManagerUpgradeable {
    //STORAGE

    /**
        @notice Maximum amount of principal that the vault can manage
     */
    uint256 private _cap;

    // EVENTS
    event VaultCapChanged(uint256 indexed prevCap, uint256 indexed newCap);

    // UPGRADEABLE INITIALIZER

    /**
        @notice Unchained initializer

        @dev This contract replaces the ERC4626Upgradeable contract. The ERC4626Upgradeable 
        contracts MUST NOT be used anywhere else in the inheritance chain. Assuming this,
        we can safely initialize the ERC4626Upgradeable contract here

        @dev The name of the init function is marked as `_unchained` because we assume that the
        ERC4626Upgradeable contract is not used anywhere else, and thus the functionality is 
        that of an unchained initialization

        @dev The RolesManager contract MUST BE initialized in the Vault/Action contract as it
        it shared among other helper contracts
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ERC4626Cap_init_unchained(uint256 cap_, address asset_) internal onlyInitializing {
        __ERC4626_init_unchained(IERC20MetadataUpgradeable(asset_));

        _setVaultCap(cap_);
    }

    // FUNCTIONS

    /**
        @notice Updates the cap for the vault principal

        @param newCap New cap for the vault principal

        @dev Can only be called by the Admin
     */
    function setVaultCap(uint256 newCap) external onlyAdmin {
        _setVaultCap(newCap);
    }

    /**
        @notice Returns the current cap for the vault principal

        @return Current cap for the vault principal
     */
    function getVaultCap() external view returns (uint256) {
        return _cap;
    }

    /**
        @notice Returns the maximum amount of principal that a user can deposit into the vault at
        this moment. This is a function of the vault cap and the amount of principal that the vault
        is currently managing. As we don't want the vault to manage more than `_cap`, the
        value returned here is the difference between the cap and the current amount of principal when
        the cap is higher than the principal. It will return 0 otherwise

        @param receiver The receiver of the shares after the deposit. Only used to call the parent's
        `maxDeposit`

        @dev The only input parameter is unnamed because it is not used in the function
     */
    function maxDeposit(address receiver) public view virtual override returns (uint256) {
        // First check if the OZ ERC4626 vault allows deposits at this time. It usually has an edge
        // case in which deposits are disabled and we want to abide by that logic. Getting the minimum here
        // ensures that we get either 0 or the amount defined in principal Cap
        uint256 currentCap = Math.min(super.maxDeposit(receiver), _cap);

        //
        if (currentCap < totalAssets()) {
            return 0;
        }

        return currentCap - totalAssets();
    }

    /**
        @notice Returns the maximum amount of shares that can be minted, taking into account the
        current deposit cap

        @param receiver The receiver of the shares after the minting. Only used to call the parent's
        maxMint

        @dev If the total number of assets is grater than the cap then no more shares can be minted

        @dev The maximum number of shares is calculated from the maximum amount of principal that can
        still be deposited in the vault. This calculation rounds down to the nearest integer, ensuring
        than requesting to mint that number of shares will always require an amount equal or less than
        the current existing deposit cap
     */
    function maxMint(address receiver) public view virtual override returns (uint256) {
        if (_cap < totalAssets()) {
            return 0;
        }

        uint256 maxAssetsAmount = Math.min(super.maxMint(receiver), _cap - totalAssets());

        return _convertToShares(maxAssetsAmount);
    }

    /// INTERNALS

    /**
        @notice See { setVaultCap }
     */
    function _setVaultCap(uint256 newCap) internal {
        uint256 prevCap = _cap;

        _cap = newCap;

        emit VaultCapChanged(prevCap, newCap);
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { RolesManagerUpgradeable } from "../common/RolesManagerUpgradeable.sol";
import "../library/PercentageUtils.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable as Address } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
    @title FeeManagerUpgradeable

    @author Roberto Cano <robercano>
    
    @notice Handles the fees that the vault pays-off to the Keeper

    @dev See { IFeeManager }

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract
 */

contract FeeManagerUpgradeable is RolesManagerUpgradeable, IFeeManager {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using PercentageUtils for uint256;

    /// STORAGE

    /**
        @notice Management fee that the vault pays-off to the Keeper, typically
        based on the principal amount that the vault manages at a certain point in time.
        Used to incentivize the Keeper to keep the vault running.

        @dev This fee is a percentage with `FEE_DECIMALS` decimals
     */
    uint256 private _managementFee;

    /**
        @notice Performance fee that the vault pays-off to the Keeper, typically
        based on the earnings of the vault until a certain point in time.
        Used to incentivize the Keeper to select the best investment strategy.

        @dev This fee is a percentage with `FEE_DECIMALS` decimals
     */
    uint256 private _performanceFee;

    /**
        @notice The receipient of all the fees defined in the manager
     */
    address payable private _feesRecipient;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Initializes the current state to Unlocked

        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize the RolesManagerUpgradeable contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __FeeManager_init_unchained(
        uint256 managementFee_,
        uint256 performanceFee_,
        address payable feeReceipient_
    ) internal onlyInitializing {
        _setManagementFee(managementFee_);
        _setPerformanceFee(performanceFee_);
        _setFeesRecipient(feeReceipient_);
    }

    /// FUNCTIONS

    /**
        @inheritdoc IFeeManager
     */
    function setManagementFee(uint256 newManagementFee) external onlyAdmin {
        _setManagementFee(newManagementFee);
    }

    /**
        @inheritdoc IFeeManager
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyAdmin {
        _setPerformanceFee(newPerformanceFee);
    }

    /**
        @inheritdoc IFeeManager
     */
    function getManagementFee() public view returns (uint256) {
        return _managementFee;
    }

    /**
        @inheritdoc IFeeManager
     */
    function getPerformanceFee() public view returns (uint256) {
        return _performanceFee;
    }

    /**
        @inheritdoc IFeeManager
     */
    function setFeesRecipient(address payable newFeesRecipient) external onlyAdmin {
        _setFeesRecipient(newFeesRecipient);
    }

    /**
        @inheritdoc IFeeManager
     */
    function getFeesRecipient() external view returns (address) {
        return _feesRecipient;
    }

    // INTERNALS

    /**
        @notice Calculates the amount to be payed according to the management fee
        @param principalAmount The amount of principal to which the management fee is applied

        @dev TODO Use the new OpenZeppelin Math.mulDiv once it is released 
    */
    function _calculateManagementPayment(uint256 principalAmount) internal view returns (uint256) {
        return principalAmount.applyPercentage(_managementFee);
    }

    /**
        @notice Calculates the amount to be payed according to the performance fee
        @param earningsAmount The amount of earnings to which the performance fee is applied

        @dev TODO Use the new OpenZeppelin Math.mulDiv once it is released 
    */
    function _calculatePerformancePayment(uint256 earningsAmount) internal view returns (uint256) {
        return earningsAmount.applyPercentage(_performanceFee);
    }

    /**
        @notice Calculates the total amount of management + performance fee to be payed and
        sends it to the fees recipient in the given token

        @param token The token to be used for the payment
        @param principalAmount The amount of principal to which the management fee is applied
        @param earningsAmount The amount of earnings to which the performance fee is applied
     */
    function _payFees(
        IERC20 token,
        uint256 principalAmount,
        uint256 earningsAmount
    ) internal {
        uint256 managementAmount = _calculateManagementPayment(principalAmount);
        uint256 performanceAmount = _calculatePerformancePayment(earningsAmount);

        emit FeesSent(_feesRecipient, address(token), managementAmount, performanceAmount);

        token.safeTransfer(_feesRecipient, managementAmount + performanceAmount);
    }

    /**
        @notice Calculates the total amount of management + performance fee to be payed and
        sends it to the fees recipient in ETH

        @param principalAmount The amount of principal to which the management fee is applied
        
    */
    function _payFeesETH(uint256 principalAmount, uint256 earningsAmount) internal {
        uint256 managementAmount = _calculateManagementPayment(principalAmount);
        uint256 performanceAmount = _calculatePerformancePayment(earningsAmount);

        emit FeesETHSent(_feesRecipient, managementAmount, performanceAmount);

        _feesRecipient.sendValue(managementAmount + performanceAmount);
    }

    /// PRIVATE FUNCTIONS

    /**
        @notice Sets the new management fee
     */
    function _setManagementFee(uint256 newManagementFee) private {
        require(
            PercentageUtils.isPercentageInRange(newManagementFee),
            "Management fee must be less than or equal to 100"
        );
        uint256 oldManagementFee = _managementFee;

        _managementFee = newManagementFee;

        emit ManagementFeeChanged(oldManagementFee, newManagementFee);
    }

    /**
        @notice Sets the new performance fee
     */
    function _setPerformanceFee(uint256 newPerformanceFee) private {
        require(
            PercentageUtils.isPercentageInRange(newPerformanceFee),
            "Performance fee must be less than or equal to 100"
        );
        uint256 oldPerformanceFee = _performanceFee;
        _performanceFee = newPerformanceFee;

        emit ManagementFeeChanged(oldPerformanceFee, newPerformanceFee);
    }

    /**
        @notice Sets the new performance fee

        @dev Only the admin can change the performance fee
     */
    function _setFeesRecipient(address payable newFeesRecipient) private {
        require(newFeesRecipient != _feesRecipient, "Fees recipient is the same as before");

        address oldFeesReceipient = newFeesRecipient;

        _feesRecipient = newFeesRecipient;

        emit FeesReceipientChanged(oldFeesReceipient, newFeesRecipient);
    }

    /**
       @dev This empty reserved space is put in place to allow future versions to add new
       variables without shifting down storage in the inheritance chain.
       See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     
       @dev The size of the gap plus the size of the storage variables defined
       above must equal 50 storage slots
     */
    uint256[47] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;
import { IActionsManager } from "../interfaces/IActionsManager.sol";
import { IAction } from "../interfaces/IAction.sol";
import { RolesManagerUpgradeable } from "../common/RolesManagerUpgradeable.sol";
import "../library/PercentageUtils.sol";

/**
    @title ActionsManagerUpgradeable

    @author Roberto Cano <robercano>
    
    @notice Contains the list of actions that will be used to enter and exit a position in the vault

    @dev See { IActionsManager }

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract

    @dev The storage gap is not used here as this contract is not expected to change in the future
 */

contract ActionsManagerUpgradeable is RolesManagerUpgradeable, IActionsManager {
    /// STORAGE

    /**
        @notice The list of actions to be executed in the Vault.
     */
    IAction[] private _actions;

    /**
        @notice Percentages of the principal assigned to each action in the vault

        @dev The percentages are stored in the form of a uint256 with
        `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */
    uint256[] private _principalPercentages;

    /**
        @notice Sum of all the principal percentages

        @dev Used to do sanity checks on the operations of the vault
     */
    uint256 private _totalPrincipalPercentages;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Initializes the list of actions and its percentages
        
        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize any other contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __ActionsManager_init_unchained(IAction[] calldata actions, uint256[] calldata principalPercentages)
        internal
        onlyInitializing
    {
        _actions = new IAction[](actions.length);
        for (uint256 i = 0; i < actions.length; i++) {
            _actions[i] = actions[i];
        }

        __setPrincipalPercentages(principalPercentages);

        emit ActionsAdded(_actions);
    }

    /// FUNCTIONS

    /**
        @inheritdoc IActionsManager
     */
    function setPrincipalPercentages(uint256[] calldata newPrincipalPercentages) external override onlyStrategist {
        __setPrincipalPercentages(newPrincipalPercentages);
    }

    /// GETTERS

    /**
        @inheritdoc IActionsManager
    */
    function getActionsLength() public view returns (uint256) {
        return _actions.length;
    }

    /**
        @inheritdoc IActionsManager
     */
    function getAction(uint256 index) public view returns (IAction) {
        return _actions[index];
    }

    /**
        @inheritdoc IActionsManager
     */
    function getPrincipalPercentages() public view returns (uint256[] memory) {
        return _principalPercentages;
    }

    /**
        @inheritdoc IActionsManager
     */
    function getPrincipalPercentage(uint256 actionIndex) public view returns (uint256 percentage) {
        if (actionIndex < _principalPercentages.length) {
            percentage = _principalPercentages[actionIndex];
        }
    }

    /**
        @inheritdoc IActionsManager
     */
    function getTotalPrincipalPercentages() public view returns (uint256) {
        return _totalPrincipalPercentages;
    }

    /// INTERNALS

    /**
        @notice See { setPrincipalPercentages }
     */
    function __setPrincipalPercentages(uint256[] calldata newPrincipalPercentages) private {
        uint256 numActions = getActionsLength();

        if (newPrincipalPercentages.length != numActions) {
            revert PrincipalPercentagesMismatch(newPrincipalPercentages.length, numActions);
        }

        if (_principalPercentages.length != numActions) {
            _principalPercentages = new uint256[](newPrincipalPercentages.length);
        }

        _totalPrincipalPercentages = 0;

        for (uint256 i = 0; i < newPrincipalPercentages.length; i++) {
            if (newPrincipalPercentages[i] == 0 || newPrincipalPercentages[i] > PercentageUtils.PERCENTAGE_100) {
                revert PrincipalPercentageOutOfRange(i, newPrincipalPercentages[i]);
            }

            _principalPercentages[i] = newPrincipalPercentages[i];
            _totalPrincipalPercentages += newPrincipalPercentages[i];
        }

        if (_totalPrincipalPercentages > PercentageUtils.PERCENTAGE_100) {
            revert PrincipalPercentagesSumMoreThan100(_totalPrincipalPercentages);
        }

        emit PrincipalPercentagesUpdated(newPrincipalPercentages);
    }

    /**
       @dev This empty reserved space is put in place to allow future versions to add new
       variables without shifting down storage in the inheritance chain.
       See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     
       @dev The size of the gap plus the size of the storage variables defined
       above must equal 50 storage slots
     */
    uint256[47] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { ILifecycleStates } from "../interfaces/ILifecycleStates.sol";
import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";

/**  
    @title IVault

    @author Roberto Cano <robercano>

    @notice Interface for the a vault that executes investment actions on each investment cycle

    @dev An IVault represents a vault that contains a set of investment actions. When entering the
    position, all the actions in the vault are executed in order, one after the other. If all
    actions succeed, then the position is entered. Once the position can be exited, the investment
    actions are also exited and the profit/loss of the investment cycle is realized.
 */
interface IVault is IRolesManager, ILifecycleStates, IEmergencyLock, IRefundsHelper, IFeeManager {
    /// EVENTS
    event VaultPositionEntered(uint256 totalPrincipalAmount, uint256 principalAmountInvested);
    event VaultPositionExited(uint256 newPrincipalAmount);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @dev When called, the vault will enter the position of all configured actions. For each action
        it will approve each action for the configured principal percentage so each action can access
        the funds in order to execute the specific investment strategy

        @dev Once the Vault enters the investment position no more immediate deposits or withdrawals
        are allowed
     */
    function enterPosition() external;

    /**
        @notice Function called to exit the investment position

        @return newPrincipalAmount The final amount of principal that is in the vault after the actions
        have exited their positions

        @dev When called, the vault will exit the position of all configured actions. Each action will send
        back the remaining funds (including profit or loss) to the vault
     */
    function exitPosition() external returns (uint256 newPrincipalAmount);

    /**
        @notice It inficates if the position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeEntered() external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeExited() external view returns (bool canExit);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to pause all the functionality of the vault in case
    of an emergency
 */

interface IEmergencyLock {
    // FUNCTIONS

    /**
        @notice Pauses the contract
     */
    function pause() external;

    /**
        @notice Unpauses the contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRolesManager

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`.
 */

interface IRolesManager {
    /// EVENTS
    event AdminChanged(address indexed prevAdminAddress, address indexed newAdminAddress);
    event StrategistChanged(address indexed prevStrategistAddress, address indexed newStrategistAddress);
    event OperatorChanged(address indexed prevOperatorAddress, address indexed newOperatorAddress);
    event VaultChanged(address indexed prevVaultAddress, address indexed newVaultAddress);

    /// FUNCTIONS

    /**
        @notice Changes the existing Admin address to a new one

        @dev Only the previous Admin can change the address to a new one
     */
    function changeAdmin(address newAdminAddress) external;

    /**
        @notice Changes the existing Strategist address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeStrategist(address newStrategistAddress) external;

    /**
        @notice Changes the existing Operator address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeOperator(address newOperatorAddress) external;

    /**
        @notice Changes the existing Vault address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeVault(address newVaultAddress) external;

    /**
        @notice Returns the current Admin address
     */
    function getAdmin() external view returns (address);

    /**
        @notice Returns the current Strategist address
     */
    function getStrategist() external view returns (address);

    /**
        @notice Returns the current Operator address
     */
    function getOperator() external view returns (address);

    /**
        @notice Returns the current Vault address
     */
    function getVault() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title ILifecycleStates

    @author Roberto Cano <robercano>
    
    @notice Handles the lifecycle of the hedging vault and provides the necessary modifiers
    to scope functions that must only work in certain states. It also provides a getter
    to query the current state and an internal setter to change the state
 */

interface ILifecycleStates {
    /// STATES

    /**
        @notice States defined for the vault. Although the exact meaning of each state is
        dependent on the HedgingVault contract, the following assumptions are made here:
            - Unlocked: the vault accepts immediate deposits and withdrawals and the specific
            configuration of the next investment strategy is not yet known.
            - Committed: the vault accepts immediate deposits and withdrawals but the specific
            configuration of the next investment strategy is already known
            - Locked: the vault is locked and cannot accept immediate deposits or withdrawals. All
            of the assets managed by the vault are locked in it. It could accept deferred deposits
            and withdrawals though
     */
    enum LifecycleState {
        Unlocked,
        Committed,
        Locked
    }

    /// EVENTS
    event LifecycleStateChanged(LifecycleState indexed prevState, LifecycleState indexed newState);

    /// FUNCTIONS

    /**
        @notice Function to get the current state of the vault
        @return The current state of the vault
     */
    function getLifecycleState() external view returns (LifecycleState);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRefundsHelper

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to refund tokens or ETH sent to the vault
    by mistake. At construction time it receives the list of tokens that cannot be refunded.
    Those tokens are typically the asset managed by the vault and any intermediary tokens
    that the vault may use to manage the asset.
 */
interface IRefundsHelper {
    /// FUNCTIONS

    /**
        @notice Refunds the given amount of tokens to the given address
        @param token address of the token to be refunded
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external;

    /**
        @notice Refunds the given amount of ETH to the given address
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refundETH(uint256 amount, address payable recipient) external;

    /// GETTERS

    /**
        @notice Returns whether the given token is refundable or not

        @param token address of the token to be checked

        @return true if the token is refundable, false otherwise
     */
    function canRefund(address token) external view returns (bool);

    /**
        @notice Returns whether the ETH is refundable or not

        @return true if ETH is refundable, false otherwise
     */
    function canRefundETH() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IERC4626Upgradeable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * _Available since v4.7._
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626Upgradeable {
    using MathUpgradeable for uint256;

    IERC20MetadataUpgradeable private _asset;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20MetadataUpgradeable asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20MetadataUpgradeable asset_) internal onlyInitializing {
        _asset = asset_;
    }

    /** @dev See {IERC4262-asset} */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4262-totalAssets} */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4262-convertToShares} */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets);
    }

    /** @dev See {IERC4262-convertToAssets} */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares);
    }

    /** @dev See {IERC4262-maxDeposit} */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4262-maxMint} */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4262-maxWithdraw} */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner));
    }

    /** @dev See {IERC4262-maxRedeem} */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4262-previewDeposit} */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets);
    }

    /** @dev See {IERC4262-previewMint} */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares);
    }

    /** @dev See {IERC4262-previewWithdraw} */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets);
    }

    /** @dev See {IERC4262-previewRedeem} */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares);
    }

    /** @dev See {IERC4262-deposit} */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4262-mint} */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4262-withdraw} */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4262-redeem} */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal convertion function (from assets to shares) with support for rounding direction
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToShares(uint256 assets) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? (assets * (10**decimals())) / (10**_asset.decimals())
                : (assets * supply) / totalAssets();
    }

    /**
     * @dev Internal convertion function (from shares to assets) with support for rounding direction
     */
    function _convertToAssets(uint256 shares) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? (shares * (10**_asset.decimals())) / (10**decimals()) : (shares * totalAssets()) / supply;
    }

    /**
     * @dev Deposit/mint common workflow
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) private {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20Upgradeable.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) private {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IFeeManager

    @author Roberto Cano <robercano>
    
    @notice Handles the fees that the vault fees payment to the configured recipients

    @dev The contract uses PercentageUtils to handle the fee percentages. See { PercentageUtils } for
    more information on the format and precision of the percentages.
 */

interface IFeeManager {
    /// EVENTS
    event ManagementFeeChanged(uint256 oldManagementFee, uint256 newManagementFee);
    event PerformanceFeeChanged(uint256 oldPerformanceFee, uint256 newPerformanceFee);
    event FeesReceipientChanged(address indexed oldFeeReceipient, address indexed newFeeReceipient);
    event FeesSent(
        address indexed receipient,
        address indexed token,
        uint256 managementAmount,
        uint256 performanceAmount
    );
    event FeesETHSent(address indexed receipient, uint256 managementAmount, uint256 performanceAmount);

    /// FUNCTIONS

    /**
        @notice Sets the new management fee

        @param newManagementFee The new management fee in fixed point format (See { PercentageUtils })
     */
    function setManagementFee(uint256 newManagementFee) external;

    /**
        @notice Sets the new performance fee

        @param newPerformanceFee The new performance fee in fixed point format (See { PercentageUtils })
     */
    function setPerformanceFee(uint256 newPerformanceFee) external;

    /**
        @notice Returns the current management fee

        @return The current management fee in fixed point format (See { PercentageUtils })
     */
    function getManagementFee() external view returns (uint256);

    /**
        @notice Returns the current performance fee

        @return The current performance fee in fixed point format (See { PercentageUtils })
     */
    function getPerformanceFee() external view returns (uint256);

    /**
        @notice Sets the new fees recipient
     */
    function setFeesRecipient(address payable newFeesRecipient) external;

    /**
        @notice Returns the current fees recipient
     */
    function getFeesRecipient() external view returns (address);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IAction } from "../interfaces/IAction.sol";

/**
    @title IActionsManager

    @author Roberto Cano <robercano>
    
    @notice Contains the list of actions that will be used to enter and exit a position in the vault
 */
interface IActionsManager {
    /// EVENTS
    event ActionsAdded(IAction[] actions);
    event PrincipalPercentagesUpdated(uint256[] _principalPercentages);

    /// ERRORS
    error PrincipalPercentagesMismatch(
        uint256 _principalPercentagesLength,
        uint256 _principalPercentagesLengthExpected
    );
    error PrincipalPercentageOutOfRange(uint256 index, uint256 value);
    error PrincipalPercentagesSumMoreThan100(uint256 totalSumOfPercentages);

    /// FUNCTIONS

    /**
        @notice Sets the new percentages of the principal assigned to each action in the vault

        @dev Reverts if the number of percentages is not the same as the number of actions in the vault
        @dev Reverts if any of the percentages is not between 0% and 100%
        @dev Reverts if the sum of all percentages is more than 100%
        @dev Each percentage is a fixed point number with `PercentageUtils.PERCENTAGE_DECIMALS` decimals

     */
    function setPrincipalPercentages(uint256[] calldata newPrincipalPercentages) external;

    /// GETTERS

    /**
        @notice Returns the number of actions available

        @return The number of actions available
    */
    function getActionsLength() external view returns (uint256);

    /**
        @notice Returns the action at the given index, starting at 0

        @param index The index of the action to return

        @return The action at the given index
     */
    function getAction(uint256 index) external view returns (IAction);

    /**
        @notice Returns the percentages of the principal assigned to each action in the vault

        @return The percentages of the principal assigned to each action in the vault
     */
    function getPrincipalPercentages() external view returns (uint256[] memory);

    /**
        @notice Returns the percentage of the principal assigned to the action with the given index, starting at 0

        @return The percentage of the principal assigned to the action with the given index

        @dev The percentage is stored in the form of a uint256 with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
        @dev if the index is out of range the function returns 0
     */
    function getPrincipalPercentage(uint256 actionIndex) external view returns (uint256);

    /**
        @notice Returns the total sum of the percentages of the principal assigned to each action in the vault

        @return The total sum of the percentages of the principal assigned to each action in the vault
     */
    function getTotalPrincipalPercentages() external view returns (uint256);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**  
    @title IAction

    @author Roberto Cano <robercano>

    @notice Interface for the investment actions executed on each investment cycle

    @dev An IAction represents an investment action that can be executed by an external caller.
    This caller will typically be a Vault, but it could also be used in other strategies.

    @dev An Action receives a loan from its caller so it can perform a specific investment action.
    The asset and amount of the loan is indicated in the `enterPosition` call, and the Action can transfer
    up to the indicated amount from the caller for the specified asset, and use it in the investment.
    Once the action indicates that the investment cycle is over, by signaling it through the
    `canPositionBeExited` call, the  caller can call `exitPosition` to exit the position. Upon this call,
    the action will transfer to the caller what's remaining of the loan, and will also return this amount
    as the return value of the `exitPotision` call.

    @dev The Actions does not need to transfer all allowed assets to itself if it is not needed. It could,
    for example, transfer a small amount which is enough to cover the cost of the investment. However,
    when returning the remaining amount, it must take into account the whole amount for the loan. For
    example:
        - The Action enters a position with a loan of 100 units of asset A
        - The Action transfers 50 units of asset A to itself
        - The Action exits the position with 65 units of asset A
        - Because it was allowed to get 100 units of asset A, and it made a profit of 15,
          the returned amount in the `exitPosition` call is 115 units of asset A (100 + 15).
        - If instead of 65 it had made a loss of 30 units, the returned amount would be
          70 units of asset A (100 - 30)

    @dev The above logic helps the caller easily track the profit/loss for the last investment cycle

 */
interface IAction {
    /// EVENTS
    event ActionPositionEntered(address indexed investmentAsset, uint256 amountToInvest);
    event ActionPositionExited(address indexed investmentAsset, uint256 amountReturned);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @param investmentAsset The asset available to the action contract for the investment 
        @param amountToInvest The amount of the asset that the action contract is allowed to use in the investment

        @dev When called, the action should have been approved for the given amount
        of asset. The action will retrieve the required amount of asset from the caller
        and invest it according to its logic
     */
    function enterPosition(address investmentAsset, uint256 amountToInvest) external;

    /**
        @notice Function called to exit the investment position

        @param investmentAsset The asset reclaim from the investment position

        @return amountReturned The amount of asset that the action contract received from the caller
        plus the profit or minus the loss of the investment cycle

        @dev When called, the action must transfer all of its balance for `asset` to the caller,
        and then return the total amount of asset that it received from the caller, plus/minus
        the profit/loss of the investment cycle.

        @dev See { IAction } description for more information on `amountReturned`
     */
    function exitPosition(address investmentAsset) external returns (uint256 amountReturned);

    /**
        @notice It inficates if the position can be entered or not

        @param investmentAsset The asset for which position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeEntered(address investmentAsset) external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @param investmentAsset The asset for which position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeExited(address investmentAsset) external view returns (bool canExit);
}