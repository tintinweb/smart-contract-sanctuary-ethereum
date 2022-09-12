// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/KeeperCompatible.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './IndexHandler.sol';

contract pfYDF is
  ERC721Enumerable,
  IndexHandler,
  KeeperCompatibleInterface,
  Ownable
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private constant PERC_DEN = 100000;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public paymentAddress;
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  bool public enabled = true;

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferred;

  address public treasury;
  mapping(address => bool) public liquidators;
  uint8 maxLiquidationsPerUpkeep = 25;

  IERC20 private _positionToken =
    IERC20(0x30dcBa0405004cF124045793E1933C798Af9E66a);

  uint16 public maxLeverage = 10; // 1x
  uint256 public minOpenTimeForProfit = 3 hours;
  uint256 public minPriceDiffForProfit = (PERC_DEN * 15) / 1000; // 1.5%
  uint256 public openPositionFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closePositionFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closePositionFeePerDurationUnit = 1 hours;
  uint256 public closePositionFeePerDuration = (PERC_DEN * 5) / 100000; // 0.005% / hour
  uint256 public totalFeesCollected;
  uint256 public totalAmountProfit;
  uint256 public totalAmountLoss;

  struct PositionIndexFeed {
    IndexFeed feed;
    uint16 phaseIdStart;
    uint80 roundIdStart;
    uint16 phaseIdSettle;
    uint80 roundIdSettle;
  }

  struct Position {
    PositionIndexFeed[] feeds;
    uint256 openTime;
    uint256 openFees;
    uint256 closeTime;
    uint256 closeFees;
    uint256 amountCollateral;
    uint256 amountPosition;
    bool isLong;
    uint16 leverage;
    uint256 indexPriceStart;
    uint256 indexPriceSettle;
    uint256 amountWon;
    uint256 amountLost;
  }

  // tokenId => Position
  mapping(uint256 => Position) public positions;
  // tokenId => address
  mapping(uint256 => address) public positionOpeners;
  // tokenId => address
  mapping(uint256 => address) public positionClosers;
  // tokenId[]
  uint256[] public allOpenPositions;
  // tokenId => allOpenPositions index
  mapping(uint256 => uint256) internal _openPositionsIndexed;

  event OpenPosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 positionCollateral
  );
  event SettlePosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 indexPriceSettle,
    uint256 amountWon,
    uint256 amountLost
  );
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  constructor(string memory _baseTokenURI)
    ERC721('Yieldification Perpetual Futures', 'pfYDF')
  {
    baseTokenURI = _baseTokenURI;
  }

  function getAllIndexes() external view returns (Index[] memory) {
    return indexes;
  }

  function openPosition(
    uint256 _indexInd,
    uint256 _collateral,
    uint16 _leverage, // 10 == 1x, 1000 == 100x
    bool _isLong
  ) external {
    require(enabled, 'opening positions is not enabled');
    require(_indexInd < indexes.length, 'invalid index provided');
    require(
      _positionToken.balanceOf(msg.sender) >= _collateral,
      'you can only open a position with up to your balance'
    );
    require(
      _leverage >= 10 && _leverage <= maxLeverage,
      'cannot exceed max allowable leverage'
    );

    _ids.increment();
    _positionToken.transferFrom(msg.sender, address(this), _collateral);
    uint256 _positionPreFee = (_collateral * _leverage) / 10;
    uint256 _openFee = (_positionPreFee * openPositionFeePositionSize) /
      PERC_DEN;
    uint256 _finalPositionCollateral = _collateral - _openFee;
    uint256 _finalPositionAmount = (_finalPositionCollateral * _leverage) / 10;
    totalFeesCollected += _openFee;

    Index memory _index = indexes[_indexInd];
    Position storage _newPosition = positions[_ids.current()];
    for (uint256 _i = 0; _i < _index.priceFeeds.length; _i++) {
      IndexFeed memory _feed = _index.priceFeeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.proxy);
      _newPosition.feeds.push(
        PositionIndexFeed({
          feed: _index.priceFeeds[_i],
          phaseIdStart: _phase,
          roundIdStart: _round,
          phaseIdSettle: 0,
          roundIdSettle: 0
        })
      );
    }
    uint256 _openPrice = getIndexPriceFromIndex(_indexInd);
    positionOpeners[_ids.current()] = msg.sender;
    _newPosition.openTime = block.timestamp;
    _newPosition.openFees = _openFee;
    _newPosition.amountCollateral = _finalPositionCollateral;
    _newPosition.amountPosition = _finalPositionAmount;
    _newPosition.isLong = _isLong;
    _newPosition.leverage = _leverage;
    _newPosition.indexPriceStart = _openPrice;
    _newPosition.indexPriceSettle = 0;
    _newPosition.amountWon = 0;
    _newPosition.amountLost = 0;

    _safeMint(msg.sender, _ids.current());
    _addOpenPosition(_ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;

    emit OpenPosition(
      _ids.current(),
      msg.sender,
      _openPrice,
      _finalPositionCollateral
    );
  }

  function closePosition(uint256 _tokenId) external {
    _closePosition(_tokenId, false);
  }

  function _closePosition(uint256 _tokenId, bool _overrideCallerCheck)
    internal
  {
    Position storage _position = positions[_tokenId];
    address _user = ownerOf(_tokenId);

    require(
      _overrideCallerCheck || (msg.sender == _user || liquidators[msg.sender]),
      'must be position owner or liquidator'
    );
    require(_exists(_tokenId), 'position is already closed');

    // make sure position should be liquidated if this is a liquidator trying to close position
    if (liquidators[msg.sender] && msg.sender != _user) {
      require(
        shouldPositionLiquidate(_tokenId),
        'position is not in liquidation status'
      );
    }

    (
      uint256 _closingFeePosition,
      uint256 _closingFeeDurationTotal
    ) = getPositionCloseFees(_tokenId);
    uint256 _totalCloseFees = _closingFeePosition + _closingFeeDurationTotal;
    totalFeesCollected += _totalCloseFees;

    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,
      bool _canCloseInProfit
    ) = getIndexAndPLInfo(_tokenId);

    if (_isProfit) {
      if (_canCloseInProfit) {
        totalAmountProfit += _absolutePL;
      }
    } else {
      totalAmountLoss += _absolutePL;
    }

    // adjust amount returned based on closing fees incurred then transfer to position holder
    _amountReturnToUser = _totalCloseFees > _amountReturnToUser
      ? 0
      : _amountReturnToUser - _totalCloseFees;
    if (_amountReturnToUser > 0) {
      _positionToken.transfer(_user, _amountReturnToUser);
    }

    positionClosers[_tokenId] = _user;
    _position.closeTime = block.timestamp;
    _position.closeFees = _totalCloseFees;
    _position.indexPriceSettle = _currentIndexPrice;
    _position.amountWon = _isProfit && _canCloseInProfit ? _absolutePL : 0;
    _position.amountLost = _isProfit
      ? 0
      : _absolutePL > _position.amountCollateral
      ? _position.amountCollateral
      : _absolutePL;

    _burn(_tokenId);
    _removeOpenPosition(_tokenId);
    _closeIndividualFeeds(_tokenId);

    emit SettlePosition(
      _tokenId,
      _user,
      _position.indexPriceStart,
      _position.indexPriceSettle,
      _position.amountWon,
      _position.amountLost
    );
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
    bool _priceIsHigherAtSettle = _currentIndexPrice >
      _position.indexPriceStart;
    uint256 _indexAbsDiffFromOpen = _priceIsHigherAtSettle
      ? _currentIndexPrice - _position.indexPriceStart
      : _position.indexPriceStart - _currentIndexPrice;
    uint256 _absolutePL = (_position.amountPosition * _indexAbsDiffFromOpen) /
      _position.indexPriceStart;
    bool _isProfit = _position.isLong
      ? _priceIsHigherAtSettle
      : !_priceIsHigherAtSettle;

    uint256 _amountReturnToUser = _position.amountCollateral;
    if (_isProfit) {
      bool _isOverMinChange = _absolutePL >=
        (_position.indexPriceStart * minPriceDiffForProfit) / PERC_DEN;
      bool _isPastMinTime = block.timestamp >=
        _position.openTime + minOpenTimeForProfit;
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
    Position memory _position = positions[_tokenId];

    // 90% of exact liquidation which would mean 100% deliquency
    // NOTE: _position.leverage == 10 means 1x
    // Ex. price start == 100, leverage == 15 (1.5x)
    // (priceStart / (15 / 10)) * (9 / 10)
    // (priceStart * 10 / 15) * (9 / 10)
    // (priceStart / 15) * 9
    // (priceStart * 9) / 15
    return (_position.indexPriceStart * 9) / _position.leverage;
  }

  function shouldPositionLiquidate(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    Position memory _position = positions[_tokenId];
    uint256 _priceChangeForLiquidation = getLiquidationPriceChange(_tokenId);
    (uint256 _closingFeeMain, uint256 _closingFeeTime) = getPositionCloseFees(
      _tokenId
    );
    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,

    ) = getIndexAndPLInfo(_tokenId);
    uint256 _indexPriceDelinquencyPrice = _position.isLong
      ? _position.indexPriceStart - _priceChangeForLiquidation
      : _position.indexPriceStart + _priceChangeForLiquidation;
    bool _priceInLiquidation = _position.isLong
      ? _currentIndexPrice <= _indexPriceDelinquencyPrice
      : _currentIndexPrice >= _indexPriceDelinquencyPrice;
    bool _feesExceedReturn = !_isProfit &&
      _absolutePL + _closingFeeMain + _closingFeeTime >= _amountReturnToUser;
    return _priceInLiquidation || _feesExceedReturn;
  }

  function getPositionIndexPrice(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    Position memory _position = positions[_tokenId];
    address[] memory _proxies = new address[](_position.feeds.length);
    uint8[] memory _weights = new uint8[](_position.feeds.length);
    uint256 _totalWeight;
    for (uint256 _i = 0; _i < _position.feeds.length; _i++) {
      _proxies[_i] = _position.feeds[_i].feed.proxy;
      _weights[_i] = _position.feeds[_i].feed.weight;
      _totalWeight += _position.feeds[_i].feed.weight;
    }
    return getIndexPriceFromFeeds(_proxies, _weights, _totalWeight);
  }

  function getPositionCloseFees(uint256 _tokenId)
    public
    view
    returns (uint256, uint256)
  {
    Position memory _position = positions[_tokenId];
    uint256 _closingFeePosition = (_position.amountPosition *
      closePositionFeePositionSize) / PERC_DEN;
    uint256 _closingFeeDurationPerUnit = (_position.amountPosition *
      closePositionFeePerDuration) / PERC_DEN;
    uint256 _closingFeeDurationTotal = (_closingFeeDurationPerUnit *
      (block.timestamp - _position.openTime)) / closePositionFeePerDurationUnit;
    return (_closingFeePosition, _closingFeeDurationTotal);
  }

  function getPositionIndexProxies(uint256 _tokenId)
    external
    view
    returns (address[] memory)
  {
    Position memory _pos = positions[_tokenId];
    PositionIndexFeed[] memory _posFeeds = _pos.feeds;
    address[] memory _proxies = new address[](_pos.feeds.length);
    for (uint256 _i = 0; _i < _posFeeds.length; _i++) {
      _proxies[_i] = _posFeeds[_i].feed.proxy;
    }
    return _proxies;
  }

  function getPositionToken() external view returns (address) {
    return address(_positionToken);
  }

  function setPositionToken(address _token) external onlyOwner {
    require(
      allOpenPositions.length == 0,
      'cannot change position token with open positions'
    );
    _positionToken = IERC20(_token);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  // 10 == 1x, 1000 == 100x, etc.
  function setMaxLeverage(uint16 _max) external onlyOwner {
    require(_max <= 2000, 'cannot be more than 200x');
    maxLeverage = _max;
  }

  function setMinOpenTimeForProfit(uint256 _seconds) external onlyOwner {
    require(_seconds <= 1 days, 'cannot be more than 1 days');
    minOpenTimeForProfit = _seconds;
  }

  function setMinPriceDiffForProfit(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 3) / 100, 'cannot be more than 3%');
    minPriceDiffForProfit = _percentage;
  }

  function setOpenPositionFeePositionSize(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 10) / 100, 'cannot be more than 10%');
    openPositionFeePositionSize = _percentage;
  }

  function setClosePositionFeePositionSize(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 10) / 100, 'cannot be more than 10%');
    closePositionFeePositionSize = _percentage;
  }

  function setClosePositionFeePerDurationUnit(uint256 _seconds)
    external
    onlyOwner
  {
    require(
      _seconds >= 10 minutes,
      'unit time frame cannot be less than 10 min'
    );
    closePositionFeePerDurationUnit = _seconds;
  }

  function setClosePositionFeePerDuration(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 1) / 100, 'cannot be more than 1%');
    closePositionFeePerDuration = _percentage;
  }

  function addLiquidator(address _wallet) external onlyOwner {
    require(!liquidators[_wallet], 'must not be liquidator to add them');
    liquidators[_wallet] = true;
  }

  function removeLiquidator(address _wallet) external onlyOwner {
    require(liquidators[_wallet], 'must be liquidator to remove them');
    delete liquidators[_wallet];
  }

  function setMaxLiquidationsPerUpkeep(uint8 _max) external onlyOwner {
    require(_max > 0, 'must allow liquidating at least 1');
    maxLiquidationsPerUpkeep = _max;
  }

  function addIndex(
    string memory _name,
    address[] memory _proxies,
    uint8[] memory _weights
  ) external onlyOwner {
    require(
      _proxies.length > 0 && _proxies.length == _weights.length,
      'must contain a weight for each proxy'
    );
    Index storage _newIndex = indexes.push();
    _newIndex.name = _name;
    for (uint256 _i = 0; _i < _proxies.length; _i++) {
      address _proxy = _proxies[_i];
      (, , uint256 _priceUSD) = getLatestProxyInfo(_proxy);
      require(_priceUSD > 0, 'invalid proxy');

      _newIndex.weightsTotal += _weights[_i];
      _newIndex.priceFeeds.push(
        IndexFeed({ proxy: _proxy, weight: _weights[_i] })
      );
    }
  }

  function removeIndex(uint256 _index) external onlyOwner {
    indexes[_index] = indexes[indexes.length - 1];
    indexes.pop();
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
    require(_exists(_tokenId), 'token does not exist');
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

  function isTokenMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
    emit SetPaymentAddress(_address);
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

  function setEnabled(bool _enabled) external onlyOwner {
    enabled = _enabled;
  }

  function processFees(uint256 _amount) external onlyOwner {
    _positionToken.transfer(address(_positionToken), _amount);
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20 _contract = IERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0, 'needs balance to withdraw');
    _contract.transfer(owner(), _amount);
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
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
      if (shouldPositionLiquidate(_tokenId)) {
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
      if (shouldPositionLiquidate(_tokenId)) {
        _closePosition(_tokenId, true);
        _liquidations++;
        if (_liquidations >= maxLiquidationsPerUpkeep) {
          break;
        }
      }
    }
  }

  function _addOpenPosition(uint256 _tokenId) internal {
    _openPositionsIndexed[_tokenId] = allOpenPositions.length;
    allOpenPositions.push(_tokenId);
  }

  function _removeOpenPosition(uint256 _tokenId) internal {
    uint256 _allPositionsIndex = _openPositionsIndexed[_tokenId];
    uint256 _tokenIdMoving = allOpenPositions[allOpenPositions.length - 1];
    delete _openPositionsIndexed[_tokenId];
    _openPositionsIndexed[_tokenIdMoving] = _allPositionsIndex;
    allOpenPositions[_allPositionsIndex] = _tokenIdMoving;
    allOpenPositions.pop();
  }

  function _closeIndividualFeeds(uint256 _tokenId) internal {
    Position storage _position = positions[_tokenId];
    // update settle phase and round data for all proxies that make up the index
    for (uint256 _i = 0; _i < _position.feeds.length; _i++) {
      PositionIndexFeed storage _feed = _position.feeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.feed.proxy);
      _feed.phaseIdSettle = _phase;
      _feed.roundIdSettle = _round;
    }
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
pragma solidity ^0.8.9;

import './interfaces/PriceFeedProxy.sol';

contract IndexHandler {
  struct IndexFeed {
    address proxy;
    uint8 weight;
  }

  struct Index {
    string name;
    uint256 weightsTotal;
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
      priceUSD += (_feedPriceUSD * _proxy.weight) / index.weightsTotal;
    }
    return priceUSD;
  }

  function getIndexPriceFromFeeds(
    address[] memory _proxies,
    uint8[] memory _weights,
    uint256 _totalWeight
  ) public view returns (uint256) {
    require(
      _proxies.length == _weights.length,
      'proxies and weights must be same length'
    );
    uint256 priceUSD;
    for (uint256 i = 0; i < _proxies.length; i++) {
      (, , uint256 _feedPriceUSD) = getLatestProxyInfo(_proxies[i]);
      priceUSD += (_feedPriceUSD * _weights[i]) / _totalWeight;
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

  function getProxyPriceAtRound(address _proxy, uint80 _roundId)
    public
    view
    returns (uint256)
  {
    PriceFeedProxy _feed = PriceFeedProxy(_proxy);
    uint8 _decimals = _feed.decimals();
    (, int256 _price, , , ) = _feed.getRoundData(_roundId);
    return uint256(_price) * (10**18 / 10**_decimals);
  }

  function getHistoricalPrice(
    address _proxy,
    uint16 _phaseId,
    uint80 _aggregatorRoundId,
    bool _requireCompletion
  )
    public
    view
    returns (
      uint80,
      uint256,
      uint256,
      uint80
    )
  {
    PriceFeedProxy _proxyContract = PriceFeedProxy(_proxy);
    uint80 _proxyRoundId = _getProxyRoundId(_phaseId, _aggregatorRoundId);
    (
      uint80 _roundId,
      int256 _price,
      ,
      uint256 _timestamp,
      uint80 _answeredInRound
    ) = _proxyContract.getRoundData(_proxyRoundId);
    uint8 _decimals = _proxyContract.decimals();
    if (_requireCompletion) {
      require(_timestamp > 0, 'Round not complete');
    }
    return (
      _roundId,
      uint256(_price) * (10**18 / 10**_decimals),
      _timestamp,
      _answeredInRound
    );
  }

  function _getProxyRoundId(uint16 _phaseId, uint80 _aggregatorRoundId)
    internal
    pure
    returns (uint80)
  {
    return uint80((uint256(_phaseId) << 64) | _aggregatorRoundId);
  }

  function getAggregatorInfo(uint256 _proxyRoundId)
    public
    pure
    returns (uint16, uint64)
  {
    uint16 _phaseId = uint16(_proxyRoundId >> 64);
    uint64 _aggregatorRoundId = uint64(_proxyRoundId);
    return (_phaseId, _aggregatorRoundId);
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