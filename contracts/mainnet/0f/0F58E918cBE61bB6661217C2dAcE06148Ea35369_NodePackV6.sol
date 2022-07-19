// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/AdminAccess.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/INodePackV3.sol";
import "./interfaces/IStrongPool.sol";
import "./interfaces/IStrongNFTPackBonus.sol";
import "./lib/InternalCalls.sol";
import "./lib/SbMath.sol";

contract NodePackV6 is AdminAccess, INodePackV3, InternalCalls {

  uint constant public PACK_TYPE_NODE_REWARD_LIFETIME = 0;
  uint constant public PACK_TYPE_NODE_REWARD_PER_SECOND = 1;
  uint constant public PACK_TYPE_FEE_STRONG = 2;
  uint constant public PACK_TYPE_FEE_CREATE = 3;
  uint constant public PACK_TYPE_FEE_RECURRING = 4;
  uint constant public PACK_TYPE_FEE_CLAIMING_NUMERATOR = 5;
  uint constant public PACK_TYPE_FEE_CLAIMING_DENOMINATOR = 6;
  uint constant public PACK_TYPE_RECURRING_CYCLE_SECONDS = 7;
  uint constant public PACK_TYPE_GRACE_PERIOD_SECONDS = 8;
  uint constant public PACK_TYPE_PAY_CYCLES_LIMIT = 9;
  uint constant public PACK_TYPE_NODES_LIMIT = 10;

  event Created(address indexed entity, uint packType, uint nodesCount, bool usedCredit, uint timestamp, address migratedFrom);
  event AddedNodes(address indexed entity, uint packType, uint nodesCount, uint totalNodesCount, bool usedCredit, uint timestamp, address migratedFrom);
  event MigratedNodes(address indexed entity, uint packType, uint nodesCount, uint lastPaidAt, uint rewardsDue, uint totalClaimed, address migratedFrom, uint timestamp);
  event MaturedNodes(address indexed entity, uint packType, uint maturedCount);
  event Paid(address indexed entity, uint packType, uint timestamp);
  event Claimed(address indexed entity, uint packType, uint reward);
  event SetNodeFeeCollector(address payable collector);
  event SetFeeCollector(address payable collector);
  event SetTakeStrongBips(uint bips);
  event SetNFTBonusContract(address strongNFTBonus);
  event SetServiceContractEnabled(address service, bool enabled);
  event SetPackTypeActive(uint packType, bool active);
  event SetPackTypeSetting(uint packType, uint settingId, uint value);
  event SetPackTypeHasSettings(uint packType, bool hasSettings);

  IERC20 public strongToken;
  IStrongNFTPackBonus public strongNFTBonus;

  uint public totalNodes;
  uint public totalMaturedNodes;
  uint public totalPacks;
  uint public totalPackTypes;
  uint public takeStrongBips;
  address payable public claimFeeCollector;
  address payable public nodeFeeCollector;

  mapping(address => uint) public entityNodeCount;
  mapping(address => uint) public entityCreditUsed;

  mapping(bytes => uint) public entityPackCreatedAt;
  mapping(bytes => uint) public entityPackLastPaidAt;
  mapping(bytes => uint) public entityPackLastClaimedAt;
  mapping(bytes => uint) public entityPackTotalNodeCount;
  mapping(bytes => uint) public entityPackMaturedNodeCount;
  mapping(bytes => uint) public entityPackRewardDue;
  mapping(bytes => uint) public entityPackClaimedTotal;
  mapping(bytes => uint) public entityPackClaimedMatured;

  mapping(uint => bool) public packTypeActive;
  mapping(uint => bool) public packTypeHasSettings;
  mapping(uint => mapping(uint => uint)) public packTypeSettings;
  mapping(address => bool) private serviceContractEnabled;

  function init(
    IERC20 _strongToken,
    IStrongNFTPackBonus _strongNFTBonus,
    address payable _nodeFeeCollector,
    address payable _claimFeeCollector
  ) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_claimFeeCollector != address(0), "no address");

    strongToken = _strongToken;
    strongNFTBonus = _strongNFTBonus;
    nodeFeeCollector = _nodeFeeCollector;
    claimFeeCollector = _claimFeeCollector;

    InternalCalls.init();
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function canPackBePaid(address _entity, uint _packType) public view returns (bool) {
    return doesPackExist(_entity, _packType) && !hasPackExpired(_entity, _packType) && !hasMaxPayments(_entity, _packType);
  }

  function doesPackExist(address _entity, uint _packType) public view returns (bool) {
    return entityPackLastPaidAt[getPackId(_entity, _packType)] > 0;
  }

  function isPackPastDue(address _entity, uint _packType) public view returns (bool) {
    bytes memory id = getPackId(_entity, _packType);
    uint lastPaidAt = entityPackLastPaidAt[id];

    return block.timestamp > (lastPaidAt + getRecurringPaymentCycle(_packType));
  }

  function hasMaxPayments(address _entity, uint _packType) public view returns (bool) {
    bytes memory id = getPackId(_entity, _packType);
    uint lastPaidAt = entityPackLastPaidAt[id];
    uint recurringPaymentCycle = getRecurringPaymentCycle(_packType);
    uint limit = block.timestamp + recurringPaymentCycle * getPayCyclesLimit(_packType);

    return lastPaidAt + recurringPaymentCycle >= limit;
  }

  function hasPackExpired(address _entity, uint _packType) public view returns (bool) {
    bytes memory id = getPackId(_entity, _packType);
    uint lastPaidAt = entityPackLastPaidAt[id];
    if (lastPaidAt == 0) return true;

    return block.timestamp > (lastPaidAt + getRecurringPaymentCycle(_packType) + getGracePeriod(_packType));
  }

  function getClaimingFee(address _entity, uint _packType, uint _timestamp) public view returns (uint) {
    return getRewardAt(_entity, _packType, _timestamp, true) * getClaimingFeeNumerator(_packType) / getClaimingFeeDenominator(_packType);
  }

  function getPacksClaimingFee(address _entity, uint _timestamp) external view returns (uint) {
    uint fee = 0;

    for (uint packType = 1; packType <= totalPackTypes; packType++) {
      fee = fee + getClaimingFee(_entity, packType, _timestamp);
    }

    return fee;
  }

  function getPackId(address _entity, uint _packType) public pure returns (bytes memory) {
    uint id = _packType != 0 ? _packType : 1;
    return abi.encodePacked(_entity, uint32(id), uint64(1));
  }

  function getEntityPackTotalNodeCount(address _entity, uint _packType) external view returns (uint) {
    return entityPackTotalNodeCount[getPackId(_entity, _packType)];
  }

  function getEntityPackMaturedNodeCount(address _entity, uint _packType) external view returns (uint) {
    return entityPackMaturedNodeCount[getPackId(_entity, _packType)];
  }

  function getEntityPackActiveNodeCount(address _entity, uint _packType) public view returns (uint) {
    bytes memory id = getPackId(_entity, _packType);
    return entityPackTotalNodeCount[id] - entityPackMaturedNodeCount[id];
  }

  function getEntityPackLifetimeRewards(address _entity, uint _packType) public view returns (uint) {
    return getNodeRewardLifetime(_packType) * entityPackTotalNodeCount[getPackId(_entity, _packType)];
  }

  function getEntityPackClaimedMaturedRewards(address _entity, uint _packType) public view returns (uint) {
    return entityPackClaimedMatured[getPackId(_entity, _packType)];
  }

  function getEntityPackClaimedTotalRewards(address _entity, uint _packType) public view returns (uint) {
    return entityPackClaimedTotal[getPackId(_entity, _packType)];
  }

  function getEntityPackAccruedTotalRewards(address _entity, uint _packType) public view returns (uint) {
    return entityPackClaimedTotal[getPackId(_entity, _packType)] + getRewardAt(_entity, _packType, block.timestamp, true);
  }

  function getPackLastPaidAt(address _entity, uint _packType) external view returns (uint) {
    return entityPackLastPaidAt[getPackId(_entity, _packType)];
  }

  function getNodeCreateFee(address _entity, uint _packType) public view returns (uint) {
    uint fee = getCreatingFeeInWei(_packType);
    uint lastPaidAt = entityPackLastPaidAt[getPackId(_entity, _packType)];

    if (lastPaidAt == 0) return fee;
    if (isPackPastDue(_entity, _packType)) return fee;
    if (hasPackExpired(_entity, _packType)) return 0;

    uint payCycleSeconds = getRecurringPaymentCycle(_packType);
    uint dueInSeconds = lastPaidAt + payCycleSeconds - block.timestamp;

    return dueInSeconds * fee / payCycleSeconds;
  }

  function getRecurringFee(address _entity, uint _packType) public view returns (uint) {
    return getRecurringFeeInWei(_packType) * getEntityPackActiveNodeCount(_entity, _packType);
  }

  function getPacksRecurringFee(address _entity) external view returns (uint) {
    uint fee = 0;

    for (uint packType = 1; packType <= totalPackTypes; packType++) {
      if (canPackBePaid(_entity, packType)) fee = fee + getRecurringFee(_entity, packType);
    }

    return fee;
  }

  function getReward(address _entity, uint _packType) external view returns (uint) {
    return getRewardAt(_entity, _packType, block.timestamp, true);
  }

  function getRewardAt(address _entity, uint _packType, uint _timestamp, bool _addBonus) public view returns (uint) {
    bytes memory id = getPackId(_entity, _packType);
    uint lastClaimedAt = entityPackLastClaimedAt[id];
    uint registeredAt = entityPackCreatedAt[id];

    if (!doesPackExist(_entity, _packType)) return 0;
    if (hasPackExpired(_entity, _packType)) return 0;
    if (_timestamp > block.timestamp) return 0;
    if (_timestamp < lastClaimedAt) return 0;
    if (_timestamp <= registeredAt) return 0;

    uint secondsPassed = lastClaimedAt > 0 ? _timestamp - lastClaimedAt : _timestamp - registeredAt;
    uint maxReward = getEntityPackLifetimeRewards(_entity, _packType);
    uint reward = secondsPassed * getNodeRewardPerSecond(_packType) * getEntityPackActiveNodeCount(_entity, _packType);
    uint bonus = _addBonus ? getBonusAt(_entity, _packType, _timestamp) : 0;
    uint totalReward = reward + bonus + entityPackRewardDue[id];

    if (entityPackClaimedTotal[id] >= maxReward) {
      return 0;
    }

    if ((entityPackClaimedTotal[id] + totalReward) >= maxReward) {
      totalReward = maxReward - entityPackClaimedTotal[id];
    }

    return totalReward;
  }

  function getBonusAt(address _entity, uint _packType, uint _timestamp) public view returns (uint) {
    if (address(strongNFTBonus) == address(0)) return 0;

    bytes memory id = getPackId(_entity, _packType);
    uint lastClaimedAt = entityPackLastClaimedAt[id] != 0 ? entityPackLastClaimedAt[id] : entityPackCreatedAt[id];

    return strongNFTBonus.getBonus(_entity, _packType, lastClaimedAt, _timestamp);
  }

  function getEntityRewards(address _entity, uint _timestamp) public view returns (uint) {
    uint reward = 0;

    for (uint packType = 1; packType <= totalPackTypes; packType++) {
      reward = reward + getRewardAt(_entity, packType, _timestamp > 0 ? _timestamp : block.timestamp, true);
    }

    return reward;
  }

  function getEntityCreditAvailable(address _entity, uint _timestamp) public view returns (uint) {
    return getEntityRewards(_entity, _timestamp) - entityCreditUsed[_entity];
  }

  function getRewardBalance() external view returns (uint) {
    return strongToken.balanceOf(address(this));
  }

  //
  // Actions
  // -------------------------------------------------------------------------------------------------------------------

  function create(uint _packType, uint _nodeCount, bool _useCredit) external payable {
    uint fee = getNodeCreateFee(msg.sender, _packType) * _nodeCount;
    uint strongFee = getStrongFeeInWei(_packType) * _nodeCount;
    uint packTypeLimit = getNodesLimit(_packType);
    uint timestamp = block.timestamp;
    bytes memory id = getPackId(msg.sender, _packType);

    require(packTypeActive[_packType], "invalid type");
    require(packTypeLimit == 0 || (entityPackTotalNodeCount[id] + _nodeCount) <= packTypeLimit, "over limit");
    require(_nodeCount >= 1, "invalid node count");
    require(msg.value >= fee, "invalid fee");

    if (address(strongNFTBonus) != address(0)) {
      strongNFTBonus.setEntityPackBonusSaved(msg.sender, _packType);
    }

    totalNodes += _nodeCount;
    entityNodeCount[msg.sender] += _nodeCount;

    if (entityPackTotalNodeCount[id] == 0) {
      entityPackCreatedAt[id] = timestamp;
      entityPackLastPaidAt[id] = timestamp;
      entityPackTotalNodeCount[id] += _nodeCount;
      totalPacks += 1;

      emit Created(msg.sender, _packType, _nodeCount, _useCredit, block.timestamp, address(0));
    }
    else {
      require(!hasPackExpired(msg.sender, _packType), "pack expired");

      updatePackState(msg.sender, _packType, true);
      entityPackTotalNodeCount[id] += _nodeCount;

      emit AddedNodes(msg.sender, _packType, _nodeCount, entityPackTotalNodeCount[id], _useCredit, block.timestamp, address(0));
    }

    if (_useCredit) {
      require(getEntityCreditAvailable(msg.sender, block.timestamp) >= strongFee, "not enough");
      entityCreditUsed[msg.sender] += strongFee;
    } else {
      uint takeStrong = strongFee * takeStrongBips / 10000;
      if (takeStrong > 0) {
        require(strongToken.transferFrom(msg.sender, nodeFeeCollector, takeStrong), "transfer failed");
      }
      if (strongFee > takeStrong) {
        require(strongToken.transferFrom(msg.sender, address(this), strongFee - takeStrong), "transfer failed");
      }
    }

    sendValue(nodeFeeCollector, msg.value);
  }

  function claim(uint _packType, uint _timestamp, address _toStrongPool) public payable returns (uint) {
    address entity = msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getPackId(entity, _packType);
    uint lastClaimedAt = entityPackLastClaimedAt[id] != 0 ? entityPackLastClaimedAt[id] : entityPackCreatedAt[id];

    require(doesPackExist(entity, _packType), "doesnt exist");
    require(!hasPackExpired(entity, _packType), "pack expired");
    require(!isPackPastDue(entity, _packType), "past due");
    require(_timestamp <= block.timestamp, "bad timestamp");
    require(lastClaimedAt + 900 < _timestamp, "too soon");

    uint reward = getRewardAt(entity, _packType, _timestamp, true);
    require(reward > 0, "no reward");
    require(strongToken.balanceOf(address(this)) >= reward, "over balance");

    uint fee = reward * getClaimingFeeNumerator(_packType) / getClaimingFeeDenominator(_packType);
    require(msg.value >= fee, "invalid fee");

    entityPackLastClaimedAt[id] = _timestamp;
    entityPackClaimedTotal[id] += reward;
    entityPackRewardDue[id] = 0;

    emit Claimed(entity, _packType, reward);

    if (entityCreditUsed[msg.sender] > 0) {
      if (entityCreditUsed[msg.sender] > reward) {
        entityCreditUsed[msg.sender] = entityCreditUsed[msg.sender] - reward;
        reward = 0;
      } else {
        reward = reward - entityCreditUsed[msg.sender];
        entityCreditUsed[msg.sender] = 0;
      }
    }

    updatePackState(msg.sender, _packType, false);

    if (address(strongNFTBonus) != address(0)) {
      strongNFTBonus.resetEntityPackBonusSaved(id);
    }

    if (reward > 0) {
      if (_toStrongPool != address(0)) IStrongPool(_toStrongPool).mineFor(entity, reward);
      else require(strongToken.transfer(entity, reward), "transfer failed");
    }

    sendValue(claimFeeCollector, fee);
    if (isUserCall() && msg.value > fee) sendValue(payable(msg.sender), msg.value - fee);

    return fee;
  }

  function claimAll(uint _timestamp, address _toStrongPool) external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint valueLeft = msg.value;

    for (uint packType = 1; packType <= totalPackTypes; packType++) {
      uint reward = getRewardAt(msg.sender, packType, _timestamp, true);

      if (reward > 0) {
        require(valueLeft >= 0, "not enough");
        uint paid = claim(packType, _timestamp, _toStrongPool);
        valueLeft = valueLeft - paid;
      }
    }

    if (valueLeft > 0) sendValue(payable(msg.sender), valueLeft);
  }

  function pay(uint _packType) public payable returns (uint) {
    require(canPackBePaid(msg.sender, _packType), "cant pay");

    updatePackState(msg.sender, _packType, true);

    bytes memory id = getPackId(msg.sender, _packType);
    uint fee = getRecurringFeeInWei(_packType) * getEntityPackActiveNodeCount(msg.sender, _packType);

    require(msg.value >= fee, "invalid fee");

    entityPackLastPaidAt[id] = entityPackLastPaidAt[id] + getRecurringPaymentCycle(_packType);

    emit Paid(msg.sender, _packType, entityPackLastPaidAt[id]);

    sendValue(nodeFeeCollector, fee);
    if (isUserCall() && msg.value > fee) sendValue(payable(msg.sender), msg.value - fee);

    return fee;
  }

  function payAll() external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no packs");

    uint valueLeft = msg.value;

    for (uint packType = 1; packType <= totalPackTypes; packType++) {
      if (!canPackBePaid(msg.sender, packType)) continue;

      require(valueLeft > 0, "not enough");
      uint paid = pay(packType);
      valueLeft = valueLeft - paid;
    }

    if (valueLeft > 0) sendValue(payable(msg.sender), valueLeft);
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function deposit(uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(strongToken.transferFrom(msg.sender, address(this), _amount), "transfer failed");
  }

  function withdraw(address _destination, uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_amount > 0);
    require(strongToken.balanceOf(address(this)) >= _amount, "over balance");
    require(strongToken.transfer(_destination, _amount), "transfer failed");
  }

  function approveStrongPool(IStrongPool _strongPool, uint _amount) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(strongToken.approve(address(_strongPool), _amount), "approve failed");
  }

  function setNodeFeeCollector(address payable _nodeFeeCollector) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_nodeFeeCollector != address(0));
    nodeFeeCollector = _nodeFeeCollector;
    emit SetNodeFeeCollector(_nodeFeeCollector);
  }

  function setClaimFeeCollector(address payable _claimFeeCollector) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_claimFeeCollector != address(0));
    claimFeeCollector = _claimFeeCollector;
    emit SetFeeCollector(_claimFeeCollector);
  }

  function setNFTBonusContract(address _contract) external onlyRole(adminControl.SERVICE_ADMIN()) {
    strongNFTBonus = IStrongNFTPackBonus(_contract);
    emit SetNFTBonusContract(_contract);
  }

  function setTakeStrongBips(uint _bips) external onlyRole(adminControl.SUPER_ADMIN()) {
    require(_bips <= 10000, "invalid value");
    takeStrongBips = _bips;
    emit SetTakeStrongBips(_bips);
  }

  function updateEntityPackLastPaidAt(address _entity, uint _packType, uint _lastPaidAt) external onlyRole(adminControl.SERVICE_ADMIN()) {
    bytes memory id = getPackId(_entity, _packType);
    entityPackLastPaidAt[id] = _lastPaidAt;
  }

  //
  // Settings
  // -------------------------------------------------------------------------------------------------------------------

  function getCustomSettingOrDefaultIfZero(uint _packType, uint _setting) internal view returns (uint) {
    return packTypeHasSettings[_packType] && packTypeSettings[_packType][_setting] > 0
    ? packTypeSettings[_packType][_setting]
    : packTypeSettings[0][_setting];
  }

  function getNodeRewardLifetime(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_NODE_REWARD_LIFETIME);
  }

  function getNodeRewardPerSecond(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_NODE_REWARD_PER_SECOND);
  }

  function getClaimingFeeNumerator(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_FEE_CLAIMING_NUMERATOR);
  }

  function getClaimingFeeDenominator(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_FEE_CLAIMING_DENOMINATOR);
  }

  function getCreatingFeeInWei(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_FEE_CREATE);
  }

  function getRecurringFeeInWei(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_FEE_RECURRING);
  }

  function getStrongFeeInWei(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_FEE_STRONG);
  }

  function getRecurringPaymentCycle(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_RECURRING_CYCLE_SECONDS);
  }

  function getGracePeriod(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_GRACE_PERIOD_SECONDS);
  }

  function getPayCyclesLimit(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_PAY_CYCLES_LIMIT);
  }

  function getNodesLimit(uint _packType) public view returns (uint) {
    return getCustomSettingOrDefaultIfZero(_packType, PACK_TYPE_NODES_LIMIT);
  }

  // -------------------------------------------------------------------------------------------------------------------

  function setPackTypeActive(uint _packType, bool _active) external onlyRole(adminControl.SERVICE_ADMIN()) {
    // Pack type 0 is being used as a placeholder for the default settings for pack types that don't have custom ones,
    // So it shouldn't be activated and used to create nodes
    require(_packType > 0, "invalid type");
    packTypeActive[_packType] = _active;
    if (totalPackTypes < _packType && _active) {
      totalPackTypes = _packType;
    }

    emit SetPackTypeActive(_packType, _active);
  }

  function setPackTypeHasSettings(uint _packType, bool _hasSettings) external onlyRole(adminControl.SERVICE_ADMIN()) {
    packTypeHasSettings[_packType] = _hasSettings;
    emit SetPackTypeHasSettings(_packType, _hasSettings);
  }

  function setPackTypeSetting(uint _packType, uint _settingId, uint _value) external onlyRole(adminControl.SERVICE_ADMIN()) {
    packTypeHasSettings[_packType] = true;
    packTypeSettings[_packType][_settingId] = _value;
    emit SetPackTypeSetting(_packType, _settingId, _value);
  }

  function setServiceContractEnabled(address _contract, bool _enabled) external onlyRole(adminControl.SERVICE_ADMIN()) {
    serviceContractEnabled[_contract] = _enabled;
    emit SetServiceContractEnabled(_contract, _enabled);
  }

  // -------------------------------------------------------------------------------------------------------------------

  function sendValue(address payable recipient, uint amount) internal {
    require(address(this).balance >= amount, "insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success,) = recipient.call{value : amount}("");
    require(success, "send failed");
  }

  function updatePackState(address _entity, uint _packType) external {
    require(msg.sender == address(strongNFTBonus), "invalid sender");

    updatePackState(_entity, _packType, true);
  }

  function updatePackState(address _entity, uint _packType, bool _saveRewardsDue) internal {
    bytes memory id = getPackId(_entity, _packType);

    uint rewardDue = getRewardAt(_entity, _packType, block.timestamp, false);
    uint accruedTotal = entityPackClaimedTotal[id] + rewardDue;
    uint nodeLifetimeReward = getNodeRewardLifetime(_packType);
    uint maturedNodesTotal = accruedTotal / nodeLifetimeReward;
    uint maturedNodesNew = maturedNodesTotal > entityPackMaturedNodeCount[id] ? maturedNodesTotal - entityPackMaturedNodeCount[id] : 0;

    if (_saveRewardsDue) {
      entityPackRewardDue[id] = rewardDue;
      entityPackLastClaimedAt[id] = block.timestamp;
    }

    if (maturedNodesNew > 0) {
      entityPackMaturedNodeCount[id] += maturedNodesNew;
      entityPackClaimedMatured[id] += maturedNodesNew * nodeLifetimeReward;
      totalMaturedNodes += maturedNodesNew;
      emit MaturedNodes(_entity, _packType, maturedNodesNew);
    }
  }

  //
  // Migration
  // -------------------------------------------------------------------------------------------------------------------

  function migrateNodes(address _entity, uint _packType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) external returns (bool) {
    require(serviceContractEnabled[msg.sender], "no service");
    require(packTypeActive[_packType], "invalid type");
    require(!doesPackExist(_entity, _packType) || !hasPackExpired(_entity, _packType), "pack expired");

    bytes memory id = getPackId(_entity, _packType);

    totalNodes += _nodeCount;
    entityNodeCount[_entity] += _nodeCount;

    if (entityPackCreatedAt[id] == 0) {
      entityPackCreatedAt[id] = block.timestamp;
      entityPackLastPaidAt[id] = _lastPaidAt > 0 ? _lastPaidAt : block.timestamp;
      totalPacks += 1;

      emit Created(_entity, _packType, _nodeCount, false, block.timestamp, msg.sender);
    }
    else {
      updatePackState(_entity, _packType, true);
      if (_lastPaidAt > 0) {
        entityPackLastPaidAt[id] = ((entityPackLastPaidAt[id] * entityPackTotalNodeCount[id]) + (_lastPaidAt * _nodeCount)) / (entityPackTotalNodeCount[id] + _nodeCount);
      }

      emit AddedNodes(_entity, _packType, _nodeCount, entityPackTotalNodeCount[id], false, block.timestamp, msg.sender);
    }

    entityPackTotalNodeCount[id] += _nodeCount;
    entityPackClaimedTotal[id] += _totalClaimed;
    entityPackRewardDue[id] += _rewardsDue;

    if (entityPackTotalNodeCount[id] > _nodeCount) {
      updatePackState(_entity, _packType, true);
    }

    emit MigratedNodes(_entity, _packType, _nodeCount, _lastPaidAt, _rewardsDue, _totalClaimed, msg.sender, block.timestamp);

    return true;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IAdminControl.sol";

abstract contract AdminAccess {

  IAdminControl public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), "no access");
    _;
  }

  function addAdminControlContract(IAdminControl _contract) external onlyRole(0) {
    adminControl = _contract;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0;

interface INodePackV3 {
  function doesPackExist(address entity, uint packId) external view returns (bool);

  function hasPackExpired(address entity, uint packId) external view returns (bool);

  function claim(uint packId, uint timestamp, address toStrongPool) external payable returns (uint);

//  function getBonusAt(address _entity, uint _packType, uint _timestamp) external view returns (uint);

  function getPackId(address _entity, uint _packType) external pure returns (bytes memory);

  function getEntityPackTotalNodeCount(address _entity, uint _packType) external view returns (uint);

  function getEntityPackActiveNodeCount(address _entity, uint _packType) external view returns (uint);

  function migrateNodes(address _entity, uint _nodeType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) external returns (bool);

//  function addPackRewardDue(address _entity, uint _packType, uint _rewardDue) external;

  function updatePackState(address _entity, uint _packType) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrongPool {
  function mineFor(address miner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStrongNFTPackBonus {
  function getBonus(address _entity, uint _packType, uint _from, uint _to) external view returns (uint);

  function setEntityPackBonusSaved(address _entity, uint _packType) external;

  function resetEntityPackBonusSaved(bytes memory _packId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./Context.sol";

abstract contract InternalCalls is Context {

  uint private constant _NOT_MAKING_INTERNAL_CALLS = 1;
  uint private constant _MAKING_INTERNAL_CALLS = 2;

  uint private _internal_calls_status;

  modifier makesInternalCalls() {
    _internal_calls_status = _MAKING_INTERNAL_CALLS;
    _;
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function init() internal {
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function isInternalCall() internal view returns (bool) {
    return _internal_calls_status == _MAKING_INTERNAL_CALLS;
  }

  function isContractCall() internal view returns (bool) {
    return _msgSender() != tx.origin;
  }

  function isUserCall() internal view returns (bool) {
    return !isInternalCall() && !isContractCall();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SbMath {

  uint internal constant DECIMAL_PRECISION = 1e18;

  /*
  * Multiply two decimal numbers and use normal rounding rules:
  * -round product up if 19'th mantissa digit >= 5
  * -round product down if 19'th mantissa digit < 5
  *
  * Used only inside the exponentiation, _decPow().
  */
  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  /*
  * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
  *
  * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
  *
  * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
  * "minutes in 1000 years": 60 * 24 * 365 * 1000
  */
  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {

    if (_minutes > 525_600_000) _minutes = 525_600_000;  // cap to avoid overflow

    if (_minutes == 0) return DECIMAL_PRECISION;

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else { // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IAdminControl {
  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);

  function ADMIN() external view returns (uint8);

  function SERVICE_ADMIN() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}