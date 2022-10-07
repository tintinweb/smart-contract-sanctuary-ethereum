// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MarginVault } from "../libs/MarginVault.sol";
import { Actions } from "../libs/Actions.sol";
import { AddressBookInterface } from "../interfaces/AddressBookInterface.sol";
import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { MarginCalculatorInterface } from "../interfaces/MarginCalculatorInterface.sol";
import { OracleInterface } from "../interfaces/OracleInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";
import { MarginPoolInterface } from "../interfaces/MarginPoolInterface.sol";
import { ArrayAddressUtils } from "../libs/ArrayAddressUtils.sol";
import { FPI } from "../libs/FixedPointInt256.sol";

/**
 * Controller Error Codes
 * C1: sender is not full pauser
 * C2: sender is not partial pauser
 * C4: system is partially paused
 * C5: system is fully paused
 * C6: msg.sender is not authorized to run action
 * C7: invalid addressbook address
 * C8: invalid owner address
 * C9: invalid input
 * C10: fullPauser cannot be set to address zero
 * C11: partialPauser cannot be set to address zero
 * C12: can not run actions for different owners
 * C13: can not run actions on different vaults
 * C14: can not run actions on inexistent vault
 * C15: cannot deposit long onToken from this address
 * C16: onToken is not whitelisted to be used as collateral
 * C17: can not withdraw an expired onToken
 * C18: cannot deposit collateral from this address
 * C19: onToken is not whitelisted
 * C20: can not mint expired onToken
 * C21: can not burn expired onToken
 * C22: onToken is not whitelisted to be redeemed
 * C23: can not redeem un-expired onToken
 * C24: asset prices not finalized yet
 * C25: can not settle vault with un-expired onToken
 * C26: invalid vault id
 * C27: vault does not have long to withdraw
 * C28: vault has no collateral to mint onToken
 * C29: deposit/withdraw collateral amounts should be same length as collateral assets amount for correspoding vault short
 * C30: donate asset adress is zero
 * C31: donate asset is one of collaterls in associated onToken
 */

/**
 * @title Controller
 * @notice Contract that controls the Gamma Protocol and the interaction of all sub contracts
 */
contract Controller is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;
    using ArrayAddressUtils for address[];

    AddressBookInterface public addressbook;
    WhitelistInterface public whitelist;
    OracleInterface public oracle;
    MarginCalculatorInterface public calculator;
    MarginPoolInterface public pool;

    /// @notice address that has permission to partially pause the system, where system functionality is paused
    /// except redeem and settleVault
    address public partialPauser;

    /// @notice address that has permission to fully pause the system, where all system functionality is paused
    address public fullPauser;

    /// @notice True if all system functionality is paused other than redeem and settle vault
    bool public systemPartiallyPaused;

    /// @notice True if all system functionality is paused
    bool public systemFullyPaused;

    /// @dev mapping between an owner address and the number of owner address vaults
    mapping(address => uint256) public accountVaultCounter;
    /// @dev mapping between an owner address and a specific vault using a vault id
    mapping(address => mapping(uint256 => MarginVault.Vault)) public vaults;
    /// @dev mapping between an account owner and their approved or unapproved account operators
    mapping(address => mapping(address => bool)) internal operators;

    /// @dev mapping to store the timestamp at which the vault was last updated, will be updated in every action that changes the vault state or when calling sync()
    mapping(address => mapping(uint256 => uint256)) internal vaultLatestUpdate;

    /// @notice emits an event when an account operator is updated for a specific account owner
    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);
    /// @notice emits an event when a new vault is opened
    event VaultOpened(address indexed accountOwner, uint256 vaultId);
    /// @notice emits an event when a long onToken is deposited into a vault
    event LongONtokenDeposited(
        address indexed onToken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a long onToken is withdrawn from a vault
    event LongONtokenWithdrawed(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is deposited into a vault
    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is withdrawn from a vault
    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short onToken is minted from a vault
    event ShortONtokenMinted(
        address indexed onToken,
        address indexed accountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short onToken is burned
    event ShortONtokenBurned(
        address indexed onToken,
        address indexed accountOwner,
        address indexed sender,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when an onToken is redeemed
    event Redeem(
        address indexed onToken,
        address indexed redeemer,
        address indexed receiver,
        address[] collateralAssets,
        uint256 onTokenBurned,
        uint256[] payouts
    );
    /// @notice emits an event when a vault is settled
    event VaultSettled(
        address indexed accountOwner,
        address indexed shortONtoken,
        address to,
        uint256[] payouts,
        uint256 vaultId
    );
    /// @notice emits an event when a call action is executed
    event CallExecuted(address indexed from, address indexed to, bytes data);
    /// @notice emits an event when the fullPauser address changes
    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);
    /// @notice emits an event when the partialPauser address changes
    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);
    /// @notice emits an event when the system partial paused status changes
    event SystemPartiallyPaused(bool isPaused);
    /// @notice emits an event when the system fully paused status changes
    event SystemFullyPaused(bool isPaused);
    /// @notice emits an event when a donation transfer executed
    event Donated(address indexed donator, address indexed asset, uint256 amount);
    /// @notice emits an event when naked cap is updated
    // event NakedCapUpdated(address indexed collateral, uint256 cap);

    /**
     * @notice modifier to check if the system is not partially paused, where only redeem and settleVault is allowed
     */
    modifier notPartiallyPaused() {
        _isNotPartiallyPaused();

        _;
    }

    /**
     * @notice modifier to check if the system is not fully paused, where no functionality is allowed
     */
    modifier notFullyPaused() {
        _isNotFullyPaused();

        _;
    }

    /**
     * @notice modifier to check if sender is the fullPauser address
     */
    modifier onlyFullPauser() {
        require(msg.sender == fullPauser, "C1");

        _;
    }

    /**
     * @notice modifier to check if the sender is the partialPauser address
     */
    modifier onlyPartialPauser() {
        require(msg.sender == partialPauser, "C2");

        _;
    }

    /**
     * @notice modifier to check if the sender is the account owner or an approved account operator
     * @param _sender sender address
     * @param _accountOwner account owner address
     */
    modifier onlyAuthorized(address _sender, address _accountOwner) {
        _isAuthorized(_sender, _accountOwner);

        _;
    }

    /**
     * @dev check if the system is not in a partiallyPaused state
     */
    function _isNotPartiallyPaused() internal view {
        require(!systemPartiallyPaused, "C4");
    }

    /**
     * @dev check if the system is not in an fullyPaused state
     */
    function _isNotFullyPaused() internal view {
        require(!systemFullyPaused, "C5");
    }

    /**
     * @dev check if the sender is an authorized operator
     * @param _sender msg.sender
     * @param _accountOwner owner of a vault
     */
    function _isAuthorized(address _sender, address _accountOwner) internal view {
        require((_sender == _accountOwner) || (operators[_accountOwner][_sender]), "C6");
    }

    /**
     * @notice initalize the deployed contract
     * @param _addressBook addressbook module
     * @param _owner account owner address
     */
    function initialize(address _addressBook, address _owner) external initializer {
        require(_addressBook != address(0), "C7");
        require(_owner != address(0), "C8");

        __Ownable_init();
        transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();

        addressbook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }

    /**
     * @notice send asset amount to margin pool
     * @dev use donate() instead of direct transfer() to store the balance in assetBalance
     * @param _asset asset address
     * @param _amount amount to donate to pool
     * @param _onToken to donate _asset for
     */
    function donate(
        address _asset,
        uint256 _amount,
        address _onToken
    ) external {
        require(_asset != address(0), "C30");
        require(whitelist.isWhitelistedONtoken(_onToken), "C19");

        address[] memory _collateralAssets = ONtokenInterface(_onToken).getCollateralAssets();

        bool isCollateralAsset = false;
        for (uint256 i = 0; i < _collateralAssets.length; i++) {
            if (_collateralAssets[i] == _asset) {
                isCollateralAsset = true;
                break;
            }
        }

        require(isCollateralAsset, "C31");

        pool.transferToPool(_asset, msg.sender, _amount);

        emit Donated(msg.sender, _asset, _amount);
    }

    /**
     * @notice allows the partialPauser to toggle the systemPartiallyPaused variable and partially pause or partially unpause the system
     * @dev can only be called by the partialPauser
     * @param _partiallyPaused new boolean value to set systemPartiallyPaused to
     */
    function setSystemPartiallyPaused(bool _partiallyPaused) external onlyPartialPauser {
        require(systemPartiallyPaused != _partiallyPaused, "C9");

        systemPartiallyPaused = _partiallyPaused;

        emit SystemPartiallyPaused(systemPartiallyPaused);
    }

    /**
     * @notice allows the fullPauser to toggle the systemFullyPaused variable and fully pause or fully unpause the system
     * @dev can only be called by the fullyPauser
     * @param _fullyPaused new boolean value to set systemFullyPaused to
     */
    function setSystemFullyPaused(bool _fullyPaused) external onlyFullPauser {
        require(systemFullyPaused != _fullyPaused, "C9");

        systemFullyPaused = _fullyPaused;

        emit SystemFullyPaused(systemFullyPaused);
    }

    /**
     * @notice allows the owner to set the fullPauser address
     * @dev can only be called by the owner
     * @param _fullPauser new fullPauser address
     */
    function setFullPauser(address _fullPauser) external onlyOwner {
        require(_fullPauser != address(0), "C10");
        require(fullPauser != _fullPauser, "C9");
        emit FullPauserUpdated(fullPauser, _fullPauser);
        fullPauser = _fullPauser;
    }

    /**
     * @notice allows the owner to set the partialPauser address
     * @dev can only be called by the owner
     * @param _partialPauser new partialPauser address
     */
    function setPartialPauser(address _partialPauser) external onlyOwner {
        require(_partialPauser != address(0), "C11");
        require(partialPauser != _partialPauser, "C9");
        emit PartialPauserUpdated(partialPauser, _partialPauser);
        partialPauser = _partialPauser;
    }

    /**
     * @notice allows a user to give or revoke privileges to an operator which can act on their behalf on their vaults
     * @dev can only be updated by the vault owner
     * @param _operator operator that the sender wants to give privileges to or revoke them from
     * @param _isOperator new boolean value that expresses if the sender is giving or revoking privileges for _operator
     */
    function setOperator(address _operator, bool _isOperator) external {
        require(operators[msg.sender][_operator] != _isOperator, "C9");

        operators[msg.sender][_operator] = _isOperator;

        emit AccountOperatorUpdated(msg.sender, _operator, _isOperator);
    }

    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /**
     * @notice execute a number of actions on specific vaults
     * @dev can only be called when the system is not fully paused
     * @param _actions array of actions arguments
     */
    function operate(Actions.ActionArgs[] memory _actions) external nonReentrant notFullyPaused {
        (bool vaultUpdated, address vaultOwner, uint256 vaultId) = _runActions(_actions);
        if (vaultUpdated) {
            vaultLatestUpdate[vaultOwner][vaultId] = block.timestamp;
        }
    }

    /**
     * @notice check if a specific address is an operator for an owner account
     * @param _owner account owner address
     * @param _operator account operator address
     * @return True if the _operator is an approved operator for the _owner account
     */
    function isOperator(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }

    /**
     * @notice return a vault's proceeds pre or post expiry, the amount of collateral that can be removed from a vault
     * @param _owner account owner of the vault
     * @param _vaultId vaultId to return balances for
     * @return amount of collateral that can be taken out
     */
    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256[] memory) {
        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_owner, _vaultId);
        return calculator.getExcessCollateral(vault);
    }

    /**
     * @dev return if an expired onToken is ready to be settled, only true when price for underlying,
     * strike and collateral assets at this specific expiry is available in our Oracle module
     * @param _onToken onToken
     */
    function isSettlementAllowed(address _onToken) external view returns (bool) {
        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            _onToken
        );
        return canSettleAssets(underlying, strike, collaterals, expiry);
    }

    /**
     * @notice check if an onToken has expired
     * @param _onToken onToken address
     * @return True if the onToken has expired, False if not
     */
    function hasExpired(address _onToken) external view returns (bool) {
        return block.timestamp >= ONtokenInterface(_onToken).expiryTimestamp();
    }

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner, vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        public
        view
        returns (MarginVault.Vault memory, uint256)
    {
        return (vaults[_owner][_vaultId], vaultLatestUpdate[_owner][_vaultId]);
    }

    /**
     * @notice execute a variety of actions
     * @dev for each action in the action array, execute the corresponding action, only one vault can be modified
     * for all actions except SettleVault, Redeem, and Call
     * @param _actions array of type Actions.ActionArgs[], which expresses which actions the user wants to execute
     * @return vaultUpdated, indicates if a vault has changed
     * @return owner, the vault owner if a vault has changed
     * @return vaultId, the vault Id if a vault has changed
     */
    function _runActions(Actions.ActionArgs[] memory _actions)
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        address vaultOwner;
        uint256 vaultId;
        bool vaultUpdated;

        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];
            Actions.ActionType actionType = action.actionType;

            // actions except Settle, Redeem are "Vault-updating actions"
            // only allow update 1 vault in each operate call
            if ((actionType != Actions.ActionType.SettleVault) && (actionType != Actions.ActionType.Redeem)) {
                // check if this action is manipulating the same vault as all other actions, if a vault has already been updated
                if (vaultUpdated) {
                    require(vaultOwner == action.owner, "C12");
                    require(vaultId == action.vaultId, "C13");
                }
                vaultUpdated = true;
                vaultId = action.vaultId;
                vaultOwner = action.owner;
            }

            if (actionType == Actions.ActionType.OpenVault) {
                _openVault(Actions._parseOpenVaultArgs(action));
            } else if (actionType == Actions.ActionType.DepositLongOption) {
                _depositLong(Actions._parseDepositLongArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawLongOption) {
                _withdrawLong(Actions._parseWithdrawLongArgs(action));
            } else if (actionType == Actions.ActionType.DepositCollateral) {
                _depositCollateral(Actions._parseDepositCollateralArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawCollateral) {
                _withdrawCollateral(Actions._parseWithdrawCollateralArgs(action));
            } else if (actionType == Actions.ActionType.MintShortOption) {
                _mintONtoken(Actions._parseMintArgs(action));
            } else if (actionType == Actions.ActionType.BurnShortOption) {
                _burnONtoken(Actions._parseBurnArgs(action));
            } else if (actionType == Actions.ActionType.Redeem) {
                _redeem(Actions._parseRedeemArgs(action));
            } else if (actionType == Actions.ActionType.SettleVault) {
                _settleVault(Actions._parseSettleVaultArgs(action));
            }
        }

        return (vaultUpdated, vaultOwner, vaultId);
    }

    /**
     * @notice open a new vault inside an account
     * @dev only the account owner or operator can open a vault, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args OpenVaultArgs structure
     */
    function _openVault(Actions.OpenVaultArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        uint256 vaultId = accountVaultCounter[_args.owner].add(1);

        require(_args.vaultId == vaultId, "C14");
        require(whitelist.isWhitelistedONtoken(_args.shortONtoken), "C19");

        ONtokenInterface onToken = ONtokenInterface(_args.shortONtoken);

        // store new vault
        accountVaultCounter[_args.owner] = vaultId;
        // every vault is linked to certain onToken which this vault can mint
        vaults[_args.owner][vaultId].shortONtoken = _args.shortONtoken;
        address[] memory collateralAssets = onToken.getCollateralAssets();
        // store collateral assets of linked onToken to vault
        vaults[_args.owner][vaultId].collateralAssets = collateralAssets;

        uint256 assetsLength = collateralAssets.length;

        // Initialize vault collateral params as arrays for later use
        vaults[_args.owner][vaultId].collateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].availableCollateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].reservedCollateralAmounts = new uint256[](assetsLength);
        vaults[_args.owner][vaultId].usedCollateralValues = new uint256[](assetsLength);

        emit VaultOpened(_args.owner, vaultId);
    }

    /**
     * @notice deposit a long onToken into a vault
     * @dev only the account owner or operator can deposit a long onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositLong(Actions.DepositLongArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        // only allow vault owner or vault operator to deposit long onToken
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C15");

        require(whitelist.isWhitelistedONtoken(_args.longONtoken), "C16");

        // Check if short and long onTokens params are matched,
        // they must be they should differ only in strike value
        require(
            calculator.isMarginableLong(_args.longONtoken, vaults[_args.owner][_args.vaultId]),
            "not marginable long"
        );

        vaults[_args.owner][_args.vaultId].addLong(_args.longONtoken, _args.amount);
        pool.transferToPool(_args.longONtoken, _args.from, _args.amount);

        emit LongONtokenDeposited(_args.longONtoken, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a long onToken from a vault
     * @dev only the account owner or operator can withdraw a long onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawLong(Actions.WithdrawLongArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        address onTokenAddress = vaults[_args.owner][_args.vaultId].longONtoken;
        require(onTokenAddress != address(0), "C27");

        ONtokenInterface onToken = ONtokenInterface(vaults[_args.owner][_args.vaultId].longONtoken);

        // Can't withdraw after expiry, should call settleVault to execute long
        require(block.timestamp < onToken.expiryTimestamp(), "C17");

        vaults[_args.owner][_args.vaultId].removeLong(onTokenAddress, _args.amount);

        pool.transferToUser(onTokenAddress, _args.to, _args.amount);

        emit LongONtokenWithdrawed(onTokenAddress, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice deposit a collateral asset into a vault
     * @dev only the account owner or operator can deposit collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositCollateral(Actions.DepositCollateralArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        // only allow vault owner or vault operator to deposit collateral
        require((_args.from == msg.sender) || (_args.from == _args.owner), "C18");

        address[] memory collateralAssets = vaults[_args.owner][_args.vaultId].collateralAssets;
        uint256 collateralsLength = collateralAssets.length;
        require(collateralsLength == _args.amounts.length, "C29");

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (_args.amounts[i] > 0) {
                pool.transferToPool(collateralAssets[i], _args.from, _args.amounts[i]);
                emit CollateralAssetDeposited(
                    collateralAssets[i],
                    _args.owner,
                    _args.from,
                    _args.vaultId,
                    _args.amounts[i]
                );
            }
        }
        vaults[_args.owner][_args.vaultId].addCollaterals(collateralAssets, _args.amounts);
    }

    /**
     * @notice withdraw a collateral asset from a vault
     * @dev only the account owner or operator can withdraw collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawCollateral(Actions.WithdrawCollateralArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        // If argument is one element array with zero element withdraw all available
        // otherwise withdraw provided amounts array
        uint256[] memory amounts = _args.amounts.length == 1 && _args.amounts[0] == 0
            ? vault.availableCollateralAmounts
            : _args.amounts;

        vaults[_args.owner][_args.vaultId].removeCollateral(amounts);

        address[] memory collateralAssets = vaults[_args.owner][_args.vaultId].collateralAssets;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                pool.transferToUser(collateralAssets[i], _args.to, amounts[i]);
                emit CollateralAssetWithdrawed(collateralAssets[i], _args.owner, _args.to, _args.vaultId, amounts[i]);
            }
        }
    }

    /**
     * @notice calculates maximal short amount can be minted for collateral in a given user and vault
     */
    function getMaxCollateratedShortAmount(address user, uint256 vault_id) external view returns (uint256) {
        return calculator.getMaxShortAmount(vaults[user][vault_id]);
    }

    /**
     * @notice mint short onTokens from a vault which creates an obligation that is recorded in the vault
     * @dev only the account owner or operator can mint an onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _mintONtoken(Actions.MintArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        MarginVault.Vault storage vault = vaults[_args.owner][_args.vaultId];

        address vaultShortONtoken = vault.shortONtoken;

        ONtokenInterface onToken = ONtokenInterface(vaultShortONtoken);
        require(block.timestamp < onToken.expiryTimestamp(), "C20");

        // Mint maximum possible shorts if zero
        if (_args.amount == 0) {
            _args.amount = calculator.getMaxShortAmount(vault);
        }

        // If amount is still zero must be not enough collateral to mint any short
        if (_args.amount == 0) {
            revert("C28");
        }

        // collateralsValuesRequired - is value of each collateral used for minting onToken in strike asset,
        // in other words -  usedCollateralsAmounts[i] * collateralAssetPriceInStrike[i]
        // collateralsAmountsUsed and collateralsValuesUsed takes into account amounts used from long too
        // collateralsAmountsRequired is amounts required from vaults deposited collaterals only, without using long
        (
            uint256[] memory collateralsAmountsRequired,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed,
            uint256 usedLongAmount
        ) = calculator.getCollateralsToCoverShort(vault, _args.amount);
        onToken.mintONtoken(_args.to, _args.amount, collateralsAmountsUsed, collateralsValuesUsed);
        vault.addShort(_args.amount);
        // Updates vault's data regarding used and available collaterals,
        // and used collaterals values for later calculations on vault settlement
        vault.useVaultsAssets(collateralsAmountsRequired, usedLongAmount, collateralsValuesUsed);

        emit ShortONtokenMinted(vaultShortONtoken, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice burn onTokens to reduce or remove the minted onToken obligation recorded in a vault
     * @dev only the account owner or operator can burn an onToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _burnONtoken(Actions.BurnArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        // check that vault id is valid for this vault owner
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");
        address onTokenAddress = vaults[_args.owner][_args.vaultId].shortONtoken;
        ONtokenInterface onToken = ONtokenInterface(onTokenAddress);

        // do not allow burning expired onToken
        require(block.timestamp < onToken.expiryTimestamp(), "C21");

        onToken.burnONtoken(_args.owner, _args.amount);

        // Cases:
        // New short amount needs less collateral or no at all cause long amount is enough

        // remove onToken from vault
        // collateralRation represents how much of already used collateral will be used after burn
        (FPI.FixedPointInt memory collateralRatio, uint256 newUsedLongAmount) = calculator.getAfterBurnCollateralRatio(
            vaults[_args.owner][_args.vaultId],
            _args.amount
        );
        (uint256[] memory freedCollateralAmounts, uint256[] memory freedCollateralValues) = vaults[_args.owner][
            _args.vaultId
        ].removeShort(_args.amount, collateralRatio, newUsedLongAmount);

        // Update onToken info regarding collaterization after burn
        onToken.reduceCollaterization(freedCollateralAmounts, freedCollateralValues, _args.amount);

        emit ShortONtokenBurned(onTokenAddress, _args.owner, msg.sender, _args.vaultId, _args.amount);
    }

    /**
     * @notice redeem an onToken after expiry, receiving the payout of the onToken in the collateral asset
     * @dev cannot be called when system is fullyPaused
     * @param _args RedeemArgs structure
     */
    function _redeem(Actions.RedeemArgs memory _args) internal {
        ONtokenInterface onToken = ONtokenInterface(_args.onToken);

        // check that onToken to redeem is whitelisted
        require(whitelist.isWhitelistedONtoken(_args.onToken), "C22");

        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            address(onToken)
        );

        // only allow redeeming expired onToken
        require(block.timestamp >= expiry, "C23");

        // Check prices are finalised
        require(canSettleAssets(underlying, strike, collaterals, expiry), "C24");

        uint256[] memory payout = calculator.getPayout(_args.onToken, _args.amount);

        onToken.burnONtoken(msg.sender, _args.amount);

        for (uint256 i = 0; i < collaterals.length; i++) {
            if (payout[i] > 0) {
                pool.transferToUser(collaterals[i], _args.receiver, payout[i]);
            }
        }

        emit Redeem(_args.onToken, msg.sender, _args.receiver, collaterals, _args.amount, payout);
    }

    /**
     * @notice settle a vault after expiry, removing the net proceeds/collateral after both long and short onToken payouts have settled
     * @dev deletes a vault of vaultId after net proceeds/collateral is removed, cannot be called when system is fullyPaused
     * @param _args SettleVaultArgs structure
     */
    function _settleVault(Actions.SettleVaultArgs memory _args) internal onlyAuthorized(msg.sender, _args.owner) {
        require(_checkVaultId(_args.owner, _args.vaultId), "C26");

        (MarginVault.Vault memory vault, ) = getVaultWithDetails(_args.owner, _args.vaultId);

        ONtokenInterface onToken;

        // new scope to avoid stack too deep error
        // check if there is short or long onToken in vault
        // do not allow settling vault that have no short or long onToken
        // if there is a long onToken, burn it
        // store onToken address outside of this scope
        {
            bool hasLong = vault.longONtoken != address(0);

            onToken = ONtokenInterface(vault.shortONtoken);

            if (hasLong && vault.longAmount > 0) {
                ONtokenInterface longONtoken = ONtokenInterface(vault.longONtoken);

                longONtoken.burnONtoken(address(pool), vault.longAmount);
            }
        }

        (address[] memory collaterals, address underlying, address strike, uint256 expiry) = _getONtokenDetails(
            address(onToken)
        );

        // do not allow settling vault with un-expired onToken
        require(block.timestamp >= expiry, "C25");
        require(canSettleAssets(underlying, strike, collaterals, expiry), "C24");

        uint256[] memory payouts = calculator.getExcessCollateral(vault);

        delete vaults[_args.owner][_args.vaultId];

        for (uint256 i = 0; i < collaterals.length; i++) {
            if (payouts[i] != 0) {
                pool.transferToUser(collaterals[i], _args.to, payouts[i]);
            }
        }

        uint256 vaultId = _args.vaultId;
        address payoutRecipient = _args.to;

        emit VaultSettled(_args.owner, address(onToken), payoutRecipient, payouts, vaultId);
    }

    /**
     * @notice check if a vault id is valid for a given account owner address
     * @param _accountOwner account owner address
     * @param _vaultId vault id to check
     * @return True if the _vaultId is valid, False if not
     */
    function _checkVaultId(address _accountOwner, uint256 _vaultId) internal view returns (bool) {
        return ((_vaultId > 0) && (_vaultId <= accountVaultCounter[_accountOwner]));
    }

    /**
     * @dev get onToken detail
     * @return collaterals, of onToken
     * @return underlying, of onToken
     * @return strike, of onToken
     * @return expiry, of onToken
     */
    function _getONtokenDetails(address _onToken)
        internal
        view
        returns (
            address[] memory,
            address,
            address,
            uint256
        )
    {
        ONtokenInterface onToken = ONtokenInterface(_onToken);
        (address[] memory collaterals, , , , address underlying, address strike, , uint256 expiry, , ) = onToken
            .getONtokenDetails();
        return (collaterals, underlying, strike, expiry);
    }

    /**
     * @dev return if underlying, strike, collateral are all allowed to be settled
     * @param _underlying onToken underlying asset
     * @param _strike onToken strike asset
     * @param _collaterals onToken collateral assets
     * @param _expiry onToken expiry timestamp
     * @return True if the onToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function canSettleAssets(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        uint256 _expiry
    ) public view returns (bool) {
        bool canSettle = true;
        for (uint256 i = 0; i < _collaterals.length; i++) {
            canSettle = canSettle && oracle.isDisputePeriodOver(_collaterals[i], _expiry);
        }
        return
            canSettle &&
            oracle.isDisputePeriodOver(_underlying, _expiry) &&
            oracle.isDisputePeriodOver(_strike, _expiry);
    }

    /**
     * @dev updates the internal configuration of the controller
     */
    function _refreshConfigInternal() internal {
        whitelist = WhitelistInterface(addressbook.getWhitelist());
        oracle = OracleInterface(addressbook.getOracle());
        calculator = MarginCalculatorInterface(addressbook.getMarginCalculator());
        pool = MarginPoolInterface(addressbook.getMarginPool());
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * @title Actions
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 * errorCode
 * A1 can only parse arguments for open vault actions
 * A2 cannot open vault for an invalid account
 * A3 cannot open vault with an invalid type
 * A4 can only parse arguments for mint actions
 * A5 cannot mint from an invalid account
 * A6 can only parse arguments for burn actions
 * A7 cannot burn from an invalid account
 * A8 can only parse arguments for deposit collateral action
 * A9 cannot deposit to an invalid account
 * A10 can only parse arguments for withdraw actions
 * A11 cannot withdraw from an invalid account
 * A12 cannot withdraw to an invalid account
 * A13 can only parse arguments for redeem actions
 * A14 cannot redeem to an invalid account
 * A15 can only parse arguments for settle vault actions
 * A16 cannot settle vault for an invalid account
 * A17 cannot withdraw payout to an invalid account
 * A18 can only parse arguments for liquidate action
 * A19 cannot liquidate vault for an invalid account owner
 * A20 cannot send collateral to an invalid account
 * A21 cannot parse liquidate action with no round id
 * A22 can only parse arguments for call actions
 * A23 target address cannot be address(0)
 * A24 amounts for minting onToken should be array with 1 element
 * A26 param "assets" should have 1 element for redeem action
 * A27 param "assets" first element should not be zero address for redeem action
 * A28 param "amounts" should have 1 element for redeem action
 * A29 param "amounts" first element should not be zero, cant redeem zero amount
 * A30 param "amounts" should be same length as param "assets"
 * A31 param "assets" should have 1 element for depositLong action
 * A32 param "amounts" should have 1 element for depositLong action
 * A33 param "amounts" should have 1 element for withdrawLong action
 * A34 param "amounts" should have 1 element for burnShort action
 * A35 param "assets" should have 1 element for burnShort action
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address[] assets;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256[] amounts;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted onTokens
        address to;
        // amount of onTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the onToken will be burned
        uint256 vaultId;
        // amount of onTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // We restrict vault to be specific for existing onToken so it's collaterals assets will be the same as onToken's
        address shortONtoken;
        // vault id to create
        uint256 vaultId;
    }

    struct DepositCollateralArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // amount of asset that is to be deposited
        uint256[] amounts;
    }

    struct DepositLongArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address longONtoken;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the onToken proceeds
        address receiver;
        // onToken that is to be redeemed
        address onToken;
        // amount of onTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawLongArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // amounts of long that is to be withdrawn
        uint256 amount;
    }

    struct WithdrawCollateralArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // amounts of collateral assets that is to be withdrawn
        uint256[] amounts;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "A1");
        require(_args.owner != address(0), "A2");

        return OpenVaultArgs({ shortONtoken: _args.secondAddress, owner: _args.owner, vaultId: _args.vaultId });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "A4");
        require(_args.owner != address(0), "A5");
        require(_args.amounts.length == 1, "A24");

        return
            MintArgs({ owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress, amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "A6");
        require(_args.owner != address(0), "A7");
        require(_args.amounts.length == 1, "A34");

        return BurnArgs({ owner: _args.owner, vaultId: _args.vaultId, amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositCollateralArgs(ActionArgs memory _args) internal pure returns (DepositCollateralArgs memory) {
        require(_args.actionType == ActionType.DepositCollateral, "A8");
        require(_args.owner != address(0), "A9");

        return
            DepositCollateralArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                amounts: _args.amounts
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositLongArgs(ActionArgs memory _args) internal pure returns (DepositLongArgs memory) {
        require(_args.actionType == ActionType.DepositLongOption, "A35");
        require(_args.owner != address(0), "A9");
        require(_args.assets.length == 1, "A31");
        require(_args.amounts.length == 1, "A32");

        return
            DepositLongArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                longONtoken: _args.assets[0],
                amount: _args.amounts[0]
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawLongArgs(ActionArgs memory _args) internal pure returns (WithdrawLongArgs memory) {
        require((_args.actionType == ActionType.WithdrawLongOption), "A10");
        require(_args.owner != address(0), "A11");
        require(_args.secondAddress != address(0), "A12");
        require(_args.amounts.length == 1, "A33");

        return
            WithdrawLongArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                amount: _args.amounts[0]
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawCollateralArgs(ActionArgs memory _args)
        internal
        pure
        returns (WithdrawCollateralArgs memory)
    {
        require((_args.actionType == ActionType.WithdrawCollateral), "A10");
        require(_args.owner != address(0), "A11");
        require(_args.secondAddress != address(0), "A12");

        return
            WithdrawCollateralArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                amounts: _args.amounts
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "A13");
        require(_args.secondAddress != address(0), "A14");
        require(_args.assets.length == 1, "A26");
        require(_args.assets[0] != address(0), "A27");
        require(_args.amounts.length == 1, "A28");
        require(_args.amounts[0] != 0, "A29");

        return RedeemArgs({ receiver: _args.secondAddress, onToken: _args.assets[0], amount: _args.amounts[0] });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(_args.actionType == ActionType.SettleVault, "A15");
        require(_args.owner != address(0), "A16");
        require(_args.secondAddress != address(0), "A17");

        return SettleVaultArgs({ owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress });
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FPI } from "../libs/FixedPointInt256.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short onToken amount
 * V2: invalid short onToken index
 * V3: short onToken address mismatch
 * V4: invalid long onToken amount
 * V5: invalid long onToken index
 * V6: long onToken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 * V10: shortONtoken should be empty when performing addShort or the same as vault already have
 * V11: _collateralAssets and _amounts length mismatch
 * V12: _collateralAssets and vault.collateralAssets length mismatch
 * V13: _amount for withdrawing long is exceeding unused long amount in the vault
 * V14: amounts for withdrawing collaterals should be same length as collateral assets of vault
 */

/**
 * @title MarginVault
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    uint256 internal constant BASE = 8;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        address shortONtoken;
        // addresses of onTokens a user has shorted (i.e. written) against this vault
        // addresses of onTokens a user has bought and deposited in this vault
        // user can be long onTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long onTokens will be 'deposited' in vaults to act as collateral in order to write onTokens against (i.e. in spreads)
        address longONtoken;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of onTokens minted/written for each onToken address in onTokenAddress
        uint256 shortAmount;
        // quantity of onTokens owned and held in the vault for each onToken address in longONtokens
        uint256 longAmount;
        uint256 usedLongAmount;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // Collateral which is currently used for minting onTokens and can't be used until expiry
        uint256[] reservedCollateralAmounts;
        uint256[] usedCollateralValues;
        uint256[] availableCollateralAmounts;
    }

    /**
     * @dev increase the short onToken balance in a vault when a new onToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _amount number of _shortONtoken being minted from the user's vault
     */
    function addShort(Vault storage _vault, uint256 _amount) external {
        require(_amount > 0, "V1");
        _vault.shortAmount = _vault.shortAmount.add(_amount);
    }

    /**
     * @dev decrease the short onToken balance in a vault when an onToken is burned
     * @param _vault vault to decrease short position in
     * @param _amount number of _shortONtoken being reduced in the user's vault
     * @param _newCollateralRatio ratio represents how much of already used collateral will be used after burn
     * @param _newUsedLongAmount new used long amount
     */
    function removeShort(
        Vault storage _vault,
        uint256 _amount,
        FPI.FixedPointInt memory _newCollateralRatio,
        uint256 _newUsedLongAmount
    ) external returns (uint256[] memory freedCollateralAmounts, uint256[] memory freedCollateralValues) {
        // check that the removed short onToken exists in the vault

        uint256 newShortAmount = _vault.shortAmount.sub(_amount);
        uint256 collateralAssetsLength = _vault.collateralAssets.length;

        uint256[] memory newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
        uint256[] memory newUsedCollateralValues = new uint256[](collateralAssetsLength);
        freedCollateralAmounts = new uint256[](collateralAssetsLength);
        freedCollateralValues = new uint256[](collateralAssetsLength);
        uint256[] memory newAvailableCollateralAmounts = _vault.availableCollateralAmounts;
        // If new short amount is zero, just free all reserved collateral
        if (newShortAmount == 0) {
            newAvailableCollateralAmounts = _vault.collateralAmounts;

            newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
            newUsedCollateralValues = new uint256[](collateralAssetsLength);
            freedCollateralAmounts = _vault.reservedCollateralAmounts;
            freedCollateralValues = _vault.usedCollateralValues;
        } else {
            // _newCollateralRatio is multiplier which is used to calculate the new used collateral values and used amounts
            for (uint256 i = 0; i < collateralAssetsLength; i++) {
                uint256 collateralDecimals = uint256(IERC20Metadata(_vault.collateralAssets[i]).decimals());
                newReservedCollateralAmounts[i] = toFPImulAndBack(
                    _vault.reservedCollateralAmounts[i],
                    collateralDecimals,
                    _newCollateralRatio,
                    true
                );

                newUsedCollateralValues[i] = toFPImulAndBack(
                    _vault.usedCollateralValues[i],
                    BASE,
                    _newCollateralRatio,
                    true
                );
                freedCollateralAmounts[i] = _vault.reservedCollateralAmounts[i].sub(newReservedCollateralAmounts[i]);
                freedCollateralValues[i] = _vault.usedCollateralValues[i].sub(newUsedCollateralValues[i]);
                newAvailableCollateralAmounts[i] = newAvailableCollateralAmounts[i].add(freedCollateralAmounts[i]);
            }
        }
        _vault.shortAmount = newShortAmount;
        _vault.reservedCollateralAmounts = newReservedCollateralAmounts;
        _vault.usedCollateralValues = newUsedCollateralValues;
        _vault.availableCollateralAmounts = newAvailableCollateralAmounts;
        _vault.usedLongAmount = _newUsedLongAmount;
    }

    /**
     * @dev helper function to transform uint256 to FPI multiply by another FPI and transform back to uint256
     */
    function toFPImulAndBack(
        uint256 _value,
        uint256 _decimals,
        FPI.FixedPointInt memory _multiplicator,
        bool roundDown
    ) internal pure returns (uint256) {
        return FPI.fromScaledUint(_value, _decimals).mul(_multiplicator).toScaledUint(_decimals, roundDown);
    }

    /**
     * @dev increase the long onToken balance in a vault when an onToken is deposited
     * @param _vault vault to add a long position to
     * @param _longONtoken address of the _longONtoken being added to the user's vault
     * @param _amount number of _longONtoken the protocol is adding to the user's vault
     */
    function addLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        require(_amount > 0, "V4");
        address existingLong = _vault.longONtoken;
        require((existingLong == _longONtoken) || (existingLong == address(0)), "V6");

        _vault.longAmount = _vault.longAmount.add(_amount);
        _vault.longONtoken = _longONtoken;
    }

    /**
     * @dev decrease the long onToken balance in a vault when an onToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longONtoken address of the _longONtoken being removed from the user's vault
     * @param _amount number of _longONtoken the protocol is removing from the user's vault
     */
    function removeLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        // check that the removed long onToken exists in the vault at the specified index
        require(_vault.longONtoken == _longONtoken, "V6");

        uint256 vaultLongAmountBefore = _vault.longAmount;
        require((vaultLongAmountBefore - _vault.usedLongAmount) >= _amount, "V13");

        _vault.longAmount = vaultLongAmountBefore.sub(_amount);
    }

    /**
     * @dev increase the collaterals balances in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAssets addresses of the _collateralAssets being added to the user's vault
     * @param _amounts number of _collateralAssets being added to the user's vault
     */
    function addCollaterals(
        Vault storage _vault,
        address[] calldata _collateralAssets,
        uint256[] calldata _amounts
    ) external {
        require(_collateralAssets.length == _amounts.length, "V11");
        require(_collateralAssets.length == _vault.collateralAssets.length, "V12");
        for (uint256 i = 0; i < _collateralAssets.length; i++) {
            _vault.collateralAmounts[i] = _vault.collateralAmounts[i].add(_amounts[i]);
            _vault.availableCollateralAmounts[i] = _vault.availableCollateralAmounts[i].add(_amounts[i]);
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _amounts number of _collateralAssets being removed from the user's vault
     */
    function removeCollateral(Vault storage _vault, uint256[] memory _amounts) external {
        address[] memory collateralAssets = _vault.collateralAssets;
        require(_amounts.length == collateralAssets.length, "V14");

        uint256[] memory availableCollateralAmounts = _vault.availableCollateralAmounts;
        uint256[] memory collateralAmounts = _vault.collateralAmounts;
        for (uint256 i = 0; i < collateralAssets.length; i++) {
            collateralAmounts[i] = _vault.collateralAmounts[i].sub(_amounts[i]);
            availableCollateralAmounts[i] = availableCollateralAmounts[i].sub(_amounts[i]);
        }
        _vault.collateralAmounts = collateralAmounts;
        _vault.availableCollateralAmounts = availableCollateralAmounts;
    }

    /**
     * @dev decrease vaults avalaible collateral and long to update vaults used assets data
     * used when vaults mint option to lock provided assets
     * @param _vault vault to remove collateral from
     * @param _amounts amount of collateral assets being locked in the user's vault
     * @param _usedLongAmount amount of long onToken being locked in the user's vault
     * @param _usedCollateralValues values of collaterals amounts being locked
     */
    function useVaultsAssets(
        Vault storage _vault,
        uint256[] memory _amounts,
        uint256 _usedLongAmount,
        uint256[] memory _usedCollateralValues
    ) external {
        require(
            _amounts.length == _vault.collateralAssets.length,
            "Amounts for collateral is not same length as collateral assets"
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 newReservedCollateralAmount = _vault.reservedCollateralAmounts[i].add(_amounts[i]);

            _vault.reservedCollateralAmounts[i] = newReservedCollateralAmount;
            require(
                _vault.reservedCollateralAmounts[i] <= _vault.collateralAmounts[i],
                "Trying to use collateral which exceeds vault's balance"
            );
            _vault.availableCollateralAmounts[i] = _vault.collateralAmounts[i].sub(newReservedCollateralAmount);
            _vault.usedCollateralValues[i] = _vault.usedCollateralValues[i].add(_usedCollateralValues[i]);
        }

        _vault.usedLongAmount = _vault.usedLongAmount.add(_usedLongAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ONtokenInterface {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnONtoken(address account, uint256 amount) external;

    function reduceCollaterization(
        uint256[] calldata collateralsAmountsForReduce,
        uint256[] calldata collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external;

    function getCollateralAssets() external view returns (address[] memory);

    function getCollateralsAmounts() external view returns (uint256[] memory);

    function getCollateralConstraints() external view returns (uint256[] memory);

    function collateralsValues(uint256) external view returns (uint256);

    function getCollateralsValues() external view returns (uint256[] memory);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function collaterizedTotalAmount() external view returns (uint256);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function expiryTimestamp() external view returns (uint256);

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external;

    function isPut() external view returns (bool);

    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] memory collateralsAmountsForMint,
        uint256[] memory collateralsValuesForMint
    ) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function strikeAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface AddressBookInterface {
    /* Getters */

    function getONtokenImpl() external view returns (address);

    function getONtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setONtokenImpl(address _onTokenImpl) external;

    function setONtokenFactory(address _factory) external;

    function setOracleImpl(address _onTokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

import { MarginVault } from "../libs/MarginVault.sol";
import { FPI } from "../libs/FixedPointInt256.sol";

interface MarginCalculatorInterface {
    function getAfterBurnCollateralRatio(MarginVault.Vault memory _vault, uint256 _shortBurnAmount)
        external
        view
        returns (FPI.FixedPointInt memory, uint256);

    function getCollateralsToCoverShort(MarginVault.Vault memory _vault, uint256 _shortAmount)
        external
        view
        returns (
            uint256[] memory collateralsAmountsRequired,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed,
            uint256 usedLongAmount
        );

    function isMarginableLong(address longONtokenAddress, MarginVault.Vault memory _vault) external view returns (bool);

    function getExcessCollateral(MarginVault.Vault memory _vault) external view returns (uint256[] memory);

    function getExpiredPayoutRate(address _onToken) external view returns (uint256[] memory);

    function getMaxShortAmount(MarginVault.Vault memory _vault) external view returns (uint256);

    function getPayout(address _onToken, uint256 _amount) external view returns (uint256[] memory);

    function oracle() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

interface FixedPointInt256 {
    struct FixedPointInt {
        int256 value;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface WhitelistInterface {
    function addressBook() external view returns (address);

    function blacklistCollateral(address[] memory _collaterals) external;

    function blacklistONtoken(address _onTokenAddress) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;

    function isWhitelistedCollaterals(address[] memory _collaterals) external view returns (bool);

    function isWhitelistedONtoken(address _onToken) external view returns (bool);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] memory _collateral,
        bool _isPut
    ) external view returns (bool);

    //  function owner() external view returns (address);

    //  function renounceOwnership() external;

    //  function transferOwnership(address newOwner) external;

    function whitelistCollaterals(address[] memory _collaterals) external;

    function whitelistONtoken(address _onTokenAddress) external;

    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * Utils library for comparing arrays of addresses
 */
library ArrayAddressUtils {
    /**
     * @dev uses hashes of array to compare, therefore arrays with different order of same elements wont be equal
     * @param arr1 address[]
     * @param arr2 address[]
     * @return bool
     */
    function isEqual(address[] memory arr1, address[] memory arr2) external pure returns (bool) {
        return keccak256(abi.encodePacked(arr1)) == keccak256(abi.encodePacked(arr2));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface MarginPoolInterface {
    /* Getters */
    function addressBook() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import { SignedConverter } from "./SignedConverter.sol";

/**
 * @title FixedPointInt256
 * @notice FixedPoint library
 */
library FPI {
    using SignedSafeMath for int256;
    using SignedConverter for int256;
    using SafeMath for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 5.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.05 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * @title SignedConverter
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
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