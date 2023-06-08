// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {TokenIdUtil} from "grappa/libraries/TokenIdUtil.sol";

// abstracts
import {CashOptionsVault} from "../mixins/options/CashOptionsVault.sol";
import {SingleOptionCashVaultStorage} from "./SingleOptionCashVaultStorage.sol";

import {TokenType} from "grappa/config/types.sol";

import "./errors.sol";
import "../../../config/types.sol";
import {PLACEHOLDER_UINT} from "../../../config/constants.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in VaultStorage.
 * SingleOptionVault should not inherit from any other contract aside from OptionVault, VaultStorage
 */
contract SingleOptionCashVault is CashOptionsVault, SingleOptionCashVaultStorage {
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) CashOptionsVault(_share, _marginEngine) {}

    /**
     * @notice Initializes the OptionsVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _auction is the address that settles the option contract
     * @param _token is the golden token to compare options against
     */
    function initialize(InitParams calldata _initParams, address _auction, uint256 _token) external initializer {
        __OptionsVault_init(_initParams, _auction);

        (, uint40 productId,,,) = _token.parseTokenId();

        if (productId == 0) revert SOCV_BadProductId();

        goldenToken = _token;
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    function verifyOptions(uint256[] calldata _options) external view override {
        uint256 currentRoundExpiry = roundExpiry[vaultState.round];

        // initRounds set value to 1, so 0 or 1 are seed values
        if (currentRoundExpiry <= PLACEHOLDER_UINT) revert SOCV_BadExpiry();

        (TokenType tokenType, uint40 productId,,,) = goldenToken.parseTokenId();

        for (uint256 i; i < _options.length;) {
            (TokenType tokenType_, uint40 productId_, uint64 expiry,,) = _options[i].parseTokenId();

            if (tokenType_ != tokenType) revert SOCV_TokenTypeMismatch();

            if (productId_ != productId) revert SOCV_ProductIdMismatch();

            // expirations need to match
            if (currentRoundExpiry != expiry) revert SOCV_ExpiryMismatch();

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/errors.sol";

/**
 * Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | reserved    (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 */

library TokenIdUtil {
    /**
     * @notice calculate ERC1155 token id for given option parameters. See table above for tokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @param reserved strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     * @return tokenId token id
     */
    function getTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 reserved)
        internal
        pure
        returns (uint256 tokenId)
    {
        unchecked {
            tokenId = (uint256(tokenType) << 232) + (uint256(productId) << 192) + (uint256(expiry) << 128)
                + (uint256(longStrike) << 64) + uint256(reserved);
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from ERC1155 token id
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     * @return reserved strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 reserved)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            longStrike := shr(64, tokenId)
            reserved := tokenId
        }
    }

    /**
     * @notice parse collateral id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return collateralId
     */
    function parseCollateralId(uint256 tokenId) internal pure returns (uint8 collateralId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            collateralId := shr(192, tokenId)
        }
    }

    /**
     * @notice parse engine id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return engineId
     */
    function parseEngineId(uint256 tokenId) internal pure returns (uint8 engineId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            engineId := shr(216, tokenId) // 192 to get product id, another 24 to get engineId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
        }
    }

    /**
     * @notice derive if option is expired from ERC1155 token id
     * @param tokenId token id
     * @return expired bool
     */
    function isExpired(uint256 tokenId) internal view returns (bool expired) {
        uint64 expiry;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            expiry := shr(128, tokenId)
        }

        expired = block.timestamp >= expiry;
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | spread type (24 b)  | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   this function will: override tokenType, remove shortStrike.
     * @param _tokenId token id to change
     */
    function convertToVanillaId(uint256 _tokenId) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // step 1: >> 64 to wipe out shortStrike
            newId := shl(64, newId) // step 2: << 64 go back

            newId := sub(newId, shl(232, 1)) // step 3: new tokenType = spread type - 1
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | spread type         | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * this function convert put or call type to spread type, add shortStrike.
     * @param _tokenId token id to change
     * @param _shortStrike strike to add
     */
    function convertToSpreadId(uint256 _tokenId, uint256 _shortStrike) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        unchecked {
            newId = _tokenId + _shortStrike;
            return newId + (1 << 232); // new type (spread type) = old type + 1
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// inherited contracts
import {BaseOptionsVault} from "./BaseOptionsVault.sol";

// interfaces
import {IMarginEngineCash} from "../../../../interfaces/IMarginEngine.sol";

// libraries
import {StructureLib} from "../../../../libraries/StructureLib.sol";

import "../../../../config/errors.sol";
import "../../../../config/types.sol";

abstract contract CashOptionsVault is BaseOptionsVault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice marginAccount is the options protocol collateral pool
    IMarginEngineCash public immutable marginEngine;

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     * @param _marginEngine is the margin engine used for Grappa (options protocol)
     */
    constructor(address _share, address _marginEngine) BaseOptionsVault(_share) {
        if (_marginEngine == address(0)) revert BadAddress();

        marginEngine = IMarginEngineCash(_marginEngine);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function overrides
    //////////////////////////////////////////////////////////////*/

    function _getMarginAccount()
        internal
        view
        virtual
        override
        returns (Position[] memory, Position[] memory, Balance[] memory)
    {
        return marginEngine.marginAccounts(address(this));
    }

    function _setAuctionMarginAccountAccess(uint256 _allowedExecutions) internal virtual override {
        marginEngine.setAccountAccess(auction, _allowedExecutions);
    }

    function _marginEngineAddr() internal view virtual override returns (address) {
        return address(marginEngine);
    }

    function _settleOptions() internal virtual override {
        StructureLib.settleOptions(marginEngine);
    }

    function _withdrawCollateral(Collateral[] memory _collaterals, uint256[] memory _amounts, address _recipient)
        internal
        virtual
        override
    {
        StructureLib.withdrawCollaterals(marginEngine, _collaterals, _amounts, _recipient);
    }

    function _depositCollateral(Collateral[] memory _collaterals) internal virtual override {
        StructureLib.depositCollateral(marginEngine, _collaterals);
    }

    function _withdrawWithShares(uint256 _totalSupply, uint256 _shares, address _pauser)
        internal
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return StructureLib.withdrawWithShares(marginEngine, _totalSupply, _shares, _pauser);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract SingleOptionCashVaultStorageV1 {
    // Token details the vault is able to mint options against
    // Only uses TokenType and productId
    uint256 public goldenToken;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of VaultStorage
// e.g. VaultStorage<versionNumber>, so finally it would look like
// contract VaultStorage is VaultStorageV1, VaultStorageV2
abstract contract SingleOptionCashVaultStorage is SingleOptionCashVaultStorageV1 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId grappa asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address oracle;
    uint8 oracleId;
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../../config/errors.sol";

// Vault
error SOCV_BadExpiry();
error SOCV_ExpiryMismatch();
error SOCV_ProductIdMismatch();
error SOCV_TokenTypeMismatch();
error SOCV_MarginEngineMismatch();
error SOCV_BadProductId();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice Initialization parameters for the vault.
 * @param _owner is the owner of the vault with critical permissions
 * @param _manager is the address that is responsible for advancing the vault
 * @param _feeRecipient is the address to receive vault performance and management fees
 * @param _oracle is used to calculate NAV
 * @param _whitelist is used to check address access permissions
 * @param _managementFee is the management fee pct.
 * @param _performanceFee is the performance fee pct.
 * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
 * @param _collateralRatios is the array of round starting balances to set the initial collateral ratios
 * @param _collaterals is the assets used in the vault
 * @param _roundConfig sets the duration and expiration of options
 * @param _vaultParams set vaultParam struct
 */
struct InitParams {
    address _owner;
    address _manager;
    address _feeRecipient;
    address _oracle;
    address _whitelist;
    uint256 _managementFee;
    uint256 _performanceFee;
    address _pauser;
    uint256[] _collateralRatios;
    Collateral[] _collaterals;
    RoundConfig _roundConfig;
}

struct Collateral {
    // Grappa asset Id
    uint8 id;
    // ERC20 token address for the required collateral
    address addr;
    // the amount of decimals or token
    uint8 decimals;
}

struct VaultState {
    // 32 byte slot 1
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Amount that is currently locked for selling options
    uint96 lockedAmount;
    // Amount that was locked for selling options in the previous round
    // used for calculating performance fee deduction
    uint96 lastLockedAmount;
    // 32 byte slot 2
    // Stores the total tally of how much of `asset` there is
    // to be used to mint vault tokens
    uint96 totalPending;
    // store the number of shares queued for withdraw this round
    // zero'ed out at the start of each round, pauser withdraws all queued shares.
    uint128 queuedWithdrawShares;
}

struct DepositReceipt {
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Deposit amount, max 79,228,162,514 or 79 Billion ETH deposit
    uint96 amount;
    // Unredeemed shares balance
    uint128 unredeemedShares;
}

struct RoundConfig {
    // the duration of the option
    uint32 duration;
    // day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
    uint8 dayOfWeek;
    // hour of the day the option should expire. 0 is midnight
    uint8 hourOfDay;
}

// Used for fee calculations at the end of a round
struct VaultDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] roundStartingBalances;
    // current balances
    uint256[] currentBalances;
    // Total pending primary asset
    uint256 totalPending;
}

// Used when rolling funds into a new round
struct NAVDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] startingBalances;
    // Current collateral balances
    uint256[] currentBalances;
    // Used to calculate NAV
    address oracleAddr;
    // Expiry of the round
    uint256 expiry;
    // Pending deposits
    uint256 totalPending;
}

/**
 * @dev Position struct
 * @param tokenId option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

// Placeholder uint value to prevent cold writes
uint256 constant PLACEHOLDER_UINT = 1;

// Fees are 18-decimal places. For example: 20 * 10**18 = 20%
uint256 constant PERCENT_MULTIPLIER = 10 ** 18;

uint32 constant SECONDS_PER_DAY = 86400;
uint32 constant DAYS_PER_YEAR = 365;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    PUT_SPREAD,
    CALL,
    CALL_SPREAD
}

/**
 * @dev common action types on margin engines
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken, // These actions are defined in "DebitSpread"
    SplitOptionToken, // These actions are defined in "DebitSpread"
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influence more than one subAccounts:
    // These actions are defined in "OptionTransferable"
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral directly to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// for easier import
import "../core/oracles/errors.sol";

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      Grappa Errors       *
 * -----------------------  */

/// @dev asset already registered
error GP_AssetAlreadyRegistered();

/// @dev margin engine already registered
error GP_EngineAlreadyRegistered();

/// @dev oracle already registered
error GP_OracleAlreadyRegistered();

/// @dev registring oracle doesn't comply with the max dispute period constraint.
error GP_BadOracle();

/// @dev amounts length speicified to batch settle doesn't match with tokenIds
error GP_WrongArgumentLength();

/// @dev cannot settle an unexpired option
error GP_NotExpired();

/// @dev settlement price is not finalized yet
error GP_PriceNotFinalized();

/// @dev cannot mint token after expiry
error GP_InvalidExpiry();

/// @dev put and call should not contain "short stirkes"
error GP_BadStrikes();

/// @dev burn or mint can only be called by corresponding engine.
error GP_Not_Authorized_Engine();

/* ---------------------------- *
 *   Common BaseEngine Errors   *
 * ---------------------------  */

/// @dev can only merge subaccount with put or call.
error BM_CannotMergeSpread();

/// @dev only spread position can be split
error BM_CanOnlySplitSpread();

/// @dev type of existing short token doesn't match the incoming token
error BM_MergeTypeMismatch();

/// @dev product type of existing short token doesn't match the incoming token
error BM_MergeProductMismatch();

/// @dev expiry of existing short token doesn't match the incoming token
error BM_MergeExpiryMismatch();

/// @dev cannot merge type with the same strike. (should use burn instead)
error BM_MergeWithSameStrike();

/// @dev account is not healthy / account is underwater
error BM_AccountUnderwater();

/// @dev msg.sender is not authorized to ask margin account to pull token from {from} address
error BM_InvalidFromAddress();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseVault} from "../../BaseVault.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IAuctionVault} from "../../../../interfaces/IAuctionVault.sol";
import {IPositionPauser} from "../../../../interfaces/IPositionPauser.sol";

// libraries
import {FeeLib} from "../../../../libraries/FeeLib.sol";
import {StructureLib} from "../../../../libraries/StructureLib.sol";
import {VaultLib} from "../../../../libraries/VaultLib.sol";

import "../../../../config/errors.sol";
import "../../../../config/constants.sol";
import "../../../../config/types.sol";

abstract contract BaseOptionsVault is BaseVault, IAuctionVault {
    /*///////////////////////////////////////////////////////////////
                        Storage V1
    //////////////////////////////////////////////////////////////*/
    // auction contract
    address public auction;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[24] private __gap;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event AuctionSet(address auction, address newAuction);

    event MarginAccountAccessSet(address auction, uint256 allowedExecutions);

    event StagedAuction(uint256 indexed expiry, uint32 round);

    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     */
    constructor(address _share) BaseVault(_share) {}

    function __OptionsVault_init(InitParams calldata _initParams, address _auction) internal onlyInitializing {
        __BaseVault_init(_initParams);

        // verifies that initial collaterals are present
        StructureLib.verifyInitialCollaterals(_initParams._collaterals);

        if (_auction == address(0)) revert BadAddress();

        auction = _auction;
    }

    /*///////////////////////////////////////////////////////////////
                                Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new batch auction address
     * @param _auction is the auction duration address
     */
    function setAuction(address _auction) external {
        _onlyOwner();

        if (_auction == address(0)) revert BadAddress();

        emit AuctionSet(auction, _auction);

        auction = _auction;
    }

    /**
     * @notice Sets the auction allowable executions on the margin account
     * @param _allowedExecutions how many times the account is authorized to update vault account.
     *        set to max(uint256) to allow unlimited access
     */
    function setAuctionMarginAccountAccess(uint256 _allowedExecutions) external {
        _onlyManager();

        emit MarginAccountAccessSet(auction, _allowedExecutions);

        _setAuctionMarginAccountAccess(_allowedExecutions);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the amount of collateral to use in the next auction
     * @dev performing asset requirements off-chain to save gas fees
     */
    function stageAuction() external {
        _onlyManager();

        uint256 expiry = _setRoundExpiry();

        _setAuctionMarginAccountAccess(type(uint256).max);

        emit StagedAuction(expiry, vaultState.round);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal function to override
    //////////////////////////////////////////////////////////////*/

    function _marginEngineAddr() internal view virtual returns (address) {}

    function _getMarginAccount() internal view virtual returns (Position[] memory, Position[] memory, Balance[] memory) {}

    function _setAuctionMarginAccountAccess(uint256 _allowedExecutions) internal virtual {}

    function _settleOptions() internal virtual {}

    function _withdrawCollateral(Collateral[] memory _collaterals, uint256[] memory _amounts, address _recipient)
        internal
        virtual
    {}

    function _depositCollateral(Collateral[] memory _collaterals) internal virtual {}

    function _withdrawWithShares(uint256 _totalSupply, uint256 _shares, address _pauser)
        internal
        virtual
        returns (uint256[] memory amounts)
    {}

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Settles the existing option(s)
     */
    function _beforeCloseRound() internal virtual override {
        VaultState memory vState = vaultState;

        if (vState.round == 1) return;

        uint256 currentExpiry = roundExpiry[vState.round];

        if (currentExpiry <= PLACEHOLDER_UINT) revert OV_RoundClosed();

        if (currentExpiry > block.timestamp) {
            if (vState.totalPending == 0) revert OV_NoCollateralPending();
        } else {
            (Position[] memory shorts, Position[] memory longs,) = _getMarginAccount();

            if (shorts.length == 0 && longs.length == 0) revert OV_RoundClosed();

            _settleOptions();
        }
    }

    /**
     * @notice Sets the next options expiry
     */
    function _setRoundExpiry() internal virtual returns (uint256 newExpiry) {
        uint256 currentRound = vaultState.round;

        if (currentRound == 1) revert OV_BadRound();

        uint256 currentExpiry = roundExpiry[currentRound];
        newExpiry = VaultLib.getNextExpiry(roundConfig);

        if (PLACEHOLDER_UINT < currentExpiry && currentExpiry < newExpiry) {
            (Position[] memory shorts, Position[] memory longs,) = _getMarginAccount();

            if (shorts.length > 0 || longs.length > 0) revert OV_ActiveRound();
        }

        roundExpiry[currentRound] = newExpiry;
    }

    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        override
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, roundStartingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        _withdrawCollateral(collaterals, totalFees, feeRecipient);

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal override {
        super._rollInFunds(_balances, _currentRound, _expiry);

        _depositCollateral(collaterals);
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual override returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares > 0) {
            vaultState.queuedWithdrawShares = 0;

            withdrawAmounts = _withdrawWithShares(share.totalSupply(address(this)), withdrawShares, pauser);

            // recording deposits with pauser for past round
            IPositionPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transferred to vault during requestWithdraw
            share.burn(address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        return withdrawAmounts[0];
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in _processFees, _rollInFunds and lockedAmount (in a rolling close)
     */
    function _getCurrentBalances() internal view virtual override returns (uint256[] memory balances) {
        (,, Balance[] memory marginCollaterals) = _getMarginAccount();

        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            if (marginCollaterals.length > i) balances[i] += marginCollaterals[i].amount;

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGrappa} from "grappa/interfaces/IGrappa.sol";
import {IPomace} from "pomace/interfaces/IPomace.sol";

import {BatchExecute as GrappaBatchExecute, ActionArgs as GrappaActionArgs} from "grappa/config/types.sol";
import {BatchExecute as PomaceBatchExecute, ActionArgs as PomaceActionArgs} from "pomace/config/types.sol";
import "../config/types.sol";

interface IMarginEngine {
    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals);

    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory);

    function allowedExecutionLeft(uint160 mask, address account) external view returns (uint256);

    function setAccountAccess(address account, uint256 allowedExecutions) external;

    function revokeSelfAccess(address granter) external;
}

interface IMarginEngineCash is IMarginEngine {
    function grappa() external view returns (IGrappa grappa);

    function execute(address account, GrappaActionArgs[] calldata actions) external;

    function batchExecute(GrappaBatchExecute[] calldata batchActions) external;
}

interface IMarginEnginePhysical is IMarginEngine {
    function pomace() external view returns (IPomace pomace);

    function execute(address account, PomaceActionArgs[] calldata actions) external;

    function batchExecute(PomaceBatchExecute[] calldata batchActions) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {CashActionUtil} from "grappa/libraries/CashActionUtil.sol";
import {PhysicalActionUtil} from "pomace/libraries/PhysicalActionUtil.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IHashnoteVault} from "../interfaces/IHashnoteVault.sol";
import {IMarginEngineCash, IMarginEnginePhysical} from "../interfaces/IMarginEngine.sol";

import {ActionArgs as GrappaActionArgs} from "grappa/config/types.sol";
import {ActionArgs as PomaceActionArgs} from "pomace/config/types.sol";

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library StructureLib {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event WithdrewCollateral(uint256[] amounts, address indexed manager);

    /**
     * @notice verifies that initial collaterals are present (non-zero)
     * @param collaterals is the array of collaterals passed from initParams in initializer
     */
    function verifyInitialCollaterals(Collateral[] calldata collaterals) external pure {
        unchecked {
            for (uint256 i; i < collaterals.length; ++i) {
                if (collaterals[i].id == 0) revert OV_BadCollateral();
            }
        }
    }

    /**
     * @notice Settles the vaults position(s) in grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function settleOptions(IMarginEngineCash marginEngine) external {
        GrappaActionArgs[] memory actions = new GrappaActionArgs[](1);

        actions[0] = CashActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Settles the vaults position(s) in pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function settleOptions(IMarginEnginePhysical marginEngine) public {
        PomaceActionArgs[] memory actions = new PomaceActionArgs[](1);

        actions[0] = PhysicalActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function depositCollateral(IMarginEngineCash marginEngine, Collateral[] calldata collaterals) external {
        GrappaActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = CashActionUtil.append(
                    actions, CashActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function depositCollateral(IMarginEnginePhysical marginEngine, Collateral[] calldata collaterals) external {
        PomaceActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = PhysicalActionUtil.append(
                    actions, PhysicalActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws all vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawAllCollateral(IMarginEngineCash marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        GrappaActionArgs[] memory actions = new GrappaActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                CashActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws all vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace engine contract
     */
    function withdrawAllCollateral(IMarginEnginePhysical marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        PomaceActionArgs[] memory actions = new PomaceActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawCollaterals(
        IMarginEngineCash marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        GrappaActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = CashActionUtil.append(
                    actions, CashActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace margin engine contract
     */
    function withdrawCollaterals(
        IMarginEnginePhysical marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        PomaceActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = PhysicalActionUtil.append(
                    actions, PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from grappa margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(IMarginEngineCash marginEngine, uint256 totalSupply, uint256 withdrawShares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        GrappaActionArgs[] memory actions = new GrappaActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = CashActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from pomace margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(
        IMarginEnginePhysical marginEngine,
        uint256 totalSupply,
        uint256 withdrawShares,
        address recipient
    ) external returns (uint256[] memory amounts) {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        PomaceActionArgs[] memory actions = new PomaceActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();
error BadAddress();

// BaseVault
error BV_ActiveRound();
error BV_BadCollateral();
error BV_BadExpiry();
error BV_BadLevRatio();
error BV_ExpiryMismatch();
error BV_MarginEngineMismatch();
error BV_RoundClosed();
error BV_BadFee();
error BV_BadRoundConfig();
error BV_BadDepositAmount();
error BV_BadAmount();
error BV_BadRound();
error BV_BadNumShares();
error BV_ExceedsAvailable();
error BV_BadPPS();
error BV_BadSB();
error BV_BadCP();
error BV_BadRatios();

// OptionsVault
error OV_ActiveRound();
error OV_BadRound();
error OV_BadCollateral();
error OV_RoundClosed();
error OV_OptionNotExpired();
error OV_NoCollateralPending();
error OV_VaultExercised();

// PhysicalOptionVault
error POV_CannotRequestWithdraw();
error POV_NotExercised();
error POV_NoCollateral();
error POV_OptionNotExpired();
error POV_BadExerciseWindow();

// Fee Utils
error FL_NPSLow();

// Vault Utils
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_BadOwnerAddress();
error VL_BadManagerAddress();
error VL_BadFeeAddress();
error VL_BadOracleAddress();
error VL_BadPauserAddress();
error VL_BadFee();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();

// StructureLib
error SL_BadExpiryDate();

// Vault Pauser
error VP_VaultNotPermissioned();
error VP_PositionPaused();
error VP_Overflow();
error VP_CustomerNotPermissioned();
error VP_RoundOpen();

// Vault Share
error VS_SupplyExceeded();

// Whitelist Manager
error WL_BadRole();
error WL_Paused();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error OC_CannotReportForFuture();

error OC_PriceNotReported();

error OC_PriceReported();

///@dev cannot dispute the settlement price after dispute period is over
error OC_DisputePeriodOver();

///@dev cannot force-set an settlement price until grace period is passed and no one has set the price.
error OC_GracePeriodNotOver();

///@dev already disputed
error OC_PriceDisputed();

///@dev owner trying to set a dispute period that is invalid
error OC_InvalidDisputePeriod();

// Chainlink oracle

error CL_AggregatorNotSet();

error CL_StaleAnswer();

error CL_RoundIdTooSmall();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {VaultLib} from "../../libraries/VaultLib.sol";
import {FeeLib} from "../../libraries/FeeLib.sol";

import {IPositionPauser} from "../../interfaces/IPositionPauser.sol";
import {IVaultShare} from "../../interfaces/IVaultShare.sol";
import {IWhitelistManager} from "../../interfaces/IWhitelistManager.sol";

import "../../config/constants.sol";
import "../../config/enums.sol";
import "../../config/errors.sol";
import "../../config/types.sol";

contract BaseVault is ERC1155TokenReceiver, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Non Upgradeable Storage
    //////////////////////////////////////////////////////////////*/

    // the erc1155 contract that issues vault shares
    IVaultShare public immutable share;

    /// @notice Stores the user's pending deposit for the round
    mapping(address => DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an hnVault token is stored
    /// This is used to determine the number of shares to be given to a user with
    /// their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice deposit asset amounts; round => collateralBalances[]
    /// @dev    used in determining deposit ratios and NAV calculations
    ///         should not be used as a reference to collateral used in the round
    ///         because it does not account for assets that were queued for withdrawal
    mapping(uint256 => uint256[]) public roundStartingBalances;

    /// @notice deposit asset prices; round => CollateralPrices[]
    mapping(uint256 => uint256[]) public roundCollateralPrices;

    /// @notice expiry of each round
    mapping(uint256 => uint256) public roundExpiry;

    /// @notice Assets deposited into vault
    //          collaterals[0] is the primary asset, other assets are relative to the primary
    //          collaterals[0] is the premium / bidding token
    Collateral[] public collaterals;

    /// @notice Vault's round state
    VaultState public vaultState;

    /// @notice Vault's round configuration
    RoundConfig public roundConfig;

    // Oracle address to calculate Net Asset Value (for round share price)
    address public oracle;

    /// @notice Vault Pauser Contract for the vault
    address public pauser;

    /// @notice Whitelist contract, checks permissions and sanctions
    address public whitelist;

    /// @notice Fee recipient for the management and performance fees
    address public feeRecipient;

    /// @notice Role in charge of round operations
    address public manager;

    /// @notice Management fee charged on entire AUM at closeRound.
    uint256 public managementFee;

    /// @notice Performance fee charged on premiums earned in closeRound. Only charged when round takes a profit.
    uint256 public performanceFee;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed account, uint256[] amounts, uint256 round);

    event QuickWithdrew(address indexed account, uint256[] amounts, uint256 round);

    event RequestedWithdraw(address indexed account, uint256 shares, uint256 round);

    event Withdrew(address indexed account, uint256[] amounts, uint256 shares);

    event Redeem(address indexed account, uint256 share, uint256 round);

    event AddressSet(AddressType _type, address origAddress, address newAddress);

    event FeesSet(uint256 managementFee, uint256 newManagementFee, uint256 performanceFee, uint256 newPerformanceFee);

    event RoundConfigSet(
        uint32 duration, uint8 dayOfWeek, uint8 hourOfDay, uint32 newDuration, uint8 newDayOfWeek, uint8 newHourOfDay
    );

    event CollectedFees(uint256[] vaultFee, uint256 round, address indexed feeRecipient);

    /*///////////////////////////////////////////////////////////////
                        Constructor & Initializer
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor(address _share) {
        if (_share == address(0)) revert BadAddress();

        share = IVaultShare(_share);
    }

    /**
     * @notice Initializes the Vault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     */
    function __BaseVault_init(InitParams calldata _initParams) internal onlyInitializing {
        VaultLib.verifyInitializerParams(_initParams);

        _transferOwnership(_initParams._owner);
        __ReentrancyGuard_init_unchained();

        manager = _initParams._manager;

        oracle = _initParams._oracle;
        whitelist = _initParams._whitelist;
        feeRecipient = _initParams._feeRecipient;
        performanceFee = _initParams._performanceFee;
        managementFee = _initParams._managementFee;
        pauser = _initParams._pauser;
        roundConfig = _initParams._roundConfig;

        if (_initParams._collateralRatios.length > 0) {
            // set the initial ratios on the first round
            roundStartingBalances[1] = _initParams._collateralRatios;
            // set init price per share and expiry to placeholder values (1)
            roundPricePerShare[1] = PLACEHOLDER_UINT;
            roundExpiry[1] = PLACEHOLDER_UINT;
        }

        for (uint256 i; i < _initParams._collaterals.length;) {
            collaterals.push(_initParams._collaterals[i]);

            unchecked {
                ++i;
            }
        }

        vaultState.round = 1;
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _onlyOwner();
    }

    /*///////////////////////////////////////////////////////////////
                    State changing functions to override
    //////////////////////////////////////////////////////////////*/
    function _beforeCloseRound() internal virtual {}
    function _afterCloseRound() internal virtual {}

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets addresses for different settings
     * @param _type of address:
     *              0 - Manager
     *              1 - FeeRecipient
     *              2 - Pauser
     *              3 - Whitelist
     * @param _address is the new address
     */
    function setAddresses(AddressType _type, address _address) external {
        _onlyOwner();

        if (_address == address(0)) revert BadAddress();

        if (AddressType.Manager == _type) {
            emit AddressSet(AddressType.Manager, manager, _address);
            manager = _address;
        } else if (AddressType.FeeRecipient == _type) {
            emit AddressSet(AddressType.FeeRecipient, feeRecipient, _address);
            feeRecipient = _address;
        } else if (AddressType.Pauser == _type) {
            emit AddressSet(AddressType.Pauser, pauser, _address);
            pauser = _address;
        } else if (AddressType.Whitelist == _type) {
            emit AddressSet(AddressType.Whitelist, whitelist, _address);
            whitelist = _address;
        }
    }

    /**
     * @notice Sets fees for the vault
     * @param _managementFee is the management fee (18 decimals). ex: 2 * 10 ** 18 = 2%
     * @param _performanceFee is the performance fee (18 decimals). ex: 20 * 10 ** 18 = 20%
     */
    function setFees(uint256 _managementFee, uint256 _performanceFee) external {
        _onlyOwner();

        if (_managementFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();
        if (_performanceFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();

        emit FeesSet(managementFee, _managementFee, performanceFee, _performanceFee);

        managementFee = _managementFee;
        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets new round Config
     * @dev this changes the expiry of options
     * @param _duration  the duration of the option
     * @param _dayOfWeek day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
     * @param _hourOfDay hour of the day the option should expire. 0 is midnight
     */
    function setRoundConfig(uint32 _duration, uint8 _dayOfWeek, uint8 _hourOfDay) external {
        _onlyOwner();

        if (_duration == 0 || _dayOfWeek > 8 || _hourOfDay > 23) revert BV_BadRoundConfig();

        emit RoundConfigSet(roundConfig.duration, roundConfig.dayOfWeek, roundConfig.hourOfDay, _duration, _dayOfWeek, _hourOfDay);

        roundConfig = RoundConfig(_duration, _dayOfWeek, _hourOfDay);
    }

    /*///////////////////////////////////////////////////////////////
                            Deposit & Withdraws
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @param _amount is the amount of primary asset to deposit
     * @param _creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 _amount, address _creditor) external nonReentrant {
        if (_creditor == address(0)) _creditor = msg.sender;

        uint256 currentRound = _depositFor(_amount, _creditor);

        // pulling all collaterals from msg.sender
        // An approve() by the msg.sender is required for all collaterals beforehand
        uint256[] memory amounts = _transferAssets(_amount, address(this), currentRound);

        emit Deposited(_creditor, amounts, currentRound);
    }

    /**
     * @notice Withdraws the assets of the vault using the outstanding `DepositReceipt.amount`
     * @dev only pending funds can be withdrawn using this method
     * @param _amount is the pending amount of primary asset to be withdrawn
     */
    function quickWithdraw(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert BV_BadAmount();

        _validateWhitelisted(msg.sender);

        DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;

        if (depositReceipt.round != currentRound) revert BV_BadRound();

        uint96 receiptAmount = depositReceipt.amount;

        if (receiptAmount < _amount) revert BV_BadAmount();

        // amount is within uin96 based on above less-than check
        depositReceipt.amount = receiptAmount - uint96(_amount);

        // amount is within uin96 because it was added to totalPending in _depositFor
        vaultState.totalPending -= uint96(_amount);

        // array of asset amounts transferred back from account
        uint256[] memory amounts = _transferAssets(_amount, msg.sender, currentRound);

        emit QuickWithdrew(msg.sender, amounts, currentRound);
    }

    /**
     * @notice requests a withdraw that can be processed once the round closes
     * @param _numShares is the number of shares to withdraw
     */
    function requestWithdraw(uint256 _numShares) external virtual {
        _requestWithdraw(_numShares);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _depositor is the address of the depositor
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function redeemFor(address _depositor, uint256 _numShares, bool _isMax) external virtual {
        if (_depositor != msg.sender) revert Unauthorized();

        _redeem(_depositor, _numShares, _isMax);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs most administrative tasks associated with a round closing
     */
    function closeRound() external nonReentrant {
        _onlyManager();

        _beforeCloseRound();

        uint32 currentRound = vaultState.round;
        uint256 currentExpiry = roundExpiry[currentRound];
        bool expirationExceeded = currentExpiry < block.timestamp;
        uint256[] memory balances = _getCurrentBalances();

        // only take fees after expiration exceeded, returns balances san fees
        if (expirationExceeded && currentRound > 1) balances = _processFees(balances, currentRound);

        // sets new pricePerShare, shares to mint, and asset prices for new funds being added
        _rollInFunds(balances, currentRound, currentExpiry);

        uint32 nextRound = currentRound + 1;

        // setting the balances at the start of the new round
        roundStartingBalances[nextRound] = balances;

        // including all pending deposits into vault
        vaultState.lastLockedAmount = vaultState.lockedAmount;
        vaultState.totalPending = 0;
        vaultState.round = nextRound;

        uint256 lockedAmount = balances[0];

        // only withdraw, otherwise
        if (expirationExceeded && currentRound > 1) lockedAmount -= _completeWithdraw();

        vaultState.lockedAmount = _toUint96(lockedAmount);

        _afterCloseRound();
    }

    /**
     * @notice Helper function to save gas for writing values into storage maps.
     *         Writing 1's into maps makes subsequent writes warm, reducing the gas significantly.
     * @param _numRounds is the number of rounds to initialize in the maps
     * @param _startFromRound is the round number from which to start initializing the maps
     */
    function initRounds(uint256 _numRounds, uint32 _startFromRound) external {
        unchecked {
            uint256 i;
            uint256[] memory placeholderArray = new uint256[](collaterals.length);

            for (i; i < collaterals.length; ++i) {
                placeholderArray[i] = PLACEHOLDER_UINT;
            }

            for (i = 0; i < _numRounds; ++i) {
                uint256 index = _startFromRound;

                index += i;

                if (roundPricePerShare[index] > 0) revert BV_BadPPS();
                if (roundExpiry[index] > 0) revert BV_BadExpiry();
                if (roundStartingBalances[index].length > 0) revert BV_BadSB();
                if (roundCollateralPrices[index].length > 0) revert BV_BadCP();

                roundPricePerShare[index] = PLACEHOLDER_UINT;
                roundExpiry[index] = PLACEHOLDER_UINT;

                roundStartingBalances[index] = placeholderArray;
                roundCollateralPrices[index] = placeholderArray;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param _account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address _account) external view returns (uint256 heldByAccount, uint256 heldByVault) {
        DepositReceipt memory depositReceipt = depositReceipts[_account];

        if (depositReceipt.round < PLACEHOLDER_UINT) {
            return (share.getBalanceOf(_account, address(this)), 0);
        }

        heldByVault = FeeLib.getSharesFromReceipt(
            depositReceipt,
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
            _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
        );

        heldByAccount = share.getBalanceOf(_account, address(this));
    }

    function getCollaterals() external view returns (Collateral[] memory) {
        return collaterals;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @param _amount is the amount of primary asset to deposit
     * @param _creditor is the address that can claim/withdraw deposited amount
     */
    function _depositFor(uint256 _amount, address _creditor) internal virtual returns (uint256 currentRound) {
        if (_amount == 0) revert BV_BadDepositAmount();

        _validateWhitelisted(msg.sender);

        if (_creditor != msg.sender) _validateWhitelisted(_creditor);

        currentRound = vaultState.round;

        uint256 depositAmount = _amount;

        DepositReceipt memory depositReceipt = depositReceipts[_creditor];
        uint256 unredeemedShares = depositReceipt.unredeemedShares;

        if (currentRound > depositReceipt.round) {
            // if we have an unprocessed pending deposit from the previous rounds, we first process it.
            if (depositReceipt.amount > 0) {
                unredeemedShares = FeeLib.getSharesFromReceipt(
                    depositReceipt,
                    currentRound,
                    roundPricePerShare[depositReceipt.round],
                    _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
                );
            }
        } else {
            // if we have a pending deposit in the current round, we add on to the pending deposit
            depositAmount += depositReceipt.amount;
        }

        depositReceipts[_creditor] = DepositReceipt({
            round: uint32(currentRound),
            amount: _toUint96(depositAmount),
            unredeemedShares: _toUint128(unredeemedShares)
        });

        // keeping track of total pending primary asset
        vaultState.totalPending += _toUint96(_amount);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _depositor receipts
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function _redeem(address _depositor, uint256 _numShares, bool _isMax) internal nonReentrant {
        if (!_isMax && _numShares == 0) revert BV_BadNumShares();

        uint256 currentRound = vaultState.round;

        DepositReceipt storage depositReceipt = depositReceipts[_depositor];

        uint256 depositInRound = depositReceipt.round;
        uint256 unredeemedShares = depositReceipt.unredeemedShares;

        if (currentRound > depositInRound) {
            unredeemedShares = FeeLib.getSharesFromReceipt(
                depositReceipt,
                currentRound,
                roundPricePerShare[depositInRound],
                _relativeNAVInRound(depositInRound, depositReceipt.amount)
            );
        }

        if (_isMax) _numShares = unredeemedShares;

        if (_numShares == 0) return;

        if (unredeemedShares < _numShares) revert BV_ExceedsAvailable();

        // if we have a depositReceipt on the same round, BUT we have unredeemed shares
        // we debit from the unredeemedShares, leaving the amount field intact
        depositReceipt.unredeemedShares = _toUint128(unredeemedShares - _numShares);

        // if the round has past we zero amount for new deposits.
        if (depositInRound < currentRound) depositReceipt.amount = 0;

        emit Redeem(_depositor, _numShares, depositInRound);

        // account shares minted at closeRound to vault, we transfer to account from vault
        share.transferVaultOnly(address(this), _depositor, _numShares, "");
    }

    function _requestWithdraw(uint256 _numShares) internal {
        if (_numShares == 0) revert BV_BadNumShares();

        DepositReceipt memory depositReceipt = depositReceipts[msg.sender];

        // if unredeemed shares exist, do a max redeem before initiating a withdraw
        if (depositReceipt.amount > 0 || depositReceipt.unredeemedShares > 0) _redeem(msg.sender, 0, true);

        // keeping track of total shares requested to withdraw at the end of round
        vaultState.queuedWithdrawShares += _toUint128(_numShares);

        // transferring vault tokens (shares) back to vault, to be burned when round closes
        share.transferVaultOnly(msg.sender, address(this), _numShares, "");

        // storing shares in pauser for future asset(s) withdraw
        IPositionPauser(pauser).pausePosition(msg.sender, _numShares);

        emit RequestedWithdraw(msg.sender, _numShares, vaultState.round);
    }

    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, roundStartingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        for (uint256 i; i < totalFees.length;) {
            if (totalFees[i] > 0) {
                IERC20(collaterals[i].addr).safeTransfer(feeRecipient, totalFees[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal virtual {
        NAVDetails memory navDetails =
            NAVDetails(collaterals, roundStartingBalances[_currentRound], _balances, oracle, _expiry, vaultState.totalPending);

        (uint256 totalNAV, uint256 pendingNAV, uint256[] memory prices) = FeeLib.calculateNAVs(navDetails);

        uint256 pricePerShare = FeeLib.pricePerShare(share.totalSupply(address(this)), totalNAV, pendingNAV);

        uint256 mintShares = FeeLib.navToShares(pendingNAV, pricePerShare);

        // mints shares for all deposits, accounts can redeem at any time
        share.mint(address(this), mintShares);

        // Finalize the pricePerShare at the end of the round
        roundPricePerShare[_currentRound] = pricePerShare;

        // Prices at expiry, if before expiry then spot
        roundCollateralPrices[_currentRound] = prices;
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares != 0) {
            vaultState.queuedWithdrawShares = 0;

            // total assets transferred to pauser
            withdrawAmounts = VaultLib.withdrawWithShares(collaterals, share.totalSupply(address(this)), withdrawShares, pauser);
            // recording deposits with pauser for past round
            IPositionPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transferred to vault during requestWithdraw
            share.burn(address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        return withdrawAmounts[0];
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in processFees
     */
    function _getCurrentBalances() internal view virtual returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Transfers assets between account holder and vault
     * @dev only called from depositFor and quickWithdraw
     */
    function _transferAssets(uint256 _amount, address _recipient, uint256 _round) internal returns (uint256[] memory) {
        return VaultLib.transferAssets(_amount, collaterals, roundStartingBalances[_round], _recipient);
    }

    /**
     * @notice gets whitelist status of an account
     * @param _account address
     */
    function _validateWhitelisted(address _account) internal view {
        if (whitelist != address(0) && !IWhitelistManager(whitelist).isCustomer(_account)) revert Unauthorized();
    }

    /**
     * @notice helper function to calculate an account's Net Asset Value relative to the rounds starting balances
     */
    function _relativeNAVInRound(uint256 _round, uint256 _amount) internal view returns (uint256) {
        return FeeLib.calculateRelativeNAV(collaterals, roundStartingBalances[_round], roundCollateralPrices[_round], _amount);
    }

    function _onlyManager() internal view {
        if (msg.sender != manager) revert Unauthorized();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _onlyPauser() internal view {
        if (msg.sender != pauser) revert Unauthorized();
    }

    function _toUint96(uint256 _num) internal pure returns (uint96) {
        if (_num > type(uint96).max) revert Overflow();
        return uint96(_num);
    }

    function _toUint128(uint256 _num) internal pure returns (uint128) {
        if (_num > type(uint128).max) revert Overflow();
        return uint128(_num);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEngineCash, IMarginEnginePhysical} from "./IMarginEngine.sol";
import {Collateral} from "../config/types.sol";

interface IAuctionVault {
    /// @notice verifies the options are allowed to be minted
    /// @param _options to mint
    function verifyOptions(uint256[] calldata _options) external view;
}

interface IAuctionVaultCash is IAuctionVault {
    function marginEngine() external view returns (IMarginEngineCash);

    function getCollaterals() external view returns (Collateral[] memory);
}

interface IAuctionVaultPhysical is IAuctionVault {
    function marginEngine() external view returns (IMarginEnginePhysical);

    function getCollaterals() external view returns (Collateral[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPositionPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice processes all pending withdrawals
    /// @param _balances of assets transfered to pauser
    function processVaultWithdraw(uint256[] calldata _balances) external;

    /// @notice user withdraws collateral
    /// @param _vault the address of vault
    /// @param _destination the address of the recipient
    function withdrawCollaterals(address _vault, address _destination) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// interfaces
import {IOracle} from "grappa/interfaces/IOracle.sol";

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library FeeLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param vaultDetails VaultDetails struct
     * @param managementFee charged at each round
     * @param performanceFee charged if the vault performs
     * @return totalFees all fees taken in round
     * @return balances is the asset balances at the start of the next round
     */
    function processFees(VaultDetails calldata vaultDetails, uint256 managementFee, uint256 performanceFee)
        external
        pure
        returns (uint256[] memory totalFees, uint256[] memory balances)
    {
        uint256 arrayLength = vaultDetails.currentBalances.length;

        totalFees = new uint256[](arrayLength);
        balances = new uint256[](arrayLength);

        for (uint256 i; i < vaultDetails.currentBalances.length;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            balances[i] = vaultDetails.currentBalances[i];

            // primary asset amount used to calculating the amount of secondary assets deposited in the round
            uint256 pendingBalance =
                vaultDetails.roundStartingBalances[i].mulDivDown(vaultDetails.totalPending, vaultDetails.roundStartingBalances[0]);

            // At round 1, currentBalance == totalPending so we do not take fee on the first round
            if (balances[i] > pendingBalance) {
                lockedBalanceSansPending = balances[i] - pendingBalance;
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(managementFee, 100 * PERCENT_MULTIPLIER);

            // Performance fee charged ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > vaultDetails.roundStartingBalances[i]) {
                if (performanceFee > 0) {
                    uint256 performanceAmount = lockedBalanceSansPending - vaultDetails.roundStartingBalances[i];

                    performanceFeeInAsset = performanceAmount.mulDivDown(performanceFee, 100 * PERCENT_MULTIPLIER);
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            // deducting fees from current balances
            balances[i] -= totalFees[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates Net Asset Value of the vault and pending deposits
     * @dev prices are based on expiry, if rolling close then spot is used
     * @param details NAVDetails struct
     * @return totalNav of all the assets
     * @return pendingNAV of just the pending assets
     * @return prices of the different assets
     */
    function calculateNAVs(NAVDetails calldata details)
        external
        view
        returns (uint256 totalNav, uint256 pendingNAV, uint256[] memory prices)
    {
        IOracle oracle = IOracle(details.oracleAddr);

        uint256 collateralLength = details.collaterals.length;

        prices = new uint256[](collateralLength);

        // primary asset that all other assets will be quotes in
        address quote = details.collaterals[0].addr;

        for (uint256 i; i < collateralLength;) {
            prices[i] = UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (i > 0) prices[i] = _getPrice(oracle, details.collaterals[i].addr, quote, details.expiry);

            // sum of all asset(s) value
            totalNav += details.currentBalances[i].mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            // calculated pending deposit based on the primary asset
            uint256 pendingBalance = details.totalPending.mulDivDown(details.startingBalances[i], details.startingBalances[0]);

            // sum of pending assets value
            pendingNAV += pendingBalance.mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balance(s)
     * @dev used in pending deposits per account
     */
    function calculateRelativeNAV(
        Collateral[] memory collaterals,
        uint256[] memory roundStartingBalances,
        uint256[] memory collateralPrices,
        uint256 primaryDeposited
    ) external pure returns (uint256 nav) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = roundStartingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            nav += balance.mulDivDown(collateralPrices[i], 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param navPerShare is the price in asset per share
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return nav.mulDivDown(UNIT, navPerShare);
    }

    function pricePerShare(uint256 totalSupply, uint256 totalNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalNAV - pendingNAV).mulDivDown(UNIT, totalSupply) : UNIT;
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracle abstracted chainlink oracle
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(IOracle oracle, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        // if timestamp is the placeholder (1) or zero then get the spot
        if (expiry <= PLACEHOLDER_UINT) price = oracle.getSpotPrice(base, quote);
        else (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
    }

    function _sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return shares.mulDivDown(navPerShare, UNIT);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWhitelistManager} from "../interfaces/IWhitelistManager.sol";

import "../config/constants.sol";
import "../config/types.sol";
import "../config/errors.sol";

library VaultLib {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Transfers assets between account holder and vault
     */
    function transferAssets(
        uint256 primaryDeposit,
        Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        address recipient
    ) external returns (uint256[] memory amounts) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = roundStartingBalances[0];

        bool isWithdraw = recipient != address(this);

        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i];

            if (isWithdraw) {
                amounts[i] = balance.mulDivDown(primaryDeposit, primaryTotal);
            } else {
                amounts[i] = balance.mulDivUp(primaryDeposit, primaryTotal);
            }

            if (amounts[i] != 0) {
                if (isWithdraw) {
                    IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
                } else {
                    IERC20(collaterals[i].addr).safeTransferFrom(msg.sender, recipient, amounts[i]);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Rebalances assets
     * @dev will only allow surplus assets to be exchanged
     */
    function rebalance(address otc, uint256[] calldata amounts, Collateral[] calldata collaterals, address whitelist) external {
        if (collaterals.length != amounts.length) revert VL_DifferentLengths();

        if (!IWhitelistManager(whitelist).isOTC(otc)) revert Unauthorized();

        for (uint256 i; i < collaterals.length;) {
            if (amounts[i] != 0) {
                IERC20 asset = IERC20(collaterals[i].addr);

                if (amounts[i] > asset.balanceOf(address(this))) revert VL_ExceedsSurplus();

                asset.safeTransfer(otc, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Processes withdrawing assets based on shares
     * @dev used to send assets to the pauser at the end of each round
     */
    function withdrawWithShares(Collateral[] calldata collaterals, uint256 totalSupply, uint256 shares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            amounts[i] = balance.mulDivDown(shares, totalSupply);

            if (amounts[i] != 0) {
                IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets the next option expiry from the given timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(RoundConfig storage roundConfig) internal view returns (uint256 nextTime) {
        uint256 offset = block.timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry,
        // so we subtract a week in order to get the day the option should expire,
        // or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) offset -= 1 weeks;
        else offset -= 1 days;

        nextTime = _getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset,
        // it means we've tried to calculate an expiry of an option which has too short of length.
        // I.e trying to run a 1 day option on a Tuesday which should expire Friday
        if (nextTime < offset) revert SL_BadExpiryDate();
    }

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6),
     *                  8 will be treated as disabled and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function _getNextDayTimeOfWeek(uint256 timestamp, uint256 dayOfWeek, uint256 hourOfDay)
        internal
        pure
        returns (uint256 nextStartTime)
    {
        // we want sunday to have a value of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek =
            timestamp + ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) * 1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            if (dayOfWeek == 8) nextStartTime += 1 days;
            else nextStartTime += 7 days;
        }
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param initParams is the struct with vault general data
     */
    function verifyInitializerParams(InitParams calldata initParams) external pure {
        if (initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (initParams._manager == address(0)) revert VL_BadManagerAddress();
        if (initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (initParams._pauser == address(0)) revert VL_BadPauserAddress();
        if (initParams._performanceFee > 100 * PERCENT_MULTIPLIER || initParams._managementFee > 100 * PERCENT_MULTIPLIER) {
            revert VL_BadFee();
        }

        if (initParams._collaterals.length == 0) revert VL_BadCollateral();
        for (uint256 i; i < initParams._collaterals.length;) {
            if (initParams._collaterals[i].addr == address(0)) revert VL_BadCollateralAddress();

            unchecked {
                ++i;
            }
        }
        if (initParams._collateralRatios.length > 0) {
            if (initParams._collateralRatios.length != initParams._collaterals.length) revert BV_BadRatios();
        }

        if (
            initParams._roundConfig.duration == 0 || initParams._roundConfig.dayOfWeek > 8
                || initParams._roundConfig.hourOfDay > 23
        ) revert VL_BadDuration();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";

interface IGrappa {
    function getDetailFromProductId(uint40 _productId)
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assetIds(address _asset) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function oracles(uint8 _id) external view returns (address oracle);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    function getProductId(address oracle, address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint40 id);

    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        external
        view
        returns (uint256 id);

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount) external returns (uint256 payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        returns (Balance[] memory payouts);

    function batchGetPayouts(uint256[] memory _tokenIds, uint256[] memory _amounts) external returns (Balance[] memory payouts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";
import {IOracle} from "./IOracle.sol";

interface IPomace {
    function oracle() external view returns (IOracle oracle);

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assetIds(address _asset) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function isCollateralizable(uint8 _asset0, uint8 _asset1) external view returns (bool);

    function isCollateralizable(address _asset0, address _asset1) external view returns (bool);

    function getDebtAndPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout);

    function batchGetDebtAndPayouts(uint256[] calldata tokenId, uint256[] calldata amount)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts);

    function getProductId(address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint32 id);

    function getTokenId(TokenType tokenType, uint32 productId, uint256 expiry, uint256 strike, uint256 exerciseWindow)
        external
        view
        returns (uint256 id);

    function getDetailFromProductId(uint32 _productId)
        external
        view
        returns (
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return debt amount collected
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount)
        external
        returns (Balance memory debt, Balance memory payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId pomace asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/types.sol";

/**
 * @title libraries to encode action arguments
 * @dev   only used in tests
 */
library CashActionUtil {
    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to deposit
     * @param from address to pull asset from
     */
    function createAddCollateralAction(uint8 collateralId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddCollateral, data: abi.encode(from, uint80(amount), collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createRemoveCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createTransferCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient address to receive minted option
     */
    function createMintAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param subAccount sub account to receive minted option
     */
    function createMintIntoAccountAction(uint256 tokenId, uint256 amount, address subAccount)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShortIntoAccount, data: abi.encode(tokenId, subAccount, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTransferLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferLong, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTransferShortAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to burn
     * @param amount amount of token to burn (6 decimals)
     * @param from address to burn option token from
     */
    function createBurnAction(uint256 tokenId, uint256 amount, address from) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.BurnShort, data: abi.encode(tokenId, from, uint64(amount))});
    }

    /**
     * @param tokenId option token id of the incoming option token.
     * @param shortId the currently shorted "option token id" to merge the option token into
     * @param amount amount to merge
     * @param from which address to burn the incoming option from.
     */
    function createMergeAction(uint256 tokenId, uint256 shortId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MergeOptionToken, data: abi.encode(tokenId, shortId, from, amount)});
    }

    /**
     * @param spreadId current shorted "spread option id"
     * @param amount amount to split
     * @param recipient address to receive the "split" long option token.
     */
    function createSplitAction(uint256 spreadId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.SplitOptionToken, data: abi.encode(spreadId, uint64(amount), recipient)});
    }

    /**
     * @param tokenId option token to be added to the account
     * @param amount amount to add
     * @param from address to pull the token from
     */
    function createAddLongAction(uint256 tokenId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddLong, data: abi.encode(tokenId, uint64(amount), from)});
    }

    /**
     * @param tokenId option token to be removed from an account
     * @param amount amount to remove
     * @param recipient address to receive the removed option
     */
    function createRemoveLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveLong, data: abi.encode(tokenId, uint64(amount), recipient)});
    }

    /**
     * @dev create action to settle an account
     */
    function createSettleAction() internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.SettleAccount, data: ""});
    }

    function concat(ActionArgs[] memory x, ActionArgs[] memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + v.length);
        uint256 z;
        uint256 i;
        for (i; i < x.length;) {
            y[z] = x[i];
            unchecked {
                ++z;
                ++i;
            }
        }
        for (i = 0; i < v.length;) {
            y[z] = v[i];
            unchecked {
                ++z;
                ++i;
            }
        }
    }

    function append(ActionArgs[] memory x, ActionArgs memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(BatchExecute[] memory x, BatchExecute memory v) internal pure returns (BatchExecute[] memory y) {
        y = new BatchExecute[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/types.sol";

/**
 * @title libraries to encode action arguments
 * @dev   only used in tests
 */
library PhysicalActionUtil {
    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to deposit
     * @param from address to pull asset from
     */
    function createAddCollateralAction(uint8 collateralId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddCollateral, data: abi.encode(from, uint80(amount), collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createRemoveCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createTransferCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient address to receive minted option
     */
    function createMintAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param subAccount sub account to receive minted option
     */
    function createMintIntoAccountAction(uint256 tokenId, uint256 amount, address subAccount)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShortIntoAccount, data: abi.encode(tokenId, subAccount, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTransferLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferLong, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTransferShortAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to burn
     * @param amount amount of token to burn (6 decimals)
     * @param from address to burn option token from
     */
    function createBurnAction(uint256 tokenId, uint256 amount, address from) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.BurnShort, data: abi.encode(tokenId, from, uint64(amount))});
    }

    /**
     * @param tokenId option token to be added to the account
     * @param amount amount to add
     * @param from address to pull the token from
     */
    function createAddLongAction(uint256 tokenId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddLong, data: abi.encode(tokenId, uint64(amount), from)});
    }

    /**
     * @param tokenId option token to be removed from an account
     * @param amount amount to remove
     * @param recipient address to receive the removed option
     */
    function createRemoveLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveLong, data: abi.encode(tokenId, uint64(amount), recipient)});
    }

    /**
     * @dev create action to settle an account
     */
    function createExerciseTokenAction(uint256 tokenId, uint256 amount) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.ExerciseToken, data: abi.encode(tokenId, uint64(amount))});
    }

    /**
     * @dev create action to settle an account
     */
    function createSettleAction() internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.SettleAccount, data: ""});
    }

    function concat(ActionArgs[] memory x, ActionArgs[] memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + v.length);
        uint256 z;
        uint256 i;
        for (i; i < x.length;) {
            y[z] = x[i];
            unchecked {
                ++z;
                ++i;
            }
        }
        for (i = 0; i < v.length;) {
            y[z] = v[i];
            unchecked {
                ++z;
                ++i;
            }
        }
    }

    function append(ActionArgs[] memory x, ActionArgs memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(BatchExecute[] memory x, BatchExecute memory v) internal pure returns (BatchExecute[] memory y) {
        y = new BatchExecute[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEnginePhysical} from "./IMarginEngine.sol";
import {IVaultShare} from "./IVaultShare.sol";

import "../config/types.sol";

interface IHashnoteVault {
    function share() external view returns (IVaultShare);

    function roundExpiry(uint256 round) external view returns (uint256);

    function whitelist() external view returns (address);

    function vaultState() external view returns (VaultState memory);

    function depositFor(uint256 amount, address creditor) external;

    function requestWithdraw(uint256 numShares) external;

    function getCollaterals() external view returns (Collateral[] memory);

    function depositReceipts(address depositor) external view returns (DepositReceipt memory);

    function redeemFor(address depositor, uint256 numShares, bool isMax) external;

    function managementFee() external view returns (uint256);

    function feeRecipient() external view returns (address);
}

interface IHashnotePhysicalOptionsVault is IHashnoteVault {
    function marginEngine() external view returns (IMarginEnginePhysical);

    function burnSharesFor(address depositor, uint256 sharesToWithdraw) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultShare {
    /**
     * @dev mint option token to an address. Can only be called by corresponding vault
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     *
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev burn option token from an address. Can only be called by corresponding vault
     * @param _from         account to burn from
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @dev burn option token from addresses. Can only be called by corresponding vault
     * @param _froms        accounts to burn from
     * @param _amounts      amounts to burn
     *
     */
    function batchBurn(address[] memory _froms, uint256[] memory _amounts) external;

    /**
     * @dev returns total supply of a vault
     * @param _vault      address of the vault
     *
     */
    function totalSupply(address _vault) external view returns (uint256 amount);

    /**
     * @dev returns vault share balance for a given holder
     * @param _owner      address of token holder
     * @param _vault      address of the vault
     *
     */
    function getBalanceOf(address _owner, address _vault) external view returns (uint256 amount);

    /**
     * @dev exposing transfer method to vault
     *
     */
    function transferVaultOnly(address _from, address _to, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev helper metod to pass in vault address instead of tokenId
     *
     */
    function transferFromWithVault(address _from, address _to, address _vault, uint256 _amount, bytes calldata _data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISanctionsList {
    function isSanctioned(address _address) external view returns (bool);
}

interface IWhitelistManager {
    function isCustomer(address _address) external view returns (bool);

    function isLP(address _address) external view returns (bool);

    function isOTC(address _address) external view returns (bool);

    function isVault(address _vault) external view returns (bool);

    function engineAccess(address _address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

enum AddressType {
    Manager,
    FeeRecipient,
    Pauser,
    Whitelist
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    CALL
}

/**
 * @dev common action types on margin engines
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    AddLong,
    RemoveLong,
    ExerciseToken,
    SettleAccount,
    // actions that influence more than one subAccounts:
    // These actions are defined in "OptionTransferable"
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral directly to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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