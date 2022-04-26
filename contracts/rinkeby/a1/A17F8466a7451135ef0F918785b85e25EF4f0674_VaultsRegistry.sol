// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IVolmexRealizedVolVault.sol";
import "../interfaces/IVaultsRegistry.sol";

/**
 * @title Volmex Vault Regisrty
 * @author volmex.finance [[email protected]]
 */
contract VaultsRegistry is OwnableUpgradeable, IVaultsRegistry {
    // incremental index for unique key
    uint256 public index;

    // mapping for storing different asset vault
    //{0: ETH, 1: SOL}
    mapping(uint256 => address) public registries;

    // mapping for whitelist vaults address
    mapping(address => bool) public whiteListVaults; 

    /**
     * @notice Constructs the registry contract
     *
     * @param _owner is the address of Owner or multisig
     */
    function initialize(address _owner) external initializer {
        __Ownable_init();
        transferOwnership(_owner);
    }

    /**
     * @notice register the vaults contract
     *
     * @param _vaults is the array of addresses of volmex realized vault
     */
    function registerVaults(address[] calldata _vaults) external onlyOwner {
        uint256 currentIndex = index;
        uint256 vaultsLength = _vaults.length;
        for (uint8 key = 0; key < vaultsLength; key++) {
            require(_vaults[key] != address(0), "VaultsRegistry: Null address");
            registries[currentIndex] = _vaults[key];
            whiteListVaults[_vaults[key]] = true;
            currentIndex++;
        }
        index = currentIndex;
        emit VaultsRegistered(index - 1, _vaults);
    }

    /**
     * @notice used to get the Vaults address
     *
     * @param _index integer number on which vault is mapped
     */
    function getVaults(uint256 _index) external view returns (address) {
        return registries[_index];
    }

    /**
     * @notice used to get the Vaults params
     *
     * @param _vault address of vault
     */
    function getVaultParams(address _vault)
        external
        view
        returns (Vault.VaultParams memory)
    {
        return IVolmexRealizedVolVault(_vault).vaultParams();
    }

    /**
     * @notice used to get the Vaults state
     *
     * @param _vault address of vault
     */
    function getVaultState(address _vault)
        external
        view
        returns (Vault.VaultState memory)
    {
        return IVolmexRealizedVolVault(_vault).vaultState();
    }

    /**
     * @notice used to get the VToken state
     *
     * @param _vault address of vault
     */
    function getVTokenState(address _vault)
        external
        view
        returns (Vault.VTokenState memory)
    {
        return IVolmexRealizedVolVault(_vault).vTokenState();
    }
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";
import "./IVolmexVault.sol";

interface IVolmexRealizedVolVault is IVolmexVault {

    function vaultParams() external view returns (Vault.VaultParams memory);
    function vaultState() external view returns (Vault.VaultState memory);
    function vTokenState() external view returns (Vault.VTokenState memory);
    function vTokenAuctionID() external view returns (uint256);
    function setAuctionDuration(uint256 newAuctionDuration) external;
    function withdrawInstantly(uint256 amount) external;
    function completeWithdraw() external;
    function commitAndClose() external;
    function redeemByMarketMaker(address vToken, uint256 shares) external;
    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory auctionSellOrder,
        address auction,
        address counterpartyThetaVault
    ) external;
    function rollToNextVtoken(
        uint256 _minVaultDeposit,
        uint256 _minVtokenPremium
    ) external;
    function startAuction() external;
    function burnRemainingVTokens() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";

interface IVaultsRegistry {
    //event
    event VaultsRegistered(uint256 indexed _lastIndex, address[] _vault);
    
    function index() external view returns (uint256);
    //setter
    function registerVaults(address[] calldata _vaults) external;

    //getters
    function whiteListVaults(address _vault) external view returns (bool);
    function getVaults(uint256 _index) external view returns (address);
    function getVaultParams(address _vault)
        external
        view
        returns (Vault.VaultParams memory);
    function getVaultState(address _vault)
        external
        view
        returns (Vault.VaultState memory);
    function getVTokenState(address _vault)
        external
        view
        returns (Vault.VTokenState memory);
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    // vTokens have 8 decimal places.
    uint256 internal constant VTOKEN_DECIMALS = 18;

    // Percentage of funds allocated to vTokens is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant ALLOCATION_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // vTokens type the vault is selling
        bool isShort;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Vault
        address asset;
        // Underlying asset of the vTokens sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint256 cap;
        // Price of asset at the time auction starts
        uint256 assetPrice;
        // Oracle index of the current asset
        uint8 oracleIndex;
    }

    struct VTokenState {
        // vTokens that the vault is shorting / longing in the next cycle
        address nextVToken;
        // vTokens that the vault is currently shorting / longing
        address currentVToken;
        // The timestamp when the `nextvTokens` can be used by the vault
        uint32 nextVTokenReadyAt;
        // The movement of the bid asset price
        uint256 delta;
        // price of vToken
        uint256 vTokenPrice;
        // realized price of vToken
        uint256 vTokenPnL;
        // minimum amount of vToken
        uint256 vTokenMinBidPremium;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling vTokens
        uint256 lockedAmount;
        // Amount that was locked for selling vTokens in the previous round
        // used for calculating performance fee deduction
        uint256 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint256 totalPending;
        // Amount locked for scheduled withdrawals;
        uint256 queuedWithdrawShares;
        // time after which next roll over happen
        uint256 nextRollOverTime;
        // boolean flag for auction status
        bool isAuctionStart;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint256 amount;
        // Unredeemed shares balance
        uint256 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint256 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of vToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";

interface IVolmexVault {
    //events
    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    // getters
    function pricePerShare(uint256 round) external view returns (uint256);
    function minVaultDeposit(uint256 round) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function nextVTokenReadyAt() external view returns (uint256);
    function currentVToken() external view returns (address);
    function nextVToken() external view returns (address);
    function keeper() external view returns (address);
    function controller() external view returns (address);
    function feeRecipient() external view returns (address);
    function performanceFee() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function totalPending() external view returns (uint256);
    function previewDeposit(uint256 _assets) external view returns (uint256);
    function previewMint(uint256 _shares) external view returns (uint256);
    function previewWithdraw(uint256 _assets) external view returns (uint256);
    function previewRedeem(uint256 _shares) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function shares(address _account) external view returns (uint256);
    function getNextRollOver() external view returns (uint256);
    function shareBalances(address _account)
        external
        view
        returns (uint256 heldByAccount, uint256 heldByVault);

    // setters
    function deposit(uint256 amount, address sender) external;
    function cap() external view returns (uint256);
    function depositFor(uint256 amount, address creditor, address receiver) external;
    function setNewKeeper(address newKeeper) external;
    function setFeeRecipient(address newFeeRecipient) external;
    function setManagementFee(uint256 newManagementFee) external;
    function setPerformanceFee(uint256 newPerformanceFee) external;
    function setCap(uint256 newCap) external;
    function mint(uint256 _shares, address _receiver) external;
    function initiateWithdraw(uint256 _numShares) external;
    function redeem(uint256 _numShares) external;
    function maxRedeem() external;
}