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

import "./MTokenAdmin.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC721/IERC721Receiver.sol";
import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/introspection/ERC165.sol";

/**
 * @title ERC-721 Token Contract
 * @notice Base for mNFTs
 * @author mmo.finance
 */
contract MERC721TokenAdmin is MTokenAdmin, ERC721("MERC721","MERC721"), MERC721AdminInterface {

    /**
     * @notice Constructs a new MERC721TokenAdmin
     */
    constructor() public MTokenAdmin() {
        implementedSelectors.push(bytes4(keccak256('initialize(address,address,address,address,string,string)')));
        implementedSelectors.push(bytes4(keccak256('redeemAndSell(uint240,uint256,address,bytes)')));
        implementedSelectors.push(bytes4(keccak256('redeem(uint240)')));
        implementedSelectors.push(bytes4(keccak256('redeemUnderlying(uint256)')));
        implementedSelectors.push(bytes4(keccak256('borrow(uint256)')));
        implementedSelectors.push(bytes4(keccak256('name()')));
        implementedSelectors.push(bytes4(keccak256('symbol()')));
        implementedSelectors.push(bytes4(keccak256('tokenURI(uint256)')));
    }

    /**
     * Marker function identifying this contract as "ERC721_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.ERC721_MTOKEN;
    }

    /**
     * @notice Initialize a new ERC-721 MToken money market
     * @dev Since each non-fungible ERC-721 is unique and thus cannot have "reserves" in the conventional sense, we have to set
     * reserveFactorMantissa_ = 0 in the mToken initialisation. Similarly, we have to set protocolSeizeShareMantissa_ = 0 since
     * seizing a NFT asset can only be done in one piece and it cannot be split up to be transferred partly to the protocol.
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param tokenAuction_ The address of the TokenAuction contract
     * @param name_ EIP-721 name of this MToken
     * @param symbol_ EIP-721 symbol of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                TokenAuction tokenAuction_,
                string memory name_,
                string memory symbol_) public {
        MTokenAdmin.initialize(underlyingContract_, mtroller_, interestRateModel_, 0, mantissaOne, 0, name_, symbol_, 18);
        // _registerInterface(this.onERC721Received.selector);
        uint err = _setTokenAuction(tokenAuction_);
        require(err == uint(Error.NO_ERROR), "setting tokenAuction failed");
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * Redeem is only possible if after redeeming the owner still has positive overall liquidity (no shortfall),
     * unless the redeem is immediately followed by a sale in the same transaction (when transferHandler != address(0)) and
     * the received sale price is sufficient to cover any such shortfall.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem into underlying
     * @param sellPrice In case of redeem followed directly by a sale to another user, this is the (minimum) price to collect from the buyer
     * @param transferHandler If this is nonzero, the redeem is directly followed by a sale, the details of which are handled by a contract at this address (see Mortgage.sol)
     * @param transferParams Call parameters for the transferHandler call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemAndSell(uint240 mToken, uint sellPrice, address payable transferHandler, bytes memory transferParams) public nonReentrant returns (uint) {
        /* Fail if sender not owner */
        if (msg.sender != ownerOf(mToken)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REDEEM_NOT_OWNER);
        }

        /* Sanity check, this should never revert */
        require(accountTokens[mToken][msg.sender] == oneUnit, "Invalid internal token amount");

        /* Reset the asking price to zero (= "not set") */
        if (askingPrice[mToken] > 0) {
            askingPrice[mToken] = 0;
        }

        /* Redeem / burn the mToken */
        uint err = redeemInternal(mToken, oneUnit, 0, msg.sender, sellPrice, transferHandler, transferParams);
        if (err != uint(Error.NO_ERROR)) {
            return err;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* Revert if market cannot be exited */
        err = mtroller.exitMarketOnBehalf(mToken, msg.sender);
        requireNoError(err, "redeem market exit failed");

        /* Burn the ERC-721 specific parts of the mToken */
        _burn(mToken);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint240 mToken) public returns (uint) {
        return redeemAndSell(mToken, 0, address(0), "");
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param underlyingID The ID of the underlying nft to be redeemed
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 underlyingID) external returns (uint) {
        return redeem(mTokenFromUnderlying[underlyingID]);
    }

    /**
      * @notice Sender enters mToken market and borrows NFT assets from the protocol to their own address.
      * @param borrowUnderlyingID The ID of the underlying NFT asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint256 borrowUnderlyingID) external returns (uint) {
        borrowUnderlyingID;
        /* No NFT borrowing for now */
        return fail(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION);
    }

    /**
      * @notice Returns the name of the mToken (contract). For now this is simply the name of the underlying.
      * @return string The name of the mToken.
      */
    function name() external view returns (string memory) {
        return IERC721Metadata(underlyingContract).name();
    }

    /**
      * @notice Returns the symbol of the mToken (contract). For now this is simply the symbol of the underlying.
      * @return string The symbol of the mToken.
      */
    function symbol() external view returns (string memory) {
        return IERC721Metadata(underlyingContract).symbol();
    }

    /**
      * @notice Returns an URI for the given mToken. For now this is simply the URI of the underlying NFT.
      * @param tokenId The mToken whose URI to get.
      * @return string The URI of the mToken.
      */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        require(tokenId <= uint240(-1), "URI query for nonexistent token");
        uint240 mToken = uint240(tokenId);
        return IERC721Metadata(underlyingContract).tokenURI(underlyingIDs[mToken]);
    }


   /*** Safe Token ***/

    /**
     * @notice Transfers an underlying NFT asset out of this contract
     * @dev Performs a transfer out, reverting upon failure.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     * @param to The address where to transfer underlying assets to
     * @param underlyingID The ID of the underlying asset
     * @param amount The amount of underlying to transfer, must be == oneUnit here
     */
    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        /** 
         * For now, amounts transferred out must always be oneUnit. Later, with NFT borrowing enabled
         * amount could be larger than oneUnit and the difference would be the lender's and protocol's
         * profit and should be distributed here. 
         */
        require(amount == oneUnit, "Amount must be oneUnit");
        if (transferHandler == address(0)) {
            // transfer without subsequent sale to a third party
            IERC721(underlyingContract).safeTransferFrom(address(this), to, underlyingID);
            require(IERC721(underlyingContract).ownerOf(underlyingID) == to, "Transfer out failed");
        }
        else {
            // transfer followed by sale to a third party (handled by transferHandler)
            // transfer underlying to transferHandler first (reduced risk, grant access rights only from transferHandler)
            IERC721(underlyingContract).safeTransferFrom(address(this), transferHandler, underlyingID);
            MEtherUserInterface mEther = tokenAuction.paymentToken();
            uint240 mEtherToken = MTokenCommon(address(mEther)).thisFungibleMToken();
            uint oldBalance = to.balance;
            uint oldBorrowBalance = mEther.borrowBalanceCurrent(to, mEtherToken);
            uint error = FlashLoanReceiverInterface(transferHandler).executeTransfer(underlyingID, to, sellPrice, transferParams);
            require(error == uint(Error.NO_ERROR), "Transfer operation failed");
            uint cashReceived = to.balance;
            require(cashReceived >= oldBalance, "Negative received payment");
            cashReceived = cashReceived - oldBalance;
            uint borrowReduced = mEther.borrowBalanceStored(to, mEtherToken);
            require(oldBorrowBalance >= borrowReduced, "Borrow increased");
            borrowReduced = oldBorrowBalance - borrowReduced;
            require((cashReceived + borrowReduced) >= sellPrice, "Received payment too low");
        }
        return amount;
    }

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint) {
        /** 
         * For now, amounts transferred must always be oneUnit. Later, with NFT borrowing enabled
         * amount could be larger than oneUnit.
         */
        require(amount == oneUnit, "Amount must be oneUnit");
        IERC721(underlyingContract).safeTransferFrom(msg.sender, to, underlyingID);
        require(IERC721(underlyingContract).ownerOf(underlyingID) == to, "Transfer out failed");
        return amount;
    }
}

contract MERC721InterfaceFull is MERC721TokenAdmin, MERC721Interface {}

pragma solidity ^0.5.16;

import "./MFungibleTokenAdmin.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";

/**
 * @title Contract for fungible tokens
 * @notice Abstract base for fungible MTokens
 * @author mmo.finance, based on Compound
 */
contract MEtherAdmin is MFungibleTokenAdmin, MEtherAdminInterface {

    /**
     * @notice Constructs a new MEtherAdmin
     */
    constructor() public MFungibleTokenAdmin() {
        implementedSelectors.push(bytes4(keccak256('isMEtherAdminImplementation()')));
        implementedSelectors.push(bytes4(keccak256('initialize(address,address,uint256,uint256,uint256,string,string,uint8)')));
        implementedSelectors.push(bytes4(keccak256('redeem(uint256)')));
        implementedSelectors.push(bytes4(keccak256('redeemUnderlying(uint256)')));
        implementedSelectors.push(bytes4(keccak256('borrow(uint256)')));
        implementedSelectors.push(bytes4(keccak256('flashBorrow(uint256,address,bytes)')));
        implementedSelectors.push(bytes4(keccak256('name()')));
        implementedSelectors.push(bytes4(keccak256('symbol()')));
        implementedSelectors.push(bytes4(keccak256('decimals()')));
    }

    /**
     * @notice Initialize a new MEther money market
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public {
        MFungibleTokenAdmin.initialize(mtroller_.underlyingContractETH(), mtroller_, interestRateModel_, 
                    reserveFactorMantissa_, initialExchangeRateMantissa_, protocolSeizeShareMantissa_, 
                    name_, symbol_, decimals_);
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset (ETH)
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external nonReentrant returns (uint) {
        return redeemInternal(thisFungibleMToken, redeemTokens, 0, msg.sender, 0, address(0), "");
    }

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset (ETH)
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external nonReentrant returns (uint) {
        return redeemInternal(thisFungibleMToken, 0, redeemAmount, msg.sender, 0, address(0), "");
    }

    /**
      * @notice Sender enters MEther market and borrows assets from the protocol to their own address.
      * @param borrowAmount The amount of the underlying asset (ETH) to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external returns (uint) {
        uint err = mtroller.enterMarketOnBehalf(thisFungibleMToken, msg.sender);
        requireNoError(err, "enter market failed");
        return borrowInternal(thisFungibleMToken, borrowAmount);
    }

    /**
     * @notice Sender borrows ETH from the protocol to a receiver address in spite of having 
     * insufficient collateral, but repays borrow or adds collateral to correct balance in the same block
     * Any ETH the sender sends with this payable function are considered a down payment and are
     * also transferred to the receiver address
     * @param borrowAmount The amount of the underlying asset (Wei) to borrow
     * @param receiver The address receiving the borrowed funds. This address must be able to receive
     * the corresponding underlying of mToken and it must implement FlashLoanReceiverInterface.
     * @param flashParams Any other data necessary for flash loan repayment
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function flashBorrow(uint borrowAmount, address payable receiver, bytes calldata flashParams) external payable returns (uint) {
        uint err = mtroller.enterMarketOnBehalf(thisFungibleMToken, msg.sender);
        requireNoError(err, "enter market failed");
        return flashBorrowInternal(thisFungibleMToken, msg.value, borrowAmount, receiver, flashParams);
    }

    function name() public view returns (string memory) {
        return mName;
    }

    function symbol() public view returns (string memory) {
        return mSymbol;
    }

    function decimals() public view returns (uint8) {
        return mDecimals;
    }

    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        // Sanity checks
        require(underlyingIDs[thisFungibleMToken] == underlyingID, "underlying tokenID mismatch");
        /* Send the Ether, with minimal gas and revert on failure */
        if (transferHandler == address(0)) {
            // transfer without subsequent sale to a third party
            to.transfer(amount);
        }
        else {
            // transfer followed by sale to a third party (handled by transferHandler)
            sellPrice;
            transferParams;
            revert("not implemented");
        }
        return amount;
    }

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint) {
        require(underlyingIDs[thisFungibleMToken] == underlyingID, "underlying tokenID mismatch");
        require(msg.value == amount, "value mismatch");
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
        return amount;
    }
}

contract MEtherInterfaceFull is MEtherAdmin, MEtherInterface {}

pragma solidity ^0.5.16;

import "./MTokenAdmin.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";

/**
 * @title Contract for fungible tokens
 * @notice Abstract base for fungible MTokens
 * @author mmo.finance, based on Compound
 */
contract MFungibleTokenAdmin is MTokenAdmin, MFungibleTokenAdminInterface {

    /**
     * @notice Constructs a new MFungibleTokenAdmin
     */
    constructor() public MTokenAdmin() {
    }

    /**
     * Marker function identifying this contract as "FUNGIBLE_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.FUNGIBLE_MTOKEN;
    }

    /**
     * @notice Initialize a new fungible MToken money market
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) internal {
        MTokenAdmin.initialize(underlyingContract_, mtroller_, interestRateModel_, reserveFactorMantissa_,
            initialExchangeRateMantissa_, protocolSeizeShareMantissa_, name_, symbol_, decimals_);
        thisFungibleMToken = mtroller_.assembleToken(getTokenType(), uint72(dummyTokenID), address(this));
    }
}

contract MFungibleTokenInterfaceFull is MFungibleTokenAdmin, MFungibleTokenInterface {}

pragma solidity ^0.5.16;

import "./MTokenCommon.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

/**
 * @title Contract for MToken
 * @notice Abstract base for any type of MToken ("admin" part)
 * @author mmo.finance, initially based on Compound
 */
contract MTokenAdmin is MTokenCommon, MTokenAdminInterface {

    /**
     * @notice Constructs a new MTokenAdmin
     */
    constructor() public MTokenCommon() {
        implementedSelectors.push(bytes4(keccak256('isMDelegatorAdminImplementation()')));
        implementedSelectors.push(bytes4(keccak256('_setFlashReceiverWhiteList(address,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setInterestRateModel(address)')));
        implementedSelectors.push(bytes4(keccak256('_setTokenAuction(address)')));
        implementedSelectors.push(bytes4(keccak256('_setMtroller(address)')));
        implementedSelectors.push(bytes4(keccak256('_setGlobalProtocolParameters(uint256,uint256,uint256,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_setGlobalAuctionParameters(uint256,uint256,uint256,uint256,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_reduceReserves(uint240,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_sweepERC20(address)')));
        implementedSelectors.push(bytes4(keccak256('_sweepERC721(address,uint256)')));
    }

    /**
     * @notice Returns the type of implementation for this contract
     */
    function isMDelegatorAdminImplementation() public pure returns (bool) {
        return true;
    }

    /*** Admin functions ***/

    /**
     * @notice Initializes a new MToken money market
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) internal {

        require(msg.sender == getAdmin(), "only admin can initialize token contract");

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        _notEntered2 = true;

        // Allow initialization only once
        require(underlyingContract == address(0), "already initialized");

        // Set the underlying contract address
        underlyingContract = underlyingContract_;

        // Set the interest rate model
        uint err = _setInterestRateModel(interestRateModel_);
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        // Set the mtroller
        err = _setMtroller(mtroller_);
        require(err == uint(Error.NO_ERROR), "setting mtroller failed");

        // Set initial exchange rate, the reserve factor, the protocol seize share, and the one-time borrow fee
        err = _setGlobalProtocolParameters(initialExchangeRateMantissa_, reserveFactorMantissa_, protocolSeizeShareMantissa_, 0.8e16);
        require(err == uint(Error.NO_ERROR), "setting global protocol parameters failed");

        // Set global auction parameters
        err = _setGlobalAuctionParameters(auctionMinGracePeriod, 500, 0, 5e16, 0);
        require(err == uint(Error.NO_ERROR), "setting global auction parameters failed");

        // Set the mToken name and symbol
        mName = name_;
        mSymbol = symbol_;
        mDecimals = decimals_;

        // Initialize the market for the anchor token
        uint240 tokenAnchor = mtroller.getAnchorToken(address(this));
        require(accrualBlockNumber[tokenAnchor] == 0 && borrowIndex[tokenAnchor] == 0, "market may only be initialized once");
        accrualBlockNumber[tokenAnchor] = getBlockNumber();
        borrowIndex[tokenAnchor] = mantissaOne;

        // Accrue interest to execute changes
        err = accrueInterest(tokenAnchor);
        require(err == uint(Error.NO_ERROR), "accrue interest failed");
    }


    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint totalCashNew;
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem
     * @param redeemTokensIn The number of mTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming mTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param beneficiary The account that will get the redeemed underlying asset
     * @param sellPrice In case of redeem followed directly by a sale to another user, this is the (minimum) price to collect from the buyer
     * @param transferHandler If this is nonzero, the redeem is directly followed by a sale, the details of which are handled by a contract at this address (see Mortgage.sol)
     * @param transferParams Call parameters for the transferHandler call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemInternal(uint240 mToken, uint redeemTokensIn, uint redeemAmountIn, address payable beneficiary, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        address payable redeemer = msg.sender;
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        uint err = accrueInterest(mToken);
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(err), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }

        RedeemLocalVars memory vars;

        /* exchangeRate = invoke Exchange Rate Stored() */
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal(mToken);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
        }

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
            }
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */

            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
            }

            vars.redeemAmount = redeemAmountIn;
        }

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply[mToken], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[mToken][redeemer], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        (vars.mathErr, vars.totalCashNew) = subUInt(totalCashUnderlying[mToken], vars.redeemAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        // check transferHandler is whitelisted (if used)
        if (transferHandler != address(0)) {
            require(flashReceiverIsWhitelisted[transferHandler] || flashReceiverIsWhitelisted[address(0)], "flash receiver not whitelisted");
        }
        doTransferOut(beneficiary, underlyingID, vars.redeemAmount, sellPrice, transferHandler, transferParams);

        /* We write previously calculated values into storage */
        totalSupply[mToken] = vars.totalSupplyNew;
        accountTokens[mToken][redeemer] = vars.accountTokensNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), mToken, vars.redeemTokens);
        emit Redeem(redeemer, mToken, vars.redeemTokens, underlyingID, vars.redeemAmount);

        /* Revert whole transaction if redeem not allowed (i.e., user has any shortfall at the end). 
         * We do this at the end to allow for redeems that include a sales transaction which can balance
         * user's liquidity 
         */
        err = mtroller.redeemAllowed(mToken, redeemer, 0);
        requireNoError(err, "redeem failed");

        /* We call the defense hook */
        mtroller.redeemVerify(mToken, redeemer, vars.redeemAmount, vars.redeemTokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param mToken The mToken whose underlying to borrow
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrowInternal(uint240 mToken, uint borrowAmount) internal returns (uint) {
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        (uint err, ) = borrowPrivate(msg.sender, mToken, borrowAmount, address(0));
        return err;
    }

    /**
     * @notice Sender borrows assets from the protocol to a receiver address in spite of having 
     * insufficient collateral, but repays borrow or adds collateral to correct balance in the same block
     * @param mToken The mToken whose underlying to borrow
     * @param downPaymentAmount Additional funds transferred from sender to receiver (down payment)
     * @param borrowAmount The amount of the underlying asset to borrow
     * @param receiver The address receiving the borrowed funds. This address must be able to receive
     * the corresponding underlying of mToken and it must implement FlashLoanReceiverInterface. Any
     * such receiver address must be whitelisted before by admin, unless admin has enables all addresses
     * by whitelisting address(0).
     * @param flashParams Any other data necessary for flash loan repayment
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function flashBorrowInternal(uint240 mToken, uint downPaymentAmount, uint borrowAmount, address payable receiver, bytes memory flashParams) internal nonReentrant2 returns (uint) {
        // check receiver is not null, and is whitelisted
        require(receiver != address(0), "invalid flash loan receiver");
        require(flashReceiverIsWhitelisted[receiver] || flashReceiverIsWhitelisted[address(0)], "flash receiver not whitelisted");

        // Revert if flash borrowing fails (need to revert because of side-effects such as down payment)
        uint error;
        uint paidOutAmount;
        if (borrowAmount > 0) {
            (error, paidOutAmount) = borrowPrivate(msg.sender, mToken, borrowAmount, receiver);
            require(error == uint(Error.NO_ERROR), "flash borrow not allowed"); 
        }

        /* Get down payment (if any) from the sender and also transfer it to the receiver. 
         * Reverts if anything goes wrong.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        if (downPaymentAmount > 0) {
            MathError mathErr;
            uint downPaymentPaid = doTransferOutFromSender(receiver, underlyingID, downPaymentAmount);
            (mathErr, paidOutAmount) = addUInt(paidOutAmount, downPaymentPaid);
            require(mathErr == MathError.NO_ERROR, "down payment calculation failed");
        }

        /* Call user-defined code that eventually repays borrow or increases collaterals sufficiently */
        error = FlashLoanReceiverInterface(receiver).executeFlashOperation(msg.sender, mToken, borrowAmount, paidOutAmount, flashParams);
        require(error == uint(Error.NO_ERROR), "execute flash operation failed");

        /* Revert whole transaction if sender (=borrower) has any shortfall remaining at the end */
        error = mtroller.borrowAllowed(mToken, msg.sender, 0);
        require(error == 0, "flash loan failed");

        emit FlashBorrow(msg.sender, underlyingID, receiver, downPaymentAmount, borrowAmount, paidOutAmount);

        return uint(Error.NO_ERROR);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint totalCashNew;
        uint protocolFee;
        uint amountPaidOut;
        uint amountBorrowerReceived;
        uint totalReservesNew;
    }

    /**
     * @notice Borrows assets from the protocol to a certain address
     * @param borrower The address that borrows and receives assets
     * @param mToken The mToken whose underlying to borrow
     * @param borrowAmount The amount of the underlying asset to borrow
     * @param receiver The address receiving the borrowed funds in case of a flash loan, otherwise 0
     * @return (possible error code 0=success, otherwise a failure (see ErrorReporter.sol for details),
     *          amount actually received by borrower (borrowAmount - protocol fees - token transfer fees))
     */
    function borrowPrivate(address payable borrower, uint240 mToken, uint borrowAmount, address payable receiver) private nonReentrant returns (uint, uint) {
        /* Accrue interest */
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED), 0);
        }

        /* Fail if borrow not allowed (flash: fail if already has shortfall before borrowing anything) */
        if (receiver != address(0)) {
            error = mtroller.borrowAllowed(mToken, borrower, 0);
        }
        else {
            error = mtroller.borrowAllowed(mToken, borrower, borrowAmount);
        }
        if (error != 0) {
            return (failOpaque(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION, error), 0);
        }

        // /* Verify market's block number equals current block number */
        // if (accrualBlockNumber[mToken] != getBlockNumber()) {
        //     return (fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK), 0);
        // }

        BorrowLocalVars memory vars;

        /* Fail gracefully if protocol has insufficient underlying cash */
        (vars.mathErr, vars.totalCashNew) = subUInt(totalCashUnderlying[mToken], borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE), 0);
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower, mToken);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows[mToken], borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /*
         * We calculate the one-time platform fee (if any) on new borrows:
         *  protocolFee = borrowFeeMantissa * borrowAmount
         *  amountPaidOut = borrowAmount - protocolFee
         */

        (vars.mathErr, vars.protocolFee) = mulScalarTruncate(Exp({mantissa: borrowFeeMantissa}), borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.amountPaidOut) = subUInt(borrowAmount, vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* Add protocolFee to totalReserves and totalCash, revert on overflow */
        (vars.mathErr, vars.totalReservesNew) = addUInt(totalReserves[mToken], vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.totalCashNew) = addUInt(vars.totalCashNew, vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the effective amountPaidOut.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has amountPaidOut less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        if (receiver != address(0)) {
            vars.amountBorrowerReceived = doTransferOut(receiver, underlyingID, vars.amountPaidOut, 0, address(0), "");
        }
        else {
            vars.amountBorrowerReceived = doTransferOut(borrower, underlyingID, vars.amountPaidOut, 0, address(0), "");
        }

        /* We write the previously calculated values into storage */
        accountBorrows[mToken][borrower].principal = vars.accountBorrowsNew;
        accountBorrows[mToken][borrower].interestIndex = borrowIndex[mToken];
        totalBorrows[mToken] = vars.totalBorrowsNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        if (vars.protocolFee != 0) {
            totalReserves[mToken] = vars.totalReservesNew;
            emit ReservesAdded(address(this), mToken, vars.protocolFee, vars.totalReservesNew);
        }

        /* We emit a Borrow event */
        emit Borrow(borrower, underlyingID, borrowAmount, vars.amountBorrowerReceived, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        // unused function
        // mtroller.borrowVerify(address(this), borrower, borrowAmount);

        return (uint(Error.NO_ERROR), vars.amountBorrowerReceived);
    }

    /*** Admin Functions ***/

    /**
     * @notice Manages the whitelist for flash loan receivers
     * @dev Admin function to manage whitelist entries for flash loan receivers
     * @param candidate the receiver address to take on/off the whitelist. putting the zero address
     * on the whitelist (candidate = 0, state = true) enables any address as flash loan receiver,
     * effectively disabling whitelisting
     * @param state true to put on whitelist, false to take off
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setFlashReceiverWhiteList(address candidate, bool state) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FLASH_WHITELIST_OWNER_CHECK);
        }

        // if state is modified, set new whitelist state and emit event
        if (flashReceiverIsWhitelisted[candidate] != state) {
            flashReceiverIsWhitelisted[candidate] = state;
            emit FlashReceiverWhitelistChanged(candidate, state);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice sets a new interest rate model
     * @dev Admin function to set a new interest rate model.
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
        }

        InterestRateModel oldInterestRateModel = interestRateModel;
        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set new interest rate model
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice sets a new token auction contract
     * @dev Admin function to set a new token auction contract.
     * @param newTokenAuction the new token auction contract to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setTokenAuction(TokenAuction newTokenAuction) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TOKEN_AUCTION_OWNER_CHECK);
        }

        TokenAuction oldTokenAuction = tokenAuction;

        // Set new interest rate model
        tokenAuction = newTokenAuction;

        // Emit NewTokenAuction(oldTokenAuction, newTokenAuction);
        emit NewTokenAuction(oldTokenAuction, newTokenAuction);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets a new mtroller for the market
      * @dev Admin function to set a new mtroller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMtroller(MtrollerInterface newMtroller) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MTROLLER_OWNER_CHECK);
        }

        MtrollerInterface oldMtroller = mtroller;
        // Ensure invoke mtroller.isMtroller() returns true
        require(MtrollerUserInterface(newMtroller).isMDelegatorUserImplementation(), "invalid mtroller");
        require(MtrollerAdminInterface(newMtroller).isMDelegatorAdminImplementation(), "invalid mtroller");

        // Set market's mtroller to newMtroller
        mtroller = newMtroller;

        // Emit NewMtroller(oldMtroller, newMtroller)
        emit NewMtroller(oldMtroller, newMtroller);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets new values for the modifiable global parameters of the protocol
      * @dev Admin function to set global parameters. Setting a value of a parameter to uint(-1) means to not
      * change the current value of that parameter.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setGlobalProtocolParameters(uint _initialExchangeRateMantissa, uint _reserveFactorMantissa, uint _protocolSeizeShareMantissa, uint _borrowFeeMantissa) public returns (uint) {

        require(msg.sender == getAdmin(), "only admin can set global protocol parameters");

        if (_initialExchangeRateMantissa != uint(-1) && _initialExchangeRateMantissa != initialExchangeRateMantissa) {
            if (_initialExchangeRateMantissa == 0) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            initialExchangeRateMantissa = _initialExchangeRateMantissa;
        }

        if (_reserveFactorMantissa != uint(-1) && _reserveFactorMantissa != reserveFactorMantissa) {
            if (_reserveFactorMantissa > reserveFactorMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            reserveFactorMantissa = _reserveFactorMantissa;
        }

        if (_protocolSeizeShareMantissa != uint(-1) && _protocolSeizeShareMantissa != protocolSeizeShareMantissa) {
            if (_protocolSeizeShareMantissa > protocolSeizeShareMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            protocolSeizeShareMantissa = _protocolSeizeShareMantissa;
        }

        if (_borrowFeeMantissa != uint(-1) && _borrowFeeMantissa != borrowFeeMantissa) {
            if (_borrowFeeMantissa > borrowFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            borrowFeeMantissa = _borrowFeeMantissa;
        }

        emit NewGlobalProtocolParameters(initialExchangeRateMantissa, reserveFactorMantissa, protocolSeizeShareMantissa, borrowFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    function _setGlobalAuctionParameters(
            uint _auctionGracePeriod,
            uint _preferredLiquidatorHeadstart,
            uint _minimumOfferMantissa,
            uint _liquidatorAuctionFeeMantissa,
            uint _protocolAuctionFeeMantissa
            ) public returns (uint) {

        require(msg.sender == getAdmin(), "only admin can set global auction parameters");

        if (_auctionGracePeriod != uint(-1) && _auctionGracePeriod != auctionGracePeriod) {
            if (_auctionGracePeriod < auctionMinGracePeriod || _auctionGracePeriod > auctionMaxGracePeriod) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            auctionGracePeriod = _auctionGracePeriod;
        }

        if (_preferredLiquidatorHeadstart != uint(-1) && _preferredLiquidatorHeadstart != preferredLiquidatorHeadstart) {
            if (_preferredLiquidatorHeadstart > preferredLiquidatorMaxHeadstart) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            preferredLiquidatorHeadstart = _preferredLiquidatorHeadstart;
        }

        if (_minimumOfferMantissa != uint(-1) && _minimumOfferMantissa != minimumOfferMantissa) {
            if (_minimumOfferMantissa > minimumOfferMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            minimumOfferMantissa = _minimumOfferMantissa;
        }

        if (_liquidatorAuctionFeeMantissa != uint(-1) && _liquidatorAuctionFeeMantissa != liquidatorAuctionFeeMantissa) {
            if (_liquidatorAuctionFeeMantissa > liquidatorAuctionFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            liquidatorAuctionFeeMantissa = _liquidatorAuctionFeeMantissa;
        }

        if (_protocolAuctionFeeMantissa != uint(-1) && _protocolAuctionFeeMantissa != protocolAuctionFeeMantissa) {
            if (_protocolAuctionFeeMantissa > protocolAuctionFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            } 
            protocolAuctionFeeMantissa = _protocolAuctionFeeMantissa;
        }

        emit NewGlobalAuctionParameters(auctionGracePeriod, preferredLiquidatorHeadstart, minimumOfferMantissa, liquidatorAuctionFeeMantissa, protocolAuctionFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves for mToken by transferring to admin
     * @param mToken The mToken whose reserves to reduce
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint240 mToken, uint reduceAmount) external nonReentrant returns (uint) {
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
        }
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(mToken, reduceAmount);
    }

    /**
     * @notice Reduces reserves for mToken by transferring to admin
     * @dev Requires fresh interest accrual
     * @param mToken The mToken whose reserves to reduce
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint240 mToken, uint reduceAmount) internal returns (uint) {
        MathError mathErr;
        uint totalReservesNew;
        uint totalCashNew;

        // Check caller is admin
        address payable admin = getAdmin();
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber[mToken] != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
        }

        /* Fail gracefully if protocol has insufficient reserves */
        (mathErr, totalReservesNew) = subUInt(totalReserves[mToken], reduceAmount);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        (mathErr, totalCashNew) = subUInt(totalCashUnderlying[mToken], reduceAmount);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for admin and the reduceAmount.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has reduceAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        doTransferOut(admin, underlyingID, reduceAmount, 0, address(0), "");

        /* We write the previously calculated values into storage */
        totalReserves[mToken] = totalReservesNew;
        totalCashUnderlying[mToken] = totalCashNew;

        emit ReservesReduced(admin, mToken, reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /*** Safe Token ***/

    /**
     * @notice Transfers underlying assets out of this contract
     * @dev Performs a transfer out, reverting upon failure.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred out (lower in case of a fee).
     */
    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint);

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint);

    /**
        @notice Admin may collect any ERC-20 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @param tokenContract The contract address of the "lost" token.
        @return (uint) Returns the amount of tokens successfully collected, otherwise reverts.
    */
    function _sweepERC20(address tokenContract) external nonReentrant returns (uint) {
        address admin = getAdmin();
        require(msg.sender == admin, "Only admin can do that");
        require(tokenContract != underlyingContract, "Cannot sweep underlying asset");
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "No leftover tokens found");
        IERC20(tokenContract).transfer(admin, amount);
        return amount;
    }

    /**
        @notice Admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param tokenContract The contract address of the "lost" token.
        @param tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address tokenContract, uint256 tokenID) external nonReentrant {
        address admin = getAdmin();
        require(msg.sender == admin, "Only admin can do that");
        if (tokenContract == underlyingContract) {
            // Only allow to sweep tokens that are not in use as supplied assets
            uint240 mToken = mTokenFromUnderlying[tokenID];
            if (mToken != 0) {
                require(IERC721(tokenContract).ownerOf(mToken) == address(0), "Cannot sweep regular asset");
            }
        }
        require(address(this) == IERC721(tokenContract).ownerOf(tokenID), "Token not owned by contract");
        IERC721(tokenContract).safeTransferFrom(address(this), admin, tokenID);
    }
}

contract MTokenInterfaceFull is MTokenAdmin, MTokenInterface {}

pragma solidity ^0.5.16;

import "./MTokenStorage.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

/**
 * @title Contract for MToken
 * @notice Abstract base for any type of MToken
 * @author mmo.finance, initially based on Compound
 */
contract MTokenCommon is MTokenV1Storage, MTokenCommonInterface, Exponential, TokenErrorReporter {

    /**
     * @notice Constructs a new MToken
     */
    constructor() public {
    }

    /**
     * @notice Tells the address of the current admin (set in MDelegator.sol)
     * @return admin The address of the current admin
     */
    function getAdmin() public view returns (address payable admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }

    struct AccrueInterestLocalVars {
        uint currentBlockNumber;
        uint accrualBlockNumberPrior;
        uint cashPrior;
        uint borrowsPrior;
        uint reservesPrior;
        uint borrowIndexPrior;
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @param mToken The mToken market to accrue interest for
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest(uint240 mToken) public returns (uint) {
        AccrueInterestLocalVars memory vars;

        /* Remember the initial block number */
        vars.currentBlockNumber = getBlockNumber();
        vars.accrualBlockNumberPrior = accrualBlockNumber[mToken];

        /* Short-circuit accumulating 0 interest */
        if (vars.accrualBlockNumberPrior == vars.currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        vars.cashPrior = totalCashUnderlying[mToken];
        vars.borrowsPrior = totalBorrows[mToken];
        vars.reservesPrior = totalReserves[mToken];
        vars.borrowIndexPrior = borrowIndex[mToken];

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(vars.cashPrior, vars.borrowsPrior, vars.reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(vars.currentBlockNumber, vars.accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, vars.borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, vars.borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, vars.reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, vars.borrowIndexPrior, vars.borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber[mToken] = vars.currentBlockNumber;
        borrowIndex[mToken] = borrowIndexNew;
        totalBorrows[mToken] = totalBorrowsNew;
        totalReserves[mToken] = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(mToken, vars.cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @param mToken The mToken whose exchange rate should be calculated
     * @return (error code, calculated exchange rate scaled by 1e18)
     */
    function exchangeRateStoredInternal(uint240 mToken) internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply[mToken];
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = totalCashUnderlying[mToken];
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows[mToken], totalReserves[mToken]);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @param mToken The borrowed mToken
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account, uint240 mToken) internal view returns (MathError, uint) {
        /* Note: we do not assert that the market is up to date */
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[mToken][account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex[mToken]);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }


    /*** Error handling ***/

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i+0] = byte(uint8(32));
        fullMessage[i+1] = byte(uint8(40));
        fullMessage[i+2] = byte(uint8(48 + ( errCode / 10 )));
        fullMessage[i+3] = byte(uint8(48 + ( errCode % 10 )));
        fullMessage[i+4] = byte(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly
     */
    modifier nonReentrant2() {
        require(_notEntered2, "re-entered");
        _notEntered2 = false;
        _;
        _notEntered2 = true; // get a gas-refund post-Istanbul
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
pragma experimental ABIEncoderV2;

import "./MTokenCommon.sol";
import "./MTokenInterfaces.sol";
import "./MEtherAdmin.sol";
import "./MERC721TokenAdmin.sol";
import "./ErrorReporter.sol";

contract WETHInterface is IERC20 {
    function withdraw(uint wad) public;
}

contract MortgageERC721UsingETH is FlashLoanReceiverInterface, TokenErrorReporter {

    address payable public admin;
    bool internal _notEntered; // re-entrancy check flag
    MERC721InterfaceFull public mERC721;
    IERC721 public underlyingERC721;
    WETHInterface WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    mapping (address => bool) public isWhiteListed;

    constructor(address _mERC721Address) public {
        admin = msg.sender;
        mERC721 = MERC721InterfaceFull(_mERC721Address);
        underlyingERC721 = IERC721(mERC721.underlyingContract());
        underlyingERC721.setApprovalForAll(_mERC721Address, true);
        _notEntered = true; // Start true prevents changing from zero to non-zero (smaller gas cost)
    }

    function _setWhiteList(address candidate, bool state) external {
        require(msg.sender == admin, "only admin");
        isWhiteListed[candidate] = state;
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external returns (uint) {
        tokenId;
        seller;
        sellPrice;
        transferParams;
        revert("not implemented");
    }

    /**
     * @notice Handle the receipt of an NFT, see Open Zeppelin's IERC721Receiver.
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4) {
        /* unused parameters - silence warnings */
        operator;
        from;
        tokenId;
        data;
        address(this);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Used in 'executeFlashOperation()' to perform initial checks (reverts on error)
     */
    function checkReceivedFunds(address sender, uint240 mToken, uint paidOutAmount) internal view returns (MEtherInterfaceFull mEther) {
        mEther = MEtherInterfaceFull(sender);
        require(isWhiteListed[sender], "caller not whitelisted");
        require(mEther.thisFungibleMToken() == mToken, "invalid mToken");
        require(mEther.underlyingContract() == address(uint160(-1)), "borrow must be in ETH");
        require(paidOutAmount <= address(this).balance, "insufficient contract balance");
    }

    /**
     * @notice Used in 'executeFlashOperation()' to pay refunds: use any remaining funds 
     * to repay part of the borrow, transfer the rest in cash (reverts on error)
     */
    function payRefunds(MEtherInterface mEther, address payable borrower, uint240 mToken, uint refund) internal {
        if (refund > 0) {
            uint borrowBalance = mEther.borrowBalanceStored(borrower, mToken);
            if (borrowBalance < refund) {
                borrower.transfer(refund - borrowBalance);
            }
            else {
                borrowBalance = refund;
            }
            if (borrowBalance > 0) {
                mEther.repayBorrowBehalf.value(borrowBalance)(borrower);
            }
        }
    }

    /**
     * @notice Used in 'executeTransfer()' to check and pay out sales proceeds: first, repay any
     * borrows of the seller, then pay out the rest in cash (reverts on error)
     */
    function checkReceivedWETHAndPayOut(uint256 oldWETHBalance, address payable seller, uint sellPrice) internal {
        /* check if sufficient funds (in WETH) received for sale */
        uint256 cashReceived = WETHContract.balanceOf(address(this));
        require(cashReceived >= oldWETHBalance, "WETH balance corrupted");
        cashReceived = cashReceived - oldWETHBalance;
        require(cashReceived >= sellPrice, "Insufficient price received");

        /* convert received WETH -> ETH */
        WETHContract.withdraw(cashReceived);

        // use proceeds to repay outstanding borrows, transfer any surplus cash to original owner
        MEtherUserInterface mEther = mERC721.tokenAuction().paymentToken();
        uint borrowBalance = mEther.borrowBalanceStored(seller, MTokenCommon(address(mEther)).thisFungibleMToken());
        if (borrowBalance > cashReceived) {
            borrowBalance = cashReceived;
        }
        if (borrowBalance > 0) {
            require(mEther.repayBorrowBehalf.value(borrowBalance)(seller) == borrowBalance, "Borrow repayment failed");
        }
        if (cashReceived > borrowBalance) {
            seller.transfer(cashReceived - borrowBalance);
        }
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

    // this is sometimes needed in case of (ETH) refunds, e.g. from NFTX buyAndRedeem()
    function () payable external {}

// The functions below this are safety measures in case of (ETH, ERC20, ERC721) transfers gone wrong.
// The admin can then retreive those left-over funds. This should not be needed in normal operation.

    function _withdraw() external {
        require(msg.sender == admin, "only admin");
        admin.transfer(address(this).balance);
    }

    /**
        @notice Admin may collect any ERC-20 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @param tokenContract The contract address of the "lost" token.
        @return (uint) Returns the amount of tokens successfully collected, otherwise reverts.
    */
    function _sweepERC20(address tokenContract) external returns (uint) {
        require(msg.sender == admin, "only admin");
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "No leftover tokens found");
        IERC20(tokenContract).transfer(admin, amount);
        return amount;
    }

    /**
        @notice Admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param tokenContract The contract address of the "lost" token.
        @param tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address tokenContract, uint256 tokenID) external {
        require(msg.sender == admin, "only admin");
        require(address(this) == IERC721(tokenContract).ownerOf(tokenID), "Token not owned by contract");
        IERC721(tokenContract).safeTransferFrom(address(this), admin, tokenID);
    }
}

contract MortgageMintGlasses is MortgageERC721UsingETH {

    constructor(address _mGlassesAddress) public MortgageERC721UsingETH(_mGlassesAddress) {
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;
        flashParams;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);

        /* Get Glasses contract address */
        TestNFT glasses = TestNFT(address(uint160(mERC721.underlyingContract())));

        /* mint new Glasses */
        uint price = glasses.price();
        require(price <= paidOutAmount, "insufficient funds");
        uint refund = paidOutAmount - price;
        uint256 newGlassesID = glasses.mint.value(price)();
        require(glasses.ownerOf(newGlassesID) == address(this), "minting failed");

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, newGlassesID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract NFTXInterface {
    function buyAndRedeem(
        uint256 vaultId, 
        uint256 amount,
        uint256[] calldata specificIds, 
        address[] calldata path,
        address to
    ) external payable;
}

contract MortgageBuyNFTX is MortgageERC721UsingETH {

    address public nFTXAddress;

    constructor(address _mERC721Address, address _nFTXAddress) public MortgageERC721UsingETH(_mERC721Address) {
        nFTXAddress = _nFTXAddress;
    }

    /**
     * @notice Convenience function for assembling flashParams call data for NFTX buyAndRedeem()
     */
    function getBuyAndRedeemData(uint256 vaultId, uint256 amount, uint256[] calldata specificIds, address[] calldata path) external pure returns (bytes memory) {
        return abi.encode(vaultId, amount, specificIds, path);
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve call arguments from flashParams */
            (uint256 vaultId, uint256 amount, uint256[] memory specificIds, address[] memory path) = abi.decode(flashParams, (uint256, uint256, uint256[], address[]));
            require(amount == 1 && specificIds.length == 1, "invalid token amount");
            underlyingID = specificIds[0];
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call NFTX with flashParams call data, obtained e.g. using getBuyAndRedeemData() */
            NFTXInterface(nFTXAddress).buyAndRedeem.value(paidOutAmount)(vaultId, amount, specificIds, path, address(this));
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from NFTX failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract OpenSeaWyvernInterface {
    /* Fee method: protocol fee or split fee. */
    enum FeeMethod { ProtocolFee, SplitFee }
    enum Side { Buy, Sell }
    enum SaleKind { FixedPrice, DutchAuction }
    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable;
}

contract MortgageBuyOpenSeaWyvern is MortgageERC721UsingETH {

    address payable public constant openSeaExchange = 0x7f268357A8c2552623316e2562D90e642bB538E5;
    address public constant merkleValidatorTarget = 0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7;
    address public constant openSeaWallet = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
    }

    /**
     * @notice Convenience function for assembling flashParams call data for OpenSea atomicMatch_()
     * @return Returns the flashParams calldata to be used directly in flashBorrow().
     */
    function getAtomicMatchData(
            address seller, 
            address sellOrderFeeRecipient, 
            uint sellMakerRelayerFee, 
            uint sellOrderPrice, 
            uint[2] memory sellOrderListingAndExpirationTime,
            uint sellOrderSalt,
            OpenSeaWyvernInterface.FeeMethod sellerFeeMethod,
            uint[3] memory sellerSignature_vrs,
            address tokenAddress,
            uint256 tokenId
        ) public view returns (bytes memory) 
    {
        AtomicMatchParameters memory params = AtomicMatchParameters(
            seller,
            sellOrderFeeRecipient, 
            sellMakerRelayerFee, 
            sellOrderPrice, 
            sellOrderListingAndExpirationTime,
            sellOrderSalt,
            sellerFeeMethod,
            sellerSignature_vrs,
            tokenAddress,
            tokenId
        );
        return getAtomicMatchDataInternal(params);
    }

    struct AtomicMatchParameters {
        address seller; 
        address sellOrderFeeRecipient; 
        uint sellMakerRelayerFee;
        uint sellOrderPrice;
        uint[2] sellOrderListingAndExpirationTime; 
        uint sellOrderSalt;
        OpenSeaWyvernInterface.FeeMethod sellerFeeMethod;
        uint[3] sellerSignature_vrs;
        address tokenAddress;
        uint256 tokenId;
    }

    struct AtomicMatchLocalVars {
        /* for stack size reasons, the following fixed size (32 bytes) params are combined into one uint[40] array:
         * address[14] addrs;
         * uint[18] uints;
         * uint8[8] feeMethodsSidesKindsHowToCalls;
        */
        uint[40] fixedSize;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint[7] signatureData; // uint8[2] vs: v, v; bytes32[5] rssMetadata: r, s, r, s
    }

    function getAtomicMatchDataInternal(AtomicMatchParameters memory params) internal view returns (bytes memory) 
    {

        AtomicMatchLocalVars memory vars;

        vars.fixedSize[0] = uint(openSeaExchange); // buy order opensea exchange contract address
        vars.fixedSize[1] = uint(address(this)); // buy order maker: buyer address
        vars.fixedSize[2] = uint(params.seller); // buy order taker: selling owner address
        vars.fixedSize[3] = uint(address(0)); // buy order feeRecipient - must be zero if seller nonzero
        vars.fixedSize[4] = uint(merkleValidatorTarget); // buy order target: MerkleValidator contract - must match sell order
        vars.fixedSize[5] = uint(address(0)); // buy order staticTarget: zero if no static target
        vars.fixedSize[6] = uint(address(0)); // buy order paymentToken: zero for ETH

        vars.fixedSize[7] = uint(openSeaExchange); // sell order opensea exchange contract address
        vars.fixedSize[8] = uint(params.seller); // sell order maker: selling owner address
        vars.fixedSize[9] = uint(address(0)); // sell order taker: nobody
        if (params.sellOrderFeeRecipient != address(0)) {
            vars.fixedSize[10] = uint(params.sellOrderFeeRecipient); // sell order feeRecipient: set by user
        } else {
            vars.fixedSize[10] = uint(openSeaWallet); // sell order feeRecipient: OpenSea Wallet contract
        }
        vars.fixedSize[11] = uint(merkleValidatorTarget); // sell order target: MerkleValidator contract - must match buy order
        vars.fixedSize[12] = uint(address(0)); // sell order staticTarget: zero if no static target
        vars.fixedSize[13] = uint(address(0)); // sell order paymentToken: zero for ETH

        vars.fixedSize[14] = params.sellMakerRelayerFee; // makerRelayerFee - unused for taker order
        vars.fixedSize[15] = 0; // takerRelayerFee
        vars.fixedSize[16] = 0; // makerProtocolFee
        vars.fixedSize[17] = 0; // takerProtocolFee
        vars.fixedSize[18] = params.sellOrderPrice; // buy order price (= sellOrderPrice)
        vars.fixedSize[19] = 0; // auction extra: 0 if not used
        vars.fixedSize[20] = block.number; // buy order listing time
        vars.fixedSize[21] = 0; // buy order expiration time: 0 if no expiration
        vars.fixedSize[22] = uint(keccak256(abi.encode(params.sellerSignature_vrs[1], msg.sender, block.number))); // buy order salt

        vars.fixedSize[23] = params.sellMakerRelayerFee; // sell order makerRelayerFee
        vars.fixedSize[24] = 0; // takerRelayerFee
        vars.fixedSize[25] = 0; // makerProtocolFee
        vars.fixedSize[26] = 0; // takerProtocolFee
        vars.fixedSize[27] = params.sellOrderPrice; // sell order price
        vars.fixedSize[28] = 0; // auction extra: 0 if not used
        vars.fixedSize[29] = params.sellOrderListingAndExpirationTime[0]; // sell order listing time
        vars.fixedSize[30] = params.sellOrderListingAndExpirationTime[1]; // sell order expiration time
        vars.fixedSize[31] = params.sellOrderSalt; // sell order salt

        vars.fixedSize[32] = uint8(params.sellerFeeMethod); // FeeMethod buy order - must match sell order
        vars.fixedSize[33] = uint8(OpenSeaWyvernInterface.Side.Buy); // Side buy order - must be opposite sell order
        vars.fixedSize[34] = uint8(OpenSeaWyvernInterface.SaleKind.FixedPrice); // SaleKind buy order - must match sell order
        vars.fixedSize[35] = uint8(OpenSeaWyvernInterface.HowToCall.DelegateCall); // HowToCall buy order - must match sell order

        vars.fixedSize[36] = uint8(params.sellerFeeMethod); // FeeMethod sell order
        vars.fixedSize[37] = uint8(OpenSeaWyvernInterface.Side.Sell); // Side sell order
        vars.fixedSize[38] = uint8(OpenSeaWyvernInterface.SaleKind.FixedPrice); // SaleKind sell order
        vars.fixedSize[39] = uint8(OpenSeaWyvernInterface.HowToCall.DelegateCall); // HowToCall sell order

        (vars.calldataBuy, 
        vars.calldataSell, 
        vars.replacementPatternBuy, 
        vars.replacementPatternSell) = constructCalldata(params.seller, params.tokenAddress, params.tokenId);

        vars.staticExtradataBuy; // unused - leave empty
        vars.staticExtradataSell; // unused - leave empty

        vars.signatureData[0] = params.sellerSignature_vrs[0];
        vars.signatureData[1] = params.sellerSignature_vrs[0];

        vars.signatureData[2] = params.sellerSignature_vrs[1];
        vars.signatureData[3] = params.sellerSignature_vrs[2];
        vars.signatureData[4] = params.sellerSignature_vrs[1];
        vars.signatureData[5] = params.sellerSignature_vrs[2];
        vars.signatureData[6] = 0;
        
        return abi.encode(vars.fixedSize, vars.calldataBuy, vars.calldataSell, vars.replacementPatternBuy, vars.replacementPatternSell, vars.staticExtradataBuy, vars.staticExtradataSell, vars.signatureData);
    }

    // calldata for token transfer call: calldataBuy must match callDataSell after replacement pattern
    function constructCalldata(address seller, address tokenAddress, uint256 tokenId) internal view 
        returns (
            bytes memory calldataBuy,
            bytes memory calldataSell,
            bytes memory replacementPatternBuy,
            bytes memory replacementPatternSell
        ) 
    {
        bytes32[] memory proof;
        calldataBuy = abi.encodeWithSelector(
            bytes4(0xfb16a595), // token transfer function selector
            address(0), // from: seller address
            address(this), // to: buyer address
            tokenAddress, // token: e.g. Penguin contract address
            tokenId, // tokenId: e.g. Penguin ID
            bytes32(0), // root: set to zero means no proof
            proof // proof (if root != 0)
        );

        calldataSell = abi.encodeWithSelector(
            bytes4(0xfb16a595), // token transfer function selector
            seller, // from: seller address
            address(0), // to: buyer address
            tokenAddress, // token: e.g. Penguin contract address
            tokenId, // tokenId: e.g. Penguin ID
            bytes32(0), // root: set to zero means no proof
            proof // proof (if root != 0)
        );
        
        bytes memory replacementPatternBuyFirst = abi.encodeWithSelector(
            bytes4(0), // token transfer function selector
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), // from: seller address
            bytes32(0) // to: buyer address
        );
        replacementPatternBuy = abi.encodePacked(replacementPatternBuyFirst, new bytes(calldataBuy.length - replacementPatternBuyFirst.length));

        bytes memory replacementPatternSellFirst = abi.encodeWithSelector(
            bytes4(0), // token transfer function selector
            bytes32(0), // from: seller address
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // to: buyer address
        );
        replacementPatternSell = abi.encodePacked(replacementPatternSellFirst, new bytes(calldataSell.length - replacementPatternSellFirst.length));
    }

    /**
     * @notice Convenience function for assembling flashParams call data for OpenSea atomicMatch_().
     * @param dataWithSignature Call data obtained e.g. from Metamask when manually buying an NFT on OpenSea
     * @return flashParams is the call data with buyer fields adjusted to be used directly in flashBorrow().
     * The other return values can be used to analyse the call data, or for getAtomicMatchData()
     */
    function parseAtomicMatchCalldata(bytes memory dataWithSignature) 
        public view returns (
            address seller,
            address sellOrderFeeRecipient,
            uint sellMakerRelayerFee,
            uint sellOrderPrice,
            uint[2] memory sellOrderListingAndExpirationTime,
            uint sellOrderSalt,
            OpenSeaWyvernInterface.FeeMethod sellerFeeMethod,
            uint[3] memory sellerSignature_vrs,
            address tokenAddress,
            uint256 tokenId,
            bytes memory flashParams
        ) 
    {
        for (uint i = 4; i < dataWithSignature.length; i++) {
            dataWithSignature[i - 4] = dataWithSignature[i];
        }
        uint[40] memory fixedSize;
        bytes memory calldataSell;
        uint[7] memory signatureData;
        // skip function signature
        (fixedSize, , calldataSell, , , , , signatureData) = abi.decode(dataWithSignature, (uint[40], bytes, bytes, bytes, bytes, bytes, bytes, uint[7]));
        seller = address(fixedSize[8]);
        sellOrderFeeRecipient = address(fixedSize[10]);
        sellMakerRelayerFee = fixedSize[23];
        sellOrderPrice = fixedSize[27];
        sellOrderListingAndExpirationTime[0] = fixedSize[29];
        sellOrderListingAndExpirationTime[1] = fixedSize[30];
        sellOrderSalt = fixedSize[31];
        sellerFeeMethod = OpenSeaWyvernInterface.FeeMethod(uint8(fixedSize[36]));
        sellerSignature_vrs[0] = signatureData[1];
        sellerSignature_vrs[1] = signatureData[4];
        sellerSignature_vrs[2] = signatureData[5];
        // skip function signature
        for (uint i = 4; i < calldataSell.length; i++) {
            calldataSell[i - 4] = calldataSell[i];
        }
        ( , , tokenAddress, tokenId) = abi.decode(calldataSell, (address, address, address, uint256));
        flashParams = getAtomicMatchData(seller, sellOrderFeeRecipient, sellMakerRelayerFee, sellOrderPrice, sellOrderListingAndExpirationTime, sellOrderSalt, sellerFeeMethod, sellerSignature_vrs, tokenAddress, tokenId);
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve underlyingID from flashParams and do some sanity checks */
            ( , bytes memory calldataBuy, , , , , , ) = abi.decode(flashParams, (uint[40], bytes, bytes, bytes, bytes, bytes, bytes, uint[7]));
            // skip function signature
            for (uint i = 4; i < calldataBuy.length; i++) {
                calldataBuy[i - 4] = calldataBuy[i];
            }
            address buyer;
            address underlyingAddress;
            ( , buyer, underlyingAddress, underlyingID) = abi.decode(calldataBuy, (address, address, address, uint256));
            require(buyer == address(this), "buyer mismatch");
            require(underlyingAddress == address(underlyingERC721), "underlying contract mismatch");
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call OpenSeaExchange with flashParams call data, obtained e.g. using getAtomicMatchData() */
            bytes memory atomicMatchCallData = abi.encodePacked(OpenSeaWyvernInterface(openSeaExchange).atomicMatch_.selector, flashParams);
            (bool success, ) = openSeaExchange.call.value(paidOutAmount)(atomicMatchCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract OpenSeaSeaportInterface {
    
    /** BASIC ORDERS */

    /**
    * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
    *      matching, a group of six functions may be called that only requires a
    *      subset of the usual order arguments. Note the use of a "basicOrderType"
    *      enum; this represents both the usual order type as well as the "route"
    *      of the basic order (a simple derivation function for the basic order
    *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
    */
    struct BasicOrderParameters {
        // calldata offset
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
        // Total length, excluding dynamic array data: 0x264 (580)
    }

    /**
    * @dev Basic orders can supply any number of additional recipients, with the
    *      implied assumption that they are supplied from the offered ETH (or other
    *      native token) or ERC20 token for the order.
    */
    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    // prettier-ignore
    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,

        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,

        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,

        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,

        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,

        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,

        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,

        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,

        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,

        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,

        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,

        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,

        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,

        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,

        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,

        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,

        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,

        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,

        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,

        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }


    /** NORMAL / ADVANCED ORDERS */

    /**
    * @dev The full set of order components, with the exception of the counter,
    *      must be supplied when fulfilling more sophisticated orders or groups of
    *      orders. The total number of original consideration items must also be
    *      supplied, as the caller may specify additional consideration items.
    */
    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    /**
    * @dev Orders require a signature in addition to the other order parameters.
    */
    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    /**
    * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
    *      and a denominator (the total size of the order) in addition to the
    *      signature and other order parameters. It also supports an optional field
    *      for supplying extra data; this data will be included in a staticcall to
    *      `isValidOrderIncludingExtraData` on the zone for the order if the order
    *      type is restricted and the offerer or zone are not the caller.
    */
    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    /**
    * @dev An offer item has five components: an item type (ETH or other native
    *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
    *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
    *      component that will either represent a tokenId or a merkle root
    *      depending on the item type, and a start and end amount that support
    *      increasing or decreasing amounts over the duration of the respective
    *      order.
    */
    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    /**
    * @dev A consideration item has the same five components as an offer item and
    *      an additional sixth component designating the required recipient of the
    *      item.
    */
    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    // prettier-ignore
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    // prettier-ignore
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,

        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    // prettier-ignore
    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }

    /**
    * @dev A criteria resolver specifies an order, side (offer vs. consideration),
    *      and item index. It then provides a chosen identifier (i.e. tokenId)
    *      alongside a merkle proof demonstrating the identifier meets the required
    *      criteria.
    */
    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }


    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Seaport.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);
}

contract MortgageBuyOpenSeaSeaportBasic is MortgageERC721UsingETH {

    address payable public constant openSeaSeaport = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address payable public constant openSeaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
        // allow OpenSea conduit to access all WETH of this contract
        WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETHContract.approve(openSeaConduit, uint256(-1));
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve underlyingID from flashParams and do some sanity checks */
            OpenSeaSeaportInterface.BasicOrderParameters memory parameters = abi.decode(flashParams, (OpenSeaSeaportInterface.BasicOrderParameters));
            require(parameters.offerToken == address(underlyingERC721), "underlying contract mismatch");
            require(parameters.offerAmount == 1, "token amount mismatch");
            underlyingID = parameters.offerIdentifier;
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call openSeaSeaport fulfillBasicOrder() with flashParams call data */
            bytes memory fulfillBasicOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillBasicOrder.selector, flashParams);
            (bool success, ) = openSeaSeaport.call.value(paidOutAmount)(fulfillBasicOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            /* check if NFT received */
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external nonReentrant returns (uint) {

        // only allow linked ERC721 contract to call this
        require(msg.sender == address(mERC721), "invalid caller");
    
        // allow openSeaConduit to transfer this tokenId (which is currently owned by this contract already)
        underlyingERC721.approve(openSeaConduit, tokenId);

        // get current WETH balance for this contract
        uint256 oldWETHBalance = WETHContract.balanceOf(address(this));

        {
            /* decode transferParams and do some sanity checks */
            OpenSeaSeaportInterface.BasicOrderParameters memory parameters = abi.decode(transferParams, (OpenSeaSeaportInterface.BasicOrderParameters));
            require(parameters.considerationToken == address(underlyingERC721), "underlying contract mismatch");
            require(parameters.considerationAmount == 1, "token amount mismatch");
            require(parameters.considerationIdentifier == tokenId, "tokenId mismatch");

            /* call openSeaSeaport fulfillBasicOrder() with transferParams call data */
            bytes memory fulfillBasicOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillBasicOrder.selector, transferParams);
            (bool success, ) = openSeaSeaport.call(fulfillBasicOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            checkReceivedWETHAndPayOut(oldWETHBalance, seller, sellPrice);
        }

        return uint(Error.NO_ERROR);
    }
}

contract MortgageBuyOpenSeaSeaportAdvanced is MortgageERC721UsingETH {

    address payable public constant openSeaSeaport = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address payable public constant openSeaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
        // allow OpenSea conduit to access all WETH of this contract
        WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETHContract.approve(openSeaConduit, uint256(-1));
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* decode flashParams and do some sanity checks including tokenId and funds recipient */
            (OpenSeaSeaportInterface.AdvancedOrder memory advancedOrder, OpenSeaSeaportInterface.CriteriaResolver[] memory criteriaResolvers, , address recipient) = abi.decode(flashParams, (OpenSeaSeaportInterface.AdvancedOrder, OpenSeaSeaportInterface.CriteriaResolver[], bytes32, address));
            require(advancedOrder.parameters.offer.length >= 1, "invalid flashParams");
            require(advancedOrder.parameters.offer[0].token == address(underlyingERC721), "underlying contract mismatch");
            require(advancedOrder.parameters.offer[0].startAmount == 1, "token amount mismatch");
            require(advancedOrder.parameters.offer[0].endAmount == 1, "token amount mismatch");
            if (advancedOrder.parameters.offer[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721) {
                underlyingID = advancedOrder.parameters.offer[0].identifierOrCriteria;
            }
            else if (advancedOrder.parameters.offer[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721_WITH_CRITERIA) {
                require(criteriaResolvers.length >= 1, "invalid criteria length");
                underlyingID = criteriaResolvers[0].identifier;
            }
            else {
                revert("tokenId not found");
            }
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");
            require(recipient == address(0) || recipient == address(this), "invalid funds recipient");
    
            /* call openSeaSeaport fulfillAdvancedOrder() with transferParams call data */
            bytes memory fulfillAdvancedOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillAdvancedOrder.selector, flashParams);
            (bool success, ) = openSeaSeaport.call(fulfillAdvancedOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            /* check if NFT received */
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external nonReentrant returns (uint) {

        // only allow linked ERC721 contract to call this
        require(msg.sender == address(mERC721), "invalid caller");
    
        // allow openSeaConduit to transfer this tokenId (which is currently owned by this contract already)
        underlyingERC721.approve(openSeaConduit, tokenId);

        // get current WETH balance for this contract
        uint256 oldWETHBalance = WETHContract.balanceOf(address(this));

        {
            /* decode transferParams and do some sanity checks including tokenId and funds recipient */
            (OpenSeaSeaportInterface.AdvancedOrder memory advancedOrder, OpenSeaSeaportInterface.CriteriaResolver[] memory criteriaResolvers, , address recipient) = abi.decode(transferParams, (OpenSeaSeaportInterface.AdvancedOrder, OpenSeaSeaportInterface.CriteriaResolver[], bytes32, address));
            require(advancedOrder.parameters.consideration.length >= 1, "invalid transferParams");
            require(advancedOrder.parameters.consideration[0].token == address(underlyingERC721), "underlying contract mismatch");
            require(advancedOrder.parameters.consideration[0].startAmount == 1, "token amount mismatch");
            require(advancedOrder.parameters.consideration[0].endAmount == 1, "token amount mismatch");
            if (advancedOrder.parameters.consideration[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721) {
                require(advancedOrder.parameters.consideration[0].identifierOrCriteria == tokenId, "tokenId mismatch");
            }
            else if (advancedOrder.parameters.consideration[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721_WITH_CRITERIA) {
                require(criteriaResolvers.length >= 1, "invalid criteria length");
                require(criteriaResolvers[0].identifier == tokenId, "tokenId criteria mismatch");
            }
            else {
                revert("tokenId not found");
            }
            require(recipient == address(0) || recipient == address(this), "invalid funds recipient");
    
            /* call openSeaSeaport fulfillAdvancedOrder() with transferParams call data */
            bytes memory fulfillAdvancedOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillAdvancedOrder.selector, transferParams);
            (bool success, ) = openSeaSeaport.call(fulfillAdvancedOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            checkReceivedWETHAndPayOut(oldWETHBalance, seller, sellPrice);
        }

        return uint(Error.NO_ERROR);
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
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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