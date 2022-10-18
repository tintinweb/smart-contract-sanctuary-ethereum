// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@chainlink/contracts/src/v0.8/KeeperCompatible.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IFeeReducer.sol';
import './interfaces/IBokkyPooBahsDateTime.sol';
import './IndexHandler.sol';
import './pfYDF.sol';

contract PerpetualFutures is IndexHandler, KeeperCompatibleInterface, Ownable {
  using SafeERC20 for ERC20;

  uint256 constant PERC_DEN = 100000;

  pfYDF perpsNft;
  IFeeReducer feeReducer;
  IBokkyPooBahsDateTime timeLibrary =
    IBokkyPooBahsDateTime(0x23d23d8F243e57d0b924bff3A3191078Af325101);

  bool public tradingEnabled;

  mapping(address => bool) public settlers;
  uint8 maxLiquidationsPerUpkeep = 25;

  address public mainCollateralToken =
    0x30dcBa0405004cF124045793E1933C798Af9E66a;
  mapping(address => bool) _validColl;
  address[] _allCollTokens;
  mapping(address => uint256) _allCollTokensInd;

  uint16 public maxLeverage = 500; // 50x
  uint8 public maxTriggerOrders = 2;
  uint256 public minOpenTimeForProfit = 3 hours;
  uint256 public minPriceDiffForProfit = (PERC_DEN * 15) / 1000; // 1.5%
  uint256 public openFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePerDurationUnit = 1 hours;
  uint256 public closeFeePerDuration = (PERC_DEN * 5) / 100000; // 0.005% / hour

  // collateral token => amount
  mapping(address => uint256) public amtOpenLong;
  mapping(address => uint256) public amtOpenShort;
  mapping(address => uint256) public maxCollateralOpenDiff;

  struct PositionIndexFeed {
    IndexFeed feed;
    uint16 phaseIdStart;
    uint80 roundIdStart;
    uint16 phaseIdSettle;
    uint80 roundIdSettle;
  }

  struct TriggerOrder {
    uint256 idxPriceCurrent;
    uint256 idxPriceTarget;
  }

  struct PositionLifecycle {
    uint256 openTime;
    uint256 openFees;
    uint256 closeTime;
    uint256 closeFees;
    uint256 settleCollPriceUSD; // For positions with alternate collateral, USD per collateral token extended to 18 decimals
    uint256 settleMainPriceUSD; // For positions with alternate collateral, USD per main token extended to 18 decimals
  }

  struct Position {
    PositionIndexFeed[] feeds;
    PositionLifecycle lifecycle;
    address collateralToken;
    uint256 collateralCloseUnsettled;
    uint256 collateralAmount;
    uint256 positionAmount;
    bool isLong;
    uint16 leverage;
    uint256 indexPriceStart;
    uint256 indexPriceSettle;
    uint256 amountWon;
    uint256 amountLost;
    bool isSettled;
  }

  // tokenId => Position
  mapping(uint256 => Position) public positions;
  // tokenId => address
  mapping(uint256 => address) public positionOpeners;
  // tokenId => address
  mapping(uint256 => address) public positionClosers;
  // tokenId => orders
  mapping(uint256 => TriggerOrder[]) public positionTriggerOrders;
  // tokenId[]
  uint256[] public allOpenPositions;
  // tokenId => allOpenPositions index
  mapping(uint256 => uint256) internal _openPositionsIdx;
  // tokenId[]
  uint256[] public allUnsettledPositions;
  // tokenId => allUnsettledPositions index
  mapping(uint256 => uint256) internal _unsettledPositionsIdx;

  event CloseUnsettledPosition(uint256 indexed tokenId);
  event OpenPosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 positionCollateral,
    bool isLong,
    uint256 leverage
  );
  event ClosePosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 indexPriceSettle,
    uint256 amountWon,
    uint256 amountLost
  );
  event LiquidatePosition(uint256 tokenId);
  event ClosePositionFromTriggerOrder(uint256 tokenId);
  event SettlePosition(
    uint256 tokenId,
    uint256 mainTokenSettleAmt,
    uint256 collSettlePrice,
    uint256 mainSettlePrice
  );

  modifier onlyPositionOwner(uint256 _tokenId) {
    require(msg.sender == perpsNft.ownerOf(_tokenId), 'must own position');
    _;
  }

  modifier onlySettler() {
    require(settlers[msg.sender], 'only settlers');
    _;
  }

  constructor(string memory _tokenURI) {
    perpsNft = new pfYDF(_tokenURI);
    perpsNft.transferOwnership(msg.sender);
  }

  function getFeeReducer() external view returns (address) {
    return address(feeReducer);
  }

  function getPerpsNFT() external view returns (address) {
    return address(perpsNft);
  }

  function getAllIndexes() external view returns (Index[] memory) {
    return indexes;
  }

  function getAllValidCollateralTokens()
    external
    view
    returns (address[] memory)
  {
    return _allCollTokens;
  }

  function getAllUnsettledPositions() external view returns (uint256[] memory) {
    return allUnsettledPositions;
  }

  function getAllPositionTriggerOrders(uint256 _tokenId)
    external
    view
    returns (TriggerOrder[] memory)
  {
    return positionTriggerOrders[_tokenId];
  }

  function openPosition(
    address _collToken,
    uint256 _indexInd,
    uint256 _desiredPrice,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%
    uint256 _collateral,
    uint16 _leverage, // 10 == 1x, 1000 == 100x
    bool _isLong,
    uint256 _triggerOrderTargetPrice
  ) external payable {
    require(tradingEnabled, 'DISABLED');
    require(_indexInd < indexes.length, 'INVIDX');
    require(_leverage >= 10 && _leverage <= maxLeverage, 'LEV1');
    require(_canOpenAgainstIndex(_indexInd, 0), 'INDOOB1');
    require(
      _collToken == address(0) ||
        _collToken == mainCollateralToken ||
        _validColl[_collToken],
      'POSTOKEN1'
    );

    uint256 _newTokenId = perpsNft.mint(msg.sender);
    (uint256 _openFee, uint256 _finalCollateral) = _processOpenCollateral(
      msg.sender,
      _collToken,
      _collateral,
      _leverage
    );

    Position storage _newPosition = _createNewPosition(_indexInd, _newTokenId);
    uint256 _openPrice = getIndexPriceFromIndex(_indexInd);
    _validateOpenPriceSlip(_desiredPrice, _openPrice, _slippage, _isLong);

    positionOpeners[_newTokenId] = msg.sender;
    _newPosition.lifecycle.openTime = block.timestamp;
    _newPosition.lifecycle.openFees = _openFee;
    _newPosition.collateralAmount = _finalCollateral;
    _newPosition.positionAmount = (_finalCollateral * _leverage) / 10;
    _newPosition.isLong = _isLong;
    _newPosition.leverage = _leverage;
    _newPosition.indexPriceStart = _openPrice;
    _newPosition.collateralToken = _collToken;

    _addOpenPosition(_newTokenId);
    _validateAndUpdateOpenAmounts(_newTokenId, _newPosition.positionAmount);
    if (_triggerOrderTargetPrice > 0) {
      _addTriggerOrder(_newTokenId, _triggerOrderTargetPrice);
    }

    emit OpenPosition(
      _newTokenId,
      msg.sender,
      _openPrice,
      _finalCollateral,
      _isLong,
      _leverage
    );
  }

  function _processOpenCollateral(
    address _user,
    address _collToken,
    uint256 _collateral,
    uint256 _leverage
  ) internal returns (uint256, uint256) {
    uint256 _openFee;
    uint256 _finalCollateral;

    // native token
    if (_collToken == address(0)) {
      require(msg.value > 0, 'COLL3');
      _collateral = msg.value;
      _openFee = _getPositionOpenFee(_user, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    } else {
      ERC20 _collCont = ERC20(_collToken);
      require(_collCont.balanceOf(_user) >= _collateral, 'BAL1');

      uint256 _before = _collCont.balanceOf(address(this));
      _collCont.safeTransferFrom(_user, address(this), _collateral);
      _collateral = _collCont.balanceOf(address(this)) - _before;
      _openFee = _getPositionOpenFee(_user, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    }
    return (_openFee, _finalCollateral);
  }

  function _validateOpenPriceSlip(
    uint256 _desiredPrice,
    uint256 _currentPrice,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%
    bool _isLong
  ) internal pure {
    uint256 _idxSlipDiff;
    if (_isLong && _currentPrice > _desiredPrice) {
      _idxSlipDiff = _currentPrice - _desiredPrice;
    } else if (!_isLong && _desiredPrice > _currentPrice) {
      _idxSlipDiff = _desiredPrice - _currentPrice;
    }
    if (_idxSlipDiff > 0) {
      require(
        (_idxSlipDiff * FACTOR) / _desiredPrice <= (_slippage * FACTOR) / 1000,
        'SLIPPAGE'
      );
    }
  }

  function _createNewPosition(uint256 _indexInd, uint256 _tokenId)
    internal
    returns (Position storage)
  {
    Position storage _newPosition = positions[_tokenId];
    for (uint256 _i = 0; _i < indexes[_indexInd].priceFeeds.length; _i++) {
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(
        indexes[_indexInd].priceFeeds[_i].proxy
      );
      _newPosition.feeds.push(
        PositionIndexFeed({
          feed: indexes[_indexInd].priceFeeds[_i],
          phaseIdStart: _phase,
          roundIdStart: _round,
          phaseIdSettle: 0,
          roundIdSettle: 0
        })
      );
    }
    return _newPosition;
  }

  function _canOpenAgainstIndex(uint256 _ind, uint256 _timestamp)
    internal
    view
    returns (bool)
  {
    return
      _doTimeBoundsPass(
        _timestamp,
        indexes[_ind].dowOpenMin,
        indexes[_ind].dowOpenMax,
        indexes[_ind].hourOpenMin,
        indexes[_ind].hourOpenMax
      );
  }

  function _doTimeBoundsPass(
    uint256 _timestamp,
    uint256 _dowOpenMin,
    uint256 _dowOpenMax,
    uint256 _hourOpenMin,
    uint256 _hourOpenMax
  ) internal view returns (bool) {
    _timestamp = _timestamp == 0 ? block.timestamp : _timestamp;
    if (_dowOpenMin >= 1 && _dowOpenMax >= 1) {
      uint256 _dow = timeLibrary.getDayOfWeek(_timestamp);
      if (_dow < _dowOpenMin || _dow > _dowOpenMax) {
        return false;
      }
    }
    if (_hourOpenMin >= 1 || _hourOpenMax >= 1) {
      uint256 _hour = timeLibrary.getHour(_timestamp);
      if (_hour < _hourOpenMin || _hour > _hourOpenMax) {
        return false;
      }
    }
    return true;
  }

  function closePosition(uint256 _tokenId) external {
    _closePosition(_tokenId, false);
  }

  function _closePosition(uint256 _tokenId, bool _overrideOwner) internal {
    address _user = perpsNft.ownerOf(_tokenId);

    require(_overrideOwner || msg.sender == _user, 'OWNLQ');
    require(perpsNft.doesTokenExist(_tokenId), 'CLOSE1');

    _getAndClosePositionPLInfo(_tokenId, _user);
    _removeOpenPosition(_tokenId);
    _closeIndividualFeeds(_tokenId);
    _updateCloseAmounts(_tokenId);
    perpsNft.burn(_tokenId);

    positionClosers[_tokenId] = _user;

    emit ClosePosition(
      _tokenId,
      _user,
      positions[_tokenId].indexPriceStart,
      positions[_tokenId].indexPriceSettle,
      positions[_tokenId].amountWon,
      positions[_tokenId].amountLost
    );
  }

  function settleUnsettledPosition(
    uint256 _tokenId,
    uint256 _collPriceUSD,
    uint256 _mainPriceUSD
  ) external onlySettler {
    Position storage _position = positions[_tokenId];
    require(!_position.isSettled, 'SET1');
    require(_position.collateralCloseUnsettled > 0, 'SET2');

    _position.isSettled = true;
    _position.lifecycle.settleCollPriceUSD = _collPriceUSD;
    _position.lifecycle.settleMainPriceUSD = _mainPriceUSD;
    uint256 _mainSettleAmt = (_position.collateralCloseUnsettled *
      10**ERC20(mainCollateralToken).decimals() *
      _collPriceUSD) /
      _mainPriceUSD /
      10**ERC20(_position.collateralToken).decimals();
    ERC20(mainCollateralToken).safeTransfer(
      positionClosers[_tokenId],
      _mainSettleAmt
    );

    // remove from unsettled positions array
    uint256 _unsetPositionsIdx = _unsettledPositionsIdx[_tokenId];
    uint256 _tokenIdMoving = allUnsettledPositions[
      allUnsettledPositions.length - 1
    ];
    delete _unsettledPositionsIdx[_tokenId];
    _unsettledPositionsIdx[_tokenIdMoving] = _unsetPositionsIdx;
    allUnsettledPositions[_unsetPositionsIdx] = _tokenIdMoving;
    allUnsettledPositions.pop();

    emit SettlePosition(_tokenId, _mainSettleAmt, _collPriceUSD, _mainPriceUSD);
  }

  function getIndexAndPLInfo(uint256 _tokenId)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      bool,
      bool
    )
  {
    Position memory _position = positions[_tokenId];
    bool _canCloseInProfit = true;
    uint256 _currentIndexPrice = getPositionIndexPrice(_tokenId);
    bool _settlePriceIsHigher = _currentIndexPrice > _position.indexPriceStart;
    bool _settlePriceIsLower = _currentIndexPrice < _position.indexPriceStart;
    uint256 _indexAbsDiffFromOpen = _settlePriceIsHigher
      ? _currentIndexPrice - _position.indexPriceStart
      : _position.indexPriceStart - _currentIndexPrice;
    uint256 _absolutePL = (_position.positionAmount * _indexAbsDiffFromOpen) /
      _position.indexPriceStart;
    bool _isProfit = _position.isLong
      ? _settlePriceIsHigher
      : _settlePriceIsLower;

    uint256 _amountReturnToUser = _position.collateralAmount;
    if (_isProfit) {
      bool _isOverMinChange = _indexAbsDiffFromOpen >=
        (_position.indexPriceStart * minPriceDiffForProfit) / PERC_DEN;
      bool _isPastMinTime = block.timestamp >=
        _position.lifecycle.openTime + minOpenTimeForProfit;
      if (_isOverMinChange || _isPastMinTime) {
        _amountReturnToUser += _absolutePL;
      } else {
        _canCloseInProfit = false;
      }
    } else {
      if (_absolutePL > _amountReturnToUser) {
        _amountReturnToUser = 0;
      } else {
        _amountReturnToUser -= _absolutePL;
      }
    }
    return (
      _currentIndexPrice,
      _amountReturnToUser,
      _absolutePL,
      _isProfit,
      _canCloseInProfit
    );
  }

  function getLiquidationPriceChange(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    // 90% of exact liquidation which would mean 100% deliquency
    // NOTE: _position.leverage == 10 means 1x
    // Ex. price start == 100, leverage == 15 (1.5x)
    // (priceStart / (15 / 10)) * (9 / 10)
    // (priceStart * 10 / 15) * (9 / 10)
    // (priceStart / 15) * 9
    // (priceStart * 9) / 15
    return
      (positions[_tokenId].indexPriceStart * 9) / positions[_tokenId].leverage;
  }

  function getPositionIndexPrice(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    address[] memory _proxies = new address[](positions[_tokenId].feeds.length);
    uint256[] memory _multipliers = new uint256[](
      positions[_tokenId].feeds.length
    );
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      _proxies[_i] = positions[_tokenId].feeds[_i].feed.proxy;
      _multipliers[_i] = positions[_tokenId].feeds[_i].feed.priceWeightMult;
    }
    return getIndexPriceFromFeeds(_proxies, _multipliers);
  }

  function getPositionCloseFees(uint256 _tokenId)
    public
    view
    returns (uint256, uint256)
  {
    address _owner = perpsNft.ownerOf(_tokenId);
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(_owner);
    uint256 _closingFeePosition = (positions[_tokenId].positionAmount *
      closeFeePositionSize) / PERC_DEN;
    uint256 _closingFeeDurationPerUnit = (positions[_tokenId].positionAmount *
      closeFeePerDuration) / PERC_DEN;
    uint256 _closingFeeDurationTotal = (_closingFeeDurationPerUnit *
      (block.timestamp - positions[_tokenId].lifecycle.openTime)) /
      closeFeePerDurationUnit;

    // user has discount from fees
    if (_percentOff > 0) {
      _closingFeePosition -=
        (_closingFeePosition * _percentOff) /
        _percOffDenomenator;
      _closingFeeDurationTotal -=
        (_closingFeeDurationTotal * _percentOff) /
        _percOffDenomenator;
    }
    return (_closingFeePosition, _closingFeeDurationTotal);
  }

  function getPositionIndexProxies(uint256 _tokenId)
    external
    view
    returns (address[] memory)
  {
    address[] memory _proxies = new address[](positions[_tokenId].feeds.length);
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      _proxies[_i] = positions[_tokenId].feeds[_i].feed.proxy;
    }
    return _proxies;
  }

  function addTriggerOrder(uint256 _tokenId, uint256 _idxPriceTarget)
    external
    onlyPositionOwner(_tokenId)
  {
    _addTriggerOrder(_tokenId, _idxPriceTarget);
  }

  function updateTriggerOrder(
    uint256 _tokenId,
    uint256 _idx,
    uint256 _idxPriceTarget
  ) external onlyPositionOwner(_tokenId) {
    _updateTriggerOrder(_tokenId, _idx, _idxPriceTarget);
  }

  function removeTriggerOrder(uint256 _tokenId, uint256 _idx)
    external
    onlyPositionOwner(_tokenId)
  {
    _removeTriggerOrder(_tokenId, _idx);
  }

  function _addTriggerOrder(uint256 _tokenId, uint256 _idxPriceTarget)
    internal
  {
    require(_idxPriceTarget > 0, 'TO0');
    require(positionTriggerOrders[_tokenId].length < maxTriggerOrders, 'TO1');
    uint256 _idxPriceCurr = getPositionIndexPrice(_tokenId);
    require(_idxPriceCurr != _idxPriceTarget, 'TO2');

    positionTriggerOrders[_tokenId].push(
      TriggerOrder({
        idxPriceCurrent: _idxPriceCurr,
        idxPriceTarget: _idxPriceTarget
      })
    );
  }

  function _updateTriggerOrder(
    uint256 _tokenId,
    uint256 _idx,
    uint256 _idxTargetPrice
  ) internal {
    require(_idxTargetPrice > 0, 'TO0');

    TriggerOrder storage _order = positionTriggerOrders[_tokenId][_idx];
    bool _isTargetLess = _order.idxPriceTarget < _order.idxPriceCurrent;
    // if original target is less than original current, new target must
    // remain less than, or vice versa for higher than prices
    require(
      _isTargetLess
        ? _idxTargetPrice < _order.idxPriceCurrent
        : _idxTargetPrice > _order.idxPriceCurrent,
      'TO3'
    );
    _order.idxPriceTarget = _idxTargetPrice;
  }

  function _removeTriggerOrder(uint256 _tokenId, uint256 _idx) internal {
    positionTriggerOrders[_tokenId][_idx] = positionTriggerOrders[_tokenId][
      positionTriggerOrders[_tokenId].length - 1
    ];
    positionTriggerOrders[_tokenId].pop();
  }

  function setValidCollateralToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(_validColl[_token] != _isValid, 'change state');
    _validColl[_token] = _isValid;
    if (_isValid) {
      _allCollTokensInd[_token] = _allCollTokens.length;
      _allCollTokens.push(_token);
    } else {
      uint256 _ind = _allCollTokensInd[_token];
      delete _allCollTokensInd[_token];
      _allCollTokens[_ind] = _allCollTokens[_allCollTokens.length - 1];
      _allCollTokens.pop();
    }
  }

  function setMainCollateralToken(address _token) external onlyOwner {
    require(allOpenPositions.length == 0, 'MAINCOLL');
    mainCollateralToken = _token;
  }

  // 10 == 1x, 1000 == 100x, etc.
  function setMaxLeverage(uint16 _max) external onlyOwner {
    require(_max <= 2500, 'max 250x');
    maxLeverage = _max;
  }

  function setMaxTriggerOrders(uint8 _max) external onlyOwner {
    maxTriggerOrders = _max;
  }

  function setMinOpenTimeForProfit(uint256 _seconds) external onlyOwner {
    require(_seconds <= 1 days, 'max 1 days');
    minOpenTimeForProfit = _seconds;
  }

  function setMinPriceDiffForProfit(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 3) / 100, 'max 3%');
    minPriceDiffForProfit = _percentage;
  }

  function setOpenFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100, 'max 10%');
    openFeePositionSize = _percentage;
  }

  function setCloseFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100, 'max 10%');
    closeFeePositionSize = _percentage;
  }

  function setCloseFeePositionPerDurationUnit(uint256 _seconds)
    external
    onlyOwner
  {
    require(_seconds >= 10 minutes, 'min 10m');
    closeFeePerDurationUnit = _seconds;
  }

  function setClosePositionFeePerDuration(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 1) / 100, 'max 1%');
    closeFeePerDuration = _percentage;
  }

  function setSettler(address _wallet, bool _isSettler) external onlyOwner {
    require(settlers[_wallet] != _isSettler, 'SET3');
    settlers[_wallet] = _isSettler;
  }

  function setMaxCollateralOpenDiff(address _collateral, uint256 _amount)
    external
    onlyOwner
  {
    maxCollateralOpenDiff[_collateral] = _amount;
  }

  function setMaxLiquidationsPerUpkeep(uint8 _max) external onlyOwner {
    require(_max > 0, 'min 1');
    maxLiquidationsPerUpkeep = _max;
  }

  function addIndex(
    string memory _name,
    address[] memory _proxies,
    uint16[] memory _weights
  ) external onlyOwner {
    require(
      _proxies.length > 0 && _proxies.length == _weights.length,
      'same len'
    );
    Index storage _newIndex = indexes.push();
    _newIndex.name = _name;

    for (uint256 _i = 0; _i < _proxies.length; _i++) {
      address _proxy = _proxies[_i];
      (, , uint256 _priceUSD) = getLatestProxyInfo(_proxy);
      require(_priceUSD > 0, 'invalid proxy');

      _newIndex.weightsTotal += _proxies.length == 1 ? 0 : _weights[_i];
      _newIndex.priceFeeds.push(
        IndexFeed({
          proxy: _proxy,
          weight: _weights[_i],
          priceWeightMult: _proxies.length == 1
            ? 0
            : (_weights[_i] * FACTOR**2) / _priceUSD
        })
      );
    }
  }

  function removeIndex(uint256 _index) external onlyOwner {
    indexes[_index] = indexes[indexes.length - 1];
    indexes.pop();
  }

  function refreshIndexFeedWeights(uint256 _indexIdx) external onlyOwner {
    Index storage _index = indexes[_indexIdx];
    require(_index.priceFeeds.length > 1, 'ISIDX');
    for (uint256 _i = 0; _i < _index.priceFeeds.length; _i++) {
      (, , uint256 _priceUSD) = getLatestProxyInfo(_index.priceFeeds[_i].proxy);
      _index.priceFeeds[_i].priceWeightMult =
        (_index.priceFeeds[_i].weight * FACTOR**2) /
        _priceUSD;
    }
  }

  function updateIndexOpenTimeBounds(
    uint256 _indexInd,
    uint256 _dowOpenMin,
    uint256 _dowOpenMax,
    uint256 _hourOpenMin,
    uint256 _hourOpenMax
  ) external onlyOwner {
    Index storage _index = indexes[_indexInd];
    _index.dowOpenMin = _dowOpenMin;
    _index.dowOpenMax = _dowOpenMax;
    _index.hourOpenMin = _hourOpenMin;
    _index.hourOpenMax = _hourOpenMax;
  }

  function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
    tradingEnabled = _tradingEnabled;
  }

  function setFeeReducer(address _reducer) external onlyOwner {
    feeReducer = IFeeReducer(_reducer);
  }

  function processFees(uint256 _amount) external onlyOwner {
    ERC20(mainCollateralToken).safeTransfer(mainCollateralToken, _amount);
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    ERC20 _contract = ERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.safeTransfer(owner(), _amount);
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      if (
        shouldPositionLiquidate(_tokenId) ||
        shouldPositionCloseFromTrigger(_tokenId)
      ) {
        upkeepNeeded = true;
        break;
      }
    }
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    uint8 _liquidations;
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      bool _wasLiquidated = checkAndLiquidatePosition(_tokenId);
      if (_wasLiquidated) {
        _liquidations++;
        if (_liquidations >= maxLiquidationsPerUpkeep) {
          break;
        }
      }
    }
  }

  function checkAndLiquidatePosition(uint256 _tokenId) public returns (bool) {
    bool _shouldLiquidate = shouldPositionLiquidate(_tokenId);
    bool _triggerClose = shouldPositionCloseFromTrigger(_tokenId);
    if (_shouldLiquidate || _triggerClose) {
      _closePosition(_tokenId, true);

      if (_shouldLiquidate) {
        emit LiquidatePosition(_tokenId);
      } else if (_triggerClose) {
        emit ClosePositionFromTriggerOrder(_tokenId);
      }
      return true;
    }
    return false;
  }

  function getFeeDiscount(address _wallet)
    public
    view
    returns (uint256, uint256)
  {
    return
      address(feeReducer) != address(0)
        ? feeReducer.percentDiscount(_wallet)
        : (0, 0);
  }

  function _getPositionOpenFee(
    address _user,
    uint256 _collateral,
    uint256 _leverage
  ) internal view returns (uint256) {
    uint256 _positionPreFee = (_collateral * _leverage) / 10;
    uint256 _openFee = (_positionPreFee * openFeePositionSize) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(_user);
    // user has discount from fees
    if (_percentOff > 0) {
      _openFee -= (_openFee * _percentOff) / _percOffDenomenator;
    }
    return _openFee;
  }

  function _addOpenPosition(uint256 _tokenId) internal {
    _openPositionsIdx[_tokenId] = allOpenPositions.length;
    allOpenPositions.push(_tokenId);
  }

  function _removeOpenPosition(uint256 _tokenId) internal {
    uint256 _allPositionsIdx = _openPositionsIdx[_tokenId];
    uint256 _tokenIdMoving = allOpenPositions[allOpenPositions.length - 1];
    delete _openPositionsIdx[_tokenId];
    _openPositionsIdx[_tokenIdMoving] = _allPositionsIdx;
    allOpenPositions[_allPositionsIdx] = _tokenIdMoving;
    allOpenPositions.pop();
  }

  function _checkAndSettlePosition(
    uint256 _tokenId,
    address _closingUser,
    uint256 _returnAmount
  ) internal {
    Position storage _position = positions[_tokenId];
    if (_returnAmount > 0) {
      if (_position.collateralToken == mainCollateralToken) {
        _position.isSettled = true;
        ERC20(_position.collateralToken).safeTransfer(
          _closingUser,
          _returnAmount
        );
      } else {
        if (_returnAmount > _position.collateralAmount) {
          if (_position.collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _position.collateralAmount }('');
            require(
              address(this).balance >= _before - _position.collateralAmount,
              'NAT1'
            );
          } else {
            ERC20(_position.collateralToken).safeTransfer(
              _closingUser,
              _position.collateralAmount
            );
          }
          _position.collateralCloseUnsettled =
            _returnAmount -
            _position.collateralAmount;
          _unsettledPositionsIdx[_tokenId] = allUnsettledPositions.length;
          allUnsettledPositions.push(_tokenId);
          emit CloseUnsettledPosition(_tokenId);
        } else {
          _position.isSettled = true;
          if (_position.collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _returnAmount }('');
            require(address(this).balance >= _before - _returnAmount, 'NAT1');
          } else {
            ERC20(_position.collateralToken).safeTransfer(
              _closingUser,
              _returnAmount
            );
          }
        }
      }
    } else {
      _position.isSettled = true;
    }
  }

  function _getAndClosePositionPLInfo(uint256 _tokenId, address _closingUser)
    internal
  {
    Position storage _position = positions[_tokenId];
    (
      uint256 _closingFeePosition,
      uint256 _closingFeeDurationTotal
    ) = getPositionCloseFees(_tokenId);
    uint256 _totalCloseFees = _closingFeePosition + _closingFeeDurationTotal;

    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,
      bool _canCloseInProfit
    ) = getIndexAndPLInfo(_tokenId);

    // adjust amount returned based on closing fees incurred then transfer to position holder
    _amountReturnToUser = _totalCloseFees > _amountReturnToUser
      ? 0
      : _amountReturnToUser - _totalCloseFees;
    _checkAndSettlePosition(_tokenId, _closingUser, _amountReturnToUser);

    _position.lifecycle.closeTime = block.timestamp;
    _position.lifecycle.closeFees = _totalCloseFees;
    _position.indexPriceSettle = _currentIndexPrice;
    _position.amountWon = _isProfit && _canCloseInProfit ? _absolutePL : 0;
    _position.amountLost = _isProfit
      ? 0
      : _absolutePL > _position.collateralAmount
      ? _position.collateralAmount
      : _absolutePL;
  }

  function _closeIndividualFeeds(uint256 _tokenId) internal {
    // update settle phase and round data for all proxies that make up the index
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      PositionIndexFeed storage _feed = positions[_tokenId].feeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.feed.proxy);
      _feed.phaseIdSettle = _phase;
      _feed.roundIdSettle = _round;
    }
  }

  function _validateAndUpdateOpenAmounts(uint256 _tokenId, uint256 _amount)
    internal
  {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] += _amount;
    } else {
      amtOpenShort[positions[_tokenId].collateralToken] += _amount;
    }
    if (maxCollateralOpenDiff[positions[_tokenId].collateralToken] > 0) {
      uint256 _openDiff = amtOpenLong[positions[_tokenId].collateralToken] >
        amtOpenShort[positions[_tokenId].collateralToken]
        ? amtOpenLong[positions[_tokenId].collateralToken] -
          amtOpenShort[positions[_tokenId].collateralToken]
        : amtOpenShort[positions[_tokenId].collateralToken] -
          amtOpenLong[positions[_tokenId].collateralToken];
      require(
        _openDiff <= maxCollateralOpenDiff[positions[_tokenId].collateralToken],
        'max collateral reached'
      );
    }
  }

  function _updateCloseAmounts(uint256 _tokenId) internal {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] -= positions[_tokenId]
        .positionAmount;
    } else {
      amtOpenShort[positions[_tokenId].collateralToken] -= positions[_tokenId]
        .positionAmount;
    }
  }

  function shouldPositionLiquidate(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    uint256 _priceChangeForLiquidation = getLiquidationPriceChange(_tokenId);
    (uint256 _closingFeeMain, uint256 _closingFeeTime) = getPositionCloseFees(
      _tokenId
    );
    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      ,
      bool _isProfit,

    ) = getIndexAndPLInfo(_tokenId);
    uint256 _indexPriceDelinquencyPrice = positions[_tokenId].isLong
      ? positions[_tokenId].indexPriceStart - _priceChangeForLiquidation
      : positions[_tokenId].indexPriceStart + _priceChangeForLiquidation;
    bool _priceInLiquidation = positions[_tokenId].isLong
      ? _currentIndexPrice <= _indexPriceDelinquencyPrice
      : _currentIndexPrice >= _indexPriceDelinquencyPrice;
    bool _feesExceedReturn = !_isProfit &&
      _closingFeeMain + _closingFeeTime >= _amountReturnToUser;
    return _priceInLiquidation || _feesExceedReturn;
  }

  function shouldPositionCloseFromTrigger(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    uint256 _currIdxPrice = getPositionIndexPrice(_tokenId);
    for (uint256 _i = 0; _i < positionTriggerOrders[_tokenId].length; _i++) {
      uint256 _target = positionTriggerOrders[_tokenId][_i].idxPriceTarget;
      bool _lessThanEQ = _target <
        positionTriggerOrders[_tokenId][_i].idxPriceCurrent;
      if (_lessThanEQ) {
        if (_currIdxPrice <= _target) {
          return true;
        }
      } else {
        if (_currIdxPrice >= _target) {
          return true;
        }
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
pragma solidity ^0.8.16;

interface IFeeReducer {
  function percentDiscount(address wallet)
    external
    view
    returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBokkyPooBahsDateTime {
  function getDayOfWeek(uint256 timestamp)
    external
    pure
    returns (uint256 dayOfWeek);

  function getHour(uint256 timestamp) external pure returns (uint256 hour);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './interfaces/PriceFeedProxy.sol';

contract IndexHandler {
  uint256 constant FACTOR = 10**18;

  struct IndexFeed {
    address proxy;
    uint16 weight;
    uint256 priceWeightMult;
  }

  struct Index {
    string name;
    uint256 weightsTotal;
    uint256 dowOpenMin;
    uint256 dowOpenMax;
    uint256 hourOpenMin;
    uint256 hourOpenMax;
    IndexFeed[] priceFeeds;
  }

  Index[] public indexes;

  function getIndexPriceFromIndex(uint256 _index)
    public
    view
    returns (uint256)
  {
    Index memory index = indexes[_index];
    uint256 priceUSD;
    for (uint256 i = 0; i < index.priceFeeds.length; i++) {
      IndexFeed memory _proxy = index.priceFeeds[i];
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxy.proxy);
      priceUSD += _proxy.priceWeightMult == 0
        ? _feedPriceUSD
        : (_feedPriceUSD * _proxy.priceWeightMult) / FACTOR;
    }
    return priceUSD;
  }

  function getIndexPriceFromFeeds(
    address[] memory _proxies,
    uint256[] memory _multipliers
  ) public view returns (uint256) {
    require(_proxies.length == _multipliers.length);
    uint256 priceUSD;
    for (uint256 i = 0; i < _proxies.length; i++) {
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxies[i]);
      priceUSD += _proxies.length == 1
        ? _feedPriceUSD
        : (_feedPriceUSD * _multipliers[i]) / FACTOR;
    }
    return priceUSD;
  }

  function getLatestProxyInfo(address _proxy)
    public
    view
    returns (
      uint16,
      uint80,
      uint256
    )
  {
    PriceFeedProxy _feed = PriceFeedProxy(_proxy);
    uint16 _phaseId = _feed.phaseId();
    uint8 _decimals = _feed.decimals();
    (uint80 _proxyRoundId, int256 _price, , , ) = _feed.latestRoundData();
    return (
      _phaseId,
      _proxyRoundId,
      uint256(_price) * (10**18 / 10**_decimals)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@chainlink/contracts/src/v0.8/KeeperCompatible.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './IndexHandler.sol';

contract pfYDF is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  address public perpetualFutures;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferred;

  event Burn(uint256 indexed tokenId, address indexed owner);
  event Mint(uint256 indexed tokenId, address indexed owner);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  modifier onlyPerps() {
    require(msg.sender == perpetualFutures, 'only perps');
    _;
  }

  constructor(string memory _baseTokenURI)
    ERC721('Yieldification Perpetual Futures', 'pfYDF')
  {
    baseTokenURI = _baseTokenURI;
    perpetualFutures = msg.sender;
  }

  function mint(address owner) external onlyPerps returns (uint256) {
    _ids.increment();
    _safeMint(owner, _ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;
    emit Mint(_ids.current(), owner);
    return _ids.current();
  }

  function burn(uint256 _tokenId) external onlyPerps {
    address _user = ownerOf(_tokenId);
    require(_exists(_tokenId));
    _burn(_tokenId);
    emit Burn(_tokenId, _user);
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId));
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function doesTokenExist(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function setPerpetualFutures(address _perps) external onlyOwner {
    perpetualFutures = _perps;
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Enumerable) {
    tokenLastTransferred[_tokenId] = block.timestamp;

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721) {
    // if from == address(0), token is being minted
    if (_from != address(0)) {
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;
    }

    // if to == address(0), token is being burned
    if (_to != address(0)) {
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);
    }

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol';

interface PriceFeedProxy is AggregatorV2V3Interface {
  function aggregator() external view returns (address);

  function phaseId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}