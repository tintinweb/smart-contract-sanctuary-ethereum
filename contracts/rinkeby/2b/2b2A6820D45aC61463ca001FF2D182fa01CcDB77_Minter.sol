//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GTokenERC20.sol';
import './AuctionHouse.sol';
import './base/Feed.sol';
import './DebtPool.sol';
import './base/CoreMath.sol';

contract Minter {
  using SafeMath for uint256;

  address public owner;

  GTokenERC20 public collateralToken;
  Feed public  collateralFeed;
  AuctionHouse auctionHouse;
  DebtPool debtPool;
  GTokenERC20[] public synths;

  uint256 public constant PENALTY_FEE = 11;
  uint256 public constant FLAG_TIP = 3 ether;
  uint public ratio = 9 ether;

  mapping (address => mapping (GTokenERC20 => uint256)) public collateralBalance;
  mapping (GTokenERC20 => uint256) public cRatioActive;
  mapping (GTokenERC20 => uint256) public cRatioPassive;
  mapping (GTokenERC20 => Feed) public feeds;
  mapping (address => mapping (GTokenERC20 => uint256)) public synthDebt;
  mapping (address => mapping (GTokenERC20 => uint256)) public auctionDebt;
  mapping (address => mapping (GTokenERC20 => uint256)) public plrDelay;

  // Events
  event CreateSynth(address token, string name, string symbol, address feed);
  event Mint(address indexed account, uint256 totalAmount);
  event Burn(address indexed account, address token, uint256 amount);
  event WithdrawnCollateral(address indexed account, address token, uint amount);
  event DepositedCollateral(address indexed account, address token, uint amount);

  // Events for liquidation
  event AccountFlaggedForLiquidation(address indexed account, address indexed keeper, uint256 deadline);
  event Liquidate(address indexed accountLiquidated, address indexed accountFrom, address token);

  event AuctionFinish(uint256 indexed id, address user, uint256 finished_at);

  modifier onlyOwner() {
    require(msg.sender == owner, 'unauthorized');
    _;
  }

  modifier isCollateral(GTokenERC20 token) {
    require(address(token) != address(collateralToken), 'invalid token');
    _;
  }

  modifier isValidKeeper(address user) {
    require(user != address(msg.sender), 'Sender cannot be the liquidated');
    _;
  }

  modifier onlyDebtPool() {
    require(address(debtPool) == address(msg.sender), 'Only permitted contract!');
    _;
  }

  constructor(address collateralToken_, address collateralFeed_, address auctionHouse_) {
    collateralToken = GTokenERC20(collateralToken_);
    collateralFeed  = Feed(collateralFeed_);
    auctionHouse  = AuctionHouse(auctionHouse_);
    owner = msg.sender;
  }

  function addDebtPool(address debtPool_) public onlyOwner {
    debtPool = DebtPool(debtPool_);
  }

  function getSynth(uint256 index) public view returns (GTokenERC20) {
    return synths[index];
  }

  function createSynth(string calldata name, string calldata symbol, uint initialSupply, uint256 cRatioActive_, uint256 cRatioPassive_, Feed feed) external onlyOwner {
    require(cRatioPassive_ > cRatioActive_, 'Invalid cRatioActive');

    uint id = synths.length;
    GTokenERC20 token = new GTokenERC20(name, symbol, initialSupply);
    synths.push(token);
    cRatioActive[synths[id]] = cRatioActive_;
    cRatioPassive[synths[id]] = cRatioPassive_;
    feeds[synths[id]] = feed;

    emit CreateSynth(address(token), name, symbol, address(feed));
  }

  function withdrawnCollateral(GTokenERC20 token, uint256 amount) external {
    require(collateralBalance[msg.sender][token] >= amount, 'Insufficient quantity');
    uint256 futureCollateralValue = (collateralBalance[msg.sender][token] - amount) * collateralFeed.price() / 1 ether;
    uint256 debtValue = globalAccountDebt(token, address(msg.sender)) * feeds[token].price() / 1 ether;
    require(futureCollateralValue >= debtValue * cRatioActive[token] / 100, 'below cRatio');

    collateralBalance[msg.sender][token] -= amount;
    collateralToken.transfer(msg.sender, amount);

    emit WithdrawnCollateral(msg.sender, address(token), amount);
  }

  function mint(GTokenERC20 token, uint256 amountToDeposit, uint256 amountToMint) external isCollateral(token) {
    collateralToken.approve(msg.sender, amountToDeposit);
    require(collateralToken.transferFrom(msg.sender, address(this), amountToDeposit), 'transfer failed');
    collateralBalance[msg.sender][token] += amountToDeposit;

    emit DepositedCollateral(msg.sender, address(token), amountToDeposit);

    require(collateralBalance[msg.sender][token] > 0, 'Without collateral deposit');
    uint256 futureCollateralValue = collateralBalance[msg.sender][token] * collateralFeed.price() / 1 ether;
    uint256 futureDebtValue = (globalAccountDebt(token, address(msg.sender)) + amountToMint) * feeds[token].price() / 1 ether;
    require((futureCollateralValue / futureDebtValue) * 1 ether >= ratio, 'Above max amount');

    token.mint(msg.sender, amountToMint);
    synthDebt[msg.sender][token] += amountToMint;

    emit Mint(msg.sender, synthDebt[msg.sender][token]);
  }


  function burn(GTokenERC20 token, uint256 amount) external {
    require(token.transferFrom(msg.sender, address(this), amount), 'transfer failed');
    token.burn(amount);
    synthDebt[msg.sender][token] -= amount;

    emit Burn(msg.sender, address(token), amount);
  }

  function debtPoolMint(GTokenERC20 token, uint256 amount) public onlyDebtPool {
    synthDebt[msg.sender][token] += amount;
    token.mint(msg.sender, amount);
  }

  function debtPoolBurn(GTokenERC20 token, uint256 amount) public onlyDebtPool {
    if (synthDebt[msg.sender][token] > 0) {
      synthDebt[msg.sender][token] -= amount;
    }

    token.burn(amount);
  }

  function globalAccountDebt(GTokenERC20 token, address account) internal returns (uint256) {
    uint poolDebtPerToken = synthDebt[address(debtPool)][token] / (token.totalSupply() - synthDebt[address(debtPool)][token]);

    return synthDebt[account][token] + (synthDebt[account][token] * poolDebtPerToken);
  }

  function liquidate(address user, GTokenERC20 token) external isValidKeeper(user) {
    require(plrDelay[user][token] > 0);
    Feed syntFeed = feeds[token];
    uint256 priceFeed = collateralFeed.price();
    uint256 collateralValue = (collateralBalance[user][token] * priceFeed) / 1 ether;
    // uint256 debtValue = synthDebt[user][token] * syntFeed.price() / 1 ether;
    uint256 debtValue = globalAccountDebt(token, address(user)) * syntFeed.price() / 1 ether;
    require((collateralValue < debtValue * cRatioActive[token] / 100) || (collateralValue < debtValue * cRatioPassive[token] / 100 && plrDelay[user][token] < block.timestamp), 'above cRatio');

    collateralToken.approve(address(auctionHouse), collateralBalance[user][token]);
    {
      uint debtAmountTransferable = debtValue / 10;
      _mintPenalty(token, user, msg.sender, debtAmountTransferable);
      _transferLiquidate(token, msg.sender, debtAmountTransferable);
      auctionDebt[user][token] += synthDebt[user][token];
      uint256 collateralBalance = collateralBalance[user][token];
      uint256 auctionDebt = (auctionDebt[user][token] * syntFeed.price()) / 1 ether;
      auctionHouse.start(user, address(token), address(collateralToken), msg.sender, collateralBalance, collateralValue, auctionDebt, priceFeed);
      updateCollateralAndSynthDebt(user, token);

      emit Liquidate(user, msg.sender, address(token));
    }
  }

  function updateCollateralAndSynthDebt(address user, GTokenERC20 token) private {
    collateralBalance[user][token] = 0;
    synthDebt[user][token] = 0;
  }

  function auctionFinish(uint256 auctionId, address user, GTokenERC20 collateralToken, GTokenERC20 synthToken, uint256 collateralAmount, uint256 synthAmount) public {
    require(address(auctionHouse) == msg.sender, 'Only auction house!');
    require(collateralToken.transferFrom(msg.sender, address(this), collateralAmount), 'transfer failed');
    require(synthToken.transferFrom(msg.sender, address(this), synthAmount), 'transfer failed');
    synthToken.burn(synthAmount);

    collateralBalance[user][synthToken] = collateralAmount;
    auctionDebt[user][synthToken] -= synthAmount;
    plrDelay[user][synthToken] = 0;

    emit AuctionFinish(auctionId, user, block.timestamp);
  }

  function flagLiquidate(address user, GTokenERC20 token) external isValidKeeper(user) {
    require(plrDelay[user][token] < block.timestamp);
    require(collateralBalance[user][token] > 0 && synthDebt[user][token] > 0, 'User cannot be flagged for liquidate');

    uint256 collateralValue = (collateralBalance[user][token] * collateralFeed.price()) / 1 ether;
    uint256 debtValue = synthDebt[user][token] * feeds[token].price() / 1 ether;
    require(collateralValue < debtValue * cRatioPassive[token] / 100, "Above cRatioPassivo");
    plrDelay[user][token] = block.timestamp + 10 days;

    _mintPenalty(token, user, msg.sender, FLAG_TIP);

    emit AccountFlaggedForLiquidation(user, msg.sender, plrDelay[user][token]);
  }

  function settleDebt(address user, GTokenERC20 token, uint amount) public {}

  function balanceOfSynth(address from, GTokenERC20 token) external view returns (uint) {
    return token.balanceOf(from);
  }

  function updateSynthCRatio(GTokenERC20 token, uint256 cRatio_, uint256 cRatioPassivo_) external onlyOwner {
    require(cRatioPassivo_ > cRatio_, 'invalid cRatio');
    cRatioActive[token] = cRatio_;
    cRatioPassive[token] = cRatioPassivo_;
  }

  function _mintPenalty(GTokenERC20 token, address user, address keeper, uint256 amount) public {
    token.mint(address(keeper), amount);
    synthDebt[address(user)][token] += amount;
  }

  // address riskReserveAddress, address liquidationVaultAddress
  function _transferLiquidate(GTokenERC20 token, address keeper, uint256 amount) public {
    uint keeperAmount = (amount / 100) * 60;
    // uint restAmount = (amount / 100) * 20;
    require(token.transfer(address(keeper), keeperAmount), 'failed transfer incentive');
    // token.transfer(address(riskReserveAddress), restAmount);
    // token.transfer(address(liquidationVaultAddress), restAmount);
  }

  function getCRatio(GTokenERC20 token) external view returns (uint256) {
    if (collateralBalance[msg.sender][token] == 0 || synthDebt[msg.sender][token] == 0) {
      return 0;
    }

    uint256 collateralValue = collateralBalance[msg.sender][token] * collateralFeed.price() / 1 ether;
    uint256 debtValue = synthDebt[msg.sender][token] * feeds[token].price() / 1 ether;

    return collateralValue.mul(1 ether).div(debtValue);
  }

  function maximumByCollateral(GTokenERC20 token, uint256 amount) external view returns (uint256) {
    require(amount != 0, 'Incorrect values');
    uint256 collateralValue = (collateralBalance[msg.sender][token] + amount) * collateralFeed.price() / 1 ether;

    return (collateralValue / ratio) * 1 ether;
  }

  function maximumByDebt(GTokenERC20 token, uint256 amount) external view returns (uint256) {
    require(amount != 0, 'Incorrect values');
    uint256 debtValue = (synthDebt[msg.sender][token] + amount) * feeds[token].price() / 1 ether;

    return (debtValue * ratio) / 1 ether;
  }

  function simulateCRatio(GTokenERC20 token, uint256 amountGHO, uint256 amountGDAI) external view returns (uint256) {
    require(amountGHO != 0 || amountGDAI != 0, 'Incorrect values');
    uint256 collateralValue = (collateralBalance[msg.sender][token] + amountGHO) * collateralFeed.price() / 1 ether;
    uint256 debtValue = (synthDebt[msg.sender][token] + amountGDAI) * feeds[token].price() / 1 ether;

    return collateralValue.mul(1 ether).div(debtValue);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GTokenERC20 is ERC20, Ownable, Pausable {

  constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20(name_, symbol_) {
    _mint(msg.sender, initialSupply);
  }

  function mint(address receiver, uint amount) external onlyOwner {
    _mint(receiver, amount);
  }

  function burn(uint256 amount) external  {
    _burn(msg.sender, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GTokenERC20.sol';
import './Minter.sol';
import './base/Feed.sol';
import './base/CoreMath.sol';

contract AuctionHouse is CoreMath {
  struct Auction {
    address user;
    address tokenAddress;
    address collateralTokenAddress;
    address keeperAddress;
    uint256 collateralBalance;
    uint256 collateralValue;
    uint256 synthAmount;
    uint256 auctionTarget;
    uint256 initialFeedPrice;
    address minterAddress;
    uint startTimestamp;
    uint endTimestamp;
  }

  uint256 constant PRICE_REDUCTION_RATIO = (uint256(99) * RAY) / 100;
  uint256 constant ratio = 9;
  uint256 constant buf = 1 ether;
  uint256 constant step = 90;
  uint256 constant dust = 10 ether;
  uint256 constant PENALTY_FEE = 11;
  uint256 constant chost = (dust * PENALTY_FEE) / 10;

  Auction[] public auctions;

  event Start(address indexed cdp, address indexed keeper, uint amount, uint start, uint end);
  event Take(uint256 indexed id, address indexed keeper, address indexed to, uint256 amount, uint256 price, uint256 end);

  function start (
    address user_,
    address tokenAddress_,
    address collateralTokenAddress_,
    address keeperAddress_,
    uint256 collateralBalance_,
    uint256 collateralValue_,
    uint256 auctionTarget_,
    uint256 initialFeedPrice_
  ) public {
    uint256 startTimestamp_ = block.timestamp;
    uint256 endTimestamp_ = startTimestamp_ + 1 weeks;

    auctions.push(
      Auction(
        user_,
        tokenAddress_,
        collateralTokenAddress_,
        keeperAddress_,
        collateralBalance_,
        collateralValue_,
        0,
        auctionTarget_,
        initialFeedPrice_,
        msg.sender,
        startTimestamp_,
        endTimestamp_
      )
    );

    emit Start(tokenAddress_, keeperAddress_, collateralBalance_, startTimestamp_, endTimestamp_);
    require(GTokenERC20(collateralTokenAddress_).transferFrom(msg.sender, address(this), collateralBalance_), "token transfer fail");
  }

  function take(uint256 auctionId, uint256 amount, uint256 maxCollateralPrice, address receiver) public  {
    Auction storage auction = auctions[auctionId];
    uint slice;
    uint keeperAmount;

    require(amount > 0 && auction.auctionTarget > 0, 'Invalid amount or auction finished');
    require(block.timestamp > auction.startTimestamp && block.timestamp < auction.endTimestamp, 'Auction period invalid');
    if (amount > auction.collateralBalance) {
      slice = auction.collateralBalance;
    } else {
      slice = amount;
    }

    uint priceTimeHouse = price(auction.initialFeedPrice, block.timestamp - auction.startTimestamp);
    require(maxCollateralPrice >= priceTimeHouse, 'price time house is bigger than collateral price');

    uint owe = mul(slice, priceTimeHouse) / WAD;
    uint liquidationTarget = calculateAmountToFixCollateral(auction.auctionTarget, (auction.collateralBalance * priceTimeHouse) / WAD);
    require(liquidationTarget > 0);

    if (liquidationTarget > owe) {
      keeperAmount = owe;

      if (auction.auctionTarget - owe >= chost) {
        slice = radiv(owe, priceTimeHouse);
        auction.auctionTarget -= owe;
        auction.collateralBalance -= slice;
      } else {
        require(auction.auctionTarget > chost, 'No partial purchase');
        slice = radiv((auction.auctionTarget - chost), priceTimeHouse);
        auction.auctionTarget = chost;
        auction.collateralBalance -= slice;
      }

      auction.synthAmount += mul(slice, priceTimeHouse) / WAD;
    } else {
      keeperAmount = liquidationTarget;
      slice = radiv(liquidationTarget, priceTimeHouse);
      auction.auctionTarget = 0;
      auction.collateralBalance -= slice;
      auction.synthAmount += keeperAmount;
    }


    GTokenERC20 synthToken = GTokenERC20(auction.tokenAddress);
    GTokenERC20 collateralToken = GTokenERC20(auction.collateralTokenAddress);

    require(synthToken.transferFrom(msg.sender, address(this), keeperAmount), 'transfer token from keeper fail');
    require(collateralToken.transfer(receiver, slice), "transfer token to keeper fail");

    if (auction.auctionTarget == 0) {
      collateralToken.approve(address(auction.minterAddress), auction.collateralBalance);
      synthToken.approve(address(auction.minterAddress), auction.synthAmount);

      auctionFinishCallback(
        auctionId,
        Minter(auction.minterAddress),
        address(auction.user),
        collateralToken,
        synthToken,
        auction.collateralBalance,
        auction.synthAmount
      );
    }

    emit Take(auctionId, msg.sender, receiver, slice, priceTimeHouse, auction.endTimestamp);
  }

  function calculateAmountToFixCollateral(uint256 debtBalance, uint256 collateral) public pure returns (uint) {
    uint dividend = (ratio * debtBalance) - collateral;

    return dividend / (ratio - 1);
  }

  function getAuction(uint auctionId) public view returns (Auction memory) {
    return auctions[auctionId];
  }

  function price(uint256 initialPrice, uint256 duration) public pure returns (uint256) {
    return rmul(initialPrice, rpow(PRICE_REDUCTION_RATIO, duration / step, RAY));
  }

  function auctionFinishCallback(uint256 id, Minter minter, address user, GTokenERC20 tokenCollateral, GTokenERC20 synthToken, uint256 collateralBalance, uint256 synthAmount) public {
    minter.auctionFinish(id, user, tokenCollateral, synthToken, collateralBalance, synthAmount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Feed {
  uint256 public price;
  string public name;

  constructor(uint price_, string memory name_) {
    price = price_;
    name = name_;
  }

  function updatePrice(uint price_) public {
    price = price_;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './GTokenERC20.sol';
import './UpdateHouse.sol';
import './Minter.sol';

contract DebtPool is Ownable {

  GTokenERC20 public token;
  Minter public minter;
  UpdateHouse public updateHouse;

  modifier onlyHouse() {
    require(msg.sender == address(updateHouse), 'Is not update house');
    _;
  }

  constructor(address token_, address minter_) {
    token = GTokenERC20(token_);
    minter = Minter(minter_);
  }

  function addUpdatedHouse(address updated_) public onlyOwner {
    updateHouse = UpdateHouse(updated_);
  }

  function mint(uint256 amount) public onlyHouse {
    minter.debtPoolMint(token, amount);
  }

  function burn(uint256 amount) public onlyHouse {
    minter.debtPoolBurn(token, amount);
  }

  function transferFrom(address receiver, uint256 amount) public onlyHouse {
    token.transfer(receiver, amount);
  }

  function getSynthDebt() public returns (uint256) {
    return minter.synthDebt(address(this), token);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract CoreMath {
  using SafeMath for uint256;

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;
  uint256 constant RAD = 10**45;

  function wad() public pure returns (uint256) {
    return WAD;
  }

  function ray() public pure returns (uint256) {
    return RAY;
  }

  function rad() public pure returns (uint256) {
    return RAD;
  }
  function radiv(uint256 dividend, uint256 divisor) public pure returns (uint256) {
    return div(div(dividend * RAD, divisor), RAY);
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = mul(x, y);
    require(y == 0 || z / y == x);
    z = div(z, RAY);
  }

  function orderToSub(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b > a) {
      return 0;
    }

    return a - b;
  }

  function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
    assembly {
      switch n case 0 { z := b }
      default {
        switch x case 0 { z := 0 }
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if shr(128, x) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x * y;
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x / y;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './oracle/GSpot.sol';
import './base/CoreMath.sol';
import './DebtPool.sol';
import './GTokenERC20.sol';
import './PositionVault.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract UpdateHouse is CoreMath, Ownable {

  using SafeMath for uint256;

  GTokenERC20 public token;
  GSpot public spot;
  DebtPool public debtPool;
  PositionVault public vault;
  address staker;

  enum Direction{ UNSET, SHORT, LONG }
  enum Status { UNSET, OPEN, FINISHED }

  struct PositionData {
    address account;
    Direction direction;
    Status status;
    bytes32 synth;
    uint256 averagePrice;
    uint256 lastSynthPrice;
    uint256 tokenAmount;
    uint256 synthTokenAmount;
    uint256 created_at;
    uint256 updated_at;
  }

  uint positionCount;

  mapping (uint => PositionData) public data;

  event Create(address account, PositionData data);
  event Finish(address account, Direction direction, Status status);
  event Increase(address account, PositionData data);
  event Decrease(address account, PositionData data);
  event Winner(address account, uint256 amount);
  event Loser(address account, uint256 amount);

  constructor(GTokenERC20 token_, GSpot spot_, DebtPool debtPool_) {
    token = GTokenERC20(token_);
    spot = GSpot(spot_);
    debtPool = DebtPool(debtPool_);
  }

  function setVault() public onlyOwner {
    vault = new PositionVault(token, address(this));
  }

  function getVault() public view returns (address) {
    return address(vault);
  }

  function createPosition(uint256 amount, bytes32 synthKey, Direction direction_) external {
    require(amount > 0, 'Invalid amount');
    require(direction_ == Direction.SHORT || direction_ == Direction.LONG, "Invalid position option");

    uint256 initialPrice = spot.read(synthKey);
    require(initialPrice > 0);

    PositionData memory dataPosition = _create(msg.sender, direction_, synthKey, initialPrice, amount);
    _addPositionVault(positionCount, address(msg.sender), amount);

    emit Create(msg.sender, dataPosition);
  }

  function increasePosition(uint index, uint256 deltaAmount) external {
    PositionData storage dataPosition = data[index];
    require(dataPosition.account == msg.sender && dataPosition.status != Status.FINISHED);
    uint256 currentPrice = spot.read(dataPosition.synth);
    require(currentPrice > 0, 'Invalid synth price');
    _addPositionVault(index, address(msg.sender), deltaAmount);

    uint256 newSynthTokenAmount = mul(deltaAmount, WAD).div(currentPrice);
    uint256 oldSynthPrice = div(dataPosition.synthTokenAmount.mul(dataPosition.averagePrice), WAD);
    uint256 newSynthPrice = div(newSynthTokenAmount.mul(currentPrice), WAD);
    uint256 averagePrice = div(mul(newSynthPrice.add(oldSynthPrice), WAD), dataPosition.synthTokenAmount.add(newSynthTokenAmount));

    dataPosition.averagePrice = averagePrice;
    dataPosition.tokenAmount += deltaAmount;
    dataPosition.synthTokenAmount = newSynthTokenAmount;
    emit Increase(msg.sender, dataPosition);
  }

  function decreasePosition(uint index, uint256 deltaAmount) external {
    PositionData storage dataPosition = data[index];
    require(dataPosition.account == msg.sender && dataPosition.status != Status.FINISHED);
    uint256 currentPrice = spot.read(dataPosition.synth);
    require(currentPrice > 0, 'Invalid synth price');

    int positionFixValue = getPositionFix(dataPosition.direction, dataPosition.synthTokenAmount, currentPrice, dataPosition.lastSynthPrice);
    uint256 oldTokenAmount = uint(int(dataPosition.tokenAmount) + positionFixValue);
    uint256 newTokenAmount = oldTokenAmount.sub(deltaAmount);
    uint256 newSynthTokenAmount = div(newTokenAmount.mul(dataPosition.synthTokenAmount), oldTokenAmount);
    uint256 tokenAmount = uint(int(newTokenAmount) - positionFixValue);
    require(tokenAmount == deltaAmount);

    dataPosition.tokenAmount -= tokenAmount;
    dataPosition.averagePrice = (newTokenAmount * WAD).div(newSynthTokenAmount);
    dataPosition.synthTokenAmount = newSynthTokenAmount;
    dataPosition.lastSynthPrice = currentPrice;

    _removePositionVault(index, address(msg.sender), tokenAmount);

    emit Decrease(msg.sender, dataPosition);
  }

  function finishPosition(uint index) external {
    PositionData storage dataPosition = data[index];
    require(dataPosition.account == msg.sender && dataPosition.status != Status.FINISHED, 'Invalid account or position already finished!');
    uint256 currentPrice = spot.read(dataPosition.synth);
    require(currentPrice > 0, 'Current price not valid!');

    int positionFixValue = getPositionFix(dataPosition.direction,
                                          dataPosition.synthTokenAmount,
                                          currentPrice,
                                          dataPosition.lastSynthPrice);

    uint256 currentPricePosition = uint(int(dataPosition.tokenAmount) + positionFixValue);

    uint256 amount = vault.withdrawFullDeposit(index);
    uint256 amountToReceive;
    if (currentPricePosition >= dataPosition.tokenAmount) {
      amountToReceive = currentPricePosition - dataPosition.tokenAmount;
      debtPool.mint(amountToReceive);

      vault.transferFrom(address(msg.sender), amount);
      debtPool.transferFrom(address(msg.sender), amountToReceive);

      emit Winner(address(msg.sender), amount + amountToReceive);
    } else {
      amountToReceive = amount - currentPricePosition;
      vault.transferFrom(address(debtPool), amountToReceive);
      debtPool.burn(amountToReceive);
      vault.transferFrom(address(msg.sender), currentPricePosition);

      emit Loser(address(msg.sender), currentPricePosition);
    }

    dataPosition.status = Status.FINISHED;
    dataPosition.updated_at = block.timestamp;
    data[index] = dataPosition;

    emit Finish(address(msg.sender), dataPosition.direction, dataPosition.status);
  }

  function _create(address account, Direction direction, bytes32 synthKey, uint256 price, uint256 amount) internal returns (PositionData memory) {
    PositionData memory dataPosition = PositionData(
      address(account),
      direction,
      Status.OPEN,
      synthKey,
      price,
      price,
      amount,
      radiv(amount, price),
      block.timestamp,
      block.timestamp
    );
    positionCount++;
    data[positionCount] = dataPosition;

    return dataPosition;
  }

  function getPositionFix(Direction direction, uint256 synthTokenAmount, uint256 currentTokenSynthAmount, uint256 lastTokenSynthAmount) public returns (int) {
    uint256 newPrice = synthTokenAmount.mul(currentTokenSynthAmount) / WAD;
    uint256 oldPrice = synthTokenAmount.mul(lastTokenSynthAmount) / WAD;

    int result = int(newPrice) - int(oldPrice);

    return result * (direction == Direction.SHORT ? int(-1) : int(1));
  }

  function _addPositionVault(uint index, address account, uint amount) internal {
    vault.addDeposit(index, account, amount);
  }

  function _removePositionVault(uint index, address account, uint amount) internal {
    vault.removeDeposit(index, account, amount);
  }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './Ssm.sol';

contract GSpot is Ownable {
  mapping (bytes32 => address) public oracles;

  function addSsm(bytes32 synth, address spot_) public onlyOwner {
    require(spot_ != address(0), "Invalid address");
    require(oracles[synth] == address(0), "Address already exists");
    oracles[synth] = spot_;
  }

  function peek(bytes32 synthKey) external view returns (uint256, bool) {
    (uint256 price, bool valid) = IMedian(oracles[synthKey]).peek();
    return (price, valid);
  }

  function read(bytes32 synthKey) external view returns (uint256) {
    return IMedian(oracles[synthKey]).read();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GTokenERC20.sol';

contract PositionVault {
  GTokenERC20 public token;
  address public owner;
  mapping (uint256 => uint256) public positionVaultData;

  constructor(GTokenERC20 _token, address _owner) {
    token = GTokenERC20(_token);
    owner = _owner;
  }

  modifier onlyOwner() {
    require(address(owner) == address(msg.sender), 'Only owner!');
    _;
  }

  function addDeposit(uint256 position, address account, uint256 amount) public onlyOwner {
    require(token.transferFrom(account, address(this), amount));
    positionVaultData[position] += amount;
  }

  function removeDeposit(uint256 position, address account, uint256 amount) public onlyOwner {
    positionVaultData[position] -= amount;
  }

  function withdrawFullDeposit(uint256 position) public onlyOwner returns (uint256) {
    require(positionVaultData[position] != 0, 'Invalid position');

    return positionVaultData[position];
  }

  function transferFrom(address receiver, uint256 amount) public onlyOwner {
    token.transfer(receiver, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IMedian.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Ssm is AccessControl {
  uint256 public stopped;
  bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
  modifier stoppable { require(stopped == 0, "Method stopped for ADMIN_ROLE"); _; }

  address public medianizer;
  uint16  constant ONE_HOUR = 1 hours;
  uint16  public hop = ONE_HOUR;
  uint64  public zzz;

  struct Feed {
    uint256 val;
    uint256 has;
  }

  event AddPrice(address sender, uint256 val);
  event ChangeMedian(address sender, address contractAddress);

  Feed cur;
  Feed nxt;

  constructor (address medianizer_) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    medianizer = medianizer_;
  }

  function stop() external onlyRole(DEFAULT_ADMIN_ROLE) {
    stopped = 1;
  }

  function start() external onlyRole(DEFAULT_ADMIN_ROLE) {
    stopped = 0;
  }

  function change(address medianizer_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    medianizer = medianizer_;

    emit ChangeMedian(msg.sender, medianizer);
  }

  function era() internal view returns (uint) {
    return block.timestamp;
  }

  function prev(uint time) internal view returns (uint64) {
    require(hop != 0, "OSM/hop-is-zero");
    return uint64(time - (time % hop));
  }

  function step(uint16 time) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(time > 0, "Can't be zero!");
    hop = time;
  }

  function void() external onlyRole(DEFAULT_ADMIN_ROLE) {
    cur = nxt = Feed(0, 0);
    stopped = 1;
  }

  function pass() public view returns (bool ok) {
    return era() >= zzz + hop;
  }

  function poke() external stoppable {
    require(pass(), "Waiting for one hour");
    (uint256 price, bool ok) = IMedian(medianizer).peek();
    if (ok) {
      cur = nxt;
      nxt = Feed(price, 1);
      zzz = prev(era());

      emit AddPrice(msg.sender, cur.val);
    }
  }

  function peek() external view onlyRole(READER_ROLE) returns (uint256, bool) {
    return (cur.val, cur.has == 1);
  }

  function peep() external view onlyRole(READER_ROLE) returns (uint256, bool) {
    return (nxt.val, nxt.has == 1);
  }

  function read() external view onlyRole(READER_ROLE) returns (uint256) {
    require(cur.has == 1, "Is not a current value");
    return cur.val;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedian {
  function peek() external view returns (uint256, bool);
  function read() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}