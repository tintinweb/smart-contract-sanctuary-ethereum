// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

error CreditFund_MinimumRequirements();
error CreditFund_BalanceSmallerThanLoanAmount();

contract CreditFund {
    //Lender
    address payable private lender;

    //Borrower
    address private borrower;

    //Mapping (Lender => Borrower)
    mapping(address => address) public loanAgreementParties;
    mapping(address => uint256) public balances;

    //1. Loan Amount: The Lender agrees to lend the Borrower the sum of [$__] (“Loan Amount”)
    uint public loanAmount;

    //2. Repayment: The Borrower agrees to repay the Loan Amount, plus any accrued interest, in [number] equal monthly installments of [$__] each, beginning on [Date] and ending on [Date].
    uint public minPayment;
    uint public installments;
    string public firstDate;
    string public lastDate;

    //3. Interest: The Borrower will pay interest on the unpaid balance of the Loan Amount at a rate of [X]% per year.
    uint public interest;

    //4. Default: If the Borrower fails to make any payment when due, the Lender may declare the entire balance of the Loan Amount, together with all accrued interest, immediately due and payable.

    //5. Collateral: The Borrower agrees to pledge [collateral] as collateral for the loan. If the Borrower defaults on the loan, the Lender may seize the collateral to satisfy the unpaid balance of the loan.

    //6. Governing Law: This Contract shall be governed by the laws of the state of [State]

    // Events
    event Payment(address indexed borrower, uint256 indexed amount);

    // Constructor
    constructor(address payable _lender) {
        lender = _lender;
    }

    //Functions

    //Borrower deposit that only borrower can access
    function deposit(uint256 value) public payable {
        require(value > 0, "Cannot deposit a value of zero or less");

        // Add the deposit to the borrower's balance
        balances[borrower] += value;

        // Emit an event to let other contracts know that a deposit has been made
        emit Payment(borrower, value);
    }

    //Credit loan payment from borrower to lender
    function loanPayment(uint amount) external payable {
        if (getMinimumPayment() >= amount)
            revert CreditFund_MinimumRequirements();
        if (balances[borrower] < amount)
            revert CreditFund_BalanceSmallerThanLoanAmount();
        //Add amount to lender balance
        emit Payment(borrower, amount);
        balances[lender] += amount;
        // require(success, "Loan payment failed");
    }

    //Changes the lender address
    function changeLender(address payable issuer) public onlyLender {
        lender = issuer;
    }

    //Setters

    function setBorrower(address _borrower) public {
        borrower = _borrower;
    }

    function setLoanAmount(uint amount) public onlyLender {
        loanAmount = amount;
    }

    function setInstallments(uint amount) public onlyLender {
        installments = amount;
    }

    function setMinimumPayment(uint min) public {
        minPayment = min;
    }

    function setStartingDate(string memory date1) public onlyLender {
        firstDate = date1;
    }

    function setDueDate(string memory date2) public onlyLender {
        lastDate = date2;
    }

    // Getters

    function getLoanAmount() public view returns (uint) {
        return loanAmount;
    }

    function getInstallments() public view returns (uint) {
        return installments;
    }

    function getMinimumPayment() public view returns (uint) {
        return minPayment;
    }

    function getStartingDate() public view returns (string memory) {
        return firstDate;
    }

    function getDueDate() public view returns (string memory) {
        return lastDate;
    }

    function getLenderBalance() public view returns (uint) {
        return balances[lender];
    }

    function getBorrowerBalance() public view returns (uint) {
        return balances[borrower];
    }

    function getLender() public view returns (address) {
        return lender;
    }

    function getBorrower() public view returns (address) {
        return borrower;
    }

    //Modifier
    // Verification of lender
    modifier onlyLender() {
        require(lender == msg.sender, "Only the lender can modify");
        _;
    }
    modifier onlyBorrower() {
        require(
            borrower == msg.sender,
            "Only the borrower can make a loan payment"
        );
        _;
    }
}