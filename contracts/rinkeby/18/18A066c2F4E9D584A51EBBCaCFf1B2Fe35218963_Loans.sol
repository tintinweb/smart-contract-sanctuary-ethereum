//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Loans {
    // Represents a loan. The struct fields will update as the loan changes
    struct Loan {
        uint256 amount;
        uint256 interestPercentage;
        uint256 interestAmount;
        uint256 duration;
        // Logs the timestamp in order to determine when the loan expires.
        uint256 timestampStart;
        uint256 forSalePrice;
        uint256 loanFractionPercentage;
        uint256 loanFractionAmount;
        address fractionalOwner;
        bool isProposed;
        bool isActive;
        bool isForSale;
    }
    // Tracks addresses that cannot participate in the marketplace
    mapping(address => bool) public isBlacklisted;
    // Tracks who has loan proposals
    mapping(address => Loan) public proposedLoans;
    // Tracks loans that have been filled
    mapping(address => mapping(address => Loan)) public activeLoans;

    event Proposal(
        uint256 amount,
        uint256 interestPercentage,
        uint256 duration,
        address indexed proposer
    );
    event ProposalFilled(address indexed lender, address indexed borrower);
    event Blacklisted(address indexed indebted);

    // Users can create loan proposals if their address is not blacklisted
    function proposeLoan(
        uint256 _amount,
        uint256 _interesetRatePercent,
        uint256 _duration
    ) external blackListedCheck {
        require(
            !proposedLoans[msg.sender].isProposed,
            "Proposal already exists"
        );
        // Calculates the interest rate amount in ETH based on the interest percentage
        uint256 interestRateAmount = (_amount *
            _interesetRatePercent *
            10**18) / (100 * 10**18);
        // Sets loan struct to reflect loan proposal
        proposedLoans[msg.sender] = Loan(
            _amount,
            _interesetRatePercent,
            interestRateAmount,
            //Converts input days into seconds
            _duration * 86400,
            0,
            0,
            0,
            0,
            address(0),
            true,
            false,
            false
        );
        emit Proposal(_amount, _interesetRatePercent, _duration, msg.sender);
    }

    // Users can fill a loan proposal if their address is not blacklisted
    function lend(address payable _borrower) public payable blackListedCheck {
        // Confirms that the current loan proposal exists
        require(
            proposedLoans[_borrower].isProposed,
            "Account has no active loan proposals"
        );
        /* 
        1) Maps the lender to the borrower.
        2) Logs the current time stamp
        3) Changes isProposed to false
        4) Changes isActive to true
        All other loan struct fields match the proposal
        */
        activeLoans[msg.sender][_borrower] = Loan(
            proposedLoans[_borrower].amount,
            proposedLoans[_borrower].interestPercentage,
            proposedLoans[_borrower].interestAmount,
            proposedLoans[_borrower].duration,
            // Locks the current timestamp to the loan
            block.timestamp,
            0,
            0,
            0,
            address(0),
            false,
            true,
            false
        );
        // Deletes proposed loan
        delete proposedLoans[_borrower];
        // Transfers the asking amount from lender to loan proposer (borrower)
        (bool success, ) = _borrower.call{
            value: activeLoans[msg.sender][_borrower].amount
        }("");
        require(success, "Transaction failed");
        emit ProposalFilled(msg.sender, _borrower);
    }

    // Borrowers can payback their debts
    function payback(address payable _lender) public payable {
        require(
            activeLoans[_lender][msg.sender].isActive,
            "Nonexistant loan cannot be paid back"
        );
        /* 
        Determines whether the loan is fractional or not
        by checking whether the fractional address on the 
        loan is the zero address or not. 
        The if block will run if the loan IS fractional. 
        */
        if (activeLoans[_lender][msg.sender].fractionalOwner != address(0)) {
            require(
                msg.value ==
                    activeLoans[_lender][msg.sender].amount +
                        activeLoans[_lender][msg.sender].loanFractionAmount,
                "Amount paid back must be exact"
            );
            // Transfers amount owed to lender from borrower
            (bool success, ) = _lender.call{
                value: activeLoans[_lender][msg.sender].amount
            }("");
            require(success, "Transaction failed");
            // Transfers amount owed to fractional owner from borrower
            (bool accept, ) = activeLoans[_lender][msg.sender]
                .fractionalOwner
                .call{
                value: activeLoans[_lender][msg.sender].loanFractionAmount
            }("");
            require(accept, "Transaction failed");
            // Deletes the active loan
            delete activeLoans[_lender][msg.sender];
            // The else block is ran if the loan was never fractionally sold
        } else {
            /*
            The loans total debt is assigned in a variable so 
            that the operation does not have to happen twice. 
            */
            uint256 totalDebtFull = activeLoans[_lender][msg.sender].amount +
                activeLoans[_lender][msg.sender].interestAmount;
            require(
                msg.value == totalDebtFull,
                "Amount paid back must be exact"
            );
            // Transfers amount owed to lender from borrower
            (bool success, ) = _lender.call{value: totalDebtFull}("");
            require(success, "Transaction failed");
            // Deletes the active loan
            delete activeLoans[_lender][msg.sender];
        }
    }

    /*
    Lenders have the right to sell a portion of the loan to a buyer. They can
    either sell a fraction of the loan, or it's entirety. If the lender sells
    a percent portion of the loan, they remain the initial lender, and the fractional
    buyer gets added to the loan. All active loans can only have one fractional owner.
    If a lender sells 100 percent of the loan, a buyer will become the 
    new lender, and is free sell any amount of the loan if they choose
    to do so. 
    */
    function listLoan(
        address _borrower,
        uint256 _salePrice,
        uint256 _loanFraction
    ) external blackListedCheck {
        require(
            activeLoans[msg.sender][_borrower].isActive,
            "You do not have the rights to sell this loan"
        );
        // Checks whether the loan has already been listed or not
        require(
            activeLoans[msg.sender][_borrower].fractionalOwner == address(0),
            "Loan can only be sold once"
        );
        // Sets the loan's for sale price
        activeLoans[msg.sender][_borrower].forSalePrice = _salePrice;
        // Sets the fractional percentage of loan for sale
        activeLoans[msg.sender][_borrower]
            .loanFractionPercentage = _loanFraction;
        // Changes loan from being NOT for sale to FOR sale.
        activeLoans[msg.sender][_borrower].isForSale = true;
    }

    // Users can buy full loan from a lender
    function buyLoan(address payable _lender, address _borrower)
        external
        payable
        blackListedCheck
        correctETHForSalePrice(_lender, _borrower)
        isForSale(_lender, _borrower)
    {
        // A new loan is created with the same fields as the original loan
        activeLoans[msg.sender][_borrower] = activeLoans[_lender][_borrower];
        // The necessary loan fields are reset to make the loan no longer for sale
        activeLoans[msg.sender][_borrower].loanFractionPercentage = 0;
        activeLoans[msg.sender][_borrower].forSalePrice = 0;
        activeLoans[msg.sender][_borrower].isForSale = false;
        // The original lenders loan is deleted
        delete activeLoans[_lender][_borrower];
        // Buyer transfers ETH to the original lender
        (bool success, ) = _lender.call{value: msg.value}("");
        require(success, "Transaction failed");
    }

    // Users can buy portions of loans from lenders if available
    function buyLoanFraction(
        address payable _lender,
        address _borrower,
        // fractionalLoanAmount and newBaseLoanAmount are determined from front end
        uint256 fractionalLoanAmount,
        uint256 newBaseLoanAmount
    )
        external
        payable
        blackListedCheck
        correctETHForSalePrice(_lender, _borrower)
        isForSale(_lender, _borrower)
    {
        //Assigns amounts and percentage split of target loan and updates struct fields
        activeLoans[_lender][_borrower]
            .loanFractionAmount = fractionalLoanAmount;
        activeLoans[_lender][_borrower].amount = newBaseLoanAmount;
        activeLoans[_lender][_borrower].isForSale = false;
        activeLoans[_lender][_borrower].fractionalOwner = msg.sender;
        (bool success, ) = _lender.call{value: msg.value}("");
        require(success, "Transaction failed");
    }

    // Deletes a loan proposal if loan is currently proposed
    function deleteLoanProposal() public {
        require(
            proposedLoans[msg.sender].isProposed,
            "Loan proposal does not exist"
        );
        delete proposedLoans[msg.sender];
    }

    /*
    If an active loan exceeds duration, the lender can blacklist the borrower.
    This will prevent the borrower from using any function within smart contract.
    */
    function blacklistAddress(address _borrower) external {
        require(activeLoans[msg.sender][_borrower].isActive, "Loan not active");
        require(
            block.timestamp >=
                activeLoans[msg.sender][_borrower].timestampStart +
                    activeLoans[msg.sender][_borrower].duration,
            "Loan has not expired yet"
        );
        isBlacklisted[_borrower] = true;
        emit Blacklisted(_borrower);
    }

    // Enables anyone to view a one loan proposal at a time.
    function viewLoanProposals(address _borrower)
        public
        view
        returns (Loan memory)
    {
        return proposedLoans[_borrower];
    }

    // Enables anyone to view one active loan at a time.
    function viewActiveLoans(address _lender, address _borrower)
        public
        view
        returns (Loan memory)
    {
        return activeLoans[_lender][_borrower];
    }

    // Checks if msg.sender is blacklisted
    modifier blackListedCheck() {
        require(
            isBlacklisted[msg.sender] == false,
            "This address is blacklisted"
        );
        _;
    }

    // Confirms that msg.sender is sending the correct msg.value with transaction
    modifier correctETHForSalePrice(address _lender, address _borrower) {
        require(
            msg.value == activeLoans[_lender][_borrower].forSalePrice,
            "Incorrect ether amount"
        );
        _;
    }

    // Confirms that the loan msg.sender is looking for is for sale
    modifier isForSale(address _lender, address _borrower) {
        require(
            activeLoans[_lender][_borrower].isForSale,
            "Active loan is not for sale"
        );
        _;
    }
}