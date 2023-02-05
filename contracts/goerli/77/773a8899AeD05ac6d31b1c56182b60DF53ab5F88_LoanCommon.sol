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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LoanCommon {
    using SafeMath for uint256;

    /// @notice Supported NFT Standard
    enum Standard {
        ERC721,   // 0
        ERC1155   // 1
    }

    /// @notice Loan Status
    enum LoanStatus {
        ACTIVE,       // 0
        CANCELLED,    // 1
        PAID,         // 2
        RECRUITING    // 3
    }

    /// @notice Loan structure
    /// field holder The address, holds the collateral that is being borrowed against
    /// field amount The loan amount
    /// field duration The loan duration
    /// field createdDate The creation timestamp when the loan is created
    /// field activationDate The timestamp when the loan is activated
    /// field status The status of the loan
    /// field calculatedInterest The calculated interest at the time the loan is activated
    /// field calculatedAmount As a can accept offers that are less than the loan amount
    /// field fractionalizedTokenId The fractionalized 1155 token ID
    /// field loanCollateralNftTokenId The collateral token ID
    /// field interestFeePercent This is a copy of the interest fee that the DAO gets paid
    /// field interestPaid Then loan is paid off, this field will hold the amount of interest paid
    struct Loan {
        uint256 loanId;                     // 0
        address holder;                     // 1
        uint256 amount;                     // 2
        uint256 duration;                   // 3
        uint256 createdDate;                // 4
        uint256 activationDate;             // 5
        LoanStatus status;                  // 6
        uint256 calculatedInterest;         // 7
        uint256 calculatedAmount;           // 8
        uint256 fractionalizedTokenId;      // 9
        uint256 loanCollateralNftTokenId;   // 10
        uint256 interestFeePercent;         // 11
    }

    /// @notice extension because we were seeing a too deep solidity error
    /// field loanId The loan Id
    /// field interestPaid when a loan is paid off this field will hold the total interest paid
    struct LoanExtension {
        uint256 loanId;                     // 0
        uint256 interestPaid;               // 1
    }

    /// @notice The structure of a nft loan collateral record
    /// field loanId The loan id
    /// field nftContracts list of NFT contracts collateral that are part of the loan
    /// field nftTokenIds list of NFT tokenIds collateral that are part of the loan
    /// field nftTokenAmounts list of NFT tokenAmounts collateral that are part of the loan
    /// field standards list of NFT standards collateral that are part of the loan
    /// field nftEstimatedValue the estimated value of the NFTs put forth by the borrower
    /// field createdDate The creation timestamp when the payment is created
    struct NftCollateral {
        uint256 loanId;
        address[] nftContracts;
        uint256[] nftTokenIds;
        uint256[] nftTokenAmounts;
        Standard[] standards;
        uint256 nftEstimatedValue;
        uint256 createdDate;
    }


    enum CollectionOfferKind {
        LOAN,           // 0
        COLLECTION      // 1
    }

    struct OfferParam {
        uint256 offerId;
        CollectionOfferKind kind;
    }

    enum CollectionOfferType {
        FIXED,          // 0
        FLOATING        // 1
    }

    enum CollectionOfferStatus {
        ACTIVE,         // 0
        CANCELLED,      // 1
        PAUSED          // 2
    }

    ///######################################
    ///# CO-0001 CO-0002
    ///######################################
    /// @notice The structure of a loan offer
    /// field collectionOfferId The primary key for the collection record
    /// field collection The collection address
    /// field lender The wallet address of the one making the collection offer
    /// field totalOfferAmount for fixed offers, this is the amount of eth allocated to this offer
    /// field maxRequestedAmount The ceiling by which a collection offer is eligible
    /// field interestRate The amount of interest expected earned at the end of the loan
    /// field offerType floating of fixed
    /// field collectionExpenditure for tracking the collection offer expenditure, for fixed offers, expenditure cannot
    ///       exceed totalLoanAmount
    /// field expiry unix time stamp for when the collection offer expires
    /// field createdDate The creation timestamp when the offer was created
    struct CollectionOffer {
        uint256 offerId;                // 0
        address collection;             // 1
        address lender;                 // 2
        //*********************************************************************
        // CO-0010 Total Loan Amount
        //*********************************************************************
        uint256 totalLoanAmount;        // 3
        //*********************************************************************
        // CO-0011 Total Loan Amount
        //*********************************************************************
        uint256 maxRequestedAmount;     // 4
        uint256 interestRate;           // 5
        CollectionOfferType offerType;  // 6
        CollectionOfferStatus status;   // 7
        uint256 collectionExpenditure;  // 8
        uint256 expiry;                 // 9
        uint256 createdDate;            // 10
        //*********************************************************************
        // CO-0012 Initial Floor
        //*********************************************************************
        uint256 floor;                  // 11
    }

    /// @notice Bid Status - the possible statuses of a bid
    enum OfferStatus {
        ACCEPTED,       // 0
        PENDING,        // 1
        DENIED,         // 2
        CANCELLED       // 3
    }

    /// @notice The structure of a loan offer
    /// field offerId The primary key for the offer record
    /// field loanId The loan id
    /// field lender The wallet address of the one making the loan offer
    /// field offeredAmount The eth amount that is being offered
    /// field interest The amount of interest expected earned at the end of the loan
    /// field acceptedAmount The amount that was accepted at the time the loan is created
    /// field status The status of the offer
    /// field createdDate The creation timestamp when the offer was created
    struct Offer {
        uint256 offerId;
        uint256 loanId;
        address lender;
        uint256 offeredAmount;
        uint256 interest;
        uint256 acceptedAmount;
        OfferStatus status;
        uint256 createdDate;
    }

    /// @notice The structure of a loan payment
    /// field paymentId The primary key for the payment record
    /// field payer The wallet address of the one making the payment
    /// field loanId The loan id
    /// field amount The amount that is being paid
    /// field createdDate The creation timestamp when the payment is created
    struct Payment {
        uint256 paymentId;
        uint256 loanId;
        address payer;
        uint256 amount;
        uint256 createdDate;
    }

    /// @notice Bid Status
    enum BidStatus {
        ACTIVE,
        CANCELLED
    }

    /// @notice Bid Structure
    struct Bid {
        uint256 bidId;
        uint256 loanId;
        address bidder;
        uint256 amount;
        BidStatus status;
        uint256 createdDate;
    }

    /// @notice calculate the number of shares owed
    /// @param _total The total amount
    /// @param _amount The amount
    /// @param _totalShares The total shares to be distributed
    /// @param _precision The precision amount
    function calculateShares(uint256 _total, uint256 _amount, uint256 _totalShares, uint256 _precision) internal pure returns(uint256) {
        uint256 percentage = _amount.mul(_precision).div(_total);
        uint256 shares = percentage.mul(_totalShares).div(_precision);
        return shares;
    }

    /// @notice calculate the percentage of an amount
    /// @dev (_amount * _percent) / _factor
    function calculatePercentage(uint256 _amount, uint256 _percent, uint256 _precision) internal pure returns (uint256) {
        return _amount.mul(_percent).div(_precision);
    }

    /////////////////////////////////////////
    // reference TFL-0016
    /////////////////////////////////////////
    /// @notice get the create loan fee
    /// @param _estimatedValue The estimated value of the loan
    function createLoanFee(uint256 _estimatedValue, uint256 _loanPostingFeePercent, uint256 _precision) internal pure returns (uint256) {
        return _estimatedValue
        .mul(_loanPostingFeePercent)
        .div(_precision);
    }
}

interface LoanService_I {
    function loans(uint256 _loanId) external view returns(LoanCommon.Loan memory);
    function updateStatus(uint256 _loanId, LoanCommon.LoanStatus _status) external;
    function updateLoanInterestPaid(uint256 _loanId, uint256 _interestPaid) external;
}

interface LoanStorage_I {
    function cancelLoan(uint256 _loanId) external;
    function create(address _borrower, uint256 _amount, uint256 _duration) external returns (uint256);
    function loans(uint256 _loanId) external view returns(LoanCommon.Loan memory);
    function updateCalculatedInterest(uint256 _loanId, uint256 _calculatedInterest) external;
    function updateCalculatedAmount(uint256 _loanId, uint256 _calculatedInterest) external;
    function updateFractionalizedTokenId(uint256 _loanId, uint256 _fractionalizedTokenId) external;
    function updateLoanActivationDate(uint256 _loanId, uint256 _timestamp) external;
    function updateLoanCollateralNftTokenId(uint256 _loanId, uint256 _loanCollateralNftTokenId) external;
    function updateStatus(uint256 _loanId, LoanCommon.LoanStatus _status) external;
    function updateLoanInterestPaid(uint256 _loanId, uint256 _interestPaid) external;
    function getLoanInterestPaid(uint256 _loanId) external view returns (uint256);
}

interface LoanNftCollateralStorage_I {
    function collaterals(uint256 _loanId) external view returns(LoanCommon.NftCollateral memory);
    function create(
        uint256 _loanId,
        address[] memory _nftContracts,
        uint256[] memory _nftTokenIds,
        uint256[] memory _nftTokenAmounts,
        LoanCommon.Standard[] memory _standards,
        uint256 _nftEstimatedValue
    ) external;
}

interface LoanNftCollateralService_I {
    function collaterals(uint256 _loanId) external view returns(LoanCommon.NftCollateral memory);
    function create(
        uint256 _loanId,
        address[] memory _nftContracts,
        uint256[] memory _nftTokenIds,
        uint256[] memory _nftTokenAmounts,
        LoanCommon.Standard[] memory _standards,
        uint256 _nftEstimatedValue
    ) external;
}

interface LoanTreasuryStorage_I {
    function account(address _wallet) external view returns (uint256);
    function addFunds(address _recipient, uint256 _amount) external;
    function collateralToken() external view returns (address);
    function collateralTokenSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function erc1155SafeTransferFrom(address _contract, address _from, address _to, uint256 _tokenId, uint256 _amount) external;
    function erc721safeTransferFrom(address _contract, address _from, address _to, uint256 _tokenId) external;
    function fractionalizeToken() external view returns (address);
    function fractionalizeTokenSafeTransferFrom(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintCollateralToken(string memory _tokenUri) external returns (uint256);
    function mintFractionalizeToken(uint256 _supply) external returns (uint256);
    function profitAddress() external view returns (address);
    function transferFunds(address _from, address _to, uint256 _amount) external;
}

interface LoanTreasuryService_I {
    function addFunds(address _recipient, uint256 _amount) external;
    function account(address _wallet) external view returns (uint256);
    function collateralTokenSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function fractionalizeTokenSafeTransferFrom(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintCollateralToken(string memory _tokenUri) external returns (uint256);
    function mintFractionalizeToken(uint256 _supply) external returns (uint256);
    function profitAddress() external view returns (address);
    function transferFunds(address _from, address _to, uint256 _amount) external;
    function ownerOfCollateralToken(uint256 _loanId) external view returns (address);
    function claimNft(uint256 _loanId, address _recipient) external;
}


interface LoanParameters_I {
    function enabled() external view returns (bool);
    function fractionalizeSupply() external view returns (uint256);
    function loanDefaultGracePeriodInMinutes() external view returns (uint256);
    function loanPostingFeePercent() external view returns (uint256);
    function loanProcessingFeePercent() external view returns (uint256);
    function maxLoanDurationInDays() external view returns (uint256);
    function maxLoanPercentageOfCollateral() external view returns (uint256);
    function minLoanDurationInDays() external view returns (uint256);
    function minLoanPercentageOfCollateral() external view returns (uint256);
    function interestFeePercent() external view returns (uint256);
    function precision() external view returns (uint256);
}

interface LoanOfferStorage_I {
    function offers(uint256 _offerId) external view returns(LoanCommon.Offer memory);
    function updateAcceptedAmount(uint256 _offerId, uint256 _acceptedAmount) external;
    function updateStatus(uint256 _offerId, LoanCommon.OfferStatus _status) external;
    function offersByLoanId(uint256 _loanId) external view returns(uint256[] memory);
    function create(address _lender, uint256 _loanId, uint256 _offeredAmount, uint256 _interest) external returns (uint256 offerId);
    function updateOffer(uint256 _offerId, uint256 _offeredAmount, uint256 _interest) external;
}

interface LoanCollectionOfferStorage_I {
    function offers(uint256 _offerId) external view returns(LoanCommon.CollectionOffer memory);
    function offersByCollection(address _collection) external view returns(uint256[] memory);
    function create(address _lender, address _collection, uint256 _maxRequestedAmount, uint256 _interestRate,
        LoanCommon.CollectionOfferType _offerType, uint256 _totalLoanAmount, uint256 _expiry, uint256 _floor
    ) external;
    function updateOffer(uint256 _offerId, uint256 _maxRequestedAmount, uint256 _interestRate, uint256 _expiry, uint256 _totalLoanAmount) external;
    function tallyExpenditure(uint256 _offerId, uint256 _amount) external;
    function updateStatus(uint256 _offerId, LoanCommon.CollectionOfferStatus status) external;
}

interface LoanCollectionOfferService_I {
    function tallyExpenditure(uint256 _offerId, uint256 _amount) external;
}

interface LoanOfferService_I {
    function offers(uint256 _offerId) external view returns(LoanCommon.Offer memory);
    function updateAcceptedAmount(uint256 _offerId, uint256 _acceptedAmount) external;
    function updateStatus(uint256 _offerId, LoanCommon.OfferStatus _status) external;
    function offersByLoanId(uint256 _loanId) external view returns(uint256[] memory);
    function createWithLender(address _lender, uint256 _loanId, uint256 _offeredAmount, uint256 _interest) external returns (uint256 offerId);
}

interface LoanPaymentStorage_I {
    function payments(uint256 _paymentId) external view returns(LoanCommon.Payment memory);
    function paymentsByLoanId(uint256 _loanId) external view returns(uint256[] memory);
    function create(address _payer, uint256 _loanId, uint256 _amount) external;
}

interface LoanBidStorage_I {
    function create(address _bidder, uint256 _loanId, uint256 _amount) external;
    function bids(uint256 _bidId) external view returns(LoanCommon.Bid memory);
    function bidsByLoanId(uint256 _loanId) external view returns(uint256[] memory);
}

interface LoanOracle_I {
    function getLoanBidServiceAddress() external view returns (address);
    function getLoanBidStorageAddress() external view returns (address);
    function getLoanCollectionOfferServiceAddress() external view returns (address);
    function getLoanCollectionOfferStorageAddress() external view returns (address);
    function getLoanCommonAddress() external view returns (address);
    function getLoanNftCollateralServiceAddress() external view returns (address);
    function getLoanNftCollateralStorageAddress() external view returns (address);
    function getLoanOfferServiceAddress() external view returns (address);
    function getLoanOfferStorageAddress() external view returns (address);
    function getLoanParametersAddress() external view returns (address);
    function getLoanPaymentServiceAddress() external view returns (address);
    function getLoanPaymentStorageAddress() external view returns (address);
    function getLoanServiceAddress() external view returns (address);
    function getLoanServiceExtensionAddress() external view returns (address);
    function getLoanStorageAddress() external view returns (address);
    function getLoanTreasuryServiceAddress() external view returns (address);
    function getLoanTreasuryStorageAddress() external view returns (address payable);
}

interface ERC1155_I {
    function setApprovalForAll(address _operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external;

    function balanceOf(address _address, uint256 _tokenId) external view returns (uint256 _balance);
}

interface ERC1155Supply_I {
    function totalSupply(uint256 id) external view returns (uint256);
}

interface ERC721_I {
    function isApprovedForAll(address _nftOwner, address _operator) external view returns (bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address _address);
}