// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v1)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// Use of ERC721M which contains staking, vesting, and gas improvements for batch minting:
import "./ERC721M/ERC721M.sol";
// Layer Zero support for multi-chain freedom:
import "./LayerZero/onft/IONFT721.sol";
import "./LayerZero/onft/ONFT721Core.sol";
// Operator Filter
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// Metadrop NFT interface
import "./INFTByMetadrop.sol";

contract SmashverseNFTByMetadrop is
  INFTByMetadrop,
  ONFT721Core,
  ERC721M,
  IONFT721,
  DefaultOperatorFilterer,
  VRFConsumerBaseV2
{
  using Strings for uint256;

  // Base chain for this collection (used with layer zero):
  uint256 immutable baseChain;
  address public immutable primarySaleContract;

  // Which metadata source are we using:
  bool public useArweave = true;
  // Are we pre-reveal:
  bool public preReveal = true;
  // Is metadata locked?:
  bool public metadataLocked = false;
  // Use the EPS composition service?
  bool public useEPS_CT = true;
  // Minting complete confirmation
  bool public mintingComplete;

  // Max duration for staking
  uint256 public maxStakingDurationInDays;

  uint256 public recordedRandomWord;
  uint256 public vrfStartPosition;

  address public baseContract;
  string public preRevealURI;
  string public arweaveURI;
  string public ipfsURI;

  /**
   * @dev Chainlink config.
   */
  // Mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  // Goerli: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
  VRFCoordinatorV2Interface vrfCoordinator;
  uint64 vrfSubscriptionId;
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // Mainnet 200 gwei: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
  // Goerli 150 gwei 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
  bytes32 vrfKeyHash;
  uint32 vrfCallbackGasLimit = 150000;
  uint16 vrfRequestConfirmations = 3;
  uint32 vrfNumWords = 1;

  bytes32 public positionProof;

  // Track tokens off-chain
  mapping(uint256 => address) public offChainOwner;

  error IncorrectConfirmationValue();
  error VRFAlreadySet();
  error PositionProofAlreadySet();

  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);

  constructor(
    address primarySaleContract_,
    uint256 supply_,
    uint256 baseChain_,
    address epsDelegateRegister_,
    address epsComposeThis_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    uint64 vrfSubscriptionId_,
    address royaltyReceipientAddress_,
    uint96 royaltyPercentageBasisPoints_
  )
    ERC721M(
      "Smashverse",
      "SMASH",
      supply_,
      epsDelegateRegister_,
      epsComposeThis_
    )
    ONFT721Core(_getLzEndPoint())
    VRFConsumerBaseV2(vrfCoordinator_)
  {
    primarySaleContract = primarySaleContract_;
    baseChain = baseChain_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    setVRFSubscriptionId(vrfSubscriptionId_);
    setDefaultRoyalty(royaltyReceipientAddress_, royaltyPercentageBasisPoints_);
  }

  // =======================================
  // OPERATOR FILTER REGISTER
  // =======================================

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721M, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override(ERC721M, IERC721)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721M, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
    _burn(tokenId);
  }

  // =======================================
  // MINTING
  // =======================================

  /**
   *
   *
   * @dev mint: mint items
   *
   *
   */
  function mint(
    uint256 quantityToMint_,
    address to_,
    uint256 vestingInDays_
  ) external {
    if (mintingComplete) {
      revert MintingIsClosedForever();
    }

    if (msg.sender != primarySaleContract) revert InvalidAddress();

    if (block.chainid != baseChain) {
      revert baseChainOnly();
    }

    _mintSequential(to_, quantityToMint_, vestingInDays_);
  }

  // =======================================
  // VRF
  // =======================================

  /**
   *
   *
   * @dev getStartPosition
   *
   *
   */
  function getStartPosition() external onlyOwner returns (uint256) {
    if (recordedRandomWord != 0) {
      revert VRFAlreadySet();
    }
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   *
   * @dev fulfillRandomWords: Callback from the chainlinkv2 oracle with randomness.
   *
   *
   */
  function fulfillRandomWords(uint256 requestId_, uint256[] memory randomWords_)
    internal
    override
  {
    recordedRandomWord = randomWords_[0];
    vrfStartPosition = (randomWords_[0] % maxSupply) + 1;
    emit RandomNumberReceived(requestId_, randomWords_[0]);
    emit VRFPositionSet(vrfStartPosition);
  }

  // =======================================
  // ADMINISTRATION
  // =======================================
  /**
   *
   *
   * @dev setDefaultRoyalty: Set the royalty percentage claimed
   * by the project owner for the collection.
   *
   * Note - we have specifically NOT implemented the ability to have different
   * royalties on a token by token basis. This reduces the complexity of processing on
   * multi-buys, and also avoids challenges to decentralisation (e.g. the project targetting
   * one users tokens with larger royalties)
   *
   *
   */
  function setDefaultRoyalty(address recipient, uint96 fraction)
    public
    onlyOwner
  {
    _setDefaultRoyalty(recipient, fraction);
  }

  /**
   *
   *
   * @dev deleteDefaultRoyalty: Delete the royalty percentage claimed
   * by the project owner for the collection.
   *
   *
   */
  function deleteDefaultRoyalty() public onlyOwner {
    _deleteDefaultRoyalty();
  }

  /**
   *
   *
   * @dev lockURIs: lock the URI data for this contract
   *
   *
   */
  function lockURIs() external onlyOwner {
    metadataLocked = true;
  }

  /**
   *
   *
   * @dev setURIs: Set the URI data for this contract
   *
   *
   */
  function setURIs(
    string memory preRevealURI_,
    string memory arweaveURI_,
    string memory ipfsURI_
  ) external onlyOwner {
    if (metadataLocked) {
      revert MetadataIsLocked();
    }

    preRevealURI = preRevealURI_;
    arweaveURI = arweaveURI_;
    ipfsURI = ipfsURI_;
  }

  /**
   *
   *
   * @dev switchImageSource (guards against either arweave or IPFS being no more)
   *
   *
   */
  function switchImageSource(bool useArweave_) external onlyOwner {
    useArweave = useArweave_;
  }

  /**
   *
   *
   * @dev setMaxStakingPeriod
   *
   *
   */
  function setMaxStakingPeriod(uint16 maxStakingDurationInDays_)
    external
    onlyOwner
  {
    maxStakingDurationInDays = maxStakingDurationInDays_;
    emit MaxStakingDurationSet(maxStakingDurationInDays_);
  }

  /**
   *
   *
   * @dev setEPSComposeThisAddress. Owner can update the EPS ComposeThis address
   *
   *
   */
  function setEPSComposeThisAddress(address epsComposeThis_)
    external
    onlyOwner
  {
    epsComposeThis = IEPS_CT(epsComposeThis_);
    emit EPSComposeThisUpdated(epsComposeThis_);
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
   *
   * @dev reveal. Owner can reveal
   *
   *
   */
  function reveal() external onlyOwner {
    preReveal = false;
    emit Revealed();
  }

  /**
   *
   *
   * @dev setMintingCompleteForeverCannotBeUndone: Allow owner to set minting complete
   * Enter confirmation value of "SmashverseMintingComplete" to confirm that you are closing
   * this mint forever.
   *
   *
   */
  function setMintingCompleteForeverCannotBeUndone(string memory confirmation_)
    external
    onlyOwner
  {
    string memory expectedValue = "SmashverseMintingComplete";
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked(expectedValue))
    ) {
      mintingComplete = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /**
   *
   *
   * @dev setBaseContract. Owner can set base contract
   *
   *
   */
  function setBaseContract(address baseContract_) external onlyOwner {
    if (block.chainid == baseChain) {
      revert ThisIsTheBaseContract();
    }

    baseContract = baseContract_;

    emit BaseContractSet(baseContract_);
  }

  /**
   *
   *
   * @dev setEPS_CTOn. Owner can turn EPS CT on
   *
   *
   */
  function setEPS_CTOn() external onlyOwner {
    useEPS_CT = true;
    emit EPS_CTTurnedOn();
  }

  /**
   *
   *
   * @dev setEPS_CTOff. Owner can turn EPS CT off
   *
   *
   */
  function setEPS_CTOff() external onlyOwner {
    useEPS_CT = false;
    emit EPS_CTTurnedOff();
  }

  /**
   *
   * @dev setPositionProof
   *
   */
  function setPositionProof(bytes32 positionProof_) external onlyOwner {
    if (positionProof != "") {
      revert PositionProofAlreadySet();
    }
    positionProof = positionProof_;

    emit MerkleRootSet(positionProof_);
  }

  /**
   *
   * @dev chainlink configuration setters:
   *
   */

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) public onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev setVRFKeyHash: Set the chainlink keyhash (gas lane).
   *
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyOwner {
    vrfKeyHash = vrfKeyHash_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit: Set the chainlink callback gas limit.
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_)
    external
    onlyOwner
  {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
  }

  /**
   *
   * @dev set: Set the chainlink number of confirmations.
   *
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_)
    external
    onlyOwner
  {
    vrfRequestConfirmations = vrfRequestConfirmations_;
  }

  // =======================================
  // STAKING AND VESTING
  // =======================================

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(uint256 tokenId_)
    external
    view
    returns (address beneficiary_, BeneficiaryType beneficiaryType_)
  {
    beneficiary_ = epsDeligateRegister.beneficiaryOf(
      address(this),
      tokenId_,
      1
    );

    if (beneficiary_ == address(this)) {
      // If this token is owned by this contract we need to determine if it is vested,
      // staked, or currently off-chain
      address stakedOwner = stakedOwnerOf(tokenId_);
      if (stakedOwner != address(0)) {
        beneficiary_ = stakedOwner;
        beneficiaryType_ = BeneficiaryType.stakedOwner;
      } else {
        address vestedOwner = vestedOwnerOf(tokenId_);
        if (vestedOwner != address(0)) {
          beneficiary_ = vestedOwner;
          beneficiaryType_ = BeneficiaryType.vestedOwner;
        } else {
          // Not vested or staked, must be off-chain:
          address otherChainOwner = offChainOwner[tokenId_];
          if (otherChainOwner != address(0)) {
            beneficiary_ = otherChainOwner;
            beneficiaryType_ = BeneficiaryType.offChainOwner;
          }
        }
      }
    } else {
      if (beneficiary_ != ownerOf(tokenId_)) {
        beneficiaryType_ = BeneficiaryType.epsDelegate;
      }
    }

    if (beneficiary_ == address(0)) {
      revert InvalidToken();
    }

    return (beneficiary_, beneficiaryType_);
  }

  /**
   *
   *
   * @dev inVestingPeriod: return if the token is in a vesting period
   *
   *
   */
  function inVestingPeriod(uint256 tokenId) external view returns (bool) {
    return (vestingEndDateForToken[tokenId] >= block.timestamp);
  }

  /**
   *
   *
   * @dev inStakedPeriod: return if the token is staked
   *
   *
   */
  function inStakedPeriod(uint256 tokenId) external view returns (bool) {
    return (stakingEndDateForToken[tokenId] >= block.timestamp);
  }

  /**
   *
   *
   * @dev stake: stake items
   *
   *
   */
  function stake(uint256[] memory tokenIds_, uint256 stakingInDays_) external {
    if (stakingInDays_ > maxStakingDurationInDays) {
      revert StakingDurationExceedsMaximum(
        stakingInDays_,
        maxStakingDurationInDays
      );
    }

    for (uint256 i = 0; i < tokenIds_.length; ) {
      _setTokenStakingDate(tokenIds_[i], stakingInDays_);
      unchecked {
        i++;
      }
    }
  }

  /**
   *
   *
   * @dev tokenURI. Includes layer zero satellite chain support
   * and staking / vesting display using EPS_CT
   *
   *
   */
  function tokenURI(uint256 tokenId_)
    public
    view
    override
    returns (string memory)
  {
    _requireMinted(tokenId_);

    // If we are using the EPS_CT service we can apply additional
    // details to metadata:

    if (useEPS_CT && address(epsComposeThis) != address(0)) {
      // Check for staking:
      if (stakingEndDateForToken[tokenId_] > block.timestamp) {
        AddedTrait[] memory addedTraits = new AddedTrait[](2);

        addedTraits[0] = AddedTrait(
          "Staked Until",
          ValueType.date,
          stakingEndDateForToken[tokenId_],
          "",
          address(0)
        );

        addedTraits[1] = AddedTrait(
          "Staked",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "staked";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      // Check for vesting:
      if (vestingEndDateForToken[tokenId_] > block.timestamp) {
        AddedTrait[] memory addedTraits = new AddedTrait[](2);

        addedTraits[0] = AddedTrait(
          "Vested Until",
          ValueType.date,
          vestingEndDateForToken[tokenId_],
          "",
          address(0)
        );

        addedTraits[1] = AddedTrait(
          "Vested",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "vested";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      // If on a satellite chain get the URI from the base chain:
      if (block.chainid != baseChain) {
        return
          epsComposeThis.composeURIFromLookup(
            baseChain,
            _baseContract(),
            tokenId_,
            new AddedTrait[](0),
            0,
            new string[](0)
          );
      }

      // Finally, if on the base chain, owned by the token contract and NOT staked
      // or vested we must be off-chain through LayerZero:
      if (ownerOf(tokenId_) == address(this)) {
        AddedTrait[] memory addedTraits = new AddedTrait[](1);

        addedTraits[0] = AddedTrait(
          "Off-chain",
          ValueType.characterString,
          0,
          "true",
          address(0)
        );

        string[] memory addedImages = new string[](1);

        addedImages[0] = "off-chain";

        return
          epsComposeThis.composeURIFromBaseURI(
            _baseTokenURI(tokenId_),
            addedTraits,
            1,
            addedImages
          );
      }

      return (_baseTokenURI(tokenId_));
    } else {
      return (_baseTokenURI(tokenId_));
    }
  }

  /**
   *
   *
   * @dev _baseTokenURI.
   *
   *
   */
  function _baseTokenURI(uint256 tokenId_)
    internal
    view
    returns (string memory)
  {
    if (preReveal) {
      return
        bytes(preRevealURI).length > 0
          ? string(abi.encodePacked(preRevealURI, tokenId_.toString(), ".json"))
          : "";
    } else {
      if (useArweave) {
        return
          bytes(arweaveURI).length > 0
            ? string(abi.encodePacked(arweaveURI, tokenId_.toString(), ".json"))
            : "";
      } else {
        return
          bytes(ipfsURI).length > 0
            ? string(abi.encodePacked(ipfsURI, tokenId_.toString(), ".json"))
            : "";
      }
    }
  }

  // =======================================
  // LAYER ZERO
  // =======================================

  /**
   *
   *
   * @dev supportsInterface. Include Layer Zero support.
   *
   *
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ONFT721Core, ERC721M, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IONFT721).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   *
   *
   * @dev _baseContract. Return the base contract address
   *
   *
   */
  function _baseContract() internal view returns (address) {
    if (block.chainid == baseChain) {
      return (address(this));
    }

    if (baseContract == address(0)) {
      return (address(this));
    } else {
      return baseContract;
    }
  }

  /**
   *
   *
   * @dev _isBaseChain. Return if this is the base chain
   *
   *
   */
  function _isBaseChain() internal view returns (bool) {
    return (block.chainid == baseChain);
  }

  /**
   *
   *
   * @dev _getLzEndPoint. Internal function to get the LZ endpoint
   * for this chain. This means we don't need to pass this in, allowing
   * for identical bytecode between chains, which enables the creation
   * of identical contract addresses using CREATE2
   *
   * Need a chain not listed? No problem, but you will need to alter the contract
   * to receive the LZ endpoint prior to deploy (this will change the bytecode
   * and mean you won't be able to deploy using the same contract ID without
   * using a create3 factory, and we haven't finished building that yet).
   *
   *
   */
  function _getLzEndPoint() internal view returns (address) {
    uint256 chainId = block.chainid;

    if (chainId == 1) return 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675; // Ethereum mainnet
    if (chainId == 5) return 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23; // Goerli testnet
    if (chainId == 80001) return 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8; // Mumbai (polygon testnet)
    if (chainId == 137) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Polygon mainnet
    if (chainId == 56) return 0x3c2269811836af69497E5F486A85D7316753cf62; // BSC mainnet
    if (chainId == 43114) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Avalanche mainnet
    if (chainId == 42161) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Arbitrum
    if (chainId == 10) return 0x3c2269811836af69497E5F486A85D7316753cf62; // Optimism
    if (chainId == 250) return 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7; // Fantom
    if (chainId == 73772) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Swimmer
    if (chainId == 53935) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // DFK
    if (chainId == 1666600000)
      return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Harmony
    if (chainId == 1284) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Moonbeam
    if (chainId == 42220) return 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9; // Celo
    if (chainId == 432204) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Dexalot
    if (chainId == 122) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Fuse
    if (chainId == 100) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Gnosis
    if (chainId == 8217) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Kaytn
    if (chainId == 1088) return 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4; // Metis

    return (address(0));
  }

  /**
   *
   *
   * @dev _debitFrom. Internal function called on a layer zero
   * transfer FROM this chain.
   *
   *
   */
  function _debitFrom(
    address _from,
    uint16,
    bytes memory,
    uint256 _tokenId
  ) internal virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "Not owner nor approved"
    );
    require(ERC721M.ownerOf(_tokenId) == _from, "Not owner");
    offChainOwner[_tokenId] = _from;
    _transfer(_from, address(this), _tokenId);
  }

  /**
   *
   *
   * @dev _creditTo. Internal function called on a layer zero
   * transfer TO this chain.
   *
   *
   */
  function _creditTo(
    uint16,
    address _toAddress,
    uint256 _tokenId
  ) internal virtual override {
    // Different behaviour depending on whether this has been deployed on
    // the base chain or a satellite chain:
    if (block.chainid == baseChain) {
      // Base chain. For us to be crediting the owner this token MUST be
      // owned by the contract, as they can only be minted on the base chain
      require(
        (_exists(_tokenId) && ERC721M.ownerOf(_tokenId) == address(this))
      );

      _transfer(address(this), _toAddress, _tokenId);
    } else {
      // Satellite chain. We can be crediting the user as a result of this reaching
      // this chain for the first time (mint) OR from a token that has been minted
      // here previously and is currently custodied by the contract.
      require(
        !_exists(_tokenId) ||
          (_exists(_tokenId) && ERC721M.ownerOf(_tokenId) == address(this))
      );
      if (!_exists(_tokenId)) {
        _safeMint(_toAddress, _tokenId);
      } else {
        _transfer(address(this), _toAddress, _tokenId);
      }
    }

    delete offChainOwner[_tokenId];
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
// EPS implementation
import "../EPS/IEPS_DR.sol";
import "../EPS/IEPS_CT.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721M is Context, ERC165, IERC721, IERC721Metadata, ERC2981 {
  using Address for address;
  using Strings for uint256;

  // EPS Compose This
  IEPS_CT public epsComposeThis;
  // EPS Delegation Register
  IEPS_DR public epsDeligateRegister;

  // Use of a burn address other than address(0) to allow easy enumeration
  // of burned tokens
  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  uint256 public immutable maxSupply;

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

  // Vesting mapping
  mapping(uint256 => uint256) public vestingEndDateForToken;

  // Staking mapping
  mapping(uint256 => uint256) public stakingEndDateForToken;

  uint256 public remainingSupply;

  error CallerNotTokenOwnerOrApproved();
  error CannotStakeForZeroDays();
  error InvalidToken();
  error QuantityExceedsRemainingSupply();

  /**
   * @dev Emitted when `owner` stakes a token
   */
  event TokenStaked(
    address indexed staker,
    uint256 indexed tokenId,
    uint256 indexed stakingEndDate
  );

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    address epsDeligateRegister_,
    address epsComposeThis_
  ) {
    _name = name_;
    _symbol = symbol_;
    maxSupply = maxSupply_;
    remainingSupply = maxSupply_;
    epsDeligateRegister = IEPS_DR(epsDeligateRegister_);
    epsComposeThis = IEPS_CT(epsComposeThis_);
  }

  /**
   * ================================
   * @dev ERC721M new functions begins
   * ================================
   */

  /**
   *
   *
   * @dev Returns total supply (minted - burned)
   *
   *
   */
  function totalSupply() external view returns (uint256) {
    return totalMinted() - totalBurned();
  }

  /**
   * @dev Returns the remaining supply
   */
  function totalUnminted() public view returns (uint256) {
    return remainingSupply;
  }

  /**
   * @dev Returns the total number of tokens ever minted
   */
  function totalMinted() public view returns (uint256) {
    return (maxSupply - remainingSupply);
  }

  /**
   * @dev Returns the count of tokens sent to the burn address
   */
  function totalBurned() public view returns (uint256) {
    return ERC721M.balanceOf(BURN_ADDRESS);
  }

  /**
   * @dev _setTokenVestingDate
   */
  function _setTokenVestingDate(uint256 tokenId_, uint256 vestingDuration_)
    internal
    virtual
  {
    if (vestingDuration_ != 0) {
      uint256 vestingEndDate = block.timestamp + (vestingDuration_ * 1 days);
      vestingEndDateForToken[tokenId_] = vestingEndDate;
      epsComposeThis.triggerMetadataUpdate(
        block.chainid,
        address(this),
        tokenId_,
        vestingEndDate
      );
    }
  }

  /**
   * @dev _setTokenStakingDate
   */
  function _setTokenStakingDate(uint256 tokenId_, uint256 stakingDuration_)
    internal
    virtual
  {
    if (!(_isApprovedOrOwner(_msgSender(), tokenId_))) {
      revert CallerNotTokenOwnerOrApproved();
    }

    // Clear token level approval if it exists. ApprovalForAll will not be
    // valid while staked as this contract will be the owner, but token level
    // approvals would persist, so must be removed
    if (_tokenApprovals[tokenId_] != address(0)) {
      _approve(address(0), tokenId_);
    }

    if (stakingDuration_ == 0) {
      revert CannotStakeForZeroDays();
    }

    uint256 stakingEndDate = block.timestamp + (stakingDuration_ * 1 days);
    stakingEndDateForToken[tokenId_] = stakingEndDate;
    epsComposeThis.triggerMetadataUpdate(
      block.chainid,
      address(this),
      tokenId_,
      stakingEndDate
    );
    emit TokenStaked(_msgSender(), tokenId_, stakingEndDate);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function stakedOwnerOf(uint256 tokenId)
    public
    view
    virtual
    returns (address)
  {
    if (stakingEndDateForToken[tokenId] > block.timestamp) {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    } else {
      return address(0);
    }
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function vestedOwnerOf(uint256 tokenId)
    public
    view
    virtual
    returns (address)
  {
    if (vestingEndDateForToken[tokenId] > block.timestamp) {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    } else {
      return address(0);
    }
  }

  /**
   * @dev _mintIdWithoutBalanceUpdate
   */
  function _mintIdWithoutBalanceUpdate(address to, uint256 tokenId) private {
    _beforeTokenTransfer(address(0), to, tokenId);

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /**
   * @dev _mintSequential
   */
  function _mintSequential(
    address to_,
    uint256 quantity_,
    uint256 vestingDuration_
  ) internal virtual {
    if (quantity_ > remainingSupply) {
      revert QuantityExceedsRemainingSupply();
    }

    require(_checkOnERC721Received(address(0), to_, 1, ""), "Not receiver");

    uint256 tokenId = maxSupply - remainingSupply;

    for (uint256 i = 0; i < quantity_; ) {
      _mintIdWithoutBalanceUpdate(to_, tokenId + i);

      _setTokenVestingDate(tokenId + i, vestingDuration_);

      unchecked {
        i++;
      }
    }

    remainingSupply = remainingSupply - quantity_;
    _balances[to_] += quantity_;
  }

  /**
   * ================================
   * @dev ERC721M new functions end
   * ================================
   */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165, ERC2981)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "Address 0");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    // Check for staking or vesting:
    if (
      stakingEndDateForToken[tokenId] > block.timestamp ||
      vestingEndDateForToken[tokenId] > block.timestamp
    ) {
      return (address(this));
    } else {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    }
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
    address owner = ERC721M.ownerOf(tokenId);
    require(to != owner, "Approval to owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "Not owner or approved"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");

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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
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
    require(_checkOnERC721Received(from, to, tokenId, data), "Not receiver");
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
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
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address owner = ERC721M.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
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
      "Not receiver"
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
    require(to != address(0), "Mint to 0 address");
    require(!_exists(tokenId), "Exists");

    _beforeTokenTransfer(address(0), to, tokenId);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    require(!_exists(tokenId), "Exists");

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address tokenOwner = ERC721M.ownerOf(tokenId);

    _beforeTokenTransfer(tokenOwner, BURN_ADDRESS, tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    _balances[tokenOwner] -= 1;
    _owners[tokenId] = BURN_ADDRESS;
    _balances[BURN_ADDRESS] += 1;

    emit Transfer(tokenOwner, BURN_ADDRESS, tokenId);

    _afterTokenTransfer(tokenOwner, BURN_ADDRESS, tokenId);
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
    require(ERC721M.ownerOf(tokenId) == from, "Not owner");
    require(to != address(0), "Tfr to 0 address");

    _beforeTokenTransfer(from, to, tokenId);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(ERC721M.ownerOf(tokenId) == from, "Not owner");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
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
    emit Approval(ERC721M.ownerOf(tokenId), to, tokenId);
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
    require(owner != operator, "Approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "Invalid Token");
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
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
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
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

pragma solidity >=0.5.0;

import "./IONFT721Core.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721 is IONFT721Core, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IONFT721Core.sol";
import "../../lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ONFT721Core is NonblockingLzApp, ERC165, IONFT721Core {
  uint256 public constant NO_EXTRA_GAS = 0;
  uint16 public constant FUNCTION_TYPE_SEND = 1;
  bool public useCustomAdapterParams;

  event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

  error AdapterParamsMustBeEmpty();

  constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IONFT721Core).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function estimateSendFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes memory _adapterParams
  ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
    // mock the payload for send()
    bytes memory payload = abi.encode(_toAddress, _tokenId);
    return
      lzEndpoint.estimateFees(
        _dstChainId,
        address(this),
        payload,
        _useZro,
        _adapterParams
      );
  }

  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable virtual override {
    _send(
      _from,
      _dstChainId,
      _toAddress,
      _tokenId,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _send(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) internal virtual {
    _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

    bytes memory payload = abi.encode(_toAddress, _tokenId);

    if (useCustomAdapterParams) {
      _checkGasLimit(
        _dstChainId,
        FUNCTION_TYPE_SEND,
        _adapterParams,
        NO_EXTRA_GAS
      );
    } else {
      if (_adapterParams.length != 0) {
        revert AdapterParamsMustBeEmpty();
      }
      // require(
      //   _adapterParams.length == 0,
      //   "LzApp: _adapterParams must be empty."
      // );
    }
    _lzSend(
      _dstChainId,
      payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams,
      msg.value
    );

    emit SendToChain(_dstChainId, _from, _toAddress, _tokenId);
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64, /*_nonce*/
    bytes memory _payload
  ) internal virtual override {
    (bytes memory toAddressBytes, uint256 tokenId) = abi.decode(
      _payload,
      (bytes, uint256)
    );
    address toAddress;
    assembly {
      toAddress := mload(add(toAddressBytes, 20))
    }

    _creditTo(_srcChainId, toAddress, tokenId);

    emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId);
  }

  function setUseCustomAdapterParams(bool _useCustomAdapterParams)
    external
    onlyOwner
  {
    useCustomAdapterParams = _useCustomAdapterParams;
    emit SetUseCustomAdapterParams(_useCustomAdapterParams);
  }

  function _debitFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId
  ) internal virtual;

  function _creditTo(
    uint16 _srcChainId,
    address _toAddress,
    uint256 _tokenId
  ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* IEPS_CT: EPS ComposeThis Interface
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

enum ValueType {
  none,
  characterString,
  number,
  date,
  chainAddress
}

struct AddedTrait {
  string trait;
  ValueType valueType;
  uint256 valueInteger;
  string valueString;
  address valueAddress;
}

interface IEPS_CT {
  event MetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  );

  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  function composeURIFromBaseURI(
    string memory baseString_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeURIFromLookup(
    uint256 baseURIChain_,
    address baseURIContract_,
    uint256 baseURITokenId_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeTraitsFromArray(AddedTrait[] memory addedTraits_)
    external
    view
    returns (string memory composedImageURL_);

  function composeImageFromBase(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress,
    uint256 id
  ) external view returns (string memory composedImageURL_);

  function composeTraitsAndImage(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_,
    AddedTrait[] memory addedTraits_
  )
    external
    view
    returns (string memory composedImageURL_, string memory composedTraits_);

  function triggerMetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT721Core is IERC165 {
  /**
   * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
   * _dstChainId - L0 defined chain id to send tokens too
   * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
   * _tokenId - token Id to transfer
   * _useZro - indicates to use zro to pay L0 fees
   * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
   */
  function estimateSendFee(
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes calldata _adapterParams
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  /**
   * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
   * `_toAddress` can be any size depending on the `dstChainId`.
   * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
   * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
   */
  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  /**
   * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
   * `_nonce` is the outbound nonce from
   */
  event SendToChain(
    uint16 indexed _dstChainId,
    address indexed _from,
    bytes indexed _toAddress,
    uint256 _tokenId
  );

  /**
   * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
   */
  event ReceiveFromChain(
    uint16 indexed _srcChainId,
    bytes indexed _srcAddress,
    address indexed _toAddress,
    uint256 _tokenId
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
  Ownable,
  ILayerZeroReceiver,
  ILayerZeroUserApplicationConfig
{
  using BytesLib for bytes;

  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
  address public precrime;

  event SetPrecrime(address precrime);
  event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
  event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
  event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);

  error InvalidEndpointCaller();
  error InvalidSourceSendingContract();
  error DestinationIsNotTrustedSource();
  error MinGasLimitNotSet();
  error GasLimitIsTooLow();
  error InvalidAdapterParams();
  error NoTrustedPathRecord();
  error InvalidMinGas();

  constructor(address _endpoint) {
    lzEndpoint = ILayerZeroEndpoint(_endpoint);
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public virtual override {
    // lzReceive must be called by the endpoint for security
    if (_msgSender() != address(lzEndpoint)) {
      revert InvalidEndpointCaller();
    }
    // require(
    //   _msgSender() == address(lzEndpoint),
    //   "LzApp: invalid endpoint caller"
    // );

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    if (
      !(_srcAddress.length == trustedRemote.length &&
        trustedRemote.length > 0 &&
        keccak256(_srcAddress) == keccak256(trustedRemote))
    ) {
      revert InvalidSourceSendingContract();
    }
    // require(
    //   _srcAddress.length == trustedRemote.length &&
    //     trustedRemote.length > 0 &&
    //     keccak256(_srcAddress) == keccak256(trustedRemote),
    //   "LzApp: invalid source sending contract"
    // );

    _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function _lzSend(
    uint16 _dstChainId,
    bytes memory _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams,
    uint256 _nativeFee
  ) internal virtual {
    bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];

    if (trustedRemote.length == 0) {
      revert DestinationIsNotTrustedSource();
    }
    // require(
    //   trustedRemote.length != 0,
    //   "LzApp: destination chain is not a trusted source"
    // );

    lzEndpoint.send{value: _nativeFee}(
      _dstChainId,
      trustedRemote,
      _payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _checkGasLimit(
    uint16 _dstChainId,
    uint16 _type,
    bytes memory _adapterParams,
    uint256 _extraGas
  ) internal view virtual {
    uint256 providedGasLimit = _getGasLimit(_adapterParams);
    uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;

    if (minGasLimit == 0) {
      revert MinGasLimitNotSet();
    }
    //require(minGasLimit > 0, "LzApp: minGasLimit not set");

    if (providedGasLimit < minGasLimit) {
      revert GasLimitIsTooLow();
    }
    //require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
  }

  function _getGasLimit(bytes memory _adapterParams)
    internal
    pure
    virtual
    returns (uint256 gasLimit)
  {
    if (_adapterParams.length < 34) {
      revert InvalidAdapterParams();
    }
    //require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");

    assembly {
      gasLimit := mload(add(_adapterParams, 34))
    }
  }

  //---------------------------UserApplication config----------------------------------------
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address,
    uint256 _configType
  ) external view returns (bytes memory) {
    return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
  }

  // generic config for LayerZero user Application
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external override onlyOwner {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setSendVersion(_version);
  }

  function setReceiveVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setReceiveVersion(_version);
  }

  function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    override
    onlyOwner
  {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }

  // _path = abi.encodePacked(remoteAddress, localAddress)
  // this function set the trusted path for the cross-chain communication
  function setTrustedRemote(uint16 _srcChainId, bytes calldata _path)
    external
    onlyOwner
  {
    trustedRemoteLookup[_srcChainId] = _path;
    emit SetTrustedRemote(_srcChainId, _path);
  }

  function setTrustedRemoteAddress(
    uint16 _remoteChainId,
    bytes calldata _remoteAddress
  ) external onlyOwner {
    trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
      _remoteAddress,
      address(this)
    );
    emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
  }

  function getTrustedRemoteAddress(uint16 _remoteChainId)
    external
    view
    returns (bytes memory)
  {
    bytes memory path = trustedRemoteLookup[_remoteChainId];
    if (path.length == 0) {
      revert NoTrustedPathRecord();
    }
    //require(path.length != 0, "LzApp: no trusted path record");

    return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
  }

  function setPrecrime(address _precrime) external onlyOwner {
    precrime = _precrime;
    emit SetPrecrime(_precrime);
  }

  function setMinDstGas(
    uint16 _dstChainId,
    uint16 _packetType,
    uint256 _minGas
  ) external onlyOwner {
    if (_minGas == 0) {
      revert InvalidMinGas();
    }
    //require(_minGas > 0, "LzApp: invalid minGas");

    minDstGasLookup[_dstChainId][_packetType] = _minGas;
    emit SetMinDstGas(_dstChainId, _packetType, _minGas);
  }

  //--------------------------- VIEW FUNCTION ----------------------------------------
  function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (bool)
  {
    bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
    return keccak256(trustedSource) == keccak256(_srcAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
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

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
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
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}