// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// EPS implementation
import "./EPS/IEPS_DR.sol";

interface ISublists {
  struct Sublist {
    uint256 sublistInteger;
    uint256 sublistPosition;
  }
}

interface ITitanMinting is ISublists {
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
  ) external payable;
}

interface ITitan is IERC721 {
  /**
   * @dev Returns the total number of tokens ever minted
   */
  function totalMinted() external view returns (uint256);
}

contract SmashversePrimarySaleRelay is Pausable, Ownable, ISublists {
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

  address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  // =======================================
  // CONFIG
  // =======================================

  // Pause cutoff
  uint256 public immutable pauseCutOffInDays;

  // The merkleroot for the list
  bytes32 public listMerkleRoot;

  // Config for the list mints
  SubListConfig[] public subListConfig;

  // The NFT contract
  ITitan immutable smashverseTitansContract;

  // V1 sale contract
  ITitanMinting immutable smashverseSaleContract;

  IERC721 immutable mintPassContract;

  bytes32[] private mintPassProof;

  bytes32[] private freeMintProof;

  uint256 private totalMintPassMintQuantity;

  uint256 private totalFreeMintQuantity;

  uint32 public publicMintStart;
  uint32 public publicMintEnd;
  bool public publicMintingClosedForever;

  bool public listDetailsLocked;

  IEPS_DR public epsDeligateRegister;

  address public beneficiary;

  // Track publicMint minting allocations:
  mapping(address => uint256) public publicMintAllocationMinted;

  // Track list minting allocations:
  mapping(address => mapping(uint256 => uint256))
    public listMintAllocationMinted;

  error MintingIsClosedForever();
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
  error IncorrectConfirmationValue();
  error ThisListMintIsClosed();
  error PublicMintClosed();
  error ListDetailsLocked();
  error InvalidMintPass();

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

  event MintPassRedeemed(
    address indexed receiver,
    uint256 indexed mintPassTokenId
  );

  constructor(
    PublicMintConfig memory publicMintConfig_,
    bytes32 listMerkleRoot_,
    address epsDeligateRegister_,
    uint256 pauseCutOffInDays_,
    address beneficiary_,
    SubListConfig[] memory subListParams,
    address smashverseTitansContract_,
    address smashverseSaleContract_,
    address mintPassContract_
  ) {
    listMerkleRoot = listMerkleRoot_;
    publicMintStart = uint32(publicMintConfig_.start);
    publicMintEnd = uint32(publicMintConfig_.end);
    epsDeligateRegister = IEPS_DR(epsDeligateRegister_);
    pauseCutOffInDays = pauseCutOffInDays_;
    beneficiary = beneficiary_;
    _loadSubListDetails(subListParams);
    smashverseTitansContract = ITitan(smashverseTitansContract_);
    smashverseSaleContract = ITitanMinting(smashverseSaleContract_);
    mintPassContract = IERC721(mintPassContract_);
  }

  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory
  ) external returns (bytes4) {
    // Allow mints from the Smashverse Titans NFT contract to be sent to this contract
    if (
      msg.sender == address(smashverseTitansContract) && from_ == address(0)
    ) {
      return this.onERC721Received.selector;
    } else {
      // Revert if the sender is not the mint pass contract, since this is a callback from a contract.
      if (msg.sender != address(mintPassContract)) {
        revert InvalidMintPass();
      }

      _performMintPassMinting(tokenId_, from_, address(this));

      return this.onERC721Received.selector;
    }
  }

  function mintPassMint(uint256[] memory mintPassTokenIds_) external {
    for (uint256 i = 0; i < mintPassTokenIds_.length; i++) {
      _performMintPassMinting(mintPassTokenIds_[i], msg.sender, msg.sender);
    }
  }

  function _performMintPassMinting(
    uint256 mintPassTokenId_,
    address receiver_,
    address currentPassHolder_
  ) internal whenNotPaused {
    // safeTransferFrom will revert if the sender does not own the token or does not have approval to transfer it.
    // Burn the mint pass. Since we can't burn NFTs, we transfer it to 0xdEaD.
    mintPassContract.safeTransferFrom(
      currentPassHolder_,
      DEAD_ADDRESS,
      mintPassTokenId_
    );

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalMintPassMintQuantity,
      2,
      0,
      0,
      mintPassProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      receiver_,
      nextTokenId,
      ""
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      receiver_,
      nextTokenId + 1,
      ""
    );

    emit MintPassRedeemed(receiver_, mintPassTokenId_);
  }

  // =======================================
  // MINTING
  // =======================================

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
   * @dev allowlistFreeMint one free mint per address on the allowlist
   *
   */
  function listMint(
    Sublist memory sublist_,
    uint256, // ignored but kept for consistency with ABI
    uint256, // ignored but kept for consistency with ABI
    uint256 unitPrice_,
    uint256 vestingInDays_,
    bytes32[] calldata proof_
  ) public payable whenNotPaused {
    _allowlistFreeMint(sublist_, 1, 1, unitPrice_, vestingInDays_, proof_);
  }

  /**
   *
   * @dev publicMint
   *
   */
  function publicMint(uint256) external payable whenNotPaused {
    _publicMint();
  }

  function _publicMint() internal {
    if (publicMintStatus() != MintStatus.open) revert PublicMintClosed();

    uint256 publicMintsForAddress = publicMintAllocationMinted[msg.sender];

    if (publicMintsForAddress != 0) {
      revert MaxPublicMintAllowanceExceeded({
        requested: 1,
        alreadyMinted: 1,
        maxAllowance: 1
      });
    }
    publicMintAllocationMinted[msg.sender] += 1;

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalFreeMintQuantity,
      1,
      0,
      0,
      freeMintProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      msg.sender,
      nextTokenId,
      ""
    );

    emit SmashMint(msg.sender, MintingType.publicMint, 0, 1);
  }

  /**
   *
   * @dev _allowlistFreeMint:
   *
   */
  function _allowlistFreeMint(
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

    if (!valid) revert ProofInvalid();
    // See if this address has already minted its full allocation:

    if (listMintAllocationMinted[minter][sublist_.sublistInteger] != 0)
      revert RequestingMoreThanRemainingAllocation({
        requested: quantityToMint_,
        remainingAllocation: 0
      });

    listMintAllocationMinted[minter][
      sublist_.sublistInteger
    ] += quantityToMint_;

    // Cache the next tokenId from the NFT:
    uint256 nextTokenId = smashverseTitansContract.totalMinted();

    smashverseSaleContract.listMint(
      Sublist(0, 0),
      totalFreeMintQuantity,
      1,
      0,
      0,
      freeMintProof
    );

    smashverseTitansContract.safeTransferFrom(
      address(this),
      msg.sender,
      nextTokenId,
      ""
    );

    emit SmashMint(
      msg.sender,
      MintingType.allowlistMint,
      sublist_.sublistInteger,
      quantityToMint_
    );
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

  /**
   *
   * @dev setProofsAndTotalQuantities
   *
   */
  function setProofsAndTotalQuantities(
    bytes32[] calldata mintPassProof_,
    uint256 totalMintPassMintQuantity_,
    bytes32[] calldata freeMintProof_,
    uint256 totalFreeMintQuantity_
  ) external onlyOwner {
    mintPassProof = mintPassProof_;
    totalMintPassMintQuantity = totalMintPassMintQuantity_;
    freeMintProof = freeMintProof_;
    totalFreeMintQuantity = totalFreeMintQuantity_;
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

  /**
   *
   * @dev Revert unexpected ETH and function calls
   *
   */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }
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