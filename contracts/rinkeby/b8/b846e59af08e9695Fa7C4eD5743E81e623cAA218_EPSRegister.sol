// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.16;
import "./DelegateRegister.sol";
import "./ProxyRegister.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 *
 * @dev The EPS Register contract, implementing the proxy and deligate registers
 *
 */
contract EPSRegister is ProxyRegister, DelegateRegister {
  using SafeERC20 for IERC20;

  // ======================================================
  // VARIABLES
  // ======================================================

  // EPS treasury address:
  address public treasury;

  // Count of active ETH addresses for total supply
  uint256 public activeEthAddresses = 1;

  // 'Air drop' of EPSAPI to every address
  uint256 public epsAPIBalance = 10000;

  /**
   * @dev Constructor initialises the parameters for the proxy and delegate registers.
   */
  constructor(
    uint256 proxyRegisterFee_,
    address treasury_,
    uint96 delegationRegisterFee_,
    uint32 delegationFeePercentage_,
    address weth_,
    uint256 deletionNominalEth_
  )
    ProxyRegister(proxyRegisterFee_, deletionNominalEth_)
    DelegateRegister(delegationRegisterFee_, delegationFeePercentage_, weth_)
  {
    setTreasuryAddress(treasury_);
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev beneficiaryOf: Returns the beneficiary of the `tokenId` token.
   */
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_) {
    // 1 Check for an active delegation. We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }
    beneficiary_ = getBeneficiaryByRight(
      tokenContract_,
      tokenId_,
      rightsIndex_
    );

    if (beneficiary_ == address(0)) {
      // 2 No delegation. Get the owner:
      beneficiary_ = IERC721(tokenContract_).ownerOf(tokenId_);

      // 3 Check if this is a proxied benefit
      if (coldIsLive(beneficiary_)) {
        beneficiary_ = coldToHot[beneficiary_];
      }
    }
  }

  /**
   * @dev beneficiaryBalance: Returns the beneficiary balance of ETH.
   */
  function beneficiaryBalance(address queryAddress_)
    external
    view
    returns (uint256 balance_)
  {
    // Get any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - include the balance
      // held natively by this address and the cold:
      balance_ += queryAddress_.balance;

      balance_ += hotToRecord[queryAddress_].cold.balance;
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += queryAddress_.balance;
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance for an ERC721, ERC20 or ERC777 contract.
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1 If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (containerToDelegationId[queryAddress_] != 0) {
      return (0);
    }

    // 2 Get delegated balances:
    balance_ = getBalanceByRight(tokenContract_, queryAddress_, rightsIndex_);

    // 3 Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC721(tokenContract_).balanceOf(queryAddress_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC721(tokenContract_).balanceOf(cold);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC721(tokenContract_).balanceOf(queryAddress_);
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf1155: Returns the beneficiary balance for an ERC1155.
   */
  function beneficiaryBalanceOf1155(
    address queryAddress_,
    address tokenContract_,
    uint256 id_
  ) external view returns (uint256 balance_) {
    // Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC1155(tokenContract_).balanceOf(queryAddress_, id_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC1155(tokenContract_).balanceOf(cold, id_);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC1155(tokenContract_).balanceOf(queryAddress_, id_);
      }
    }
  }

  /**
   * @dev getAddresses: Returns the register address details (cold and delivery address) for a passed hot address
   */
  function getAddresses(address _receivedAddress)
    public
    view
    returns (
      address cold,
      address delivery,
      bool isProxied
    )
  {
    require(
      !coldIsLive(_receivedAddress),
      "Cold wallet cannot interact: use hot"
    );
    if (hotIsLive(_receivedAddress)) {
      return (
        hotToRecord[_receivedAddress].cold,
        hotToRecord[_receivedAddress].delivery,
        true
      );
    } else {
      return (_receivedAddress, _receivedAddress, false);
    }
  }

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================
  /**
   * @dev setTreasuryAddress: set the treasury address:
   */
  function setTreasuryAddress(address _treasuryAddress) public onlyOwner {
    treasury = _treasuryAddress;
  }

  /**
   * @dev setActiveEthAddresses: used in the psuedo total supply calc:
   */
  function setNNumberOfEthAddressesAndAirdropAmount(
    uint256 count_,
    uint256 air_
  ) public onlyOwner {
    activeEthAddresses = count_;
    epsAPIBalance = air_;
  }

  /**
   * @dev withdrawETH: withdraw eth to the treasury:
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = treasury.call{value: amount_}("");
    require(success, "E04");
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

  // ======================================================
  // ETH CALL ENTRY POINT
  // ======================================================

  /**
   *
   * @dev receive: Wallets need never connect directly to add to EPS register, rather they can
   * interact through ETH or ERC20 transfers. This 'air gaps' your wallet(s) from
   * EPS. ETH transfers can be used to pay the fee or delete a record (sent from either
   * the hot or the cold wallet).
   *
   */
  receive() external payable {
    require(
      msg.value == proxyRegisterFee ||
        msg.value == deletionNominalEth ||
        containerToDelegationId[msg.sender] != 0 ||
        msg.sender == owner(),
      "Unknown amount"
    );

    if (msg.value == proxyRegisterFee) {
      _payFee(msg.sender);
    } else if (msg.value == deletionNominalEth) {
      // Either hot or cold requesting a deletion:
      _deleteRecord(msg.sender, 0);
    }
  }

  /**
   * @dev _payFee: process receipt of payment
   */
  function _payFee(address from_) internal {
    // 1) If our from address is a hot address and the proxy is pending payment we
    // can record this as paid and put the record live:
    if (hotToRecord[from_].status == ProxyStatus.pendingPayment) {
      _recordLive(
        from_,
        hotToRecord[from_].cold,
        hotToRecord[from_].delivery,
        hotToRecord[from_].provider
      );
    } else if (
      // 2) If our from address is a cold address and the proxy is pending payment we
      // can record this as paid and put the record live:
      hotToRecord[coldToHot[from_]].status == ProxyStatus.pendingPayment
    ) {
      _recordLive(
        coldToHot[from_],
        from_,
        hotToRecord[coldToHot[from_]].delivery,
        hotToRecord[coldToHot[from_]].provider
      );
    } else revert NoPaymentPendingForAddress();
  }

  // ======================================================
  // ERC20 METHODS (to expose API)
  // ======================================================

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return "EPS API";
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "EPSAPI";
  }

  function decimals() public pure returns (uint8) {
    return 0;
  }

  function balanceOf(address) public view returns (uint256) {
    return epsAPIBalance;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return activeEthAddresses * epsAPIBalance;
  }

  /**
   * @dev Doesn't move tokens at all. There was no spoon and there are no tokens.
   * Rather the quantity being 'sent' denotes the action the user is taking
   * on the EPS register, and the address they are 'sent' to is the address that is
   * being referenced by this request.
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    _tokenAPICall(msg.sender, to, amount);

    return (true);
  }
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

// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEPSProxyRegister.sol";

/**
 *
 * @dev The EPS Proxy Register contract. This contract implements a trustless proof of proxy between
 * two addresses, allowing the hot address to operate with the same rights as a cold address, and
 * for new assets to be delivered to a configurable delivery address.
 *
 */
contract ProxyRegister is IEPSProxyRegister, Ownable {
  // ======================================================
  // CONSTANTS
  // ======================================================

  // Constants denoting the API access types:
  uint256 constant HOT_NOMINATE_COLD = 1;
  uint256 constant COLD_ACCEPT_HOT = 2;
  uint256 constant CHANGE_DELIVERY = 3;
  uint256 constant DELETE_RECORD = 4;

  // ======================================================
  // VARIABLES
  // ======================================================

  // Fee to add a live proxy record to the register. This must be sent by the cold or hot wallet
  // address to the contract AFTER the hot wallet has nominated the cold wallet and the cold
  // wallet has accepted. If a fee is payable the record will remain in paymentPending status
  // until it is paid. If no fee is being charged the record is live after the cold wallet has
  // accepted the nomination.
  uint256 public proxyRegisterFee;

  // Cold wallet addresses need never call methods on EPS. All functionality is provided through
  // an ERC20 interface API, as well as traditional contract methods. To allow a cold wallet to delete
  // a proxy record without even using the ERC20 API, for example when the owner has lost access to
  // the hot wallet, we provide a nominal ETH payment, that if received from a cold wallet on a live
  // proxy will delete that proxy record.
  uint256 public deletionNominalEth;

  // ======================================================
  // MAPPINGS
  // ======================================================

  // Mapping between the hot wallet and the proxy record, the proxy record holding all the details of
  // the proxy relationship
  mapping(address => Record) hotToRecord;

  // Mapping from a cold address to a the associated hot address
  mapping(address => address) coldToHot;

  /**
   * @dev Constructor initialises the register fee and nominal ETH to which can be sent to
   * the contract to end an existing proxy.
   */
  constructor(uint256 registerFee_, uint256 deletionNominalEth_) {
    proxyRegisterFee = registerFee_;
    deletionNominalEth = deletionNominalEth_;
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev isValidAddresses: Check the validity of sent addresses
   */
  function isValidAddresses(
    address hot_,
    address cold_,
    address delivery_
  ) public pure {
    require(cold_ != address(0), "Cold = 0");
    require(cold_ != hot_, "Hot = cold");
    require(delivery_ != address(0), "Delivery = 0");
  }

  /**
   * @dev addressIsAvailable: Return if an address isn't, as either hot or cold:
   * 1) live
   * 2) pending acceptance (unless we are checking as a cold address, which can be at pendingAcceptance infinite times)
   * 3) pending payment
   */
  function addressIsAvailable(address queryAddress_, bool checkingHot_)
    public
    view
    returns (bool)
  {
    // Check as cold:
    ProxyStatus currentStatus = hotToRecord[coldToHot[queryAddress_]].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      // Cold addresses CAN be pending acceptance as many times as they like,
      // in fact it is vital that they can be, so we only check this for the hot
      // address:
      (checkingHot_ && currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return false;
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      // Neither cold or hot can be a hot address, at any status
      currentStatus == ProxyStatus.pendingAcceptance
    ) {
      return false;
    }

    return true;
  }

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) public view returns (bool) {
    return (hotToRecord[coldToHot[cold_]].status == ProxyStatus.live);
  }

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) public view returns (bool) {
    return (hotToRecord[hot_].status == ProxyStatus.live);
  }

  /**
   * @dev coldIsActiveOnRegister: Return if a cold wallet is active
   */
  function coldIsActiveOnRegister(address cold_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[coldToHot[cold_]].status;
    return (currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment);
  }

  /**
   * @dev hotIsActiveOnRegister: Return if a hot wallet is active
   */
  function hotIsActiveOnRegister(address hot_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[hot_].status;
    return (currentStatus != ProxyStatus.none);
  }

  /**
   * @dev getProxyRecordForHot: Get proxy details for a hot address
   */
  function getProxyRecordForHot(address hot_)
    public
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    Record memory currentItem = hotToRecord[hot_];
    return (
      currentItem.status,
      hot_,
      currentItem.cold,
      currentItem.delivery,
      currentItem.provider,
      currentItem.feePaid
    );
  }

  /**
   * @dev getProxyRecordForCold: Get proxy details for a cold address
   */
  function getProxyRecordForCold(address cold_)
    public
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    address currentHot = coldToHot[cold_];
    Record memory currentItem = hotToRecord[currentHot];
    return (
      currentItem.status,
      currentHot,
      currentItem.cold,
      currentItem.delivery,
      currentItem.provider,
      currentItem.feePaid
    );
  }

  /**
   * @dev Get proxy details for an address, checking cold and hot
   */
  function getProxyRecordForAddress(address queryAddress_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    )
  {
    // Check as cold:
    ProxyStatus currentStatus = hotToRecord[coldToHot[queryAddress_]].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      (currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return getProxyRecordForCold(queryAddress_);
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.live ||
      currentStatus == ProxyStatus.pendingPayment ||
      (currentStatus == ProxyStatus.pendingAcceptance)
    ) {
      return (getProxyRecordForHot(queryAddress_));
    }

    // Address not found
    return (ProxyStatus.none, address(0), address(0), address(0), 0, false);
  }

  // ======================================================
  // LIFECYCLE - NOMINATION
  // ======================================================

  /**
   * @dev nominate: Hot Nominates cold, direct contract call
   */
  function nominate(
    address cold_,
    address delivery_,
    uint64 provider_
  ) external payable {
    require(msg.value == proxyRegisterFee, "Incorrect fee");
    _processNomination(msg.sender, cold_, delivery_, msg.value, provider_);
  }

  /**
   * @dev _processNomination: Process the nomination
   */
  // The hot wallet cannot be on any record, live or pending, as either a hot or cold wallet.
  // The cold wallet cannot be currently live or pending payment, but can be 'pending' on multiple records. It can
  // only accept one of those pending records (at at time - others can be accepted if it cancels the existing proxy)
  function _processNomination(
    address hot_,
    address cold_,
    address delivery_,
    uint256 feePaid_,
    uint64 provider_
  ) internal {
    isValidAddresses(hot_, cold_, delivery_);

    require(
      addressIsAvailable(hot_, true) && addressIsAvailable(cold_, false),
      "Already proxied"
    );

    // Record the mapping from the hot address to the record. This is pending until accepted by the cold address.
    hotToRecord[hot_] = Record(
      provider_,
      ProxyStatus.pendingAcceptance,
      feePaid_ == proxyRegisterFee,
      cold_,
      delivery_
    );

    emit NominationMade(hot_, cold_, delivery_, provider_);
  }

  /**
   * @dev acceptNomination: Cold accepts nomination, direct contract call
   * (though it is anticipated that most will use an ERC20 transfer)
   */
  function acceptNomination(address hot_, uint64 provider_) external payable {
    _acceptNominationValidation(hot_, msg.sender);

    require(
      hotToRecord[hot_].feePaid || msg.value == proxyRegisterFee,
      "Fee required"
    );
    _acceptNomination(hot_, msg.sender, msg.value, provider_);
  }

  /**
   * @dev _acceptNominationValidation: validate passed parameters
   */
  function _acceptNominationValidation(address hot_, address cold_)
    internal
    view
  {
    // Check that the address passed in matches a pending record for the hot address:
    require(
      hotToRecord[hot_].cold == cold_ &&
        hotToRecord[hot_].status == ProxyStatus.pendingAcceptance,
      "Address mismatch"
    );

    // Check that the cold address isn't live or pending payment anywhere on the register:
    require(addressIsAvailable(cold_, false), "Already proxied");
  }

  /**
   * @dev _acceptNomination: Cold wallet accepts nomination
   */
  function _acceptNomination(
    address hot_,
    address cold_,
    uint256 feePaid_,
    uint64 providerCode_
  ) internal {
    // Record the mapping from the cold to the hot address:
    coldToHot[cold_] = hot_;

    emit NominationAccepted(
      hot_,
      cold_,
      hotToRecord[hot_].delivery,
      providerCode_
    );

    if (hotToRecord[hot_].feePaid || feePaid_ == proxyRegisterFee) {
      _recordLive(
        hot_,
        cold_,
        hotToRecord[hot_].delivery,
        hotToRecord[hot_].provider
      );
    } else {
      hotToRecord[hot_].status = ProxyStatus.pendingPayment;
    }
  }

  /**
   * @dev _recordLive: put a proxy record live
   */
  function _recordLive(
    address hot_,
    address cold_,
    address delivery_,
    uint64 provider_
  ) internal {
    hotToRecord[hot_].feePaid = true;
    hotToRecord[hot_].status = ProxyStatus.live;

    emit ProxyRecordLive(hot_, cold_, delivery_, provider_);
  }

  // ======================================================
  // LIFECYCLE - CHANGING DELIVERY ADDRESS
  // ======================================================

  /**
   * @dev updateDeliveryAddress: Change delivery address on an existing proxy record.
   */
  function updateDeliveryAddress(address delivery_, uint256 provider_)
    external
  {
    _updateDeliveryAddress(msg.sender, delivery_, provider_);
  }

  /**
   * @dev _updateDeliveryAddress: unified delivery address update processing
   */
  function _updateDeliveryAddress(
    address caller_,
    address delivery_,
    uint256 provider_
  ) internal {
    require(delivery_ != address(0), "Delivery = 0");
    // Only hot can change delivery address:
    if (hotIsActiveOnRegister(caller_)) {
      // Hot is requesting the change of address.
      // Get the associated hot address and process the address change
      _processUpdateDeliveryAddress(caller_, delivery_, provider_);
      //
    } else if (coldIsActiveOnRegister(caller_)) {
      // Cold is requesting the change of address. Cold cannot perform this operation:
      revert OnlyHotAddressCanChangeAddress();
      //
    } else {
      // Address not found, revert
      revert NoRecordFoundForAddress();
    }
  }

  /**
   * @dev _processUpdateDeliveryAddress: Process the update of the delivery address
   */
  function _processUpdateDeliveryAddress(
    address hot_,
    address delivery_,
    uint256 provider_
  ) internal {
    Record memory priorItem = hotToRecord[hot_];

    hotToRecord[hot_].delivery = delivery_;
    emit DeliveryUpdated(
      hot_,
      priorItem.cold,
      delivery_,
      priorItem.delivery,
      provider_
    );
  }

  // ======================================================
  // LIFECYCLE - DELETING A RECORD
  // ======================================================

  /**
   * @dev deleteRecord: Delete a proxy record, if found
   */
  function deleteRecord(uint256 provider_) external {
    _deleteRecord(msg.sender, provider_);
  }

  /**
   * @dev _deleteRecord: unified delete record processing
   */
  function _deleteRecord(address caller_, uint256 provider_) internal {
    // Hot can delete any entry that exists for it:
    if (hotIsActiveOnRegister(caller_)) {
      // Hot is requesting the deletion.
      // Get the associated cold address and process the deletion.
      _processDeleteRecord(
        caller_,
        hotToRecord[caller_].cold,
        Participant.hot,
        provider_
      );
      // Cold can only delete a record that it has accepted. This means a record
      // at either pendingPayment or live
    } else if (coldIsActiveOnRegister(caller_)) {
      // Cold is requesting the deletion.
      // Get the associated hot address and process the deletion
      _processDeleteRecord(
        coldToHot[caller_],
        caller_,
        Participant.cold,
        provider_
      );
    } else {
      // Address not found, revert
      revert NoRecordFoundForAddress();
    }
  }

  /**
   * @dev _processDeleteRecord: process record deletion
   */
  function _processDeleteRecord(
    address hot_,
    address cold_,
    Participant initiator_,
    uint256 provider_
  ) internal {
    // Delete the register entry
    delete hotToRecord[hot_];

    // Delete the cold to hot mapping:
    delete coldToHot[cold_];

    emit RecordDeleted(initiator_, cold_, hot_, provider_);
  }

  // ======================================================
  // ERC20 CALL ENTRY POINT
  // ======================================================

  /**
   * @dev tokenAPICall: receive a token API call
   */
  function _tokenAPICall(
    address from_,
    address to_,
    uint256 amount_
  ) internal {
    // The final digit of the amount are the action code, the
    // rest of the amount is the provider code

    uint256 actionCode = amount_ % 10;

    require(actionCode > 0 && actionCode < 5, "Unknown EPSAPI amount");

    uint64 providerCode = uint64(amount_ / 10);

    if (actionCode == HOT_NOMINATE_COLD)
      _processNomination(from_, to_, from_, 0, providerCode);
    else if (actionCode == COLD_ACCEPT_HOT) {
      _acceptNominationValidation(to_, from_);
      _acceptNomination(to_, from_, 0, providerCode);
    } else if (actionCode == CHANGE_DELIVERY)
      _updateDeliveryAddress(from_, to_, providerCode);
    else if (actionCode == DELETE_RECORD) _deleteRecord(from_, providerCode);
  }

  // ======================================================
  // CONFIGURATION
  // ======================================================

  /**
   * @dev setRegisterFee: set the fee for accepting a registration:
   */
  function setRegisterFee(uint256 registerFee_) external onlyOwner {
    proxyRegisterFee = registerFee_;
  }

  /**
   * @dev setDeletionNominalEth: set the nominal ETH transfer that represents an address ending a proxy
   */
  function setDeletionNominalEth(uint256 deleteNominalEth_) external onlyOwner {
    deletionNominalEth = deleteNominalEth_;
  }
}

// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IDelegationContainer.sol";
import "./IEPSDelegateRegister.sol";

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

contract DelegateRegister is IEPSDelegateRegister, Ownable, IERC721Receiver {
  using Clones for address payable;

  // ============================
  // CONSTANTS
  // ============================

  // Total rights, positions 13, 14 and 15 reserved for project specific rights.
  uint256 constant TOTAL_RIGHTS =
    10000100001000010000100001000010000100001000010000100001000010000100001;
  //15   14   13   12   11   10   9    8    7    6    5    4    3    2    1

  // Rights slice length - this is used in run time to slice up rights integers into their component parts.
  uint256 constant RIGHTS_SLICE_LENGTH = 5;

  // Default for any percentages, which must be held as a prortion of 100,000, i.e. a
  // percentage of 5% is held as 5,000.
  uint256 constant PERCENTAGE_DENOMINATOR = 100000;

  address immutable weth;

  // ============================
  // STORAGE
  // ============================

  // Unique ID for every proposed delegation.
  uint64 public delegationId;

  // Unique ID for every collection offer.
  uint64 public collectionOfferId;

  // Basic fee charged by the protocol for operations that require payment, namely the acceptance of a delegation
  // or the secondary sale of rights.
  uint96 public delegationRegisterFee;

  // Percentage fee applied to proceeds derived from protocol actions. For example, if this is set to 0.5% (500) and
  // an asset owner has charged 1 ETH for a delegation this will be a charge of 0.005 ETH. Note that this is charged in
  // addition to the base fee. This is important, as the base fee is all the protocol will take for fee free transactions,
  // and some revenue is required to maintain the service.
  uint32 public delegationFeePercentage;

  // The string descriptions associated with the default rights codes. Only position 1 to 12 will be used, but full length
  // provided here for future flexiblity
  string[16] public defaultRightsCodes;

  // Lock for delegation container address
  bool public delegationContainerTemplateLocked;

  struct DelegationRecord {
    // The unique identifier for every delegation. Note that this is stamped on each delegation container. This doesn't mean
    // that every delegation Id will make it to the register, as this might be a proposed delegation that is not taken
    // up by anyone.
    uint64 delegationId; // 64
    // The owner of the asset that is being containerised for delegation.
    address owner; // 160
    // The end time for this delegation. After the end time the owner can remove the asset.
    uint32 endTime; // 32
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
    uint24 duration; // 32
    // The fee that the delegate must pay for this delegation to go live.
    uint96 fee; // 128
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

  struct ERC20PaymentOptions {
    bool isValid;
    uint96 registerFee;
  }

  // The address of the delegation container template.
  address payable public delegationContainer;

  // Map a tokenContract and Id to a delegation record.
  // bytes32 mapping for this is tokenContract and tokenId
  mapping(bytes32 => DelegationRecord) public tokenToDelegationRecord;

  // Map a token contract and query address to a balance struct:
  // bytes32 mapping for this is tokenContract and address being queried
  mapping(bytes32 => uint256) public contractToBalanceByRights;

  // Map a deployed container contract to a delegation record.
  mapping(address => uint64) public containerToDelegationId;

  // Map a token contract to a listing of contract specific rights codes:
  mapping(address => string[16]) public tokenContractToRightsCodes;

  // Map collection offer ID to offer:
  mapping(uint64 => Offer) public offerIdToOfferDetails;

  // Store offer ERC20 payment options, the returned value if the base fee for that ERC20
  mapping(address => ERC20PaymentOptions) public validERC20PaymentOption;

  /**
   *
   * @dev Constructor
   *
   */
  constructor(
    uint96 delegationRegisterFee_,
    uint32 delegationFeePercentage_,
    address weth_
  ) {
    delegationRegisterFee = delegationRegisterFee_;
    delegationFeePercentage = delegationFeePercentage_;
    weth = weth_;
  }

  // ============================
  // GETTERS
  // ============================

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

  // ============================
  // SETTERS
  // ============================

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
   * @dev setDefaultRightsCodes: set the string description for the 12 defauls rights codes. Note this is for information only - these strings are
   * not used in the contract for any purpose.
   */
  function setDefaultRightsCodes(
    uint256 rightsIndex_,
    string memory rightsDescription_
  ) public onlyOwner {
    require(rightsIndex_ > 0 && rightsIndex_ < 16, "");
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
    require(rightsIndex_ > 0 && rightsIndex_ < 16, "");
    tokenContractToRightsCodes[tokenContract_][
      rightsIndex_
    ] = rightsDescription_;
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
    require(delegationContainer != address(0), "");
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
    require(!delegationContainerTemplateLocked, "");
    delegationContainer = delegationContainer_;
  }

  // ============================
  // IMPLEMENTATION
  // ============================

  /**
   * @dev Throws if this is not a valid container, returnds delegation Id if it's valid.
   */
  function isValidContainer(address container_)
    public
    view
    returns (uint64 recordId_)
  {
    recordId_ = containerToDelegationId[container_];

    require(recordId_ != 0, "Invalid container");

    return (recordId_);
  }

  /**
   *
   * @dev acceptOfferToExistingContainer: Perform acceptance processing where the user is
   * ending a delegation and accepting an offer.
   *
   */
  function acceptOfferToExistingContainer(
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
    // Check this is a valid call from a delegationContainer:
    isValidContainer(msg.sender);

    _offerAccepted(
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
      tokenContract_
    );

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_
    );

    _moveContainerToNewDelegationId(msg.sender, keyHash);

    _updateDelegationRecordDetails(
      keyHash,
      uint32(block.timestamp) + (duration_ * 1 days),
      newDelegate_,
      delegateRightsInteger_
    );

    bytes32 newDelegateHash = keccak256(
      abi.encodePacked(tokenContract_, newDelegate_)
    );

    _increaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      (TOTAL_RIGHTS - delegateRightsInteger_)
    );

    _increaseRightsInteger(
      msg.sender,
      newDelegate_,
      tokenContract_,
      tokenId_,
      newDelegateHash,
      delegateRightsInteger_
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
    uint256 tokenId_
  ) internal returns (bytes32 keyHash_, bytes32 ownerHash_) {
    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getHashes(
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

    return (keyHash, ownerHash);
  }

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
   * @dev _moveContainerToNewDelegationId: move container to new delegation id
   *
   */
  function _moveContainerToNewDelegationId(address container_, bytes32 keyHash_)
    internal
  {
    _assignDelegationId(container_);

    tokenToDelegationRecord[keyHash_].delegationId = delegationId;
  }

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
   * @dev _updateDelegationRecordDetails: common processing for delegation record updates
   *
   */
  function _updateDelegationRecordDetails(
    bytes32 keyHash_,
    uint32 endTime_,
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
   * @dev _createDelegationFromOffer: call when an offer is being accepted on ERC721 receive
   *
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
      uint32(block.timestamp) + (delegationData_.duration * 1 days),
      delegationData_.delegate,
      delegationData_.delegateRightsInteger,
      keyHash_
    );

    bytes32 delegateHash = keccak256(
      abi.encodePacked(tokenContract_, delegationData_.delegate)
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
      delegateHash,
      delegationData_.delegateRightsInteger
    );

    emit DelegationAccepted(
      delegationData_.provider,
      delegationId,
      tokenContract_,
      tokenId_,
      owner_,
      delegationData_.delegate,
      uint32(block.timestamp) + (delegationData_.duration * 1 days),
      delegationData_.delegateRightsInteger
    );
  }

  /**
   *
   * @dev _createDelegationFromOffer: call when an offer is being accepted on ERC721 receive
   *
   */
  function _createDelegation(
    address owner_,
    uint32 endTime_,
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
      revert("Invalid offer");
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

      require(validERC20PaymentOption[paymentERC20Address].isValid, "");

      registerFee = validERC20PaymentOption[paymentERC20Address].registerFee;
    }

    // Transfer payment amount from the delegate:

    // Cancel the offer as it is being actioned
    delete offerIdToOfferDetails[delegationData_.offerId];

    // Claim payment from the offerer:
    IERC20(paymentERC20Address).transferFrom(
      delegationData_.delegate,
      address(this),
      (delegationData_.fee + registerFee)
    );

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
      IERC20(paymentERC20Address).transfer(
        owner_,
        ((delegationData_.fee + registerFee) - epsFee)
      );
    }

    emit OfferAccepted(delegationData_.provider, delegationData_.offerId);
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
    require(from_ != address(0), "No minting");

    address tokenContract = msg.sender;

    // Decode the delegation parameters from the data_ passed in:
    DelegationParameters memory delegationData = abi.decode(
      data_,
      (DelegationParameters)
    );

    // Check that we have been passed valid rights details for the owner and the beneficiary.
    require(
      delegationData.ownerRightsInteger +
        delegationData.delegateRightsInteger ==
        TOTAL_RIGHTS,
      "Invalid rights"
    );

    // Cannot assign the current owner as the delegate:
    require(delegationData.delegate != from_, "Owner cannot be delegate");

    // Create the container contract:
    address newDelegationContainer = delegationContainer.clone();

    // Assign the container a delegation Id
    _assignDelegationId(newDelegationContainer);

    emit DelegationCreated(
      delegationData.provider,
      delegationId,
      newDelegationContainer,
      from_,
      delegationData.delegate,
      delegationData.fee,
      delegationData.duration,
      tokenContract,
      tokenId_,
      delegationData.delegateRightsInteger
    );

    bytes32 keyHash = keccak256(abi.encodePacked(tokenContract, tokenId_));

    bytes32 ownerHash = keccak256(abi.encodePacked(tokenContract, from_));

    // If this was accepting an offer we save a full delegation record now:
    if (delegationData.offerId != 0) {
      _createDelegationFromOffer(
        delegationData,
        tokenId_,
        from_,
        keyHash,
        ownerHash,
        tokenContract,
        newDelegationContainer
      );
    } else {
      _createDelegation(from_, 0, address(0), 0, keyHash);

      _increaseRightsInteger(
        newDelegationContainer,
        from_,
        tokenContract,
        tokenId_,
        ownerHash,
        TOTAL_RIGHTS
      );
    }

    // Initialise storage data:
    IDelegationContainer(newDelegationContainer).initialiseDelegationContainer(
      payable(from_),
      payable(delegationData.delegate),
      delegationData.fee,
      delegationData.duration,
      msg.sender,
      tokenId_,
      delegationData.delegateRightsInteger,
      delegationData.URI,
      delegationData.offerId
    );

    // Deliver the ERC721 to the container:
    IERC721(msg.sender).safeTransferFrom(
      address(this),
      newDelegationContainer,
      tokenId_
    );

    return this.onERC721Received.selector;
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
    uint32 endTime_,
    uint256 delegateRightsInteger_
  ) external payable {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash, bytes32 delegateHash) = _getHashes(
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

    emit DelegationAccepted(
      provider_,
      recordId,
      tokenContract_,
      tokenId_,
      owner_,
      delegate_,
      endTime_,
      delegateRightsInteger_
    );
  }

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
   * @dev changeAssetOwner: Change the owner of the container on sale.
   *
   */
  function changeAssetOwner(
    uint64 provider_,
    address newOwner_,
    address tokenContract_,
    uint256 tokenId_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    bytes32 keyHash = keccak256(abi.encodePacked(tokenContract_, tokenId_));

    // Save the old owner:
    address oldOwner = tokenToDelegationRecord[keyHash].owner;

    // This has been called from a container, and that method is assetOwner only. Procced to
    // update the register accordingly:

    // Update owner:
    tokenToDelegationRecord[keyHash].owner = newOwner_;

    // Get hashes for new and old owner:
    bytes32 oldOwnerHash = keccak256(
      abi.encodePacked(tokenContract_, oldOwner)
    );
    bytes32 newOwnerHash = keccak256(
      abi.encodePacked(tokenContract_, newOwner_)
    );

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

    emit DelegationOwnerChanged(provider_, recordId);
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
    uint256 tokenId_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    bytes32 keyHash = keccak256(abi.encodePacked(tokenContract_, tokenId_));

    // Save the old delegate:
    address oldDelegate = tokenToDelegationRecord[keyHash].delegate;

    // This has been called from a container, and that method is delegate only. Procced to
    // update the register accordingly:

    // Update delegate:
    tokenToDelegationRecord[keyHash].delegate = newDelegate_;

    // Get hashes for new and old delegate:
    bytes32 oldDelegateHash = keccak256(
      abi.encodePacked(tokenContract_, oldDelegate)
    );
    bytes32 newDelegateHash = keccak256(
      abi.encodePacked(tokenContract_, newDelegate_)
    );

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

    emit DelegationOwnerChanged(provider_, recordId);
  }

  /**
   *
   * @dev deleteEntry: remove a completed entry from the register.
   *
   */
  function deleteEntry(
    uint64 provider_,
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
      tokenId_
    );

    // Delete the register entry and owner and delegate data:
    delete tokenToDelegationRecord[keyHash];
    delete containerToDelegationId[msg.sender];

    emit DelegationDeleted(provider_, recordId);
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
    uint256 delegateRightsInteger_
  ) external {
    // Check this is a valid call from a delegationContainer:
    uint64 recordId = isValidContainer(msg.sender);

    (bytes32 keyHash, bytes32 ownerHash) = _adjustBalancesAtEndOfDelegation(
      tokenContract_,
      msg.sender,
      owner_,
      oldDelegate_,
      tokenId_
    );

    _moveContainerToNewDelegationId(msg.sender, keyHash);

    _updateDelegationRecordDetails(keyHash, 0, address(0), 0);

    _increaseRightsInteger(
      msg.sender,
      owner_,
      tokenContract_,
      tokenId_,
      ownerHash,
      TOTAL_RIGHTS
    );

    emit DelegationContainerRelisted(
      provider_,
      msg.sender,
      recordId,
      delegationId
    );

    emit DelegationCreated(
      provider_,
      recordId,
      msg.sender,
      owner_,
      newDelegate_,
      fee_,
      durationInDays_,
      tokenContract_,
      tokenId_,
      delegateRightsInteger_
    );
  }

  /**
   *
   * @dev _getHashes: get the hashes for tracking owner and delegate
   *
   */
  function _getHashes(
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
    keyHash_ = keccak256(abi.encodePacked(tokenContract_, tokenId_));

    // Make the hash for both the owner and the delegate:
    ownerHash_ = keccak256(abi.encodePacked(tokenContract_, owner_));

    delegateHash_ = keccak256(abi.encodePacked(tokenContract_, delegate_));

    return (keyHash_, ownerHash_, delegateHash_);
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
    bytes32 queryHash = keccak256(
      abi.encodePacked(tokenContract_, queryAddress_)
    );

    return (
      _sliceRightsInteger(rightsIndex_, contractToBalanceByRights[queryHash])
    );
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
   * @dev getBeneficiaryByRight: Get beneficiary by rights
   *
   */
  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) public view returns (address) {
    bytes32 keyHash = keccak256(abi.encodePacked(tokenContract_, tokenId_));

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
    require(
      offerERC20_ == address(0) || validERC20PaymentOption[offerERC20_].isValid,
      "invalid token"
    );

    // Increment offer id
    collectionOfferId += 1;

    offerIdToOfferDetails[collectionOfferId] = Offer(
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
    _updateOfferExpiry(provider_, offerId_, 0);
  }

  /**
   *
   * @dev changeOfferExpiry: change expiry of an offer.
   *
   */
  function changeOfferExpiry(
    uint64 provider_,
    uint64 offerId_,
    uint32 newExpiry_
  ) external {
    _updateOfferExpiry(provider_, offerId_, newExpiry_);
  }

  /**
   *
   * @dev _updateOfferExpiry: update the expiry date on an offer.
   *
   */
  function _updateOfferExpiry(
    uint64 provider_,
    uint64 offerId_,
    uint32 newExpiry_
  ) internal {
    require(
      msg.sender == offerIdToOfferDetails[offerId_].offerMaker,
      "Not offerer"
    );

    offerIdToOfferDetails[offerId_].expiry = newExpiry_;

    emit OfferExpiryChanged(provider_, offerId_, newExpiry_);
  }
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSProxyRegister {
  // ======================================================
  // ENUMS
  // ======================================================
  // enum for available proxy statuses
  enum ProxyStatus {
    none,
    pendingAcceptance,
    pendingPayment,
    live
  }

  // enum for participant
  enum Participant {
    hot,
    cold
  }

  // ======================================================
  // STRUCTS
  // ======================================================

  // Full proxy record
  struct Record {
    // Slot 1: 64 + 8 + 8 + 160 = 240
    uint64 provider;
    ProxyStatus status;
    bool feePaid;
    address cold;
    // Slot 2: 160
    address delivery;
  }

  // ======================================================
  // EVENTS
  // ======================================================

  // Emitted when an hot address nominates a cold address:
  event NominationMade(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint256 provider
  );

  // Emitted when a cold accepts a nomination from a hot address:
  event NominationAccepted(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint64 indexed provider
  );

  // Emitted when a proxy goes live
  event ProxyRecordLive(
    address indexed hot,
    address indexed cold,
    address delivery,
    uint64 indexed provider
  );

  // Emitted when the delivery address is updated on a record:
  event DeliveryUpdated(
    address indexed hot,
    address indexed cold,
    address indexed delivery,
    address oldDelivery,
    uint256 provider
  );

  // Emitted when a register record is deleted. initiator 0 = cold, 1 = hot:
  event RecordDeleted(
    Participant initiator,
    address indexed hot,
    address indexed cold,
    uint256 provider
  );

  // ======================================================
  // ERRORS
  // ======================================================

  error NoPaymentPendingForAddress();
  error NoRecordFoundForAddress();
  error OnlyHotAddressCanChangeAddress();

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev Return if a cold wallet is live
   */
  function coldIsLive(address cold_) external view returns (bool);

  /**
   * @dev Return if a hot wallet is live
   */
  function hotIsLive(address hot_) external view returns (bool);

  /**
   * @dev Get proxy details for a hot address
   */
  function getProxyRecordForHot(address hot_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Get proxy details for a cold address
   */
  function getProxyRecordForCold(address cold_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Get proxy details for a cold address
   */
  function getProxyRecordForAddress(address queryAddress_)
    external
    view
    returns (
      ProxyStatus status,
      address hot,
      address cold,
      address delivery,
      uint64 provider_,
      bool feePaid
    );

  /**
   * @dev Returns the current role of a given address
   */
  // function getRole(address roleAddress_) external view returns (Role);

  // ======================================================
  // LIFECYCLE - NOMINATION
  // ======================================================

  /**
   * @dev nominate: Hot Nominates cold, direct contract call
   */
  function nominate(
    address cold_,
    address delivery_,
    uint64 provider_
  ) external payable;

  /**
   * @dev acceptNomination: Cold accepts nomination, direct contract call
   * (though it is anticipated that most will use an ERC20 transfer)
   */
  function acceptNomination(address hot_, uint64 provider_) external payable;

  // ======================================================
  // LIFECYCLE - CHANGING DELIVERY ADDRESS
  // ======================================================

  /**
   * @dev updateDeliveryAddress: Change delivery address on an existing proxy record.
   */
  function updateDeliveryAddress(address delivery_, uint256 provider_) external;

  // ======================================================
  // LIFECYCLE - DELETING A RECORD
  // ======================================================

  /**
   * @dev deleteRecord: Delete a proxy record, if found
   */
  function deleteRecord(uint256 provider_) external;

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================

  /**
   * @dev setRegisterFee: set the fee for accepting a registration:
   */
  function setRegisterFee(uint256 registerFee_) external;

  /**
   * @dev setDeletionNominalEth: set the nominal ETH transfer that represents an address ending a proxy
   */
  function setDeletionNominalEth(uint256 deleteNominalEth_) external;
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
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

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
    address tokenContract_,
    uint256 tokenId_,
    address owner_,
    address delegate_,
    uint32 endTime_,
    uint256 delegateRightsInteger_
  );

  // Emitted when the delegation is deleted:
  event DelegationDeleted(uint64 indexed provider, uint64 indexed delegationId);

  // Emitted when the delegation owner changed:
  event DelegationOwnerChanged(
    uint64 indexed provider,
    uint64 indexed delegationId
  );

  event DelegationContainerRelisted(
    uint64 provider,
    address container,
    uint64 oldId,
    uint64 newId
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

  event OfferExpiryChanged(uint64 provider, uint64 offerId, uint32 offerExpiry);

  event TransferRights(
    address indexed from,
    address indexed to,
    address indexed tokenContract,
    uint256 tokenId,
    uint256 rightsInteger
  );

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
    uint32 endTime_,
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
    uint64 provider_,
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

  function acceptOfferToExistingContainer(
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
}

// SPDX-License-Identifier: MIT
// EPSP Contracts v2.0.0

pragma solidity 0.8.16;

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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