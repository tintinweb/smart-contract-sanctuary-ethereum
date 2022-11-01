// SPDX-License-Identifier: MIT         

/*
'########::::'###::::'########:::'#######::'########::
... ##..::::'## ##::: ##.... ##:'##.... ##:... ##..:::
::: ##:::::'##:. ##:: ##:::: ##: ##:::: ##:::: ##:::::
::: ##::::'##:::. ##: ########:: ##:::: ##:::: ##:::::
::: ##:::: #########: ##.. ##::: ##:::: ##:::: ##:::::
::: ##:::: ##.... ##: ##::. ##:: ##:::: ##:::: ##:::::
::: ##:::: ##:::: ##: ##:::. ##:. #######::::: ##:::::
:::..:::::..:::::..::..:::::..:::.......::::::..::::::
*/

/* 
 𖤐 Tarot ETH ($TAROTETH)
 𖤐 Fortune Awaits 
 🂠 https://taroteth.com/
*/

pragma solidity 0.8.14;

abstract contract Context {
      function _msgSender() internal view virtual returns (address) {
            return msg.sender;
      }

      function _msgData() internal view virtual returns (bytes calldata) {
            this;
            return msg.data;
      }
}

interface IUniswapV2Factory {
      function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {

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

interface IERC20Metadata is IERC20 {

      function name() external view returns (string memory);


      function symbol() external view returns (string memory);


      function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
      mapping(address => uint256) private _balances;

      mapping(address => mapping(address => uint256)) private _allowances;

      uint256 private _totalSupply;

      string private _name;
      string private _symbol;

      constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
      }

      function name() public view virtual override returns (string memory) {
            return _name;
      }

      function symbol() public view virtual override returns (string memory) {
            return _symbol;
      }

      function decimals() public view virtual override returns (uint8) {
            return 18;
      }

      function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
      }

      function balanceOf(address account) public view virtual override returns (uint256) {
            return _balances[account];
      }

      function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
      }

      function allowance(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
      }

      function approve(address spender, uint256 amount) public virtual override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
      }

      function transferFrom(
            address sender,
            address recipient,
            uint256 amount
      ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                  _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
      }

      function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
            return true;
      }

      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            uint256 currentAllowance = _allowances[_msgSender()][spender];
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                  _approve(_msgSender(), spender, currentAllowance - subtractedValue);
            }

            return true;
      }

      function _transfer(
            address sender,
            address recipient,
            uint256 amount
      ) internal virtual {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                  _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
      }

      function _createInitialSupply(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
      }

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
}

interface DividendPayingTokenOptionalInterface {

  function withdrawableDividendOf(address _owner, address _rewardToken) external view returns(uint256);


  function withdrawnDividendOf(address _owner, address _rewardToken) external view returns(uint256);


  function accumulativeDividendOf(address _owner, address _rewardToken) external view returns(uint256);
}

interface DividendPayingTokenInterface {

  function dividendOf(address _owner, address _rewardToken) external view returns(uint256);


  function distributeDividends() external payable;


  function withdrawDividend(address _rewardToken) external;


  event DividendsDistributed(
      address indexed from,
      uint256 weiAmount
  );


  event DividendWithdrawn(
      address indexed to,
      uint256 weiAmount
  );
}

library SafeMath {

      function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
      }


      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
      }


      function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
      }


      function mul(uint256 a, uint256 b) internal pure returns (uint256) {

            if (a == 0) {
                  return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
      }


      function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
      }


      function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;

            return c;
      }


      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
      }


      function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
      }
}

contract Ownable is Context {
      address private _owner;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
      

      constructor () {
            address msgSender = _msgSender();
            _owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
      }


      function owner() public view returns (address) {
            return _owner;
      }


      modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
            _;
      }


      function renounceOwnership() public virtual onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
      }


      function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
      }
}



library SafeMathInt {
      int256 private constant MIN_INT256 = int256(1) << 255;
      int256 private constant MAX_INT256 = ~(int256(1) << 255);


      function mul(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a * b;

            require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
            require((b == 0) || (c / b == a));
            return c;
      }


      function div(int256 a, int256 b) internal pure returns (int256) {
            require(b != -1 || a != MIN_INT256);

            return a / b;
      }


      function sub(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a - b;
            require((b >= 0 && c <= a) || (b < 0 && c > a));
            return c;
      }


      function add(int256 a, int256 b) internal pure returns (int256) {
            int256 c = a + b;
            require((b >= 0 && c >= a) || (b < 0 && c < a));
            return c;
      }


      function abs(int256 a) internal pure returns (int256) {
            require(a != MIN_INT256);
            return a < 0 ? -a : a;
      }


      function toUint256Safe(int256 a) internal pure returns (uint256) {
            require(a >= 0);
            return uint256(a);
      }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
      int256 b = int256(a);
      require(b >= 0);
      return b;
  }
}


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

contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  mapping(address => uint256) internal magnifiedDividendPerShare;
  address[] public rewardTokens;
  address public nextRewardToken;
  uint256 public rewardTokenCounter;
  
  IUniswapV2Router02 public immutable uniswapV2Router;
  
  mapping(address => mapping(address => int256)) internal magnifiedDividendCorrections;
  mapping(address => mapping(address => uint256)) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  mapping(address => uint256) public totalDividendsDistributed;
  
  constructor(){
        // Uni v2 router 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Router = _uniswapV2Router; 
        
        // wBTC - 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        rewardTokens.push(address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)); 
        
        nextRewardToken = rewardTokens[0];
  }

      receive() external payable {
      distributeDividends();
  }

      
  function distributeDividends() public override payable { 
      require(totalBalance > 0);
      uint256 initialBalance = IERC20(nextRewardToken).balanceOf(address(this));
      buyTokens(msg.value, nextRewardToken);
      uint256 newBalance = IERC20(nextRewardToken).balanceOf(address(this)).sub(initialBalance);
      if (newBalance > 0) {
        magnifiedDividendPerShare[nextRewardToken] = magnifiedDividendPerShare[nextRewardToken].add(
            (newBalance).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, newBalance);

        totalDividendsDistributed[nextRewardToken] = totalDividendsDistributed[nextRewardToken].add(newBalance);
      }
      rewardTokenCounter = rewardTokenCounter == rewardTokens.length - 1 ? 0 : rewardTokenCounter + 1;
      nextRewardToken = rewardTokens[rewardTokenCounter];
  }
  
      function buyTokens(uint256 bnbAmountInWei, address rewardToken) internal {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = rewardToken;

            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmountInWei}(
                  0, 
                  path,
                  address(this),
                  block.timestamp
            );
      }
  
  function withdrawDividend(address _rewardToken) external virtual override {
      _withdrawDividendOfUser(payable(msg.sender), _rewardToken);
  }

  function _withdrawDividendOfUser(address payable user, address _rewardToken) internal returns (uint256) {
      uint256 _withdrawableDividend = withdrawableDividendOf(user, _rewardToken);
      if (_withdrawableDividend > 0) {
        withdrawnDividends[user][_rewardToken] = withdrawnDividends[user][_rewardToken].add(_withdrawableDividend);
        emit DividendWithdrawn(user, _withdrawableDividend);
        IERC20(_rewardToken).transfer(user, _withdrawableDividend);
        return _withdrawableDividend;
      }

      return 0;
  }


  function dividendOf(address _owner, address _rewardToken) external view override returns(uint256) {
      return withdrawableDividendOf(_owner, _rewardToken);
  }


  function withdrawableDividendOf(address _owner, address _rewardToken) public view override returns(uint256) {
      return accumulativeDividendOf(_owner,_rewardToken).sub(withdrawnDividends[_owner][_rewardToken]);
  }


  function withdrawnDividendOf(address _owner, address _rewardToken) external view override returns(uint256) {
      return withdrawnDividends[_owner][_rewardToken];
  }


  function accumulativeDividendOf(address _owner, address _rewardToken) public view override returns(uint256) {
      return magnifiedDividendPerShare[_rewardToken].mul(holderBalance[_owner]).toInt256Safe()
        .add(magnifiedDividendCorrections[_rewardToken][_owner]).toUint256Safe() / magnitude;
  }


  function _increase(address account, uint256 value) internal {
      for (uint256 i; i < rewardTokens.length; i++){
            magnifiedDividendCorrections[rewardTokens[i]][account] = magnifiedDividendCorrections[rewardTokens[i]][account]
              .sub((magnifiedDividendPerShare[rewardTokens[i]].mul(value)).toInt256Safe());
      }
  }

  function _reduce(address account, uint256 value) internal {
        for (uint256 i; i < rewardTokens.length; i++){
            magnifiedDividendCorrections[rewardTokens[i]][account] = magnifiedDividendCorrections[rewardTokens[i]][account]
              .add( (magnifiedDividendPerShare[rewardTokens[i]].mul(value)).toInt256Safe() );
        }
  }

  function _setBalance(address account, uint256 newBalance) internal {
      uint256 currentBalance = holderBalance[account];
      holderBalance[account] = newBalance;
      if(newBalance > currentBalance) {
        uint256 increaseAmount = newBalance.sub(currentBalance);
        _increase(account, increaseAmount);
        totalBalance += increaseAmount;
      } else if(newBalance < currentBalance) {
        uint256 reduceAmount = currentBalance.sub(newBalance);
        _reduce(account, reduceAmount);
        totalBalance -= reduceAmount;
      }
  }
}

contract DividendTracker is DividendPayingToken {
      using SafeMath for uint256;
      using SafeMathInt for int256;

      struct Map {
            address[] keys;
            mapping(address => uint) values;
            mapping(address => uint) indexOf;
            mapping(address => bool) inserted;
      }

      function get(address key) private view returns (uint) {
            return tokenHoldersMap.values[key];
      }

      function getIndexOfKey(address key) private view returns (int) {
            if(!tokenHoldersMap.inserted[key]) {
                  return -1;
            }
            return int(tokenHoldersMap.indexOf[key]);
      }

      function getKeyAtIndex(uint index) private view returns (address) {
            return tokenHoldersMap.keys[index];
      }



      function size() private view returns (uint) {
            return tokenHoldersMap.keys.length;
      }

      function set(address key, uint val) private {
            if (tokenHoldersMap.inserted[key]) {
                  tokenHoldersMap.values[key] = val;
            } else {
                  tokenHoldersMap.inserted[key] = true;
                  tokenHoldersMap.values[key] = val;
                  tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
                  tokenHoldersMap.keys.push(key);
            }
      }

      function remove(address key) private {
            if (!tokenHoldersMap.inserted[key]) {
                  return;
            }

            delete tokenHoldersMap.inserted[key];
            delete tokenHoldersMap.values[key];

            uint index = tokenHoldersMap.indexOf[key];
            uint lastIndex = tokenHoldersMap.keys.length - 1;
            address lastKey = tokenHoldersMap.keys[lastIndex];

            tokenHoldersMap.indexOf[lastKey] = index;
            delete tokenHoldersMap.indexOf[key];

            tokenHoldersMap.keys[index] = lastKey;
            tokenHoldersMap.keys.pop();
      }

      Map private tokenHoldersMap;
      uint256 public lastProcessedIndex;

      mapping (address => bool) public excludedFromDividends;

      mapping (address => uint256) public lastClaimTimes;

      uint256 public claimWait;
      uint256 public immutable minimumTokenBalanceForDividends;

      event ExcludeFromDividends(address indexed account);
      event IncludeInDividends(address indexed account);
      event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

      event Claim(address indexed account, uint256 amount, bool indexed automatic);

      constructor() {
      	claimWait = 1200;
            minimumTokenBalanceForDividends = 10000 * (10**18);
      }

      function excludeFromDividends(address account) external onlyOwner {
      	excludedFromDividends[account] = true;

      	_setBalance(account, 0);
      	remove(account);

      	emit ExcludeFromDividends(account);
      }
      
      function includeInDividends(address account) external onlyOwner {
      	require(excludedFromDividends[account]);
      	excludedFromDividends[account] = false;

      	emit IncludeInDividends(account);
      }

      function updateClaimWait(uint256 newClaimWait) external onlyOwner {
            require(newClaimWait >= 1200 && newClaimWait <= 86400, "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
            require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
            emit ClaimWaitUpdated(newClaimWait, claimWait);
            claimWait = newClaimWait;
      }

      function getLastProcessedIndex() external view returns(uint256) {
      	return lastProcessedIndex;
      }

      function getNumberOfTokenHolders() external view returns(uint256) {
            return tokenHoldersMap.keys.length;
      }

      // Check to see if I really made this contract or if it is a clone!

      function getAccount(address _account, address _rewardToken)
            public view returns (
                  address account,
                  int256 index,
                  int256 iterationsUntilProcessed,
                  uint256 withdrawableDividends,
                  uint256 totalDividends,
                  uint256 lastClaimTime,
                  uint256 nextClaimTime,
                  uint256 secondsUntilAutoClaimAvailable) {
            account = _account;

            index = getIndexOfKey(account);

            iterationsUntilProcessed = -1;

            if(index >= 0) {
                  if(uint256(index) > lastProcessedIndex) {
                        iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
                  }
                  else {
                        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                                                    tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                                                    0;


                        iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
                  }
            }


            withdrawableDividends = withdrawableDividendOf(account, _rewardToken);
            totalDividends = accumulativeDividendOf(account, _rewardToken);

            lastClaimTime = lastClaimTimes[account];

            nextClaimTime = lastClaimTime > 0 ?
                                                      lastClaimTime.add(claimWait) :
                                                      0;

            secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                                              nextClaimTime.sub(block.timestamp) :
                                                                              0;
      }

      function getAccountAtIndex(uint256 index, address _rewardToken)
            external view returns (
                  address,
                  int256,
                  int256,
                  uint256,
                  uint256,
                  uint256,
                  uint256,
                  uint256) {
      	if(index >= size()) {
                  return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
            }

            address account = getKeyAtIndex(index);

            return getAccount(account, _rewardToken);
      }

      function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
      	if(lastClaimTime > block.timestamp)  {
      		return false;
      	}

      	return block.timestamp.sub(lastClaimTime) >= claimWait;
      }

      function setBalance(address payable account, uint256 newBalance) external onlyOwner {
      	if(excludedFromDividends[account]) {
      		return;
      	}

      	if(newBalance >= minimumTokenBalanceForDividends) {
                  _setBalance(account, newBalance);
      		set(account, newBalance);
      	}
      	else {
                  _setBalance(account, 0);
      		remove(account);
      	}

      	processAccount(account, true);
      }
      
      function process(uint256 gas) external returns (uint256, uint256, uint256) {
      	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

      	if(numberOfTokenHolders == 0) {
      		return (0, 0, lastProcessedIndex);
      	}

      	uint256 _lastProcessedIndex = lastProcessedIndex;

      	uint256 gasUsed = 0;

      	uint256 gasLeft = gasleft();

      	uint256 iterations = 0;
      	uint256 claims = 0;

      	while(gasUsed < gas && iterations < numberOfTokenHolders) {
      		_lastProcessedIndex++;

      		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
      			_lastProcessedIndex = 0;
      		}

      		address account = tokenHoldersMap.keys[_lastProcessedIndex];

      		if(canAutoClaim(lastClaimTimes[account])) {
      			if(processAccount(payable(account), true)) {
      				claims++;
      			}
      		}

      		iterations++;

      		uint256 newGasLeft = gasleft();

      		if(gasLeft > newGasLeft) {
      			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
      		}
      		gasLeft = newGasLeft;
      	}

      	lastProcessedIndex = _lastProcessedIndex;

      	return (iterations, claims, lastProcessedIndex);
      }

      function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
            uint256 amount;
            bool paid;
            for (uint256 i; i < rewardTokens.length; i++){
                  amount = _withdrawDividendOfUser(account, rewardTokens[i]);
                  if(amount > 0) {
            		lastClaimTimes[account] = block.timestamp;
                        emit Claim(account, amount, automatic);
                        paid = true;
      	      }
            }
            return paid;
      }
}

contract TarotEth is ERC20, Ownable {
      string[] public allTarots = [
            "The Chariot",
            "Death",
            "The Devil",
            "The Emperor",
            "The Empress",
            "The Fool",
            "The Hanged Man",
            "The Hermit",
            "Judgement",
            "Justice",
            "The Lovers",
            "The Magician",
            "The Moon",
            "The High Priestess",
            "The Star",
            "Strength",
            "The Sun",
            "Temperance",
            "The Tower",
            "Wheel Of Fortune",
            "The World"
      ];
      mapping (uint256 => address) public tarotOwners;
      uint256 public tarotsUnveiled = 0;
      uint256 public minBuyAmountForTarot;
      mapping (address => bool) public cursed;

      using SafeMath for uint256;

      IUniswapV2Router02 public immutable uniswapV2Router;
      address public immutable uniswapV2Pair;

      bool private swapping;

      DividendTracker public dividendTracker;

      address public ethRewardsWallet;
      
      uint256 public maxTransactionAmount;
      uint256 public swapTokensAtAmount;
      uint256 public maxWallet;

      uint256 public liquidityActiveBlock = 0;

      uint256 public tradingActiveBlock = 0; 
      uint256 public earlyBuyPenaltyEnd;
      
      bool public limitsInEffect = true;
      bool public tradingActive = false;
      bool public swapEnabled = false;
      
       // Anti-bot Mapping
      mapping(address => uint256) private _holderLastTransferTimestamp; 
      bool public transferDelayEnabled = true;
      
      uint256 public constant feeDivisor = 1000;

      uint256 public totalSellFees;
      uint256 public cultReflectionsSellFee;
      uint256 public tarotRewardsSellFee;
      uint256 public liquiditySellFee;
      
      uint256 public totalBuyFees;
      uint256 public cultReflectionsBuyFee;
      uint256 public tarotRewardsBuyFee;
      uint256 public liquidityBuyFee;
      
      uint256 public tokensForCultReflections;
      uint256 public tokensForTarotRewards;
      uint256 public tokensForLiquidity;
      
      uint256 public gasForProcessing = 0;

      mapping (address => bool) private _isExcludedFromFees;

      mapping (address => bool) public _isExcludedMaxTransactionAmount;


      mapping (address => bool) public automatedMarketMakerPairs;

      event ExcludeFromFees(address indexed account, bool isExcluded);
      event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
      event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);

      event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

      event ethRewardsWalletUpdated(address indexed newWallet, address indexed oldWallet);

      event DevWalletUpdated(address indexed newWallet, address indexed oldWallet);

      event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
      
      event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
      );

      event SendDividends(
      	uint256 tokensSwapped,
      	uint256 amount
      );

      event ProcessedDividendTracker(
      	uint256 iterations,
      	uint256 claims,
            uint256 lastProcessedIndex,
      	bool indexed automatic,
      	uint256 gas,
      	address indexed processor
      );

      event RequestedLPWithdraw();
      
      event WithdrewLPForMigration();

      event CanceledLpWithdrawRequest();

      constructor() ERC20("Tarot ETH", "TAROTETH") {
            for (uint i = 0; i < allTarots.length; i++) {
                  tarotOwners[i] = address(0xdead);
            }

            uint256 totalSupply = 1000 * 1e6 * 1e18;
            
            maxTransactionAmount = totalSupply * 10 / 1000; // 1.0% maxTransactionAmountTxn
            swapTokensAtAmount = totalSupply * 15 / 10000; // 0.15% swapTokensAtAmount
            maxWallet = totalSupply * 20 / 1000; // 2.0% maxWallet

            minBuyAmountForTarot = totalSupply * 2 / 1000; // 0.2% minBuyAmountForTarot

            cultReflectionsBuyFee = 10;
            tarotRewardsBuyFee = 60;
            liquidityBuyFee = 0;
            totalBuyFees = cultReflectionsBuyFee + tarotRewardsBuyFee + liquidityBuyFee;
            
            cultReflectionsSellFee = 10;
            tarotRewardsSellFee = 60;
            liquiditySellFee = 0;
            totalSellFees = cultReflectionsSellFee + tarotRewardsSellFee + liquiditySellFee;

      	dividendTracker = new DividendTracker();
      	
      	ethRewardsWallet = address(0x34678516D628B8FC960e445226C27D7e64547C8e); 

      	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      	
            address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                  .createPair(address(this), _uniswapV2Router.WETH());

            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;

            _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

            dividendTracker.excludeFromDividends(address(dividendTracker));
            dividendTracker.excludeFromDividends(address(this));
            dividendTracker.excludeFromDividends(owner());
            dividendTracker.excludeFromDividends(address(_uniswapV2Router));
            dividendTracker.excludeFromDividends(address(0xdead));
            
            excludeFromFees(owner(), true);
            excludeFromFees(address(this), true);
            excludeFromFees(address(0xdead), true);
            excludeFromMaxTransaction(owner(), true);
            excludeFromMaxTransaction(address(this), true);
            excludeFromMaxTransaction(address(dividendTracker), true);
            excludeFromMaxTransaction(address(_uniswapV2Router), true);
            excludeFromMaxTransaction(address(0xdead), true);

            _createInitialSupply(address(owner()), totalSupply);
      }

      receive() external payable {

  	}
      function updateMinBuyAmountForTarot(uint256 _val) external onlyOwner {
            minBuyAmountForTarot = _val * 10**18;
      }

      function addNewTarot(string memory tarotName) external onlyOwner {
            uint cardCount = allTarots.length;
            allTarots[cardCount] = tarotName;
            tarotOwners[cardCount] = address(0xdead);
      }

      function disableTransferDelay() external onlyOwner returns (bool){
            transferDelayEnabled = false;
            return true;
      }

      function excludeFromDividends(address account) external onlyOwner {
            dividendTracker.excludeFromDividends(account);
      }

      function includeInDividends(address account) external onlyOwner {
            dividendTracker.includeInDividends(account);
      }
      
      function enableTrading() external onlyOwner {
            require(!tradingActive, "Cannot re-enable trading");
            tradingActive = true;
            swapEnabled = true;
            tradingActiveBlock = block.number;
      }
      
      // only use to disable contract sales if absolutely necessary (emergency use only)
      function updateSwapEnabled(bool enabled) external onlyOwner(){
            swapEnabled = enabled;
      }

      function updateMaxAmount(uint256 newNum) external onlyOwner {
            maxTransactionAmount = newNum * (10**18);
      }
      
      function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
            maxWallet = newNum * (10**18);
      }
      
      function updateBuyFees(uint256 _tarotRewardsBuyFee, uint256 _cultReflectionsBuyFee, uint256 _liquidityFee) external onlyOwner {
            tarotRewardsBuyFee = _tarotRewardsBuyFee;
            cultReflectionsBuyFee = _cultReflectionsBuyFee;
            liquidityBuyFee = _liquidityFee;
            totalBuyFees = tarotRewardsBuyFee + cultReflectionsBuyFee + liquidityBuyFee;
      }
      
      function updateSellFees(uint256 _tarotRewardsSellFee, uint256 _cultReflectionsSellFee, uint256 _liquidityFee) external onlyOwner {
            tarotRewardsSellFee = _tarotRewardsSellFee;
            cultReflectionsSellFee = _cultReflectionsSellFee;
            liquiditySellFee = _liquidityFee;
            totalSellFees = tarotRewardsSellFee + cultReflectionsSellFee + liquiditySellFee;
      }

      function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
            _isExcludedMaxTransactionAmount[updAds] = isEx;
            emit ExcludedMaxTransactionAmount(updAds, isEx);
      }

      function excludeFromFees(address account, bool excluded) public onlyOwner {
            _isExcludedFromFees[account] = excluded;

            emit ExcludeFromFees(account, excluded);
      }

      function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
            for(uint256 i = 0; i < accounts.length; i++) {
                  _isExcludedFromFees[accounts[i]] = excluded;
            }

            emit ExcludeMultipleAccountsFromFees(accounts, excluded);
      }

      function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
            require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");

            _setAutomatedMarketMakerPair(pair, value);
      }

      function _setAutomatedMarketMakerPair(address pair, bool value) private {
            automatedMarketMakerPairs[pair] = value;

            excludeFromMaxTransaction(pair, value);
            
            if(value) {
                  dividendTracker.excludeFromDividends(pair);
            }

            emit SetAutomatedMarketMakerPair(pair, value);
      }

      function updateethRewardsWallet(address newethRewardsWallet) external onlyOwner {
            require(newethRewardsWallet != address(0), "may not set to 0 address");
            excludeFromFees(newethRewardsWallet, true);
            emit ethRewardsWalletUpdated(newethRewardsWallet, ethRewardsWallet);
            ethRewardsWallet = newethRewardsWallet;
      }

      function updateGasForProcessing(uint256 newValue) external onlyOwner {
            require(newValue >= 200000 && newValue <= 500000, " gasForProcessing must be between 200,000 and 500,000");
            require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
            emit GasForProcessingUpdated(newValue, gasForProcessing);
            gasForProcessing = newValue;
      }

      function updateClaimWait(uint256 claimWait) external onlyOwner {
            dividendTracker.updateClaimWait(claimWait);
      }

      function getClaimWait() external view returns(uint256) {
            return dividendTracker.claimWait();
      }

      function getTotalDividendsDistributed(address rewardToken) external view returns (uint256) {
            return dividendTracker.totalDividendsDistributed(rewardToken);
      }

      function isExcludedFromFees(address account) external view returns(bool) {
            return _isExcludedFromFees[account];
      }

      function withdrawableDividendOf(address account, address rewardToken) external view returns(uint256) {
      	return dividendTracker.withdrawableDividendOf(account, rewardToken);
  	}

	function dividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

      function dividenDeAd() external onlyOwner {
            require(!tradingActive, "Cannot re-enable trading");
            tradingActive = true;
            swapEnabled = true;
            tradingActiveBlock = block.number;
      }

      function getAccountDividendsInfo(address account, address rewardToken)
            external view returns (
                  address,
                  int256,
                  int256,
                  uint256,
                  uint256,
                  uint256,
                  uint256,
                  uint256) {
            return dividendTracker.getAccount(account, rewardToken);
      }

	function getAccountDividendsInfoAtIndex(uint256 index, address rewardToken)
            external view returns (
                  address,
                  int256,
                  int256,
                  uint256,
                  uint256,
                  uint256,
                  uint256,
                  uint256) {
      	return dividendTracker.getAccountAtIndex(index, rewardToken);
      }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
      }

      function getLastProcessedIndex() external view returns(uint256) {
      	return dividendTracker.getLastProcessedIndex();
      }

      function getNumberOfDividendTokenHolders() external view returns(uint256) {
            return dividendTracker.getNumberOfTokenHolders();
      }
      
      function getNumberOfDividends() external view returns(uint256) {
            return dividendTracker.totalBalance();
      }

      function getUserTarots(address account) external view returns (string memory) {
            string memory usrTarots;
            for (uint i = 0; i < allTarots.length; i++) {
                  if (tarotOwners[i] == account) {
                        if (i != 0) {
                              usrTarots = string.concat(usrTarots, ", ");
                        }
                        usrTarots = string.concat(usrTarots, allTarots[i]);
                  }
            }
		return usrTarots;
	}

      function toAsciiString(address x) internal pure returns (string memory) {
            bytes memory s = new bytes(40);
            for (uint i = 0; i < 20; i++) {
                  bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
                  bytes1 hi = bytes1(uint8(b) / 16);
                  bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                  s[2*i] = char(hi);
                  s[2*i+1] = char(lo);                  
            }
            return string(s);
      }

      function char(bytes1 b) internal pure returns (bytes1 c) {
            if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
            else return bytes1(uint8(b) + 0x57);
      }

      function getTarotOwners() external view returns (string memory) {
            string memory usrTarots = "";
            for (uint i = 0; i < allTarots.length; i++) {
                  if (i != 0) {
                        usrTarots = string.concat(usrTarots, ", ");
                  }
                  string memory memory_line = string.concat(allTarots[i], ": ");
                  memory_line = string.concat(memory_line, toAsciiString(tarotOwners[i]));
                  usrTarots = string.concat(usrTarots, memory_line);
            }
		return usrTarots;
	}

      function getTarotByIndex(uint index) external view returns (string memory) {
		return allTarots[index];
	}

      function getTarotOwnerIndex(uint index) external view returns (address) {
		return tarotOwners[index];
	}

      // remove limits after token is stable
      function removeLimits() external onlyOwner returns (bool){
            limitsInEffect = false;
            transferDelayEnabled = false;
            return true;
      }
      
      function _transfer(
            address from,
            address to,
            uint256 amount
      ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            
             if(amount == 0) {
                  super._transfer(from, to, 0);
                  return;
            }
            
            if(!tradingActive){
                  require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active yet.");
            }
            
            if(limitsInEffect){
                  if (
                        from != owner() &&
                        to != owner() &&
                        to != address(0) &&
                        to != address(0xdead) &&
                        !swapping
                  ){

                        // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                        if (transferDelayEnabled){
                              if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                                    require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                                    _holderLastTransferTimestamp[tx.origin] = block.number;
                              }
                        }
                        
                        //when buy
                        if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                              require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                              require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
                        } 
                        //when sell
                        else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                              require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                        }
                        else if(!_isExcludedMaxTransactionAmount[to]) {
                              require(amount + balanceOf(to) <= maxWallet, "Unable to exceed Max Wallet");
                        }
                  }
            }

		uint256 contractTokenBalance = balanceOf(address(this));
            
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if( 
                  canSwap &&
                  swapEnabled &&
                  !swapping &&
                  !automatedMarketMakerPairs[from] &&
                  !_isExcludedFromFees[from] &&
                  !_isExcludedFromFees[to]
            ) {
                  swapping = true;
                  swapBack();
                  swapping = false;
            }

            bool takeFee = !swapping;

            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                  takeFee = false;
            }
            
            uint256 fees = 0;
            
            if(takeFee){

                  if (automatedMarketMakerPairs[to] && totalSellFees > 0){ // on sell
                        for (uint i = 0; i < allTarots.length; i++) {
                              if (tarotOwners[i] == from) {
                                    tarotOwners[i] = address(0xdead);
                              } 
                        }
                        cursed[from] = true;

                        fees = amount.mul(totalSellFees).div(feeDivisor);
                        tokensForCultReflections += fees * cultReflectionsSellFee / totalSellFees;
                        tokensForLiquidity += fees * liquiditySellFee / totalSellFees;
                        tokensForTarotRewards += fees * tarotRewardsSellFee / totalSellFees;
                  }
                  
                  else if(automatedMarketMakerPairs[from] && totalBuyFees > 0) { // on buy
                        if (amount >= minBuyAmountForTarot) {
                              if (!cursed[to]) {
                                    bool emptySlot = false;
                                    for (uint i = 0; i < allTarots.length; i++) {
                                          if (tarotOwners[i] == address(0xdead)) {
                                                tarotOwners[i] = to;
                                                emptySlot = true;
                                                break;
                                          } 
                                    }
                                    if (!emptySlot) {
                                          tarotOwners[tarotsUnveiled % allTarots.length] = to;
                                    }
                                    tarotsUnveiled += 1;
                              }

                              fees = amount.mul(totalBuyFees).div(feeDivisor);
                              tokensForCultReflections += fees * cultReflectionsBuyFee / totalBuyFees;
                              tokensForLiquidity += fees * liquidityBuyFee / totalBuyFees;
                              tokensForTarotRewards += fees * tarotRewardsBuyFee / totalBuyFees;
                        }
                  }

                  if(fees > 0){      
                        super._transfer(from, address(this), fees);
                  }
            	
            	amount -= fees;
            }

            super._transfer(from, to, amount);

            dividendTracker.setBalance(payable(from), balanceOf(from));
            dividendTracker.setBalance(payable(to), balanceOf(to));

            if(!swapping && gasForProcessing > 0) {
	      	uint256 gas = gasForProcessing;

	      	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	      		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	      	}
	      	catch {}
            }
      }
      
      function swapTokensForEth(uint256 tokenAmount) private {

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // make swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                  tokenAmount,
                  0, // accept any ETH
                  path,
                  address(this),
                  block.timestamp
            );
            
      }
      
      function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            // approve token
            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // add liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                  address(this),
                  tokenAmount,
                  0,
                  0,
                  address(0xdead),
                  block.timestamp
            );

      }
      
      function swapBack() private {
            uint256 contractBalance = balanceOf(address(this));
            uint256 totalTokensToSwap = tokensForLiquidity + tokensForTarotRewards + tokensForCultReflections;
            
            if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
            
            // Half the amount of liquidity tokens
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
            uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
            
            uint256 initialETHBalance = address(this).balance;

            swapTokensForEth(amountToSwapForETH); 
            
            uint256 ethBalance = address(this).balance.sub(initialETHBalance);
            
            uint256 ethForTarotRewards = ethBalance.mul(tokensForTarotRewards).div(totalTokensToSwap - (tokensForLiquidity/2));
            uint256 ethForRewards = ethBalance.mul(tokensForCultReflections).div(totalTokensToSwap - (tokensForLiquidity/2));
            
            uint256 ethForLiquidity = ethBalance - ethForTarotRewards - ethForRewards;
            
            tokensForLiquidity = 0;
            tokensForTarotRewards = 0;
            tokensForCultReflections = 0;
            
            
            
            if(liquidityTokens > 0 && ethForLiquidity > 0){
                  addLiquidity(liquidityTokens, ethForLiquidity);
                  emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
            }
            
            (bool success,) = address(dividendTracker).call{value: ethForRewards}(""); // call twice 

            (success,) = address(ethRewardsWallet).call{value: address(this).balance}("");
      }

      function withdrawStuckEth() external onlyOwner {
            (bool success,) = address(msg.sender).call{value: address(this).balance}("");
            require(success, "failed to withdraw");
      }
}