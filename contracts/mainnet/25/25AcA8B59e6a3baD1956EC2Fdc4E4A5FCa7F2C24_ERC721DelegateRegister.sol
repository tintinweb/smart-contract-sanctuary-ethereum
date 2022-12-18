// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IERC721DelegationContainer.sol";
import "./IERC721DelegateRegister.sol";

/**
 *
 * @dev The EPS Delegation Register contract. This contract is part of the EPSRegister, and allows the owner
 * of an ERC721 to delegate rights to another address (the delegate address). The owner decides what rights
 * they wish to delegate, how long for, and if they require payment for the delegation. For example, a holder
 * might decide that they wish to delegate physical event rights to another for three months. They want 0.5 ETH
 * for this privelidge. They load the delegation here, with the asset being custodied in a delegation container
 * that the original asset owner owns. Other addresses can accept that delegation proposal by paying the ETH
 * due. This loads the delegation details to the register, and means that query functions like beneficiaryOf and
 * beneficiaryBalanceOf return data that reflect this delegation.
 *
 */

contract ERC721DelegateRegister is
  IERC721DelegateRegister,
  Ownable,
  IERC721Receiver
{
  using Clones for address payable;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  // =======================================
  // CONSTANTS
  // =======================================

  // Total rights, positions 13, 14 and 15 reserved for project specific rights.
  uint256 constant TOTAL_RIGHTS =
    10000100001000010000100001000010000100001000010000100001000010000100001;
  //15   14   13   12   11   10   9    8    7    6    5    4    3    2    1

  // Rights slice length - this is used in run time to slice up rights integers into their component parts.
  uint256 constant RIGHTS_SLICE_LENGTH = 5;

  // Default for any percentages, which must be held as a prortion of 100,000, i.e. a
  // percentage of 5% is held as 5,000.
  uint256 constant PERCENTAGE_DENOMINATOR = 100000;

  address public immutable weth;

  // =======================================
  // STORAGE
  // =======================================

  // Unique ID for every proposed delegation.
  uint64 public delegationId;

  // Unique ID for every collection offer.
  uint64 public offerId;

  // Basic fee charged by the protocol for operations that require payment, namely the acceptance of a delegation
  // or the secondary sale of rights.
  uint96 public delegationRegisterFee;

  // Percentage fee applied to proceeds derived from protocol actions. For example, if this is set to 0.5% (500) and
  // an asset owner has charged 1 ETH for a delegation this will be a charge of 0.005 ETH. Note that this is charged in
  // addition to the base fee. This is important, as the base fee is all the protocol will take for fee free transactions,
  // and some revenue is required to maintain the service.
  uint32 public delegationFeePercentage;

  // Lock for delegation container address
  bool public delegationContainerTemplateLocked;

  // Provide ability to pause new sales (in-ife functionality including asset reclaim cannot be paused)
  bool public marketplacePaused;

  // The address of the delegation container template.
  address payable public delegationContainer;

  // EPS treasury address:
  address public treasury;

  // The string descriptions associated with the default rights codes. Only position 1 to 12 will be used, but full length
  // provided here for future flexiblity
  string[16] public defaultRightsCodes;

  // Map a tokenContract and Id to a delegation record.
  // bytes32 mapping for this is tokenContract and tokenId
  mapping(bytes32 => DelegationRecord) public tokenToDelegationRecord;

  // Map a token contract and query address to a balance struct:
  // bytes32 mapping for this is tokenContract and address being queried
  mapping(bytes32 => uint256) public contractToBalanceByRights;

  // Map a deployed container contract to a delegation record.
  mapping(address => uint64) public containerToDelegationId;

  // Map collection offer ID to offer:
  mapping(uint64 => Offer) public offerIdToOfferDetails;

  // Store offer ERC20 payment options, the returned value if the base fee for that ERC20
  mapping(address => ERC20PaymentOptions) public validERC20PaymentOption;

  // Map addresses to containers. Owners:
  mapping(address => EnumerableSet.AddressSet) internal _containersForOwner;

  // Map addresses to containers. Delegates:
  mapping(address => EnumerableSet.AddressSet) internal _containersForDelegate;

  // Map a token contract to a listing of contract specific rights codes:
  mapping(address => string[16]) public tokenContractToRightsCodes;

  error EthWithdrawFailed();

  /**
   *
   * @dev Constructor
   *
   */
  constructor(
    uint96 delegationRegisterFee_,
    uint32 delegationFeePercentage_,
    address weth_,
    address treasury_
  ) {
    delegationRegisterFee = delegationRegisterFee_;
    delegationFeePercentage = delegationFeePercentage_;
    weth = weth_;
    setTreasuryAddress(treasury_);
  }

  // =======================================
  // GETTERS
  // =======================================

  /**
   *
   * @dev getRightsCodesByTokenContract: Get token contract rights codes (strings)
   * given a certain token contract.
   *
   */
  function getRightsCodesByTokenContract(address tokenContract_)
    public
    view
    returns (string[16] memory rightsCodes_)
  {
    for (uint256 i = 0; i < defaultRightsCodes.length; i++) {
      rightsCodes_[i] = defaultRightsCodes[i];
    }
    // We overlay the project specific codes on the default list. Note that we have
    // provisionally reserved 3 codes for projects, with the first 12 being default codes,
    // but we have left scope for the project utilised codes to expand. We can load project
    // overrides into any index position, clearly avoiding those in use for default codes, but
    // allowing the prospect of, for example, a project having four specific codes in positions
    // 12, 13, 14 and 15.
    for (
      uint256 i = 0;
      i < tokenContractToRightsCodes[tokenContract_].length;
      i++
    ) {
      if (bytes(tokenContractToRightsCodes[tokenContract_][i]).length != 0) {
        rightsCodes_[i] = tokenContractToRightsCodes[tokenContract_][i];
      }
    }
  }

  /**
   *
   * @dev getRightsCodes: Get token contract rights codes (no specific token project).
   *
   */
  function getRightsCodes()
    external
    view
    returns (string[16] memory rightsCodes_)
  {
    return (getRightsCodesByTokenContract(address(0)));
  }

  function containersForOwnerContains(address owner_, address value_)
    public
    view
    returns (bool)
  {
    return _containersForOwner[owner_].contains(value_);
  }

  function containersForDelegateContains(address delegate_, address value_)
    public
    view
    returns (bool)
  {
    return _containersForDelegate[delegate_].contains(value_);
  }

  function containersForOwnerLength(address owner_)
    public
    view
    returns (uint256)
  {
    return _containersForOwner[owner_].length();
  }

  function containersForDelegateLength(address delegate_)
    public
    view
    returns (uint256)
  {
    return _containersForDelegate[delegate_].length();
  }

  function containersForOwnerAt(address owner_, uint256 index_)
    public
    view
    returns (address)
  {
    return _containersForOwner[owner_].at(index_);
  }

  function containersForDelegateAt(address delegate_, uint256 index_)
    public
    view
    returns (address)
  {
    return _containersForDelegate[delegate_].at(index_);
  }

  function containersForOwnerValues(address owner_)
    public
    view
    returns (address[] memory)
  {
    return _containersForOwner[owner_].values();
  }

  function containersFoDelegateValues(address delegate_)
    public
    view
    returns (address[] memory)
  {
    return _containersForDelegate[delegate_].values();
  }

  /**
   *
   * @dev getAllAddressesByRightsIndex: Get all addresses for a queried address
   *
   */
  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) public view returns (address[] memory containers_) {
    // Create a working list that represented the max size that we can possibly
    // return from this function, being a scenario where the receivedAddress has
    // rights as either delegate or owner to all associated containers.

    uint256 ownerSetLength = _containersForOwner[receivedAddress_].length();
    uint256 delegateSetLength = _containersForDelegate[receivedAddress_]
      .length();

    uint256 i;
    uint256 containerCount;
    uint256 addIndexes;

    // Our received address will be returned on the list of valid addresses, so
    // we will need to add +1 to hold this item. See if we will also need to pass
    // back the COLD address
    if (includeReceivedAndCold_) {
      if (coldAddress_ != address(0)) {
        addIndexes = 2;
      } else {
        addIndexes = 1;
      }
    }

    address[] memory workingList = new address[](
      ownerSetLength + delegateSetLength + addIndexes
    );

    if (coldAddress_ != address(0)) {
      // Stage 1: check for any delegations for the COLD address
      for (i = 0; i < ownerSetLength; ) {
        // Check if the owner has the rights to this container:
        address container = _containersForOwner[coldAddress_].at(i);
        address beneficiary = IERC721DelegationContainer(container)
          .getBeneficiaryByRight(rightsIndex_);

        if (beneficiary == coldAddress_) {
          workingList[containerCount] = container;
          unchecked {
            containerCount++;
          }
        }

        unchecked {
          i++;
        }
      }

      for (i = 0; i < delegateSetLength; ) {
        // Check if the delegate has the rights to this container:
        address container = _containersForDelegate[coldAddress_].at(i);
        address beneficiary = IERC721DelegationContainer(container)
          .getBeneficiaryByRight(rightsIndex_);

        if (beneficiary == coldAddress_) {
          workingList[containerCount] = container;
          unchecked {
            containerCount++;
          }
        }

        unchecked {
          i++;
        }
      }
    }

    // Stage 2: check for any delegations for the HOT address that is calling

    for (i = 0; i < ownerSetLength; ) {
      // Check if the owner has the rights to this container:
      address container = _containersForOwner[receivedAddress_].at(i);
      address beneficiary = IERC721DelegationContainer(container)
        .getBeneficiaryByRight(rightsIndex_);

      if (beneficiary == receivedAddress_) {
        workingList[containerCount] = container;
        unchecked {
          containerCount++;
        }
      }

      unchecked {
        i++;
      }
    }

    for (i = 0; i < delegateSetLength; ) {
      // Check if the delegate has the rights to this container:
      address container = _containersForDelegate[receivedAddress_].at(i);
      address beneficiary = IERC721DelegationContainer(container)
        .getBeneficiaryByRight(rightsIndex_);

      if (beneficiary == receivedAddress_) {
        workingList[containerCount] = container;
        unchecked {
          containerCount++;
        }
      }

      unchecked {
        i++;
      }
    }

    address[] memory returnList = new address[](containerCount + addIndexes);

    if (includeReceivedAndCold_) {
      returnList[0] = receivedAddress_;
      if (coldAddress_ != address(0)) {
        returnList[1] = coldAddress_;
      }
    }

    for (i = 0; i < containerCount; ) {
      returnList[i + addIndexes] = workingList[i];
      unchecked {
        i++;
      }
    }

    return (returnList);
  }

  /**
   *
   * @dev getFeeDetails: Get fee details (register fee and fee percentage).
   *
   */
  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_)
  {
    return (delegationRegisterFee, delegationFeePercentage);
  }

  /**
   *
   * @dev getDelegationIdForContainer: Get delegation ID for a given container.
   *
   */
  function getDelegationIdForContainer(address container_)
    external
    view
    returns (uint64 delegationId_)
  {
    return (containerToDelegationId[container_]);
  }

  /**
   *
   * @dev getBalanceByRight: Get balance by rights
   *
   */
  function getBalanceByRight(
    address tokenContract_,
    address queryAddress_,
    uint256 rightsIndex_
  ) public view returns (uint256) {
    // Create the hash for this contract and address combination:

    bytes32 queryHash = _getParticipantHash(tokenContract_, queryAddress_);

    return (
      _sliceRightsInteger(rightsIndex_, contractToBalanceByRights[queryHash])
    );
  }

  /**
   *
   * @dev getBeneficiaryByRight: Get beneficiary by rights
   *
   */
  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) public view returns (address) {
    bytes32 keyHash = _getKeyHash(tokenContract_, tokenId_);

    DelegationRecord memory currentRecord = tokenToDelegationRecord[keyHash];

    // Check for delegation

    if (currentRecord.delegationId != 0) {
      if (
        _sliceRightsInteger(
          rightsIndex_,
          currentRecord.delegateRightsInteger
        ) == 0
      ) {
        // Owner has the rights
        return (currentRecord.owner);
      } else {
        // Delegate has the rights
        return (currentRecord.delegate);
      }
    }

    // Return 0 if there is nothing stored here.
    return (address(0));
  }

  // =======================================
  // SETTERS
  // =======================================

  /**
   * @dev setDefaultRightsCodes: set the string description for the 12 defauls rights codes. Note this is for information only - these strings are
   * not used in the contract for any purpose.
   */
  function setDefaultRightsCodes(
    uint256 rightsIndex_,
    string memory rightsDescription_
  ) public onlyOwner {
    defaultRightsCodes[rightsIndex_] = rightsDescription_;
  }

  /**
   * @dev setProjectSpecificRightsCodes: set the string description for the 3 configurable rights codes that can be set per token contract. These
   * occupy positions 13, 14 and 15 on the rights index. These may be seldom used, but the idea is to give projects three positions in the rights
   * integer where they can determine their own authorities.
   */
  function setProjectSpecificRightsCodes(
    address tokenContract_,
    uint256 rightsIndex_,
    string memory rightsDescription_
  ) public onlyOwner {
    tokenContractToRightsCodes[tokenContract_][
      rightsIndex_
    ] = rightsDescription_;
  }

  /**
   * @dev addOfferPaymentERC20: add an offer ERC20 payment option
   */
  function addOfferPaymentERC20(address contractForERC20_, uint96 baseFee_)
    public
    onlyOwner
  {
    validERC20PaymentOption[contractForERC20_].isValid = true;
    validERC20PaymentOption[contractForERC20_].registerFee = baseFee_;
  }

  /**
   * @dev removeOfferPaymentERC20: remove an offer ERC20 payment option
   */
  function removeOfferPaymentERC20(address contractForERC20_) public onlyOwner {
    delete validERC20PaymentOption[contractForERC20_];
  }

  /**
   * @dev setDelegationRegisterFee: set the base fee for transactions.
   */
  function setDelegationRegisterFee(uint96 delegationRegisterFee_)
    public
    onlyOwner
  {
    delegationRegisterFee = delegationRegisterFee_;
  }

  /**
   * @dev setDelegationFeePercentage: set the percentage fee taken from transactions that involve payment.
   */
  function setDelegationFeePercentage(uint32 delegationFeePercentage_)
    public
    onlyOwner
  {
    delegationFeePercentage = delegationFeePercentage_;
  }

  /**
   * @dev lockDelegationContainerTemplate: allow the delegation container template to be locked at a given address.
   */
  function lockDelegationContainerTemplate() public onlyOwner {
    delegationContainerTemplateLocked = true;
  }

  /**
   *
   * @dev setDelegationContainer: set the container address. Can only be called once. Not set in the constructor
   * as the container needs to know the address of the register (which IS set in the constructor)
   * so we have a chicken and egg situation to resolve. Only allow to be set ONCE.
   *
   */
  function setDelegationContainer(address payable delegationContainer_)
    public
    onlyOwner
  {
    if (delegationContainerTemplateLocked) revert TemplateContainerLocked();
    delegationContainer = delegationContainer_;
  }

  /**
   * @dev toggleMarketplace: allow the marketplace to be paused / unpaused
   */
  function pauseMarketplace(bool marketPlacePaused) public onlyOwner {
    marketplacePaused = marketPlacePaused;
  }

  // =======================================
  // VALIDATION
  // =======================================

  /**
   * @dev Throws if this is not a valid container, returnds delegation Id if it's valid.
   */
  function isValidContainer(address container_)
    public
    view
    returns (uint64 recordId_)
  {
    recordId_ = containerToDelegationId[container_];

    if (recordId_ == 0) revert InvalidContainer();

    return (recordId_);
  }

  /**
   * @dev Throws if marketplace is not open
   */
  function _isMarketOpen() internal view {
    if (marketplacePaused) revert MarketPlacePaused();
  }

  // =======================================
  // RIGHTS 'BOOKKEEPING'
  // =======================================

  /**
   *
   * @dev _increaseRightsInteger: increase the passed rights integer with the passed integer
   *
   */
  function _increaseRightsInteger(
    address containerAddress_,
    address participantAddress_,
    address tokenContract_,
    uint256 tokenId_,
    bytes32 participantHash_,
    uint256 rightsInteger_
  ) internal {
    contractToBalanceByRights[participantHash_] += rightsInteger_;

    // An increase of rights is implicitly a transfer from the container that holds the asset:
    emit TransferRights(
      containerAddress_,
      participantAddress_,
      tokenContract_,
      tokenId_,
      rightsInteger_
    );
  }

  /**
   *
   * @dev _decreaseRightsInteger: decrease the passed rights integer with the passed integer
   *
   */
  function _decreaseRightsInteger(
    address containerAddress_,
    address participantAddress_,
    address tokenContract_,
    uint256 tokenId_,
    bytes32 participantHash_,
    uint256 rightsInteger_
  ) internal {
    contractToBalanceByRights[participantHash_] -= rightsInteger_;

    // An decrease of rights is implicitly a transfer to the container that holds the asset:
    emit TransferRights(
      participantAddress_,
      containerAddress_,
      tokenContract_,
      tokenId_,
      rightsInteger_
    );
  }

  /**
   *
   * @dev _adjustBalancesAtEndOfDelegation: reduce balances when a delegation has ended
   *
   */
  function _adjustBalancesAtEndOfDelegation(
    address tokenContract_,
    address container_,
    address owner_,
    address delegate_,
    uint256 tokenId_,
    uint64 delegationId_
  ) internal returns (bytes32 keyHash_, bytes32 ownerHash_) {
    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getAllHashes(
      tokenContract_,
      tokenId_,
      owner_,
      delegate_
    );

    _decreaseRightsInteger(
      container_,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      (TOTAL_RIGHTS - tokenToDelegationRecord[keyHash].delegateRightsInteger)
    );

    _decreaseRightsInteger(
      container_,
      delegate_,
      tokenContract_,
      tokenId_,
      delegateHash,
      tokenToDelegationRecord[keyHash].delegateRightsInteger
    );

    // Emit event to show that this delegation is now
    _emitComplete(delegationId_);

    return (keyHash, ownerHash);
  }

  // =======================================
  // DELEGATION RECORDS MANAGEMENT
  // =======================================

  /**
   *
   * @dev _assignDelegationId: Create new delegation Id and assign it.
   *
   */
  function _assignDelegationId(address container_) internal {
    delegationId += 1;

    containerToDelegationId[container_] = delegationId;
  }

  /**
   *
   * @dev _resetDelegationRecordDetails: reset to default on relist
   *
   */
  function _resetDelegationRecordDetails(bytes32 keyHash_) internal {
    _updateDelegationRecordDetails(keyHash_, 0, address(0), 0);
  }

  /**
   *
   * @dev _updateDelegationRecordDetails: common processing for delegation record updates
   *
   */
  function _updateDelegationRecordDetails(
    bytes32 keyHash_,
    uint64 endTime_,
    address delegate_,
    uint256 delegateRightsInteger_
  ) internal {
    tokenToDelegationRecord[keyHash_].endTime = endTime_;
    tokenToDelegationRecord[keyHash_].delegate = delegate_;
    tokenToDelegationRecord[keyHash_]
      .delegateRightsInteger = delegateRightsInteger_;
  }

  /**
   *
   * @dev _getAllHashes: get the hashes for tracking owner and delegate
   *
   */
  function _getAllHashes(
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  )
    internal
    pure
    returns (
      bytes32 keyHash_,
      bytes32 ownerHash_,
      bytes32 delegateHash_
    )
  {
    (keyHash_, ownerHash_) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      owner_
    );

    delegateHash_ = keccak256(abi.encodePacked(tokenContract_, delegate_));

    return (keyHash_, ownerHash_, delegateHash_);
  }

  /**
   *
   * @dev _getKeyAndParticipantHashes: get key and one participant hashes
   *
   */
  function _getKeyAndParticipantHashes(
    address tokenContract_,
    uint256 tokenId_,
    address participant_
  ) internal pure returns (bytes32 keyHash_, bytes32 participantHash_) {
    keyHash_ = _getKeyHash(tokenContract_, tokenId_);

    participantHash_ = _getParticipantHash(tokenContract_, participant_);

    return (keyHash_, participantHash_);
  }

  /**
   *
   * @dev _getParticipantHash: get one participant hash
   *
   */
  function _getParticipantHash(address tokenContract_, address participant_)
    internal
    pure
    returns (bytes32 participantHash_)
  {
    participantHash_ = keccak256(
      abi.encodePacked(tokenContract_, participant_)
    );

    return (participantHash_);
  }

  /**
   *
   * @dev _getKeyHash: get key hash
   *
   */
  function _getKeyHash(address tokenContract_, uint256 tokenId_)
    internal
    pure
    returns (bytes32 keyHash_)
  {
    keyHash_ = keccak256(abi.encodePacked(tokenContract_, tokenId_));

    return (keyHash_);
  }

  /**
   *
   * @dev _sliceRightsInteger: extract a position from the rights integer
   *
   */
  function _sliceRightsInteger(uint256 position_, uint256 rightsInteger_)
    internal
    pure
    returns (uint256 value)
  {
    uint256 exponent = (10**(position_ * RIGHTS_SLICE_LENGTH));
    uint256 divisor;
    if (position_ == 1) {
      divisor = 1;
    } else {
      divisor = (10**((position_ - 1) * RIGHTS_SLICE_LENGTH));
    }

    return ((rightsInteger_ % exponent) / divisor);
  }

  /**
   *
   * @dev sundryEvent: generic function for delegation register emits
   *
   */
  function sundryEvent(
    uint64 provider_,
    address address1_,
    address address2_,
    uint256 int1_,
    uint256 int2_,
    uint256 int3_,
    uint256 int4_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit a sundry event so we know about it:
    emit SundryEvent(
      provider_,
      recordId,
      address1_,
      address2_,
      int1_,
      int2_,
      int3_,
      int4_
    );
  }

  // =======================================
  // DELEGATION CREATION
  // =======================================

  /**
   *
   * @dev _createDelegationFromOffer: call when an offer is being accepted
   *_createDelegation
   */
  function _createDelegationFromOffer(
    DelegationParameters memory delegationData_,
    uint256 tokenId_,
    address owner_,
    bytes32 keyHash_,
    bytes32 ownerHash_,
    address tokenContract_,
    address container_
  ) internal {
    _offerAccepted(delegationData_, tokenId_, owner_, tokenContract_);

    _createDelegation(
      owner_,
      uint64(block.timestamp) + (uint64(delegationData_.duration) * 1 days),
      delegationData_.delegate,
      delegationData_.delegateRightsInteger,
      keyHash_
    );

    _increaseRightsInteger(
      container_,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash_,
      (TOTAL_RIGHTS - delegationData_.delegateRightsInteger)
    );

    _increaseRightsInteger(
      container_,
      delegationData_.delegate,
      tokenContract_,
      tokenId_,
      _getParticipantHash(tokenContract_, delegationData_.delegate),
      delegationData_.delegateRightsInteger
    );

    _emitDelegationAccepted(
      delegationData_,
      container_,
      tokenContract_,
      tokenId_,
      owner_
    );
  }

  /**
   *
   * @dev _emitDelegationAccepted
   *
   */
  function _emitDelegationAccepted(
    DelegationParameters memory delegationData_,
    address container_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_
  ) internal {
    emit DelegationAccepted(
      delegationData_.provider,
      delegationId,
      container_,
      tokenContract_,
      tokenId_,
      owner_,
      delegationData_.delegate,
      uint64(block.timestamp) + (uint64(delegationData_.duration) * 1 days),
      delegationData_.delegateRightsInteger,
      0,
      delegationData_.URI
    );
  }

  /**
   *
   * @dev _createDelegation: create the delegation record
   *
   */
  function _createDelegation(
    address owner_,
    uint64 endTime_,
    address delegate_,
    uint256 delegateRightsInteger_,
    bytes32 keyHash_
  ) internal {
    tokenToDelegationRecord[keyHash_] = DelegationRecord(
      delegationId,
      owner_,
      endTime_,
      delegate_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev _offerAccepted: call when an offer is being accepted
   *
   */
  function _offerAccepted(
    DelegationParameters memory delegationData_,
    uint256 tokenId_,
    address owner_,
    address collection_
  ) internal {
    // 1) Check this is a valid match.
    Offer memory offerData = offerIdToOfferDetails[delegationData_.offerId];

    if (
      (offerData.collection != collection_) ||
      (!offerData.collectionOffer && offerData.tokenId != tokenId_) ||
      (delegationData_.delegate != offerData.offerMaker) ||
      (delegationData_.duration != offerData.delegationDuration) ||
      (delegationData_.fee != offerData.offerAmount) ||
      (delegationData_.delegateRightsInteger !=
        offerData.delegateRightsInteger) ||
      (block.timestamp > offerData.expiry)
    ) {
      revert InvalidOffer();
    }

    // 2) Perform payment processing:

    // If the payment ERC20 is address(0) this means the default, which is weth
    // (doing this saves a slot on the offer struct)
    address paymentERC20Address;
    uint256 registerFee;
    if (offerData.paymentERC20 == address(0)) {
      paymentERC20Address = weth;
      registerFee = delegationRegisterFee;
    } else {
      paymentERC20Address = offerData.paymentERC20;

      if (!validERC20PaymentOption[paymentERC20Address].isValid)
        revert InvalidERC20();

      registerFee = validERC20PaymentOption[paymentERC20Address].registerFee;
    }

    // Cancel the offer as it is being actioned
    delete offerIdToOfferDetails[delegationData_.offerId];

    uint256 claimAmount = (delegationData_.fee + registerFee);

    // Claim payment from the offerer:
    if (claimAmount > 0) {
      IERC20(paymentERC20Address).transferFrom(
        delegationData_.delegate,
        address(this),
        claimAmount
      );
    }

    uint256 epsFee;

    // The fee taken by the protocol is a percentage of the delegation fee + the register fee. This ensures
    // that even for free delegations the platform takes a small fee to remain sustainable.

    if (delegationData_.fee == 0) {
      epsFee = registerFee;
    } else {
      epsFee =
        ((delegationData_.fee * delegationFeePercentage) /
          PERCENTAGE_DENOMINATOR) +
        registerFee;
    }

    // Handle delegation Fee remittance
    if (delegationData_.fee != 0) {
      IERC20(paymentERC20Address).transfer(owner_, (claimAmount - epsFee));
    }

    emit OfferAccepted(
      delegationData_.provider,
      delegationData_.offerId,
      epsFee,
      paymentERC20Address
    );
  }

  /**
   *
   * @dev _decodeParameters
   *
   */
  function _decodeParameters(bytes memory data_)
    internal
    pure
    returns (DelegationParameters memory)
  {
    // Decode the delegation parameters from the data_ passed in:
    (
      uint64 paramProvider,
      address paramDelegate,
      uint24 paramDuration,
      uint96 paramFee,
      uint256 paramOwnerRights,
      uint256 paramDelegateRights,
      string memory paramURI,
      uint64 paramPfferId
    ) = abi.decode(
        data_,
        (uint64, address, uint24, uint96, uint256, uint256, string, uint64)
      );

    return (
      DelegationParameters(
        paramProvider,
        paramDelegate,
        paramDuration,
        paramFee,
        paramOwnerRights,
        paramDelegateRights,
        paramURI,
        paramPfferId
      )
    );
  }

  /**
   *
   * @dev onERC721Received - tokens are containerised for delegation by being sent to this
   * contract with the correct bytes data. NOTE - DO NOT JUST SEND ERC721s TO THIS
   * CONTRACT. This MUST be called from an interface that correctly encodes the
   * bytes parameter data for decode.
   *
   */

  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory data_
  ) external override returns (bytes4) {
    if (from_ == address(0)) revert DoNoMintToThisAddress();

    address tokenContract = msg.sender;

    // Decode the delegation parameters from the data_ passed in:
    DelegationParameters memory delegationData = _decodeParameters(data_);

    _containerise(
      from_,
      tokenId_,
      tokenContract,
      address(this),
      delegationData
    );

    return this.onERC721Received.selector;
  }

  function containeriseForDelegation(
    address tokenContract_,
    uint256 tokenId_,
    DelegationParameters memory delegationData_
  ) external override {
    _containerise(
      msg.sender,
      tokenId_,
      tokenContract_,
      msg.sender,
      delegationData_
    );
  }

  /**
   *
   * @dev _containerise
   *
   */

  function _containerise(
    address from_,
    uint256 tokenId_,
    address tokenContract_,
    address currentTokenHolder_,
    DelegationParameters memory delegationData_
  ) internal {
    // Check that we have been passed valid rights details for the owner and the beneficiary.
    if (
      delegationData_.ownerRightsInteger +
        delegationData_.delegateRightsInteger !=
      TOTAL_RIGHTS
    ) revert InvalidRights();

    // Cannot assign the current owner as the delegate:
    if (delegationData_.delegate == from_) revert OwnerCannotBeDelegate();

    // Create the container contract:
    address newDelegationContainer = delegationContainer.clone();

    // Assign the container a delegation Id
    _assignDelegationId(newDelegationContainer);

    if (delegationData_.offerId == 0) {
      emit DelegationCreated(
        delegationData_.provider,
        delegationId,
        newDelegationContainer,
        from_,
        delegationData_.delegate,
        delegationData_.fee,
        delegationData_.duration,
        tokenContract_,
        tokenId_,
        delegationData_.delegateRightsInteger,
        delegationData_.URI
      );
    }

    (bytes32 keyHash, bytes32 ownerHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      from_
    );

    // If this was accepting an offer we save a full delegation record now:
    if (delegationData_.offerId != 0) {
      _isMarketOpen();

      _createDelegationFromOffer(
        delegationData_,
        tokenId_,
        from_,
        keyHash,
        ownerHash,
        tokenContract_,
        newDelegationContainer
      );
    } else {
      _createDelegation(from_, 0, address(0), 0, keyHash);

      _increaseRightsInteger(
        newDelegationContainer,
        from_,
        tokenContract_,
        tokenId_,
        ownerHash,
        TOTAL_RIGHTS
      );
    }

    // Initialise storage data:
    IERC721DelegationContainer(newDelegationContainer)
      .initialiseDelegationContainer(
        payable(from_),
        payable(delegationData_.delegate),
        delegationData_.fee,
        delegationData_.duration,
        tokenContract_,
        tokenId_,
        delegationData_.delegateRightsInteger,
        delegationData_.URI,
        delegationData_.offerId
      );

    // Deliver the ERC721 to the container:
    IERC721(tokenContract_).safeTransferFrom(
      currentTokenHolder_,
      newDelegationContainer,
      tokenId_
    );

    // Add map for owner and delegate IF this is non-0 (i.e. was accepting an offer):
    _containersForOwner[from_].add(newDelegationContainer);
    if (delegationData_.delegate != address(0)) {
      _containersForDelegate[delegationData_.delegate].add(
        newDelegationContainer
      );
    }
  }

  /**
   *
   * @dev saveDelegationRecord: Save the complete delegation to the register.
   *
   */
  function saveDelegationRecord(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint64 endTime_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external payable {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getAllHashes(
      tokenContract_,
      tokenId_,
      owner_,
      delegate_
    );

    _updateDelegationRecordDetails(
      keyHash,
      endTime_,
      delegate_,
      delegateRightsInteger_
    );

    // We can just subtract the delegate rights integer as we added in a
    // TOTAL_RIGHTS for the owner while the delegation was pending:
    _decreaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      delegateRightsInteger_
    );

    _increaseRightsInteger(
      msg.sender,
      delegate_,
      tokenContract_,
      tokenId_,
      delegateHash,
      delegateRightsInteger_
    );

    // Record the mapping for the delegate to the container:
    _containersForDelegate[delegate_].add(msg.sender);

    emit DelegationAccepted(
      provider_,
      recordId,
      msg.sender,
      tokenContract_,
      tokenId_,
      owner_,
      delegate_,
      endTime_,
      delegateRightsInteger_,
      msg.value,
      containerURI_
    );
  }

  /**
   *
   * @dev acceptOfferPriorToCommencement: Accept an offer from a container that is pre-commencement
   *
   */
  function acceptOfferPriorToCommencement(
    uint64 provider_,
    address owner_,
    address delegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      owner_
    );

    // Remove the temporary full rights for the owner:
    _decreaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      TOTAL_RIGHTS
    );

    // Emit event to show that the previous listing is removed:
    _emitComplete(recordId);

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _createDelegationFromOffer(
      DelegationParameters(
        provider_,
        delegate_,
        duration_,
        fee_,
        TOTAL_RIGHTS - delegateRightsInteger_,
        delegateRightsInteger_,
        "",
        offerId_
      ),
      tokenId_,
      owner_,
      keyHash,
      ownerHash,
      tokenContract_,
      msg.sender
    );

    // Owner mapping to the delegation container was created when the ERC721 was received. Now we record the delegate:
    _containersForDelegate[delegate_].add(msg.sender);
  }

  // =======================================
  // SECONDARY MARKET / TRANSFERS
  // =======================================

  /**
   *
   * @dev containerListedForSale: record that a delegation container has been listed for sale.
   *
   */
  function containerListedForSale(uint64 provider_, uint96 salePrice_)
    external
  {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit ContainerListedForSale(provider_, recordId, msg.sender, salePrice_);
  }

  /**
   *
   * @dev containerDetailsUpdated: record that an asset owner has updated container details.
   *
   */
  function containerDetailsUpdated(
    uint64 provider_,
    address delegate_,
    uint256 fee_,
    uint256 duration_,
    uint256 delegateRightsInteger_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit ContainerDetailsUpdated(
      provider_,
      recordId,
      msg.sender,
      delegate_,
      fee_,
      duration_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev changeAssetOwner: Change the owner of the container on sale.
   *
   */
  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 newOwnerHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      newOwner_
    );

    // Save the old owner:
    address oldOwner = tokenToDelegationRecord[keyHash].owner;

    // Get hash for old owner:
    bytes32 oldOwnerHash = _getParticipantHash(tokenContract_, oldOwner);

    // This has been called from a container, and that method is assetOwner only. Procced to
    // update the register accordingly.

    // Update owner:
    tokenToDelegationRecord[keyHash].owner = newOwner_;

    // Reduce the contract to balance rights of the old owner by the owner rights integer
    // for this delegation record, and likewise increase it for the new owner:

    uint256 rightsInteger = TOTAL_RIGHTS -
      tokenToDelegationRecord[keyHash].delegateRightsInteger;

    _decreaseRightsInteger(
      msg.sender,
      oldOwner,
      tokenContract_,
      tokenId_,
      oldOwnerHash,
      rightsInteger
    );

    _increaseRightsInteger(
      msg.sender,
      newOwner_,
      tokenContract_,
      tokenId_,
      newOwnerHash,
      rightsInteger
    );

    // Remove mapping from old owner and apply to new owner:
    _containersForOwner[oldOwner].remove(msg.sender);
    _containersForOwner[newOwner_].add(msg.sender);

    emit DelegationOwnerChanged(provider_, recordId, newOwner_, epsFee_);
  }

  /**
   *
   * @dev List the delegation for sale.
   *
   */
  function delegationListedForSale(uint64 provider_, uint96 salePrice_)
    external
  {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    // Emit an event so we know about it:
    emit DelegationListedForSale(provider_, recordId, salePrice_);
  }

  /**
   *
   * @dev changeDelegate: Change the delegate on a delegation.
   *
   */
  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 newDelegateHash) = _getKeyAndParticipantHashes(
      tokenContract_,
      tokenId_,
      newDelegate_
    );

    // Save the old delegate:
    address oldDelegate = tokenToDelegationRecord[keyHash].delegate;

    // Get hashes for new and old delegate:
    bytes32 oldDelegateHash = _getParticipantHash(tokenContract_, oldDelegate);

    // This has been called from a container, and that method is delegate only. Procced to
    // update the register accordingly:

    // Update delegate:
    tokenToDelegationRecord[keyHash].delegate = newDelegate_;

    // Reduce the contract to balance rights of the old delegate by the delegate rights integer
    // for this delegation record, and likewise increase it for the new delegate:

    uint256 rightsInteger = tokenToDelegationRecord[keyHash]
      .delegateRightsInteger;

    _decreaseRightsInteger(
      msg.sender,
      oldDelegate,
      tokenContract_,
      tokenId_,
      oldDelegateHash,
      rightsInteger
    );

    _increaseRightsInteger(
      msg.sender,
      newDelegate_,
      tokenContract_,
      tokenId_,
      newDelegateHash,
      rightsInteger
    );

    // Remove the mapping for the old delegate and apply to the new delegate:
    _containersForDelegate[oldDelegate].remove(msg.sender);
    _containersForDelegate[newDelegate_].add(msg.sender);

    emit DelegationDelegateChanged(provider_, recordId, newDelegate_, epsFee_);
  }

  // =======================================
  // END OF DELEGATION
  // =======================================

  /**
   *
   * @dev acceptOfferAfterDelegationCompleted: Perform acceptance processing where the user is
   * ending a delegation and accepting an offer.
   *
   */
  function acceptOfferAfterDelegationCompleted(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external payable {
    _isMarketOpen();

    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_,
      recordId
    );

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _createDelegationFromOffer(
      DelegationParameters(
        provider_,
        newDelegate_,
        duration_,
        fee_,
        TOTAL_RIGHTS - delegateRightsInteger_,
        delegateRightsInteger_,
        "",
        offerId_
      ),
      tokenId_,
      owner_,
      keyHash,
      ownerHash,
      tokenContract_,
      msg.sender
    );

    // Owner mapping to the delegation container was created when the ERC721 was received. Now we record the delegate:
    _containersForDelegate[newDelegate_].add(msg.sender);

    // And remove the old elegate:
    _containersForDelegate[oldDelegate_].remove(msg.sender);
  }

  /**
   *
   * @dev deleteEntry: remove a completed entry from the register.
   *
   */
  function deleteEntry(
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, ) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      delegate_,
      tokenId_,
      recordId
    );

    // Delete the register entry and owner and delegate data:
    delete tokenToDelegationRecord[keyHash];
    delete containerToDelegationId[msg.sender];

    // Remove the mappings for both owner and delegate:
    _containersForOwner[owner_].remove(msg.sender);
    _containersForDelegate[delegate_].remove(msg.sender);
  }

  /**
   *
   * @dev relistEntry: relist an entry for a new delegation
   *
   */
  function relistEntry(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_,
      recordId
    );

    // Move the container to a new delegation Id:
    _assignDelegationId(msg.sender);

    _resetDelegationRecordDetails(keyHash);

    _increaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      TOTAL_RIGHTS
    );

    // Remove the mapping for the old delegate:
    _containersForDelegate[oldDelegate_].remove(msg.sender);

    emit DelegationCreated(
      provider_,
      delegationId,
      msg.sender,
      owner_,
      newDelegate_,
      fee_,
      durationInDays_,
      tokenContract_,
      tokenId_,
      delegateRightsInteger_,
      containerURI_
    );
  }

  /**
   *
   * @dev _emitComplete: signal that this delegation is complete
   *
   */
  function _emitComplete(uint64 delegationId_) internal {
    emit DelegationComplete(delegationId_);
  }

  // =======================================
  // OFFERS
  // =======================================

  /**
   *
   * @dev makeOffer: make an offer.
   *
   */
  function makeOffer(
    uint64 provider_,
    uint24 duration_,
    uint32 expiry_,
    bool collectionOffer_,
    address collection_,
    uint96 offerAmount_,
    address offerERC20_,
    uint256 tokenId_,
    uint256 delegateRightsRequested_
  ) external {
    // Check that the payment ERC20 is valid

    if (
      offerERC20_ != address(0) && !validERC20PaymentOption[offerERC20_].isValid
    ) revert InvalidERC20();

    // Increment offer id
    offerId += 1;

    offerIdToOfferDetails[offerId] = Offer(
      msg.sender,
      duration_,
      expiry_,
      collectionOffer_,
      collection_,
      offerAmount_,
      tokenId_,
      delegateRightsRequested_,
      offerERC20_
    );

    emit OfferMade(
      provider_,
      offerId,
      collection_,
      collectionOffer_,
      tokenId_,
      duration_,
      expiry_,
      offerAmount_,
      delegateRightsRequested_,
      msg.sender
    );
  }

  /**
   *
   * @dev cancelOffer: cancel an offer.
   *
   */
  function cancelOffer(uint64 provider_, uint64 offerId_) external {
    if (msg.sender != offerIdToOfferDetails[offerId_].offerMaker)
      revert CallerIsNotOfferMaker();
    delete offerIdToOfferDetails[offerId_];
    emit OfferDeleted(provider_, offerId_);
  }

  /**
   *
   * @dev changeOffer: change an offer.
   *
   */
  function changeOffer(
    uint64 provider_,
    uint64 offerId_,
    uint24 newDuration_,
    uint32 newExpiry_,
    uint96 newAmount_,
    uint256 newRightsInteger_
  ) external {
    if (msg.sender != offerIdToOfferDetails[offerId_].offerMaker)
      revert CallerIsNotOfferMaker();

    if (newDuration_ != 0)
      offerIdToOfferDetails[offerId_].delegationDuration = newDuration_;
    if (newExpiry_ != 0) offerIdToOfferDetails[offerId_].expiry = newExpiry_;
    if (newAmount_ != 0)
      offerIdToOfferDetails[offerId_].offerAmount = newAmount_;
    if (newRightsInteger_ != 0)
      offerIdToOfferDetails[offerId_].delegateRightsInteger = newRightsInteger_;

    emit OfferChanged(
      provider_,
      offerId_,
      newDuration_,
      newExpiry_,
      newAmount_,
      newRightsInteger_
    );
  }

  /**
   * @dev setTreasuryAddress: set the treasury address:
   */
  function setTreasuryAddress(address treasuryAddress_) public onlyOwner {
    treasury = treasuryAddress_;
  }

  /**
   * @dev withdrawETH: withdraw eth to the treasury:
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = treasury.call{value: amount_}("");

    if (!success) revert EthWithdrawFailed();
  }

  /**
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of any assets sent here in error
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(owner(), amount_);
  }

  /**
   * @dev withdrawERC721: Allow any ERC721s to be withdrawn. Note, all delegated ERC721s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function withdrawERC721(IERC721 token_, uint256 tokenId_) external onlyOwner {
    token_.transferFrom(address(this), owner(), tokenId_);
  }

  receive() external payable {
    if (containerToDelegationId[msg.sender] == 0 && msg.sender != owner())
      revert();
  }
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS Delegation register interface.
 *
 */
interface IERC721DelegateRegister {
  // ======================================================
  // EVENTS
  // ======================================================

  struct DelegationRecord {
    // The unique identifier for every delegation. Note that this is stamped on each delegation container. This doesn't mean
    // that every delegation Id will make it to the register, as this might be a proposed delegation that is not taken
    // up by anyone.
    uint64 delegationId; // 64
    // The owner of the asset that is being containerised for delegation.
    address owner; // 160
    // The end time for this delegation. After the end time the owner can remove the asset.
    uint64 endTime; // 64
    // The address of the delegate for this delegation
    address delegate; // 160
    // Delegate rights integer:
    uint256 delegateRightsInteger;
  }

  struct DelegationParameters {
    // The provider who has originated this delegation.
    uint64 provider; // 64
    // The address proposed as deletage. The owner of an asset can specify a particular address OR they can leave
    // this as address 0 if they will accept any delegate, subject to payment of the fee (if any)
    address delegate; // 160
    // The duration of the delegation.
    uint24 duration; // 24
    // The fee that the delegate must pay for this delegation to go live.
    uint96 fee; // 96
    // Owner rights integer:
    uint256 ownerRightsInteger;
    // Delegate rights integer:
    uint256 delegateRightsInteger;
    // URI
    string URI;
    // Offer ID, passed if this is accepting an offer, otherwise will be 0:
    uint64 offerId;
  }

  struct Offer {
    // Slot 1 160 + 24 + 32 + 8 = 224
    // The address that is making the offer
    address offerMaker; // 160
    // The delegation duration time in days for this offer.
    uint24 delegationDuration; //24
    // When this offer expires
    uint32 expiry; // 32
    // Boolean to note a collection offer
    bool collectionOffer; // 8
    // Slot 2 160 + 96 = 256
    // The collection the offer is for
    address collection;
    // Offer amount (in provided ERC)
    uint96 offerAmount;
    // Slot 3 = 256
    // TokenId, (is ignored for collection offers)
    uint256 tokenId;
    // Slot 4 = 256
    // Delegate rights integer that they are requesting:
    uint256 delegateRightsInteger;
    // ERC20 that they are paying in:
    address paymentERC20;
  }

  // Configurable payment options for offers:
  struct ERC20PaymentOptions {
    bool isValid;
    uint96 registerFee;
  }

  // Emitted when a delegation container is created:
  event DelegationCreated(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed containerAddress,
    address owner,
    address delegate,
    uint96 fee,
    uint24 durationInDays,
    address tokenContract,
    uint256 tokenId,
    uint256 delegateRightsInteger,
    string URI
  );

  // Emitted when the delegation is accepted:
  event DelegationAccepted(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address container,
    address tokenContract,
    uint256 tokenId,
    address owner,
    address delegate,
    uint64 endTime,
    uint256 delegateRightsInteger,
    uint256 epsFee,
    string URI
  );

  // Emitted when a delegation is complete:
  event DelegationComplete(uint64 indexed delegationId);

  // Emitted when the delegation owner changes:
  event DelegationOwnerChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newOwner,
    uint256 epsFee
  );

  // Emitted when the delegation delegate changes:
  event DelegationDelegateChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newDelegate,
    uint256 epsFee
  );

  event ContainerListedForSale(
    uint64 provider,
    uint64 delegationId,
    address container,
    uint96 salePrice
  );

  event DelegationListedForSale(
    uint64 provider,
    uint64 delegationId,
    uint96 salePrice
  );

  event OfferMade(
    uint64 provider,
    uint64 offerId,
    address collection,
    bool collectionOffer,
    uint256 tokenId,
    uint24 duration,
    uint32 expiry,
    uint96 offerAmount,
    uint256 delegateRightsRequested,
    address offerer
  );

  event OfferAccepted(
    uint64 provider,
    uint64 offerId,
    uint256 epsFee,
    address epsFeeToken
  );

  event OfferDeleted(uint64 provider, uint64 offerId);

  event OfferChanged(
    uint64 provider,
    uint64 offerId,
    uint24 duration,
    uint32 offerExpiry,
    uint96 offerAmount,
    uint256 delegateRightsInteger
  );

  event TransferRights(
    address indexed from,
    address indexed to,
    address indexed tokenContract,
    uint256 tokenId,
    uint256 rightsInteger
  );

  event ContainerDetailsUpdated(
    uint64 provider,
    uint64 delegationId,
    address container,
    address delegate,
    uint256 fee,
    uint256 duration,
    uint256 delegateRightsInteger
  );

  event SundryEvent(
    uint64 provider,
    uint64 delegationId,
    address address1,
    address address2,
    uint256 integer1,
    uint256 integer2,
    uint256 integer3,
    uint256 integer4
  );

  // ======================================================
  // ERRORS
  // ======================================================

  error TemplateContainerLocked();
  error InvalidContainer();
  error InvalidERC20();
  error DoNoMintToThisAddress();
  error InvalidRights();
  error OwnerCannotBeDelegate();
  error CallerIsNotOfferMaker();
  error InvalidOffer();
  error MarketPlacePaused();

  // ======================================================
  // FUNCTIONS
  // ======================================================

  function getRightsCodesByTokenContract(address tokenContract_)
    external
    view
    returns (string[16] memory rightsCodes_);

  function getRightsCodes()
    external
    view
    returns (string[16] memory rightsCodes_);

  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_);

  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) external view returns (address[] memory containers_);

  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address);

  function getBalanceByRight(
    address tokenContract_,
    address queryAddress_,
    uint256 rightsIndex_
  ) external view returns (uint256);

  function containeriseForDelegation(
    address tokenContract_,
    uint256 tokenId_,
    DelegationParameters memory delegationData_
  ) external;

  function saveDelegationRecord(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint64 endTime_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external payable;

  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee
  ) external;

  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 epsFee_
  ) external;

  function deleteEntry(
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_
  ) external;

  function containerListedForSale(uint64 provider_, uint96 salePrice_) external;

  function delegationListedForSale(uint64 provider_, uint96 salePrice_)
    external;

  function containerToDelegationId(address container_)
    external
    view
    returns (uint64 delegationId_);

  function delegationRegisterFee() external view returns (uint96);

  function delegationFeePercentage() external view returns (uint32);

  function relistEntry(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_,
    string memory containerURI_
  ) external;

  function acceptOfferAfterDelegationCompleted(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address newDelegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external payable;

  function containerDetailsUpdated(
    uint64 provider_,
    address delegate_,
    uint256 fee_,
    uint256 duration_,
    uint256 delegateRightsInteger_
  ) external;

  function acceptOfferPriorToCommencement(
    uint64 provider_,
    address owner_,
    address delegate_,
    uint24 duration_,
    uint96 fee_,
    uint256 delegateRightsInteger_,
    uint64 offerId_,
    address tokenContract_,
    uint256 tokenId_
  ) external;

  function sundryEvent(
    uint64 provider_,
    address address1_,
    address address2_,
    uint256 int1_,
    uint256 int2_,
    uint256 int3_,
    uint256 int4_
  ) external;
}

// SPDX-License-Identifier: MIT
// EPSP Contracts v2.0.0

pragma solidity 0.8.17;

/**
 *
 * @dev The EPS Delegation container contract interface. Lightweight interface with just the functions required
 * by the register contract.
 *
 */
interface IERC721DelegationContainer {
  event OwnershipTransferred(
    uint64 provider,
    address indexed previousOwner,
    address indexed newOwner
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event EPSRegisterCallError(bytes reason);

  /**
   * @dev initialiseDelegationContainer - function to call to set storage correctly on a new clone:
   */
  function initialiseDelegationContainer(
    address payable owner_,
    address payable delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 ownerRightsInteger,
    string memory containerURI_,
    uint64 offerId
  ) external;

  /**
   * @dev Delegate accepts delegation
   */
  function acceptDelegation(uint64 provider_) external payable;

  /**
   * @dev Get delegation details.
   */
  function getDelegationContainerDetails(uint64 passedDelegationId_)
    external
    view
    returns (
      uint64 delegationId_,
      address assetOwner_,
      address delegate_,
      address tokenContract_,
      uint256 tokenId_,
      bool terminated_,
      uint32 startTime_,
      uint24 durationInDays_,
      uint96 delegationFee_,
      uint256 delegateRightsInteger_,
      uint96 containerSalePrice_,
      uint96 delegationSalePrice_
    );

  /**
   * @dev getBeneficiaryByRight: Get balance modifier by rights
   */
  function getBeneficiaryByRight(uint256 rightsIndex_)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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