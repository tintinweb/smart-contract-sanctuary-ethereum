// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ValidatorAssetManager.sol";

contract ValidatorConditionChecker {
  address public operator;
  address public rootContract;
  address[] public requiredNft;
  ValidatorAssetManager public assetManager;

  struct Condition {
    address requiredNft;
    uint256 requiredNftAmount;
  }

  mapping(uint256 => Condition) private conditionsToSubmit;
  uint256 private conditionsToSubmitIndex;

  modifier onlyRootContract() {
    require(msg.sender == rootContract, "can only call from root contract");
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == rootContract, "only operator");
    _;
  }

  constructor(address _rootContract, address _assetManager) {
    operator = msg.sender;
    rootContract = _rootContract;
    assetManager = ValidatorAssetManager(_assetManager);
  }

  function setConditionToSubmitByNft(address _requiredNft, uint256 _nftRequiredAmount)
    public
    onlyOperator
  {
    Condition memory _condition = Condition({
      requiredNft: _requiredNft,
      requiredNftAmount: _nftRequiredAmount
    });
    conditionsToSubmit[conditionsToSubmitIndex] = _condition;
    conditionsToSubmitIndex = conditionsToSubmitIndex + 1;
  }

  function isValidatorValidForSubmit(address _validatorAddress) public view returns (bool) {
    for (uint256 i = 0; i < conditionsToSubmitIndex; i++) {
      Condition memory _condition = conditionsToSubmit[i];
      if (_condition.requiredNft != address(0)) {
        uint256 amount = assetManager.getNftStakedByHolder(
          _validatorAddress,
          _validatorAddress,
          _condition.requiredNft
        );
        if (_condition.requiredNftAmount > amount) {
          return false;
        }
      }
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/INftRarityDecider.sol";

contract ValidatorAssetManager {
  struct Validator {
    bool staked;
    uint256 nftCount;
    uint256 pod;
    uint256 wealth;
  }

  // INIT
  mapping(address => address) public wealthDecider;
  address public rootContract;
  uint256 public constant POD_WEALTH_RATIO = 1;

  // STATE
  mapping(address => uint256) private validatorWealth;
  mapping(address => mapping(address => uint256)) private holderWealthByValidator;
  uint256 public stakedWealth;

  mapping(bytes32 => uint256) private holderNftStakedAmountByTokenId;
  mapping(bytes32 => uint256) private holderNftStakedAmount;
  mapping(bytes32 => uint256) private holderPodStakedAmount;
  mapping(address => Validator) public validatorStakedInfo;

  modifier onlyRootContract() {
    require(msg.sender == rootContract, "can only call from root contract");
    _;
  }

  constructor(address _rootContract) {
    stakedWealth = 0;
    rootContract = _rootContract;
  }

  // --- GET ---
  function isValidatorStaked(address _validatorAddress) public view returns (bool) {
    return validatorStakedInfo[_validatorAddress].staked;
  }

  function getValidatorWealth(address _validatorAddress) public view returns (uint256) {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    if (!_validator.staked || _validator.pod == 0) {
      return 0;
    }

    return _validator.wealth;
  }

  function getHolderWealth(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    return holderWealthByValidator[_validatorAddress][_holderAddress];
  }

  function isValidNft(address _nftAddress) public view returns (bool) {
    return wealthDecider[_nftAddress] != address(0);
  }

  function wealthCalcNft(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _amount
  ) public view returns (uint256) {
    if (wealthDecider[_nftAddress] == address(0)) {
      return 0;
    }

    return INftRarityDecider(wealthDecider[_nftAddress]).calcRarity(_tokenId) * _amount;
  }

  function wealthCalcPod(uint256 _amount) public pure returns (uint256) {
    return _amount * POD_WEALTH_RATIO;
  }

  function _nftHolderHash(
    address _validatorAddress,
    address _owner,
    address _nft
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_validatorAddress, _owner, _nft));
  }

  function _nftTokenHolderHash(
    address _validatorAddress,
    address _owner,
    address _nft,
    uint256 _tokenId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_validatorAddress, _owner, _nft, _tokenId));
  }

  function _podHolderHash(address _validatorAddress, address _owner)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_validatorAddress, _owner));
  }

  function isOwnedNft(
    address _validatorAddress,
    address _nftAddress,
    address _holderAddress,
    uint256 _tokenId,
    uint256 _amount
  ) public view returns (bool) {
    bytes32 _nftHash = _nftTokenHolderHash(
      _validatorAddress,
      _holderAddress,
      _nftAddress,
      _tokenId
    );
    return holderNftStakedAmountByTokenId[_nftHash] >= _amount;
  }

  function isStakedPodAtLeast(
    address _validatorAddress,
    address _holderAddress,
    uint256 _amount
  ) public view returns (bool) {
    bytes32 _podHash = _podHolderHash(_validatorAddress, _holderAddress);
    return holderPodStakedAmount[_podHash] >= _amount;
  }

  function getNftStakedByHolder(
    address _validatorAddress,
    address _holderAddress,
    address _nftAddress
  ) public view returns (uint256) {
    bytes32 _nftHolder = _nftHolderHash(_validatorAddress, _holderAddress, _nftAddress);
    return holderNftStakedAmount[_nftHolder];
  }

  function getPodStakedByHolder(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    bytes32 _nftHolder = _podHolderHash(_validatorAddress, _holderAddress);
    return holderPodStakedAmount[_nftHolder];
  }

  function isNft721(address _nftAddress) public view returns (bool) {
    return INftRarityDecider(wealthDecider[_nftAddress]).isErc721();
  }

  // --- MUTATION ---
  function setValidatorValidForStake(address _validatorAddress) public onlyRootContract {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    if (_validator.staked) {
      return;
    }

    _validator.staked = true;
    validatorStakedInfo[_validatorAddress] = _validator;

    stakedWealth += _validator.wealth;
  }

  function setStakedWealth(uint256 newWealth) public onlyRootContract {
    stakedWealth = newWealth;
  }

  function updateValidatorWealth(address _validatorAddress, uint256 newWealth)
    public
    onlyRootContract
  {
    validatorWealth[_validatorAddress] = newWealth;
  }

  function updateHolderWealth(
    address _validatorAddress,
    address _holderAddress,
    uint256 newWealth
  ) public onlyRootContract {
    holderWealthByValidator[_validatorAddress][_holderAddress] = newWealth;
  }

  function setWealthDecider(address _nftAddress, address _wealthDecider) public onlyRootContract {
    wealthDecider[_nftAddress] = _wealthDecider;
  }

  function updatePodStakedAmount(
    address _validatorAddress,
    address _holderAddress,
    uint256 _amount,
    bool _isReduce
  ) public onlyRootContract {
    bytes32 _podHash = _podHolderHash(_validatorAddress, _holderAddress);
    if (_isReduce) {
      holderPodStakedAmount[_podHash] -= _amount;
    } else {
      holderPodStakedAmount[_podHash] += _amount;
    }
  }

  function updateHolderNftStakedAmountByTokenId(
    address _validatorAddress,
    address _holderAddress,
    address _nftAddress,
    uint256 _tokenId,
    uint256 _amount,
    bool _isReduce
  ) public onlyRootContract {
    bytes32 _nftTokenIdHolderHash = _nftTokenHolderHash(
      _validatorAddress,
      _holderAddress,
      _nftAddress,
      _tokenId
    );
    bytes32 _nftHolder = _nftHolderHash(_validatorAddress, _holderAddress, _nftAddress);

    if (_isReduce) {
      holderNftStakedAmountByTokenId[_nftTokenIdHolderHash] -= _amount;
      holderNftStakedAmount[_nftHolder] -= _amount;
    } else {
      holderNftStakedAmountByTokenId[_nftTokenIdHolderHash] += _amount;
      holderNftStakedAmount[_nftHolder] += _amount;
    }
  }

  function updateStakedInfo(
    address _validatorAddress,
    address _holderAddress,
    uint256 _wealthChange,
    uint256 _nftStakedChange,
    uint256 _podChange,
    bool _isReduce
  ) public onlyRootContract {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    uint256 wealthBefore = _validator.wealth;
    if (_isReduce) {
      _validator.nftCount = _validator.nftCount - _nftStakedChange;
      _validator.pod = _validator.pod - _podChange;
      _validator.wealth = _validator.wealth - _wealthChange;
      holderWealthByValidator[_validatorAddress][_holderAddress] -= _wealthChange;
    } else {
      _validator.nftCount = _validator.nftCount + _nftStakedChange;
      _validator.pod = _validator.pod + _podChange;
      _validator.wealth = _validator.wealth + _wealthChange;
      holderWealthByValidator[_validatorAddress][_holderAddress] += _wealthChange;
    }

    // update staked wealth
    if (_validator.staked) {
      stakedWealth = stakedWealth - wealthBefore + _validator.wealth;
    }

    validatorStakedInfo[_validatorAddress] = _validator;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INftRarityDecider {
  function calcRarity(uint256 _tokenId) external pure returns (uint256);
  function isErc721() external pure returns (bool);
  function isErc1155() external pure returns (bool);
}