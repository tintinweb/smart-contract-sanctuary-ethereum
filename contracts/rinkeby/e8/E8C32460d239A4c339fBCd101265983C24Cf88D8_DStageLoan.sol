// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./DStageAdmin.sol";
import "./DStageSigningUtils.sol";
import "./interfaces/INFTWrapper.sol";
import "./interfaces/IPermittedContracts.sol";

// @title  Main contract for DStage. This contract manages the ability to create
//         NFT-backed peer-to-peer loans.
// @notice There are five steps needed to commence an NFT-backed loan. First,
//         the borrower calls nftContract.approveAll(DStage), approving the DStage
//         contract to move their NFT's on their behalf. Second, the borrower
//         signs an off-chain message for each NFT that they would like to
//         put up for collateral. This prevents borrowers from accidentally
//         lending an NFT that they didn't mean to lend, due to approveAll()
//         approving their entire collection. Third, the lender calls
//         erc20Contract.approve(DStage), allowing DStage to move the lender's
//         ERC20 tokens on their behalf. Fourth, the lender signs an off-chain
//         message, proposing the amount, rate, and duration of a loan for a
//         particular NFT. Fifth, the borrower calls DStage.beginLoan() to
//         accept these terms and enter into the loan. The NFT is stored in the
//         contract, the borrower receives the loan principal in the specified
//         ERC20 currency, and the lender receives an DStage promissory note (in
//         ERC721 form) that represents the rights to either the
//         principal-plus-interest, or the underlying NFT collateral if the
//         borrower does not pay back in time. The lender can freely transfer
//         and trade this ERC721 promissory note as they wish, with the
//         knowledge that transferring the ERC721 promissory note tranfsers the
//         rights to principal-plus-interest and/or collateral, and that they
//         will no longer have a claim on the loan. The ERC721 promissory note
//         itself represents that claim.
// @notice A loan may end in one of two ways. First, a borrower may call
//         DStage.payBackLoan() and pay back the loan plus interest at any time,
//         in which case they receive their NFT back in the same transaction.
//         Second, if the loan's duration has passed and the loan has not been
//         paid back yet, a lender can call DStage.liquidateOverdueLoan(), in
//         which case they receive the underlying NFT collateral and forfeit
//         the rights to the principal-plus-interest, which the borrower now
//         keeps.
// @notice If the loan was agreed to be a pro-rata interest loan, then the user
//         only pays the principal plus pro-rata interest if repaid early.
//         However, if the loan was agreed to be a fixed-repayment loan (by
//         specifying UINT32_MAX as the value for
//         loanInterestRateForDurationInBasisPoints), then the borrower pays
//         the maximumRepaymentAmount regardless of whether they repay early
//         or not.
contract DStageLoan is DStageAdmin, DStageSigningUtils, ERC721 {
  // @notice OpenZeppelin's SafeMath library is used for all arithmetic
  //         operations to avoid overflows/underflows.
  using SafeMath for uint256;

  /* ********** */
  /* DATA TYPES */
  /* ********** */

  // @notice The main Loan struct. The struct fits in six 256-bits words due
  //         to Solidity's rules for struct packing.
  struct Loan {
    // A unique identifier for this particular loan, sourced from the
    // continuously increasing parameter totalNumLoans.
    uint256 loanId;
    // The original sum of money transferred from lender to borrower at the
    // beginning of the loan, measured in loanERC20Denomination's smallest
    // units.
    uint256 loanPrincipalAmount;
    // The maximum amount of money that the borrower would be required to
    // repay retrieve their collateral, measured in loanERC20Denomination's
    // smallest units. If interestIsProRated is set to false, then the
    // borrower will always have to pay this amount to retrieve their
    // collateral, regardless of whether they repay early.
    uint256 maximumRepaymentAmount;
    // The ID within the NFTCollateralContract for the NFT being used as
    // collateral for this loan. The NFT is stored within this contract
    // during the duration of the loan.
    uint256 nftCollateralId;
    // The block.timestamp when the loan first began (measured in seconds).
    uint64 loanStartTime;
    // The amount of time (measured in seconds) that can elapse before the
    // lender can liquidate the loan and seize the underlying collateral.
    uint32 loanDuration;
    // If interestIsProRated is set to true, then this is the interest rate
    // (measured in basis points, e.g. hundreths of a percent) for the loan,
    // that must be repaid pro-rata by the borrower at the conclusion of
    // the loan or risk seizure of their nft collateral. Note that if
    // interestIsProRated is set to false, then this value is not used and
    // is irrelevant.
    uint32 loanInterestRateForDurationInBasisPoints;
    // The percent (measured in basis points) of the interest earned that
    // will be taken as a fee by the contract admins when the loan is
    // repaid. The fee is stored here to prevent an attack where the
    // contract admins could adjust the fee right before a loan is repaid,
    // and take all of the interest earned.
    uint32 loanAdminFeeInBasisPoints;
    // The ERC721 contract of the NFT collateral
    address nftCollateralContract;
    // The ERC20 contract of the currency being used as principal/interest
    // for this loan.
    address loanERC20Denomination;
    // The address of the borrower.
    address borrower;
    // A boolean value determining whether the interest will be pro-rated
    // if the loan is repaid early, or whether the borrower will simply
    // pay maximumRepaymentAmount.
    bool interestIsProRated;
  }

  /* ****** */
  /* EVENTS */
  /* ****** */

  // TODO: Add NatSpec
  event PermittedContractsUpdated(address indexed newPermittedContractsAddress);

  // @notice This event is fired whenever a borrower begins a loan by calling
  //         NFTfi.beginLoan(), which can only occur after both the lender
  //         and borrower have approved their ERC721 and ERC20 contracts to
  //         use NFTfi, and when they both have signed off-chain messages that
  //         agree on the terms of the loan.
  // @param  loanId - A unique identifier for this particular loan, sourced
  //         from the continuously increasing parameter totalNumLoans.
  // @param  borrower - The address of the borrower.
  // @param  lender - The address of the lender. The lender can change their
  //         address by transferring the NFTfi ERC721 token that they
  //         received when the loan began.
  // @param  loanPrincipalAmount - The original sum of money transferred from
  //         lender to borrower at the beginning of the loan, measured in
  //         loanERC20Denomination's smallest units.
  // @param  maximumRepaymentAmount - The maximum amount of money that the
  //         borrower would be required to retrieve their collateral. If
  //         interestIsProRated is set to false, then the borrower will
  //         always have to pay this amount to retrieve their collateral.
  // @param  nftCollateralId - The ID within the NFTCollateralContract for the
  //         NFT being used as collateral for this loan. The NFT is stored
  //         within this contract during the duration of the loan.
  // @param  loanStartTime - The block.timestamp when the loan first began
  //         (measured in seconds).
  // @param  loanDuration - The amount of time (measured in seconds) that can
  //         elapse before the lender can liquidate the loan and seize the
  //         underlying collateral NFT.
  // @param  loanInterestRateForDurationInBasisPoints - If interestIsProRated
  //         is set to true, then this is the interest rate (measured in
  //         basis points, e.g. hundreths of a percent) for the loan, that
  //         must be repaid pro-rata by the borrower at the conclusion of the
  //         loan or risk seizure of their nft collateral. Note that if
  //         interestIsProRated is set to false, then this value is not used
  //         and is irrelevant.
  // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
  // @param  loanERC20Denomination - The ERC20 contract of the currency being
  //         used as principal/interest for this loan.
  // @param  interestIsProRated - A boolean value determining whether the
  //         interest will be pro-rated if the loan is repaid early, or
  //         whether the borrower will simply pay maximumRepaymentAmount.
  event LoanStarted(
    uint256 loanId,
    address borrower,
    address lender,
    uint256 loanPrincipalAmount,
    uint256 maximumRepaymentAmount,
    uint256 nftCollateralId,
    uint256 loanStartTime,
    uint256 loanDuration,
    uint256 loanInterestRateForDurationInBasisPoints,
    address nftCollateralContract,
    address loanERC20Denomination,
    bool interestIsProRated
  );

  // @notice This event is fired whenever a borrower successfully repays
  //         their loan, paying principal-plus-interest-minus-fee to the
  //         lender in loanERC20Denomination, paying fee to owner in
  //         loanERC20Denomination, and receiving their NFT collateral back.
  // @param  loanId - A unique identifier for this particular loan, sourced
  //         from the continuously increasing parameter totalNumLoans.
  // @param  borrower - The address of the borrower.
  // @param  lender - The address of the lender. The lender can change their
  //         address by transferring the NFTfi ERC721 token that they
  //         received when the loan began.
  // @param  loanPrincipalAmount - The original sum of money transferred from
  //         lender to borrower at the beginning of the loan, measured in
  //         loanERC20Denomination's smallest units.
  // @param  nftCollateralId - The ID within the NFTCollateralContract for the
  //         NFT being used as collateral for this loan. The NFT is stored
  //         within this contract during the duration of the loan.
  // @param  amountPaidToLender The amount of ERC20 that the borrower paid to
  //         the lender, measured in the smalled units of
  //         loanERC20Denomination.
  // @param  adminFee The amount of interest paid to the contract admins,
  //         measured in the smalled units of loanERC20Denomination and
  //         determined by adminFeeInBasisPoints. This amount never exceeds
  //         the amount of interest earned.
  // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
  // @param  loanERC20Denomination - The ERC20 contract of the currency being
  //         used as principal/interest for this loan.
  event LoanRepaid(
    uint256 loanId,
    address borrower,
    address lender,
    uint256 loanPrincipalAmount,
    uint256 nftCollateralId,
    uint256 amountPaidToLender,
    uint256 adminFee,
    address nftCollateralContract,
    address loanERC20Denomination
  );

  // @notice This event is fired whenever a lender liquidates an outstanding
  //         loan that is owned to them that has exceeded its duration. The
  //         lender receives the underlying NFT collateral, and the borrower
  //         no longer needs to repay the loan principal-plus-interest.
  // @param  loanId - A unique identifier for this particular loan, sourced
  //         from the continuously increasing parameter totalNumLoans.
  // @param  borrower - The address of the borrower.
  // @param  lender - The address of the lender. The lender can change their
  //         address by transferring the NFTfi ERC721 token that they
  //         received when the loan began.
  // @param  loanPrincipalAmount - The original sum of money transferred from
  //         lender to borrower at the beginning of the loan, measured in
  //         loanERC20Denomination's smallest units.
  // @param  nftCollateralId - The ID within the NFTCollateralContract for the
  //         NFT being used as collateral for this loan. The NFT is stored
  //         within this contract during the duration of the loan.
  // @param  loanMaturityDate - The unix time (measured in seconds) that the
  //         loan became due and was eligible for liquidation.
  // @param  loanLiquidationDate - The unix time (measured in seconds) that
  //         liquidation occurred.
  // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
  event LoanLiquidated(
    uint256 loanId,
    address borrower,
    address lender,
    uint256 loanPrincipalAmount,
    uint256 nftCollateralId,
    uint256 loanMaturityDate,
    uint256 loanLiquidationDate,
    address nftCollateralContract
  );

  /* ******* */
  /* STORAGE */
  /* ******* */

  // TODO: Add NatSpec
  address public permittedContractsAndNFTTypeRegistry;

  // @notice A continuously increasing counter that simultaneously allows
  //         every loan to have a unique ID and provides a running count of
  //         how many loans have been started by this contract.
  uint256 public totalNumLoans = 0;

  // @notice A counter of the number of currently outstanding loans.
  uint256 public totalActiveLoans = 0;

  // @notice A mapping from a loan's identifier to the loan's details,
  //         represted by the loan struct. To fetch the lender, call
  //         NFTfi.ownerOf(loanId).
  mapping(uint256 => Loan) public loanIdToLoan;

  // @notice A mapping tracking whether a loan has either been repaid or
  //         liquidated. This prevents an attacker trying to repay or
  //         liquidate the same loan twice.
  mapping(uint256 => bool) public loanRepaidOrLiquidated;

  // @notice A mapping that takes both a user's address and a loan nonce
  //         that was first used when signing an off-chain order and checks
  //         whether that nonce has previously either been used for a loan,
  //         or has been pre-emptively cancelled. The nonce referred to here
  //         is not the same as an Ethereum account's nonce. We are referring
  //         instead to nonces that are used by both the lender and the
  //         borrower when they are first signing off-chain NFTfi orders.
  //         These nonces can be any uint256 value that the user has not
  //         previously used to sign an off-chain order. Each nonce can be
  //         used at most once per user within NFTfi, regardless of whether
  //         they are the lender or the borrower in that situation. This
  //         serves two purposes. First, it prevents replay attacks where an
  //         attacker would submit a user's off-chain order more than once.
  //         Second, it allows a user to cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  mapping(address => mapping(uint256 => bool)) private _nonceHasBeenUsedForUser;

  /* *********** */
  /* CONSTRUCTOR */
  /* *********** */

  constructor(
    address _permitedContractsAndNFTTypeRegistry
  ) ERC721("DStage Promissory Note", "DSTAGE") {
    permittedContractsAndNFTTypeRegistry = _permitedContractsAndNFTTypeRegistry;
  }

  /* ********* */
  /* FUNCTIONS */
  /* ********* */

  // TODO: Add NatSpec
  function setPermittedContracsAddress(address permittedContractsAddress) external onlyOwner {
    permittedContractsAndNFTTypeRegistry = permittedContractsAddress;

    emit PermittedContractsUpdated(permittedContractsAddress);
  }

  // @notice This function is called by a borrower when they want to commence
  //         a loan, but can only be called after first: (1) the borrower has
  //         called approve() or approveAll() on the NFT contract for the NFT
  //         that will be used as collateral, (2) the borrower has signed an
  //         off-chain message indicating that they are willing to use this
  //         NFT as collateral, (3) the lender has called approve() on the
  //         ERC20 contract of the principal, and (4) the lender has signed
  //         an off-chain message agreeing to the terms of this loan supplied
  //         in this transaction.
  // @notice Note that a user may submit UINT32_MAX as the value for
  //         _loanInterestRateForDurationInBasisPoints to indicate that they
  //         wish to take out a fixed-repayment loan, where the interest is
  //         not pro-rated if repaid early.
  // @param  _loanPrincipalAmount - The original sum of money transferred
  //         from lender to borrower at the beginning of the loan, measured
  //         in loanERC20Denomination's smallest units.
  // @param  _maximumRepaymentAmount - The maximum amount of money that the
  //         borrower would be required to retrieve their collateral,
  //         measured in the smallest units of the ERC20 currency used for
  //         the loan. If interestIsProRated is set to false (by submitting
  //         a value of UINT32_MAX for
  //         _loanInterestRateForDurationInBasisPoints), then the borrower
  //         will always have to pay this amount to retrieve their
  //         collateral, regardless of whether they repay early.
  // @param  _nftCollateralId - The ID within the NFTCollateralContract for
  //         the NFT being used as collateral for this loan. The NFT is
  //         stored within this contract during the duration of the loan.
  // @param  _loanDuration - The amount of time (measured in seconds) that can
  //         elapse before the lender can liquidate the loan and seize the
  //         underlying collateral NFT.
  // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
  //         (measured in basis points, e.g. hundreths of a percent) for the
  //         loan, that must be repaid pro-rata by the borrower at the
  //         conclusion of the loan or risk seizure of their nft collateral.
  //         However, a user may submit UINT32_MAX as the value for
  //         _loanInterestRateForDurationInBasisPoints to indicate that they
  //         wish to take out a fixed-repayment loan, where the interest is
  //         not pro-rated if repaid early. Instead, maximumRepaymentAmount
  //         will always be the amount to be repaid.
  // @param  _adminFeeInBasisPoints - The percent (measured in basis
  //         points) of the interest earned that will be taken as a fee by
  //         the contract admins when the loan is repaid. The fee is stored
  //         in the loan struct to prevent an attack where the contract
  //         admins could adjust the fee right before a loan is repaid, and
  //         take all of the interest earned.
  // @param  _borrowerAndLenderNonces - An array of two UINT256 values, the
  //         first of which is the _borrowerNonce and the second of which is
  //         the _lenderNonce. The nonces referred to here are not the same
  //         as an Ethereum account's nonce. We are referring instead to
  //         nonces that are used by both the lender and the borrower when
  //         they are first signing off-chain NFTfi orders. These nonces can
  //         be any uint256 value that the user has not previously used to
  //         sign an off-chain order. Each nonce can be used at most once per
  //         user within NFTfi, regardless of whether they are the lender or
  //         the borrower in that situation. This serves two purposes. First,
  //         it prevents replay attacks where an attacker would submit a
  //         user's off-chain order more than once. Second, it allows a user
  //         to cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  // @param  _nftCollateralContract - The address of the ERC721 contract of
  //         the NFT collateral.
  // @param  _loanERC20Denomination - The address of the ERC20 contract of
  //         the currency being used as principal/interest for this loan.
  // @param  _lender - The address of the lender. The lender can change their
  //         address by transferring the NFTfi ERC721 token that they
  //         received when the loan began.
  // @param  _borrowerSignature - The ECDSA signature of the borrower,
  //         obtained off-chain ahead of time, signing the following
  //         combination of parameters: _nftCollateralId, _borrowerNonce,
  //         _nftCollateralContract, _borrower.
  // @param  _lenderSignature - The ECDSA signature of the lender,
  //         obtained off-chain ahead of time, signing the following
  //         combination of parameters: _loanPrincipalAmount,
  //         _maximumRepaymentAmount _nftCollateralId, _loanDuration,
  //         _loanInterestRateForDurationInBasisPoints, _lenderNonce,
  //         _nftCollateralContract, _loanERC20Denomination, _lender,
  //         _interestIsProRated.
  function beginLoan(
    uint256 _loanPrincipalAmount,
    uint256 _maximumRepaymentAmount,
    uint256 _nftCollateralId,
    uint256 _loanDuration,
    uint256 _loanInterestRateForDurationInBasisPoints,
    uint256 _adminFeeInBasisPoints,
    uint256[2] memory _borrowerAndLenderNonces,
    address _nftCollateralContract,
    address _loanERC20Denomination,
    address _lender,
    bytes memory _borrowerSignature,
    bytes memory _lenderSignature
  ) public whenNotPaused nonReentrant {
    // Save loan details to a struct in memory first, to save on gas if any
    // of the below checks fail, and to avoid the "Stack Too Deep" error by
    // clumping the parameters together into one struct held in memory.
    Loan memory loan = Loan({
      loanId: totalNumLoans, //currentLoanId,
      loanPrincipalAmount: _loanPrincipalAmount,
      maximumRepaymentAmount: _maximumRepaymentAmount,
      nftCollateralId: _nftCollateralId,
      loanStartTime: uint64(block.timestamp), //_loanStartTime
      loanDuration: uint32(_loanDuration),
      loanInterestRateForDurationInBasisPoints: uint32(_loanInterestRateForDurationInBasisPoints),
      loanAdminFeeInBasisPoints: uint32(_adminFeeInBasisPoints),
      nftCollateralContract: _nftCollateralContract,
      loanERC20Denomination: _loanERC20Denomination,
      borrower: msg.sender, //borrower
      interestIsProRated: (_loanInterestRateForDurationInBasisPoints != ~(uint32(0)))
    });

    // Sanity check loan values.
    require(
      loan.maximumRepaymentAmount >= loan.loanPrincipalAmount,
      "Negative interest rate loans are not allowed."
    );
    require(
      uint256(loan.loanDuration) <= maximumLoanDuration,
      "Loan duration exceeds maximum loan duration"
    );
    require(uint256(loan.loanDuration) != 0, "Loan duration cannot be zero");
    require(
      uint256(loan.loanAdminFeeInBasisPoints) == adminFeeInBasisPoints,
      "The admin fee has changed since this order was signed."
    );

    // Check that both the collateral and the principal come from supported
    // contracts.
    // require(
    //   erc20CurrencyIsWhitelisted[loan.loanERC20Denomination],
    //   "Currency denomination is not permitted to be used by this contract"
    // );
    // TODO: Check! Newly added
    require(
      IPermittedContracts(permittedContractsAndNFTTypeRegistry).getERC20Permit(loan.loanERC20Denomination),
      "Currency denomination is not permitted to be used by this contract"
    );

    // require(nftContractIsWhitelisted[loan.nftCollateralContract], "NFT collateral contract is not whitelisted to be used by this contract");
    // TODO: Check! Newly added
    address nftWrapper = _getWrapper(loan.nftCollateralContract);
    require(nftWrapper != address(0), "NFT collateral contract is not permitted");

    // Check loan nonces. These are different from Ethereum account nonces.
    // Here, these are uint256 numbers that should uniquely identify
    // each signature for each user (i.e. each user should only create one
    // off-chain signature for each nonce, with a nonce being any arbitrary
    // uint256 value that they have not used yet for an off-chain NFTfi
    // signature).
    require(
      !_nonceHasBeenUsedForUser[msg.sender][_borrowerAndLenderNonces[0]],
      "Borrower nonce invalid, borrower has either cancelled/begun this loan, or reused this nonce when signing"
    );
    _nonceHasBeenUsedForUser[msg.sender][_borrowerAndLenderNonces[0]] = true;
    require(
      !_nonceHasBeenUsedForUser[_lender][_borrowerAndLenderNonces[1]],
      "Lender nonce invalid, lender has either cancelled/begun this loan, or reused this nonce when signing"
    );
    _nonceHasBeenUsedForUser[_lender][_borrowerAndLenderNonces[1]] = true;

    // Check that both signatures are valid.
    require(
      isValidBorrowerSignature(
        loan.nftCollateralId,
        _borrowerAndLenderNonces[0], //_borrowerNonce,
        loan.nftCollateralContract,
        msg.sender, //borrower,
        _borrowerSignature
      ),
      "Borrower signature is invalid"
    );
    require(
      isValidLenderSignature(
        loan.loanPrincipalAmount,
        loan.maximumRepaymentAmount,
        loan.nftCollateralId,
        loan.loanDuration,
        loan.loanInterestRateForDurationInBasisPoints,
        loan.loanAdminFeeInBasisPoints,
        _borrowerAndLenderNonces[1], //_lenderNonce,
        loan.nftCollateralContract,
        loan.loanERC20Denomination,
        _lender,
        loan.interestIsProRated,
        _lenderSignature
      ),
      "Lender signature is invalid"
    );

    // Add the loan to storage before moving collateral/principal to follow
    // the Checks-Effects-Interactions pattern.
    loanIdToLoan[totalNumLoans] = loan;
    totalNumLoans = totalNumLoans.add(1);

    // Update number of active loans.
    totalActiveLoans = totalActiveLoans.add(1);
    require(
      totalActiveLoans <= maximumNumberOfActiveLoans,
      "Contract has reached the maximum number of active loans allowed by admins"
    );

    // Transfer collateral from borrower to this contract to be held until
    // loan completion.
    // IERC721(loan.nftCollateralContract).transferFrom(msg.sender, address(this), loan.nftCollateralId);
    // TODO: Check! Newly added
    _transferNFT(
      nftWrapper,
      loan.nftCollateralContract,
      msg.sender,
      address(this),
      loan.nftCollateralId
    );

    // Transfer principal from lender to borrower.
    IERC20(loan.loanERC20Denomination).transferFrom(_lender, msg.sender, loan.loanPrincipalAmount);

    // Issue an ERC721 promissory note to the lender that gives them the
    // right to either the principal-plus-interest or the collateral.
    _mint(_lender, loan.loanId);

    // Emit an event with all relevant details from this transaction.
    emit LoanStarted(
      loan.loanId,
      msg.sender, //borrower,
      _lender,
      loan.loanPrincipalAmount,
      loan.maximumRepaymentAmount,
      loan.nftCollateralId,
      block.timestamp, //_loanStartTime
      loan.loanDuration,
      loan.loanInterestRateForDurationInBasisPoints,
      loan.nftCollateralContract,
      loan.loanERC20Denomination,
      loan.interestIsProRated
    );
  }

  // @notice This function is called by a borrower when they want to repay
  //         their loan. It can be called at any time after the loan has
  //         begun. The borrower will pay a pro-rata portion of their
  //         interest if the loan is paid off early. The interest will
  //         continue to accrue after the loan has expired. This function can
  //         continue to be called by the borrower even after the loan has
  //         expired to retrieve their NFT. Note that the lender can call
  //         NFTfi.liquidateOverdueLoan() at any time after the loan has
  //         expired, so a borrower should avoid paying their loan after the
  //         due date, as they risk their collateral being seized. However,
  //         if a lender has called NFTfi.liquidateOverdueLoan() before a
  //         borrower could call NFTfi.payBackLoan(), the borrower will get
  //         to keep the principal-plus-interest.
  // @notice This function is purposefully not pausable in order to prevent
  //         an attack where the contract admin's pause the contract and hold
  //         hostage the NFT's that are still within it.
  // @param _loanId  A unique identifier for this particular loan, sourced
  //        from the continuously increasing parameter totalNumLoans.
  function payBackLoan(uint256 _loanId) external nonReentrant {
    // Sanity check that payBackLoan() and liquidateOverdueLoan() have
    // never been called on this loanId. Depending on how the rest of the
    // code turns out, this check may be unnecessary.
    require(!loanRepaidOrLiquidated[_loanId], "Loan has already been repaid or liquidated");

    // Fetch loan details from storage, but store them in memory for the
    // sake of saving gas.
    Loan memory loan = loanIdToLoan[_loanId];

    // Check that the borrower is the caller, only the borrower is entitled
    // to the collateral.
    require(
      msg.sender == loan.borrower,
      "Only the borrower can pay back a loan and reclaim the underlying NFT"
    );

    // Fetch current owner of loan promissory note.
    address lender = ownerOf(_loanId);

    // Calculate amounts to send to lender and admins
    uint256 interestDue = (loan.maximumRepaymentAmount).sub(loan.loanPrincipalAmount);
    if (loan.interestIsProRated == true) {
      interestDue = _computeInterestDue(
        loan.loanPrincipalAmount,
        loan.maximumRepaymentAmount,
        block.timestamp.sub(uint256(loan.loanStartTime)),
        uint256(loan.loanDuration),
        uint256(loan.loanInterestRateForDurationInBasisPoints)
      );
    }
    uint256 adminFee = _computeAdminFee(interestDue, uint256(loan.loanAdminFeeInBasisPoints));
    uint256 payoffAmount = ((loan.loanPrincipalAmount).add(interestDue)).sub(adminFee);

    // Mark loan as repaid before doing any external transfers to follow
    // the Checks-Effects-Interactions design pattern.
    loanRepaidOrLiquidated[_loanId] = true;

    // Update number of active loans.
    totalActiveLoans = totalActiveLoans.sub(1);

    // Transfer principal-plus-interest-minus-fees from borrower to lender
    IERC20(loan.loanERC20Denomination).transferFrom(loan.borrower, lender, payoffAmount);

    // Transfer fees from borrower to admins
    IERC20(loan.loanERC20Denomination).transferFrom(loan.borrower, owner(), adminFee);

    // Transfer collateral from this contract to borrower.
    // require(_transferNftToAddress(
    //     loan.nftCollateralContract,
    //     loan.nftCollateralId,
    //     loan.borrower
    // ), "NFT was not successfully transferred");
    // TODO: Newly Added
    address nftWrapper = _getWrapper(loan.nftCollateralContract);
    require(nftWrapper != address(0), "NFT collateral contract is not permitted");
    _transferNFT(
      nftWrapper,
      loan.nftCollateralContract,
      address(this),
      loan.borrower,
      loan.nftCollateralId
    );

    // Destroy the lender's promissory note.
    _burn(_loanId);

    // Emit an event with all relevant details from this transaction.
    emit LoanRepaid(
      _loanId,
      loan.borrower,
      lender,
      loan.loanPrincipalAmount,
      loan.nftCollateralId,
      payoffAmount,
      adminFee,
      loan.nftCollateralContract,
      loan.loanERC20Denomination
    );

    // Delete the loan from storage in order to achieve a substantial gas
    // savings and to lessen the burden of storage on Ethereum nodes, since
    // we will never access this loan's details again, and the details are
    // still available through event data.
    delete loanIdToLoan[_loanId];
  }

  // @notice This function is called by a lender once a loan has finished its
  //         duration and the borrower still has not repaid. The lender
  //         can call this function to seize the underlying NFT collateral,
  //         although the lender gives up all rights to the
  //         principal-plus-collateral by doing so.
  // @notice This function is purposefully not pausable in order to prevent
  //         an attack where the contract admin's pause the contract and hold
  //         hostage the NFT's that are still within it.
  // @notice We intentionally allow anybody to call this function, although
  //         only the lender will end up receiving the seized collateral. We
  //         are exploring the possbility of incentivizing users to call this
  //         function by using some of the admin funds.
  // @param _loanId  A unique identifier for this particular loan, sourced
  //        from the continuously increasing parameter totalNumLoans.
  function liquidateOverdueLoan(uint256 _loanId) external nonReentrant {
    // Sanity check that payBackLoan() and liquidateOverdueLoan() have
    // never been called on this loanId. Depending on how the rest of the
    // code turns out, this check may be unnecessary.
    require(!loanRepaidOrLiquidated[_loanId], "Loan has already been repaid or liquidated");

    // Fetch loan details from storage, but store them in memory for the
    // sake of saving gas.
    Loan memory loan = loanIdToLoan[_loanId];

    // Ensure that the loan is indeed overdue, since we can only liquidate
    // overdue loans.
    uint256 loanMaturityDate = (uint256(loan.loanStartTime)).add(uint256(loan.loanDuration));
    require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

    // Fetch the current lender of the promissory note corresponding to
    // this overdue loan.
    address lender = ownerOf(_loanId);

    // Mark loan as liquidated before doing any external transfers to
    // follow the Checks-Effects-Interactions design pattern.
    loanRepaidOrLiquidated[_loanId] = true;

    // Update number of active loans.
    totalActiveLoans = totalActiveLoans.sub(1);

    // Transfer collateral from this contract to the lender, since the
    // lender is seizing collateral for an overdue loan.
    // require(_transferNftToAddress(
    //     loan.nftCollateralContract,
    //     loan.nftCollateralId,
    //     lender
    // ), "NFT was not successfully transferred");
    address nftWrapper = _getWrapper(loan.nftCollateralContract);
    require(nftWrapper != address(0), "NFT collateral contract is not permitted");
    _transferNFT(
      nftWrapper,
      loan.nftCollateralContract,
      address(this),
      lender,
      loan.nftCollateralId
    );

    // Destroy the lender's promissory note for this loan, since by seizing
    // the collateral, the lender has forfeit the rights to the loan
    // principal-plus-interest.
    _burn(_loanId);

    // Emit an event with all relevant details from this transaction.
    emit LoanLiquidated(
      _loanId,
      loan.borrower,
      lender,
      loan.loanPrincipalAmount,
      loan.nftCollateralId,
      loanMaturityDate,
      block.timestamp,
      loan.nftCollateralContract
    );

    // Delete the loan from storage in order to achieve a substantial gas
    // savings and to lessen the burden of storage on Ethereum nodes, since
    // we will never access this loan's details again, and the details are
    // still available through event data.
    delete loanIdToLoan[_loanId];
  }

  // @notice This function can be called by either a lender or a borrower to
  //         cancel all off-chain orders that they have signed that contain
  //         this nonce. If the off-chain orders were created correctly,
  //         there should only be one off-chain order that contains this
  //         nonce at all.
  // @param  _nonce - The nonce referred to here is not the same as an
  //         Ethereum account's nonce. We are referring instead to nonces
  //         that are used by both the lender and the borrower when they are
  //         first signing off-chain NFTfi orders. These nonces can be any
  //         uint256 value that the user has not previously used to sign an
  //         off-chain order. Each nonce can be used at most once per user
  //         within NFTfi, regardless of whether they are the lender or the
  //         borrower in that situation. This serves two purposes. First, it
  //         prevents replay attacks where an attacker would submit a user's
  //         off-chain order more than once. Second, it allows a user to
  //         cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  function cancelLoanCommitmentBeforeLoanHasBegun(uint256 _nonce) external {
    require(
      !_nonceHasBeenUsedForUser[msg.sender][_nonce],
      "Nonce invalid, user has either cancelled/begun this loan, or reused a nonce when signing"
    );
    _nonceHasBeenUsedForUser[msg.sender][_nonce] = true;
  }

  /* ******************* */
  /* READ-ONLY FUNCTIONS */
  /* ******************* */

  // @notice This function can be used to view the current quantity of the
  //         ERC20 currency used in the specified loan required by the
  //         borrower to repay their loan, measured in the smallest unit of
  //         the ERC20 currency. Note that since interest accrues every
  //         second, once a borrower calls repayLoan(), the amount will have
  //         increased slightly.
  // @param  _loanId  A unique identifier for this particular loan, sourced
  //         from the continuously increasing parameter totalNumLoans.
  // @return The amount of the specified ERC20 currency required to pay back
  //         this loan, measured in the smallest unit of the specified ERC20
  //         currency.
  function getPayoffAmount(uint256 _loanId) public view returns (uint256) {
    Loan storage loan = loanIdToLoan[_loanId];
    if (loan.interestIsProRated == false) {
      return loan.maximumRepaymentAmount;
    } else {
      uint256 loanDurationSoFarInSeconds = block.timestamp.sub(uint256(loan.loanStartTime));
      uint256 interestDue = _computeInterestDue(
        loan.loanPrincipalAmount,
        loan.maximumRepaymentAmount,
        loanDurationSoFarInSeconds,
        uint256(loan.loanDuration),
        uint256(loan.loanInterestRateForDurationInBasisPoints)
      );
      return (loan.loanPrincipalAmount).add(interestDue);
    }
  }

  // @notice This function can be used to view whether a particular nonce
  //         for a particular user has already been used, either from a
  //         successful loan or a cancelled off-chain order.
  // @param  _user - The address of the user. This function works for both
  //         lenders and borrowers alike.
  // @param  _nonce - The nonce referred to here is not the same as an
  //         Ethereum account's nonce. We are referring instead to nonces
  //         that are used by both the lender and the borrower when they are
  //         first signing off-chain NFTfi orders. These nonces can be any
  //         uint256 value that the user has not previously used to sign an
  //         off-chain order. Each nonce can be used at most once per user
  //         within NFTfi, regardless of whether they are the lender or the
  //         borrower in that situation. This serves two purposes. First, it
  //         prevents replay attacks where an attacker would submit a user's
  //         off-chain order more than once. Second, it allows a user to
  //         cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  // @return A bool representing whether or not this nonce has been used for
  //         this user.
  function getWhetherNonceHasBeenUsedForUser(address _user, uint256 _nonce)
    public
    view
    returns (bool)
  {
    return _nonceHasBeenUsedForUser[_user][_nonce];
  }

  /* ****************** */
  /* INTERNAL FUNCTIONS */
  /* ****************** */

  // @notice A convenience function that calculates the amount of interest
  //         currently due for a given loan. The interest is capped at
  //         _maximumRepaymentAmount minus _loanPrincipalAmount.
  // @param  _loanPrincipalAmount - The total quantity of principal first
  //         loaned to the borrower, measured in the smallest units of the
  //         ERC20 currency used for the loan.
  // @param  _maximumRepaymentAmount - The maximum amount of money that the
  //         borrower would be required to retrieve their collateral. If
  //         interestIsProRated is set to false, then the borrower will
  //         always have to pay this amount to retrieve their collateral.
  // @param  _loanDurationSoFarInSeconds - The elapsed time (in seconds) that
  //         has occurred so far since the loan began until repayment.
  // @param  _loanTotalDurationAgreedTo - The original duration that the
  //         borrower and lender agreed to, by which they measured the
  //         interest that would be due.
  // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
  ///        that the borrower and lender agreed would be due after the
  //         totalDuration passed.
  // @return The quantity of interest due, measured in the smallest units of
  //         the ERC20 currency used to pay this loan.
  function _computeInterestDue(
    uint256 _loanPrincipalAmount,
    uint256 _maximumRepaymentAmount,
    uint256 _loanDurationSoFarInSeconds,
    uint256 _loanTotalDurationAgreedTo,
    uint256 _loanInterestRateForDurationInBasisPoints
  ) internal pure returns (uint256) {
    uint256 interestDueAfterEntireDuration = (
      _loanPrincipalAmount.mul(_loanInterestRateForDurationInBasisPoints)
    ).div(uint256(10000));
    uint256 interestDueAfterElapsedDuration = (
      interestDueAfterEntireDuration.mul(_loanDurationSoFarInSeconds)
    ).div(_loanTotalDurationAgreedTo);
    if (_loanPrincipalAmount.add(interestDueAfterElapsedDuration) > _maximumRepaymentAmount) {
      return _maximumRepaymentAmount.sub(_loanPrincipalAmount);
    } else {
      return interestDueAfterElapsedDuration;
    }
  }

  // @notice A convenience function computing the adminFee taken from a
  //         specified quantity of interest
  // @param  _interestDue - The amount of interest due, measured in the
  //         smallest quantity of the ERC20 currency being used to pay the
  //         interest.
  // @param  _adminFeeInBasisPoints - The percent (measured in basis
  //         points) of the interest earned that will be taken as a fee by
  //         the contract admins when the loan is repaid. The fee is stored
  //         in the loan struct to prevent an attack where the contract
  //         admins could adjust the fee right before a loan is repaid, and
  //         take all of the interest earned.
  // @return The quantity of ERC20 currency (measured in smalled units of
  //         that ERC20 currency) that is due as an admin fee.
  function _computeAdminFee(uint256 _interestDue, uint256 _adminFeeInBasisPoints)
    internal
    pure
    returns (uint256)
  {
    return (_interestDue.mul(_adminFeeInBasisPoints)).div(10000);
  }

  // TODO: Add NatSpec
  function _getWrapper(address _nftCollateralContract) internal view returns (address) {
    return
      IPermittedContracts(permittedContractsAndNFTTypeRegistry).getNFTWrapper(
        _nftCollateralContract
      );
  }

  // TODO: ADD NatSpec
  function _transferNFT(
    address _nftWrapper,
    address _nftCollateralContract,
    address _sender,
    address _recepient,
    uint256 _nftCollateralId
  ) internal {
    Address.functionDelegateCall(
      _nftWrapper,
      abi.encodeWithSelector(
        INFTWrapper(_nftWrapper).transferNFT.selector,
        _sender,
        _recepient,
        _nftCollateralContract,
        _nftCollateralId
      )
    );
  }

  /* ***************** */
  /* FALLBACK FUNCTION */
  /* ***************** */

  // @notice By calling 'revert' in the fallback function, we prevent anyone
  //         from accidentally sending funds directly to this contract.
  fallback() external payable {
    revert();
  }

  // @notice By calling 'revert' in the fallback function, we prevent anyone
  //         from accidentally sending funds directly to this contract.
  receive() external payable {
    revert();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @title  Helper contract for DStage. This contract manages verifying signatures
//         from off-chain NFTfi orders. 
contract DStageSigningUtils {
  /* *********** */
  /* CONSTRUCTOR */
  /* *********** */

  constructor() {}

  /* ********* */
  /* FUNCTIONS */
  /* ********* */

  // @notice OpenZeppelin's ECDSA library is used to call all ECDSA functions
  //         directly on the bytes32 variables themselves.
  using ECDSA for bytes32;

  // @notice This function gets the current chain ID.
  function getChainID() public view returns (uint256) {
    uint256 id;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      id := chainid()
    }
    return id;
  }

  // @notice This function is called in NFTfi.beginLoan() to validate the
  //         borrower's signature that the borrower provided off-chain to
  //         verify that they did indeed want to use this NFT for this loan.
  // @param  _nftCollateralId - The ID within the NFTCollateralContract for
  //         the NFT being used as collateral for this loan. The NFT is
  //         stored within this contract during the duration of the loan.
  // @param  _borrowerNonce - The nonce referred to here
  //         is not the same as an Ethereum account's nonce. We are referring
  //         instead to nonces that are used by both the lender and the
  //         borrower when they are first signing off-chain NFTfi orders.
  //         These nonces can be any uint256 value that the user has not
  //         previously used to sign an off-chain order. Each nonce can be
  //         used at most once per user within NFTfi, regardless of whether
  //         they are the lender or the borrower in that situation. This
  //         serves two purposes. First, it prevents replay attacks where an
  //         attacker would submit a user's off-chain order more than once.
  //         Second, it allows a user to cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  // @param  _nftCollateralContract - The ERC721 contract of the NFT
  //         collateral
  // @param  _borrower - The address of the borrower.
  // @param  _borrowerSignature - The ECDSA signature of the borrower,
  //         obtained off-chain ahead of time, signing the following
  //         combination of parameters: _nftCollateralId, _borrowerNonce,
  //         _nftCollateralContract, _borrower.
  // @return A bool representing whether verification succeeded, showing that
  //         this signature matched this address and parameters.
  function isValidBorrowerSignature(
    uint256 _nftCollateralId,
    uint256 _borrowerNonce,
    address _nftCollateralContract,
    address _borrower,
    bytes memory _borrowerSignature
  ) public view returns (bool) {
    if (_borrower == address(0)) {
      return false;
    } else {
      uint256 chainId;
      chainId = getChainID();
      bytes32 message = keccak256(
        abi.encodePacked(
          _nftCollateralId,
          _borrowerNonce,
          _nftCollateralContract,
          _borrower,
          chainId
        )
      );

      bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

      return (messageWithEthSignPrefix.recover(_borrowerSignature) == _borrower);
    }
  }

  // @notice This function is called in NFTfi.beginLoan() to validate the
  //         lender's signature that the lender provided off-chain to
  //         verify that they did indeed want to agree to this loan according
  //         to these terms.
  // @param  _loanPrincipalAmount - The original sum of money transferred
  //         from lender to borrower at the beginning of the loan, measured
  //         in loanERC20Denomination's smallest units.
  // @param  _maximumRepaymentAmount - The maximum amount of money that the
  //         borrower would be required to retrieve their collateral. If
  //         interestIsProRated is set to false, then the borrower will
  //         always have to pay this amount to retrieve their collateral.
  // @param  _nftCollateralId - The ID within the NFTCollateralContract for
  //         the NFT being used as collateral for this loan. The NFT is
  //         stored within this contract during the duration of the loan.
  // @param  _loanDuration - The amount of time (measured in seconds) that can
  //         elapse before the lender can liquidate the loan and seize the
  //         underlying collateral NFT.
  // @param  _loanInterestRateForDurationInBasisPoints - The interest rate
  //         (measured in basis points, e.g. hundreths of a percent) for the
  //         loan, that must be repaid pro-rata by the borrower at the
  //         conclusion of the loan or risk seizure of their nft collateral.
  // @param  _adminFeeInBasisPoints - The percent (measured in basis
  //         points) of the interest earned that will be taken as a fee by
  //         the contract admins when the loan is repaid. The fee is stored
  //         in the loan struct to prevent an attack where the contract
  //         admins could adjust the fee right before a loan is repaid, and
  //         take all of the interest earned.
  // @param  _lenderNonce - The nonce referred to here
  //         is not the same as an Ethereum account's nonce. We are referring
  //         instead to nonces that are used by both the lender and the
  //         borrower when they are first signing off-chain NFTfi orders.
  //         These nonces can be any uint256 value that the user has not
  //         previously used to sign an off-chain order. Each nonce can be
  //         used at most once per user within NFTfi, regardless of whether
  //         they are the lender or the borrower in that situation. This
  //         serves two purposes. First, it prevents replay attacks where an
  //         attacker would submit a user's off-chain order more than once.
  //         Second, it allows a user to cancel an off-chain order by calling
  //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
  //         nonce as used and prevents any future loan from using the user's
  //         off-chain order that contains that nonce.
  // @param  _nftCollateralContract - The ERC721 contract of the NFT
  //         collateral
  // @param  _loanERC20Denomination - The ERC20 contract of the currency being
  //         used as principal/interest for this loan.
  // @param  _lender - The address of the lender. The lender can change their
  //         address by transferring the NFTfi ERC721 token that they
  //         received when the loan began.
  // @param  _interestIsProRated - A boolean value determining whether the
  //         interest will be pro-rated if the loan is repaid early, or
  //         whether the borrower will simply pay maximumRepaymentAmount.
  // @param  _lenderSignature - The ECDSA signature of the lender,
  //         obtained off-chain ahead of time, signing the following
  //         combination of parameters: _loanPrincipalAmount,
  //         _maximumRepaymentAmount _nftCollateralId, _loanDuration,
  //         _loanInterestRateForDurationInBasisPoints, _lenderNonce,
  //         _nftCollateralContract, _loanERC20Denomination, _lender,
  //         _interestIsProRated.
  // @return A bool representing whether verification succeeded, showing that
  //         this signature matched this address and parameters.
  function isValidLenderSignature(
    uint256 _loanPrincipalAmount,
    uint256 _maximumRepaymentAmount,
    uint256 _nftCollateralId,
    uint256 _loanDuration,
    uint256 _loanInterestRateForDurationInBasisPoints,
    uint256 _adminFeeInBasisPoints,
    uint256 _lenderNonce,
    address _nftCollateralContract,
    address _loanERC20Denomination,
    address _lender,
    bool _interestIsProRated,
    bytes memory _lenderSignature
  ) public view returns (bool) {
    if (_lender == address(0)) {
      return false;
    } else {
      uint256 chainId;
      chainId = getChainID();
      bytes32 message = keccak256(
        abi.encodePacked(
          _loanPrincipalAmount,
          _maximumRepaymentAmount,
          _nftCollateralId,
          _loanDuration,
          _loanInterestRateForDurationInBasisPoints,
          _adminFeeInBasisPoints,
          _lenderNonce,
          _nftCollateralContract,
          _loanERC20Denomination,
          _lender,
          _interestIsProRated,
          chainId
        )
      );

      bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

      return (messageWithEthSignPrefix.recover(_lenderSignature) == _lender);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// @title Admin contract for DStage. Holds owner-only functions to adjust
//        contract-wide fees, parameters, etc.
contract DStageAdmin is Ownable, Pausable, ReentrancyGuard {

    /* ****** */
    /* EVENTS */
    /* ****** */

    // @notice This event is fired whenever the admins change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  newAdminFee - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    event AdminFeeUpdated(
        uint256 newAdminFee
    );

    /* ******* */
    /* STORAGE */
    /* ******* */

    // @notice The maximum duration of any loan started on this platform,
    //         measured in seconds. This is both a sanity-check for borrowers
    //         and an upper limit on how long admins will have to support v1 of
    //         this contract if they eventually deprecate it, as well as a check
    //         to ensure that the loan duration never exceeds the space alotted
    //         for it in the loan struct.
    uint256 public maximumLoanDuration = 53 weeks;

    // @notice The maximum number of active loans allowed on this platform.
    //         This parameter is used to limit the risk that NFTfi faces while
    //         the project is first getting started.
    uint256 public maximumNumberOfActiveLoans = 100;

    // @notice The percentage of interest earned by lenders on this platform
    //         that is taken by the contract admin's as a fee, measured in
    //         basis points (hundreths of a percent).
    uint256 public adminFeeInBasisPoints = 25;

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice This function can be called by admins to change the
    //         maximumLoanDuration. Note that they can never change
    //         maximumLoanDuration to be greater than UINT32_MAX, since that's
    //         the maximum space alotted for the duration in the loan struct.
    // @param  _newMaximumLoanDuration - The new maximum loan duration, measured
    //         in seconds.
    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external onlyOwner {
        require(_newMaximumLoanDuration <= uint256(~uint32(0)), "Loan duration cannot exceed space alotted in struct");
        maximumLoanDuration = _newMaximumLoanDuration;
    }

    // @notice This function can be called by admins to change the
    //         maximumNumberOfActiveLoans. 
    // @param  _newMaximumNumberOfActiveLoans - The new maximum number of
    //         active loans, used to limit the risk that NFTfi faces while the
    //         project is first getting started.
    function updateMaximumNumberOfActiveLoans(uint256 _newMaximumNumberOfActiveLoans) external onlyOwner {
        maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
    }

    // @notice This function can be called by admins to change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  _newAdminFeeInBasisPoints - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    function updateAdminFee(uint256 _newAdminFeeInBasisPoints) external onlyOwner {
        require(_newAdminFeeInBasisPoints <= 10000, "By definition, basis points cannot exceed 10000");
        adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
        
        emit AdminFeeUpdated(_newAdminFeeInBasisPoints);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 *@title Whitelisted NFT/ERC20 contracts
 *@dev Interface for whitelisted NFT/ERC20 contracts
 */
interface IPermittedContracts {
  function setNFTPermit(address nftContract, string memory nftType) external;
  function getNFTPermit(address nftContract) external view returns (bytes32);
  function getNFTWrapper(address nftContract) external view returns (address);

  function setERC20Permit(address erc20, bool permit) external;
  function getERC20Permit(address erc20) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 *@title INftTypeRegistry
 *@dev Interface for NFT Wrappers
 */
interface INFTWrapper {
  function transferNFT(
    address from,
    address to,
    address nftContract,
    uint256 tokenId
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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