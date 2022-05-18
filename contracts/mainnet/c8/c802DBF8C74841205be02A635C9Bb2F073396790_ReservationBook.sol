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

import "./IReservationBook.sol";
import "./IERC721Dispatcher.sol";
import "./DispatchLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ReservationBook
 * @dev ReservationBook contract for use with ERC721Dispatcher.
 * @author 0xAnimist (kanon.art)
 */
contract ReservationBook is IReservationBook {

  // ERC721Dispatcher
  address public dispatcherAddress;

  // The dispatcher
  IERC721Dispatcher private dispatcher;

  // Basic terms
  struct TermBase {
    address payee;
    address reservee;
    address currency;
    uint256 fee;
    uint256 durationInSecs;
  }

  // Stores reservation information
  struct Reservations {
    uint256 startingIndex;
    uint256 maxReservations;
    uint256[] startTimes;
    uint256[] feesAccruedInWei;
    address[] reservees;
    address[] payees;
    bytes[] terms;
  }

  // Mapping from token ID to reservations
  mapping(uint256 => Reservations) internal _reservations;

  // Temporary buffer for processing refunds
  mapping(uint256 => address) private _refundRecipientsBuffer;

  // Temporary buffer for processing refunds
  mapping(address => uint256) private _refundAmountBuffer;

  // Default maxiumum reservations per token
  uint256 defaultMaxReservations = 20;

  modifier onlyDispatcher() {
    require(msg.sender == dispatcherAddress, "only dispatcher");
    _;
  }

  /**
   * @dev Constructor.
   */
  constructor(address _dispatcherAddress) {
    dispatcherAddress = _dispatcherAddress;
    dispatcher = IERC721Dispatcher(_dispatcherAddress);
  }

  /**
   * @dev See {IReservationBook-setDefaultMaxReservations}.
   */
  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external virtual override onlyDispatcher {
    defaultMaxReservations = _defaultMaxReservations;
  }

  /**
   * @dev See {IReservationBook-setMaxReservations}.
   */
  function setMaxReservations(uint256[] memory _maxReservations, uint256[] memory _tokenIds) external virtual override onlyDispatcher {
    require(_tokenIds.length == _maxReservations.length, "must be same length");
    for(uint256 i = 0; i < _tokenIds.length; i++){
      _reservations[_tokenIds[i]].maxReservations = _maxReservations[i];
    }
  }

  /**
   * @dev See {IReservationBook-getMaxReservations}.
   */
  function getMaxReservations(uint256 _tokenId) external virtual override view returns (uint256 maxReservations) {
    return _reservations[_tokenId].maxReservations;
  }

  /**
   * @dev See {IReservationBook-reserve}.
   */
  function reserve(address _reservee, address _RQContract, uint256 _RQTokenId, uint256 _startTime, bytes memory _requestTerms, bytes calldata _data) external payable virtual override returns (bool success) {
    (bool tokenExists, uint256 tokenId) = dispatcher.getTokenIdByDeposit(_RQContract, _RQTokenId);
    require(tokenExists, "no such tokenId");
    require(_startTime >= block.timestamp, "past");

    uint256 reservationsRemaining = purgeExpired(tokenId);

    require(reservationsRemaining > 0, "reservations full");

    //confirm terms are acceptable
    bool valid;
    TermBase memory termBase;
    (valid, termBase.currency, termBase.fee, termBase.durationInSecs) = DispatchLib.validateReservation(msg.sender, _requestTerms, dispatcher.getTerms(tokenId));
    require(valid, "inv");

    //confirm the reservation window is available
    (bool reserved, uint256 insertHere) = isReserved(_startTime, _startTime + termBase.durationInSecs - 1, tokenId);
    require(!reserved, "already reserved at this time");
    require(dispatcher.getNextAvailable(tokenId) <= _startTime, "not avail");

    //process pre-payment
    _processPayment(msg.sender, termBase.currency, termBase.fee);

    termBase.reservee = _reservee;
    termBase.payee = msg.sender;

    success = _insertReservation(termBase, _startTime, insertHere, tokenId, _requestTerms);

    if(success){
      emit Reserved(termBase.payee, termBase.reservee, _startTime, tokenId, _requestTerms, _data);
    }
  }

  /**
   * @dev Proceeses payment.
   */
  function _processPayment(address _payee, address _currency, uint256 _fee) internal {
    if(_fee > 0){
      //collect withholding
      if(_currency != address(0)){//pay in ERC20
        IERC20(_currency).transferFrom(_payee, address(this), _fee);
      }else{//pay in ETH
        require(msg.value >= _fee, "more ETH");
      }
    }
  }

  /**
   * @dev See {IReservationBook-refundFutureReservations}.
   */
  function refundFutureReservations(address _currency, uint256 _tokenId) external {
    uint256 totalRecipients = 0;

    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].feesAccruedInWei.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);

      if(endTime >= block.timestamp){
        for(uint256 j = 0; j <= totalRecipients; j++){
          if(_refundRecipientsBuffer[j] == _reservations[_tokenId].payees[i]){
            break;
          }else{
            if(j == totalRecipients){
              _refundRecipientsBuffer[totalRecipients] = _reservations[_tokenId].payees[i];
              totalRecipients++;
              break;
            }
          }
        }
        //require(false, "add to buffer");
        _refundAmountBuffer[_reservations[_tokenId].payees[i]] += _reservations[_tokenId].feesAccruedInWei[i];

      }
    }
    _processRefunds(_currency, totalRecipients);
  }

  /**
   * @dev Processes refunds to recipients, paying with `_currency` currency.
   */
  function _processRefunds(address _currency, uint256 _totalRecipients) internal {
    //require(false, "_processRefunds");
    for(uint256 i = 0; i < _totalRecipients; i++){
      //require(false, "_processRefunds for");
      _pay(_currency, _refundRecipientsBuffer[i], _refundAmountBuffer[_refundRecipientsBuffer[i]]);

      delete _refundAmountBuffer[_refundRecipientsBuffer[i]];
      delete _refundRecipientsBuffer[i];
    }
  }

  /**
   * @dev See {IReservationBook-claimFeesAccrued}.
   */
  function claimFeesAccrued(address _currency, uint256 _tokenId) external onlyDispatcher returns (bool success, uint256 feesClaimedInWei){
    uint256 feesToPayInWei = 0;
    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].feesAccruedInWei.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);
      if(block.timestamp > endTime){
        feesToPayInWei += _reservations[_tokenId].feesAccruedInWei[i];
        _clearReservation(i, _tokenId);
      }
    }

    return _pay(_currency, dispatcherAddress, feesToPayInWei);
  }

  /**
   * @dev Clears reservation at `_i` index on `_tokenId` token.
   */
  function _clearReservation(uint256 _i, uint256 _tokenId) internal {
    delete _reservations[_tokenId].startTimes[_i];
    delete _reservations[_tokenId].feesAccruedInWei[_i];
    delete _reservations[_tokenId].payees[_i];
    delete _reservations[_tokenId].reservees[_i];
    delete _reservations[_tokenId].terms[_i];
  }

  /**
   * @dev Pays out `_amountInWei` amount in wei of `_currency` currency to `_recipient` recipient.
   */
  function _pay(address _currency, address _recipient, uint256 _amountInWei) internal returns (bool success, uint256 paidInWei){
    if(_currency == address(0)){//ETH is the currency
      (success,) = _recipient.call{value: _amountInWei}("");
    }else{//currency is an ERC20
      try IERC20(_currency).transfer(_recipient, _amountInWei) returns (bool transferred){
        success = transferred;
      } catch {}
    }
    paidInWei = _amountInWei;
  }

  /**
   * @dev See {IERC721DispatcherReservable-isReserved}.
   */
  function isReserved(uint256 _startTime, uint256 _endTime, uint256 _tokenId) public view virtual override returns (bool reserved, uint256 nextIndex) {
    return DispatchLib.isReserved(_endTime, _reservations[_tokenId].startTimes, _reservations[_tokenId].terms);
  }

  /**
   * @dev Inserts new reservation into the _reservations[_tokenId] mapping.
   */
  function _insertReservation(TermBase memory _termBase, uint256 _startTime, uint256 insertHere, uint256 _tokenId, bytes memory _terms) internal returns (bool success){
    uint256 totalReservations = _reservations[_tokenId].reservees.length;
    //add to end if inserting after last reservation
    if(totalReservations == insertHere){
      _reservations[_tokenId].payees.push(_termBase.payee);
      _reservations[_tokenId].reservees.push(_termBase.reservee);
      _reservations[_tokenId].startTimes.push(_startTime);
      _reservations[_tokenId].terms.push(_terms);
      _reservations[_tokenId].feesAccruedInWei.push(_termBase.fee);
      return true;
    }

    //make room for new reservation
    for(uint256 i = insertHere; i < totalReservations+1; i++){
      _reservations[_tokenId].payees[i+1] = _reservations[_tokenId].payees[i];
      _reservations[_tokenId].reservees[i+1] = _reservations[_tokenId].reservees[i];
      _reservations[_tokenId].startTimes[i+1] = _reservations[_tokenId].startTimes[i];
      _reservations[_tokenId].terms[i+1] = _reservations[_tokenId].terms[i];
      _reservations[_tokenId].feesAccruedInWei[i+1] = _reservations[_tokenId].feesAccruedInWei[i];
    }

    //insert new reservation
    _reservations[_tokenId].payees[insertHere] = _termBase.payee;
    _reservations[_tokenId].reservees[insertHere] = _termBase.reservee;
    _reservations[_tokenId].startTimes[insertHere] = _startTime;
    _reservations[_tokenId].terms[insertHere] = _terms;
    _reservations[_tokenId].feesAccruedInWei[insertHere] = _termBase.fee;

    return true;
  }

  /**
   * @dev See {IERC721DispatcherReservable-getReservations}.
   */
  function getReservations(uint256 _tokenId) external view virtual override returns (address[] memory reservees, uint256[] memory startTimes, bytes[] memory terms) {
    uint256 length = _reservations[_tokenId].reservees.length - _reservations[_tokenId].startingIndex;
    reservees = new address[](length);
    startTimes = new uint256[](length);
    terms = new bytes[](length);

    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].reservees.length; i++){
      uint256 j = i - _reservations[_tokenId].startingIndex;
      reservees[j] = _reservations[_tokenId].reservees[i];
      startTimes[j] = _reservations[_tokenId].startTimes[i];
      terms[j] = _reservations[_tokenId].terms[i];
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-reservedFor}.
   */
  function reservedFor(uint256 _time, uint256 _tokenId) public view virtual override returns (address reservee, uint256 startTime, uint256 endTime, uint256 termsIndex) {
    bool reserved;
    (reserved, termsIndex, endTime) = DispatchLib.reservedFor(_time, _reservations[_tokenId].reservees, _reservations[_tokenId].startTimes, _reservations[_tokenId].terms);

    if(reserved){
      reservee = _reservations[_tokenId].reservees[termsIndex];
      startTime = _reservations[_tokenId].startTimes[termsIndex];
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-validateReservation}.
   */
  function validateReservation(address _reservee, uint256 _tokenId, bytes memory _requestedTerms) external view returns (bool valid) {
    (address reservee,,, uint256 termsIndex) = reservedFor(block.timestamp, _tokenId);
    if(reservee != _reservee){
      return false;
    }

    //confirm terms match the reservation terms
    if(DispatchLib.termsApproved(_reservations[_tokenId].terms[termsIndex], _requestedTerms)) {
      return true;
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-purgeExpired}.
   */
  function purgeExpired(uint256 _tokenId) public returns (uint256 reservationsRemaining){
    uint256 startingIndex = _reservations[_tokenId].startingIndex;
    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].reservees.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);
      if(block.timestamp > endTime){//reservation at index i has expired
        startingIndex = i+1;
      }else{
        break;
      }
    }
    _reservations[_tokenId].startingIndex = startingIndex;

    uint256 currentTotal = _reservations[_tokenId].reservees.length - startingIndex;
    return _reservations[_tokenId].maxReservations - currentTotal;
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