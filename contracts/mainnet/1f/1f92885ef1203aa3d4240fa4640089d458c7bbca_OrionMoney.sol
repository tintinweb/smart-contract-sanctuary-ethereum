// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IConversionPool} from "@orionterra/eth-anchor-contracts/contracts/extensions/ConversionPool.sol";
import {IExchangeRateFeeder} from "@orionterra/eth-anchor-contracts/contracts/extensions/ExchangeRateFeeder.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";

import {StableRateFeeder} from "./StableRateFeeder.sol";
import {IDepositable} from "./IDepositable.sol";
import {ISaver} from "./ISaver.sol";

contract OrionMoney is OwnableUpgradeable, IDepositable, ISaver {
  using Math for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Balance {
    uint256 original_amount;
    uint256 orioned_amount;
  }

  // currency (erc20 stable coin contract address) => user address => balances
  mapping(IERC20 => mapping(address => Balance)) private _balances;

  struct TokenInfo {
    IERC20 proxy_token;
    IERC20 anchored_token;
    IConversionPool conversion_pool;
    IExchangeRateFeeder exchange_rate_feeder;
    StableRateFeeder orion_rate_feeder;
    uint256 ten_pow_decimals;  // 10 ** decimals
  }

  struct WithdrawOperation {
    bytes20 operation_id;
    address user;
    uint256 requested_amount;
    uint256 requested_amount_after_fee;
    uint256 anchored_amount;
    uint256 orioned_amount;
    uint256 updated_original_amount;
  }

  // ERC20 stable coin contract address => anchored token contract address & conversion pool
  mapping(IERC20 => TokenInfo) private _tokens;
  // token => total amount of requested and not finished withdraw amount for all users
  mapping(IERC20 => uint256) private _total_pending_withdraw_amount;
  // token => sum of orioned_amount across all users
  mapping(IERC20 => uint256) private _total_orioned_amount;

  // pending withdraw operations, some first elements could be already processed and deleted (_first_withdraw_operation > 0)
  mapping(IERC20 => WithdrawOperation[]) private _withdraw_operations;
  // first not finished withdraw operations, used during partial processing
  mapping(IERC20 => uint) _first_withdraw_operation;
  // store index (of _withdraw_operations) + 1
  // 0 - means 'no operation'
  mapping(IERC20 => mapping(address => uint32)) private _active_withdraw_operations;

  // current deposit limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _deposit_limit;
  // current withdraw limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _withdraw_limit;

  // default slippage tolerance, 1% = 0.01 stored as 1000;
  uint256 private _default_slippage_tolerance;
  uint256 constant _default_slippage_tolerance_denom = 100_000;

  bool private _atomic_guard;

  modifier criticalSection() {
    require(_atomic_guard == false, "Reentrancy attack detected");
    _atomic_guard = true;
    _;
    _atomic_guard = false;
  }

  // current local deposit limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _local_deposit_limit;
  // current local withdraw limit (in integer stable coins, no 1e18, e.g. 1000 = $1000)
  uint256 private _local_withdraw_limit;

  // white list of receivers to transfer deposits to
  mapping(IDepositable => uint8) private _white_list;

  // parameters related to shuttle fee
  uint256 private _min_fee; // minimal fee amount
  uint256 private _max_fee; // maximal fee amount
  uint256 private _fee_fraction; // E.g., 0.1% can be stored as _fee_fraction=100 and _fee_fraction_denom=100_000
  uint256 constant _fee_fraction_denom = 100_000;

  event Deposit(address indexed token, address indexed user, uint256 token_amount, uint256 orioned_amount, uint256 anchored_amount, uint256 real_deposited_token_amount);
  event WithdrawInit(address indexed token, address indexed user, bytes20 indexed operation_id,
                     uint256 requested_amount, uint256 requested_amount_after_fee,
                     uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);
  event WithdrawFinalized(address indexed token, address indexed user, bytes20 indexed operation_id,
                          uint256 requested_amount, uint256 requested_amount_after_fee,
                          uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);

  event TransferDeposit(address indexed token, address indexed user, address indexed receiver, uint256 requested_amount,
                        uint256 anchored_amount, uint256 orioned_amount, uint256 updated_original_amount);

  event TokenAdded(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint32 decimals);
  event TokenRemoved(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint256 ten_pow_decimals);
  event TokenUpdated(address indexed token, address proxy_token, address anchored_token, address conversion_pool, address exchange_rate_feeder, address orion_rate_feeder, uint32 decimals);

  function initialize(uint256 deposit_limit, uint256 withdraw_limit) public virtual initializer {
    OwnableUpgradeable.__Ownable_init();
    _deposit_limit = deposit_limit;
    _withdraw_limit = withdraw_limit;
    _default_slippage_tolerance = 15_000;  // 15%
    _local_deposit_limit = 1_000;
    _local_withdraw_limit = 1_500;
  }

  function checkToken(IERC20 token) internal view {
    require(_tokens[token].anchored_token != IERC20(0), "Token is not registered");
  }

  function addToken(IERC20 token,
                    IERC20 proxy_token,
                    IERC20 anchored_token,
                    IConversionPool conversion_pool,
                    IExchangeRateFeeder exchange_rate_feeder,
                    StableRateFeeder orion_rate_feeder,
                    uint32 decimals)
  public onlyOwner {
    require(token != IERC20(0), "Zero address provided");
    require(_tokens[token].anchored_token == IERC20(0), "Token already registered");

    _tokens[token].proxy_token = proxy_token;
    _tokens[token].anchored_token = anchored_token;
    _tokens[token].conversion_pool = conversion_pool;
    _tokens[token].exchange_rate_feeder = exchange_rate_feeder;
    _tokens[token].orion_rate_feeder = orion_rate_feeder;
    _tokens[token].ten_pow_decimals = 10 ** uint256(decimals);
    _total_pending_withdraw_amount[token] = 0;
    _total_orioned_amount[token] = 0;

    emit TokenAdded(address(token),
                    address(proxy_token),
                    address(anchored_token),
                    address(conversion_pool),
                    address(exchange_rate_feeder),
                    address(orion_rate_feeder),
                    decimals);
  }

  function updateToken(IERC20 token,
                       IERC20 proxy_token,
                       IERC20 anchored_token,
                       IConversionPool conversion_pool,
                       IExchangeRateFeeder exchange_rate_feeder,
                       StableRateFeeder orion_rate_feeder,
                       uint32 decimals)
  public onlyOwner criticalSection {
    checkToken(token);

    _tokens[token].proxy_token = proxy_token;
    _tokens[token].anchored_token = anchored_token;
    _tokens[token].conversion_pool = conversion_pool;
    _tokens[token].exchange_rate_feeder = exchange_rate_feeder;
    _tokens[token].orion_rate_feeder = orion_rate_feeder;
    _tokens[token].ten_pow_decimals = 10 ** uint256(decimals);

    emit TokenUpdated(address(token),
                      address(proxy_token),
                      address(anchored_token),
                      address(conversion_pool),
                      address(exchange_rate_feeder),
                      address(orion_rate_feeder),
                      decimals);
  }

  function removeToken(IERC20 token) public onlyOwner criticalSection {
    checkToken(token);
    require(_total_pending_withdraw_amount[token] == 0, "There are active withdraw operations");
    require(_total_orioned_amount[token] == 0, "There are deposits in this token");

    emit TokenRemoved(address(token),
                      address(_tokens[token].proxy_token),
                      address(_tokens[token].anchored_token),
                      address(_tokens[token].conversion_pool),
                      address(_tokens[token].exchange_rate_feeder),
                      address(_tokens[token].orion_rate_feeder),
                      _tokens[token].ten_pow_decimals);

    delete _total_pending_withdraw_amount[token];
    delete _total_orioned_amount[token];
    delete _tokens[token];
  }

  function setLocalLimits(uint256 local_deposit_limit, uint256 local_withdraw_limit) public onlyOwner {
    _local_deposit_limit = local_deposit_limit;
    _local_withdraw_limit = local_withdraw_limit;
  }

  function setLimits(uint256 deposit_limit, uint256 withdraw_limit) public onlyOwner {
    _deposit_limit = deposit_limit;
    _withdraw_limit = withdraw_limit;
  }

  function getDepositLimit() public override view returns (uint256) {
    return _deposit_limit;
  }

  function getWithdrawLimit() public override view returns (uint256) {
    return _withdraw_limit;
  }

  function getLocalDepositLimit() public override view returns (uint256) {
    return _local_deposit_limit;
  }

  function getLocalWithdrawLimit() public override view returns (uint256) {
    return _local_withdraw_limit;
  }

  function getLimits() public view returns (uint256 deposit_limit,
                                            uint256 withdraw_limit,
                                            uint256 local_deposit_limit,
                                            uint256 local_withdraw_limit) {
    deposit_limit        = _deposit_limit;
    withdraw_limit       = _withdraw_limit;
    local_deposit_limit  = _local_deposit_limit;
    local_withdraw_limit = _local_withdraw_limit;
  }

  function setDefaultSlippageTolerance(uint256 new_tolerance) public onlyOwner {
    require(new_tolerance >= 0 && new_tolerance <= _default_slippage_tolerance_denom,
            "Value should be in [0 .. 100%] i.e. [0 .. 100_000]");
    _default_slippage_tolerance = new_tolerance;
  }

  function getDefaultSlippageTolerance() public view returns (uint256) {
    return _default_slippage_tolerance;
  }

  function isValidToken(IERC20 token) public view returns (bool) {
    return _tokens[token].anchored_token != IERC20(0);
  }

  function getTokenAnchorAddress(IERC20 token) public view returns (IERC20) {
    return _tokens[token].anchored_token;
  }

  function getTokenInfo(IERC20 token) public view returns (
      IERC20 proxy_token,
      IERC20 anchored_token,
      IConversionPool conversion_pool,
      IExchangeRateFeeder exchange_rate_feeder,
      StableRateFeeder orion_rate_feeder,
      uint256 ten_pow_decimals) {
    checkToken(token);

    proxy_token = _tokens[token].proxy_token;
    anchored_token = _tokens[token].anchored_token;
    conversion_pool = _tokens[token].conversion_pool;
    exchange_rate_feeder = _tokens[token].exchange_rate_feeder;
    orion_rate_feeder = _tokens[token].orion_rate_feeder;
    ten_pow_decimals = _tokens[token].ten_pow_decimals;
  }

  // @action == 1: add @receiver to the white list
  // @action == 0: remove @receiver from the white list
  function addToWhiteList(IDepositable receiver, uint8 action) public onlyOwner {
    require(receiver != IDepositable(0), "Zero address provided");
    _white_list[receiver] = action;
  }

  function balanceOf(IERC20 token, address user) public view override returns (uint256 original_amount,
                                                                      uint256 orioned_amount,
                                                                      uint256 current_amount) {
    checkToken(token);

    Balance memory balance = _balances[token][user];
    original_amount = balance.original_amount;
    orioned_amount = balance.orioned_amount;
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    current_amount = orion_rate_feeder.multiplyByCurrentRate(orioned_amount);
  }

  function convert_atokens_to_tokens(IERC20 token, uint256 atoken_amount) internal view returns (uint256) {
    IExchangeRateFeeder feeder = _tokens[token].exchange_rate_feeder;
    uint256 pER = feeder.exchangeRateOf(address(token), true);
    return atoken_amount.mul(pER).div(1e18).mul(_tokens[token].ten_pow_decimals).div(1e18);
  }

  function convert_tokens_to_atokens(IERC20 token, uint256 token_amount) internal view returns (uint256) {
    IExchangeRateFeeder feeder = _tokens[token].exchange_rate_feeder;
    uint256 pER = feeder.exchangeRateOf(address(token), true);
    return token_amount.mul(1e18).div(pER).mul(1e18).div(_tokens[token].ten_pow_decimals);
  }

  function convert_tokens_to_orioned_amount(IERC20 token, uint256 requested_amount) internal view returns (uint256) {
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    return requested_amount.mul(1e18).div(orion_rate_feeder.multiplyByCurrentRate(1e18));
  }

  function convert_orioned_amount_to_tokens(IERC20 token, uint256 orioned_amount) internal view returns (uint256) {
    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    return orion_rate_feeder.multiplyByCurrentRate(orioned_amount);
  }

  /*

  The following functions help to manage 'unbonded' token and aToken ammounts.
  'Unbonded' token amount is the amount in excess of tokens required to cover users deposits.

  Let's say users deposited 10,000 USDT in total, and that equals to 9,500 aUSDT at current
  USDT/aUSDT exchange rate. If contract has 9700 aUSDT, then 200 aUSDT is the amount of 'unbonded'
  tokens. In other words, if all users decide to withdraw their deposits, we would need 9,500
  aUST to cover it, and 200 aUSDT will belong to Orion Money project.

  */


  /*

  Calculates amount of unbonded aTokens

  */
  function getFreeAnchoredAmount(IERC20 token) public view returns (int256) {
    checkToken(token);

    StableRateFeeder orion_rate_feeder = _tokens[token].orion_rate_feeder;
    uint256 total_deposits_amount = orion_rate_feeder.multiplyByCurrentRate(_total_orioned_amount[token]);

    IERC20 atoken = _tokens[token].anchored_token;
    uint256 total_atokens = atoken.balanceOf(address(this));
    return int256(total_atokens) - int256(convert_tokens_to_atokens(token, total_deposits_amount));
  }

  /*

  Withdraws aTokens limited by unbonded aTokens amount

  */
  function takeAnchoredProfit(IERC20 token, address receiver, uint256 amount) public onlyOwner criticalSection {
    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    require(int256(amount) <= free_anchored_amount, "Amount exceeds the amount of unbonded atokens");
    _tokens[token].anchored_token.safeTransfer(receiver, amount);
  }

  /*

  Calculates amount of unbonded tokens that can be deposited to EthAnchor or taken away

  */
  function getDepositableAmount(IERC20 token) public view returns (int256) {
    checkToken(token);

    uint256 contract_balance = token.balanceOf(address(this));
    return int256(contract_balance) - int256(_total_pending_withdraw_amount[token]);
  }

  /*

  Withdraws tokens limited by unbounded tokens amount

  */
  function takeProfit(IERC20 token, address receiver, uint256 amount) public onlyOwner criticalSection {
    uint256 contract_balance = token.balanceOf(address(this));
    require(contract_balance >= _total_pending_withdraw_amount[token] + amount, "Amount exceeds the amount of unbonded tokens");
    token.safeTransfer(receiver, amount);
  }

  /*

  Similar to takeProfit. Instead of withdrawing unbonded tokens, deposits amount to Anchorprotocol.
  Obtained aTokens could be later withdrawn using takeAnchorProfit, or could stay on contract to server
  depositLocal calls.

  */
  function depositFreeFunds(IERC20 token, uint256 amount) public onlyOwner criticalSection {
    require(token.balanceOf(address(this)) >= _total_pending_withdraw_amount[token] + amount,
      "Amount exceeds the amount of unbonded tokens");

    token.safeApprove(address(_tokens[token].conversion_pool), amount);

    _tokens[token].conversion_pool.deposit(
      amount,
      amount.sub(amount.mul(_default_slippage_tolerance).div(_default_slippage_tolerance_denom))
    );
  }

  /*

  Similar to takeAnchoredProfit. Instead of withdrawing unbonded aTokens, redeems if from Anchorprotocol.
  Redeemed tokens could be later withdrawn using takeProfit, or could stay on contract to serve
  withdrawLocal calls.

  */
  function withdrawFreeFunds(IERC20 token, uint256 anchored_amount) public onlyOwner criticalSection {
    require(getFreeAnchoredAmount(token) >= int256(anchored_amount), "Amount exceeds the amount of unbonded atokens");

    _tokens[token].anchored_token.safeApprove(address(_tokens[token].conversion_pool), anchored_amount);
    _tokens[token].conversion_pool.redeem(anchored_amount);
  }

  /*

  Checks if contract has enough unbounded aTokens for specified amount of tokens

  */
  function canDepositLocal(IERC20 token, uint256 amount) public override view returns(bool) {
    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    uint256 atokens_to_deposit = convert_tokens_to_atokens(token, amount);
    return int256(atokens_to_deposit) <= free_anchored_amount;
  }

  /*

  Local deposit. In contrast to regular deposit function funds are not sent to Anchorprotocol. Instead we
  check if we have enough unbonded aTokens on contract, and update balances accordingly.

  For smaller investors this helps to signinficanlty save on gas fees.

  */
  function depositLocal(IERC20 token, uint256 amount) public override criticalSection {
    require(_active_withdraw_operations[token][msg.sender] == 0, "Withdraw operation pending");
    require(amount.div(_tokens[token].ten_pow_decimals) <= _local_deposit_limit, "Amount exceeds local deposit limit");
    require(amount > 0, "Amount should be greater than zero");

    int256 free_anchored_amount = getFreeAnchoredAmount(token);
    uint256 atokens_to_deposit = convert_tokens_to_atokens(token, amount);
    require(int256(atokens_to_deposit) <= free_anchored_amount, "Not enough free atokens");

    uint256 token_balance_before = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), amount);

    require(token.balanceOf(address(this)) - token_balance_before == amount,
      "ERC20 token has not transferred the same amount as requested");

    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, amount);

    _balances[token][msg.sender].original_amount += amount;
    _balances[token][msg.sender].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), msg.sender, amount, deposited_orioned, atokens_to_deposit, amount);
  }

  function deposit(IERC20 token, uint256 amount, uint256 min_amount) public criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "Withdraw operation pending");

    require(amount.div(_tokens[token].ten_pow_decimals) <= _deposit_limit, "Amount exceeds deposit limit");
    require(amount > 0, "Amount should be > 0");

    IERC20 atoken = _tokens[token].anchored_token;

    uint256 token_balance_before = token.balanceOf(address(this));
    uint256 atoken_balance_before = atoken.balanceOf(address(this));

    token.safeTransferFrom(msg.sender, address(this), amount);

    require(token.balanceOf(address(this)) - token_balance_before == amount,
      "ERC20 token has not transferred the same amount as requested");

    IConversionPool conversion_pool = _tokens[token].conversion_pool;
    token.safeApprove(address(conversion_pool), amount);
    conversion_pool.deposit(amount, min_amount);

    uint256 atoken_balance_after = atoken.balanceOf(address(this));

    uint256 atokens_deposited = atoken_balance_after.sub(atoken_balance_before);
    uint256 real_deposited_token_amount = convert_atokens_to_tokens(token, atokens_deposited);
    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, real_deposited_token_amount);

    _balances[token][msg.sender].original_amount += real_deposited_token_amount;
    _balances[token][msg.sender].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), msg.sender, amount, deposited_orioned, atokens_deposited, real_deposited_token_amount);
  }

  /*

  There are cases, when we want to accept deposits in aTokens directly. For example, if user participated in
  Private Farming, but decided to continue holding funds with Orion Saver we will just transfer his/her aTokens from
  Private Farming contract to Orion Saver

  */
  function depositAnchored(IERC20 token, address depositor, uint256 anchored_amount) public override criticalSection  {
    require(depositor != address(0), "Wrong depositor address");
    checkToken(token);
    require(_active_withdraw_operations[token][depositor] == 0, "Withdraw operation pending");
    require(anchored_amount > 0, "Amount should be > 0");

    uint256 stable_coin_amount = convert_atokens_to_tokens(token, anchored_amount);
    require(stable_coin_amount.div(_tokens[token].ten_pow_decimals) <= _deposit_limit, "Amount exceeds deposit limit");

    IERC20 atoken = _tokens[token].anchored_token;

    uint256 atoken_balance_before = atoken.balanceOf(address(this));
    /* Transferring funds from msg.sender (contract) */
    atoken.safeTransferFrom(msg.sender, address(this), anchored_amount);
    require(atoken.balanceOf(address(this)) - atoken_balance_before == anchored_amount,
      "ERC20 token has not transferred the same amount as requested");

    uint256 deposited_orioned = convert_tokens_to_orioned_amount(token, stable_coin_amount);
    /* Depositing funds in favour of depositor */
    _balances[token][depositor].original_amount += stable_coin_amount;
    _balances[token][depositor].orioned_amount += deposited_orioned;
    _total_orioned_amount[token] = _total_orioned_amount[token].add(deposited_orioned);

    emit Deposit(address(token), depositor, stable_coin_amount, deposited_orioned, anchored_amount, stable_coin_amount);
  }

  // with default slippage tolerance
  function deposit(IERC20 token, uint256 amount) public override {
    deposit(token, amount, amount.sub(amount.mul(_default_slippage_tolerance).div(_default_slippage_tolerance_denom)));
  }

  /*

  Checks if contract has enough unbounded tokens to withdraw funds right away

  */
  function canWithdrawLocal(IERC20 token, uint256 amount) public override view returns(bool) {
    uint256 current_balance = token.balanceOf(address(this));
    return current_balance >= _total_pending_withdraw_amount[token] + amount;
  }

  /*

  Local deposit. In contrast to regular deposit function funds are not withdrawn from Anchorprotocol.
  Instead we check if we have enough unbonded tokens on contract, transfer funds to user, and
  update balances accordingly

  For smaller investors this helps to signinficanlty save on gas fees.

  */
  function withdrawLocal(IERC20 token, uint256 requested_amount) public override criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0,
      "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _local_withdraw_limit,
      "Amount exceeds local withdraw limit");

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);
    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 current_balance = token.balanceOf(address(this));
    require(current_balance >= _total_pending_withdraw_amount[token] + requested_amount, "Insufficient unbonded tokens");

    token.safeTransfer(msg.sender, requested_amount);

    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);
    _balances[token][msg.sender].original_amount = updated_original_amount;

    _balances[token][msg.sender].orioned_amount = _balances[token][msg.sender].orioned_amount
                                                      .sub(requested_orioned_amount);

    _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);

    bytes20 operation_id = bytes20(keccak256(abi.encodePacked(block.number, token, msg.sender)));

    /*
      to support same interface we simply emit two events one after another.
      This way event listener (backend) doesn't need to handle local deposits differently
      from regular deposits
    */
    emit WithdrawInit(address(token), msg.sender, operation_id,
                      requested_amount, requested_amount,
                      requested_anchored_amount, requested_orioned_amount, updated_original_amount);

    emit WithdrawFinalized(address(token), msg.sender, operation_id,
                          requested_amount, requested_amount,
                          requested_anchored_amount, requested_orioned_amount, updated_original_amount);
  }

  // @min_fee and @max_fee should be in whole units (without decimal zeroes), i.e. 1 means 1$.
  function setWithdrawFee(uint256 min_fee,
                          uint256 max_fee,
                          uint256 fee_fraction) public onlyOwner {
    require(min_fee <= max_fee, "min_fee is greater than max_fee");
    require(min_fee <= 100_000, "min_fee is too large");
    _min_fee = min_fee;
    _max_fee = max_fee;
    _fee_fraction = fee_fraction;
  }

  function get_withdraw_fee(IERC20 token, uint256 amount) public view returns(uint256) {
    // clamp(amount * fee_fraction, min_fee, max_fee)
    return amount
      .mul(_fee_fraction).div(_fee_fraction_denom)
      .max(_min_fee * _tokens[token].ten_pow_decimals)
      .min(_max_fee * _tokens[token].ten_pow_decimals);
  }

  function withdraw(IERC20 token, uint256 requested_amount) public override criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _withdraw_limit, "Amount exceeds withdraw limit");

    IERC20 atoken = _tokens[token].anchored_token;

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);
    uint256 requested_amount_after_fee = requested_amount.sub(get_withdraw_fee(token, requested_amount));

    // do redeem
    {
      uint256 atoken_balance_before = atoken.balanceOf(address(this));
      require(atoken_balance_before >= requested_anchored_amount, "Insufficient funds on contract anchored balance");

      atoken.safeApprove(address(_tokens[token].conversion_pool), requested_anchored_amount);
      _tokens[token].conversion_pool.redeem(requested_anchored_amount);

      require(atoken_balance_before - atoken.balanceOf(address(this)) == requested_anchored_amount,
        "Redeem has not transferred full approved amount");

      _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);
      _total_pending_withdraw_amount[token] = _total_pending_withdraw_amount[token].add(requested_amount_after_fee);
    }

    // require(current_amount >= requested_amount) already checked
    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);

    bytes20 operation_id = bytes20(keccak256(abi.encodePacked(block.number, token, msg.sender)));

    _withdraw_operations[token].push(WithdrawOperation({
      operation_id: operation_id,
      user: msg.sender,
      requested_amount: requested_amount,
      requested_amount_after_fee: requested_amount_after_fee,
      anchored_amount: requested_anchored_amount,
      orioned_amount: requested_orioned_amount,
      updated_original_amount: updated_original_amount}));

    _active_withdraw_operations[token][msg.sender] = uint32(_withdraw_operations[token].length);

    emit WithdrawInit(address(token), msg.sender, operation_id,
                      requested_amount, requested_amount_after_fee,
                      requested_anchored_amount, requested_orioned_amount, updated_original_amount);
  }

  /*

  There are cases when users might want to transfer aTokens between Orion Money contracts.
  For example, if user holds funds with Orion Saver, but wants to participate in Private Farming event,
  this function will allow to transfer aTokens to PrivateFarming contract without withdrawing and then
  depositing back (helps to save on fees)

  */
  function transferDeposit(IERC20 token, IDepositable receiver, uint256 requested_amount) public criticalSection {
    checkToken(token);
    require(_active_withdraw_operations[token][msg.sender] == 0, "One withdraw allowed per user/token");
    require(requested_amount.div(_tokens[token].ten_pow_decimals) <= _withdraw_limit, "Amount exceeds withdraw limit");
    require(_white_list[receiver] == 1, "Receiver is not in the white list");

    IERC20 atoken = _tokens[token].anchored_token;

    (uint256 original_amount, uint256 orioned_amount, uint256 current_amount) = balanceOf(token, msg.sender);
    require(current_amount >= requested_amount, "Insufficient funds on user current balance");

    uint256 requested_orioned_amount = convert_tokens_to_orioned_amount(token, requested_amount);
    require(orioned_amount >= requested_orioned_amount, "Insufficient funds on user orioned balance");

    uint256 requested_anchored_amount = convert_tokens_to_atokens(token, requested_amount);

    uint256 atoken_balance_before = atoken.balanceOf(address(this));
    require(atoken_balance_before >= requested_anchored_amount, "Insufficient funds on contract anchored balance");

    atoken.safeApprove(address(receiver), requested_anchored_amount);
    receiver.depositAnchored(token, msg.sender, requested_anchored_amount);

    require(atoken_balance_before - atoken.balanceOf(address(this)) == requested_anchored_amount,
      "Deposit Receiver did not transfer approved tokens");

    _total_orioned_amount[token] = _total_orioned_amount[token].sub(requested_orioned_amount);

    // require(current_amount >= requested_amount) already checked
    uint256 updated_original_amount = (current_amount - requested_amount).min(original_amount);

    _balances[token][msg.sender].original_amount = updated_original_amount;
    _balances[token][msg.sender].orioned_amount = _balances[token][msg.sender].orioned_amount.sub(requested_orioned_amount);

    emit TransferDeposit(address(token), msg.sender, address(receiver),
      requested_amount, requested_anchored_amount,
      requested_orioned_amount, updated_original_amount);
  }

  function finalizeWithdrawUpToUser(IERC20 token, address stop_address) public criticalSection {
    checkToken(token);
    require(_withdraw_operations[token].length > _first_withdraw_operation[token], "No active withdraw operations");

    uint256 current_balance = token.balanceOf(address(this));
    uint i = _first_withdraw_operation[token];
    for (; i < _withdraw_operations[token].length; ++i) {
      WithdrawOperation memory op = _withdraw_operations[token][i];

      if (current_balance >= op.requested_amount_after_fee) {
        _balances[token][op.user].original_amount = op.updated_original_amount;
        _balances[token][op.user].orioned_amount = _balances[token][op.user].orioned_amount.sub(op.orioned_amount);

        token.safeTransfer(op.user, op.requested_amount_after_fee);

        _total_pending_withdraw_amount[token] = _total_pending_withdraw_amount[token].sub(op.requested_amount_after_fee);

        delete _active_withdraw_operations[token][op.user];
        delete _withdraw_operations[token][i];

        emit WithdrawFinalized(address(token), op.user, op.operation_id,
                               op.requested_amount, op.requested_amount_after_fee,
                               op.anchored_amount, op.orioned_amount, op.updated_original_amount);

        current_balance -= op.requested_amount_after_fee;
        if (op.user == stop_address) {
          ++i;
          break;
        }
      } else {
        require(i != _first_withdraw_operation[token], "Not enough funds on contract");
        break;
      }
    }

    // fully processed
    if (i < _withdraw_operations[token].length) {
      _first_withdraw_operation[token] = i;
    } else {
      delete _withdraw_operations[token];
      if (_first_withdraw_operation[token] != 0) _first_withdraw_operation[token] = 0;
    }
  }

  function finalizeWithdraw(IERC20 token) public {
    return finalizeWithdrawUpToUser(token, address(0));
  }

  function getActiveWithdrawOperationsCount(IERC20 token) public view returns (uint) {
    return _withdraw_operations[token].length - _first_withdraw_operation[token];
  }

  // 2 - can process 2 operation
  // 1 - can process 1 operation
  // 0 - can't process even the first operation
  // -1 - there is no any active operation to process
  function getWithdrawOperationsAbleToProcess(IERC20 token) public view returns (int) {
    checkToken(token);

    if (_first_withdraw_operation[token] >= _withdraw_operations[token].length) {
      return -1;
    }

    uint256 current_balance = token.balanceOf(address(this));
    uint i = _first_withdraw_operation[token];
    for (; i < _withdraw_operations[token].length; ++i) {
      if (current_balance < _withdraw_operations[token][i].requested_amount_after_fee) {
        break;
      }
      current_balance -= _withdraw_operations[token][i].requested_amount_after_fee;
    }
    return int(i - _first_withdraw_operation[token]);
  }

  function getWithdrawOperationByIndex(IERC20 token, uint idx) public view
  returns (bytes20 operation_id,
           address user,
           uint256 requested_amount,
           uint256 requested_amount_after_fee,
           uint256 anchored_amount,
           uint256 orioned_amount,
           uint256 updated_original_amount) {
    checkToken(token);
    require(idx + _first_withdraw_operation[token] < _withdraw_operations[token].length, "Index out of bounds");
    WithdrawOperation memory op = _withdraw_operations[token][idx + _first_withdraw_operation[token]];
    return (op.operation_id, op.user, op.requested_amount, op.requested_amount_after_fee,
            op.anchored_amount, op.orioned_amount, op.updated_original_amount);
  }

  function getActiveWithdrawOperation(IERC20 for_token, address for_user) public view
  returns (bytes20 operation_id,
           address user,
           uint256 requested_amount,
           uint256 requested_amount_after_fee,
           uint256 anchored_amount,
           uint256 orioned_amount,
           uint256 updated_original_amount) {
    checkToken(for_token);
    uint32 index_plus_1 = _active_withdraw_operations[for_token][for_user];
    require(index_plus_1 > _first_withdraw_operation[for_token] && index_plus_1 <= _withdraw_operations[for_token].length,
           "Active withdraw operation for this user and token not found");
    return getWithdrawOperationByIndex(for_token, index_plus_1 - 1);
  }

  function hasActiveWithdrawOperation(IERC20 token, address user) public view returns (bool) {
    checkToken(token);
    uint32 index_p1 = _active_withdraw_operations[token][user];
    return index_p1 > _first_withdraw_operation[token] && index_p1 <= _withdraw_operations[token].length;
  }

  function getTotalPendingWithdrawAmount(IERC20 token) public view returns (uint256) {
    checkToken(token);
    return _total_pending_withdraw_amount[token];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";


/* 
For a given APY (annual percentage yield) this contract calculates aToken/token exchange rate 
at any point in time after the contract deployment.

The formula is: currentValue = startValue * apy^(seconds/secondsPerYear). 
The second multiplier in this formula can be further represented as follows:
apy^(seconds/secondsPerYear) = 
  apy^((1/secondsPerYear)*seconds) = 
  (apy^(1/secondsPerYear))^seconds

Where apy^(1/secondsPerYear) is a constant which represents second to second growth of aToken/token 
exchange rate. This way formula becomes: currentValue = startValue * second_to_second_rate^seconds

Contract's constructor accepts two values: start_value and second_to_second_rate. The tricky part is 
how to calculate power of second_to_second_rate constant.

To do that using only integer ethereum arithmetic we pre-build table with following values
_rate_pows_num[0] = second_to_second_rate
_rate_pows_num[1] = second_to_second_rate^2
_rate_pows_num[2] = second_to_second_rate^4
_rate_pows_num[3] = second_to_second_rate^8
...
_rate_pows_num[31] = second_to_second_rate^32

We then use binary representation of seconds value, e.g. seconds = 13 = 0b1101 which is (1)*2^3 + (1)*2^2 + (0)*2^1 + (1)*2^0

second_to_second_rate^seconds = 
  second_to_second_rate^(1*2^3 + 1*2^2 + 0*2^1 + 1*2^0) =
  second_to_second_rate^(1*2^3) * second_to_second_rate^(1*2^2) * 1 * second_to_second_rate^(1*2^0) =
  second_to_second_rate^8 * second_to_second_rate^4 * second_to_second_rate =
  _rate_pows_num[3] * _rate_pows_num[2] * _rate_pows_num[0]

To use binary representation we use binary shift >> 1 and check the first bit every iteration

Please google for "binary exponention" or "exponention by squaring" for further details, 
e.g. https://cp-algorithms.com/algebra/binary-exp.html
*/

contract StableRateFeeder {
  using Math for uint256;
  using SafeMath for uint256;

  uint256 public start_value;
  uint32 public start_value_decimals;
  uint256 internal _start_value_denom; // 10^start_value_decimals

  uint256[1] internal _rate_pows_num; // rate_pows[i] = _second_to_second_rate^(2^i) * 10^rate_decimals;
  uint256 internal _rate_pows_denom;  // 10^rate_decimals

  uint public start_timestamp;

  //                         start_value_num
  // real start_value = ------------------------
  //                     10^start_value_decimals_
  constructor(uint256 start_value_num, uint32 start_value_decimals_,
              uint256 second_to_second_rate, uint32 rate_decimals) public {
    require(start_value_num != 0, "Start value can't be zero");
    require(start_value_decimals_ > 0 && start_value_decimals_ <= 59,
      "start_value_decimals should be more then 0 and less then 59");
    require(rate_decimals > 0 && rate_decimals <= 38,
      "rate_decimals should be more then 0 and less then 38");

    start_value = start_value_num;
    start_value_decimals = start_value_decimals_;
    _start_value_denom = 10 ** uint256(start_value_decimals);

    _rate_pows_num[0] = second_to_second_rate;
    _rate_pows_denom = 10 ** uint256(rate_decimals);

    start_timestamp = block.timestamp;
  }

  function getRatePow(uint n) public view returns (uint256) {
    uint256 rate_pow = _rate_pows_num[0];
    uint256 denom = _rate_pows_denom;
    for (uint i; i < n; ++i) {
      rate_pow = rate_pow.mul(rate_pow).div(denom);
    }
    return rate_pow;
  }

  // returns value * (second_to_second_rate)^pow_count
  function powerValueBy(uint256 value, uint pow_count) internal view returns (uint256) {
    uint256 rate_pow = _rate_pows_num[0];
    uint256 denom = _rate_pows_denom;
    for (uint i = 0; pow_count != 0; ++i) {
      if (pow_count & 1 != 0) {
        value = value.mul(rate_pow).div(denom);
      }
      rate_pow = rate_pow.mul(rate_pow).div(denom);
      pow_count >>= 1;
    }

    return value;
  }

  function getYearRate() public view returns (uint256) {
    return powerValueBy(1e18, 60*60*24*365);
  }

  function multiplyByRate(uint256 value, uint timestamp) public view returns (uint256) {
    require(timestamp >= start_timestamp, "Can't proceed the past");

    value = value.mul(start_value).div(_start_value_denom);
    if (timestamp > start_timestamp) {
      uint pow_count = timestamp - start_timestamp;
      return powerValueBy(value, pow_count);
    }
    return value;
  }

  function multiplyByCurrentRate(uint256 value) public view returns (uint256) {
    return multiplyByRate(value, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISaver {
  function balanceOf(IERC20 token, address user) external view returns (uint256 original_amount, uint256 orioned_amount, uint256 current_amount);

  function getDepositLimit() external view returns (uint256);

  function getLocalDepositLimit() external view returns (uint256);

  function deposit(IERC20 token, uint256 amount) external;

  function depositLocal(IERC20 token, uint256 amount) external;

  function canDepositLocal(IERC20 token, uint256 amount) external view returns(bool);

  function getWithdrawLimit() external view returns (uint256);

  function getLocalWithdrawLimit() external view returns (uint256);

  function withdraw(IERC20 token, uint256 requested_amount) external;

  function withdrawLocal(IERC20 token, uint256 requested_amount) external;

  function canWithdrawLocal(IERC20 token, uint256 amount) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDepositable {
  function depositAnchored(IERC20 token, address depositor, uint256 anchored_amount) external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library StdQueue {
    struct Queue {
        uint256 index;
        uint256 size;
        mapping(uint256 => bytes32) store;
    }

    function _length(Queue storage q) internal view returns (uint256) {
        return q.size;
    }

    function _isEmpty(Queue storage q) internal view returns (bool) {
        return q.size == 0;
    }

    function _getItemAt(Queue storage q, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return q.store[q.index + index];
    }

    function _produce(Queue storage q, bytes32 data) internal {
        q.store[q.index + q.size] = data;
        q.size += 1;
    }

    function _consume(Queue storage q) internal returns (bytes32) {
        require(!_isEmpty(q), "StdQueue: empty queue");
        bytes32 data = _getItemAt(q, 0);
        q.index += 1;
        q.size -= 1;
        return data;
    }

    // ====================== Bytes32 ====================== //

    struct Bytes32Queue {
        Queue _inner;
    }

    function length(Bytes32Queue storage queue)
        internal
        view
        returns (uint256)
    {
        return _length(queue._inner);
    }

    function isEmpty(Bytes32Queue storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    function getItemAt(Bytes32Queue storage queue, uint256 _index)
        internal
        view
        returns (bytes32)
    {
        return _getItemAt(queue._inner, _index);
    }

    function produce(Bytes32Queue storage queue, bytes32 _value) internal {
        _produce(queue._inner, _value);
    }

    function consume(Bytes32Queue storage queue) internal returns (bytes32) {
        return _consume(queue._inner);
    }

    // ====================== Address ====================== //

    struct AddressQueue {
        Queue _inner;
    }

    function length(AddressQueue storage queue)
        internal
        view
        returns (uint256)
    {
        return _length(queue._inner);
    }

    function isEmpty(AddressQueue storage queue) internal view returns (bool) {
        return _isEmpty(queue._inner);
    }

    function getItemAt(AddressQueue storage queue, uint256 _index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_getItemAt(queue._inner, _index))));
    }

    function produce(AddressQueue storage queue, address _value) internal {
        _produce(queue._inner, bytes32(uint256(uint160(_value))));
    }

    function consume(AddressQueue storage queue) internal returns (address) {
        return address(uint256(bytes32(_consume(queue._inner))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract Ownable_ is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable_: caller is not the owner");
        _;
    }

    function setOwner(address _newOwner) internal virtual {
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable_: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

contract Operator is Context {
    address public owner;
    address public operator;

    constructor() {
        owner = _msgSender();
        operator = _msgSender();
    }

    function setRole(address _owner, address _operator) internal virtual {
        owner = _owner;
        operator = _operator;
    }

    modifier onlyOwner {
        require(checkOwner(), "Operator: owner access denied");

        _;
    }

    function checkOwner() public view returns (bool) {
        return _msgSender() == owner;
    }

    modifier onlyOperator {
        require(checkOperator(), "Operator: operator access denied");

        _;
    }

    function checkOperator() public view returns (bool) {
        return _msgSender() == operator;
    }

    modifier onlyGranted {
        require(checkGranted(), "Operator: access denied");

        _;
    }

    function checkGranted() public view returns (bool) {
        return checkOwner() || checkOperator();
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }

    function transferOperator(address _operator) public onlyOwner {
        operator = _operator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20Controlled is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;

    function burnFrom(address _from, uint256 _amount) external;
}

contract ERC20Controlled is Context, Ownable, IERC20Controlled, ERC20 {
    using SafeMath for uint256;

    constructor(string memory _name, string memory _symbol)
        Ownable()
        ERC20(_name, _symbol)
    {}

    function mint(address _to, uint256 _amount) public override onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public override {
        _burn(_msgSender(), _amount);
    }

    function burnFrom(address _from, uint256 _amount) public override {
        uint256 decreasedAllowance =
            allowance(_from, _msgSender()).sub(
                _amount,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(_from, _msgSender(), decreasedAllowance);
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface ISwapper {
    function swapToken(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minAmountOut,
        address _beneficiary
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {StdQueue} from "../utils/Queue.sol";
import {IOperation} from "./Operation.sol";
import {OperationACL} from "./OperationACL.sol";

interface IOperationStore {
    // Events
    event OperationAllocated(
        address indexed controller,
        address indexed operation
    );
    event OperationInitialized(
        address indexed controller,
        address indexed operation,
        bool autoFinish
    );
    event OperationFinished(
        address indexed controller,
        address indexed operation
    );
    event OperationStopped(
        address indexed controller,
        address indexed operation
    );
    event OperationRecovered(
        address indexed controller,
        address indexed operation
    );
    event OperationDeallocated(
        address indexed controller,
        address indexed operation
    );
    event OperationFlushed(
        address indexed controller,
        address indexed operation,
        Queue from,
        Queue to
    );

    // Data Structure
    enum Status {
        IDLE,
        RUNNING_AUTO,
        RUNNING_MANUAL,
        FINISHED,
        STOPPED,
        RECOVERED,
        DEALLOCATED
    }

    enum Queue {IDLE, RUNNING, STOPPED, NULL}

    // getter
    function getAvailableOperation() external view returns (address);

    function getQueuedOperationAt(Queue _queue, uint256 _index)
        external
        view
        returns (address);

    function getQueueSizeOf(Queue _queue) external view returns (uint256);

    function getStatusOf(address _opt) external view returns (Status);

    // logics
    function allocate(address _opt) external;

    function init(bool _autoFinish) external returns (address);

    function finish(address _opt) external;

    function halt(address _opt) external;

    function recover(address _opt) external;

    function deallocate(address _opt) external;

    // queue
    function flush(Queue queue, uint256 _amount) external;

    function flushAll(uint256 _amount) external; // running, failed
}

contract OperationStore is IOperationStore, OperationACL {
    using StdQueue for StdQueue.AddressQueue;
    using EnumerableSet for EnumerableSet.AddressSet;

    // queues
    mapping(address => Status) public optStat;

    EnumerableSet.AddressSet internal optIdle;
    StdQueue.AddressQueue internal optStopped;
    StdQueue.AddressQueue internal optRunning;

    function getAvailableOperation() public view override returns (address) {
        if (optIdle.length() == 0) {
            return address(0x0);
        }
        return optIdle.at(0);
    }

    function getQueuedOperationAt(Queue _queue, uint256 _index)
        public
        view
        override
        returns (address)
    {
        if (_queue == Queue.IDLE) {
            return optIdle.at(_index);
        } else if (_queue == Queue.RUNNING) {
            return optRunning.getItemAt(_index);
        } else if (_queue == Queue.STOPPED) {
            return optStopped.getItemAt(_index);
        } else {
            revert("OperationStore: invalid queue type");
        }
    }

    function getQueueSizeOf(Queue _queue)
        public
        view
        override
        returns (uint256)
    {
        if (_queue == Queue.IDLE) {
            return optIdle.length();
        } else if (_queue == Queue.RUNNING) {
            return optRunning.length();
        } else if (_queue == Queue.STOPPED) {
            return optStopped.length();
        } else {
            revert("OperationStore: invalid queue type");
        }
    }

    function getStatusOf(address _opt) public view override returns (Status) {
        return optStat[_opt];
    }

    // lifecycle

    // x -> init
    function allocate(address _opt) public override onlyGranted {
        optIdle.add(_opt);
        optStat[_opt] = Status.IDLE;
        emit OperationAllocated(msg.sender, _opt);
    }

    // =========================== RUNNING QUEUE OPERATIONS =========================== //

    // init -> finish -> idle
    //      -> fail -> ~
    //      -> x (if autoFinish disabled)
    function init(bool _autoFinish)
        public
        override
        onlyRouter
        returns (address)
    {
        // consume
        address opt = optIdle.at(0);
        optIdle.remove(opt);

        if (_autoFinish) {
            optRunning.produce(opt); // idle -> running
            optStat[opt] = Status.RUNNING_AUTO;
        } else {
            optStat[opt] = Status.RUNNING_MANUAL;
        }

        emit OperationInitialized(msg.sender, opt, _autoFinish);
        return opt;
    }

    // =========================== RUNNING QUEUE OPERATIONS =========================== //

    function finish(address _opt) public override onlyGranted {
        Status status = optStat[_opt];

        if (status == Status.RUNNING_MANUAL) {
            allocate(_opt);
        } else if (status == Status.RUNNING_AUTO) {
            // wait for flush
            optStat[_opt] = Status.FINISHED;
        } else {
            revert("Router: invalid condition for finish operation");
        }

        emit OperationFinished(msg.sender, _opt);
    }

    // fail -> recover -> idle
    //      -> deallocate -> x
    function halt(address _opt) public override onlyController {
        Status stat = optStat[_opt];
        if (stat == Status.IDLE) {
            // push to failed queue
            optIdle.remove(_opt);
            optStopped.produce(_opt);
        }
        optStat[_opt] = Status.STOPPED;
        emit OperationStopped(msg.sender, _opt);
    }

    function flushRunningQueue(StdQueue.AddressQueue storage _queue)
        internal
        returns (bool)
    {
        address opt = _queue.getItemAt(0);
        Status stat = optStat[opt];
        if (stat == Status.FINISHED) {
            optIdle.add(_queue.consume());
            optStat[opt] = Status.IDLE;
            emit OperationFlushed(msg.sender, opt, Queue.RUNNING, Queue.IDLE);
        } else if (stat == Status.STOPPED) {
            optStopped.produce(_queue.consume());
            emit OperationFlushed(
                msg.sender,
                opt,
                Queue.RUNNING,
                Queue.STOPPED
            );
        } else {
            return false; // RUNNING
        }
        return true;
    }

    // =========================== FAIL QUEUE OPERATIONS =========================== //

    function recover(address _opt) public override onlyController {
        optStat[_opt] = Status.RECOVERED;
        emit OperationRecovered(msg.sender, _opt);
    }

    function deallocate(address _opt) public override onlyController {
        optStat[_opt] = Status.DEALLOCATED;
        emit OperationDeallocated(msg.sender, _opt);
    }

    function flushStoppedQueue(StdQueue.AddressQueue storage _queue)
        internal
        returns (bool)
    {
        address opt = _queue.getItemAt(0);
        Status stat = optStat[opt];
        if (stat == Status.RECOVERED) {
            optIdle.add(_queue.consume());
            optStat[opt] = Status.IDLE;
            emit OperationFlushed(msg.sender, opt, Queue.STOPPED, Queue.IDLE);
        } else if (stat == Status.DEALLOCATED) {
            _queue.consume();
            emit OperationFlushed(msg.sender, opt, Queue.STOPPED, Queue.NULL);
        } else {
            return false; // STOPPED
        }

        return true;
    }

    function _flush(
        StdQueue.AddressQueue storage _queue,
        uint256 _amount,
        function(StdQueue.AddressQueue storage) returns (bool) _handler
    ) internal {
        for (uint256 i = 0; i < _amount; i++) {
            if (_queue.isEmpty()) {
                return;
            }

            if (!_handler(_queue)) {
                return;
            }
        }
    }

    function flush(Queue _queue, uint256 _amount)
        public
        override
        onlyController
    {
        if (_queue == Queue.RUNNING) {
            _flush(optRunning, _amount, flushRunningQueue);
        } else if (_queue == Queue.STOPPED) {
            _flush(optStopped, _amount, flushStoppedQueue);
        } else {
            revert("OperationStore: invalid queue type");
        }
    }

    function flushAll(uint256 _amount) public override onlyController {
        flush(Queue.RUNNING, _amount);
        flush(Queue.STOPPED, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {OperationACL} from "./OperationACL.sol";

interface OperationStandard {
    function initialize(bytes memory) external;

    function initPayload(
        address,
        address,
        bytes32
    ) external view returns (bytes memory);
}

interface IOperationFactory {
    event ContractDeployed(
        address indexed instance,
        address indexed controller,
        bytes32 indexed terraAddress
    );

    struct Standard {
        address router;
        address controller;
        address operation;
    }

    function pushTerraAddresses(bytes32[] memory _addrs) external;

    function fetchAddressBufferSize() external view returns (uint256);

    function fetchNextTerraAddress() external view returns (bytes32);

    function build(uint256 _optId) external returns (address);
}

contract OperationFactory is IOperationFactory, OperationACL {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // standard operations
    uint256 public standardIndex = 0;
    mapping(uint256 => Standard) public standards;

    function pushStandardOperation(
        address _router,
        address _controller,
        address _operation
    ) public onlyOwner returns (uint256) {
        uint256 optStdId = standardIndex;
        standards[optStdId] = Standard({
            router: _router,
            controller: _controller,
            operation: _operation
        });
        standardIndex += 1;
        return optStdId;
    }

    // terra address buffer
    EnumerableSet.Bytes32Set private terraAddresses;

    function pushTerraAddresses(bytes32[] memory _addrs)
        public
        override
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            terraAddresses.add(_addrs[i]);
        }
    }

    function fetchAddressBufferSize() public view override returns (uint256) {
        return terraAddresses.length();
    }

    function fetchNextTerraAddress() public view override returns (bytes32) {
        return terraAddresses.at(0);
    }

    function fetchTerraAddress() private returns (bytes32) {
        bytes32 addr = terraAddresses.at(0);
        terraAddresses.remove(addr);
        return addr;
    }

    function build(uint256 _optId)
        public
        override
        onlyGranted
        returns (address)
    {
        bytes32 terraAddr = fetchTerraAddress();
        Standard memory std = standards[_optId];

        address instance = Clones.clone(std.operation);
        bytes memory payload =
            OperationStandard(std.operation).initPayload(
                std.router,
                std.controller,
                terraAddr
            );
        OperationStandard(instance).initialize(payload);

        emit ContractDeployed(instance, std.controller, terraAddr);

        return instance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

abstract contract OperationACL is Context {
    address public owner;
    address public router;
    address public controller;

    constructor() {
        owner = _msgSender();
        router = _msgSender();
        controller = _msgSender();
    }

    modifier onlyOwner {
        require(_msgSender() == owner, "OperationACL: owner access denied");

        _;
    }

    modifier onlyRouter {
        require(_msgSender() == router, "OperationACL: router access denied");

        _;
    }

    modifier onlyController {
        require(
            _msgSender() == controller,
            "OperationACL: controller access denied"
        );

        _;
    }

    modifier onlyGranted {
        address sender = _msgSender();
        require(
            sender == owner || sender == router || sender == controller,
            "OperationACL: denied"
        );

        _;
    }

    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }

    function transferRouter(address _router) public onlyOwner {
        router = _router;
    }

    function transferController(address _controller) public onlyOwner {
        controller = _controller;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {WrappedAsset} from "../assets/WrappedAsset.sol";
import {Operator} from "../utils/Operator.sol";
import {OperationACL} from "./OperationACL.sol";
import {ISwapper} from "../swapper/ISwapper.sol";

interface IOperation {
    // Events
    event AutoFinishEnabled(address indexed operation);
    event InitDeposit(address indexed operator, uint256 amount, bytes32 to);
    event FinishDeposit(address indexed operator, uint256 amount);
    event InitRedemption(address indexed operator, uint256 amount, bytes32 to);
    event FinishRedemption(address indexed operator, uint256 amount);
    event EmergencyWithdrawActivated(address token, uint256 amount);

    // Data Structure
    enum Status {IDLE, RUNNING, STOPPED}
    enum Type {NEUTRAL, DEPOSIT, REDEEM}

    struct Info {
        Status status;
        Type typ;
        address operator;
        uint256 amount;
        address input;
        address output;
        address swapper;
        address swapDest;
    }

    // Interfaces

    function terraAddress() external view returns (bytes32);

    function getCurrentStatus() external view returns (Info memory);

    function initDepositStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) external;

    function initRedeemStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) external;

    function finish() external;

    function finish(uint256 _minAmountOut) external;

    function finishDepositStable() external;

    function finishRedeemStable() external;

    function halt() external;

    function recover() external;

    function emergencyWithdraw(address _token, address _to) external;

    function emergencyWithdraw(address payable _to) external;
}

// Operation.sol: subcontract generated per wallet, defining all relevant wrapping functions
contract Operation is Context, OperationACL, IOperation, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for WrappedAsset;

    Info public DEFAULT_STATUS =
        Info({
            status: Status.IDLE,
            typ: Type.NEUTRAL,
            operator: address(0x0),
            amount: 0,
            input: address(0x0),
            output: address(0x0),
            swapper: address(0x0),
            swapDest: address(0x0)
        });
    Info public currentStatus;

    WrappedAsset public wUST;
    WrappedAsset public aUST;

    bytes32 public override terraAddress;

    function initialize(bytes memory args) public initializer {
        (
            address _router,
            address _controller,
            bytes32 _terraAddress,
            address _wUST,
            address _aUST
        ) = abi.decode(args, (address, address, bytes32, address, address));

        currentStatus = DEFAULT_STATUS;
        terraAddress = _terraAddress;
        wUST = WrappedAsset(_wUST);
        aUST = WrappedAsset(_aUST);

        router = _router;
        controller = _controller;
    }

    function initPayload(
        address _router,
        address _controller,
        bytes32 _terraAddress
    ) public view returns (bytes memory) {
        return abi.encode(_router, _controller, _terraAddress, wUST, aUST);
    }

    modifier checkStopped {
        require(currentStatus.status != Status.STOPPED, "Operation: stopped");

        _;
    }

    function getCurrentStatus() public view override returns (Info memory) {
        return currentStatus;
    }

    function _init(
        Type _typ,
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) private onlyRouter checkStopped {
        require(currentStatus.status == Status.IDLE, "Operation: running");
        require(_amount >= 10 ether, "Operation: amount must be more than 10");

        currentStatus = Info({
            status: Status.RUNNING,
            typ: _typ,
            operator: _operator,
            amount: _amount,
            input: address(0x0),
            output: address(0x0),
            swapper: _swapper,
            swapDest: _swapDest
        });

        if (_typ == Type.DEPOSIT) {
            currentStatus.input = address(wUST);
            currentStatus.output = address(aUST);

            wUST.safeTransferFrom(_msgSender(), address(this), _amount);
            wUST.burn(_amount, terraAddress);

            emit InitDeposit(_operator, _amount, terraAddress);
        } else if (_typ == Type.REDEEM) {
            currentStatus.input = address(aUST);
            currentStatus.output = address(wUST);

            aUST.safeTransferFrom(_msgSender(), address(this), _amount);
            aUST.burn(_amount, terraAddress);

            emit InitRedemption(_operator, _amount, terraAddress);
        } else {
            revert("Operation: invalid operation type");
        }

        if (_autoFinish) {
            emit AutoFinishEnabled(address(this));
        }
    }

    function initDepositStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) public override {
        _init(
            Type.DEPOSIT,
            _operator,
            _amount,
            _swapper,
            _swapDest,
            _autoFinish
        );
    }

    function initRedeemStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) public override {
        _init(
            Type.REDEEM,
            _operator,
            _amount,
            _swapper,
            _swapDest,
            _autoFinish
        );
    }

    function _finish(uint256 _minAmountOut)
        private
        onlyGranted
        checkStopped
        returns (address, uint256)
    {
        // check status
        require(currentStatus.status == Status.RUNNING, "Operation: idle");

        WrappedAsset output = WrappedAsset(currentStatus.output);
        uint256 amount = output.balanceOf(address(this));
        address operator = currentStatus.operator;
        address swapper = currentStatus.swapper;

        require(amount > 0, "Operation: not enough token");

        if (swapper != address(0x0)) {
            output.safeIncreaseAllowance(swapper, amount);

            try
                ISwapper(swapper).swapToken(
                    address(output),
                    currentStatus.swapDest,
                    amount,
                    _minAmountOut,
                    operator
                )
            {} catch {
                output.safeDecreaseAllowance(swapper, amount);
                output.safeTransfer(operator, amount);
            }
        } else {
            output.safeTransfer(operator, amount);
        }

        // state reference gas optimization
        Type typ = currentStatus.typ;

        if (typ == Type.DEPOSIT) {
            emit FinishDeposit(operator, amount);
        } else if (typ == Type.REDEEM) {
            emit FinishRedemption(operator, amount);
        }

        // reset
        currentStatus = DEFAULT_STATUS;

        return (address(output), amount);
    }

    function finish() public override {
        _finish(0);
    }

    function finish(uint256 _minAmountOut) public override {
        _finish(_minAmountOut);
    }

    function finishDepositStable() public override {
        _finish(0);
    }

    function finishRedeemStable() public override {
        _finish(0);
    }

    function halt() public override onlyController {
        currentStatus.status = Status.STOPPED;
    }

    function recover() public override onlyController {
        if (currentStatus.operator == address(0x0)) {
            currentStatus.status = Status.IDLE;
        } else {
            currentStatus.status = Status.RUNNING;
        }
    }

    function emergencyWithdraw(address _token, address _to)
        public
        override
        onlyController
    {
        require(
            currentStatus.status == Status.STOPPED,
            "Operation: not an emergency"
        );

        if (currentStatus.operator != address(0x0)) {
            require(
                currentStatus.output != _token,
                "Operation: withdrawal rejected"
            );
        }

        IERC20(_token).safeTransfer(
            _to,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function emergencyWithdraw(address payable _to)
        public
        override
        onlyController
    {
        require(
            currentStatus.status == Status.STOPPED,
            "Operation: not an emergency"
        );

        _to.transfer(address(this).balance);
    }
}

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IExchangeRateFeeder {
    event RateUpdated(
        address indexed _operator,
        address indexed _token,
        uint256 _before,
        uint256 _after,
        uint256 _updateCount
    );

    enum Status {NEUTRAL, RUNNING, STOPPED}

    struct Token {
        Status status;
        uint256 exchangeRate;
        uint256 period;
        uint256 weight;
        uint256 lastUpdatedAt;
    }

    function exchangeRateOf(address _token, bool _simulate)
        external
        view
        returns (uint256);

    function update(address _token) external;
}

interface IExchangeRateFeederGov {
    function addToken(
        address _token,
        uint256 _baseRate,
        uint256 _period,
        uint256 _weight
    ) external;

    function startUpdate(address[] memory _tokens) external;

    function stopUpdate(address[] memory _tokens) external;
}

contract ExchangeRateFeeder is IExchangeRateFeeder, Ownable {
    using SafeMath for uint256;

    mapping(address => Token) public tokens;

    function addToken(
        address _token,
        uint256 _baseRate,
        uint256 _period,
        uint256 _weight
    ) public onlyOwner {
        tokens[_token] = Token({
            status: Status.NEUTRAL,
            exchangeRate: _baseRate,
            period: _period,
            weight: _weight,
            lastUpdatedAt: block.timestamp
        });
    }

    function startUpdate(address[] memory _tokens) public onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens[_tokens[i]].status = Status.RUNNING;
            tokens[_tokens[i]].lastUpdatedAt = block.timestamp; // reset
        }
    }

    function stopUpdate(address[] memory _tokens) public onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens[_tokens[i]].status = Status.STOPPED;
        }
    }

    function exchangeRateOf(address _token, bool _simulate)
        public
        view
        override
        returns (uint256)
    {
        uint256 exchangeRate = tokens[_token].exchangeRate;
        if (_simulate) {
            Token memory token = tokens[_token];

            uint256 elapsed = block.timestamp.sub(token.lastUpdatedAt);
            uint256 updateCount = elapsed.div(token.period);
            for (uint256 i = 0; i < updateCount; i++) {
                exchangeRate = exchangeRate.mul(token.weight).div(1e18);
            }
        }
        return exchangeRate;
    }

    function update(address _token) public override {
        Token memory token = tokens[_token];

        require(token.status == Status.RUNNING, "Feeder: invalid status");

        uint256 elapsed = block.timestamp.sub(token.lastUpdatedAt);
        if (elapsed < token.period) {
            return;
        }

        uint256 updateCount = elapsed.div(token.period);
        uint256 exchangeRateBefore = token.exchangeRate; // log
        for (uint256 i = 0; i < updateCount; i++) {
            token.exchangeRate = token.exchangeRate.mul(token.weight).div(1e18);
        }
        token.lastUpdatedAt = block.timestamp;

        tokens[_token] = token;

        emit RateUpdated(
            msg.sender,
            _token,
            exchangeRateBefore,
            token.exchangeRate,
            updateCount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {
    IUniswapV2Pair
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {IExchangeRateFeeder} from "./ExchangeRateFeeder.sol";
import {IRouter, IConversionRouter} from "../core/Router.sol";
import {Operator} from "../utils/Operator.sol";
import {ISwapper} from "../swapper/ISwapper.sol";
import {IERC20Controlled, ERC20Controlled} from "../utils/ERC20Controlled.sol";
import {UniswapV2Library} from "../libraries/UniswapV2Library.sol";

interface IConversionPool {
    function deposit(uint256 _amount) external;

    function deposit(uint256 _amount, uint256 _minAmountOut) external;

    function redeem(uint256 _amount) external;

    function redeem(uint256 _amount, uint256 _minAmountOut) external;
}

contract ConversionPool is IConversionPool, Context, Operator, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Controlled;

    // pool token settings
    IERC20 public inputToken; // DAI / USDC / USDT
    IERC20Controlled public outputToken; // aDAI / aUSDC / aUSDT

    // swap settings
    ISwapper public swapper;

    // proxy settings
    IERC20 public proxyInputToken; // UST
    IERC20 public proxyOutputToken; // aUST
    uint256 public proxyReserve = 0; // aUST reserve

    address public optRouter;
    IExchangeRateFeeder public feeder;

    // flags
    bool public isDepositAllowed = true;
    bool public isRedemptionAllowed = true;

    function initialize(
        // ===== tokens
        string memory _outputTokenName,
        string memory _outputTokenSymbol,
        address _inputToken,
        address _proxyInputToken,
        address _proxyOutputToken,
        // ===== others
        address _optRouter,
        address _swapper,
        address _exchangeRateFeeder
    ) public initializer {
        inputToken = IERC20(_inputToken);
        outputToken = new ERC20Controlled(_outputTokenName, _outputTokenSymbol);

        proxyInputToken = IERC20(_proxyInputToken);
        proxyOutputToken = IERC20(_proxyOutputToken);

        setRole(msg.sender, msg.sender);
        setSwapper(_swapper);
        setOperationRouter(_optRouter);
        setExchangeRateFeeder(_exchangeRateFeeder);
    }

    // governance

    function setSwapper(address _swapper) public onlyOwner {
        swapper = ISwapper(_swapper);
        inputToken.safeApprove(address(swapper), type(uint256).max);
    }

    function setOperationRouter(address _optRouter) public onlyOwner {
        optRouter = _optRouter;
        proxyInputToken.safeApprove(optRouter, type(uint256).max);
        proxyOutputToken.safeApprove(optRouter, type(uint256).max);
    }

    function setExchangeRateFeeder(address _exchangeRateFeeder)
        public
        onlyOwner
    {
        feeder = IExchangeRateFeeder(_exchangeRateFeeder);
    }

    function setDepositAllowance(bool _allow) public onlyOwner {
        isDepositAllowed = _allow;
    }

    function setRedemptionAllowance(bool _allow) public onlyOwner {
        isRedemptionAllowed = _allow;
    }

    // migrate
    function migrate(address _to) public onlyOwner {
        require(
            !(isDepositAllowed && isRedemptionAllowed),
            "ConversionPool: invalid status"
        );

        proxyOutputToken.transfer(
            _to,
            proxyOutputToken.balanceOf(address(this))
        );
    }

    // reserve

    function provideReserve(uint256 _amount) public onlyGranted {
        proxyReserve = proxyReserve.add(_amount);
        proxyOutputToken.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function removeReserve(uint256 _amount) public onlyGranted {
        proxyReserve = proxyReserve.sub(_amount);
        proxyOutputToken.safeTransfer(_msgSender(), _amount);
    }

    // operations

    modifier _updateExchangeRate {
        feeder.update(address(inputToken));
        feeder.update(address(proxyInputToken));

        _;
    }

    function earn() public onlyOwner _updateExchangeRate {
        require(
            proxyReserve < proxyOutputToken.balanceOf(address(this)),
            "ConversionPool: not enough balance"
        );

        // UST(aUST) - UST(aToken) = earnable amount
        uint256 pER = feeder.exchangeRateOf(address(inputToken), false);
        uint256 pv = outputToken.totalSupply().mul(pER).div(1e18);

        uint256 aER = feeder.exchangeRateOf(address(proxyInputToken), false);
        uint256 av =
            proxyOutputToken
                .balanceOf(address(this))
                .sub(proxyReserve)
                .mul(aER)
                .div(1e18);

        if (av < pv) {
            return;
        }

        uint256 earnAmount = av.sub(pv);
        proxyOutputToken.safeTransfer(
            msg.sender,
            earnAmount.mul(1e18).div(aER)
        );
    }

    function deposit(uint256 _amount) public override {
        deposit(_amount, 0);
    }

    function deposit(uint256 _amount, uint256 _minAmountOut)
        public
        override
        _updateExchangeRate
    {
        require(isDepositAllowed, "ConversionPool: deposit not stopped");

        inputToken.safeTransferFrom(_msgSender(), address(this), _amount);

        // swap to UST
        swapper.swapToken(
            address(inputToken),
            address(proxyInputToken),
            _amount,
            _minAmountOut,
            address(this)
        );

        // depositStable
        uint256 ust = proxyInputToken.balanceOf(address(this));
        IRouter(optRouter).depositStable(ust);

        uint256 pER = feeder.exchangeRateOf(address(inputToken), false);
        outputToken.mint(_msgSender(), ust.mul(1e18).div(pER));
    }

    function redeem(uint256 _amount) public override _updateExchangeRate {
        require(isRedemptionAllowed, "ConversionPool: redemption not allowed");

        outputToken.burnFrom(_msgSender(), _amount);

        uint256 pER = feeder.exchangeRateOf(address(inputToken), false);
        uint256 out = _amount.mul(pER).div(1e18);

        uint256 aER = feeder.exchangeRateOf(address(proxyInputToken), false);
        IConversionRouter(optRouter).redeemStable(
            _msgSender(),
            out.mul(1e18).div(aER),
            address(swapper),
            address(inputToken)
        );
    }

    function redeem(uint256 _amount, uint256 _minAmountOut) public override {
        redeem(_amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {Ownable_} from "../utils/Ownable.sol";
import {StdQueue} from "../utils/Queue.sol";
import {IOperation} from "../operations/Operation.sol";
import {IOperationStore} from "../operations/OperationStore.sol";
import {IOperationFactory} from "../operations/OperationFactory.sol";

interface IRouter {
    // ======================= common ======================= //

    function init(
        IOperation.Type _type,
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) external;

    function finish(address _operation) external;

    // ======================= deposit stable ======================= //

    function depositStable(uint256 _amount) external;

    function depositStable(address _operator, uint256 _amount) external;

    function initDepositStable(uint256 _amount) external;

    function finishDepositStable(address _operation) external;

    // ======================= redeem stable ======================= //

    function redeemStable(uint256 _amount) external;

    function redeemStable(address _operator, uint256 _amount) external;

    function initRedeemStable(uint256 _amount) external;

    function finishRedeemStable(address _operation) external;
}

interface IConversionRouter {
    // ======================= deposit stable ======================= //

    function depositStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) external;

    function initDepositStable(
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) external;

    // ======================= redeem stable ======================= //

    function redeemStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) external;

    function initRedeemStable(
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) external;
}

contract Router is IRouter, IConversionRouter, Context, Ownable_, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // operation
    address public optStore;
    uint256 public optStdId;
    address public optFactory;

    // constant
    address public wUST;
    address public aUST;

    // flags
    bool public isDepositAllowed = true;
    bool public isRedemptionAllowed = true;

    function initialize(
        address _optStore,
        uint256 _optStdId,
        address _optFactory,
        address _wUST,
        address _aUST
    ) public initializer {
        optStore = _optStore;
        optStdId = _optStdId;
        optFactory = _optFactory;
        wUST = _wUST;
        aUST = _aUST;
        setOwner(msg.sender);
    }

    function setOperationStore(address _store) public onlyOwner {
        optStore = _store;
    }

    function setOperationId(uint256 _optStdId) public onlyOwner {
        optStdId = _optStdId;
    }

    function setOperationFactory(address _factory) public onlyOwner {
        optFactory = _factory;
    }

    function setDepositAllowance(bool _allow) public onlyOwner {
        isDepositAllowed = _allow;
    }

    function setRedemptionAllowance(bool _allow) public onlyOwner {
        isRedemptionAllowed = _allow;
    }

    function _init(
        IOperation.Type _typ,
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) internal {
        IOperationStore store = IOperationStore(optStore);
        if (store.getAvailableOperation() == address(0x0)) {
            address instance = IOperationFactory(optFactory).build(optStdId);
            store.allocate(instance);
        }
        IOperation operation = IOperation(store.init(_autoFinish));

        // check allowance
        if (IERC20(wUST).allowance(address(this), address(operation)) == 0) {
            IERC20(wUST).safeApprove(address(operation), type(uint256).max);
            IERC20(aUST).safeApprove(address(operation), type(uint256).max);
        }

        if (_typ == IOperation.Type.DEPOSIT) {
            IERC20(wUST).safeTransferFrom(_msgSender(), address(this), _amount);
            operation.initDepositStable(
                _operator,
                _amount,
                _swapper,
                _swapDest,
                _autoFinish
            );
            return;
        }

        if (_typ == IOperation.Type.REDEEM) {
            IERC20(aUST).safeTransferFrom(_msgSender(), address(this), _amount);
            operation.initRedeemStable(
                _operator,
                _amount,
                _swapper,
                _swapDest,
                _autoFinish
            );
            return;
        }

        revert("Router: invalid operation type");
    }

    function _finish(address _opt) internal {
        IOperationStore.Status status =
            IOperationStore(optStore).getStatusOf(_opt);

        if (status == IOperationStore.Status.RUNNING_MANUAL) {
            // check sender
            require(
                IOperation(_opt).getCurrentStatus().operator == _msgSender(),
                "Router: invalid sender"
            );
        } else {
            revert("Router: invalid status for finish");
        }

        IOperation(_opt).finish();
        IOperationStore(optStore).finish(_opt);
    }

    // =================================== COMMON =================================== //

    function init(
        IOperation.Type _type,
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest,
        bool _autoFinish
    ) public override {
        _init(_type, _operator, _amount, _swapper, _swapDest, _autoFinish);
    }

    function finish(address _operation) public override {
        _finish(_operation);
    }

    // =================================== DEPOSIT STABLE =================================== //

    function depositStable(uint256 _amount) public override {
        _init(
            IOperation.Type.DEPOSIT,
            _msgSender(),
            _amount,
            address(0x0),
            address(0x0),
            true
        );
    }

    function depositStable(address _operator, uint256 _amount) public override {
        _init(
            IOperation.Type.DEPOSIT,
            _operator,
            _amount,
            address(0x0),
            address(0x0),
            true
        );
    }

    function depositStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) public override {
        _init(
            IOperation.Type.DEPOSIT,
            _operator,
            _amount,
            _swapper,
            _swapDest,
            true
        );
    }

    function initDepositStable(uint256 _amount) public override {
        _init(
            IOperation.Type.DEPOSIT,
            _msgSender(),
            _amount,
            address(0x0),
            address(0x0),
            false
        );
    }

    function initDepositStable(
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) public override {
        _init(
            IOperation.Type.DEPOSIT,
            _msgSender(),
            _amount,
            _swapper,
            _swapDest,
            false
        );
    }

    function finishDepositStable(address _operation) public override {
        _finish(_operation);
    }

    // =================================== REDEEM STABLE =================================== //

    function redeemStable(uint256 _amount) public override {
        _init(
            IOperation.Type.REDEEM,
            _msgSender(),
            _amount,
            address(0x0),
            address(0x0),
            true
        );
    }

    function redeemStable(address _operator, uint256 _amount) public override {
        _init(
            IOperation.Type.REDEEM,
            _operator,
            _amount,
            address(0x0),
            address(0x0),
            true
        );
    }

    function redeemStable(
        address _operator,
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) public override {
        _init(
            IOperation.Type.REDEEM,
            _operator,
            _amount,
            _swapper,
            _swapDest,
            true
        );
    }

    function initRedeemStable(uint256 _amount) public override {
        _init(
            IOperation.Type.REDEEM,
            _msgSender(),
            _amount,
            address(0x0),
            address(0x0),
            false
        );
    }

    function initRedeemStable(
        uint256 _amount,
        address _swapper,
        address _swapDest
    ) public override {
        _init(
            IOperation.Type.REDEEM,
            _msgSender(),
            _amount,
            _swapper,
            _swapDest,
            false
        );
    }

    function finishRedeemStable(address _operation) public override {
        _finish(_operation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WrappedAsset is IERC20 {
    event Burn(address indexed _sender, bytes32 indexed _to, uint256 amount);

    function burn(uint256 amount, bytes32 to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}