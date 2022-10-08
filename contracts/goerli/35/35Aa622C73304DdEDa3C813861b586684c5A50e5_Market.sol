// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import './libraries/Detector.sol';
import './libraries/RentaFiSVG.sol';
import './libraries/Calculator.sol';
import './interfaces/IMarket.sol';
import './interfaces/IVault.sol';
import './interfaces/IERC20Detailed.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

//ERROR
error AlreadyReserved();
error overLimits();

contract Market is ERC721, ERC721Burnable, Ownable, ReentrancyGuard, Pausable, IMarket {
  using Counters for Counters.Counter;
  using SafeERC20 for IERC20;
  using Detector for address;

  constructor() ERC721('RentaFi Yield NFT', 'RentaFi-YN') {}

  /*************
   *  STORAGE  *
   *************/

  /** PRIVATE */
  uint256 private constant E5 = 1e5;
  Counters.Counter private totalLended;
  Counters.Counter private totalRented;

  /** PUBLIC */
  uint256 public protocolAdminFeeRatio = 10 * 1000;
  uint256 public reservationLimits = 10;

  // whitelisted vault list
  address[] internal vaults;

  // lockId => LendRent
  mapping(uint256 => LendRent) public lendRent;
  // vaultAddress => allowed
  mapping(address => uint256) public vaultWhiteList;
  // lockId => paymentToken =>lenderBenefit
  mapping(uint256 => mapping(address => uint256)) public lenderBenefit; //TODO ユーザーがそれぞれのトークンでいくら収益を持っているかを取得する
  // vaultAddress => paymentToken =>collectionOwnerBenefit
  mapping(address => mapping(address => uint256)) public collectionOwnerBenefit;
  // paymentToken => protocolAdminBenefit
  mapping(address => uint256) public protocolAdminBenefit;
  // paymentToken => uint256 as a bool
  mapping(address => uint256) public paymentTokenWhiteList; //NOTE: paymentTokenの配列を削除しました

  /**************
   *  MODIFIER  *
   **************/
  modifier onlyLender(uint256 _lockId) {
    require(lendRent[_lockId].lend.lender == msg.sender, 'OnlyLender');
    _;
  }

  modifier onlyPayoutAddress(address _vaultAddress) {
    require(msg.sender == IVault(_vaultAddress).payoutAddress(), 'onlyPayoutAddress');
    _;
  }

  modifier onlyProtocolAdmin() {
    require(owner() == msg.sender, 'onlyProtocolAdmin');
    _;
  }

  modifier onlyONftOwner(uint256 _lockId) {
    require(IVault(lendRent[_lockId].lend.vault).ownerOf(_lockId) == msg.sender, 'onlyONftOwner');
    _;
  }

  modifier onlyYNftOwner(uint256 _lockId) {
    require(ownerOf(_lockId) == msg.sender, 'onlyYNftOwner');
    _;
  }

  modifier onlyBeforeLock(uint256 _lockId) {
    require(
      lendRent[_lockId].rent.length == 0 ||
        lendRent[_lockId].lend.lockStartTime == lendRent[_lockId].lend.lockExpireTime,
      'onlyBeforeLock'
    );
    _;
  }

  modifier onlyAfterLockExpired(uint256 _lockId) {
    require(block.timestamp > lendRent[_lockId].lend.lockExpireTime, 'onlyAfterLockExpired');
    _;
  }

  modifier onlyNotRentaled(uint256 _lockId) {
    Rent[] storage _rents = lendRent[_lockId].rent;
    /*unchecked {
      for (uint256 i; i < _rents.length; i++)
        _deleteLockId(renterLockIds, _rents[i].renterAddress, _lockId);
    }*/
    _deleteExpiredRent(_rents);
    require(_rents.length == 0, 'onlyNotRentaled');
    _;
  }

  /**********************
   * EXTERNAL FUNCTIONS *
   **********************/

  // Deposit the NFT into an escrow contract.
  function mintAndCreateList(
    uint256 _tokenId, // ID of the NFT you wish to loan out
    uint256 _lockDuration, // days
    uint256 _minRentalDuration, // days
    uint256 _maxRentalDuration, // days
    uint256 _amount, // token amount (only in the case of ERC1155)
    uint256 _dailyRentalPrice,
    address _privateAddress,
    address _vaultAddress, //The Vault address corresponding to the collection you wish to loan out
    address _paymentToken,
    PaymentMethod _paymentMethod
  ) external whenNotPaused {
    require(_amount > 0, 'NotZero');
    require(_lockDuration == 0 || _lockDuration >= _minRentalDuration, 'lockDur<minRentalDur');
    require(_lockDuration == 0 || _maxRentalDuration <= _lockDuration, 'maxRentDur>lockDur');
    require(_minRentalDuration <= _maxRentalDuration, 'minRentalDur>maxRentalDur');
    require(vaultWhiteList[_vaultAddress] >= 1, 'Notwhitelisted');
    require(IVault(_vaultAddress).getTokenIdAllowed(_tokenId), 'NotAllowedId');
    require(
      IVault(_vaultAddress).minPrices(_paymentToken) <= _dailyRentalPrice,
      'dailyRentPrice<min'
    );
    require(IVault(_vaultAddress).minDuration() <= _minRentalDuration, 'minRentDur<minDur');
    require(IVault(_vaultAddress).maxDuration() >= _maxRentalDuration, 'maxRentDur>maxDur');
    require(_isPaymentTokenAllowed(_vaultAddress, _paymentToken) >= 1, 'NotAllowedToken'); //NOTE: この内部関数をいじってます

    totalLended.increment();
    uint256 _lockId = totalLended.current();

    _createList(
      _lockId,
      _tokenId,
      _lockDuration,
      _minRentalDuration,
      _maxRentalDuration,
      _amount,
      _dailyRentalPrice,
      _privateAddress,
      _vaultAddress,
      _paymentToken,
      _paymentMethod
    );

    // To avoid error below, mint NFTs after creating the list
    // CompilerError: Stack too deep, try removing local variables.
    _mintNft(_lockId, _lockDuration);
  }

  // Lending process: On the vault side, process whether to send originalNFT or wrapNFT as mint.
  function rent(
    uint256 _lockId,
    uint256 _rentalStartTimestamp, // If zero, rent now
    uint256 _rentalDurationByDay,
    uint256 _amount
  ) external payable whenNotPaused nonReentrant {
    if (_rentalStartTimestamp > (block.timestamp + reservationLimits)) revert overLimits();

    Lend memory _lend = lendRent[_lockId].lend;

    {
      address _privateAddress = _lend.privateAddress;
      if (!(_privateAddress == address(0) || msg.sender == _privateAddress))
        revert AlreadyReserved();
    }

    _calcFee(
      _lockId,
      _lend.dailyRentalPrice,
      _lend.lockStartTime,
      _lend.lockExpireTime,
      _lend.lender,
      _rentalDurationByDay,
      _amount,
      _lend.vault,
      _lend.paymentToken
    );

    (uint256 _rentalStartTime, uint256 _rentalExpireTime) = Calculator.duration(
      _rentalStartTimestamp,
      _rentalDurationByDay,
      _lend.lockStartTime,
      _lend.lockExpireTime,
      _lend.maxRentalDuration,
      _lend.minRentalDuration
    );

    totalRented.increment();
    uint256 _rentId = totalRented.current();

    Rent memory _rent = Rent({
      renterAddress: msg.sender,
      rentId: _rentId,
      rentalStartTime: _rentalStartTime,
      rentalExpireTime: _rentalExpireTime,
      amount: _amount
    });

    _updateRent(_lend.vault, _lockId, _lend, _rent);

    // Pseudo Transfer WrappedNFT (if it starts later, only booking)
    IVault(_lend.vault).mintWNft(
      msg.sender,
      _rentalStartTime,
      _rentalExpireTime,
      _lockId,
      _lend.tokenId,
      _amount
    );

    emit Rented(_rentId, msg.sender, _lockId, _rent);
  }

  function activate(uint256 _lockId, uint256 _rentId) external {
    Rent[] memory _rents = lendRent[_lockId].rent;
    uint256 _rentsLength = _rents.length;
    for (uint256 i; i < _rentsLength; ) {
      if (_rents[i].rentId == _rentId)
        IVault(lendRent[_lockId].lend.vault).activate(
          _rentId,
          _lockId,
          msg.sender,
          _rents[i].amount
        );
      unchecked {
        i++;
      }
    }
  }

  function cancel(uint256 _lockId)
    external
    onlyLender(_lockId)
    onlyBeforeLock(_lockId)
    onlyNotRentaled(_lockId)
  {
    if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime)
      burn(_lockId); // burn yNFT
    _redeemNFT(_lockId); // burn oNFT and redeem original token
    emit Canceled(_lockId);
  }

  // Burn oNFT to execute an internal function that redeems the original NFT
  function claimNFT(uint256 _lockId)
    external
    onlyONftOwner(_lockId)
    onlyAfterLockExpired(_lockId)
    onlyNotRentaled(_lockId)
  {
    _redeemNFT(_lockId);
  }

  //for Lender
  function claimFee(uint256 _lockId) external onlyYNftOwner(_lockId) onlyAfterLockExpired(_lockId) {
    _claimFee(_lockId);
  }

  // NOTE: 変更なし
  // for Collection Owner
  function claimRoyalty(address _vaultAddress) external onlyPayoutAddress(_vaultAddress) {
    address[] memory _allowedPaymentTokens = IVault(_vaultAddress).getPaymentTokens();
    uint256 _allowedPaymentTokensLength = _allowedPaymentTokens.length;
    for (uint256 i; i < _allowedPaymentTokensLength; ) {
      uint256 _sendAmount = collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
      if (_allowedPaymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_allowedPaymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      delete collectionOwnerBenefit[_vaultAddress][_allowedPaymentTokens[i]];
      unchecked {
        i++;
      }
    }
    emit ClaimedRoyalty(IVault(_vaultAddress).originalCollection());
  }

  // NOTE: paymentToken配列を削除し、手動でトークンアドレスをバッチで渡すように処理を変更
  function claimProtocolFee(address[] calldata _paymentTokens) external onlyProtocolAdmin {
    uint256 _paymentTokensLength = _paymentTokens.length; //トレージから呼び出しではなく引数で渡すようにした
    for (uint256 i; i < _paymentTokensLength; ) {
      uint256 _sendAmount = protocolAdminBenefit[_paymentTokens[i]];
      if (_paymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_paymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      delete protocolAdminBenefit[_paymentTokens[i]];
      unchecked {
        i++;
      }
    }
  }

  function emergencyWithdraw(uint256 _lockId) external whenPaused onlyYNftOwner(_lockId) {
    _claimFee(_lockId);
  }

  /** GETTER FUNCTIONS */
  //TODO: 戻り値をboolではなく数量にすることを検討
  function checkAvailability(uint256 _lockId) external view returns (uint256) {
    uint256 _now = block.timestamp;
    return
      Detector.availability(
        IVault(lendRent[_lockId].lend.vault).originalCollection(),
        lendRent[_lockId].rent,
        lendRent[_lockId].lend,
        _now,
        _now
      );
  }

  // Getters that are set automatically do not return arrays in the structure, so this must be specified explicitly
  function getLendRent(uint256 _lockId) external view returns (LendRent memory) {
    return lendRent[_lockId];
  }

  function tokenURI(uint256 _lockId) public view override returns (string memory) {
    require(_exists(_lockId), 'ERC721Metadata: URI query for nonexistent token');

    // CHANGE STATE
    Lend memory _lend = lendRent[_lockId].lend;

    // TODO: This must be changed by deploying chain
    string memory _tokenSymbol = 'ETH';
    if (_lend.paymentToken != address(0))
      _tokenSymbol = IERC20Detailed(_lend.paymentToken).symbol();
    string memory _name = IVault(IVault(_lend.vault).originalCollection()).name();

    bytes memory json = RentaFiSVG.getYieldSVG(
      _lockId,
      _lend.tokenId,
      _lend.amount,
      lenderBenefit[_lockId][_lend.paymentToken],
      _lend.lockStartTime,
      _lend.lockExpireTime,
      IVault(_lend.vault).originalCollection(),
      _name,
      _tokenSymbol
    );
    string memory _tokenURI = string(
      abi.encodePacked('data:application/json;base64,', Base64.encode(json))
    );

    return _tokenURI;
  }

  /** PROTOCOL ADMIN FUNCTIONS */

  function setProtocolAdminFeeRatio(uint256 _protocolAdminFeeRatio) external onlyProtocolAdmin {
    if (_protocolAdminFeeRatio > 10 * 1000) revert overLimits();
    protocolAdminFeeRatio = _protocolAdminFeeRatio;
  }

  function setReservationLimit(uint256 _days) public onlyProtocolAdmin {
    reservationLimits = _days;
  }

  function setVaultWhiteList(address _vaultAddress, uint256 _allowed) external onlyProtocolAdmin {
    if (_allowed >= 1) {
      vaultWhiteList[_vaultAddress] = _allowed;
    } else {
      delete vaultWhiteList[_vaultAddress];
    }
    uint256 _exists;
    address[] memory local_vaults = vaults;
    uint256 local_vaultsLength = local_vaults.length;
    for (uint256 i; i < local_vaultsLength; ) {
      if (local_vaults[i] == _vaultAddress) {
        _exists = 1;
        break;
      }
      unchecked {
        i++;
      }
    }
    if (_exists < 1) vaults.push(_vaultAddress);
    emit WhiteListed(IVault(_vaultAddress).originalCollection(), _vaultAddress);
  }

  function setPaymentTokenWhiteList(address _token, uint256 _bool) external onlyProtocolAdmin {
    paymentTokenWhiteList[_token] = _bool;
  }

  function pause() external onlyProtocolAdmin {
    paused() ? _unpause() : _pause();
  }

  /*********************
   * PRIVATE FUNCTIONS *
   *********************/
  function _deleteExpiredRent(Rent[] storage _rents) private {
    for (uint256 i = 1; i <= _rents.length; ) {
      if (_rents[i - 1].rentalExpireTime < block.timestamp) {
        if (_rents[_rents.length - 1].rentalExpireTime >= block.timestamp) {
          _rents[i - 1] = _rents[_rents.length - 1];
        } else {
          i--;
        }
        _rents.pop();
      }
      unchecked {
        i++;
      }
    }
  }

  function _isPaymentTokenAllowed(address _vaultAddress, address _paymentToken)
    private
    view
    returns (uint256 _allowed)
  {
    _allowed = IVault(_vaultAddress).minPrices(_paymentToken);
  }

  function _claimFee(uint256 _lockId) private {
    address[] memory _allowedPaymentTokens = IVault(lendRent[_lockId].lend.vault)
      .getPaymentTokens();
    uint256 _allowedPaymentTokensLength = _allowedPaymentTokens.length;
    for (uint256 i; i < _allowedPaymentTokensLength; ) {
      uint256 _sendAmount = lenderBenefit[_lockId][_allowedPaymentTokens[i]];
      delete lenderBenefit[_lockId][_allowedPaymentTokens[i]];
      if (_allowedPaymentTokens[i] == address(0)) {
        payable(msg.sender).transfer(_sendAmount);
      } else {
        IERC20(_allowedPaymentTokens[i]).safeTransfer(msg.sender, _sendAmount);
      }
      unchecked {
        i++;
      }
    }
    if (lendRent[_lockId].lend.lockStartTime != lendRent[_lockId].lend.lockExpireTime)
      burn(_lockId); // burn yNFT
    emit Claimed(_lockId);
  }

  function _calcFee(
    uint256 _lockId,
    uint256 _dailyRentalPrice,
    uint64 _lockStartTime,
    uint64 _lockExpireTime,
    address _lender,
    uint256 _rentalDurationByDay,
    uint256 _amount,
    address _vault,
    address _paymentToken
  ) private {
    (
      uint256 _lenderBenefit,
      uint256 _collectionOwnerBenefit,
      uint256 _protocolAdminBenefit
    ) = Calculator.fee(
        _dailyRentalPrice,
        _lockStartTime,
        _lockExpireTime,
        _lender,
        _paymentToken,
        protocolAdminFeeRatio,
        _rentalDurationByDay,
        _amount,
        IVault(_vault).collectionOwnerFeeRatio()
      );

    lenderBenefit[_lockId][_paymentToken] = lenderBenefit[_lockId][_paymentToken] + _lenderBenefit;
    collectionOwnerBenefit[_vault][_paymentToken] =
      collectionOwnerBenefit[_vault][_paymentToken] +
      _collectionOwnerBenefit;
    protocolAdminBenefit[_paymentToken] =
      protocolAdminBenefit[_paymentToken] +
      _protocolAdminBenefit;
  }

  function _updateRent(
    address _vaultAddress,
    uint256 _lockId,
    Lend memory _lend,
    Rent memory _rent
  ) private {
    //Rent[] storage _rents = lendRent[_lockId].rent;

    _deleteExpiredRent(lendRent[_lockId].rent);

    require(
      Detector.availability(
        IVault(_vaultAddress).originalCollection(),
        lendRent[_lockId].rent,
        _lend,
        _rent.rentalStartTime,
        _rent.rentalExpireTime
      ) >= 1,
      'NotAvailable'
    );

    // Push new rent
    lendRent[_lockId].rent.push(_rent);
  }

  function _mintNft(uint256 _lockId, uint256 _lockDuration) private {
    _mintONft(_lockId);
    // Mint the yNFT to match the mint of the oNFT
    if (_lockDuration != 0) _mintYNft(_lockId);
  }

  // Deposit the original NFT to the Vault
  // Receive oNFT minted instead
  function _mintONft(uint256 _lockId) private {
    (address _vaultAddress, uint256 _tokenId, uint256 _amount) = (
      lendRent[_lockId].lend.vault,
      lendRent[_lockId].lend.tokenId,
      lendRent[_lockId].lend.amount
    );
    // Process the NFT to deposit it in the vault
    // Send and mint the NFT after confirming that the owner of the NFT is executing
    // Get the address of the original NFT
    // NFT sent to vault (= locked)
    _safeTransferBundle(
      IVault(_vaultAddress).originalCollection(),
      msg.sender,
      _vaultAddress,
      _tokenId,
      _amount
    );
    // Minting oNft from Vault.
    IVault(_vaultAddress).mintONft(_lockId);
  }

  // Mint the yNFT instead of listing it on the market
  function _mintYNft(uint256 _lockId) private {
    _mint(msg.sender, _lockId);
  }

  // The part that actually creates the lending board
  function _createList(
    uint256 _lockId, // Unique number for each loan
    uint256 _tokenId,
    uint256 _lockDuration,
    uint256 _minRentalDuration,
    uint256 _maxRentalDuration,
    uint256 _amount,
    uint256 _dailyRentalPrice,
    address _privateAddress,
    address _vaultAddress,
    address _paymentToken,
    PaymentMethod _paymentMethod
  ) private {
    // By the time you get here, the deposit process has been completed and the o/yNFT has been issued.
    LendRent storage _lendRent = lendRent[_lockId];

    _lendRent.lend = Lend({
      minRentalDuration: uint64(_minRentalDuration),
      maxRentalDuration: uint64(_maxRentalDuration),
      lockStartTime: uint64(block.timestamp),
      lockExpireTime: uint64(block.timestamp + (_lockDuration)),
      dailyRentalPrice: _dailyRentalPrice,
      tokenId: _tokenId,
      amount: _amount,
      vault: _vaultAddress,
      lender: msg.sender,
      paymentToken: _paymentToken,
      privateAddress: _privateAddress,
      paymentMethod: _paymentMethod
    });

    emit Listed(_lockId, msg.sender, _lendRent.lend);
  }

  // Redeem NFTs deposited in the Vault by Burning oNFTs
  function _redeemNFT(uint256 _lockId) private {
    // Redeem NFTs deposited in the vault. wrapped NFTs are released on the vault side.
    IVault(lendRent[_lockId].lend.vault).redeem(_lockId);
    _clearStorages(_lockId);
    emit Withdrawn(_lockId);
  }

  function _clearStorages(uint256 _lockId) private {
    delete lendRent[_lockId];
  }

  function _safeTransferBundle(
    address _originalNftAddress,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount
  ) private {
    if (_originalNftAddress.is1155()) {
      IERC1155(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId, _amount, '');
    } else if (_originalNftAddress.is721()) {
      IERC721(_originalNftAddress).safeTransferFrom(_from, _to, _tokenId);
    } else {
      IVault(_originalNftAddress).transferFrom(_from, _to, _tokenId);
    }
  }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

library RentaFiSVG {
  function weiToEther(uint256 num) public pure returns (string memory) {
    if (num == 0) return '0.0';
    bytes memory b = bytes(Strings.toString(num));
    uint256 n = b.length;
    if (n < 19) for (uint256 i = 0; i < 19 - n; i++) b = abi.encodePacked('0', b);
    n = b.length;
    uint256 k = 18;
    for (uint256 i = n - 1; i > n - 18; i--) {
      if (b[i] != '0') break;
      k--;
    }
    uint256 m = n - 18 + k + 1;
    bytes memory a = new bytes(m);
    for (uint256 i = 0; i < k; i++) a[m - 1 - i] = b[n - 19 + k - i];
    a[m - k - 1] = '.';
    for (uint256 i = 0; i < n - 18; i++) a[m - k - 2 - i] = b[n - 19 - i];
    return string(a);
  }

  function getYieldSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _benefit,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name,
    string memory _tokenSymbol
  ) public pure returns (bytes memory) {
    string memory parsed = weiToEther(_benefit);
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>Yield NFT - RentaFi</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400' text-anchor='end'><tspan x='465' y='150'>",
          _tokenSymbol,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>Claimable Funds</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900'><tspan x='440' y='150' text-anchor='end'>",
          parsed,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='270'>"
        ),
        abi.encodePacked(
          _name,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='283'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='270'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='283'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      abi.encodePacked(
        '{"name": "yieldNFT #',
        Strings.toString(_lockId),
        ' - RentaFi", "description": "YieldNFT represents Rental Fee deposited by Borrower in a RentaFi Escrow. The owner of this NFT can claim rental fee after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"'
      ),
      abi.encodePacked(
        Strings.toString(_lockStartTime),
        '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
        Strings.toString(_lockExpireTime),
        '"},{"trait_type":"FeeAmount", "value":"',
        parsed,
        '"},{"trait_type":"Collection", "value":"',
        _name,
        '"}]}'
      )
    );

    return json;
  }

  function getOwnershipSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name
  ) public pure returns (bytes memory) {
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>RentaFi Ownership NFT</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='280' y='270'>Until Unlock</tspan><tspan x='430' y='270'>Day</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>",
          _name,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900' text-anchor='end'><tspan x='425' y='270'>",
          Strings.toString((_lockExpireTime - _lockStartTime))
        ),
        abi.encodePacked(
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='170'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='185'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='200'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      '{"name": "OwnershipNFT #',
      Strings.toString(_lockId),
      ' - RentaFi", "description": "OwnershipNFT represents Original NFT locked in a RentaFi Escrow. The owner of this NFT can claim original NFT after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
      Strings.toString(_lockStartTime),
      '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
      Strings.toString(_lockExpireTime),
      '"},{"trait_type": "Collection", "value":"',
      _name,
      '"}]}'
    );

    return json;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library Calculator {
  uint256 private constant E5 = 1e5;
  using SafeERC20 for IERC20;

  function duration(
    uint256 _rentalStartTimestamp,
    uint256 _rentalDurationByDay,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    uint256 _maxRentalDuration,
    uint256 _minRentalDuration
  ) public view returns (uint256 _rentalStartTime, uint256 _rentalExpireTime) {
    _rentalStartTime = block.timestamp;

    // Check to see if the number of days or date conditions set by lend are met.
    require(
      _rentalExpireTime < _lockExpireTime || _lockExpireTime - _lockStartTime == 0,
      'RentalExpireAfterLockExpire'
    );
    require(
      _minRentalDuration <= _rentalDurationByDay && _rentalDurationByDay <= _maxRentalDuration,
      'RentalDurationIsOutOfRange'
    );
    // For Reservation
    if (_rentalStartTimestamp != 0) {
      require(_rentalStartTimestamp > block.timestamp, 'rentalStartShouldBeNow/Later');
      _rentalStartTime = _rentalStartTimestamp;
    }
    // Arguments are passed in days, so they are converted to seconds
    _rentalExpireTime = _rentalStartTime + (_rentalDurationByDay);
  }

  function fee(
    uint256 _dailyRentalPrice,
    uint64 _lockStartTime,
    uint64 _lockExpireTime,
    address _lender,
    address _paymentToken,
    uint256 _adminFeeRatio,
    uint256 _rentalDurationByDay,
    uint256 _amount,
    uint256 _collectionOwnerFeeRatio
  )
    public
    returns (
      uint256 _lenderBenefit,
      uint256 _collectionOwnerFee,
      uint256 _adminFee
    )
  {
    /*
     * If the amount is greater than 1 in ERC721,
     * the renter will only pay more than necessary,
     * so we do not revert here to save on gas costs.
     */
    //_rentalFeeは、1日あたりの価格と数量、日数によって計算される
    uint256 _rentalFee = _dailyRentalPrice * _amount * _rentalDurationByDay; // dailyRentalPrice per Unit * Rental Amount * rentalDuration(days)
    // adminFeeは、レンタル料金に対してプロトコルロイヤリティの割合で計算される
    _adminFee = (_rentalFee * _adminFeeRatio) / E5;
    // コレクションオーナーへの収益は、コレクションオーナーロイヤリティの割合と、レンタル料金で計算される
    _collectionOwnerFee = (_rentalFee * _collectionOwnerFeeRatio) / E5;
    //貸し手の収益は、上記の残額分
    uint256 _lenderFee = _rentalFee - _adminFee - _collectionOwnerFee;

    require(_rentalFee == _adminFee + _collectionOwnerFee + _lenderFee, 'invalidCalc');
    // If the lockDuration is Zero, fee is sent to lender this time
    if (_lockStartTime < _lockExpireTime) _lenderBenefit = _lenderFee;

    // Native token
    if (_paymentToken == address(0)) {
      require(msg.value >= _rentalFee, 'InsufficientFunds');
      if (msg.value > _rentalFee) payable(msg.sender).transfer(msg.value - _rentalFee);
      // If No Locked
      if (_lockStartTime == _lockExpireTime) payable(_lender).transfer(_lenderFee); //lenderに送るのは、_lenderFeeのみ。 adminFeeとCollectionOwnerFeeはmsg.valueで送られている
      // If Loked, protocol received fee by msg.value. so no method required.
    }
    //ERC20 token
    else {
      // If No Locked
      if (_lockStartTime == _lockExpireTime) {
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(_lender), _lenderFee); //lenderに送るのは、_lenderFeeのみ
        IERC20(_paymentToken).safeTransferFrom(
          msg.sender,
          address(this),
          _collectionOwnerFee + _adminFee
        );
      }
      // If Locked, pay all fee to protocol
      else {
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _rentalFee);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IERC20Detailed {
  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '../interfaces/IMarket.sol';
import '../ERC4907/IERC4907.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

library Detector {
  function is721(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC721).interfaceId);
  }

  function is1155(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC1155).interfaceId);
  }

  function is4907(address collection) public view returns (bool) {
    return IERC165(collection).supportsInterface(type(IERC4907).interfaceId);
  }

  function availability(
    address _originalNftAddress,
    IMarket.Rent[] calldata _rents,
    IMarket.Lend calldata _lend,
    uint256 _rentalStartTime,
    uint256 _rentalExpireTime
  ) public view returns (uint256) {
    uint256 _rentaled;
    // ERC721 availability
    if (is721(_originalNftAddress)) {
      // Check for rental availability
      unchecked {
        for (uint256 i = 0; i < _rents.length; i++) {
          // Periods A-B and C-D overlap only if A<=D && C<=B
          if (
            _rents[i].rentalStartTime <= _rentalExpireTime &&
            _rentalStartTime <= _rents[i].rentalExpireTime
          ) _rentaled += _rents[i].amount;
        }
        // Check for rental availability
        return _lend.amount - _rentaled;
      }
    }

    // ERC1155 availability
    if (is1155(_originalNftAddress)) {
      // Confirmation of the number of tokens remaining available for rent
      unchecked {
        for (uint256 i = 0; i < _rents.length; i++) {
          // Counting rent amount with overlapping periods
          // Periods A-B and C-D overlap only if A<=D && C<=B
          if (
            _rents[i].rentalStartTime <= _rentalExpireTime &&
            _rentalStartTime <= _rents[i].rentalExpireTime
          ) _rentaled += _rents[i].amount;
        }
      }
      // Check for rental availability
      return _lend.amount - _rentaled;
    }

    return 0;
  }
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IVault {
  function factoryContract() external view returns (address);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function approve(address _to, uint256 _tokenId) external;

  function burn(uint256 _tokenId) external;

  function mintONft(uint256 _lockId) external;

  function mintWNft(
    address _renter,
    uint256 _starts,
    uint256 _expires,
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount
  ) external;

  function activate(
    uint256 _rentId,
    uint256 _lockId,
    address _renter,
    uint256 _amount
  ) external;

  function originalCollection() external view returns (address);

  function redeem(uint256 _tokenId) external;

  function ownerOf(uint256 _tokenId) external view returns (address owner);

  function collectionOwner() external view returns (address);

  function payoutAddress() external view returns (address);

  function collectionOwnerFeeRatio() external view returns (uint256);

  function getTokenIdAllowed(uint256 _tokenId) external view returns (bool);

  function getPaymentTokens() external view returns (address[] memory);

  //function paymentTokenWhiteList(address _paymentToken) external view returns (uint256 _bool);

  function setMinPrices(uint256[] memory _minPrices, address[] memory _paymentTokens) external;

  //NOTE ホワリスの代わり
  function minPrices(address _paymentToken) external view returns (uint256);

  function minDuration() external view returns (uint256);

  function maxDuration() external view returns (uint256);

  function flashloan(
    address _tokenAddress,
    uint256 _tokenId,
    address _receiver
  ) external payable;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;
}

// SPDX-License-Identifier: None
pragma solidity =0.8.13;

interface IMarket {
  event Listed(uint256 indexed lockId, address indexed lender, Lend lend);
  event Rented(uint256 indexed rentId, address indexed renter, uint256 lockId, Rent rent);
  event Canceled(uint256 indexed lockId);
  event WhiteListed(address indexed collection, address indexed vault);
  event Withdrawn(uint256 indexed lockId);
  event Claimed(uint256 indexed lockId);
  event ClaimedRoyalty(address indexed collection);

  enum LockIdTarget {
    Lender,
    Renter,
    Vault,
    Token
  }

  enum PaymentMethod {
    // 32bit
    OneTime,
    Loan,
    BNPL,
    Subscription
  }

  /*
   * Market only returns data for listings
   * Original NFT is in the Vault contract
   */
  struct Lend {
    uint64 minRentalDuration; // days
    uint64 maxRentalDuration; // days
    uint64 lockStartTime;
    uint64 lockExpireTime;
    uint256 dailyRentalPrice; // wei
    uint256 tokenId;
    uint256 amount; // for ERC1155
    address vault; //160 bit
    address paymentToken; // 160 bit
    address lender; // 160 bit
    address privateAddress;
    PaymentMethod paymentMethod; // 32bit
  }

  struct Rent {
    address renterAddress;
    uint256 rentId;
    uint256 rentalStartTime;
    uint256 rentalExpireTime;
    uint256 amount;
  }

  struct LendRent {
    Lend lend;
    Rent[] rent;
  }

  function getLendRent(uint256 _lockId) external view returns (LendRent memory);

  function paymentTokenWhiteList(address _paymentToken) external view returns (uint256);

  function protocolAdminFeeRatio() external view returns (uint256);
}

interface IMarketOwner {
  function owner() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity =0.8.13;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);
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