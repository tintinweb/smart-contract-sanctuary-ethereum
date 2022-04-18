// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";
import "Strings.sol";

import "IChubbyKaijuDAOStakingV2_old.sol";
import "IChubbyKaijuDAOCrunch.sol";
import "IChubbyKaijuDAOGEN2.sol";

/***************************************************************************************************
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddddxxxxxdd
kkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkxkkkkkkkkkkkkkkkkkkkkkxxddddddddddddxxkkkxx
kkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkxxdddddxxxxxkkkkkkkkkkkkkkkkxxddddddddddddxxkxkk
kkkkkkkkkkkkkkkkkkkkxxxxxddddxxkxxkkxxkkkkkkkxxkkxxkkkxxddddddddxxxxkkkkkkkkxxkkkxxddddddddddddxxkkk
kkkkkkkkkkkkkkkxxxxddddddddxxxxkxxoooodxkkkkkxxdooddxkxxkkkxxxxdddddxxxkkkkkkkkkkkxxdddddddddddddxkk
kkkkkkkkkkkkxxxdddddoddxxxxkkkxl,.',,''.',::;'.''','',lxxxkkkkxxddddddxxxkkkxxxxxkkxddddddddddddddxk
kkkkkkkkxxxdddddddddddxxxxdddo,.,d0XXK0kdl;,:ok0KKK0x;.'lxxxxxxxxddddddddxxkkxxxxxxddodddddddddddddx
kkkkkxxxddddddddddddddddddddl'.:KMMMMMMMMNKXWMMMWWMMWXc..';;;:cloddddddddddxkkxxdddddodddddddddddddd
kkxxxddddddddddddddddddddddc..c0WMMMMMMMMWXNMMMMMMMWk;,',;::;,'..':oxxxxddodxxxkxxdddddxdddddddddddd
kxxdddddddddddddddddddddoc'.'d0XWMMMMMMMMMWMMMMMMMMWXOKNWWMMMWX0kl,.'cdkkxxxddddxdddxxkkkxxxdddddddd
xddddxxxxxxdddddddddddl:'.,xXNKKNMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMNk:..cxkkxxxddddddxkkkkkkkxddddddd
xxxxxkkkxxxdddddddddo;..ckNMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,.,dxxkkxxxdddxkkkkkxkkxdddddd
kkkkxxxxdddddddoddo:..c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..cxkkkkkxxxxkkkkkkkkkxddddd
kkkxxxddoddddddddd:..xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNWWMMMMMMMMMMWNO,.;dkkkkkxkkxxkkkkkkkxxdddd
kxxxdddddo:'',;:c;. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNWMMMMMWMMMWMMMXc.'okxkkkkkkkkkkkkkkkxdddd
xxdddddodo' .;,',,,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:xXMMMMMMMMMMMWNNNXd..lkkkkkkkkkxkkkkkkkxddd
ddddddddddc..oKKXWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWkc'      ,0MMMMMMMMMWNNNXNWx..okkkkkkkkkkkkkkkkxdod
dddddddddddl..l0XNNWWWMMWXNMMMMMMMMMMMMMMMMMMMMNd.   ....  :XMMMMMMWWW0l,,;d0l.,xkkkxkkkkkkkkkkkxddd
ddddddddddxko'.,lxO0KXNNO;cXMMMMMMMMMMMMMMMMMMMk.  ....... .kMMMMMMMWk.     :x'.lkkkkkkkkkkkkkkkkxdd
ddddddddxxxkkxl;'.'',:cl:..dWMMMMMMMMMMMMMMMMMWl  ........ .kMMMMMMMNc  ... .c, :xxkkkkkkkkkkkkkkxdd
dddddddxkkkkkkkkxdoc:;,''. ;KMMMMMMMMMMMMMMMMMWl  .......  ,KWWMWX0Ox'       '..cxxkkkkkkkkkkkkkkxdd
dddddxxkkkkkkkkxxkkxkkkkxo'.oWMMMMMMMMMMMMMMMMMO'    ...  .xKkoc;,,,;,.   ,:;,...:dkxkkxkkkkkkkkkxdd
ddddxxkkkkkkkkkkkkkxkkxxddc..kWMMMMMMMMMMMMMMMMMXdc:.. ..;:;...'oOXNWO:colkWMWXk;.,xkxkkkkkkkkkkkxdd
ddxxkkxxkkkkkkkkkkkkxxddddo;.;KMMMMMMMMMMMMMMMMMMMMWX0O0XXxcod;cKMMMMWKl:OMMMMMM0,.lkxkkkkkkkkkkkxdd
dxxkkkkkkkkkkkkxxkkxxddddddo,.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMWMKc:KMMMMMNxoKMMWMMM0,.lkxxxkkkkkkkkxxdd
xxkkkkkkkkkkkkkkkkxxddddddddl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWMMMMWWMMMWMMNl.,dkkkxkkkkkkkkxddd
xkkkkkkkkkkkkkkkkxdddddddddodl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMKdOWNxo0WNxlOWKcoXNo..okxxkkkkkkkkkkxddd
kkkkkkkkkkkkkkkkkxddodddddddddo'.,OWMMMMMMMMMMMMMMMMMMMMMN0Oc .lc. .l:. .;. .,, .lkxxkkkkkkkkkkxxddd
kkkkkkkkkkkkkkkkxddddddddddddddo' cNMMMMMMMMMMMMMMMMMMMMMKl,;'. .,,. .'. .,. '' 'xkkxkkkkkkkkkkxdddd
kkkkkkkkkkkkkkkkxddoddddl:,'..';. :NMMMMMMMMMMMMMMMMMMMMMWWWWKlc0WNd,xNx;kWx;xl ,xkkkkxxkkxxkkxxdddd
kkkkkkkkkkkkkkkkxdddddo:..:dxdl'  ,0MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMWWMMWWK; :kkkkkkkkkkxkkxddddd
kkkkkkkkkxkkkkkxxdoddo; 'kNMWMNl.'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:.'dkkkkkxkkkkkkxdddddd
kkkkkkkkkkkxkkkxxddddo' lXNMMWo.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o' 'dkkkkxxkkkkkkxxdddddd
kkkkkkkxkkkkkkkxdc;,,'.,kXNMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXO:,,..ckkkkxkkkxkkxxddddddd
kkkkkkkkkxxkxkxc..;loox0KKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXXXXXXXXXXXKXXk'.cxkxkkxkkkxxdddddddd
kkkkkkkkkkkkxkl..xNMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNWWWWWMMMMMMWO'.ckxkkxkxxxdoddddddx
kkkkkkkkkkkkkx, cNMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..okkkkxddddddddddxx
kkkkkkkkkkkkkx, cNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.'dkxxddddddddddxkk
kkkkkkkkkxkxxx: ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMX; :ddddddddoddxxkkx
kkkkkkkkxxkkxko..dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXXXXXXNNWMMMMMMMMMWk..cdddddddddxxkxxd
kkkkkkkxxkkxkkx, cXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMWWWNNNNWMMMMMMMMN: ,oddddddxxxkxxdd
kkkkkkkkkkkxkko..oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWMMMMMMMMMMMMMMMMWWWMMMMMMMMWk..ldddddxkkxkkxxx
xkkkkkkkkkkxkd,.lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ;dddxxkkkkxxkkk
xxkkkkkkkxkkk: :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo 'dxxkkkkkkkkkkk
dxkkkkkkkkxkx, dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..okxkkkkkkkkkkx
ddxkkxkkkkxkd'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMX; ckkkkkkkkkkxxd
dodxxkkkkxkkx; cWMMMMWNWMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWc ;xkkkxkkkxxddd
dddddxxkkkkxkl..OWMMWNXWMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMd.'dkkkkxxdddddd
ddddddxxkkkkkx; :KWWN0KWMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMk..okxxxdddddddd
ddddddddxxkkkkl..xXX0ccKMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMM0'.lxddddddddddd
***************************************************************************************************/

contract ChubbyKaijuDAOStakingV2 is IChubbyKaijuDAOStakingV2, OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  using Strings for uint128;

  uint32 public totalZombieStaked; // trait 0
  uint32 public totalAlienStaked; // trait 1
  uint32 public totalUndeadStaked; // trait 2



  uint48 public lastClaimTimestamp;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;

  uint128 public constant MAXIMUM_CRUNCH = 18000000 ether; 
  uint128 public remaining_crunch = 17999872 ether;  // for 10 halvings
  uint128 public halving_phase = 0;

  uint128 public totalCrunchEarned;

  uint128 public CRUNCH_EARNING_RATE = 1024; //40; //74074074; // 1 crunch per day; H
  mapping(uint16=>uint128) public species_rate; 
  uint128 public constant TIME_BASE_RATE = 100000000;

  struct TimeStake { uint16 tokenId; uint48 time; address owner; uint16 trait; uint16 reward_type;}

  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);

  IChubbyKaijuDAOGEN2 private chubbykaijuGen2;
  IChubbyKaijuDAOCrunch private chubbykaijuDAOCrunch;


  TimeStake[] public gen2StakeByToken; 
  mapping(uint16 => uint16) public gen2Hierarchy; 
  mapping(address => EnumerableSetUpgradeable.UintSet) private _gen2StakedTokens;


  address private common_address;
  address private uncommon_address;
  address private rare_address;
  address private epic_address;
  address private legendary_address;
  address private one_address;

  

  struct rewardTypeStaked{
    uint32  common_gen2; // reward_type: 0 -> 1*1*(1+Time weight)
    uint32  uncommon_gen2; // reward_type: 1 -> 1*1*(1+Time weight)
    uint32  rare_gen2; // reward_type: 2 -> 2*1*(1+Time weight)
    uint32  epic_gen2; // reward_type: 3 -> -> 3*1*(1+Time weight)
    uint32  legendary_gen2; // reward_type: 4 -> 5*1*(1+Time weight)
    uint32  one_gen2; // reward_type: 5 -> 15*1*(1+Time weight)

  }

  rewardTypeStaked private rewardtypeStaked;

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    _pause();
  }

  function setSigners(address[] calldata signers) public onlyOwner{
    common_address = signers[0];
    uncommon_address = signers[1];
    rare_address = signers[2];
    epic_address = signers[3];
    legendary_address = signers[4];
    one_address = signers[5];
  }

  function setSpeciesRate() public onlyOwner{
    species_rate[0] = 125;
    species_rate[1] = 150;
    species_rate[2] = 200;
  }


  function stakeTokens(address account, uint16[] calldata tokenIds, bytes[] memory signatures) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender), "only owners approved");
    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(chubbykaijuGen2.ownerOf(tokenIds[i]) == msg.sender, "only owners approved");
      uint16 trait = chubbykaijuGen2.traits(tokenIds[i]); 
      _stakeGEN2(account, tokenIds[i], trait, signatures[i]);
      chubbykaijuGen2.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  
  }


  function _stakeGEN2(address account, uint16 tokenId, uint16 trait, bytes memory signature) internal {
    if(trait == 0){
      totalZombieStaked += 1;
    }else if(trait == 1){
      totalAlienStaked += 1;
    }else if(trait == 2){
      totalUndeadStaked += 1;
    }
    address rarity = rarityCheck(tokenId, signature);
    uint16 reward_type = 0;

    if(rarity == common_address){
      reward_type = 0;
      rewardtypeStaked.common_gen2 +=1;
    }else if(rarity == uncommon_address){
      reward_type = 1;
      rewardtypeStaked.uncommon_gen2 +=1;
    }else if(rarity == rare_address){
      reward_type = 2;
      rewardtypeStaked.rare_gen2 +=1;
    }else if (rarity == epic_address){
      reward_type = 3;
      rewardtypeStaked.epic_gen2 +=1;
    }else if(rarity == legendary_address){
      reward_type = 4;
      rewardtypeStaked.legendary_gen2 +=1;
    }else if(rarity == one_address){
      reward_type = 5;
      rewardtypeStaked.one_gen2 +=1;
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
    

    emit TokenStaked("CHUBBYKAIJUGen2", tokenId, account);
  }



  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      reward += _claimGen2(tokenIds[i], unstake, time);
    }
    if (reward != 0) {
      chubbykaijuDAOCrunch.mint(msg.sender, reward);
    }
  }


  function _claimGen2(uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    TimeStake memory stake = gen2StakeByToken[gen2Hierarchy[tokenId]];
    uint16 trait = stake.trait;
    uint16 reward_type = stake.reward_type;
    require(stake.owner == msg.sender, "only owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    reward = _calculateGEN2Rewards(tokenId);

    if (unstake) {
      TimeStake memory lastStake = gen2StakeByToken[gen2StakeByToken.length - 1];
      gen2StakeByToken[gen2Hierarchy[tokenId]] = lastStake; 
      gen2Hierarchy[lastStake.tokenId] = gen2Hierarchy[tokenId];
      gen2StakeByToken.pop(); 
      delete gen2Hierarchy[tokenId]; 

      if(trait == 0){
        totalZombieStaked -= 1;
      }else if(trait == 1){
        totalAlienStaked -= 1;
      }else if(trait == 2){
        totalUndeadStaked -= 1;
      }
      if(reward_type == 0){
        rewardtypeStaked.common_gen2 -=1;
      }else if(reward_type == 1){
        rewardtypeStaked.uncommon_gen2 -= 1;
      }else if(reward_type == 2){
        rewardtypeStaked.rare_gen2 -= 1;
      }else if(reward_type == 3){
        rewardtypeStaked.epic_gen2 -= 1;
      }else if(reward_type == 4){
        rewardtypeStaked.legendary_gen2 -= 1;
      }else if(reward_type == 5){
        rewardtypeStaked.one_gen2 -= 1;
      }
      _gen2StakedTokens[stake.owner].remove(tokenId); 
      chubbykaijuGen2.transferFrom(address(this), msg.sender, tokenId);

      emit TokenUnstaked("CHUBBYKAIJUGen2", tokenId, stake.owner, reward);
    } 
    else {
      gen2StakeByToken[gen2Hierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time,
        trait: trait,
        reward_type: reward_type
      });
    }
    
  }


  function _calculateGEN2Rewards(uint16  tokenId) internal view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");
    TimeStake memory stake = gen2StakeByToken[gen2Hierarchy[tokenId]];

    uint48 time = uint48(block.timestamp);
    uint16 reward_type = stake.reward_type;
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*120? 2*TIME_BASE_RATE: 20*(time-stake.time);
      if(reward_type == 0){
        reward = 1*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*120? 2*TIME_BASE_RATE: 20*(lastClaimTimestamp-stake.time);
      if(reward_type == 0){
        reward = 1*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    }
    reward *= species_rate[stake.trait];
  }
  function calculateGEN2Rewards(uint16  tokenId) external view returns (uint128) {
    return _calculateGEN2Rewards(tokenId);
  }

  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint48 time = uint48(block.timestamp);
      uint128 temp = (1*1*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.common_gen2);
      uint128 temp2 = (100000000+20*(time - lastClaimTimestamp))*150;
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (1*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.uncommon_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (2*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.rare_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (3*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.epic_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (5*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.legendary_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (15*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.one_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;
      
      lastClaimTimestamp = time;
    }
    if(MAXIMUM_CRUNCH-totalCrunchEarned < remaining_crunch/2 && halving_phase < 10){
      CRUNCH_EARNING_RATE /= 2;
      remaining_crunch /= 2;
      halving_phase += 1;
    }
    _;
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

  function setGen2Contract(address _address) external onlyOwner {
    chubbykaijuGen2 = IChubbyKaijuDAOGEN2(_address);
  }

  function setCrunchContract(address _address) external onlyOwner {
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

  function rarityCheck(uint16 tokenId, bytes memory signature) public pure returns (address) {
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