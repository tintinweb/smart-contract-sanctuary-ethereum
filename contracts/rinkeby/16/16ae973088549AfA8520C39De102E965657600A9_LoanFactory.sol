// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LoanFactory {

  event SubmitLoan(
    uint256 indexed id,
    address indexed lender,
    address indexed borrower,
    uint256 amount,
    uint256 interest,
    Token collateral,
    uint256 deadline
  );

  event ConfirmLender(uint256 indexed id, address indexed lender);
  event ConfirmBorrower(uint256 indexed id, address indexed borrower);

  event ActivateLoan(uint256 indexed id);

  event RevokeConfirmation(uint256 indexed id, address indexed revoker);

  event ExecuteLoan(uint256 indexed id, bool paidBack);

  struct Token {
    address contractAddress;
    uint256 tokenId;
  } 

  struct Loan {
    address payable lender;
    address borrower;
    uint256 amount;
    uint256 interest;
    Token collateral;
    uint256 deadline;
    bool lenderConfirmed;
    bool borrowerConfirmed;
    bool active;
    bool executed;
  }

  Loan[] private loans;

  modifier loanExists(uint256 _id) {
    require(_id < loans.length, "This loan does not exist");
    _;
  }

  modifier notActive(uint256 _id) {
    require(!loans[_id].active, "This loan is already active");
    _;
  }

  modifier notExecuted(uint256 _id) {
    require(!loans[_id].executed, "This loan was already executed");
    _;
  }

  modifier deadlineAhead(uint256 _id) {
    require(loans[_id].deadline >= block.timestamp, "This loans deadline is exceeded");
    _;
  }

  modifier isActive(uint256 _id) {
    require(loans[_id].active, "This loan is not active");
    _;
  }

  modifier isLender(uint256 _id) {
    require(loans[_id].lender == msg.sender, "You are not the lender of this loan");
    _;
  }

  modifier isBorrower(uint256 _id) {
    require(loans[_id].borrower == msg.sender, "You are not the borrower of this loan");
    _;
  }

  function submitLoan(address payable _lender, address _borrower, uint256 _amount, uint256 _interest, Token memory _collateral, uint256 _deadline) public returns (uint256) {
    // Uncomment after tests are done
    // require(_deadline > block.timestamp, "Deadline can not be in the past");

    uint256 id = loans.length;

    loans.push(
      Loan({
        lender: _lender,
        borrower: _borrower,
        amount: _amount,
        interest: _interest,
        collateral: _collateral,
        deadline: _deadline,
        lenderConfirmed: false,
        borrowerConfirmed: false,
        active: false,
        executed: false
      })
    );

    emit SubmitLoan(id, _lender, _borrower, _amount, _interest, _collateral, _deadline);

    return id;
  }

  function confirmLender(uint256 _id) external payable loanExists(_id) notActive(_id) notExecuted(_id) isLender(_id) deadlineAhead(_id) {
    Loan storage loan = loans[_id];

    require(!loan.lenderConfirmed, "You already confirmed this loan");
    require(msg.value == loan.amount, "Please send the amount you agreed to loaning out");

    loan.lenderConfirmed = true;

    // Activating loan
    if (loan.lenderConfirmed && loan.borrowerConfirmed) activateLoan(_id);

    emit ConfirmLender(_id, msg.sender);
  }

  function confirmBorrower(uint256 _id) public loanExists(_id) notActive(_id) notExecuted(_id) isBorrower(_id) deadlineAhead(_id) {
    Loan storage loan = loans[_id];
    require(!loan.borrowerConfirmed, "You already confirmed this loan");
    
    IERC721 collateral = IERC721(loan.collateral.contractAddress);
    require(collateral.isApprovedForAll(msg.sender, address(this)), "Token is not approved for this contract");

    collateral.transferFrom(msg.sender, address(this), loan.collateral.tokenId);

    loan.borrowerConfirmed = true;

    // Activating loan
    if (loan.lenderConfirmed && loan.borrowerConfirmed) activateLoan(_id);

    emit ConfirmBorrower(_id, msg.sender);
  }

  function activateLoan(uint256 _id) private loanExists(_id) notExecuted(_id) notActive(_id) {
    Loan storage loan = loans[_id];
    require(loan.lenderConfirmed && loan.borrowerConfirmed, "Loan is unconfirmed");

    loan.active = true;
    emit ActivateLoan(_id);
  }

  function paybackLoan(uint256 _id) public payable loanExists(_id) isActive(_id) notExecuted(_id) isBorrower(_id) deadlineAhead(_id) {
    Loan storage loan = loans[_id];
    require(msg.value == loan.amount + loan.interest, "Please pay back the exact amount you owe");

    bool loanPaid = loan.lender.send(msg.value);
    require(loanPaid, "Something went wrong with the payment");

    IERC721 collateral = IERC721(loan.collateral.contractAddress);
    collateral.transferFrom(address(this), loan.borrower, loan.collateral.tokenId);

    loan.active = false;
    loan.executed = true;

    emit ExecuteLoan(_id, true);
  }

  function claimCollateral(uint256 _id) public loanExists(_id) isActive(_id) notExecuted(_id) isLender(_id) {
    Loan storage loan = loans[_id];
    require(block.timestamp >= loan.deadline, "Deadline not reached");

    IERC721 collateral = IERC721(loan.collateral.contractAddress);
    collateral.transferFrom(address(this), loan.lender, loan.collateral.tokenId);

    loan.active = false;
    loan.executed = true;

    emit ExecuteLoan(_id, false);
  }

  function extendDeadline(uint256 _id, uint256 _newDeadline) public loanExists(_id) notExecuted(_id) isLender(_id) {
    Loan storage loan = loans[_id];
    require(_newDeadline > loan.deadline, "New deadline needs to be after current deadline");

    loan.deadline = _newDeadline;
  }

  // Getters
  function test() public pure returns(bool) { return true; }

  function getLoan(uint256 _id) public view loanExists(_id) returns (Loan memory) {
    Loan memory loan = loans[_id];
    require(loan.lender == msg.sender || loan.borrower == msg.sender, "You are not participating in this loan");
    return loans[_id];
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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