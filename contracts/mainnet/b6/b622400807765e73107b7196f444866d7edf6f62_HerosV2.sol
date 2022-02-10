/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract HerosV2 is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) public _lastBuyTime;
    mapping (address => uint256) public _firstBuyTime;
    mapping (address => uint256) public _accountedRewardsPeriods;
    mapping (address => uint256) public _rewardsBasis;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

    address payable public dev;
    address payable public charity;
    address payable public marketing;
    address public rewards;
    address public _burnPool = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**15 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Heros Token";
    string private _symbol = "HEROS";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 1;
    uint256 public _liquidityFee = 1;
    uint256 public _marketingBuyFee = 3;
    uint256 public _marketingSellFee = 4;
    uint256 public _developmentBuyFee = 3;
    uint256 public _developmentSellFee = 4;
    uint256 public _charityFee = 2;
    uint256 public _dayTraderMultiplicator = 20; // div by 10
    uint256 public _rewardRate = 1200; // 12%
    uint256 public _rewardPeriod = 7776000; // in unix seconds
    bool public transfersEnabled; //once enabled, transfers cannot be disabled

    uint256 public _pendingLiquidityFees;
    uint256 public _pendingCharityFees;
    uint256 public _pendingMarketingFees;
    uint256 public _pendingDevelopmentFees;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxWalletHolding = 3 * 10**15 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 5 * 10**12 * 10**9;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _devWallet, address payable _marketingWallet, address payable _charityWallet, address _rewardsWallet) public {
      dev = _devWallet;
      marketing = _marketingWallet;
      charity = _charityWallet;
      rewards = _rewardsWallet;

      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[_burnPool] = true;
      _isExcludedFromFee[_rewardsWallet] = true;

      _isExcluded[_burnPool] = true;
      _excluded.push(_burnPool);

      _isExcluded[uniswapV2Pair] = true;
      _excluded.push(uniswapV2Pair);

      _isExcluded[address(this)] = true;
      _excluded.push(address(this));

      uint256 currentRate =  _getRate();
      uint256 burnPoolAllocation = _tTotal.div(10);
      _rOwned[_burnPool] = burnPoolAllocation.mul(currentRate);
      _tOwned[_burnPool] = burnPoolAllocation;

      currentRate = _getRate();
      uint256 rewardsAllocation = _tTotal.mul(30).div(100);
      _rOwned[_rewardsWallet] = rewardsAllocation.mul(currentRate);

      _rOwned[_msgSender()] = _rTotal - _rOwned[_rewardsWallet] - _rOwned[_burnPool];

      emit Transfer(address(0), _msgSender(), _tTotal);
      emit Transfer(_msgSender(), _rewardsWallet, rewardsAllocation);
      emit Transfer(_msgSender(), _burnPool, burnPoolAllocation);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        (uint256 totalBalance,) = pendingRewards(account);
        if (_isExcluded[account]) totalBalance = totalBalance + _tOwned[account];
        else totalBalance = totalBalance + tokenFromReflection(_rOwned[account]);
        return totalBalance;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function manualSwapAndLiquify() public onlyOwner() {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapAndLiquify(contractTokenBalance);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTax(uint256 _taxType, uint _taxSize) external onlyOwner() {
      if (_taxType == 1) {
        _taxFee = _taxSize;
      }
      else if (_taxType == 2) {
        _liquidityFee = _taxSize;
      }
      else if (_taxType == 3) {
        _developmentBuyFee = _taxSize;
      }
      else if (_taxType == 4) {
        _developmentSellFee = _taxSize;
      }
      else if (_taxType == 5) {
        _charityFee = _taxSize;
      }
      else if (_taxType == 6) {
        _marketingBuyFee = _taxSize;
      }
      else if (_taxType == 7) {
        _marketingSellFee = _taxSize;
      }
      else if (_taxType == 8) {
        _dayTraderMultiplicator = _taxSize;
      }
      else if (_taxType == 9) {
        _rewardRate = _taxSize;
      }
      else if (_taxType == 10) {
        _rewardPeriod = _taxSize;
      }
    }

    function setSwapAndLiquifyEnabled(bool _enabled, uint256 _numTokensMin) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        numTokensSellToAddToLiquidity = _numTokensMin;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function enableTransfers() public onlyOwner() {
        transfersEnabled = true;
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function deliverReflections(uint256 tAmount) external {
        require(!_isExcluded[msg.sender], "Only holders that are not excluded from rewards can call this");
        uint256 currentRate =  _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[msg.sender] = _rOwned[msg.sender].sub(rAmount);
        _reflectFee(rAmount, tAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeOperations(uint256 tAmount, uint256 feeType, bool isBuy) private returns (uint256) {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = tAmount;
        uint256 taxMultiplicator = 10;

        if (feeType == 2) taxMultiplicator = _dayTraderMultiplicator;

        uint256 tFee = calculateFee(tAmount, _taxFee, taxMultiplicator);
        uint256 tLiquidity = calculateFee(tAmount, _liquidityFee, taxMultiplicator);
        uint256 tMarketing = calculateFee(tAmount, isBuy ? _marketingBuyFee : _marketingSellFee, taxMultiplicator);
        uint256 tCharity = calculateFee(tAmount, _charityFee, taxMultiplicator);
        uint256 tDevelopment = calculateFee(tAmount, isBuy ? _developmentBuyFee : _developmentSellFee, taxMultiplicator);

        _pendingLiquidityFees = _pendingLiquidityFees.add(tLiquidity);
        _pendingCharityFees = _pendingCharityFees.add(tCharity);
        _pendingMarketingFees = _pendingMarketingFees.add(tMarketing);
        _pendingDevelopmentFees = _pendingDevelopmentFees.add(tDevelopment);

        tTransferAmount = tAmount - tFee - tLiquidity;
        tTransferAmount = tTransferAmount - tMarketing - tCharity - tDevelopment;
        uint256 tTaxes = tLiquidity.add(tMarketing).add(tCharity).add(tDevelopment);

        _reflectFee(tFee.mul(currentRate), tFee);

        _rOwned[address(this)] = _rOwned[address(this)].add(tTaxes.mul(currentRate));
        _tOwned[address(this)] = _tOwned[address(this)].add(tTaxes);
        return tTransferAmount;
    }

    function calculateFee(uint256 _amount, uint256 _taxRate, uint256 _taxMultiplicator) private pure returns (uint256) {
        return _amount.mul(_taxRate).div(10**2).mul(_taxMultiplicator).div(10);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function pendingRewards(address account) public view returns (uint256, uint256) {
        if (!_isExcluded[account]) {
          uint256 rewardTimespan = block.timestamp.sub(_firstBuyTime[account]);
          if (_firstBuyTime[account] == 0) rewardTimespan = 0;
          uint256 rewardPeriods = rewardTimespan.div(_rewardPeriod);
          if (rewardPeriods >= _accountedRewardsPeriods[account]) rewardPeriods = rewardPeriods - _accountedRewardsPeriods[account];
          else rewardPeriods = 0;
          uint256 _pendingRewards = rewardPeriods.mul(_rewardRate).mul(_rewardsBasis[account]).div(10**4);
          return (_pendingRewards, rewardPeriods);
        }
        return (0, 0);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer( address from, address to, uint256 amount ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        _lastBuyTime[to] = block.timestamp;
        if (_firstBuyTime[to] == 0) _firstBuyTime[to] = block.timestamp;

        bool distributedFrom = distributeRewards(from);
        bool distributedTo = distributeRewards(to);

        //indicates if fee should be deducted from transfer
        uint256 feeType = 1;
        bool isBuy = from == uniswapV2Pair;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            feeType = 0;
        }
        else {
          require(transfersEnabled, "Transfers are not enabled now");
          if (to != uniswapV2Pair && from != uniswapV2Pair) {
            feeType = 0;
          }
          if (to == uniswapV2Pair || (to != uniswapV2Pair && from != uniswapV2Pair)) {
            if (_lastBuyTime[from] != 0 && (_lastBuyTime[from] + (24 hours) > block.timestamp) ) {
              feeType = 2;
            }
          }
        }

        _tokenTransfer(from, to, amount, feeType, isBuy);

        syncRewards(from, distributedFrom);
        syncRewards(to, distributedTo);

        if (!_isExcludedFromFee[to] && (to != uniswapV2Pair)) require(balanceOf(to) < _maxWalletHolding, "Max Wallet holding limit exceeded");
    }

    function distributeRewards(address account) private returns (bool) {
        (uint256 _rewards, uint256 _periods) = pendingRewards(account);
        if (_rewards > 0) {
          _accountedRewardsPeriods[account] = _accountedRewardsPeriods[account] + _periods;
          uint256 currentRate =  _getRate();
          uint256 rRewards = _rewards.mul(currentRate);
          if (_rOwned[rewards] > rRewards) {
            _rOwned[account] = _rOwned[account].add(rRewards);
            _rOwned[rewards] = _rOwned[rewards].sub(rRewards);
          }
          return true;
        }
        return false;
    }

    function syncRewards(address account, bool rewardsDistributed) private {
        uint256 accountBalance = balanceOf(account);
        if (_rewardsBasis[account] == 0 || accountBalance < _rewardsBasis[account] || rewardsDistributed ) _rewardsBasis[account] = accountBalance;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 liquidityPart = 0;
        if (_pendingLiquidityFees < contractTokenBalance) liquidityPart = _pendingLiquidityFees;
        uint256 distributionPart = contractTokenBalance.sub(liquidityPart);
        uint256 totalPendingFees = _pendingLiquidityFees + _pendingCharityFees + _pendingMarketingFees + _pendingDevelopmentFees;
        uint256 liquidityHalfPart = liquidityPart.div(2);
        uint256 liquidityHalfTokenPart = liquidityPart.sub(liquidityHalfPart);

        //now swapping half of the liquidity part + all of the distribution part into ETH
        uint256 totalETHSwap = liquidityHalfPart.add(distributionPart);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(totalETHSwap);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 liquidityBalance = liquidityHalfPart.mul(newBalance).div(totalETHSwap);

        // add liquidity to uniswap
        if (liquidityHalfTokenPart > 0 && liquidityBalance > 0) addLiquidity(liquidityHalfTokenPart, liquidityBalance);
        emit SwapAndLiquify(liquidityHalfPart, liquidityBalance, liquidityHalfPart);

        newBalance = address(this).balance;

        uint256 payMarketing = _pendingMarketingFees.mul(newBalance).div(totalPendingFees);
        uint256 payDevelopment = _pendingDevelopmentFees.mul(newBalance).div(totalPendingFees);

        if (payMarketing <= address(this).balance) marketing.call{ value: payMarketing }("");
        if (payDevelopment <= address(this).balance) dev.call{ value: payDevelopment }("");
        if (address(this).balance > 0) charity.call{ value: address(this).balance }("");

        _pendingLiquidityFees = 0;
        _pendingCharityFees = 0;
        _pendingMarketingFees = 0;
        _pendingDevelopmentFees = 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 feeType, bool isBuy) private {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = amount;
        if (feeType != 0) {
          tTransferAmount = _takeOperations(amount, feeType, isBuy);
        }
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        uint256 rAmount = amount.mul(currentRate);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        } else {
            _transferStandard(sender, recipient, rAmount, amount, tTransferAmount, rTransferAmount);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 rAmount, uint256 tAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

}