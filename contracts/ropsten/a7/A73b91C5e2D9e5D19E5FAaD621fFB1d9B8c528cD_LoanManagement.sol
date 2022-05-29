pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../IERC20.sol";
import "./Loan.sol";

interface TrustTokenInterface {
    function isTrustee(address) external view returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface ProposalManagementInterface {
    function memberId(address) external view returns (uint256);

    function contractFee() external view returns (uint256);

    function setLoanManagement(address) external;

    function transferTokensFrom(address, address, uint256) external returns (bool);
}

interface LoanInterface {

    struct LoanParams {
        address lender;
        address borrower;
        bool initiatorVerified;
        uint256 principalAmount;
        uint256 paybackAmount;
        uint256 contractFee;
        string purpose;
        address collateralToken;
        uint256 collateralAmount;
        uint256 duration;
        uint256 effectiveDate;
    }

    function managementAcceptLoanOffer(address) external;

    function managementAcceptLoanRequest(address) external;

    function managementReturnCollateral() external;

    function managementDefaultOnLoan() external;

    function cleanUp() external;

    function borrower() external view returns (address);

    function lender() external view returns (address);

    function getLoanParameters() external view returns (LoanParams memory);

    function getLoanStatus() external view returns (uint8);

    function refreshAndGetLoanStatus() external returns (uint8);
}

contract LoanManagement {

    // Loan platform settings.
    address payable private trustToken;
    address private proposalManagement;

    // Loan management variables.
    mapping(address => uint256) private userRequestCount;
    mapping(address => uint256) private userOfferCount;
    mapping(address => bool) private validLoanAd;
    mapping(address => bool) private openLoan;
    address[] private loanRequests;
    address[] private loanOffers;

    // Credit rating system variables.
    mapping(address => uint256) public borrowerRatings;
    mapping(address => uint256) public lenderRatings;

    // Event for when a borrower requests a loan.
    event LoanRequested();
    // Event for when a lender offers a loan.
    event LoanOffered();
    // Event for when a borrower accepts a loan offer, or a lender accepts a loan request.
    event LoanGranted();
    // Event for a borrower deposits collateral to the loan.
    // Event for when a borrower withdraws the loan's value.
    event LoanDisbursed();
    // Event for when a borrower repays or a lender withdraws collateral.
    event LoanSettled();

    /**
     * @notice Creates an instance of the LoanManagement contract.
     * @param _trustToken Address of the TrustToken
     * @param _proposalManagement Address of the ProposalManagement
     */
    constructor(
        address payable _trustToken,
        address _proposalManagement) public {
        trustToken = _trustToken;
        proposalManagement = _proposalManagement;
        ProposalManagementInterface(proposalManagement).setLoanManagement(address(this));
    }

    /**
     * @notice Creates a request from a borrower for a new loan.
     * @param _principalAmount Loan principal amount in Wei
     * @param _paybackAmount Loan repayment amount (in Wei?)
     * @param _purpose Purpose(s) the loan will be used for
     * @param _collateralToken Address of the token to be used for collateral
     * @param _collateralAmount Amount of collateral (denominated in _collateralToken) required
     * @param _duration Length of time borrower has to repay the loan from when the lender deposits the principal
     */
    function createLoanRequest(
        uint256 _principalAmount,
        uint256 _paybackAmount,
        string memory _purpose,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _duration) public {

        // Validate the input parameters.
        require(_principalAmount > 0, "Principal amount must be greater than 0");
        require(_paybackAmount > _principalAmount, "Payback amount must be greater than principal");
        require(userRequestCount[msg.sender] < 5, "Too many loan requests made");
        require(_collateralToken == address(trustToken), "Only BBET is currently supported as a collateral token");
        require(_duration >= 60 * 60 * 12, "Loan duration must be at least 12 hours");

        // Check if borrower is a verified member.
        bool borrowerVerified = TrustTokenInterface(address(trustToken)).isTrustee(msg.sender);
        borrowerVerified = borrowerVerified || ProposalManagementInterface(proposalManagement).memberId(msg.sender) != 0;
        require(borrowerVerified, "Must be a DFND holder to request loans");

        // Get contract fee.
        uint256 contractFee = ProposalManagementInterface(proposalManagement).contractFee();

        // Check if the borrower has enough collateral.
        require(IERC20(_collateralToken).balanceOf(msg.sender) > _collateralAmount, "Insufficient collateral in account");

        // Create new Loan contract.
        address loan = address(
            new Loan(
                payable(proposalManagement), trustToken, address(0), msg.sender,
                _principalAmount, _paybackAmount, contractFee, _purpose,
                _collateralToken, _collateralAmount, _duration
            )
        );

        // Update number of active requests by the borrower.
        userRequestCount[msg.sender]++;

        // Add new loan request to management structures.
        loanRequests.push(loan);

        // Mark requested loan as a valid ad (request/offer).
        validLoanAd[loan] = true;

        // Trigger LoanRequested event.
        // TODO emit LoanRequested();

        // TODO In web3.js: Ask user to approve spending of collateral by management contract.
    }

    /**
     * @notice Creates an offer by a lender for a new loan.
     * @param _principalAmount Loan principal amount in Wei
     * @param _paybackAmount Loan repayment amount (in Wei?)
     * @param _purpose Purpose(s) the loan will be used for
     * @param _collateralToken Address of the token to be used for collateral
     * @param _collateralAmount Amount of collateral (denominated in _collateralToken) required
     * @param _duration Length of time borrower has to repay the loan from when the lender deposits the principal
     */
    function createLoanOffer(
        uint256 _principalAmount,
        uint256 _paybackAmount,
        string memory _purpose,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _duration) public {

        // Validate the input parameters.
        require(_principalAmount > 0, "Principal amount must be greater than 0");
        require(_paybackAmount > _principalAmount, "Payback amount must be greater than principal");
        require(userOfferCount[msg.sender] < 5, "Too many loan offers made");
        require(_collateralToken == address(trustToken), "Only BBET is currently supported as a collateral token");
        require(_duration >= 60 * 60 * 12, "Loan duration must be at least 12 hours");

        // Check if lender is a verified member.
        bool lenderVerified = TrustTokenInterface(address(trustToken)).isTrustee(msg.sender);
        lenderVerified = lenderVerified || ProposalManagementInterface(proposalManagement).memberId(msg.sender) != 0;
        require(lenderVerified, "Must be a DFND holder to offer loans");

        // Get contract fee.
        uint256 contractFee = ProposalManagementInterface(proposalManagement).contractFee();

        // Make sure the lender has enough DFND to pay the principal.
        require(IERC20(trustToken).balanceOf(msg.sender) > _principalAmount, "Insufficient balance to offer this loan");

        // Create new Loan contract.
        address loan = address(
            new Loan(
                payable(proposalManagement), trustToken, msg.sender, address(0),
                _principalAmount, _paybackAmount, contractFee, _purpose,
                _collateralToken, _collateralAmount, _duration
            )
        );

        // Update number of offers made by the lender.
        userOfferCount[msg.sender]++;

        // Add new loan offer management structures.
        loanOffers.push(loan);

        // Mark offered loan as a valid ad (request/offer).
        validLoanAd[loan] = true;

        // Trigger LoanOffered event.
        // TODO emit LoanOffered();
    }

    /**
     * @notice Borrower accepts loan offer; collateral transfers from borrower to loan; principal transfers from lender to borrower.
     * @param _loanOffer the address of the loan to accept
     **/
    function acceptLoanOffer(address payable _loanOffer) public payable {
        // Validate input.
        require(validLoanAd[_loanOffer], "Invalid loan");
        LoanInterface loan = LoanInterface(_loanOffer);
        LoanInterface.LoanParams memory loanParams = loan.getLoanParameters();

        // Check if user is verified.
        bool borrowerVerified = TrustTokenInterface(address(trustToken)).isTrustee(msg.sender);
        borrowerVerified = borrowerVerified || ProposalManagementInterface(proposalManagement).memberId(msg.sender) != 0;
        require(borrowerVerified, "DFND balance insufficient or account not verified to accept loan offers");

        // Check if borrower has approved spending of collateral.
        if (loanParams.collateralAmount > 0) {
            require(IERC20(loanParams.collateralToken).allowance(msg.sender, _loanOffer) < loanParams.collateralAmount, "Borrower must approve spending of collateral before accepting the loan");
        }

        // Check if lender has enough DFND to accept.
        if (TrustTokenInterface(address(trustToken)).balanceOf(loanParams.lender) >= loanParams.principalAmount) {
            cancelLoanAd(_loanOffer);
            // TODO Emit event saying: Lender failed to maintain enough DFND to fund the loan. Loan offer is now canceled
            return;
        }

        // Transfer borrower's collateral to loan.
        if (loanParams.collateralAmount > 0) {
            IERC20(loanParams.collateralToken).transferFrom(msg.sender, _loanOffer, loanParams.collateralAmount);
        }

        // Transfer principal from lender to borrower.
        ProposalManagementInterface(proposalManagement).transferTokensFrom(loanParams.lender, msg.sender, loanParams.principalAmount);

        // Update loan status.
        Loan(_loanOffer).managementAcceptLoanOffer(msg.sender);

        // Remove loan offer from management structures.
        removeLoanOffer(_loanOffer, loanParams.borrower);
        openLoan[_loanOffer] = true;

        // TODO Emit the proper event for frontend to notify loan counterparty.
        // TODO emit LoanGranted();
    }

    /**
     * @notice Lender accepts loan request; collateral transfers from borrower to loan; principal transfers from lender to borrower.
     * @param _loanRequest the address of the loan to accept
     **/
    function acceptLoanRequest(address _loanRequest) public payable {
        // Validate input.
        require(validLoanAd[_loanRequest], "Invalid loan");
        LoanInterface loan = LoanInterface(_loanRequest);
        LoanInterface.LoanParams memory loanParams = loan.getLoanParameters();

        // Check if user is verified.
        bool lenderVerified = TrustTokenInterface(address(trustToken)).isTrustee(msg.sender);
        lenderVerified = lenderVerified || ProposalManagementInterface(proposalManagement).memberId(msg.sender) != 0;
        require(lenderVerified, "DFND balance insufficient or account not verified");

        // Check if lender has enough DFND to accept.
        require(TrustTokenInterface(address(trustToken)).balanceOf(msg.sender) >= loanParams.principalAmount, "DFND balance insufficient");

        // Check if borrower has approved spending of collateral.
        if (loanParams.collateralAmount > 0) {
            if (IERC20(loanParams.collateralToken).allowance(loanParams.borrower, _loanRequest) < loanParams.collateralAmount) {
                cancelLoanAd(_loanRequest);
                // TODO Emit event saying: Borrower failed to put up collateral. Loan was canceled
                return;
            }
        }

        // Transfer borrower's collateral to loan.
        if (loanParams.collateralAmount > 0) {
            IERC20(loanParams.collateralToken).transferFrom(address(loanParams.borrower), _loanRequest, loanParams.collateralAmount);
        }

        // Transfer principal from lender to borrower.
        ProposalManagementInterface(proposalManagement).transferTokensFrom(msg.sender, loanParams.borrower, loanParams.principalAmount);

        // Update loan status.
        Loan(_loanRequest).managementAcceptLoanRequest(msg.sender);

        // Remove loan request from management structures.
        removeLoanRequest(_loanRequest, loanParams.borrower);
        openLoan[_loanRequest] = true;

        // TODO Emit the proper event for frontend to notify loan counterparty.
        // TODO emit LoanGranted();
    }

    /**
     * @notice Transfers DFND from the borrower to the lender and returns borrower's collateral.
     */
    function repayLoan(address _loan) public {
        // Validate parameters.
        LoanInterface loan = LoanInterface(_loan);
        LoanInterface.LoanParams memory loanParams = loan.getLoanParameters();
        require(msg.sender == loanParams.borrower, "Only the borrower may repay their loan");

        // Check if borrower has sufficient funds to repay loan and fee.
        require(TrustTokenInterface(trustToken).balanceOf(msg.sender) >= loanParams.paybackAmount + loanParams.contractFee,
            "Insufficient balance");

        // Transfer principal to lender.
        ProposalManagementInterface(proposalManagement).transferTokensFrom(msg.sender, loanParams.lender, loanParams.paybackAmount);

        // Transfer contract fee management contract.
        ProposalManagementInterface(proposalManagement).transferTokensFrom(msg.sender, address(this), loanParams.contractFee);

        // Transfer collateral to lender.
        if (loanParams.collateralAmount > 0) {
            loan.managementReturnCollateral();
        }

        // Destroy loan.
        openLoan[_loan] = false;
        loan.cleanUp();

        // TODO Increase credit score if loan was repaid on time.

        // TODO Lower credit score if loan was repaid late.

        // TODO Emit the proper event and respond to it.
        // TODO emit LoanRepaid();
    }

    /**
     * @notice Checks if loan expired, penalizes borrower for failure to repay, gives collateral to the lender.
     */
    function defaultOnLoan(address _loan) public {
        // Validate parameters.
        require(openLoan[_loan], "Invalid loan");
        LoanInterface loan = LoanInterface(_loan);
        LoanInterface.LoanParams memory loanParams = loan.getLoanParameters();
        require(msg.sender == loanParams.lender, "Only the lender may claim the loan's collateral");

        // Check if the loan term has expired.
        uint8 loanStatus = loan.refreshAndGetLoanStatus();
        require(loanStatus == 2, "Cannot claim collateral until the loan has reached maturity");

        // Send collateral from loan contract to lender.
        if (loanParams.collateralAmount > 0) {
            loan.managementDefaultOnLoan();
        }

        // Mark loan as completed.
        openLoan[_loan] = false;
        loan.cleanUp();

    }
    
    function creditScore(address _loan) public {
        LoanInterface loan = LoanInterface(_loan);
        LoanInterface.LoanParams memory loanParams = loan.getLoanParameters();

         // Increase/decrease borrower credit score.
        if (loanParams.effectiveDate + loanParams.duration < block.timestamp + 60) {

            // Increase borrower credit score if loan was repaid on time.
            uint256 borrowerScore = borrowerRatings[msg.sender];
            borrowerScore += (borrowerScore < 100) ? 50 : (300 - borrowerScore) / 4;

            // TODO ignore for now: add additional points for amount of ETH borrowed.
            // Save the borrower's new score.
            borrowerRatings[msg.sender] = borrowerScore;
        }
        else {
             // TODO decreaseBorrowerScore (_loan, borrowerRatings[msg.sender]);
        }

         // TODO Increase/decrease lender credit score. 
            // TODO increase Lender credit score if loan was repaid late.
        if (loanParams.effectiveDate + loanParams.duration < block.timestamp + 60) {

            // Increase lender credit score if loan was not repaid on time.
            uint256 lenderScore = lenderRatings[loanParams.lender];
            lenderScore += (lenderScore < 100) ? 50 : (300 - lenderScore) / 4;

            // TODO ignore for now: add additional points for amount of ETH borrowed.
            // Save the borrower's new score.
            lenderRatings[loanParams.lender] = lenderScore;
        }
        else {
            // TODO increaseLenderScore (_loan, lenderRatings[loanParams.lender]);
        }
    }
    

    /**
     * @notice Cancels the loan request/offer.
     *          Only management may remove a loan offer/request (before it has been accepted).
     *          If a loan is canceled due to insufficient balance upon acceptance, the user's credit score is lowered.
     * @param _loan Address of the loan request/offer to cancel
     */
    function cancelLoanAd(address _loan) public {

        // Validate input.
        require(msg.sender == proposalManagement || msg.sender == address(this), "Only admin may cancel a loan ad");
        require(validLoanAd[_loan], "Loan request/offer is invalid, either because it does not exist or has already gone into effect");

        // Get loan parameters and state.
        LoanInterface loanVar = LoanInterface(_loan);
        LoanInterface.LoanParams memory loanParams = loanVar.getLoanParameters();

        // Destroy the loan contract.
        loanVar.cleanUp();

        // Remove the loan ad from management variables.
        require(loanParams.borrower == address(0) || loanParams.lender == address(0), "INVALID LOAN STATE/PARAMS");
        if (loanParams.borrower == address(0)) {
            removeLoanOffer(_loan, loanParams.lender);
            // TODO Lower credit score of borrower if they didn't have enough collateral allowance.
        } else {
            removeLoanRequest(_loan, loanParams.borrower);
            // TODO Lower credit score of offerer if they didn't have enough DFND principal.
        }

        // TODO Use correct event, if it's even needed.
        // TODO emit LoanRequestCanceled();
    }

    /**
     * @notice Removes the loan offer from the management structures.
     */
    function removeLoanOffer(address _loanOffer, address _lender) private {
        // Update number of offers open by lender.
        userOfferCount[_lender]--;

        // Mark loan offer as invalid.
        validLoanAd[_loanOffer] = false;

        // Find index of loan offer.
        uint idx = loanOffers.length;
        bool idxFound = false;
        while (true) {
            idx--;
            if (loanOffers[idx] == _loanOffer) {
                idxFound = true;
                break;
            }
        }

        // Remove loan offer from array by moving back all other offers after its index.
        if (idxFound) {
            while (idx < loanOffers.length - 1) {
                loanOffers[idx] = loanOffers[idx + 1];
                idx++;
            }
            loanOffers.pop();
        }
    }

    /**
     * @notice Removes the loan request from the management structures.
     */
    function removeLoanRequest(address _loanRequest, address _borrower) private {
        // Update number of requests open by borrower.
        userRequestCount[_borrower]--;

        // Mark loan request as invalid.
        validLoanAd[_loanRequest] = false;

        // Find index of loan request.
        uint idx = loanRequests.length;
        bool idxFound = false;
        while (idx > 0) {
            idx--;
            if (loanRequests[idx] == _loanRequest) {
                idxFound = true;
                break;
            }
        }

        // Remove loan request from array by moving back all other requests after its index.
        if (idxFound) {
            while (idx < loanRequests.length - 1) {
                loanRequests[idx] = loanRequests[idx + 1];
                idx++;
            }
            loanRequests.pop();
        }
    }

    /**
     * @notice Gets all open loan requests.
     * @return An array of all open loan requests
     */
    function getLoanRequests() public view returns (address[] memory) {
        return loanRequests;
    }

    /**
     * @notice Gets all open loan offers.
     * @return An array of all open loan offers
     */
    function getLoanOffers() public view returns (address[] memory) {
        return loanOffers;
    }

    /**
     * @notice Gets all loan parameters except trustToken and proposalManagement.
     * @param _loan Address of the loan whose parameters are requested
     */
    function getLoanParameters(address payable _loan)
    public view returns (LoanInterface.LoanParams memory) {
        return LoanInterface(_loan).getLoanParameters();
    }

    /**
     * @notice Gets integer describing status of the loan.
     * @return loanStatus == 0: loan offer/request made.
     *          1: loan offer/request accepted. principal & collateral automatically transferred.
     *          2: loan defaulted. lender has claimed the collateral after the loan expired without repayment.
     */
    function getLoanStatus(address _loan)
    public view returns (uint8 loanStatus) {

        return LoanInterface(_loan).getLoanStatus();
    }

    /**
     * @notice Gets integer describing status of the loan. First, checks if the loan has defaulted.
     * @return loanStatus == 0: loan offer/request made.
     *          1: loan offer/request accepted. principal & collateral automatically transferred.
     *          2: loan defaulted. lender has claimed the collateral after the loan expired without repayment.
     */
    function refreshAndGetLoanStatus(address _loan)
    public returns (uint8 loanStatus) {
        return LoanInterface(_loan).refreshAndGetLoanStatus();
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../IERC20.sol";
import "./LoanManagement.sol";

contract Loan {

    modifier calledByLoanManagement {
        require(msg.sender == managementContract, "Invalid caller");
        _;
    }

    // Loan system settings.
    address payable private managementContract;
    address payable private trustToken;

    // Loan settings.
    address public lender;
    address public borrower;
    bool public borrowerIsInitiator;   // whether the borrower or lender initially requested/offered the loan
    bool private initiatorVerified;
    uint256 public principalAmount;
    uint256 public paybackAmount;
    uint256 public contractFee;         // cost of processing the transaction (or amount paid to the management?)
    string public purpose;
    address public collateralToken;
    uint256 public collateralAmount;
    uint256 public duration;
    uint256 public effectiveDate;

    // loanStatus == 0: loan offer/request made.
    // loanStatus == 1: loan offer/request accepted. principal & collateral automatically transferred.
    // loanStatus == 2: loan defaulted. lender has claimed the collateral after the loan expired without repayment.
    uint8 public loanStatus;

    constructor(
        address payable _managementContract,
        address payable _trustToken,
        address _lender,
        address _borrower,
        uint256 _principalAmount,
        uint256 _paybackAmount,
        uint256 _contractFee,
        string memory _purpose,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _duration
    ) public {
        managementContract = _managementContract;
        trustToken = _trustToken;
        lender = _lender;
        borrower = _borrower;
        borrowerIsInitiator = (lender == address(0));
        initiatorVerified = true;
        principalAmount = _principalAmount;
        paybackAmount = _paybackAmount;
        contractFee = _contractFee;
        purpose = _purpose;
        collateralToken = _collateralToken;
        collateralAmount = _collateralAmount;
        duration = _duration;
        // Don't set effectiveDate until the loan goes into effect (LenderAd or BorrowerAd is accepted).
        effectiveDate = 0;
        loanStatus = 0;
    }

    /**
     * @notice Called by management contract to update loan's variables when a request is accepted by a lender.
     */
    function managementAcceptLoanRequest(address _lender) external calledByLoanManagement {
        lender = _lender;
        loanStatus = 1;
        effectiveDate = block.timestamp;
    }

    /**
     * @notice Called by management contract to update loan's variables when an offer is accepted by a borrower.
     */
    function managementAcceptLoanOffer(address _borrower) external calledByLoanManagement {
        borrower = _borrower;
        loanStatus = 1;
        effectiveDate = block.timestamp;
    }

    /**
     * @notice Called by LoanManagement to transfer collateral to borrower.
     */
    function managementReturnCollateral() external calledByLoanManagement {
        IERC20(collateralToken).transfer(borrower, collateralAmount);
    }

    /**
     * @notice Called by LoanManagement to transfer collateral to lender.
     */
    function managementDefaultOnLoan() external calledByLoanManagement {
        IERC20(collateralToken).transfer(lender, collateralAmount);
    }

    /**
     * @notice Destroys the loan contract and forwards all remaining funds to the management contract.
     */
    function cleanUp() external calledByLoanManagement {
        selfdestruct(managementContract);
    }

    /**
     * @notice Getter for all loan parameters except trustToken and proposalManagement.
     */
    function getLoanParameters() external view
    returns (LoanInterface.LoanParams memory) {
        return LoanInterface.LoanParams(lender, borrower, initiatorVerified, principalAmount, paybackAmount, contractFee, purpose, collateralToken, collateralAmount, duration, effectiveDate);
    }

    /**
     * @notice Getter for status variables of the loan.
     */
    function getLoanStatus() external view returns (uint8) {
        return (loanStatus);
    }

    /**
     * @notice Non-static getter for status variables of the loan. Checks to update loan status before returning it.
     */
    function refreshAndGetLoanStatus() external returns (uint8) {
        // Check if loan has defaulted.
        if (loanStatus == 1 && block.timestamp > effectiveDate + duration) {
            loanStatus = 2;
        }

        // Return loan status.
        return (loanStatus);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}