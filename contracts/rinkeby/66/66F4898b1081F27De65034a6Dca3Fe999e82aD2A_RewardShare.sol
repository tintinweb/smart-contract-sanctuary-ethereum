// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint balance);
    function approve(address to, uint tokenId) external;
}

interface IVE {
    function withdraw(uint _tokenId) external returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
    function create_lock(uint _value, uint _lock_duration) external returns (uint);
    function ownerOf(uint tokenId) external view returns (address owner);
}

interface IReward {
  function rewardToken() external view returns (address);
  function claimReward(uint tokenId, uint startEpoch, uint endEpoch) external returns (uint reward);
  function getEpochIdByTime(uint _time) view external returns (uint);
  function getEpochInfo(uint epochId) view external returns (uint, uint, uint);
  function getPendingRewardSingle(uint tokenId, uint epochId) view external returns (uint reward, bool finished);
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    uint256 public nextTokenId = 1;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

contract RewardShare is ERC721, Administrable {
    address public ve;
    uint256 public ve_tokenId;
    address public vereward;
    address public multi;
    uint256 public totalLocked;
    uint256 constant totalShare = 10000;
    mapping (uint256 => uint256) public totalAmount; // day => total multi amount
    mapping (uint256 => uint256) public globalReward; // epochId => reward

    event LogCreateSharedVE(uint256 tokenId, uint256 amount, uint256 duration);
    event LogWithdrawVE(uint256 tokenId);
    event LogWithdrawMulti(uint256 amount);
    event LogWithdrawReward(uint256 amount);
    event LogHarvest(uint256 tokenId, uint256 endTime, uint256 amount);
    event LogMint(uint256 tokenId, address to, uint256 amount, uint256 startTime, uint256 endTime);
    event LogMintBatch(uint256[] tokenId, address[] to, uint256 amount, uint256 startTime, uint256 endTime);

    constructor (address multi_, address ve_, address vereward_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        ve = ve_;
        vereward = vereward_;
        multi = multi_;
        setAdmin(msg.sender);
    }

    function createVe(uint256 amount, uint256 duration) onlyAdmin external returns (uint) {
        require(ve_tokenId == 0);
        IERC20(multi).approve(ve, amount);
        ve_tokenId = IVE(ve).create_lock(amount, duration);
        totalLocked = amount;
        emit LogCreateSharedVE(ve_tokenId, amount, duration);
        return ve_tokenId;
    }

    // withdraw multi after expired
    function withdrawMulti(address to) onlyAdmin external {
        IVE(ve).withdraw(ve_tokenId);
        IVE(ve).withdraw(ve_tokenId);
        uint256 amount = IERC20(multi).balanceOf(address(this));
        IERC20(multi).transferFrom(address(this), to, amount);
        ve_tokenId = 0;
        emit LogWithdrawMulti(amount);
    }

    function withdrawReward(address to, uint256 amount) onlyAdmin external {
        IERC20(IReward(vereward).rewardToken()).transferFrom(address(this), to, amount);
        emit LogWithdrawReward(amount);
    }

    function withdrawVe(address to) onlyAdmin external {
        IVE(ve).safeTransferFrom(address(this), to, ve_tokenId);
        emit LogWithdrawVE(ve_tokenId);
        ve_tokenId = 0;
    }

    function collectGlobalReward(uint256 startEpochId, uint256 endEpochId) internal {
      for (uint i = startEpochId; i <= endEpochId; i++) {
        globalReward[i] += IReward(vereward).claimReward(ve_tokenId, i, i);
      }
    }

    mapping (uint256 => uint256) public lastHarvestUntil; // tokenId => time

    mapping (uint256 => TokenInfo) public tokenInfo;

    uint256 public day = 60;

    struct TokenInfo {
        uint256 share;
        uint256 startTime;
        uint256 endTime;
    }

    function claimable(uint256 tokenId) external view returns(uint256) {
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      uint256 endTime = block.timestamp < tokenInfo[tokenId].endTime ? block.timestamp : tokenInfo[tokenId].endTime;
      return _claimable(tokenId, startTime, endTime);
    }

    function claimable(uint256 tokenId, uint256 endTime) external view returns(uint256) {
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      require(endTime <= block.timestamp && endTime <= tokenInfo[tokenId].endTime);
      return _claimable(tokenId, startTime, endTime);
    }
  
    function _claimable(uint256 tokenId, uint256 startTime, uint256 endTime) internal view returns(uint256) {
      uint256 startEpochId = IReward(vereward).getEpochIdByTime(startTime);
      uint256 endEpochId = IReward(vereward).getEpochIdByTime(endTime);

      (uint256 uncollected,) = IReward(vereward).getPendingRewardSingle(ve_tokenId, endEpochId);

      uint256 reward = 0;
      uint256 userLockStart;
      uint256 userLockEnd;
      uint256 collectedTime;
      for (uint i = startEpochId; i <= endEpochId; i++) {
        uint256 reward_i = globalReward[i] + uncollected;
        (uint epochStartTime, uint epochEndTime, ) = IReward(vereward).getEpochInfo(i);
        // user's unclaimed time span in an epoch
        userLockStart = epochStartTime;
        userLockEnd = epochEndTime;
        collectedTime = epochEndTime - epochStartTime;
        if (i == startEpochId) {
          userLockStart = startTime;
        }
        if (i == endEpochId) {
          userLockEnd = endTime; // assuming endTime <= block.timestamp
          collectedTime = block.timestamp - epochStartTime;
        }
        reward_i = reward_i * (userLockEnd - userLockStart) / collectedTime;
        reward += reward_i;
      }
      uint256 userReward = reward * tokenInfo[tokenId].share / totalLocked;
      return userReward;
    }

    function harvest(uint256 tokenId) external {
      require(msg.sender == IVE(ve).ownerOf(tokenId));
      // user's unclaimed timespan
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      uint256 endTime = block.timestamp < tokenInfo[tokenId].endTime ? block.timestamp : tokenInfo[tokenId].endTime;
      try this._harvest1(tokenId, startTime, endTime) returns (uint256 amount) {
        emit LogHarvest(tokenId, endTime, amount);
      } catch {
        emit LogHarvest(tokenId, endTime, 0);
      }
      //emit LogHarvest(tokenId, endTime, amount);
    }

    function harvest(uint256 tokenId, uint256 endTime) external {
      require(msg.sender == IVE(ve).ownerOf(tokenId));
      // user's unclaimed timespan
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      require(endTime <= block.timestamp && endTime <= tokenInfo[tokenId].endTime);
      uint256 amount = this._harvest1(tokenId, startTime, endTime);
      emit LogHarvest(tokenId, endTime, amount);
    }

    function _harvest1(uint256 tokenId, uint256 startTime, uint256 endTime) external returns (uint256) {
      uint256 startEpochId = IReward(vereward).getEpochIdByTime(startTime);
      uint256 endEpochId = IReward(vereward).getEpochIdByTime(endTime);
      collectGlobalReward(startEpochId, endEpochId);
      uint256 reward = 0;
      uint256 userLockStart;
      uint256 userLockEnd;
      uint256 collectedTime;
      for (uint i = startEpochId; i <= endEpochId; i++) {
        uint256 reward_i = globalReward[i];
        (uint epochStartTime, uint epochEndTime, ) = IReward(vereward).getEpochInfo(i);
        // user's unclaimed time span in an epoch
        userLockStart = epochStartTime;
        userLockEnd = epochEndTime;
        collectedTime = epochEndTime - epochStartTime;
        if (i == startEpochId) {
          userLockStart = startTime;
        }
        if (i == endEpochId) {
          userLockEnd = endTime; // assuming endTime <= block.timestamp
          collectedTime = block.timestamp - epochStartTime;
        }
        reward_i = reward_i * (userLockEnd - userLockStart) / collectedTime;
        reward += reward_i;
      }
      // update last harvest time
      lastHarvestUntil[tokenId] = endTime;
      uint256 userReward = reward * tokenInfo[tokenId].share / totalLocked;
      IERC20(IReward(vereward).rewardToken()).transferFrom(address(this), msg.sender, userReward);
      return userReward;
    }

    function _createLock(address to, uint256 amount, uint256 startDay, uint256 endDay) internal onlyAdmin returns (bool success, uint256 tokenId) {
      for (uint i = startDay; i < endDay; i++) {
        totalAmount[i] = totalAmount[i] + amount;
        if (totalAmount[i] > totalLocked) {
          return (false, 0);
        }
      }
      tokenId = nextTokenId;
      nextTokenId += 1;
      _mint(to, tokenId);
      tokenInfo[tokenId] = TokenInfo(amount, startDay * day, endDay * day);
      return (true, tokenId);
    }

    function mint(address to, uint256 amount, uint256 startTime, uint256 endTime) external onlyAdmin returns (bool success, uint256 tokenId) {
      uint startDay = startTime / day;
      uint endDay = endTime / day + 1;
      require(endDay - startDay <= 360, "duration is too long");
      (success, tokenId) = _createLock(to, amount, startDay, endDay);
      emit LogMint(tokenId, to, amount, startTime, endTime);
      return (success, tokenId);
    }

    function mintBatch(address[] calldata to, uint256 amount, uint256 startTime, uint256 endTime) external onlyAdmin returns (bool[] memory success, uint256[] memory tokenId) {
      uint len = to.length;
      success = new bool[](len);
      tokenId = new uint256[](len);
      uint startDay = startTime / day;
      uint endDay = endTime / day + 1;
      require(endDay - startDay <= 360, "duration is too long");
      for (uint i = 0; i < len; i++) {
        (bool succ, uint256 tid) = _createLock(to[i], amount, startDay, endDay);
        success[i] = succ;
        tokenId[i] = tid;
      }
      emit LogMintBatch(tokenId, to, amount, startTime, endTime);
      return (success, tokenId);
    }

    function mintByShare(address to, uint256 share, uint256 startTime, uint256 endTime) public onlyAdmin returns (bool success, uint256 tokenId) {
      uint startDay = startTime / day;
      uint endDay = endTime / day + 1;
      uint256 amount = share * totalLocked / totalShare;
      require(endDay - startDay <= 360, "duration is too long");
      (success, tokenId) = _createLock(to, amount, startDay, endDay);
      emit LogMint(tokenId, to, amount, startTime, endTime);
      return (success, tokenId);
    }

    function mintBatchByShare(address[] calldata to, uint256 share, uint256 startTime, uint256 endTime) external onlyAdmin returns (bool[] memory success, uint256[] memory tokenId) {
      uint len = to.length;
      success = new bool[](len);
      tokenId = new uint256[](len);
      uint startDay = startTime / day;
      uint endDay = endTime / day + 1;
      uint256 amount = share * totalLocked / totalShare;
      require(endDay - startDay <= 360, "duration is too long");
      for (uint i = 0; i < len; i++) {
        (bool succ, uint256 tid) = _createLock(to[i], amount, startDay, endDay);
        success[i] = succ;
        tokenId[i] = tid;
      }
      emit LogMintBatch(tokenId, to, amount, startTime, endTime);
      return (success, tokenId);
    }
}