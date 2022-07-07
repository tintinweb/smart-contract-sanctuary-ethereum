/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}

interface IERC721 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function totalSupply() external returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransfer(address _to, uint256 _tokenId) external;

    function safeMint(
        string calldata _name,
        string calldata _description,
        string calldata _imageURI
    ) external payable returns(uint256);

    function setPrice(uint256 _price) external;

    function getPrice() external view returns (uint256);

    function getMetadata(uint256 _tokenId)
        external
        view
        returns (
            string memory _name,
            string memory _description,
            string memory _imageURI
        );
}

interface IERC721Receiver {
    function onERC721Received(address _from, uint256 _tokenId)
        external
        returns (bytes4);
}

contract LoanContract is Ownable, IERC721Receiver {
    IERC721 private nftContractAddress;
    uint256 private loanAmount;
    uint256 private loanInterest;
    uint256 private deadlineTime;
    uint256 private promisedLoanedAmount;
    uint256 private profit;

    mapping(address => uint256) private accountLoans;
    mapping(uint256 => uint256) private tokenIdLoans;
    Loan[] loans;

    uint256 constant emptyLoanContract = 0;

    struct Loan {
        uint256 loanId;
        uint256 tokenId;
        address loanedAddress;
        uint256 loanAmount;
        uint256 amountPaid;
        LoanStatus status;
        uint256 deadlineDateTime;
        uint256 loanInterestSnapshot;
        bool loanWithdrawed;
        bool nftWithdrawed;
    }

    enum LoanStatus {
        PENDING,
        APPROVED,
        PAID
    }

    modifier noActiveLoan() {
        Loan memory activeLoan = loans[accountLoans[msg.sender]];
        require(
            accountLoans[msg.sender] == emptyLoanContract ||
                activeLoan.status == LoanStatus.PAID,
            'Account already has an active Loan'
        );
        _;
    }

    constructor(
        address _nftContractAddress,
        uint256 _deadlineTime,
        uint256 _loanInterest
    ) payable {
        // Avoid using loan in position 0
        loans.push();

        deadlineTime = _deadlineTime;
        loanInterest = _loanInterest;
        nftContractAddress = IERC721(_nftContractAddress);
    }

    /**
     * @dev This method allows to set a new loan amount per NFT Loaned
     * Notes: Only the owner can call it
     */
    function setLoanAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, 'Loan amount must be a positive number');
        require(loanAmount != newAmount, 'New loan amount must be different');

        loanAmount = newAmount;
    }

    function getLoanAmount() external view returns (uint256) {
        return loanAmount;
    }

    /**
     * @dev Users may request a new loan using this method
     * Notes: Only the owner can call it
     */
    function requestLoan(uint256 token_id) external noActiveLoan {
        require(
            address(this).balance >
                (promisedLoanedAmount + loanAmount - profit),
            "The contract doesn't have liquidity for a new loan"
        );
        require(loanAmount > 0, 'The contract is not ready for issuing loans');
        require(
            checkOwner(token_id),
            'The sender is not the owner of the token'
        );

        Loan memory newLoan;
        newLoan.loanId = loans.length;
        newLoan.tokenId = token_id;
        newLoan.loanedAddress = msg.sender;
        newLoan.loanAmount = loanAmount;
        newLoan.status = LoanStatus.PENDING;
        newLoan.deadlineDateTime = block.timestamp + deadlineTime;
        newLoan.loanInterestSnapshot = loanInterest;
        loans.push(newLoan);

        accountLoans[msg.sender] = newLoan.loanId;
        tokenIdLoans[token_id] = newLoan.loanId;
        promisedLoanedAmount += loanAmount;
    }

    /**
     * @dev Check an user load status
     */
    function getLoanStatus() external view returns (string memory) {
        require(
            accountLoans[msg.sender] != emptyLoanContract,
            'No loan for active account'
        );

        Loan memory loan = loans[accountLoans[msg.sender]];
        if (loan.status == LoanStatus.PENDING) {
            return 'Pending';
        } else if (loan.status == LoanStatus.APPROVED) {
            return 'Approved';
        } else {
            return 'Paid';
        }
    }

    /**
     * @dev Allow user to withdraw his loan
     */
    function withdrawLoanAmount() external {
        require(accountLoans[msg.sender] != 0, 'Sender doesnt have any loan');
        Loan storage loan = loans[accountLoans[msg.sender]];
        require(!loan.loanWithdrawed, 'User already withdraw the loan');

        // Is this possible given the current implementation?
        require(
            address(this).balance - profit > loan.loanAmount,
            'Loan Contract ran out of liquidity'
        );

        loan.loanWithdrawed = true;
        payable(msg.sender).transfer(loan.loanAmount);
    }

    /**
     * @dev Check the owner of an NFT
     */
    function checkOwner(uint256 _token_id) private view returns (bool) {
        IERC721 nftContract = IERC721(nftContractAddress);
        address realOwner = nftContract.ownerOf(_token_id);
        return realOwner == msg.sender;
    }

    /**
     * @dev ERC 721 receive standard method
     */
    function onERC721Received(address _from, uint256 _tokenId)
        external
        returns (bytes4)
    {
        require(
            msg.sender == address(nftContractAddress),
            'NFT Contract mismatch'
        );
        require(
            accountLoans[_from] != emptyLoanContract,
            'NFT Sender doesnt have any pending loan'
        );

        Loan memory loan = loans[accountLoans[_from]];
        require(
            loan.status == LoanStatus.PENDING,
            'Loan is not in pending status'
        );
        require(loan.tokenId == _tokenId, 'Token received is wrong');

        // NFT Received -> Loan approved
        loans[accountLoans[_from]].status = LoanStatus.APPROVED;
        return bytes4(keccak256('onERC721Received(address,uint256)'));
    }

    /**
     * @dev Owner can change future loans deadline using this method
     * Notes: Only the owner can call it,
     * New deadline must be greater than zero.
     */
    function setDeadline(uint256 _newDeadline) external onlyOwner {
        require(_newDeadline > 0, 'Deadline must be greater than zero.');
        require(
            _newDeadline != deadlineTime,
            'New deadline must be different.'
        );
        deadlineTime = _newDeadline;
    }

    /**
     * @dev User can see his loan deadline using this method
     */
    function getDeadline() external view returns (uint256) {
        uint256 loanId = accountLoans[msg.sender];
        require(loanId != 0, "You don't have a loan");

        return loans[loanId].deadlineDateTime;
    }

    /**
     * @dev Returns the current debt for an user
     */
    function getDebt() external view returns (uint256) {
        uint256 loanId = accountLoans[msg.sender];
        require(loanId != emptyLoanContract, "You don't have a loan");
        require(
            block.timestamp < loans[loanId].deadlineDateTime,
            'Loan has Expired'
        );

        Loan memory loan = loans[loanId];

        return
            ((loan.loanAmount - loan.amountPaid) *
                (100 + loan.loanInterestSnapshot)) / 100;
    }

    /**
     * @dev Returns information about a loan
     * Can only be called by the Owner
     * Id's start at 1
     */
    function getLoanInformation(uint256 _loan_id)
        external
        view
        onlyOwner
        returns (Loan memory)
    {
        require(
            _loan_id != 0 && _loan_id <= loans.length,
            'Loan does not exist'
        );
        return loans[_loan_id];
    }

    /**
     * @dev Returns the amount of loans created
     * Can only be called by the Owner
     */
    function getNumberOfLoans() external view onlyOwner returns (uint256) {
        return loans.length - 1;
    }

    function _isLoanOverdue(Loan memory _loan) private view returns (bool) {
        return _loan.deadlineDateTime <= block.timestamp;
    }

    receive() external payable {}

    /**
     * @dev User should pay the loan sending ethers to the contract
     * Notes: If the loan is completed, the loan is marked as paid.
     * Notes: In case the payer sends more than the loan amount,
         the remaining amount will be returned to the payer.
     */
    function payment() external payable {
        uint256 loanIndex = accountLoans[msg.sender];
        require(loanIndex != emptyLoanContract, "You don't have a loan");

        Loan storage activeLoan = loans[loanIndex];
        require(
            activeLoan.status == LoanStatus.APPROVED,
            'Your loan is either pending or payed'
        );
        require(!_isLoanOverdue(activeLoan), 'Your loan is overdue');
        require(activeLoan.loanWithdrawed, "Your loan isn't withdrawed");

        // If we pay less than 100 wei, we don't collect interest
        uint256 payedInterest = (msg.value / 100) *
            activeLoan.loanInterestSnapshot;

        uint256 deductedAmount = msg.value - payedInterest;

        uint256 newAmountPaid = activeLoan.amountPaid + deductedAmount;

        // Save profit amount
        profit += payedInterest;

        if (newAmountPaid >= activeLoan.loanAmount) {
            activeLoan.amountPaid = activeLoan.loanAmount;
            activeLoan.status = LoanStatus.PAID;
        } else {
            activeLoan.amountPaid = newAmountPaid;
        }

        // In case the new payed amount is greater than the loan value
        // it means that the user is paying more than necessary
        if (newAmountPaid > activeLoan.loanAmount) {
            // We return only the overflow from the amount paid (without the interest)
            payable(msg.sender).transfer(
                uint256(newAmountPaid - activeLoan.loanAmount)
            );
        }
    }

    function setInterest(uint256 _newInterest) external onlyOwner {
        require(_newInterest > 0, 'Interest must be greater than zero.');
        require(
            _newInterest != loanInterest,
            'Interest must be different than previous one.'
        );

        loanInterest = _newInterest;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(
            profit >= _amount,
            'The amount to be withdraw cannot be greater than the profits obtained'
        );
        // This is impossible given the current implementation
        require(
            address(this).balance >= _amount,
            'The contract doesnt have liquidity to withdraw profit'
        );
        profit -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function withdrawNFT() external {
        uint256 loanIndex = accountLoans[msg.sender];
        require(loanIndex != emptyLoanContract, "You don't have a loan");

        Loan storage activeLoan = loans[loanIndex];
        require(
            activeLoan.status == LoanStatus.PAID,
            'Your loan is not paid yet'
        );
        require(!activeLoan.nftWithdrawed, 'Your NFT was already withdrawn');

        activeLoan.nftWithdrawed = true;

        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransfer(activeLoan.loanedAddress, activeLoan.tokenId);
    }

    /**
     * @dev Owner can take ownership of the token once loan is expired
     * Notes: Only the owner can call it
     */
    function takeOwnership(uint256 _token_id) public {
        //Validate tokenId and loan
        uint256 loanId = tokenIdLoans[_token_id];
        require(loanId != 0, 'There is no loan related for that tokenId');
        Loan storage activeLoan = loans[loanId];
        require(
            activeLoan.status == LoanStatus.APPROVED,
            'Loan is either pending or already payed'
        );
        require(_isLoanOverdue(activeLoan), 'Loan still active');

        // Transfer token to contract owner
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransfer(owner, _token_id);

        // Set loan as paid
        activeLoan.status = LoanStatus.PAID;
    }
}