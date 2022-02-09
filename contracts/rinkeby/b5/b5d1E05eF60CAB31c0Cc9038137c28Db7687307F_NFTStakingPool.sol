// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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

contract NFTStakingPool is AccessControl, ERC1155Holder {

  using SafeERC20 for IERC20;

  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
 
  // Fixed / admin assigned values:

  uint256 public rewardRate;
  IERC20 public rainiToken;

  uint256 public staminaDuration;

  uint256 constant public STAMINA_DECIMALS = 1000;


  // Universal variables

  struct GeneralRewardVars {
    uint32 periodFinish;
    uint56 rainiRewardRate;
  }

  // level => vars
  mapping(uint256 => GeneralRewardVars) public generalRewardVars;

  // account specific variables

  struct AccountRewardVars {
    uint32 lastUpdated;
    uint64 rainiRewardPerTokenPaid;
    uint128 staked;
  }

  struct AccountVars {
    uint128 pointsBalance;
    uint128 rainiRewards;
  }


  // account => level =>
  mapping(address => mapping(uint256 => AccountRewardVars)) public accountRewardVars;
  mapping(address => AccountVars) public accountVars;
  mapping(address => mapping(uint256 => uint24[])) public stakedNFTs;

  mapping(address => uint256) public approvedTokenContracts;

  // Stamina Events track when stamina of staked NFTs expire using a single linked list
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

  uint256 public staminaEventCount;
  // Mapping 
  mapping (uint24 => StaminaEvent) public staminaEvents;



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

  uint256 public rainiNftCount;
  mapping(uint256 => RainiNft) public rainiNfts;

  // contract => tokenId => nftId
  mapping(address => mapping(uint256 => uint256)) public rainiNftIdMap;

  constructor(address _rainiToken) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    rainiToken = IERC20(_rainiToken);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NFTSP: caller is not an owner");
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, _msgSender()), "NFTSP: caller is not a burner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "NFTSP: caller is not a minter");
    _;
  }

  modifier onlyEditor() {
    require(hasRole(EDITOR_ROLE, _msgSender()), "NFTSP: caller is not a editor");
    _;
  }


  function addTokenContract(address _tokenContract, uint256 _contractId) 
    external onlyOwner {
      approvedTokenContracts[_tokenContract] = _contractId;
  }

  function removeTokenContract(address _tokenContract) 
    external onlyOwner {
      delete approvedTokenContracts[_tokenContract];
  }



  
  //Setters

  function setGeneralRewardVars(uint256 _level, GeneralRewardVars memory _generalRewardVars) 
    external onlyEditor {
      generalRewardVars[_level] = _generalRewardVars;
  }

  function setAccountRewardVars(address _account, uint256 _level, AccountRewardVars memory _accountRewardVars) 
    external onlyEditor {
      accountRewardVars[_account][_level] = _accountRewardVars;
  }

  function setAccountVars(address _account, AccountVars memory _accountVars) 
    external onlyEditor {
      accountVars[_account] = _accountVars;
  }

  function setStaminaEvent(uint24 _id, StaminaEvent memory _staminaEvent)
    external onlyEditor {
      staminaEvents[_id] = _staminaEvent;
  }

  function setStaminaEventCount(uint256 _staminaEventCount)
    external onlyEditor {
      staminaEventCount = _staminaEventCount;
    }

  function setRainiNft(uint24 _id, RainiNft memory _rainiNft)
    external onlyEditor {
      rainiNfts[_id] = _rainiNft;
  }

  function setStakedNft(address _account, uint256 _level, uint32 _index, uint24 _nftId)
    external onlyEditor {
      stakedNFTs[_account][_level][_index] = _nftId;
  }

  function setRainiNftCount(uint256 _rainiNftCount)
    external onlyEditor {
      rainiNftCount = _rainiNftCount;
    }

  function setRainiNftIdMap(address _contract, uint256 _tokenId, uint256 _nftId) 
    external onlyEditor {
      rainiNftIdMap[_contract][_tokenId] = _nftId;
  }


  function setReward(uint256 _rewardRate)
    external onlyOwner {
      rewardRate = _rewardRate;
  }

  function setStaminaDuration(uint256 _staminaDuration)
    external onlyOwner {
      staminaDuration = _staminaDuration;
  }

  // only returns the calculated balance - balanceUpdate required to calculate newer balance
  function balanceOf(address _owner)
    public view returns(uint256) {
      return accountVars[_owner].pointsBalance;
  }


  function addStakedNft(address _account, uint256 _level, uint24 _nftId)
    external onlyEditor {
      uint24[] memory nfts = stakedNFTs[_account][_level];
      bool wasAdded = false;
      for (uint j = 0; j < nfts.length; j++) {
        if (nfts[j] == 0) {
          stakedNFTs[_account][_level][j] = _nftId;
          wasAdded = true;
          break;
        }
      }
      if (!wasAdded) {
        stakedNFTs[_account][_level].push(_nftId);
      }
  }

  function removeStakedNft(address _account, uint256 _level, uint24 _nftId)
    external onlyEditor returns (bool _wasRemoved) {
      uint24[] memory nfts = stakedNFTs[_account][_level];
      for (uint j = 0; j < nfts.length; j++) {
        if (nfts[j] == _nftId) {
          delete stakedNFTs[_account][_level][j];
          return true;
        }
      }
      return false;
  }

  function withdrawNft(address _contractAddress, uint256 _tokenId, address _owner)
    external onlyEditor {
      IRainiNft1155(_contractAddress).safeTransferFrom(address(this), _owner, _tokenId, 1, '0x');
  }

  function insertStaminaEvent(uint24 _currentId, StaminaEvent memory _newEvent, uint256 _level) external onlyEditor {
    uint32 lastTime = 0;
    uint24 lastId = 0;

    while (true) {
      StaminaEvent memory _se = staminaEvents[_currentId];
      require(_currentId == 0 || _se.level == _level, 'wrong level');

      if (_currentId == 0 || _se.timeStamp > _newEvent.timeStamp) {
        require(lastTime != 0, 'starting event in future');
        _newEvent.next = _currentId;
        staminaEventCount++;
        uint24 newId = uint24(staminaEventCount);
        _newEvent.id = newId;
        staminaEvents[newId] = _newEvent;
        staminaEvents[lastId].next = newId;
        return;
      } else {
        lastTime = _se.timeStamp;
        lastId = _currentId;
        _currentId = _se.next;
      }
    }
  }

  function _initNft(address _nftContractAddress, uint256 _tokenId, uint32 _stamina, bool _isStaked, uint24 _staminaEventId) internal returns (uint32 maxStamina) {
    IRainiNft1155 tokenContract = IRainiNft1155(_nftContractAddress);
    uint256 _contractId = approvedTokenContracts[_nftContractAddress];

    IRainiNft1155.TokenVars memory _tv = tokenContract.tokenVars(_tokenId);

    require(_tv.cardId != 0, "Invalid token");
    
    IRainiNft1155.CardLevel memory _cl = tokenContract.cardLevels(_tv.cardId, _tv.level);

    require(_cl.tokenId == 0, "Invalid token");

    rainiNftCount++;

    rainiNfts[rainiNftCount] = RainiNft({
      id: uint24(rainiNftCount),
      lastStamina: _stamina == 0 ? uint32(_cl.maxStamina * STAMINA_DECIMALS) : _stamina,
      maxStamina: _cl.maxStamina,
      level: _tv.level,
      lastUpdated: uint32(block.timestamp),
      staminaEventId: _stamina != 1 ? _staminaEventId : 0,
      tokenId: uint32(_tokenId),
      contractId: uint16(_contractId),
      isInitialised: true,
      isStaked: _isStaked
    });

    rainiNftIdMap[_nftContractAddress][_tokenId] = rainiNftCount;

    return _cl.maxStamina;
  }

  function initNft(address _nftContractAddress, uint256 _tokenId, uint32 _stamina, bool _isStaked, uint24 _staminaEventId) public onlyEditor returns (uint32 maxStamina) {
    return _initNft(_nftContractAddress, _tokenId, _stamina, _isStaked, _staminaEventId);
  }

  function removeStaminaEvent(uint24 _removeId, uint24 _prevId) external onlyEditor returns (bool wasRemoved) {
    if (staminaEvents[_removeId].timeStamp > block.timestamp) {
      while (true) {
        uint24 _next = staminaEvents[_prevId].next;
        require(staminaEvents[_prevId].next != 0, 'bad prevId');
        if (_next == _removeId) {
          staminaEvents[_prevId].next = staminaEvents[_removeId].next;
          delete staminaEvents[_removeId];
          return true;
        } else {
          _prevId = _next;
        }
      }
    }
    return false;
  }
  
  function mint(address[] calldata _addresses, uint256[] calldata _points) 
    external onlyMinter {
      for (uint256 i = 0; i < _addresses.length; i++) {
        accountVars[_addresses[i]].pointsBalance = uint128(accountVars[_addresses[i]].pointsBalance + _points[i]);
      }
  }
  
  function burn(address _owner, uint256 _amount) 
    external onlyBurner {
      accountVars[_owner].pointsBalance = uint128(accountVars[_owner].pointsBalance - _amount);
  }
  
  function getTokenStaminaTotal(uint256 _tokenId, address _nftContractAddress) public view returns (uint32 stamina) {
    uint256 nftId = rainiNftIdMap[_nftContractAddress][_tokenId];
    RainiNft memory _rainiNft = rainiNfts[nftId];

    if (_rainiNft.isStaked) {
      uint256 degraded = (_rainiNft.maxStamina * STAMINA_DECIMALS * (block.timestamp - _rainiNft.lastUpdated)) / staminaDuration;
      if (degraded >= _rainiNft.lastStamina) {
        return 1;
      } else {
        return uint32(_rainiNft.lastStamina - degraded);
      }
    } else {
      return _rainiNft.lastStamina;
    }
  }

  function getTokenStamina(uint256 _tokenId, address _nftContractAddress) external view returns (uint256 _stamina) {
    uint256 stamina = getTokenStaminaTotal(_tokenId, _nftContractAddress);
    if (stamina == 0) {
      IRainiNft1155 tokenContract = IRainiNft1155(_nftContractAddress);
      IRainiNft1155.TokenVars memory _tv = tokenContract.tokenVars(_tokenId);
      IRainiNft1155.CardLevel memory _cl = tokenContract.cardLevels(_tv.cardId, _tv.level);
      return _cl.maxStamina;
    }
    return stamina / STAMINA_DECIMALS;
  }

  function getStakedNfts(address _account, uint256 _level) public view returns (uint24[] memory _stakedNfts) {
    return stakedNFTs[_account][_level];
  }

  function _setTokenStaminaTotal(uint32 _stamina, uint256 _tokenId, address _nftContractAddress) 
    internal {
      
      uint256 nftId = rainiNftIdMap[_nftContractAddress][_tokenId];
      

      if (nftId == 0) {
        _initNft(_nftContractAddress, _tokenId, _stamina, false, 0);
      } else {
        
        RainiNft memory _rainiNft = rainiNfts[nftId];
        _rainiNft.lastStamina = _stamina;
        _rainiNft.lastUpdated = uint32(block.timestamp);

        require(!_rainiNft.isStaked, 'token staked');

        rainiNfts[nftId] = _rainiNft;
      }
  }

  function setTokenStaminaTotal(uint32 _stamina, uint256 _tokenId, address _nftContractAddress) 
    public onlyEditor {
      _setTokenStaminaTotal(_stamina, _tokenId, _nftContractAddress);
  }

  function mergeTokens(uint256 _newTokenId, uint256[] memory _tokenIds, address _nftContractAddress) external onlyEditor {

    IRainiNft1155 tokenContract = IRainiNft1155(_nftContractAddress);
    IRainiNft1155.TokenVars memory _tv;
    require(_tv.cardId != 0, "Invalid token");
    IRainiNft1155.CardLevel memory _cl1;
    IRainiNft1155.CardLevel memory _cl2;
    uint256 _cardId = 0;
    uint256 _stamina = 0;
    uint256 _conversionRateSum = 0;

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _tv = tokenContract.tokenVars(_tokenIds[i]);
      if (_cardId == 0) {
        _cardId = _tv.cardId;
         _cl1 = tokenContract.cardLevels(_cardId, 1);
         _cl2 = tokenContract.cardLevels(_cardId, 2);
      }

      if (_tv.level == 1) {
        uint256 _tokenStamina = getTokenStaminaTotal(_tokenIds[i], _nftContractAddress);
        if (_tokenStamina > 0) {
          _stamina += getTokenStaminaTotal(_tokenIds[i], _nftContractAddress);
          _conversionRateSum += _cl1.conversionRate;
        }
      }
    }
    _stamina = _cl2.maxStamina * (_stamina * _cl1.conversionRate + (_cl2.conversionRate - _conversionRateSum) * _cl1.maxStamina * STAMINA_DECIMALS) / (_cl1.maxStamina * _cl2.conversionRate);
    
    rainiNftCount++;

    rainiNfts[rainiNftCount] = RainiNft({
      id: uint24(rainiNftCount),
      lastStamina: uint32(_stamina),
      maxStamina: _cl2.maxStamina,
      level: 2,
      lastUpdated: uint32(block.timestamp),
      staminaEventId: 0,
      tokenId: uint32(_newTokenId),
      contractId: uint16(approvedTokenContracts[_nftContractAddress]),
      isInitialised: true,
      isStaked: false
    });

    rainiNftIdMap[_nftContractAddress][_newTokenId] = rainiNftCount;
  }

  // emergency raini recovery if there are issues
  function recoverRaini(uint256 _amount) external onlyOwner {
    rainiToken.transfer(_msgSender(), _amount);
  }

  // emergency nft recovery if there are issues
  function recoverNfts(uint256[] memory _tokenId, address[] memory _contractAddress, address[] memory owner) external onlyOwner {
    for (uint256 i; i < _tokenId.length; i++) {
      uint256 _nftId = rainiNftIdMap[_contractAddress[i]][_tokenId[i]];
      RainiNft memory _nft = rainiNfts[_nftId];

      bool ownsNFT = false;
      uint24[] memory nfts = stakedNFTs[owner[i]][_nft.level];
      for (uint j = 0; j < nfts.length; j++) {
        if (nfts[j] == _nftId) {
          ownsNFT = true;
          delete stakedNFTs[owner[i]][_nft.level][j];
          break;
        }
      }
      require(ownsNFT == true, "NFTSP: Not the owner");

      IRainiNft1155(_contractAddress[i]).safeTransferFrom(address(this), owner[i], _tokenId[i], 1, '0x');
    }
  }

  function transferRaini(address _recipient, uint256 _amount) external onlyEditor {
    rainiToken.safeTransfer(_recipient, _amount);
  }

  function supportsInterface(bytes4 interfaceId) 
    public virtual override(AccessControl, ERC1155Receiver) view returns (bool) {
      return interfaceId == this.supportsInterface.selector;
  }

  function findStaminaEventBefore(uint256 _eventId, uint256 _timeStamp, uint256 _start, uint256 _maxSteps, bool _stateSet) 
    public view returns (int256 _beforeId) {
    
    uint256 lastTime = 0;
    uint256 lastId = 0;
    uint256 nextId = _start;
    uint256 lastStateId = 0;

    for (uint256 i = 0; i < _maxSteps; i++) {
      StaminaEvent memory _se = staminaEvents[uint24(nextId)];
        
      if (_stateSet && _se.rainiRewardPerTokenStored > 0) {
        lastStateId = nextId;
      }

      if (nextId == 0 || _eventId == nextId || (_timeStamp > 0 && _se.timeStamp > _timeStamp)) {
        require(lastTime != 0 || _eventId == nextId, 'starting event in future');
        require(!(_eventId > 0 && nextId == 0), 'event not found');
        if (_stateSet) {
          return int(lastStateId);
        } else {
          return int(lastId);
        }
      } else {
        lastTime = _se.timeStamp;
        lastId = nextId;
        nextId = _se.next;
      }
    }

    return -int(lastId);
  }

  function getBalanceUpdateEventIds(address _account, uint256 _level, uint256[] memory _startIds, uint32[] memory nftOrder, uint256 _maxSteps) 
    public view returns (int256[] memory eventIds) {

      AccountRewardVars memory _rewardVars = accountRewardVars[_account][_level];
      uint24[] memory _stakedNFTs = stakedNFTs[_account][_level];
      uint256 lastEventId = 0;
      int256[] memory _eventIds = new int256[](nftOrder.length + 1);

      for (uint256 n = 0; n <= nftOrder.length; n++) {
        
        RainiNft memory nft;
        StaminaEvent memory _nftEvent;

        if (n < nftOrder.length) {
          nft = rainiNfts[_stakedNFTs[nftOrder[n]]];
          _nftEvent = staminaEvents[nft.staminaEventId];
        } else {
          nft = RainiNft(0,0,0,0,0,0,0,0,false,false);
          _nftEvent = StaminaEvent(0,0,0,uint32(block.timestamp),0,0,0,0);
        }

        if (n == nftOrder.length || (_nftEvent.timeStamp > _rewardVars.lastUpdated && _nftEvent.timeStamp <= block.timestamp)) {
          uint256 _startId = Math.max(_startIds[n], lastEventId);
          int eventIdBefore = findStaminaEventBefore(nft.staminaEventId, (n == nftOrder.length) ? block.timestamp : 0, _startId, _maxSteps, true);
          _eventIds[n] = eventIdBefore;
          if (eventIdBefore < 0) {
            return _eventIds;
          }
          lastEventId = uint256(eventIdBefore);
        }
      }
      return _eventIds;
  }

  function getNftEventTimes(address _account, uint256 _level)
      public view returns (uint32[] memory eventTimes) {
        uint24[] memory _stakedNFTs = stakedNFTs[_account][_level];
        uint32[] memory _eventTimes = new uint32[](_stakedNFTs.length);

        for (uint256 n = 0; n < _stakedNFTs.length; n++) {
          RainiNft memory nft = rainiNfts[_stakedNFTs[n]];
          _eventTimes[n] = staminaEvents[nft.staminaEventId].timeStamp;
        }
        return _eventTimes;
  }

  function getStakedNftData(address _account, uint256 _level) public view returns (RainiNft[] memory _nfts) {
    uint24[] memory _stakedNFTs = stakedNFTs[_account][_level];
    RainiNft[] memory _nftData = new RainiNft[](_stakedNFTs.length);
    for (uint256 n = 0; n < _stakedNFTs.length; n++) {
      _nftData[n] = rainiNfts[_stakedNFTs[n]];
    }
    return _nftData;
  }

    function getNftData(uint256[] memory _tokenId, address[] memory _contractAddress) 
    external view returns (RainiNft[] memory _nfts) {
      RainiNft[] memory _nftData = new RainiNft[](_tokenId.length);
      for (uint256 n = 0; n < _tokenId.length; n++) {
        _nftData[n] = rainiNfts[rainiNftIdMap[_contractAddress[n]][_tokenId[n]]];
      }
      return _nftData;
  }
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