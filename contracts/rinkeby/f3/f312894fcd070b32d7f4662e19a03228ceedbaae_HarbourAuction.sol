/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(
      isAdmin(msg.sender),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(msg.sender);
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

abstract contract CreatorWithdraw is AdminRole {
  address payable private _creator;

  constructor() {
    _creator = payable(msg.sender);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {
    // thank you
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else if (erc20 != address(this)) {
      IERC20(erc20).transfer(_creator, amount);
    }
  }

  function withdrawToken(address erc721, uint256 tokenId) public onlyAdmin {
    IERC721(erc721).transferFrom(address(this), _creator, tokenId);
  }
}

contract HarbourAuction is AdminRole, CreatorWithdraw {
  address payable private _creator;
  // maker => token address => tokenId => price
  mapping(address => mapping(address => mapping(uint256 => uint256)))
    private _priceByMakerTokenTokenId;

  uint256 private constant BPS = 10000;
  uint256 public minPrice;
  uint256 public maxPrice;
  uint256 public exchangeFeeBps;
  address payable public exchangeFeeAddress;
  bool public isUnwrappedValid = false;
  mapping(address => bool) private _validCurrencies;

  constructor(
    uint256 min,
    uint256 max,
    uint256 fee,
    address payable feeAddress,
    bool unwrappedValid
  ) {
    minPrice = min;
    maxPrice = max;
    exchangeFeeBps = fee;
    exchangeFeeAddress = feeAddress;
    isUnwrappedValid = unwrappedValid;
  }

  event CurrencyUpdate(address erc20, bool valid);
  event LimitUpdate(uint256 min, uint256 max);
  event FeeUpdate(address payable feeAddress, uint256 fee);

  function setCurrencyValid(address erc20, bool valid) public onlyAdmin {
    if (erc20 == address(0)) {
      isUnwrappedValid = valid;
    } else {
      _validCurrencies[erc20] = valid;
    }
    emit CurrencyUpdate(erc20, valid);
  }

  function setPriceLimits(uint256 min, uint256 max) public onlyAdmin {
    minPrice = min;
    maxPrice = max;
    emit LimitUpdate(min, max);
  }

  function setExchangeFee(address payable feeAddress, uint256 fee)
    public
    onlyAdmin
  {
    exchangeFeeAddress = feeAddress;
    exchangeFeeBps = fee;
    emit FeeUpdate(feeAddress, fee);
  }

  event OrderOffer(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId,
    uint256 price
  );
  event OrderCancel(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId
  );
  event OrderTaken(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId,
    uint256 price,
    address taker
  );

  function _setOffer(
    address maker,
    address token,
    uint256 tokenId,
    uint256 price
  ) internal {
    _priceByMakerTokenTokenId[maker][token][tokenId] = price;
  }

  function _clearOffer(
    address maker,
    address token,
    uint256 tokenId
  ) internal {
    _priceByMakerTokenTokenId[maker][token][tokenId] = 0;
  }

  function isCurrencyValid(address erc20) public view returns (bool) {
    return _validCurrencies[erc20];
  }

  function getOffer(
    address maker,
    address token,
    uint256 tokenId
  ) public view returns (uint256) {
    return _priceByMakerTokenTokenId[maker][token][tokenId];
  }

  function cancelOffer(address token, uint256 tokenId) public {
    address maker = msg.sender;
    uint256 oldPrice = getOffer(maker, token, tokenId);
    require(oldPrice > 0, 'offer_not_found');
    _clearOffer(maker, token, tokenId);
    emit OrderCancel(maker, token, tokenId);
  }

  function makeOffer(
    address token,
    uint256 tokenId,
    uint256 price
  ) public {
    require(price >= minPrice, 'price_too_low');
    require(price <= maxPrice, 'price_too_high');

    address maker = msg.sender;
    _setOffer(maker, token, tokenId, price);
    emit OrderOffer(maker, token, tokenId, price);
  }

  struct PayoutResult {
    address payable royaltyAddress;
    uint256 royaltyFee;
    uint256 exchangeFee;
    uint256 makerAmount;
  }

  function _getPayouts(
    address token,
    uint256 tokenId,
    uint256 price
  ) internal view returns (PayoutResult memory) {
    PayoutResult memory payouts;
    try IERC721(token).royaltyInfo(tokenId, price) returns (
      address royaltyAddress,
      uint256 fee
    ) {
      payouts.royaltyAddress = payable(royaltyAddress);
      payouts.royaltyFee = fee;
    } catch {
      payouts.royaltyFee = 0;
    }
    require(price > payouts.royaltyFee, 'erc2981_invalid_royalty');

    payouts.exchangeFee = (price * exchangeFeeBps) / BPS;
    payouts.makerAmount = price - payouts.exchangeFee - payouts.royaltyFee;
    require(payouts.makerAmount > 0, 'maker_amount_invalid');
    return payouts;
  }

  function previewPayout(
    address token,
    uint256 tokenId,
    uint256 price
  )
    public
    view
    returns (
      uint256 exchangeFee,
      uint256 royaltyFee,
      uint256 makerAmount
    )
  {
    PayoutResult memory payouts = _getPayouts(token, tokenId, price);
    return (payouts.exchangeFee, payouts.royaltyFee, payouts.makerAmount);
  }

  function checkOffer(
    address maker,
    address token,
    uint256 tokenId
  ) public view returns (uint256 price) {
    price = getOffer(maker, token, tokenId);
    require(price != 0, 'offer_not_found');
    require(price >= minPrice, 'price_too_low');
    require(price <= maxPrice, 'price_too_high');
    address owner = IERC721(token).ownerOf(tokenId);
    require(owner == maker, 'owner_not_maker');
    bool isApprovedForAll = IERC721(token).isApprovedForAll(
      maker,
      address(this)
    );
    bool isApproved = IERC721(token).getApproved(tokenId) == address(this);
    require(isApprovedForAll || isApproved, 'erc721_not_approved');
    return price;
  }

  function preflightTake(
    address maker,
    address taker,
    address token,
    uint256 tokenId,
    uint256 price,
    address erc20
  ) public view returns (bool) {
    require(maker != taker, 'maker_is_taker');
    uint256 offerPrice = checkOffer(maker, token, tokenId);
    require(price >= offerPrice, 'offer_gt_price');
    _getPayouts(token, tokenId, price);
    if (erc20 == address(0)) {
      require(isUnwrappedValid, 'unwrapped_currency_not_allowed');
    } else {
      require(isCurrencyValid(erc20), 'erc20_not_accepted');
      uint256 balance = IERC20(erc20).balanceOf(taker);
      require(balance >= price, 'erc20_balance_too_low');
      uint256 allowance = IERC20(erc20).allowance(taker, address(this));
      require(allowance >= price, 'erc20_transfer_not_allowed');
    }
    return true;
  }

  function _validateAndTake(
    address maker,
    address newTokenOwner,
    address token,
    uint256 tokenId,
    uint256 price
  ) internal returns (PayoutResult memory) {
    require(maker != newTokenOwner, 'maker_is_new_owner');

    uint256 offerPrice = getOffer(maker, token, tokenId);
    require(offerPrice != 0, 'offer_not_found');
    require(price >= offerPrice, 'offer_gt_price');
    require(offerPrice >= minPrice, 'price_too_low');
    require(offerPrice <= maxPrice, 'price_too_high');

    // clear offer re-entrance check
    _clearOffer(maker, token, tokenId);

    address owner = IERC721(token).ownerOf(tokenId);
    require(owner == maker, 'owner_not_maker');
    PayoutResult memory payouts = _getPayouts(token, tokenId, price);
    IERC721(token).safeTransferFrom(maker, newTokenOwner, tokenId);
    emit OrderTaken(maker, token, tokenId, offerPrice, newTokenOwner);
    return payouts;
  }

  function _sendTokens(
    address erc20,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(
      IERC20(erc20).transferFrom(from, to, amount),
      'erc20_transfer_failed'
    );
  }

  function takeOfferUnwrapped(
    address payable maker,
    address token,
    uint256 tokenId,
    address newTokenOwner
  ) public payable {
    require(isUnwrappedValid, 'unwrapped_currency_not_allowed');
    uint256 price = msg.value;
    PayoutResult memory payouts = _validateAndTake(
      maker,
      newTokenOwner,
      token,
      tokenId,
      price
    );
    if (payouts.exchangeFee > 0) {
      exchangeFeeAddress.transfer(payouts.exchangeFee);
    }
    if (payouts.royaltyFee > 0) {
      payouts.royaltyAddress.transfer(payouts.royaltyFee);
    }
    maker.transfer(payouts.makerAmount);
  }

  function takeOfferUnwrapped(
    address payable maker,
    address token,
    uint256 tokenId
  ) public payable {
    takeOfferUnwrapped(maker, token, tokenId, msg.sender);
  }

  function takeOffer(
    address maker,
    address token,
    uint256 tokenId,
    uint256 price,
    address erc20,
    address newTokenOwner
  ) public {
    require(isCurrencyValid(erc20), 'erc20_not_accepted');
    PayoutResult memory payouts = _validateAndTake(
      maker,
      newTokenOwner,
      token,
      tokenId,
      price
    );
    if (payouts.exchangeFee > 0) {
      _sendTokens(erc20, msg.sender, exchangeFeeAddress, payouts.exchangeFee);
    }
    if (payouts.royaltyFee > 0) {
      _sendTokens(
        erc20,
        msg.sender,
        payouts.royaltyAddress,
        payouts.royaltyFee
      );
    }
    _sendTokens(erc20, msg.sender, maker, payouts.makerAmount);
  }

  function takeOffer(
    address maker,
    address token,
    uint256 tokenId,
    uint256 price,
    address erc20
  ) public {
    takeOffer(maker, token, tokenId, price, erc20, msg.sender);
  }
}