/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Unauthorized();
error InterestRateOutOfRange();
error AmountCanNotBeNull();
error NotEnoughFundsInContract();
error Max2LoansAllowed();
error LoanMustExist();
error ExactDebtMustBePaid();

/** @title LendingBorrowing : contract for lending&borrowing ETH
 *  @author SiegfriedBz
 *  @notice This contract allows lenders to receive interests on loans, as a function of each lender balance/contract balance at the time a loan is created
 *  @notice This contract allows borrowers to create a max of 2 active loans at a given time
 */
contract LendingBorrowing {
    uint256 public immutable i_interestRate;
    uint256 public totalActiveLoanCounter;
    address payable public immutable i_owner;
    address[] public lenders;
    mapping(address => uint256) public lenderToBalance;
    mapping(address => Loan[]) public borrowerToLoans;
    struct Loan {
        uint256 id;
        uint256 debt; // with interest
        address borrower;
        mapping(address => uint256) lenderToDebt; // due debt with interest for each lender
    }

    modifier onlyLender() {
        if (lenderToBalance[msg.sender] == 0) {
            revert Unauthorized();
        }
        _;
    }

    constructor(uint256 _interestRate) {
        if (_interestRate == 0 || _interestRate >= 10**18) {
            /// interestRate must be ]0,1[
            revert InterestRateOutOfRange();
        }
        i_owner = payable(msg.sender);
        i_interestRate = _interestRate;
    }

    /// fallback functions
    receive() external payable {
        lend();
    }

    fallback() external payable {
        lend();
    }

    /**
     * @notice lend ETH to the contract
     */
    function lend() public payable {
        /// revert if value sent is null
        if (msg.value == 0) {
            revert AmountCanNotBeNull();
        }
        /// add new lender if not already in lenders array
        if (lenderToBalance[msg.sender] == 0) {
            lenders.push(msg.sender);
        }
        /// update lender's balance
        lenderToBalance[msg.sender] += msg.value;
    }

    /**
     * @notice borrow ETH from the contract
     * creates a new loan
     * calculates the total debt for this loan
     * calculates the debt for each lender for this loan
     */
    function borrow(uint256 _amount) external payable {
        /// revert if amount is null
        if (_amount == 0) {
            revert AmountCanNotBeNull();
        }
        /// revert if not enough ETH on contract
        if (address(this).balance < _amount) {
            revert NotEnoughFundsInContract();
        }
        /// revert if borrower has already 2 loans
        if (getBorrowerActiveLoansNumber(msg.sender) >= 2) {
            revert Max2LoansAllowed();
        }
        /// calculate debt with interest for this amount
        uint256 debtWithInterest = calculateDebtWithInterest(_amount);
        /// create Loan
        totalActiveLoanCounter++;
        uint256 borrowerLoanIndex = borrowerToLoans[msg.sender].length;
        Loan[] storage borrowerLoans = borrowerToLoans[msg.sender];
        borrowerLoans.push();
        /// update Loan
        borrowerLoans[borrowerLoanIndex].id = borrowerLoanIndex;
        borrowerLoans[borrowerLoanIndex].debt = debtWithInterest;
        borrowerLoans[borrowerLoanIndex].borrower = msg.sender;
        /// update each lender's data
        for (uint256 i = 0; i < lenders.length; i++) {
            (
                uint256 borrowedToLender,
                uint256 debtWithInterestToLender
            ) = calculateLenderData(lenders[i], _amount, debtWithInterest);
            /// update each lender's balance
            lenderToBalance[lenders[i]] -= borrowedToLender;
            /// update borrower's debt (with interest) to each lender
            borrowerLoans[borrowerLoanIndex].lenderToDebt[
                    lenders[i]
                ] = debtWithInterestToLender;
        }
        /// send ETH to borrower
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

    /**
     * @notice repay a loan : send ETH due debt to each lender
     */
    function payloan(uint8 _id) external payable {
        /// loan must exist
        if (borrowerToLoans[msg.sender].length < _id + 1) {
            revert LoanMustExist();
        }
        /// payer must be borrower
        if (borrowerToLoans[msg.sender][_id].borrower != msg.sender) {
            revert Unauthorized();
        }
        /// access loan in storage
        Loan storage targetLoan = borrowerToLoans[msg.sender][_id];
        /// must sent enough ETH to cover total debt
        if (msg.value != targetLoan.debt) {
            revert ExactDebtMustBePaid();
        }
        /// send due debt (with interest) to each lender
        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 debtWithInterestToLender = targetLoan.lenderToDebt[
                lenders[i]
            ];
            if (debtWithInterestToLender != 0) {
                (bool success, ) = payable(lenders[i]).call{
                    value: debtWithInterestToLender
                }("");
                require(success);
            }
        }
        /// delete borrower this Loan
        totalActiveLoanCounter--;
        delete borrowerToLoans[msg.sender][_id];
    }

    /**
     * @notice allows a lender to withdraw all ETH from the contract
     * sends each ETH lender's balance to each lender
     */
    function withdraw() external payable onlyLender {
        if (address(this).balance == 0) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < lenders.length; i++) {
            /// send each lender balance
            (bool success, ) = payable(lenders[i]).call{
                value: lenderToBalance[lenders[i]]
            }("");
            require(success);
            /// initialize each lender's balance
            lenderToBalance[lenders[i]] = 0;
        }
        /// initialize lenders' array
        lenders = new address[](0);
    }

    /**
     * @notice
     * calculates the total due debt with interest for a given borrowed amount
     */
    function calculateDebtWithInterest(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 _interest = (_amount * i_interestRate) / 10**18;
        return _amount + _interest;
    }

    /**
     * @notice
     * calculates the lender's amount borrowed for a given lender - total amount borrowed
     * calculates the lender's due debt with interest for a given lender - total amount borrowed
     */
    function calculateLenderData(
        address _lender,
        uint256 _totalAmountBorrowed, /// total Amount Borrowed in this loan
        uint256 _debtWithInterest /// total Amount Borrowed with interest in this loan
    ) internal view returns (uint256, uint256) {
        /// lender's amount borrowed : based on ratio of lender's balance to total contract balance
        uint256 borrowedToLender = (_totalAmountBorrowed *
            lenderToBalance[_lender]) / address(this).balance;
        /// lender's due debt with interest : based on ratio of lender's balance to total contract balance
        uint256 debtWithInterestToLender = (_debtWithInterest *
            lenderToBalance[_lender]) / address(this).balance;
        return (borrowedToLender, debtWithInterestToLender);
    }

    /**
     * @notice Getters
     * returns the number of active loans for a given borrower
     */
    function getBorrowerActiveLoansNumber(address _borrower)
        public
        view
        returns (uint8)
    {
        uint8 counter;
        for (uint8 i = 0; i < borrowerToLoans[_borrower].length; i++) {
            if (borrowerToLoans[_borrower][i].debt != 0) {
                counter++;
            }
        }
        return counter;
    }

    /**
     * @notice Getters for front end
     * returns the total number of lenders
     */
    function getNumberOfLenders() external view returns (uint256) {
        return lenders.length;
    }

    /**
     * @notice Getters for front end
     * returns the total due debt with interest for a given borrower - loan
     */
    function getBorrowerLoanDueDebt(address _borrower, uint256 _loanId)
        external
        view
        returns (uint256)
    {
        return borrowerToLoans[_borrower][_loanId].debt;
    }

    /**
     * @notice Getters for front end
     * returns the lender's due debt with interest for a given borrower - loan - lender
     */
    function getBorrowerLoanDueDebtToLender(
        address _borrower,
        uint256 _loanId,
        address _lender
    ) external view returns (uint256) {
        return borrowerToLoans[_borrower][_loanId].lenderToDebt[_lender];
    }
}