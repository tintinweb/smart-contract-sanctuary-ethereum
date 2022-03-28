/***************************************************
IuvoDAO

We are philanthropy. Iuvo aims to become the defacto crypto standard in charity and giving to people in need.
We donate money all on chain and to cryptocurrency wallets in real time and immediately.
***************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './IuvoDaoRewards.sol';

contract IuvoDaoToken is ERC20, Ownable {
  uint256 private constant ONE_DAY = 60 * 60 * 24;
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  address payable public dao;
  address payable public treasury;

  IuvoDaoRewards private _rewards;
  mapping(address => bool) private _isRewardsExcluded;
  mapping(address => bool) private _isTaxExcluded;

  uint256 public voteCooldownPeriod = ONE_DAY * 7; // 7 days
  mapping(address => uint256) public voteCooldownStart;

  bool private _taxesOff;
  uint256 private _taxDaoDonations = 40;
  uint256 private _taxDaoRewards = 20;
  uint256 private _taxLp = 20;
  uint256 private _totalTax;

  uint256 public earlySellMultiplier = 2;
  uint256 public earlySellTaperDays = 14;

  uint256 private _liquifyRate = 10; // 1% of liquidity pair balance
  uint256 public launchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => uint256) private _lastBuy;
  uint256 public epochSeconds = ONE_DAY / 3; // 8 hours
  mapping(uint256 => address[]) public epochBuyers;
  mapping(uint256 => mapping(address => bool)) public epochBuyersIndexed;

  mapping(address => bool) private _isBot;
  address[] private _confirmedBots;

  uint256 private _lastManualLpBurn;
  uint256 private _manualNukeFrequency = 60 * 60;

  bool private _swapEnabled = true;
  bool private _swapping = false;
  modifier lockSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20('IuvoDAO', 'IUVO') {
    _mint(address(this), 100_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _setTotalTax();
    _rewards = new IuvoDaoRewards(address(this));
    _rewards.transferOwnership(msg.sender);

    _isRewardsExcluded[address(this)] = true;
    _isRewardsExcluded[address(_rewards)] = true;
    _isRewardsExcluded[uniswapV2Pair] = true;
    _isRewardsExcluded[address(uniswapV2Router)] = true;
    _isTaxExcluded[address(_rewards)] = true;
    _isTaxExcluded[msg.sender] = true;
  }

  // _supplyPercentLp: 1 = 0.1%, 1000 = 100%
  function launch(uint16 _supplyPercentLp) external payable onlyOwner {
    require(launchTime == 0, 'already launched');
    require(msg.value > 0, 'need ETH for initial LP');
    require(
      _supplyPercentLp <= PERCENT_DENOMENATOR,
      'cannot add more than supply to LP'
    );

    uint256 _supplyForLp = (totalSupply() * _supplyPercentLp) /
      PERCENT_DENOMENATOR;
    uint256 _leftover = totalSupply() - _supplyForLp;
    if (_supplyForLp > 0) {
      _addLp(_supplyForLp, msg.value);
    }
    if (_leftover > 0) {
      _transfer(address(this), owner(), _leftover);
    }
    launchTime = block.timestamp;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() ||
      recipient == owner() ||
      msg.sender == owner();
    require(
      _isOwner || amount <= _maxTx(sender, recipient),
      'ERC20: too much ser'
    );
    require(!_isBot[recipient], 'Stop botting!');
    require(!_isBot[sender], 'Stop botting!');
    require(!_isBot[_msgSender()], 'Stop botting!');
    uint256 contractTokenBalance = balanceOf(address(this));

    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    bool _isSwap = _isBuy || _isSell;
    if (_isSwap) {
      if (block.timestamp == launchTime) {
        _isBot[recipient] = true;
        _confirmedBots.push(recipient);
      }
    } else {
      // just a transfer and restarting cooldown for recipient
      // to prevent potential double DAO votes
      voteCooldownStart[recipient] = block.timestamp;
    }

    if (_isBuy) {
      _lastBuy[recipient] = block.timestamp;

      uint256 _epoch = getEpoch();
      if (!epochBuyersIndexed[_epoch][recipient]) {
        epochBuyersIndexed[_epoch][recipient] = true;
        epochBuyers[_epoch].push(recipient);
      }

      // reset cooldown if buying and new holder
      if (balanceOf(recipient) == 0) {
        voteCooldownStart[recipient] = 0;
      }
    }

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
      PERCENT_DENOMENATOR;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      launchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      // don't allow _swapping more than liquifyRate% of what's in the liquidity pool
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      launchTime != 0 &&
      _isSwap &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
      if (tax > 0) {
        if (_isSell) {
          tax = calculateEarlySellTax(sender, tax);
        }
        super._transfer(sender, address(this), tax);
      }
    }

    super._transfer(sender, recipient, amount - tax);

    if (!_isRewardsExcluded[sender]) {
      try _rewards.setShare(sender, balanceOf(sender)) {} catch {}
    }
    if (!_isRewardsExcluded[recipient]) {
      try _rewards.setShare(recipient, balanceOf(recipient)) {} catch {}
    }
  }

  // handle early sell tax tapering.
  // earlySellMultiplier is base case and if buyer is selling same day
  // earlySellTaperDays handles how the base case multiplier decreases per day, and how
  // many days it takes to get back to the normal tax
  // EXAMPLE:
  //    normal tax = 10%
  //    earlySellMultiplier = 2
  //    earlySellTaperDays = 10
  //      - 0 days later (same day as buy); tax = 20%
  //      - 1 day later; tax = 19%
  //      - 2 days later; tax = 18%
  //      - 3 days later; tax = 17%
  //      ... and so on until 10 days later+; tax = 10%
  function calculateEarlySellTax(address _sender, uint256 _tax)
    public
    view
    returns (uint256)
  {
    if (
      earlySellMultiplier > 1 &&
      block.timestamp < calculateEarlySellExpiration(_sender)
    ) {
      uint256 _daysAfterBuy = (block.timestamp - _lastBuy[_sender]) / ONE_DAY;
      return
        (_tax * ((earlySellMultiplier * earlySellTaperDays) - _daysAfterBuy)) /
        earlySellTaperDays;
    }
    return _tax;
  }

  function calculateEarlySellExpiration(address _sender)
    public
    view
    returns (uint256)
  {
    return _lastBuy[_sender] + (earlySellTaperDays * ONE_DAY);
  }

  function _maxTx(address sender, address recipient)
    private
    view
    returns (uint256)
  {
    bool _isOwner = sender == owner() ||
      recipient == owner() ||
      msg.sender == owner();
    uint256 expiration = 60 * 15; // 15 minutes
    if (
      _isOwner || launchTime == 0 || block.timestamp > launchTime + expiration
    ) {
      return totalSupply();
    }
    return totalSupply() / 100; // 1%
  }

  function _swap(uint256 contractTokenBalance) private lockSwap {
    uint256 balBefore = address(this).balance;
    uint256 liquidityTokens = (contractTokenBalance * _taxLp) / _totalTax / 2;
    uint256 tokensToSwap = contractTokenBalance - liquidityTokens;

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokensToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokensToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - balBefore;
    if (balToProcess > 0) {
      _processFees(balToProcess, liquidityTokens);
    }
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      treasury == address(0) ? owner() : treasury,
      block.timestamp
    );
  }

  function _sendDao(uint256 _daoETH) private {
    address payable _dao = dao == address(0) ? payable(owner()) : dao;
    _dao.call{ value: _daoETH }('');
  }

  function _addDaoRewards(uint256 _amountETH) private {
    _rewards.depositRewards{ value: _amountETH }();
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
    uint256 daoRewardsETH = (amountETH * _taxDaoRewards) / _totalTax;
    uint256 daoDonationsETH = (amountETH * _taxDaoDonations) / _totalTax;
    uint256 lpETH = amountETH - daoRewardsETH - daoDonationsETH;

    _sendDao(daoDonationsETH);
    if (daoRewardsETH > 0) {
      _addDaoRewards(daoRewardsETH);
    }
    if (amountLpTokens > 0) {
      _addLp(amountLpTokens, lpETH);
    }
  }

  function _setTotalTax() private {
    _totalTax = _taxDaoDonations + _taxDaoRewards + _taxLp;
    require(
      _totalTax <= (PERCENT_DENOMENATOR * 15) / 100,
      'tax cannot be above 15%'
    );
    require(
      _totalTax * earlySellMultiplier <= (PERCENT_DENOMENATOR * 40) / 100,
      'tax with early multiplier cannot be above 40%'
    );
  }

  // starts at 1 and increments forever every `epoch` time frame
  function getEpoch() public view returns (uint256) {
    uint256 secondsSinceLaunch = block.timestamp - launchTime;
    return 1 + (secondsSinceLaunch / epochSeconds);
  }

  function rewardsContract() external view returns (address) {
    return address(_rewards);
  }

  function isRemovedBot(address account) external view returns (bool) {
    return _isBot[account];
  }

  function removeBot(address account) external onlyOwner {
    require(
      account != address(uniswapV2Router),
      'cannot not blacklist Uniswap'
    );
    require(!_isBot[account], 'user is already blacklisted');
    _isBot[account] = true;
    _confirmedBots.push(account);
  }

  function amnestyBot(address account) external onlyOwner {
    require(_isBot[account], 'user is not blacklisted');
    for (uint256 i = 0; i < _confirmedBots.length; i++) {
      if (_confirmedBots[i] == account) {
        _confirmedBots[i] = _confirmedBots[_confirmedBots.length - 1];
        _isBot[account] = false;
        _confirmedBots.pop();
        break;
      }
    }
  }

  function setTaxDaoDonations(uint256 _tax) external onlyOwner {
    _taxDaoDonations = _tax;
    _setTotalTax();
  }

  function setTaxDaoRewards(uint256 _tax) external onlyOwner {
    _taxDaoRewards = _tax;
    _setTotalTax();
  }

  function setTaxLp(uint256 _tax) external onlyOwner {
    _taxLp = _tax;
    _setTotalTax();
  }

  function setDao(address _dao) external onlyOwner {
    dao = payable(_dao);
    setIsRewardsExcluded(_dao, true);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = payable(_treasury);
    setIsRewardsExcluded(_treasury, true);
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setEarlySellTaxMultiplier(uint256 _mult) external onlyOwner {
    require(_mult <= 4, 'no more than 4 times normal tax');
    earlySellMultiplier = _mult;
  }

  function setEarlySellTaperDays(uint256 _numberDays) external onlyOwner {
    require(_numberDays <= 60, 'no more than 60 days');
    earlySellTaperDays = _numberDays;
  }

  function setIsRewardsExcluded(address _wallet, bool _isExcluded)
    public
    onlyOwner
  {
    _isRewardsExcluded[_wallet] = _isExcluded;
    if (_isExcluded) {
      _rewards.setShare(_wallet, 0);
    } else {
      _rewards.setShare(_wallet, balanceOf(_wallet));
    }
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setVoteCooldownPeriod(uint256 _seconds) external onlyOwner {
    require(_seconds < ONE_DAY * 30, 'cannot be more than 30 days');
    voteCooldownPeriod = _seconds;
  }

  function setVoteCooldownStart(address _user, uint256 _start)
    external
    onlyOwner
  {
    voteCooldownStart[_user] = _start;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setManualBurnFrequency(uint256 _seconds) external onlyOwner {
    _manualNukeFrequency = _seconds;
  }

  function setEpochSeconds(uint256 _seconds) external onlyOwner {
    epochSeconds = _seconds;
  }

  function manualBurnLpTokens(uint256 _percent, address _to)
    external
    onlyOwner
  {
    require(
      block.timestamp > _lastManualLpBurn + _manualNukeFrequency,
      'cooldown please'
    );
    require(
      _percent <= PERCENT_DENOMENATOR / 10,
      'cannot nuke more than 10% of LP tokens'
    );
    _lastManualLpBurn = block.timestamp;

    uint256 amountToBurn = (balanceOf(uniswapV2Pair) * _percent) /
      PERCENT_DENOMENATOR;
    if (amountToBurn > 0) {
      address receiver = _to == address(0) ? address(0xdead) : _to;
      super._transfer(uniswapV2Pair, receiver, amountToBurn);
    }

    // sync price since this is not in a buy/sell txn
    IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
    pair.sync();
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IDao.sol';
import './interfaces/IDaoRewards.sol';

contract IuvoDaoRewards is IDaoRewards, Ownable {
  struct Reward {
    uint256 totalExcluded; // excluded reward
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }

  IDao private dao;
  address public shareholderToken;
  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise

  // amount of shares a user has
  mapping(address => Share) shares;
  // reward information per user
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event ClaimReward(address user, bool autoDonate);
  event DistributeReward(address indexed user, address payable receiver);
  event DepositRewards(address indexed user, uint256 amountETH);

  modifier onlyToken() {
    require(msg.sender == shareholderToken, 'must be token contract');
    _;
  }

  constructor(address _shareholderToken) {
    shareholderToken = _shareholderToken;
  }

  function setShare(address shareholder, uint256 newBalance)
    external
    onlyToken
  {
    // _addShares and _removeShares takes the amount to add or remove respectively,
    // so we should handle the diff from the new balance when passing in the amounts
    // to these functions
    if (shares[shareholder].amount > newBalance) {
      _removeShares(shareholder, shares[shareholder].amount - newBalance);
    } else if (shares[shareholder].amount < newBalance) {
      _addShares(shareholder, newBalance - shares[shareholder].amount);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder, false);
    }

    uint256 sharesBefore = shares[shareholder].amount;

    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    require(
      shares[shareholder].amount > 0 &&
        (amount == 0 || amount <= shares[shareholder].amount),
      'you can only unstake if you have some staked'
    );
    _distributeReward(shareholder, false);

    uint256 removeAmount = amount == 0 ? shares[shareholder].amount : amount;

    totalSharesDeposited -= removeAmount;
    shares[shareholder].amount -= removeAmount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards() external payable override {
    require(msg.value > 0, 'value must be greater than 0');
    require(
      totalSharesDeposited > 0,
      'must be shares deposited to be rewarded rewards'
    );

    uint256 amount = msg.value;
    totalRewards += amount;
    rewardsPerShare += (ACC_FACTOR * amount) / totalSharesDeposited;
    emit DepositRewards(msg.sender, msg.value);
  }

  function _distributeReward(address shareholder, bool autoDonate) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);

    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
    rewards[shareholder].lastClaim = block.timestamp;

    if (amount > 0) {
      address payable receiver = autoDonate && address(dao) != address(0)
        ? payable(dao.currentCharity())
        : payable(shareholder);
      totalDistributed += amount;
      uint256 balanceBefore = address(this).balance;
      receiver.call{ value: amount }('');
      require(address(this).balance >= balanceBefore - amount);
      emit DistributeReward(shareholder, receiver);
    }
  }

  function claimReward(bool _autoDonate) external override {
    _distributeReward(msg.sender, _autoDonate);
    emit ClaimReward(msg.sender, _autoDonate);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getDao() external view returns (address) {
    return address(dao);
  }

  function setDao(address _dao) external onlyOwner {
    dao = IDao(_dao);
  }

  receive() external payable {}
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDao {
  function currentCharity() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDaoRewards {
  function claimReward(bool autoDonate) external;

  function depositRewards() external payable;

  function getShares(address wallet) external view returns (uint256);
}