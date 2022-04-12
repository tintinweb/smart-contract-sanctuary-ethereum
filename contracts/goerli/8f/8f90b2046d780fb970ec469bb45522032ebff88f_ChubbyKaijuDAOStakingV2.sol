pragma solidity ^0.8.10;

import "Ownable.sol";
import "IERC721Receiver.sol";
import "EnumerableSet.sol";
import "Strings.sol";

import "IChubbyKaijuDAOStakingV2Old.sol";
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

contract ChubbyKaijuDAOStakingV2 is Ownable, IERC721Receiver {

  using EnumerableSet for EnumerableSet.UintSet;
  using Strings for uint256;

  bool public paused;

  uint256 public totalZombieStaked; // trait 0
  uint256 public totalAlienStaked; // trait 1
  uint256 public totalUndeadStaked; // trait 2

  uint256 public lastClaimTimestamp;

  uint256 public constant MINIMUM_TO_EXIT = 1 days;

  uint256 public constant MAXIMUM_CRUNCH = 18000000 ether; 
  uint256 public remaining_crunch = 17999872 ether;  // for 10 halvings
  uint256 public halving_phase = 0;

  uint256 public totalCrunchEarned;

  uint256 public CRUNCH_EARNING_RATE = 1024; //40; //74074074; // 1 crunch per day; H
  mapping(uint256=>uint256) public speciesRate; 
  uint256 public constant TIME_BASE_RATE = 100000000;

  //event TokenStaked(string kind, uint256 tokenId, address owner);
  //event TokenUnstaked(string kind, uint256 tokenId, address owner, uint256 earnings);

  IChubbyKaijuDAOGEN2 private chubbyKaijuGen2;
  IChubbyKaijuDAOCrunch private chubbyKaijuDAOCrunch;
  IChubbyKaijuDAOStakingV2Old private gen2StakeOld;

  mapping(address => EnumerableSet.UintSet) private _gen2StakedTokens;
  mapping(address => mapping(uint256 => uint256)) private _gen2StakedTimes;

  mapping(uint256 => uint256) public gen2RewardTypes;

  struct rewardTypeStaked {
    uint16 common_uncommon; // reward_type: 0 -> 1*1*(1+Time weight)
    //uint16 uncommon; // reward_type: 1 -> 1*1*(1+Time weight)
    uint16 rare; // reward_type: 2 -> 2*1*(1+Time weight)
    uint16 epic; // reward_type: 3 -> -> 3*1*(1+Time weight)
    uint16 legendary; // reward_type: 4 -> 5*1*(1+Time weight)
    uint16 one; // reward_type: 5 -> 15*1*(1+Time weight)
  }
  rewardTypeStaked private stakedCount;

  constructor() {

    speciesRate[0] = 125;
    speciesRate[1] = 150;
    speciesRate[2] = 200;

    paused = true;

  }

  function setRewardTypes(uint256[] calldata tokenIds, uint rewardType) public onlyOwner{
    for (uint256 i = 0; i < tokenIds.length; i++) {
      gen2RewardTypes[tokenIds[i]] = rewardType;
    }
  }

  function migrateTokens() external _updateEarnings {
      require(paused == false, "Staking paused");
      
      uint256[] memory tokenIds = gen2StakeOld.GEN2depositsOf(msg.sender);

      for (uint256 i = 0; i < tokenIds.length; i++) {
          _stakeGEN2(msg.sender, tokenIds[i], 1646434800); // staked since 2022-03-05 00:00:00
      }
  }

  function stakeTokens(uint256[] calldata tokenIds) external _updateEarnings {
    require(paused == false, "Staking paused");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _stakeGEN2(msg.sender, tokenIds[i], uint256(block.timestamp));
      chubbyKaijuGen2.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  function _stakeGEN2(address account, uint256 tokenId, uint256 time) internal {
    uint256 trait = (tokenId <= 6666 ? 0 : tokenId <= 9999 ? 1 : 2);

    if (trait == 0) {
      totalZombieStaked += 1;
    } else if (trait == 1) {
      totalAlienStaked += 1;
    } else if (trait == 2) {
      totalUndeadStaked += 1;
    }

    uint256 rewardType = gen2RewardTypes[tokenId];
    if (rewardType == 0) {
      stakedCount.common_uncommon += 1;
    /*} else if (rewardType == 1) {
      stakedCount.uncommon += 1;*/
    } else if(rewardType == 2) {
      stakedCount.rare += 1;
    } else if (rewardType == 3) {
      stakedCount.epic += 1;
    } else if (rewardType == 4) {
      stakedCount.legendary += 1;
    } else if(rewardType == 5) {
      stakedCount.one += 1;
    }

    _gen2StakedTokens[account].add(tokenId);
    _gen2StakedTimes[account][tokenId] = time;

    //emit TokenStaked("CHUBBYKAIJUGen2", tokenId, account);
  }

  function claimRewardsAndUnstake(uint256[] calldata tokenIds, bool unstake) external _updateEarnings {
    require(paused == false, "Staking paused");
    require(tx.origin == msg.sender, "eos only");

    uint256 reward;
    uint256 time = uint256(block.timestamp);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      reward += _claimGen2(tokenIds[i], unstake, time);
    }

    if (reward != 0) {
      chubbyKaijuDAOCrunch.mint(msg.sender, reward);
    }
  }

  function _claimGen2(uint256 tokenId, bool unstake, uint256 time) internal returns (uint256 reward) {
    require(_gen2StakedTokens[msg.sender].contains(tokenId), "only owners can unstake");
    
    uint256 trait = (tokenId <= 6666 ? 0 : tokenId <= 9999 ? 1 : 2);
    uint256 rewardType = gen2RewardTypes[tokenId];
    uint256 stake_time = _gen2StakedTimes[msg.sender][tokenId];

    require(!(unstake && block.timestamp - stake_time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    reward = _calculateGEN2Rewards(tokenId);

    if (unstake) {
      if (trait == 0) {
        totalZombieStaked -= 1;
      } else if (trait == 1) {
        totalAlienStaked -= 1;
      } else if(trait == 2) {
        totalUndeadStaked -= 1;
      }
    
      if (rewardType == 0) {
        stakedCount.common_uncommon -= 1;
      /*} else if (rewardType == 1) {
        stakedCount.uncommon -= 1;*/
      } else if(rewardType == 2) {
        stakedCount.rare -= 1;
      } else if (rewardType == 3) {
        stakedCount.epic -= 1;
      } else if (rewardType == 4) {
        stakedCount.legendary -= 1;
      } else if(rewardType == 5) {
        stakedCount.one -= 1;
      }
      
      _gen2StakedTokens[msg.sender].remove(tokenId); 
      delete _gen2StakedTimes[msg.sender][tokenId];

      chubbyKaijuGen2.safeTransferFrom(address(this), msg.sender, tokenId);

      //emit TokenUnstaked("CHUBBYKAIJUGen2", tokenId, msg.sender, reward);
    } else {
      _gen2StakedTimes[msg.sender][tokenId] = time;
    }
  }

  function _calculateGEN2Rewards(uint256  tokenId) internal view returns (uint256 reward) {
    require(tx.origin == msg.sender, "eos only");

    uint256 time = uint256(block.timestamp);
    uint256 trait = (tokenId <= 6666 ? 0 : tokenId <= 9999 ? 1 : 2);
    uint256 rewardType = gen2RewardTypes[tokenId];
    uint256 stakeTime = _gen2StakedTimes[msg.sender][tokenId];
    uint256 timeWeight;

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      timeWeight = time-stakeTime > 3600*24*120 ? 2*TIME_BASE_RATE : 20*(time-stakeTime);
      if (rewardType == 0) {
        reward = 1*1*(time-stakeTime)*CRUNCH_EARNING_RATE;
      /*} else if (rewardType == 1) {
        reward = 1*1*(time-stakeTime)*CRUNCH_EARNING_RATE;*/
      } else if (rewardType == 2) {
        reward = 2*1*(time-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 3) {
        reward = 3*1*(time-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 4) {
        reward = 5*1*(time-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 5) {
        reward = 15*1*(time-stakeTime)*CRUNCH_EARNING_RATE;
      }
    } else if (stakeTime <= lastClaimTimestamp) {
      timeWeight = lastClaimTimestamp-stakeTime > 3600*24*120 ? 2*TIME_BASE_RATE : 20*(lastClaimTimestamp-stakeTime);
      if (rewardType == 0) {
        reward = 1*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;
      /*} else if (rewardType == 1) {
        reward = 1*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;*/
      } else if (rewardType == 2) {
        reward = 2*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 3) {
        reward = 3*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 4) {
        reward = 5*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;
      } else if (rewardType == 5) {
        reward = 15*1*(lastClaimTimestamp-stakeTime)*CRUNCH_EARNING_RATE;
      }
    }
    reward *= (TIME_BASE_RATE+timeWeight);
    reward *= speciesRate[trait];
  }

  function calculateGEN2Rewards(uint256  tokenId) external view returns (uint256) {
    return _calculateGEN2Rewards(tokenId);
  }

  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint256 time = uint256(block.timestamp);
      uint256 temp = (1*(time-lastClaimTimestamp)*CRUNCH_EARNING_RATE*stakedCount.common_uncommon);
      uint256 temp2 = (100000000+20*(time - lastClaimTimestamp))*150;
      temp *= temp2;
      totalCrunchEarned += temp;

      /*temp = (1*1*(time-lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*stakedCount.uncommon);
      temp *= temp2;
      totalCrunchEarned += temp;*/

      temp = (2*1*(time-lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*stakedCount.rare);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (3*1*(time-lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*stakedCount.epic);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (5*1*(time-lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*stakedCount.legendary);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (15*1*(time-lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*stakedCount.one);
      temp *= temp2;
      totalCrunchEarned += temp;
      
      lastClaimTimestamp = time;
    }
    if (MAXIMUM_CRUNCH-totalCrunchEarned < remaining_crunch/2 && halving_phase < 10){
      CRUNCH_EARNING_RATE /= 2;
      remaining_crunch /= 2;
      halving_phase += 1;
    }
    _;
  }

  function GEN2depositsOf(address account) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage depositSet = _gen2StakedTokens[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint256(depositSet.at(i));
    }

    return tokenIds;
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }

  function setGen2Contract(address _address) external onlyOwner {
    chubbyKaijuGen2 = IChubbyKaijuDAOGEN2(_address);
  }

  function setCrunchContract(address _address) external onlyOwner {
    chubbyKaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
  }

  function setOldContract(address _address) external onlyOwner {
    gen2StakeOld = IChubbyKaijuDAOStakingV2Old(_address);
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {    
    return IERC721Receiver.onERC721Received.selector;
  }
}