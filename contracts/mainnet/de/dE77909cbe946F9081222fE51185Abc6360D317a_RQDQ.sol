// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./ERC721Dispatcher.sol";
import "./IReservationBook.sol";

/**
 * @title RQDQ
 * @dev ERC721Dispatcher for ERC721Delegable tokens.
 * @author 0xAnimist (kanon.art)
 */
contract RQDQ is ERC721Dispatcher {

  IReservationBook private reservationBook;

  bool public initialized = false;

  // Basic terms
  struct TermBase {
    address currency;
    uint256 fee;
    uint256 durationInSecs;
  }

  /**
   * @dev Initializes the contract by setting a `name` and `symbol`for the token collection and initializes admin and platformFeeRecipient to contract deployer.
   */
  constructor(address _defaultCurrency, address _ERC721DispatcherURI) ERC721("RQDQ", "sDQ") {
    admin = _msgSender();
    platformFeeRecipient = _msgSender();
    defaultCurrency = _defaultCurrency;
    _SERVED_METHOD_IDs = [
      DispatchLib._METHOD_ID_BORROW,
      DispatchLib._METHOD_ID_BORROW_RESERVED,
      DispatchLib._METHOD_ID_BORROW_WITH_721_PASS,
      DispatchLib._METHOD_ID_BORROW_RESERVED_WITH_721_PASS,
      DispatchLib._METHOD_ID_BORROW_WITH_1155_PASS,
      DispatchLib._METHOD_ID_BORROW_RESERVED_WITH_1155_PASS
    ];
    ERC721DispatcherURI = _ERC721DispatcherURI;
  }

  function initialize(address _reservationBook) external {
    require(_msgSender() == admin, "only admin");
    reservationBook = IReservationBook(_reservationBook);
    initialized = true;
  }

  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external {
    require(_msgSender() == admin, "only admin");
    reservationBook.setDefaultMaxReservations(_defaultMaxReservations);
  }

  function setMaxReservations(uint256 _maxReservations, uint256 _tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "only owner");
    uint256[] memory tokenId = new uint256[](1);
    tokenId[0] = _tokenId;
    uint256[] memory maxReservations = new uint256[](1);
    maxReservations[0] = _maxReservations;
    reservationBook.setMaxReservations(maxReservations, tokenId);
  }

  function depositWithMaxReservations(address[] memory _RQContract, uint256[] memory _RQTokenId, bytes[][] memory _terms, uint256[] memory _maxReservations, bytes calldata _data) public virtual returns (uint256[] memory tokenIds) {
    tokenIds = ERC721Dispatcher.deposit(_RQContract, _RQTokenId, _terms, _data);
    reservationBook.setMaxReservations(_maxReservations, tokenIds);
  }

  function getReservationBook() external view returns (address) {
    require(initialized, "not init");
    return address(reservationBook);
  }

  /**
   * @dev Hook that allows for withdrawing withheld fees accrued outside of this contract.
   */
  function _refundAltWithholding(address _currency, uint256 _tokenId) internal virtual override {
    /* Hook */
    reservationBook.purgeExpired(_tokenId);
    reservationBook.refundFutureReservations(_currency, _tokenId);
  }

  function _claimAltFeesAccrued(address _currency, uint256 _tokenId) internal virtual override returns (bool success, uint256 alternateFeesClaimedInWei){
    uint256 openingBalance= _getThisBalance(_currency);

    (success, alternateFeesClaimedInWei) = reservationBook.claimFeesAccrued(_currency, _tokenId);

    uint256 currentBalance = _getThisBalance(_currency);
    success = success && ((currentBalance - openingBalance) == alternateFeesClaimedInWei);
  }

  function _getThisBalance(address _currency) internal view returns (uint256 balance){
    if(_currency == address(0)){//ETH
      balance = address(this).balance;
    }else{//ERC20
      balance = IERC20(_currency).balanceOf(address(this));
    }
  }

  function _processAltRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal virtual override returns (bool) {
    //pass _payee in case requires a pass that _payee must hold
    (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) = DispatchLib.validateRequest(_payee, _requestedTerms, _deposits[_tokenId].terms);
    require(valid, "inv alt req");

    if(DispatchLib.isReserveRequest(methodId)){//attempting to claim a reservation
      require(reservationBook.validateReservation(_to, _tokenId, _requestedTerms), "inv alt res");

      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;
    }else if(methodId == DispatchLib._METHOD_ID_BORROW_WITH_721_PASS || methodId == DispatchLib._METHOD_ID_BORROW_WITH_1155_PASS){
      require(DispatchLib.validatePass(_payee, methodId, _requestedTerms, _deposits[_tokenId].terms), "inv pass");

      require(isAvailable(_tokenId), "alt not avail");

      //process payment and update accounting
      _receivePayment(_payee, currency, fee);
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = fee;

      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;
    }else{
      return false;
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

/**
 * @title IReservationBook
 * @dev Interface for ReservationBook contract for ERC721Dispatcher.
 * @author 0xAnimist (kanon.art)
 */
interface IReservationBook {
  /**
   * @dev Emitted when `tokenId` token is reserved for `reservee` reservee by `payee` payee.
   */
  event Reserved(address indexed payee, address indexed reservee, uint256 startTime, uint256 indexed tokenId, bytes terms, bytes data);

  /**
   *  @dev Reserves `ERC721Delegable` `ERC721DelegableTokenId` token for `_reservee` beginning at `_startTime` with
   * `_terms` terms.
   *
   *  Requirements:
   *
   * - ERC721Delegable token must be deposited.
   * - terms must be acceptable
   * - token must not already be reserved in this time window (NOTE: duration described in terms)
   */
  function reserve(address _reservee, address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId, uint256 _startTime, bytes memory _requestTerms, bytes calldata _data) external payable returns (bool success);

  /**
   *  @dev Returns all reservations for `_tokenId` token.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function getReservations(uint256 _tokenId) external view returns (address[] memory reservees, uint256[] memory startTimes, bytes[] memory terms);

  /**
   *  @dev Returns `startTime` start time, `terms` terms, and address of
   * `reservee` if `_tokenId` token is reserved at `_time` time.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function reservedFor(uint256 _time, uint256 _tokenId) external view returns (address reservee, uint256 startTime, uint256 endTime, uint256 index);

  /**
   *  @dev Returns true if `_tokenId` token is reserved between `_startTime` and `_endTime`, as well as the index of the next reservation.
   *
   *  Requirements:
   *
   * - token must exist.
   */
  function isReserved(uint256 _startTime, uint256 _endTime, uint256 _tokenId) external view returns (bool reserved, uint256 nextIndex);

  /**
   *  @dev Returns true if `_requestedTerms` reservation terms requested by `_reservee` reservee on `_tokenId` token are valid.
   */
  function validateReservation(address _reservee, uint256 _tokenId, bytes memory _requestedTerms) external view returns (bool valid);

  /**
   *  @dev Sets the default maxiumum reservations a token can have at a time.
   */
  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external;

  /**
   *  @dev Sets the maxiumum reservations a token can have at a time.
   */
  function setMaxReservations(uint256[] memory _maxReservations, uint256[] memory _tokenIds) external;

  /**
   *  @dev Gets the maxiumum reservations a token can have at a time.
   */
  function getMaxReservations(uint256 _tokenId) external view returns (uint256 maxReservations);

  /**
   *  @dev Withdraws fees accrued for `_tokenId` token in `_currency` currency (where address(0) == ETH) to the caller.
   */
  function claimFeesAccrued(address _currency, uint256 _tokenId) external returns (bool success, uint256 feesClaimedInWei);

  /**
   *  @dev Refunds prepaid fees for all reservations with end times in the future.
   */
  function refundFutureReservations(address _currency, uint256 _tokenId) external;

  /**
   * @dev Removes expired reservations.
   */
  function purgeExpired(uint256 _tokenId) external returns (uint256 reservationsRemaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title IERC721Dispatcher
 * @dev Interface for an ERC721Delegable token dispatcher.
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Dispatcher {

  /**
   * @dev Emitted when a delegate token has been deposited.
   */
  event Deposited(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address depositedBy, bytes[] terms, bytes data);

  /**
   * @dev Emitted when a delegate token has been withdrawn.
   */
  event Withdrawn(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address withdrawnBy, bytes data);

  /**
   * @dev Emitted when an approval request has been granted.
   */
  event ApprovalGranted(address indexed sourceTokenContract, uint256 indexed sourceTokenId, address indexed to, address payee, bytes terms, bytes data);

  /**
   * @dev Emitted when terms are set for a token.
   */
  event TermsSet(address indexed owner, bytes[] terms, uint256 tokenId, bytes data);

  /**
   * @dev Deposits an array of delegate tokens of their corresponding delegable Tokens
   * in exchange for sDQ receipt tokens.
   *
   * Requirements:
   *
   * - must be the owner of the delegate token
   *
   * Emits a {Deposited} event.
   */
  function deposit(address[] memory _ERC721DelegableContract, uint256[] memory _ERC721DelegableTokenId, bytes[][] memory _terms, bytes calldata _data) external returns (uint256[] memory tokenIds);

  /**
   * @dev Withdraws a staked delegate token in exchange for `_tokenId` sDQ token receipt.
   *
   * Emits a {Withdrawn} event.
   */
  function withdraw(uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Sets the terms by which an approval request will be granted.
   *
   * Emits a {TermsSet} event.
   */
  function setTerms(bytes[] memory _terms, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the terms by which an approval request will be granted.
   */
  function getTerms(uint256 _tokenId) external view returns (bytes[] memory terms);

  /**
   * @dev Gets array of methodIds served by the dispatcher.
   */
  function getServedMethodIds() external view returns (bytes4[] memory methodIds);

  /**
   * @dev Gets timestamp of next availability for `_tokenId` token.
   */
  function getNextAvailable(uint256 _tokenId) external view returns (uint256 availableStartingTime);

  /**
   * @dev Gets source ERC721Delegable token for a given `_tokenId` token.
   */
  function getDepositByTokenId(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gets tokenId` token ID for a given source ERC721Delegable token.
   */
  function getTokenIdByDeposit(address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId) external view returns (bool success, uint256 tokenId);

  /**
   * @dev Requests dispatcher call approveByDelegate() on the source ERC721Delegable
   * token corresponding to `_tokenId` token for `_to` address with `_terms` terms.
   */
  function requestApproval(address _payee, address _to, address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId, bytes memory _terms, bytes calldata _data) external payable;

  /**
   * @dev Withdraws fees accrued to all eligible recipients for `_tokenId` token without withdrawing the token itself.
   *
   * Requirements:
   *
   * - token must exist.
   *
   */
  function claimFeesAccrued(uint256 _tokenId) external returns (bool success, address currency);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Delegable
 * @dev Interface for a delegable ERC721 token contract
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Delegable is IERC721 {
  /**
   * @dev Emitted when the delegate token is set for `tokenId` token.
   */
  event DelegateTokenSet(address indexed delegateContract, uint256 indexed delegateTokenId, uint256 indexed tokenId, address operator, bytes data);

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId) external;

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getDelegateToken(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the delegate token.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approveByDelegate(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IERC721Delegable.sol";
import "./BytesLib.sol";
import "./DispatchLib.sol";
import "./BasisPoints.sol";
import "./IERC721Dispatcher.sol";

interface IERC721DispatcherURI {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title ERC721Dispatcher
 * @dev Abstract Dispatcher contract that allows fee splitting.
 * @author 0xAnimist (kanon.art)
 */
abstract contract ERC721Dispatcher is IERC721Dispatcher, IERC721Receiver, ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {

  // Contract administrator
  address public admin;

  // Address of contract that renders tokenURI
  address public ERC721DispatcherURI;

  // ERC165 interface ID for ERC2981
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // Array of method IDs served by this contract
  bytes4[] public _SERVED_METHOD_IDs;

  // Stores information for deposited delegate tokens
  struct Deposit {
    bool valid;
    address RQContract;
    uint256 RQTokenId;
    uint256 nextAvailable;
    uint256 withholdingInWei;
    uint256 feesAccruedInWei;
    bytes[] terms;
    address[] recipients;
    uint256[] sharesInBp;
  }

  // Mapping from token ID to Deposited delegate token and its source delegable token
  mapping(uint256 => Deposit) internal _deposits;

  // Mapping from source delegable token to token ID
  mapping(address => mapping(uint256 => uint256)) internal _tokenIdsByDeposit;

  // Counter of total deposits, does not decrement on withdraw
  uint256 internal totalDeposits = 1;

  // Default RQDQ platform fee
  uint256 public defaultPlatformFeeInBp = 500;//5%

  // Recipient of RQDQ platform fee
  address public platformFeeRecipient;

  // Default RQDQ royalty fee
  uint256 public defaultRoyaltyInBp = 1000;//10%

  // Allows depositors to set currencies != defaultCurrency
  bool public settableCurrency = false;

  // Default platform currency
  address public defaultCurrency;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
      return interfaceId == type(IERC721Dispatcher).interfaceId || interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(ERC721Enumerable).interfaceId || interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Sets contract administrator.
   */
  function setAdmin(address _admin) external {
    require(_msgSender() == admin, "only admin can set");
    admin = _admin;
  }

  /**
   * @dev Sets platform parameters.
   */
  function setPlatformParams(address _platformFeeRecipient, uint256 _defaultPlatformFeeInBp, uint256 _defaultRoyaltyInBp, bool _settableCurrency, address _defaultCurrency) external {
    require(_msgSender() == admin, "only admin can set");
    platformFeeRecipient = _platformFeeRecipient;
    defaultPlatformFeeInBp = _defaultPlatformFeeInBp;
    defaultRoyaltyInBp = _defaultRoyaltyInBp;
    defaultCurrency = _defaultCurrency;
    settableCurrency = _settableCurrency;
  }

  /**
   * @dev See {IERC2981-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address receiver, uint256 royaltyAmount) {
    try IERC2981(_deposits[tokenId].RQContract).royaltyInfo(_deposits[tokenId].RQTokenId, salePrice) returns (address _receiver, uint256 _royaltyAmount) {
      return (_receiver, _royaltyAmount);
    } catch {
      return (address(0), 0);
    }
  }

  /**
   * @dev See {IERC721Dispatcher-getServedMethodIds}.
   */
  function getServedMethodIds() external view returns (bytes4[] memory methodIds) {
    return _SERVED_METHOD_IDs;
  }

  /**
   * @dev Sets recipients of fees accrued for `_tokenId` token and their relative share.
   * @param _recipients array of recipient addresses
   * @param _sharesInBp relative share in basis points
   * @param _tokenId token
   */
  function setFeeRecipients(address[] memory _recipients, uint256[] memory _sharesInBp, uint256 _tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "only sDQ can set");
    require(_recipients.length == _sharesInBp.length, "one recipient per share");

    uint256 shareTotalInBp;
    for(uint256 i = 0; i < _sharesInBp.length; i++){
      shareTotalInBp += _sharesInBp[i];
    }
    require(shareTotalInBp <= (BasisPoints.BASE - defaultPlatformFeeInBp - defaultRoyaltyInBp), "over 100");

    _deposits[_tokenId].recipients = _recipients;
    _deposits[_tokenId].sharesInBp = _sharesInBp;
  }

  /**
   * @dev See {IERC721Dispatcher-deposit}.
   */
  function deposit(address[] memory _RQContract, uint256[] memory _RQTokenId, bytes[][] memory _terms, bytes calldata _data) public virtual override returns (uint256[] memory tokenIds) {
    tokenIds = new uint256[](_RQContract.length);

    //stake the delegate token; it is the same for all RQs
    (address delegateContract, uint256 delegateTokenId) = IERC721Delegable(_RQContract[0]).getDelegateToken(_RQTokenId[0]);

    tokenIds[0] = _singleDeposit(_RQContract[0], _RQTokenId[0], _terms[0], _data);

    for(uint256 i = 1; i < _RQContract.length; i++){
      (address iDelegateContract, uint256 iDelegateTokenId) = IERC721Delegable(_RQContract[i]).getDelegateToken(_RQTokenId[i]);

      require((iDelegateContract == delegateContract) && (iDelegateTokenId == delegateTokenId), "not same delegate");

      tokenIds[i] = _singleDeposit(_RQContract[i], _RQTokenId[i], _terms[i], _data);
    }

    IERC721(delegateContract).safeTransferFrom(_msgSender(), address(this), delegateTokenId, _data);

    require(IERC721(delegateContract).ownerOf(delegateTokenId) == address(this), "delegate not trans");
  }

  /**
   * @dev Deposits a single delegate token for a single ERC721Delegable token.
   */
  function _singleDeposit(address _RQContract, uint256 _RQTokenId, bytes[] memory _terms, bytes calldata _data) internal virtual returns (uint256 tokenId){
    require(
      address(0) != IERC721Delegable(_RQContract).ownerOf(_RQTokenId),
       "RQ token not minted"
     );
    require(DispatchLib.validateTerms(settableCurrency, defaultCurrency, _terms, _SERVED_METHOD_IDs), "inv terms");

    //record the deposit
    tokenId = totalDeposits++;
    _deposits[tokenId].valid = true;
    _deposits[tokenId].RQContract = _RQContract;
    _deposits[tokenId].RQTokenId = _RQTokenId;
    _deposits[tokenId].terms = _terms;
    _deposits[tokenId].recipients = new address[](0);
    _tokenIdsByDeposit[_RQContract][_RQTokenId] = tokenId;

    //mint the sDQ receipt token
    _safeMint(_msgSender(), tokenId);

    emit Deposited(_RQContract, _RQTokenId, tokenId, _msgSender(), _terms, _data);
  }

  /**
   * @dev See {IERC721Dispatcher-withdraw}.
   */
  function withdraw(uint256 _tokenId, bytes calldata _data) external virtual override nonReentrant {
    require(_exists(_tokenId), "no id");
    require(_msgSender() == ownerOf(_tokenId), "not owner");

    //return the delegate token
    (address delegateTokenContract, uint256 delegateTokenId) = IERC721Delegable(_deposits[_tokenId].RQContract).getDelegateToken(_deposits[_tokenId].RQTokenId);
    IERC721(delegateTokenContract).safeTransferFrom(address(this), _msgSender(), delegateTokenId, _data);

    //payout any unclaimed fees accrued, return withholding if necessary
    (,address currency) = claimFeesAccrued(_tokenId);
    _refundWithholding(currency, _tokenId);
    _refundAltWithholding(currency, _tokenId);

    //invalidate _deposits[_tokenId]
    _deposits[_tokenId].valid = false;

    //burn the sDQ token
    _burn(_tokenId);

    emit Withdrawn(_deposits[_tokenId].RQContract, _deposits[_tokenId].RQTokenId, _tokenId, _msgSender(), _data);
  }

  function _refundWithholding(address _currency, uint256 _tokenId) internal {
    if(block.timestamp < _deposits[_tokenId].nextAvailable && _deposits[_tokenId].withholdingInWei > 0){
      (address RQContract, uint256 RQTokenId) = getDepositByTokenId(_tokenId);
      address withholdingRecipient = IERC721(RQContract).ownerOf(RQTokenId);
      _pay(_currency, withholdingRecipient, _deposits[_tokenId].withholdingInWei);
    }

    _deposits[_tokenId].withholdingInWei = 0;
  }

  /**
   * @dev Hook that allows for withdrawing withheld fees accrued outside of this contract.
   */
   function _refundAltWithholding(address _currency, uint256 _tokenId) internal virtual {
     /* Hook */
   }


  function claimFeesAccrued(uint256 _tokenId) public returns (bool success, address currency){
    //process status of withholding
    if(block.timestamp >= _deposits[_tokenId].nextAvailable){
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = 0;
    }

    //all currencies must be the same, so just use the first one
    (currency,,) = DispatchLib.unpackBorrowTerms(_deposits[_tokenId].terms[0]);

    uint256 alternateFeesAccruedInWei;
    (success, alternateFeesAccruedInWei) = _claimAltFeesAccrued(currency, _tokenId);

    if((_deposits[_tokenId].feesAccruedInWei + alternateFeesAccruedInWei) > 0){
      //includes hook to include alternate fees accrued
      success = success && _payFeesAccruedToAllRecipients(currency, _deposits[_tokenId].feesAccruedInWei + alternateFeesAccruedInWei, _tokenId);
    }
  }

  /**
   * @dev Hook that is called when withdrawing fees accrued in `_currency` currency. Allows for withdrawing fees accrued outside of this contract.
   */
  function _claimAltFeesAccrued(address _currency, uint256 _tokenId) internal virtual returns (bool success, uint256 alternateFeesClaimedInWei){
    /* Hook */
    return (true, 0);
  }

  function _payFeesAccruedToAllRecipients(address _currency, uint256 _feesAccruedInWei, uint256 _tokenId) internal returns (bool success){
    uint256 sharesPaidInWei = 0;
    success = true;

    //pay out platform fee
    if(platformFeeRecipient != address(0)){
      uint256 platformFee = BasisPoints.mulByBp(_feesAccruedInWei, defaultPlatformFeeInBp);
      success = success && _pay(_currency, platformFeeRecipient, platformFee);
      sharesPaidInWei += platformFee;
    }

    //pay out royalty
    (address royaltyRecipient, uint256 royaltyAmount) = royaltyInfo(_tokenId, _feesAccruedInWei);
    if(royaltyRecipient != address(0) && royaltyAmount > 0){
      success = success && _pay(_currency, royaltyRecipient, royaltyAmount);
      sharesPaidInWei += royaltyAmount;
    }

    //pay out shares to all recipients
    for(uint256 i = 0; i < _deposits[_tokenId].recipients.length; i++){
      uint256 shareInWei = BasisPoints.mulByBp(_feesAccruedInWei, _deposits[_tokenId].sharesInBp[i]);
      success = success && _pay(_currency, _deposits[_tokenId].recipients[i], shareInWei);
      sharesPaidInWei += shareInWei;
    }

    //pay remainder to sDQ owner
    address sDQOwner = ownerOf(_tokenId);
    success = success && _pay(_currency, sDQOwner, _feesAccruedInWei - sharesPaidInWei);

    _deposits[_tokenId].feesAccruedInWei = 0;
  }

  function _pay(address _currency, address _recipient, uint256 _amountInWei) internal returns (bool success){
    if(_currency == address(0)){//ETH is the currency
      (success,) = _recipient.call{value: _amountInWei}("");
    }else{//currency is an ERC20
      try IERC20(_currency).transfer(_recipient, _amountInWei) returns (bool transferred){
        success = transferred;
      } catch {}
    }
  }

  /**
   * @dev See {IERC721Dispatcher-setTerms}.
   */
  function setTerms(bytes[] memory _terms, uint256 _tokenId, bytes calldata _data) external virtual override {
    require(_exists(_tokenId), "no id");
    require(_msgSender() == ownerOf(_tokenId), "not owner");

    require(DispatchLib.validateTerms(settableCurrency, defaultCurrency, _terms, _SERVED_METHOD_IDs), "inv terms");

    //must zero out accounts to change currency
    (bool currencyIsDifferent) = DispatchLib.isCurrencyDiff(_terms[0], _deposits[_tokenId].terms[0]);
    if(currencyIsDifferent){
      require((_deposits[_tokenId].feesAccruedInWei == 0) && (_deposits[_tokenId].withholdingInWei == 0), "claim fees or withdraw");
    }

    _deposits[_tokenId].terms = _terms;

    emit TermsSet(_msgSender(), _terms, _tokenId, _data);
  }

  /**
   * @dev See {IERC721Dispatcher-getTerms}.
   */
  function getTerms(uint256 _tokenId) public view virtual override returns (bytes[] memory terms) {
    require(_exists(_tokenId), "no id");
    return _deposits[_tokenId].terms;
  }

  /**  @dev Gets the deposited RQ NFT contract address and `tokenId` for a given sDQ NFT `_tokenId`
    *  @param _tokenId sDQ NFT tokenId to query
    *  @return contractAddress deposited NFT contract address
    *  @return tokenId deposited NFT tokenId
    */
  function getDepositByTokenId(uint256 _tokenId) public view virtual override returns(address contractAddress, uint256 tokenId) {
    require(_tokenId < totalDeposits, "no id");
    return (_deposits[_tokenId].RQContract, _deposits[_tokenId].RQTokenId);
  }

  /**
   * @dev Gets the sDQ NFT `tokenId` for a given deposited NFT contract address and `tokenId`
   * @param _RQContract deposited NFT contract address
   * @param _RQTokenId deposited NFT tokenId
   * @return success true if successful
   * @return tokenId sDQ NFT token ID
   */
  function getTokenIdByDeposit(address _RQContract, uint256 _RQTokenId) public view returns (bool success, uint256 tokenId) {
    if(_tokenIdsByDeposit[_RQContract][_RQTokenId] > 0){
      return (true, _tokenIdsByDeposit[_RQContract][_RQTokenId]);
    }
    return (false, 0);
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data) external virtual override pure returns(bytes4) {

      return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev See {IERC721Dispatcher-requestApproval}.
   */
  function requestApproval(address _payee, address _to, address _RQContract, uint256 _RQTokenId, bytes memory _terms, bytes calldata _data) external payable virtual override {
    (bool exists, uint256 tokenId) = getTokenIdByDeposit(_RQContract, _RQTokenId);
    require(exists, "no id");

    require(_processRequest(_payee, _to, tokenId, _terms), "fail");

    if(_to != IERC721(_RQContract).getApproved(_RQTokenId) && _to != IERC721(_RQContract).ownerOf(_RQTokenId)){
      IERC721Delegable(_deposits[tokenId].RQContract).approveByDelegate(_payee, _deposits[tokenId].RQTokenId);
    }

    emit ApprovalGranted(_deposits[tokenId].RQContract, _deposits[tokenId].RQTokenId, _to, _msgSender(), _terms, _data);
  }

  function _processRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal returns (bool processed){
    //check if request is served by this contract
    if(DispatchLib.isPaymentOutstanding(_requestedTerms)){
      (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) = DispatchLib.validateRequest(_payee, _requestedTerms, _deposits[_tokenId].terms);
      require(valid, "inv req");
      require(isAvailable(_tokenId), "not avail");

      //process payment and update accounting
      _receivePayment(_payee, currency, fee);
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = fee;

      //shift availability window
      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;

      return true;
    }else{//hook to process alt request
      return _processAltRequest(_payee, _to, _tokenId, _requestedTerms);
    }
  }

  /**
   * @dev Proceeses payment.
   */
  function _receivePayment(address _payee, address _currency, uint256 _fee) internal {
    if(_fee > 0){
      //collect withholding
      if(_currency != address(0)){//pay in ERC20
        IERC20(_currency).transferFrom(_payee, address(this), _fee);
      }else{//pay in ETH
        require(msg.value >= _fee, "more ETH");
      }
    }
  }

  function _processAltRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal virtual returns (bool proceesed) {
    return false;
  }

  /**
   * @dev Returns true if `_tokenId` token is available.
   */
  function isAvailable(uint256 _tokenId) public view returns (bool) {
    if(_deposits[_tokenId].nextAvailable <= block.timestamp){
      return true;
    }
    return false;
  }

  function getNextAvailable(uint256 _tokenId) external view returns (uint256 availableStartingTime) {
    return _deposits[_tokenId].nextAvailable;
  }

  function setERC721DispatcherURI(address _ERC721DispatcherURI) external {
    require(_msgSender() == admin, "only admin");
    ERC721DispatcherURI = _ERC721DispatcherURI;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "no such token");
    return IERC721DispatcherURI(ERC721DispatcherURI).tokenURI(tokenId);
  }

}

// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./IERC721Dispatcher.sol";
import "./BytesLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title DispatchLib
/// @notice Utility library for ERC721Dispatcher
/// @author 0xAnimist (kanon.art)
library DispatchLib {

  bytes4 public constant _METHOD_ID_BORROW = bytes4(keccak256("borrow(address,uint256,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED = bytes4(keccak256("borrowReserved(address,uint256,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs)

  bytes4 public constant _METHOD_ID_BORROW_WITH_721_PASS = bytes4(keccak256("borrowWith721Pass(address,uint256,uint256,address)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC721Contract)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED_WITH_721_PASS = bytes4(keccak256("borrowReservedWith721Pass(address,uint256,uint256,address)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC721Contract)

  bytes4 public constant _METHOD_ID_BORROW_WITH_1155_PASS = bytes4(keccak256("borrowWith1155Pass(address,uint256,uint256,address,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC1155Contract, ERC1155TokenId)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS = bytes4(keccak256("borrowReservedWith1155Pass(address,uint256,uint256,address,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC1155Contract, ERC1155TokenId)

  function validateMethodId(bytes4 methodId) public pure returns (bool valid) {
    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      valid = true;
    }
  }

  function validateRequestFormat(bytes memory _term, bytes4[] memory _servedMethodIds) public pure returns (bool valid) {
    bytes4 methodId = bytes4(_term);
    for(uint256 i = 0; i < _servedMethodIds.length; i++){
      if(_servedMethodIds[i] == methodId){//methodId is served
        if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED){
          return _term.length == 88;
        }else if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS){
          return _term.length == 108;
        }else if(methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
          return _term.length == 140;
        }
      }
    }
  }

  function isReserveRequest(bytes4 methodId) public pure returns (bool reserveRequest) {
    if(methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      reserveRequest = true;
    }
  }

  function getDuration(bytes memory _terms) public pure returns (uint256 duration) {
    if(validateMethodId(bytes4(_terms))){
      return BytesLib.toUint256(_terms, 56);
    }
  }

  function isReservedMethodId(bytes4 _methodId) public pure returns (bool reservedMethodId) {
    if(_methodId == _METHOD_ID_BORROW_RESERVED || _methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || _methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      return true;
    }
    return false;
  }


  function isCurrencyDiff(bytes memory _newTerms, bytes memory _oldTerms) public pure returns (bool diff) {
    diff = BytesLib.toAddress(_newTerms, 4) != BytesLib.toAddress(_oldTerms, 4);
  }

  function getBorrowTerms(bytes[] memory _terms) public pure returns (bool success, address currency, uint256 feeInWeiPerSec, uint256 maxDurationInSecs){
    (bool borrowTermsSet, uint256 i) = getTermIndexByMethodId(_terms, _METHOD_ID_BORROW);
    if(borrowTermsSet){
      (currency, feeInWeiPerSec, maxDurationInSecs) = unpackBorrowTerms(_terms[i]);
      success = true;
    }
  }

  function getTermIndexByMethodId(bytes[] memory _terms, bytes4 _type) public pure returns (bool success, uint256 index) {
    for(uint256 i = 0; i < _terms.length; i++){
      if(bytes4(_terms[i]) == _type){
        return (true, i);
      }
    }
  }

  function unpackMethodId(bytes memory _term) public pure returns (bytes4 methodId) {
    require(_term.length >= 4, "no methodId");
    return bytes4(_term);
  }

  function requiresPass(bytes memory _term) public pure returns (bool required, bool is721) {
    bytes4 methodId = unpackMethodId(_term);
    if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS){
      required = true;
      is721 = true;
    }else if(methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      required = true;
      is721 = false;
    }
  }

  function termsApproved(bytes memory _approvedTerms, bytes memory _requestedTerms) public pure returns (bool approved) {
    return BytesLib.equal(_approvedTerms, _requestedTerms);
  }

  function validateTerms(bool settableCurrency, address defaultCurrency, bytes[] memory _terms, bytes4[] memory _servedMethodIds) public pure returns (bool valid) {
    address firstCurrency = BytesLib.toAddress(_terms[0], 4);

    for(uint256 i = 0; i < _terms.length; i++){
      //determines if it served and if the terms well-formatted
      validateRequestFormat(_terms[i], _servedMethodIds);

      //validate currencies
      address currency = BytesLib.toAddress(_terms[i], 4);
      if((currency != firstCurrency && settableCurrency && i > 0) || (currency != defaultCurrency && !settableCurrency)){
        return false;//cannot have multiple currencies
      }
    }

    return true;
  }

  function unpackPass(bytes memory _term) public pure returns (bool passRequired, bool is721, bool hasId, address passContract, uint256 passId) {
    (passRequired, is721) = requiresPass(_term);
    if(passRequired){
      passContract = unpackPassContractTerms(_term);
      if(!is721){
        passId = unpackPassIdTerms(_term);
        hasId = true;
      }
    }
  }

  function unpackPassIdTerms(bytes memory _term) public pure returns (uint256 passId) {
    return BytesLib.toUint256(_term, 108);
  }

  function unpackPassContractTerms(bytes memory _term) public pure returns (address passContract) {
    return BytesLib.toAddress(_term, 88);
  }

  function unpackBorrowTerms(bytes memory _term) public pure returns (address currency, uint256 feeInWeiPerSec, uint256 maxDurationInSecs) {
    return (BytesLib.toAddress(_term, 4), BytesLib.toUint256(_term, 24), BytesLib.toUint256(_term, 56));
  }

  function validateReservation(address _from, bytes memory _requestTerms, bytes[] memory _allApprovedTerms) public pure returns (bool valid, address currency, uint256 fee, uint256 durationInSecs){

    (bool validTerms, bytes4 methodId, address currency_, uint256 fee_, uint256 durationInSecs_) = validateRequestedBorrowTerms(_requestTerms, _allApprovedTerms);

    bool isReservedMethod = isReservedMethodId(methodId);

    bool validPass = true;//validatePass(_from, methodId, _requestTerms, _allApprovedTerms);

    return (true == validPass == validTerms == isReservedMethod, currency_, fee_, durationInSecs_);
  }

  function validateRequest(address _payee, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public view returns (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) {
    //paid is true if prepaid (eg as with reservation)
    bool validTerms;
    (validTerms, methodId, currency, fee, durationInSecs) = validateRequestedBorrowTerms(_requestedTerms, _allApprovedTerms);

    bool validPass = true;

    if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS){
      validPass = validatePass(_payee, methodId, _requestedTerms, _allApprovedTerms);
    }

    valid = (true == validTerms == validPass);
  }

  function isApprovedPassContract(address _requestedPassContract, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool approved) {
    for(uint256 i = 0; i < _allApprovedTerms.length; i++){
      if(bytes4(_allApprovedTerms[i]) == bytes4(_requestedTerms)){
        if(_requestedPassContract == unpackPassContractTerms(_allApprovedTerms[i])){
          return true;
        }
      }
    }
  }

  function isApprovedPassId(uint256 _requestedPassId, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool approved) {
    for(uint256 i = 0; i < _allApprovedTerms.length; i++){
      if(bytes4(_allApprovedTerms[i]) == bytes4(_requestedTerms)){
        if(_requestedPassId == unpackPassIdTerms(_allApprovedTerms[i])){
          return true;
        }
      }
    }
  }

  function validatePass(address _passHolder, bytes4 _methodId, bytes memory _requestTerms, bytes[] memory _allApprovedTerms) public view returns (bool valid){
    address requestedPassContract = unpackPassContractTerms(_requestTerms);

    if(!isApprovedPassContract(requestedPassContract, _requestTerms, _allApprovedTerms)){
      return false;
    }

    if(_methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || _methodId == _METHOD_ID_BORROW_WITH_721_PASS){
      if(IERC721(requestedPassContract).balanceOf(_passHolder) < 1){
        return false;
      }
    }else if(_methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS || _methodId == _METHOD_ID_BORROW_WITH_1155_PASS){
      uint256 requestedPassId = unpackPassIdTerms(_requestTerms);

      if(!isApprovedPassId(requestedPassId, _requestTerms, _allApprovedTerms)){
        return false;
      }

      if(IERC1155(requestedPassContract).balanceOf(_passHolder, requestedPassId) < 1){
        return false;
      }
    }
    return true;
  }

  function validateRequestedBorrowTerms(bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) {
    methodId = bytes4(_requestedTerms);

    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS){

      for(uint256 i = 0; i < _allApprovedTerms.length; i++){
        if(bytes4(_allApprovedTerms[i]) == methodId){
          (address approvedCurrency, uint256 approvedFeeInWeiPerSec, uint256 approvedMaxDurationInSecs) = unpackBorrowTerms(_allApprovedTerms[i]);

          (address requestedCurrency, uint requestedTotalFeeInWei, uint256 requestedDurationInSecs) = unpackBorrowTerms(_requestedTerms);

          require(requestedCurrency == approvedCurrency, "RequestLib: request currency invalid");

          fee = requestedDurationInSecs * approvedFeeInWeiPerSec;
          require(requestedTotalFeeInWei >= fee, "RequestLib: requested fee insufficient for requested duration");

          require(requestedDurationInSecs <= approvedMaxDurationInSecs, "RequestLib: requested duration exceeds max");

          valid = true;
          currency = approvedCurrency;
          durationInSecs = requestedDurationInSecs;
          break;
        }
      }
    //}else if(request == _METHOD_ID_BORROWTO){

    //}
    }
  }

  function isPaymentOutstanding(bytes memory _requestedTerms) public pure returns (bool outstanding) {
    bytes4 methodId = bytes4(_requestedTerms);
    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS) {
      return true;
    }
  }

  /// @dev Checks if a time window is already reserved in an
  /// array of reservations ordered by ascending start times
  function isReserved(uint256 _endTime, uint256[] memory _startTimes, bytes[] memory _terms) public pure returns (bool reserved, uint256 nextIndex) {
    uint256[] memory endTimes = new uint256[](_startTimes.length);

    for(uint256 i = 0; i < _startTimes.length; i++){
      endTimes[i] = _startTimes[i] + getDuration(_terms[i]) -1;
    }

    //insert reservation
    for(uint256 i = 0; i <= _startTimes.length; i++){
      nextIndex = i;
      if(i == _startTimes.length){
        return (false, i);
      }

      if(endTimes[i] > _endTime){
        if(_startTimes[i] > _endTime){
          break;
        }else{
          return (true, 0);
        }
      }
    }
    reserved = false;
  }

  function reservedFor(uint256 _time, address[] memory _reservees, uint256[] memory _startTimes, bytes[] memory _terms) public pure returns (bool reserved, uint256 index, uint256 endTime) {
    for(uint256 i = 0; i < _startTimes.length; i++){
      if(_startTimes[i] <= _time){
        endTime = _startTimes[i] + getDuration(_terms[i]);
        if(_time <= endTime){
          reserved = true;
          index = i;
        }
      }
    }
  }

}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title BasisPoints
/// @notice Provides a function for multiplying in basis points
library BasisPoints {

  uint128 public constant BASE = 10000;

  /**  @notice Calculate _input * _basisPoints / _base rounding down
    *  @dev from Mikhail Vladimirov's response here: https://ethereum.stackexchange.com/questions/55701/how-to-do-solidity-percentage-calculation/55702
    */
  function mulByBp(uint256 _input, uint256 _basisPoints) public pure returns (uint256) {
    uint256 a = _input / BASE;
    uint256 b = _input % BASE;
    uint256 c = _basisPoints / BASE;
    uint256 d = _basisPoints % BASE;

    return a * c * BASE + a * d + b * c + b * d / BASE;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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