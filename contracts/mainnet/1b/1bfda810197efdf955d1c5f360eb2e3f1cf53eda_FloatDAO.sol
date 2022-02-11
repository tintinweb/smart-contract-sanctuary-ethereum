/**
 *Submitted for verification at Etherscan.io on 2022-02-11
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
}

contract FloatDAO is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) public _firstBuyTime;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _isExcludedFromFee;

    address payable public dev;
    address payable public advocacy;
    address payable public treasury;
    address public _burnPool = 0x0000000000000000000000000000000000000000;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 57 * 10**15 * 10**9;

    string private _name = "Float DAO";
    string private _symbol = "FLOAT";
    uint8 private _decimals = 9;

    uint256 public _treasuryFee = 1000;
    uint256 public _advocacyFee = 200;
    uint256 public _burnFee = 200;
    uint256 public _developmentFee = 100;
    uint256 public _dayTraderMultiplicator = 17;
    bool public transfersEnabled; //once enabled, transfers cannot be disabled

    uint256 private launchBlock;
    uint256 private launchTime;
    uint256 private blocksLimit;

    uint256 public _pendingDevelopmentFees;
    uint256 public _pendingAdvocacyFees;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxWalletHolding = 142 * 10**13 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 10 * 10**12 * 10**9;

    uint256 public _marketingAllocation = 3 * 10**15 * 10**9;
    uint256 public _futureBurnsAllocation = 15 * 10**15 * 10**9;
    uint256 public _defiAdvocacyAllocation = 2 * 10**15 * 10**9;
    uint256 public _exchangeAllocation = 10 * 10**15 * 10**9;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _devWallet, address payable _advocacyWallet, address payable _treasuryWallet, address _marketingWallet, address _exchangeWallet, address _futureBurnsWallet, address _defiAdvocacyWallet) public {
      dev = _devWallet;
      advocacy = _advocacyWallet;
      treasury = _treasuryWallet;

      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
      uniswapV2Router = _uniswapV2Router;

      _isExcludedFromFee[owner()] = true;
      _isExcludedFromFee[address(this)] = true;
      _isExcludedFromFee[_burnPool] = true;
      _isExcludedFromFee[_futureBurnsWallet] = true;
      _isExcludedFromFee[_advocacyWallet] = true;
      _isExcludedFromFee[_marketingWallet] = true;
      _isExcludedFromFee[_exchangeWallet] = true;
      _isExcludedFromFee[_treasuryWallet] = true;
      _isExcludedFromFee[_defiAdvocacyWallet] = true;

      _balances[_futureBurnsWallet] = _futureBurnsAllocation;
      _balances[_defiAdvocacyWallet] = _defiAdvocacyAllocation;
      _balances[_exchangeWallet] = _exchangeAllocation;
      _balances[_marketingWallet] = _marketingAllocation;

      _balances[_msgSender()] = _tTotal - _balances[_marketingWallet] - _balances[_exchangeWallet] - _balances[_defiAdvocacyWallet] - _balances[_futureBurnsWallet];

      emit Transfer(address(0), _msgSender(), _tTotal);
      emit Transfer(_msgSender(), _marketingWallet, _marketingAllocation);
      emit Transfer(_msgSender(), _exchangeWallet, _exchangeAllocation);
      emit Transfer(_msgSender(), _futureBurnsWallet, _futureBurnsAllocation);
      emit Transfer(_msgSender(), _defiAdvocacyWallet, _defiAdvocacyAllocation);
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
        return _balances[account];
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

    function airdrop(address payable [] memory holders, uint256 [] memory balances) public onlyOwner() {
      require(holders.length == balances.length, "Incorrect input");
      uint256 deployer_balance = _balances[_msgSender()];

      for (uint8 i = 0; i < holders.length; i++) {
        uint256 balance = balances[i] * 10 ** 15;
        _balances[holders[i]] = _balances[holders[i]] + balance;
        _firstBuyTime[holders[i]] = block.timestamp;
        emit Transfer(_msgSender(), holders[i], balance);
        deployer_balance = deployer_balance.sub(balance);
      }

      _balances[_msgSender()] = deployer_balance;
    }

    function manualSwapAndLiquify() public onlyOwner() {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapAndLiquify(contractTokenBalance);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTax(uint256 _taxType, uint _taxSize) external onlyOwner() {
      if (_taxType == 1) {
        _treasuryFee = _taxSize;
        require(_treasuryFee <= 1000);
      }
      else if (_taxType == 2) {
        _developmentFee = _taxSize;
        require(_developmentFee <= 200);
      }
      else if (_taxType == 3) {
        _advocacyFee = _taxSize;
        require(_advocacyFee <= 200);
      }
      else if (_taxType == 4) {
        _burnFee = _taxSize;
        require(_burnFee <= 200);
      }
      else if (_taxType == 5) {
        _dayTraderMultiplicator = _taxSize;
      }
    }

    function setSwapAndLiquifyEnabled(bool _enabled, uint256 _numTokensMin) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        numTokensSellToAddToLiquidity = _numTokensMin;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function enableTransfers(uint256 _blocksLimit) public onlyOwner() {
        transfersEnabled = true;
        launchBlock = block.number;
        launchTime = block.timestamp;
        blocksLimit = _blocksLimit;
    }

    function setSniperEnabled(bool _enabled, address sniper) public onlyOwner() {
        _isSniper[sniper] = _enabled;
    }

    receive() external payable {}

    function _takeOperations(uint256 tAmount, uint256 feeType) private returns (uint256) {
        uint256 tTransferAmount = tAmount;
        uint256 taxMultiplicator = 10;

        if (feeType == 2) taxMultiplicator = _dayTraderMultiplicator;

        uint256 tAdvocacy = calculateFee(tAmount, _advocacyFee, taxMultiplicator);
        uint256 tDevelopment = calculateFee(tAmount, _developmentFee, taxMultiplicator);
        uint256 tTreasury = calculateFee(tAmount, _treasuryFee, taxMultiplicator);
        uint256 tBurn = calculateFee(tAmount, _burnFee, taxMultiplicator);

        _pendingDevelopmentFees = _pendingDevelopmentFees.add(tDevelopment);
        _pendingAdvocacyFees = _pendingAdvocacyFees.add(tAdvocacy);

        tTransferAmount = tAmount - tTreasury - tAdvocacy - tDevelopment - tBurn;
        uint256 tTaxes = tAmount - tTransferAmount - tBurn;

        _balances[address(this)] = _balances[address(this)].add(tTaxes);
        _balances[_burnPool] = _balances[_burnPool].add(tBurn);

        return tTransferAmount;
    }

    function calculateFee(uint256 _amount, uint256 _taxRate, uint256 _taxMultiplicator) private pure returns (uint256) {
        return _amount.mul(_taxRate).div(10**4).mul(_taxMultiplicator).div(10);
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
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        if (_firstBuyTime[to] == 0) _firstBuyTime[to] = block.timestamp;

        //indicates if fee should be deducted from transfer
        uint256 feeType = 1;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            feeType = 0;
        }
        else {
          require(transfersEnabled, "Transfers are not enabled now");
          if (to == uniswapV2Pair || (to != uniswapV2Pair && from != uniswapV2Pair)) {
            require(!_isSniper[from], "SNIPER!");
            if (to != uniswapV2Pair && from != uniswapV2Pair) {
              feeType = 0;
            }
            if (_firstBuyTime[from] != 0 && (_firstBuyTime[from] + (24 hours) > block.timestamp) ) {
              feeType = 2;
            }
          }
          if (from == uniswapV2Pair) {
            if (block.number <= (launchBlock + blocksLimit)) _isSniper[to] = true;
          }
        }

        _tokenTransfer(from, to, amount, feeType);

        if (!_isExcludedFromFee[to] && (to != uniswapV2Pair)) require(balanceOf(to) < _maxWalletHolding, "Max Wallet holding limit exceeded");
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 payDevelopment = _pendingDevelopmentFees.mul(newBalance).div(contractTokenBalance);
        uint256 payAdvocacy = _pendingAdvocacyFees.mul(newBalance).div(contractTokenBalance);
        if (payDevelopment <= address(this).balance && payDevelopment > 0) dev.call{ value: payDevelopment }("");
        if (payAdvocacy <= address(this).balance && payAdvocacy > 0) advocacy.call{ value: payAdvocacy }("");
        if (address(this).balance > 0) treasury.call{ value: address(this).balance }("");
        _pendingDevelopmentFees = 0;
        _pendingAdvocacyFees = 0;
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

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 feeType) private {
        uint256 tTransferAmount = amount;

        if (feeType != 0) {
          tTransferAmount = _takeOperations(amount, feeType);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

}