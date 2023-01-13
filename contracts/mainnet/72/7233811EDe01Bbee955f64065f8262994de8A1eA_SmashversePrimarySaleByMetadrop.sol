// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// EPS implementation
import "./EPS/IEPS_DR.sol";
// Metadrop NFT Interface
import "./INFTByMetadrop.sol";

contract SmashversePrimarySaleByMetadrop is Pausable, Ownable, IERC721Receiver {
  using Strings for uint256;

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  enum MintingType {
    publicMint,
    allowlistMint,
    mintPassMint
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PublicMintConfig {
    uint256 price;
    uint256 maxPerAddress;
    uint32 start;
    uint32 end;
  }

  struct Sublist {
    uint256 sublistInteger;
    uint256 sublistPosition;
  }

  // =======================================
  // CONFIG
  // =======================================

  // Max supply for this collection
  uint256 public immutable supply;
  // Mint price for the public mint.
  uint256 public immutable publicMintPrice;
  // Max allowance per address for public mint
  uint256 public immutable maxPublicMintPerAddress;
  // Pause cutoff
  uint256 public immutable pauseCutOffInDays;
  // Mint passes
  ERC721Burnable public immutable mintPass;

  // The merkleroot for the list
  bytes32 public listMerkleRoot;

  // Config for the list mints
  SubListConfig[] public subListConfig;

  // The NFT contract
  INFTByMetadrop public nftContract;

  uint32 public publicMintStart;
  uint32 public publicMintEnd;
  bool public publicMintingClosedForever;

  bool public listDetailsLocked;

  IEPS_DR public epsDeligateRegister;

  address public beneficiary;

  // Track the number of allowlist + public mints made as these cannot exceed the
  // set limit (4,000 at time of writing)
  uint256 public allowListPlusPublicMintCount;

  // The sublist for the allowlist that combines with the public mint in terms
  // of max supply:
  uint256 public allowlistSublistInteger;

  // Track publicMint minting allocations:
  mapping(address => uint256) public publicMintAllocationMinted;

  // Track list minting allocations:
  mapping(address => mapping(uint256 => uint256))
    public listMintAllocationMinted;

  error MintingIsClosedForever();
  error IncorrectETHPayment();
  error TransferFailed();
  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  );
  error ProofInvalid();
  error RequestingMoreThanRemainingAllocation(
    uint256 requested,
    uint256 remainingAllocation
  );
  error AddressAlreadySet();
  error IncorrectConfirmationValue();
  error InvalidAllowlistType();
  error ThisListMintIsClosed();
  error PublicMintClosed();
  error MintPassClosed();
  error RequestedQuantityExceedsSupply(uint256 requested, uint256 available);
  error InvalidPass();
  error ListDetailsLocked();

  event EPSDelegateRegisterUpdated(address epsDelegateRegisterAddress);
  event MerkleRootSet(bytes32 merkleRoot);
  event SmashMint(
    address indexed minter,
    MintingType mintType,
    uint256 subListInteger,
    uint256 quantityMinted
  );
  event SublistConfigSet(
    uint256 sublistInteger,
    uint256 start,
    uint256 end,
    uint256 supply
  );
  event AllowlistSublistIntegerSet(uint256 sublistInteger);

  constructor(
    uint256 supply_,
    PublicMintConfig memory publicMintConfig_,
    bytes32 listMerkleRoot_,
    address epsDeligateRegister_,
    uint256 pauseCutOffInDays_,
    address beneficiary_,
    address mintPass_,
    SubListConfig[] memory subListParams
  ) {
    supply = supply_;
    publicMintPrice = publicMintConfig_.price;
    maxPublicMintPerAddress = publicMintConfig_.maxPerAddress;
    listMerkleRoot = listMerkleRoot_;
    publicMintStart = uint32(publicMintConfig_.start);
    publicMintEnd = uint32(publicMintConfig_.end);
    epsDeligateRegister = IEPS_DR(epsDeligateRegister_);
    pauseCutOffInDays = pauseCutOffInDays_;
    beneficiary = beneficiary_;
    mintPass = ERC721Burnable(mintPass_);
    _loadSubListDetails(subListParams);
  }

  // =======================================
  // MINTING
  // =======================================

  /**
   *
   * @dev onERC721Received: Recieve an ERC721
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory
  ) external returns (bytes4) {
    // Refuse all except mint pass holders:
    if (msg.sender != address(mintPass)) {
      revert InvalidPass();
    }

    _performMintPassMinting(tokenId_, from_);

    return this.onERC721Received.selector;
  }

  /**
   *
   * @dev _loadSubListDetails
   *
   */
  function _loadSubListDetails(SubListConfig[] memory config_) internal {
    for (uint256 i = 0; i < config_.length; i++) {
      subListConfig.push(config_[i]);
    }
  }

  /**
   *
   * @dev listMintStatus: View of a list mint status
   *
   */
  function listMintStatus(uint256 listInteger)
    public
    view
    returns (
      MintStatus status,
      uint256 start,
      uint256 end
    )
  {
    return (
      _mintTypeStatus(
        subListConfig[listInteger].start,
        subListConfig[listInteger].end
      ),
      subListConfig[listInteger].start,
      subListConfig[listInteger].end
    );
  }

  /**
   *
   * @dev _mintTypeStatus: return the status of the mint type
   *
   */
  function _mintTypeStatus(uint256 start_, uint256 end_)
    internal
    view
    returns (MintStatus)
  {
    // Explicitly check for open before anything else. This is the only valid path to making a
    // state change, so keep the gas as low as possible for the code path through 'open'
    if (block.timestamp >= (start_) && block.timestamp <= (end_)) {
      return (MintStatus.open);
    }

    if ((start_ + end_) == 0) {
      return (MintStatus.notEnabled);
    }

    if (block.timestamp > end_) {
      return (MintStatus.finished);
    }

    if (block.timestamp < start_) {
      return (MintStatus.notYetOpen);
    }

    return (MintStatus.unknown);
  }

  /**
   *
   * @dev publicMintStatus: View of public mint status
   *
   */
  function publicMintStatus() public view returns (MintStatus) {
    return _mintTypeStatus(publicMintStart, publicMintEnd);
  }

  /**
   *
   * @dev allMint: Mint simultaneously from:
   * - Any Sublist
   * - Public
   * - MintPass
   *
   */
  function allMint(
    Sublist[] memory subLists_,
    uint256[] memory quantityEligibles_,
    uint256[] memory quantityToMints_,
    uint256[] memory unitPrices_,
    uint256[] memory vestingInDays_,
    bytes32[][] calldata proofs_,
    uint256 publicQuantityToMint_,
    uint256[] memory mintPassTokenIds_
  ) external payable whenNotPaused {
    uint256 totalPrice = 0;

    // Calculate the total price of public and valid listMint calls
    totalPrice = publicMintPrice * publicQuantityToMint_;

    for (uint256 i = 0; i < subLists_.length; i++) {
      if (proofs_[i].length != 0) {
        // Add the price of this listMint to the total price
        totalPrice += unitPrices_[i] * quantityToMints_[i];
      }
    }

    // Check that the value of the message is equal to the total price
    if (msg.value != totalPrice) revert IncorrectETHPayment();

    // Process mint pass minting
    if (mintPassTokenIds_.length != 0) {
      _mintPassMint(mintPassTokenIds_, msg.sender);
    }

    // Process public minting
    if (publicQuantityToMint_ != 0) {
      _publicMint(publicQuantityToMint_);
    }

    // Make the listMint calls
    for (uint256 i = 0; i < subLists_.length; i++) {
      if (proofs_[i].length != 0) {
        _listMint(
          subLists_[i],
          quantityEligibles_[i],
          quantityToMints_[i],
          unitPrices_[i],
          vestingInDays_[i],
          proofs_[i]
        );
      }
    }
  }

  /**
   *
   * @dev listMints: Mint simultaneously from any sublists
   *
   */
  function listsMint(
    Sublist[] memory subLists_,
    uint256[] memory quantityEligibles_,
    uint256[] memory quantityToMints_,
    uint256[] memory unitPrices_,
    uint256[] memory vestingInDays_,
    bytes32[][] calldata proofs_
  ) external payable whenNotPaused {
    uint256 totalPrice = 0;

    // Calculate the total price of the valid listMint calls
    for (uint256 i = 0; i < subLists_.length; i++) {
      if (proofs_[i].length != 0) {
        // Add the price of this listMint to the total price
        totalPrice += unitPrices_[i] * quantityToMints_[i];
      }
    }

    // Check that the value of the message is equal to the total price
    if (msg.value != totalPrice) revert IncorrectETHPayment();

    // Make the listMint calls
    for (uint256 i = 0; i < subLists_.length; i++) {
      if (proofs_[i].length != 0) {
        _listMint(
          subLists_[i],
          quantityEligibles_[i],
          quantityToMints_[i],
          unitPrices_[i],
          vestingInDays_[i],
          proofs_[i]
        );
      }
    }
  }

  /**
   *
   * @dev listMint: mint from any of the lists
   *
   */
  function listMint(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) public payable whenNotPaused {
    if (msg.value != (unitPrice_ * quantityToMint_)) {
      revert IncorrectETHPayment();
    }

    _listMint(
      sublist_,
      quantityEligible_,
      quantityToMint_,
      unitPrice_,
      vestingInDays_,
      proof_
    );
  }

  /**
   *
   * @dev _listMint: mint from any of the lists
   *
   */
  function _listMint(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) internal {
    (address minter, bool valid) = merkleListValid(
      msg.sender,
      sublist_,
      quantityEligible_,
      proof_,
      unitPrice_,
      vestingInDays_,
      listMerkleRoot
    );

    MintStatus status;
    (status, , ) = listMintStatus(sublist_.sublistInteger);
    if (status != MintStatus.open) revert ThisListMintIsClosed();

    if (sublist_.sublistInteger == allowlistSublistInteger) {
      if (!_allowlistAndPublicSupplyRemains(quantityToMint_)) {
        revert RequestedQuantityExceedsSupply(
          quantityToMint_,
          subListConfig[allowlistSublistInteger].phaseMaxSupply -
            allowListPlusPublicMintCount
        );
      }
    }

    if (!valid) revert ProofInvalid();
    // See if this address has already minted its full allocation:

    if (
      (listMintAllocationMinted[minter][sublist_.sublistInteger] +
        quantityToMint_) > quantityEligible_
    )
      revert RequestingMoreThanRemainingAllocation({
        requested: quantityToMint_,
        remainingAllocation: quantityEligible_ -
          listMintAllocationMinted[minter][sublist_.sublistInteger]
      });

    listMintAllocationMinted[minter][
      sublist_.sublistInteger
    ] += quantityToMint_;

    if (sublist_.sublistInteger == allowlistSublistInteger) {
      allowListPlusPublicMintCount += quantityToMint_;
    }
    nftContract.mint(quantityToMint_, msg.sender, vestingInDays_);
    emit SmashMint(
      msg.sender,
      MintingType.allowlistMint,
      sublist_.sublistInteger,
      quantityToMint_
    );
  }

  /**
   *
   * @dev publicMint:  Minting not related to a list. Note that the confi
   * may impose a per address limit (maxPublicMintPerAddress).
   *
   */
  function publicMint(uint256 quantityToMint_) external payable whenNotPaused {
    if (msg.value != (publicMintPrice * quantityToMint_))
      revert IncorrectETHPayment();

    _publicMint(quantityToMint_);
  }

  function _publicMint(uint256 quantityToMint_) internal {
    if (publicMintStatus() != MintStatus.open) revert PublicMintClosed();

    if (!_allowlistAndPublicSupplyRemains(quantityToMint_)) {
      revert RequestedQuantityExceedsSupply(
        quantityToMint_,
        subListConfig[allowlistSublistInteger].phaseMaxSupply -
          allowListPlusPublicMintCount
      );
    }

    if (maxPublicMintPerAddress != 0) {
      // Get previous mint count and check that this quantity will not exceed the allowance:
      uint256 publicMintsForAddress = publicMintAllocationMinted[msg.sender];

      if ((publicMintsForAddress + quantityToMint_) > maxPublicMintPerAddress) {
        revert MaxPublicMintAllowanceExceeded({
          requested: quantityToMint_,
          alreadyMinted: publicMintsForAddress,
          maxAllowance: maxPublicMintPerAddress
        });
      }
      publicMintAllocationMinted[msg.sender] += quantityToMint_;
    }

    allowListPlusPublicMintCount += quantityToMint_;

    nftContract.mint(quantityToMint_, msg.sender, 0);

    emit SmashMint(msg.sender, MintingType.publicMint, 0, quantityToMint_);
  }

  /**
   *
   * @dev mintPassMint:  Minting using a mint pass. Note that this contract
   * must have approval before this can be called
   *
   */

  function mintPassMint(uint256[] memory mintPassTokenIds_) external {
    _mintPassMint(mintPassTokenIds_, msg.sender);
  }

  function _mintPassMint(uint256[] memory mintPassTokenIds_, address receiver_)
    internal
  {
    for (uint256 i = 0; i < mintPassTokenIds_.length; i++) {
      _performMintPassMinting(mintPassTokenIds_[i], receiver_);
    }
  }

  function _performMintPassMinting(uint256 tokenId_, address receiver_)
    internal
  {
    // The mint pass cannot start until the allowlist (designated via allowlistSublistInteger) has started
    if (block.timestamp < subListConfig[allowlistSublistInteger].start) {
      revert MintPassClosed();
    }

    // Burn the mint pass:
    mintPass.burn(tokenId_);

    // Mint the owner of the mint pass two NFTs:
    nftContract.mint(2, receiver_, 0);

    emit SmashMint(msg.sender, MintingType.mintPassMint, 0, 2);
  }

  /**
   *
   * @dev _allowlistAndPublicSupplyRemains
   *
   */
  function _allowlistAndPublicSupplyRemains(uint256 quantityToMint_)
    internal
    view
    returns (bool)
  {
    return
      (quantityToMint_ + allowListPlusPublicMintCount) <=
      subListConfig[allowlistSublistInteger].phaseMaxSupply;
  }

  /**
   *
   * @dev merkleListValid: Eligibility check for the merkleroot controlled minting. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible) as well as from within the contract.
   *
   * Function flow is as follows:
   * (1) Check that the address and eligible quantity are in the rafflelist.
   *   -> (1a) If NOT then go to (2),
   *   -> (1b) if it IS go to (4).
   * (2) If (1) is false, check if the sender address is a proxy for a nominator,
   *   -> (2a) If there is NO nominator exit with false eligibility and reason "Mint proof invalid"
   *   -> (2b) if there IS a nominator go to (3)
   * (3) Check if the nominator is in the rafflelist.
   *   -> (3a) if NOT then exit with false eligibility and reason "Mint proof invalid"
   *   -> (3b) if it IS then go to (4), having set the minter to the nominator which is the eligible address for this mint.
   * (4) Check if this minter address has already minted. If so, exit with false eligibility and reason "Requesting more than remaining allocation"
   * (5) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function merkleListValid(
    address addressToCheck_,
    Sublist memory sublist_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32 root_
  ) public view returns (address minter, bool success) {
    // Default delivery and minter address are the addresses passed in, which from the contract will be the msg.sender:
    minter = addressToCheck_;

    bytes32 leaf = _getListHash(
      addressToCheck_,
      sublist_,
      quantityEligible_,
      unitPrice_,
      vestingInDays_
    );

    // (1) Check rafflelist for addressToCheck_:
    if (MerkleProof.verify(proof_, root_, leaf) == false) {
      // (2) addressToCheck_ is not on the list. Check if they are a cold EPS address for a hot EPS address:
      if (address(epsDeligateRegister) != address(0)) {
        address epsCold;
        address[] memory epsAddresses;
        (epsAddresses, ) = epsDeligateRegister.getAllAddresses(
          addressToCheck_,
          1
        );

        if (epsAddresses.length > 1) {
          epsCold = epsAddresses[1];
        } else {
          return (minter, false);
        }

        // (3) If this matches a proxy record and the nominator isn't the addressToCheck_ we have a nominator to check
        if (epsCold != addressToCheck_) {
          leaf = _getListHash(
            epsCold,
            sublist_,
            quantityEligible_,
            unitPrice_,
            vestingInDays_
          );

          if (MerkleProof.verify(proof_, root_, leaf) == false) {
            // (3a) Not valid at either address. Say so and return
            return (minter, false);
          } else {
            // (3b) There is a value at the nominator. The nominator is the minter, use it to check and track allowance.
            minter = epsCold;
          }
        } else {
          // (2a) Sender isn't on the list, and there is no proxy to consider:
          return (minter, false);
        }
      }
    }

    // (5) Can only reach here for a valid address and quantity:
    return (minter, true);
  }

  /**
   *
   * @dev _getListHash: Get hash of information for the rafflelist mint.
   *
   */
  function _getListHash(
    address minter_,
    Sublist memory sublist_,
    uint256 quantity_,
    uint256 unitPrice_,
    uint256 vestingInDays_
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          minter_,
          sublist_.sublistPosition,
          quantity_,
          unitPrice_,
          vestingInDays_,
          sublist_.sublistInteger
        )
      );
  }

  /**
   *
   * @dev checkAllocation: Eligibility check for all lists. Will return a count of remaining allocation (if any) and an optional
   * status code.
   */
  function checkAllocation(
    Sublist memory sublist_,
    uint256 quantityEligible_,
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_,
    address addressToCheck_
  ) external view returns (uint256 allocation, AllocationCheck statusCode) {
    (address minter, bool valid) = merkleListValid(
      addressToCheck_,
      sublist_,
      quantityEligible_,
      proof_,
      unitPrice_,
      vestingInDays_,
      listMerkleRoot
    );

    if (!valid) {
      return (0, AllocationCheck.invalidProof);
    } else {
      allocation =
        quantityEligible_ -
        listMintAllocationMinted[minter][sublist_.sublistInteger];
      if (allocation > 0) {
        return (allocation, AllocationCheck.hasAllocation);
      } else {
        return (allocation, AllocationCheck.allocationExhausted);
      }
    }
  }

  // =======================================
  // ADMINISTRATION
  // =======================================

  /**
   *
   * @dev setSublistConfig:
   *
   */
  function setSublistConfig(
    uint256 sublistInteger_,
    uint256 start_,
    uint256 end_,
    uint256 supply_
  ) external onlyOwner {
    if (listDetailsLocked) {
      revert ListDetailsLocked();
    }

    subListConfig[sublistInteger_].start = start_;
    subListConfig[sublistInteger_].end = end_;
    subListConfig[sublistInteger_].phaseMaxSupply = supply_;

    emit SublistConfigSet(sublistInteger_, start_, end_, supply_);
  }

  /**
   *
   * @dev setAllowlistSublistInteger:
   *
   */
  function setAllowlistSublistInteger(uint256 allowlistSublistInteger_)
    external
    onlyOwner
  {
    allowlistSublistInteger = allowlistSublistInteger_;

    emit AllowlistSublistIntegerSet(allowlistSublistInteger_);
  }

  /**
   *
   * @dev setNFTAddress
   *
   */
  function setNFTAddress(address nftContract_) external onlyOwner {
    if (nftContract == INFTByMetadrop(address(0))) {
      nftContract = INFTByMetadrop(nftContract_);
    } else {
      revert AddressAlreadySet();
    }
  }

  /**
   *
   * @dev setList: Set the merkleroot
   *
   */
  function setList(bytes32 merkleRoot_) external onlyOwner {
    if (listDetailsLocked) {
      revert ListDetailsLocked();
    }

    listMerkleRoot = merkleRoot_;

    emit MerkleRootSet(merkleRoot_);
  }

  /**
   *
   *
   * @dev setpublicMintStart: Allow owner to set minting open time.
   *
   *
   */
  function setpublicMintStart(uint32 time_) external onlyOwner {
    if (publicMintingClosedForever) {
      revert MintingIsClosedForever();
    }
    publicMintStart = time_;
  }

  /**
   *
   *
   * @dev setpublicMintEnd: Allow owner to set minting closed time.
   *
   *
   */
  function setpublicMintEnd(uint32 time_) external onlyOwner {
    if (publicMintingClosedForever) {
      revert MintingIsClosedForever();
    }
    publicMintEnd = time_;
  }

  /**
   *
   *
   * @dev setPublicMintingClosedForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashversePrimarySale" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setPublicMintingClosedForeverCannotBeUndone(
    string memory confirmation_
  ) external onlyOwner {
    string memory expectedValue = "SmashversePrimarySale";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      publicMintEnd = uint32(block.timestamp);
      publicMintingClosedForever = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev setListDetailsLockedForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashversePrimarySale" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setListDetailsLockedForeverCannotBeUndone(
    string memory confirmation_
  ) external onlyOwner {
    string memory expectedValue = "SmashversePrimarySale";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      listDetailsLocked = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev pause: Allow owner to pause.
   *
   *
   */
  function pause() external onlyOwner {
    require(
      publicMintStart == 0 ||
        block.timestamp < (publicMintStart + pauseCutOffInDays * 1 days),
      "Pause cutoff passed"
    );
    _pause();
  }

  /**
   *
   *
   * @dev unpause: Allow owner to unpause.
   *
   *
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   *
   *
   * @dev setEPSDelegateRegisterAddress. Owner can update the EPS DelegateRegister address
   *
   *
   */
  function setEPSDelegateRegisterAddress(address epsDelegateRegister_)
    external
    onlyOwner
  {
    epsDeligateRegister = IEPS_DR(epsDelegateRegister_);
    emit EPSDelegateRegisterUpdated(epsDelegateRegister_);
  }

  // =======================================
  // FINANCE
  // =======================================

  /**
   *
   *
   * @dev withdrawETH: A withdraw function to allow ETH to be withdrawn to the vesting contract.
   * Note that this can be performed by anyone, as all funds flow to the vesting contract only.
   *
   *
   */
  function withdrawETH(uint256 amount) external {
    (bool success, ) = beneficiary.call{value: amount}("");
    if (!success) revert TransferFailed();
  }

  /**
   *
   *
   * @dev withdrawERC20: A withdraw function to allow ERC20s to be withdrawn to the vesting contract.
   * Note that this can be performed by anyone, as all funds flow to the vesting contract only.
   *
   *
   */
  function withdrawERC20(IERC20 token, uint256 amount) external {
    token.transfer(beneficiary, amount);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTByMetadrop {
  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  enum BeneficiaryType {
    owner,
    epsDelegate,
    stakedOwner,
    vestedOwner,
    offChainOwner
  }

  // ============================
  // EVENTS
  // ============================
  event EPSComposeThisUpdated(address epsComposeThisAddress);
  event EPSDelegateRegisterUpdated(address epsDelegateRegisterAddress);
  event EPS_CTTurnedOn();
  event EPS_CTTurnedOff();
  event Revealed();
  event BaseContractSet(address baseContract);
  event VestingAddressSet(address vestingAddress);
  event MaxStakingDurationSet(uint16 maxStakingDurationInDays);
  event MerkleRootSet(bytes32 merkleRoot);

  // ============================
  // ERRORS
  // ============================
  error ThisIsTheBaseContract();
  error MintingIsClosedForever();
  error ThisMintIsClosed();
  error IncorrectETHPayment();
  error TransferFailed();
  error VestingAddressIsLocked();
  error MetadataIsLocked();
  error StakingDurationExceedsMaximum(
    uint256 requestedStakingDuration,
    uint256 maxStakingDuration
  );
  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  );
  error ProofInvalid();
  error RequestingMoreThanRemainingAllocation(
    uint256 requested,
    uint256 remainingAllocation
  );
  error baseChainOnly();
  error InvalidAddress();

  // ============================
  // FUNCTIONS
  // ============================

  function setURIs(
    string memory placeholderURI_,
    string memory arweaveURI_,
    string memory ipfsURI_
  ) external;

  function lockURIs() external;

  function switchImageSource(bool useArweave_) external;

  function setDefaultRoyalty(address recipient, uint96 fraction) external;

  function deleteDefaultRoyalty() external;

  function mint(
    uint256 quantityToMint_,
    address to_,
    uint256 vestingInDays_
  ) external;
}

// SPDX-License-Identifier: MIT
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* IEPS_DR: EPS Delegate Regsiter Interface
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EPS Contracts v2.0.0

pragma solidity ^0.8.17;

/**
 *
 * @dev Interface for the EPS portal
 *
 */

/**
 * @dev Returns the beneficiary of the `tokenId` token.
 */
interface IEPS_DR {
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_);

  /**
   * @dev Returns the beneficiary balance for a contract.
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_);

  /**
   * @dev beneficiaryBalance: Returns the beneficiary balance of ETH.
   */
  function beneficiaryBalance(address queryAddress_)
    external
    view
    returns (uint256 balance_);

  /**
   * @dev beneficiaryBalanceOf1155: Returns the beneficiary balance for an ERC1155.
   */
  function beneficiaryBalanceOf1155(
    address queryAddress_,
    address tokenContract_,
    uint256 id_
  ) external view returns (uint256 balance_);

  function getAddresses(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAddresses1155(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAddresses20(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAllAddresses(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) external view returns (bool);

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
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