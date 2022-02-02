// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Dwarfs_NFT.sol";
import "./GOD.sol";

contract Clan is Ownable, IERC721Receiver, Pausable {
  
  // maximum alpha score for a Mobster
  uint8 public constant MAX_ALPHA = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event MerchantClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event MobsterClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  // reference to the Dwarfs_NFT NFT contract
  Dwarfs_NFT dwarfs_nft;
  // reference to the $GOD contract for minting $GOD earnings
  GOD god;

  // maps tokenId to stake
  mapping(uint256 => Stake) public clan; 
  // maps alpha to all Mobster stakes with that alpha
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Mobster in Pack
  mapping(uint256 => uint256) public packIndices; 
  // total alpha scores staked
  uint256 public totalAlphaStaked = 0; 
  // any rewards distributed when no wolves are staked
  uint256 public unaccountedRewards = 0; 
  // amount of $GOD due for each alpha point staked
  uint256 public godPerAlpha = 0; 

  // merchant earn 10000 $GOD per day
  uint256 public constant DAILY_GOD_RATE = 10000 ether;
  // merchant must have 2 days worth of $GOD to unstake or else it's too cold
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // wolves take a 20% tax on all $GOD claimed
  uint256 public constant GOD_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $GOD earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GOD = 2400000000 ether;

  // amount of $GOD earned so far
  uint256 public totalGodEarned;
  // number of Merchant staked in the Clan
  uint256 public totalMerchantStaked;
  // the last time $GOD was claimed
  uint256 public lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GOD
  bool public rescueEnabled = false;

  /**
   * @param _dwarfs_nft reference to the Dwarfs_NFT NFT contract
   * @param _god reference to the $GOD token
   */
  constructor(address _dwarfs_nft, address _god) { 
    dwarfs_nft = Dwarfs_NFT(_dwarfs_nft);
    god = GOD(_god);
  }

  /** STAKING */

  /**
   * adds Merchant and Wolves to the Clan and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Merchant and Wolves to stake
   */
  function addManyToClanAndPack(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender() || _msgSender() == address(dwarfs_nft), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(dwarfs_nft)) { // dont do this step if its a mint + stake
        require(dwarfs_nft.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        dwarfs_nft.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (isMerchant(tokenIds[i])) 
        _addMerchantToClan(account, tokenIds[i]);
      else 
        _addMobsterToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Merchant to the Clan
   * @param account the address of the staker
   * @param tokenId the ID of the Merchant to add to the Clan
   */
  function _addMerchantToClan(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    clan[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalMerchantStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

  /**
   * adds a single Mobster to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Mobster to add to the Pack
   */
  function _addMobsterToPack(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForMobster(tokenId);
    totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[alpha].length; // Store the location of the mobster in the Pack
    pack[alpha].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(godPerAlpha)
    })); // Add the mobster to the Pack
    emit TokenStaked(account, tokenId, godPerAlpha);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GOD earnings and optionally unstake tokens from the Clan / Pack
   * to unstake a Merchant it will require it has 2 days worth of $GOD unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromClanAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isMerchant(tokenIds[i]))
        owed += _claimMerchantFromClan(tokenIds[i], unstake);
      else
        owed += _claimMobsterFromPack(tokenIds[i], unstake);
    }
    if (owed == 0) return;
    god.mint(_msgSender(), owed);
  }

  /**
   * realize $GOD earnings for a single Merchant and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Wolves
   * if unstaking, there is a 50% chance all $GOD is stolen
   * @param tokenId the ID of the Merchant to claim earnings from
   * @param unstake whether or not to unstake the Merchant
   * @return owed - the amount of $GOD earned
   */
  function _claimMerchantFromClan(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = clan[tokenId];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S GOD");
    if (totalGodEarned < MAXIMUM_GLOBAL_GOD) {
      owed = (block.timestamp - stake.value) * DAILY_GOD_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GOD production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_GOD_RATE / 1 days; // stop earning additional $GOD if it's all been earned
    }
    if (unstake) {
      if (random(tokenId) & 1 == 1) { // 50% chance of all $GOD stolen
        _payMobsterTax(owed);
        owed = 0;
      }
      dwarfs_nft.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Merchant
      delete clan[tokenId];
      totalMerchantStaked -= 1;
    } else {
      _payMobsterTax(owed * GOD_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked wolves
      owed = owed * (100 - GOD_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Merchant owner
      clan[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit MerchantClaimed(tokenId, owed, unstake);
  }

  /**
   * realize $GOD earnings for a single Mobster and optionally unstake it
   * Wolves earn $GOD proportional to their Alpha rank
   * @param tokenId the ID of the Mobster to claim earnings from
   * @param unstake whether or not to unstake the Mobster
   * @return owed - the amount of $GOD earned
   */
  function _claimMobsterFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(dwarfs_nft.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
    uint256 alpha = _alphaForMobster(tokenId);
    Stake memory stake = pack[alpha][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = (alpha) * (godPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
    if (unstake) {
      totalAlphaStaked -= alpha; // Remove Alpha from total staked
      dwarfs_nft.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Mobster
      Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
      pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Mobster to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[alpha].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
    } else {
      pack[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(godPerAlpha)
      }); // reset stake
    }
    emit MobsterClaimed(tokenId, owed, unstake);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 alpha;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isMerchant(tokenId)) {
        stake = clan[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        dwarfs_nft.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Merchant
        delete clan[tokenId];
        totalMerchantStaked -= 1;
        emit MerchantClaimed(tokenId, 0, true);
      } else {
        alpha = _alphaForMobster(tokenId);
        stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        dwarfs_nft.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Mobster
        lastStake = pack[alpha][pack[alpha].length - 1];
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Mobster to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        emit MobsterClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $GOD to claimable pot for the Pack
   * @param amount $GOD to add to the pot
   */
  function _payMobsterTax(uint256 amount) internal {
    if (totalAlphaStaked == 0) { // if there's no staked wolves
      unaccountedRewards += amount; // keep track of $GOD due to wolves
      return;
    }
    // makes sure to include any unaccounted $GOD 
    godPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GOD earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGodEarned < MAXIMUM_GLOBAL_GOD) {
      totalGodEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalMerchantStaked
        * DAILY_GOD_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * checks if a token is a Merchant
   * @param tokenId the ID of the token to check
   * @return merchant - whether or not a token is a Merchant
   */
  function isMerchant(uint256 tokenId) public view returns (bool merchant) {
    (merchant, , , , , , , , , ) = dwarfs_nft.tokenTraits(tokenId);
  }

  /**
   * gets the alpha score for a Mobster
   * @param tokenId the ID of the Mobster to get the alpha score for
   * @return the alpha score of the Mobster (5-8)
   */
  function _alphaForMobster(uint256 tokenId) internal view returns (uint8) {
    ( , , , , , , , , , uint8 alphaIndex) = dwarfs_nft.tokenTraits(tokenId);
    return MAX_ALPHA - alphaIndex; // alpha index is 0-3
  }

  /**
   * chooses a random Mobster thief when a newly minted token is stolen
   * @param seed a random value to choose a Mobster from
   * @return the owner of the randomly selected Mobster thief
   */
  function randomMobsterOwner(uint256 seed) external view returns (address) {
    if (totalAlphaStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Wolves with the same alpha score
    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Mobster with that alpha score
      return pack[i][seed % pack[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Clan directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}