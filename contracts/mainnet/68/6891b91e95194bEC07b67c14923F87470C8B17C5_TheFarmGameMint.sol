// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IEggShop.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IHenHouse.sol';
import './interfaces/IRandomizer.sol';
import './interfaces/ISpecialMint.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract TheFarmGameMint is Ownable, ERC165Storage, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  event MintCommitted(address indexed owner, uint256 indexed quantity);
  event MintRevealed(address indexed owner, uint256 indexed quantity);
  event EggShopAward(address indexed recipient, uint16 indexed typeId);
  event SaleStatusUpdated(
    uint256 preSaleTime,
    uint256 allowListTime,
    uint256 preSaleFee,
    uint256 preSaleStakeFee,
    uint256 publicSaleTime,
    uint256 publicSaleFee,
    uint256 publicStakeFee
  );
  event InitializedContract(address thisContract);

  // PreSale
  uint256 public preSaleTime = 1666105200; // Thursday, October 18, 2022 3:00 PM UTC / 11:00 AM EST

  uint256 public preSaleFee = 0.049 ether;
  uint256 public preSaleMaxQty = 4;
  uint256 public preSaleStakeFee = 0.025 ether;
  bytes32 public preSaleRoot; // Merkel root for preSale

  // Allow List
  uint256 public allowListTime = 1666110600; // Thursday, October 18, 2022 4:30 PM UTC / 12:30 PM EST
  bytes32 public allowListRoot; // Merkel root for allow list sale

  mapping(address => uint16) private mintRecords; // Address => tokenIDs, track number of mints during presale

  // Public Sale Gen 0
  uint256 public publicTime = 1666117800; // Thursday, October 18, 2022 6:30 PM UTC / 2:30 PM EST
  uint256 public publicFee = 0.049 ether;
  uint256 public publicStakeFee = 0.035 ether;
  uint256 public publicMaxPerTx = 5;

  uint256 public teamMintEvery = 25; // Auto mints Gen0 token to team every X

  // Gen 1+
  uint256 private maxEggCost = 72000 ether; // max EGG cost

  // Mint Commit/Reveal
  struct MintCommit {
    bool stake;
    uint16 quantity;
  }
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits; // address -> commit # -> commits
  mapping(address => uint16) private _pendingCommitId; // address -> commit num of commit need revealed for account
  mapping(uint16 => uint256) private _commitRandoms; // commit # -> offchain random
  uint16 private _commitId = 1;
  uint16 private pendingMintAmt;
  bool public allowCommits = false;

  // Auto-liquidity
  uint256 liqudityAlreadyPaid = 0; // Count of tokens that liquidity is already paid for

  // Admin
  mapping(address => bool) public controllers; // address => can call allowedToCallFunctions

  // LastWrite security
  struct LastWrite {
    uint64 time;
    uint64 blockNum;
  }

  mapping(address => LastWrite) private _lastWrite;

  // Egg shop type IDs
  uint16 public applePieTypeId = 1;
  uint16 public platinumEggTypeId = 5;

  // Interfaces
  IRandomizer public randomizer;
  IHenHouse public henHouse; // reference to the Hen House for choosing random Coyote thieves
  IEGGToken public eggToken; // reference to EGG for burning on mint
  IFarmAnimals public farmAnimalsNFT; // reference to NFT collection
  IEggShop public eggShop; // reference to eggShop collection
  ISpecialMint public specialMint; // reference to special mint

  /** MODIFIERS */

  /**
   * @dev Modifer to require contract to be set before a transfer can happen
   */

  modifier requireContractsSet() {
    require(
      address(eggToken) != address(0) &&
        address(farmAnimalsNFT) != address(0) &&
        address(henHouse) != address(0) &&
        address(eggShop) != address(0) &&
        address(randomizer) != address(0),
      'Contracts not set'
    );
    _;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  /**
   * Instantiates contract
   * Emits InitilizeContract event to kickstart subgraph
   */
  constructor(
    IEGGToken _eggToken,
    IEggShop _eggShop,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouse _henHouse,
    IRandomizer _randomizer,
    ISpecialMint _specialMint
  ) {
    eggToken = _eggToken;
    eggShop = _eggShop;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouse = _henHouse;
    randomizer = _randomizer;
    specialMint = _specialMint;
    controllers[_msgSender()] = true;

    _pause();
    emit InitializedContract(address(this));
  }

  /**
   *  ███    ███ ██ ███    ██ ████████
   *  ████  ████ ██ ████   ██    ██
   *  ██ ████ ██ ██ ██ ██  ██    ██
   *  ██  ██  ██ ██ ██  ██ ██    ██
   *  ██      ██ ██ ██   ████    ██
   * This section has everything to do with Character minting and burning
   */

  /**
   * @notice Mint public sale Gen 0 for ETH
   * @dev Gen 0 mint a token - ~87% Hen, 10% Coyotes, 3% Rooster
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   */

  function mint(uint256 quantity, bool stake) external payable whenNotPaused nonReentrant {
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(block.timestamp >= publicTime, 'Public sale not yet started');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();

    require(minted <= gen0Supply, 'All paid tokens minted');
    require(minted + quantity <= gen0Supply, 'Qty greater than available tokens');
    require(quantity > 0 && quantity <= publicMaxPerTx, 'Invalid mint qty');

    LastWrite storage lw = _lastWrite[tx.origin];

    uint256 totalEthCost = 0;
    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;

    for (uint256 i = 0; i < quantity; i++) {
      minted++; // current ID being minted

      uint256 seed = randomizer.randomToken(minted);

      // Gen0 Price
      if (stake) {
        totalEthCost = publicStakeFee * quantity;
      } else {
        totalEthCost = publicFee * quantity;
      }

      if (!stake) {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(_msgSender(), seed);
        numOfMints += newTokenIds.length;
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints += newTokenIds.length;
      }
    }
    require(msg.value >= totalEthCost, 'Invalid ETH amount');

    uint16[] memory tokenIds = new uint16[](numOfMints);
    for (uint16 i = 0; i < numOfMints; i++) {
      tokenIds[i] = startingTokenId + i;
    }
    farmAnimalsNFT.updateOriginAccess(tokenIds);

    if (stake) {
      henHouse.addManyToHenHouse(_msgSender(), tokenIds);
    }

    lw.time = uint64(block.timestamp);
    lw.blockNum = uint64(block.number);
    teamMint(startingTokenId, numOfMints);
  }

  function _mintStake(
    address recipient,
    uint256 quantity,
    bool stake,
    uint16 minted
  ) internal {
    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;
    for (uint256 i = 0; i < quantity; i++) {
      minted++;
      uint256 seed = randomizer.randomToken(minted);
      if (!stake) {
        farmAnimalsNFT.mint(recipient, seed);
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints = numOfMints + newTokenIds.length;
      }
    }
    if (stake) {
      uint16[] memory tokenIds = new uint16[](numOfMints);
      for (uint16 i = 0; i < numOfMints; i++) {
        tokenIds[i] = startingTokenId + i;
      }
      henHouse.addManyToHenHouse(recipient, tokenIds);
    }
    teamMint(startingTokenId, numOfMints);
  }

  function teamMint(uint16 startingTokenId, uint256 numOfMints) internal {
    for (uint16 i = 0; i < numOfMints; i++) {
      if ((startingTokenId + i) % teamMintEvery == 0) {
        uint256 seed = randomizer.randomToken(startingTokenId + i + block.timestamp);
        farmAnimalsNFT.mint(owner(), seed);
      }
    }
  }

  /**
   * @notice Mint via preSale merkle tree for ETH
   * @dev Only callable if public sale has not started && contracts have been set
   * @param quantity number of NFTs to mint in this transaction
   * @param stake stake NFTs upon minting
   * @param merkleProof merkle proof for msg.sender
   */
  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof
  ) external payable whenNotPaused requireContractsSet {
    require(tx.origin == _msgSender() || controllers[_msgSender()], 'Only EOA or controllers');
    require(block.timestamp >= preSaleTime && block.timestamp < publicTime, 'Pre-sale not running');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    require(minted < gen0Supply, 'All tokens minted');
    require(minted + quantity <= gen0Supply, 'Qty exceeds max supply');

    bytes32 node = keccak256(abi.encode(msg.sender));
    if (block.timestamp >= preSaleTime && block.timestamp < allowListTime) {
      require(MerkleProof.verify(merkleProof, preSaleRoot, node), 'Minters address not eligible for preSale mint');
    } else if (block.timestamp >= allowListTime) {
      require(MerkleProof.verify(merkleProof, allowListRoot, node), 'Minters address not eligible for allow list mint');
    }

    require(mintRecords[_msgSender()] + quantity <= preSaleMaxQty, 'Mint would exceed minters address max allowed');

    mintRecords[_msgSender()] = mintRecords[_msgSender()] + uint16(quantity);

    // Price Calc
    uint256 totalEthCost = 0;
    if (stake) {
      totalEthCost = preSaleStakeFee * quantity;
    } else {
      totalEthCost = preSaleFee * quantity;
    }

    require(msg.value >= totalEthCost, 'Payment amount is not correct.');

    _mintStake(_msgSender(), quantity, stake, minted);
  }

  /**
   * @notice Get number of NFTs _minter has minted via preSaleMint()
   * @param _minter address of minter to lookup
   */
  function getMintRecord(address _minter) external view returns (uint256) {
    return mintRecords[_minter];
  }

  /**
   * Mint Commit/Reveal
   */

  /**
   * @notice Get Pending Mint Amount regarding the address
   * address to get pending mint amount
   */

  function getPendingMint(address _address) external view returns (MintCommit memory) {
    require(_pendingCommitId[_address] != 0, 'No pending commits');
    return _mintCommits[_address][_pendingCommitId[_address]];
  }

  /**
   * @notice Make sure address has a Pending Mint.
   */

  function hasMintPending(address _address) external view returns (bool) {
    return _pendingCommitId[_address] != 0;
  }

  /**
   * @notice Make sure address can reveal a pending mint
   */

  function canReveal(address _address) external view returns (bool) {
    return _pendingCommitId[_address] != 0 && _commitRandoms[_pendingCommitId[_address]] > 0;
  }

  /**
   * @notice Seed the current commit id so that pending commits can be revealed
   */

  function addCommitRandom(uint256 seed) external onlyController {
    _commitRandoms[_commitId] = seed;
    _commitId += 1;
  }

  /**
   * @notice Remove all pending mints by address
   */

  function deleteCommit(address _address) external onlyController {
    uint16 commitIdCur = _pendingCommitId[_address];
    require(commitIdCur > 0, 'No pending commit');
    delete _mintCommits[_address][commitIdCur];
    delete _pendingCommitId[_address];
  }

  /**
   * @notice Reveal the pending mints by address
   */

  function forceRevealCommit(address _address) external onlyController {
    reveal(_address);
  }

  /**
   * @dev Initiate the start of a mint. This action burns EGG, as the intent of committing is that you cannot back out once you've started.
   * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
   * commit was added to. */
  function mintCommit(uint256 quantity, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, 'Adding commits disallowed');
    require(tx.origin == _msgSender(), 'Only EOA');
    require(_pendingCommitId[_msgSender()] == 0, 'Already have pending mints');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    require(minted >= gen0Supply, 'Gen 0 not fully minted');
    require(minted + pendingMintAmt + quantity <= maxSupply, 'All tokens minted');
    require(quantity > 0 && quantity <= 10, 'Invalid mint qty');

    uint256 totalEggCost = 0;
    // Loop through the quantity of
    for (uint256 i = 1; i <= quantity; i++) {
      totalEggCost += mintCostEGG(minted + pendingMintAmt + i);
    }
    if (totalEggCost > 0) {
      eggToken.burn(_msgSender(), totalEggCost);
    }
    uint16 amt = uint16(quantity);
    _mintCommits[_msgSender()][_commitId] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitId;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), quantity);
  }

  /**
   * @dev Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
   * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), 'Only EOA');
    reveal(_msgSender());
  }

  function reveal(address _address) internal {
    uint16 commitIdCur = _pendingCommitId[_address];

    require(commitIdCur > 0, 'No pending commit');
    require(_commitRandoms[commitIdCur] > 0, 'Random seed not set');
    uint16 minted = farmAnimalsNFT.minted();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    MintCommit memory commit = _mintCommits[_address][commitIdCur];
    pendingMintAmt -= commit.quantity;

    uint16 startingTokenId = minted + 1;
    uint256 numOfMints = 0;

    uint256 seed = _commitRandoms[commitIdCur];
    for (uint256 k = 0; k < commit.quantity; k++) {
      minted++;

      seed = uint256(keccak256(abi.encode(seed, _address)));
      address recipient = _selectRecipient(seed, minted, gen0Supply);
      if (!commit.stake || recipient != _address) {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(recipient, seed);
        numOfMints = numOfMints + newTokenIds.length;
      } else {
        uint16[] memory newTokenIds = farmAnimalsNFT.mint(address(henHouse), seed);
        numOfMints = numOfMints + newTokenIds.length;
      }
    }

    uint16[] memory tokenIds = new uint16[](numOfMints);
    uint256 numOfOwned = 0;
    for (uint16 i = 0; i < numOfMints; i++) {
      uint16 tokenId = startingTokenId + i;
      // Add tokenIds to tokenIds[] for updateOriginAccess
      tokenIds[i] = startingTokenId + i;

      address currentOwner = farmAnimalsNFT.ownerOf(tokenId);
      if (currentOwner == address(henHouse)) {
        numOfOwned++;
      }
    }

    farmAnimalsNFT.updateOriginAccess(tokenIds);

    // If stake then calc build array of owned mints (not kidnapped)
    if (commit.stake) {
      uint16[] memory tokenIdsToStake = new uint16[](numOfOwned);
      uint16 nIndex = 0;
      for (uint16 i = 0; i < numOfMints; i++) {
        uint16 tokenId = startingTokenId + i;
        address currentOwner = farmAnimalsNFT.ownerOf(tokenId);
        if (currentOwner == address(henHouse)) {
          tokenIdsToStake[nIndex] = tokenId;
          nIndex++;
        }
      }

      henHouse.addManyToHenHouse(_address, tokenIdsToStake);
    }

    // If minting any incement of 100 then aware a platinum egg for gen 1+
    for (uint16 i = 0; i < numOfMints; i++) {
      uint16 tokenId = startingTokenId + i;
      if (tokenId > gen0Supply && tokenId % 100 == 0) {
        IEggShop.TypeInfo memory platinumTypeInfo = eggShop.getInfoForType(platinumEggTypeId);
        if ((platinumTypeInfo.mints + platinumTypeInfo.burns) < platinumTypeInfo.maxSupply) {
          uint256 tokenIdGift = uint256(tokenId).sub(randomizer.randomToken(tokenId).mod(100));
          address tokenOwner = farmAnimalsNFT.ownerOf(tokenIdGift);
          if (tokenOwner == address(henHouse)) {
            IHenHouse.Stake memory stake = henHouse.getStakeInfo(uint16(tokenIdGift));
            _awardPlatinumEgg(stake.owner);
          } else {
            _awardPlatinumEgg(tokenOwner);
          }
        }
      }
    }

    delete _mintCommits[_address][commitIdCur];
    delete _pendingCommitId[_address];
    emit MintRevealed(_address, numOfMints);
  }

  /**
   * End Randomenizer calls
   */

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice Mint Platinum EggShop Token
   * @param tokenOwner Recipient address to receive Platinum EGG
   */

  function _awardPlatinumEgg(address tokenOwner) internal {
    eggShop.mint(platinumEggTypeId, 1, tokenOwner, uint256(0));
    emit EggShopAward(tokenOwner, uint16(platinumEggTypeId));
  }

  /**
   * The first Gen0 (ETH purchases) go to the minter
   * The remaining have a 10% chance to be given to a random staked coyote
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Coyote thief's owner)
   */
  function _selectRecipient(
    uint256 seed,
    uint256 minted,
    uint256 gen0Supply
  ) internal view returns (address) {

    if (minted <= gen0Supply || ((seed >> 245) % 10) != 0) return _msgSender();

    address thief = henHouse.randomCoyoteOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0) || thief == _msgSender()) {
      return _msgSender();
    }
    return thief;
  }

  /**
   * @notice Transfer ETH and return the success status.
   * @dev This function only forwards 30,000 gas to the callee.
   * @param to Address for ETH to be send to
   * @param value Amount of ETH to send
   */
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /**
   * @notice Get the current NFT Mint Price
   * it will return mint eth price or EGG price regarding presale and publicsale
   */

  function currentPriceToMint() public view returns (uint256) {
    uint16 minted = farmAnimalsNFT.minted();

    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    if (minted >= gen0Supply) {
      return mintCostEGG(minted + pendingMintAmt + 1);
    } else if (block.timestamp >= publicTime) {
      return publicFee;
    } else {
      return preSaleFee;
    }
  }

  /**
   * @return the cost for the current gen step
   */

  function mintCostEGG(uint256 tokenId) public view returns (uint256) {
    uint256 maxSupply = farmAnimalsNFT.maxSupply();
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 gAmount = (maxSupply.sub(gen0Supply)).div(5);
    if (tokenId <= gen0Supply) return 0; // GEN 0
    if (tokenId <= (gAmount + gen0Supply)) return 24000 ether; // GEN 1
    if (tokenId <= (gAmount * 2) + gen0Supply) return 36000 ether; // GEN 2
    if (tokenId <= (gAmount * 3) + gen0Supply) return 48000 ether; // GEN 3
    if (tokenId <= (gAmount * 4) + gen0Supply) return 60000 ether; // GEN 4
    return maxEggCost; // GEN 5
  }

  /**
   * @notice Get current mint sale status
   */

  function getSaleStatus() external view returns (string memory) {
    if (block.timestamp >= publicTime) {
      if (paused() == true) {
        return 'paused';
      }
      uint16 minted = farmAnimalsNFT.minted();
      uint256 maxSupply = farmAnimalsNFT.maxSupply();
      uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
      uint256 gAmount = (maxSupply.sub(gen0Supply)).div(5);
      if (minted < gen0Supply) return 'GEN 0';
      if (minted <= (gAmount + gen0Supply)) return 'GEN 1';
      if (minted <= (gAmount * 2) + gen0Supply) return 'GEN 2';
      if (minted <= (gAmount * 3) + gen0Supply) return 'GEN 3';
      if (minted <= (gAmount * 4) + gen0Supply) return 'GEN 4';
      return 'GEN 5';
    } else if (block.timestamp < publicTime && block.timestamp >= allowListTime) {
      return 'allowlist';
    } else if (block.timestamp < allowListTime && block.timestamp >= preSaleTime) {
      return 'presale';
    } else {
      return 'soon';
    }
  }

  /**
   * @notice Get current mint status
   */

  function canMint() external view returns (bool) {
    if (paused() == true) {
      return false;
    }
    if (block.timestamp >= publicTime || block.timestamp >= preSaleTime) {
      return true;
    } else {
      return false;
    }
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
    if (_paused) _pause();
    else _unpause();
    emit SaleStatusUpdated(
      preSaleTime,
      allowListTime,
      preSaleFee,
      preSaleStakeFee,
      publicTime,
      publicFee,
      publicStakeFee
    );
  }

  /**
   * @notice Set new EGG Max Mint amount
   * @param _amount max EGG amount
   */

  function setMaxEggCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxEggCost = _amount;
  }

  /**
   * @notice Mint via preSale merkle tree
   * @dev Only callable if caller is controller
   * @param _hash the merkle root hash value
   */

  function setPreSaleRoot(bytes32 _hash) external onlyOwner {
    preSaleRoot = _hash;
  }

  /**
   * @notice Mint via allowList merkle tree
   * @dev Only callable if caller is controller
   * @param _hash the merkle root hash value
   */

  function setAllowListRoot(bytes32 _hash) external onlyOwner {
    allowListRoot = _hash;
  }

  /**
   * @notice Allow the mintCommit feature
   */

  function setAllowCommits(bool allowed) external onlyOwner {
    allowCommits = allowed;
  }

  /** Allow the contract owner to set the pending mint amount.
   * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been
   *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
   * This function should not be called lightly, this will have negative consequences on the game.
   */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Set new public sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPreSaleFee(uint256 _fee) external onlyOwner {
    preSaleFee = _fee;
  }

  /**
   * @notice Set new public mint & stake sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPreSaleMintStakeFee(uint256 _fee) external onlyOwner {
    preSaleStakeFee = _fee;
  }

  /**
   * @notice Set new Presale TimeStamp
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new presale time
   */

  function setPreSaleTime(uint256 _time) external onlyOwner {
    preSaleTime = _time;
  }

  /**
   * @notice Set new Presale TimeStamp
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new presale time
   */

  function setAllowListTime(uint256 _time) external onlyOwner {
    allowListTime = _time;
  }

  /**
   * @notice Set new public sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPublicFee(uint256 _fee) external onlyOwner {
    publicFee = _fee;
  }

  /**
   * @notice Set new public mint & stake sale mint price
   * @param _fee eth price for the public mint sale
   */

  function setPublicMintStakeFee(uint256 _fee) external onlyOwner {
    preSaleStakeFee = _fee;
  }

  /**
   * @notice Set new Public Sale Time
   * @dev Modifer to require msg.sender to be owner
   * @param _time Unix time to update new public sale time
   */

  function setPublicSaleTime(uint256 _time) external onlyOwner {
    publicTime = _time;
  }

  /**
   * @notice Set Public sale max tx limit
   * @param _txLimit the max tokens per tx
   */

  function setPublicSaleMaxTx(uint256 _txLimit) external onlyOwner {
    publicMaxPerTx = _txLimit;
  }

  /**
   * @notice Set Team Reserve
   * @param _qty the team reserve quantity
   */

  function setTeamReserve(uint256 _qty) external onlyOwner {
    teamMintEvery = _qty;
  }

  /**
   * @notice Allows owner to withdraw ETH funds to an address
   * @dev wraps _user in payable to fix address -> address payable
   * @param to Address for ETH to be send to
   */

  function withdraw(address payable to) external onlyOwner {
    uint256 gen0Supply = farmAnimalsNFT.maxGen0Supply();
    uint256 minted = farmAnimalsNFT.minted();
    if (liqudityAlreadyPaid < gen0Supply) {
      uint256 tokenCountToBeAdded = 0;
      if (minted <= gen0Supply) {
        tokenCountToBeAdded = minted - liqudityAlreadyPaid;
      } else {
        tokenCountToBeAdded = gen0Supply - liqudityAlreadyPaid;
      }
      liqudityAlreadyPaid += tokenCountToBeAdded;
      uint256 ethToBeAdded = tokenCountToBeAdded * 0.0025 ether;
      uint256 ethToWidraw = address(this).balance.sub(ethToBeAdded);
      uint256 eggToBeAdded = tokenCountToBeAdded * 10000 ether;
      // eggToken.mint(address(this), eggToBeAdded);
      eggToken.addLiquidityETH{ value: ethToBeAdded }(eggToBeAdded, ethToBeAdded);
      require(_safeTransferETH(to, ethToWidraw));
    } else {
      require(_safeTransferETH(to, address(this).balance));
    }
  }

  /**
   * @notice Allows owner to withdraw any accident tokens transferred to contract
   * @param _tokenContract Address for the token
   * @param to Address for token to be send to
   * @param amount Amount of token to send
   */
  function withdrawToken(
    address _tokenContract,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(to, amount);
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IRandomizer {
  function random() external view returns (uint256);

  function randomToken(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint16 tokenId) external;

  function maxGen0Supply() external view returns (uint16);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint16 tokenId) external view returns (Traits memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function mint(address recipient, uint256 seed) external returns (uint16[] memory);

  function minted() external view returns (uint16);

  function mintedRoosters() external returns (uint16);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function updateAdvantage(
    uint16 tokenId,
    uint8 score,
    bool decrement
  ) external;

  function updateOriginAccess(uint16[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface ISpecialMint {
  function getSpecialMintReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

pragma solidity ^0.8.17;

interface IEggShop is IERC1155 {
  struct TypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
  }

  struct DetailedTypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
    string name;
  }

  function mint(
    uint256 typeId,
    uint16 qty,
    address recipient,
    uint256 eggAmt
  ) external;

  function burn(
    uint256 typeId,
    uint16 qty,
    address burnFrom,
    uint256 eggAmt
  ) external;

  // function balanceOf(address account, uint256 id) external returns (uint256);

  function getInfoForType(uint256 typeId) external view returns (TypeInfo memory);

  function getInfoForTypeName(uint256 typeId) external view returns (DetailedTypeInfo memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint16 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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