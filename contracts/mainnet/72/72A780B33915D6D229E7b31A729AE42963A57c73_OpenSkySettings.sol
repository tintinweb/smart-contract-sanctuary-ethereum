// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IACLManager.sol';
import '../libraries/types/DataTypes.sol';
import '../libraries/helpers/Errors.sol';

contract OpenSkySettings is IOpenSkySettings, Ownable {
    uint256 public constant MAX_RESERVE_FACTOR = 3000;

    address public immutable ACLManagerAddress;

    // nftAddress=>data
    mapping(uint256 => mapping(address => DataTypes.WhitelistInfo)) internal _whitelist;

    // liquidator contract whitelist
    mapping(address => bool) internal _liquidators;

    // one-time initialization factors
    address public override poolAddress;
    address public override loanAddress;
    address public override vaultFactoryAddress;
    address public override incentiveControllerAddress;
    address public override wethGatewayAddress;
    address public override punkGatewayAddress;
    address public override daoVaultAddress;

    // governance factors
    address public override moneyMarketAddress;
    address public override treasuryAddress;
    address public override loanDescriptorAddress;
    address public override nftPriceOracleAddress;
    address public override interestRateStrategyAddress;

    uint256 public override reserveFactor = 2000;
    uint256 public override prepaymentFeeFactor = 0;
    uint256 public override overdueLoanFeeFactor = 100;

    constructor(address _ACLManagerAddress) Ownable() {
        ACLManagerAddress = _ACLManagerAddress;
    }

    modifier onlyGovernance() {
        IACLManager ACLManager = IACLManager(ACLManagerAddress);
        require(ACLManager.isGovernance(_msgSender()), Errors.ACL_ONLY_GOVERNANCE_CAN_CALL);
        _;
    }

    modifier onlyWhenNotInitialized(address address_) {
        require(address_ == address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        _;
    }

    function initPoolAddress(address address_) external onlyOwner onlyWhenNotInitialized(poolAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        poolAddress = address_;
        emit InitPoolAddress(msg.sender, address_);
    }

    function initLoanAddress(address address_) external onlyOwner onlyWhenNotInitialized(loanAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        loanAddress = address_;
        emit InitLoanAddress(msg.sender, address_);
    }

    function initVaultFactoryAddress(address address_) external onlyOwner onlyWhenNotInitialized(vaultFactoryAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        vaultFactoryAddress = address_;
        emit InitVaultFactoryAddress(msg.sender, address_);
    }

    function initIncentiveControllerAddress(address address_)
        external
        onlyOwner
        onlyWhenNotInitialized(incentiveControllerAddress)
    {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        incentiveControllerAddress = address_;
        emit InitIncentiveControllerAddress(msg.sender, address_);
    }

    function initWETHGatewayAddress(address address_) external onlyOwner onlyWhenNotInitialized(wethGatewayAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        wethGatewayAddress = address_;
        emit InitWETHGatewayAddress(msg.sender, address_);
    }

    function initPunkGatewayAddress(address address_) external onlyOwner onlyWhenNotInitialized(punkGatewayAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        punkGatewayAddress = address_;
        emit InitPunkGatewayAddress(msg.sender, address_);
    }

    function initDaoVaultAddress(address address_) external onlyOwner onlyWhenNotInitialized(daoVaultAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        daoVaultAddress = address_;
        emit InitDaoVaultAddress(msg.sender, address_);
    }

    // Only take effect when creating new reserve
    function setMoneyMarketAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        moneyMarketAddress = address_;
        emit SetMoneyMarketAddress(msg.sender, address_);
    }

    function setTreasuryAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        treasuryAddress = address_;
        emit SetTreasuryAddress(msg.sender, address_);
    }

    function setLoanDescriptorAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        loanDescriptorAddress = address_;
        emit SetLoanDescriptorAddress(msg.sender, address_);
    }

    function setNftPriceOracleAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        nftPriceOracleAddress = address_;
        emit SetNftPriceOracleAddress(msg.sender, address_);
    }

    function setInterestRateStrategyAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        interestRateStrategyAddress = address_;
        emit SetInterestRateStrategyAddress(msg.sender, address_);
    }

    function setReserveFactor(uint256 factor) external onlyGovernance {
        require(factor <= MAX_RESERVE_FACTOR, Errors.SETTING_RESERVE_FACTOR_NOT_ALLOWED);
        reserveFactor = factor;
        emit SetReserveFactor(msg.sender, factor);
    }

    function setPrepaymentFeeFactor(uint256 factor) external onlyGovernance {
        prepaymentFeeFactor = factor;
        emit SetPrepaymentFeeFactor(msg.sender, factor);
    }

    function setOverdueLoanFeeFactor(uint256 factor) external onlyGovernance {
        overdueLoanFeeFactor = factor;
        emit SetOverdueLoanFeeFactor(msg.sender, factor);
    }

    function addToWhitelist(
        uint256 reserveId,
        address nft,
        string memory name,
        string memory symbol,
        uint256 LTV,
        uint256 minBorrowDuration,
        uint256 maxBorrowDuration,
        uint256 extendableDuration,
        uint256 overdueDuration
    ) external onlyGovernance {
        require(reserveId > 0, Errors.SETTING_WHITELIST_INVALID_RESERVE_ID);
        require(nft != address(0), Errors.SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO);
        require(minBorrowDuration <= maxBorrowDuration, Errors.SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER);
        require(bytes(name).length != 0, Errors.SETTING_WHITELIST_NFT_NAME_EMPTY);
        require(bytes(symbol).length != 0, Errors.SETTING_WHITELIST_NFT_SYMBOL_EMPTY);
        require(LTV > 0 && LTV <= 10000, Errors.SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED);

        _whitelist[reserveId][nft] = DataTypes.WhitelistInfo({
            enabled: true,
            name: name,
            symbol: symbol,
            LTV: LTV,
            minBorrowDuration: minBorrowDuration,
            maxBorrowDuration: maxBorrowDuration,
            extendableDuration: extendableDuration,
            overdueDuration: overdueDuration
        });
        emit AddToWhitelist(msg.sender, reserveId, nft);
    }

    function removeFromWhitelist(uint256 reserveId, address nft) external onlyGovernance {
        if (_whitelist[reserveId][nft].enabled) {
            _whitelist[reserveId][nft].enabled = false;
            emit RemoveFromWhitelist(msg.sender, reserveId, nft);
        }
    }

    function inWhitelist(uint256 reserveId, address nft) external view override returns (bool) {
        return _whitelist[reserveId][nft].enabled;
    }

    function getWhitelistDetail(uint256 reserveId, address nft)
        external
        view
        override
        returns (DataTypes.WhitelistInfo memory)
    {
        return _whitelist[reserveId][nft];
    }

    // liquidator
    function addLiquidator(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        if (!_liquidators[address_]) {
            _liquidators[address_] = true;
            emit AddLiquidator(msg.sender, address_);
        }
    }

    function removeLiquidator(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        if (_liquidators[address_]) {
            _liquidators[address_] = false;
            emit RemoveLiquidator(msg.sender, address_);
        }
    }

    function isLiquidator(address address_) external view override returns (bool) {
        return _liquidators[address_];
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IACLManager {
    function addEmergencyAdmin(address admin) external;
    
    function isEmergencyAdmin(address admin) external view returns (bool);
    
    function removeEmergencyAdmin(address admin) external;
    
    function addGovernance(address admin) external;
    
    function isGovernance(address admin) external view returns (bool);

    function removeGovernance(address admin) external;

    function addPoolAdmin(address admin) external;

    function isPoolAdmin(address admin) external view returns (bool);

    function removePoolAdmin(address admin) external;

    function addLiquidationOperator(address address_) external;

    function isLiquidationOperator(address address_) external view returns (bool);

    function removeLiquidationOperator(address address_) external;

    function addAirdropOperator(address address_) external;

    function isAirdropOperator(address address_) external view returns (bool);

    function removeAirdropOperator(address address_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}

// SPDX-License-Identifier: MIT

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