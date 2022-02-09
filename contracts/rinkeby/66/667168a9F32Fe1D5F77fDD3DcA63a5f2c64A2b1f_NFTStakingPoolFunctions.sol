// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./INFTStakingPool.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IRainiNft1155 is IERC1155 {
  struct CardLevel {
    uint64 conversionRate; // number of base tokens required to create
    uint32 numberMinted;
    uint128 tokenId; // ID of token if grouped, 0 if not
    uint32 maxStamina; // The initial and maxiumum stamina for a token
  }
  
  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  function cardLevels(uint256, uint256) external view returns (CardLevel memory);
  function tokenVars(uint256) external view returns (TokenVars memory);
}

contract NFTStakingPoolFunctions is AccessControl {

  using SafeERC20 for IERC20;

  INFTStakingPool public nftStakingPool;

  uint256 constant public RAINI_REWARD_DECIMALS = 1000000000;
  uint256 constant public STAMINA_DECIMALS = 1000;

  event StateUpdated(
    uint256 level,     
    uint24 id,
    uint32 timeStamp,
    uint56 rainiRewardPerTokenStored,
    uint32 totalSupply,
    uint56 rainiRewardRate 
  );

  constructor(address _stakingPoolAddress) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    nftStakingPool = INFTStakingPool(_stakingPoolAddress);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NFTSP: caller is not an owner");
    _;
  }

  function initLevels(uint8[] memory levels) external onlyOwner {
    uint256 _staminaEventCount = nftStakingPool.staminaEventCount();

    for (uint256 i; i < levels.length; i++) {
      _staminaEventCount++;

      nftStakingPool.setStaminaEvent(uint24(_staminaEventCount), INFTStakingPool.StaminaEvent({
        id: uint24(_staminaEventCount),
        next: 0,
        nftId: 0,
        timeStamp: uint32(block.timestamp),
        rainiRewardPerTokenStored: 1,
        totalSupply: 0,
        rainiRewardRate: 0,
        level: levels[i]
      }));
    }
    nftStakingPool.setStaminaEventCount(_staminaEventCount);
  }

  function calculateRewardPerToken(uint32 duration, uint56 rainiRewardRate, uint32 _totalSupply) private pure returns (uint56 rewardPerToken) {
    if (_totalSupply == 0) {
      return 0;
    }
    return uint56((uint256(duration) * rainiRewardRate) / _totalSupply);
  }

  function getRewardPerToken(uint24 _eventId, uint24 _fromEvent) public view returns (INFTStakingPool.StaminaEvent memory se) {

    uint24 _currentId = _fromEvent;
    INFTStakingPool.StaminaEvent memory _se = nftStakingPool.staminaEvents(_currentId);

    uint32 _totalSupply;
    uint56 rainiRewardPerTokenStored;
    uint32 lastTime = _se.timeStamp;
    uint56 rainiRewardRate;
    uint32 rewardPeriodFinish = nftStakingPool.generalRewardVars(_se.level).periodFinish;
    uint256 _finalTimeApplicable = _se.timeStamp < rewardPeriodFinish ? Math.min(block.timestamp, rewardPeriodFinish) : block.timestamp;

    require (_se.rainiRewardPerTokenStored > 0, 'invalid start 1');

    while (true) {

      if (_se.rainiRewardPerTokenStored > 0) {
        rainiRewardPerTokenStored = _se.rainiRewardPerTokenStored;
        _totalSupply = _se.totalSupply;
        rainiRewardRate = _se.rainiRewardRate;
      }

      INFTStakingPool.StaminaEvent memory _seNext = nftStakingPool.staminaEvents(_se.next);

      if (_eventId != _currentId && (_se.next == 0 || _seNext.timeStamp > _finalTimeApplicable)) {
        require(_eventId == 0 && _se.timeStamp <= _finalTimeApplicable, 'invalid start 2');
        _currentId = 0;
        _se.timeStamp = uint32(_finalTimeApplicable);
        // As this event now acts as the start of the new reward period, set
        //_se.timeStampDelta = uint32(_finalTimeApplicable - _se.timeStamp);
      }
      
      if (_eventId == _currentId || _se.timeStamp >= _finalTimeApplicable) {
        if (_eventId == 0) {
          if (_se.timeStamp != lastTime) {
            rainiRewardPerTokenStored += calculateRewardPerToken(_se.timeStamp - lastTime, rainiRewardRate, _totalSupply);
          }
          _se.totalSupply = _totalSupply;
          if (_se.timeStamp >= rewardPeriodFinish) {
            _se.rainiRewardRate = 0;
          } else {
            _se.rainiRewardRate = rainiRewardRate;
          }
        }
        _se.rainiRewardPerTokenStored = rainiRewardPerTokenStored;
        return _se;
      }

      _currentId = _se.next;

      _se = _seNext;
      if (_se.timeStamp > lastTime) {
        rainiRewardPerTokenStored += calculateRewardPerToken(_se.timeStamp - lastTime, rainiRewardRate, _totalSupply);
        lastTime = _se.timeStamp;
      }

      _totalSupply -= nftStakingPool.rainiNfts(_se.nftId).maxStamina;
    }
  }


  function balanceUpdate(address _owner, uint24[] memory _eventIds, uint32[] memory nftOrder, int256 _dataUpdate, uint256 _level) internal {
     
      INFTStakingPool.AccountVars memory _accountVars = nftStakingPool.accountVars(_owner);
      INFTStakingPool.AccountRewardVars memory _rewardVars = nftStakingPool.accountRewardVars(_owner, _level);

      uint256 lastDate = _rewardVars.lastUpdated;

      uint24[] memory _stakedNFTs = nftStakingPool.getStakedNfts(_owner, _level);

      uint256 nftArrayLength = _stakedNFTs.length;

      require(nftOrder.length == nftArrayLength, 'order length bad');

      bool[] memory checked = new bool[](nftArrayLength);

      // loops then nftOrder, then one extra loop to determine the final values
      for (uint256 n = 0; n <= nftOrder.length; n++) {
        INFTStakingPool.RainiNft memory nft;
        INFTStakingPool.StaminaEvent memory _nftEvent;

        if (n < nftOrder.length) {
          nft = nftStakingPool.rainiNfts(_stakedNFTs[nftOrder[n]]);
          _nftEvent = nftStakingPool.staminaEvents(nft.staminaEventId);
          checked[nftOrder[n]] = true;
        } else {
          nft = INFTStakingPool.RainiNft(0,0,0,0,0,0,0,0,false,false);
          _nftEvent = INFTStakingPool.StaminaEvent(0,0,0,uint32(block.timestamp),0,0,0,0);
        }
        
        require(_nftEvent.timeStamp <= _rewardVars.lastUpdated || lastDate <= _nftEvent.timeStamp, 'invalid order');


        if (n == nftOrder.length || (_nftEvent.timeStamp > _rewardVars.lastUpdated && _nftEvent.timeStamp <= block.timestamp)) {
          INFTStakingPool.StaminaEvent memory _se;

          if (n == nftOrder.length || _nftEvent.timeStamp != lastDate) {
            _se = getRewardPerToken(nft.staminaEventId, _eventIds[n]);
            _accountVars.rainiRewards += uint104((uint256(_rewardVars.staked) * (_se.rainiRewardPerTokenStored - _rewardVars.rainiRewardPerTokenPaid)));
            _rewardVars.rainiRewardPerTokenPaid = _se.rainiRewardPerTokenStored;
            _accountVars.pointsBalance += calculateReward(_rewardVars.staked, _nftEvent.timeStamp - lastDate);
          }

          if (n == nftOrder.length) {
            if (_owner == address(0)) {
              _se.rainiRewardRate = uint56(uint(_dataUpdate));
            } else {
              //update the total supply depending on whether the user is staking or withdrawing
              require(int(uint256(_se.totalSupply)) + _dataUpdate >= 0, 'totalSupply err');
              _se.totalSupply = uint32(uint(int(uint256(_se.totalSupply)) + _dataUpdate));
              //_se.supplyDelta = int16(_dataUpdate);

              require(int(uint256(_rewardVars.staked)) + _dataUpdate >= 0, 'staked err');
              _rewardVars.staked = uint32(uint(int(uint256(_rewardVars.staked)) + _dataUpdate));
              _rewardVars.lastUpdated = uint32(block.timestamp);
            }
            // update the values of the most recent stamina event
            _se.nftId = 0;
            nftStakingPool.insertStaminaEvent(_se.id, _se, _se.level);
            emit StateUpdated({
              level:  _se.level,     
              id: uint24(nftStakingPool.staminaEventCount()),
              timeStamp: _se.timeStamp,
              rainiRewardPerTokenStored: _se.rainiRewardPerTokenStored,
              totalSupply: _se.totalSupply,
              rainiRewardRate: _se.rainiRewardRate
            });

            //staminaEvents[rainiNfts[_se.nftId].staminaEventId] = _se;
          } else {
            _rewardVars.staked -= nft.maxStamina;
          }
          lastDate = _nftEvent.timeStamp;
        }
      }

      for (uint256 i; i < checked.length; i++) {
        require(checked[i], 'nft missing');
      }

      if (_owner != address(0)) {
        nftStakingPool.setAccountVars(_owner, _accountVars);
        nftStakingPool.setAccountRewardVars(_owner, _level, _rewardVars);
      }
  }

  struct StakeVars {
    uint256 rainiNftCount;
    uint256 contractId;
    uint256 stamina;
    uint256 nftId;
    uint256[] supplyAdded;
  }

  function stake(uint32[] memory _tokenId, address[] memory _contractAddress, uint24[] memory _staminaEventId, uint24[][] memory _eventIds, uint32[][] memory _nftOrder)
    external {


      StakeVars memory _locals = StakeVars({
        rainiNftCount: nftStakingPool.rainiNftCount(),
        contractId: 0,
        stamina: 0,
        nftId: 0,
        supplyAdded: new uint256[](_eventIds.length)
      });


      for (uint256 i = 0; i < _tokenId.length; i++) {
        uint256 _contractId = nftStakingPool.approvedTokenContracts(_contractAddress[i]);
        require(_contractId != 0, "NFTSP: invalid token contract");
        IRainiNft1155 tokenContract = IRainiNft1155(_contractAddress[i]);

        IRainiNft1155.TokenVars memory _tv = tokenContract.tokenVars(_tokenId[i]);

        require(_tv.cardId != 0, "Invalid token");
        
        IRainiNft1155.CardLevel memory _cl = tokenContract.cardLevels(_tv.cardId, _tv.level);

        require(_cl.tokenId == 0, "Invalid token");
        require(_cl.maxStamina > 0, "Invalid token");

        tokenContract.safeTransferFrom(_msgSender(), address(nftStakingPool), _tokenId[i], 1, bytes('0x0'));

        _locals.nftId = nftStakingPool.rainiNftIdMap(_contractAddress[i], _tokenId[i]);
        
        if (_locals.nftId == 0) {
          _locals.stamina = _cl.maxStamina * STAMINA_DECIMALS;
          _locals.rainiNftCount++;
          nftStakingPool.setRainiNft(uint24(_locals.rainiNftCount), INFTStakingPool.RainiNft({
            id: uint24(_locals.rainiNftCount),
            lastStamina: uint32(_locals.stamina),
            maxStamina: _cl.maxStamina,
            level: _tv.level,
            lastUpdated: uint32(block.timestamp),
            staminaEventId: uint24(nftStakingPool.staminaEventCount() + 1),
            tokenId: _tokenId[i],
            contractId: uint16(_contractId),
            isInitialised: true,
            isStaked: true
          }));
          _locals.nftId = _locals.rainiNftCount;
          nftStakingPool.setRainiNftIdMap(_contractAddress[i], _tokenId[i], _locals.nftId);
        } else {
          INFTStakingPool.RainiNft memory _nft = nftStakingPool.rainiNfts(_locals.nftId);
          _locals.stamina = _nft.lastStamina;
          _nft.isStaked = true;
          _nft.lastUpdated = uint32(block.timestamp);
          _nft.staminaEventId = _locals.stamina > 1 ? uint24(nftStakingPool.staminaEventCount() + 1) : 0;
          nftStakingPool.setRainiNft(uint24(_locals.nftId), _nft);
        }

        if (_locals.stamina > 1) {

          uint256 endTime = block.timestamp + (_locals.stamina * nftStakingPool.staminaDuration()) / _cl.maxStamina / STAMINA_DECIMALS;

          INFTStakingPool.StaminaEvent memory _se = INFTStakingPool.StaminaEvent({
            id: 0,
            next: 0,
            nftId: uint24(_locals.nftId),
            timeStamp: uint32(endTime),
            rainiRewardPerTokenStored: 0,
            totalSupply: 0,
            rainiRewardRate: 0,
            level: uint8(_tv.level)
          });

          nftStakingPool.insertStaminaEvent(_staminaEventId[i], _se, _tv.level);

          _locals.supplyAdded[_tv.level] += _cl.maxStamina;
        }

        nftStakingPool.addStakedNft(_msgSender(), _tv.level, uint24(_locals.nftId));
      }

      nftStakingPool.setRainiNftCount(_locals.rainiNftCount);

      for (uint256 i = 0; i < _eventIds.length; i++) {
        require(_locals.supplyAdded[i] <  2 ** 15, 'staking too much');
        if (_locals.supplyAdded[i] > 0) {
          //make sure a balance update is set for the level
          require(_eventIds.length >= i && _eventIds[i].length > 0, "Invalid fields");
          balanceUpdate(_msgSender(), _eventIds[i], _nftOrder[i], int(_locals.supplyAdded[i]), i);
        }
      }

  }
  
  function withdrawTokens(uint256[] memory _tokenId, address[] memory _contractAddress, uint24[] memory _prevEventId, uint24[][] memory _eventIds, uint32[][] memory _nftOrder)
    external {

    uint256[] memory supplyRemoved = new uint256[](_eventIds.length);
    bool[] memory willRunBalanceUpdate = new bool[](_eventIds.length);
    INFTStakingPool.RainiNft[] memory _nfts = new INFTStakingPool.RainiNft[](_tokenId.length);

    for (uint256 i = 0; i < _tokenId.length; i++) {
      uint256 _nftId = nftStakingPool.rainiNftIdMap(_contractAddress[i], _tokenId[i]);
      _nfts[i] = nftStakingPool.rainiNfts(_nftId);

      require(_eventIds.length >= _nfts[i].level + 1 && _eventIds[_nfts[i].level].length > 0, "Invalid fields");

      if (!willRunBalanceUpdate[_nfts[i].level]) {
        willRunBalanceUpdate[_nfts[i].level] = true;
      }
      if (nftStakingPool.staminaEvents(_nfts[i].staminaEventId).timeStamp > block.timestamp) {
        supplyRemoved[_nfts[i].level] += _nfts[i].maxStamina;
      }
    }

    for (uint256 i = 0; i < _eventIds.length; i++) {
      if (willRunBalanceUpdate[i]) {
        require(supplyRemoved[i] <  2 ** 15, 'removing too much');
        //make sure a balance update is set for the level
        require(_eventIds.length >= i && _eventIds[i].length > 0, "Invalid fields");
        balanceUpdate(_msgSender(), _eventIds[i], _nftOrder[i], -int(supplyRemoved[i]), i);
      }
    }

    for (uint256 i = 0; i < _tokenId.length; i++) {

      bool ownsNFT = nftStakingPool.removeStakedNft(_msgSender(), _nfts[i].level, _nfts[i].id);
      require(ownsNFT == true, "NFTSP: Not the owner");
      
      nftStakingPool.removeStaminaEvent(_nfts[i].staminaEventId, _prevEventId[i]);

      _nfts[i].lastStamina = nftStakingPool.getTokenStaminaTotal(_tokenId[i], _contractAddress[i]);
      _nfts[i].isStaked = false;
      _nfts[i].lastUpdated = uint32(block.timestamp);
      _nfts[i].staminaEventId = 0;

      nftStakingPool.withdrawNft(_contractAddress[i], _tokenId[i], _msgSender());

      nftStakingPool.setRainiNft(_nfts[i].id, _nfts[i]);
    }
  }
    
  function calculateReward(uint256 _amount, uint256 _duration) 
    private view returns(uint128) {
      return uint128(_duration * nftStakingPool.rewardRate() * _amount);
  }

  // RAINI rewards

  function addRainiRewardPool(uint256 _amount, uint256 _duration, uint32 _level, uint24[] memory _eventIds)
    external onlyOwner {

      INFTStakingPool.GeneralRewardVars memory _generalRewardVars = nftStakingPool.generalRewardVars(_level);

      if (_generalRewardVars.periodFinish > block.timestamp) {
        uint256 timeRemaining = _generalRewardVars.periodFinish - block.timestamp;
        _amount += timeRemaining * _generalRewardVars.rainiRewardRate;
      }

      nftStakingPool.rainiToken().safeTransferFrom(_msgSender(), address(nftStakingPool), _amount);
      _generalRewardVars.rainiRewardRate = uint56(_amount / _duration / RAINI_REWARD_DECIMALS);
      _generalRewardVars.periodFinish = uint32(block.timestamp + _duration);
      nftStakingPool.setGeneralRewardVars(_level, _generalRewardVars);

      balanceUpdate(address(0), _eventIds, new uint32[](0), int(uint256(_generalRewardVars.rainiRewardRate)), _level);
  }

  function abortRainiRewardPool(uint32 _level, uint24[] memory _eventIds) external onlyOwner {

      INFTStakingPool.GeneralRewardVars memory _generalRewardVars = nftStakingPool.generalRewardVars(_level);

      require (_generalRewardVars.periodFinish > block.timestamp, "Reward pool is not active");
      
      uint256 timeRemaining = _generalRewardVars.periodFinish - block.timestamp;
      uint256 remainingAmount = timeRemaining * _generalRewardVars.rainiRewardRate;
      nftStakingPool.transferRaini(_msgSender(), remainingAmount);

      _generalRewardVars.rainiRewardRate = 0;
      _generalRewardVars.periodFinish = uint32(block.timestamp);
      nftStakingPool.setGeneralRewardVars(_level, _generalRewardVars);

      balanceUpdate(address(0), _eventIds, new uint32[](0), 0, _level);
  }

  function updateBalance(uint24[] memory _eventIds, uint32[] memory _nftOrder, uint256 _level) external {
    balanceUpdate(_msgSender(), _eventIds, _nftOrder, 0, _level);
  }

  function withdrawReward(uint24[][] memory _eventIds, uint32[][] memory _nftOrder) external {

    for (uint256 i = 0; i < _eventIds.length; i++) {
      if (_eventIds[i].length > 0) {
        balanceUpdate(_msgSender(), _eventIds[i], _nftOrder[i], 0, i);
      }
    }

    INFTStakingPool.AccountVars memory _accountVars = nftStakingPool.accountVars(_msgSender());

    require(_accountVars.rainiRewards > 0, "no reward to withdraw");
    nftStakingPool.transferRaini(_msgSender(), _accountVars.rainiRewards * RAINI_REWARD_DECIMALS);
    _accountVars.rainiRewards = 0;
    nftStakingPool.setAccountVars(_msgSender(), _accountVars);
  }
  
  function getRewardBalance(address _owner, uint24[] memory _eventIds, uint32[] memory nftOrder, uint256 _level) external view returns (INFTStakingPool.AccountVars memory rewards) {
     
      INFTStakingPool.AccountVars memory _accountVars = nftStakingPool.accountVars(_owner);
      INFTStakingPool.AccountRewardVars memory _rewardVars = nftStakingPool.accountRewardVars(_owner, _level);

      uint256 lastDate = _rewardVars.lastUpdated;

      uint24[] memory _stakedNFTs = nftStakingPool.getStakedNfts(_owner, _level);

      uint256 nftArrayLength = _stakedNFTs.length;

      require(nftOrder.length == nftArrayLength, 'order length bad');

      bool[] memory checked = new bool[](nftArrayLength);

      // loops then nftOrder, then one extra loop to determine the final values
      for (uint256 n = 0; n <= nftOrder.length; n++) {
        INFTStakingPool.RainiNft memory nft;
        INFTStakingPool.StaminaEvent memory _nftEvent;

        if (n < nftOrder.length) {
          nft = nftStakingPool.rainiNfts(_stakedNFTs[nftOrder[n]]);
          _nftEvent = nftStakingPool.staminaEvents(nft.staminaEventId);
          checked[nftOrder[n]] = true;
        } else {
          nft = INFTStakingPool.RainiNft(0,0,0,0,0,0,0,0,false,false);
          _nftEvent = INFTStakingPool.StaminaEvent(0,0,0,uint32(block.timestamp),0,0,0,0);
        }
        
        require(_nftEvent.timeStamp <= _rewardVars.lastUpdated || lastDate <= _nftEvent.timeStamp, 'invalid order');


        if (n == nftOrder.length || (_nftEvent.timeStamp > _rewardVars.lastUpdated && _nftEvent.timeStamp <= block.timestamp)) {
          INFTStakingPool.StaminaEvent memory _se;

          if (n == nftOrder.length || _nftEvent.timeStamp != lastDate) {
            _se = getRewardPerToken(nft.staminaEventId, _eventIds[n]);
            _accountVars.rainiRewards += uint104((uint256(_rewardVars.staked) * (_se.rainiRewardPerTokenStored - _rewardVars.rainiRewardPerTokenPaid)));
            _rewardVars.rainiRewardPerTokenPaid = _se.rainiRewardPerTokenStored;
            _accountVars.pointsBalance += calculateReward(_rewardVars.staked, _nftEvent.timeStamp - lastDate);
          }

          if (n != nftOrder.length) {
            _rewardVars.staked -= nft.maxStamina;
          }
          lastDate = _nftEvent.timeStamp;
        }
      }

      for (uint256 i; i < checked.length; i++) {
        require(checked[i], 'nft missing');
      }

      return _accountVars;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTStakingPool {
  
  struct GeneralRewardVars {
    uint32 periodFinish;
    uint56 rainiRewardRate;
  }

  struct AccountRewardVars {
    uint32 lastUpdated;
    uint64 rainiRewardPerTokenPaid;
    uint128 staked;
  }

  struct AccountVars {
    uint128 pointsBalance;
    uint128 rainiRewards;
  }

  struct StaminaEvent {
    uint24 id;
    uint24 next;
    uint24 nftId;
    uint32 timeStamp;
    uint56 rainiRewardPerTokenStored;
    uint32 totalSupply;
    uint56 rainiRewardRate; 
    uint8 level;
  }

  struct RainiNft {
    uint24 id;
    uint32 lastStamina;
    uint32 maxStamina;
    uint32 level;
    uint32 lastUpdated;
    uint24 staminaEventId;
    uint32 tokenId;
    uint16 contractId;
    bool isInitialised;
    bool isStaked;
  }


  //Getters

  function generalRewardVars(uint256 _level) external view returns (GeneralRewardVars memory);

  function accountRewardVars(address _account, uint256 _level) external view returns (AccountRewardVars memory);

  function accountVars(address _account) external view returns (AccountVars memory);

  function staminaEvents(uint24 _id) external view returns (StaminaEvent memory);

  function staminaEventCount() external view returns (uint256);

  function rainiNfts(uint256 _id) external view returns (RainiNft memory);

  function stakedNFTs(address _account, uint256 _level) external view returns (uint24[] memory);

  function rainiNftCount() external view returns (uint256);

  function rainiNftIdMap(address _contract, uint256 _tokenId) external view returns (uint256);

  function rewardRate() external view returns (uint256);

  function staminaDuration() external view returns (uint256);

  function approvedTokenContracts(address _contractAddress) external view returns (uint256);

  function rainiToken() external view returns (IERC20);

  function getStakedNfts(address _account, uint256 _level) external view returns (uint24[] memory _stakedNfts);

  //Setters

  function setGeneralRewardVars(uint256 _level, GeneralRewardVars memory _generalRewardVars)  external;

  function setAccountRewardVars(address _account, uint256 _level, AccountRewardVars memory _accountRewardVars) external;

  function setAccountVars(address _account, AccountVars memory _accountVars) external;

  function setStaminaEvent(uint24 _id, StaminaEvent memory _staminaEvent) external;

  function setStaminaEventCount(uint256 _staminaEventCount) external;

  function setRainiNft(uint24 _id, RainiNft memory _rainiNft) external;

  function setRainiNftCount(uint256 _rainiNftCount) external;

  function setRainiNftIdMap(address _contract, uint256 _tokenId, uint256 _nftId) external;

  function setReward(uint256 _rewardRate) external;

  function setStaminaDuration(uint256 _staminaDuration) external;


  // Functions

  function addStakedNft(address _account, uint256 _level, uint24 _nftId) external;

  function removeStakedNft(address _account, uint256 _level, uint24 _nftId) external returns (bool);

  function withdrawNft(address _contractAddress, uint256 _tokenId, address _owner) external;

  function insertStaminaEvent(uint24 _currentId, StaminaEvent memory _newEvent, uint256 _level) external;

  function initNft(address _nftContractAddress, uint256 _tokenId, uint32 _stamina, bool _isStaked, uint24 _staminaEventId) external returns (uint32 maxStamina);

  function removeStaminaEvent(uint24 _removeId, uint24 _prevId) external returns (bool wasRemoved);

  function getTokenStaminaTotal (uint256 _tokenId, address _nftContractAddress) external view returns (uint32);

  function transferRaini(address _recipient, uint256 _amount) external;


  // Unicorn/Rainbow endpoints

  function getStaked(address _owner, uint256 _level) 
    external view returns(uint256);

  // only returns the calculated balance - balanceUpdate required to calculate newer balance
  function balanceOf(address _owner)
    external view returns(uint256);

  
  function mint(address[] calldata _addresses, uint256[] calldata _points) 
    external;
  
  function burn(address _owner, uint256 _amount) 
    external;

  // emergency raini recovery if there are issues
  function recoverRaini(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}