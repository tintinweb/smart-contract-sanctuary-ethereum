// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "IERC721Receiver.sol";
import "ECDSA.sol";
import "Strings.sol";

import "IChubbyKaijuDAOStakingV2.sol";
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

contract ChubbyKaijuDAOStakingV2 is IChubbyKaijuDAOStakingV2, Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint128;

  uint32 public totalZombieStaked; // trait 0
  uint32 public totalAlienStaked; // trait 1
  uint32 public totalUndeadStaked; // trait 2

  uint48 public lastClaimTimestamp;
  uint128 public halving_phase = 0;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;
  uint128 public constant MAXIMUM_CRUNCH = 18000000 ether; 
  uint128 public CRUNCH_EARNING_RATE = 1024; //40; //74074074; // 1 crunch per day; H
  uint128 public constant TIME_BASE_RATE = 100000000;
  bool STAKE = true;
  bool UNSTAKE = false;

  uint128 public totalCrunchEarned;
  uint128 public remaining_crunch = 17999872 ether;  // for 10 halvings

  mapping(uint16=>uint128) public species_rate;

  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);

  IChubbyKaijuDAOGEN2 private chubbyKaijuGen2;
  IChubbyKaijuDAOCrunch private chubbyKaijuDAOCrunch;
  IChubbyKaijuDAOStakingV2Old private chubbyKaijuStakingOld;

  mapping(address => uint256[53]) public tokensByAddressBitMap;
  mapping(uint256 => uint256) public timeStakeByToken;

  uint256[53] public totalTokensStakedBitMap;
  uint256[53] public migratedTokensBitmap;

  address private _commonAddress;
  address private _uncommonAddress;
  address private _rareAddress;
  address private _epicAddress;
  address private _legendaryAddress;
  address private _oneAddress;

  struct rewardTypeStaked {
    uint32 common; // rewardType: 0
    uint32 uncommon; // rewardType: 1
    uint32 rare; // rewardType: 2
    uint32 epic; // rewardType: 3
    uint32 legendary; // rewardType: 5
    uint32 one; // rewardType: 15
  }
  rewardTypeStaked private typeStaked;

  constructor() {
    _pause();
  }

  function setSigners(address[] calldata signers) public onlyOwner{
    _commonAddress = signers[0];
    _uncommonAddress = signers[1];
    _rareAddress = signers[2];
    _epicAddress = signers[3];
    _legendaryAddress = signers[4];
    _oneAddress = signers[5];
  }

  function setSpeciesRate() public onlyOwner{
    species_rate[0] = 125;
    species_rate[1] = 150;
    species_rate[2] = 200;
  }

  function stakeTokens(uint16[] calldata tokenIds, bytes[] memory signatures) external whenNotPaused nonReentrant _updateEarnings {    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      _stakeGEN2(msg.sender, tokenIds[i], uint48(block.timestamp), signatures[i]);
      chubbyKaijuGen2.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  function _stakeGEN2(address account, uint16 tokenId, uint48 stakeTime, bytes memory signature) internal {
    uint16 trait = (tokenId <= 6666 ? 0 : tokenId <= 9999 ? 1 : 2);

    if (trait == 0) {
      totalZombieStaked += 1;
    } else if (trait == 1) {
      totalAlienStaked += 1;
    } else if (trait == 2) {
      totalUndeadStaked += 1;
    }

    address rarity = rarityCheck(tokenId, signature);
    uint16 rewardType = 0;

    if (rarity == _commonAddress) {
      rewardType = 0;
      typeStaked.common++;
    } else if (rarity == _uncommonAddress) {
      rewardType = 1;
      typeStaked.uncommon++;
    } else if (rarity == _rareAddress) {
      rewardType = 2;
      typeStaked.rare++;
    } else if (rarity == _epicAddress) {
      rewardType = 3;
      typeStaked.epic++;
    } else if (rarity == _legendaryAddress) {
      rewardType = 5;
      typeStaked.legendary++;
    } else if (rarity == _oneAddress) {
      rewardType = 15;
      typeStaked.one++;
    }

    _setMap(tokensByAddressBitMap[account], tokenId, STAKE);
    timeStakeByToken[tokenId] = _createTimeStake(account, tokenId, stakeTime, trait, rewardType);
  
    emit TokenStaked("CHUBBYKAIJUGen2", tokenId, account);
  }

  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;

    for (uint8 i = 0; i < tokenIds.length; i++) {
      reward += _claimGen2(tokenIds[i], unstake);
    }
  
    if (reward != 0) {
      chubbyKaijuDAOCrunch.mint(msg.sender, reward);
    }
  }

  function claimNonMigratedRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake, bytes[] memory signatures) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;

    for (uint8 i = 0; i < tokenIds.length; i++) {
      uint16 tokenIndex = chubbyKaijuStakingOld.gen2Hierarchy(uint256(tokenIds[i]));
      IChubbyKaijuDAOStakingV2Old.TimeStake memory stake = chubbyKaijuStakingOld.gen2StakeByToken(tokenIndex);
      _stakeGEN2(stake.owner, tokenIds[i], stake.time, signatures[i]);

      reward += _claimGen2(tokenIds[i], unstake);
  
      // also checks if token is migrated
      setMigrated(tokenIds[i]);
    }
  
    if (reward != 0) {
      chubbyKaijuDAOCrunch.mint(msg.sender, reward);
    }
  }

  function _claimGen2(uint16 tokenId, bool unstake) internal returns (uint128 reward) {
    uint48 time = uint48(block.timestamp);
    uint256 timeStake = timeStakeByToken[tokenId];
    (address owner, , uint48 stakeTime, uint16 trait, uint16 rewardType) = _getTimeStake(timeStake);
  
    require(owner == msg.sender, "only owners can unstake");
    // require(!(unstake && time - stakeTime < MINIMUM_TO_EXIT), "need to stake for at least 1 day to unstake");

    reward = _calculateGEN2Rewards(rewardType, stakeTime, trait);

    if (unstake) {
      if (trait == 0) {
        totalZombieStaked--;
      }else if (trait == 1) {
        totalAlienStaked--;
      } else if (trait == 2) {
        totalUndeadStaked--;
      }
      if (rewardType == 0) {
        typeStaked.common--;
      } else if (rewardType == 1) {
        typeStaked.uncommon--;
      } else if (rewardType == 2) {
        typeStaked.rare--;
      } else if (rewardType == 3) {
        typeStaked.epic--;
      } else if (rewardType == 5) {
        typeStaked.legendary--;
      } else if (rewardType == 15) {
        typeStaked.one--;
      }

      chubbyKaijuGen2.transferFrom(address(this), msg.sender, tokenId);
      _setMap(tokensByAddressBitMap[owner], tokenId, UNSTAKE);
      delete timeStakeByToken[tokenId];

      emit TokenUnstaked("CHUBBYKAIJUGen2", tokenId, owner, reward);
    } else {
      timeStakeByToken[tokenId] = _createTimeStake(
        owner, 
        tokenId, 
        time, 
        trait, 
        rewardType
      );
    }
  }

  function _calculateGEN2Rewards(uint16 rewardType, uint48 stakeTime, uint16 trait) internal view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");
    uint48 time = uint48(block.timestamp);
    uint128 timeWeight;
    uint128 stakePeriod;

    // if rewardType == 0, set rewardType to 1 for multiplier
    rewardType = rewardType == 0 ? 1 : rewardType;

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      stakePeriod = time - stakeTime;
    } 
    else if (stakeTime <= lastClaimTimestamp) {
      stakePeriod = lastClaimTimestamp - stakeTime;
    }

    timeWeight = stakePeriod > 3600 * 24 * 120 ? 2 * TIME_BASE_RATE : 20 * stakePeriod;
    reward = rewardType * stakePeriod * CRUNCH_EARNING_RATE;
    reward *= (TIME_BASE_RATE + timeWeight);
    reward *= species_rate[trait];
  }

  function calculateGEN2Rewards(uint16 tokenId) external view returns (uint128) {
    uint256 stake = timeStakeByToken[tokenId];
    (, , uint48 time, uint16 trait, uint16 rewardType) = _getTimeStake(stake);
    return _calculateGEN2Rewards(rewardType, time, trait);
  }

  function calculateNonMigratedGEN2Rewards(uint256 tokenId, uint16 rewardType) external view returns (uint128) {
    uint16 tokenIndex = chubbyKaijuStakingOld.gen2Hierarchy(tokenId);
    IChubbyKaijuDAOStakingV2Old.TimeStake memory stake = chubbyKaijuStakingOld.gen2StakeByToken(tokenIndex);
    return _calculateGEN2Rewards(rewardType, stake.time, stake.trait);
  }

  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint48 time = uint48(block.timestamp);
      uint128 temp2 = (100000000 + 20 * (time - lastClaimTimestamp)) * 150;
      uint128 timeMultiplier = (time - lastClaimTimestamp) * CRUNCH_EARNING_RATE;
      
      uint128 temp = timeMultiplier * (typeStaked.common + typeStaked.uncommon);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = 2 * timeMultiplier * typeStaked.rare;
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = 3 * timeMultiplier * typeStaked.epic;
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = 5 * timeMultiplier * typeStaked.legendary;
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = 15 * timeMultiplier * typeStaked.one;
      temp *= temp2;
      totalCrunchEarned += temp;

      lastClaimTimestamp = time;
    }
    if (MAXIMUM_CRUNCH - totalCrunchEarned < remaining_crunch / 2 && halving_phase < 10) {
      CRUNCH_EARNING_RATE /= 2;
      remaining_crunch /= 2;
      halving_phase += 1;
    }
    _;
  }

  function GEN2depositsOf(address account) external view returns (uint256[53] memory) {
    return tokensByAddressBitMap[account];
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function setGen2Contract(address _address) external onlyOwner {
    chubbyKaijuGen2 = IChubbyKaijuDAOGEN2(_address);
  }

  function setCrunchContract(address _address) external onlyOwner {
    chubbyKaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
  }

  function setOldContract(address _address) external onlyOwner {
    chubbyKaijuStakingOld = IChubbyKaijuDAOStakingV2Old(_address);
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
    return IERC721Receiver.onERC721Received.selector;
  }

  /* bitMap functions */
  function hasMigrated(uint256 tokenId) external view returns (bool) {
    uint256 tokenIndex = tokenId - 1;
    uint256 index = tokenIndex / 256;
    uint256 bitIndex = tokenIndex - (256 * index);
    uint256 bitAtIndex = migratedTokensBitmap[index] & (1 << bitIndex);

    return bitAtIndex > 0;
  }

  function setMigrated(uint256 tokenId) internal {
    uint256 tokenIndex = tokenId - 1;
    uint256 index = tokenIndex / 256;
    uint256 bitIndex = tokenIndex - (256 * index);
    uint256 bitToAdd = 1 << bitIndex;
    uint256 bitAtIndex = migratedTokensBitmap[index] & bitToAdd;
    require(bitAtIndex == 0, "token already migrated");

    migratedTokensBitmap[index] += bitToAdd;
  }

  function _setMap(uint256[53] storage map, uint256 tokenId, bool stake) internal {
    // tokenId must be greater than 0, else transaction will fail
    uint256 tokenIndex = tokenId - 1;
    uint256 index = tokenIndex / 256;
    uint256 bitIndex = tokenIndex - (256 * index);
    uint256 bitToChange = 1 << bitIndex;
    uint256 storageBits = 1 << 20;
    uint256 bitAtIndex;

    if (stake) {
      bitAtIndex = totalTokensStakedBitMap[index] & bitToChange;
      require(bitAtIndex == 0, "token already staked");
      map[index] += bitToChange;
      totalTokensStakedBitMap[index] += bitToChange;
      // store number of staked tokens at end of map
      map[52] += storageBits;
    } else {
      bitAtIndex = map[index] & bitToChange;
      require(bitAtIndex == bitToChange, "not owner of token");
      map[index] -= bitToChange;
      totalTokensStakedBitMap[index] -= bitToChange;
      // remove one from storage if there is at least 1
      uint16 tokenNum = uint16(map[52] >> 20);
      if (tokenNum >= 1) {
        map[52] -= storageBits;
      } else {
        revert("cannot unstake, no tokens found");
      }
    } 
  }

  function _getTokenNum(uint256[53] storage map) internal view returns (uint16 tokenNum) {
    tokenNum = uint16(map[52] >> 20);
  }

  function getTokenNum(address owner) external view returns (uint16 tokenNum) {
    tokenNum = _getTokenNum(tokensByAddressBitMap[owner]);
  }

  /* TimeStake functions 
  struct TimeStake {
    address owner;
    uint48 time;
    uint16 tokenId;
    uint16 trait;
    uint16 rewardType;
  }
  */
  function _createTimeStake(
    address owner, 
    uint16 tokenId, 
    uint48 time,
    uint16 trait, 
    uint16 rewardType
  ) internal pure returns (uint256 timeStake) {
    timeStake = uint256(uint160(owner));
    timeStake |= uint256(tokenId) << 160;
    timeStake |= uint256(time) << 176;
    timeStake |= uint256(trait) << 224;
    timeStake |= uint256(rewardType) << 240;
  }

  function _getTimeStake(uint256 timeStake) internal pure returns (
    address owner, 
    uint16 tokenId, 
    uint48 time, 
    uint16 trait, 
    uint16 rewardType
  ) {
    owner = address(uint160(timeStake));
    tokenId = uint16(timeStake >> 160);
    time = uint48(timeStake >> 176);
    trait = uint16(timeStake >> 224);
    rewardType = uint16(timeStake >> 240);
  }

  function getTimeStake(uint256 timeStake) external pure returns (
    address owner, 
    uint16 tokenId, 
    uint48 time, 
    uint16 trait, 
    uint16 rewardType
  ) {
    (owner, tokenId, time, trait, rewardType) = _getTimeStake(timeStake);
  } 
}