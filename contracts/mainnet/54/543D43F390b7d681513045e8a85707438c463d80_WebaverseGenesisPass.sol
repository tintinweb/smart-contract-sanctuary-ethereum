// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IWebaverseLand.sol";

/**
 *
 * @dev Inheritance details:
 *      ERC721            ERC721 token standard, imported from openzeppelin
 *      Pausable          Allows functions to be Paused, note that this contract includes the metadrop
 *                        time-limited pause, where the contract can only be paused for a defined time period.
 *                        Imported from openzeppelin.
 *      Ownable           Allow priviledged access to certain functions. Imported from openzeppelin.
 *      ERC721Burnable    Helper library for convenient burning of ERC721s. Imported from openzeppelin.
 *      VRFConsumerBaseV2   Chainlink RNG contract. Imported from chainlink.
 *
 */
contract WebaverseGenesisPass is
  ERC721,
  Pausable,
  Ownable,
  ERC721Burnable,
  VRFConsumerBaseV2
{
  using SafeERC20 for IERC20;
  using Strings for uint256;

  /**
   * @dev Chainlink config.
   */
  VRFCoordinatorV2Interface vrfCoordinator;
  uint64 vrfSubscriptionId;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 vrfKeyHash;
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 vrfCallbackGasLimit = 150000;
  // The default is 3, but you can set this higher.
  uint16 vrfRequestConfirmations = 3;
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 vrfNumWords = 1;

  uint256 public immutable maxSupply;
  uint256 public immutable numberOfCommunities;
  uint256 public immutable mintPrice;
  uint256 public immutable maxCommunityWhitelistLength;
  uint256 public immutable whitelistMintStart;
  uint256 public immutable whitelistMintEnd;
  address payable public immutable beneficiaryAddress;

  string private _tokenBaseURI;
  string public placeholderTokenURI;

  uint256 public communityRandomness;

  uint256 private _royaltyPercentageBasisPoints;

  uint256 public tokenIdCounter;

  uint256 public burnCounter;

  // Slot size (32 + 160 + 8 + 8 + 8 = 216)
  // ERC-2981: NFT Royalty Standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address private _royaltyReceipientAddress;
  bool public tokenBaseURILocked;
  bool public listsLocked;
  bool public webaverseLandAddressLocked;
  bool public placeholderTokenURILocked;

  // Claim whitelist merkle root - for auction
  // hash(quantity, address)
  bytes32 public claimWhitelistMerkleRoot;
  mapping(address => bool) private _claimHasMinted;

  // Treasury whitelist merkle root - for metadrop & webaverse treasury
  // hash(quantity, address)
  bytes32 public treasuryWhitelistMerkleRoot;
  mapping(address => uint256) private _treasuryAllocationMinted;

  // Direct whitelist merkle root
  // hash(position, address)
  bytes32 public directWhitelistMerkleRoot;

  // Community whitelist merkle root
  // hash(community, position, address)
  bytes32 public communityWhitelistMerkleRoot;
  // Community ID => Community whitelist merkle length
  mapping(uint256 => uint256) public communityWhitelistLengths;

  // Completion whitelist merkle root
  // hash(quantity, address, unitPrice)
  bytes32 public completionWhitelistMerkleRoot;
  mapping(address => uint256) private _completionAllocationMinted;

  uint256 public pauseCutoffDays;

  // Single bool for first stage mint (direct and community) - each
  // address can only mint once, regardless of multiple eligibility:
  mapping(address => bool) private _firstStageAddressHasMinted;

  // Webaverse Land contract address:
  address public webaverseLandAddress;

  /**
   *
   * @dev constructor: Must be passed following addresses:
   *                   * chainlink VRF address and Link token address
   *
   */
  constructor(
    // configIntegers array must contain the following:
    // [0]: numberOfCommunities (e.g. 7)
    // [1]: maxCommunityWhitlistLength (how many slots are open per community, beyond which we 'lottery' using a randon start position)
    // [2]: whitelistMintStart (timestamp of when the stage 1 mint will start)
    // [3]: pauseCutoffDays (when the ability to pause this contract expires)
    uint256[] memory configIntegers_,
    uint256 maxSupply_,
    uint256 mintPrice_,
    address royaltyReceipientAddress_,
    uint256 royaltyPercentageBasisPoints_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    address payable beneficiaryAddress_
  )
    ERC721("Webaverse Genesis Pass", "WEBA")
    VRFConsumerBaseV2(vrfCoordinator_)
  {
    numberOfCommunities = configIntegers_[0];
    maxCommunityWhitelistLength = configIntegers_[1];
    whitelistMintStart = configIntegers_[2];
    pauseCutoffDays = configIntegers_[3];
    whitelistMintEnd = whitelistMintStart + 2 days;

    maxSupply = maxSupply_;
    mintPrice = mintPrice_;
    _royaltyReceipientAddress = royaltyReceipientAddress_;
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    beneficiaryAddress = beneficiaryAddress_;
  }

  /**
   *
   * @dev WebaverseVotes: Emit the votes cast with this mint to be tallied off-chain.
   *
   */
  event WebaverseVotes(address voter, uint256 quantityMinted, uint256[] votes);

  /**
   *
   * @dev Only allow when stage 1 whitelist minting is open:
   *
   */
  modifier whenStage1MintingOpen() {
    require(stage1MintingOpen(), "Stage 1 mint closed");
    require(communityRandomness != 0, "Community randomness not set");
    _;
  }

  /**
   *
   * @dev whenListsUnlocked: restrict access to when the lists are unlocked.
   * This allows the owner to effectively end new minting, with eligibility
   * fixed to the details on the merkle roots (and associated lists) already
   * saved in storage
   *
   */
  modifier whenListsUnlocked() {
    require(!listsLocked, "Lists locked");
    _;
  }

  /**
   *
   * @dev whenLandAddressUnlocked: the webaverse land address cannot be
   * updated after it has been locked
   *
   */
  modifier whenLandAddressUnlocked() {
    require(!webaverseLandAddressLocked, "Land address locked");
    _;
  }

  /**
   *
   * @dev whenPlaceholderURIUnlocked: the placeholder URI cannot be
   * updated after it has been locked
   *
   */
  modifier whenPlaceholderURIUnlocked() {
    require(!placeholderTokenURILocked, "Place holder URI locked");
    _;
  }

  /**
   *
   * @dev whenSupplyRemaining: Supply is controlled by lists and cannot be exceeded, but as
   * an explicity and clear control we check here that the mint operation requested will not
   * exceed the max supply.
   *
   */
  modifier whenSupplyRemaining(uint256 quantity_) {
    require((tokenIdCounter + quantity_) <= maxSupply, "Max supply exceeded");
    _;
  }

  /**
   *
   * @dev stage1MintingOpen: View of whether stage 1 mint is open
   *
   */
  function stage1MintingOpen() public view returns (bool) {
    return
      block.timestamp > (whitelistMintStart - 1) &&
      block.timestamp < (whitelistMintEnd + 1);
  }

  /**
   *
   * @dev isStage1MintingEnded: View of whether stage 1 mint is ended
   *
   */
  function stage1MintingEnded() public view returns (bool) {
    return block.timestamp > whitelistMintEnd;
  }

  /**
   * totalSupply is the number of tokens minted (value tokenIdCounter, as this is 0
   * indexed by always set to the next ID it will issue) minus burned
   */
  function totalSupply() public view returns (uint256) {
    return tokenIdCounter - burnCounter;
  }

  /**
   *
   * @dev getRandomNumber: Requests randomness.
   *
   */
  function getRandomNumber() public onlyOwner returns (uint256) {
    require(communityWhitelistMerkleRoot != 0, "Community list not set");
    require(communityRandomness == 0, "Randomness set");
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
   * @dev fulfillRandomWords: Callback function used by VRF Coordinator.
   * This function is used to generate random values used in community & claim minting
   *
   */
  function fulfillRandomWords(uint256, uint256[] memory randomWords_)
    internal
    override
  {
    require(communityRandomness == 0, "Randomness set");
    communityRandomness = randomWords_[0];
  }

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev withdrawContractBalance: A withdraw function to allow ETH balance to be withdrawn to the beneficiary address
   * set in the constructor
   *
   */
  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev receive: Handles receiving ether to the contract. Reject all direct payments to the contract except from beneficiary and owner.
   * set in the constructor
   *
   */
  receive() external payable {
    require(msg.value > 0, "No ETH");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary"
    );
  }

  /**
   *
   * @dev transferERC20Token: A withdraw function to avoid locking ERC20 tokens in the contract forever.
   * Tokens can only be withdrawn by the owner, to the owner.
   *
   */
  function transferERC20Token(IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  /**
   *
   * @dev pause: Allow owner to pause.
   *
   */
  function pause() public onlyOwner {
    require(
      whitelistMintStart == 0 ||
        block.timestamp < (whitelistMintStart + pauseCutoffDays * 1 days),
      "Pause cutoff passed"
    );
    _pause();
  }

  /**
   *
   * @dev unpause: Allow owner to unpause.
   *
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *
   * @dev lockLists: Prevent any further changes to list merkle roots.
   *
   */
  function lockLists() public onlyOwner {
    listsLocked = true;
  }

  /**
   *
   * @dev lockLandAddress: Prevent any further changes to the webaverse land contract address.
   *
   */
  function lockLandAddress() public onlyOwner {
    webaverseLandAddressLocked = true;
  }

  /**
   *
   * @dev setLandAddress: Set the root for the auction claims.
   *
   */
  function setLandAddress(address webaverseLandAddress_)
    external
    onlyOwner
    whenLandAddressUnlocked
  {
    webaverseLandAddress = webaverseLandAddress_;
  }

  /**
   *
   * @dev lockPlaceholderTokenURI: Prevent any further changes to the placeholder URI.
   *
   */
  function lockPlaceholderTokenURI() public onlyOwner {
    placeholderTokenURILocked = true;
  }

  /**
   *
   * @dev setPlaceholderTokenURI: Set the string for the placeholder
   * token URI.
   *
   */
  function setPlaceholderTokenURI(string memory placeholderTokenURI_)
    external
    onlyOwner
    whenPlaceholderURIUnlocked
  {
    placeholderTokenURI = placeholderTokenURI_;
  }

  /**
   *
   * @dev setDirectWhitelist: Set the initial data for the direct list mint.
   *
   */
  function setDirectWhitelist(bytes32 directWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    directWhitelistMerkleRoot = directWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setCommunityWhitelist: Set the initial data for the community mint.
   *
   */
  function setCommunityWhitelist(
    uint256[] calldata communityWhitelistLengths_,
    bytes32 communityWhitelistMerkleRoot_
  ) external whenListsUnlocked onlyOwner {
    require(
      communityWhitelistLengths_.length == numberOfCommunities,
      "Community length doesnt match"
    );

    communityWhitelistMerkleRoot = communityWhitelistMerkleRoot_;

    for (
      uint256 communityId = 0;
      communityId < numberOfCommunities;
      communityId++
    ) {
      communityWhitelistLengths[communityId] = communityWhitelistLengths_[
        communityId
      ];
    }
  }

  /**
   *
   * @dev setClaimWhitelistMerkleRoot: Set the root for the auction claims.
   *
   */
  function setClaimWhitelistMerkleRoot(bytes32 claimWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    claimWhitelistMerkleRoot = claimWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setTreasuryWhitelistMerkleRoot: Set the root for the treasury claims (metadrop + webaverse allocations).
   *
   */
  function setTreasuryWhitelistMerkleRoot(bytes32 treasuryWhitelistMerkleRoot_)
    external
    whenListsUnlocked
    onlyOwner
  {
    treasuryWhitelistMerkleRoot = treasuryWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev setCompletionWhitelistMerkleRoot: Set the root for completion mints.
   *
   */
  function setCompletionWhitelistMerkleRoot(
    bytes32 completionWhitelistMerkleRoot_
  ) external whenListsUnlocked onlyOwner {
    completionWhitelistMerkleRoot = completionWhitelistMerkleRoot_;
  }

  /**
   *
   * @dev _getCommunityHash: Get hash of information for the community mint.
   *
   */
  function _getCommunityHash(
    uint256 community_,
    uint256 position_,
    address minter_
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(community_, position_, minter_));
  }

  /**
   *
   * @dev _getDirectHash: Get hash of information for mints for direct list.
   *
   */
  function _getDirectHash(address minter_) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(minter_));
  }

  /**
   *
   * @dev _getClaimAndTreasuryHash: Get hash of information for mints from the auction (claims).
   * Also the same hash format as the treasury whitelist, used for treasuryWhitelistMerkleRoot too
   *
   */
  function _getClaimAndTreasuryHash(uint256 quantity_, address minter_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(quantity_, minter_));
  }

  /**
   *
   * @dev _getCompletionHash: Get hash of information for mints from the auction (claims).
   * Also the same hash format as the treasury whitelist, used for treasuryWhitelistMerkleRoot too
   *
   */
  function _getCompletionHash(
    uint256 quantity_,
    address minter_,
    uint256 unitPrice_
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(quantity_, minter_, unitPrice_));
  }

  /**
   *
   * @dev isValidPosition: Check is this is a valid position for this community allowlist. There are
   * 1,000 positions per community. If more than 1,000 have registered a random start position in the
   * allowlist is used to determine eligibility.
   *
   */
  function isValidPosition(uint256 position_, uint256 community_)
    internal
    view
    returns (bool)
  {
    uint256 communityWhitelistLength = communityWhitelistLengths[community_];
    require(communityWhitelistLength > 0, "Length not set");

    if (communityWhitelistLength > maxCommunityWhitelistLength) {
      // Find the random starting point somewhere in the whitelist length array
      uint256 startPoint = communityRandomness % communityWhitelistLength;
      uint256 endPoint = startPoint + maxCommunityWhitelistLength;
      // If the valid range exceeds the length of the whitelist, it must roll over
      if (endPoint > communityWhitelistLength) {
        return
          position_ >= startPoint ||
          position_ < endPoint - communityWhitelistLength;
      } else {
        return position_ >= startPoint && position_ < endPoint;
      }
    } else {
      return true;
    }
  }

  /**
   *
   * @dev _checkTheVote: check the count of votes = the quantity minted:
   *
   */
  function _checkTheVote(uint256[] memory votesToCount_, uint256 quantity_)
    internal
    view
  {
    // (1) Check that we have been passed the right number of community votes in the array:
    require(
      votesToCount_.length == numberOfCommunities,
      "Vote array does not match community count"
    );

    // (2) Check that the total votes matches the mint quantity:
    uint256 totalVotes;
    for (uint256 i = 0; i < votesToCount_.length; i++) {
      totalVotes += votesToCount_[i];
    }
    require(totalVotes == quantity_, "Votes do not match minting quantity");
  }

  /**
   *
   * @dev communityMint: Minting of community allocations from the allowlist.
   *
   */
  function communityMint(
    uint256 community_,
    uint256 position_,
    bytes32[] calldata proof_,
    uint256[] calldata votes_
  ) external payable whenStage1MintingOpen whenSupplyRemaining(1) {
    require(msg.value == mintPrice, "Insufficient ETH passed");

    require(communityWhitelistMerkleRoot != 0, "Community merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, 1);

    bytes32 leaf = _getCommunityHash(community_, position_, msg.sender);

    require(
      MerkleProof.verify(proof_, communityWhitelistMerkleRoot, leaf),
      "Community mint proof invalid"
    );

    require(
      isValidPosition(position_, community_),
      "This position has missed out"
    );

    _performDirectAndCommunityMint(msg.sender, votes_);
  }

  /**
   *
   * @dev directMint:  Mint allocations from the webaverse direct allowlist
   *
   */
  function directMint(bytes32[] calldata proof_, uint256[] calldata votes_)
    external
    payable
    whenStage1MintingOpen
    whenSupplyRemaining(1)
  {
    require(msg.value == mintPrice, "Insufficient ETH passed");

    require(directWhitelistMerkleRoot != 0, "Direct merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, 1);

    bytes32 leaf = _getDirectHash(msg.sender);

    require(
      MerkleProof.verify(proof_, directWhitelistMerkleRoot, leaf),
      "Direct mint proof invalid"
    );

    _performDirectAndCommunityMint(msg.sender, votes_);
  }

  /**
   *
   * @dev claimMint: Whitelist proof is generated from quantity and address
   *
   */
  function claimMint(
    uint256 quantityToMint_,
    bytes32[] calldata proof_,
    uint256[] calldata votes_
  ) public whenSupplyRemaining(quantityToMint_) {
    require(claimWhitelistMerkleRoot != 0, "Mint merkle root not set");

    // Check the total votes passed equals the minted quantity:
    _checkTheVote(votes_, quantityToMint_);

    bytes32 leaf = _getClaimAndTreasuryHash(quantityToMint_, msg.sender);

    require(
      MerkleProof.verify(proof_, claimWhitelistMerkleRoot, leaf),
      "Claim mint proof invalid"
    );

    require(!_claimHasMinted[msg.sender], "Claim: Address has already minted");

    _claimHasMinted[msg.sender] = true;

    _batchMint(msg.sender, quantityToMint_);

    emit WebaverseVotes(msg.sender, quantityToMint_, votes_);
  }

  /**
   *
   * @dev treasuryMint: Mint function for metadrop & webaverse treasury + other parties
   *
   */
  function treasuryMint(
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_
  ) public whenSupplyRemaining(quantityToMint_) {
    require(treasuryWhitelistMerkleRoot != 0, "Mint merkle root not set");

    bytes32 leaf = _getClaimAndTreasuryHash(quantityEligible_, msg.sender);

    require(
      MerkleProof.verify(proof_, treasuryWhitelistMerkleRoot, leaf),
      "Treasury: mint proof invalid"
    );

    require(
      (_treasuryAllocationMinted[msg.sender] + quantityToMint_) <=
        quantityEligible_,
      "Treasury: Requesting more than remaining allocation"
    );

    _treasuryAllocationMinted[msg.sender] += quantityToMint_;

    _batchMint(msg.sender, quantityToMint_);
  }

  /**
   *
   * @dev completionMint
   *
   */
  function completionMint(
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) public payable whenSupplyRemaining(quantityToMint_) {
    require(
      msg.value == (quantityToMint_ * unitPrice_),
      "Insufficient ETH passed"
    );

    require(
      completionWhitelistMerkleRoot != 0,
      "Completion merkle root not set"
    );

    bytes32 leaf = _getCompletionHash(
      quantityEligible_,
      msg.sender,
      unitPrice_
    );

    require(
      MerkleProof.verify(proof_, completionWhitelistMerkleRoot, leaf),
      "Completion: mint proof invalid"
    );

    require(
      (_completionAllocationMinted[msg.sender] + quantityToMint_) <=
        quantityEligible_,
      "Completion: Requesting more than remaining allocation"
    );

    _completionAllocationMinted[msg.sender] += quantityToMint_;

    _batchMint(msg.sender, quantityToMint_);
  }

  /**
   *
   * @dev _performDirectAndCommunityMint:  Unified processing for direct and community mint
   *
   */
  function _performDirectAndCommunityMint(
    address minter_,
    uint256[] calldata votes_
  ) internal {
    require(
      !_firstStageAddressHasMinted[minter_],
      "Community and Direct: Address has already minted"
    );

    _firstStageAddressHasMinted[minter_] = true;

    _safeMint(minter_, tokenIdCounter);
    tokenIdCounter += 1;

    emit WebaverseVotes(minter_, 1, votes_);
  }

  /**
   *
   * @dev _batchMint:  Unified processing for treasury, claim and completion mint
   *
   */
  function _batchMint(address minter_, uint256 quantity_) internal {
    uint256 tempTokenIdCounter = tokenIdCounter;
    for (uint256 i = 0; i < quantity_; i++) {
      _safeMint(minter_, tempTokenIdCounter);
      tempTokenIdCounter += 1;
    }
    tokenIdCounter = tempTokenIdCounter;
  }

  /**
   *
   * @dev setRoyaltyPercentageBasisPoints: allow the owner to set the base royalty percentage.
   *
   */
  function setRoyaltyPercentageBasisPoints(
    uint256 royaltyPercentageBasisPoints_
  ) external onlyOwner {
    _royaltyPercentageBasisPoints = royaltyPercentageBasisPoints_;
  }

  /**
   *
   * @dev setRoyaltyReceipientAddress: Allow the owner to set the royalty recipient.
   *
   */
  function setRoyaltyReceipientAddress(
    address payable royaltyReceipientAddress_
  ) external onlyOwner {
    _royaltyReceipientAddress = royaltyReceipientAddress_;
  }

  /**
   *
   * @dev setTokenBaseURI: Allow the owner to set the base token URI
   *
   */
  function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
    require(!tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURI = tokenBaseURI_;
  }

  /**
   *
   * @dev lockTokenBaseURI: allow the owner to lock the base token URI, after which the URI cannot be altered.
   *
   */
  function lockTokenBaseURI() external onlyOwner {
    require(!tokenBaseURILocked, "Token base URI is locked");
    tokenBaseURILocked = true;
  }

  /**
   *
   * @dev royaltyInfo: Returns recipent address and royalty.
   *
   */
  function royaltyInfo(uint256, uint256 salePrice_)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 royalty = (salePrice_ * _royaltyPercentageBasisPoints) / 10000;
    return (_royaltyReceipientAddress, royalty);
  }

  /**
   *
   * @dev _baseURI: returns the URI
   *
   */
  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    // If there is a land contract address set, use that address to retrieve the tokenURI:
    if (webaverseLandAddress != address(0)) {
      // Call the contract to return the token URI for this token ID:
      return IWebaverseLand(webaverseLandAddress).uriForToken(tokenId);

      // See if we have a token base URI set:
    } else if (bytes(_tokenBaseURI).length != 0) {
      // Return tokenBaseURI appended with the tokenId number:
      return
        string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));

      // If neither of the above, use the placeholder URI
    } else {
      // The placeholder URI is the same for all tokenIds:
      return placeholderTokenURI;
    }
  }

  /**
   *
   * @dev _beforeTokenTransfer: function called before tokens are transfered.
   *
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   *
   * @dev supportsInterface: ERC2981 interface support.
   *
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return
      interfaceId == _INTERFACE_ID_ERC2981 ||
      super.supportsInterface(interfaceId);
  }

  /**
   * ============================
   * Web app eligibility getters:
   * ============================
   */

  /**
   *
   * @dev eligibleForCommunityMint: Eligibility check for the COMMUNITY mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position, community and address are in the allowlist.
   * (2) Check if this leaf has already minted. If so, exit with false eligibility and reason "Sender has already minted for this community"
   * (3) Check if this leaf is in a valid position in the allowlist. If not, exit with false eligilibity and reason "This position has missed out"
   * (4) All checks passed, return elibility = true, the delivery address and valid leaf.
   *
   */
  function eligibleForCommunityMint(
    address addressToCheck_,
    uint256 position_,
    uint256 community_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      bool eligible,
      string memory reason,
      bytes32 leaf,
      address
    )
  {
    leaf = _getCommunityHash(community_, position_, addressToCheck_);

    if (
      MerkleProof.verify(proof_, communityWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        false,
        "Community mint proof invalid",
        leaf,
        addressToCheck_
      );
    }

    if (_firstStageAddressHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        false,
        "Community: Address has already minted",
        leaf,
        addressToCheck_
      );
    }

    if (!isValidPosition(position_, community_)) {
      return (
        addressToCheck_,
        false,
        "This position has missed out",
        leaf,
        addressToCheck_
      );
    }

    return (addressToCheck_, true, "", leaf, addressToCheck_);
  }

  /**
   *
   * @dev eligibleForDirectMint: Eligibility check for the DIRECT mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position and address are in the allowlist.
   * (2) Check if this minter address has already minted. If so, exit with false eligibility and reason "Address has already minted"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForDirectMint(
    address addressToCheck_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getDirectHash(addressToCheck_);

    if (MerkleProof.verify(proof_, directWhitelistMerkleRoot, leaf) == false) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Direct mint proof invalid"
      );
    }

    if (_firstStageAddressHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Direct: Address has already minted"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForClaimMint: Eligibility check for the CLAIM mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   *
   * Function flow is as follows:
   * (1) Check that the position and address are in the allowlist.
   * (2) Check if this minter address has already minted. If so, exit with false eligibility and reason "Address has already minted"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForClaimMint(
    address addressToCheck_,
    uint256 quantity_,
    bytes32[] calldata proof_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getClaimAndTreasuryHash(quantity_, addressToCheck_);

    if (MerkleProof.verify(proof_, claimWhitelistMerkleRoot, leaf) == false) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Claim mint proof invalid"
      );
    }

    if (_claimHasMinted[addressToCheck_]) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Claim: Address has already minted"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForTreasuryMint: Eligibility check for the treasury mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   * Function flow is as follows:
   * (1) Check that the quantityEligible and address are in the allowlist.
   * (2) Check if this minter is requesting more than its allocation. If so, exit with false eligibility and reason "Treasury: Requesting more than remaining allocation"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForTreasuryMint(
    address addressToCheck_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    // (2) Check the proof is valid
    bytes32 leaf = _getClaimAndTreasuryHash(quantityEligible_, addressToCheck_);

    if (
      MerkleProof.verify(proof_, treasuryWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Treasury: mint proof invalid"
      );
    }

    if (
      (_treasuryAllocationMinted[addressToCheck_] + quantityToMint_) >
      quantityEligible_
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Treasury: Requesting more than remaining allocation"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   *
   * @dev eligibleForCompletionMint: Eligibility check for the completion mint. This can be called from front-end (for example to control
   * screen components that indicate if the connected address is eligible).
   * Function flow is as follows:
   * (1) Check that the quantityEligible, address and unitPrice are in the allowlist.
   * (2) Check if this minter is requesting more than its allocation. If so, exit with false eligibility and reason "Treasury: Requesting more than remaining allocation"
   * (3) All checks passed, return elibility = true, the delivery address and valid minter adress.
   *
   */
  function eligibleForCompletionMint(
    address addressToCheck_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  )
    external
    view
    returns (
      address,
      address,
      bool eligible,
      string memory reason
    )
  {
    bytes32 leaf = _getCompletionHash(
      quantityEligible_,
      addressToCheck_,
      unitPrice_
    );

    if (
      MerkleProof.verify(proof_, completionWhitelistMerkleRoot, leaf) == false
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Completion: mint proof invalid"
      );
    }

    if (
      (_completionAllocationMinted[addressToCheck_] + quantityToMint_) >
      quantityEligible_
    ) {
      return (
        addressToCheck_,
        addressToCheck_,
        false,
        "Completion: Requesting more than remaining allocation"
      );
    }

    return (addressToCheck_, addressToCheck_, true, "");
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public override {
    super.burn(tokenId);
    burnCounter += 1;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

interface IWebaverseLand {
  // Function to call to return the tokenURI for a passed token Id
  function uriForToken(uint256 tokenId_) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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