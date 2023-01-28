// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IFeeReducer.sol';
import './interfaces/IWETH.sol';
import './otcYDF.sol';

contract OverTheCounter is IERC721Receiver, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 private constant PERC_DEN = 100000;

  enum AssetType {
    ERC20,
    ERC721,
    ERC1155
  }

  bool public enabled = true;
  uint32 public maxAssetsPerPackage = 10;
  uint256 public createServiceFeeETH = 1 ether / 100; // 0.01 ETH
  uint256 public poolAddFeePerc = (PERC_DEN * 1) / 100; // 1%
  uint256 public buyPackageFeePerc = (PERC_DEN * 1) / 100; // 1%
  uint256 public addOfferFee = 1 ether / 1000; // 0.001 ETH
  address public treasury;
  IFeeReducer public feeReducer;
  IWETH public weth;
  otcYDF public otcNFT;

  // ERC20 token => amount volume
  mapping(address => uint256) public totalVolume;
  // ERC20 token => whether it's valid
  mapping(address => bool) public validOfferERC20;
  address[] _validOfferTokens;
  mapping(address => uint256) _validOfferTokensIdx;

  struct OTC {
    address creator;
    bool isPool;
    Package package;
    Pool pool;
  }

  struct Asset {
    address assetContract; // address(0) means native
    AssetType assetType;
    uint256 amount; // ERC20 or native
    uint256 id; // For ERC721 will be tokenId, for ERC1155 will be asset ID
  }

  struct Package {
    Asset[] assets;
    uint256 creationTime;
    uint256 unlockStart; // if > 0, specified when ERC20/native begins vesting and can begin being withdrawn
    uint256 unlockEnd; // if > 0, ERC20/native will support continuous vesting until this date
    uint256 lastWithdraw;
    // NOTE: if buyItNowAmount > 0, the package can be
    // bought immediately if another user offers this asset/amount combo.
    // Make sure it's an appropriate amount.
    address buyItNowAsset;
    uint256 buyItNowAmount;
    address buyItNowWhitelist; // if present, is the only address that can buy this package instantly
  }

  struct PkgOffer {
    address owner;
    address assetContract; // address(0) == ETH/native
    uint256 amount;
    uint256 timestamp;
    uint256 expiration;
  }

  // One-way OTC ERC20 pool where a creator can deposit token0 and users can
  // purchase token0 at price18 specified by creator w/ no slippage.
  // Users can only purchase token0 by sending token1 and will receive
  // token0 based on price18 provided
  struct Pool {
    address token0; // ERC20
    address token1; // ERC20
    uint256 amount0Deposited;
    uint256 amount0Remaining;
    uint256 amount1Deposited;
    uint256 price18; // amount1 * 10**18 / amount0
  }

  // tokenId => OTC
  mapping(uint256 => OTC) public otcs;
  // tokenId[]
  uint256[] public allOTCs;
  // tokenId => allOTCs index
  mapping(uint256 => uint256) internal _otcsIndexed;
  // tokenId => PkgOffer[]
  mapping(uint256 => PkgOffer[]) public pkgOffers;
  // address => sourceTokenId => targetTokenId
  mapping(address => mapping(uint256 => uint256)) public userOtcTradeWhitelist;

  event CreatePool(
    uint256 indexed tokenId,
    address indexed user,
    address token0,
    address token1,
    uint256 amount0,
    uint256 amount0LessFee,
    uint256 price18
  );
  event UpdatePool(
    uint256 indexed tokenId,
    address indexed owner,
    uint256 newPrice18,
    uint256 amount0Adding,
    bool withdrawToken1
  );
  event RemovePool(uint256 indexed tokenId, address indexed owner);
  event SwapPool(
    uint256 indexed tokenId,
    address indexed swapper,
    address token0,
    uint256 token0Amount,
    address token1,
    uint256 token1Amount
  );
  event CreatePackage(
    uint256 indexed tokenId,
    address indexed user,
    uint256 numberAssets
  );
  event WithdrawFromPackage(uint256 indexed tokenId, address indexed user);
  event AddPackageOffer(
    uint256 indexed tokenId,
    address indexed offerer,
    address offerAsset,
    uint256 offerAmount
  );
  event AcceptPackageOffer(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    uint256 numAssetsInOffer
  );
  event RemovePackageOffer(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    uint256 offerIndex
  );
  event BuyItNow(
    uint256 indexed tokenId,
    address indexed pkgOwner,
    address buyer,
    address buyToken,
    uint256 amount
  );
  event Trade(
    address indexed user1,
    address indexed user2,
    uint256 user1TokenIdSent,
    uint256 user2TokenIdSent
  );

  modifier onlyNFT() {
    require(msg.sender == address(otcNFT), 'ONLYNFT');
    _;
  }

  constructor(IWETH _weth, string memory _baseTokenURI) {
    weth = _weth;
    otcNFT = new otcYDF(_baseTokenURI);
    otcNFT.transferOwnership(msg.sender);
  }

  function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /* tokenId */
    bytes calldata /* data */
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function getAllValidOfferTokens() external view returns (address[] memory) {
    return _validOfferTokens;
  }

  function getAllActiveOTCTokenIds() external view returns (uint256[] memory) {
    return allOTCs;
  }

  function getAllPackageOffers(uint256 _tokenId)
    external
    view
    returns (PkgOffer[] memory)
  {
    return pkgOffers[_tokenId];
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

  function poolCreate(
    address _token0,
    address _token1,
    uint256 _amount0,
    uint256 _price18
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'POOLCR: enabled');
    require(_amount0 > 0, 'POOLCR: need to provide amount0');
    require(_price18 > 0, 'POOLCR: need valid price');
    // at least one token in the pool needs to be a valid ERC20
    require(
      _token0 != address(0) || _token1 != address(0),
      'POOLCR: invalid pool'
    );
    uint256 _poolFee = (_amount0 * poolAddFeePerc) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
    if (_percentOff > 0) {
      _poolFee -= (_poolFee * _percentOff) / _percOffDenom;
    }
    uint256 _amount0LessFee = _amount0 - _poolFee;

    _sendETHOrERC20(
      msg.sender,
      address(this),
      _token0,
      _token0 == address(0) ? _amount0 + createServiceFeeETH : _amount0
    );
    require(
      _token1 == address(0) || IERC20(_token1).totalSupply() > 0,
      'POOLCR: token1 validate'
    );

    if (_poolFee > 0) {
      _sendETHOrERC20(address(this), _getTreasury(), _token0, _poolFee);
    }

    if (createServiceFeeETH > 0) {
      require(msg.value >= createServiceFeeETH, 'POOLCR: service fee ETH');
      _sendETHOrERC20(
        address(this),
        _getTreasury(),
        address(0),
        createServiceFeeETH
      );
    }

    uint256 _tokenId = otcNFT.mint(msg.sender);

    OTC storage _otc = otcs[_tokenId];
    Pool storage _newPool = _otc.pool;

    _newPool.token0 = _token0;
    _newPool.token1 = _token1;
    _newPool.amount0Deposited = _amount0LessFee;
    _newPool.amount0Remaining = _amount0LessFee;
    _newPool.price18 = _price18;

    _otc.creator = msg.sender;
    _otc.isPool = true;

    otcNFT.approveOverTheCounter(_tokenId);

    _otcsIndexed[_tokenId] = allOTCs.length;
    allOTCs.push(_tokenId);
    emit CreatePool(
      _tokenId,
      msg.sender,
      _token0,
      _token1,
      _amount0,
      _amount0LessFee,
      _price18
    );
  }

  function poolUpdate(
    uint256 _tokenId,
    uint256 _newPrice18,
    uint256 _amount0ToAdd,
    bool _withdrawToken1
  ) external payable nonReentrant {
    Pool storage _pool = otcs[_tokenId].pool;
    require(msg.sender == otcNFT.ownerOf(_tokenId), 'POOLUPD: owner');

    if (_newPrice18 > 0 && _pool.price18 != _newPrice18) {
      _pool.price18 = _newPrice18;
    }

    if (_amount0ToAdd > 0) {
      uint256 _poolFee = (_amount0ToAdd * poolAddFeePerc) / PERC_DEN;
      (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
      if (_percentOff > 0) {
        _poolFee -= (_poolFee * _percentOff) / _percOffDenom;
      }
      uint256 _amount0LessFee = _amount0ToAdd - _poolFee;

      if (_amount0LessFee > 0) {
        _pool.amount0Deposited += _amount0LessFee;
        _sendETHOrERC20(
          msg.sender,
          address(this),
          _pool.token0,
          _amount0LessFee
        );
      }
    }

    if (_withdrawToken1 && _pool.amount1Deposited > 0) {
      uint256 _amount1ToWithdraw = _pool.amount1Deposited;
      _pool.amount1Deposited = 0;
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token1,
        _amount1ToWithdraw
      );
    }

    emit UpdatePool(
      _tokenId,
      msg.sender,
      _newPrice18,
      _amount0ToAdd,
      _withdrawToken1
    );
  }

  function poolRemove(uint256 _tokenId) external nonReentrant {
    Pool memory _pool = otcs[_tokenId].pool;
    require(msg.sender == otcNFT.ownerOf(_tokenId), 'POOLRM: owner');
    // at least one token in the pool needs to be a valid ERC20
    require(
      _pool.token0 != address(0) || _pool.token1 != address(0),
      'POOLRM: invalid pool'
    );

    _deleteOTC(_tokenId);

    // send remaining token0 to pool owner
    if (_pool.amount0Remaining > 0) {
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token0,
        _pool.amount0Remaining
      );
    }

    // send remaining token1 to pool owner
    if (_pool.amount1Deposited > 0) {
      _sendETHOrERC20(
        address(this),
        msg.sender,
        _pool.token1,
        _pool.amount1Deposited
      );
    }
    emit RemovePool(_tokenId, msg.sender);
  }

  function swapPool(uint256 _tokenId, uint256 _amount1Provided)
    external
    payable
    nonReentrant
  {
    require(enabled || msg.sender == owner(), 'POOLSW: enabled');
    Pool storage _pool = otcs[_tokenId].pool;
    _pool.amount1Deposited += _amount1Provided;

    // validate enough token0 assets in pool to swap based on _amount1Provided and price
    uint256 _amount0ToSend = (_amount1Provided * 10**(18 * 2)) /
      _pool.price18 /
      10**18;
    require(_pool.amount0Remaining >= _amount0ToSend, 'POOLSW: token0 liq');
    _pool.amount0Remaining -= _amount0ToSend;

    // receive token0 from user who is swapping
    _sendETHOrERC20(msg.sender, address(this), _pool.token1, _amount1Provided);

    // send token0 to user who is swapping
    _sendETHOrERC20(address(this), msg.sender, _pool.token0, _amount0ToSend);

    totalVolume[_pool.token0] += _amount0ToSend;
    emit SwapPool(
      _tokenId,
      msg.sender,
      _pool.token0,
      _amount0ToSend,
      _pool.token1,
      _amount1Provided
    );
  }

  function packageCreate(
    // OTC asset(s) info
    Asset[] memory _assets,
    // OTC package info
    uint256 _unlockStart,
    uint256 _unlockEnd,
    address _buyItNowAsset,
    uint256 _buyItNowAmount,
    address _buyItNowWhitelist
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'PKGCR: enabled');
    require(_assets.length <= maxAssetsPerPackage, 'PKGCR: max assets');
    require(
      _buyItNowAsset == address(0) || validOfferERC20[_buyItNowAsset],
      'PKGCR: asset not valid'
    );

    uint256 _tokenId = otcNFT.mint(msg.sender);

    OTC storage _otc = otcs[_tokenId];
    Package storage _newPkg = _otc.package;

    uint256 _nativeCheck;
    for (uint256 _i; _i < _assets.length; _i++) {
      if (_assets[_i].assetContract == address(0)) {
        _nativeCheck += _assets[_i].amount;
      }
      _validateAndSupplyPackageAsset(msg.sender, _assets[_i]);

      Asset memory _newAsset = Asset({
        assetContract: _assets[_i].assetContract,
        assetType: _assets[_i].assetType,
        amount: _assets[_i].amount,
        id: _assets[_i].id
      });
      _newPkg.assets.push(_newAsset);
    }
    require(
      msg.value >= _nativeCheck + createServiceFeeETH,
      'PKGCR: ETH assets plus service'
    );
    if (createServiceFeeETH > 0) {
      _sendETHOrERC20(
        address(this),
        _getTreasury(),
        address(0),
        createServiceFeeETH
      );
    }

    require(
      (_unlockEnd == 0 && _unlockStart == 0) ||
        (_unlockEnd != 0 && _unlockStart != 0 && _unlockEnd > _unlockStart),
      'PKGCR: validate unlock period'
    );

    _newPkg.creationTime = block.timestamp;
    _newPkg.unlockStart = _unlockStart;
    _newPkg.unlockEnd = _unlockEnd;
    _newPkg.buyItNowAsset = _buyItNowAsset;
    _newPkg.buyItNowAmount = _buyItNowAmount;
    _newPkg.buyItNowWhitelist = _buyItNowWhitelist;

    _otc.creator = msg.sender;
    _otc.package = _newPkg;

    otcNFT.approveOverTheCounter(_tokenId);

    _otcsIndexed[_tokenId] = allOTCs.length;
    allOTCs.push(_tokenId);
    emit CreatePackage(_tokenId, msg.sender, _assets.length);
  }

  function packageWithdrawal(uint256 _tokenId) external nonReentrant {
    _packageWithdrawal(msg.sender, _tokenId);
  }

  function addPackageOffer(
    uint256 _tokenId,
    address _offerAsset,
    uint256 _assetAmount,
    uint256 _expiration
  ) external payable {
    require(enabled || msg.sender == owner(), 'PKGOFF: enabled');
    PkgOffer storage _newOffer = pkgOffers[_tokenId].push();
    _newOffer.owner = msg.sender;
    _newOffer.timestamp = block.timestamp;

    address _finalOfferToken;
    uint256 _finalOfferAmount;
    if (_offerAsset == address(0)) {
      require(msg.value > addOfferFee, 'PKGOFF: need ETH');
      require(validOfferERC20[address(weth)], 'PKGOFF: WETH not valid');

      uint256 _ethOfferAmount = msg.value - addOfferFee;
      IERC20 _wethIERC20 = IERC20(address(weth));
      uint256 _wethBalBefore = _wethIERC20.balanceOf(address(this));
      weth.deposit{ value: _ethOfferAmount }();
      _wethIERC20.transfer(
        msg.sender,
        _wethIERC20.balanceOf(address(this)) - _wethBalBefore
      );

      _finalOfferToken = address(weth);
      _finalOfferAmount = (_ethOfferAmount * 10**weth.decimals()) / 10**18;
    } else {
      require(msg.value == addOfferFee, 'PKGOFF: offer fee');
      require(validOfferERC20[_offerAsset], 'PKGOFF: invalid offer token');
      _finalOfferToken = _offerAsset;
      _finalOfferAmount = _assetAmount;
    }

    if (addOfferFee > 0) {
      _sendETHOrERC20(address(this), _getTreasury(), address(0), addOfferFee);
    }

    IERC20 _offTokenCont = IERC20(_finalOfferToken);
    require(
      _offTokenCont.balanceOf(msg.sender) >= _finalOfferAmount,
      'PKGOFF: bad balance'
    );
    require(
      _offTokenCont.allowance(msg.sender, address(this)) >= _finalOfferAmount,
      'PKGOFF: need allowance'
    );

    _newOffer.assetContract = _finalOfferToken;
    _newOffer.amount = _finalOfferAmount;
    _newOffer.expiration = _expiration;
    emit AddPackageOffer(
      _tokenId,
      msg.sender,
      _finalOfferToken,
      _finalOfferAmount
    );
  }

  function acceptPackageOffer(
    uint256 _tokenId,
    uint256 _offerIndex,
    address _offerAssetCheck,
    uint256 _offerAmountCheck
  ) external nonReentrant {
    require(enabled || msg.sender == owner(), 'ACCEPTOFF: enabled');
    require(otcNFT.ownerOf(_tokenId) == msg.sender, 'ACCEPTOFF: owner');

    PkgOffer memory _offer = pkgOffers[_tokenId][_offerIndex];
    require(_offer.assetContract == _offerAssetCheck, 'ACCEPTOFF: bad asset');
    require(_offer.amount == _offerAmountCheck, 'ACCEPTOFF: bad amount');
    require(
      _offer.expiration == 0 || _offer.expiration > block.timestamp,
      'ACCEPTOFF: expired'
    );

    uint256 _buyFee = (_offer.amount * buyPackageFeePerc) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenom) = getFeeDiscount(msg.sender);
    if (_percentOff > 0) {
      _buyFee -= (_buyFee * _percentOff) / _percOffDenom;
    }
    uint256 _remainingAmount = _offer.amount - _buyFee;

    if (_buyFee > 0) {
      _sendETHOrERC20(
        _offer.owner,
        _getTreasury(),
        _offer.assetContract,
        _buyFee
      );
    }
    _sendETHOrERC20(
      _offer.owner,
      msg.sender,
      _offer.assetContract,
      _remainingAmount
    );
    otcNFT.safeTransferFrom(msg.sender, _offer.owner, _tokenId);
    otcNFT.approveOverTheCounter(_tokenId);
    pkgOffers[_tokenId][_offerIndex] = pkgOffers[_tokenId][
      pkgOffers[_tokenId].length - 1
    ];
    pkgOffers[_tokenId].pop();
    totalVolume[_offer.assetContract] += _offer.amount;
    emit AcceptPackageOffer(_tokenId, msg.sender, _offerIndex);
  }

  function removePackageOffer(uint256 _tokenId, uint256 _offerIndex)
    external
    nonReentrant
  {
    PkgOffer memory _offer = pkgOffers[_tokenId][_offerIndex];
    require(
      otcNFT.ownerOf(_tokenId) == msg.sender || _offer.owner == msg.sender,
      'REJECTOFF: owner'
    );

    pkgOffers[_tokenId][_offerIndex] = pkgOffers[_tokenId][
      pkgOffers[_tokenId].length - 1
    ];
    pkgOffers[_tokenId].pop();
    emit RemovePackageOffer(_tokenId, msg.sender, _offerIndex);
  }

  function buyItNow(
    uint256 _tokenId,
    address _buyItNowToken,
    uint256 _buyItNowAmount,
    bool _unpack
  ) external payable nonReentrant {
    require(enabled || msg.sender == owner(), 'BIN: enabled');
    address _owner = otcNFT.ownerOf(_tokenId);
    Package memory _pkg = otcs[_tokenId].package;
    require(_pkg.buyItNowAmount > 0, 'BIN: not configured');
    require(_pkg.buyItNowAsset == _buyItNowToken, 'BIN: bad token');
    require(_pkg.buyItNowAmount == _buyItNowAmount, 'BIN: bad amount');
    if (_pkg.buyItNowWhitelist != address(0)) {
      require(msg.sender == _pkg.buyItNowWhitelist, 'BIN: not whitelisted');
    }

    uint256 _buyFee = (_pkg.buyItNowAmount * buyPackageFeePerc) / PERC_DEN;
    uint256 _remainingAmount = _pkg.buyItNowAmount - _buyFee;
    address _from = msg.sender;
    if (_pkg.buyItNowAsset == address(0)) {
      _from = address(this);
      require(msg.value == _buyItNowAmount, 'BIN: not enough ETH');
    }
    if (_buyFee > 0) {
      _sendETHOrERC20(_from, _getTreasury(), _pkg.buyItNowAsset, _buyFee);
    }
    _sendETHOrERC20(_from, _owner, _pkg.buyItNowAsset, _remainingAmount);

    otcNFT.safeTransferFrom(_owner, msg.sender, _tokenId);
    otcNFT.approveOverTheCounter(_tokenId);
    totalVolume[_pkg.buyItNowAsset] += _pkg.buyItNowAmount;

    // unpack now if buying user would like
    if (_unpack) {
      _packageWithdrawal(msg.sender, _tokenId);
    }

    emit BuyItNow(
      _tokenId,
      _owner,
      msg.sender,
      _buyItNowToken,
      _buyItNowAmount
    );
  }

  function updatePackageInfo(
    uint256 _tokenId,
    uint256 _unlockStart,
    uint256 _unlockEnd,
    address _buyItNowAsset,
    uint256 _buyItNowAmount,
    address _buyItNowWhitelist
  ) external nonReentrant {
    require(otcNFT.ownerOf(_tokenId) == msg.sender, 'UDPATEPKG: owner');
    require(
      _buyItNowAsset == address(0) || validOfferERC20[_buyItNowAsset],
      'UPDATEPKG: asset not valid'
    );
    Package storage _pkg = otcs[_tokenId].package;
    _pkg.buyItNowAsset = _buyItNowAsset;
    _pkg.buyItNowAmount = _buyItNowAmount;
    _pkg.buyItNowWhitelist = _buyItNowWhitelist;

    // can only update unlock info if OTC package creator
    if (msg.sender == otcs[_tokenId].creator) {
      _pkg.unlockStart = _unlockStart;
      _pkg.unlockEnd = _unlockEnd;
    }
  }

  function tradeOTC(uint256 _sourceTokenId, uint256 _desiredTokenId)
    external
    nonReentrant
  {
    require(
      otcNFT.ownerOf(_sourceTokenId) == msg.sender,
      'TRADE: bad source owner'
    );
    // short circuit if the user is just removing the trade flag
    if (_desiredTokenId == 0) {
      delete userOtcTradeWhitelist[msg.sender][_sourceTokenId];
      return;
    }

    userOtcTradeWhitelist[msg.sender][_sourceTokenId] = _desiredTokenId;
    address _desiredOwner = otcNFT.ownerOf(_desiredTokenId);
    if (
      userOtcTradeWhitelist[_desiredOwner][_desiredTokenId] == _sourceTokenId
    ) {
      otcNFT.transferFrom(msg.sender, _desiredOwner, _sourceTokenId);
      otcNFT.transferFrom(_desiredOwner, msg.sender, _desiredTokenId);
      otcNFT.approveOverTheCounter(_sourceTokenId);
      otcNFT.approveOverTheCounter(_desiredTokenId);

      delete userOtcTradeWhitelist[msg.sender][_sourceTokenId];
      delete userOtcTradeWhitelist[_desiredOwner][_desiredTokenId];

      emit Trade(msg.sender, _desiredOwner, _sourceTokenId, _desiredTokenId);
    }
  }

  function _packageWithdrawal(address _authdUser, uint256 _tokenId) internal {
    OTC storage _otc = otcs[_tokenId];
    Package storage _pkg = _otc.package;
    address _user = otcNFT.ownerOf(_tokenId);
    require(_authdUser == _user, 'PKGWITH: owner');
    require(_pkg.assets.length > 0, 'PKGWITH: invalid package');

    for (uint256 _i; _i < _pkg.assets.length; _i++) {
      _withdrawAssetFromPackage(_user, _tokenId, _i);
    }
    _pkg.lastWithdraw = block.timestamp;

    if (
      _otc.creator == _user ||
      _pkg.unlockEnd == 0 ||
      block.timestamp >= _pkg.unlockEnd
    ) {
      _deleteOTC(_tokenId);
    }
    emit WithdrawFromPackage(_tokenId, _user);
  }

  function _validateAndSupplyPackageAsset(address _user, Asset memory _asset)
    internal
  {
    if (_asset.assetType == AssetType.ERC20) {
      // ETH or ERC20
      _sendETHOrERC20(
        _user,
        address(this),
        _asset.assetContract,
        _asset.amount
      );
    } else if (_asset.assetType == AssetType.ERC721) {
      // ERC721
      require(_asset.id > 0, 'VALIDPKG: token ID');
      IERC721(_asset.assetContract).safeTransferFrom(
        _user,
        address(this),
        _asset.id
      );
    } else {
      // ERC1155
      IERC1155(_asset.assetContract).safeTransferFrom(
        _user,
        address(this),
        _asset.id,
        _asset.amount,
        ''
      );
    }
  }

  function _withdrawAssetFromPackage(
    address _withdrawer,
    uint256 _tokenId,
    uint256 _assetIdx
  ) internal {
    Package storage _package = otcs[_tokenId].package;
    Asset storage _asset = _package.assets[_assetIdx];
    uint256 _amountCache = _asset.amount;

    if (
      otcs[_tokenId].creator != _withdrawer &&
      _package.unlockEnd > 0 &&
      block.timestamp < _package.unlockEnd
    ) {
      // if it's NFT, short circuit as it cannot be withdrawn until unlock period is over
      if (_asset.assetType == AssetType.ERC721) {
        return;
      }
      uint256 _fullVestingPeriod = _package.unlockEnd - _package.unlockStart;
      uint256 _lastWithdraw = _package.lastWithdraw > 0
        ? _package.lastWithdraw
        : _package.unlockStart > 0
        ? _package.unlockStart
        : _package.creationTime;
      _amountCache =
        ((block.timestamp - _lastWithdraw) * _amountCache) /
        _fullVestingPeriod;
      // if there is nothing to withdraw for this asset, short circuit
      if (_amountCache == 0) {
        return;
      }

      _asset.amount -= _amountCache;
    } else {
      _asset.amount = 0;
    }

    if (_asset.assetType == AssetType.ERC20) {
      _sendETHOrERC20(
        address(this),
        _withdrawer,
        _asset.assetContract,
        _amountCache
      );
    } else if (_asset.assetType == AssetType.ERC721) {
      IERC721(_asset.assetContract).safeTransferFrom(
        address(this),
        _withdrawer,
        _asset.id
      );
    } else {
      // ERC1155
      IERC1155(_asset.assetContract).safeTransferFrom(
        address(this),
        _withdrawer,
        _asset.id,
        _amountCache,
        ''
      );
    }
  }

  function _sendETHOrERC20(
    address _source,
    address _target,
    address _token,
    uint256 _amount
  ) internal {
    if (_token == address(0)) {
      if (_target == address(this)) {
        require(msg.value >= _amount, 'SEND: not enough ETH');
      } else {
        require(_source == address(this), 'SEND: bad source');
        uint256 _balBefore = address(this).balance;
        (bool _sent, ) = payable(_target).call{ value: _amount }('');
        require(_sent, 'SEND: could not send');
        require(address(this).balance >= _balBefore - _amount, 'SEND: ETH');
      }
    } else {
      // NOTE: tokens w/ taxes on transfer should whitelist this OTC
      // contract as we don't want end users to experience unexpected
      // results by losing tokens as they're moving between here and their wallet
      IERC20 _cont = IERC20(_token);
      uint256 _tokenBalBefore = _cont.balanceOf(_target);
      if (_source == address(this)) {
        _cont.safeTransfer(_target, _amount);
      } else {
        _cont.safeTransferFrom(_source, _target, _amount);
      }
      require(
        _cont.balanceOf(_target) >= _amount + _tokenBalBefore,
        'SEND: ERC20 amount'
      );
    }
  }

  function _deleteOTC(uint256 _tokenId) internal {
    otcNFT.burn(_tokenId);
    uint256 _deletingOTCIndex = _otcsIndexed[_tokenId];
    uint256 _tokenIdMoving = allOTCs[allOTCs.length - 1];
    delete _otcsIndexed[_tokenId];
    _otcsIndexed[_tokenIdMoving] = _deletingOTCIndex;
    allOTCs[_deletingOTCIndex] = _tokenIdMoving;
    allOTCs.pop();
  }

  function _getTreasury() internal view returns (address) {
    return treasury == address(0) ? owner() : treasury;
  }

  function turnOffPackageTrading(uint256 _tokenId) external onlyNFT {
    otcs[_tokenId].package.buyItNowAmount = 0;
  }

  function setFeeReducer(IFeeReducer _reducer) external onlyOwner {
    feeReducer = _reducer;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setMaxAssetsPerPackage(uint8 _max) external onlyOwner {
    maxAssetsPerPackage = _max;
  }

  function setServiceFeeETH(uint256 _wei) external onlyOwner {
    createServiceFeeETH = _wei;
  }

  function setPoolAddFeePerc(uint256 _percent) external onlyOwner {
    require(_percent <= (PERC_DEN * 25) / 100, 'must be less than 25%');
    poolAddFeePerc = _percent;
  }

  function setBuyPackageFeePerc(uint256 _percent) external onlyOwner {
    require(_percent <= (PERC_DEN * 20) / 100, 'must be less than 20%');
    buyPackageFeePerc = _percent;
  }

  function setAddOfferFee(uint256 _wei) external onlyOwner {
    addOfferFee = _wei;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    require(enabled != _enabled, 'SETENABLED: toggle');
    enabled = _enabled;
  }

  function updateValidOfferToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(validOfferERC20[_token] != _isValid, 'must toggle');
    validOfferERC20[_token] = _isValid;
    if (_isValid) {
      _validOfferTokensIdx[_token] = _validOfferTokens.length;
      _validOfferTokens.push(_token);
    } else {
      uint256 _idx = _validOfferTokensIdx[_token];
      delete _validOfferTokensIdx[_token];
      _validOfferTokens[_idx] = _validOfferTokens[_validOfferTokens.length - 1];
      _validOfferTokens.pop();
    }
  }
}

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity ^0.8.16;

interface IFeeReducer {
  function percentDiscount(address wallet)
    external
    view
    returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
  function decimals() external view returns (uint8);

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IOverTheCounterSlim.sol';

contract otcYDF is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  address public overTheCounter;

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

  event Burn(uint256 indexed tokenId, address indexed owner);
  event Mint(uint256 indexed tokenId, address indexed owner);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  modifier onlyOTC() {
    require(msg.sender == overTheCounter, 'only OTC');
    _;
  }

  constructor(string memory _baseTokenURI)
    ERC721('Yieldification OTC', 'otcYDF')
  {
    baseTokenURI = _baseTokenURI;
    overTheCounter = msg.sender;
  }

  function mint(address owner) external onlyOTC returns (uint256) {
    _ids.increment();
    _safeMint(owner, _ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;
    emit Mint(_ids.current(), owner);
    return _ids.current();
  }

  function burn(uint256 _tokenId) external onlyOTC {
    address _user = ownerOf(_tokenId);
    require(_exists(_tokenId));
    _burn(_tokenId);
    emit Burn(_tokenId, _user);
  }

  function approveOverTheCounter(uint256 _tokenId) external onlyOTC {
    _approve(overTheCounter, _tokenId);
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

  function setPerpetualFutures(address _otc) external onlyOwner {
    overTheCounter = _otc;
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

    // if this package is just moving wallets, turn off trading
    // so the new wallet can control if/when they would like to trade
    if (_from != address(0) && _to != address(0)) {
      IOverTheCounterSlim(overTheCounter).turnOffPackageTrading(_tokenId);
    }

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity ^0.8.16;

interface IOverTheCounterSlim {
  function turnOffPackageTrading(uint256 tokenId) external;
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