/*
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░██████████░░░░░██████████░░░███████████████░░██████████░░░░░██████████░░░░░
  ░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░
  ░░░░░█████░░░██████████░░░░░██████████░░░░░██████████░░░░░██████████░░█████░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░█████░░                                                            ░░░░░███░░
  ░░░░░░░░░░          ██████████                    ██████████          ░░░█████░░
  ░░░░░███░░        ██          ███               ██          ███       ░░░██░░░░░
  ░░░░░░░░░░     ███               ██          ███               ██     ░░░░░░░░░░
  ░░░█████░░     ███     █████     ██          ███     █████     ██     ░░░░░███░░
  ░░░░░░░░░░     ███       ███     ██   █████  ███       ███     ██     ░░░█████░░
  ░░░░░███░░     ███     █████     ██          ███     █████     ██     ░░░██░░░░░
  ░░░░░░░░░░     ███     █████     ██   █████  ███     █████     ██     ░░░░░░░░░░
  ░░░█████░░        ██          ███               ██          ███       ░░░██░░░░░
  ░░░░░░░░░░          ██████████        █████       ██████████          ░░░█████░░
  ░░░░░███░░                                                            ░░░░░███░░
  ░░░░░░░░░░     █████                                        █████     ░░░░░░░░░░
  ░░░█████░░     █████   █████  █████   █████  █████   █████  █████     ░░░██░░░░░
  ░░░░░░░░░░             █████  █████   █████     ██   █████            ░░░█████░░
  ░░░░░███░░                                                            ░░░░░███░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░███░░███░░████████░░████████░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░███░░███░░█████░░░░░████████░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░███░░███░░███░░░░░░░████████░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


                       scotato.eth, shahruz.eth, cjpais.eth

*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPC} from './interfaces/IOKPC.sol';
import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {SSTORE2} from '@0xsequence/sstore2/contracts/SSTORE2.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {IOKPCMetadata} from './interfaces/IOKPCMetadata.sol';

contract OKPC is IOKPC, ERC721A, IERC2981, Ownable, ReentrancyGuard {
  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   CONFIG                                   */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- MINTING -------------------------------- */
  uint256 public immutable MAX_SUPPLY;
  uint16 private immutable ARTISTS_RESERVED;
  uint16 private immutable TEAM_RESERVED;
  uint16 private immutable MAX_PER_PHASE;
  uint256 public immutable MINT_COST;
  /* --------------------------------- GALLERY -------------------------------- */
  uint8 private constant MAX_ART_PER_ARTIST = 8;
  uint8 private constant MIN_GALLERY_ART = 128;
  uint16 public constant MAX_COLLECT_PER_ART = 512;
  uint256 public constant ART_COLLECT_COST = 0.02 ether;
  /* -------------------------------- ROYALTIES ------------------------------- */
  uint256 private constant ROYALTY = 640;
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  uint256 public clockSpeedMaxMultiplier = 24;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- MINTING -------------------------------- */
  Phase public mintingPhase;
  mapping(address => bool) public earlyBirdsMintClaimed;
  mapping(address => bool) public friendsMintClaimed;
  bytes32 private _artistsMerkleRoot;
  bytes32 private _earlyBirdsMerkleRoot;
  bytes32 private _friendsMerkleRoot;
  /* --------------------------------- GALLERY -------------------------------- */
  bool public galleryOpen;
  uint256 public galleryArtCounter;
  uint256 private maxGalleryArt = 512;
  mapping(uint256 => uint256) public galleryArtCollectedCount;
  mapping(uint256 => address) private _galleryArtData;
  mapping(address => uint256) public galleryArtistArtCount;
  mapping(uint256 => uint256) public activeArtForOKPC;
  mapping(uint256 => mapping(uint256 => bool)) public artCollectedByOKPC;
  mapping(uint256 => uint256) public artCountForOKPC;
  mapping(bytes32 => bool) private _galleryArtHashes;
  /* ---------------------------------- PAINT --------------------------------- */
  bool public paintOpen;
  mapping(uint256 => Art) public paintArtForOKPC;
  mapping(uint256 => Commission) public openCommissionForOKPC;
  mapping(address => bool) public denyList;
  /* -------------------------------- RENDERER -------------------------------- */
  address public metadataAddress;
  mapping(uint256 => bool) public useOffchainMetadata;
  /* -------------------------------- PAYMENTS -------------------------------- */
  uint256 public paymentBalanceOwner;
  mapping(address => uint256) public paymentBalanceArtist;
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  mapping(uint256 => ClockSpeedXP) public clockSpeedData;
  /* ------------------------------- EXPANSIONS ------------------------------- */
  address public messagingAddress;
  address public communityAddress;
  address public marketplaceAddress;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */
  event hello();
  /* --------------------------------- MINTING -------------------------------- */
  event MintingPhaseStarted(Phase phase);
  /* --------------------------------- GALLERY -------------------------------- */
  event ArtChanged(uint256 pcId, uint256 artId);
  event GalleryOpenUpdated(bool open);
  event GalleryArtCreated(uint256 indexed artId, address artist);
  event GalleryArtCollected(uint256 pcId, uint256 artId);
  event GalleryArtSwapped(uint256 pcId1, uint256 pcId2);
  event GalleryArtTransferred(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  );
  event GalleryMaxArtUpdated(uint256 maxGalleryArt);
  /* ---------------------------------- PAINT --------------------------------- */
  event PaintOpenUpdated(bool open);
  event PaintArtCreated(uint256 indexed pcId, address artist);
  event CommissionCreated(uint256 pcId, address artist, uint256 amount);
  event CommissionCompleted(uint256 pcId, address artist, uint256 amount);
  event CommissionCancelled(uint256 pcId);
  /* -------------------------------- RENDERER -------------------------------- */
  event MetadataAddressUpdated(address addr);
  /* -------------------------------- PAYMENTS -------------------------------- */
  event PaymentWithdrawnOwner(uint256 amount);
  event PaymentWithdrawnArtist(address artist, uint256 amount);
  event PaymentReceivedArtist(address artist, uint256 amount);
  event PaymentReceivedOwner(uint256 amount);
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  event ClockSpeedMaxMultiplierUpdated(uint256 maxMultiplier);
  /* ------------------------------- EXPANSIONS ------------------------------- */
  event MessagingAddressUpdated(address messagingAddress);
  event CommunityAddressUpdated(address communityAddress);
  event MarketplaceAddressUpdated(address marketplaceAddress);

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */
  error NotOKPCOwner();
  error OKPCNotFound();
  error MerkleProofInvalid();
  error InvalidAddress();
  /* --------------------------------- MINTING -------------------------------- */
  error MintPhaseNotOpen();
  error MintTooManyOKPCs();
  error MintAlreadyClaimed();
  error MintMaxReached();
  error MintNotAuthorized();
  /* --------------------------------- GALLERY -------------------------------- */
  error GalleryNotOpen();
  error GalleryMinArtNotReached();
  error GalleryMaxArtReached();
  error GalleryArtNotFound();
  error GalleryArtAlreadyCollected();
  error GalleryArtNotCollected();
  error GalleryArtCollectedMaximumTimes();
  error GalleryArtCannotBeActive();
  error GalleryArtDuplicate();
  error GalleryArtLastCollected();
  /* ---------------------------------- PAINT --------------------------------- */
  error PaintArtDataInvalid();
  error PaintArtNotFound();
  error PaintNotOpen();
  error PaintDenyList();
  error PaintCommissionInvalid();
  error PaintNotCommissionedArtist();
  /* -------------------------------- PAYMENTS -------------------------------- */
  error PaymentAmountInvalid();
  error PaymentBalanceZero();
  error PaymentTransferFailed();
  /* ------------------------------- EXPANSIONS ------------------------------- */
  error NotCommunityAddress();
  error NotMarketplaceAddress();
  error NotOwnerOrCommunity();

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  MODIFIERS                                 */
  /* -------------------------------------------------------------------------- */
  /// @notice Requires the caller to be the owner of the specified pcId.
  modifier onlyOwnerOf(uint256 pcId) {
    if (msg.sender != ownerOf(pcId)) revert NotOKPCOwner();
    _;
  }
  /* --------------------------------- MINTING -------------------------------- */
  /// @notice Requires the current total OKPC supply to be less than the max supply for the current phase.
  modifier onlyIfSupplyMintable() {
    if (
      _currentIndex >
      ARTISTS_RESERVED + TEAM_RESERVED + (uint256(mintingPhase) * MAX_PER_PHASE)
    ) revert MintMaxReached();
    _;
  }
  /// @notice Requires the specified minting phase be active.
  modifier onlyIfMintingPhaseIsSetTo(Phase phase) {
    if (mintingPhase != phase) revert MintPhaseNotOpen();
    _;
  }
  /// @notice Requires the specified minting phase be active or have been active before
  modifier onlyIfMintingPhaseIsSetToOrAfter(Phase minimumPhase) {
    if (mintingPhase < minimumPhase) revert MintPhaseNotOpen();
    _;
  }
  /// @notice Requires the a valid merkle proof for the specified merkle root.
  modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
    if (
      !MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender)))
    ) revert MerkleProofInvalid();
    _;
  }
  /// @notice Requires no earlier claims for the caller in the Early Birds mint.
  modifier onlyIfNotAlreadyClaimedEarlyBirds() {
    if (earlyBirdsMintClaimed[msg.sender]) revert MintAlreadyClaimed();
    _;
  }
  /// @notice Requires no earlier claims for the caller in the Friends mint.
  modifier onlyIfNotAlreadyClaimedFriends() {
    if (friendsMintClaimed[msg.sender]) revert MintAlreadyClaimed();
    _;
  }
  /* --------------------------------- GALLERY -------------------------------- */
  /// @notice Requires Gallery to be open.
  modifier onlyIfGalleryOpen() {
    if (!galleryOpen) revert GalleryNotOpen();
    _;
  }
  /// @notice Requires the artId corresponds to existing Gallery art.
  modifier onlyIfGalleryArtExists(uint256 artId) {
    if (artId > galleryArtCounter || artId == 0) revert GalleryArtNotFound();
    _;
  }
  /// @notice Requires the pcId to have artId in its collection already
  modifier onlyIfOKPCHasCollectedGalleryArt(uint256 pcId, uint256 artId) {
    if (!artCollectedByOKPC[pcId][artId]) revert GalleryArtNotCollected();
    _;
  }
  /// @notice Requires the minimum amount of Gallery art to be uploaded already.
  modifier onlyAfterMinimumGalleryArtUploaded() {
    if (galleryArtCounter < MIN_GALLERY_ART) revert GalleryMinArtNotReached();
    _;
  }
  /* ---------------------------------- PAINT --------------------------------- */
  /// @notice Requires Paint to be open.
  modifier onlyIfPaintOpen() {
    if (!paintOpen) revert PaintNotOpen();
    _;
  }
  /* -------------------------------- PAYMENTS -------------------------------- */
  /// @notice Requires msg.value be exactly the specified amount.
  modifier onlyIfPaymentAmountValid(uint256 value) {
    if (msg.value != value) revert PaymentAmountInvalid();
    _;
  }
  /* ------------------------------- EXPANSIONS ------------------------------- */
  /// @notice Requires the caller be the owner or community address.
  modifier onlyOwnerOrCommunity() {
    if (msg.sender != communityAddress && msg.sender != owner())
      revert NotOwnerOrCommunity();
    _;
  }
  /// @notice Requires the caller be the community address.
  modifier onlyCommunity() {
    if (msg.sender != communityAddress) revert NotCommunityAddress();
    _;
  }
  /// @notice Requires the caller be the marketplace address.
  modifier onlyMarketplace() {
    if (msg.sender != marketplaceAddress) revert NotMarketplaceAddress();
    _;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */
  constructor(
    uint16 artistsReserved,
    uint16 teamReserved,
    uint16 maxPerPhase,
    uint256 mintCost
  ) ERC721A('OKPC', 'OKPC') {
    ARTISTS_RESERVED = artistsReserved;
    TEAM_RESERVED = teamReserved;
    MAX_PER_PHASE = maxPerPhase;
    MAX_SUPPLY = ARTISTS_RESERVED + TEAM_RESERVED + (MAX_PER_PHASE * 3);
    MINT_COST = mintCost;

    emit hello();
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows owner to set a merkle root for Artists.
  /// @param newRoot The new merkle root to set.
  function setArtistsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _artistsMerkleRoot = newRoot;
  }

  /// @notice Allows owner to set a merkle root for Early Birds.
  /// @param newRoot The new merkle root to set.
  function setEarlyBirdsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _earlyBirdsMerkleRoot = newRoot;
  }

  /// @notice Allows owner to set a merkle root for Friends.
  /// @param newRoot The new merkle root to set.
  function setFriendsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _friendsMerkleRoot = newRoot;
  }

  /// @notice Allows the owner to upload initial Gallery art before minting opens.
  /// @param data The data of the art to be uploaded for 128 art pieces
  function addInitialGalleryArt(bytes calldata data) external onlyOwner {
    if (galleryArtCounter > 0) revert GalleryMaxArtReached();
    if (data.length != uint256(MIN_GALLERY_ART) * 128)
      revert PaintArtDataInvalid();

    for (uint256 i; i < MIN_GALLERY_ART; i++) {
      uint256 artId = i + 1;

      (address artist, uint256 data1, uint256 data2, bytes16 title) = abi
        .decode(
          data[i * MIN_GALLERY_ART:artId * MIN_GALLERY_ART],
          (address, uint256, uint256, bytes16)
        );

      if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
      if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
        revert GalleryArtDuplicate();
      if (galleryArtistArtCount[artist] == MAX_ART_PER_ARTIST)
        revert GalleryMaxArtReached();

      unchecked {
        galleryArtistArtCount[artist]++;
      }
      _galleryArtHashes[keccak256(abi.encodePacked(data1, data2))] = true;

      emit GalleryArtCreated(artId, artist);
    }

    _galleryArtData[0] = SSTORE2.write(data);
    galleryArtCounter = MIN_GALLERY_ART;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   MINTING                                  */
  /* -------------------------------------------------------------------------- */
  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows owner to mint 64 OKPCs to a list of 64 artist addresses.
  /// @param addr An array of 64 artist addresses.
  function mintArtists(address[64] calldata addr)
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    nonReentrant
  {
    if (_currentIndex > ARTISTS_RESERVED) revert MintMaxReached();
    for (uint16 i; i < 64; i++) {
      _collectIncludedGalleryArt(_currentIndex);
      _safeMint(addr[i], 1);
    }
  }

  /// @notice Allows owner to mint 64 OKPCs to a list of 4 team addresses.
  /// @param addr An array of 4 team addresses.
  function mintTeam(address[4] calldata addr)
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    nonReentrant
  {
    if (_currentIndex < ARTISTS_RESERVED) revert MintPhaseNotOpen();
    if (_currentIndex > ARTISTS_RESERVED + TEAM_RESERVED)
      revert MintMaxReached();
    for (uint16 i; i < 64; i++) {
      _collectIncludedGalleryArt(_currentIndex);
      _safeMint(addr[i % 4], 1);
    }
  }

  /* ------------------------------- EARLY BIRDS ------------------------------ */
  /// @notice Allows the owner to start the Early Birds minting phase.
  function startEarlyBirdsMint()
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    onlyIfMintingPhaseIsSetTo(Phase.INIT)
  {
    if (_currentIndex <= 512) revert MintPhaseNotOpen();
    mintingPhase = Phase.EARLY_BIRDS;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC if you're on the Early Birds list.
  /// @param merkleProof A Merkle proof of the caller's address in the Early Birds list.
  function mintEarlyBirds(bytes32[] calldata merkleProof)
    external
    payable
    onlyIfMintingPhaseIsSetToOrAfter(Phase.EARLY_BIRDS)
    onlyIfValidMerkleProof(_earlyBirdsMerkleRoot, merkleProof)
    onlyIfPaymentAmountValid(MINT_COST)
    onlyIfNotAlreadyClaimedEarlyBirds
    onlyIfSupplyMintable
    nonReentrant
  {
    earlyBirdsMintClaimed[msg.sender] = true;

    _collectIncludedGalleryArt(_currentIndex);

    addToOwnerBalance(MINT_COST - ART_COLLECT_COST);
    addToArtistBalance(
      getGalleryArt(_includedGalleryArtForOKPC(_currentIndex)).artist,
      ART_COLLECT_COST
    );

    _safeMint(msg.sender, 1);
  }

  /* --------------------------------- FRIENDS -------------------------------- */
  /// @notice Allows the owner to start the Friends minting phase.
  function startFriendsMint()
    external
    onlyOwner
    onlyIfMintingPhaseIsSetTo(Phase.EARLY_BIRDS)
  {
    mintingPhase = Phase.FRIENDS;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC if you're on the Friends list.
  /// @param merkleProof A Merkle proof of the caller's address in the Friends list.
  function mintFriends(bytes32[] calldata merkleProof)
    external
    payable
    onlyIfMintingPhaseIsSetToOrAfter(Phase.FRIENDS)
    onlyIfValidMerkleProof(_friendsMerkleRoot, merkleProof)
    onlyIfPaymentAmountValid(MINT_COST)
    onlyIfSupplyMintable
    onlyIfNotAlreadyClaimedFriends
    nonReentrant
  {
    friendsMintClaimed[msg.sender] = true;

    _collectIncludedGalleryArt(_currentIndex);

    addToOwnerBalance(MINT_COST - ART_COLLECT_COST);
    addToArtistBalance(
      getGalleryArt(_includedGalleryArtForOKPC(_currentIndex)).artist,
      ART_COLLECT_COST
    );

    _safeMint(msg.sender, 1);
  }

  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Allows the owner to start the Public minting phase.
  function startPublicMint()
    external
    onlyOwner
    onlyIfMintingPhaseIsSetTo(Phase.FRIENDS)
  {
    mintingPhase = Phase.PUBLIC;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC.
  /// @param amount The number of OKPCs to mint. Accepts values between 1 and 8.
  function mint(uint256 amount)
    external
    payable
    onlyIfMintingPhaseIsSetTo(Phase.PUBLIC)
    onlyIfSupplyMintable
    onlyIfPaymentAmountValid(MINT_COST * amount)
    nonReentrant
  {
    if (amount > 8) revert MintTooManyOKPCs();
    if (tx.origin != msg.sender) revert MintNotAuthorized();

    addToOwnerBalance(amount * (MINT_COST - ART_COLLECT_COST));

    for (uint256 i; i < amount; i++) {
      _collectIncludedGalleryArt(_currentIndex + i);
      addToArtistBalance(
        getGalleryArt(_includedGalleryArtForOKPC(_currentIndex + i)).artist,
        ART_COLLECT_COST
      );
    }

    _safeMint(msg.sender, amount);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   GALLERY                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Returns data for the specified Gallery art.
  /// @param artId The artId to look for in the Gallery.
  function getGalleryArt(uint256 artId)
    public
    view
    onlyIfGalleryArtExists(artId)
    returns (Art memory)
  {
    if (artId <= MIN_GALLERY_ART) {
      uint256 artBucket = (artId - 1) / MIN_GALLERY_ART;
      uint256 artBucketOffset = (artId - 1) % MIN_GALLERY_ART;
      (address addr, uint256 data1, uint256 data2, bytes16 title) = abi.decode(
        SSTORE2.read(
          _galleryArtData[artBucket],
          artBucketOffset * 128,
          (artBucketOffset + 1) * 128
        ),
        (address, uint256, uint256, bytes16)
      );
      return Art(addr, title, data1, data2);
    } else {
      (address addr, uint256 data1, uint256 data2, bytes16 title) = abi.decode(
        SSTORE2.read(_galleryArtData[artId]),
        (address, uint256, uint256, bytes16)
      );
      return Art(addr, title, data1, data2);
    }
  }

  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Collect artwork from the Gallery on your OKPC.
  /// @param pcId The id of the OKPC to collect the gallery to.
  /// @param artId The id of the artwork you'd like to collect.
  /// @param makeActive Set to true to switch your OKPC to displaying this art.
  function collectArt(
    uint256 pcId,
    uint256 artId,
    bool makeActive
  )
    external
    payable
    onlyIfGalleryOpen
    onlyOwnerOf(pcId)
    onlyIfGalleryArtExists(artId)
  {
    address artist = getGalleryArt(artId).artist;
    if (msg.sender != artist && msg.value != ART_COLLECT_COST)
      revert PaymentAmountInvalid();
    else if (msg.sender == artist && msg.value > 0)
      revert PaymentAmountInvalid();

    if (msg.value > 0) addToArtistBalance(artist, msg.value);

    _collectGalleryArt(pcId, artId);

    if (makeActive) setGalleryArt(pcId, artId);
  }

  /// @notice Collect multiple Gallery artworks on your OKPC.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC.
  /// @param artIds An array of ids for the art you'd like to collect.
  function collectArt(uint256 pcId, uint256[] calldata artIds)
    external
    payable
    onlyIfGalleryOpen
    onlyOwnerOf(pcId)
  {
    if (msg.value != ART_COLLECT_COST * artIds.length)
      revert PaymentAmountInvalid();

    for (uint256 i; i < artIds.length; i++) {
      if (artIds[i] > galleryArtCounter || artIds[i] == 0)
        revert GalleryArtNotFound();

      addToArtistBalance(getGalleryArt(artIds[i]).artist, ART_COLLECT_COST);

      _collectGalleryArt(pcId, artIds[i]);
    }
  }

  /// @notice Switch the active Gallery art on your OKPC.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC.
  /// @param artId A id of the art you'd like to display. If your OKPC has custom art, you can display it by setting this to 0.
  function setGalleryArt(uint256 pcId, uint256 artId)
    public
    onlyOwnerOf(pcId)
    onlyIfOKPCHasCollectedGalleryArt(pcId, artId)
  {
    activeArtForOKPC[pcId] = artId;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, artId);
  }

  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Post new Gallery artwork if you're an OKPC artist.
  /// @param title The title of the artwork.
  /// @param data1 The first part of the art data to be stored.
  /// @param data1 The second part of the art data to be stored.
  /// @param merkleProof A Merkle proof of the caller's address in the Artists list.
  function addGalleryArt(
    bytes16 title,
    uint256 data1,
    uint256 data2,
    bytes32[] calldata merkleProof
  ) external onlyIfValidMerkleProof(_artistsMerkleRoot, merkleProof) {
    if (denyList[msg.sender]) revert PaintDenyList();
    if (galleryArtCounter == maxGalleryArt) revert GalleryMaxArtReached();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
    if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
      revert GalleryArtDuplicate();
    if (galleryArtistArtCount[msg.sender] == MAX_ART_PER_ARTIST)
      revert GalleryMaxArtReached();

    unchecked {
      galleryArtistArtCount[msg.sender]++;
      galleryArtCounter++;
    }
    _galleryArtHashes[keccak256(abi.encodePacked(data1, data2))] = true;

    _galleryArtData[galleryArtCounter] = SSTORE2.write(
      abi.encode(msg.sender, data1, data2, title)
    );

    emit GalleryArtCreated(galleryArtCounter, msg.sender);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Toggles the Gallery interactions on or off.
  function toggleGalleryOpen() external onlyOwner {
    galleryOpen = !galleryOpen;
    emit GalleryOpenUpdated(galleryOpen);
  }

  /// @notice Allows the owner to increase the size of the Gallery.
  /// @param newMaxGalleryArt The new maximum number of Gallery artworks. Must be greater than the previous amount.
  function increaseMaxGalleryArt(uint256 newMaxGalleryArt) external onlyOwner {
    if (maxGalleryArt >= newMaxGalleryArt) revert GalleryMaxArtReached();
    maxGalleryArt = newMaxGalleryArt;
    emit GalleryMaxArtUpdated(maxGalleryArt);
  }

  /// @notice Allows the owner or community to moderate Gallery artwork.
  /// @param artId The id of the Gallery artwork to moderate.
  /// @param title The title for the replacement art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  /// @param artist The address of the artist of the replacement art.
  function moderateGalleryArt(
    uint256 artId,
    bytes16 title,
    uint256 data1,
    uint256 data2,
    address artist
  ) external onlyOwnerOrCommunity {
    if (artId <= 128) revert PaintArtDataInvalid();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();

    Art memory art = getGalleryArt(artId);
    galleryArtistArtCount[art.artist]--;

    unchecked {
      galleryArtistArtCount[artist]++;
    }

    _galleryArtData[artId] = SSTORE2.write(
      abi.encode(artist, data1, data2, title)
    );

    emit GalleryArtCreated(galleryArtCounter, msg.sender);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Collects Gallery artwork to your OKPC.
  /// @param pcId The id of the OKPC to collect to.
  /// @param artId The id of the Gallery art you'd like to collect.
  function _collectGalleryArt(uint256 pcId, uint256 artId) internal {
    if (artCollectedByOKPC[pcId][artId]) revert GalleryArtAlreadyCollected();
    if (galleryArtCollectedCount[artId] == MAX_COLLECT_PER_ART)
      revert GalleryArtCollectedMaximumTimes();

    artCollectedByOKPC[pcId][artId] = true;

    unchecked {
      artCountForOKPC[pcId]++;
      galleryArtCollectedCount[artId]++;
    }

    emit GalleryArtCollected(pcId, artId);
  }

  /// @notice Determines the included Gallery artwork for an OKPC.
  /// @param pcId The id of the OKPC being minted.
  function _includedGalleryArtForOKPC(uint256 pcId)
    internal
    view
    returns (uint256)
  {
    return
      pcId <= 128
        ? pcId
        : (uint256(
          keccak256(
            abi.encodePacked(
              'OKPC',
              pcId,
              blockhash(block.number - 1),
              block.coinbase,
              block.difficulty,
              msg.sender
            )
          )
        ) % galleryArtCounter) + 1;
  }

  /// @notice Collects the included Gallery artwork for an OKPC.
  /// @param pcId The id of the OKPC being minted.
  function _collectIncludedGalleryArt(uint256 pcId) internal {
    uint256 artId = _includedGalleryArtForOKPC(pcId);

    artCountForOKPC[pcId] = 1;
    artCollectedByOKPC[pcId][artId] = true;
    emit GalleryArtCollected(pcId, artId);

    activeArtForOKPC[pcId] = artId;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, artId);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                    PAINT                                   */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Get the Paint art stored on an OKPC.
  /// @param pcId The id of the OKPC to look up.
  function getPaintArt(uint256 pcId) public view returns (Art memory) {
    if (paintArtForOKPC[pcId].artist == address(0)) revert PaintArtNotFound();
    return paintArtForOKPC[pcId];
  }

  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Displays stored Paint art on your OKPC.
  /// @param pcId The id of the OKPC to display. You'll need to own the OKPC.
  function setPaintArt(uint256 pcId) external onlyOwnerOf(pcId) {
    if (paintArtForOKPC[pcId].artist == address(0)) revert PaintArtNotFound();
    activeArtForOKPC[pcId] = 0;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, 0);
  }

  /// @notice Stores and displays stored Paint art on your OKPC.
  /// @param pcId The id of the OKPC to store Paint art on. You'll need to own the OKPC.
  /// @param title The title of the Paint art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  function setPaintArt(
    uint256 pcId,
    bytes16 title,
    uint256 data1,
    uint256 data2
  ) external onlyIfPaintOpen onlyOwnerOf(pcId) {
    _setPaintArt(pcId, title, msg.sender, data1, data2);
  }

  /// @notice Create a commission for another artist to use Paint on your OKPC.
  /// @param pcId The id of the OKPC to use. You'll need to own the OKPC.
  /// @param artist The address of the artist to create a commission for.
  function createCommission(uint256 pcId, address artist)
    external
    payable
    onlyOwnerOf(pcId)
    onlyIfPaintOpen
    nonReentrant
  {
    if (artist == address(0)) revert PaintCommissionInvalid();
    if (msg.sender == artist) revert PaintCommissionInvalid();

    if (openCommissionForOKPC[pcId].artist != address(0))
      cancelCommission(pcId);

    openCommissionForOKPC[pcId] = Commission(artist, msg.value);

    emit CommissionCreated(pcId, artist, msg.value);
  }

  /// @notice Cancels a commission
  /// @param pcId The id of the OKPC to cancel a commission on. You'll need to own the OKPC.
  function cancelCommission(uint256 pcId)
    public
    onlyOwnerOf(pcId)
    onlyIfPaintOpen
  {
    _cancelCommission(pcId);
  }

  /// @notice Cancels a commission. This may be called by the owner of the OKPC or when a token is being transferred.
  /// @param pcId The id of the OKPC to cancel a commission on.
  function _cancelCommission(uint256 pcId) internal nonReentrant {
    if (openCommissionForOKPC[pcId].artist == address(0))
      revert PaintCommissionInvalid();

    uint256 amount = openCommissionForOKPC[pcId].amount;
    delete openCommissionForOKPC[pcId];

    if (amount > 0) {
      (bool success, ) = ownerOf(pcId).call{value: amount}('');
      if (!success) revert PaymentTransferFailed();
    }

    emit CommissionCancelled(pcId);
  }

  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Completes a commission.
  /// @param pcId The id of the OKPC to complete a commission for.
  /// @param title The title of the new art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  function completeCommission(
    uint256 pcId,
    bytes16 title,
    uint256 data1,
    uint256 data2
  ) external onlyIfPaintOpen nonReentrant {
    if (msg.sender != openCommissionForOKPC[pcId].artist)
      revert PaintNotCommissionedArtist();

    _setPaintArt(pcId, title, msg.sender, data1, data2);

    uint256 amount = openCommissionForOKPC[pcId].amount;
    delete openCommissionForOKPC[pcId];
    if (amount > 0) {
      (bool success, ) = msg.sender.call{value: amount}('');
      if (!success) revert PaymentTransferFailed();
    }

    emit CommissionCompleted(pcId, msg.sender, amount);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Toggles the Paint interactions on or off.
  function togglePaintOpen() external onlyOwner {
    paintOpen = !paintOpen;
    emit PaintOpenUpdated(paintOpen);
  }

  /// @notice Allows the owner to update the deny list status for an address.
  /// @param artist The address of the artist to update.
  /// @param deny Whether to deny the artist or not from submitting Art.
  function setDenyListStatus(address artist, bool deny) external onlyOwner {
    denyList[artist] = deny;
  }

  /// @notice Allows the owner or community to moderate Paint art and revert to collected Gallery art.
  /// @param pcId The OKPC containing the Paint art.
  /// @param artId The Gallery Art to revert to. This must already be owned by the OKPC.
  function moderatePaintArt(uint256 pcId, uint256 artId)
    external
    onlyOwnerOrCommunity
    onlyIfOKPCHasCollectedGalleryArt(pcId, artId)
  {
    if (getPaintArt(pcId).artist == address(0)) revert PaintArtNotFound();

    delete paintArtForOKPC[pcId];

    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Stores and displays Paint art on an OKPC.
  function _setPaintArt(
    uint256 pcId,
    bytes16 title,
    address artist,
    uint256 data1,
    uint256 data2
  ) internal {
    if (denyList[artist]) revert PaintDenyList();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
    if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
      revert GalleryArtDuplicate();

    paintArtForOKPC[pcId].artist = artist;
    paintArtForOKPC[pcId].title = title;
    paintArtForOKPC[pcId].data1 = data1;
    paintArtForOKPC[pcId].data2 = data2;
    emit PaintArtCreated(pcId, artist);

    activeArtForOKPC[pcId] = 0;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, 0);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  RENDERER                                  */
  /* -------------------------------------------------------------------------- */
  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Toggles the off-chain renderer for your OKPC.
  /// @param pcId The OKPC to toggle.
  function switchOKPCRenderer(uint256 pcId) external onlyOwnerOf(pcId) {
    useOffchainMetadata[pcId] = !useOffchainMetadata[pcId];
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Updates the metadata address for OKPC.
  /// @param addr The new metadata address. Must conform to IOKPCMetadata.
  function setMetadataAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    metadataAddress = addr;
    emit MetadataAddressUpdated(addr);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  PAYMENTS                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Sends you your full available balance if you're an OKPC artist.
  function withdrawArtistBalance() external nonReentrant {
    uint256 balance = paymentBalanceArtist[msg.sender];
    if (balance == 0) revert PaymentBalanceZero();
    paymentBalanceArtist[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: balance}('');
    if (!success) revert PaymentBalanceZero();

    emit PaymentWithdrawnArtist(msg.sender, balance);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Sends you your full available balance if you're the OKPC.
  /// @param withdrawTo The address to send the balance to.
  function withdrawOwnerBalance(address withdrawTo)
    external
    onlyOwner
    nonReentrant
  {
    if (paymentBalanceOwner == 0) revert PaymentBalanceZero();
    uint256 balance = paymentBalanceOwner;
    paymentBalanceOwner = 0;

    (bool success, ) = withdrawTo.call{value: balance}('');
    if (!success) revert PaymentBalanceZero();

    emit PaymentWithdrawnOwner(balance);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Adds funds to the payment balance for the specified address.
  /// @param artist The address to add funds to.
  /// @param amount The amount to add to the balance.
  function addToArtistBalance(address artist, uint256 amount) internal {
    emit PaymentReceivedArtist(artist, amount);
    paymentBalanceArtist[artist] += amount;
  }

  /// @notice Adds funds to the payment balance for the owner.
  /// @param amount The amount to add to the balance.
  function addToOwnerBalance(uint256 amount) internal {
    emit PaymentReceivedOwner(amount);
    paymentBalanceOwner += amount;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  ROYALTIES                                 */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice EIP2981 royalty standard
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * ROYALTY) / 10000);
  }

  /// @notice Receive royalties
  receive() external payable {
    addToOwnerBalance(msg.value);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                 CLOCK SPEED                                */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Returns the clockspeed for the specified OKPC.
  /// @param pcId The id of the OKPC to look up.
  function clockSpeed(uint256 pcId) public view returns (uint256) {
    uint256 lastBlock = clockSpeedData[pcId].lastSaveBlock;
    if (lastBlock == 0) {
      return 1;
    }
    uint256 delta = block.number - lastBlock;
    uint256 multiplier = delta / 200_000;
    if (multiplier > clockSpeedMaxMultiplier) {
      multiplier = clockSpeedMaxMultiplier;
    }
    uint256 total = clockSpeedData[pcId].savedSpeed +
      ((delta * (multiplier + 1)) / 10_000);
    if (total < 1) total = 1;
    return total;
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows the owner to update the maximum clockspeed multiplier.
  /// @param multiplier The new max clockspeed multiplier to set.
  function setClockSpeedMaxMultiplier(uint256 multiplier) external onlyOwner {
    clockSpeedMaxMultiplier = multiplier;
    emit ClockSpeedMaxMultiplierUpdated(multiplier);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Saves clockspeed data. Called before an OKPC is transferred.
  function _saveClockSpeed(uint256 pcId) internal {
    clockSpeedData[pcId].savedSpeed = clockSpeed(pcId);
    clockSpeedData[pcId].lastSaveBlock = block.number;
    unchecked {
      clockSpeedData[pcId].transferCount++;
    }
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                 EXPANSIONS                                 */
  /* -------------------------------------------------------------------------- */
  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows the owner to update the Messaging address.
  /// @param addr The new Messaging address.
  function setMessagingAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    messagingAddress = addr;
    emit MessagingAddressUpdated(addr);
  }

  /// @notice Allows the owner to update the Community address.
  /// @param addr The new Community address.
  function setCommunityAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    communityAddress = addr;
    emit CommunityAddressUpdated(addr);
  }

  /// @notice Allows the owner to update the Marketplace address.
  /// @param addr The new Marketplace address.
  function setMarketplaceAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    marketplaceAddress = addr;
    emit MarketplaceAddressUpdated(addr);
  }

  /* ------------------------------- MARKETPLACE ------------------------------ */
  /// @notice Allows the Marketplace contract to transfer art between OKPCs.
  /// @param fromOKPCId The id of the OKPC to transfer from.
  /// @param toOKPCId The id of the OKPC to transfer to.
  /// @param artId The id of the Gallery artwork to transfer.
  function transferArt(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  ) external onlyMarketplace onlyIfGalleryArtExists(artId) {
    if (!artCollectedByOKPC[fromOKPCId][artId]) revert GalleryArtNotCollected();

    if (artCollectedByOKPC[toOKPCId][artId])
      revert GalleryArtAlreadyCollected();

    if (artCountForOKPC[fromOKPCId] == 1) revert GalleryArtLastCollected();

    if (activeArtForOKPC[fromOKPCId] == artId)
      revert GalleryArtCannotBeActive();

    artCollectedByOKPC[fromOKPCId][artId] = false;
    artCountForOKPC[fromOKPCId]--;

    artCollectedByOKPC[toOKPCId][artId] = true;
    unchecked {
      artCountForOKPC[toOKPCId]++;
    }
    emit GalleryArtTransferred(fromOKPCId, toOKPCId, artId);
  }

  /// @notice Allows the Marketplace contract to add funds to an artist's withdrawable balance.
  /// @param artist The address to add funds to.
  function addToArtistBalanceFromMarketplace(address artist)
    external
    payable
    onlyMarketplace
  {
    addToArtistBalance(artist, msg.value);
  }

  /// @notice Allows the Marketplace contract to add funds to the owner's withdrawable balance.
  function addToOwnerBalanceFromMarketplace() external payable onlyMarketplace {
    addToOwnerBalance(msg.value);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   ERC721A                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice The standard ERC721 tokenURI function. Routes to the Metadata contract.
  function tokenURI(uint256 pcId) public view override returns (string memory) {
    if (!_exists(pcId)) revert OKPCNotFound();
    return IOKPCMetadata(metadataAddress).tokenURI(pcId);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice ERC721A override to start tokenId's at 1 instead of 0.
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @notice Overrides _beforeTokenTransfers to update clockspeeds and clear any active commissions.
  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    for (uint256 i; i < quantity; i++) {
      uint256 pcId = startTokenId + i;
      _saveClockSpeed(pcId);
      if (openCommissionForOKPC[pcId].artist != address(0))
        _cancelCommission(pcId);
    }
  }

  /* --------------------------------- ****** --------------------------------- */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

interface IOKPC {
  enum Phase {
    INIT,
    EARLY_BIRDS,
    FRIENDS,
    PUBLIC
  }
  struct Art {
    address artist;
    bytes16 title;
    uint256 data1;
    uint256 data2;
  }
  struct Commission {
    address artist;
    uint256 amount;
  }
  struct ClockSpeedXP {
    uint256 savedSpeed;
    uint256 lastSaveBlock;
    uint256 transferCount;
    uint256 artLastChanged;
  }

  function getPaintArt(uint256) external view returns (Art memory);

  function getGalleryArt(uint256) external view returns (Art memory);

  function activeArtForOKPC(uint256) external view returns (uint256);

  function useOffchainMetadata(uint256) external view returns (bool);

  function clockSpeed(uint256) external view returns (uint256);

  function artCountForOKPC(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPC} from './IOKPC.sol';
import {IOKPCParts} from './IOKPCParts.sol';

interface IOKPCMetadata {
  error InvalidTokenID();
  error NotEnoughPixelData();

  struct Parts {
    IOKPCParts.Vector headband;
    IOKPCParts.Vector rightSpeaker;
    IOKPCParts.Vector leftSpeaker;
    IOKPCParts.Color color;
    string word;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function renderArt(bytes memory art, uint256 colorIndex)
    external
    view
    returns (string memory);

  function getParts(uint256 tokenId) external view returns (Parts memory);

  function drawArt(bytes memory artData) external pure returns (string memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface IOKPCParts {
  // errors
  error IndexOutOfBounds(uint256 index, uint256 maxIndex);

  // structures
  struct Color {
    bytes6 light;
    bytes6 regular;
    bytes6 dark;
    string name;
  }

  struct Vector {
    string data;
    string name;
  }

  // functions
  function getColor(uint256 index) external view returns (Color memory);

  function getHeadband(uint256 index) external view returns (Vector memory);

  function getSpeaker(uint256 index) external view returns (Vector memory);

  function getWord(uint256 index) external view returns (string memory);
}