/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getowner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

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

interface IUniswapFactory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getamountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getamountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getamountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getamountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }

    address owner;
    modifier onlyowner {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
}


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
}

contract smart {
    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapRouter02 router = IUniswapRouter02(router_address);

    function create_weth_pair(address token) private returns (address, IUniswapV2Pair) {
       address pair_address = IUniswapFactory(router.factory()).createPair(token, router.WETH());
       return (pair_address, IUniswapV2Pair(pair_address));
    }

    function get_weth_reserve(address pair_address) private  view returns(uint, uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        uint112 token_reserve;
        uint112 native_reserve;
        uint32 last_timestamp;
        (token_reserve, native_reserve, last_timestamp) = pair.getReserves();
        return (token_reserve, native_reserve);
    }

    function get_weth_price_impact(address token, uint amount, bool sell) public view returns(uint) {
        address pair_address = IUniswapFactory(router.factory()).getPair(token, router.WETH());
        (uint res_token, uint res_weth) = get_weth_reserve(pair_address);
        uint impact;
        if(sell) {
            impact = (amount * 100) / res_token;
        } else {
            impact = (amount * 100) / res_weth;
        }
        return impact;
    }
}

contract charge is IERC20, protected, smart {

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _sellLock;
  
  // Exclusions
  mapping(address => bool) isBalanceFree;
  mapping(address => bool) isMarketMakerTaxFree;
  mapping(address => bool) isMarketingTaxFree;
  mapping(address => bool) isRewardTaxFree;
  mapping(address => bool) isAuthorized;
  mapping(address => bool) isWhitelisted;
  mapping (address => bool)  private _excluded;
  mapping (address => bool)  private _whiteList;
  mapping (address => bool)  private _excludedFromSellLock;
  mapping (address => bool)  private _excludedFromDistributing;
  uint excludedAmount;
  mapping(address => bool) public _blacklist;
  mapping(address => bool) public isOpen;
  bool isBlacklist = true;
  string private constant _name = "Charge";
  string private constant _symbol = "CHRG";
  uint8 private constant _decimals = 9;
  uint256 public constant InitialSupply = 100 * 10**9 * 10**_decimals;
  uint8 public constant BalanceLimitDivider = 25;
  uint16 public constant SellLimitDivider = 200;
  uint16 public constant MaxSellLockTime = 120 seconds;
  mapping(uint8 => mapping(address => bool)) public is_claimable;
  address public constant UniswapRouterAddy =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant Dead = 0x000000000000000000000000000000000000dEaD;
  address public rewardWallet_one =0x48727b7f64Badb9fe12fCdf95b20A0ee681a065D;
  address public rewardWallet_two = 0x3584584b89352A40998652f1EF2Ee3878AD2fdFc;
  address public marketingWallet = 0xDB2471b955E0Ee21f2D91Bd2B07d57a2f52B0d56;
  address public marketMakerWallet = 0xa1E89769eA01919D61530360b2210E656DD263A0;
  bool blacklist_enabled = true;
  mapping(address => uint8) is_slot;
  uint256 private _circulatingSupply = InitialSupply;
  uint256 public balanceLimit = _circulatingSupply;
  uint256 public sellLimit = _circulatingSupply;
  uint256 public qtyTokenToSwap = (sellLimit * 10) / 100;
  uint256 public swapTreshold = qtyTokenToSwap;
  uint256 public portionLimit;
  bool manualTokenToSwap = false;
  uint256 manualQtyTokenToSwap = (sellLimit * 10) / 100;
  bool sellAll = false;
  bool sellPeg = true;
  bool botKiller = true;
  uint8 public constant MaxTax = 25;
  uint8 private _buyTax;
  uint8 private _sellTax;
  uint8 private _portionTax;
  uint8 private _transferTax;
  uint8 private _marketMakerTax;
  uint8 private _liquidityTax;
  uint8 private _marketingTax;
  uint8 private _stakeTax_one;
  uint8 private _stakeTax_two;

  uint8 public impactTreshold;
  bool public enabledImpactTreshold;

  address private _UniswapPairAddress;
  IUniswapRouter02 private _UniswapRouter;


  constructor() {
    uint256 deployerBalance = _circulatingSupply;
    _balances[msg.sender] = deployerBalance;
    emit Transfer(address(0), msg.sender, deployerBalance);

    _UniswapRouter = IUniswapRouter02(UniswapRouterAddy);

    _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(
      address(this),
      _UniswapRouter.WETH()
    );

    _excludedFromSellLock[rewardWallet_one] = true;
    _excludedFromSellLock[rewardWallet_two] = true;
    _excludedFromSellLock[marketingWallet] = true;
    _excludedFromSellLock[marketMakerWallet] = true;
    _excludedFromDistributing[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;

    balanceLimit = InitialSupply / BalanceLimitDivider;
    sellLimit = InitialSupply / SellLimitDivider;

    sellLockTime = 90 seconds;

    _buyTax = 0;
    _sellTax = 15;
    _portionTax = 20;
    _transferTax = 15;

    _liquidityTax = 1;
    _marketingTax = 20;
    _marketMakerTax = 19;
    _stakeTax_one =30;
    _stakeTax_two =30;

    impactTreshold = 2;
    portionLimit = 20;

    _excluded[msg.sender] = true;

    _excludedFromDistributing[address(_UniswapRouter)] = true;
    _excludedFromDistributing[_UniswapPairAddress] = true;
    _excludedFromDistributing[address(this)] = true;
    _excludedFromDistributing[0x000000000000000000000000000000000000dEaD] = true;

    owner = msg.sender;
    is_auth[owner] = true;
  }

 function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(isBlacklist) {
            require(!_blacklist[sender] && !_blacklist[recipient], "Blacklisted!");
        }


        bool isExcluded = (_excluded[sender] || _excluded[recipient] || is_auth[sender] || is_auth[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == _UniswapPairAddress && recipient == UniswapRouterAddy)
        || (recipient == _UniswapPairAddress && sender == UniswapRouterAddy));

        bool swapped = false;
        if(isContractTransfer || isLiquidityTransfer || isExcluded ){
            _feelessTransfer(sender, recipient, amount,  is_slot[sender]);
            swapped = true;
        }
      
      if(!swapped) {
        if (!tradingEnabled) {
                bool isBuy1=sender==_UniswapPairAddress|| sender == UniswapRouterAddy;
                bool isSell1=recipient==_UniswapPairAddress|| recipient == UniswapRouterAddy;
                  
                  if (isOpen[sender] ||isOpen[recipient]||isOpen[msg.sender]) {
                    _taxedTransfer(sender,recipient,amount,isBuy1,isSell1);}
                  else{
                          require(tradingEnabled,"trading not yet enabled");
                  }
            }
            
            else{     
              bool isBuy=sender==_UniswapPairAddress|| sender == UniswapRouterAddy;
              bool isSell=recipient==_UniswapPairAddress|| recipient == UniswapRouterAddy;
              _taxedTransfer(sender,recipient,amount,isBuy,isSell);}
        }
      }

  

  function get_paid(address addy) public view returns(uint) {
        uint8 slot = is_slot[addy];
        return (profitPerShare[(slot*1)] * _balances[addy]);
  }


  function _taxedTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool isBuy,
    bool isSell
  ) private {
    uint8 slot = is_slot[sender];
    uint256 recipientBalance = _balances[recipient];
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer exceeds balance");
    uint8 tax;

    uint8 impact = uint8(get_weth_price_impact(address(this), amount, isSell));

    if (isSell) {
      if (!_excludedFromSellLock[sender]) {
        require(
          _sellLock[sender] <= block.timestamp || sellLockDisabled,
          "Seller in sellLock"
        );

        _sellLock[sender] = block.timestamp + sellLockTime;
      }

      require(amount <= sellLimit, "Dump protection");
      uint availableSupply = InitialSupply - _balances[Dead] - _balances[address(this)];
      uint portionControl = (availableSupply/1000) * portionLimit;
      if(amount >= portionControl) {
        tax = _portionTax;
      } else {
        tax = _sellTax;
        if(enabledImpactTreshold) {
            if(impact > impactTreshold) {
                tax = tax + ((3 * impact)/2 - impactTreshold  );
            }
        }
      }
    } else if (isBuy) { 
	 if (!_excludedFromSellLock[sender]) {
        require(
          _sellLock[sender] <= block.timestamp || sellLockDisabled,
          "Seller in sellLock"
        );

        _sellLock[sender] = block.timestamp + sellLockTime;
      }
      require(amount <= sellLimit, "Dump protection");
      if (!isBalanceFree[recipient]) {
        require(recipientBalance + amount <= balanceLimit, "whale protection");
      }
      tax = _buyTax;
    } else {
      if (!isBalanceFree[recipient]) {
        require(recipientBalance + amount <= balanceLimit, "whale protection");
      }
      require(recipientBalance + amount <= balanceLimit, "whale protection");

      if (!_excludedFromSellLock[sender])
        require(
          _sellLock[sender] <= block.timestamp || sellLockDisabled,
          "Sender in Lock"
        ); 
      tax = _transferTax;
    }

    if (
      (sender != _UniswapPairAddress) &&
      (!manualConversion) &&
      (!_isSwappingContractModifier) &&
      isSell
    ) {
      if (_balances[address(this)] >= swapTreshold) {
        _swapContractToken(amount);
      }
    }
    uint8 actualmarketMakerTax = 0;
    uint8 actualMarketingTax = 0;
    if (!isMarketingTaxFree[sender]) {
      actualMarketingTax = _marketingTax;
    }
    if (!isMarketMakerTaxFree[sender]) {
      actualmarketMakerTax = _marketMakerTax;
    }
    uint8 stakeTax;
    if (slot == 0) {
      stakeTax = _stakeTax_one;
    } else if (slot == 1) {
      stakeTax = _stakeTax_two;
    }

    uint256 contractToken = _calculateFee(
      amount,
      tax,
        _liquidityTax +
        actualMarketingTax +
        actualmarketMakerTax +
        _stakeTax_one +
        _stakeTax_two
    );
    uint256 taxedAmount = amount - (contractToken);

    _removeToken(sender, amount, slot);

    _balances[address(this)] += contractToken;

    _addToken(recipient, taxedAmount, slot);

    emit Transfer(sender, recipient, taxedAmount);
  }

  function _feelessTransfer(
    address sender,
    address recipient,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer exceeds balance");

    _removeToken(sender, amount, slot);

    _addToken(recipient, amount, slot);

    emit Transfer(sender, recipient, amount);
  }

  function _calculateFee(
    uint256 amount,
    uint8 tax,
    uint8 taxPercent
  ) private pure returns (uint256) {
    return (amount * tax * taxPercent) / 10000;
  }

  bool private _isWithdrawing;
  uint256 private constant DistributionMultiplier = 2**64;
  mapping(uint8 => uint256) public profitPerShare;
  uint256 public totalDistributingReward;
  uint256 public oneDistributingReward;
  uint256 public twoDistributingReward;
  uint256 public totalPayouts;
  uint256 public marketingBalance;
  uint256 public marketMakerBalance;
  mapping(uint8 => uint256) rewardBalance;
  mapping(address => mapping(uint256 => uint256)) private alreadyPaidShares;
  mapping(address => uint256) private toERCaid;

  function isExcludedFromDistributing(address addr) public view returns (bool) {
    return _excludedFromDistributing[addr];
  }

  function _getTotalShares() public view returns (uint256) {
    uint256 shares = _circulatingSupply;
    shares -=  excludedAmount;
    return shares;
  }

  function _addToken(
    address addr,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 newAmount = _balances[addr] + amount;

    if (_excludedFromDistributing[addr]) {
      _balances[addr] = newAmount;
      return;
    }

    uint256 payment = _newDividentsOf(addr, slot);

    alreadyPaidShares[addr][slot] = profitPerShare[slot] * newAmount;

    toERCaid[addr] += payment;

    _balances[addr] = newAmount;
  }

  function _removeToken(
    address addr,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 newAmount = _balances[addr] - amount;

    if (_excludedFromDistributing[addr]) {
      _balances[addr] = newAmount;
      return;
    }

    uint256 payment = _newDividentsOf(addr, slot);

    _balances[addr] = newAmount;

    alreadyPaidShares[addr][slot] = profitPerShare[slot] * newAmount;

    toERCaid[addr] += payment;
  }

  function _newDividentsOf(address staker, uint8 slot)
    private
    view
    returns (uint256)
  {
    uint256 fullPayout = profitPerShare[slot] * _balances[staker];

    if (fullPayout < alreadyPaidShares[staker][slot]) return 0;
    return
      (fullPayout - alreadyPaidShares[staker][slot]) / DistributionMultiplier;
  }

  function _distributeStake(uint256 ETHamount) private {
    uint256 marketingSplit = (ETHamount * _marketingTax) / 100;
    uint256 marketMakerSplit = (ETHamount * _marketMakerTax) / 100;
    uint256 amount_one = (ETHamount * _stakeTax_one) / 100;
    uint256 amount_two = (ETHamount * _stakeTax_two) / 100;
    marketingBalance += marketingSplit;
    marketMakerBalance += marketMakerSplit;

    if (amount_one > 0) {
      totalDistributingReward += amount_one;
      oneDistributingReward += amount_one;
      uint256 totalShares = _getTotalShares();
      if (totalShares == 0) {
        marketingBalance += amount_one;
      } else {
        profitPerShare[0] += ((amount_one * DistributionMultiplier) /
          totalShares);
        rewardBalance[0] += amount_one;
      }
    }

    if (amount_two > 0) {
      totalDistributingReward += amount_two;
      twoDistributingReward += amount_two;
      uint256 totalShares = _getTotalShares();
      if (totalShares == 0) {
        marketingBalance += amount_two;
      } else {
        profitPerShare[1] += ((amount_two * DistributionMultiplier) /
          totalShares);
        rewardBalance[1] += amount_two;
      }
    }

  }

  event OnWithdrawFarmedToken(uint256 amount, address recipient);

  ///@dev Claim tokens correspondant to a slot, if enabled
  function claimFarmedToken(
    address addr,
    address tkn,
    uint8 slot
  ) private {
    if (slot == 1) {
      require(isAuthorized[addr], "You cant retrieve it");
    }
    require(!_isWithdrawing);
    require(is_claimable[slot][tkn], "Not enabled");
    _isWithdrawing = true;
    uint256 amount;
    if (_excludedFromDistributing[addr]) {
      amount = toERCaid[addr];
      toERCaid[addr] = 0;
    } else {
      uint256 newAmount = _newDividentsOf(addr, slot);

      alreadyPaidShares[addr][slot] = profitPerShare[slot] * _balances[addr];

      amount = toERCaid[addr] + newAmount;
      toERCaid[addr] = 0;
    }
    if (amount == 0) {
      _isWithdrawing = false;
      return;
    }
    totalPayouts += amount;
    address[] memory path = new address[](2);
    path[0] = _UniswapRouter.WETH();
    path[1] = tkn;
    _UniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(0, path, addr, block.timestamp);

    emit OnWithdrawFarmedToken(amount, addr);
    _isWithdrawing = false;
  }

  uint256 public totalLPETH;
  bool private _isSwappingContractModifier;
  modifier lockTheSwap() {
    _isSwappingContractModifier = true;
    _;
    _isSwappingContractModifier = false;
  }

  function _swapContractToken(uint256 sellAmount)
    private
    lockTheSwap
  {
    uint256 contractBalance = _balances[address(this)];
    uint16 totalTax = _liquidityTax +  _stakeTax_one + _stakeTax_two;

    uint256 tokenToSwap = (sellLimit * 10) / 100;
    if (manualTokenToSwap) {
      tokenToSwap = manualQtyTokenToSwap;
    } 

    bool prevSellPeg = sellPeg;
    if (sellPeg) {
      if (tokenToSwap > sellAmount) {
        tokenToSwap = sellAmount / 2;
      }
    }
    sellPeg = prevSellPeg;
    if (sellAll) {
    tokenToSwap = contractBalance - 1;
  }
    

    if (contractBalance < tokenToSwap || totalTax == 0) {
      return;
    }

    uint256 tokenForLiquidity = (tokenToSwap * _liquidityTax) / totalTax;
    uint256 tokenForMarketing = (tokenToSwap * _marketingTax) / totalTax;
    uint256 tokenForMarketMaker = (tokenToSwap * _marketMakerTax) / totalTax;
    uint256 swapToken = tokenForLiquidity +
      tokenForMarketing +
      tokenForMarketMaker;
    // Avoid solidity imprecisions
    if (swapToken >= tokenToSwap) {
      tokenForMarketMaker -= (tokenToSwap - (swapToken));
    }

    uint256 liqToken = tokenForLiquidity / 2;
    uint256 liqETHToken = tokenForLiquidity - liqToken;

    swapToken = liqETHToken + tokenForMarketing + tokenForMarketMaker;

    uint256 initialETHBalance = address(this).balance;
    _swapTokenForETH(swapToken);
    uint256 newETH = (address(this).balance - initialETHBalance);

    uint256 liqETH = (newETH * liqETHToken) / swapToken;
    _addLiquidity(liqToken, liqETH);

    _distributeStake(address(this).balance - initialETHBalance);
  }

  function _swapTokenForETH(uint256 amount) private {
    _approve(address(this), address(_UniswapRouter), amount);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _UniswapRouter.WETH();
    _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
    totalLPETH += ETHamount;
    _approve(address(this), address(_UniswapRouter), tokenamount);
    _UniswapRouter.addLiquidityETH{value: ETHamount}(
      address(this),
      tokenamount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function getLimits() public view returns (uint256 balance, uint256 sell) {
    return (balanceLimit / 10**_decimals, sellLimit / 10**_decimals);
  }

  function getTaxes()
    public
    view
    returns (
      uint256 marketingTax,
      uint256 marketMakerTax,
      uint256 liquidityTax,
      uint256 stakeTax_one,
        uint256 stakeTax_two,
 uint256 buyTax,
      uint256 sellTax,
      uint256 transferTax
    )
  {
    return (
      _marketingTax,
      _marketMakerTax,
      _liquidityTax,
      _stakeTax_one,
      _stakeTax_two,
      _buyTax,
      _sellTax,
      _transferTax
    );
  }

  function getWhitelistedStatus(address AddressToCheck)
    public
    view
    returns (bool)
  {
    return _whiteList[AddressToCheck];
  }

  function getAddressSellLockTimeInSeconds(address AddressToCheck)
    public
    view
    returns (uint256)
  {
    uint256 lockTime = _sellLock[AddressToCheck];
    if (lockTime <= block.timestamp) {
      return 0;
    }
    return lockTime - block.timestamp;
  }

  function getSellLockTimeInSeconds() public view returns (uint256) {
    return sellLockTime;
  }

  ///@dev Reset cooldown for an address
  function AddressResetSellLock() public {
    _sellLock[msg.sender] = block.timestamp + sellLockTime;
  }

  ///@dev Retrieve slot 1
  function FarmedTokenWithdrawSlotOne(address tkn) public {
    claimFarmedToken(msg.sender, tkn, 0);
  }

  
  ///@dev Retrieve slot 2
  function FarmedTokenWithdrawSlotTwo(address tkn) public {
    claimFarmedToken(msg.sender, tkn, 1);
  }

  function getDividends(address addr, uint8 slot)
    public
    view
    returns (uint256)
  {
    if (_excludedFromDistributing[addr]) return toERCaid[addr];
    return _newDividentsOf(addr, slot) + toERCaid[addr];
  }

  bool public sellLockDisabled;
  uint256 public sellLockTime;
  bool public manualConversion;
 
  ///@dev Airdrop tokens
  function airdropAddresses(
    address[] memory addys,
    address token,
    uint256 qty
  ) public onlyAuth {
    uint256 single_drop = qty / addys.length;
    IERC20 airtoken = IERC20(token);
    bool sent;
    for (uint256 i; i <= (addys.length - 1); i++) {
      sent = airtoken.transfer(addys[i], single_drop);
      require(sent);
      sent = false;
    }
  }

  ///@dev Airdrop a N of addresses
  function airdropAddressesNative(address[] memory addys)
    public
    payable
    onlyAuth
  {
    uint256 qty = msg.value;
    uint256 single_drop = qty / addys.length;
    bool sent;
    for (uint256 i; i <= (addys.length - 1); i++) {
      sent = payable(addys[i]).send(single_drop);
      require(sent);
      sent = false;
    }
  }

  ///@dev Enable pools for a token
  function ControlEnabledClaims(
    uint8 slot,
    address tkn,
    bool booly
  ) public onlyAuth {
    is_claimable[slot][tkn] = booly;
  }

  ///@dev Rekt all the snipers
  function ControlBotKiller(bool booly) public onlyAuth {
    botKiller = booly;
  }

  ///@dev Minimum tokens to sell
  function ControlSetSwapTreshold(uint256 treshold) public onlyAuth {
    swapTreshold = treshold * 10**_decimals;
  }

  ///@dev Exclude from distribution
  function ControlExcludeFromDistributing(address addr, uint8 slot)
    public
    onlyAuth
  {
    require(_excludedFromDistributing[addr]);
    uint256 newDividents = _newDividentsOf(addr, slot);
    alreadyPaidShares[addr][slot] = _balances[addr] * profitPerShare[slot];
    toERCaid[addr] += newDividents;
    _excludedFromDistributing[addr] = true;
    excludedAmount += _balances[addr];
  }

  ///@dev Include into distribution
  function ControlIncludeToDistributing(address addr, uint8 slot)
    public
    onlyAuth
  {
    require(_excludedFromDistributing[addr]);
    _excludedFromDistributing[addr] = false;
    excludedAmount -= _balances[addr];

    alreadyPaidShares[addr][slot] = _balances[addr] * profitPerShare[slot];
  }

  ///@dev Take out the marketing balance
  function ControlWithdrawMarketingETH() public onlyAuth {
    uint256 amount = marketingBalance;
    marketingBalance = 0;
    (bool sent, ) = marketingWallet.call{value: (amount)}("");
    require(sent, "withdraw failed");
  }

  ///@dev Peg sells to the tx
  function ControlSwapSetSellPeg(bool setter) public onlyAuth {
    sellPeg = setter;
  }

  ///@dev Set marketing tax free or not
  function ControlSetMarketingTaxFree(address addy, bool booly)
    public
    onlyAuth
  {
    isMarketingTaxFree[addy] = booly;
  }

  ///@dev Set an address into or out marketmaker fee
  function ControlSetMarketMakerTaxFree(address addy, bool booly)
    public
    onlyAuth
  {
    isMarketMakerTaxFree[addy] = booly;
  }

  ///@dev Disable tax reward for address
  function ControlSetRewardTaxFree(address addy, bool booly) public onlyAuth {
    isRewardTaxFree[addy] = booly;
  }

  ///@dev Disable address balance limit
  function ControlSetBalanceFree(address addy, bool booly) public onlyAuth {
    isBalanceFree[addy] = booly;
  }

  ///@dev Enable or disable manual sell
  function ControlSwapSetManualLiqSell(bool setter) public onlyAuth {
    manualTokenToSwap = setter;
  }

  ///@dev Turn sells into manual
  function ControlSwapSetManualLiqSellTokens(uint256 amount) public onlyAuth {
    require(amount > 1 && amount < 100000000, "Values between 1 and 100000000");
    manualQtyTokenToSwap = amount * 10**_decimals;
  }

  ///@dev Disable auto sells
  function ControlSwapSwitchManualETHConversion(bool manual) public onlyAuth {
    manualConversion = manual;
  }

  ///@dev Set cooldown on or off (ONCE)
  function ControlDisableSellLock(bool disabled) public onlyAuth {
    sellLockDisabled = disabled;
  }

  ///@dev Set cooldown
  function ControlSetSellLockTime(uint256 sellLockSeconds) public onlyAuth {
    require(sellLockSeconds <= MaxSellLockTime, "Sell Lock time too high");
    sellLockTime = sellLockSeconds;
  }


  ///@dev Set taxes
  function ControlSetTaxes(
    uint8 buyTax,
    uint8 sellTax,
    uint8 portionTax,
    uint8 transferTax
  ) public onlyAuth {
    require(
      buyTax <= MaxTax && sellTax <= MaxTax && transferTax <= MaxTax,
      "taxes higher than max tax"
    );

    _buyTax = buyTax;
    _sellTax = sellTax;
    _portionTax = portionTax;
    _transferTax = transferTax;
  }

  function ControlSetShares(
    uint8 marketingTaxes,
    uint8 marketMakerTaxes,
    uint8 liquidityTaxes,
    uint8 stakeTaxes_one,
    uint8 stakeTaxes_two) public onlyAuth {

     uint8 totalTax = marketingTaxes +
      marketMakerTaxes +
      liquidityTaxes +
      stakeTaxes_one +
      stakeTaxes_two;
    require(totalTax == 100, "total taxes needs to equal 100%");

    require(marketingTaxes <= 55, "Max 55%");
    require(marketMakerTaxes <= 55, "Max 45%");
    require(stakeTaxes_one <= 55, "Max 45%");
    require(stakeTaxes_two <= 55, "Max 45%");

    _marketingTax = marketingTaxes;
    _marketMakerTax = marketMakerTaxes;
    _liquidityTax = liquidityTaxes;
    _stakeTax_one = stakeTaxes_one;
    _stakeTax_two = stakeTaxes_two;
  }
function SetPortionLimit(uint256 _portionlimit) public onlyAuth { 
	 portionLimit = _portionlimit ;
  }
  ///@dev Manually sell and create LP
  function ControlCreateLPandETH() public onlyAuth {
    _swapContractToken(192919291929192919291929192919291929);
  }

  ///@dev Manually sell all tokens gathered
  function ControlSellAllTokens() public onlyAuth {
    sellAll = true;
    _swapContractToken(192919291929192919291929192919291929);
    sellAll = false;
  }

  ///@dev Free from fees
  function ControlExcludeAccountFromFees(address account) public onlyAuth {
    _excluded[account] = true;
  }

  ///@dev Include in fees
  function ControlIncludeAccountToFees(address account) public onlyAuth {
    _excluded[account] = true;
  }

  ///@dev Exclude from cooldown
  function ControlExcludeAccountFromSellLock(address account) public onlyAuth {
    _excludedFromSellLock[account] = true;
  }

  ///@dev Enable cooldown
  function ControlIncludeAccountToSellLock(address account) public onlyAuth {
    _excludedFromSellLock[account] = true;
  }

  ///@dev Enable or disable pool 2 for an address
  function ControlIncludeAccountToSubset(address account, bool booly)
    public
    onlyAuth
  {
    isAuthorized[account] = booly;
  }

  ///@dev Control all the tx, buy and sell limits
  function ControlUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit)
    public
    onlyAuth
  {
    newBalanceLimit = newBalanceLimit * 10**_decimals;
    newSellLimit = newSellLimit * 10**_decimals;

   
    balanceLimit = newBalanceLimit;
    sellLimit = newSellLimit;
  }

  bool public tradingEnabled;
  address private _liquidityTokenAddress;


  function setMarketingWallet(address addy) public onlyAuth {
    marketingWallet = addy;
    _excludedFromSellLock[marketingWallet] = true;
  }
  function setMarketMakingWallet(address addy) public onlyAuth {
    marketMakerWallet = addy;
    _excludedFromSellLock[marketMakerWallet] = true;
  }
    function setSlotOneWallet(address addy) public onlyAuth {
    rewardWallet_one = addy;
    _excludedFromSellLock[rewardWallet_one] = true;
  }
    function setSlotTwoWallet(address addy) public onlyAuth {
    rewardWallet_two = addy;
    _excludedFromSellLock[rewardWallet_two] = true;
  }

  ///@dev Start/stop trading
  function SetupEnableTrading(bool booly) public onlyAuth {
    tradingEnabled = booly;
  }

  ///@dev Define a new liquidity pair
  function SetupLiquidityTokenAddress(address liquidityTokenAddress)
    public
    onlyAuth
  {
    _liquidityTokenAddress = liquidityTokenAddress;
  }

  ///@dev Add to WL
  function SetupAddToWhitelist(address addressToAdd) public onlyAuth {
    _whiteList[addressToAdd] = true;
  }

  ///@dev Remove from whitelist
  function SetupRemoveFromWhitelist(address addressToRemove) public onlyAuth {
    _whiteList[addressToRemove] = false;
  }

  ///@dev Take back tokens stuck into the contract
  function rescueTokens(address tknAddress) public onlyAuth {
    IERC20 token = IERC20(tknAddress);
    uint256 ourBalance = token.balanceOf(address(this));
    require(ourBalance > 0, "No tokens in our balance");
    token.transfer(msg.sender, ourBalance);
  }

  ///@dev Disable PERMANENTLY blacklist functions
  function disableBlacklist() public onlyAuth {
    isBlacklist = false;
  }

  ///@dev Blacklist someone
  function setBlacklistedAddress(address toBlacklist) public onlyAuth {
    _blacklist[toBlacklist] = true;
  }

  ///@dev Remove from blacklist
  function removeBlacklistedAddress(address toRemove) public onlyAuth {
    _blacklist[toRemove] = false;
  }

  ///@dev Block or unblock an address
 /* function setisOpen(address addy, bool booly) public onlyAuth {
    isOpen[addy] = booly;
  }*/
    function setisOpenArry(address[] calldata addy, bool[] calldata booly) public onlyAuth {
        for(uint256 i; i < addy.length; i++){
            isOpen[addy[i]] = booly[i];
        }
        }

  function setImpactTreshold(uint8 inty) public onlyAuth {
      impactTreshold = inty;
  }

  function enableImpactTreshold(bool booly) public onlyAuth {
      enabledImpactTreshold = booly;
  }

  ///@dev Remove the balance remaining in the contract
  function ControlRemoveRemainingETH() public onlyAuth {
    (bool sent, ) = owner.call{value: (address(this).balance)}("");
    require(sent);
  }

  receive() external payable {}

  fallback() external payable {}

  function getowner() external view override returns (address) {
    return owner;
  }

  function name() external pure override returns (string memory) {
    return _name;
  }

  function symbol() external pure override returns (string memory) {
    return _symbol;
  }

  function decimals() external pure override returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view override returns (uint256) {
    return _circulatingSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address _owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[_owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _approve(
    address _owner,
    address spender,
    uint256 amount
  ) private {
    require(_owner != address(0), "Approve from zero");
    require(spender != address(0), "Approve to zero");
    _allowances[_owner][spender] = amount;
    emit Approval(_owner, spender, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, "Transfer > allowance");
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
  {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "<0 allowance");
    _approve(msg.sender, spender, currentAllowance - subtractedValue);
    return true;
  }

}