// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LoanCommon.sol";

contract LoanStoragePayment is Ownable {

    /// @notice The loan oracle address
    address public loanOracleAddress;

    /// @notice Set the oracle address
    /// @param _address The new loan storage address
    function setLoanOracleAddress(address _address) public onlyOwner {
        loanOracleAddress = _address;
    }

    /// @notice internal function to get the loan oracle address
    function getLoanOracleAddress() internal view returns (address) {
        require (loanOracleAddress != address(0x0), "loan oracle address must be set");
        return loanOracleAddress;
    }

    /// @dev payments[paymentId] => LoanPayment
    mapping(uint256 => LoanCommon.Payment) public paymentMapping;

    /// @notice Payment tracking ID
    uint256 public paymentIdTracker = 0;

    /// @dev loanPaymentMapping[loanId] => unit256[] list of payment IDs
    mapping(uint256 => uint256[]) public loanPaymentMapping;

    /// @notice convenient method to get the payment ids for a loan
    /// @param _loanId The loan id
    function paymentsByLoanId(uint256 _loanId) public view returns(uint256[] memory) {
        return loanPaymentMapping[_loanId];
    }

    /// @notice loan payment activities
    enum PaymentEvent {
        CREATED     // 0
    }

    /// @notice loan payment event
    event PaymentActivity(uint256 indexed paymentId, uint256 indexed loanId, PaymentEvent activity, uint256 amount, uint256 timestamp);

    modifier onlyServiceContractOrOwner() {
        address loanServicePaymentAddress = LoanOracle_I(getLoanOracleAddress()).getLoanServicePaymentAddress();
        require(
            msg.sender == loanServicePaymentAddress || msg.sender == owner(),
            "caller must be service contract or owner"
        );
        _;
    }

    /// @notice get a payment object by payment ID
    /// @param _paymentId The Payment ID
    function payments(uint256 _paymentId) public view returns(LoanCommon.Payment memory) {
        return paymentMapping[_paymentId];
    }

    /// @notice Make payment on a loan
    /// @param _payer The wallet address of the payer
    /// @param _loanId The ID of the loan
    /// @param _amount The amount to be applied to the loan
    function create(address _payer, uint256 _loanId, uint256 _amount) public onlyServiceContractOrOwner {
        paymentIdTracker++;
        paymentMapping[paymentIdTracker] = LoanCommon.Payment({
            paymentId: paymentIdTracker,
            loanId : _loanId,
            payer : _payer,
            amount : _amount,
            createdDate : block.timestamp
        });
        loanPaymentMapping[_loanId].push(paymentIdTracker);

        // Emit payment event
        emit PaymentActivity(paymentIdTracker, _loanId, PaymentEvent.CREATED, _amount, block.timestamp);
    }
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

    /// @notice Bid Status - the possible statuses of a bid
    enum OfferStatus {
        ACCEPTED,
        PENDING,
        DENIED
    }

    /// @notice The structure of a loan offer
    /// field offerId The primary key for the payment record
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
}

interface LoanStorageNftCollateral_I {
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

interface LoanServiceNftCollateral_I {
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

interface LoanStorageTreasury_I {
    function addFunds(address _recipient, uint256 _amount) external;
    function account(address _wallet) external view returns (uint256);
    function burnCollateralToken(uint256 _tokenId) external;
    function collateralToken() external returns (address);
    function collateralTokenSafeTransferFrom(address _to, uint256 _tokenId) external;
    function erc721safeTransferFrom(address _contract, address _from, address _to, uint256 _tokenId) external;
    function erc1155SafeTransferFrom(address _contract, address _from, address _to, uint256 _tokenId, uint256 _amount) external;
    function fractionalizeTokenSafeTransferFrom(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintCollateralToken() external returns (uint256);
    function mintFractionalizeToken(uint256 _supply) external returns (uint256);
    function profitAddress() external view returns (address);
    function transferFunds(address _from, address _to, uint256 _amount) external;
}

interface LoanServiceTreasury_I {
    function addFunds(address _recipient, uint256 _amount) external;
    function account(address _wallet) external view returns (uint256);
    function collateralTokenSafeTransferFrom(address _to, uint256 _tokenId) external;
    function fractionalizeTokenSafeTransferFrom(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintCollateralToken() external returns (uint256);
    function mintFractionalizeToken(uint256 _supply) external returns (uint256);
    function profitAddress() external view returns (address);
    function transferFunds(address _from, address _to, uint256 _amount) external;
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
    function precision() external view returns (uint256);
}

interface LoanStorageOffer_I {
    function offers(uint256 _offerId) external view returns(LoanCommon.Offer memory);
    function updateAcceptedAmount(uint256 _offerId, uint256 _acceptedAmount) external;
    function updateStatus(uint256 _offerId, LoanCommon.OfferStatus _status) external;
    function offersByLoanId(uint256 _loanId) external view returns(uint256[] memory);
    function create(address _lender, uint256 _loanId, uint256 _offeredAmount, uint256 _interest) external;
    function updateOffer(uint256 _offerId, uint256 _offeredAmount, uint256 _interest) external;
}

interface LoanServiceOffer_I {
    function offers(uint256 _offerId) external view returns(LoanCommon.Offer memory);
    function updateAcceptedAmount(uint256 _offerId, uint256 _acceptedAmount) external;
    function updateStatus(uint256 _offerId, LoanCommon.OfferStatus _status) external;
    function offersByLoanId(uint256 _loanId) external view returns(uint256[] memory);
}

interface LoanStoragePayment_I {
    function payments(uint256 _paymentId) external view returns(LoanCommon.Payment memory);
    function paymentsByLoanId(uint256 _loanId) external view returns(uint256[] memory);
    function create(address _payer, uint256 _loanId, uint256 _amount) external;
}

interface LoanStorageBid_I {
    function create(address _bidder, uint256 _loanId, uint256 _amount) external;
    function bids(uint256 _bidId) external view returns(LoanCommon.Bid memory);
    function bidsByLoanId(uint256 _loanId) external view returns(uint256[] memory);
}

interface LoanOracle_I {
    function getLoanCommonAddress() external view returns (address);
    function getLoanServiceAddress() external view returns (address);
    function getLoanServiceBidAddress() external view returns (address);
    function getLoanServiceExtensionAddress() external view returns (address);
    function getLoanServiceNftCollateralAddress() external view returns (address);
    function getLoanServiceOfferAddress() external view returns (address);
    function getLoanServicePaymentAddress() external view returns (address);
    function getLoanServiceTreasuryAddress() external view returns (address);
    function getLoanStorageAddress() external view returns (address);
    function getLoanStorageBidAddress() external view returns (address);
    function getLoanStorageNftCollateralAddress() external view returns (address);
    function getLoanStorageOfferAddress() external view returns (address);
    function getLoanStoragePaymentAddress() external view returns (address);
    function getLoanStorageTreasuryAddress() external view returns (address payable);
    function getLoanParametersAddress() external view returns (address);
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