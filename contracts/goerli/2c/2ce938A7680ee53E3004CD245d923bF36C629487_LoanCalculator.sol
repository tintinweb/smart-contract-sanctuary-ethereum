// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./TermData.sol";

/**
 * @title LoanCalculator
 * @author
 * @notice
 */
contract LoanCalculator is TermData {
    /* ******* */
    /* DATA TYPE */
    /* ******* */

    /* ******* */
    /* STORAGE */
    /* ******* */

    uint16 private constant HUNDRED_PERCENT = 10000;

    uint16 private USER_INTEREST_PERCENTAGE = 9600;

    uint16 private ONE_YEAR = 366;

    /* *********** */
    /* EVENTS */
    /* *********** */

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* FALLBACK FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    function getUserInterest(OfferTerm calldata _offer)
        public
        view
        returns (uint256)
    {
        if (_offer.offerType == OfferType.FIXED) {
            return
                _offer.principalAmount +
                (_offer.principalAmount *
                    _offer.annualPercentageRate *
                    _offer.duration *
                    USER_INTEREST_PERCENTAGE) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                ONE_YEAR;
        }
        return _offer.principalAmount;
    }

    function getAdminFee(OfferTerm calldata _offer)
        public
        view
        returns (uint256)
    {
        if (_offer.offerType == OfferType.FIXED) {
            return
                (_offer.principalAmount *
                    _offer.annualPercentageRate *
                    _offer.duration *
                    (HUNDRED_PERCENT - USER_INTEREST_PERCENTAGE)) /
                HUNDRED_PERCENT /
                HUNDRED_PERCENT /
                ONE_YEAR;
        }
        return 0;
    }

    function getTotalRepayAmount(OfferTerm calldata _offer)
        public
        view
        returns (uint256)
    {
        return getUserInterest(_offer) + getAdminFee(_offer);
    }

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title  TermData
 * @author Solarr
 * @notice An interface containg the main Loan struct shared by Direct Loans types.
 */
interface TermData {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    enum CollateralType {
        ERC721,
        ERC721A,
        ERC1155,
        ERC998,
        ERC1190
    }

    enum OfferType {
        FIXED
    }

    /**
     * @notice The offer made by the lender. Used as parameter on both acceptOffer (initiated by the borrower) and
     * acceptListing (initiated by the lender).
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param repaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     *  collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always
     * have to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     */
    struct OfferTerm {
        address collateralAddress;
        uint256 collateralId;
        CollateralType collateralType;
        uint256 principalAmount;
        uint16 duration;
        uint16 annualPercentageRate;
        address loanCurrencyAddress;
        OfferType offerType;
    }

    /**
     * @notice The offer made by the lender. Used as parameter on both acceptOffer (initiated by the borrower) and
     * acceptListing (initiated by the lender).
     *
     * @param borrower - The borrower address, that the nft owner who accepts the offer and transfer the ownership of
     * the nft to the contract, get received ERC20 token.
     * @param lender - The lender address, that the crypto owner who requested the offer, and transfer the ERC20 token
     * to the borrower.
     * @param startTime - The block.timestamp when the loan first began (measured in seconds).
     */
    struct LoanTerm {
        OfferTerm offer;
        address borrower;
        address lender;
        uint256 startTime;
    }
}