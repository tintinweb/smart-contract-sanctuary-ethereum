// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "./IERC721DelegateRegister.sol";
import "./IERC1155DelegateRegister.sol";
import "./IERC20DelegateRegister.sol";
import "./ProxyRegister.sol";
import "./ENSReverseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *
 * @dev The EPS Register contract, implementing the proxy and deligate registers
 *
 */
contract EPSRegister is ProxyRegister {
  using SafeERC20 for IERC20;

  struct MigratedRecord {
    address hot;
    address cold;
    address delivery;
  }

  // Record migration complete:
  bool public migrationComplete;

  ENSReverseRegistrar public ensReverseRegistrar;

  // EPS treasury address:
  address public treasury;

  // EPS ERC721 delegation register
  IERC721DelegateRegister public erc721DelegationRegister;
  bool public erc721DelegationRegisterAddressLocked;

  // EPS ERC1155 delegation register
  IERC1155DelegateRegister public erc1155DelegationRegister;
  bool public erc1155DelegationRegisterAddressLocked;

  // EPS ERC20 delegation register
  IERC20DelegateRegister public erc20DelegationRegister;
  bool public erc20DelegationRegisterAddressLocked;

  // Count of active ETH addresses for total supply
  uint256 public activeEthAddresses = 1;

  // 'Air drop' of EPSAPI to every address
  uint256 public epsAPIBalance = 10000 * (10**decimals());

  error ColdWalletCannotInteractUseHot();
  error EthWithdrawFailed();
  error UnknownAmount();
  error RegisterAddressLocked();
  error MigrationIsAllowedOnceOnly();

  event ERC20FeeUpdated(address erc20, uint256 erc20Fee_);
  event MigrationComplete();
  event Transfer(address indexed from, address indexed to, uint256 value);
  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  /**
   * @dev Constructor - change ownership
   */
  constructor() {
    _transferOwnership(0x9F0773aF2b1d3f7cC7030304548A823B4E6b13bB);
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev beneficiaryOf: Returns the beneficiary of the `tokenId` token for an ERC721
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

    beneficiary_ = erc721DelegationRegister.getBeneficiaryByRight(
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
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance for an ERC721
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc721DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc721DelegationRegister.getBalanceByRight(
      tokenContract_,
      queryAddress_,
      rightsIndex_
    );

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
    uint256 id_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc1155DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc1155DelegationRegister.getBalanceByRight(
      tokenContract_,
      id_,
      queryAddress_,
      rightsIndex_
    );

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
   * @dev beneficiaryBalanceOf20: Returns the beneficiary balance for an ERC20 or ERC777
   */
  function beneficiaryBalanceOf20(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc20DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc20DelegationRegister.getBalanceByRight(
      tokenContract_,
      queryAddress_,
      rightsIndex_
    );

    // 3 Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC20(tokenContract_).balanceOf(queryAddress_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC20(tokenContract_).balanceOf(cold);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC20(tokenContract_).balanceOf(queryAddress_);
      }
    }
  }

  /**
   * @dev getAddresses721: Returns the register addresses for the passed address and rights index for ERC721
   *
     Possible scenarios are:
   
      1) The receivedAddress_ is NOT on the proxy register and is NOT on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
          - the receivedAddress_ as the delivery address
   
      2) The receivedAddress_ is a HOT address on the proxy register and is NOT on the delegate register
         In this instance the return values will be:
          - proxyAddresses_:
            - The receivedAddress_ at index 0
            - The COLD address at index 1
          - DELIVERY address as the delivery address

      3) The receivedAddress_ is a COLD address on the proxy register (whether it  has entries on the 
           delegate register or not)
          - proxyAddresses_:
            - NOTHING (i.e. empty array)
          - the receivedAddress_ as the delivery address 

      4) The receivedAddress_ is NOT on the proxy register BUT it DOES have entries on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
            - The delegate register entries at index 1 to n
          - the receivedAddress_ as the delivery address

      5) The receivedAddress_ IS on the proxy register AND has entries on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
            - The COLD address at index 1
            - The delegate register entries at index 2 to n
           - DELIVERY address as the delivery address

      Some points to note:
        * Index 0 in the returned address array will ALWAYS be the receivedAddress_ address UNLESS it's the address
          is a COLD wallet, in which case the array is empty. This enforces that a COLD wallet has no
          rights in its own right WITHOUT us needing to revert and have the caller handle the situation
        * Therefore if you wish to IGNORE the hot address, start any iteration over the returned list from index 1
          onwards. Index 1 (if it exists) will always either be the COLD address or the first entry from the delegate register.

   *
   */
  function getAddresses721(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc721DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAddresses1155: Returns the register addresses for the passed address and rights index for ERC1155
   *
   */
  function getAddresses1155(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc1155DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAddresses20: Returns the register addresses for the passed address and rights index for ERC20 and 777
   *
   */
  function getAddresses20(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc20DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAllAddresses: Returns ALL register addresses for the passed address and rights index
   *
   */
  function getAllAddresses(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (
      address[] memory erc721Addresses_,
      address[] memory erc1155Addresses_,
      address[] memory erc20Addresses_,
      address delivery_
    )
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (
        erc721Addresses_,
        erc1155Addresses_,
        erc20Addresses_,
        receivedAddress_
      );
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    if (
      address(erc721DelegationRegister) == address(0) &&
      address(erc1155DelegationRegister) == address(0) &&
      address(erc20DelegationRegister) == address(0)
    ) {
      // This is unexpected, but theoretically possible. In this case, return
      // the base addresses in the first return array:
      uint256 addIndexes;
      if (cold != address(0)) {
        addIndexes = 2;
      } else {
        addIndexes = 1;
      }

      address[] memory baseAddresses = new address[](addIndexes);

      baseAddresses[0] = receivedAddress_;
      if (cold != address(0)) {
        baseAddresses[1] = cold;
      }
      return (baseAddresses, erc1155Addresses_, erc20Addresses_, delivery_);
    } else {
      bool includeBaseAddresses = true;

      if (address(erc721DelegationRegister) != address(0)) {
        erc721Addresses_ = erc721DelegationRegister
          .getAllAddressesByRightsIndex(
            receivedAddress_,
            rightsIndex_,
            cold,
            includeBaseAddresses
          );
        includeBaseAddresses = false;
      }

      if (address(erc1155DelegationRegister) != address(0)) {
        erc1155Addresses_ = erc1155DelegationRegister
          .getAllAddressesByRightsIndex(
            receivedAddress_,
            rightsIndex_,
            cold,
            includeBaseAddresses
          );
        includeBaseAddresses = false;
      }

      if (address(erc20DelegationRegister) != address(0)) {
        erc20Addresses_ = erc20DelegationRegister.getAllAddressesByRightsIndex(
          receivedAddress_,
          rightsIndex_,
          cold,
          includeBaseAddresses
        );
        includeBaseAddresses = false;
      }
    }
    return (erc721Addresses_, erc1155Addresses_, erc20Addresses_, delivery_);
  }

  /**
   * @dev getColdAndDeliveryAddresses: Returns the register address details (cold and delivery address) for a passed hot address
   */
  function getColdAndDeliveryAddresses(address _receivedAddress)
    public
    view
    returns (
      address cold,
      address delivery,
      bool isProxied
    )
  {
    if (coldIsLive(_receivedAddress)) revert ColdWalletCannotInteractUseHot();

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

  /**
   *
   * @dev setRewardToken
   *
   */
  function setRewardToken(address rewardToken_) external onlyOwner {
    rewardToken = IOAT(rewardToken_);
    emit RewardTokenUpdated(rewardToken_);
  }

  /**
   *
   * @dev setRewardRate
   *
   */
  function setRewardRate(uint88 rewardRate_) external onlyOwner {
    if (rewardRateLocked) {
      revert RewardRateIsLocked();
    }
    rewardRate = rewardRate_;
    emit RewardRateUpdated(rewardRate_);
  }

  /**
   *
   * @dev lockRewardRate
   *
   */
  function lockRewardRate() external onlyOwner {
    rewardRateLocked = true;
    emit RewardRateLocked();
  }

  /**
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   */
  function setENSName(string memory ensName_) external onlyOwner {
    ensReverseRegistrar.setName(ensName_);
  }

  /**
   * @dev setTreasuryAddress: set the treasury address:
   */
  function setTreasuryAddress(address treasuryAddress_) public onlyOwner {
    treasury = treasuryAddress_;
  }

  /**
   * @dev setERC721DelegationRegister: set the delegation register address:
   */
  function setERC721DelegationRegister(address erc721DelegationRegister_)
    public
    onlyOwner
  {
    if (erc721DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc721DelegationRegister = IERC721DelegateRegister(
      erc721DelegationRegister_
    );
  }

  /**
   * @dev lockERC721DelegationRegisterAddress
   */
  function lockERC721DelegationRegisterAddress() public onlyOwner {
    erc721DelegationRegisterAddressLocked = true;
  }

  /**
   * @dev setERC1155DelegationRegister: set the delegation register address:
   */
  function setERC1155DelegationRegister(address erc1155DelegationRegister_)
    public
    onlyOwner
  {
    if (erc1155DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc1155DelegationRegister = IERC1155DelegateRegister(
      erc1155DelegationRegister_
    );
  }

  /**
   * @dev lockERC1155DelegationRegisterAddress
   */
  function lockERC1155DelegationRegisterAddress() public onlyOwner {
    erc1155DelegationRegisterAddressLocked = true;
  }

  /**
   * @dev setERC20DelegationRegister: set the delegation register address:
   */
  function setERC20DelegationRegister(address erc20DelegationRegister_)
    public
    onlyOwner
  {
    if (erc20DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc20DelegationRegister = IERC20DelegateRegister(erc20DelegationRegister_);
  }

  /**
   * @dev lockERC20DelegationRegisterAddress
   */
  function lockERC20DelegationRegisterAddress() public onlyOwner {
    erc20DelegationRegisterAddressLocked = true;
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

    if (!success) revert EthWithdrawFailed();
  }

  /**
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(treasury, amount_);
  }

  /**
   * @dev rescueERC20: Allow any ERC20s to be rescued. Note, this is provided to enable the
   * withdrawal assets sent here in error. ERC20 fee payments are withdrawn to the treasury.
   * in withDrawERC1155
   */
  function rescueERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(owner(), amount_);
  }

  /**
   * @dev rescueERC721: Allow any ERC721s to be rescued. Note, all delegated ERC721s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function rescueERC721(IERC721 token_, uint256 tokenId_) external onlyOwner {
    token_.transferFrom(address(this), owner(), tokenId_);
  }

  /**
   * @dev rescueERC1155: Allow any ERC1155s to be rescued. Note, all delegated ERC1155s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function rescueERC1155(IERC1155 token_, uint256 tokenId_) external onlyOwner {
    token_.safeTransferFrom(
      address(this),
      owner(),
      tokenId_,
      token_.balanceOf(address(this), tokenId_),
      ""
    );
  }

  /**
   *
   * @dev setERC20Fee
   *
   */
  function setERC20Fee(address erc20_, uint256 erc20Fee_) external onlyOwner {
    erc20PerTransactionFee[erc20_] = erc20Fee_;
    emit ERC20FeeUpdated(erc20_, erc20Fee_);
  }

  /**
   *
   * @dev setENSReverseRegistrar
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_)
    external
    onlyOwner
  {
    ensReverseRegistrar = ENSReverseRegistrar(ensReverseRegistrar_);
    emit ENSReverseRegistrarSet(ensReverseRegistrar_);
  }

  /**
   * @dev One-off migration routine to bring in register details from a previous version
   */
  function migration(MigratedRecord[] memory migratedRecords_)
    external
    onlyOwner
  {
    if (migrationComplete) {
      revert MigrationIsAllowedOnceOnly();
    }

    for (uint256 i = 0; i < migratedRecords_.length; ) {
      MigratedRecord memory currentRecord = migratedRecords_[i];

      _processNomination(
        currentRecord.hot,
        currentRecord.cold,
        currentRecord.delivery,
        true,
        0
      );

      _acceptNomination(currentRecord.hot, currentRecord.cold, 0, 0);

      unchecked {
        i++;
      }
    }

    migrationComplete = true;

    emit MigrationComplete();
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
    if (
      msg.value != proxyRegisterFee &&
      msg.value != deletionNominalEth &&
      erc721DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      erc1155DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      erc20DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      msg.sender != owner()
    ) revert UnknownAmount();

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
    if (hotToRecord[from_].status == ProxyStatus.PendingPayment) {
      _recordLive(
        from_,
        hotToRecord[from_].cold,
        hotToRecord[from_].delivery,
        hotToRecord[from_].provider
      );
    } else if (
      // 2) If our from address is a cold address and the proxy is pending payment we
      // can record this as paid and put the record live:
      hotToRecord[coldToHot[from_]].status == ProxyStatus.PendingPayment
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

    emit Transfer(msg.sender, to, 0);

    return (true);
  }
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
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

abstract contract ENSReverseRegistrar {
  function setName(string memory name) public virtual returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEPSProxyRegister.sol";
import "./IOAT.sol";
import "./IERCOmnReceiver.sol";

/**
 *
 * @dev The EPS Proxy Register contract. This contract implements a trustless proof of proxy between
 * two addresses, allowing the hot address to operate with the same rights as a cold address, and
 * for new assets to be delivered to a configurable delivery address.
 *
 */
contract ProxyRegister is IEPSProxyRegister, IERCOmnReceiver, Ownable {
  // ======================================================
  // CONSTANTS
  // ======================================================

  // Constants denoting the API access types:
  uint256 constant HOT_NOMINATE_COLD = 1;
  uint256 constant COLD_ACCEPT_HOT = 2;
  uint256 constant CHANGE_DELIVERY = 3;
  uint256 constant DELETE_RECORD = 4;

  // ======================================================
  // STORAGE
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

  // Reward token details:
  IOAT public rewardToken;
  uint88 public rewardRate;
  bool public rewardRateLocked;

  // ======================================================
  // MAPPINGS
  // ======================================================

  // Mapping between the hot wallet and the proxy record, the proxy record holding all the details of
  // the proxy relationship
  mapping(address => Record) public hotToRecord;

  // Mapping from a cold address to the associated hot address
  mapping(address => address) public coldToHot;

  mapping(address => uint256) public erc20PerTransactionFee;

  /**
   * @dev Constructor - nothing required
   */
  constructor() {}

  // ======================================================
  // VIEW METHODS
  // ======================================================

  function decimals() public pure returns (uint8) {
    return 18;
  }

  /**
   * @dev isValidAddresses: Check the validity of sent addresses
   */
  function isValidAddresses(
    address hot_,
    address cold_,
    address delivery_
  ) public pure {
    if (cold_ == address(0)) revert ColdIsAddressZero();
    if (cold_ == hot_) revert ColdAddressCannotBeTheSameAsHot();
    if (delivery_ == address(0)) revert DeliveryIsAddressZero();
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
      currentStatus == ProxyStatus.Live ||
      currentStatus == ProxyStatus.PendingPayment ||
      // Cold addresses CAN be pending acceptance as many times as they like,
      // in fact it is vital that they can be, so we only check this for the hot
      // address:
      (checkingHot_ && currentStatus == ProxyStatus.PendingAcceptance)
    ) {
      return false;
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.Live ||
      currentStatus == ProxyStatus.PendingPayment ||
      // Neither cold or hot can be a hot address, at any status
      currentStatus == ProxyStatus.PendingAcceptance
    ) {
      return false;
    }

    return true;
  }

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) public view returns (bool) {
    return (hotToRecord[coldToHot[cold_]].status == ProxyStatus.Live);
  }

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) public view returns (bool) {
    return (hotToRecord[hot_].status == ProxyStatus.Live);
  }

  /**
   * @dev coldIsActiveOnRegister: Return if a cold wallet is active
   */
  function coldIsActiveOnRegister(address cold_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[coldToHot[cold_]].status;
    return (currentStatus == ProxyStatus.Live ||
      currentStatus == ProxyStatus.PendingPayment);
  }

  /**
   * @dev hotIsActiveOnRegister: Return if a hot wallet is active
   */
  function hotIsActiveOnRegister(address hot_) public view returns (bool) {
    ProxyStatus currentStatus = hotToRecord[hot_].status;
    return (currentStatus != ProxyStatus.None);
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
      currentStatus == ProxyStatus.Live ||
      currentStatus == ProxyStatus.PendingPayment ||
      (currentStatus == ProxyStatus.PendingAcceptance)
    ) {
      return getProxyRecordForCold(queryAddress_);
    }

    // Check as hot:
    currentStatus = hotToRecord[queryAddress_].status;

    if (
      currentStatus == ProxyStatus.Live ||
      currentStatus == ProxyStatus.PendingPayment ||
      (currentStatus == ProxyStatus.PendingAcceptance)
    ) {
      return (getProxyRecordForHot(queryAddress_));
    }

    // Address not found
    return (ProxyStatus.None, address(0), address(0), address(0), 0, false);
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
    if (msg.value != proxyRegisterFee) revert IncorrectProxyRegisterFee();
    _processNomination(
      msg.sender,
      cold_,
      delivery_,
      msg.value == proxyRegisterFee,
      provider_
    );
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
    bool feePaid_,
    uint64 provider_
  ) internal {
    isValidAddresses(hot_, cold_, delivery_);

    if (!addressIsAvailable(hot_, true) || !addressIsAvailable(cold_, false))
      revert AlreadyProxied();

    // Record the mapping from the hot address to the record. This is pending until accepted by the cold address.
    hotToRecord[hot_] = Record(
      provider_,
      ProxyStatus.PendingAcceptance,
      feePaid_,
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

    if (!hotToRecord[hot_].feePaid && msg.value != proxyRegisterFee)
      revert ProxyRegisterFeeRequired();

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

    if (
      hotToRecord[hot_].cold != cold_ ||
      hotToRecord[hot_].status != ProxyStatus.PendingAcceptance
    ) revert AddressMismatch();

    // Check that the cold address isn't live or pending payment anywhere on the register:
    if (!addressIsAvailable(cold_, false)) revert AlreadyProxied();
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
      hotToRecord[hot_].status = ProxyStatus.PendingPayment;
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
    hotToRecord[hot_].status = ProxyStatus.Live;

    if (address(rewardToken) != address(0)) {
      _performReward(delivery_);
    }

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
    if (delivery_ == address(0)) revert DeliveryCannotBeTheZeroAddress();

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
        Participant.Hot,
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
        Participant.Cold,
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

    // All processing is on whole amounts, no decimals

    uint256 actionCode = (amount_ / 10**decimals()) % 10;

    if (actionCode == 0 || actionCode > 4) revert UnrecognisedEPSAPIAmount();

    uint64 providerCode = uint64((amount_ / 10**decimals()) / 10);

    if (actionCode == HOT_NOMINATE_COLD)
      _processNomination(
        from_,
        to_,
        from_,
        proxyRegisterFee == 0,
        providerCode
      );
    else if (actionCode == COLD_ACCEPT_HOT) {
      _acceptNominationValidation(to_, from_);
      _acceptNomination(to_, from_, 0, providerCode);
    } else if (actionCode == CHANGE_DELIVERY)
      _updateDeliveryAddress(from_, to_, providerCode);
    else if (actionCode == DELETE_RECORD) _deleteRecord(from_, providerCode);
  }

  /**
   *
   * @dev _performReward: mint reward tokens.
   *
   */
  function _performReward(address account) internal {
    rewardToken.emitToken(account, rewardRate);
  }

  /**
   *
   * @dev onTokenTransfer: call relayed via an ERCOmni payable token type.
   *
   */
  function onTokenTransfer(
    address sender_,
    uint256 erc20Value_,
    bytes memory data_
  ) external payable {
    // Check valid token relay origin:
    uint256 erc20Fee = erc20PerTransactionFee[msg.sender];
    require(erc20Fee != 0, "Invalid ERC20");

    // Decode instructions:
    (address cold, address delivery, uint64 provider) = abi.decode(
      data_,
      (address, address, uint64)
    );

    if (erc20Value_ != erc20Fee) revert IncorrectProxyRegisterFee();
    _processNomination(sender_, cold, delivery, true, provider);
  }
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS ERC20 Delegation register interface.
 *
 */
interface IERC20DelegateRegister {
  function getBeneficiaryByRight(address tokenContract_, uint256 rightsIndex_)
    external
    view
    returns (address);

  function getBalanceByRight(
    address tokenContract_,
    address queryAddress_,
    uint256 rightsIndex_
  ) external view returns (uint256);

  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) external view returns (address[] memory containers_);

  function containerToDelegationId(address container_)
    external
    view
    returns (uint64 delegationId_);
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS ERC1155 Delegation register interface.
 *
 */
interface IERC1155DelegateRegister {
  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address);

  function getBalanceByRight(
    address tokenContract_,
    uint256 tokenId_,
    address queryAddress_,
    uint256 rightsIndex_
  ) external view returns (uint256);

  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) external view returns (address[] memory containers_);

  function containerToDelegationId(address container_)
    external
    view
    returns (uint64 delegationId_);
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
pragma solidity 0.8.17;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOAT.sol";

/**
 * @dev OAT interface
 */
interface IOAT is IERC20 {
  /**
   *
   * @dev emitToken
   *
   */
  function emitToken(address receiver_, uint256 amount_) external;

  /**
   *
   * @dev addEmitter
   *
   */
  function addEmitter(address emitter_) external;

  /**
   *
   * @dev removeEmitter
   *
   */
  function removeEmitter(address emitter_) external;

  /**
   *
   * @dev setTreasury
   *
   */
  function setTreasury(address treasury_) external;
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

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
    None,
    PendingAcceptance,
    PendingPayment,
    Live
  }

  // enum for participant
  enum Participant {
    Hot,
    Cold
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

  // Emitted when a hot address nominates a cold address:
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

  // Reward token events:
  event RewardTokenUpdated(address newToken);
  event RewardRateLocked();
  event RewardRateUpdated(uint96 rewardRate);

  // ======================================================
  // ERRORS
  // ======================================================

  error NoPaymentPendingForAddress();
  error NoRecordFoundForAddress();
  error OnlyHotAddressCanChangeAddress();
  error ColdIsAddressZero();
  error ColdAddressCannotBeTheSameAsHot();
  error DeliveryIsAddressZero();
  error IncorrectProxyRegisterFee();
  error AlreadyProxied();
  error ProxyRegisterFeeRequired();
  error AddressMismatch();
  error DeliveryCannotBeTheZeroAddress();
  error UnrecognisedEPSAPIAmount();
  error RewardRateIsLocked();

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
   * @dev Get proxy details for a passed address (could be hot or cold)
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