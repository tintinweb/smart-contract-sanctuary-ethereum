/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return now;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "no permission");
        require(now > _lockTime , "not expired");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

contract HSFOperators is Ownable {

    // @dev 操作员Address => 是否授权, 删除时并不会真正删除仅标记失效
    mapping (address => bool) private operators_;

    // MODIFIERS
    // ========================================================================
    // 仅操作员可调用
    modifier onlyOperator() {
        require(operators_[msg.sender], "Not operator");
        _;
    }
    // 仅Admin和操作员可调用
    modifier onlyOwnerOrOperator() {
        require((msg.sender == owner()) || operators_[msg.sender], "Not owner or operator");
        _;
    }

    // EVENT
    // ========================================================================
    event EnrollOperatorAddress(address operator);
    event DisableOperatorAddress(address operator);

    // FUNCTIONS
    // ========================================================================
    /**
     * @notice Enroll new operator addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     */
    function enrollOperatorAddress(address _operatorAddress) external onlyOwnerOrOperator {
        require(_operatorAddress != address(0), "Cannot be zero address");
        require(!operators_[_operatorAddress], "Already registered");
        operators_[_operatorAddress] = true;
        emit EnrollOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Disable a operator addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     */
    function disableOperatorAddress(address _operatorAddress) external onlyOwnerOrOperator {
        require(_operatorAddress != address(0), "Cannot be zero address");
        require(operators_[_operatorAddress], "Already disabled");
        operators_[_operatorAddress] = false;
        emit DisableOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Get operator availability
     * @param _operatorAddress: address of the operator
     */
    function getOperatorEnable(address _operatorAddress) public view returns (bool) {
        return operators_[_operatorAddress];
    }

}

contract HASHI is IERC20, HSFOperators {
    using SafeMath for uint256;

    address private _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap Router Address
    address payable public marketingAddress = 0x2c9FF62Ffa20E7eb12F225B395F2b404F1461467; // Marketing Address
    address payable public burningAddress = 0x0000000000000000000000000000000000000000; // Burn Address
    address payable public treasuryAddress = 0xfA881543b592CDAF979c9Bee932337b213ed47d7; // Treasury Address

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => address) public inviter;

    uint256 private constant MAX = ~uint256(0);

    uint256 private constant _tTotal = 100 * 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "HashLinkV10";
    string private constant _symbol = "HASHI10";
    uint8 private constant _decimals = 9;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _burnFee = 2;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _marketingFee = 2;
    uint256 private _previousMarketingFee = _marketingFee;
    bool public swapMarketingEnabled = true;

    uint256 public _treasuryFee = 2;
    uint256 private _previousTreasuryFee = _treasuryFee;
    bool public swapTreasuryEnabled = false;

    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _inviterFee = 1;
    uint256 private _previousInviterFee = _inviterFee;

    // sum must be 10000
    uint256 public _upperLv1Fee = 5000;
    uint256 public _upperLv2Fee = 3500;
    uint256 public _upperLv3Fee = 1500;

    uint256 private minimumTokensBeforeSwap = 1 * 10**9 * 10**9;
    uint256 public _maxWalletAmount = 10 * 10**9 * 10**9;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapToLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event EnrollInviters(
        uint256 indexed fromId,
        uint256 indexed toId,
        address[] leafAddresses,
        address[] branchAddresses,
        uint256 timeStamp
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[treasuryAddress] = true;
        _isExcludedFromFee[burningAddress] = true;

        _isExcluded[burningAddress] = true;
        _excluded.push(burningAddress);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _tokenTransfer(sender, recipient, amount, !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]));
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded");
        (uint256 rAmount,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwnerOrOperator() {
//        require(account != _uniswapRouterAddress, 'Cant exclude Pancake router');
        require(!_isExcluded[account], "Already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwnerOrOperator() {
        require(_isExcluded[account], "Already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = reflectionFromToken(_tOwned[account], false);
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (
            overMinimumTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {

            swapAndLiquify(contractTokenBalance);
        }

        _tokenTransfer(from,to,amount,takeFee);
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

    function _swapAddLiquify(uint256 liquidityQuota) private {
        if (liquidityQuota > 0) {
            uint256 initialBalance = address(this).balance;
            uint256 half = liquidityQuota.div(2);
            uint256 otherHalf = liquidityQuota.sub(half);
            swapTokensForEth(half);
            uint256 transferredLiquidityBalance = address(this).balance.sub(initialBalance);
            if (transferredLiquidityBalance > 0) {
                addLiquidity(otherHalf, transferredLiquidityBalance);
                emit SwapToLiquify(half, transferredLiquidityBalance, otherHalf);
            }
        }
    }

    function _swapTransferAddress(uint256 tokenAmount) private {
        uint256 totalFee = _marketingFee.add(_treasuryFee);
        if (totalFee > 0) {

            uint256 treasuryQuota = tokenAmount.mul(_treasuryFee).div(totalFee);
            if (treasuryQuota > 0) {
                _tokenTransfer(address(this), treasuryAddress, treasuryQuota, !_isExcludedFromFee[treasuryAddress]);
            }

            uint256 marketingQuota = tokenAmount.sub(treasuryQuota);
            if (swapMarketingEnabled && marketingQuota > 0) {
                uint256 initialBalance = address(this).balance;
                swapTokensForEth(marketingQuota);
                _transferForMarketingETH(marketingAddress, address(this).balance.sub(initialBalance));
            } else if (marketingQuota > 0) {
                _tokenTransfer(address(this), marketingAddress, marketingQuota, !_isExcludedFromFee[marketingAddress]);
            }
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into burn, marketing, treasury and liquify quotas
        uint256 totalFee = _burnFee.add(_marketingFee).add(_liquidityFee).add(_treasuryFee);
        if (totalFee > 0) {
            // burn
            uint256 burnQuota = contractTokenBalance.mul(_burnFee).div(totalFee);
            if (burnQuota > 0) {
                // burning tokens
                _tokenTransfer(address(this), burningAddress, burnQuota, !_isExcludedFromFee[burningAddress]);
            }

            // liquidity
            uint256 liquidityQuota = contractTokenBalance.mul(_liquidityFee).div(totalFee);
            _swapAddLiquify(liquidityQuota);

            // treasury, marketing
            _swapTransferAddress(contractTokenBalance.sub(burnQuota).sub(liquidityQuota));
        }
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
            address(this), // The contract
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {

        if(!takeFee) {
            removeAllFee();
        } else if (recipient != uniswapV2Pair) {
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(contractBalanceRecepient + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount");
        }

        // set inviter
        if (balanceOf(recipient) == 0 && inviter[recipient] == address(0) && sender != uniswapV2Pair && recipient != uniswapV2Pair) {
            inviter[recipient] = sender;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rInviter, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tInviter) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _takeInviterFee(sender, recipient, tInviter, rInviter);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rInviter, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tInviter) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _takeInviterFee(sender, recipient, tInviter, rInviter);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rInviter, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tInviter) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _takeInviterFee(sender, recipient, tInviter, rInviter);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rInviter, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tInviter) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _takeInviterFee(sender, recipient, tInviter, rInviter);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256[4] memory tValues = _getTValues(tAmount);
        uint256[4] memory rValues = _getRValues(tAmount, tValues[1], tValues[2], tValues[3]);
        return (rValues[0], rValues[1], rValues[2], rValues[3], tValues[0], tValues[1], tValues[2], tValues[3]);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256[4] memory) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tInviter = calculateInviterFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tInviter);
        return [tTransferAmount, tFee, tLiquidity, tInviter];
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tInviter) private view returns (uint256[4] memory) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rInviter = tInviter.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rInviter);
        return [rAmount, rTransferAmount, rFee, rInviter];
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

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if(tLiquidity > 0) {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            emit Transfer(sender, address(this), tLiquidity);
        }
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 rAmount
    ) private {
        if (_inviterFee == 0 || (tAmount == 0 && rAmount == 0)) return;
        address cur;
        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }
        // The unclaimed amount is transferred into the contract to continue reflection
        uint256 unclaimedTAmount = 0;
        uint256 unclaimedRAmount = 0;
        for (int256 i = 0; i < 3; i++) {
            uint256 rate;
            if (i == 0) {
                rate = _upperLv1Fee;
            } else if(i == 1 ){
                rate = _upperLv2Fee;
            } else {
                rate = _upperLv3Fee;
            }
            cur = inviter[cur];
            uint256 curTAmount = tAmount.div(10000).mul(rate);
            uint256 curRAmount = rAmount.div(10000).mul(rate);
            if (cur == address(0)) {
                unclaimedTAmount += curTAmount;
                unclaimedRAmount += curRAmount;
            } else if (_isExcluded[cur]) {
                unclaimedTAmount += curTAmount;
                unclaimedRAmount += curRAmount;
            } else {
                _rOwned[cur] = _rOwned[cur].add(curRAmount);
                emit Transfer(sender, cur, curTAmount);
            }
        }
        if (unclaimedTAmount > 0) {
            if (_isExcluded[address(this)]) {
                _tOwned[address(this)] = _tOwned[address(this)].add(unclaimedTAmount);
                _rOwned[address(this)] = _rOwned[address(this)].add(unclaimedRAmount);
            } else {
                _rOwned[address(this)] = _rOwned[address(this)].add(unclaimedRAmount);
            }
            emit Transfer(sender, address(this), unclaimedTAmount);
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee.add(_marketingFee).add(_liquidityFee).add(_treasuryFee)).div(
            10**2
        );
    }

    function calculateInviterFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_inviterFee).div(
            10**2
        );
    }

    function removeAllFee() private {
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTreasuryFee = _treasuryFee;
        _previousInviterFee = _inviterFee;
        _taxFee = 0;
        _burnFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _treasuryFee = 0;
        _inviterFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _treasuryFee = _previousTreasuryFee;
        _inviterFee = _previousInviterFee;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwnerOrOperator {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwnerOrOperator {
        _isExcludedFromFee[account] = false;
    }

    function setFeePercent(uint256 taxFee, uint256 burnFee, uint256 liquidityFee, uint256 treasuryFee, uint256 marketingFee, uint256 inviterFee) external onlyOwner() {
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _burnFee = burnFee;
        _treasuryFee = treasuryFee;
        _marketingFee = marketingFee;
        _inviterFee = inviterFee;
    }

    function setUpperFeePercent(uint256 upper1Fee, uint256 upper2Fee, uint256 upper3Fee) external onlyOwner() {
        require(
            (upper1Fee + upper2Fee + upper3Fee) == 10000,
            "Must equal 10000"
        );
        _upperLv1Fee = upper1Fee;
        _upperLv2Fee = upper2Fee;
        _upperLv3Fee = upper3Fee;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwnerOrOperator() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setAddresses(address payable _treasuryAddress, address payable _marketingAddress) external onlyOwner() {
        treasuryAddress = _treasuryAddress;
        marketingAddress = _marketingAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwnerOrOperator {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapMarketingEnabled(bool _enabled) external onlyOwnerOrOperator {
        swapMarketingEnabled = _enabled;
    }

    function setMaxWalletPercent(uint256 maxWalletPercent) public onlyOwnerOrOperator {
        require(maxWalletPercent > 0, "Cannot set transaction amount less than 1 percent!");
        _maxWalletAmount = _tTotal.mul(maxWalletPercent).div(
            10**2
        );
    }

    function transferContractBalance(uint256 amount) external onlyOwnerOrOperator {
        require(amount > 0, "Transfer amount must be greater than zero");
        payable(marketingAddress).transfer(amount);
    }

    function _transferForMarketingETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function enrollInviters(uint256 fromId, uint256 toId, address[] calldata leafAddresses, address[] calldata branchAddresses) external onlyOwnerOrOperator {
        require(leafAddresses.length != 0, "No address enrolled");
        require(leafAddresses.length <= 100, "Too many addresses");
        require(leafAddresses.length == branchAddresses.length, "Data does not match");
        for (uint256 i = 0; i < leafAddresses.length; i++) {
            address _leafAddress = leafAddresses[i];
            address _branchAddress = branchAddresses[i];
            require(_leafAddress != address(0), "Address is 0x0");
            require(_leafAddress != _branchAddress, "Address conflict");
            inviter[_leafAddress] = _branchAddress;
        }
        address[] memory leafOutput = new address[](leafAddresses.length);
        address[] memory branchOutput = new address[](branchAddresses.length);
        for (uint256 i = 0; i < leafAddresses.length; i++) {
            leafOutput[i] = leafAddresses[i];
            branchOutput[i] = branchAddresses[i];
        }
        emit EnrollInviters(fromId, toId, leafOutput, branchOutput, now);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}