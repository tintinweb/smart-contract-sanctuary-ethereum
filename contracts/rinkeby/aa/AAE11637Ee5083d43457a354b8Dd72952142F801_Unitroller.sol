pragma solidity ^0.8.0;

import "./ErrorReporter.sol";
import "./ComptrollerStorage.sol";
/**
 * @title ComptrollerCore
 * @dev Storage for the comptroller is at this address, while execution is delegated to the `comptrollerImplementation`.
 * CTokens should reference this contract as their comptroller.
 */
contract Unitroller is UnitrollerAdminStorage, ComptrollerErrorReporter {

    /**
      * @notice Emitted when pendingComptrollerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingComptrollerImplementation || pendingComptrollerImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = comptrollerImplementation;
        address oldPendingImplementation = pendingComptrollerImplementation;

        comptrollerImplementation = pendingComptrollerImplementation;

        pendingComptrollerImplementation = address(0);

        emit NewImplementation(oldImplementation, comptrollerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

        return uint(Error.NO_ERROR);
    }


    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() public returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() external payable  {
        // delegate all other functions to current implementation
        (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }

    receive() external payable  {

    }
}

pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.8.0;

import "./CNftInterface.sol";
import "./ZBond.sol";
import "./NftPriceOracle.sol";
import "./PriceOracle.sol";

abstract contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingComptrollerImplementation;
}

contract ComptrollerStorage is UnitrollerAdminStorage {

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;


    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => mapping(address => ZBond[])) public accountAssets;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;
        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;


    }
    
    struct BorrowState {
        uint dueTime;
        uint initialBorrow;

    }
    /**
     * @notice Official mapping of asset -> collateral metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    
    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets for a cNFT market
    mapping(CNftInterface => mapping(ZBond => bool)) public allMarkets;

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each zBond address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;

    /// @notice Last block at which a contributor's COMP rewards have been allocated
    mapping(address => uint) public lastContributorBlock;

    NftPriceOracle public nftOracle;


    mapping(address => mapping(address => uint[])) public sequenceOfLiquidation; // nft => user => id


    // token awards storage

        // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ZUMERs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accZumerPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accZumerPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address pool;           // Address of the contract being rewarded.
        uint balance;        // balance of the tokens that will be used in the calculation.
        uint allocPoint;       // How many allocation points assigned to this pool. ZUMERs to distribute per block.
        uint lastRewardBlock;  // Last block number that ZUMERs distribution occurs.
        uint accZumerPerShare; // Accumulated ZUMERs per share, times 1e12. See below.
    }

    // The ZUMER TOKEN!
    ERC20 public zumer;
    // Block number when bonus ZUMER period ends.
    uint256 public bonusEndBlock;
    // ZUMER tokens created per block.
    uint256 public zumerPerBlock;
    // Bonus muliplier for early zumer makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint) public poolToID;
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ZUMER mining starts.
    uint256 public startBlock;



}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ZBond.sol";
abstract contract CNftInterface is ERC721, IERC721Receiver{
    address public underlying;
    bool isPunk;
    string public uri;
    address admin;
    address public comptroller;
    bool public constant isCNft = true;
    /// @notice transfer NFT

    /**
     * @notice Event emitted when cNFTs are minted
     */
    event Mint(address minter, uint[] mintIds);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint[] redeemIds);

    function seize(address liquidator, address borrower, uint256[] calldata seizeIds) virtual external;
    function mint(uint256[] calldata tokenIds) virtual external returns(uint);
    function redeem(uint256[] calldata tokenIds) virtual external returns(uint);
    function safeBatchTransferFrom(
        address from,
        address to, uint[] calldata ids
    ) virtual external;


}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ComptrollerInterface.sol";
import "./FeeSelector.sol";
import "./ProvisioningPool.sol";
import "./ExponentialNoError.sol";
import "./CNftInterface.sol";

interface ZBondInterface{
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);
    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

}

abstract contract ZBondStorage is ZBondInterface{
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /** 
        how much time that a user can borrow without paying interests until they get margin call
    */
    uint public minimumPaymentDueFrequency = 30 days; // TODO

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current funding cost should be
     */
    FeeSelector public feeSelector;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public provisioningPoolMantissa;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total number of underlying accumulated in the contract plus the borrowed token
     */
    uint public totalSupplyPrinciplePlusInterest;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     */
    struct BorrowSnapshot {
        uint deadline;
        uint loanDuration;
        uint minimumPaymentDue;
        uint principalBorrow;
        uint weightedInteretRate;
    }

    struct SupplySnapshot {
        uint principalSupply;
        uint startDate;
    }

    /**
     * @notice days that one has to pledge in the pool to get all the awards
     */
    uint public fullAwardCollectionDuration = 30 days;

    uint public maximumLoanDuration = 180 days;
    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) public accountBorrows;
    mapping(address => SupplySnapshot) public accountSupplies;
    mapping(address => uint[]) public userLiquidationSequence;
    CNftInterface public cNFT;
    ProvisioningPool public provisioningPool;
    bool public isZBond = true;

    uint public creditCostRatioMantissa = 0.05 * 1e18;

    uint public underwritingFeeRatioMantissa = 0.01 * 1e18;




}


abstract contract ZBond is ERC20, Ownable, ZBondStorage, Exponential {
    constructor(string memory name_, string memory symbol_, CNftInterface cNFT_, FeeSelector feeSelector_, ComptrollerInterface comptroller_)
        ERC20(name_, symbol_)
    {
        cNFT = cNFT_;
        feeSelector = feeSelector_;
        comptroller = comptroller_;
    }

    /**
        amountIn: the underlying asset that will be transfered in the contract.
     */
    function mintInternal(uint amountIn) internal returns (uint256) {
        uint256 mintAmount = mulScalarTruncate(Exp(getExchangeRateMantissa()), amountIn);
        _mint(msg.sender, mintAmount);
        emit Mint(msg.sender, amountIn, mintAmount);

        // effects
        // change user state
        accountSupplies[msg.sender].principalSupply += amountIn;
        if (accountSupplies[msg.sender].startDate == 0) {
            accountSupplies[msg.sender].startDate = block.timestamp;
        }

        // change global state
        totalSupplyPrinciplePlusInterest += amountIn;

        // interaction
        doTransferIn(msg.sender, amountIn);

        return mintAmount;
    }
    /**
        amountIn: the underlying asset that will be transfered out from the contract contract.
     */
    function redeemInternal(uint256 amountOut) internal returns (uint256) {
        require(
            address(this).balance > 0,
            "No ETH to unstake in the provisioning pool."
        );
        // effects
        uint256 burnAmount = divScalarByExpTruncate(amountOut, Exp(getExchangeRateMantissa()));
        require(burnAmount <= balanceOf(msg.sender), "Not enough balance to redeem");

        // reduce both principle borrow and the corresponding amount of interests
        totalSupplyPrinciplePlusInterest -= amountOut;
        _burn(msg.sender, burnAmount);

        // interaction
        emit Redeem(msg.sender, amountOut, burnAmount);
        doTransferOut(msg.sender, amountOut);

        return burnAmount;
    }

    function borrowInternal(uint256 amount, uint256 duration)
        internal
        returns (uint, uint)
    {
        require(comptroller.borrowAllowed(address(this), msg.sender, amount, duration) == 0, "Comptroller rejected borrow");
        uint256 fundingRateMantissa = feeSelector.getFundingCostForDuration(duration, maximumLoanDuration);

        fundingRateMantissa += creditCostRatioMantissa;

        // effects
        updateUserStateAfterBorrow(msg.sender, amount, duration, fundingRateMantissa);

        // interactions
        // transfer underwriting fee to the admin
        uint underwritingFee = mul_(amount, Exp(underwritingFeeRatioMantissa));
        doTransferOut(owner(), underwritingFee);
        // transfer principle borrow to the user
        doTransferOut(msg.sender, amount - underwritingFee);



        //zumerMiner.increaseBalance(msg.sender, amount);
    }
    /**
    
        returns actual amount paid and the interest that are transfered to the provisioining pool.
     */
    function repayBorrowInternal(address borrower, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        require(
            comptroller.repayBorrowAllowed(
                address(this),
                msg.sender,
                msg.sender,
                amount
            ) == 0,
            "Comptroller rejected repay"
        );
        

        // effects
        (uint overpay, uint interestPaid) = updateUserStateAfterRepay(borrower, amount);
        uint provisioningInterest = mulScalarTruncate(Exp(provisioningPoolMantissa), interestPaid);
        totalSupplyPrinciplePlusInterest += (interestPaid - provisioningInterest);

        // interactions
        doTransferIn(msg.sender, amount - overpay);

        if(address(provisioningPool) != address(0)) {

            doTransferOut(address(provisioningPool), provisioningInterest);
        } else {
            doTransferOut(owner(), provisioningInterest);
        }
        
        // update zumer claims

        //zumerMiner.decreaseBalance(msg.sender, amount);


        return (amount - overpay, provisioningInterest);
    }

    function liquidateBorrowInternal(
        address liquidator,
        address borrower,
        uint256[] calldata id
    ) internal returns (uint256) {

        uint err = comptroller.liquidateBorrowAllowed(address(this), address(cNFT), liquidator, borrower, id);
        require(err == 0, "Comptroller rejected liquidation");
        
        uint repayAmount = comptroller.calculateLiquidationAmount(borrower, address(this), id, address(cNFT));
        (uint actualPayBack, uint provisioningPoolInterestPaid) = repayBorrowInternal(borrower, repayAmount);

        // seize collaterals;
        cNFT.seize(liquidator, borrower, id);
        return actualPayBack;
    }

    /**
        Gets the rate betwen the total supply of zBondToken: totalSupply
     */
    function getExchangeRateMantissa() public view returns (uint256) {

        if (totalSupply() == 0) {
            return 1e18;
        } else {
            return getExp(totalSupply(), totalSupplyPrinciplePlusInterest).mantissa;
        }
    }

    /** 
        update the users' borrow state
        returns (overpay, interest paid).   
    */
    function updateUserStateAfterRepay(address borrower, uint256 paid)
        internal
        returns (uint256, uint256)
    {
        uint256 borrowBalance = accountBorrows[borrower].principalBorrow;
        uint256 currentInterestToPay = getAccountCurrentBorrowBalance(borrower) - borrowBalance;
        if (paid < currentInterestToPay) {
            return (0, paid);
        } else {
            // if user closed position, then delete user borrow position
            if (borrowBalance + currentInterestToPay <= paid) {
                delete accountBorrows[borrower];
                return (paid - (borrowBalance + currentInterestToPay), currentInterestToPay);
            }
            // if user reduced position (or at least paid all of their interests), then reduce initial borrow and carry over the minimum payment due time, total loan due time is not affected
            else {
                accountBorrows[borrower].minimumPaymentDue = block.timestamp + minimumPaymentDueFrequency;
                accountBorrows[borrower].principalBorrow = borrowBalance + currentInterestToPay - paid;

                return (0, currentInterestToPay);
            }
        }
    }

    function updateUserStateAfterBorrow(
        address borrower,
        uint256 borrowAmount,
        uint256 duration,
        uint256 interest
    ) internal {
        // initialize borrow state if dueTime is not set
        if (accountBorrows[borrower].minimumPaymentDue == 0) {
            accountBorrows[borrower].minimumPaymentDue = block.timestamp + minimumPaymentDueFrequency;
        }
        if (accountBorrows[borrower].deadline == 0) {
            accountBorrows[borrower].loanDuration = duration;
            accountBorrows[borrower].deadline = block.timestamp + accountBorrows[borrower].loanDuration;
        }

        // set weighted interest
        uint256 timeLeft = accountBorrows[borrower].deadline - block.timestamp;
        if(accountBorrows[borrower].principalBorrow == 0 ) {
            accountBorrows[borrower].weightedInteretRate = interest;
        } else {
            accountBorrows[borrower].weightedInteretRate = getExp(
                (accountBorrows[borrower].weightedInteretRate *
                    accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    interest *
                    borrowAmount *
                    timeLeft),
                (accountBorrows[borrower].principalBorrow *
                    accountBorrows[borrower].loanDuration +
                    borrowAmount *
                    timeLeft)
            ).mantissa;
        }


        accountBorrows[borrower].principalBorrow += borrowAmount;

        require(
            (accountBorrows[borrower].minimumPaymentDue >= block.timestamp) &&
                (accountBorrows[borrower].minimumPaymentDue >= block.timestamp),
            "cannot increase position if overdue"
        );
    }

    function getAccountCurrentBorrowBalance(address borrower) public view returns (uint) {
        uint principle = accountBorrows[borrower].principalBorrow;

        if(principle == 0) {
            return 0;
        }

        uint interestRate = accountBorrows[borrower].weightedInteretRate;
        uint duration = accountBorrows[borrower].loanDuration;
        uint deadline = accountBorrows[borrower].deadline;
        uint accruedPeriod;

        if (block.timestamp > deadline) { // if overdue, balance should be all the principle and all the interests
            accruedPeriod = duration;
        } else {
            accruedPeriod = deadline - block.timestamp;
        }

        Exp memory ratio = getExp(accruedPeriod, duration);
        // interest = (timeleft / totalLoanDuration) * principle * interestRate
        uint interest = mul_(mul_(principle, Exp(interestRate)), ratio);
        
        return principle + interest;
    }

    function doTransferIn(address sender, uint amount) internal virtual {

    }

    function doTransferOut(address receiver, uint amount) internal virtual {

    }

    function getCashBalance() external view virtual  returns(uint) {
        
    }

    function setProvisioningPool(address provisioningPoolAddress, uint provisioingPoolMantissa_) onlyOwner public {
        provisioningPool = ProvisioningPool(payable(provisioningPoolAddress));
        provisioningPoolMantissa = provisioingPoolMantissa_;
    }

    function setUnderwritingFeeRatio(uint underwritingFeeRatioMantissa_) onlyOwner public{
        underwritingFeeRatioMantissa = underwritingFeeRatioMantissa_;
    }

    function setCreditCostRatio(uint creditCostRatioMantissa_) onlyOwner public {
        creditCostRatioMantissa = creditCostRatioMantissa_;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CNftInterface.sol";

abstract contract NftPriceOracle {
    /// @notice Indicator that this is a NftPriceOracle contract (for inspection)
    bool public constant isNftPriceOracle = true;

    /**
      * @notice Get the underlying price of a cNft asset
      * @param cNft The cNft to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CNftInterface cNft) virtual external view returns (uint);
}

pragma solidity ^0.8.0;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param asset The asset to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address asset) virtual external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

pragma solidity ^0.8.0;

/// @dev Keep in sync with ComptrollerInterface080.sol.
abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Policy Hooks ***/
    function mintAllowed(address zBond, address minter, uint mintAmount) virtual external returns (uint);

    function redeemAllowed(address zBond, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address zBond, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address zBond, address borrower, uint borrowAmount, uint duration) virtual external returns (uint);

    function repayBorrowAllowed(
        address zBond,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function calculateLiquidationAmount(
        address borrower, 
        address zBondBorrowed,
        uint[] calldata id, 
        address cNFT) virtual external returns (uint);
    function liquidateBorrowAllowed(
        address zBondBorrowed,
        address cNFT,
        address liquidator,
        address borrower,
        uint[] calldata id) virtual external returns (uint);

    function seizeAllowed(
        address zBondCollateral,
        address zBondBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);

    function transferAllowed(address zBond, address src, address dst, uint transferTokens) virtual external returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeNfts(
        address zBondBorrowed,
        address zBondCollateral,
        uint repayAmount) virtual external view returns (uint, uint);



}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Exponential.sol";
/// @title A title that should describe the contract/interface
    /// @author The name of the author
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details

contract FeeSelector is Exponential{
    
    /**
        _decisionToken: token that is used to decide the fee
        upperBound: upper bound of the drafting fee
        lowerBound
    */

    struct UserVotes{
        uint upperLong;
        uint lowerLong;
        uint upperShort;
        uint lowerShort;
    }

    IERC20 public decisionToken;

    struct PoolInfo {
        uint upperBound;
        uint lowerBound;
        uint upperTotal;
        uint lowerTotal;
    }

    PoolInfo public longPool;

    PoolInfo public shortPool;


    mapping(address => UserVotes) public userAcounts;
    constructor(IERC20 _decisionToken, uint _upperBoundLong, uint _lowerBoundLong,
    uint _upperBoundShort, uint _lowerBoundShort ) {
        decisionToken = _decisionToken;
        longPool.upperBound = _upperBoundLong;
        longPool.lowerBound = _lowerBoundLong;

        shortPool.upperBound = _upperBoundShort;
        shortPool.lowerBound = _lowerBoundShort;
    }
    
    function stake(uint upperAmount, uint lowerAmount, bool isLong) public {
        if(isLong) {
            userAcounts[msg.sender].upperLong += upperAmount;
            userAcounts[msg.sender].lowerLong += lowerAmount;

            longPool.upperTotal += upperAmount;
            longPool.lowerTotal += lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort += upperAmount;
            userAcounts[msg.sender].lowerShort += lowerAmount;

            shortPool.upperTotal += upperAmount;
            shortPool.lowerTotal += lowerAmount;

        }
        
        decisionToken.transferFrom(msg.sender, address(this), upperAmount + lowerAmount);
    }

    function unstake(uint upperAmount, uint lowerAmount, bool isLong) public {
        if(isLong) {
            userAcounts[msg.sender].upperLong -= upperAmount;
            userAcounts[msg.sender].lowerLong -= lowerAmount;

            longPool.upperTotal -= upperAmount;
            longPool.lowerTotal -= lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort -= upperAmount;
            userAcounts[msg.sender].lowerShort -= lowerAmount;

            shortPool.upperTotal -= upperAmount;
            shortPool.lowerTotal -= lowerAmount;

        }
        
        decisionToken.transferFrom(address(this), msg.sender, upperAmount + lowerAmount);
    }
    

    /**
        Returns the rate per second. (*1e18)
     */
    function getFundingCostForDuration(uint loanDuration, uint maximumLoanDuration) public view returns (uint){
        (uint upper, uint lower) = getFundingCostRateFx();
        return (upper + lower) * loanDuration/ maximumLoanDuration;
    }

    function getFundingCost(PoolInfo memory pool) public pure returns(uint) {
        if(pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return (pool.upperBound * pool.upperTotal + pool.lowerBound * pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    function getFundingCostRateFx() public view returns (uint, uint) {
        uint upper = getFundingCost(longPool);
        uint lower = getFundingCost(shortPool);

        return (upper, lower);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Exponential.sol";
import "./ZBond.sol";
import "./CNftInterface.sol";
import "./ComptrollerInterface.sol";
import "./AuctionMarket.sol";
/**
    @title Zumer's Provioning Pool
    @notice 

 */

abstract contract ProvisioningPool is Ownable, Exponential, ERC20 {
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
    event Received(address sender, uint amount);

    CNftInterface public immutable cNftCollateral;
    ComptrollerInterface public immutable comptroller;
    ZBond public immutable zBond;
    uint public penaltyMantissa;
    AuctionMarket public auctionMarket;
    uint public expireDuration = 30 days;

    uint totalStakedUnderlying;


    struct StakeData {
        uint expireTime;
        uint staked;
        uint unstaked;
    }
    mapping(address => StakeData[]) public userStakeData;


    constructor(ComptrollerInterface _comptroller, CNftInterface _cNftCollateral, ZBond _zBond, string memory _name, string memory _symbol, AuctionMarket _auctionMarket) ERC20(_name, _symbol) {
        comptroller = _comptroller;
        cNftCollateral = _cNftCollateral;
        zBond = _zBond;
        auctionMarket = _auctionMarket;
    }


    /**
        Stakes in the provisioning pool. Returns the number of ppToken minted.
    
     */
    function stakeInternal(uint amount , uint time) internal returns (uint){
        require(time >= expireDuration, "Stake should be at least 30 days.");
        uint mintAmount =  mulScalarTruncate(Exp(getCurrentExchangeRateMantissa()), amount);
        _mint(msg.sender, mintAmount);

        totalStakedUnderlying += amount;
        emit Staked(msg.sender, mintAmount);

        // update user timestamp data.
        StakeData memory stakeData = StakeData(time + block.timestamp, mintAmount, 0);
        userStakeData[msg.sender].push(stakeData);

        // interaction
        doTransferIn(msg.sender, amount);

        //zumerMiner.increaseBalance(msg.sender, amount);
    


        return mintAmount;
    }

    /**
        Unstakes in the provisioning pool. Returns the number of ppToken burned.
    
     */
    function unstakeInternal(uint amount) internal returns (uint) {
        require(address(this).balance >0, "Not enough to unstake in the provisioning pool.");

        // effects

        uint burnAmount = mulExp(amount, getCurrentExchangeRateMantissa()).mantissa;
        _burn(msg.sender, burnAmount);
        totalStakedUnderlying -= amount;

        // interaction
        doTransferOut(msg.sender, amount);
        emit Unstaked(msg.sender, amount);


        //zumerMiner.decreaseBalance(msg.sender, amount);


        return burnAmount;

    }


    function unstakeAll() external returns (uint) {
        uint burnedPPAmount = 0;
        uint numOfUnstakes = 0;
        uint length = userStakeData[msg.sender].length;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for(uint i = 0; i < length; i++) {
            if(sd[i].expireTime < block.timestamp) {
                burnedPPAmount += sd[i].staked - sd[i].unstaked;
                sd[i].unstaked = sd[i].staked;
                numOfUnstakes += 1;
            } 
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
/*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        } */


        // interaction
        uint burnAmount = unstakeInternal(burnedPPAmount);
        return burnAmount;

    }
    /**
        returns pp token burned and the amount 
     */
    function unstakeAmount(uint amount) external returns(uint burnAmount, uint) {
        uint burnedPPAmount = 0;
        uint numOfUnstakes = 0;
        uint length = userStakeData[msg.sender].length;
        uint insufficientAmount = amount;

        require(length > 0, "User has no stakes to unstake");
        StakeData[] storage sd = userStakeData[msg.sender];

        // effects
        for(uint i = 0; i < length; i++) {
            if(sd[i].expireTime < block.timestamp) {
                if(amount >= sd[i].staked - sd[i].unstaked) { // if we have enough tokens to unstake then unstake
                    burnedPPAmount += sd[i].staked - sd[i].unstaked;
                    numOfUnstakes += 1;
                    amount -= sd[i].staked - sd[i].unstaked;
                    sd[i].unstaked = sd[i].staked;
                }else { // else only unstake some then terminate
                    burnedPPAmount += amount;
                    sd[i].unstaked += amount;
                    amount = 0;        
                    break;        

                }
            } 
        }

        // remove empty user data/ claimed user data so the contract doesn't get locked because the array is too long
        // by shifting
/*         for(uint i = 0; i < length - numOfUnstakes; i++) {
            sd[i] = sd[i + numOfUnstakes];
        }

        for(uint i = 0; i < numOfUnstakes; i++) {
            sd.pop();
        }
 */

        // interaction
        burnAmount = unstakeInternal(burnedPPAmount);
        return (burnAmount, insufficientAmount - amount);
    }

    /** Liquidation */
    function liquidateOverDueNFT(address borrower, uint[] calldata id) public {
        // require(address(address(cNftCollateral).comptroller()) == comptroller, "comptroller does not match");

        address originalOwner = cNftCollateral.ownerOf(id[0]);

        uint repayFromProvisioning = comptroller.calculateLiquidationAmount(borrower, address(zBond), id, address(cNftCollateral));
        uint actualRepayAmount = repayAndSeize(address(this), borrower, id);
        require(cNftCollateral.ownerOf(id[0]) == address(this), "NFT liquidation failed");

        // send to auction
        uint repay;
        if (penaltyMantissa <= 1e18) {
            repay = actualRepayAmount;
        } else {
            repay = mul_(actualRepayAmount, Exp({mantissa: penaltyMantissa}));
        }

        // start auction
        auctionMarket.startAuction(id[0], repay, originalOwner, CNftInterface(address(cNftCollateral)));
    }

    function repayAndSeize(address liquidator, address borrower, uint[] calldata id) public virtual returns(uint actualRepayAmount);

    /**
     LENS FUNCTIONS
     */


    /**
        Gets the exchange rate of ppToken: underlying. Scaled by 1e18;
     */
    function getCurrentExchangeRateMantissa() public view returns (uint) {

        if(totalSupply() == 0) {
            return 1e18;
        } else {
            return getExp(totalSupply(), totalStakedUnderlying).mantissa;
        }
    }

    function getMaxBurn(address account) public view returns (uint) {
        // calculate maximum claimable.
        uint maxBurn = 0;
        for(uint i = 0; i < userStakeData[account].length; i++) {
            StakeData memory sd = userStakeData[account][i];
            if(sd.expireTime < block.timestamp) {
                maxBurn += sd.staked - sd.unstaked;
            }
        }
        return maxBurn;
    }

    function doTransferIn(address sender, uint amount) internal virtual;

    function doTransferOut(address receiver, uint amount) internal virtual;

    function getCashBalance() external view virtual  returns(uint);

    /** Replenish lending pool */
    /**
        When the lending pool run out of money, replenish the pool with money from the provisioning pool. 
    require(msg.sender == address(zBond) || msg.sender == address(auctionMarket));
        require(amount <= address(this).balance, "provisioning: insufficient funds");
     */
    function replenishLendingPoolInternal(uint amount) internal {
        totalStakedUnderlying -= amount;
        doTransferOut(address(zBond), amount);
    }


}

pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return (truncate(product) + addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: (a.mantissa + b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: (a.mantissa + b.mantissa)});
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa - b.mantissa});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa - b.mantissa});
    }


    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa * b.mantissa / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: a.mantissa * b});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return a * b.mantissa / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa * b.mantissa / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: a.mantissa * b});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return a * b.mantissa / doubleScale;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: ((a.mantissa * expScale)/ b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: (a.mantissa/ b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return ((a * expScale)/ b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: ((a.mantissa * doubleScale)/ b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: (a.mantissa/ b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return ((a * doubleScale)/ b.mantissa);
    }



    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: ((a * doubleScale)/ b)});
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.0;

import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (Exp memory) {
        uint scaledNumerator = num * expScale;
        uint rational = scaledNumerator/ denom;
        return (Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        uint result = a.mantissa + b.mantissa;

        return (Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
         uint result = a.mantissa - b.mantissa;

        return (Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        uint scaledMantissa = a.mantissa * scalar;

        return Exp({mantissa: scaledMantissa});
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mulScalar(a, scalar);

        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        (Exp memory product) = mulScalar(a, scalar);


        return truncate(product) + addend;
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (Exp memory) {
        (uint descaledMantissa) = (a.mantissa/ scalar);

        return (Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (uint numerator) = (expScale * scalar);
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (uint) {
        (Exp memory fraction) = divScalarByExp(scalar, divisor);

        return (truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {

        (uint doubleScaledProduct) = (a.mantissa * b.mantissa);


        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (uint doubleScaledProductWithHalfScale) = (halfExpScale + doubleScaledProduct);

        (uint product) = (doubleScaledProductWithHalfScale / expScale);

        return (Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (Exp memory) {
        (Exp memory ab) = mulExp(a, b);
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.8.0;

import "./ProvisioningPool.sol";

contract AuctionMarket is Ownable {
    event Start(uint id, uint repayAmount);
    event Bid(address indexed bidder, uint id, uint amount);
    event Withdraw(address indexed bidder, uint id, uint amout);
    event CloseBid(address winnder, uint closeAmount);

    uint bidExtension = 10 minutes;
    mapping(address => mapping (uint => AuctionInfo)) public auctionInfo;  // cNFT -> id -> Auction info so that this auction market can do auction for all nfts.
    mapping(address => mapping (uint => bool)) public insurance;  // if true then the NFT is being protected by insurance
    mapping(address =>mapping(address => uint) ) public accountInsurance; // hit points of the users insurance
    ProvisioningPool[] public provisioningPools;
    uint32 immutable redeemDuration  = 24 hours;
    /**
        isOnAuction: is auction still going
        redeemEndAt: the time when the borrower can no longer depay borrow debt to redeem.
        auctionEndAt: the time when the auction ends and the highest bid gets the NFT.
        highestBidder: 
        highestBid:
        borrowBalance: the balance that the borrower have to repay to redeem the NFT.
        bids: bidder vs. their bid amount
        borrower: address of the borrower who originally own the NFT. 
     */

    struct AuctionInfo {
        bool isOnAuction;
        uint redeemEndAt;
        uint auctionEndAt;
        address highestBidder;
        uint highestBid;
        uint borrowRepay;
        mapping(address => uint) bids;
        address borrower;
    }

    function setProvisioningPool(ProvisioningPool pp) public onlyOwner {
        provisioningPools.push(pp);
    }

    /** Pay penalty */
    function redeemAndPayPenalty(uint id, CNftInterface cNftCollateral) external payable {
        require(block.timestamp < auctionInfo[address(cNftCollateral)][id].redeemEndAt, "Redeem period over.");
        require(msg.sender == auctionInfo[address(cNftCollateral)][id].borrower, "redeemer not the borrower");
        uint repay = auctionInfo[address(cNftCollateral)][id].borrowRepay;
        require(msg.value >= repay, "insufficient redeem amount");
        if(msg.value > repay) {
            //payable(msg.sender).transfer(msg.value - repay);
        }
        // return the NFT
        cNftCollateral.safeTransferFrom(address(this), msg.sender, id);
        
        // end bid
        endBid(id, repay, address(cNftCollateral));
    }

    /** Auction */
    /**

        struct AuctionInfo {
        bool isOnAuction;
        uint32 redeemEndAt;
        uint32 auctionEndAt;
        address highestBidder;
        uint highestBid;
        uint borrowBalance;
        mapping(address => uint) bids;
        }
     */
    function startAuction(uint id, uint repayAmount, address originalOwner, CNftInterface cNftCollateral) public {
        //require(address(cNftCollateral.comptroller()) == comptroller, "comptroller does not match");
        require(cNftCollateral.ownerOf(id) == address(this), "Auct pool does not own this NFT.");
        require(!auctionInfo[address(cNftCollateral)][id].isOnAuction, "NFT already on auction.");

        // initialize the auction
        auctionInfo[address(cNftCollateral)][id].isOnAuction = true;

        if(accountInsurance[originalOwner][address(cNftCollateral)] > 0) {
            auctionInfo[address(cNftCollateral)][id].redeemEndAt = block.timestamp + redeemDuration;
            spendInsurance(address(cNftCollateral), originalOwner);
        } else {
            auctionInfo[address(cNftCollateral)][id].redeemEndAt = block.timestamp;
        }
        auctionInfo[address(cNftCollateral)][id].redeemEndAt = block.timestamp + redeemDuration;
        auctionInfo[address(cNftCollateral)][id].auctionEndAt = block.timestamp + redeemDuration;
        auctionInfo[address(cNftCollateral)][id].borrowRepay = repayAmount;
        auctionInfo[address(cNftCollateral)][id].borrower = originalOwner;
    }

    function bid(uint id, address cNftCollateral) payable public{
        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];


        require(msg.value + auction.bids[msg.sender] > auction.highestBid, "Bid must be higher than the highest bid");
        require(msg.value + auction.bids[msg.sender] > auction.borrowRepay, "Bid must be higher than the borrow repay");
        require(block.timestamp < auction.auctionEndAt && auction.isOnAuction, "Auction ended");
        auction.bids[msg.sender] += msg.value;
        auction.highestBid += msg.value;
        auction.highestBidder = msg.sender;

        // extend bid time if within the last bidding period. 
        if(block.timestamp > auction.auctionEndAt - bidExtension) {
            auction.auctionEndAt = block.timestamp + bidExtension;
        }

        emit Bid(msg.sender, id, msg.value);
    }

    function withdrawBid(uint id, address cNftCollateral) public {

        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];
        require(msg.sender != auction.highestBidder, "Highest bidder"); // highest bidder cannot withdraw
        require(auction.bids[msg.sender] > 0, "Non existing bidder");
        
        // transfer bid & reset the bid
        auction.bids[msg.sender] = 0;
        //payable(msg.sender).transfer(auction.bids[msg.sender]);

        emit Withdraw(msg.sender, id, auction.bids[msg.sender]);
    }

    function withdrawBidAll(uint[] calldata id, address cNftCollateral) public {
        for(uint i = 0; i < id.length; i++) {
            withdrawBid(id[i], cNftCollateral);
        }
    }

    function winBid(uint id, ProvisioningPool provisioningPool) public {
        CNftInterface cNftCollateral = provisioningPool.cNftCollateral();
        AuctionInfo storage auction = auctionInfo[address(cNftCollateral)][id];

        require(block.timestamp > auction.auctionEndAt, "Auction ongoing");
        require(auction.isOnAuction, "Auction ended");
        if (auction.highestBidder != address(0)) {
            cNftCollateral.transferFrom(address(this), auction.highestBidder, id);
            // end the auction
            endBid(id, auction.highestBid, address(cNftCollateral)); // end bid and replenish money in the Provisioning pool
            //payable(provisioningPool).transfer(auction.highestBid);

        } else { 
            // continue auction
            auction.auctionEndAt = block.timestamp + redeemDuration;
        }

    }

    function endBid(uint id, uint closeAmount, address cNftCollateral) internal {
        AuctionInfo storage auction = auctionInfo[cNftCollateral][id];
        auction.isOnAuction = false;
        auction.redeemEndAt = 0;
        auction.auctionEndAt = 0;
        auction.borrowRepay = 0;
        auction.highestBidder = address(0);
        auction.highestBid = 0;
        auction.borrower = address(0);
        emit CloseBid(auction.highestBidder, closeAmount);
        
    }

    function activateInsurance(address cNftCollateralAddress, address originalOwner, uint amount) public {
        accountInsurance[cNftCollateralAddress][originalOwner] += amount;

    }

    function spendInsurance(address cNftCollateralAddress, address originalOwner) internal {
        // spend insurance on the event of being liquidatedated
        accountInsurance[originalOwner][cNftCollateralAddress] -= 1; // spend insurance

    }



    
}