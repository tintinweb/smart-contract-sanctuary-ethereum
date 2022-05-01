// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./vendor/EnumerableSet.sol";
import "./libraries/WadRayMath.sol";

contract AlphaLoan is Ownable, ERC721, Pausable {
  //
  /*************************************** LIBRARIES *****************************************/

  using WadRayMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  /*************************************** CONSTANTS *****************************************/

  uint256 public immutable LIQUIDATION_PERIOD;
  uint256 public immutable MIN_LOAN_DURATION;
  uint256 public immutable MIN_FUNDING_PERIOD;
  uint256 public immutable LIQUIDATION_PRICE_MULTIPLIER;
  uint256 private constant SECONDS_PER_YEAR_AS_RAY = 365 days * 1e27;

  /*************************************** ERRORS ********************************************/

  error ContributionTooSmall();
  error ContributionTooLarge();
  error InsufficientFunds();
  error InvalidLoanTerms();
  error NotLiquidatable();
  error NotClaimable();
  error NotRepayable();
  error NotLendable();
  error OutsideFundingPeriod();
  error Unauthorized();

  /*************************************** EVENTS ********************************************/

  event NewLoanRequested(
    address indexed borrower,
    uint256 tokenID,
    ERC721 collateralToken,
    uint256 collateralTokenID,
    IERC20 settlementToken,
    uint256 maxAmount,
    uint256 minAPRRay,
    uint256 maxAPRRay,
    uint256 startDate,
    uint256 endDate,
    uint256 fundingPeriod
  );

  event ContributionMade(
    address indexed lender,
    uint256 indexed tokenID,
    uint256 amount,
    uint256 amountOwed,
    uint256 rateRay,
    uint256 index
  );

  event CollateralClaimed(
    address indexed claimant,
    uint256 indexed tokenID,
    ERC721 collateralToken,
    uint256 collateralTokenID
  );

  event LoanLiquidated(uint256 indexed tokenID, uint256 amount);

  event LoanRepaid(uint256 indexed tokenID, uint256 amount);

  event BorrowerWithdrawMade(uint256 indexed tokenID, uint256 amount);

  event LenderWithdrawMade(uint256 indexed tokenID, uint256 amount);

  /*************************************** STRUCTS *******************************************/

  struct Terms {
    // TODO - struct pack
    IERC20 settlementToken;
    uint256 maxAmount;
    uint256 minAPRRay;
    uint256 maxAPRRay;
    uint256 startDate;
    uint256 endDate;
    uint256 fundingPeriod;
  }

  struct LoanContribution {
    // TODO - struct pack
    address lender;
    uint256 rateRay;
    uint256 createdDate;
    bool repaid;
    uint256 amountOwed;
    uint256 amount;
    uint256 totalAmountOwed;
  }

  struct State {
    bool wasLiquidated;
    bool wasRepaid;
    bool wasCancelled;
  }

  /*************************************** STORAGE *******************************************/

  uint256 private s_nextTokenID = 1;
  mapping(uint256 => address) private s_borrower;
  mapping(uint256 => ERC721) private s_collateralToken;
  mapping(uint256 => uint256) private s_collateralTokenID;
  mapping(uint256 => Terms) private s_terms;
  mapping(uint256 => uint256) private s_balance;
  mapping(uint256 => State) private s_state;
  mapping(uint256 => uint256) private s_liquidationPrice;
  mapping(uint256 => mapping(address => bool)) private s_lenderWithdrawn;
  mapping(uint256 => LoanContribution[]) private s_contributions;
  mapping(uint256 => mapping(address => uint256[]))
    private s_lenderContrubutionIndices;
  mapping(uint256 => uint256) private s_amountLent;
  EnumerableSet.AddressSet private s_settlementTokens;
  mapping(address => uint256) private s_minimumContribution;

  /*************************************** CONSTRUCTOR ***************************************/

  constructor(
    uint256 liquidationPeriod,
    uint256 minLoanDuration,
    uint256 minFundingPeriod,
    uint256 liquidationPriceMultiplier
  ) ERC721("Nau Alpha Loan", "NAL") {
    LIQUIDATION_PERIOD = liquidationPeriod;
    MIN_LOAN_DURATION = minLoanDuration;
    MIN_FUNDING_PERIOD = minFundingPeriod;
    LIQUIDATION_PRICE_MULTIPLIER = liquidationPriceMultiplier;
  }

  /*************************************** PUBLIC ********************************************/

  /**
   * @notice creates a new loan and mints a new AlphaLoan NFT to the borrower
   * @param collateralToken - the address of the collateral NFT
   * @param collateralTokenID - the TokenID of the collateral NFT
   * @param settlementToken - the ERC20 token to loan
   * @param maxAmount - the maximum amount to loan
   * @param minAPRRay - the starting APR offered to lenders
   * @param maxAPRRay - the maximum APR offered to lenders
   * @param endDate - the loan's end date
   * @param fundingPeriod - the period during which lenders can make contributions
   */
  function requestNewLoan(
    ERC721 collateralToken,
    uint256 collateralTokenID,
    IERC20 settlementToken,
    uint256 maxAmount,
    uint256 minAPRRay,
    uint256 maxAPRRay,
    uint256 endDate,
    uint256 fundingPeriod
  ) external whenNotPaused returns (uint256) {
    uint256 tokenID = s_nextTokenID;
    _safeMint(msg.sender, tokenID);
    s_borrower[tokenID] = msg.sender;
    s_collateralToken[tokenID] = collateralToken;
    s_collateralTokenID[tokenID] = collateralTokenID;
    s_nextTokenID++;
    Terms memory terms = Terms({
      settlementToken: settlementToken,
      maxAmount: maxAmount,
      minAPRRay: minAPRRay,
      maxAPRRay: maxAPRRay,
      startDate: block.timestamp,
      endDate: endDate,
      fundingPeriod: fundingPeriod
    });
    validate(terms);
    s_terms[tokenID] = terms;
    collateralToken.transferFrom(msg.sender, address(this), collateralTokenID);
    emit NewLoanRequested(
      msg.sender,
      tokenID,
      collateralToken,
      collateralTokenID,
      terms.settlementToken,
      terms.maxAmount,
      terms.minAPRRay,
      terms.maxAPRRay,
      terms.startDate,
      terms.endDate,
      terms.fundingPeriod
    );
    return tokenID;
  }

  /**
   * @notice loans money to the borrower
   * @param tokenID - tokenID of the loan to contribute to
   * @param amount - the amount to lend
   */
  function lend(uint256 tokenID, uint256 amount) external {
    Terms memory terms = s_terms[tokenID];
    if (s_state[tokenID].wasCancelled) {
      revert NotLendable();
    }
    if (block.timestamp > terms.startDate + terms.fundingPeriod) {
      revert OutsideFundingPeriod();
    }
    uint256 numContributions = s_contributions[tokenID].length;
    if (
      numContributions == 0 &&
      amount < s_minimumContribution[address(terms.settlementToken)]
    ) {
      revert ContributionTooSmall();
    }
    uint256 amountLent = s_amountLent[tokenID];
    amountLent += amount;
    if (amountLent > terms.maxAmount) {
      revert ContributionTooLarge();
    }
    s_amountLent[tokenID] = amountLent;
    s_balance[tokenID] += amount;
    uint256 rateRay = _getAskingRate(terms);
    uint256 amountOwed = calculateBalanceWithInterest(
      amount,
      terms.endDate - block.timestamp,
      rateRay
    );
    s_contributions[tokenID].push(
      LoanContribution({
        lender: msg.sender,
        repaid: false,
        amount: amount,
        amountOwed: amountOwed,
        rateRay: rateRay,
        createdDate: block.timestamp,
        totalAmountOwed: getTotalAmountOwed(tokenID) + amountOwed
      })
    );
    s_lenderContrubutionIndices[tokenID][msg.sender].push(
      s_contributions[tokenID].length - 1
    );
    terms.settlementToken.transferFrom(msg.sender, address(this), amount);
    emit ContributionMade(
      msg.sender,
      tokenID,
      amount,
      amountOwed,
      rateRay,
      s_contributions[tokenID].length - 1
    );
  }

  /**
   * @notice withdraw borrowed funds
   * @param tokenID - tokenID of the loan to withdraw from
   * @param amount - the amount to withdraw
   */
  function borrowerWithdraw(uint256 tokenID, uint256 amount)
    external
    onlyBorrower(tokenID)
  {
    Terms memory terms = s_terms[tokenID];
    require(block.timestamp <= terms.endDate);
    if (amount > s_balance[tokenID]) {
      revert InsufficientFunds();
    }
    s_balance[tokenID] -= amount;
    s_terms[tokenID].settlementToken.transfer(msg.sender, amount);
    emit BorrowerWithdrawMade(tokenID, amount);
  }

  /**
   * @notice repays the full amount of the loan
   * @param tokenID - tokenID of the loan to repay
   */
  function repayAll(uint256 tokenID)
    external
    onlyBorrower(tokenID)
    repayable(tokenID)
  {
    Terms memory terms = s_terms[tokenID];
    uint256 amountToPay = getNetAmountOwed(tokenID);
    s_state[tokenID].wasRepaid = true;
    _pay(tokenID, terms, amountToPay);
    s_collateralToken[tokenID].transferFrom(
      address(this),
      msg.sender,
      s_collateralTokenID[tokenID]
    );
    emit LoanRepaid(tokenID, amountToPay);
  }

  /**
   * @notice liquidates a loan
   * @param tokenID - tokenID of the loan to liquidate
   */
  function liquidate(uint256 tokenID) external {
    if (!isLiquidatable(tokenID)) {
      revert NotLiquidatable();
    }
    Terms memory terms = s_terms[tokenID];
    uint256 liquidationPrice = _getLiquidationPrice(tokenID, terms);
    s_state[tokenID].wasLiquidated = true;
    s_liquidationPrice[tokenID] = liquidationPrice;
    _pay(tokenID, terms, liquidationPrice);
    s_collateralToken[tokenID].transferFrom(
      address(this),
      msg.sender,
      s_collateralTokenID[tokenID]
    );
    emit LoanLiquidated(tokenID, liquidationPrice);
  }

  /**
   * @notice withdraw principal and earnings from loans, after thay have been repaid or liquidated
   * @param tokenID - tokenID of the loan to withdraw from
   */
  function lenderWithdraw(uint256 tokenID) public {
    Terms memory terms = s_terms[tokenID];
    uint256 amount = getLenderWithdrawableAmount(tokenID, msg.sender);
    s_lenderWithdrawn[tokenID][msg.sender] = true;
    terms.settlementToken.transfer(msg.sender, amount);
    emit LenderWithdrawMade(tokenID, amount);
  }

  /**
   * @notice withdraw funds from multiple loans at once
   * @param tokenIDs - tokenIDs of the loans to withdraw from
   */
  function lenderWithdrawAll(uint256[] calldata tokenIDs) external {
    for (uint256 idx = 0; idx < tokenIDs.length; idx++) {
      lenderWithdraw(tokenIDs[idx]);
    }
  }

  /**
   * @notice reclaims the collateral NFT, and cancels the existing loan
   * @param tokenID - tokenID of the loan to claim collateral from
   */
  function claimCollateral(uint256 tokenID) external {
    if (ownerOf(tokenID) != msg.sender) {
      revert Unauthorized();
    }
    if (!isClaimable(tokenID)) {
      revert NotClaimable();
    }
    ERC721 collateralToken = s_collateralToken[tokenID];
    uint256 collateralTokenID = s_collateralTokenID[tokenID];
    s_state[tokenID].wasCancelled = true;
    collateralToken.transferFrom(address(this), msg.sender, collateralTokenID);
    emit CollateralClaimed(
      msg.sender,
      tokenID,
      collateralToken,
      collateralTokenID
    );
  }

  /*************************************** SETTERS *******************************************/

  function setSettlementToken(
    address settlementToken,
    bool permissioned,
    uint256 minContribution
  ) external onlyOwner {
    if (permissioned) {
      if (!s_settlementTokens.contains(settlementToken)) {
        s_settlementTokens.add(settlementToken);
      }
      s_minimumContribution[settlementToken] = minContribution;
    } else if (s_settlementTokens.contains(settlementToken)) {
      s_settlementTokens.remove(settlementToken);
    }
    s_minimumContribution[settlementToken] = minContribution;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /*************************************** GETTERS *******************************************/

  function getWhitelistedSettlementTokens()
    external
    view
    returns (address[] memory)
  {
    return s_settlementTokens.values();
  }

  function getMinimumContributionForToken(address settlementToken)
    external
    view
    returns (uint256)
  {
    return s_minimumContribution[settlementToken];
  }

  function getBorrower(uint256 tokenID) external view returns (address) {
    return s_borrower[tokenID];
  }

  function getBorrowerWithdrawableAmount(uint256 tokenID)
    external
    view
    returns (uint256)
  {
    return s_balance[tokenID];
  }

  function getCollateral(uint256 tokenID)
    external
    view
    returns (ERC721, uint256)
  {
    return (s_collateralToken[tokenID], s_collateralTokenID[tokenID]);
  }

  function isClaimable(uint256 tokenID) public view returns (bool) {
    State memory state = s_state[tokenID];
    return !state.wasCancelled && s_contributions[tokenID].length == 0;
  }

  function isLiquidatable(uint256 tokenID) public view returns (bool) {
    Terms memory terms = s_terms[tokenID];
    return _isLiquidatable(tokenID, terms);
  }

  function wasRepaid(uint256 tokenID) external view returns (bool) {
    return s_state[tokenID].wasRepaid;
  }

  function wasLiquidated(uint256 tokenID) external view returns (bool) {
    return s_state[tokenID].wasLiquidated;
  }

  function wasCancelled(uint256 tokenID) external view returns (bool) {
    return s_state[tokenID].wasCancelled;
  }

  function getTerms(uint256 tokenID) external view returns (Terms memory) {
    return s_terms[tokenID];
  }

  function getLiquidationPrice(uint256 tokenID)
    external
    view
    returns (uint256)
  {
    Terms memory terms = s_terms[tokenID];
    if (!_isLiquidatable(tokenID, terms)) {
      return 0;
    }
    return _getLiquidationPrice(tokenID, terms);
  }

  function getAskingRate(uint256 tokenID) external view returns (uint256) {
    Terms memory terms = s_terms[tokenID];
    return _getAskingRate(terms);
  }

  /**
   * @notice total amount owed: principal + interest, regardless of how much
   * has been withdrawn
   */
  function getTotalAmountOwed(uint256 tokenID) public view returns (uint256) {
    uint256 len = s_contributions[tokenID].length;
    if (len == 0) {
      return 0;
    }
    return s_contributions[tokenID][len - 1].totalAmountOwed;
  }

  /**
   * @notice net amount owed: principal + interest - balance
   */
  function getNetAmountOwed(uint256 tokenID) public view returns (uint256) {
    State memory state = s_state[tokenID];
    if (state.wasLiquidated || state.wasRepaid) {
      return 0;
    }
    uint256 len = s_contributions[tokenID].length;
    if (len == 0) {
      return 0;
    }
    return
      s_contributions[tokenID][len - 1].totalAmountOwed - s_balance[tokenID];
  }

  function getContributions(uint256 tokenID)
    external
    view
    returns (LoanContribution[] memory)
  {
    return s_contributions[tokenID];
  }

  /*
   * Should return 0 if Lender does not exist
   */
  function getLenderWithdrawableAmount(uint256 tokenID, address lender)
    public
    view
    returns (uint256)
  {
    // If lender already withdrew
    if (s_lenderWithdrawn[tokenID][lender]) {
      return 0;
    }
    State memory state = s_state[tokenID];
    uint256 total;
    uint256[] memory indices = s_lenderContrubutionIndices[tokenID][lender];
    if (state.wasRepaid) {
      for (uint256 idx = 0; idx < indices.length; idx++) {
        total += s_contributions[tokenID][indices[idx]].amountOwed;
      }
    } else if (state.wasLiquidated) {
      LoanContribution memory contribution;
      uint256 liquidationPrice = s_liquidationPrice[tokenID];
      for (uint256 idx = 0; idx < indices.length; idx++) {
        contribution = s_contributions[tokenID][indices[idx]];
        if (contribution.totalAmountOwed < liquidationPrice) {
          total += contribution.amountOwed;
        } else {
          uint256 prevTotalAmountOwed;
          if (indices[idx] > 0) {
            prevTotalAmountOwed = s_contributions[tokenID][indices[idx] - 1]
              .totalAmountOwed;
          }
          if (prevTotalAmountOwed < liquidationPrice) {
            total += liquidationPrice - prevTotalAmountOwed;
          }
          break;
        }
      }
    }
    return total;
  }

  /*************************************** PRIVATE *******************************************/

  function validate(Terms memory terms) private view {
    require(terms.startDate < terms.endDate, "end date in past");
    uint256 loanDuration = terms.endDate - terms.startDate;
    require(loanDuration >= MIN_LOAN_DURATION, "loan period too short");
    require(terms.minAPRRay <= terms.maxAPRRay, "max rate < min rate");
    require(terms.maxAPRRay > 0, "max rate is 0");
    require(
      terms.fundingPeriod >= MIN_FUNDING_PERIOD,
      "funding period too short"
    );
    require(terms.fundingPeriod <= loanDuration, "funding period too long");
    require(
      s_settlementTokens.contains(address(terms.settlementToken)),
      "invalid settlement token"
    );
  }

  function _pay(
    uint256 tokenID,
    Terms memory terms,
    uint256 amount
  ) private {
    uint256 newBalance = s_balance[tokenID] + amount;
    s_balance[tokenID] = newBalance;
    terms.settlementToken.transferFrom(msg.sender, address(this), amount);
  }

  function _getAskingRate(Terms memory terms) private view returns (uint256) {
    if (terms.fundingPeriod + terms.startDate <= block.timestamp) {
      return terms.maxAPRRay;
    }
    return
      terms.minAPRRay +
      (((terms.maxAPRRay - terms.minAPRRay) *
        (block.timestamp - terms.startDate)) / terms.fundingPeriod);
  }

  function _isLiquidatable(uint256 tokenID, Terms memory terms)
    private
    view
    returns (bool)
  {
    State memory state = s_state[tokenID];
    return
      terms.endDate < block.timestamp &&
      !state.wasRepaid &&
      !state.wasLiquidated &&
      s_contributions[tokenID].length > 0;
  }

  function _getLiquidationPrice(uint256 tokenID, Terms memory terms)
    public
    view
    returns (uint256)
  {
    if (block.timestamp - terms.endDate >= LIQUIDATION_PERIOD) {
      return 0;
    }
    uint256 owed = getTotalAmountOwed(tokenID);
    uint256 maxPrice = LIQUIDATION_PRICE_MULTIPLIER * owed;
    return
      maxPrice -
      (maxPrice * (block.timestamp - terms.endDate)) /
      LIQUIDATION_PERIOD;
  }

  /*************************************** PURE **********************************************/

  function calculateBalanceWithInterest(
    uint256 principal, // in wei
    uint256 duration, // in seconds
    uint256 rateRay // annual rate ray
  ) internal pure returns (uint256) {
    return
      rateRay
        .rayDiv(SECONDS_PER_YEAR_AS_RAY)
        .add(WadRayMath.RAY)
        .rayPow(duration)
        .rayMul(principal);
  }

  /*************************************** MODIFIERS *****************************************/

  modifier onlyBorrower(uint256 tokenID) {
    if (msg.sender != s_borrower[tokenID]) {
      revert Unauthorized();
    }
    _;
  }

  modifier repayable(uint256 tokenID) {
    State memory state = s_state[tokenID];
    if (state.wasLiquidated || state.wasRepaid) {
      revert NotRepayable();
    }
    _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
      uint256 len = _length(set._inner);
      address[] memory result = new address[](len);
      for (uint256 index = 0; index < len; index++) {
        result[index] = address(uint160(uint256(_at(set._inner, index))));
      }
      return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;
  uint256 internal constant HALF_WAD_RAY_RATIO = WAD_RAY_RATIO / 2;

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function weiToRay(uint256 a) internal pure returns (uint256) {
    return a * RAY;
  }

  function weiToWad(uint256 a) internal pure returns (uint256) {
    return a * WAD;
  }

  function rayToWei(uint256 a) internal pure returns (uint256) {
    return a / RAY;
  }

  function wadToWei(uint256 a) internal pure returns (uint256) {
    return a / WAD;
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    return (HALF_WAD_RAY_RATIO + a) / WAD_RAY_RATIO;
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a * WAD_RAY_RATIO;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (HALF_WAD + a * b) / WAD;
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (b / 2 + a * WAD) / b;
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (HALF_RAY + a * b) / RAY;
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return (b / 2 + a * RAY) / b;
  }

  function rayPow(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = b % 2 != 0 ? a : RAY;
    for (b /= 2; b != 0; b /= 2) {
      a = rayMul(a, a);
      if (b % 2 != 0) {
        c = rayMul(c, a);
      }
    }
    return c;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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