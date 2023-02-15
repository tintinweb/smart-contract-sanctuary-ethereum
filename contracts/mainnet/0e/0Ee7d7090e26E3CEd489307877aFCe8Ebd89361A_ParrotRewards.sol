// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './FeeProcessor.sol';
import './ParrotRewards.sol';

contract Parrot is ERC20, Ownable {
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address private constant DEX_ROUTER =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  uint256 public buyDevelopmentFee = 20; // 2%
  uint256 public buyTreasuryFee = 20; // 2%
  uint256 public buyLiquidityFee = 20; // 2%
  uint256 public buyTotalFees =
    buyDevelopmentFee + buyTreasuryFee + buyLiquidityFee;

  uint256 public sellDevelopmentFee = 20; // 2%
  uint256 public sellTreasuryFee = 20; // 2%
  uint256 public sellLiquidityFee = 20; // 2%
  uint256 public sellTotalFees =
    sellDevelopmentFee + sellTreasuryFee + sellLiquidityFee;

  uint256 public tokensForDevelopment;
  uint256 public tokensForTreasury;
  uint256 public tokensForLiquidity;

  FeeProcessor private _feeProcessor;
  ParrotRewards private _rewards;
  mapping(address => bool) private _isTaxExcluded;
  bool private _taxesOff;

  uint256 public maxTxnAmount;
  mapping(address => bool) public isExcludedMaxTxnAmount;
  uint256 public maxWallet;
  mapping(address => bool) public isExcludedMaxWallet;

  uint256 public liquifyRate = 5; // 0.5% of LP balance

  address public USDC;
  address public uniswapV2Pair;
  IUniswapV2Router02 public uniswapV2Router;
  mapping(address => bool) public marketMakingPairs;

  mapping(address => bool) private _isBlacklisted;

  bool private _swapEnabled = true;
  bool private _swapping = false;
  modifier lockSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor(address _usdc) ERC20('Parrot', 'PRT') {
    _mint(msg.sender, 1_000_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(DEX_ROUTER);
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _usdc);
    USDC = _usdc;
    marketMakingPairs[_uniswapV2Pair] = true;
    uniswapV2Pair = _uniswapV2Pair;
    uniswapV2Router = _uniswapV2Router;

    maxTxnAmount = (totalSupply() * 1) / 100; // 1% supply
    maxWallet = (totalSupply() * 1) / 100; // 1% supply

    _feeProcessor = new FeeProcessor(address(this), USDC, DEX_ROUTER);
    _feeProcessor.transferOwnership(msg.sender);
    _rewards = new ParrotRewards(address(this));
    _rewards.setUSDCAddress(USDC);
    _rewards.transferOwnership(msg.sender);
    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[address(_feeProcessor)] = true;
    _isTaxExcluded[msg.sender] = true;
    isExcludedMaxTxnAmount[address(this)] = true;
    isExcludedMaxTxnAmount[address(_feeProcessor)] = true;
    isExcludedMaxTxnAmount[msg.sender] = true;
    isExcludedMaxWallet[address(this)] = true;
    isExcludedMaxWallet[address(_feeProcessor)] = true;
    isExcludedMaxWallet[address(_rewards)] = true;
    isExcludedMaxWallet[msg.sender] = true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isBuy = marketMakingPairs[sender] &&
      recipient != address(uniswapV2Router);
    bool _isSell = marketMakingPairs[recipient];
    bool _isSwap = _isBuy || _isSell;
    address _marketMakingPair;

    if (!_isBuy) {
      require(!_isBlacklisted[recipient], 'blacklisted wallet');
      require(!_isBlacklisted[sender], 'blacklisted wallet');
      require(!_isBlacklisted[_msgSender()], 'blacklisted wallet');
    }

    if (_isSwap) {
      if (_isBuy) {
        // buy
        _marketMakingPair = sender;

        if (!isExcludedMaxTxnAmount[recipient]) {
          require(
            amount <= maxTxnAmount,
            'cannot swap more than max transaction amount'
          );
        }
      } else {
        // sell
        _marketMakingPair = recipient;

        if (!isExcludedMaxTxnAmount[sender]) {
          require(
            amount <= maxTxnAmount,
            'cannot swap more than max transaction amount'
          );
        }
      }
    }

    // enforce on buys and wallet/wallet transfers only
    if (!_isSell && !isExcludedMaxWallet[recipient]) {
      require(
        amount + balanceOf(recipient) <= maxWallet,
        'max wallet exceeded'
      );
    }

    uint256 _minSwap = totalSupply();
    if (_marketMakingPair != address(0)) {
      _minSwap =
        (balanceOf(_marketMakingPair) * liquifyRate) /
        PERCENT_DENOMENATOR;
      _minSwap = _minSwap == 0 ? totalSupply() : _minSwap;
    }
    bool _overMin = tokensForDevelopment +
      tokensForTreasury +
      tokensForLiquidity >=
      _minSwap;
    if (_swapEnabled && !_swapping && _overMin && sender != _marketMakingPair) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      _isSwap &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      if (_isBuy) {
        tax = (amount * buyTotalFees) / PERCENT_DENOMENATOR;
        tokensForDevelopment += (tax * buyDevelopmentFee) / buyTotalFees;
        tokensForTreasury += (tax * buyTreasuryFee) / buyTotalFees;
        tokensForLiquidity += (tax * buyLiquidityFee) / buyTotalFees;
      } else {
        // sell
        tax = (amount * sellTotalFees) / PERCENT_DENOMENATOR;
        tokensForDevelopment += (tax * sellDevelopmentFee) / sellTotalFees;
        tokensForTreasury += (tax * sellTreasuryFee) / sellTotalFees;
        tokensForLiquidity += (tax * sellLiquidityFee) / sellTotalFees;
      }
      if (tax > 0) {
        super._transfer(sender, address(this), tax);
      }

      _trueUpTaxTokens();
    }

    super._transfer(sender, recipient, amount - tax);
  }

  function _swap(uint256 _amountToSwap) private lockSwap {
    uint256 _tokensForDevelopment = tokensForDevelopment;
    uint256 _tokensForTreasury = tokensForTreasury;
    uint256 _tokensForLiquidity = tokensForLiquidity;

    // the max amount we want to swap is _amountToSwap, so make sure if
    // the amount of tokens that are available to swap is more than that,
    // that we adjust the tokens to swap to be max that amount.
    if (
      _tokensForDevelopment + _tokensForTreasury + _tokensForLiquidity >
      _amountToSwap
    ) {
      _tokensForLiquidity = _tokensForLiquidity > _amountToSwap
        ? _amountToSwap
        : _tokensForLiquidity;
      uint256 _remaining = _amountToSwap - _tokensForLiquidity;
      _tokensForTreasury =
        (_remaining * buyTreasuryFee) /
        (buyTreasuryFee + buyDevelopmentFee);
      _tokensForDevelopment = _remaining - _tokensForTreasury;
    }

    uint256 _liquidityTokens = _tokensForLiquidity / 2;
    uint256 _finalAmountToSwap = _tokensForDevelopment +
      _tokensForTreasury +
      _liquidityTokens;

    // generate the uniswap pair path of token -> USDC
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = USDC;

    _approve(address(this), address(uniswapV2Router), _finalAmountToSwap);
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _finalAmountToSwap,
      0,
      path,
      address(_feeProcessor),
      block.timestamp
    );
    if (_liquidityTokens > 0) {
      super._transfer(address(this), address(_feeProcessor), _liquidityTokens);
    }
    _feeProcessor.processAndDistribute(
      _tokensForDevelopment,
      _tokensForTreasury,
      _liquidityTokens
    );

    tokensForDevelopment -= _tokensForDevelopment;
    tokensForTreasury -= _tokensForTreasury;
    tokensForLiquidity -= _tokensForLiquidity;
  }

  function _trueUpTaxTokens() internal {
    uint256 _latestBalance = balanceOf(address(this));
    uint256 _latestDesiredBal = tokensForDevelopment +
      tokensForTreasury +
      tokensForLiquidity;
    if (_latestDesiredBal != _latestBalance) {
      if (_latestDesiredBal > _latestBalance) {
        bool _areExcessMoreThanBal = tokensForDevelopment + tokensForTreasury >
          _latestBalance;
        tokensForTreasury = _areExcessMoreThanBal ? 0 : tokensForTreasury;
        tokensForDevelopment = _areExcessMoreThanBal ? 0 : tokensForDevelopment;
      }
      tokensForLiquidity =
        _latestBalance -
        tokensForTreasury -
        tokensForDevelopment;
    }
  }

  function feeProcessor() external view returns (address) {
    return address(_feeProcessor);
  }

  function rewardsContract() external view returns (address) {
    return address(_rewards);
  }

  function isBlacklisted(address wallet) external view returns (bool) {
    return _isBlacklisted[wallet];
  }

  function blacklistWallet(address wallet) external onlyOwner {
    require(
      wallet != address(uniswapV2Router),
      'cannot not blacklist dex router'
    );
    require(!_isBlacklisted[wallet], 'wallet is already blacklisted');
    _isBlacklisted[wallet] = true;
  }

  function forgiveBlacklistedWallet(address wallet) external onlyOwner {
    require(_isBlacklisted[wallet], 'wallet is not blacklisted');
    _isBlacklisted[wallet] = false;
  }

  function setBuyTaxes(
    uint256 _developmentFee,
    uint256 _treasuryFee,
    uint256 _liquidityFee
  ) external onlyOwner {
    buyDevelopmentFee = _developmentFee;
    buyTreasuryFee = _treasuryFee;
    buyLiquidityFee = _liquidityFee;
    buyTotalFees = buyDevelopmentFee + buyTreasuryFee + buyLiquidityFee;
    require(
      buyTotalFees <= (PERCENT_DENOMENATOR * 15) / 100,
      'tax cannot be more than 15%'
    );
  }

  function setSellTaxes(
    uint256 _developmentFee,
    uint256 _treasuryFee,
    uint256 _liquidityFee
  ) external onlyOwner {
    sellDevelopmentFee = _developmentFee;
    sellTreasuryFee = _treasuryFee;
    sellLiquidityFee = _liquidityFee;
    sellTotalFees = sellDevelopmentFee + sellTreasuryFee + sellLiquidityFee;
    require(
      sellTotalFees <= (PERCENT_DENOMENATOR * 15) / 100,
      'tax cannot be more than 15%'
    );
  }

  function setMarketMakingPair(address _addy, bool _isPair) external onlyOwner {
    marketMakingPairs[_addy] = _isPair;
  }

  function setMaxTxnAmount(uint256 _numTokens) external onlyOwner {
    require(
      _numTokens >= (totalSupply() * 1) / 1000,
      'must be more than 0.1% supply'
    );
    maxTxnAmount = _numTokens;
  }

  function setMaxWallet(uint256 _numTokens) external onlyOwner {
    require(
      _numTokens >= (totalSupply() * 5) / 1000,
      'must be more than 0.5% supply'
    );
    maxWallet = _numTokens;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'must be less than 10%');
    liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setIsExcludeFromMaxTxnAmount(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isExcludedMaxTxnAmount[_wallet] = _isExcluded;
  }

  function setIsExcludeFromMaxWallet(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isExcludedMaxWallet[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    require(_tokenAddy != address(this), 'cannot withdraw this token');
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IParrotRewards.sol";

contract ParrotRewards is IParrotRewards, Ownable {
    event DistributeReward(address indexed wallet, address receiver);
    event DepositRewards(address indexed wallet, uint256 amountETH);

    IERC20 public usdc;

    address public immutable shareholderToken;
    uint256 public totalLockedUsers;
    uint256 public totalSharesDeposited;
    uint256 public totalRewards;
    uint256 public totalDistributed;

    uint160[] private shareHolders;

    mapping(address => uint256) private shares;
    mapping(address => uint256) private unclaimedRewards;
    mapping(address => uint256) private claimedRewards;

    uint256 private constant ACC_FACTOR = 10 ** 36;

    constructor(address _shareholderToken) {
        shareholderToken = _shareholderToken;
    }

    function deposit(uint256 _amount) external {
        IERC20 tokenContract = IERC20(shareholderToken);
        tokenContract.transferFrom(msg.sender, address(this), _amount);
        _addShares(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        address shareholder = msg.sender;
        _removeShares(shareholder, _amount);
        IERC20(shareholderToken).transfer(shareholder, _amount);
    }

    function _addShares(address shareholder, uint256 amount) internal {
        uint256 sharesBefore = shares[shareholder];
        totalSharesDeposited += amount;
        shares[shareholder] += amount;
        if (sharesBefore == 0 && shares[shareholder] > 0) {
            shareHolders.push(uint160(shareholder));
            totalLockedUsers++;
        }
    }

    function _removeShares(address shareholder, uint256 amount) internal {
        require(
            shares[shareholder] > 0 && amount <= shares[shareholder],
            "only withdraw what you deposited"
        );
        _distributeReward(shareholder);

        totalSharesDeposited -= amount;
        shares[shareholder] -= amount;
        if (shares[shareholder] == 0) {
            if (shareHolders.length > 1) {
                for (uint256 i = 0; i < shareHolders.length; ) {
                    if (shareHolders[i] == uint160(shareholder)) {
                        shareHolders[i] = shareHolders[shareHolders.length - 1];
                        delete shareHolders[shareHolders.length - 1];
                    }
                    unchecked {
                        ++i;
                    }
                }
            } else {
                delete shareHolders[0];
            }
            totalLockedUsers--;
        }
    }

    function depositRewards(uint256 _amount) external {
        require(totalSharesDeposited > 0, "no reward recipients");
        usdc.transferFrom(msg.sender, address(this), _amount);

        uint256 shareAmount = (ACC_FACTOR * _amount) / totalSharesDeposited;
        for (uint256 i = 0; i < shareHolders.length; ) {
            uint256 userCut = shareAmount * shares[address(shareHolders[i])];
            // Calculate the USDC equivalent of the share amount
            uint256 usdcAmount = userCut / ACC_FACTOR;
            unclaimedRewards[address(shareHolders[i])] += usdcAmount;
            unchecked {
                ++i;
            }
        }

        totalRewards += _amount;
        emit DepositRewards(msg.sender, _amount);
    }

    function _distributeReward(address shareholder) internal {
        require(shares[shareholder] > 0, "no shares owned");

        uint256 amount = getUnpaid(shareholder);
        if (amount > 0) {
            claimedRewards[shareholder] += amount;
            totalDistributed += amount;
            unclaimedRewards[shareholder] = 0;

            usdc.transfer(shareholder, amount);
            emit DistributeReward(shareholder, shareholder);
        }
    }

    function claimReward() external {
        _distributeReward(msg.sender);
    }

    function setUSDCAddress(address _usdc) external onlyOwner {
        usdc = IERC20(_usdc);
    }

    function getUnpaid(address shareholder) public view returns (uint256) {
        return unclaimedRewards[shareholder];
    }

    function getClaimed(address shareholder) public view returns (uint256) {
        return claimedRewards[shareholder];
    }

    function getShares(address user) external view returns (uint256) {
        return shares[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FeeProcessor is Ownable {
  address public developmentWallet;
  address public treasuryWallet;
  address public liquidityWallet;

  address public PRT;
  address public USDC;
  IUniswapV2Router02 public uniswapV2Router;

  modifier onlyPrt() {
    require(msg.sender == PRT, 'only PRT contract can call');
    _;
  }

  constructor(
    address _prt,
    address _usdc,
    address _dexRouter
  ) {
    PRT = _prt;
    USDC = _usdc;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_dexRouter);
    uniswapV2Router = _uniswapV2Router;
  }

  function processAndDistribute(
    uint256 _tokensForDevelopment,
    uint256 _tokensForTreasury,
    uint256 _liquidityPRT
  ) external onlyPrt {
    uint256 _finalSwapAmount = _tokensForDevelopment +
      _tokensForTreasury +
      _liquidityPRT;
    uint256 _usdcBalToProcess = IERC20(USDC).balanceOf(address(this));
    if (_usdcBalToProcess > 0) {
      uint256 _treasuryUSDC = (_usdcBalToProcess * _tokensForTreasury) /
        _finalSwapAmount;
      uint256 _developmentUSDC = (_usdcBalToProcess * _tokensForDevelopment) /
        _finalSwapAmount;
      uint256 _liquidityUSDC = _usdcBalToProcess -
        _treasuryUSDC -
        _developmentUSDC;
      _processFees(
        _developmentUSDC,
        _treasuryUSDC,
        _liquidityUSDC,
        _liquidityPRT
      );
    }
  }

  function _processFees(
    uint256 _developmentUSDC,
    uint256 _treasuryUSDC,
    uint256 _liquidityUSDC,
    uint256 _liquidityPRT
  ) internal {
    IERC20 _usdc = IERC20(USDC);
    if (_developmentUSDC > 0) {
      address _developmentWallet = developmentWallet == address(0)
        ? owner()
        : developmentWallet;
      _usdc.transfer(_developmentWallet, _developmentUSDC);
    }

    if (_treasuryUSDC > 0) {
      address _treasuryWallet = treasuryWallet == address(0)
        ? owner()
        : treasuryWallet;
      _usdc.transfer(_treasuryWallet, _treasuryUSDC);
    }

    if (_liquidityUSDC > 0 && _liquidityPRT > 0) {
      _addLp(_liquidityPRT, _liquidityUSDC);
    }
  }

  function _addLp(uint256 prtAmount, uint256 usdcAmount) internal {
    address _liquidityWallet = liquidityWallet == address(0)
      ? owner()
      : liquidityWallet;
    IERC20 _prt = IERC20(PRT);
    IERC20 _usdc = IERC20(USDC);

    _prt.approve(address(uniswapV2Router), prtAmount);
    _usdc.approve(address(uniswapV2Router), usdcAmount);
    uniswapV2Router.addLiquidity(
      USDC,
      PRT,
      usdcAmount,
      prtAmount,
      0,
      0,
      _liquidityWallet,
      block.timestamp
    );
    uint256 _contUSDCBal = _usdc.balanceOf(address(this));
    if (_contUSDCBal > 0) {
      _usdc.transfer(_liquidityWallet, _contUSDCBal);
    }
    uint256 _contPRTBal = _prt.balanceOf(address(this));
    if (_contPRTBal > 0) {
      _prt.transfer(_liquidityWallet, _contPRTBal);
    }
  }

  function setDevelopmentWallet(address _wallet) external onlyOwner {
    developmentWallet = _wallet;
  }

  function setTreasuryWallet(address _wallet) external onlyOwner {
    treasuryWallet = _wallet;
  }

  function setLiquidityWallet(address _wallet) external onlyOwner {
    liquidityWallet = _wallet;
  }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
pragma solidity ^0.8.9;

interface IParrotRewards {
  function claimReward() external;

  function depositRewards(uint256 _amount) external;

  function getShares(address wallet) external view returns (uint256);

  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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