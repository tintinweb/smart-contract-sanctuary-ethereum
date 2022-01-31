pragma solidity ^0.8.10;

import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";
import "Strings.sol";

import "IChubbyKaijuDAOStakingV1.sol";
import "IChubbyKaijuDAOCrunch.sol";
import "IChubbyKaijuDAOGEN1.sol";
import "IChubbyKaijuDAOGEN2.sol";

contract ChubbyKaijuDAOStakingV1 is IChubbyKaijuDAOStakingV1, OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  using Strings for uint128;

  uint32 public totalCrocodilesStaked;

  uint32 public totalPowerStaked; // trait 0
  uint32 public totalMoneyStaked; // trait 1
  uint32 public totalMusicStaked; // trait 2

  uint32 public totalZombieStaked; // trait 3
  uint32 public totalAlienStaked; // trait 4
  uint32 public totalHalfZombieStaked; // trait 5


  uint48 public lastClaimTimestamp;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;

  uint128 public constant MAXIMUM_CRUNCH = 18000000 ether;

  uint128 public totalCrunchEarned;

  uint128 public constant CRUNCH_EARNING_RATE = 115740; //74074074; // 1 crunch per day;
  uint128 public constant TIME_BASE_RATE = 100000000;

  struct TimeStake { uint16 tokenId; uint48 time; address owner; uint16 trait; uint16 reward_type;}

  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);

  IChubbyKaijuDAOGEN1 private chubbykaijuGen1;
  IChubbyKaijuDAOCrunch private chubbykaijuDAOCrunch;
  IChubbyKaijuDAOGEN2 private chubbykaijuGen2;


  TimeStake[] public gen1StakeByToken; 
  mapping(uint16 => uint16) public gen1Hierarchy; 
  mapping(address => EnumerableSetUpgradeable.UintSet) private _gen1StakedTokens;

  TimeStake[] public gen2StakeByToken; 
  mapping(uint16 => uint16) public gen2Hierarchy; 
  mapping(address => EnumerableSetUpgradeable.UintSet) private _gen2StakedTokens;

  address private uncommon_address;
  address private common_address;
  address private rare_address;
  address private epic_address;
  address private sos_address;
  address private one_address;

  

  struct rewardTypeStaked{
    uint32  uncommon_gen1; // reward_type: 0 -> 1*1*(1+Time weight)
    uint32  uncommon_zombieailen; // reward_type: 1 -> 1*1.5*(1+Time weight)
    uint32  uncommon_halfzombie; // reward_type: 2 -> 1*3*(1+Time weight)

    uint32  common_gen1; // reward_type: 3 -> 1*1*(1+Time weight)
    uint32  common_zombieailen; // reward_type: 4 -> 1*1.5*(1+Time weight)
    uint32  common_halfzombie; // reward_type: 5 -> 1*3*(1+Time weight)

    uint32  rare_gen1; // reward_type: 6 -> 2*1*(1+Time weight)
    uint32  rare_zombieailen; // reward_type: 7 -> 2*1.5*(1+Time weight)
    uint32  rare_halfzombie; // reward_type: 8 -> 2*3*(1+Time weight)

    uint32  epic_gen1; // reward_type: 9 -> -> 3*1*(1+Time weight)
    uint32  epic_zombieailen; // reward_type: 10 -> 3*1.5*(1+Time weight)
    uint32  epic_halfzombie; // reward_type: 11 -> 3*3*(1+Time weight)

    uint32  sos_gen1; // reward_type: 12 -> 5*1*(1+Time weight)
    uint32  sos_zombieailen; // reward_type: 13 -> 5*1.5*(1+Time weight)
    uint32  sos_halfzombie; // reward_type: 14 -> 5*3*(1+Time weight)

    uint32  one_gen1; // reward_type: 15 -> 15*1*(1+Time weight)
    uint32  one_zombieailen; // reward_type: 16 -> 15*1.5*(1+Time weight)
    uint32  one_halfzombie; // reward_type: 17 -> 15*3*(1+Time weight)
  }

  rewardTypeStaked private rewardtypeStaked;

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    //_pause();
  }

  function setSigners(address[] calldata signers) public onlyOwner{
    uncommon_address = signers[0];
    common_address = signers[1];
    rare_address = signers[2];
    epic_address = signers[3];
    sos_address = signers[4];
    one_address = signers[5];
  }


  function stakeTokens(address account, uint16[] calldata tokenIds, bool[] calldata gens, bytes[] memory signatures) external whenNotPaused nonReentrant _updateEarnings {
    /*
    require((account == msg.sender && tx.origin == msg.sender), "not approved");
    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      if(gens[i]){ // GEN1 staking
        require(chubbykaijuGen1.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
        uint16 trait = tokenIds[i]>9913? 2:chubbykaijuGen1.traits(tokenIds[i]);
        _stakeGEN1(account, tokenIds[i], trait, signatures[i]);
        chubbykaijuGen1.transferFrom(msg.sender, address(this), tokenIds[i]);
      }else{  // GEN2 staking
        require(chubbykaijuGen2.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
        uint16 trait = chubbykaijuGen2.traits(tokenIds[i]);
        _stakeGEN2(account, tokenIds[i], trait, signatures[i]);
        chubbykaijuGen2.transferFrom(msg.sender, address(this), tokenIds[i]);
      }
    }
    */
  }


  function _stakeGEN1(address account, uint16 tokenId, uint16 trait, bytes memory signature) internal {
    if(trait == 0){
      totalPowerStaked += 1;
    }else if(trait == 1){
      totalMoneyStaked += 1;
    }else if(trait == 2){
      totalMusicStaked += 1;
    }
    address rarity = rarityCheck(tokenId, signature);
    uint16 reward_type = 0;

    if(rarity == uncommon_address){
      reward_type = 0;
    }else if(rarity == common_address){
      reward_type = 3;
    }else if(rarity == rare_address){
      reward_type = 6;
    }else if (rarity == epic_address){
      reward_type = 9;
    }else if(rarity == sos_address){
      reward_type = 12;
    }else if(rarity == one_address){
      reward_type = 15;
    }

    gen1Hierarchy[tokenId] = uint16(gen1StakeByToken.length);
    gen1StakeByToken.push(TimeStake({
        owner: account,
        tokenId: tokenId,
        time: uint48(block.timestamp),
        trait: trait,
        reward_type: reward_type
    }));
    _gen1StakedTokens[account].add(tokenId); 


    emit TokenStaked("CHUBBYKAIJUGEN1", tokenId, account);
  }

  function _stakeGEN2(address account, uint16 tokenId, uint16 trait, bytes memory signature) internal {
    if(trait == 3){
      totalZombieStaked += 1;
    }else if(trait == 4){
      totalAlienStaked += 1;
    }else if(trait == 5){
      totalHalfZombieStaked += 1;
    }

    address rarity = rarityCheck(tokenId, signature);
    uint16 reward_type = 0;

    if(rarity == uncommon_address){
      if(trait == 3 || trait ==4){
        reward_type = 1;
      }else{
        reward_type = 2;
      }
    }else if(rarity == common_address){
      if(trait == 3 || trait ==4){
        reward_type = 4;
      }else{
        reward_type = 5;
      }
    }else if(rarity == rare_address){
      if(trait == 3 || trait ==4){
        reward_type = 7;
      }else{
        reward_type = 8;
      }
    }else if (rarity == epic_address){
      if(trait == 3 || trait ==4){
        reward_type = 10;
      }else{
        reward_type = 11;
      }
    }else if(rarity == sos_address){
      if(trait == 3 || trait ==4){
        reward_type = 13;
      }else{
        reward_type = 14;
      }
    }else if(rarity == one_address){
      if(trait == 3 || trait ==4){
        reward_type = 16;
      }else{
        reward_type = 17;
      }
    }

    gen2Hierarchy[tokenId] = uint16(gen2StakeByToken.length);
    gen2StakeByToken.push(TimeStake({
        owner: account,
        tokenId: tokenId,
        time: uint48(block.timestamp),
        trait: trait,
        reward_type: reward_type
    }));

    _gen2StakedTokens[account].add(tokenId); 


    emit TokenStaked("CHUBBYKAIJUGEN2", tokenId, account);
  }



  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool[] calldata gens, bool unstake) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      if(gens[i]){ // GEN1 Claim
        reward += _claimGEN1(tokenIds[i], unstake, time);
      }else{ // GEN2 Claim

      }
    }
    if (reward != 0) {
      chubbykaijuDAOCrunch.mint(msg.sender, reward);
    }
  }


  function _claimGEN1(uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    TimeStake memory stake = gen1StakeByToken[gen1Hierarchy[tokenId]];
    uint16 trait = stake.trait;
    uint16 reward_type = stake.reward_type;
    require(stake.owner == msg.sender, "only owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(time-stake.time);
      if(reward_type == 0){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 3){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 6){
        reward = 2*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 9){
        reward = 3*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 12){
        reward = 5*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 15){
        reward = 15*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(lastClaimTimestamp-stake.time);
      if(reward_type == 0){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 3){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 6){
        reward = 2*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 9){
        reward = 3*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 12){
        reward = 5*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 15){
        reward = 15*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }
    }
    if (unstake) {
      TimeStake memory lastStake = gen1StakeByToken[gen1StakeByToken.length - 1];
      gen1StakeByToken[gen1Hierarchy[tokenId]] = lastStake; 
      gen1Hierarchy[lastStake.tokenId] = gen1Hierarchy[tokenId];
      gen1StakeByToken.pop(); 
      delete gen1Hierarchy[tokenId]; 

      if(trait == 0){
        totalPowerStaked -= 1;
      }else if(trait == 1){
        totalMoneyStaked -= 1;
      }else if(trait == 2){
        totalMusicStaked -= 1;
      }
      if(reward_type == 0){
        rewardtypeStaked.uncommon_gen1 -=1;
      }else if(reward_type == 3){
        rewardtypeStaked.common_gen1 -= 1;
      }else if(reward_type == 6){
        rewardtypeStaked.rare_gen1 -= 1;
      }else if(reward_type == 9){
        rewardtypeStaked.epic_gen1 -= 1;
      }else if(reward_type == 12){
        rewardtypeStaked.sos_gen1 -= 1;
      }else if(reward_type == 15){
        rewardtypeStaked.one_gen1 -= 1;
      }
      _gen1StakedTokens[stake.owner].remove(tokenId); 
      emit TokenUnstaked("CHUBBYKAIJUGEN1", tokenId, stake.owner, reward);
    } 
    else {
      gen1StakeByToken[gen1Hierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time,
        trait: trait,
        reward_type: reward_type
      });
    }
    
  }

  function _claimGEN2(uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    TimeStake memory stake = gen2StakeByToken[gen2Hierarchy[tokenId]];
    uint16 trait = stake.trait;
    uint16 reward_type = stake.reward_type;
    require(stake.owner == msg.sender, "only owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(time-stake.time);
      if(reward_type==1){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==2){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==4){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==5){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==7){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==8){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==10){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==11){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==13){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==14){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==16){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==17){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(lastClaimTimestamp-stake.time);
      if(reward_type==1){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==2){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==4){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==5){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==7){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==8){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==10){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==11){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==13){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==14){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==16){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==17){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }
    }
    if (unstake) {
      TimeStake memory lastStake = gen2StakeByToken[gen1StakeByToken.length - 1];
      gen2StakeByToken[gen2Hierarchy[tokenId]] = lastStake; 
      gen2Hierarchy[lastStake.tokenId] = gen2Hierarchy[tokenId];
      gen2StakeByToken.pop(); 
      delete gen2Hierarchy[tokenId]; 

      if(trait == 3){
        totalZombieStaked -= 1;
      }else if(trait == 4){
        totalAlienStaked -= 1;
      }else if(trait == 5){
        totalHalfZombieStaked -= 1;
      }
      if(reward_type==1){
        rewardtypeStaked.uncommon_zombieailen -=1;
      }else if(reward_type==2){
        rewardtypeStaked.uncommon_halfzombie -=1;
      }else if(reward_type==4){
        rewardtypeStaked.common_zombieailen -=1;
      }else if(reward_type==5){
        rewardtypeStaked.common_halfzombie -=1;
      }else if(reward_type==7){
        rewardtypeStaked.rare_zombieailen -=1;
      }else if(reward_type==8){
        rewardtypeStaked.rare_halfzombie -=1;
      }else if(reward_type==10){
        rewardtypeStaked.epic_zombieailen -=1;
      }else if(reward_type==11){
        rewardtypeStaked.epic_halfzombie -=1;
      }else if(reward_type==13){
        rewardtypeStaked.sos_zombieailen -=1;
      }else if(reward_type==14){
        rewardtypeStaked.sos_halfzombie -=1;
      }else if(reward_type==16){
        rewardtypeStaked.one_zombieailen -=1;
      }else if(reward_type==17){
        rewardtypeStaked.one_halfzombie -=1;
      }
      _gen2StakedTokens[stake.owner].remove(tokenId); 
      emit TokenUnstaked("CHUBBYKAIJUGEN2", tokenId, stake.owner, reward);
    } 
    else {
      gen2StakeByToken[gen1Hierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time,
        trait: trait,
        reward_type: reward_type
      });
    }
    
  }

  function calculateGEN1Rewards(uint16  tokenId) external view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");
    TimeStake memory stake = gen1StakeByToken[gen1Hierarchy[tokenId]];

    uint48 time = uint48(block.timestamp);
    uint16 trait = stake.trait;
    uint16 reward_type = stake.reward_type;
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(time-stake.time);
      if(reward_type == 0){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 3){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 6){
        reward = 2*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 9){
        reward = 3*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 12){
        reward = 5*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 15){
        reward = 15*1*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(lastClaimTimestamp-stake.time);
      if(reward_type == 0){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 3){
        reward = 1*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 6){
        reward = 2*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 9){
        reward = 3*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 12){
        reward = 5*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type == 15){
        reward = 15*1*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }
    }
  }

  function calculateGEN2Rewards(uint16  tokenId) external view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");
    TimeStake memory stake = gen2StakeByToken[gen2Hierarchy[tokenId]];
    uint16 reward_type = stake.reward_type;
    uint48 time = uint48(block.timestamp);

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(time-stake.time);
      if(reward_type==1){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==2){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==4){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==5){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==7){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==8){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==10){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==11){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==13){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==14){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==16){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==17){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(time-stake.time)*CRUNCH_EARNING_RATE;
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*200? TIME_BASE_RATE: 6*(lastClaimTimestamp-stake.time);
      if(reward_type==1){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==2){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==4){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==5){
        reward = 1*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==7){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==8){
        reward = 2*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==10){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==11){
        reward = 3*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==13){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==14){
        reward = 5*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }else if(reward_type==16){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE/2;
      }else if(reward_type==17){
        reward = 15*3*(TIME_BASE_RATE+time_weight)*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
      }
    }
  }


  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint48 time = uint48(block.timestamp);

      totalCrunchEarned += (1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.uncommon_gen1);
      /*
        (1*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.uncommon_gen1)+
        (1*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.uncommon_zombieailen)+
        (1*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.uncommon_halfzombie)+
        (1*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.common_gen1)+
        (1*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.common_zombieailen)+
        (1*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.common_halfzombie);
      totalCrunchEarned +=
        (2*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.rare_gen1)+
        (2*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.rare_zombieailen)+
        (2*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.rare_halfzombie)+
        (3*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.epic_gen1)+
        (3*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.epic_zombieailen)+
        (3*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.epic_halfzombie)+
        (5*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.sos_gen1)+
        (5*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.sos_zombieailen)+
        (5*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.sos_halfzombie)+
        (15*1*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.one_gen1)+
        (15*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE/2)*rewardtypeStaked.one_zombieailen)+
        (15*3*(100000000+6*(time - lastClaimTimestamp))*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.one_halfzombie);*/
      
      
      lastClaimTimestamp = time;
    }
    _;
  }

  function GEN1depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _gen1StakedTokens[account];
    uint16[] memory tokenIds = new uint16[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint16(depositSet.at(i));
    }

    return tokenIds;
  }

  function GEN2depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _gen2StakedTokens[account];
    uint16[] memory tokenIds = new uint16[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint16(depositSet.at(i));
    }

    return tokenIds;
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function setGEN1Contract(address _address) external onlyOwner {
    chubbykaijuGen1 = IChubbyKaijuDAOGEN1(_address);
  }
  function setGEN2Contract(address _address) external onlyOwner {
    chubbykaijuGen2 = IChubbyKaijuDAOGEN2(_address);
  }
  function setPiranhaContract(address _address) external onlyOwner {
    chubbykaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
  }

  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
  }


  function messageHash(uint128 tokenId) public view returns (bytes32){
    return keccak256(Strings.toString(tokenId));
  }
  function rarityCheck(uint16 tokenId, bytes memory signature) public view returns (address) {
      bytes32 messageHash = keccak256(Strings.toString(tokenId));
      bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

      return recoverSigner(ethSignedMessageHash, signature);
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
      return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
      require(sig.length == 65, "sig invalid");

      assembly {
      /*
      First 32 bytes stores the length of the signature

      add(sig, 32) = pointer of sig + 32
      effectively, skips first 32 bytes of signature

      mload(p) loads next 32 bytes starting at the memory address p into memory
      */

      // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
      // second 32 bytes
          s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }

      // implicitly return (r, s, v)
  }

  

  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (bytes memory) {
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
        return buffer;
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

pragma solidity ^0.8.10;

interface IChubbyKaijuDAOStakingV1 {
  function stakeTokens(address, uint16[] calldata, bool[] calldata, bytes[] memory) external;
}

pragma solidity ^0.8.10;

interface IChubbyKaijuDAOCrunch {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
}

pragma solidity ^0.8.10;

interface IChubbyKaijuDAOGEN1 {
  function ownerOf(uint256) external view returns (address owner);
  function transferFrom(address, address, uint256) external;
  function safeTransferFrom(address, address, uint256, bytes memory) external;
  function burn(uint16) external;
  function traits(uint256) external returns (uint16);
}

pragma solidity ^0.8.10;

interface IChubbyKaijuDAOGEN2 {
  function ownerOf(uint256) external view returns (address owner);
  function transferFrom(address, address, uint256) external;
  function safeTransferFrom(address, address, uint256, bytes memory) external;
  function burn(uint16) external;
  function traits(uint256) external returns (uint16);
}