/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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


// File contracts/LoanLibrary.sol

pragma solidity ^0.8.4;

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
    /// field calculatedApr The calculated APR of all the accepted bids
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
        uint256 calculatedApr;                  // 13
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
        uint256 apr;
        uint256 created;
        uint256 acceptedAmount;
        LoanBidStatus status;
    }

    /// The structure of a loan payment
    struct LoanPayment {
        address payer;
        uint256 loanId;
        uint256 amount;
        uint256 created;
    }

    /// @notice calculate yearly gross
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return amount + the year interest revenue
    function calculateYearlyGross(uint256 _amount, uint256 _apr, uint256 _precision) public pure returns (uint256) {
        return _amount + calculateYearlyInterestRevenue(_amount, _apr, _precision);
    }

    /// @notice calculate yearly interest revenue
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @return the year interest revenue
    function calculateYearlyInterestRevenue(uint256 _amount, uint256 _apr, uint256 _precision) public pure returns (uint256) {
        return _amount.mul(_apr).div(_precision);
    }

    /// @notice calculate interest revenue for number of days
    /// @param _amount The amount from a loan
    /// @param _apr The APR from a loan
    /// @param _precision The precision by with the apr is stored
    /// @param _days The number of days to calculate for interest earned
    /// @return the days interest revenue
    function calculateInterestRevenueForDays(uint256 _amount, uint256 _apr, uint256 _precision, uint256 _days) public pure returns (uint256) {
        uint256 yearlyInterestRevenue = calculateYearlyInterestRevenue(_amount, _apr, _precision);
        return yearlyInterestRevenue.mul(_days).div(365);
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
        require(_timestampBegin <= _timestampEnd, 'The begin timestamp must be less than the end timestamp');
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

    function libraryAddress() public view returns(address) {
        return address(this);
    }
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
    function setApprovalForAll(address _operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address _address);
}


// File contracts/LoanProvider.sol

pragma solidity ^0.8.4;

contract LoanProvider is Ownable {
    /// @dev loanBidMapping[loanBidId] => Bid
    mapping(uint256 => LoanLibrary.LoanBid) public loanBidMapping;

    /// @notice get a Loan Bid by the loanBid ID
    /// @param _loanBidId The bid ID
    function loanBids(uint256 _loanBidId) public view returns(LoanLibrary.LoanBid memory) {
        return loanBidMapping[_loanBidId];
    }

    /// Loan Bid tracking id
    uint256 public loanBidIdTracker = 0;

    /// @dev loanBidOfBorrower[borrowerAddress] => uint256[] loan bid IDs
    mapping(address => uint256[]) public loanBidsOfBorrower;

    /// @dev loanBidsOfLoan[loanId] => uint256[] loan bid ids
    mapping(uint256 => uint256[]) public loanBidsOfLoanMapping;

    /// @notice get a list of loan bid indexes by loan ID
    /// @param _loanId The Loan ID
    function loanBidsByLoanId(uint256 _loanId) public view returns(uint256[] memory) {
        return loanBidsOfLoanMapping[_loanId];
    }

    /// @notice get list of loan bids by loan ID
    /// @param _loanId the Loan ID
    function loanBidsOfLoan(uint256 _loanId) public view returns(LoanLibrary.LoanBid[] memory) {
        uint256[] memory loanBidIndexes = loanBidsOfLoanMapping[_loanId];
        LoanLibrary.LoanBid[] memory _loanBids = new LoanLibrary.LoanBid[](loanBidIndexes.length);
        for (uint256 i = 0; i < loanBidIndexes.length; i++) {
            LoanLibrary.LoanBid memory loanBid = loanBidMapping[loanBidIndexes[i]];
            _loanBids[i] = loanBid;
        }
        return _loanBids;
    }

    /// @notice Convenient method for getting loan bid ids for a loan
    /// @param _borrower The wallet of the borrower
    function loanBidsOfBorrowerValue(address _borrower) public view returns (uint256[] memory) {
        return loanBidsOfBorrower[_borrower];
    }

    /// Loan Bid created event
    event LoanBidCreated(uint256 loanBidId);

    address loanOrchestrator;

    constructor() {
    }

    function setLoanOrchestrator(address _loanOrchestrator) public onlyOwner {
        loanOrchestrator = _loanOrchestrator;
    }

    modifier onlyOrchestrator() {
        require(msg.sender == address(loanOrchestrator), "caller must be orchestrator");
        _;
    }


    /// @notice Create a bid
    /// @param _loanId The ID of the loan
    /// @param _offered The amount being offered
    /// @param _apr The offered APR of this bid
    function createLoanBid(
        LoanLibrary.Loan memory _loan,
        address _provider,
        uint256 _loanId,
        uint256 _offered,
        uint256 _apr) public {

        require(
            _loan.status == LoanLibrary.LoanStatus.RECRUITING,
            "Loan status must be in recruiting phase."
        );

        // Create Loan Bid
        loanBidIdTracker++;
        loanBidMapping[loanBidIdTracker] = LoanLibrary.LoanBid({
            loanBidId: loanBidIdTracker,
            loanId: _loanId,
            provider: _provider,
            offered: _offered,
            apr: _apr,
            created: block.timestamp,
            acceptedAmount: 0,
            status: LoanLibrary.LoanBidStatus.PENDING
        });

        // Add Loan Bid of owner
        loanBidsOfBorrower[msg.sender].push(loanBidIdTracker);

        // Add Loan Bid of the loan
        loanBidsOfLoanMapping[_loanId].push(loanBidIdTracker);

        // Emit Loan Bid Created
        emit LoanBidCreated(loanBidIdTracker);
    }

    /// @notice convenient method to set the loan bid status
    function updateLoanBidStatus(uint256 _loanBidId, LoanLibrary.LoanBidStatus _status) public onlyOrchestrator {
        LoanLibrary.LoanBid storage loanBid = loanBidMapping[_loanBidId];
        loanBid.status = _status;
    }

    /// @notice convenient method to update the loan bid accepted amount
    /// @param _value the new accepted amount
    function updateLoanBidAcceptedAmount(uint256 _loanBidId, uint256 _value) public onlyOrchestrator {
        LoanLibrary.LoanBid storage loanBid = loanBidMapping[_loanBidId];
        loanBid.acceptedAmount = _value;
    }
}