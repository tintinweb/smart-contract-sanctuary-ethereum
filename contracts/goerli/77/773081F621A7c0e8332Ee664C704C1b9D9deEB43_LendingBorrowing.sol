// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error InterestRateOutOfRange();
error Unauthorized();
error NotEnoughFunds();
error AmountSentCanNotBeNull();
error Max2LoansAllowed();
error LoanMustExist();
error TotalLoanMustBePaid();

/** @title LendingBorrowing : contract for lending&borrowing ETH.
 *  @author SiegfriedBz
 *  @notice This contract allows lenders to receive interests on loans, as a function of each lender balance at the time a loan is created.
 *  @notice This contract allows borrowers to create a max of 2 active loans at a given time.
 */
contract LendingBorrowing {
    uint256 public immutable i_interestRate;
    uint256 public activeLoanCounter;
    address payable public immutable i_owner;
    address[] public lenders;
    mapping(address => uint256) public lenderToBalance;
    mapping(address => Loan[]) public borrowerToLoans;

    struct Loan {
        uint256 id;
        uint256 debt; // with interest
        address borrower;
        mapping(address => uint256) lenderToDebt;
    }

    modifier onlyLender() {
        if (lenderToBalance[msg.sender] == 0) {
            revert Unauthorized();
        }
        _;
    }

    constructor(uint256 _interestRate) {
        if (_interestRate == 0 || _interestRate >= 10**18) {
            // interestRate must be ]0,1[
            revert InterestRateOutOfRange();
        }
        i_owner = payable(msg.sender);
        i_interestRate = _interestRate;
    }

    receive() external payable {
        lend();
    }

    fallback() external payable {
        lend();
    }

    function lend() public payable {
        if (msg.value == 0) {
            revert AmountSentCanNotBeNull();
        }
        if (lenderToBalance[msg.sender] == 0) {
            // create new lender
            lenders.push(msg.sender);
        }
        // update lender's balance
        lenderToBalance[msg.sender] += msg.value;
    }

    function borrrow(uint256 _amount) public payable {
        // revert if not enough ETH on contract
        if (address(this).balance < _amount) {
            revert NotEnoughFunds();
        }
        // revert if borrower has already 2 loans
        if (getBorrowerActiveLoansNumber() >= 2) {
            revert Max2LoansAllowed();
        }
        // calculate debt with interest
        uint256 totalDebt = calculateDebt(_amount);
        // create Loan
        activeLoanCounter++;
        uint256 borrowerLoansCounter = borrowerToLoans[msg.sender].length;
        Loan[] storage borrowerLoans = borrowerToLoans[msg.sender];
        borrowerLoans.push();
        borrowerLoans[borrowerLoansCounter].id = borrowerLoansCounter;
        borrowerLoans[borrowerLoansCounter].debt = totalDebt;
        borrowerLoans[borrowerLoansCounter].borrower = msg.sender;
        // update lenders' data
        for (uint256 i = 0; i < lenders.length; i++) {
            (
                uint256 debtToLender,
                uint256 debtWithInterestToLender
            ) = calculateLenderData(lenders[i], _amount, totalDebt);
            lenderToBalance[lenders[i]] -= debtToLender;
            borrowerLoans[borrowerLoansCounter].lenderToDebt[
                    lenders[i]
                ] = debtWithInterestToLender;
        }
        // send ETH to borrower
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

    function payloan(uint8 _id) public payable {
        // loan must exist
        if (borrowerToLoans[msg.sender].length < _id + 1) {
            revert LoanMustExist();
        }
        // must sent enough ETH to cover total debt
        Loan storage targetLoan = borrowerToLoans[msg.sender][_id];
        if (msg.value != targetLoan.debt) {
            revert TotalLoanMustBePaid();
        }
        // send due debt to each lender
        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 dueDebt = targetLoan.lenderToDebt[lenders[i]];
            if (dueDebt != 0) {
                (bool success, ) = payable(lenders[i]).call{value: dueDebt}("");
                require(success);
            }
        }
        // delete borrower this Loan
        activeLoanCounter--;
        delete borrowerToLoans[msg.sender][_id];
    }

    function withdraw() external payable onlyLender {
        if (address(this).balance == 0) {
            revert NotEnoughFunds();
        }
        for (uint256 i = 0; i < lenders.length; i++) {
            // send each lender balance
            (bool success, ) = payable(lenders[i]).call{
                value: lenderToBalance[lenders[i]]
            }("");
            // initialize each lender's balance
            lenderToBalance[lenders[i]] = 0;
            require(success);
        }
        // initialize lenders' array
        lenders = new address[](0);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getNumberOfLenders() external view returns (uint256) {
        return lenders.length;
    }

    function calculateDebt(uint256 _amount) internal view returns (uint256) {
        uint256 _interest = (_amount * i_interestRate) / 10**18;
        return _amount + _interest;
    }

    function calculateLenderData(
        address _lender,
        uint256 _amount,
        uint256 _totalDebt
    ) internal view returns (uint256, uint256) {
        uint256 ratio = (lenderToBalance[_lender] * 10**2) /
            address(this).balance;
        uint256 debtToLender = (_amount * ratio) / 10**2;
        uint256 debtWithInterestToLender = (_totalDebt * ratio) / 10**2;
        return (debtToLender, debtWithInterestToLender);
    }

    function getDueDebtForLoan(uint256 _loanId) public view returns (uint256) {
        return borrowerToLoans[msg.sender][_loanId].debt;
    }

    function getBorrowerActiveLoansNumber() public view returns (uint8) {
        uint8 counter;
        for (uint8 i = 0; i < borrowerToLoans[msg.sender].length; i++) {
            if (borrowerToLoans[msg.sender][i].debt != 0) {
                counter++;
            }
        }
        return counter;
    }
}