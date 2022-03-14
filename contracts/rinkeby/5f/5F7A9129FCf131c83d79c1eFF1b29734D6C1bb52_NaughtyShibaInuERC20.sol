// SPDX-License-Identifier: UNLICENSED
// Author: @moonchimpe
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract NaughtyShibaInuERC20 is ERC20, Ownable{

  IUniswapV2Router02 public immutable _uniswapV2Router;
  address public immutable _uniswapV2Pair;
  address public constant _deadAddress = address(0xdead);

  bool private _swapping;

  address public _marketingWallet;
  address public _devWallet;

  uint public _maxTxnAmount;
  uint public _swapTokensThreshold;
  uint public _maxWallet;

  uint public _percentForLPBurn = 25; //25 = .25%
  bool public _lpBurnEnabled = true;
  uint public _lpBurnFrequency = 3600 seconds;
  uint public _lastLpBurnTime;

  uint public _manualBurnFrequency = 30 minutes;
  uint public _lastManualLpBurnTime;

  bool public _limitsInEffect = true;
  bool public _tradingEnabled = false;
  bool public _swapEnabled = false;

  /// Anti-bot and ant-whale mappings and variables

  /// @notice Hold last transfers temporarily during launch
  /// account => timestamp
  mapping(address => uint) private _holderLastTransferTimestamp;
  bool public _transferDelayEnabled = true;

  /// All fees scaled by 100 (i.e. 5 = 5%)

  uint public _buyTotalFees;
  uint public _buyMarketingFee;
  uint public _buyLiquidityFee;
  uint public _buyDevFee;

  uint public _sellTotalFees;
  uint public _sellMarketingFee;
  uint public _sellLiquidityFee;
  uint public _sellDevFee;

  uint public _tokensForMarketing;
  uint public _tokensForLiquidity;
  uint public _tokensForDev;

  mapping(address => bool) public _isExcludedFromFees;
  mapping(address => bool) public _isExcludedFromMaxTxn;

  /// Store addresses of AMM pairs. Any transfer *to* these addresses
  /// could be subject to a maximum transfer amount
  /// contractAddress => bool
  mapping(address => bool) public _AMMPairs;

  event TradingEnabled();

  event LimitsRemoved();

  event TransferDelayDisabled();

  event UpdateSwapTokensThreshold(uint amount);
  
  event UpdateBuyFees(uint marketingFee, uint liquidityFee, uint devFee);

  event UpdateSellFees(uint marketingFee, uint liquidityFee, uint devFee);

  event UpdateMarketingWallet(address indexed newWallet, address indexed oldWallet);

  event UpdateDevWallet(address indexed newWallet, address indexed oldWallet);
  
  event ExcludeFromFees(address indexed account, bool isExcluded);

  event ExcludeFromMaxTxn(address indexed account, bool isExcluded);
  
  event SetAMMPair(address indexed pair, bool indexed value);

  event SwapAndLiquify(uint tokensSwapped, uint ethForLP, uint tokensForLP);

  event AutoNukeLP();

  event ManualNukeLP();
  
  constructor(
              address marketingWallet,
              address devWallet
              ) ERC20("Naughty Shiba Inu", "NAUTY"){

    // Mainnet `UniswapV2Router02` contract deployment address
    // See https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
    _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    excludeFromMaxTxn(address(_uniswapV2Router), true);

    // Create the WETH/Token liquidity pool on Uniswap V2
    IUniswapV2Factory factory = IUniswapV2Factory(_uniswapV2Router.factory());
    _uniswapV2Pair = factory.createPair(address(this), _uniswapV2Router.WETH());
    excludeFromMaxTxn(_uniswapV2Pair, true);
    setAMMPair(_uniswapV2Pair, true);

    // Set initial buy fees
    _buyMarketingFee = 5;
    _buyLiquidityFee = 3;
    _buyDevFee = 2;
    _buyTotalFees = _buyMarketingFee + _buyLiquidityFee + _buyDevFee;

    // Set initial sell fees
    _sellMarketingFee = 10;
    _sellLiquidityFee = 3;
    _sellDevFee =2;
    _sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee;
       
    _maxTxnAmount = 10_000_000 * 1e18; // 1% from total supply
    _maxWallet = 20_000_000 * 1e18; // 2% from total supply
    _swapTokensThreshold = 500_000 * 1e18; // .05% from total supply
    
    _marketingWallet = marketingWallet;
    _devWallet = devWallet;

    excludeFromFees(owner(), true);
    excludeFromFees(address(this), true);
    excludeFromFees(address(0xdead), true);
    
    excludeFromMaxTxn(owner(), true);
    excludeFromMaxTxn(address(this), true);
    excludeFromMaxTxn(address(0xdead), true);

    uint totalSupply = 1_000_000_000 * 1e18;
    _mint(msg.sender, totalSupply);
    
  }

  receive() external payable {}

  /** ADMIN FUNCTIONS **/

  /// @notice Enables trading.
  /// NOTE: Once enabled, can never be disabled.
  function enableTrading() external onlyOwner {
    _tradingEnabled = true;
    _swapEnabled = true;
    _lastLpBurnTime = block.timestamp;
    emit TradingEnabled();
  }

  /// @notice Remove limits after token is stable.
  /// NOTE: Once disabled, can never be re-enabled.
  function removeLimits() external onlyOwner {
    _limitsInEffect = false;
    emit LimitsRemoved();
  }

  /// @notice Disable transfer delay.
  /// NOTE: Once disabled, can never be re-enabled.
  function disableTransferDelay() external onlyOwner {
    _transferDelayEnabled = false;
    emit TransferDelayDisabled();
  }

  /// Use to disable contract sales if absolutely necessary.
  /// For emergency use only.
  /// @param enabled Toggle enable/disable
  function updateSwapEnabled(bool enabled) external onlyOwner {
    _swapEnabled = enabled;
  }
  
  /// @notice Change the min contract token balance before swap is triggered
  /// @param amount New amount
  function updateSwapTokensThreshold(uint amount) external onlyOwner {

    // Swap amount cannot be lower than .001% of total supply
    require(amount >= totalSupply() / 100000, "swap amount < .001% of total supply");

    // Swap amount cannot be higher than 0.5% of total supply
    require(amount <= totalSupply() * 5 / 1000, "swap amount > 0.5% of total supply");

    // emit the event
    emit UpdateSwapTokensThreshold(amount);

    _swapTokensThreshold = amount;
  }

  /// @notice Change the max transaction amount
  /// @param amount New amount
  function updateMaxTxnAmount(uint amount) external onlyOwner {

    // Max transaction amount cannot be lower than 0.1% of total supply
    require(amount >= totalSupply() / 1000, "maxTxnAmount < 0.1% of total supply");

    _maxTxnAmount = amount;
  }

  /// @notice Change the maximum amount a single wallet can hold
  /// @param amount New amount
  function updateMaxWalletAmount(uint amount) external onlyOwner {

    // Max wallet amount cannot be lower than 0.5% of total supply
    require(amount >= totalSupply() * 5 / 1000, "maxWallet < 0.5%");

    _maxWallet = amount;
  }  

  /// @notice Update buy taxes
  /// @param buyMarketingFee_ Marketing fee, scaled by 100 (e.g. 3 = 3%)
  /// @param buyLiquidityFee_ Liquidity fee, scaled by 100 (e.g. 5 = 5%)
  /// @param buyDevFee_ Dev fee, scaled by 100 (e.g., 2 = 2%)
  function updateBuyFees(
                         uint buyMarketingFee_,
                         uint buyLiquidityFee_,
                         uint buyDevFee_
                         ) external onlyOwner {
    _buyMarketingFee = buyMarketingFee_;
    _buyLiquidityFee = buyLiquidityFee_;
    _buyDevFee = buyDevFee_;
    _buyTotalFees = _buyMarketingFee + _buyLiquidityFee + _buyDevFee;

    // Total buy fees must be lower than 20%
    require(_buyTotalFees <= 20, "total buy fees > 20%");

    // Emit the event
    emit UpdateBuyFees(_buyMarketingFee, _buyLiquidityFee, _buyDevFee);
  }

  /// @notice Update sell taxes
  /// @param sellMarketingFee_ Marketing fee, scaled by 100 (e.g. 3 = 3%)
  /// @param sellLiquidityFee_ Liquidity fee, scaled by 100 (e.g. 5 = 5%)
  /// @param sellDevFee_ Dev fee, scaled by 100 (e.g. 2 = 2%)
  function updateSellFees(
                          uint sellMarketingFee_,
                          uint sellLiquidityFee_,
                          uint sellDevFee_
                          ) external onlyOwner {
    _sellMarketingFee = sellMarketingFee_;
    _sellLiquidityFee = sellLiquidityFee_;
    _sellDevFee = sellDevFee_;
    _sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee;
    
    // Total sell fees must be lower than 25%
    require(_sellTotalFees <= 25, "total sell fees > 25%");

    // Emit the event
    emit UpdateSellFees(_sellMarketingFee, _sellLiquidityFee, _sellDevFee);
  }

  /// @notice Update marketing wallet address
  /// @param marketingWallet_ New marketing wallet address  
  function updateMarketingWallet(address marketingWallet_) external onlyOwner {

    // Emit the event
    emit UpdateMarketingWallet(marketingWallet_, _marketingWallet);

    // Update state
    _marketingWallet = marketingWallet_;
  }

  /// @notice Update dev wallet address
  /// @param devWallet_ New dev wallet address  
  function updateDevWallet(address devWallet_) external onlyOwner {

    // Emit the event
    emit UpdateDevWallet(devWallet_, _devWallet);

    // Update state
    _devWallet = devWallet_;
  }

  /// @notice Set the automated market maker pairs
  /// @param pair Address of the pair
  /// @param value Toggle enable/disable
  function setAMMPair(address pair, bool value) public onlyOwner {
    if(pair == _uniswapV2Pair) {
      require(value, "pair cannot be removed from _AMMPairs");
    }
    _AMMPairs[pair] = value;
    emit SetAMMPair(pair, value);
  }

  /// @notice Allow/disallow an account to be excluded from taxes
  /// @param account Address of account
  /// @param excluded Toggle enable/disable
  function excludeFromFees(address account, bool excluded) public onlyOwner {

    // Update state
    _isExcludedFromFees[account] = excluded;

    // Emit the event
    emit ExcludeFromFees(account, excluded);
  }

  /// @notice Allow/disallow an account to be excluded from max transaction amount
  /// @param account Address of account
  /// @param excluded Toggle enable/disable
  function excludeFromMaxTxn(address account, bool excluded) public onlyOwner {

    // Update state
    _isExcludedFromMaxTxn[account] = excluded;

    // Emit the event
    emit ExcludeFromMaxTxn(account, excluded); 
  }


  function setAutoLPBurnSettings(
                                 uint frequencyInSec,
                                 uint percent,
                                 bool enabled
                                 ) external onlyOwner {
    //TODO
  }

  function manualBurnTokensFromPool(uint basisPoints) external onlyOwner {

    require(
            block.timestamp > _lastManualLpBurnTime + _manualBurnFrequency,
            "must wait for burn cooldown"
            );

    require(basisPoints <= 1000, "may not nuke more than 10% of tokens in LP");

    _lastManualLpBurnTime = block.timestamp;

    // Get internal token balance of liquidity pool
    uint poolTokenBalance = this.balanceOf(_uniswapV2Pair);

    // Calculate amount to burn
    uint amountToBurn = poolTokenBalance * basisPoints / 10000;

    // Pull tokens from the liquidity pool and move to dead address permanently
    if(amountToBurn > 0){
      super._transfer(_uniswapV2Pair, address(0xdead), amountToBurn);
    }

    // Sync price since the liquidity pool's token balance has been altered
    // outside of a swap transaction
    IUniswapV2Pair pair = IUniswapV2Pair(_uniswapV2Pair);
    pair.sync();

    // Emit the event
    emit AutoNukeLP();
  }
  

  /** PRIVATE FUNCTIONS **/

  function _transfer(address from, address to, uint amount) internal override {

    require(from != address(0), "ERC20: transfer from the zero address");

    require(to != address(0), "ERC20: transfer from the zero address");

    if(amount == 0){
      super._transfer(from, to, 0);
      return;
    }

    if(_limitsInEffect){
      if(from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping){
        if(!_tradingEnabled) {
          // If trading not enabled, only whitelisted addresses may
          // send/receive transfer
          require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "trading not enabled");
        }
        
        if(_transferDelayEnabled) {
          // Only one transfer per block allowed when transfer delay is enabled
          if(to != owner() && to != address(_uniswapV2Router) && to != _uniswapV2Pair) {
            require(
                    _holderLastTransferTimestamp[tx.origin] < block.number,
                    "ERC20: transfer delay enabled. Only one purchase per block allowed"
                    );
            _holderLastTransferTimestamp[tx.origin] = block.number;
          }
        }

        if(_AMMPairs[from] && !_isExcludedFromMaxTxn[to]){
          // Check transaction and wallet amounts when user is buying from AMM
          require(amount <= _maxTxnAmount, "ERC20: buy transfer amount exceeds _maxTxnAmount");
          require(amount + balanceOf(to) <= _maxWallet, "ERC20: max wallet exceeded");
        } else if(_AMMPairs[to] && !_isExcludedFromMaxTxn[from]){
          // Check transaction amount when user is selling to AMM
          require(amount <= _maxTxnAmount, "ERC20: sell transfer amount exceeds _maxTxnAmount");
        } else if(!_isExcludedFromMaxTxn[to]){
          // General check: non whitelisted wallets should not be allowed to exceed
          // max wallet size
          require(amount + balanceOf(to) <= _maxWallet, "ERC20: max wallet exceeded");
        }
      }
    } // End of _limitsInEffect workflow

    // Trigger swap when internal token balance exceeds the threshold
    if(
       balanceOf(address(this)) >= _swapTokensThreshold &&
       _swapEnabled &&
       !_swapping &&
       !_AMMPairs[from] &&
       !_isExcludedFromFees[from] &&
       !_isExcludedFromFees[to]
       ) {
      _swapping = true;
      _triggerSwap();
      _swapping = false;
    }

    // Trigger burning tokens from liquidity as a function of time
    if(
       !_swapping &&
       _AMMPairs[to] &&
       _lpBurnEnabled &&
       block.timestamp >= _lastLpBurnTime + _lpBurnFrequency &&
       !_isExcludedFromFees[from]
       ) {
      _autoBurnTokensFromPool();
    }

    bool takeFee = !_swapping;

    // If any account belongs to `_isExcludedFromFees, then remove the fee
    if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
      takeFee = false;
    }

    // Only take fees on buys / sells. Do not take fees on wallet transfers
    if(takeFee){

      // Initialize fee amount
      uint fees = 0;
      
      if(_AMMPairs[to] && _sellTotalFees > 0) {

        // User selling tokens. Calculate the total sell fees to be taken
        fees = amount * _sellTotalFees / 100;
        
        // Distribute fees proportionally to liquidity/dev/marketing
        _tokensForLiquidity += (fees * _sellLiquidityFee) / _sellTotalFees;
        _tokensForDev += (fees * _sellDevFee) / _sellTotalFees;
        _tokensForMarketing += (fees * _sellMarketingFee) / _sellTotalFees;
      }else if(_AMMPairs[from] && _buyTotalFees > 0) {

        // User buying tokens. Calculate the total buy fees to be taken
        fees = amount * _buyTotalFees / 100;

        // Distribute fees proportionally to liquidity/dev/marketing
        _tokensForLiquidity += (fees * _buyLiquidityFee) / _buyTotalFees;
        _tokensForDev += (fees * _buyDevFee) / _buyTotalFees;
        _tokensForMarketing += (fees * _buyMarketingFee) / _buyTotalFees;
      }

      // Send fees back to the contract
      if(fees > 0){
        super._transfer(from, address(this), fees);
      }
      
      // Subtract the fees from the transfer amount
      amount -= fees;
    }

    // Complete the transfer as per usual
    super._transfer(from, to, amount);
  }
  
  /// @notice Once the internal balance of tokens reaches the threshold,
  /// trigger an automated swap of the balance to ETH and distribute according
  /// to tax schedule
  function _triggerSwap() private {

    // Get the current contract balance of tokens
    uint balanceToSwap = balanceOf(address(this));

    // Get the total balance of tokens accumulated from fees
    uint totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing + _tokensForDev;

    bool success;

    // Exit early in zero balance cases to prevent division by zero
    if(balanceToSwap == 0 || totalTokensToSwap == 0){
      return;
    }

    // Cap the balance to swap in a single transaction
    if(balanceToSwap > _swapTokensThreshold * 20){
      balanceToSwap = _swapTokensThreshold * 20;
    }

    // Half of the `_tokensForLiquidity` need to be reserved for the liquidity pool.
    // The rest of the `balanceToSwap` can be freely swapped to ETH.
    uint tokensForLP = (balanceToSwap * _tokensForLiquidity) / totalTokensToSwap / 2;
    uint amountToSwapForEth = balanceToSwap - tokensForLP;

    // Store the initial ETH balance
    uint initEthBalance = address(this).balance;

    // Swap the balance to ETH
    _swapTokensForEth(amountToSwapForEth);

    // Calculate how much ETH can freely be distributed to marketing/dev/liquidity
    uint ethForDistribution = address(this).balance - initEthBalance;
    uint ethForMarketing = ethForDistribution * _tokensForMarketing / totalTokensToSwap;
    uint ethForDev = ethForDistribution * _tokensForDev / totalTokensToSwap;
    uint ethForLP = ethForDistribution - ethForMarketing - ethForDev;

    // Zero out the token balance accumulated from fees
    _tokensForLiquidity = 0;
    _tokensForMarketing = 0;
    _tokensForDev = 0;

    // Send ETH to dev wallet
    (success, ) = address(_devWallet).call{value: ethForDev}("");

    // Send token / ETH to liquidity pool
    if(tokensForLP > 0 && ethForLP > 0) {
      _addLiquidity(tokensForLP, ethForLP);
      emit SwapAndLiquify(amountToSwapForEth, ethForLP, tokensForLP);
    }

    // Send ETH to marketing wallet
    (success, ) = address(_marketingWallet).call{value: address(this).balance}("");
    
  }

  /// @notice Swap token for ETH via Uniswap
  /// @param tokenAmount Amount of token to swap
  function _swapTokensForEth(uint tokenAmount) private {
    // Generate the uniswap pair path of token -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapV2Router.WETH();

    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    // Make the swap. Set `amountOutMin` to zero to avoid revert due to
    // unavoidable slippage
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                                                                        tokenAmount,
                                                                        0,
                                                                        path,
                                                                        address(this),
                                                                        block.timestamp
                                                                        );
  }

  /// @notice Add token and ETH into the liquidity pool. LP tokens are
  /// irrevocably locked forever and sent to dead address
  /// @param tokenAmount Amount of tokens to deposit into pool
  /// @param ethAmount Amount of ETH to deposit into pool
  function _addLiquidity(uint tokenAmount, uint ethAmount) private {

    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    // Add the liquidity. Set `amountTokenMin` and `amountETHMin` to
    // zero to avoid revert due to unavoidable slippage
    _uniswapV2Router.addLiquidityETH{value: ethAmount}(
                                                       address(this),
                                                       tokenAmount,
                                                       0,
                                                       0,
                                                       _deadAddress,
                                                       block.timestamp
                                                       );    
  }

  /// @notice Automatically burns tokens from the uniswap liquidity pool
  /// by force transferring them to the dead address
  function _autoBurnTokensFromPool() internal {

    // Store last LP burn time
    _lastLpBurnTime = block.timestamp;    

    // Get internal token balance of liquidity pool
    uint poolTokenBalance = this.balanceOf(_uniswapV2Pair);

    // Calculate amount to burn
    uint amountToBurn = poolTokenBalance * _percentForLPBurn / 10000;

    // Pull tokens from the liquidity pool and move to dead address permanently
    if(amountToBurn > 0){
      super._transfer(_uniswapV2Pair, address(0xdead), amountToBurn);
    }

    // Sync price since the liquidity pool's token balance has been altered
    // outside of a swap transaction
    IUniswapV2Pair pair = IUniswapV2Pair(_uniswapV2Pair);
    pair.sync();

    // Emit the event
    emit AutoNukeLP();    
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

pragma solidity ^0.8.9;

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

pragma solidity ^0.8.9;

import "./IUniswapV2Router01.sol";

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

pragma solidity ^0.8.9;

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