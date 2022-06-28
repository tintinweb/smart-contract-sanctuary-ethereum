// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LoanLibrary.sol";
import "./LoanParameters.sol";

contract LoanBorrower is Ownable {
    using SafeMath for uint256;

    /////////////////////
    /// LOANS
    /////////////////////

    /// @dev loans[loanId] => Loan
    mapping(uint256 => LoanLibrary.Loan) public loanMapping;

    /// @notice get a loan object by loan ID
    /// @param _loanId The Loan ID
    function loans(uint256 _loanId) public view returns(LoanLibrary.Loan memory) {
        return loanMapping[_loanId];
    }

    /// @notice Campaign tracking ID
    uint256 public loanIdTracker = 0;

    /// @dev loansOfBorrower[borrowerId] => uint256[] loan IDs
    mapping(address => uint256[]) public addressToLoanIdMapping;

    /// @notice Convenience method for getting loan ids for a borrower
    /// @param _ownerAddress The address of the loan owner
    /// @return a list of of loan IDs
    function loanIdsByAddress(address _ownerAddress) public view returns (uint256[] memory) {
        return addressToLoanIdMapping[_ownerAddress];
    }

    /// @notice Convenience method for getting a range of loans
    /// @param _start The starting index
    /// @param _end The ending index
    function loanList(uint256 _start, uint256 _end)
        public view returns(uint256[] memory _idList, LoanLibrary.Loan[] memory _loanList) {

        require(_end >= _start, "The end index must be greater than or equal to the start index");

        uint256[] memory workingIds = new uint256[](_end.sub(_start).add(1));
        LoanLibrary.Loan[] memory workingLoans = new LoanLibrary.Loan[](_end.sub(_start).add(1));

        uint256 index = 0;
        for (uint256 i = _start; i <= _end; i++) {
            workingIds[index] = i;
            workingLoans[index] = loanMapping[i];
            index++;
        }
        return(workingIds, workingLoans);
    }

    /// @notice Loan created event
    event LoanCampaignCreated(uint256 loanId);

    /////////////////////
    /// PAYMENTS
    /////////////////////

    /// @dev payments[paymentId] => LoanPayment
    mapping(uint256 => LoanLibrary.LoanPayment) public paymentMapping;

    /// @notice Payment tracking ID
    uint256 public paymentIdTracker = 0;

    /// @dev loanPaymentMapping[loanId] => unit256[] list of payment IDs
    mapping(uint256 => uint256[]) public loanPaymentMapping;

    /// @notice Loan payment event
    event LoanPayment(uint256 loanId, address payer, uint256 amount);

    event LoanOrchestratorChange(address orchestartorAddress);

    LoanParameters loanParameters;
    address loanOrchestrator;

    constructor(
        LoanParameters _loanParameters
    ) {
        loanParameters = _loanParameters;
    }

    function setLoanOrchestrator(address _loanOrchestrator) public onlyOwner {
        loanOrchestrator = _loanOrchestrator;
        emit LoanOrchestratorChange(_loanOrchestrator);
    }

    modifier onlyOrchestratorOrOwner() {
        require(
            msg.sender == address(loanOrchestrator) || msg.sender == owner(),
            "caller must be orchestrator or owner"
        );
        _;
    }

    /// @notice get payments that have been applied to a loan
    /// @param _loanId The Loan ID
    function loanPayments(uint256 _loanId) public view returns(LoanLibrary.LoanPayment[] memory) {
        uint256[] memory loanPaymentIndexes = loanPaymentMapping[_loanId];
        LoanLibrary.LoanPayment[] memory paymentList = new LoanLibrary.LoanPayment[](loanPaymentIndexes.length);
        for (uint256 i = 0; i < loanPaymentIndexes.length; i++) {
            uint256 index = loanPaymentIndexes[i];
            LoanLibrary.LoanPayment memory p = paymentMapping[index];
            paymentList[i] = p;
        }
        return paymentList;
    }

    /// @notice Create a loan campaign
    /// @param _borrower The address of the borrower
    /// @param _nftContracts A list of nft contracts
    /// @param _nftTokenIds A list of nft token IDs
    /// @param _nftTokenAmounts A list of token amounts
    /// @param _standards A list of token standards
    /// @param _nftEstimatedValue The borrower estimated value of the NFT
    /// @param _loanAmount The amount that the borrower would like to borrow
    /// @param _loanDuration The duration in days that the borrower would like the loan to last
    /// @param _description The description of the loan collateral
    function createLoanCampaign(
        address _borrower,
        address[] memory _nftContracts,
        uint256[] memory _nftTokenIds,
        uint256[] memory _nftTokenAmounts,
        LoanLibrary.Standard[] memory _standards,
        uint256 _nftEstimatedValue,
        uint256 _loanAmount,
        uint256 _loanDuration,
        string memory _description
    ) public {

        /////////////////////////////////////////
        // Reference TFL-0018
        /////////////////////////////////////////
        require (
            loanParameters.enabled(),
            "The ability to create new loan campaign is disabled"
        );

        /////////////////////////////////////////
        // Reference TFL-0013
        /////////////////////////////////////////
        require (
            _loanDuration >= loanParameters.minLoanDurationInDays(),
            "The loan duration must be >= to the minimum duration in days"
        );

        /////////////////////////////////////////
        // Reference TFL-0014
        /////////////////////////////////////////
        require (
            _loanDuration <= loanParameters.maxLoanDurationInDays(),
            "The loan duration must be less than or equal ot the maximum duration in days"
        );

        require(
            _nftContracts.length > 0,
            "At least one NFT contract is required"
        );
        require(
            _nftContracts.length == _nftTokenIds.length &&
            _nftContracts.length == _nftTokenAmounts.length &&
            _nftContracts.length == _standards.length,
            "the NFT arrays must be equal length"
        );

        /////////////////////////////////////////////
        // Reference TFL-0011
        /////////////////////////////////////////////
        require(
            _loanAmount >= LoanLibrary
            .calculatePercentage(
                _nftEstimatedValue,
                loanParameters.minLoanPercentageOfCollateral(),
                loanParameters.precision()
            ), "The loan amount must be >= to the minimum loan percentage of collateral"
        );

        /////////////////////////////////////////////
        // Reference TFL-0012
        /////////////////////////////////////////////
        require(
            _loanAmount <= LoanLibrary
            .calculatePercentage(
                _nftEstimatedValue,
                loanParameters.maxLoanPercentageOfCollateral(),
                loanParameters.precision()
            ), "The loan amount must be <= to the maximum loan percentage of collateral"
        );

        //////////////////
        // Create Campaign
        //////////////////
        loanIdTracker++;
        loanMapping[loanIdTracker] = LoanLibrary.Loan({
            nftHolder: _borrower,
            nftContracts: new address[](0),
            nftTokenIds: new uint256[](0),
            nftTokenAmounts: new uint256[](0),
            standards: new LoanLibrary.Standard[](0),
            nftEstimatedValue: _nftEstimatedValue,
            loanAmount: _loanAmount,
            loanDuration: _loanDuration,
            created: block.timestamp,
            loanStart: 0,
            fractionalizedTokenId: 0,
            status: LoanLibrary.LoanStatus.RECRUITING,
            loanCollateralNftTokenId: 0,
            calculatedInterest: 0,
            description: _description
        });

        for (uint i = 0; i < _nftContracts.length; i++) {
            loanMapping[loanIdTracker].nftContracts.push(_nftContracts[i]);
            loanMapping[loanIdTracker].nftTokenIds.push(_nftTokenIds[i]);
            loanMapping[loanIdTracker].nftTokenAmounts.push(_nftTokenAmounts[i]);
            loanMapping[loanIdTracker].standards.push(_standards[i]);
        }

        ////////////////////
        // Add Loan To Owner
        ////////////////////
        addressToLoanIdMapping[_borrower].push(loanIdTracker);

        emit LoanCampaignCreated(loanIdTracker);
    }

    /// @notice convenient method to update the loan status
    /// @param _loanId The Loan ID
    /// @param _status The new status of the loan
    function updateLoanStatus(uint256 _loanId, LoanLibrary.LoanStatus _status) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.status = _status;
    }

    /// @notice convenient method to update the loan loanStart
    /// @param _loanId The Loan ID
    /// @param _timestamp The timestamp
    /// @dev meant to be set when loan is activated
    function updateLoanStart(uint256 _loanId, uint256 _timestamp) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.loanStart = _timestamp;
    }

    /// @notice convenient method to update the nft token id
    /// @param _loanId The Loan ID
    /// @param _loanNftTokenId The token id to be set
    /// @dev meant to be set when the loan is activated and a loaf nft is created
    function updateLoanNftTokenId(uint256 _loanId, uint256 _loanNftTokenId) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.loanCollateralNftTokenId = _loanNftTokenId;
    }

    /// @notice convenient method to update the calculated apr
    /// @param _loanId The Loan ID
    /// @param _calculatedApr The calculated APR
    function updateCalculatedApr(uint256 _loanId, uint256 _calculatedApr) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.calculatedInterest = _calculatedApr;
    }

    /// @notice calculate the interest to date on the loan
    /// @param _loanId The Loan ID
    /// @return The actual interest rate
    function calculateActualInterestToDate(uint256 _loanId) public view returns (uint256) {
        LoanLibrary.Loan memory loan = loans(_loanId);

        uint256 currentDayOfTheLoan = LoanLibrary.calculateDurationInDays(loan.loanStart, block.timestamp);

        return LoanLibrary.calculateInterestYieldForDays(
            loan.loanAmount,
            loan.calculatedInterest,
            loan.loanDuration,
            currentDayOfTheLoan,
            loanParameters.precision()
        );
    }

    /// @notice convenient method to get the loan payoff amount
    /// @param _loanId The loan ID
    /// @return The calculated payoff amount
    function payoffAmount(uint256 _loanId) public view returns (uint256) {
        LoanLibrary.Loan memory loan = loans(_loanId);

        uint256 interestMinLoanDuration = LoanLibrary.calculateInterestYieldForDays(
            loan.loanAmount,
            loan.calculatedInterest,
            loan.loanDuration,
            loanParameters.minLoanDurationInDays(),
            loanParameters.precision()
        );

        // ######################################
        // Reference TFL-0015
        // ######################################
        uint256 minDurationPenaltyInterest = LoanLibrary.calculateInterestYieldForDays(
            loan.loanAmount,
            loanParameters.minPercentOfDurationForInterest(),
            loan.loanDuration,
            loan.loanDuration,
            loanParameters.precision()
        );

        uint256 actualDurationInterest = calculateActualInterestToDate(_loanId);
        uint256 minimumLoanDurationAmount = interestMinLoanDuration + loan.loanAmount;
        uint256 minDurationPenaltyAmount = minDurationPenaltyInterest + loan.loanAmount;
        uint256 actualDurationAmount = actualDurationInterest + loan.loanAmount;

        uint256 actualAmount = loan.loanAmount;

        if ( minimumLoanDurationAmount >= minDurationPenaltyAmount &&
            minimumLoanDurationAmount >= actualDurationAmount)
        {
            /// The minimumLoanDurationAmount was found to be the highest value
            actualAmount = minimumLoanDurationAmount;
        } else if ( minDurationPenaltyAmount >= minimumLoanDurationAmount &&
            minDurationPenaltyAmount >= actualDurationAmount)
        {
            /// The minDurationPenaltyAmount was found to be the highest value
            actualAmount = minDurationPenaltyAmount;
        } else if ( actualDurationAmount >= minimumLoanDurationAmount &&
            actualDurationAmount >= minDurationPenaltyAmount)
        {
            /// The minDurationPenaltyAmount was found to be the highest value
            actualAmount = actualDurationAmount;
        }

        // Subtract payments from amounts
        LoanLibrary.LoanPayment[] memory payments = loanPayments(_loanId);
        for (uint256 i = 0; i < payments.length; i++) {
            actualAmount = actualAmount.sub(payments[i].amount);
        }

        return actualAmount;
    }

    /// @notice Make payment on a loan
    /// @param _loanId The ID of the loan
    /// @param _amount The amount to be applied to the loan
    function makePayment(uint256 _loanId, uint256 _amount) public onlyOwner {
        LoanLibrary.Loan memory loan = loans(_loanId);
        require(
            loan.status == LoanLibrary.LoanStatus.ACTIVE,
            "Loan must be in an active status"
        );

        /// #####################################
        /// reference TFL-0019
        /// #####################################
        require(
            !isLoanInDefault(_loanId), "Payments cannot be made against a loan in default"
        );

        uint256 payOffAmount = payoffAmount(_loanId);
        bool payingInFull = _amount == payOffAmount;

        paymentIdTracker++;
        paymentMapping[paymentIdTracker] = LoanLibrary.LoanPayment({
            paymentId: paymentIdTracker,
            loanId : _loanId,
            payer : msg.sender,
            amount : _amount,
            created : block.timestamp
        });

        loanPaymentMapping[_loanId].push(paymentIdTracker);
        if (payingInFull) {
            updateLoanStatus(_loanId, LoanLibrary.LoanStatus.PAID);
        }

        // Emit payment event
        emit LoanPayment(_loanId, msg.sender, _amount);

    }

    /// @notice Get the remaining principle on a loan
    /// @param _loanId The ID of the loan
    function remainingPrinciple(uint256 _loanId) public view returns (uint256) {
        LoanLibrary.Loan memory loan = loans(_loanId);

        // Check if payment is paying in full early
        uint256 actualAmount = loan.loanAmount;

        // Subtract payments from amounts
        LoanLibrary.LoanPayment[] memory payments = loanPayments(_loanId);
        for (uint256 i = 0; i < payments.length; i++) {
            actualAmount = actualAmount.sub(payments[i].amount);
        }

        return actualAmount;
    }

    /// @notice calculate if loan is in default
    /// @param _loanId The Loan ID
    /// @return true if loan is defaulted
    function isLoanInDefault(uint256 _loanId) public view returns (bool) {
        // ######################################
        // reference TLF-0019
        // ######################################
        LoanLibrary.Loan memory loan = loans(_loanId);
        uint256 currentDurationOfLoan = LoanLibrary.calculateDurationInDays(loan.loanStart, block.timestamp);
        return currentDurationOfLoan > LoanLibrary.periodInDays(
            loan.loanDuration
        ).add(
            LoanLibrary.periodInMinutes(loanParameters.loanDefaultGracePeriodInMinutes())
        );
    }

    /// @notice get the number of days until the loan is in a default status
    /// @param _loanId The Loan ID
    /// @return number of day left on the loan
    function numberOfDaysLeftOnLoan(uint256 _loanId) public view returns (uint256) {
        LoanLibrary.Loan memory loan = loans(_loanId);
        uint256 currentDurationOfLoan = LoanLibrary.calculateDurationInDays(loan.loanStart, block.timestamp).sub(1);
        return loan.loanDuration.sub(currentDurationOfLoan);
    }

    /// @notice cancel a loan that is current in recruiting phase
    /// @param _loanId The loan id
    function cancelLoan(uint256 _loanId) public {
        LoanLibrary.Loan memory loan = loans(_loanId);
        require(loan.nftHolder == msg.sender, "NFT Holder must be the one cancelling the loan");
        require(loan.status == LoanLibrary.LoanStatus.RECRUITING, "Loan must be in recruiting status");
        updateLoanStatus(_loanId, LoanLibrary.LoanStatus.CANCELLED);
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LoanLibrary {
    using SafeMath for uint256;

    /// Supported NFT Standard
    enum Standard {
        ERC721,
        ERC1155
    }

    /// Loan Status
    enum LoanStatus {
        ACTIVE,
        CANCELLED,
        DEFAULTED,
        LIQUIDATED,
        PAID,
        RECRUITING,
        SOLD
    }

    /// Loan structure
    /// developer note might be able to put some of these fields in IPFS to save gas
    /// field nftHolder The borrower address, holds the NFTs that is being borrowed against
    /// field nftContracts list of NFT contracts collateral that are part of the loan
    /// field nftTokenIds list of NFT tokenIds collateral that are part of the loan
    /// field nftTokenAmounts list of NFT tokenAmounts collateral that are part of the loan - typically should only be 1
    /// field standards list of NFT standards collateral that are part of the loan
    /// field nftEstimatedValue the estimated value of the NFTs put forth by the borrower
    /// field loanAmount The loan amount that is being asked for
    /// field loanDuration The loan duration that is being asked for
    /// field created The creation timestamp when the loan is created
    /// field loanStart The start timestamp when the loan is activated
    /// field fractionalizedTokenId The tokenId of the 1155 minted token distributed to the loan providers
    /// field status The status of the loan
    /// field loanNftCollateralTokenId The LoanCollateral tokenID created to represent the loan and distributed to the borrower
    /// field calculatedInterest The calculated APR of all the accepted bids
    /// field description The description of the loan collateral
    struct Loan {
        address nftHolder;                      // 0
        address[] nftContracts;                 // 1
        uint256[] nftTokenIds;                  // 2
        uint256[] nftTokenAmounts;              // 3
        Standard[] standards;                   // 4
        uint256 nftEstimatedValue;              // 5
        uint256 loanAmount;                     // 6
        uint256 loanDuration;                   // 7
        uint256 created;                        // 8
        uint256 loanStart;                      // 9
        uint256 fractionalizedTokenId;          // 10
        LoanStatus status;                      // 11
        uint256 loanCollateralNftTokenId;       // 12
        uint256 calculatedInterest;             // 13
        string description;                     // 14
    }

    /// Bid Status - the possible statuses of a bid
    enum LoanBidStatus {
        ACCEPTED,
        PENDING,
        DENIED
    }

    /// Provider Loan Bid Structure
    struct LoanBid {
        uint256 loanBidId;
        uint256 loanId;
        address provider;
        uint256 offered;
        uint256 interest;
        uint256 created;
        uint256 acceptedAmount;
        LoanBidStatus status;
    }

    /// The structure of a loan payment
    struct LoanPayment {
        uint256 paymentId;
        address payer;
        uint256 loanId;
        uint256 amount;
        uint256 created;
    }

    /// @notice calculate yearly gross
    /// @param _amount The amount from a loan
    /// @param _interest The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return amount + the year interest revenue
    function calculateGrossYield(uint256 _amount, uint256 _interest, uint256 _precision) public pure returns (uint256) {
        return _amount + calculateInterestYield(_amount, _interest, _precision);
    }

    /// @notice calculate interest revenue
    /// @param _amount The amount from a loan
    /// @param _interest The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return the interest revenue
    function calculateInterestYield(uint256 _amount, uint256 _interest, uint256 _precision) public pure returns (uint256) {
        return _amount.mul(_interest).div(_precision);
    }

    /// @notice calculate interest yield for number of days
    /// @param _amount The amount from a loan
    /// @param _interest The APR from a loan
    /// @param _duration The duration that interest is calculated
    /// @param _days The number of days to calculate for interest earned
    /// @param _precision The precision by with the apr is stored
    /// @return the days interest yield
    function calculateInterestYieldForDays(
        uint256 _amount,
        uint256 _interest,
        uint256 _duration,
        uint256 _days,
        uint256 _precision
    ) public pure returns (uint256) {
        uint256 singleDayRate = _amount.mul(_interest).div(_duration.mul(_precision));
        return singleDayRate.mul(_days);
    }

    /// @notice calculate the percentage of an amount
    /// @dev (_amount * _percent) / _factor
    function calculatePercentage(uint256 _amount, uint256 _percent, uint256 _precision) public pure returns (uint256) {
        return _amount.mul(_percent).div(_precision);
    }

    /// @notice calculate the number of day between two timestamps
    /// @param _timestampBegin the beginning timestamp
    /// @param _timestampEnd the ending timestamp
    /// @return the number of days between the two timestamps
    /// @dev business logic dictates that point 0 is day 1
    function calculateDurationInDays(uint256 _timestampBegin, uint256 _timestampEnd) public pure returns (uint256) {
        require(_timestampBegin <= _timestampEnd, "The begin timestamp must be less than the end timestamp");
        uint256 day = 60 * 60 * 24;
        return _timestampEnd.sub(_timestampBegin).div(day) + 1;
    }

    /// @notice get the number of seconds for a period in days
    /// @param _period The period amount
    /// @return number of seconds in days for a given period
    function periodInDays(uint256 _period) public pure returns (uint256) {
        return _period.mul(60 * 60 * 24);
    }

    /// @notice get the number of seconds for a period in minutes
    /// @param _period The period amount
    /// @return number of seconds in minutes for a given period
    function periodInMinutes(uint256 _period) public pure returns (uint256) {
        return _period.mul(60 * 60);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

interface Provider_I {
    function loanBids(uint256 _loanBidId) external view returns(LoanLibrary.LoanBid memory);
    function loanBidIdTracker() external view returns(uint256);
    function updateLoanBidAcceptedAmount(uint256 _loanBidId, uint256 _value) external;
    function updateLoanBidStatus(uint256 _loanBidId, LoanLibrary.LoanBidStatus _status) external;
    function loanBidsByLoanId(uint256 _loanId) external view returns(uint256[] memory);
}

interface Borrower_I {
    function loans(uint256 _loanId) external view returns(LoanLibrary.Loan memory);
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LoanParameters is Ownable {

    /// @notice The precision at which we store decimals. A precision of 10000 allows storage of 10.55% as 1055
    /// @dev The higher the number the more precise the calculated values. Since we are using this to store apr
    ///      the value should be read only as making it writable would break the math of pre existing loans
    uint256 public precision = 10000;

    /// @notice The total supply of the fractionalized loan. Fractions are then distributed to Loan Provider based on
    ///         the amount of eth loan and the apr averaged across all accepted providers for that loan.
    uint256 public fractionalizeSupply = 10000;

    /// @notice The minimum percent a borrower can either select or accept to determine the principal amount of the loan.
    uint256 public minLoanPercentageOfCollateral = 2000;

    /// @notice The maximum percent a borrower can either select or accept to determine the principal amount of the loan.
    uint256 public maxLoanPercentageOfCollateral = 6000;

    /// @notice The minimum number of days a loan is allowed to be taken out for.
    uint256 public minLoanDurationInDays = 7;

    /// @notice The maximum number of days a loan is allowed to be taken out for. If set to 0, no upper limit.
    uint256 public maxLoanDurationInDays = 365;

    /// @notice When a loan is ended (paid in full) prior to the scheduled end date, interest owed is only calculated
    ///         on the actual duration of the loan, not the originally selected loan duration. However, if the loan is
    ///         paid too early, this presents a situation where the loan providers could actually lose money on this
    ///         loan. Therefore this value represents the minimum percentage of the estimated duration that interest
    ///         must be paid by the borrower. The borrower may be required to pay more, this is the minimum. NOTE:
    ///         When interest is calculated on a loan paid back early, the actual interest owed is determined by which
    ///         value is larger when using these values for the duration: minLoanDurationInDays,
    ///         minPercentOfDurationForInterest * requestedLoanDuration, actualLoanDuration.
    uint256 public minPercentOfDurationForInterest = 4000;

    /// @notice This is the fee that a borrower is required to pay as part of starting the campaign. This is calculated
    ///         as a percentage of the estimatedCollateralValue.
    uint256 public loanPostingFeePercent = 100;

    /// @notice This is the fee that a borrower pays at the time they start the loan, making the loan active. This is
    ///         calculated as a percentage of the estimatedCollateralValue.
    uint256 public loanProcessingFeePercent = 100;

    /// @notice This tells the contract if it can be used to create new loan campaigns. Setting this to false, would
    ///         render the create campaign capability.
    bool public enabled = true;

    /// @notice This is the amount of days after the loan period has elapsed before the loan officially defaults.
    uint256 public loanDefaultGracePeriodInMinutes = 30;

    /// @notice set the fractionalize supply
    /// @param _value the new fractional supply value
    function setFractionalizeSupply(uint256 _value) public onlyOwner {
        fractionalizeSupply = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0011
    /////////////////////////////////////////////

    /// @notice set the minLoanPercentageOfCollateral
    /// @param _value the new minLoanPercentageOfCollateral value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMinLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        minLoanPercentageOfCollateral = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0012
    /////////////////////////////////////////////

    /// @notice set the maxLoanPercentageOfCollateral
    /// @param _value the new maxLoanPercentageOfCollateral value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMaxLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        maxLoanPercentageOfCollateral = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0013
    /////////////////////////////////////////////

    /// @notice set the minLoanDurationInDays
    /// @param _value the new minLoanDurationInDays value
    function setMinLoanDurationInDays(uint256 _value) public onlyOwner {
        minLoanDurationInDays = _value;
    }

    /////////////////////////////////////////////
    // Reference TFL-0014
    /////////////////////////////////////////////

    /// @notice set the maxLoanDurationInDays
    /// @param _value the new maxLoanDurationInDays value
    function setMaxLoanDurationInDays(uint256 _value) public onlyOwner {
        maxLoanDurationInDays = _value;
    }

    /// @notice set the setMinPercentOfDurationForInterest
    /// @param _value the new setMinPercentOfDurationForInterest value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setMinPercentOfDurationForInterest(uint256 _value) public onlyOwner {
        minPercentOfDurationForInterest = _value;
    }

    /// @notice set the setLoanPostingFeePercent
    /// @param _value the new setLoanPostingFeePercent value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setLoanPostingFeePercent(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // Reference TFL-0016
        /////////////////////////////////////////
        loanPostingFeePercent = _value;
    }

    /// @notice set the setLoanProcessingFeePercent
    /// @param _value the new setLoanProcessingFeePercent value
    /// @dev this value is stored by a factor of 100 i.e .25 is stored as 25
    function setLoanProcessingFeePercent(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0017
        /////////////////////////////////////////
        loanProcessingFeePercent = _value;
    }

    /// @notice set the enabled
    /// @param _value the new enabled value
    function setEnabled(bool _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0018
        /////////////////////////////////////////
        enabled = _value;
    }

    /// @notice set the loanDefaultGracePeriodInMinutes
    /// @param _value the new loanDefaultGracePeriodInMinutes value
    function setLoanDefaultGracePeriodInMinutes(uint256 _value) public onlyOwner {
        /////////////////////////////////////////
        // TFL-0019
        /////////////////////////////////////////
        loanDefaultGracePeriodInMinutes = _value;
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