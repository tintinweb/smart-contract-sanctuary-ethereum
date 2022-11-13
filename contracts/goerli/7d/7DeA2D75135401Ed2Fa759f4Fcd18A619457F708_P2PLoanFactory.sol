// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "P2PLoan.sol";

contract P2PLoanFactory{

    address public owner;
    address[] public loaneeList;
    uint256 public call_window;
    mapping (address => LoanFactoryObject) loanFactory;
    mapping ( address => bool ) acceptableNFTs;

    mapping (address => mapping(P2PLoan => LoanDetails)) loanDetail;

    event LoanContract(P2PLoan _p2ploan, uint256 index);
    event LoanCreated(string loanCreated);
    event LoanFunded(string loanFunded);
    event LoanPayed(string loanPayed);
    event LoanCanceled(string loanCanceled);
    event ValidInterestNow(uint256 validInterestNow);
    enum InterestUpdated{INTEREST_VALUE_PERIOD_NOT_CALLED,INTEREST_VALUE_PERIOD_CALLED}
    constructor () {
        owner = msg.sender;
    }

    struct LoanFactoryObject{
        address loanee;
        P2PLoan[] p2ploans;
        mapping (P2PLoan => uint256) p2ploanIndexFromCA;
        InterestUpdated interestUpdated;
    }

    struct LoanDetails {
        address LFBorrower;
        address LFLoaner;
        uint256 LFLoanAmountInWEi;
        uint256 LFDurationOfLoan;
        uint256 LFInterestInWEI;
        uint256 validInterestNow;
    }


    function createP2PLoanContract(address _NFTAddress) public {
        require(acceptableNFTs[_NFTAddress] == true, "NFT not supported at the moment.");
        P2PLoan p2ploanContract = new P2PLoan(_NFTAddress, msg.sender);
        loanFactory[msg.sender].loanee = msg.sender;
        loanFactory[msg.sender].p2ploans.push(p2ploanContract);
        loanFactory[msg.sender].p2ploanIndexFromCA[p2ploanContract] = loanFactory[msg.sender].p2ploans.length -1;
        loanFactory[msg.sender].interestUpdated = InterestUpdated.INTEREST_VALUE_PERIOD_NOT_CALLED;
        loaneeList.push(msg.sender);
        emit LoanContract(p2ploanContract, loanFactory[msg.sender].p2ploanIndexFromCA[p2ploanContract]);
    }


    function getLoanContract(uint256 _index, address _loanee) public view returns (P2PLoan) {
        P2PLoan p2pLoanContract = P2PLoan(address(loanFactory[_loanee].p2ploans[_index]));

        return p2pLoanContract;
    }

    function listOfP2PLoans(address _loanee) public view returns(P2PLoan[] memory){
        return loanFactory[_loanee].p2ploans;
    }


    function LFCreateLoan(uint256 _index,
    uint256 _loanAmountInWEi,
    uint256 _durationOfLoan, 
    uint256 _interestInWEI, 
    uint256 _tokenID
    ) public {
        P2PLoan p2pLoanContract = getLoanContract(_index, msg.sender);
        loanDetail[msg.sender][p2pLoanContract].LFBorrower = msg.sender;
        loanDetail[msg.sender][p2pLoanContract].LFLoanAmountInWEi = _loanAmountInWEi;
        loanDetail[msg.sender][p2pLoanContract].LFDurationOfLoan = _durationOfLoan * 1 minutes;
        loanDetail[msg.sender][p2pLoanContract].LFInterestInWEI = _interestInWEI;
        p2pLoanContract.createLoan(_loanAmountInWEi, _durationOfLoan, _interestInWEI, _tokenID, msg.sender, address(p2pLoanContract),msg.sender);
        emit LoanCreated('Loan created');
    }


    function LFLoanDetail(uint256 _index, address _loanee) public view returns(LoanDetails memory) {
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        return loanDetail[_loanee][p2pLoanContract];
    }


    function LFUpdateLoanDetail(uint256 _index, 
    address _loanee, 
    uint256 _updateDurationOfLoan, 
    uint256 _updateInterestInWEI, 
    uint256 _updateLoanAmount
    ) public {
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        loanDetail[_loanee][p2pLoanContract].LFDurationOfLoan = _updateDurationOfLoan;
        loanDetail[_loanee][p2pLoanContract].LFInterestInWEI = _updateInterestInWEI;
        loanDetail[_loanee][p2pLoanContract].LFLoanAmountInWEi = _updateLoanAmount;
        p2pLoanContract.updateLoanDetail(_updateDurationOfLoan, _updateInterestInWEI, _updateLoanAmount);
    }


    function LFCancelLoan(uint256 _index, address _loanee) public{
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        p2pLoanContract.cancelLoan(address(p2pLoanContract), msg.sender);
        emit LoanCanceled('Loan canceled');
    }


    function LFFundLoan(uint256 _index, address _loanee) public payable {
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        require(msg.value == loanDetail[_loanee][p2pLoanContract].LFLoanAmountInWEi, "");
        p2pLoanContract.fundBorrower(msg.sender, msg.value);
        payable(_loanee).transfer(msg.value);   
        loanDetail[_loanee][p2pLoanContract].LFLoaner = msg.sender;
        emit LoanFunded('Loan funded');
    }


    function LFPayLoan(uint256 _index, address _loanee) public payable {
        if (block.timestamp > call_window ){
            loanFactory[msg.sender].interestUpdated = InterestUpdated.INTEREST_VALUE_PERIOD_NOT_CALLED;
        }
        require(loanFactory[_loanee].interestUpdated == InterestUpdated.INTEREST_VALUE_PERIOD_CALLED, "State Not Changed.");
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        require(msg.value == loanDetail[_loanee][p2pLoanContract].LFLoanAmountInWEi+loanDetail[_loanee][p2pLoanContract].validInterestNow, "value must be equal to loanAmount + interest");
        p2pLoanContract.payLoan(address(p2pLoanContract), msg.sender);
        payable(loanDetail[_loanee][p2pLoanContract].LFLoaner).transfer(msg.value);
        emit LoanPayed('Loan payed');
    }


    function interest(uint256 _index, address _loanee) public view returns(uint256, uint256){
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        (uint256 x, uint256 y)=p2pLoanContract.getInterest();
        return (x, y);
    }


    function interestValidPeriod(uint256 _index, address _loanee) public {
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        (uint256 x, uint256 y) = interest(_index, _loanee);
        if (block.timestamp <= y) {
            loanDetail[_loanee][p2pLoanContract].validInterestNow = x;
        }else{
            (uint256 xNow,) = interest(_index, _loanee);
            loanDetail[_loanee][p2pLoanContract].validInterestNow = xNow;
        }
        loanFactory[msg.sender].interestUpdated = InterestUpdated.INTEREST_VALUE_PERIOD_CALLED;
        call_window = block.timestamp + 1 minutes;

        emit ValidInterestNow(loanDetail[_loanee][p2pLoanContract].validInterestNow);
    }
    

    function getInterestInValidPeriod(uint256 _index, address _loanee) public view returns(uint256){
        require(loanFactory[msg.sender].interestUpdated == InterestUpdated.INTEREST_VALUE_PERIOD_CALLED, "");
        P2PLoan p2pLoanContract = getLoanContract(_index, _loanee);
        return (loanDetail[_loanee][p2pLoanContract].validInterestNow);
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function updateAcceptableNFTs(address _NFTAddress) public onlyOwner {
        acceptableNFTs[_NFTAddress] = true;
    }

    function removeNFT(address _removeNFT) public onlyOwner returns(address, string memory){
        //uint256 index = acceptableNFTsIndex[_removeNFT];
        delete acceptableNFTs[_removeNFT];

        return(_removeNFT, "Removed");
    }


}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
    //create Loan
    //quit loan if state is not change
    //deposit eth in relation to the amount of loan needed
    //see if the nft can back up the loan
    //deposit multiple NFTs

contract P2PLoan{

    address public borrower;
    address public lender;
    IERC721 public NFTContract;
    address public NFTContractAddress;
    uint256 public start;

    enum State{LOAN_CREATED, AWAITING_FUNDING, LOAN_FUNDED, LOAN_CANCLED, LOAN_PAYED, LOAN_EXPIRED}

    event CreatedLoan (uint256 loanAmount, uint256 durationOfLoan, uint256 interest, uint256 tokenID);
    event UpdatedLoan (uint256 updateDurationOfLoan, uint256 updateInterest, uint256 updateLoanAmount);
    event LoanFunded(address _sender, uint256 time, uint256 value, State _current);

    State public current_state;

    mapping(address => uint256) public loanAmountDeposited;
    mapping(IERC721 => uint256) public NFTToTokenID; //map nft to tokenID

    struct LoanDetails{
        address borrowerAddress;
        uint256 loanAmount;
        uint256  durationOfLoan;
        uint256 interest;
        uint256 tokenId;
    }

    LoanDetails public loanDetail;

    constructor (address _nftContractAddress, address _loanee){
        borrower = _loanee;
        NFTContract = IERC721(_nftContractAddress);
        NFTContractAddress = _nftContractAddress;
        current_state = State.LOAN_CREATED;
    }

    modifier onlyBorrower{
        require(msg.sender == borrower, "Only borrower can call this function.");
        _;
    }

    function createLoan(uint256 _loanAmountInWEi, 
    uint256 _durationOfLoan, 
    uint256 _interestInWEI, 
    uint256 _tokenID, 
    address _from, 
    address _to, 
    address _sender) public payable{
        require(_sender == borrower, "Only borrower can call this function.");
        require(current_state == State.LOAN_CREATED, "Loan already Created");
        NFTContract.transferFrom(_from, _to, _tokenID);
        NFTToTokenID[NFTContract] = _tokenID;
        loanDetail.borrowerAddress = borrower;
        loanDetail.loanAmount = _loanAmountInWEi;
        loanDetail.interest = _interestInWEI;
        loanDetail.tokenId = _tokenID;
        loanDetail.durationOfLoan = _durationOfLoan * 1 minutes;
        current_state = State.AWAITING_FUNDING;

        emit CreatedLoan(_loanAmountInWEi, loanDetail.durationOfLoan, _interestInWEI, _tokenID);
    }

    // Update Loan loanDetail
    function updateLoanDetail(uint256 _updateDurationOfLoan, uint256 _updateInterestInWEI, uint256 _updateLoanAmount) public {
        require(current_state == State.AWAITING_FUNDING,"");
        loanDetail.durationOfLoan =(_updateDurationOfLoan * 1 minutes);
        loanDetail.loanAmount = _updateLoanAmount;
        loanDetail.interest = _updateInterestInWEI;

        emit UpdatedLoan(_updateDurationOfLoan, _updateInterestInWEI, _updateLoanAmount);
    }


    function cancelLoan(address _from, address _sender) public{
        require(_sender == borrower, "Only borrower can call this function.");
        require(current_state == State.AWAITING_FUNDING || current_state ==State.LOAN_CANCLED , "Loan is already Funded");
        NFTContract.transferFrom(_from, borrower, NFTToTokenID[NFTContract]);
        current_state = State.LOAN_CANCLED;
    }


    
    function fundBorrower(address _sender, uint256 _value) public payable{
        require(current_state == State.AWAITING_FUNDING, "");
        //require(msg.value == loanDetail.loanAmount, "Value has too be equal to loan Amount");
        lender = _sender;
        loanAmountDeposited[lender] = _value;
        start = block.timestamp;
        loanDetail.durationOfLoan = start + loanDetail.durationOfLoan;
        current_state = State.LOAN_FUNDED;
        emit LoanFunded(lender, loanDetail.durationOfLoan, loanDetail.loanAmount, current_state);
    }


    function payLoan(address _from, address _sender) public payable {
        require(current_state == State.LOAN_FUNDED, "Loan is yet to be funded.");
        require(_sender == borrower, "Only borrower can call this function.");
        if (block.timestamp >= loanDetail.durationOfLoan) {
            loanExpired();
        }else{
            //require(_value == loanDetail.loanAmount, "Value has too be equal to loanAmount+interest");
            // transfer _from NFT contract to borrower if loan has not expired.
            NFTContract.transferFrom(_from, borrower, NFTToTokenID[NFTContract]);
        }
        current_state = State.LOAN_PAYED;
        // send money back with interest
    }


    function loanExpired() public {
        require(block.timestamp >= loanDetail.durationOfLoan, "Time Is not over");
        require(current_state == State.LOAN_FUNDED);
        NFTContract.transferFrom(address(this), lender, NFTToTokenID[NFTContract]);
        // send nft to lender when loan expires
    }


    function getInterest() public view returns(uint256 interestToBePaid, uint256 validStart) {
        //require (block.timestamp <= loanDetail.durationOfLoan, );
        require(current_state == State.LOAN_FUNDED, "");
        if (block.timestamp < loanDetail.durationOfLoan) {
            uint256 timeRemaining = (loanDetail.durationOfLoan - block.timestamp);
            uint256 interestRate = loanDetail.interest;
            validStart = block.timestamp + 1 minutes;
            // startTime == interestRate;
            // timeRemaining == newInterest;
            uint256 loanDuration = loanDetail.durationOfLoan - start;
            uint256 timeRemainingNow = loanDuration - timeRemaining;
            uint256 newInterest = (timeRemainingNow * interestRate)/loanDuration;
            interestToBePaid = (loanDetail.loanAmount * newInterest)/ 1 ether;
            //interestNow = interestToBePaid;
            return(interestToBePaid, validStart);
        }else {
            uint256 newInterest = loanDetail.interest;
            interestToBePaid = (loanDetail.loanAmount * newInterest)/ 1 ether;
            return(interestToBePaid, validStart);
        }
        // assume that the timestamp is in seconds
        // it's in wei
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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