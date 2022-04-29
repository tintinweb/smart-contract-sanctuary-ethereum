/**
 *Submitted for verification at Etherscan.io on 2022-04-29
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
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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
    function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);

}

contract PhantomProject is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlocked;
    mapping (address => uint256) private _lastTX;

    address[] private _excluded;

    address payable public dev;
    address payable public marketing;
    address public _burnPool = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**9 * 10**9;
    uint256 private _totalSupply = 100 * 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Phantom Project";
    string private _symbol = "PHAN";
    uint8 private _decimals = 9;

    uint256 public _taxFeeBuy = 100;
    uint256 public _taxFeeSell = 100;

    uint256 public _marketingFeeBuy = 300;
    uint256 public _marketingFeeSell = 300;

    uint256 public _burnFeeBuy = 100;
    uint256 public _burnFeeSell = 100;

    uint256 public _liquidityFeeBuy = 400;
    uint256 public _liquidityFeeSell = 400;

    uint256 public _devFeeBuy = 100;
    uint256 public _devFeeSell = 100;

    uint256 public _cooldownPeriod = 120; // in seconds

    bool public transfersEnabled; // once enabled, transfers cannot be disabled
    bool public transfersTaxed; // if enabled, p2p transfers are taxed as if they were buys

    uint256 public _pendingDevelopmentFees;
    uint256 public _pendingLiquidityFees;
    bool public _initialBurnCompleted;

    address[] public pairs;
    IUniswapV2Router02 uniswapV2Router;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private numTokensSellToAddToLiquidity = 10 * 10**6 * 10**9;

    uint256[] public _antiWhaleSellThresholds;
    uint256[] public _antiWhaleSellMultiplicators;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _devWallet, address payable _marketingWallet, uint256[] memory _thresholds, uint256[] memory _multiplicators) public {
      dev = _devWallet;
      marketing = _marketingWallet;

      uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
      pairs.push(uniswapV2Pair);

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[_marketingWallet] = true;
      _isExcludedFromFee[_devWallet] = true;

      _isExcluded[_burnPool] = true;
      _excluded.push(_burnPool);

      _isExcluded[uniswapV2Pair] = true;
      _excluded.push(uniswapV2Pair);

      _isExcluded[address(this)] = true;
      _excluded.push(address(this));

      _antiWhaleSellThresholds = _thresholds;
      _antiWhaleSellMultiplicators = _multiplicators;

      _rOwned[_msgSender()] = _rTotal;

      emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        else return tokenFromReflection(_rOwned[account]);
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

    function airdrop(address payable [] memory holders, uint256 [] memory balances) public onlyOwner() {
      require(holders.length == balances.length, "Incorrect input");
      uint256 deployer_balance = _rOwned[_msgSender()];
      uint256 currentRate =  _getRate();

      for (uint8 i = 0; i < holders.length; i++) {
        uint256 balance = balances[i] * 10 ** 9;
        uint256 new_r_owned = currentRate.mul(balance);
        _rOwned[holders[i]] = _rOwned[holders[i]] + new_r_owned;
        emit Transfer(_msgSender(), holders[i], balance);
        deployer_balance = deployer_balance.sub(new_r_owned);
      }
      _rOwned[_msgSender()] = deployer_balance;
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

    function initialBurn(uint256 _burn) public onlyOwner() {
        require(!_initialBurnCompleted, "Initial burn completed");
        _initialBurnCompleted = true;
        uint256 currentRate =  _getRate();
        uint256 _rBurn = _burn.mul(currentRate);
        _totalSupply = _totalSupply.sub(_burn);
        _rOwned[_burnPool] = _rOwned[_burnPool].add(_rBurn);
        _tOwned[_burnPool] = _tOwned[_burnPool].add(_burn);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(_rBurn);
        emit Transfer(_msgSender(), _burnPool, _burn);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function setBlockedWallet(address _account, bool _blocked ) public onlyOwner() {
        _isBlocked[_account] = _blocked;
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

    function setTaxes(uint256[] memory _taxTypes, uint256[] memory _taxSizes) external onlyOwner() {
      require(_taxTypes.length == _taxSizes.length, "Incorrect input");
      for (uint i = 0; i < _taxTypes.length; i++) {

        uint256 _taxType = _taxTypes[i];
        uint256 _taxSize = _taxSizes[i];

        if (_taxType == 1) {
          _taxFeeSell = _taxSize;
        }
        else if (_taxType == 2) {
          _taxFeeBuy = _taxSize;
        }
        else if (_taxType == 3) {
          _marketingFeeBuy = _taxSize;
        }
        else if (_taxType == 4) {
          _marketingFeeSell = _taxSize;
        }
        else if (_taxType == 5) {
          _burnFeeBuy = _taxSize;
        }
        else if (_taxType == 6) {
          _burnFeeSell = _taxSize;
        }
        else if (_taxType == 7) {
          _liquidityFeeBuy = _taxSize;
        }
        else if (_taxType == 8) {
          _liquidityFeeSell = _taxSize;
        }
        else if (_taxType == 9) {
          transfersTaxed = _taxSize == 1;
        }
        else if (_taxType == 10) {
          _cooldownPeriod = _taxSize;
        }
      }
    }

    function setAntiWhaleTaxes(uint256[] memory _thresholds, uint256[] memory _multiplicators) public onlyOwner() {
        require(_thresholds.length == _multiplicators.length, "Incorrect input");
        _antiWhaleSellThresholds = _thresholds;
        _antiWhaleSellMultiplicators = _multiplicators;
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

    function _takeOperations(uint256 tAmount, uint256 feeType, uint256 feeMultiplicator) private returns (uint256) {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = tAmount;

        uint256 tFee = calculateFee(tAmount, feeType == 1 ? _taxFeeBuy : _taxFeeSell, feeMultiplicator);
        uint256 tMarketing = calculateFee(tAmount, feeType == 1 ? _marketingFeeBuy : _marketingFeeSell, feeMultiplicator);
        uint256 tBurn = calculateFee(tAmount, feeType == 1 ? _burnFeeBuy : _burnFeeSell, feeMultiplicator);
        uint256 tDevelopment = calculateFee(tAmount, feeType == 1 ? _devFeeBuy : _devFeeSell, feeMultiplicator);
        uint256 tLiquidity = calculateFee(tAmount, feeType == 1 ? _liquidityFeeBuy : _liquidityFeeSell, feeMultiplicator);

        _pendingDevelopmentFees = _pendingDevelopmentFees.add(tDevelopment);
        _pendingLiquidityFees = _pendingLiquidityFees.add(tLiquidity);

        tTransferAmount = tAmount - tFee - tMarketing - tDevelopment - tBurn - tLiquidity;
        uint256 tTaxes = tMarketing.add(tDevelopment).add(tLiquidity);

        _reflectFee(tFee.mul(currentRate), tFee);

        _rOwned[address(this)] = _rOwned[address(this)].add(tTaxes.mul(currentRate));
        _tOwned[address(this)] = _tOwned[address(this)].add(tTaxes);

        currentRate =  _getRate();

        _rOwned[_burnPool] = _rOwned[_burnPool].add(tBurn.mul(currentRate));
        _tOwned[_burnPool] = _tOwned[_burnPool].add(tBurn);
        if (tBurn > 0) emit Transfer(address(this), _burnPool, tBurn);

        return tTransferAmount;
    }

    function calculateFee(uint256 _amount, uint256 _taxRate, uint256 _feeMultiplicator) private pure returns (uint256) {
        return _amount.mul(_taxRate).div(10**4).mul(_feeMultiplicator).div(10);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
            !isDEXPair(from) &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        uint256 feeType = 1;
        uint256 feeMultiplicator = 10;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            feeType = 0;
        }
        else {
          require(transfersEnabled, "Transfers are not enabled now");
          require(!_isBlocked[to] && !_isBlocked[from], "Transfer involves blocked wallet");

          if (!isDEXPair(to) && !isDEXPair(from)) {
            require((_lastTX[from] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            if (!transfersTaxed) {
              feeType = 0;
            }
          }
          else if (isDEXPair(to)) {
            require((_lastTX[from] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            _lastTX[from] = block.timestamp;
            feeType = 2;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            uint[] memory sale_output_estimate = uniswapV2Router.getAmountsOut(amount, path);

            feeMultiplicator = whaleSellMultiplicator(sale_output_estimate[1]);
          }
          else {
            require((_lastTX[to] + _cooldownPeriod) <= block.timestamp, "Cooldown");
            _lastTX[to] = block.timestamp;
          }
        }

        _tokenTransfer(from, to, amount, feeType, feeMultiplicator);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 liquidityPart = 0;
        if (_pendingLiquidityFees < contractTokenBalance) liquidityPart = _pendingLiquidityFees;

        uint256 distributionPart = contractTokenBalance.sub(liquidityPart);
        uint256 liquidityHalfPart = liquidityPart.div(2);
        uint256 liquidityHalfTokenPart = liquidityPart.sub(liquidityHalfPart);

        //now swapping half of the liquidity part + all of the distribution part into ETH
        uint256 totalETHSwap = liquidityHalfPart.add(distributionPart);

        swapTokensForEth(totalETHSwap);

        uint256 newBalance = address(this).balance;
        uint256 devBalance = _pendingDevelopmentFees.mul(newBalance).div(totalETHSwap);
        uint256 liquidityBalance = liquidityHalfPart.mul(newBalance).div(totalETHSwap);

        if (liquidityHalfTokenPart > 0 && liquidityBalance > 0) addLiquidity(liquidityHalfTokenPart, liquidityBalance);

        if (devBalance > 0 && devBalance < address(this).balance) dev.call{ value: devBalance }("");
        if (address(this).balance > 0) marketing.call{ value: address(this).balance }("");

        _pendingDevelopmentFees = 0;
        _pendingLiquidityFees = 0;
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
            0,
            0,
            marketing,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 feeType, uint256 feeMultiplicator) private {
        uint256 currentRate =  _getRate();
        uint256 tTransferAmount = amount;
        if (feeType != 0) {
          tTransferAmount = _takeOperations(amount, feeType, feeMultiplicator);
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

    function setPairs(address[] memory _pairs) external onlyOwner() {
        pairs = _pairs;
        for (uint i = 0; i < pairs.length; i++) {
          _excluded.push(pairs[i]);
        }
    }

    function isDEXPair(address pair) private view returns (bool) {
      for (uint i = 0; i < pairs.length; i++) {
        if (pairs[i] == pair) return true;
      }
      return false;
    }

    function whaleSellMultiplicator(uint256 _saleOutputEstimate) private view returns (uint256) {
      uint256 multiplicator = 10;

      for (uint i = 0; i < _antiWhaleSellThresholds.length; i++) {
        if (_saleOutputEstimate >= _antiWhaleSellThresholds[i]) {
          if (_antiWhaleSellMultiplicators[i] > multiplicator) multiplicator = _antiWhaleSellMultiplicators[i];
        }
      }

      return multiplicator;
    }

}