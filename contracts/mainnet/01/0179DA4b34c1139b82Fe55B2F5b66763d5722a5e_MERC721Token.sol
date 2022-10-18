pragma solidity ^0.5.16;

contract MtrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        MTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        INVALID_TOKEN_TYPE
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
        MTROLLER_REJECTION,
        MTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        INVALID_COLLATERAL,
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
        AUCTION_NOT_ALLOWED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_MTROLLER_REJECTION,
        FLASH_LOAN_BORROW_FAILED,
        FLASH_OPERATION_NOT_DEFINED,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COLLATERAL_NOT_FUNGIBLE,
        LIQUIDATE_COLLATERAL_NOT_EXISTING,
        LIQUIDATE_MTROLLER_REJECTION,
        LIQUIDATE_MTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_GRACE_PERIOD_NOT_EXPIRED,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_NOT_PREFERRED_LIQUIDATOR,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_MTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        LIQUIDATE_SEIZE_NON_FUNGIBLE_ASSET,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_MTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_NEW_TOTAL_CASH_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_MTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDEEM_MARKET_EXIT_NOT_POSSIBLE,
        REDEEM_NOT_OWNER,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_MTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_GLOBAL_PARAMETERS_VALUE_CHECK,
        SET_MTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_FLASH_WHITELIST_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        SET_TOKEN_AUCTION_OWNER_CHECK,
        TRANSFER_MTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TOTAL_CASH_CALCULATION_FAILED,
        ADD_RESERVES_TOTAL_RESERVES_CALCULATION_FAILED,
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

pragma solidity ^0.5.16;

import "./ErrorReporter.sol";
import "./MtrollerInterface.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";

/**
 * @title MDelegator
 * @dev Storage for the delegatee is at this contract, while execution is delegated.
 * @author mmo.finance
 */
contract MDelegator is MDelegatorIdentifier {

    // Storage position of the address of the user part of the current implementation
    bytes32 private constant mDelegatorUserImplementationPosition = 
        keccak256("com.mmo-finance.mDelegator.user.implementation.address");
    
    // Storage position of the address of the admin part of the current implementation
    bytes32 private constant mDelegatorAdminImplementationPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.implementation.address");
    
    // Storage position base of the implemented admin function selector verifiers
    bytes32 private constant mDelegatorAdminImplementationSelectorPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.implementation.selector.bool");
    
    // Storage position of the enable implementation update flag
    bytes32 private constant mDelegatorEnableUpdate = 
        keccak256("com.mmo-finance.mDelegator.enableUpdate.bool");
    
    /**
    * @dev the constructor sets the admin
    */
    constructor() public {
        _setMDelegatorAdmin(msg.sender);
        // initially enable implementation updates
        bool _enable = true;
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            sstore(position, _enable)
        }
    }
    
    /**
     * @notice Tells the address of the current mDelegatorUserImplementation
     * @return implementation The address of the current mDelegatorUserImplementation
     */
    function mDelegatorUserImplementation() public view returns (address implementation) {
        bytes32 position = mDelegatorUserImplementationPosition;
        assembly {
            implementation := sload(position)
        }
    }
    
    /**
     * @notice Tells the address of the current mDelegatorAdminImplementation
     * @return implementation The address of the current mDelegatorAdminImplementation
     */
    function mDelegatorAdminImplementation() public view returns (address implementation) {
        bytes32 position = mDelegatorAdminImplementationPosition;
        assembly {
            implementation := sload(position)
        }
    }
    
    /**
     * @notice Tells if the current mDelegatorAdminImplementation supports the given function selector
     * @param selector The function selector (signature) to check, e.g. bytes4(keccak256('func()'))
     * @return supported Returns true if the selector is supported
     */
    function mDelegatorAdminImplementationSelectorSupported(bytes4 selector) public view returns (bool supported) {
        bytes32 position = keccak256(abi.encode(selector, mDelegatorAdminImplementationSelectorPosition));
        assembly {
            supported := sload(position)
        }
    }

    /**
     * @notice Tells if updating implementations is enabled
     * @return enabled Returns true if the admin and user implementations can be updated
     */
    function mDelegatorImplementationUpdateEnabled() public view returns (bool enabled) {
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            enabled := sload(position)
        }
    }

    /**
     * @notice Tells the address of the current admin
     * @return admin The address of the current admin
     */
    function mDelegatorAdmin() public view returns (address admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }
    
    /**
     * @notice Sets the two addresses of the current implementation
     * @dev Gets implementedSelectors[] from new admin implementation and marks them as supported
     * @param _newUserImplementation address of the new mDelegatorUserImplementation
     * @param _newAdminImplementation address of the new mDelegatorAdminImplementation
     */
    function _setImplementation(address _newUserImplementation, address _newAdminImplementation) public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        require(mDelegatorImplementationUpdateEnabled(), "update disabled");
        require(MTokenInterface(_newUserImplementation).isMDelegatorUserImplementation(), "invalid user implementation");
        require(MTokenInterface(_newAdminImplementation).isMDelegatorAdminImplementation(), "invalid admin implementation");
        MDelegateeStorage oldAdminImpl = MDelegateeStorage(mDelegatorAdminImplementation());
        MDelegateeStorage newAdminImpl = MDelegateeStorage(_newAdminImplementation);

        // delete mapping entries for previously supported selectors (if needed)
        if (address(oldAdminImpl) != address(0)) {
            uint len = oldAdminImpl.implementedSelectorsLength();
            for (uint i = 0; i < len; i++) {
                _setAdminSelectorSupported(oldAdminImpl.implementedSelectors(i), false);
            }
        }

        // change to new implementations
        bytes32 positionUser = mDelegatorUserImplementationPosition;
        bytes32 positionAdmin = mDelegatorAdminImplementationPosition;
        assembly {
            sstore(positionUser, _newUserImplementation)
            sstore(positionAdmin, _newAdminImplementation)
        }

        // add mapping entries for newly supported selectors
        uint len = newAdminImpl.implementedSelectorsLength();
        for (uint i = 0; i < len; i++) {
            _setAdminSelectorSupported(newAdminImpl.implementedSelectors(i), true);
        }
    }
    
    /**
     * @notice Marks the given function selector as supported by the current mDelegatorAdminImplementation
     * @param selector The function selector (signature) to mark as supported, e.g. bytes4(keccak256('func()'))
     * @param supported Set true if to be marked as supported, else set to false
     */
    function _setAdminSelectorSupported(bytes4 selector, bool supported) public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        bytes32 position = keccak256(abi.encode(selector, mDelegatorAdminImplementationSelectorPosition));
        assembly {
            sstore(position, supported)
        }
    }

    /**
     * @notice Disable further implementation updates (NOTE: irreversible change!)
     */
    function _disableFurtherImplementationUpdates() public {
        require(msg.sender == mDelegatorAdmin(), "only admin");
        bool _enable = false;
        bytes32 position = mDelegatorEnableUpdate;
        assembly {
            sstore(position, _enable)
        }
    }

    /**
     * @notice Sets the address of the admin
     */
    function _setMDelegatorAdmin(address _newAdmin) public {
        if (mDelegatorAdmin() != address(0)) {
            require(msg.sender == mDelegatorAdmin(), "only admin");
            require(_newAdmin != address(0), "invalid new admin");
        }
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            sstore(position, _newAdmin)
        }
    }

    /**
     * @notice Delegates execution of all other functions to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        address implementation;

        // if the function selector msg.sig is supported by the admin implementation, choose the admin implementation
        // else choose the user implementation (default)
        if (mDelegatorAdminImplementationSelectorSupported(msg.sig)) {
            implementation = mDelegatorAdminImplementation();
        }
        else {
            implementation = mDelegatorUserImplementation();
        }
        
        // delegate call to chosen implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}

/* The three contracts that are currently using MDelegator */

contract Mtroller is MDelegator {
    constructor(MtrollerUserInterface userImpl, MtrollerAdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}

contract MEther is MDelegator {
    constructor(MEtherUserInterface userImpl, MEtherAdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}

contract MERC721Token is MDelegator {
    constructor(MERC721UserInterface userImpl, MERC721AdminInterface adminImpl) public MDelegator() {
        _setImplementation(address(userImpl), address(adminImpl));
    }
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";
import "./compound/EIP20NonStandardInterface.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";

contract MTokenCommonInterface is MTokenIdentifier, MDelegatorIdentifier {

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint240 mToken, uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Events emitted when tokens are minted
     */
    event Mint(address minter, address beneficiary, uint mintAmountUnderlying, uint240 mTokenMinted, uint amountTokensMinted);

    /**
     * @notice Events emitted when tokens are transferred
     */
    event Transfer(address from, address to, uint240 mToken, uint amountTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint240 mToken, uint redeemTokens, uint256 underlyingID, uint underlyingRedeemAmount);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 underlyingID, uint borrowAmount, uint paidOutAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when underlying is borrowed in a flash loan operation
     */
    event FlashBorrow(address borrower, uint256 underlyingID, address receiver, uint downPayment, uint borrowAmount, uint paidOutAmount);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 underlyingID, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint240 mTokenBorrowed, uint repayAmountUnderlying, uint240 mTokenCollateral, uint seizeTokens);

    /**
     * @notice Event emitted when a grace period is started before liquidating a token with an auction
     */
    event GracePeriod(uint240 mTokenCollateral, uint lastBlockOfGracePeriod);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when flash receiver whitlist is changed
     */
    event FlashReceiverWhitelistChanged(address receiver, bool newState);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when tokenAuction is changed
     */
    event NewTokenAuction(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /**
     * @notice Event emitted when mtroller is changed
     */
    event NewMtroller(MtrollerInterface oldMtroller, MtrollerInterface newMtroller);

    /**
     * @notice Event emitted when global protocol parameters are updated
     */
    event NewGlobalProtocolParameters(uint newInitialExchangeRateMantissa, uint newReserveFactorMantissa, uint newProtocolSeizeShareMantissa, uint newBorrowFeeMantissa);

    /**
     * @notice Event emitted when global auction parameters are updated
     */
    event NewGlobalAuctionParameters(uint newAuctionGracePeriod, uint newPreferredLiquidatorHeadstart, uint newMinimumOfferMantissa, uint newLiquidatorAuctionFeeMantissa, uint newProtocolAuctionFeeMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint240 mToken, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint240 mToken, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    function getAdmin() public view returns (address payable admin);
    function accrueInterest(uint240 mToken) public returns (uint);
}

contract MTokenAdminInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    /*** Admin Functions ***/

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
    function _setTokenAuction(TokenAuction newTokenAuction) public returns (uint);
    function _setMtroller(MtrollerInterface newMtroller) public returns (uint);
    function _setGlobalProtocolParameters(uint _initialExchangeRateMantissa, uint _reserveFactorMantissa, uint _protocolSeizeShareMantissa, uint _borrowFeeMantissa) public returns (uint);
    function _setGlobalAuctionParameters(uint _auctionGracePeriod, uint _preferredLiquidatorHeadstart, uint _minimumOfferMantissa, uint _liquidatorAuctionFeeMantissa, uint _protocolAuctionFeeMantissa) public returns (uint);
    function _reduceReserves(uint240 mToken, uint reduceAmount) external returns (uint);
    function _sweepERC20(address tokenContract) external returns (uint);
    function _sweepERC721(address tokenContract, uint256 tokenID) external;
}

contract MTokenUserInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** User Interface ***/

    function balanceOf(address owner, uint240 mToken) external view returns (uint);
    function getAccountSnapshot(address account, uint240 mToken) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock(uint240 mToken) external view returns (uint);
    function supplyRatePerBlock(uint240 mToken) external view returns (uint);
    function totalBorrowsCurrent(uint240 mToken) external returns (uint);
    function borrowBalanceCurrent(address account, uint240 mToken) external returns (uint);
    function borrowBalanceStored(address account, uint240 mToken) public view returns (uint);
    function exchangeRateCurrent(uint240 mToken) external returns (uint);
    function exchangeRateStored(uint240 mToken) external view returns (uint);
    function getCash(uint240 mToken) external view returns (uint);
    function seize(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) external returns (uint);
}

contract MTokenInterface is MTokenAdminInterface, MTokenUserInterface {}

contract MFungibleTokenAdminInterface is MTokenAdminInterface {
}

contract MFungibleTokenUserInterface is MTokenUserInterface{

    /*** Market Events ***/

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

contract MFungibleTokenInterface is MFungibleTokenAdminInterface, MFungibleTokenUserInterface {}

contract MEtherAdminInterface is MFungibleTokenAdminInterface {

    /*** Admin Functions ***/

    function initialize(MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public;

    /*** User Interface ***/

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function flashBorrow(uint borrowAmount, address payable receiver, bytes calldata flashParams) external payable returns (uint);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);
}

contract MEtherUserInterface is MFungibleTokenUserInterface {

    /*** Admin Functions ***/

    function getProtocolAuctionFeeMantissa() external view returns (uint);
    function _addReserves() external payable returns (uint);

    /*** User Interface ***/

    function mint() external payable returns (uint);
    function mintTo(address beneficiary) external payable returns (uint);
    function repayBorrow() external payable returns (uint);
    function repayBorrowBehalf(address borrower) external payable returns (uint);
    function liquidateBorrow(address borrower, uint240 mTokenCollateral) external payable returns (uint);
}

contract MEtherInterface is MEtherAdminInterface, MEtherUserInterface {}

contract MERC721AdminInterface is MTokenAdminInterface, IERC721, IERC721Metadata {

    event NewTokenAuctionContract(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /*** Admin Functions ***/

    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                TokenAuction tokenAuction_,
                string memory name_,
                string memory symbol_) public;

    /*** User Interface ***/

    function redeem(uint240 mToken) public returns (uint);
    function redeemUnderlying(uint256 underlyingID) external returns (uint);
    function redeemAndSell(uint240 mToken, uint sellPrice, address payable transferHandler, bytes memory transferParams) public returns (uint);
    function borrow(uint256 borrowUnderlyingID) external returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MERC721UserInterface is MTokenUserInterface, IERC721 {

    event LiquidateToPaymentToken(address indexed oldOwner, address indexed newOwner, uint240 mToken, uint256 auctioneerTokens, uint256 oldOwnerTokens);

    /*** Admin Functions ***/

//    function _addReserves(uint240 mToken, uint addAmount) external payable returns (uint);

    /*** User Interface ***/

    function mint(uint256 underlyingTokenID) external returns (uint240);
    function mintAndCollateralizeTo(address beneficiary, uint256 underlyingTokenID) external returns (uint240);
    function mintTo(address beneficiary, uint256 underlyingTokenID) public returns (uint240);
//    function repayBorrow(uint256 repayUnderlyingID) external payable returns (uint);
//    function repayBorrowBehalf(address borrower, uint256 repayUnderlyingID) external payable returns (uint);
//    function liquidateBorrow(address borrower, uint256 repayUnderlyingID, uint240 mTokenCollateral) external payable returns (uint);
    function addAuctionBid(uint240 mToken) external payable;
    function instantSellToHighestBidder(uint240 mToken, uint256 minimumPrice) public;
    function setAskingPrice(uint240 mToken, uint256 newAskingPrice) external;
    function startGracePeriod(uint240 mToken) external returns (uint);
    function liquidateToPaymentToken(uint240 mToken) external returns (uint, uint240, uint, uint);
}

contract MERC721Interface is MERC721AdminInterface, MERC721UserInterface {}

contract FlashLoanReceiverInterface {
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external returns (uint);
    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external returns (uint);
}

pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";

contract MDelegateeStorage {
    /**
    * @notice List of all public function selectors implemented by "admin type" contract
    * @dev Needs to be initialized in the constructor(s)
    */
    bytes4[] public implementedSelectors;

    function implementedSelectorsLength() public view returns (uint) {
        return implementedSelectors.length;
    }
}

contract MTokenV1Storage is MDelegateeStorage {

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;
    bool internal _notEntered2;


    /*** Global variables: addresses of other contracts to call. 
     *   These are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Address of the underlying asset contract (this never changes again after initialization)
     */
    address public underlyingContract;

    /**
     * @notice Contract address of model which tells what the current interest rate(s) should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Contract used for (non-fungible) mToken auction (used only if applicable)
     */ 
    TokenAuction public tokenAuction;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    MtrollerInterface public mtroller;


    /*** Global variables: token identification constants. 
     *   These variables are set at contract initialization and never modified again
    ***/

    /**
     * @notice EIP-20 token name for this token
     */
    string public mName;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public mSymbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public mDecimals;


    /*** Global variables: protocol control parameters. 
     *   These variables are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Initial exchange rate used when minting the first mTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public reserveFactorMantissa;

    /**
     * @notice Fraction of seized (fungible) collateral that is added to reserves
     */
    uint internal constant protocolSeizeShareMaxMantissa = 5e16; // upper protocol limit (5%)
    uint public protocolSeizeShareMantissa;

    /**
     * @notice Fraction of new borrow amount set aside for reserves (one-time fee)
     */
    uint internal constant borrowFeeMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public borrowFeeMantissa;

    /**
     * @notice Mapping of addresses that are whitelisted as receiver for flash loans
     */
    mapping (address => bool) public flashReceiverIsWhitelisted;


    /*** Global variables: auction liquidation control parameters. 
     *   The variables are set at contract initialization and can only be changed by a (timelock) admin
    ***/

    /**
     * @notice Minimum and maximum values that can ever be used for the grace period, which is
     * the minimum time liquidators have to wait before they can seize a non-fungible mToken collateral
     */ 
    uint256 public constant auctionMinGracePeriod = 2000; // lower limit (2000 blocks, i.e. about 8 hours)
    uint256 public constant auctionMaxGracePeriod = 50000; // upper limit (50000 blocks, i.e. about 8.5 days)
    uint256 public auctionGracePeriod;

    /**
     * @notice "Headstart" time in blocks the preferredLiquidator has available to liquidate a mToken
     * exclusively before everybody else is also allowed to do it.
     */
    uint256 public constant preferredLiquidatorMaxHeadstart = 2000; // upper limit (2000 blocks, i.e. about 8 hours)
    uint256 public preferredLiquidatorHeadstart;

    /**
     * @notice Minimum offer required to win liquidation auction, relative to the NFTs regular price.
     */
    uint public constant minimumOfferMaxMantissa = 80e16; // upper limit (80% of market price)
    uint public minimumOfferMantissa;

    /**
     * @notice Fee for the liquidator executing liquidateToPaymentToken().
     */
    uint public constant liquidatorAuctionFeeMaxMantissa = 10e16; // upper limit (10%)
    uint public liquidatorAuctionFeeMantissa;

    /**
     * @notice Fee for the protocol when executing liquidateToPaymentToken() or acceptHighestOffer().
     * The funds are directly added to mEther reserves.
     */
    uint public constant protocolAuctionFeeMaxMantissa = 20e16; // upper limit (50%)
    uint public protocolAuctionFeeMantissa;


    /*** Token variables: basic token identification. 
     *   These variables are only initialized the first time the given token is minted
    ***/

    /**
     * @notice Mapping of mToken to underlying tokenID
     */
    mapping (uint240 => uint256) public underlyingIDs;

    /**
     * @notice Mapping of underlying tokenID to mToken
     */
    mapping (uint256 => uint240) public mTokenFromUnderlying;

    /**
     * @notice Total number of (ever) minted mTokens. Note: Burning a mToken (when redeeming the 
     * underlying asset) DOES NOT reduce this count. The maximum possible amount of tokens that 
     * can ever be minted by this contract is limited to 2^88-1, which is finite but high enough 
     * to never be reached in realistic time spans.
     */
    uint256 public totalCreatedMarkets;

    /**
     * @notice Maps mToken to block number that interest was last accrued at
     */
    mapping (uint240 => uint) public accrualBlockNumber;

    /**
     * @notice Maps mToken to accumulator of the total earned interest rate since the opening of that market
     */
    mapping (uint240 => uint) public borrowIndex;


    /*** Token variables: general token accounting. 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Official record of token balances for each mToken, for each account
     */
    mapping (uint240 => mapping (address => uint)) internal accountTokens;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances, for any given mToken
     */
    mapping(uint240 => mapping(address => BorrowSnapshot)) internal accountBorrows;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maps mToken to total amount of cash of the underlying in that market
     */
    mapping (uint240 => uint) public totalCashUnderlying;

    /**
     * @notice Maps mToken to total amount of outstanding borrows of the underlying in that market
     */
    mapping (uint240 => uint) public totalBorrows;

    /**
     * @notice Maps mToken to total amount of reserves of the underlying held in that market
     */
    mapping (uint240 => uint) public totalReserves;

    /**
     * @notice Maps mToken to total number of tokens in circulation in that market
     */
    mapping (uint240 => uint) public totalSupply;


    /*** Token variables: Special variables used for fungible tokens (e.g. ERC-20). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Dummy ID for "underlying asset" in case of a (single) fungible token
     */
    uint256 internal constant dummyTokenID = 1;

    /**
     * @notice The mToken for a (single) fungible token
     */
    uint240 public thisFungibleMToken;

    /**
     * @notice Approved token transfer amounts on behalf of others (for fungible tokens)
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;


    /*** Token variables: Special variables used for non-fungible tokens (e.g. ERC-721). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Virtual amount of "cash" that corresponds to one underlying NFT. This is used as 
     * calculatory units internally for mTokens with strictly non-fungible underlying (such as ERC-721) 
     * to avoid loss of mathematical precision for calculations such as borrowing amounts. However, both 
     * underlying NFT and associated mToken are still non-fungible (ERC-721 compliant) tokens and can 
     * only be transferred as one item.
     */
    uint internal constant oneUnit = 1e18;

    /**
     * @notice Mapping of mToken to the block number of the last block in their grace period (zero
     * if mToken is not in a grace period)
     */
    mapping (uint240 => uint256) public lastBlockGracePeriod;

    /**
     * @notice Mapping of mToken to the address that has "fist mover" rights to do the liquidation
     * for the mToken (because that address first called startGracePeriod())
     */
    mapping (uint240 => address) public preferredLiquidator;

    /**
     * @notice Asking price that can be set by a mToken's current owner. At or above this price the mToken
     * will be instantly sold. Set to zero to disable.
     */
    mapping (uint240 => uint256) public askingPrice;
}

pragma solidity ^0.5.16;

import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";
import "./open-zeppelin/token/ERC20/ERC20.sol";

contract TestNFT is ERC721, IERC721Metadata {

    string internal constant _name = "Glasses";
    string internal constant _symbol = "GLSS";
    uint256 public constant price = 0.1e18;
    uint256 public constant maxSupply = 1000;
    uint256 public nextTokenID;
    address payable public admin;
    string internal _baseURI;
    uint internal _digits;
    string internal _suffix;

    constructor(address payable _admin) ERC721(_name, _symbol) public {
        admin = msg.sender;
        _setMetadata("ipfs://QmWNi2ByeUbY1fWbMq841nvNW2tDTpNzyGAhxWDqoXTAEr", 0, "");
        admin = _admin;
    }
    
    function mint() public payable returns (uint256 newTokenID) {
        require(nextTokenID < maxSupply, "all Glasses sold out");
        require(msg.value >= price, "payment too low");
        newTokenID = nextTokenID;
        nextTokenID++;
        _safeMint(msg.sender, newTokenID);
    }

    function () external payable {
        mint();
    }

//***** below this is just for trying out NFTX market functionality */
    function buyAndRedeem(uint256 vaultId, uint256 amount, uint256[] calldata specificIds, address[] calldata path, address to) external payable {
        path;
        require(vaultId == 2, "wrong vault");
        require(amount == 1, "wrong amount");
        require(specificIds[0] == nextTokenID, "wrong ID");
        require(to == msg.sender, "wrong to");
        mint();
    }
//***** above this is just for trying out NFTX market functionality */

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (_digits == 0) {
            return string(abi.encodePacked(_baseURI, _suffix));
        }
        else {
            bytes memory _tokenID = new bytes(_digits);
            uint _i = _digits;
            while (_i != 0) {
                _i--;
                _tokenID[_i] = bytes1(48 + uint8(tokenId % 10));
                tokenId /= 10;
            }
            return string(abi.encodePacked(_baseURI, string(_tokenID), _suffix));
        }
    }

    /*** Admin functions ***/

    function _setMetadata(string memory newBaseURI, uint newDigits, string memory newSuffix) public {
        require(msg.sender == admin, "only admin");
        require(newDigits < 10, "newDigits too big");
        _baseURI = newBaseURI;
        _digits = newDigits;
        _suffix = newSuffix;
    }

    function _setAdmin(address payable newAdmin) public {
        require(msg.sender == admin, "only admin");
        admin = newAdmin;
    }

    function _withdraw() external {
        require(msg.sender == admin, "only admin");
        admin.transfer(address(this).balance);
    }
}

contract TestERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";

contract MTokenIdentifier {
    /* mToken identifier handling */
    
    enum MTokenType {
        INVALID_MTOKEN,
        FUNGIBLE_MTOKEN,
        ERC721_MTOKEN
    }

    /*
     * Marker for valid mToken contract. Derived MToken contracts need to override this returning 
     * the correct MTokenType for that MToken
    */
    function getTokenType() public pure returns (MTokenType) {
        return MTokenType.INVALID_MTOKEN;
    }
}

contract MDelegatorIdentifier {
    // Storage position of the admin of a delegator contract
    bytes32 internal constant mDelegatorAdminPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.address");
}

contract MtrollerCommonInterface is MTokenIdentifier, MDelegatorIdentifier {
    /// @notice Emitted when an admin supports a market
    event MarketListed(uint240 mToken);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(uint240 mToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when an account enters a market
    event MarketEntered(uint240 mToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(uint240 mToken, address account);

    /// @notice Emitted when a new MMO speed is calculated for a market
    event MmoSpeedUpdated(uint240 indexed mToken, uint newSpeed);

    /// @notice Emitted when a new MMO speed is set for a contributor
    event ContributorMmoSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when MMO is distributed to a supplier
    event DistributedSupplierMmo(uint240 indexed mToken, address indexed supplier, uint mmoDelta, uint MmoSupplyIndex);

    /// @notice Emitted when MMO is distributed to a borrower
    event DistributedBorrowerMmo(uint240 indexed mToken, address indexed borrower, uint mmoDelta, uint mmoBorrowIndex);

    /// @notice Emitted when MMO is granted by admin
    event MmoGranted(address recipient, uint amount);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(uint240 mToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(uint240 indexed mToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    function getAdmin() public view returns (address payable admin);

    function underlyingContractETH() public pure returns (address);
    function getAnchorToken(address mTokenContract) public pure returns (uint240);
    function assembleToken(MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) public pure returns (uint240 mToken);
    function parseToken(uint240 mToken) public pure returns (MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress);

    function collateralFactorMantissa(uint240 mToken) public view returns (uint);
}

contract MtrollerUserInterface is MtrollerCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** Assets You Are In ***/

    function getAssetsIn(address account) external view returns (uint240[] memory);
    function checkMembership(address account, uint240 mToken) external view returns (bool);
    function enterMarkets(uint240[] calldata mTokens) external returns (uint[] memory);
    function enterMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function exitMarket(uint240 mToken) external returns (uint);
    function exitMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function _setCollateralFactor(uint240 mToken, uint newCollateralFactorMantissa) external returns (uint);

    /*** Policy Hooks ***/

    function auctionAllowed(uint240 mToken, address bidder) public view returns (uint);
    function mintAllowed(uint240 mToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(uint240 mToken, address minter, uint actualMintAmount, uint mintTokens) external view;
    function redeemAllowed(uint240 mToken, address redeemer, uint redeemTokens) external view returns (uint);
    function redeemVerify(uint240 mToken, address redeemer, uint redeemAmount, uint redeemTokens) external view;
    function borrowAllowed(uint240 mToken, address borrower, uint borrowAmount) external view returns (uint);
    function borrowVerify(uint240 mToken, address borrower, uint borrowAmount) external view;
    function repayBorrowAllowed(uint240 mToken, address payer, address borrower, uint repayAmount) external view returns (uint);
    function repayBorrowVerify(uint240 mToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex) external view;
    function liquidateBorrowAllowed(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint repayAmount) external view returns (uint);
    function liquidateERC721Allowed(uint240 mToken) external view returns (uint);
    function liquidateBorrowVerify(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint actualRepayAmount, uint seizeTokens) external view;
    function seizeAllowed(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view returns (uint);
    function seizeVerify(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view;
    function transferAllowed(uint240 mToken, address src, address dst, uint transferTokens) external view returns (uint);
    function transferVerify(uint240 mToken, address src, address dst, uint transferTokens) external view;

    /*** Price and Liquidity/Liquidation Calculations ***/
    function getAccountLiquidity(address account) public view returns (uint, uint, uint);
    function getHypotheticalAccountLiquidity(address account, uint240 mTokenModify, uint redeemTokens, uint borrowAmount) public view returns (uint, uint, uint);
    function liquidateCalculateSeizeTokens(uint240 mTokenBorrowed, uint240 mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint);
    function getBlockNumber() public view returns (uint);
    function getPrice(uint240 mToken) public view returns (uint);

    /*** Mmo reward handling ***/
    function updateContributorRewards(address contributor) public;
    function claimMmo(address holder, uint240[] memory mTokens) public;
    function claimMmo(address[] memory holders, uint240[] memory mTokens, bool borrowers, bool suppliers) public;

    /*** Mmo admin functions ***/
    function _grantMmo(address recipient, uint amount) public;
    function _setMmoSpeed(uint240 mToken, uint mmoSpeed) public;
    function _setContributorMmoSpeed(address contributor, uint mmoSpeed) public;
    function getMmoAddress() public view returns (address);
}

contract MtrollerAdminInterface is MtrollerCommonInterface {

    function initialize(address _mmoTokenAddress, uint _maxAssets) public;

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    function _supportMarket(uint240 mToken) external returns (uint);
    function _setPriceOracle(PriceOracle newOracle) external returns (uint);
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint);
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint);
    function _setMaxAssets(uint newMaxAssets) external;
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;
    function _setMarketBorrowCaps(uint240[] calldata mTokens, uint[] calldata newBorrowCaps) external;
    function _setPauseGuardian(address newPauseGuardian) public returns (uint);
    function _setAuctionPaused(uint240 mToken, bool state) public returns (bool);
    function _setMintPaused(uint240 mToken, bool state) public returns (bool);
    function _setBorrowPaused(uint240 mToken, bool state) public returns (bool);
    function _setTransferPaused(uint240 mToken, bool state) public returns (bool);
    function _setSeizePaused(uint240 mToken, bool state) public returns (bool);
}

contract MtrollerInterface is MtrollerAdminInterface, MtrollerUserInterface {}

pragma solidity ^0.5.16;

import "./MTokenTest_coins.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the price of an underlying token
      * @param underlyingToken The address of the underlying token contract
      * @param tokenID The ID of the underlying token if it is a NFT (0 for fungible tokens)
      * @return The underlying asset price mantissa (scaled by 1e18). For fungible underlying tokens that
      * means e.g. if one single underlying token costs 1 Wei then the asset price mantissa should be 1e18. 
      * In case of underlying (ERC-721 compliant) NFTs one NFT always corresponds to oneUnit = 1e18 
      * internal calculatory units (see MTokenInterfaces.sol), therefore if e.g. one NFT costs 0.1 ETH 
      * then the asset price mantissa returned here should be 0.1e18.
      * Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint);
}

contract PriceOracleV0_1 is PriceOracle {

    event NewCollectionFloorPrice(uint oldFloorPrice, uint newFloorPrice);

    address admin;
    TestNFT glassesContract;
    IERC721 collectionContract;
    uint collectionFloorPrice;

    constructor(address _admin, TestNFT _glassesContract, IERC721 _collectionContract) public {
        admin = _admin;
        glassesContract = _glassesContract;
        collectionContract = _collectionContract;
    }

    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint) {
        tokenID;
        if (underlyingToken == address(uint160(-1))) {
            return 1.0e18; // relative price of MEther token is 1.0 (1 token = 1 Wei)
        }
        else if (underlyingToken == address(glassesContract)) {
            return glassesContract.price(); // one unit (1e18) of NFT price in wei
        }
        else if (underlyingToken == address(collectionContract)) {
            return collectionFloorPrice; // one unit (1e18) of NFT price in wei
        }
        else {
            return 0;
        }
    }

    function _setCollectionFloorPrice(uint newFloorPrice) external {
        require(msg.sender == admin, "only admin");
        uint oldFloorPrice = collectionFloorPrice;
        collectionFloorPrice = newFloorPrice;

        emit NewCollectionFloorPrice(oldFloorPrice, newFloorPrice);
    }
}

pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

contract TokenAuction is Exponential, TokenErrorReporter {

    event NewAuctionOffer(uint240 tokenID, address offeror, uint256 totalOfferAmount);
    event AuctionOfferCancelled(uint240 tokenID, address offeror, uint256 cancelledOfferAmount);
    event HighestOfferAccepted(uint240 tokenID, address offeror, uint256 acceptedOfferAmount, uint256 auctioneerTokens, uint256 oldOwnerTokens);
    event AuctionRefund(address beneficiary, uint256 amount);

    struct Bidding {
        mapping (address => uint256) offers;
        mapping (address => uint256) offerIndex;
        uint256 nextOffer;
        mapping (uint256 => mapping (uint256 => address)) maxOfferor;
    }

    bool internal _notEntered; // re-entrancy check flag
    
    MEtherUserInterface public paymentToken;
    MtrollerUserInterface public mtroller;

    mapping (uint240 => Bidding) public biddings;

    // ETH account for each participant
    mapping (address => uint256) public refunds;

    constructor(MtrollerUserInterface _mtroller, MEtherUserInterface _mEtherPaymentToken) public
    {
        mtroller = _mtroller;
        paymentToken = _mEtherPaymentToken;
        _notEntered = true; // Start true prevents changing from zero to non-zero (smaller gas cost)
    }

    function addOfferETH(
        uint240 _mToken,
        address _bidder,
        address _oldOwner,
        uint256 _askingPrice
    )
        external
        nonReentrant
        payable
        returns (uint256)
    {
        require (msg.value > 0, "No payment sent");
        require(mtroller.auctionAllowed(_mToken, _bidder) == uint(Error.NO_ERROR), "Auction not allowed");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");
        uint256 _oldOffer = biddings[_mToken].offers[_bidder];
        uint256 _newOffer = _oldOffer + msg.value;

        /* if new offer is >= asking price of mToken, we do not enter the bid but sell directly */
        if (_newOffer >= _askingPrice && _askingPrice > 0) {
            if (_oldOffer > 0) {
                require(cancelOfferInternal(_mToken, _bidder) == _oldOffer, "Could not cancel offer");
            }
            ( , uint256 oldOwnerTokens) = processPaymentInternal(_oldOwner, _newOffer, _oldOwner, 0);
            emit HighestOfferAccepted(_mToken, _bidder, _newOffer, 0, oldOwnerTokens);
            return _newOffer;
        }
        /* otherwise the new bid is entered normally */
        else {
            if (_oldOffer == 0) {
                uint256 _nextIndex = biddings[_mToken].nextOffer;
                biddings[_mToken].offerIndex[_bidder] = _nextIndex;
                biddings[_mToken].nextOffer = _nextIndex + 1;
            }
            _updateOffer(_mToken, biddings[_mToken].offerIndex[_bidder], _bidder, _newOffer);
            emit NewAuctionOffer(_mToken, _bidder, _newOffer);
            return 0;
        }
    }

    function cancelOffer(
        uint240 _mToken
    )
        public
        nonReentrant
    {
        // // for later version: if sender is the highest bidder try to start grace period 
        // // and do not allow to cancel bid during grace period (+ 2 times preferred liquidator delay)
        // if (msg.sender == getMaxOfferor(_mToken)) {
        //     ( , , address _mTokenAddress) = mtroller.parseToken(_mToken);
        //     MERC721Interface(_mTokenAddress).startGracePeriod(_mToken);
        // }
        uint256 _oldOffer = cancelOfferInternal(_mToken, msg.sender);
        refunds[msg.sender] += _oldOffer;
        emit AuctionOfferCancelled(_mToken, msg.sender, _oldOffer);
    }
    
    function acceptHighestOffer(
        uint240 _mToken,
        address _oldOwner,
        address _auctioneer,
        uint256 _auctioneerFeeMantissa,
        uint256 _minimumPrice
    )
        external
        nonReentrant
        returns (address _maxOfferor, uint256 _maxOffer, uint256 auctioneerTokens, uint256 oldOwnerTokens)
    {
        require(mtroller.auctionAllowed(_mToken, _auctioneer) == uint(Error.NO_ERROR), "Auction not allowed");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");
        _maxOfferor = getMaxOfferor(_mToken); // reverts if no valid offer found
        _maxOffer = cancelOfferInternal(_mToken, _maxOfferor);
        require(_maxOffer >= _minimumPrice, "Best offer too low");

        /* process payment, reverts on error */
        (auctioneerTokens, oldOwnerTokens) = processPaymentInternal(_oldOwner, _maxOffer, _auctioneer, _auctioneerFeeMantissa);

        emit HighestOfferAccepted(_mToken, _maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
        
        return (_maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
    }

    function payOut(address beneficiary, uint256 amount) internal returns (uint256 mintedMTokens) {
        // try to accrue mEther interest first; if it fails, pay out full amount in mEther
        uint240 mToken = MTokenV1Storage(address(paymentToken)).thisFungibleMToken();
        uint err = paymentToken.accrueInterest(mToken);
        if (err != uint(Error.NO_ERROR)) {
            mintedMTokens = paymentToken.mintTo.value(amount)(beneficiary);
            return mintedMTokens;
        }

        // if beneficiary has outstanding borrows, repay as much as possible (revert on error)
        uint256 borrowBalance = paymentToken.borrowBalanceStored(beneficiary, mToken);
        if (borrowBalance > amount) {
            borrowBalance = amount;
        }
        if (borrowBalance > 0) {
            require(paymentToken.repayBorrowBehalf.value(borrowBalance)(beneficiary) == borrowBalance, "Borrow repayment failed");
        }

        // payout any surplus: in cash (ETH) if beneficiary has no shortfall; otherwise in mEther
        if (amount > borrowBalance) {
            uint256 shortfall;
            (err, , shortfall) = MtrollerInterface(MTokenV1Storage(address(paymentToken)).mtroller()).getAccountLiquidity(beneficiary);
            if (err == uint(Error.NO_ERROR) && shortfall == 0) {
                (bool success, ) = beneficiary.call.value(amount - borrowBalance)("");
                require(success, "ETH Transfer failed");
                mintedMTokens = 0;
            }
            else {
                mintedMTokens = paymentToken.mintTo.value(amount - borrowBalance)(beneficiary);
            }
        }
    }

    function processPaymentInternal(
        address _oldOwner,
        uint256 _price,
        address _broker,
        uint256 _brokerFeeMantissa
    )
        internal
        returns (uint256 brokerTokens, uint256 oldOwnerTokens) 
    {
        require(_oldOwner != address(0), "Invalid owner address");
        require(_price > 0, "Invalid price");
        
        /* calculate fees for protocol and add it to protocol's reserves (in underlying cash) */
        uint256 _amountLeft = _price;
        Exp memory _feeShare = Exp({mantissa: paymentToken.getProtocolAuctionFeeMantissa()});
        (MathError _mathErr, uint256 _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
        if (_fee > 0) {
            (_mathErr, _amountLeft) = subUInt(_price, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
            paymentToken._addReserves.value(_fee)();
        }

        /* calculate and pay broker's fee (if any) by minting corresponding paymentToken amount */
        _feeShare = Exp({mantissa: _brokerFeeMantissa});
        (_mathErr, _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
        if (_fee > 0) {
            require(_broker != address(0), "Invalid broker address");
            (_mathErr, _amountLeft) = subUInt(_amountLeft, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
            brokerTokens = payOut(_broker, _fee);
        }

        /* 
         * Pay anything left to the old owner by minting a corresponding paymentToken amount. In case 
         * of liquidation these paymentTokens can be liquidated in a next step. 
         * NEVER pay underlying cash to the old owner here!!
         */
        if (_amountLeft > 0) {
            oldOwnerTokens = payOut(_oldOwner, _amountLeft);
        }
    }
    
    function cancelOfferInternal(
        uint240 _mToken,
        address _offeror
    )
        internal
        returns (uint256 _oldOffer)
    {
        _oldOffer = biddings[_mToken].offers[_offeror];
        require (_oldOffer > 0, "No active offer found");
        uint256 _thisIndex = biddings[_mToken].offerIndex[_offeror];
        uint256 _nextIndex = biddings[_mToken].nextOffer;
        assert (_nextIndex > 0);
        _nextIndex--;
        if (_thisIndex != _nextIndex) {
            address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
            biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
            uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
            _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
        }
        _updateOffer(_mToken, _nextIndex, address(0), 0);
        delete biddings[_mToken].offers[_offeror];
        delete biddings[_mToken].offerIndex[_offeror];
        biddings[_mToken].nextOffer = _nextIndex;
        return _oldOffer;
    }
    
    /**
        @notice Withdraws any funds the contract has collected for the msg.sender from refunds
                and proceeds of sales or auctions.
    */
    function withdrawAuctionRefund() 
        public
        nonReentrant 
    {
        require(refunds[msg.sender] > 0, "No outstanding refunds found");
        uint256 _refundAmount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        msg.sender.transfer(_refundAmount);
        emit AuctionRefund(msg.sender, _refundAmount);
    }

    /**
        @notice Convenience function to cancel and withdraw in one call
    */
    function cancelOfferAndWithdrawRefund(
        uint240 _mToken
    )
        external
    {
        cancelOffer(_mToken);
        withdrawAuctionRefund();
    }

    uint256 constant private clusterSize = (2**4);

    function _updateOffer(
        uint240 _mToken,
        uint256 _offerIndex,
        address _newOfferor,
        uint256 _newOffer
    )
        internal
    {
        assert (biddings[_mToken].nextOffer > 0);
        assert (biddings[_mToken].offers[address(0)] == 0);
        uint256 _n = 0;
        address _origOfferor = _newOfferor;
        uint256 _origOffer = biddings[_mToken].offers[_newOfferor];
        if (_newOffer != _origOffer) {
            biddings[_mToken].offers[_newOfferor] = _newOffer;
        }
        
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {

            uint256 _oldOffer;
            address _oldOfferor = biddings[_mToken].maxOfferor[_n][_offerIndex];
            if (_oldOfferor != _newOfferor) {
                biddings[_mToken].maxOfferor[_n][_offerIndex] = _newOfferor;
            }

            _offerIndex = _offerIndex / clusterSize;
            address _maxOfferor = biddings[_mToken].maxOfferor[_n + 1][_offerIndex];
            if (tmp < clusterSize) {
                if (_maxOfferor != address(0)) {
                    biddings[_mToken].maxOfferor[_n + 1][_offerIndex] = address(0);
                }
                return;
            }
            
            if (_maxOfferor != address(0)) {
                if (_oldOfferor == _origOfferor) {
                    _oldOffer = _origOffer;
                }
                else {
                    _oldOffer = biddings[_mToken].offers[_oldOfferor];
                }
                
                if ((_oldOfferor != _maxOfferor) && (_newOffer <= _oldOffer)) {
                    return;
                }
                if ((_oldOfferor == _maxOfferor) && (_newOffer > _oldOffer)) {
                    _n++;
                    continue;
                }
            }
            uint256 _i = _offerIndex * clusterSize;
            _newOfferor = biddings[_mToken].maxOfferor[_n][_i];
            _newOffer = biddings[_mToken].offers[_newOfferor];
            _i++;
            while ((_i % clusterSize) != 0) {
                address _tmpOfferor = biddings[_mToken].maxOfferor[_n][_i];
                if (biddings[_mToken].offers[_tmpOfferor] > _newOffer) {
                    _newOfferor = _tmpOfferor;
                    _newOffer = biddings[_mToken].offers[_tmpOfferor];
                }
                _i++;
            } 
            _n++;
        }
    }

    function getMaxOffer(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        if (biddings[_mToken].nextOffer == 0) {
            return 0;
        }
        return biddings[_mToken].offers[getMaxOfferor(_mToken)];
    }

    function getMaxOfferor(
        uint240 _mToken
    )
        public
        view
        returns (address)
    {
        uint256 _n = 0;
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {
            _n++;
        }
        require (_n > 0, "No valid offer found");
        _n--;
        return biddings[_mToken].maxOfferor[_n][0];
    }

    function getMaxOfferor(
        uint240 _mToken, 
        uint256 _level, 
        uint256 _offset
    )
        public
        view
        returns (address[10] memory _offerors)
    {
        for (uint256 _i = 0; _i < 10; _i++) {
            _offerors[_i] = biddings[_mToken].maxOfferor[_level][_offset + _i];
        }
        return _offerors;
    }

    function getOffer(
        uint240 _mToken,
        address _account
    )
        public
        view
        returns (uint256)
    {
        return biddings[_mToken].offers[_account];
    }

    function getOfferIndex(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        require (biddings[_mToken].offers[msg.sender] > 0, "No active offer");
        return biddings[_mToken].offerIndex[msg.sender];
    }

    function getCurrentOfferCount(
        uint240 _mToken
    )
        external
        view
        returns (uint256)
    {
        return(biddings[_mToken].nextOffer);
    }

    function getOfferAtIndex(
        uint240 _mToken,
        uint256 _offerIndex
    )
        external
        view
        returns (address offeror, uint256 offer)
    {
        require(biddings[_mToken].nextOffer > 0, "No valid offer");
        require(_offerIndex < biddings[_mToken].nextOffer, "Offer index out of range");
        offeror = biddings[_mToken].maxOfferor[0][_offerIndex];
        offer = biddings[_mToken].offers[offeror];
    }

    /**
     * @dev Block reentrancy (directly or indirectly)
     */
    modifier nonReentrant() {
        require(_notEntered, "Reentrance not allowed");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }


// ************************************************************
//  Test functions only below this point, remove in production!

    // function addOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender,
    //     uint256 _amount
    // )
    //     public
    //     nonReentrant
    // {
    //     require (_amount > 0, "No payment sent");
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     uint256 _newOffer = _oldOffer + _amount;
    //     if (_oldOffer == 0) {
    //         uint256 _nextIndex = biddings[_mToken].nextOffer;
    //         biddings[_mToken].offerIndex[_sender] = _nextIndex;
    //         biddings[_mToken].nextOffer = _nextIndex + 1;
    //     }
    //     _updateOffer(_mToken, biddings[_mToken].offerIndex[_sender], _sender, _newOffer);
    //     emit NewAuctionOffer(_mToken, _sender, _newOffer);
    // }

    // function cancelOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender
    // )
    //     public
    //     nonReentrant
    // {
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     require (_oldOffer > 0, "No active offer found");
    //     uint256 _thisIndex = biddings[_mToken].offerIndex[_sender];
    //     uint256 _nextIndex = biddings[_mToken].nextOffer;
    //     assert (_nextIndex > 0);
    //     _nextIndex--;
    //     if (_thisIndex != _nextIndex) {
    //         address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
    //         biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
    //         uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
    //         _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
    //     }
    //     _updateOffer(_mToken, _nextIndex, address(0), 0);
    //     delete biddings[_mToken].offers[_sender];
    //     delete biddings[_mToken].offerIndex[_sender];
    //     biddings[_mToken].nextOffer = _nextIndex;
    //     refunds[_sender] += _oldOffer;
    //     emit AuctionOfferCancelled(_mToken, _sender, _oldOffer);
    // }

    // function testBidding(
    //     uint256 _start,
    //     uint256 _cnt
    // )
    //     public
    // {
    //     for (uint256 _i = _start; _i < (_start + _cnt); _i++) {
    //         addOfferETH_Test(1, address(uint160(_i)), _i);
    //     }
    // }

}

pragma solidity ^0.5.16;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.5.16;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.5.16;

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
        return add_(truncate(product), addend);
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
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.5.16;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../math/ZSafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using ZSafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library ZSafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/ZSafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using ZSafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/ZSafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using ZSafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}