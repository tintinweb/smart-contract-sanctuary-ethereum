// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDelegationContainer.sol";
import "./IEPSDelegateRegister.sol";

/**
 *
 * @dev The delegation container contract. This contract holds details of the EPS
 * delegation and custodies the asset. It is owned by the asset owner.
 *
 */
contract DelegationContainer is IDelegationContainer, IERC721Receiver, Context {
  using Address for address;

  // ============================
  // Constants
  // ============================

  // Default for any percentages, which must be held as a prortion of 100,000, i.e. a
  // percentage of 5% is held as 5,000.
  uint256 constant PERCENTAGE_DENOMINATOR = 100000;

  uint256 constant AIR_DROP_RIGHTS = 1; // Defined as the FREE claim of new assets

  uint256 constant RIGHTS_SLICE_LENGTH = 5;

  uint256 constant OWNER_TOKEN_ID = 0;

  uint256 constant DELEGATE_TOKEN_ID = 1;

  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  IEPSDelegateRegister immutable epsRegister;

  // ============================
  // Storage
  // ============================

  // Slot 1: 160 + 24 + 32 + 8 + 32 = 256
  address payable public assetOwner; //160
  uint24 public durationInDays; // 24 || 184
  uint32 public startTime; // 32 || 216
  bool public terminated; // 8 || 224
  uint32 public tokenIdShort; // 32 || 256

  // Slot 2: 160 + 96 = 256
  address payable public delegate; // 160
  uint96 containerSalePrice; // 96 || 256

  // Slot 3: 160 + 96 = 256
  address public tokenContract; // 160
  uint96 public delegationFee; // 96 || 25

  // Slot 4: 256
  uint256 public delegateRightsInteger; // 256

  // Slot 5: 256
  uint256 public tokenIdLong; // 256

  // Slot 6: 96 = 96
  uint96 delegationSalePrice; // 96 || 96

  // Slot 7: variable, minimum 256
  string public containerURI;

  /**
   *
   * @dev Constructor: immutable register address accepted and loaded into bytecode
   *
   */
  constructor(address epsRegisterAddress_) {
    epsRegister = IEPSDelegateRegister(epsRegisterAddress_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Throws if called by any account other than the delegate.
   */
  modifier onlyDelegate() {
    require(delegate == _msgSender(), "Ownable: caller is not the delegate");
    _;
  }

  /**
   * @dev Throws if the delegation can't be ended.
   */
  modifier whenCanBeEnded() {
    // Can only be called when this delegation has expired OR the delegate has abandoned the delegation and
    // burned their rights:
    require(
      (block.timestamp > startTime + (uint64(durationInDays) * 1 days)) ||
        (delegate == BURN_ADDRESS),
      "Delegation not yet expired"
    );

    require(
      startTime != 0,
      "Cannot end if never started - can cancel or change details"
    );

    require(!terminated, "Delegation already terminated");
    _;
  }

  /**
   * @dev Throws if the delegation has already started
   */
  modifier whenPreCommencement() {
    require(startTime == 0, "Cannot do during delegation term");

    require(!terminated, "Delegation already terminated");
    _;
  }

  // ============================
  // Getters
  // ============================

  /**
   * @dev getDelegationContainerDetails: Get details of this container
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
    )
  {
    return (
      passedDelegationId_,
      assetOwner,
      delegate,
      tokenContract,
      _tokenId(),
      terminated,
      startTime,
      durationInDays,
      delegationFee,
      delegateRightsInteger,
      containerSalePrice,
      delegationSalePrice
    );
  }

  /**
   * @dev tokenId: Return the tokenId (short or long)
   */
  function tokenId() external view returns (uint256) {
    return (_tokenId());
  }

  // ============================
  // Implementation
  // ============================

  /**
   *
   * @dev initialiseDelegationContainer: function to call to set storage correctly on a new delegation container.
   *
   */
  function initialiseDelegationContainer(
    address payable owner_,
    address payable delegate_,
    uint96 delegationFee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_,
    string memory containerURI_,
    uint64 offerId_
  ) external {
    require(owner_ != address(0), "Initialise: Owner cannot be 0 address");

    require(assetOwner == address(0), "Initialise: Can only initialise once");

    assetOwner = owner_;

    delegate = delegate_;

    delegationFee = delegationFee_;

    durationInDays = durationInDays_;

    tokenContract = tokenContract_;

    if (tokenId_ < 4294967295) {
      tokenIdShort = uint32(tokenId_);
    } else {
      tokenIdLong = tokenId_;
    }

    delegateRightsInteger = delegateRightsInteger_;

    if (bytes(containerURI_).length > 0) {
      containerURI = containerURI_;
    }

    if (offerId_ != 0) {
      // If this is accepting an offer start the delegation
      startTime = uint32(block.timestamp);

      // Make the delegation delegate token (id 1) visible:
      emit Transfer(address(0), address(delegate), DELEGATE_TOKEN_ID);
    }
  }

  /**
   *
   * @dev acceptDelegation: Delegate accepts delegation.
   *
   */
  function acceptDelegation(uint64 provider_) external payable {
    // Can't accept this twice:
    require(startTime == 0, "EPS Delegation: Delegation not available");

    // Asset owner cannot also be delegate:
    require(
      assetOwner != msg.sender,
      "EPS Delegation: Owner cannot be delegate"
    );

    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // If there is a delegation fee due it must have been paid:
    require(
      msg.value == (delegationFee + delegationRegisterFee),
      "EPS Delegation: Incorrect delegation fee"
    );

    if (delegate == address(0)) {
      delegate = payable(msg.sender);
    } else {
      // If this delegation is address specific it can only be accepted from that address:
      require(delegate == msg.sender, "EPS: Incorrect delegate address");
    }

    // We have a valid delegation, finalise the arrangement:
    startTime = uint32(block.timestamp);

    uint256 epsFee;

    // The fee taken by the protocol is a percentage of the delegation fee + the register fee. This ensures
    // that even for free delegations the platform takes a small fee to remain sustainable.
    if (msg.value == delegationRegisterFee) {
      epsFee = delegationRegisterFee;
    } else {
      epsFee = _calculateEPSFee(
        msg.value,
        delegationRegisterFee,
        delegationFeePercentage
      );
    }

    // Load to epsRegister:
    epsRegister.saveDelegationRecord{value: epsFee}(
      provider_,
      tokenContract,
      _tokenId(),
      assetOwner,
      delegate,
      uint64(block.timestamp) + (uint64(durationInDays) * 1 days),
      delegateRightsInteger
    );

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(assetOwner, (msg.value - epsFee));
    }

    // Make the delegate token (token id 1) visible:
    emit Transfer(address(0), address(delegate), DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev cancelDelegation: The owner can call this to cancel a delegation that has not yet begun.
   *
   */
  function cancelDelegation() external onlyOwner whenPreCommencement {
    _performFinalisation();
  }

  /**
   *
   * @dev changeDelegationDetails: The owner can call this to change details of a delegation that has not yet begun.
   *
   */
  function changeDelegationDetails(
    uint64 provider_,
    uint96 fee_,
    uint24 duration_,
    address delegate_,
    uint256 delegateRightsInteger_
  ) external onlyOwner whenPreCommencement {
    delegationFee = fee_;
    durationInDays = duration_;
    delegate = payable(delegate_);
    delegateRightsInteger = delegateRightsInteger_;

    epsRegister.containerDetailsUpdated(
      provider_,
      delegate_,
      fee_,
      duration_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev acceptOfferPreCommencement: The owner can accept an offer prior to a delegation starting
   *
   */
  function acceptOfferPreCommencement(
    uint64 provider_,
    address delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    uint256 delegateRightsInteger_,
    uint64 offerId_
  ) external onlyOwner whenPreCommencement {
    epsRegister.acceptOfferPriorToCommencement(
      provider_,
      assetOwner,
      delegate_,
      durationInDays_,
      fee_,
      delegateRightsInteger_,
      offerId_,
      tokenContract,
      _tokenId()
    );

    // Set the container entries to those retrieved from the offer:
    durationInDays = durationInDays_;
    startTime = uint32(block.timestamp);
    delegate = payable(delegate_);
    delegationFee = fee_;
    delegateRightsInteger = delegateRightsInteger_;

    emit Transfer(address(0), delegate_, DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev endDelegationAndRetrieveAsset: When this delegation has expired it can be ended, with the original
   * asset returned to the assetOwner and the register details removed. Note that any NEW assets
   * on this contract are handled according to the rights delegated (i.e. whether they go to the owner
   * or the delegate).
   *
   */
  function endDelegationAndRetrieveAsset() external onlyOwner whenCanBeEnded {
    _performFinalisation();

    // Also "burn" the delegate token:
    emit Transfer(delegate, address(0), DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev endDelegationAndRelist: When this delegation has expired it can be ended, with a new delegation
   * specified in its place.
   *
   * This function can be called by the asset owner only
   *
   */
  function endDelegationAndRelist(
    uint64 provider_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    uint256 delegateRightsInteger_
  ) external onlyOwner whenCanBeEnded {
    address oldDelegate = delegate;

    // Reset the container entries:
    durationInDays = durationInDays_;
    startTime = 0;
    delegate = payable(newDelegate_);
    delegationFee = fee_;
    delegateRightsInteger = delegateRightsInteger_;

    // Reset the register entries:
    epsRegister.relistEntry(
      provider_,
      assetOwner,
      oldDelegate,
      newDelegate_,
      fee_,
      durationInDays_,
      tokenContract,
      _tokenId(),
      delegateRightsInteger_
    );

    //  "burn" the previous delegate token:
    emit Transfer(oldDelegate, address(0), DELEGATE_TOKEN_ID);
    // New delegation is now ready to be accepted.
  }

  /**
   *
   * @dev endDelegationAndAcceptOffer: When this delegation has expired it can be ended, and a delegation
   * offer accepted (subject to all the normal checks when accepting an offer)
   *
   * This function can be called by the asset owner only
   *
   */
  function endDelegationAndAcceptOffer(
    uint64 provider_,
    address newDelegate_,
    uint96 fee_,
    uint24 durationInDays_,
    uint256 delegateRightsInteger_,
    uint64 offerId_
  ) external onlyOwner whenCanBeEnded {
    address oldDelegate = delegate;

    epsRegister.acceptOfferAfterDelegationCompleted(
      provider_,
      assetOwner,
      oldDelegate,
      newDelegate_,
      durationInDays_,
      fee_,
      delegateRightsInteger_,
      offerId_,
      tokenContract,
      _tokenId()
    );

    // Set the container entries to those retrieved from the offer:
    durationInDays = durationInDays_;
    startTime = uint32(block.timestamp);
    delegate = payable(newDelegate_);
    delegationFee = fee_;
    delegateRightsInteger = delegateRightsInteger_;

    // Note we could transfer the delegate token directly from the old delegate to the new delegate
    // in the same event. However, this is not what's happening, rather the delegation associated with
    // the old delegate is ending, and that with the new delegate is beginning. We therefore 'burn'
    // the old delegates token and 'mint' a new one for the new delegate.
    emit Transfer(oldDelegate, address(0), DELEGATE_TOKEN_ID);
    emit Transfer(address(0), newDelegate_, DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev _tokenId: return either tokenIdShort or Long
   *
   */
  function _tokenId() internal view returns (uint256) {
    // This saves storage on practically every container, as tokenId is very rarely
    // more than 4,294,967,295, but we store a whole uint256 for it every time, therefore
    // requiring a whole slot. Note that this method works for tokenId 0 as well, as that
    // will enter here, fail the tokenIdShort check (as it has been set to 0) and return
    // the value from tokenIdLong (which, correctly, is 0)
    if (tokenIdShort != 0) return (tokenIdShort);
    else return (tokenIdLong);
  }

  /**
   *
   * @dev _performFinalisation: unified processing for actions at the end of a delegation
   *
   */
  function _performFinalisation() internal {
    // A key principle of an EPS container is that the asset owner continues to have full rights
    // to the asset, subject to those delegated as part of the EPS delegation. The asset owner
    // has full ownership of the container. There is no other priviledged access, save the
    // delegate's right to transfer or list the delegation, and call functions if they are the
    // 'senior' rights owner of the airdrop right.
    //
    // It is therefore essential that nothing interupt the asset owner retrieving the ERC721 once
    // a delegation period has completed. Below we update the register to show that this delegation
    // has ceased and then return the asset to the owner. We do not anticipate a call to the register
    // ever failing, but it *is* an external call (i.e. to another contract). If for whatever reason it
    // fails the owner MUST still receive their ERC721. EPS would need to investigate the error and
    // determine if any corrective action is needed, but job one of the protocol is to see assets
    // under the full control of the rightful owner. For this reason we handle the external call in
    // a try / except clause. If this fails we still return the asset to the owner, in addition to
    // logging the error in an event for further analysis.

    // Remove the register entries:
    try
      epsRegister.deleteEntry(tokenContract, _tokenId(), assetOwner, delegate)
    {
      //
    } catch (bytes memory reason) {
      emit EPSRegisterCallError(reason);
    }

    terminated = true;

    // Return the original asset to the owner:
    IERC721(tokenContract).transferFrom(address(this), assetOwner, _tokenId());

    // "Burn" the owner token denoting this delegation:
    emit Transfer(owner(), address(0), OWNER_TOKEN_ID);
  }

  /**
   * @dev listContainerForSale: Allows the asset owner to list the delegation container for sale. This allows the
   * owner of an asset with an active delegation to sell the entire container contract, therefore
   * transferring the right to retrieve the ERC721 at the end of the delegation period. This also
   * allows the new owner to acknowledge that existing rights have been delegated, and that these
   * are grandfathered to the delegate despite the change of the owner of the container (and underlying asset).
   */
  function listContainerForSale(uint64 provider_, uint96 salePrice_)
    external
    onlyOwner
  {
    require(
      startTime != 0,
      "Cannot sell inactive container - owner can cancel"
    );
    require(salePrice_ != 0, "Sale price cannot be 0");
    containerSalePrice = salePrice_;
    epsRegister.containerListedForSale(provider_, salePrice_);
  }

  /**
   * @dev buyContainerForSale: allows someone to purchase the container if they have paid the right amount
   * of eth.
   */
  function buyContainerForSale(uint64 provider_) external payable {
    // Sale price of 0 is not for sale
    require(containerSalePrice != 0, "Container not for sale");

    // Prevent someone from buying an expired delegation or one for an empty container!
    require(
      IERC721(tokenContract).ownerOf(_tokenId()) == address(this),
      "Asset no longer in container"
    );

    require(
      block.timestamp < (startTime + (uint64(durationInDays) * 1 days)),
      "Delegation expired"
    );

    // Handle remittance:
    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // Check the fee:
    require(
      msg.value == (containerSalePrice + delegationRegisterFee),
      "Incorrect sale price"
    );

    address oldOwner = assetOwner;

    _transferOwnership(provider_, msg.sender);

    // Platform fee is a percentage of the sale price + the base platform fee.

    uint256 epsFee = _calculateEPSFee(
      msg.value,
      delegationRegisterFee,
      delegationFeePercentage
    );

    _processPayment(address(epsRegister), epsFee);

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(oldOwner, (msg.value - epsFee));
    }
  }

  /**
   * @dev listDelegationForSale: Allows the delegate to list the delegation for sale.
   */
  function listDelegationForSale(uint64 provider_, uint96 salePrice_)
    external
    onlyDelegate
  {
    require(salePrice_ != 0, "EPS: Sale price cannot be 0");
    delegationSalePrice = salePrice_;
    epsRegister.delegationListedForSale(provider_, salePrice_);
  }

  /**
   * @dev buyDelegationForSale: allows someone to purchase the delegation if they have paid the right amount
   * of eth.
   */
  function buyDelegationForSale(uint64 provider_) external payable {
    // Sale price of 0 is not for sale
    require(delegationSalePrice != 0, "EPS: Delegation not for sale");

    // Prevent someone from buying an expired delegation or one for an empty container!
    require(
      IERC721(tokenContract).ownerOf(_tokenId()) == address(this),
      "EPS: Asset no longer in container"
    );

    require(
      block.timestamp < (startTime + (uint64(durationInDays) * 1 days)),
      "EPS: Delegation expired"
    );

    // Handle remittance:
    (
      uint256 delegationRegisterFee,
      uint256 delegationFeePercentage
    ) = epsRegister.getFeeDetails();

    // Check the fee:
    require(
      msg.value == (delegationSalePrice + delegationRegisterFee),
      "EPS: Incorrect sale price"
    );

    address oldDelegate = delegate;

    _transferDelegate(provider_, msg.sender);

    // EPS fee is a percentage of the sale price + the base platform fee.

    uint256 epsFee = _calculateEPSFee(
      msg.value,
      delegationRegisterFee,
      delegationFeePercentage
    );

    _processPayment(address(epsRegister), epsFee);

    // Handle delegationFee remittance
    if (msg.value - epsFee > 0) {
      _processPayment(oldDelegate, (msg.value - epsFee));
    }

    // "Transfer" the delegate NFT:
    emit Transfer(oldDelegate, msg.sender, DELEGATE_TOKEN_ID);
  }

  /**
   *
   * @dev _calculateEPSFee: calculate the EPS fee for the provider parameters
   *
   */
  function _calculateEPSFee(
    uint256 payment_,
    uint256 delegationRegisterFee_,
    uint256 delegationFeePercentage_
  ) internal pure returns (uint256 epsFee) {
    return
      (((payment_ - delegationRegisterFee_) * delegationFeePercentage_) /
        PERCENTAGE_DENOMINATOR) + delegationRegisterFee_;
  }

  /**
   *
   * @dev _processPayment: unified processing for transfer of ETH
   *
   */
  function _processPayment(address payee_, uint256 payment_) internal {
    if (payment_ > 0) {
      (bool success, ) = payee_.call{value: payment_}("");
      require(success, "EPS: Transfer failed");
    }
  }

  /**
   * @dev getBeneficiaryByRight: Get balance modifier by rights
   */
  function getBeneficiaryByRight(uint256 rightsIndex_)
    external
    view
    returns (address)
  {
    // Check the delegateRightsInteger to see whether the owner or the
    // delegate has rights at this index (note that the rights integers always sum
    // so we can check either to get the same result)

    if (_sliceRightsInteger(rightsIndex_, delegateRightsInteger) == 0) {
      // Owner has the rights
      return (assetOwner);
    } else {
      // Delegate has the rights
      return (delegate);
    }
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
   * @dev onERC721Received: Recieve an ERC721
   *
   */
  function onERC721Received(
    address,
    address,
    uint256 tokenId_,
    bytes memory
  ) external override returns (bytes4) {
    // If this is the arrival of the original asset 'mint' the owner token:
    if (msg.sender == tokenContract && tokenId_ == _tokenId()) {
      emit Transfer(address(0), address(assetOwner), OWNER_TOKEN_ID);
    }
    return this.onERC721Received.selector;
  }

  /**
   * @dev Ownable methods: owner() is the assetOwner.
   */

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return assetOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(uint64 provider_, address newOwner)
    public
    onlyOwner
  {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(provider_, newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(uint64 provider_, address newOwner) internal {
    address oldOwner = assetOwner;
    assetOwner = payable(newOwner);

    // Remove any sale details for this container:
    containerSalePrice = 0;

    // Update the delegation register:
    epsRegister.changeAssetOwner(
      provider_,
      newOwner,
      tokenContract,
      _tokenId()
    );
    emit OwnershipTransferred(provider_, oldOwner, newOwner);

    // "Transfer" the ownership NFT
    emit Transfer(oldOwner, newOwner, OWNER_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate to a new account (`newDelegate`).
   * Can only be called by the current delegate.
   */
  function transferDelegate(uint64 provider_, address newDelegate_)
    public
    onlyDelegate
  {
    require(
      newDelegate_ != address(0),
      "Ownable: new owner is the zero address"
    );

    address oldDelegate = delegate;

    _transferDelegate(provider_, newDelegate_);

    // "Transfer" the delegate NFT:
    emit Transfer(oldDelegate, newDelegate_, DELEGATE_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate to the dead address.
   * Can only be called by the current delegate.
   */
  function burnDelegate(uint64 provider_) public onlyDelegate {
    address oldDelegate = delegate;

    _transferDelegate(provider_, BURN_ADDRESS);

    // We set the delegate to the 0xdead address as we need this address
    // to be non-0 to show that there IS a delegation here, even though
    // the delegate has burned their rights for the duration of the delegation.
    emit Transfer(oldDelegate, BURN_ADDRESS, DELEGATE_TOKEN_ID);
  }

  /**
   * @dev Transfers delegate on the contract to a new account (`newDelegate`).
   * Internal function without access restriction.
   */
  function _transferDelegate(uint64 provider_, address newDelegate_) internal {
    delegate = payable(newDelegate_);

    // Clear sale data
    delegationSalePrice = 0;

    // Update the delegation register:
    epsRegister.changeDelegate(provider_, delegate, tokenContract, _tokenId());
  }

  /**
   *
   * @dev airdropAddress: return the address that has new asset (i.e. airdrop) rights on this delegation.
   *
   */
  function _airdropAddress() internal view returns (address payable) {
    // Check the delegateRightsInteger to see whether the owner or the
    // delegate has rights at this index (note that the rights integers always sum
    // so we can check either to get the same result)

    if (_sliceRightsInteger(1, delegateRightsInteger) == 0) {
      // Owner has the rights
      return (assetOwner);
    } else {
      // Delegate has the rights
      return (delegate);
    }
  }

  /**
   *
   * @dev withdrawETH: A withdraw function to allow ETH to be withdrawn to the address with airdrop rights
   *
   */
  function withdrawETH(uint256 amount_) external {
    (bool success, ) = _airdropAddress().call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev withdrawERC20: A withdraw function to allow ERC20s to be withdrawn to the address with airdrop rights
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external {
    token_.transfer(_airdropAddress(), amount_);
  }

  /**
   *
   * @dev withdrawERC721: A withdraw function to allow ERC721s to be withdrawn to the address with airdrop rights
   * Note - this excludes the delegated asset!
   *
   */
  function withdrawERC721(IERC721 token_, uint256 tokenId_) external {
    require(
      !(address(token_) == tokenContract && tokenId_ == _tokenId()),
      "Cannot transfer delegated asset"
    );

    token_.transferFrom(address(this), _airdropAddress(), tokenId_);
  }

  /**
   *
   * @dev withdrawERC1155: A withdraw function to allow ERC1155s to be withdrawn to the address with airdrop rights
   * Note - this excludes the delegated asset!
   *
   */
  function withdrawERC1155(
    IERC1155 token_,
    uint256 tokenId_,
    uint256 amount_
  ) external {
    token_.safeTransferFrom(
      address(this),
      _airdropAddress(),
      tokenId_,
      amount_,
      ""
    );
  }

  /**
   *
   * @dev callExternal: It remains possible that to claim some benefit the beneficial owner of the asset needs to
   * make a call to another contract. For example, there could be an airdrop that must be claimed, and the project
   * performing the airdrop hasn't consulted the delegation register. Hopefully this doesn't happen, but if it does,
   * provide this method of calling any contract with any parameters.
   *
   * Note that we are making a distinction ahead of time that this function can only be used by the owner with air-drop
   * rights. It is conceivable that this function could be used in a mint scenario, but it is impossible to know ahead of time
   * what uses this may be put to by future projects. Airdrop rights in this sense are the 'senior' new asset right.
   *
   */
  function callExternal(
    address to_,
    uint256 value_,
    bytes memory data_,
    uint256 txGas_
  ) external returns (bool success) {
    // This cannot be used on a call to the tokenContract of the delegated asset, itself, or the EPS register
    require(
      to_ != tokenContract &&
        to_ != address(this) &&
        to_ != address(epsRegister),
      "Invalid call"
    );

    // Only the airdrop address
    require(
      msg.sender == _airdropAddress(),
      "Only address with airdrop rights"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := call(txGas_, to_, value_, add(data_, 0x20), mload(data_), 0, 0)
    }

    require(success, "External call failed");
  }

  /**
   * @dev Receive ETH
   */
  receive() external payable {}

  /**
   * ================================
   * IERC721 interface
   * ================================
   */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner_) public view returns (uint256) {
    if (terminated) {
      return (0);
    }

    if (owner_ == owner()) {
      return (1);
    }

    if (owner_ == delegate && startTime != 0) {
      return (1);
    }

    return (0);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId_) public view returns (address ownerOf_) {
    if (terminated || tokenId_ > 1) {
      revert("ERC721: invalid token ID");
    }

    if (tokenId_ == 0) {
      return (owner());
    }

    if (tokenId_ == 1) {
      if (startTime == 0) {
        // Can't have an owner of a delegate token before this has started:
        revert("ERC721: invalid token ID");
      }
      if (delegate == BURN_ADDRESS) {
        // Unusual situation of a delegate having burned their delegation rights:
        revert("ERC721: invalid token ID");
      }
      return (delegate);
    }
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view returns (string memory) {
    uint64 delegationId = epsRegister.getDelegationIdForContainer(
      address(this)
    );

    return
      string.concat(
        "EPS ",
        Strings.toString(delegationId),
        ",  Token 0 is owner, Token 1 is delegate"
      );
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view returns (string memory) {
    uint64 delegationId = epsRegister.getDelegationIdForContainer(
      address(this)
    );

    return string.concat("EPS", Strings.toString(delegationId));
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId_) public view returns (string memory) {
    require(tokenId_ < 2, "ERC721: invalid token ID");

    return IERC721Metadata(tokenContract).tokenURI(_tokenId());
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
interface IEPSDelegateRegister {
  // ======================================================
  // EVENTS
  // ======================================================
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
    uint256 delegateRightsInteger
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
    uint256 delegateRightsInteger
  );

  // Emitted when a delegation is complete:
  event DelegationComplete(uint64 indexed delegationId);

  // Emitted when the delegation owner changes:
  event DelegationOwnerChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newOwner
  );

  // Emitted when the delegation delegate changes:
  event DelegationDelegateChanged(
    uint64 indexed provider,
    uint64 indexed delegationId,
    address indexed newDelegate
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

  event OfferAccepted(uint64 provider, uint64 offerId);

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

  error CannotLockToEmptyContainer();
  error TemplateContainerLocked();
  error InvalidContainer();
  error InvalidERC20();
  error DoNoMintToThisAddress();
  error InvalidRights();
  error OwnerCannotBeDelegate();
  error CallerIsNotOfferMaker();
  error InvalidOffer();

  // ======================================================
  // FUNCTIONS
  // ======================================================

  function getFeeDetails()
    external
    view
    returns (uint96 delegationRegisterFee_, uint32 delegationFeePercentage_);

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

  function saveDelegationRecord(
    uint64 provider_,
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint64 endTime_,
    uint256 delegateRightsInteger_
  ) external payable;

  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_
  ) external;

  function changeDelegate(
    uint64 provider_,
    address newDelegate_,
    address tokenContract_,
    uint256 tokenId_
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

  function getDelegationIdForContainer(address container_)
    external
    view
    returns (uint64 delegationId_);

  function relistEntry(
    uint64 provider_,
    address owner_,
    address oldDelegate_,
    address delegate_,
    uint96 fee_,
    uint24 durationInDays_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 delegateRightsInteger_
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
interface IDelegationContainer {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
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