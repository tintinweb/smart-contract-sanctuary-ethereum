// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "./interfaces/IERC20.sol";
import "./interfaces/IRealTokenYamUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract RealTokenYamUpgradeable is
  PausableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IRealTokenYamUpgradeable
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

  mapping(uint256 => uint256) private prices;
  mapping(uint256 => uint256) private amounts;
  mapping(uint256 => address) private offerTokens;
  mapping(uint256 => address) private buyerTokens;
  mapping(uint256 => address) private sellers;
  mapping(uint256 => address) private buyers;
  mapping(address => TokenType) private tokenTypes;
  uint256 private offerCount;
  uint256 public fee; // fee in basis points

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice the initialize function to execute only once during the contract deployment
  /// @param admin_ address of the default admin account: whitelist tokens, delete frozen offers, upgrade the contract
  /// @param moderator_ address of the admin with unique responsibles
  function initialize(address admin_, address moderator_) external initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(UPGRADER_ROLE, admin_);
    _grantRole(MODERATOR_ROLE, moderator_);
    __ReentrancyGuard_init();
  }

  /// @notice The admin (with upgrader role) uses this function to update the contract
  /// @dev This function is always needed in future implementation contract versions, otherwise, the contract will not be upgradeable
  /// @param newImplementation is the address of the new implementation contract
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADER_ROLE)
  {}

  /**
   * @dev Only moderator or admin can call functions marked by this modifier.
   **/
  modifier onlyModeratorOrAdmin() {
    require(
      hasRole(MODERATOR_ROLE, _msgSender()) ||
        hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "caller is not moderator or admin"
    );
    _;
  }

  /**
   * @dev Only whitelisted token can be used by functions marked by this modifier.
   **/
  modifier onlyWhitelistTokenWithType(address token_) {
    require(
      tokenTypes[token_] != TokenType.NOTWHITELISTEDTOKEN,
      "Token is not whitelisted"
    );
    _;
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function toggleWhitelistWithType(
    address[] calldata tokens_,
    TokenType[] calldata types_
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tokens_.length == types_.length, "Lengths are not equal");
    uint256 length = tokens_.length;
    for (uint256 i = 0; i < length; ) {
      tokenTypes[tokens_[i]] = types_[i];
      ++i;
    }
    emit TokenWhitelistWithTypeToggled(tokens_, types_);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function createOffer(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount
  ) public override whenNotPaused {
    // If the offerToken is a RealToken, isTransferValid need to be checked
    if (tokenTypes[offerToken] == TokenType.REALTOKEN) {
      require(
        _isTransferValid(offerToken, msg.sender, msg.sender, amount),
        "Seller can not transfer tokens"
      );
    }
    _createOffer(offerToken, buyerToken, buyer, price, amount);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function createOfferWithPermit(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override whenNotPaused {
    // If the offerToken is a RealToken, isTransferValid need to be checked
    if (tokenTypes[offerToken] == TokenType.REALTOKEN) {
      require(
        _isTransferValid(offerToken, msg.sender, msg.sender, amount),
        "Seller can not transfer tokens"
      );
    }

    // Create the offer
    _createOffer(offerToken, buyerToken, buyer, price, amount);

    // Permit amount is cumulated through all offers
    uint256 amountToPermit = amount +
      IBridgeToken(offerToken).allowance(msg.sender, address(this));
    IBridgeToken(offerToken).permit(
      msg.sender,
      address(this),
      amountToPermit,
      deadline,
      v,
      r,
      s
    );
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function buy(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external override whenNotPaused {
    _buy(offerId, price, amount);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function buyWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override whenNotPaused {
    // If the offerToken is a RealToken, isTransferValid need to be checked
    if (tokenTypes[offerTokens[offerId]] == TokenType.REALTOKEN) {
      require(
        _isTransferValid(
          offerTokens[offerId],
          sellers[offerId],
          msg.sender,
          amount
        ),
        "transfer is not valid"
      );
    }

    uint256 buyerTokenAmount = (price * amount) /
      (uint256(10)**IERC20(offerTokens[offerId]).decimals());
    IBridgeToken(buyerTokens[offerId]).permit(
      msg.sender,
      address(this),
      buyerTokenAmount,
      deadline,
      v,
      r,
      s
    );
    _buy(offerId, price, amount);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function updateOffer(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external override whenNotPaused {
    _updateOffer(offerId, price, amount);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function updateOfferWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override whenNotPaused {
    // Permit new amount
    uint256 amountToPermit = IBridgeToken(offerTokens[offerId]).allowance(
      msg.sender,
      address(this)
    ) +
      amount -
      amounts[offerId];
    IBridgeToken(offerTokens[offerId]).permit(
      msg.sender,
      address(this),
      amountToPermit,
      deadline,
      v,
      r,
      s
    );
    // Then update the offer
    _updateOffer(offerId, price, amount);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function deleteOffer(uint256 offerId) public override whenNotPaused {
    require(sellers[offerId] == msg.sender, "only the seller can delete offer");
    _deleteOffer(offerId);
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function deleteOfferBatch(uint256[] calldata offerIds)
    external
    override
    whenNotPaused
  {
    uint256 length = offerIds.length;
    for (uint256 i = 0; i < length; ) {
      deleteOffer(offerIds[i]);
      ++i;
    }
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function deleteOfferByAdmin(uint256[] calldata offerIds)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    uint256 length = offerIds.length;
    for (uint256 i = 0; i < length; ) {
      _deleteOffer(offerIds[i]);
      ++i;
    }
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function getOfferCount() external view override returns (uint256) {
    return offerCount;
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function getTokenType(address token)
    external
    view
    override
    returns (TokenType)
  {
    return tokenTypes[token];
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function tokenInfo(address tokenAddr)
    external
    view
    override
    returns (
      uint256,
      string memory,
      string memory
    )
  {
    IERC20 tokenInterface = IERC20(tokenAddr);
    return (
      tokenInterface.decimals(),
      tokenInterface.symbol(),
      tokenInterface.name()
    );
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function getInitialOffer(uint256 offerId)
    external
    view
    override
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    )
  {
    return (
      offerTokens[offerId],
      buyerTokens[offerId],
      sellers[offerId],
      buyers[offerId],
      prices[offerId],
      amounts[offerId]
    );
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function showOffer(uint256 offerId)
    external
    view
    override
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    )
  {
    // get offerTokens balance and allowance, whichever is lower is the available amount
    uint256 availableBalance = IERC20(offerTokens[offerId]).balanceOf(
      sellers[offerId]
    );
    uint256 availableAllow = IERC20(offerTokens[offerId]).allowance(
      sellers[offerId],
      address(this)
    );
    uint256 availableAmount = amounts[offerId];

    if (availableBalance < availableAmount) {
      availableAmount = availableBalance;
    }

    if (availableAllow < availableAmount) {
      availableAmount = availableAllow;
    }

    return (
      offerTokens[offerId],
      buyerTokens[offerId],
      sellers[offerId],
      buyers[offerId],
      prices[offerId],
      availableAmount
    );
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function pricePreview(uint256 offerId, uint256 amount)
    external
    view
    override
    returns (uint256)
  {
    IERC20 offerTokenInterface = IERC20(offerTokens[offerId]);
    return
      (amount * prices[offerId]) /
      (uint256(10)**offerTokenInterface.decimals());
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function saveLostTokens(address token)
    external
    override
    onlyModeratorOrAdmin
  {
    IERC20 tokenInterface = IERC20(token);
    tokenInterface.transfer(
      msg.sender,
      tokenInterface.balanceOf(address(this))
    );
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function setFee(uint256 fee_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    emit FeeChanged(fee, fee_);
    fee = fee_;
  }

  /**
   * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
   * @param _offerToken The address of the token to be sold
   * @param _buyerToken The address of the token to be bought
   * @param _price The price in base units of the token to be sold
   * @param _amount The amount of tokens to be sold
   **/
  function _createOffer(
    address _offerToken,
    address _buyerToken,
    address _buyer,
    uint256 _price,
    uint256 _amount
  )
    private
    onlyWhitelistTokenWithType(_offerToken)
    onlyWhitelistTokenWithType(_buyerToken)
  {
    // if no offerId is given a new offer is made, if offerId is given only the offers price is changed if owner matches
    uint256 _offerId = offerCount;
    offerCount++;
    if (_buyer != address(0)) {
      buyers[_offerId] = _buyer;
    }
    sellers[_offerId] = msg.sender;
    offerTokens[_offerId] = _offerToken;
    buyerTokens[_offerId] = _buyerToken;
    prices[_offerId] = _price;
    amounts[_offerId] = _amount;

    emit OfferCreated(
      _offerToken,
      _buyerToken,
      msg.sender,
      _buyer,
      _offerId,
      _price,
      _amount
    );
  }

  /**
   * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
   * @param _offerId The address of the token to be sold
   * @param _price The address of the token to be bought
   * @param _amount The price in base units of the token to be sold
   **/
  function _updateOffer(
    uint256 _offerId,
    uint256 _price,
    uint256 _amount
  ) private {
    require(
      sellers[_offerId] == msg.sender,
      "only the seller can change offer"
    );
    emit OfferUpdated(
      _offerId,
      prices[_offerId],
      _price,
      amounts[_offerId],
      _amount
    );
    prices[_offerId] = _price;
    amounts[_offerId] = _amount;
  }

  /**
   * @notice Deletes an existing offer
   * @param _offerId The Id of the offer to be deleted
   **/
  function _deleteOffer(uint256 _offerId) private {
    delete sellers[_offerId];
    delete buyers[_offerId];
    delete offerTokens[_offerId];
    delete buyerTokens[_offerId];
    delete prices[_offerId];
    delete amounts[_offerId];
    emit OfferDeleted(_offerId);
  }

  /**
   * @notice Accepts an existing offer
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param _offerId The Id of the offer
   * @param _price The price in base units of the offer tokens
   * @param _amount The amount of offer tokens
   **/
  function _buy(
    uint256 _offerId,
    uint256 _price,
    uint256 _amount
  ) private {
    if (buyers[_offerId] != address(0)) {
      require(buyers[_offerId] == msg.sender, "private offer");
    }

    address seller = sellers[_offerId];
    address offerToken = offerTokens[_offerId];
    address buyerToken = buyerTokens[_offerId];

    IERC20 offerTokenInterface = IERC20(offerToken);
    IERC20 buyerTokenInterface = IERC20(buyerToken);

    // given price is being checked with recorded data from mappings
    require(prices[_offerId] == _price, "offer price wrong");

    // calculate the price of the order
    require(_amount <= amounts[_offerId], "amount too high");
    require(
      _amount * _price > (uint256(10)**offerTokenInterface.decimals()),
      "amount too low"
    );
    uint256 buyerTokenAmount = (_amount * _price) /
      (uint256(10)**offerTokenInterface.decimals());

    // some old erc20 tokens give no return value so we must work around by getting their balance before and after the exchange
    uint256 oldBuyerBalance = buyerTokenInterface.balanceOf(msg.sender);
    uint256 oldSellerBalance = offerTokenInterface.balanceOf(seller);

    // Update amount in mapping
    amounts[_offerId] = amounts[_offerId] - _amount;

    // finally do the exchange
    buyerTokenInterface.transferFrom(msg.sender, seller, buyerTokenAmount);
    offerTokenInterface.transferFrom(seller, msg.sender, _amount);

    // now check if the balances changed on both accounts.
    // we do not check for exact amounts since some tokens behave differently with fees, burnings, etc
    // we assume if both balances are higher than before all is good
    require(
      oldBuyerBalance > buyerTokenInterface.balanceOf(msg.sender),
      "buyer error"
    );
    require(
      oldSellerBalance > offerTokenInterface.balanceOf(seller),
      "seller error"
    );

    emit OfferAccepted(
      _offerId,
      seller,
      msg.sender,
      offerToken,
      buyerToken,
      _price,
      _amount
    );
  }

  /**
   * @notice Returns true if the transfer is valid, false otherwise
   * @param _token The token address
   * @param _from The sender address
   * @param _to The receiver address
   * @param _amount The amount of tokens to be transferred
   * @return Whether the transfer is valid
   **/
  function _isTransferValid(
    address _token,
    address _from,
    address _to,
    uint256 _amount
  ) private view returns (bool) {
    // Generalize verifying rules (for example: 11, 1, 12)
    (bool isTransferValid, , ) = IBridgeToken(_token).canTransfer(
      _from,
      _to,
      _amount
    );

    // If everything is fine, return true
    return isTransferValid;
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function createOfferBatch(
    address[] calldata _offerTokens,
    address[] calldata _buyerTokens,
    address[] calldata _buyers,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external override whenNotPaused {
    uint256 length = _offerTokens.length;
    require(
      _buyerTokens.length == length &&
        _buyers.length == length &&
        _prices.length == length &&
        _amounts.length == length,
      "length mismatch"
    );
    for (uint256 i = 0; i < length; ) {
      createOffer(
        _offerTokens[i],
        _buyerTokens[i],
        _buyers[i],
        _prices[i],
        _amounts[i]
      );
      ++i;
    }
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function updateOfferBatch(
    uint256[] calldata _offerIds,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external override whenNotPaused {
    uint256 length = _offerIds.length;
    require(
      _prices.length == length && _amounts.length == length,
      "length mismatch"
    );
    for (uint256 i = 0; i < length; ) {
      _updateOffer(_offerIds[i], _prices[i], _amounts[i]);
      ++i;
    }
  }

  /// @inheritdoc	IRealTokenYamUpgradeable
  function buyOfferBatch(
    uint256[] calldata _offerIds,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external override whenNotPaused {
    uint256 length = _offerIds.length;
    require(
      _prices.length == length && _amounts.length == length,
      "length mismatch"
    );
    for (uint256 i = 0; i < length; ) {
      _buy(_offerIds[i], _prices[i], _amounts[i]);
      ++i;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  // no return value on transfer and transferFrom to tolerate old erc20 tokens
  // we work around that in the buy function by checking balance twice
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  function transfer(address to, uint256 amount) external;

  function decimals() external view returns (uint256);

  function symbol() external view returns (string calldata);

  function name() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IBridgeToken.sol";
import "./IComplianceRegistry.sol";

interface IRealTokenYamUpgradeable {
  enum TokenType {
    NOTWHITELISTEDTOKEN,
    REALTOKEN,
    ERC20WITHPERMIT,
    ERC20WITHOUTPERMIT
  }

  /**
   * @dev Emitted after an offer is updated
   * @param tokens the token addresses
   **/
  event TokenWhitelistWithTypeToggled(
    address[] indexed tokens,
    TokenType[] indexed types
  );

  /**
   * @dev Emitted after an offer is created
   * @param offerToken the token you want to sell
   * @param buyerToken the token you want to buy
   * @param offerId the Id of the offer
   * @param price the price in baseunits of the token you want to sell
   * @param amount the amount of tokens you want to sell
   **/
  event OfferCreated(
    address indexed offerToken,
    address indexed buyerToken,
    address seller,
    address buyer,
    uint256 indexed offerId,
    uint256 price,
    uint256 amount
  );

  /**
   * @dev Emitted after an offer is updated
   * @param offerId the Id of the offer
   * @param oldPrice the old price of the token
   * @param newPrice the new price of the token
   * @param oldAmount the old amount of tokens
   * @param newAmount the new amount of tokens
   **/
  event OfferUpdated(
    uint256 indexed offerId,
    uint256 oldPrice,
    uint256 indexed newPrice,
    uint256 oldAmount,
    uint256 indexed newAmount
  );

  /**
   * @dev Emitted after an offer is deleted
   * @param offerId the Id of the offer to be deleted
   **/
  event OfferDeleted(uint256 indexed offerId);

  /**
   * @dev Emitted after an offer is accepted
   * @param offerId The Id of the offer that was accepted
   * @param seller the address of the seller
   * @param buyer the address of the buyer
   * @param price the price in baseunits of the token
   * @param amount the amount of tokens that the buyer bought
   **/
  event OfferAccepted(
    uint256 indexed offerId,
    address indexed seller,
    address indexed buyer,
    address offerToken,
    address buyerToken,
    uint256 price,
    uint256 amount
  );

  /**
   * @dev Emitted after an offer is deleted
   * @param oldFee the old fee basic points
   * @param newFee the new fee basic points
   **/
  event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

  /**
   * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
   * @param offerToken The address of the token to be sold
   * @param buyerToken The address of the token to be bought
   * @param buyer The address of the allowed buyer (zero address means anyone can buy)
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   **/
  function createOffer(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Creates a new offer or updates an existing offer with permit (call this again with the changed price + offerId)
   * @param offerToken The address of the token to be sold
   * @param buyerToken The address of the token to be bought
   * @param buyer The address of the allowed buyer (zero address means anyone can buy)
   * @param price The price in base units of the token to be sold
   * @param amount The amount to be permitted
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function createOfferWithPermit(
    address offerToken,
    address buyerToken,
    address buyer,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Updates an existing offer
   * @param offerId The Id of the offer
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   **/
  function updateOffer(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Updates an existing offer
   * @param offerId The Id of the offer
   * @param price The price in base units of the token to be sold
   * @param amount The amount of the offer token
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function updateOfferWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Deletes an existing offer, only the seller of the offer can do this
   * @param offerId The Id of the offer to be deleted
   **/
  function deleteOffer(uint256 offerId) external;

  /**
   * @notice Deletes an array of existing offers (for example in case tokens are frozen), only the admin can do this
   * @param offerIds The Ids array of the offers to be deleted
   **/
  function deleteOfferBatch(uint256[] calldata offerIds) external;

  /**
   * @notice Deletes an existing offer (for example in case tokens are frozen), only the admin can do this
   * @param offerIds The Id of the offer to be deleted
   **/
  function deleteOfferByAdmin(uint256[] calldata offerIds) external;

  /**
   * @notice Accepts an existing offer
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param offerId The Id of the offer
   * @param price The price in base units of the offer tokens
   * @param amount The amount of offer tokens
   **/
  function buy(
    uint256 offerId,
    uint256 price,
    uint256 amount
  ) external;

  /**
   * @notice Accepts an existing offer with permit
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param offerId The Id of the offer
   * @param price The price in base units of the offer tokens
   * @param amount The amount of offer tokens
   * @param deadline The deadline of the permit
   * @param v v of the signature
   * @param r r of the signature
   * @param s s of the signature
   **/
  function buyWithPermit(
    uint256 offerId,
    uint256 price,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Returns the offer count
   * @return offerCount The offer count
   **/
  // return the total number of offers to loop through all offers
  // its the web frontends job to keep track of offers
  function getOfferCount() external view returns (uint256);

  /**
   * @notice Returns the offer count
   * @return offerCount The offer count
   **/
  function getTokenType(address token) external view returns (TokenType);

  /**
   * @notice Returns the token information: decimals, symbole, name
   * @param tokenAddress The address of the reference asset of the distribution
   * @return The decimals of the token
   * @return The symbol  of the token
   * @return The name of the token
   **/
  function tokenInfo(address tokenAddress)
    external
    view
    returns (
      uint256,
      string memory,
      string memory
    );

  /**
   * @notice Returns the offer information
   * @param offerId The offer Id
   * @return The offer token address
   * @return The buyer token address
   * @return The seller address
   * @return The buyer address
   * @return The price
   * @return The amount of the offer token
   **/
  function getInitialOffer(uint256 offerId)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    );

  /**
   * @notice Returns the offer information
   * @param offerId The offer Id
   * @return The offer token address
   * @return The buyer token address
   * @return The seller address
   * @return The buyer address
   * @return The price
   * @return The available balance
   **/
  function showOffer(uint256 offerId)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      uint256,
      uint256
    );

  /**
   * @notice Returns price in buyertokens for the specified amount of offertokens
   * @param offerId The offer Id
   * @param amount The amount of offer tokens
   * @return The total amount to pay
   **/
  function pricePreview(uint256 offerId, uint256 amount)
    external
    view
    returns (uint256);

  /**
   * @notice Whitelist or unwhitelist a token
   * @param tokens The token addresses
   * @param types The token whitelist status, true for whitelisted and false for unwhitelisted
   **/
  function toggleWhitelistWithType(
    address[] calldata tokens,
    TokenType[] calldata types
  ) external;

  /**
   * @notice In case someone wrongfully directly sends erc20 to this contract address, the moderator can move them out
   * @param token The token address
   **/
  function saveLostTokens(address token) external;

  /**
   * @notice Admin sets the fee
   * @param fee The new fee basic points
   **/
  function setFee(uint256 fee) external;

  /**
   * @notice Creates a new offer or updates an existing offer (call this again with the changed price + offerId)
   * @param _offerTokens The array addresses of the tokens to be sold
   * @param _buyerTokens The array addresses of the tokens to be bought
   * @param _buyers The array addresses of the allowed buyers (zero address means anyone can buy)
   * @param _prices The array prices in base units of the tokens to be sold
   * @param _amounts The array amounts of the offer tokens
   **/
  function createOfferBatch(
    address[] calldata _offerTokens,
    address[] calldata _buyerTokens,
    address[] calldata _buyers,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Updates an array of existing offers
   * @param _offerIds The array Ids of the offers
   * @param _prices The array prices in base units of the tokens to be sold
   * @param _amounts The array amounts of the offer tokens
   **/
  function updateOfferBatch(
    uint256[] calldata _offerIds,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Accepts an existing offer
   * @notice The buyer must bring the price correctly to ensure no frontrunning / changed offer
   * @notice If the offer is changed in meantime, it will not execute
   * @param _offerIds The array Ids of the offers
   * @param _prices The array prices in base units of the offer tokens
   * @param _amounts The array amounts of offer tokens
   **/
  function buyOfferBatch(
    uint256[] calldata _offerIds,
    uint256[] calldata _prices,
    uint256[] calldata _amounts
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeToken {
  function rules() external view returns (uint256[] memory, uint256[] memory);

  function rule(uint256 ruleId) external view returns (uint256, uint256);

  function owner() external view returns (address);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool);

  function canTransfer(
    address _from,
    address _to,
    uint256 _amount
  )
    external
    view
    returns (
      bool,
      uint256,
      uint256
    );

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: CNU

/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity ^0.8.0;

/**
 * @title IComplianceRegistry
 * @dev IComplianceRegistry interface
 **/
interface IComplianceRegistry {
  event AddressAttached(
    address indexed trustedIntermediary,
    uint256 indexed userId,
    address indexed address_
  );
  event AddressDetached(
    address indexed trustedIntermediary,
    uint256 indexed userId,
    address indexed address_
  );

  function userId(address[] calldata _trustedIntermediaries, address _address)
    external
    view
    returns (uint256, address);

  function validUntil(address _trustedIntermediary, uint256 _userId)
    external
    view
    returns (uint256);

  function attribute(
    address _trustedIntermediary,
    uint256 _userId,
    uint256 _key
  ) external view returns (uint256);

  function attributes(
    address _trustedIntermediary,
    uint256 _userId,
    uint256[] calldata _keys
  ) external view returns (uint256[] memory);

  function isAddressValid(
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (bool);

  function isValid(address _trustedIntermediary, uint256 _userId)
    external
    view
    returns (bool);

  function registerUser(
    address _address,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function registerUsers(
    address[] calldata _addresses,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function attachAddress(uint256 _userId, address _address) external;

  function attachAddresses(
    uint256[] calldata _userIds,
    address[] calldata _addresses
  ) external;

  function detachAddress(address _address) external;

  function detachAddresses(address[] calldata _addresses) external;

  function updateUserAttributes(
    uint256 _userId,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function updateUsersAttributes(
    uint256[] calldata _userIds,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function updateTransfers(
    address _realm,
    address _from,
    address _to,
    uint256 _value
  ) external;

  function monthlyTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function monthlyInTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyInTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function monthlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function addOnHoldTransfer(
    address trustedIntermediary,
    address token,
    address from,
    address to,
    uint256 amount
  ) external;

  function getOnHoldTransfers(address trustedIntermediary)
    external
    view
    returns (
      uint256 length,
      uint256[] memory id,
      address[] memory token,
      address[] memory from,
      address[] memory to,
      uint256[] memory amount
    );

  function processOnHoldTransfers(
    uint256[] calldata transfers,
    uint8[] calldata transferDecisions,
    bool skipMinBoundaryUpdate
  ) external;

  function updateOnHoldMinBoundary(uint256 maxIterations) external;

  event TransferOnHold(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferApproved(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferRejected(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferCancelled(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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