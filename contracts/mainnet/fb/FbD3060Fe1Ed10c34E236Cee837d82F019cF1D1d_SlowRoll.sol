//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title interfact to interact with ERC20 tokens
/// @author elee

interface IERC20 {
  function mint(address account, uint256 amount) external;

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @title slowroll is the third gen wave contract
// solhint-disable comprehensive-interface
contract SlowRoll {

  /// user defined variables
  uint256 public _maxQuantity; // max quantity available in wave
  uint64 public _startPrice; // start price
  uint64 public _maxPrice; // max price
  uint64 public _waveDuration; // duration, in seconds, of the next wave
  /// end user defined variables

  /// contract controlled values
  uint64 public _endTime; // start time of the wave + waveDuration
  uint256 public _soldQuantity; // amount currently sold in wave
  /// end contract controlled values


  // the token used to claim points, USDC
  IERC20 public _pointsToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // usdc
  // the token to be rewarded, IPT
  IERC20 public immutable _rewardToken = IERC20(0xd909C5862Cdb164aDB949D92622082f0092eFC3d); // IPT
  // light ownership
  address public _owner;

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  constructor() {
    _owner = msg.sender; // creator of contracto
    _maxQuantity = 1_000_000 * 1e18; // 1_00_000 IPT, in wei - max IPT sold per day
    _startPrice = 250_000; // 25 cents
    _maxPrice = 500_000; // 50 cents
    _waveDuration = 60*60*22; // 22 hours in seconds
  }

  function setMaxQuantity(uint256 maxQuantity_) external onlyOwner {
    _maxQuantity = maxQuantity_;
  }
  function setStartPrice(uint64 startPrice_) external onlyOwner {
    _startPrice = startPrice_;
    require(_startPrice < _maxPrice,"start not < max");
  }
  function setMaxPrice(uint64 maxPrice_) external onlyOwner {
    _maxPrice = maxPrice_;
    require(_startPrice < _maxPrice,"start not < max");
  }
  function setWaveDuration(uint64 waveDuration_) external onlyOwner {
    _waveDuration = waveDuration_;
  }

  function forceNewDay() external onlyOwner {
    new_day();
  }
  ///@notice sends reward tokens to the receiver
  function withdraw(uint256 amount) external onlyOwner {
    giveTo(_owner, amount);
  }

  ///@notice a view only convenience getter
  function getCurrentPrice() external view returns (uint256) {
    return current_price();
  }

  /// @notice submit usdc to be converted
  /// @param amount amount of usdc
  function getPoints(
    uint256 amount
  ) public {
    try_new_day();
    uint256 currentPrice = current_price();
    uint256 rewardAmount = reward_amount(amount, currentPrice);
    _soldQuantity = _soldQuantity + rewardAmount;
    require(canClaim(), "Cap reached");
    takeFrom(msg.sender, amount);
    giveTo(msg.sender, rewardAmount);
  }

  /// ALL FUNCTIONS BELOW SHOULD BE INTERNAL

  function canClaim() internal view returns (bool){
    return _maxQuantity >= _soldQuantity;
  }

  function try_new_day() internal {
    if(uint64(block.timestamp) > _endTime) {
      new_day();
    }
  }

  function new_day() internal {
    _soldQuantity = 0;
    _endTime = uint64(_waveDuration + block.timestamp);
  }

  // get the current price
  function current_price() internal view returns (uint256) {
    // this is sold %, in 1e18 terms, multiplied by the difference between the start and max current_price
    // this will give us the amount to increase the price, in 1e18 terms
    uint256 scalar = (_soldQuantity * 1e18 / _maxQuantity) * (_maxPrice - _startPrice);
    // the price therefore is that number / 1e18 + the start price
    return (scalar / 1e18) + _startPrice;
  }

  /// @notice note that usdc being 1e6 decimals is hard coded here, since our price is in 6 decimals as well.
  /// @param amount the amount of USDC
  /// @param price is the amount of USDC, in usdc base units, to buy 1e18 of IPT
  /// @return the amount of IPT that the usdc amount entitles to.
  function reward_amount(uint256 amount, uint256 price ) internal pure returns (uint256) {
    return 1e18 * amount / price;
  }

  /// @notice function which transfer the point token
  function takeFrom(address target, uint256 amount) internal {
    bool check = _pointsToken.transferFrom(target, _owner, amount);
    require(check, "erc20 transfer failed");
  }

  /// @notice function which sends the reward token
  function giveTo(address target, uint256 amount) internal {
    if (_rewardToken.balanceOf(address(this)) < amount) {
      amount = _rewardToken.balanceOf(address(this));
    }
    require(amount > 0, "cant redeem zero");
    bool check = _rewardToken.transfer(target, amount);
    require(check, "erc20 transfer failed");
  }
}
// solhint-enable comprehensive-interface