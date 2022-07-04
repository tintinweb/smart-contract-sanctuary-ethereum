// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LoanParameters.sol";
import "./LoanBorrower.sol";
import "./LoanProvider.sol";
import "./LoanTreasury.sol";
import "./LoanOrchestrator.sol";
import "./LoanLibrary.sol";
import "./LoanAuction.sol";

import "hardhat/console.sol";

contract LoanArbiter is Ownable {
    using SafeMath for uint256;

    address public loanLibraryAddress;
    address public loanProviderAddress;
    address public loanBorrowerAddress;
    address payable public loanTreasuryAddress;
    address public loanOrchestratorAddress;
    address public loanAuctionAddress;
    address public loanParametersAddress;

    LoanBorrower loanBorrower;
    LoanProvider loanProvider;
    LoanTreasury loanTreasury;
    LoanOrchestrator loanOrchestrator;
    LoanParameters loanParameters;
    LoanAuction loanAuction;

    /// @notice set the parameters contract address and initialize contract
    /// @param _loanParametersAddress The parameters contract address
    function setParameterAddress(address _loanParametersAddress) public onlyOwner {
        loanParameters = LoanParameters(_loanParametersAddress);
        loanParametersAddress = _loanParametersAddress;
    }

    /// @notice set the loan provider contract address and initialize contract
    /// @param _loanProviderAddress the loan provider contract address
    function setProviderAddress(address _loanProviderAddress) public onlyOwner {
        loanProvider = LoanProvider(_loanProviderAddress);
        loanProviderAddress = _loanProviderAddress;
    }

    /// @notice set the loan borrower contract address and initialize contract
    /// @param _loanBorrowerAddress the loan borrower contract address
    function setBorrowerAddress(address _loanBorrowerAddress) public onlyOwner {
        loanBorrower = LoanBorrower(_loanBorrowerAddress);
        loanBorrowerAddress = _loanBorrowerAddress;
    }

    /// @notice set the loan treasury contract address and initialize contract
    /// @param _loanTreasuryAddress the loan treasury contract address
    function setTreasuryAddress(address payable _loanTreasuryAddress) public onlyOwner {
        loanTreasury = LoanTreasury(_loanTreasuryAddress);
        loanTreasuryAddress = _loanTreasuryAddress;
    }

    /// @notice set the loan orchestrator contract address and initialize the contract
    /// @param _loanOrchestratorAddress the loan orchestrator contract address
    function setOrchestrationAddress(address payable _loanOrchestratorAddress) public onlyOwner {
        loanOrchestrator = LoanOrchestrator(_loanOrchestratorAddress);
        loanOrchestratorAddress = _loanOrchestratorAddress;
    }

    /// @notice set the auction contract address and initialize the contract
    /// @param _loanAuctionAddress the loan auction contract address
    function setAuctionAddress(address payable _loanAuctionAddress) public onlyOwner {
        loanAuction = LoanAuction(_loanAuctionAddress);
        loanAuctionAddress = _loanAuctionAddress;
    }

    /// @notice a modifier to put in constraints where only the orchestrator can invoke certain methods
    modifier onlyOrchestrator() {
        require(msg.sender == address(loanOrchestrator), "caller must be orchestrator");
        _;
    }

    /// @notice Create a loan campaign
    /// @param _nftContracts a list of nft contracts
    /// @param _nftTokenIds a list of nft token IDs
    /// @param _nftTokenAmounts a list of token amounts
    /// @param _standards a list of token standards
    /// @param _nftEstimatedValue the borrower estimated value of the NFT
    /// @param _loanAmount the amount that the borrower would like to borrow
    /// @param _loanDuration the duration in days that the borrower would like the loan to last
    /// @param _description The description of the loan collateral
    function createLoanCampaign(
        address[] memory _nftContracts,
        uint256[] memory _nftTokenIds,
        uint256[] memory _nftTokenAmounts,
        LoanLibrary.Standard[] memory _standards,
        uint256 _nftEstimatedValue,
        uint256 _loanAmount,
        uint256 _loanDuration,
        string memory _description
    ) public payable {
        /////////////////////////////////////////
        // reference TFL-0016
        /////////////////////////////////////////
        uint256 amount = calculateCreateLoanCampaignFee(_nftEstimatedValue);

        require(msg.value == amount, string.concat("Payment amount is off ", LoanLibrary.uint256ToString(amount)));

        /// #########################################
        /// TFL-0001 TFL-0002, TFL-0003, TFL-0004,
        /// TFL-0005 TFL-0006, TFL-0010, TFL-0007
        /// #########################################
        loanBorrower.createLoanCampaign(
            msg.sender,
            _nftContracts,
            _nftTokenIds,
            _nftTokenAmounts,
            _standards,
            _nftEstimatedValue,
            _loanAmount,
            _loanDuration,
            _description
        );

        address profitAddress = loanTreasury.profitAddress();
        loanTreasuryAddress.transfer(msg.value);
        loanTreasury.addFunds(profitAddress, msg.value);
    }

    function calculateCreateLoanCampaignFee(uint256 estimatedValue) public view returns(uint256) {
        return estimatedValue.mul(loanParameters.loanPostingFeePercent()).div(loanParameters.precision());
    }

    /// @notice Get the contract address of the fractionalize contract 1155
    /// @return the address of the fractionalize 1155 contract
    function fractionalizeContractAddress() public view returns (address) {
        return loanTreasury.getFractionalizeContractAddress();
    }

    /// @notice Get the contract address of the loanCollateralToken contract 721
    /// @return the address of the loan collateral 721 contract
    function loanCollateralTokenAddress() public view returns (address) {
        return loanTreasury.getLoanCollateralTokenAddress();
    }

    /// @notice Create a loan bid
    /// @param _loanId The ID of the loan
    /// @param _offered The amount being offered
    /// @param _interest The offered interest of this loan bid
    function createLoanBid(
        uint256 _loanId,
        uint256 _offered,
        uint256 _interest
    ) public payable {

        loanProvider.createLoanBid(
            _loanId,
            msg.sender,
            _offered,
            _interest
        );

        loanTreasuryAddress.transfer(msg.value);
        loanTreasury.addFunds(msg.sender, msg.value);
    }

    /// @notice Make payment on a loan
    /// @param _loanId The ID of the loan
    function makePayment(uint256 _loanId, address payable _loanTreasuryAddress) public payable {
        require(
            _loanTreasuryAddress == address(loanTreasury),
            "passed in treasury address must be the same as the treasure address"
        );

        loanBorrower.makePayment(_loanId, msg.value);
        _loanTreasuryAddress.transfer(msg.value);
    }

    /// @notice set the minimum loan percentage of collateral
    /// @dev pass through to loanParameters.setMinLoanPercentageOfCollateral(uint256)
    function setMinLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        loanParameters.setMinLoanPercentageOfCollateral(_value);
    }

    /// @notice set the maximum loan percentage of collateral
    /// @dev pass through to loanParameters.setMaxLoanPercentageOfCollateral(uint256)
    function setMaxLoanPercentageOfCollateral(uint256 _value) public onlyOwner {
        loanParameters.setMaxLoanPercentageOfCollateral(_value);
    }

    /// @notice set the minimum loan duration in days
    /// @dev pass through to loanParameters.setMinLoanDurationInDays
    function setMinLoanDurationInDays(uint256 _value) public onlyOwner {
        //////////////////////////////////////////////
        // TFL-0013
        //////////////////////////////////////////////
        loanParameters.setMinLoanDurationInDays(_value);
    }

    /// @notice set the maximum loan duration in days
    /// @dev pass through to loanParameters.setMaxLoanDurationInDays
    function setMaxLoanDurationInDays(uint256 _value) public onlyOwner {
        //////////////////////////////////////////////
        // TFL-0014
        //////////////////////////////////////////////
        loanParameters.setMaxLoanDurationInDays(_value);
    }

    /// @notice set the enabled flag for creating loan campaigns
    /// @dev pass through to loanParameters.setEnabled(bool)
    function setEnabled(bool _value) public onlyOwner {
        loanParameters.setEnabled(_value);
    }

    /// @notice set the minimum percent of duration for interest
    /// @dev pass through to loanParameters.setMinPercentOfDurationForInterest(bool)
    function setMinPercentOfDurationForInterest(uint256 _value) public onlyOwner {
        loanParameters.setMinPercentOfDurationForInterest(_value);
    }

    /// @notice allow the collateral token holder to claim the NFT
    function claimNft(uint256 _loanId) public {
        loanTreasury.claimNft(loanBorrower.loans(_loanId), msg.sender);
    }

    /// @notice allow for the transfer of funds owned by the loan treasury
    /// @param _to the address to transfer to
    /// @param _amount the amount to transfer
    function transferFunds(address _to, uint256 _amount) public onlyOwner {
        loanTreasury.transferFunds(address(loanTreasury), _to, _amount);
    }

    /// @notice set the loan library address
    /// @dev this method is called when the contract is created
    /// @param _loanLibraryAddress the Loan Library address
    function setLoanLibraryAddress(address _loanLibraryAddress) public onlyOwner {
        loanLibraryAddress = _loanLibraryAddress;
    }

    /// @notice set the loan posting fee
    /// @param _value the new value for the loan posting fee
    function setLoanPostingFeePercent(uint256 _value) public onlyOwner {
        loanParameters.setLoanPostingFeePercent(_value);
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

    /////////////////////
    /// PAYMENTS
    /////////////////////

    /// @dev payments[paymentId] => LoanPayment
    mapping(uint256 => LoanLibrary.LoanPayment) public paymentMapping;

    /// @notice Payment tracking ID
    uint256 public paymentIdTracker = 0;

    /// @dev loanPaymentMapping[loanId] => unit256[] list of payment IDs
    mapping(uint256 => uint256[]) public loanPaymentMapping;

    /////////////////////
    /// EVENTS
    /////////////////////

    /// @notice loan borrower activities
    enum BorrowerEvent {
        LOAN_CREATED,
        LOAN_UPDATED,
        LOAN_CANCELLED,
        LOAN_PAYMENT
    }

    /// @notice loan borrower event
    event BorrowerActivity(uint256 indexed loanId, BorrowerEvent activity, uint256 timestamp);

    /// @notice Loan Orchestrator Address has changed
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

        emit BorrowerActivity(loanIdTracker, BorrowerEvent.LOAN_CREATED, block.timestamp);
    }

    /// @notice convenient method to update the loan status
    /// @param _loanId The Loan ID
    /// @param _status The new status of the loan
    function updateLoanStatus(uint256 _loanId, LoanLibrary.LoanStatus _status) public {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];

        require(
            msg.sender == address(loanOrchestrator) || msg.sender == owner() || loan.nftHolder == msg.sender,
            "caller must be loan holder, orchestrator or owner"
        );

        loan.status = _status;

        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_UPDATED, block.timestamp);
    }

    /// @notice convenient method to update the loan loanStart
    /// @param _loanId The Loan ID
    /// @param _timestamp The timestamp
    /// @dev meant to be set when loan is activated
    function updateLoanStart(uint256 _loanId, uint256 _timestamp) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.loanStart = _timestamp;
        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_UPDATED, block.timestamp);
    }

    /// @notice convenient method to update the nft token id
    /// @param _loanId The Loan ID
    /// @param _loanNftTokenId The token id to be set
    /// @dev meant to be set when the loan is activated and a loaf nft is created
    function updateLoanNftTokenId(uint256 _loanId, uint256 _loanNftTokenId) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.loanCollateralNftTokenId = _loanNftTokenId;
        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_UPDATED, block.timestamp);
    }

    /// @notice convenient method to update the calculated apr
    /// @param _loanId The Loan ID
    /// @param _calculatedApr The calculated APR
    function updateCalculatedInterest(uint256 _loanId, uint256 _calculatedApr) public onlyOrchestratorOrOwner {
        LoanLibrary.Loan storage loan = loanMapping[_loanId];
        loan.calculatedInterest = _calculatedApr;
        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_UPDATED, block.timestamp);
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

        uint256 originalPayoff = loan.loanAmount.add(loan.loanAmount.mul(loan.calculatedInterest).div(loanParameters.precision()));

        // Subtract payments from amounts
        LoanLibrary.LoanPayment[] memory payments = loanPayments(_loanId);
        for (uint256 i = 0; i < payments.length; i++) {
            originalPayoff = originalPayoff.sub(payments[i].amount);
        }

        return originalPayoff;
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
        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_PAYMENT, block.timestamp);
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
        emit BorrowerActivity(_loanId, BorrowerEvent.LOAN_CANCELLED, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./LoanLibrary.sol";
import "./LoanBorrower.sol";

//import "hardhat/console.sol";

contract LoanProvider is Ownable {
    using SafeMath for uint256;

    /// @dev loanBidMapping[loanBidId] => Bid
    mapping(uint256 => LoanLibrary.LoanBid) public loanBidMapping;

    /// @notice get a Loan Bid by the loanBid ID
    /// @param _loanBidId The bid ID
    function loanBids(uint256 _loanBidId) public view returns(LoanLibrary.LoanBid memory) {
        return loanBidMapping[_loanBidId];
    }

    /// Loan Bid tracking id
    uint256 public loanBidIdTracker = 0;

    /// @dev loanBidOfBorrower[providerAddress] => uint256[] loan bid IDs
    mapping(address => uint256[]) public providerLoanBids;

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

    /// @notice get list of loan bids by provider
    /// @param _provider the address of the provider
    /// @param _start The starting index
    /// @param _end The ending index
    function loanBidsOfProvider(address _provider, uint256 _start, uint256 _end) public view returns(LoanLibrary.LoanBid[] memory) {
        require(_end >= _start, "The end index must be greater than or equal to the start index");
        LoanLibrary.LoanBid[] memory _loanBids = new LoanLibrary.LoanBid[](_end.sub(_start).add(1));

        uint256[] memory loanBidIndexes = providerLoanBids[_provider];

        uint256 index = 0;
        for (uint256 i = _start; i <= _end; i++) {
            _loanBids[index] = loanBidMapping[loanBidIndexes[i]];
            index++;
        }

        return _loanBids;
    }

    /// @notice The number of loan bids created by the provider
    /// @param _provider The provider address
    function loanBidsOfProviderTotal(address _provider) public view returns (uint256) {
        return providerLoanBids[_provider].length;
    }

    /// @notice Convenient method for getting loan bid ids for a provider
    /// @param _provider The wallet of the provider
    function loanBidsOfProviderValue(address _provider) public view returns (uint256[] memory) {
        return providerLoanBids[_provider];
    }

    /// @notice loan borrower activities
    enum ProviderEvent {
        BID_CREATED,
        BID_UPDATED
    }

    /// @notice loan borrower event
    event ProviderActivity(uint256 indexed loanBidId, ProviderEvent activity, uint256 timestamp);

    /// @notice Loan Bid updated event
    event LoanBidUpdated(uint256 loandBidId, uint256 offered, uint256 interest);

    /// @notice the address of the loan orchestrator contract
    address public loanOrchestrator;


    /// @notice setter for the loan orchestrator
    /// @param _loanOrchestrator the loan orchestrator contract address
    function setLoanOrchestrator(address _loanOrchestrator) public onlyOwner {
        loanOrchestrator = _loanOrchestrator;
    }

    /// @notice the address of the loan borrower contract
    address public loanBorrower;

    /// @notice setter for the loan borrower contract address
    /// @param _loanBorrower the loan borrower contract address
    function setLoanBorrower(address _loanBorrower) public onlyOwner {
        loanBorrower = _loanBorrower;
    }

    /// @notice modifier for only orchestrator
    modifier onlyOrchestrator() {
        require(msg.sender == address(loanOrchestrator), "caller must be orchestrator");
        _;
    }

    /// @notice Create a bid
    /// @param _loanId The ID of the loan
    /// @param _provider The loan provider
    /// @param _offered The amount being offered
    /// @param _interest The offered APR of this bid
    function createLoanBid(
        uint256 _loanId,
        address _provider,
        uint256 _offered,
        uint256 _interest) public onlyOwner {

        LoanLibrary.Loan memory loan = Borrower_I(loanBorrower).loans(_loanId);

        require(
            loan.status == LoanLibrary.LoanStatus.RECRUITING,
            "Loan status must be in recruiting phase."
        );

        // Create Loan Bid
        loanBidIdTracker++;
        loanBidMapping[loanBidIdTracker] = LoanLibrary.LoanBid({
            loanBidId: loanBidIdTracker,
            loanId: _loanId,
            provider: _provider,
            offered: _offered,
            interest: _interest,
            created: block.timestamp,
            acceptedAmount: 0,
            status: LoanLibrary.LoanBidStatus.PENDING
        });

        // Add Loan Bid of provider
        providerLoanBids[_provider].push(loanBidIdTracker);

        // Add Loan Bid of the loan
        loanBidsOfLoanMapping[_loanId].push(loanBidIdTracker);

        // Emit Loan Bid Created
        emit ProviderActivity(loanBidIdTracker, ProviderEvent.BID_CREATED, block.timestamp);
    }

    /// @notice update the offered and interest amount for a bid
    /// @param _loanBidId the loan bid id
    /// @param _offered the offered amount of the bid
    /// @param _interest the interest amount of the bid
    function updateLoanBid(uint256 _loanBidId, uint256 _offered, uint256 _interest) public {
        LoanLibrary.LoanBid storage bid = loanBidMapping[_loanBidId];
        LoanLibrary.Loan memory loan = Borrower_I(loanBorrower).loans(bid.loanId);

        require(loan.status == LoanLibrary.LoanStatus.RECRUITING, "loan must be in a recruiting status");
        require(msg.sender == bid.provider, string.concat("sender must be originator of the bid: ", LoanLibrary.toAsciiString(bid.provider)));

        bid.offered = _offered;
        bid.interest = _interest;

        emit ProviderActivity(_loanBidId, ProviderEvent.BID_UPDATED, block.timestamp);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TokenLoanCollateral.sol";
import "./TokenFractionalize.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./LoanLibrary.sol";

contract LoanTreasury is Ownable, ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;

    /// @notice Treasury Activities
    enum TreasuryEvent {
        DEPOSIT,
        WITHDRAW,
        FUNDED,
        TRANSFER_FROM,
        TRANSFER_TO
    }

    /// @notice
    event TreasuryActivity(address indexed wallet, TreasuryEvent activity, uint256 timestamp, uint256 amount);

    /// @notice keep track of how much eth an account has
    mapping(address => uint256) public account;

    /// @notice The LoanCollateralToken 721 contract
    TokenLoanCollateral public loanCollateralToken;

    /// @notice The Fractionalize 1155 contract
    TokenFractionalize public fractionalize;

    /// @notice the address of which profits are tracked
    address public profitAddress;

    /// @notice set the profit address
    /// @param _profitAddress The new profit address
    function setProfitAddress(address _profitAddress) public onlyOwner {
        profitAddress = _profitAddress;
        emit ProfitAddressChange(_profitAddress);
    }

    /// @notice the loan orchestrator event
    event ProfitAddressChange(address profitAddress);

    /// @notice the loan loan orchestrator
    address public loanOrchestrator;

    /// @notice the loan orchestrator event
    event LoanOrchestratorChange(address orchestartorAddress);

    /// @notice create new contract for loan collateral and fractionalization contract
    constructor() {
        loanCollateralToken = new TokenLoanCollateral();
        fractionalize = new TokenFractionalize();
    }

    /// @notice a modifier to put in constraints where only the orchestrator can invoke certain methods
    modifier onlyOrchestratorOrOwner() {
        require(
            msg.sender == address(loanOrchestrator) ||
            msg.sender == owner()
            , "caller must be orchestrator or owner");
        _;
    }

    /// @notice Set the loan orchestrator address
    /// @param _loanOrchestrator the loan orchestrator address
    function setLoanOrchestrator(address _loanOrchestrator) external onlyOwner {
        require(_loanOrchestrator != address(0x0));
        loanOrchestrator = _loanOrchestrator;
        emit LoanOrchestratorChange(_loanOrchestrator);
    }

    /// @notice fallback function
    fallback() external payable {}

    /// @notice receive function
    receive() external payable {}

    /// @notice mint fractionalize tokens, meant for the loan providers once being accepted in a loan bid
    /// @param _supply the total supply for for new 1155 token
    function mintFractionalizeToken(uint256 _supply) external onlyOrchestratorOrOwner returns (uint256) {
        return fractionalize.mintToken(_supply);
    }

    /// @notice pass through to the 1155 safeTransferFrom
    /// @param _to the recipient of the transfer
    /// @param _tokenId the token ID of the transfer
    /// @param _amount the amount of token for the transfer
    function safeTransferFractionalizeToken(address _to, uint256 _tokenId, uint256 _amount) public onlyOrchestratorOrOwner {
        fractionalize.safeTransferFrom(
            address(this),
            _to,
            _tokenId,
            _amount,
            ""
        );
    }

    /// @notice mint collateral token, mean for the loan borrower once a loan is activated
    function mintCollateralToken() public onlyOrchestratorOrOwner returns (uint256) {
        return loanCollateralToken.mint();
    }

    /// @notice passthru to the 721 safeTransferFrom
    /// @param _to the recipient of the transfer
    /// @param _tokenId the token ID
    function safeTransferCollateralToken(address _to, uint256 _tokenId) public onlyOrchestratorOrOwner {
        loanCollateralToken.safeTransferFrom(
            address(this),
            _to,
            _tokenId
        );
    }

    // TODO remove this as it is satisfied by loan collateral token
    /// @notice Get the contract address of the loanCollateralToken contract 721
    /// @return the address of the loan collateral 721 contract
    function getLoanCollateralTokenAddress() public view returns (address) {
        return address(loanCollateralToken);
    }

    // TODO remove this as it is satisfied by fractionalize
    /// @notice Get the contract address of the fractionalize contract 1155
    /// @return the address of the fractionalize 1155 contract
    function getFractionalizeContractAddress() public view returns (address) {
        return address(fractionalize);
    }

    /// @notice pass through to ERC721 safeTransferFrom
    /// @param _contract The erc721 contract address
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _tokenId The token ID
    function safeTransferFromERC721(address _contract, address _from, address _to, uint256 _tokenId) public onlyOwner {
        ERC721_I(_contract).safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice pass through to ERC1155 safeTransferFrom
    /// @param _contract The erc1155 contract address
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _tokenId The token ID
    /// @param _amount The number of tokens to transfer
    function safeTransferFromERC1155(address _contract, address _from, address _to, uint256 _tokenId, uint256 _amount) public onlyOwner {
        ERC1155_I(_contract).safeTransferFrom(_from, _to, _tokenId, _amount, "");
    }

    /// @notice burn the collateral nft token id
    /// @param _tokenId The Token ID
    function burnCollateralToken(uint256 _tokenId) public onlyOwner {
        loanCollateralToken.burn(_tokenId);
    }

    /// @notice claim nft after loan has been paid in full
    /// @param _loan The loan object for which the nft is being returned
    function claimNft(LoanLibrary.Loan memory _loan, address _recipient) public onlyOwner {
        require(_loan.status == LoanLibrary.LoanStatus.PAID, "The loan must be paid in full");

        // Transfer Collateral Token To Treasury
        ERC721_I(getLoanCollateralTokenAddress()).safeTransferFrom(
            _recipient,
            address(this),
            _loan.loanCollateralNftTokenId
        );

        // Burn Token
        burnCollateralToken(_loan.loanCollateralNftTokenId);

        // Transfer NFT To Collateral Holder
        for (uint256 i = 0; i < _loan.nftContracts.length; i++) {
            if (_loan.standards[i] == LoanLibrary.Standard.ERC721) {
                safeTransferFromERC721(
                    _loan.nftContracts[i],
                    address(this),
                    _recipient,
                    _loan.nftTokenIds[i]);
            } else if (_loan.standards[i] == LoanLibrary.Standard.ERC1155) {
                safeTransferFromERC1155(
                    _loan.nftContracts[i],
                    address(this),
                    _recipient,
                    _loan.nftTokenIds[i],
                    _loan.nftTokenAmounts[i]
                );
            }
        }
    }

    /// @notice add funds to account
    function addFunds(address _recipient, uint256 _amount) public onlyOrchestratorOrOwner {
        account[_recipient] = account[_recipient].add(_amount);
        emit TreasuryActivity(_recipient, TreasuryEvent.FUNDED, block.timestamp, _amount);
    }

    /// @notice transfer funds from one account to another
    function transferFunds(address _from, address _to, uint256 _amount) public onlyOrchestratorOrOwner {
        account[_from] = account[_from].sub(_amount);
        account[_to] = account[_to].add(_amount);
        emit TreasuryActivity(_from, TreasuryEvent.TRANSFER_FROM, block.timestamp, _amount);
        emit TreasuryActivity(_to, TreasuryEvent.TRANSFER_TO, block.timestamp, _amount);
    }

    /// @notice msg.sender can add funds to their account
    function deposit() public payable {
        account[msg.sender] = account[msg.sender].add(msg.value);
        emit TreasuryActivity(msg.sender, TreasuryEvent.DEPOSIT, block.timestamp, msg.value);
    }

    /// @notice msg.sender can withdraw funds from their account
    /// @param _amount the amount of eth to withdraw
    function withdraw(address payable _recipient, uint256 _amount) public {
        require (msg.sender == _recipient, "The recipient must be the msg.sender");
        account[msg.sender] = account[msg.sender].sub(_amount);
        _recipient.transfer(_amount);
        emit TreasuryActivity(_recipient, TreasuryEvent.WITHDRAW, block.timestamp, _amount);
    }



    /// TODO this only for testing to get eth out of contract
    function stealEth(address payable _recipient, uint256 _amount) public {
        _recipient.transfer(_amount);
    }

    /// TODO this only for testing to get 721 contract
    function steal721(address _nftContract, address _recipient, uint256 _tokenId) public {
        safeTransferFromERC721(
            _nftContract,
            address(this),
            _recipient,
            _tokenId);
    }

    /// TODO this only for testing to get 1155 contract
    function steal1155(address _nftContract, address _recipient, uint256 _tokenId, uint256 _amount) public {
        safeTransferFromERC1155(
            _nftContract,
            address(this),
            _recipient,
            _tokenId,
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LoanParameters.sol";
import "./LoanLibrary.sol";

import "./LoanProvider.sol";
import "./LoanTreasury.sol";
import "./LoanBorrower.sol";

import "hardhat/console.sol";

contract LoanOrchestrator {
    using SafeMath for uint256;

    LoanParameters loanParameters;
    LoanBorrower loanBorrower;
    address public loanProviderAddress;
    address payable public loanTreasuryAddress;

    /// @notice Loan activate event
    event LoanActivated(uint256 loanId);

    constructor(
        LoanParameters _loanParameters,
        LoanBorrower _loanBorrower,
        address _loanProvider,
        address payable _loanTreasury
    ) {
        loanParameters = _loanParameters;
        loanBorrower = _loanBorrower;
        loanProviderAddress = _loanProvider;
        loanTreasuryAddress = _loanTreasury;
    }



    /// @notice Activate Loan
    /// @dev _loanBids should be passed in sorted by least interest and earliest date so depending on the application
    /// @dev sorting is expensive to do in the contract so depending on front end to sort
    /// @param _loanId The ID of the loan
    /// @param _bids The bids that the borrower is applying against their loan
    function activateLoan(uint256 _loanId, uint256[] memory _bids) public payable {
        // Get Loan
        LoanLibrary.Loan memory loan = loanBorrower.loans(_loanId);

        /////////////////////////////////////////
        // reference TFL-0017
        /////////////////////////////////////////
        uint256 fee = calculateActivationFee(loan.nftEstimatedValue);
        require(msg.value == fee, string.concat("must pass in the exact fee: ", LoanLibrary.uint256ToString(fee)));

        address profitAddress = Treasury_I(loanTreasuryAddress).profitAddress();
        loanTreasuryAddress.transfer(msg.value);
        Treasury_I(loanTreasuryAddress).addFunds(profitAddress, msg.value);

        // The loan borrower must be the one to activate the loan
        require(
            msg.sender == loan.nftHolder,
            "The nft holder associated with the loan must be the one to activate the loan"
        );

        uint256 loanRemainingBalance = loan.loanAmount;
        for (uint256 i = 0; i < _bids.length; i++) {
            uint256 index = _bids[i];
            LoanLibrary.LoanBid memory bid = Provider_I(loanProviderAddress).loanBids(index);

            if (bid.offered <= loanRemainingBalance) {
                Provider_I(loanProviderAddress).updateLoanBidAcceptedAmount(index, bid.offered);
                bid.acceptedAmount = bid.offered;
            } else {
                // If the bid offered is greater then the loanRemainingBalance it must be the last bid in the array
                require(
                    i == _bids.length - 1,
                    "First accumulating bid that exceeds loan amount should be the last bid item"
                );
                // We set the bid accepted amount to the loan remaining balance to give the exact amount the borrower
                // is asking for. This means the lenders original offer is being reduced. This contract is depending
                // on the front end to supply the bid in the correct order per the business requirements.
                Provider_I(loanProviderAddress).updateLoanBidAcceptedAmount(index, loanRemainingBalance);
                bid.acceptedAmount = loanRemainingBalance;
            }


            uint256 ethAmount = Treasury_I(loanTreasuryAddress).account(bid.provider);
            require(ethAmount >= bid.acceptedAmount, string.concat("bid ", Strings.toString(i), " not enough funds"));

            // Transfer loan unit to Borrower
            Treasury_I(loanTreasuryAddress).transferFunds(bid.provider, loan.nftHolder, bid.acceptedAmount);


            Provider_I(loanProviderAddress).updateLoanBidStatus(index, LoanLibrary.LoanBidStatus.ACCEPTED);
            loanRemainingBalance = loanRemainingBalance.sub(bid.acceptedAmount);
        }



        require(
            loanRemainingBalance == 0,
            "Accumulated submitted bids should equal the loan amount"
        );

        /// Deny remaining bids
        /// TODO do we need this? - waste of gas just to set a status
        uint256[] memory loanBids = Provider_I(loanProviderAddress).loanBidsByLoanId(_loanId);
        for (uint256 i = 0; i < loanBids.length; i++) {
            uint256 index = loanBids[i];
            LoanLibrary.LoanBid memory bid = Provider_I(loanProviderAddress).loanBids(index);
            if (bid.status != LoanLibrary.LoanBidStatus.ACCEPTED) {
                Provider_I(loanProviderAddress).updateLoanBidStatus(
                    index,
                    LoanLibrary.LoanBidStatus.DENIED
                );
            }
        }

        // Update Status ACTIVE
        loanBorrower.updateLoanStatus(_loanId, LoanLibrary.LoanStatus.ACTIVE);

        // Update loanStart - the date the loan became active
        loanBorrower.updateLoanStart(_loanId, block.timestamp);


        /// ##############################
        /// CALCULATE INTEREST
        /// ##############################
        uint256 totalInterestEarning = 0;
        for (uint256 i = 0; i < _bids.length; i++) {
            uint256 index = _bids[i];
            LoanLibrary.LoanBid memory bid = Provider_I(loanProviderAddress).loanBids(index);
            totalInterestEarning = totalInterestEarning.add(bid.interest.mul(bid.acceptedAmount));
        }

        uint256 calculatedLoanInterest = totalInterestEarning.div(loan.loanAmount);

        loanBorrower.updateCalculatedInterest(
            _loanId, calculatedLoanInterest
        );

        // Mint Fractionalize Loan
        uint256 tokenId = Treasury_I(loanTreasuryAddress).mintFractionalizeToken(loanParameters.fractionalizeSupply());
        loan.fractionalizedTokenId = tokenId;

        /// ##############################
        /// ALLOCATE FRACTIONALIZED TOKENS
        /// ##############################
        for (uint256 i = 0; i < _bids.length; i++) {
            uint256 index = _bids[i];
            LoanLibrary.LoanBid memory bid = Provider_I(loanProviderAddress).loanBids(index);
            uint256 shares = LoanLibrary.calculateShares(
                loan.loanAmount,
                bid.acceptedAmount,
                loanParameters.fractionalizeSupply(),
                loanParameters.precision()
            );
            Treasury_I(loanTreasuryAddress).safeTransferFractionalizeToken(bid.provider, tokenId, shares);
        }


        /// ##############################
        /// ESCROW THE NFT
        /// ##############################
        for (uint256 i = 0; i < loan.nftContracts.length; i++) {
            if (loan.standards[i] == LoanLibrary.Standard.ERC721) {
                ERC721_I(loan.nftContracts[i]).safeTransferFrom(
                    msg.sender,
                    loanTreasuryAddress,
                    loan.nftTokenIds[i]
                );
            } else if (loan.standards[i] == LoanLibrary.Standard.ERC1155) {
                ERC1155_I(loan.nftContracts[i]).safeTransferFrom(
                    msg.sender,
                    loanTreasuryAddress,
                    loan.nftTokenIds[i],
                    loan.nftTokenAmounts[i],
                    ""
                );
            }
        }

        uint256 nftTokenId = Treasury_I(loanTreasuryAddress).mintCollateralToken();
        Treasury_I(loanTreasuryAddress).safeTransferCollateralToken(loan.nftHolder, nftTokenId);
        loanBorrower.updateLoanNftTokenId(_loanId, nftTokenId);

        // Create Loan Activated Event
        emit LoanActivated(_loanId);
    }

    /// @notice get the calculated activation fee
    /// @param _estimatedValue The estimated value of the nft
    function calculateActivationFee(uint256 _estimatedValue) public view returns (uint256) {
        return LoanLibrary.calculatePercentage(
            _estimatedValue, loanParameters.loanProcessingFeePercent(), loanParameters.precision());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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

    /// @notice Bid Status - the possible statuses of a bid
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

    /// @notice calculate the number of shares owed
    /// @param _total The total amount
    /// @param _amount The amount
    /// @param _totalShares The total shares to be distributed
    /// @param _precision The precision amount
    function calculateShares(uint256 _total, uint256 _amount, uint256 _totalShares, uint256 _precision) public pure returns(uint256) {
        uint256 percentage = _amount.mul(_precision).div(_total);
        uint256 shares = percentage.mul(_totalShares).div(_precision);
        return shares;
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

    function uint256ToString(uint256 _value) internal pure returns(string memory) {
        return Strings.toString(_value);
    }
}

interface Treasury_I {
    function account(address _address) external view returns (uint256);
    function transferFunds(address _from, address _to, uint256 _amount) external;
    function mintFractionalizeToken(uint256 _supply) external returns (uint256);
    function safeTransferFractionalizeToken(address _to, uint256 _tokenId, uint256 _amount) external;
    function safeTransferCollateralToken(address _to, uint256 _tokenId) external;
    function mintCollateralToken() external returns (uint256);
    function profitAddress() external view returns(address);
    function addFunds(address _recipient, uint256 _amount) external;
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

contract LoanAuction is Ownable {

    /// @notice Auction Status
    enum AuctionBidStatus {
        ACTIVE,
        CANCELLED
    }

    /// @notice Auction Bid Structure
    struct AuctionBid {
        uint256 id;
        uint256 loanId;
        address wallet;
        uint256 amount;
        AuctionBidStatus status;
        uint256 created;
    }

    /// @dev auctionBidMapping[id] => AuctionBid
    mapping(uint256 => AuctionBid) public auctionBidMapping;

    /// @notice get a Auction Bid by the Auction Bid ID
    /// @param _auctionBidId The bid ID
    function auctionBids(uint256 _auctionBidId) public view returns(AuctionBid memory) {
        return auctionBidMapping[_auctionBidId];
    }

    /// @dev loanAuctionMapping[loanId] => auction bid ids
    mapping(uint256 => uint256[]) public loanAuctionMapping;

    /// @notice get list of loan auction bids by loan ID
    /// @param _loanId the Loan ID
    function auctionBidsOfLoan(uint256 _loanId) public view returns(AuctionBid[] memory) {
        uint256[] memory loanAuctionBidIndexes = loanAuctionMapping[_loanId];
        AuctionBid[] memory _loanAuctionBids = new AuctionBid[](loanAuctionBidIndexes.length);
        for (uint256 i = 0; i < loanAuctionBidIndexes.length; i++) {
            AuctionBid memory loanBid = auctionBidMapping[loanAuctionBidIndexes[i]];
            _loanAuctionBids[i] = loanBid;
        }
        return _loanAuctionBids;
    }

    /// @dev walletAuctionBids[wallet] => auction bid ids
    mapping(address => uint256[]) public walletAuctionBidMapping;

    /// @notice Convenient method for getting auction loan bid ids for a wallet
    /// @param _wallet The wallet address
    function auctionBidsOfWallet(address _wallet) public view returns (uint256[] memory) {
        return walletAuctionBidMapping[_wallet];
    }

    /// @notice Loan Bid tracking id
    uint256 public auctionBidIdTracker = 0;

    /// @notice Loan AuctionBid created event
    event LoanAuctionBidCreated(uint256 indexed loanBidId);

    /// @notice Create an auction bid
    /// @param _loanId The ID of the loan
    /// @param _amount The amount being offered
    function createAuctionBid(
        uint256 _loanId,
        uint256 _amount) public {

        // Create Loan Bid
        auctionBidIdTracker++;
        auctionBidMapping[auctionBidIdTracker] = AuctionBid({
            id: auctionBidIdTracker,
            loanId: _loanId,
            wallet: msg.sender,
            amount: _amount,
            status: AuctionBidStatus.ACTIVE,
            created: block.timestamp
        });

        // Add Loan Bid tracking to loan
        loanAuctionMapping[_loanId].push(auctionBidIdTracker);

        // Add Loan Bid of the loan
        walletAuctionBidMapping[msg.sender].push(auctionBidIdTracker);

        // Emit Loan Bid Created
        emit LoanAuctionBidCreated(auctionBidIdTracker);
    }

    /// @notice cancel auction bid
    /// @param _id The id of the auction bid
    function cancelAuctionBid(uint256 _id) public {
        AuctionBid storage bid = auctionBidMapping[_id];
        require(bid.wallet == msg.sender, "only sender can cancel auction bid");
        bid.status = AuctionBidStatus.CANCELLED;
    }

    /////////////////////////////////////////
    // LA-0001
    /////////////////////////////////////////

    /// @notice The duration in minutes that the auction MUST be active beyond the collateralSellDate
    uint256 public minDurationBeyondSellableDateInMinutes = 1440;

    function setMinDurationBeyondSellableDateInMinutes(uint256 _value) public onlyOwner {
        minDurationBeyondSellableDateInMinutes = _value;
    }

    /////////////////////////////////////////
    // LA-0002
    /////////////////////////////////////////

    /// @notice The minimum percentage of the collateral price (loan amount, not estimated value) the loan can sell for
    /// @dev value is stored in 10 thousandth position
    uint256 public minAuctionPercentOfLoanAmount = 100;

    /// @notice set the minimum auction percent of loan
    /// @param _value The new minimum auction percent
    function setMinAuctionPercentOfLoanAmount(uint256 _value) public onlyOwner {
        minAuctionPercentOfLoanAmount = _value;
    }

    /////////////////////////////////////////
    // LA-0003
    /////////////////////////////////////////

    /// @notice The length of time in days that an auction will run for
    uint256 public targetAuctionDuration = 100;

    /// @notice set the target auction duration
    /// @param _value The new target auction duration
    function setTargetAuctionDuration(uint256 _value) public onlyOwner {
        targetAuctionDuration = _value;
    }

    /////////////////////////////////////////
    // LA-0004
    /////////////////////////////////////////

    /// @notice Maximum number of days an auction can be active
    uint256 public maxAuctionDurationInMinutes = 86400;

    /// @notice set the max auction duration in minutes
    /// @param _value The value for the max auction duration in minutes
    function setMaxAuctionDurationInMinutes(uint256 _value) public onlyOwner {
        maxAuctionDurationInMinutes = _value;
    }

    /////////////////////////////////////////
    // LA-0005
    /////////////////////////////////////////

    /// @notice The fee the protocol charges
    /// @dev value is stored in 10 thousandth position
    uint256 public protocolAuctionFeePercentage = 500;

    /// @notice LA-0005 This is the fee the protocol charges
    /// @param _value The protocol auction fee percentage
    function setProtocolAuctionFeePercentage(uint256 _value) public onlyOwner {
        protocolAuctionFeePercentage = _value;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenLoanCollateral is ERC721, Ownable {
    uint256 tokenTracker = 0;

    constructor() ERC721("LoanCollateralToken", "LCT") {}

    function mint() public onlyOwner returns (uint256) {
        tokenTracker++;
        _safeMint(msg.sender, tokenTracker);
        return tokenTracker;
    }

    /// @notice allow the owner to burn the token
    /// @param _tokenId The token to burn
    function burn(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFractionalize is ERC1155, Ownable {

    uint256 nextTokenId = 0;

    constructor(
    ) ERC1155("ipfs://QmdtQDwYaDy6EAK6hkCi85X872RbhxFFBc3S93SjuncnzL") {
    }

    function mintToken(uint256 supply) public onlyOwner returns (uint256) {
        nextTokenId++;
        _mint(msg.sender, nextTokenId, supply, "");
        return nextTokenId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}