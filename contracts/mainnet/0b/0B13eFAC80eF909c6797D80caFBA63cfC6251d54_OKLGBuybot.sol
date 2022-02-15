// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './OKLGAffiliate.sol';

/**
 * @title OKLGBuybot
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
contract OKLGBuybot is OKLGAffiliate {
  AggregatorV3Interface internal priceFeed;

  uint256 public totalSpentWei = 0;
  uint256 public paidPricePerDayUsd = 15;
  mapping(address => uint256) public overridePricePerDayUSD;
  mapping(address => bool) public removeCost;
  event SetupBot(
    address indexed user,
    address token,
    string client,
    string channel,
    uint256 expiration
  );
  event SetupBotAdmin(
    address indexed user,
    address token,
    string client,
    string channel,
    uint256 expiration
  );
  event DeleteBot(
    address indexed user,
    address token,
    string client,
    string channel
  );

  struct Buybot {
    address token;
    string client; // telegram, discord, etc.
    string channel;
    bool isPaid;
    uint256 minThresholdUsd;
    // lpPairAltToken?: string; // if blank, assume the other token in the pair is native (ETH, BNB, etc.)
    uint256 expiration; // unix timestamp of expiration, or 0 if no expiration
  }
  mapping(bytes32 => Buybot) public buybotConfigs;
  bytes32[] public buybotConfigsList;

  constructor(address _linkPriceFeedContract) {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    priceFeed = AggregatorV3Interface(_linkPriceFeedContract);
  }

  function getAllBuybotIds() external view returns (bytes32[] memory) {
    return buybotConfigsList;
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getLatestETHPrice() public view returns (uint256) {
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function setPriceFeed(address _feedContract) external onlyOwner {
    priceFeed = AggregatorV3Interface(_feedContract);
  }

  function setOverridePricePerDayUSD(address _wallet, uint256 _priceUSD)
    external
    onlyOwner
  {
    overridePricePerDayUSD[_wallet] = _priceUSD;
  }

  function setOverridePricesPerDayUSDBulk(
    address[] memory _contracts,
    uint256[] memory _pricesUSD
  ) external onlyOwner {
    require(
      _contracts.length == _pricesUSD.length,
      'arrays need to be the same length'
    );
    for (uint256 _i = 0; _i < _contracts.length; _i++) {
      overridePricePerDayUSD[_contracts[_i]] = _pricesUSD[_i];
    }
  }

  function setRemoveCost(address _wallet, bool _isRemoved) external onlyOwner {
    removeCost[_wallet] = _isRemoved;
  }

  function getId(
    address _token,
    string memory _client,
    string memory _channel
  ) public pure returns (bytes32) {
    return sha256(abi.encodePacked(_token, _client, _channel));
  }

  function setupBot(
    address _token,
    string memory _client,
    string memory _channel,
    bool _isPaid,
    uint256 _minThresholdUsd,
    address _referrer
  ) external payable {
    require(!_isPaid || msg.value > 0, 'must send some ETH to pay for bot');

    uint256 _costPerDayUSD = overridePricePerDayUSD[msg.sender] > 0
      ? overridePricePerDayUSD[msg.sender]
      : paidPricePerDayUsd;

    if (_isPaid && !removeCost[msg.sender]) {
      pay(msg.sender, _referrer, msg.value);
      totalSpentWei += msg.value;
    } else {
      _costPerDayUSD = 0;
    }

    uint256 _daysOfService18 = 30 * 10**18;
    if (_costPerDayUSD > 0) {
      uint256 _ethPriceUSD18 = getLatestETHPrice();
      _daysOfService18 = (msg.value * _ethPriceUSD18) / 10**18 / _costPerDayUSD;
    }

    uint256 _secondsOfService = (_daysOfService18 * 24 * 60 * 60) / 10**18;
    bytes32 _id = getId(_token, _client, _channel);

    Buybot storage _bot = buybotConfigs[_id];
    if (_bot.expiration == 0) {
      buybotConfigsList.push(_id);
    }
    uint256 _start = _bot.expiration < block.timestamp
      ? block.timestamp
      : _bot.expiration;

    _bot.token = _token;
    _bot.isPaid = _isPaid;
    _bot.client = _client;
    _bot.channel = _channel;
    _bot.minThresholdUsd = _minThresholdUsd;
    _bot.expiration = _start + _secondsOfService;
    emit SetupBot(msg.sender, _token, _client, _channel, _bot.expiration);
  }

  function setupBotAdmin(
    address _token,
    string memory _client,
    string memory _channel,
    bool _isPaid,
    uint256 _minThresholdUsd,
    uint256 _expiration
  ) external onlyOwner {
    bytes32 _id = getId(_token, _client, _channel);
    Buybot storage _bot = buybotConfigs[_id];
    if (_bot.expiration == 0) {
      buybotConfigsList.push(_id);
    }
    _bot.token = _token;
    _bot.isPaid = _isPaid;
    _bot.client = _client;
    _bot.channel = _channel;
    _bot.minThresholdUsd = _minThresholdUsd;
    _bot.expiration = _expiration;
    emit SetupBotAdmin(msg.sender, _token, _client, _channel, _bot.expiration);
  }

  function deleteBot(
    address _token,
    string memory _client,
    string memory _channel
  ) external onlyOwner {
    bytes32 _id = getId(_token, _client, _channel);
    delete buybotConfigs[_id];
    for (uint256 _i = 0; _i < buybotConfigsList.length; _i++) {
      if (buybotConfigsList[_i] == _id) {
        buybotConfigsList[_i] = buybotConfigsList[buybotConfigsList.length - 1];
        buybotConfigsList.pop();
      }
    }
    emit DeleteBot(msg.sender, _token, _client, _channel);
  }

  function setPricePerDayUsd(uint256 _price) external onlyOwner {
    paidPricePerDayUsd = _price;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
pragma solidity ^0.8.4;

import './OKLGWithdrawable.sol';

/**
 * @title OKLGAffiliate
 * @dev Support affiliate logic
 */
contract OKLGAffiliate is OKLGWithdrawable {
  modifier onlyAffiliateOrOwner() {
    require(
      msg.sender == owner() || affiliates[msg.sender] > 0,
      'caller must be affiliate or owner'
    );
    _;
  }

  uint16 public constant PERCENT_DENOMENATOR = 10000;
  address public paymentWallet = 0x0000000000000000000000000000000000000000;

  mapping(address => uint256) public affiliates; // value is percentage of fees for affiliate (denomenator of 10000)
  mapping(address => uint256) public discounts; // value is percentage off for user (denomenator of 10000)

  event AddAffiliate(address indexed wallet, uint256 percent);
  event RemoveAffiliate(address indexed wallet);
  event AddDiscount(address indexed wallet, uint256 percent);
  event RemoveDiscount(address indexed wallet);
  event Pay(address indexed payee, uint256 amount);

  function pay(
    address _caller,
    address _referrer,
    uint256 _basePrice
  ) internal {
    uint256 price = getFinalPrice(_caller, _basePrice);
    require(msg.value >= price, 'not enough ETH to pay');

    // affiliate fee if applicable
    if (affiliates[_referrer] > 0) {
      uint256 referrerFee = (price * affiliates[_referrer]) /
        PERCENT_DENOMENATOR;
      (bool sent, ) = payable(_referrer).call{ value: referrerFee }('');
      require(sent, 'affiliate payment did not go through');
      price -= referrerFee;
    }

    // if affiliate does not take everything, send normal payment
    if (price > 0) {
      address wallet = paymentWallet == address(0) ? owner() : paymentWallet;
      (bool sent, ) = payable(wallet).call{ value: price }('');
      require(sent, 'main payment did not go through');
    }
    emit Pay(msg.sender, _basePrice);
  }

  function getFinalPrice(address _caller, uint256 _basePrice)
    public
    view
    returns (uint256)
  {
    if (discounts[_caller] > 0) {
      return
        _basePrice - ((_basePrice * discounts[_caller]) / PERCENT_DENOMENATOR);
    }
    return _basePrice;
  }

  function addDiscount(address _wallet, uint256 _percent)
    external
    onlyAffiliateOrOwner
  {
    require(
      _percent <= PERCENT_DENOMENATOR,
      'cannot have more than 100% discount'
    );
    discounts[_wallet] = _percent;
    emit AddDiscount(_wallet, _percent);
  }

  function removeDiscount(address _wallet) external onlyAffiliateOrOwner {
    require(discounts[_wallet] > 0, 'affiliate must exist');
    delete discounts[_wallet];
    emit RemoveDiscount(_wallet);
  }

  function addAffiliate(address _wallet, uint256 _percent) external onlyOwner {
    require(
      _percent <= PERCENT_DENOMENATOR,
      'cannot have more than 100% referral fee'
    );
    affiliates[_wallet] = _percent;
    emit AddAffiliate(_wallet, _percent);
  }

  function removeAffiliate(address _wallet) external onlyOwner {
    require(affiliates[_wallet] > 0, 'affiliate must exist');
    delete affiliates[_wallet];
    emit RemoveAffiliate(_wallet);
  }

  function setPaymentWallet(address _wallet) external onlyOwner {
    paymentWallet = _wallet;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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